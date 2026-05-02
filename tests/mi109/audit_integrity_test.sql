-- =============================================================================
-- MI-109 — Audit integrity test (v2)
-- =============================================================================
-- Purpose: prove that submit_cs_authorization produces the expected audit
-- artifacts for accepted, rejected, and already_recorded RPC paths.
--
-- Authority: discovery/whiteboard_override_template.md "Architectural Notes
-- from Jorge" (Notes 2/3) + "Decision log (resolved 2026-05-02 session open)"
-- (INV-1 envelope schema, INV-NB10 compliance event shape, INV-NB11 error
-- code enum).
--
-- Audit chain mechanism (Note 2 + Note 3):
--   - RPC inserts cs_replacement_authorizations row.
--   - write_audit_log AFTER trigger on cs_replacement_authorizations fires
--     and writes audit_log with prev_hash='PENDING', row_hash='PENDING'.
--   - BEFORE INSERT trigger on audit_log overwrites both placeholders with
--     the real hash chain values. Test verifies overwrite happened (no
--     'PENDING' values remain on the new audit_log row).
--   - DO NOT re-implement canonical encoding in this test.
--
-- Compliance event shape (INV-NB10):
--   p_event_type:    'cs_replacement.auth.accepted'
--                  | 'cs_replacement.auth.rejected'
--                  | 'cs_replacement.auth.duplicate'
--   p_severity:      'alert'
--   p_source:        'MI-109'
--   p_correlation_id: phase_submission_id::text
--   p_message:       human-readable
--   p_details jsonb: {phase_submission_id, supervisor, authorized_at,
--                     reason_length, status,
--                     error_code (if rejected/duplicate),
--                     existing_authorization_id (already_recorded only)}
--
-- Validation error_codes (INV-NB11, bare — no VALIDATION_ prefix):
--   REASON_TOO_SHORT, SUPERVISOR_EMPTY, PHASE_SUBMISSION_ID_MISSING,
--   PHASE_SUBMISSION_NOT_FOUND, FORBIDDEN_CROSS_FIRM, AUTHORIZED_AT_MISSING,
--   ALREADY_RECORDED.
--   PHASE_SUBMISSION_ID_MISSING and AUTHORIZED_AT_MISSING are param null/empty
--   checks; PHASE_SUBMISSION_NOT_FOUND is the DB-lookup-miss case.
--
-- Run as: postgres
-- Mode:   single transaction wrapped in BEGIN/ROLLBACK
--
-- !! TESTER ACTION NEEDED — seed-row column shape !!
--   Same as rls_test.sql — minimal seed inserts; extend if NOT NULL columns
--   on firms/phase_submissions are missing.
-- =============================================================================

BEGIN;

SET LOCAL client_min_messages = NOTICE;

-- -----------------------------------------------------------------------------
-- 0. Test fixtures: one firm, one user, two phase_submissions
--    (sub_a for accepted+duplicate paths; sub_b for rejected path)
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_firm uuid := extensions.gen_random_uuid();
  v_user uuid := extensions.gen_random_uuid();
  v_sub_a uuid := extensions.gen_random_uuid();
  v_sub_b uuid := extensions.gen_random_uuid();
