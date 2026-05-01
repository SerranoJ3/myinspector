-- MI-109: CS Replacement Authorization Gate (CDM-Smith rule c, NO EXCEPTION)
--
-- ASSUMES (Jorge to verify against live DB before merge):
--   1. `phase_submissions` table exists with column `id uuid PRIMARY KEY` and `firm_id uuid`.
--   2. `firms` table exists with `id uuid PRIMARY KEY`.
--   3. `profiles` table exists with at minimum `id uuid REFERENCES auth.users(id)`
--      and `firm_id uuid REFERENCES firms(id)`. This is the canonical firm-isolation
--      lookup used by other RLS policies (per CLAUDE.md MI-200 closure).
--   4. `audit_log` table exists from MI-202 with at least these columns:
--        id uuid PK,
--        event_type text NOT NULL,
--        table_name text NOT NULL,
--        row_id uuid NULL,
--        firm_id uuid NULL,
--        actor_id uuid NULL,
--        payload jsonb NOT NULL,
--        prev_hash text NOT NULL,
--        current_hash text NOT NULL,
--        created_at timestamptz NOT NULL DEFAULT now()
--      with the SHA-256 hash chain seeded by literal 'GENESIS' (per CLAUDE.md
--      Audit chain Layer 3). If column names differ on the live DB, adjust the
--      INSERT in fn_mi109_audit_cs_auth_accepted() accordingly.
--   5. `pgcrypto` extension is installed (provides gen_random_uuid + digest).
--      If digest() lives elsewhere, swap encode(digest(...,'sha256'),'hex')
--      for the helper used by MI-202.
--   6. There is no pre-existing helper function for hash-chain inserts visible
--      in the local repo. We compute prev_hash inline from the latest audit_log
--      row (ORDER BY created_at DESC, id DESC LIMIT 1) and fall back to
--      'GENESIS' on empty table. If MI-202 shipped a helper (e.g.
--      audit_log_append(...)), prefer that and replace the inline INSERT.
--   7. Layer 1 of the audit chain (no UPDATE/DELETE grant) is enforced via
--      REVOKE on this new table; the existing global pattern is assumed to be
--      table-by-table, not role-wide.

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Extend phase_submissions with cs_replacement flag
-- ---------------------------------------------------------------------------
ALTER TABLE public.phase_submissions
  ADD COLUMN IF NOT EXISTS cs_replacement boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.phase_submissions.cs_replacement IS
  'MI-109: true when this submission involves a curbstop replacement. '
  'Triggers Carlo authorization requirement at submit time (CDM-Smith rule c).';

-- ---------------------------------------------------------------------------
-- 2. cs_replacement_authorizations table (Owner Data — audit chain applies)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cs_replacement_authorizations (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id    uuid NOT NULL REFERENCES public.phase_submissions(id) ON DELETE RESTRICT,
  firm_id          uuid NOT NULL REFERENCES public.firms(id),
  supervisor_name  text NOT NULL DEFAULT 'Carlo Domenick',
  authorized_date  date NOT NULL,
  authorized_time  time NOT NULL,
  reason           text NOT NULL CHECK (length(trim(reason)) >= 20),
  created_by       uuid NOT NULL REFERENCES auth.users(id) DEFAULT auth.uid(),
  created_at       timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.cs_replacement_authorizations IS
  'MI-109: Per-CS-replacement authorization records (CDM-Smith rule c, NO EXCEPTION). '
  'Owner Data — immutable, audit-chained. Insert-only. Rejected attempts are NOT '
  'inserted here; they go directly to audit_log via the cs-auth-submit edge function.';

CREATE INDEX IF NOT EXISTS idx_cs_auth_submission_id
  ON public.cs_replacement_authorizations(submission_id);
CREATE INDEX IF NOT EXISTS idx_cs_auth_firm_id
  ON public.cs_replacement_authorizations(firm_id);
CREATE INDEX IF NOT EXISTS idx_cs_auth_created_at_desc
  ON public.cs_replacement_authorizations(created_at DESC);

-- ---------------------------------------------------------------------------
-- 3. Layer 1: Lock down grants (no UPDATE/DELETE for clients)
-- ---------------------------------------------------------------------------
ALTER TABLE public.cs_replacement_authorizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cs_replacement_authorizations FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.cs_replacement_authorizations FROM anon, authenticated;
GRANT SELECT, INSERT ON public.cs_replacement_authorizations TO authenticated;
-- (anon stays fully revoked — no anon access to Owner Data)

-- ---------------------------------------------------------------------------
-- 4. RLS policies — firm isolation, insert binds to caller
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS cs_auth_select_same_firm ON public.cs_replacement_authorizations;
CREATE POLICY cs_auth_select_same_firm
  ON public.cs_replacement_authorizations
  FOR SELECT
  TO authenticated
  USING (
    firm_id = (SELECT p.firm_id FROM public.profiles p WHERE p.id = auth.uid())
  );

DROP POLICY IF EXISTS cs_auth_insert_same_firm ON public.cs_replacement_authorizations;
CREATE POLICY cs_auth_insert_same_firm
  ON public.cs_replacement_authorizations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    created_by = auth.uid()
    AND firm_id = (SELECT p.firm_id FROM public.profiles p WHERE p.id = auth.uid())
  );

