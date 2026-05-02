-- ============================================================================
-- MI-109 Phase 2 — CS Replacement Authorization Gate (backend)
-- ============================================================================
--
-- Ticket: MI-109 (CDM-Smith compliance rule (c) — CS replacement requires
--                 Carlo Domenick authorization with date+time+reason; NO EXCEPTION)
-- Branch: mi-109-rpc-rebuild
-- Generated: 2026-05-02 01:38:54 UTC
--
-- WHAT THIS MIGRATION DOES
-- ----------------------------------------------------------------------------
-- 1. Creates `public.cs_replacement_authorizations` (Owner Data, RLS forced,
--    INSERT-only via grants posture, audit-chained).
-- 2. Adds `cs_replacement boolean NOT NULL DEFAULT false` to `phase_submissions`.
-- 3. Creates `public.submit_cs_authorization(jsonb)` RPC (SECURITY DEFINER,
--    JSONB envelope return per INV-1) that validates input, inserts the auth
--    row, flips `phase_submissions.cs_replacement` to true, and self-logs every
--    attempt (accepted / rejected / already_recorded) via
--    `record_compliance_event` so the audit-every-attempt requirement holds.
--
-- HOW IT IS APPLIED
-- ----------------------------------------------------------------------------
-- Jorge runs this file in the Supabase dashboard SQL editor (project ref
-- `wryitfoletwskkdqqwcw`). This team does NOT use `supabase db push` — the
-- dashboard is the canonical apply path.
--
-- AUDIT CHAIN INTEGRATION
-- ----------------------------------------------------------------------------
-- Per discovery/whiteboard_override_template.md note 2: this migration does
-- NOT touch `audit_log` directly. AFTER INSERT trigger calls `write_audit_log`
-- which inserts a placeholder row; the BEFORE INSERT trigger on `audit_log`
-- itself overwrites the placeholder with the real `prev_hash`/`row_hash`
-- chain values. The new column `phase_submissions.cs_replacement` is captured
-- automatically because `write_audit_log` snapshots `to_jsonb(NEW)` on every
-- audited table. No layer-3 hash is computed in this file.
--
-- IMMUTABILITY POSTURE
-- ----------------------------------------------------------------------------
-- INSERT-only via GRANT (per note 4/5). `anon` and `authenticated` get
-- SELECT/REFERENCES/TRIGGER/TRUNCATE only — NO INSERT/UPDATE/DELETE. Writes
-- happen exclusively through the SECURITY DEFINER RPC, which runs as the
-- function owner and inherits its grants. NO BEFORE UPDATE/DELETE trigger
-- raising an exception (Phase 3 deferral — keep this reversible).
--
-- INVENTIONS (load-bearing — see discovery/whiteboard_override_template.md
-- "Inventions" section for full justifications and lead/Jorge resolutions)
-- ----------------------------------------------------------------------------
-- INV-1: RPC returns JSONB envelope `{status, authorization_id?, error_code?,
--        message}`. Validation rejections return envelope (NOT raise) so
--        same-transaction `record_compliance_event` INSERTs survive. Only
--        AUTH_DENIED raises (security boundary).
-- INV-2: RLS uses inline `profiles` subquery; `role = 'super_admin'` for
--        cross-firm escalation (CLAUDE.md NULL-firm super_admin branch).
-- INV-3: `extensions.gen_random_uuid()` schema-qualified.
-- NB3:   Single `authorized_at timestamptz` (lead override of original split).
-- NB1, NB2, NB4-NB13: Approved as proposed.
--
-- POST-DEPLOY VERIFICATION (run these against prod after Jorge applies)
-- ----------------------------------------------------------------------------
-- - Confirm RLS forced: `SELECT relrowsecurity, relforcerowsecurity FROM
--     pg_class WHERE oid='public.cs_replacement_authorizations'::regclass;`
-- - Confirm grants match Note 4: `SELECT grantee, privilege_type FROM
--     information_schema.role_table_grants WHERE table_schema='public' AND
--     table_name='cs_replacement_authorizations';`
-- - Confirm audit triggers attached: `SELECT tgname FROM pg_trigger WHERE
--     tgrelid='public.cs_replacement_authorizations'::regclass AND NOT
--     tgisinternal;`
-- - Smoke test RPC with a known phase_submission_id; confirm row inserted,
--   `phase_submissions.cs_replacement` flipped true, two compliance_events
--   rows logged (accepted + parent INSERT audit_log entry).
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. ALTER phase_submissions: add cs_replacement flag
-- ----------------------------------------------------------------------------
ALTER TABLE public.phase_submissions
  ADD COLUMN IF NOT EXISTS cs_replacement boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.phase_submissions.cs_replacement IS
  'MI-109: true when this submission involves a curbstop replacement; '
  'requires a corresponding row in cs_replacement_authorizations '
  '(Carlo Domenick authorization, no exception per CDM-Smith rule c).';