BEGIN
  PERFORM set_config('mi109.firm', v_firm::text, true);
  PERFORM set_config('mi109.user', v_user::text, true);
  PERFORM set_config('mi109.sub_a', v_sub_a::text, true);
  PERFORM set_config('mi109.sub_b', v_sub_b::text, true);

  -- TODO: extend column lists if live schema has additional NOT NULL columns.
  INSERT INTO public.firms (id, name, firm_code)
    VALUES (v_firm, 'TEST-FIRM-AUDIT-MI109', 'TEST-AUDIT-MI109');

  INSERT INTO auth.users (id, email, instance_id, aud, role)
    VALUES (v_user, 'audit@mi109.test',
            '00000000-0000-0000-0000-000000000000',
            'authenticated', 'authenticated');

  INSERT INTO public.profiles (id, firm_id, role, full_name)
    VALUES (v_user, v_firm, 'inspector', 'Test Inspector Audit');

  INSERT INTO public.phase_submissions (id, firm_id, cs_replacement)
    VALUES (v_sub_a, v_firm, true),
           (v_sub_b, v_firm, true);

  RAISE NOTICE 'fixtures seeded — firm=%, user=%, sub_a=%, sub_b=%',
    v_firm, v_user, v_sub_a, v_sub_b;
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 1. Snapshot baseline counts before any RPC call
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_auth int; v_audit int; v_compliance int;
BEGIN
  SELECT count(*) INTO v_auth       FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_audit      FROM public.audit_log;
  SELECT count(*) INTO v_compliance FROM public.compliance_events;
  PERFORM set_config('mi109.b_auth',       v_auth::text,       true);
  PERFORM set_config('mi109.b_audit',      v_audit::text,      true);
  PERFORM set_config('mi109.b_compliance', v_compliance::text, true);
  RAISE NOTICE 'baseline — auth=%, audit_log=%, compliance_events=%',
    v_auth, v_audit, v_compliance;
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 2. Accepted RPC call → envelope assertion
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_user uuid := current_setting('mi109.user')::uuid;
  v_sub_a uuid := current_setting('mi109.sub_a')::uuid;
  v_envelope jsonb;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  v_envelope := public.submit_cs_authorization(
    p_phase_submission_id    => v_sub_a,
    p_supervisor_name => 'Carlo Domenick',
    p_authorized_at          => now(),
    p_reason                 => 'Accepted-path audit test — well over twenty characters per CDM-Smith rule c.'
  );
  RESET ROLE;

  IF v_envelope->>'status' <> 'accepted' THEN
    RAISE EXCEPTION 'FAIL 2: accepted envelope.status=% — full=%',
      v_envelope->>'status', v_envelope::text;
  END IF;
  PERFORM set_config('mi109.auth_id', v_envelope->>'authorization_id', true);
  RAISE NOTICE 'PASS 2: accepted envelope — authorization_id=%', v_envelope->>'authorization_id';
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 3. Verify deltas after accepted call:
--    cs_replacement_authorizations +1, audit_log +2 (one for cs_auth INSERT,
--    one for phase_submissions UPDATE — both Owner Data writes audit per
--    CLAUDE.md chain layer 2), compliance_events +1
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_b_auth       int := current_setting('mi109.b_auth')::int;
  v_b_audit      int := current_setting('mi109.b_audit')::int;
  v_b_compliance int := current_setting('mi109.b_compliance')::int;
  v_a_auth       int; v_a_audit int; v_a_compliance int;
BEGIN
  SELECT count(*) INTO v_a_auth       FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_a_audit      FROM public.audit_log;
  SELECT count(*) INTO v_a_compliance FROM public.compliance_events;

  IF v_a_auth <> v_b_auth + 1 THEN
    RAISE EXCEPTION 'FAIL 3a: cs_replacement_authorizations delta=% (expected +1)', v_a_auth - v_b_auth;
  END IF;
  IF v_a_audit <> v_b_audit + 2 THEN
    RAISE EXCEPTION 'FAIL 3b: audit_log delta=% (expected +2: cs_auth INSERT + phase_submissions UPDATE both fire write_audit_log per CLAUDE.md audit chain layer 2)',
      v_a_audit - v_b_audit;
  END IF;
  IF v_a_compliance <> v_b_compliance + 1 THEN
    RAISE EXCEPTION 'FAIL 3c: compliance_events delta=% (expected +1 accepted row)',
      v_a_compliance - v_b_compliance;
  END IF;
  RAISE NOTICE 'PASS 3: deltas correct — auth=+1, audit_log=+2, compliance_events=+1';
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 4. Verify accepted compliance_events row content
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_user uuid := current_setting('mi109.user')::uuid;
  v_sub_a uuid := current_setting('mi109.sub_a')::uuid;
  v_row record;
