-- =============================================================================
-- MI-109 — RLS + INSERT-only-via-grants verification (v2)
-- =============================================================================
-- Purpose: prove cs_replacement_authorizations enforces:
--   1. authenticated has NO INSERT/UPDATE/DELETE grants — direct DML fails with
--      insufficient_privilege (Note 4: grant-enforced immutability).
--   2. Insert path is the SECURITY DEFINER RPC submit_cs_authorization, which
--      runs as definer (postgres) and is constrained by the RLS WITH CHECK
--      expression embedded in the policy (firm_id binds to caller's profile).
--   3. SELECT under RLS hides cross-firm rows.
--   4. UPDATE / DELETE blocked by grant alone (no BEFORE-trigger raise per
--      Note 5).
--   5. RPC happy path returns envelope {status:'accepted', authorization_id, ...}
--      and inserts exactly one row.
--   6. RPC duplicate path returns envelope {status:'already_recorded', ...}
--      and does NOT insert a second row (UNIQUE on phase_submission_id).
--   7. RPC cross-firm attempt by inspector A on firm-B submission returns
--      rejected envelope (or RAISEs AUTH_DENIED) — never lands a row.
--
-- Run as:  postgres
-- Mode:    single transaction wrapped in BEGIN/ROLLBACK — leaves no residue.
--
-- Authority: discovery/whiteboard_override_template.md "Architectural Notes
-- from Jorge" + "Decision log (resolved 2026-05-02 session open)".
--
-- Schema asserted (from decision log):
--   cs_replacement_authorizations(
--     id uuid PK DEFAULT extensions.gen_random_uuid(),
--     phase_submission_id uuid NOT NULL UNIQUE REFERENCES phase_submissions(id),
--     firm_id uuid NULL REFERENCES firms(id),
--     authorizing_supervisor text NOT NULL DEFAULT 'Carlo Domenick',
--     authorized_at timestamptz NOT NULL,
--     reason text NOT NULL CHECK (length(reason) >= 20),
--     submitted_by uuid NULL REFERENCES auth.users(id),
--     created_at timestamptz NOT NULL DEFAULT now()
--   )
--
-- RPC parameter shape (decision log NB3 override):
--   submit_cs_authorization(
--     p_phase_submission_id uuid,
--     p_authorizing_supervisor text,
--     p_authorized_at timestamptz,
--     p_reason text
--   ) RETURNS jsonb
--
-- Envelope (decision log INV-1):
--   {status, authorization_id, error_code, message}
--
-- !! TESTER ACTION NEEDED — seed-row column shape !!
--   Step 0 fixture inserts use a minimal column set for firms,
--   profiles, phase_submissions. If live schema has additional NOT NULL
--   columns the seed will fail. Run \d on staging and extend the column
--   lists if needed. Marked TODO inline.
-- =============================================================================

BEGIN;

SET LOCAL client_min_messages = NOTICE;

-- -----------------------------------------------------------------------------
-- 0. Test fixtures: two firms, one user each, one phase_submission per firm
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_firm_a uuid := extensions.gen_random_uuid();
  v_firm_b uuid := extensions.gen_random_uuid();
  v_user_a uuid := extensions.gen_random_uuid();
  v_user_b uuid := extensions.gen_random_uuid();
  v_sub_a  uuid := extensions.gen_random_uuid();
  v_sub_b  uuid := extensions.gen_random_uuid();
BEGIN
  PERFORM set_config('mi109.firm_a', v_firm_a::text, true);
  PERFORM set_config('mi109.firm_b', v_firm_b::text, true);
  PERFORM set_config('mi109.user_a', v_user_a::text, true);
  PERFORM set_config('mi109.user_b', v_user_b::text, true);
  PERFORM set_config('mi109.sub_a',  v_sub_a::text,  true);
  PERFORM set_config('mi109.sub_b',  v_sub_b::text,  true);

  -- TODO: extend column lists to match live schema if NOT NULL violations
  -- occur. Likely missing columns on phase_submissions: phase, property_id,
  -- created_by, submitted_at. Confirm via \d on staging.
  INSERT INTO public.firms (id, name, firm_code)
    VALUES (v_firm_a, 'TEST-FIRM-A-MI109', 'TEST-A-MI109'),
           (v_firm_b, 'TEST-FIRM-B-MI109', 'TEST-B-MI109');

  INSERT INTO auth.users (id, email, instance_id, aud, role)
    VALUES (v_user_a, 'a@mi109.test', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
           (v_user_b, 'b@mi109.test', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

  INSERT INTO public.profiles (id, firm_id, role, full_name)
    VALUES (v_user_a, v_firm_a, 'inspector', 'Test Inspector A'),
           (v_user_b, v_firm_b, 'inspector', 'Test Inspector B');

  INSERT INTO public.phase_submissions (id, firm_id, cs_replacement)
    VALUES (v_sub_a, v_firm_a, true),
           (v_sub_b, v_firm_b, true);

  RAISE NOTICE 'fixtures seeded — firm_a=%, firm_b=%, sub_a=%, sub_b=%',
    v_firm_a, v_firm_b, v_sub_a, v_sub_b;
END $$;

-- -----------------------------------------------------------------------------
-- 1. As authenticated: direct INSERT must FAIL (no INSERT grant per Note 4)
--    Expected: SQLSTATE 42501 (insufficient_privilege)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_firm_a uuid := current_setting('mi109.firm_a')::uuid;
  v_sub_a  uuid := current_setting('mi109.sub_a')::uuid;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  BEGIN
    INSERT INTO public.cs_replacement_authorizations
      (phase_submission_id, firm_id, authorizing_supervisor, authorized_at, reason, submitted_by)
    VALUES
      (v_sub_a, v_firm_a, 'Carlo Domenick', now(),
       'Direct INSERT attempt as authenticated — must fail per Note 4 grant model.',
       v_user_a);
    RESET ROLE;
    RAISE EXCEPTION 'FAIL 1: direct INSERT as authenticated succeeded; Note 4 says no INSERT grant';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RESET ROLE;
      RAISE NOTICE 'PASS 1: direct INSERT as authenticated blocked (insufficient_privilege) — %', SQLERRM;
    WHEN OTHERS THEN
      RESET ROLE;
      IF SQLSTATE = '42501' THEN
        RAISE NOTICE 'PASS 1: direct INSERT blocked (errcode 42501) — %', SQLERRM;
      ELSE
        RAISE EXCEPTION 'FAIL 1: direct INSERT failed for wrong reason (errcode % / %)', SQLSTATE, SQLERRM;
      END IF;
  END;
END $$;

-- -----------------------------------------------------------------------------
-- 2. RPC happy path: user A authorizes own-firm phase submission
--    Expected: jsonb envelope {status:'accepted', authorization_id:<uuid>,
--              error_code:null, message:<text>}
--    Side effect: exactly one row in cs_replacement_authorizations
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_sub_a  uuid := current_setting('mi109.sub_a')::uuid;
  v_envelope jsonb;
  v_status   text;
  v_auth_id  uuid;
  v_count    int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  v_envelope := public.submit_cs_authorization(
    p_phase_submission_id    => v_sub_a,
    p_authorizing_supervisor => 'Carlo Domenick',
    p_authorized_at          => now(),
    p_reason                 => 'RPC happy-path test reason — exceeds twenty character minimum per CDM-Smith rule c.'
  );

  RESET ROLE;

  v_status  := v_envelope->>'status';
  v_auth_id := (v_envelope->>'authorization_id')::uuid;

  IF v_status <> 'accepted' THEN
    RAISE EXCEPTION 'FAIL 2a: envelope.status=% (expected accepted) — full=%', v_status, v_envelope::text;
  END IF;
  IF v_auth_id IS NULL THEN
    RAISE EXCEPTION 'FAIL 2b: envelope.authorization_id is NULL on accepted — full=%', v_envelope::text;
  END IF;
  IF (v_envelope ? 'error_code') AND v_envelope->>'error_code' IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL 2c: envelope.error_code=% on accepted (expected null) — full=%',
      v_envelope->>'error_code', v_envelope::text;
  END IF;
  IF NOT (v_envelope ? 'message') OR v_envelope->>'message' IS NULL THEN
    RAISE EXCEPTION 'FAIL 2d: envelope.message missing or null on accepted — full=%', v_envelope::text;
  END IF;

  SELECT count(*) INTO v_count
    FROM public.cs_replacement_authorizations
   WHERE phase_submission_id = v_sub_a;
  IF v_count <> 1 THEN
    RAISE EXCEPTION 'FAIL 2e: cs_replacement_authorizations row count for sub_a=% (expected 1)', v_count;
  END IF;
  RAISE NOTICE 'PASS 2: RPC accepted — authorization_id=%, row count=1', v_auth_id;
END $$;

-- -----------------------------------------------------------------------------
-- 3. RPC duplicate path: user A retries on same submission
--    Expected: envelope {status:'already_recorded', authorization_id:<existing>,
--              error_code:'ALREADY_RECORDED', message:<text>}
--    Side effect: NO new row (UNIQUE constraint protects)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_sub_a  uuid := current_setting('mi109.sub_a')::uuid;
  v_envelope jsonb;
  v_count_before int;
  v_count_after  int;
BEGIN
  SELECT count(*) INTO v_count_before
    FROM public.cs_replacement_authorizations
   WHERE phase_submission_id = v_sub_a;

  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  v_envelope := public.submit_cs_authorization(
    p_phase_submission_id    => v_sub_a,
    p_authorizing_supervisor => 'Carlo Domenick',
    p_authorized_at          => now(),
    p_reason                 => 'Duplicate retry — RPC must catch 23505 and return already_recorded envelope.'
  );

  RESET ROLE;

  SELECT count(*) INTO v_count_after
    FROM public.cs_replacement_authorizations
   WHERE phase_submission_id = v_sub_a;

  IF v_envelope->>'status' <> 'already_recorded' THEN
    RAISE EXCEPTION 'FAIL 3a: duplicate envelope.status=% (expected already_recorded) — full=%',
      v_envelope->>'status', v_envelope::text;
  END IF;
  IF v_envelope->>'error_code' <> 'ALREADY_RECORDED' THEN
    RAISE EXCEPTION 'FAIL 3b: duplicate envelope.error_code=% (expected ALREADY_RECORDED)',
      v_envelope->>'error_code';
  END IF;
  IF v_count_after <> v_count_before THEN
    RAISE EXCEPTION 'FAIL 3c: duplicate path inserted a row (before=%, after=%)',
      v_count_before, v_count_after;
  END IF;
  RAISE NOTICE 'PASS 3: duplicate envelope correct, no new row';
END $$;

-- -----------------------------------------------------------------------------
-- 4. RPC validation rejection: reason < 20 chars
--    Expected: envelope {status:'rejected', authorization_id:null,
--              error_code:'REASON_TOO_SHORT', message:<text>}
--    Side effect: NO row inserted for sub_b (we use sub_b to keep sub_a clean
--                 since step 2 already populated sub_a)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_b uuid := current_setting('mi109.user_b')::uuid;
  v_sub_b  uuid := current_setting('mi109.sub_b')::uuid;
  v_envelope jsonb;
  v_count int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_b::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  v_envelope := public.submit_cs_authorization(
    p_phase_submission_id    => v_sub_b,
    p_authorizing_supervisor => 'Carlo Domenick',
    p_authorized_at          => now(),
    p_reason                 => 'too short'
  );

  RESET ROLE;

  IF v_envelope->>'status' <> 'rejected' THEN
    RAISE EXCEPTION 'FAIL 4a: rejection envelope.status=% (expected rejected) — full=%',
      v_envelope->>'status', v_envelope::text;
  END IF;
  IF v_envelope->>'error_code' <> 'REASON_TOO_SHORT' THEN
    RAISE EXCEPTION 'FAIL 4b: rejection envelope.error_code=% (expected REASON_TOO_SHORT) — full=%',
      v_envelope->>'error_code', v_envelope::text;
  END IF;
  IF v_envelope->>'authorization_id' IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL 4c: rejection envelope.authorization_id non-null — full=%', v_envelope::text;
  END IF;

  SELECT count(*) INTO v_count
    FROM public.cs_replacement_authorizations
   WHERE phase_submission_id = v_sub_b;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL 4d: rejected path inserted a row for sub_b (count=%)', v_count;
  END IF;
  RAISE NOTICE 'PASS 4: validation rejection envelope correct, no row inserted';
END $$;

-- -----------------------------------------------------------------------------
-- 5. RPC cross-firm: user A attempts to authorize firm-B's submission
--    Two acceptable outcomes per INV-NB11:
--      (i)  envelope {status:'rejected', error_code:'FORBIDDEN_CROSS_FIRM', ...}
--      (ii) RAISE EXCEPTION 'AUTH_DENIED:...' with errcode 42501
--    Side effect: NO row inserted for sub_b
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_sub_b  uuid := current_setting('mi109.sub_b')::uuid;
  v_envelope jsonb;
  v_count int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  BEGIN
    v_envelope := public.submit_cs_authorization(
      p_phase_submission_id    => v_sub_b,
      p_authorizing_supervisor => 'Carlo Domenick',
      p_authorized_at          => now(),
      p_reason                 => 'Cross-firm authorization attempt — RPC must deny by RLS or explicit check.'
    );
    RESET ROLE;

    -- Outcome (i): envelope rejection
    IF v_envelope->>'status' <> 'rejected' THEN
      RAISE EXCEPTION 'FAIL 5a: cross-firm not rejected — envelope=%', v_envelope::text;
    END IF;
    IF v_envelope->>'error_code' NOT IN ('FORBIDDEN_CROSS_FIRM', 'PHASE_SUBMISSION_NOT_FOUND') THEN
      RAISE EXCEPTION 'FAIL 5b: cross-firm error_code=% (expected FORBIDDEN_CROSS_FIRM or PHASE_SUBMISSION_NOT_FOUND)',
        v_envelope->>'error_code';
    END IF;
    RAISE NOTICE 'PASS 5: cross-firm denied via envelope — error_code=%', v_envelope->>'error_code';
  EXCEPTION
    WHEN insufficient_privilege THEN
      -- Outcome (ii): AUTH_DENIED RAISE
      RESET ROLE;
      IF SQLERRM NOT LIKE 'AUTH_DENIED:%' THEN
        RAISE EXCEPTION 'FAIL 5c: insufficient_privilege but message did not start AUTH_DENIED: — %', SQLERRM;
      END IF;
      RAISE NOTICE 'PASS 5: cross-firm denied via AUTH_DENIED RAISE — %', SQLERRM;
    WHEN OTHERS THEN
      RESET ROLE;
      RAISE EXCEPTION 'FAIL 5d: cross-firm raised unexpected error — % / %', SQLSTATE, SQLERRM;
  END;

  SELECT count(*) INTO v_count
    FROM public.cs_replacement_authorizations
   WHERE phase_submission_id = v_sub_b;
  IF v_count <> 0 THEN
    RAISE EXCEPTION 'FAIL 5e: cross-firm path inserted a row for sub_b (count=%)', v_count;
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 6. SELECT under RLS: user A sees only own-firm rows
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_firm_a uuid := current_setting('mi109.firm_a')::uuid;
  v_visible_count   int;
  v_off_firm_count  int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  SELECT count(*) INTO v_visible_count
    FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_off_firm_count
    FROM public.cs_replacement_authorizations
   WHERE firm_id IS DISTINCT FROM v_firm_a;

  RESET ROLE;

  IF v_visible_count < 1 THEN
    RAISE EXCEPTION 'FAIL 6a: user A sees zero rows; expected the row inserted in step 2';
  END IF;
  IF v_off_firm_count <> 0 THEN
    RAISE EXCEPTION 'FAIL 6b: user A sees % off-firm rows (expected 0)', v_off_firm_count;
  END IF;
  RAISE NOTICE 'PASS 6: user A sees only firm A rows (count=%)', v_visible_count;
END $$;

-- -----------------------------------------------------------------------------
-- 7. UPDATE blocked by grant alone (Note 5 — no BEFORE trigger)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_sub_a  uuid := current_setting('mi109.sub_a')::uuid;
  v_row_id uuid;
BEGIN
  SELECT id INTO v_row_id
    FROM public.cs_replacement_authorizations
   WHERE phase_submission_id = v_sub_a
   LIMIT 1;
  IF v_row_id IS NULL THEN
    RAISE EXCEPTION 'FAIL 7-pre: no row to UPDATE — step 2 did not land';
  END IF;

  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  BEGIN
    UPDATE public.cs_replacement_authorizations
       SET reason = 'Tampering attempt — must fail by grant.'
     WHERE id = v_row_id;
    RESET ROLE;
    RAISE EXCEPTION 'FAIL 7: UPDATE succeeded; authenticated has no UPDATE grant';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RESET ROLE;
      RAISE NOTICE 'PASS 7: UPDATE blocked (insufficient_privilege) — %', SQLERRM;
    WHEN OTHERS THEN
      RESET ROLE;
      IF SQLSTATE = '42501' THEN
        RAISE NOTICE 'PASS 7: UPDATE blocked (errcode 42501) — %', SQLERRM;
      ELSE
        RAISE EXCEPTION 'FAIL 7: UPDATE failed for wrong reason (errcode % / %)', SQLSTATE, SQLERRM;
      END IF;
  END;
END $$;

-- -----------------------------------------------------------------------------
-- 8. DELETE blocked by grant alone
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_sub_a  uuid := current_setting('mi109.sub_a')::uuid;
  v_row_id uuid;
BEGIN
  SELECT id INTO v_row_id
    FROM public.cs_replacement_authorizations
   WHERE phase_submission_id = v_sub_a
   LIMIT 1;

  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  BEGIN
    DELETE FROM public.cs_replacement_authorizations WHERE id = v_row_id;
    RESET ROLE;
    RAISE EXCEPTION 'FAIL 8: DELETE succeeded; authenticated has no DELETE grant';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RESET ROLE;
      RAISE NOTICE 'PASS 8: DELETE blocked (insufficient_privilege) — %', SQLERRM;
    WHEN OTHERS THEN
      RESET ROLE;
      IF SQLSTATE = '42501' THEN
        RAISE NOTICE 'PASS 8: DELETE blocked (errcode 42501) — %', SQLERRM;
      ELSE
        RAISE EXCEPTION 'FAIL 8: DELETE failed for wrong reason (errcode % / %)', SQLSTATE, SQLERRM;
      END IF;
  END;
END $$;

-- -----------------------------------------------------------------------------
-- 9. Cross-firm SELECT by row id: seed firm-B row directly as postgres,
--    then attempt to read it as user A through RLS — must be invisible
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_firm_b uuid := current_setting('mi109.firm_b')::uuid;
  v_user_b uuid := current_setting('mi109.user_b')::uuid;
  v_sub_b  uuid := current_setting('mi109.sub_b')::uuid;
  v_row_b  uuid := extensions.gen_random_uuid();
  v_seen   int;
BEGIN
  -- As postgres, bypass grants + RLS to seed a firm-B row.
  INSERT INTO public.cs_replacement_authorizations
    (id, phase_submission_id, firm_id, authorizing_supervisor,
     authorized_at, reason, submitted_by)
  VALUES
    (v_row_b, v_sub_b, v_firm_b, 'Carlo Domenick',
     now(),
     'Firm-B row seeded by postgres for cross-firm SELECT visibility test.',
     v_user_b);

  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  SELECT count(*) INTO v_seen
    FROM public.cs_replacement_authorizations
   WHERE id = v_row_b;

  RESET ROLE;

  IF v_seen <> 0 THEN
    RAISE EXCEPTION 'FAIL 9: user A read firm-B row by id (count=%); RLS leaked', v_seen;
  END IF;
  RAISE NOTICE 'PASS 9: user A cannot read firm-B row by id — RLS holds';
END $$;

-- =============================================================================
-- Cleanup: rollback removes all test fixtures + rows.
-- =============================================================================
ROLLBACK;