-- ----------------------------------------------------------------------------
-- 2. CREATE TABLE cs_replacement_authorizations
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cs_replacement_authorizations (
  id                       uuid        PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  phase_submission_id      uuid        NOT NULL
                                       REFERENCES public.phase_submissions(id),
  authorizing_supervisor   text        NOT NULL DEFAULT 'Carlo Domenick',
  authorized_at            timestamptz NOT NULL,
  reason                   text        NOT NULL,
  submitted_by             uuid        REFERENCES auth.users(id),
  firm_id                  uuid        REFERENCES public.firms(id),  -- NULLABLE: super_admin per CLAUDE.md
  created_at               timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT cs_replacement_auth_unique_per_submission UNIQUE (phase_submission_id),
  CONSTRAINT cs_replacement_auth_supervisor_nonempty
    CHECK (length(btrim(authorizing_supervisor)) > 0),
  CONSTRAINT cs_replacement_auth_reason_min_length
    CHECK (length(reason) >= 20)
);

COMMENT ON TABLE public.cs_replacement_authorizations IS
  'MI-109: Carlo Domenick authorization required for any CS (curbstop) '
  'replacement (CDM-Smith rule c). INSERT-only via grants; SELECT gated by '
  'RLS; UPDATE/DELETE not granted to anon/authenticated. Writes flow only '
  'through public.submit_cs_authorization() RPC.';

-- ----------------------------------------------------------------------------
-- 3. RLS — force, then per-firm SELECT/INSERT policy with super_admin escalation
-- ----------------------------------------------------------------------------
ALTER TABLE public.cs_replacement_authorizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cs_replacement_authorizations FORCE ROW LEVEL SECURITY;

-- One policy covers SELECT + INSERT (USING + WITH CHECK). UPDATE/DELETE are
-- not granted at the role level so no policy is needed for them.
DROP POLICY IF EXISTS cs_replacement_auth_firm_isolation
  ON public.cs_replacement_authorizations;