BEGIN
  SELECT *
    INTO v_row
    FROM public.compliance_events
   WHERE event_type = 'cs_replacement.auth.accepted'
     AND correlation_id = v_sub_a::text
     AND source = 'MI-109'
   ORDER BY created_at DESC
   LIMIT 1;

  IF v_row IS NULL THEN
    RAISE EXCEPTION 'FAIL 4a: no compliance_events row for cs_replacement.auth.accepted / correlation_id=%', v_sub_a;
  END IF;
  IF v_row.severity <> 'alert' THEN
    RAISE EXCEPTION 'FAIL 4b: severity=% (expected alert)', v_row.severity;
  END IF;
  IF v_row.details IS NULL OR jsonb_typeof(v_row.details) <> 'object' THEN
    RAISE EXCEPTION 'FAIL 4c: details missing or not jsonb object — typeof=%',
      jsonb_typeof(v_row.details);
  END IF;
  IF NOT (v_row.details ? 'phase_submission_id') THEN
    RAISE EXCEPTION 'FAIL 4d: details missing phase_submission_id — %', v_row.details::text;
  END IF;
  IF NOT (v_row.details ? 'supervisor') THEN
    RAISE EXCEPTION 'FAIL 4e: details missing supervisor — %', v_row.details::text;
  END IF;
  IF NOT (v_row.details ? 'authorized_at') THEN
    RAISE EXCEPTION 'FAIL 4f: details missing authorized_at — %', v_row.details::text;
  END IF;
  IF NOT (v_row.details ? 'reason_length') THEN
    RAISE EXCEPTION 'FAIL 4g: details missing reason_length — %', v_row.details::text;
  END IF;
  IF NOT (v_row.details ? 'status') THEN
    RAISE EXCEPTION 'FAIL 4h: details missing status — %', v_row.details::text;
  END IF;
  IF v_row.details->>'status' <> 'accepted' THEN
    RAISE EXCEPTION 'FAIL 4i: details.status=% (expected accepted)', v_row.details->>'status';
  END IF;
  RAISE NOTICE 'PASS 4: accepted compliance_events row valid';
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 5. Verify audit_log row written by write_audit_log AFTER trigger:
--    - prev_hash and row_hash are NOT 'PENDING' (chain trigger overwrote)
--    - row_hash matches lowercase hex (sha256-shaped)
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_recent_prev text;
  v_recent_hash text;
BEGIN
  SELECT prev_hash, row_hash
    INTO v_recent_prev, v_recent_hash
    FROM public.audit_log
   ORDER BY created_at DESC, id DESC
   LIMIT 1;

  IF v_recent_prev IS NULL THEN
    RAISE EXCEPTION 'FAIL 5a: prev_hash NULL on newest audit_log row';
  END IF;
  IF v_recent_hash IS NULL THEN
    RAISE EXCEPTION 'FAIL 5b: row_hash NULL on newest audit_log row';
  END IF;
  IF v_recent_prev = 'PENDING' THEN
    RAISE EXCEPTION 'FAIL 5c: prev_hash still PENDING — BEFORE INSERT chain trigger did not overwrite (Note 3)';
  END IF;
  IF v_recent_hash = 'PENDING' THEN
    RAISE EXCEPTION 'FAIL 5d: row_hash still PENDING — chain trigger did not overwrite';
  END IF;
  IF v_recent_hash !~ '^[0-9a-f]+$' THEN
    RAISE EXCEPTION 'FAIL 5e: row_hash not lowercase hex — %', v_recent_hash;
  END IF;
  RAISE NOTICE 'PASS 5: audit_log chain populated — prev=%, hash=%',
    left(v_recent_prev, 12) || '...', left(v_recent_hash, 12) || '...';
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 6. Verify chain link: prev_hash on the new row equals row_hash of the row
--    that immediately precedes it. Computed by SELECT, not by re-encoding.
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_prev text;
  v_predecessor_hash text;