-- NOTE: No UPDATE policy. No DELETE policy. By design (Layer 1).

-- ---------------------------------------------------------------------------
-- 5. Layer 2: BEFORE UPDATE/DELETE trigger raises exception
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_mi109_block_mutations()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public, pg_temp
AS $$
BEGIN
  RAISE EXCEPTION
    'cs_replacement_authorizations is immutable (MI-109 / CDM-Smith rule c). '
    'Operation % blocked by audit-chain Layer 2.', TG_OP
    USING ERRCODE = 'insufficient_privilege';
END;
$$;

DROP TRIGGER IF EXISTS trg_mi109_block_update
  ON public.cs_replacement_authorizations;
CREATE TRIGGER trg_mi109_block_update
  BEFORE UPDATE ON public.cs_replacement_authorizations
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_mi109_block_mutations();

DROP TRIGGER IF EXISTS trg_mi109_block_delete
  ON public.cs_replacement_authorizations;
CREATE TRIGGER trg_mi109_block_delete
  BEFORE DELETE ON public.cs_replacement_authorizations
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_mi109_block_mutations();

-- ---------------------------------------------------------------------------
-- 6. Layer 3: AFTER INSERT trigger writes to audit_log + extends hash chain
--
-- Hash chain semantics (from CLAUDE.md):
--   - Seed: literal 'GENESIS'
--   - prev_hash = current_hash of latest audit_log row, or 'GENESIS' if empty
--   - current_hash = sha256(prev_hash || canonical(payload))
--   - canonical encoding = jsonb cast to text (Postgres jsonb output is
--     deterministic for a given input via key-sort + whitespace normalization).
--     If MI-202 uses a different canonicalizer (e.g. jsonb_strip_nulls or a
--     custom function), swap it in here.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.fn_mi109_audit_cs_auth_accepted()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path = public, pg_temp
AS $$
DECLARE
  v_prev_hash    text;
  v_payload      jsonb;
  v_canonical    text;
  v_current_hash text;
BEGIN
  v_payload := to_jsonb(NEW);

  -- Pull latest hash for chain continuation. Genesis on empty.
  SELECT current_hash
    INTO v_prev_hash
    FROM public.audit_log
    ORDER BY created_at DESC, id DESC
    LIMIT 1;

  IF v_prev_hash IS NULL THEN
    v_prev_hash := 'GENESIS';
  END IF;

  -- Deterministic canonical encoding of payload.
  v_canonical := v_payload::text;

  v_current_hash := encode(
    digest(v_prev_hash || v_canonical, 'sha256'),
    'hex'
  );

  INSERT INTO public.audit_log (
    event_type,
    table_name,
    row_id,
    firm_id,
    actor_id,
    payload,
    prev_hash,
    current_hash
  ) VALUES (
    'cs_auth_accepted',
    'cs_replacement_authorizations',
    NEW.id,
    NEW.firm_id,
    NEW.created_by,
    v_payload,
    v_prev_hash,
    v_current_hash
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mi109_audit_cs_auth_accepted
  ON public.cs_replacement_authorizations;
CREATE TRIGGER trg_mi109_audit_cs_auth_accepted
  AFTER INSERT ON public.cs_replacement_authorizations
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_mi109_audit_cs_auth_accepted();

COMMIT;