CREATE POLICY cs_replacement_auth_firm_isolation
  ON public.cs_replacement_authorizations
  AS PERMISSIVE
  FOR ALL
  TO authenticated
  USING (
    firm_id = (SELECT firm_id FROM public.profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin')
  )
  WITH CHECK (
    firm_id = (SELECT firm_id FROM public.profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin')
  );

-- ----------------------------------------------------------------------------
-- 4. Grants — mirror whiteboard_override_log posture (note 4):
--    anon/authenticated get SELECT/REFERENCES/TRIGGER/TRUNCATE only.
--    NO INSERT/UPDATE/DELETE for either. Writes only via SECURITY DEFINER RPC.
-- ----------------------------------------------------------------------------
REVOKE ALL ON public.cs_replacement_authorizations FROM PUBLIC;
REVOKE ALL ON public.cs_replacement_authorizations FROM anon;
REVOKE ALL ON public.cs_replacement_authorizations FROM authenticated;

GRANT SELECT, REFERENCES, TRIGGER, TRUNCATE
  ON public.cs_replacement_authorizations TO anon;
GRANT SELECT, REFERENCES, TRIGGER, TRUNCATE
  ON public.cs_replacement_authorizations TO authenticated;
-- postgres + service_role retain ALL by default (table owner / superuser).

-- ----------------------------------------------------------------------------
-- 5. Audit chain — attach the same write_audit_log trigger used on other
--    Owner Data tables (mirror whiteboard_override_log per note 2). The
--    function `public.write_audit_log()` is assumed to exist already (it
--    powers MI-202's chain). Lead flags if the trigger function in production
--    has a different name (e.g. audit_owner_data_trigger) and backend revises.
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS write_audit_log_trg
  ON public.cs_replacement_authorizations;

CREATE TRIGGER write_audit_log_trg
  AFTER INSERT OR UPDATE OR DELETE
  ON public.cs_replacement_authorizations
  FOR EACH ROW
  EXECUTE FUNCTION public.write_audit_log();

-- ----------------------------------------------------------------------------
-- 6. RPC — submit_cs_authorization(p_args jsonb) -> jsonb envelope
-- ----------------------------------------------------------------------------
-- INPUT (jsonb object — single param to keep the RPC signature stable as
-- fields evolve; matches frontend's existing supabase.rpc(name, {...}) call):
--   {
--     phase_submission_id: uuid,
--     authorizing_supervisor: text,    // optional; defaults to 'Carlo Domenick'
--     authorized_at: timestamptz (ISO 8601 string),
--     reason: text                     // min 20 chars after trim
--   }
--
-- RETURN (jsonb envelope per INV-1):
--   {
--     status: 'accepted' | 'rejected' | 'already_recorded',
--     authorization_id: uuid | null,
--     error_code: text | null,
--     message: text
--   }
--
-- BEHAVIOR
-- - auth.uid() IS NULL  -> RAISE 'AUTH_DENIED: ...' USING ERRCODE='insufficient_privilege'
--   (security boundary, not auditable from inside the RPC; Postgrest layer
--   surfaces this to the client as 401).
-- - Validation failure -> log to compliance_events with
--   event_type='cs_replacement.auth.rejected', return rejected envelope.
-- - Phase submission not found in caller's firm -> rejected
--   error_code='PHASE_SUBMISSION_NOT_FOUND'.
-- - 23505 unique_violation (existing auth row for same phase_submission_id)
--   -> log event_type='cs_replacement.auth.duplicate', return
--   already_recorded envelope with the existing row's id.
-- - Success -> insert auth row, set phase_submissions.cs_replacement=true,
--   log event_type='cs_replacement.auth.accepted', return accepted envelope
--   with new authorization_id.
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.submit_cs_authorization(p_args jsonb)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO public, extensions, pg_temp
AS $fn$
DECLARE
  v_caller_uid           uuid;
  v_caller_firm_id       uuid;
  v_caller_role          text;
  v_phase_submission_id  uuid;
  v_supervisor           text;
  v_authorized_at        timestamptz;
  v_reason               text;
  v_phase_firm_id        uuid;
  v_phase_exists         boolean;
  v_existing_auth_id     uuid;
  v_new_auth_id          uuid;
  v_details              jsonb;
  v_message              text;
BEGIN
  -- ------------------------------------------------------------------------
  -- (1) Identify caller — auth.uid() / profiles lookup.
  --     auth.uid() returns NULL when called from the SQL editor (no JWT).
  --     Per CLAUDE.md and the brief, mirror the record_whiteboard_override
  --     fallback: SQL Editor calls are rejected at this layer because there
  --     is no JWT identity to attribute the authorization to. Production
  --     callers always have auth.uid().
  -- ------------------------------------------------------------------------
  v_caller_uid := auth.uid();

  IF v_caller_uid IS NULL THEN
    RAISE EXCEPTION 'AUTH_DENIED: submit_cs_authorization requires an authenticated caller'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  SELECT firm_id, role
    INTO v_caller_firm_id, v_caller_role
    FROM public.profiles
   WHERE id = v_caller_uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'AUTH_DENIED: caller has no profile row'
      USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- ------------------------------------------------------------------------
  -- (2) Extract and coerce arguments. Defensive: NULLs flow through to
  --     validation step and become rejected envelopes, NOT raises.
  -- ------------------------------------------------------------------------
  v_phase_submission_id := NULLIF(p_args->>'phase_submission_id','')::uuid;
  v_supervisor          := COALESCE(NULLIF(btrim(p_args->>'authorizing_supervisor'),''), 'Carlo Domenick');
  v_authorized_at       := NULLIF(p_args->>'authorized_at','')::timestamptz;
  v_reason              := COALESCE(p_args->>'reason','');

  -- ------------------------------------------------------------------------
  -- (3) Validation — return rejected envelope (NOT raise) on each failure
  --     so the compliance_events INSERT below survives.
  -- ------------------------------------------------------------------------
  IF v_phase_submission_id IS NULL THEN
    v_details := jsonb_build_object(
      'phase_submission_id', NULL,
      'supervisor', v_supervisor,
      'authorized_at', v_authorized_at,
      'reason_length', length(v_reason),
      'status', 'rejected',
      'error_code', 'PHASE_SUBMISSION_NOT_FOUND'
    );
    PERFORM public.record_compliance_event(
      p_event_type    => 'cs_replacement.auth.rejected',
      p_message       => 'CS authorization rejected: phase_submission_id missing',
      p_severity      => 'alert',
      p_details       => v_details,
      p_source        => 'MI-109',
      p_correlation_id=> COALESCE(p_args->>'phase_submission_id','')
    );
    RETURN jsonb_build_object(
      'status', 'rejected',
      'authorization_id', NULL,
      'error_code', 'PHASE_SUBMISSION_NOT_FOUND',
      'message', 'phase_submission_id is required'
    );
  END IF;

  IF v_authorized_at IS NULL THEN
    v_details := jsonb_build_object(
      'phase_submission_id', v_phase_submission_id,
      'supervisor', v_supervisor,
      'authorized_at', NULL,
      'reason_length', length(v_reason),
      'status', 'rejected',
      'error_code', 'AUTHORIZED_AT_MISSING'
    );
    PERFORM public.record_compliance_event(
      p_event_type    => 'cs_replacement.auth.rejected',
      p_message       => 'CS authorization rejected: authorized_at missing or invalid',
      p_severity      => 'alert',
      p_details       => v_details,
      p_source        => 'MI-109',
      p_correlation_id=> v_phase_submission_id::text
    );
    RETURN jsonb_build_object(
      'status', 'rejected',
      'authorization_id', NULL,
      'error_code', 'AUTHORIZED_AT_MISSING',
      'message', 'authorized_at is required (ISO 8601 timestamp)'
    );
  END IF;

  IF length(btrim(v_supervisor)) = 0 THEN
    v_details := jsonb_build_object(
      'phase_submission_id', v_phase_submission_id,
      'supervisor', v_supervisor,
      'authorized_at', v_authorized_at,
      'reason_length', length(v_reason),
      'status', 'rejected',
      'error_code', 'SUPERVISOR_EMPTY'
    );
    PERFORM public.record_compliance_event(
      p_event_type    => 'cs_replacement.auth.rejected',
      p_message       => 'CS authorization rejected: authorizing_supervisor is empty',
      p_severity      => 'alert',
      p_details       => v_details,
      p_source        => 'MI-109',
      p_correlation_id=> v_phase_submission_id::text
    );
    RETURN jsonb_build_object(
      'status', 'rejected',
      'authorization_id', NULL,
      'error_code', 'SUPERVISOR_EMPTY',
      'message', 'authorizing_supervisor cannot be empty'
    );
  END IF;

  IF length(v_reason) < 20 THEN
    v_details := jsonb_build_object(
      'phase_submission_id', v_phase_submission_id,
      'supervisor', v_supervisor,
      'authorized_at', v_authorized_at,
      'reason_length', length(v_reason),
      'status', 'rejected',
      'error_code', 'REASON_TOO_SHORT'
    );
    PERFORM public.record_compliance_event(
      p_event_type    => 'cs_replacement.auth.rejected',
      p_message       => format('CS authorization rejected: reason too short (%s/20)', length(v_reason)),
      p_severity      => 'alert',
      p_details       => v_details,
      p_source        => 'MI-109',
      p_correlation_id=> v_phase_submission_id::text
    );
    RETURN jsonb_build_object(
      'status', 'rejected',
      'authorization_id', NULL,
      'error_code', 'REASON_TOO_SHORT',
      'message', 'reason must be at least 20 characters'
    );
  END IF;

  -- ------------------------------------------------------------------------
  -- (4) Lookup phase submission for cross-firm enforcement + denorm.
  --     SECURITY DEFINER bypasses RLS, so we enforce firm isolation
  --     manually here. Super_admin bypasses (matches RLS expression).
  -- ------------------------------------------------------------------------
  SELECT firm_id, true
    INTO v_phase_firm_id, v_phase_exists
    FROM public.phase_submissions
   WHERE id = v_phase_submission_id;

  IF NOT FOUND OR NOT v_phase_exists THEN
    v_details := jsonb_build_object(
      'phase_submission_id', v_phase_submission_id,
      'supervisor', v_supervisor,
      'authorized_at', v_authorized_at,
      'reason_length', length(v_reason),
      'status', 'rejected',
      'error_code', 'PHASE_SUBMISSION_NOT_FOUND'
    );
    PERFORM public.record_compliance_event(
      p_event_type    => 'cs_replacement.auth.rejected',
      p_message       => 'CS authorization rejected: phase submission not found',
      p_severity      => 'alert',
      p_details       => v_details,
      p_source        => 'MI-109',
      p_correlation_id=> v_phase_submission_id::text
    );
    RETURN jsonb_build_object(
      'status', 'rejected',
      'authorization_id', NULL,
      'error_code', 'PHASE_SUBMISSION_NOT_FOUND',
      'message', 'phase submission not found'
    );
  END IF;

  -- Cross-firm check: caller's firm must match phase submission's firm,
  -- unless caller is super_admin (NULL firm_id allowed).
  IF v_caller_role IS DISTINCT FROM 'super_admin'
     AND v_phase_firm_id IS DISTINCT FROM v_caller_firm_id THEN
    v_details := jsonb_build_object(
      'phase_submission_id', v_phase_submission_id,
      'supervisor', v_supervisor,
      'authorized_at', v_authorized_at,
      'reason_length', length(v_reason),
      'status', 'rejected',
      'error_code', 'FORBIDDEN_CROSS_FIRM'
    );
    PERFORM public.record_compliance_event(
      p_event_type    => 'cs_replacement.auth.rejected',
      p_message       => 'CS authorization rejected: cross-firm attempt blocked',
      p_severity      => 'alert',
      p_details       => v_details,
      p_source        => 'MI-109',
      p_correlation_id=> v_phase_submission_id::text
    );
    RETURN jsonb_build_object(
      'status', 'rejected',
      'authorization_id', NULL,
      'error_code', 'FORBIDDEN_CROSS_FIRM',
      'message', 'phase submission belongs to a different firm'
    );
  END IF;

  -- ------------------------------------------------------------------------
  -- (5) INSERT auth row. Catch 23505 (UNIQUE on phase_submission_id) for
  --     idempotent retry semantics — return already_recorded envelope with
  --     the existing row's id.
  -- ------------------------------------------------------------------------
  BEGIN
    INSERT INTO public.cs_replacement_authorizations (
      phase_submission_id,
      authorizing_supervisor,
      authorized_at,
      reason,
      submitted_by,
      firm_id
    )
    VALUES (
      v_phase_submission_id,
      v_supervisor,
      v_authorized_at,
      v_reason,
      v_caller_uid,
      v_phase_firm_id
    )
    RETURNING id INTO v_new_auth_id;
  EXCEPTION
    WHEN unique_violation THEN
      SELECT id INTO v_existing_auth_id
        FROM public.cs_replacement_authorizations
       WHERE phase_submission_id = v_phase_submission_id;

      v_details := jsonb_build_object(
        'phase_submission_id', v_phase_submission_id,
        'supervisor', v_supervisor,
        'authorized_at', v_authorized_at,
        'reason_length', length(v_reason),
        'status', 'already_recorded',
        'error_code', 'ALREADY_RECORDED',
        'existing_authorization_id', v_existing_auth_id
      );
      PERFORM public.record_compliance_event(
        p_event_type    => 'cs_replacement.auth.duplicate',
        p_message       => 'CS authorization retry: already recorded for this phase submission',
        p_severity      => 'alert',
        p_details       => v_details,
        p_source        => 'MI-109',
        p_correlation_id=> v_phase_submission_id::text
      );
      RETURN jsonb_build_object(
        'status', 'already_recorded',
        'authorization_id', v_existing_auth_id,
        'error_code', 'ALREADY_RECORDED',
        'message', 'CS replacement authorization already recorded for this phase submission'
      );
  END;

  -- Flip phase_submissions.cs_replacement to true. This UPDATE is captured
  -- by the audit chain layer-2 trigger automatically (write_audit_log
  -- snapshots to_jsonb(NEW), so the new column travels with it).
  UPDATE public.phase_submissions
     SET cs_replacement = true
   WHERE id = v_phase_submission_id;

  -- ------------------------------------------------------------------------
  -- (6) Self-log success.
  -- ------------------------------------------------------------------------
  v_details := jsonb_build_object(
    'phase_submission_id', v_phase_submission_id,
    'supervisor', v_supervisor,
    'authorized_at', v_authorized_at,
    'reason_length', length(v_reason),
    'status', 'accepted',
    'authorization_id', v_new_auth_id
  );
  v_message := format(
    'CS replacement authorization accepted by %s at %s for phase submission %s',
    v_supervisor,
    v_authorized_at::text,
    v_phase_submission_id::text
  );
  PERFORM public.record_compliance_event(
    p_event_type    => 'cs_replacement.auth.accepted',
    p_message       => v_message,
    p_severity      => 'alert',
    p_details       => v_details,
    p_source        => 'MI-109',
    p_correlation_id=> v_phase_submission_id::text
  );

  RETURN jsonb_build_object(
    'status', 'accepted',
    'authorization_id', v_new_auth_id,
    'error_code', NULL,
    'message', v_message
  );
END;
$fn$;

COMMENT ON FUNCTION public.submit_cs_authorization(jsonb) IS
  'MI-109: Records Carlo Domenick authorization for a CS (curbstop) '
  'replacement on a phase submission. SECURITY DEFINER. Returns JSONB '
  'envelope {status, authorization_id, error_code, message}. Every attempt '
  '(accepted/rejected/already_recorded) is logged to compliance_events with '
  'severity=''alert''. Auth-denied raises insufficient_privilege.';

-- Grants — RPC is callable by authenticated only; anon must not be able to
-- record CS authorizations. Mirror whiteboard pattern (note 4): writes flow
-- via the SECURITY DEFINER function, not via direct table grants.
REVOKE ALL ON FUNCTION public.submit_cs_authorization(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.submit_cs_authorization(jsonb) FROM anon;
GRANT EXECUTE ON FUNCTION public.submit_cs_authorization(jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_cs_authorization(jsonb) TO service_role;

COMMIT;