BEGIN
  SELECT prev_hash INTO v_prev
    FROM public.audit_log
   ORDER BY created_at DESC, id DESC
   LIMIT 1;

  SELECT row_hash INTO v_predecessor_hash
    FROM public.audit_log
   ORDER BY created_at DESC, id DESC
   OFFSET 1 LIMIT 1;

  IF v_predecessor_hash IS NULL THEN
    -- audit_log was empty before our insert; prev_hash should be GENESIS seed.
    IF v_prev <> 'GENESIS' THEN
      RAISE EXCEPTION 'FAIL 6a: audit_log was empty pre-insert; expected prev_hash=GENESIS, got %', v_prev;
    END IF;
    RAISE NOTICE 'PASS 6: chain link valid — empty pre-insert, prev_hash=GENESIS';
  ELSE
    IF v_prev <> v_predecessor_hash THEN
      RAISE EXCEPTION 'FAIL 6b: chain break — new prev_hash=% does not match predecessor row_hash=%',
        v_prev, v_predecessor_hash;
    END IF;
    RAISE NOTICE 'PASS 6: chain link valid — new prev_hash matches predecessor row_hash';
  END IF;
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 7. Re-snapshot before rejected call
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_auth int; v_audit int; v_compliance int;
BEGIN
  SELECT count(*) INTO v_auth       FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_audit      FROM public.audit_log;
  SELECT count(*) INTO v_compliance FROM public.compliance_events;
  PERFORM set_config('mi109.r_auth',       v_auth::text,       true);
  PERFORM set_config('mi109.r_audit',      v_audit::text,      true);
  PERFORM set_config('mi109.r_compliance', v_compliance::text, true);
  RAISE NOTICE 'pre-reject snapshot — auth=%, audit_log=%, compliance_events=%',
    v_auth, v_audit, v_compliance;
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 8. Capture phase_submissions.cs_replacement before rejected call
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_sub_b uuid := current_setting('mi109.sub_b')::uuid;
  v_flag boolean;
BEGIN
  SELECT cs_replacement INTO v_flag FROM public.phase_submissions WHERE id = v_sub_b;
  PERFORM set_config('mi109.flag_before', v_flag::text, true);
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 9. Rejected RPC call (reason < 20 chars) — envelope return, no exception.
--    Per INV-1 (envelope pattern), validation must NOT raise. RAISE is reserved
--    for AUTH_DENIED only.
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_user uuid := current_setting('mi109.user')::uuid;
  v_sub_b uuid := current_setting('mi109.sub_b')::uuid;
  v_envelope jsonb;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  v_envelope := public.submit_cs_authorization(
    p_phase_submission_id    => v_sub_b,
    p_supervisor_name => 'Carlo Domenick',
    p_authorized_at          => now(),
    p_reason                 => 'too short'
  );
  RESET ROLE;

  IF v_envelope->>'status' <> 'rejected' THEN
    RAISE EXCEPTION 'FAIL 9a: rejection envelope.status=% (expected rejected) — full=%',
      v_envelope->>'status', v_envelope::text;
  END IF;
  IF v_envelope->>'error_code' <> 'REASON_TOO_SHORT' THEN
    RAISE EXCEPTION 'FAIL 9b: rejection envelope.error_code=% (expected REASON_TOO_SHORT)',
      v_envelope->>'error_code';
  END IF;
  IF v_envelope->>'authorization_id' IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL 9c: rejection envelope.authorization_id non-null — full=%', v_envelope::text;
  END IF;
  RAISE NOTICE 'PASS 9: rejected envelope correct';
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 10. Verify rejection side-effects:
--      cs_replacement_authorizations: +0
--      audit_log: +0 (no row inserted, no chain entry)
--      compliance_events: +1 with event_type 'cs_replacement.auth.rejected'
--      phase_submissions.cs_replacement: unchanged
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_sub_b uuid := current_setting('mi109.sub_b')::uuid;
  v_r_auth       int := current_setting('mi109.r_auth')::int;
  v_r_audit      int := current_setting('mi109.r_audit')::int;
  v_r_compliance int := current_setting('mi109.r_compliance')::int;
  v_a_auth int; v_a_audit int; v_a_compliance int;
  v_flag_before boolean := current_setting('mi109.flag_before')::boolean;
  v_flag_after  boolean;
  v_reject_row  record;
BEGIN
  SELECT count(*) INTO v_a_auth       FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_a_audit      FROM public.audit_log;
  SELECT count(*) INTO v_a_compliance FROM public.compliance_events;
  SELECT cs_replacement INTO v_flag_after FROM public.phase_submissions WHERE id = v_sub_b;

  IF v_a_auth <> v_r_auth THEN
    RAISE EXCEPTION 'FAIL 10a: cs_replacement_authorizations delta=% on rejection (expected 0)',
      v_a_auth - v_r_auth;
  END IF;
  IF v_a_audit <> v_r_audit THEN
    RAISE EXCEPTION 'FAIL 10b: audit_log delta=% on rejection (expected 0)', v_a_audit - v_r_audit;
  END IF;
  IF v_a_compliance <> v_r_compliance + 1 THEN
    RAISE EXCEPTION 'FAIL 10c: compliance_events delta=% on rejection (expected +1) — envelope pattern must persist event',
      v_a_compliance - v_r_compliance;
  END IF;
  IF v_flag_before IS DISTINCT FROM v_flag_after THEN
    RAISE EXCEPTION 'FAIL 10d: phase_submissions.cs_replacement changed (% -> %)',
      v_flag_before, v_flag_after;
  END IF;

  SELECT *
    INTO v_reject_row
    FROM public.compliance_events
   WHERE event_type = 'cs_replacement.auth.rejected'
     AND correlation_id = v_sub_b::text
     AND source = 'MI-109'
   ORDER BY created_at DESC
   LIMIT 1;

  IF v_reject_row IS NULL THEN
    RAISE EXCEPTION 'FAIL 10e: no compliance_events row for cs_replacement.auth.rejected / correlation_id=%', v_sub_b;
  END IF;
  IF v_reject_row.severity <> 'alert' THEN
    RAISE EXCEPTION 'FAIL 10f: rejected severity=% (expected alert)', v_reject_row.severity;
  END IF;
  IF jsonb_typeof(v_reject_row.details) <> 'object' THEN
    RAISE EXCEPTION 'FAIL 10g: rejected details not jsonb object';
  END IF;
  IF v_reject_row.details->>'error_code' <> 'REASON_TOO_SHORT' THEN
    RAISE EXCEPTION 'FAIL 10h: rejected details.error_code=% (expected REASON_TOO_SHORT)',
      v_reject_row.details->>'error_code';
  END IF;
  IF v_reject_row.details->>'status' <> 'rejected' THEN
    RAISE EXCEPTION 'FAIL 10i: rejected details.status=% (expected rejected)', v_reject_row.details->>'status';
  END IF;
  RAISE NOTICE 'PASS 10: rejected compliance_events row valid, no other side effects';
END $TESTBODY$;

-- -----------------------------------------------------------------------------
-- 11. Duplicate path: re-call RPC on sub_a (already authorized in step 2)
--      Expected envelope: {status:'already_recorded', error_code:'ALREADY_RECORDED', ...}
--      Side effects:
--        cs_replacement_authorizations: +0
--        audit_log: +0
--        compliance_events: +1 with event_type 'cs_replacement.auth.duplicate'
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_user uuid := current_setting('mi109.user')::uuid;
  v_sub_a uuid := current_setting('mi109.sub_a')::uuid;
  v_envelope jsonb;
  v_b_auth int; v_b_audit int; v_b_compliance int;
  v_a_auth int; v_a_audit int; v_a_compliance int;
  v_dup_row record;
BEGIN
  SELECT count(*) INTO v_b_auth       FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_b_audit      FROM public.audit_log;
  SELECT count(*) INTO v_b_compliance FROM public.compliance_events;

  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  v_envelope := public.submit_cs_authorization(
    p_phase_submission_id    => v_sub_a,
    p_supervisor_name => 'Carlo Domenick',
    p_authorized_at          => now(),
    p_reason                 => 'Duplicate retry test — RPC must catch 23505 and return already_recorded.'
  );
  RESET ROLE;

  IF v_envelope->>'status' <> 'already_recorded' THEN
    RAISE EXCEPTION 'FAIL 11a: duplicate envelope.status=% (expected already_recorded) — full=%',
      v_envelope->>'status', v_envelope::text;
  END IF;
  IF v_envelope->>'error_code' <> 'ALREADY_RECORDED' THEN
    RAISE EXCEPTION 'FAIL 11b: duplicate envelope.error_code=% (expected ALREADY_RECORDED)',
      v_envelope->>'error_code';
  END IF;

  SELECT count(*) INTO v_a_auth       FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_a_audit      FROM public.audit_log;
  SELECT count(*) INTO v_a_compliance FROM public.compliance_events;

  IF v_a_auth <> v_b_auth THEN
    RAISE EXCEPTION 'FAIL 11c: cs_replacement_authorizations delta=% on duplicate (expected 0)',
      v_a_auth - v_b_auth;
  END IF;
  IF v_a_audit <> v_b_audit THEN
    RAISE EXCEPTION 'FAIL 11d: audit_log delta=% on duplicate (expected 0)', v_a_audit - v_b_audit;
  END IF;
  IF v_a_compliance <> v_b_compliance + 1 THEN
    RAISE EXCEPTION 'FAIL 11e: compliance_events delta=% on duplicate (expected +1)',
      v_a_compliance - v_b_compliance;
  END IF;

  SELECT *
    INTO v_dup_row
    FROM public.compliance_events
   WHERE event_type = 'cs_replacement.auth.duplicate'
     AND correlation_id = v_sub_a::text
     AND source = 'MI-109'
   ORDER BY created_at DESC
   LIMIT 1;

  IF v_dup_row IS NULL THEN
    RAISE EXCEPTION 'FAIL 11f: no compliance_events row for cs_replacement.auth.duplicate / correlation_id=%', v_sub_a;
  END IF;
  IF v_dup_row.severity <> 'alert' THEN
    RAISE EXCEPTION 'FAIL 11g: duplicate severity=% (expected alert)', v_dup_row.severity;
  END IF;
  IF v_dup_row.details->>'error_code' <> 'ALREADY_RECORDED' THEN
    RAISE EXCEPTION 'FAIL 11h: duplicate details.error_code=% (expected ALREADY_RECORDED)',
      v_dup_row.details->>'error_code';
  END IF;
  -- existing_authorization_id is allowed (and expected) on duplicate event_type only.
  IF NOT (v_dup_row.details ? 'existing_authorization_id') THEN
    RAISE EXCEPTION 'FAIL 11i: duplicate details missing existing_authorization_id — %',
      v_dup_row.details::text;
  END IF;
  IF (v_dup_row.details->>'existing_authorization_id') IS NULL THEN
    RAISE EXCEPTION 'FAIL 11j: duplicate details.existing_authorization_id is null';
  END IF;
  -- Should match the envelope.authorization_id (existing row's id, surfaced from the 23505 catch).
  IF v_dup_row.details->>'existing_authorization_id' <> v_envelope->>'authorization_id' THEN
    RAISE EXCEPTION 'FAIL 11k: duplicate details.existing_authorization_id=% does not match envelope.authorization_id=%',
      v_dup_row.details->>'existing_authorization_id', v_envelope->>'authorization_id';
  END IF;
  RAISE NOTICE 'PASS 11: duplicate envelope + compliance_events row valid';
END $TESTBODY$;

-- =============================================================================
-- Cleanup
-- =============================================================================
ROLLBACK;
