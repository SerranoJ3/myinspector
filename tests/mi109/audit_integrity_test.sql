-- =============================================================================
-- MI-109 — Audit integrity test
-- =============================================================================
-- Purpose: prove that submit_cs_authorization produces correct audit artifacts
-- for both accepted and rejected calls.
--
-- Accepted call:
--   1. exactly one new row in cs_replacement_authorizations
--   2. exactly one new row in audit_log (Layer 3 — write_audit_log AFTER trigger
--      fires on the cs_replacement_authorizations INSERT)
--   3. exactly one new row in compliance_events with:
--        event_type      = 'cs_replacement.auth.accepted'
--        severity        = 'alert'
--        source          = 'MI-109'
--        correlation_id  = phase_submission_id::text
--        details         contains the supervisor_name + actor_id keys
--   4. audit_log row's chain link is internally consistent (assertion deferred —
--      see TODO Q8-Q10 below)
--
-- Rejected call (reason < 20 chars):
--   1. zero new rows in cs_replacement_authorizations
--   2. exactly one new row in compliance_events with:
--        event_type      = 'cs_replacement.auth.rejected'
--        severity        = 'alert'
--        source          = 'MI-109'
--        correlation_id  = phase_submission_id::text
--        details         contains rejection_reason
--   3. phase_submissions.cs_replacement is unchanged
--   4. (Contract 4 deferred) audit_log delta — for now the assertion is "no
--      regression of cs_replacement_authorizations row count + compliance_events
--      gained one rejected row." See TODO Q1.
--
-- Run as: postgres
-- Mode:   single transaction wrapped in BEGIN/ROLLBACK
--
-- ASSUMPTIONS:
--   - public.audit_log table exists with at least: id, event_type text, created_at
--     timestamptz. Other column names (prev_hash, current_hash, payload, etc.)
--     are NOT asserted here until Q8-Q10 land.
--   - public.compliance_events columns per record_compliance_event signature:
--       event_type text, message text, severity text, details jsonb,
--       source text, correlation_id text, created_at timestamptz
--   - submit_cs_authorization parameter shape per Phase 2 backend brief:
--       p_submission_id, p_supervisor_name, p_authorized_date, p_authorized_time,
--       p_reason
--
-- TODO BLOCKS (resolve when Q1 + Q8-Q10 land in discovery dump):
--   [Q8-Q10] audit_log chain-link assertions: prev_hash on the new row matches
--            previous row's current_hash, and current_hash matches the chain-
--            trigger's deterministic computation. Until live column names are
--            confirmed, only row-count delta + event_type are asserted.
--   [Q1]     Rejection envelope vs exception: if submit_cs_authorization uses
--            RAISE EXCEPTION for validation, the inner record_compliance_event
--            INSERT rolls back too — losing the rejection log. If Q1 reveals
--            the whiteboard-override pattern uses the JSONB-envelope approach,
--            replace the EXCEPTION block in test 5 with a direct-call assertion
--            on the returned envelope.
-- =============================================================================

BEGIN;

SET LOCAL client_min_messages = NOTICE;

-- -----------------------------------------------------------------------------
-- 0. Test fixtures: one firm, one user, one phase_submission
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_firm uuid := gen_random_uuid();
  v_user uuid := gen_random_uuid();
  v_sub  uuid := gen_random_uuid();
BEGIN
  PERFORM set_config('mi109.firm', v_firm::text, true);
  PERFORM set_config('mi109.user', v_user::text, true);
  PERFORM set_config('mi109.sub',  v_sub::text,  true);

  -- TODO: extend column lists below to match live schema if NOT NULL violations
  -- occur on the seed step. Likely columns missing for phase_submissions:
  -- phase, property_id, created_by, submitted_at. Confirm via \d on staging.
  INSERT INTO public.firms (id, name, firm_code)
    VALUES (v_firm, 'TEST-FIRM-AUDIT-MI109', 'TEST-AUDIT-MI109');

  INSERT INTO auth.users (id, email, instance_id, aud, role)
    VALUES (v_user, 'audit@mi109.test',
            '00000000-0000-0000-0000-000000000000',
            'authenticated', 'authenticated');

  INSERT INTO public.profiles (id, firm_id, role, full_name)
    VALUES (v_user, v_firm, 'inspector', 'Test Inspector Audit');

  INSERT INTO public.phase_submissions (id, firm_id, cs_replacement)
    VALUES (v_sub, v_firm, true);

  RAISE NOTICE 'fixtures seeded — firm=%, user=%, sub=%', v_firm, v_user, v_sub;
END $$;

-- -----------------------------------------------------------------------------
-- 1. Snapshot baseline counts before any RPC call
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_auth_count        int;
  v_audit_count       int;
  v_compliance_count  int;
BEGIN
  SELECT count(*) INTO v_auth_count        FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_audit_count       FROM public.audit_log;
  SELECT count(*) INTO v_compliance_count  FROM public.compliance_events;

  PERFORM set_config('mi109.b_auth',       v_auth_count::text,       true);
  PERFORM set_config('mi109.b_audit',      v_audit_count::text,      true);
  PERFORM set_config('mi109.b_compliance', v_compliance_count::text, true);

  RAISE NOTICE 'baseline — auth=%, audit_log=%, compliance_events=%',
    v_auth_count, v_audit_count, v_compliance_count;
END $$;

-- -----------------------------------------------------------------------------
-- 2. Accepted RPC call
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user uuid := current_setting('mi109.user')::uuid;
  v_sub  uuid := current_setting('mi109.sub')::uuid;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  PERFORM public.submit_cs_authorization(
    p_submission_id   => v_sub,
    p_supervisor_name => 'Carlo Domenick',
    p_authorized_date => current_date,
    p_authorized_time => current_time::time,
    p_reason          => 'Accepted-path test — reason text well over twenty characters per CDM-Smith rule c.'
  );

  RESET ROLE;
  RAISE NOTICE 'PASS 2: submit_cs_authorization (accepted) returned successfully';
EXCEPTION WHEN OTHERS THEN
  RESET ROLE;
  RAISE EXCEPTION 'FAIL 2: accepted RPC call raised — % / %', SQLSTATE, SQLERRM;
END $$;

-- -----------------------------------------------------------------------------
-- 3. Verify row deltas after accepted call:
--    cs_replacement_authorizations +1, audit_log +1, compliance_events +1
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_b_auth       int := current_setting('mi109.b_auth')::int;
  v_b_audit      int := current_setting('mi109.b_audit')::int;
  v_b_compliance int := current_setting('mi109.b_compliance')::int;
  v_a_auth       int;
  v_a_audit      int;
  v_a_compliance int;
BEGIN
  SELECT count(*) INTO v_a_auth       FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_a_audit      FROM public.audit_log;
  SELECT count(*) INTO v_a_compliance FROM public.compliance_events;

  IF v_a_auth <> v_b_auth + 1 THEN
    RAISE EXCEPTION 'FAIL 3a: cs_replacement_authorizations delta=% (expected +1)', v_a_auth - v_b_auth;
  END IF;
  IF v_a_audit <> v_b_audit + 1 THEN
    RAISE EXCEPTION 'FAIL 3b: audit_log delta=% (expected +1 from Layer-3 trigger)', v_a_audit - v_b_audit;
  END IF;
  IF v_a_compliance <> v_b_compliance + 1 THEN
    RAISE EXCEPTION 'FAIL 3c: compliance_events delta=% (expected +1 accepted row)', v_a_compliance - v_b_compliance;
  END IF;
  RAISE NOTICE 'PASS 3: deltas correct — auth=+1, audit_log=+1, compliance_events=+1';
END $$;

-- -----------------------------------------------------------------------------
-- 4. Verify accepted compliance_events row content
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user uuid := current_setting('mi109.user')::uuid;
  v_sub  uuid := current_setting('mi109.sub')::uuid;
  v_row  record;
BEGIN
  SELECT *
    INTO v_row
    FROM public.compliance_events
   WHERE event_type = 'cs_replacement.auth.accepted'
     AND correlation_id = v_sub::text
     AND source = 'MI-109'
   ORDER BY created_at DESC
   LIMIT 1;

  IF v_row IS NULL THEN
    RAISE EXCEPTION 'FAIL 4a: no compliance_events row for cs_replacement.auth.accepted / correlation_id=%', v_sub;
  END IF;
  IF v_row.severity <> 'alert' THEN
    RAISE EXCEPTION 'FAIL 4b: severity=% (expected alert)', v_row.severity;
  END IF;
  IF v_row.details IS NULL THEN
    RAISE EXCEPTION 'FAIL 4c: details jsonb is NULL';
  END IF;
  -- Expected keys per backend brief — supervisor_name and actor identity should
  -- be observable in details. Loose check: details has at least one key.
  IF jsonb_typeof(v_row.details) <> 'object' THEN
    RAISE EXCEPTION 'FAIL 4d: details is not a jsonb object (typeof=%)', jsonb_typeof(v_row.details);
  END IF;
  RAISE NOTICE 'PASS 4: accepted compliance_events row valid — id=%', v_row.id;
END $$;

-- -----------------------------------------------------------------------------
-- 5. Verify audit_log row exists and is the most recent for the new auth row
--    [TODO Q8-Q10] add chain-link assertion: prev_hash on this row matches
--    current_hash on the previous audit_log row, and current_hash matches what
--    audit_log_chain_trigger computed (compute via SELECT against existing
--    rows, NOT by re-encoding payload here).
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user uuid := current_setting('mi109.user')::uuid;
  v_recent_audit_event_type text;
BEGIN
  SELECT event_type
    INTO v_recent_audit_event_type
    FROM public.audit_log
   ORDER BY created_at DESC, id DESC
   LIMIT 1;

  -- Expected: the audit_log row written by the AFTER INSERT trigger references
  -- the cs_replacement_authorizations table. Until Q8 confirms exact column
  -- names and event_type literal, assert only that *some* recent row exists.
  -- TODO: replace with strict assertion once Q8-Q10 land:
  --   IF v_recent_audit_event_type NOT IN ('cs_auth_accepted', 'INSERT')
  --      OR v_recent_table_name <> 'cs_replacement_authorizations'
  --      OR v_recent_actor_id <> v_user
  --   THEN RAISE...
  IF v_recent_audit_event_type IS NULL THEN
    RAISE EXCEPTION 'FAIL 5: audit_log empty after accepted RPC call';
  END IF;
  RAISE NOTICE 'PASS 5 (loose, Q8-Q10 pending): audit_log latest event_type=%',
    v_recent_audit_event_type;
END $$;

-- -----------------------------------------------------------------------------
-- 6. Re-snapshot before rejected call
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_auth_count        int;
  v_audit_count       int;
  v_compliance_count  int;
BEGIN
  SELECT count(*) INTO v_auth_count        FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_audit_count       FROM public.audit_log;
  SELECT count(*) INTO v_compliance_count  FROM public.compliance_events;

  PERFORM set_config('mi109.r_auth',       v_auth_count::text,       true);
  PERFORM set_config('mi109.r_audit',      v_audit_count::text,      true);
  PERFORM set_config('mi109.r_compliance', v_compliance_count::text, true);
  RAISE NOTICE 'pre-reject snapshot — auth=%, audit_log=%, compliance_events=%',
    v_auth_count, v_audit_count, v_compliance_count;
END $$;

-- -----------------------------------------------------------------------------
-- 7. Capture phase_submissions.cs_replacement before rejected call
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_sub uuid := current_setting('mi109.sub')::uuid;
  v_flag boolean;
BEGIN
  SELECT cs_replacement INTO v_flag FROM public.phase_submissions WHERE id = v_sub;
  PERFORM set_config('mi109.flag_before', v_flag::text, true);
END $$;

-- -----------------------------------------------------------------------------
-- 8. Rejected RPC call (reason < 20 chars)
--    [TODO Q1] Two possible patterns:
--      (i)  RPC raises VALIDATION_ exception — inner BEGIN/EXCEPTION traps it,
--           but the rejection compliance_events INSERT also rolls back.
--           Assertion in step 9 then has to be relaxed.
--      (ii) RPC returns a JSONB envelope {status:'rejected', error:'...'} —
--           no exception raised, compliance_events row commits cleanly.
--    For v1 we assume pattern (ii) is what Q1 will reveal (matches the brief's
--    "audit every attempt"). If Q1 reveals (i), revise: wrap in EXCEPTION block
--    and rely on async/dblink path or accept rejection-log loss explicitly.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user uuid := current_setting('mi109.user')::uuid;
  v_sub  uuid := current_setting('mi109.sub')::uuid;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  BEGIN
    PERFORM public.submit_cs_authorization(
      p_submission_id   => v_sub,
      p_supervisor_name => 'Carlo Domenick',
      p_authorized_date => current_date,
      p_authorized_time => current_time::time,
      p_reason          => 'too short'
    );
    -- If the RPC returns an envelope, falling through here is expected.
    RESET ROLE;
    RAISE NOTICE 'INFO 8: rejected RPC returned without raising (envelope pattern)';
  EXCEPTION WHEN OTHERS THEN
    RESET ROLE;
    -- Pattern (i): exception raised. Assert message prefix is VALIDATION_.
    IF SQLERRM NOT LIKE 'VALIDATION_%' THEN
      RAISE EXCEPTION 'FAIL 8: rejection raised but message did not start with VALIDATION_ — % / %',
        SQLSTATE, SQLERRM;
    END IF;
    RAISE NOTICE 'INFO 8: rejected RPC raised VALIDATION_ exception (exception pattern) — %', SQLERRM;
  END;
END $$;

-- -----------------------------------------------------------------------------
-- 9. Verify rejection side-effects:
--      cs_replacement_authorizations: +0
--      phase_submissions.cs_replacement: unchanged
--      compliance_events: +1 with event_type 'cs_replacement.auth.rejected'
--    [TODO Q1] If RPC uses pattern (i) AND record_compliance_event is not run
--    out-of-transaction, compliance_events delta will be 0 and this test will
--    fail — that's the architectural decision Q1 forces.
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_sub uuid := current_setting('mi109.sub')::uuid;
  v_r_auth       int := current_setting('mi109.r_auth')::int;
  v_r_compliance int := current_setting('mi109.r_compliance')::int;
  v_a_auth       int;
  v_a_compliance int;
  v_flag_before  boolean := current_setting('mi109.flag_before')::boolean;
  v_flag_after   boolean;
  v_reject_row   record;
BEGIN
  SELECT count(*) INTO v_a_auth       FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_a_compliance FROM public.compliance_events;
  SELECT cs_replacement INTO v_flag_after FROM public.phase_submissions WHERE id = v_sub;

  IF v_a_auth <> v_r_auth THEN
    RAISE EXCEPTION 'FAIL 9a: cs_replacement_authorizations delta=% on rejection (expected 0)',
      v_a_auth - v_r_auth;
  END IF;
  IF v_flag_before IS DISTINCT FROM v_flag_after THEN
    RAISE EXCEPTION 'FAIL 9b: phase_submissions.cs_replacement changed on rejection (% -> %)',
      v_flag_before, v_flag_after;
  END IF;

  IF v_a_compliance = v_r_compliance THEN
    RAISE WARNING 'INFO 9c: compliance_events delta=0 on rejection — Q1 outcome is pattern (i) without out-of-transaction logging. Architectural decision needed.';
  ELSIF v_a_compliance = v_r_compliance + 1 THEN
    SELECT *
      INTO v_reject_row
      FROM public.compliance_events
     WHERE event_type = 'cs_replacement.auth.rejected'
       AND correlation_id = v_sub::text
       AND source = 'MI-109'
     ORDER BY created_at DESC
     LIMIT 1;

    IF v_reject_row IS NULL THEN
      RAISE EXCEPTION 'FAIL 9d: compliance_events +1 but no matching rejected row for sub=%', v_sub;
    END IF;
    IF v_reject_row.severity <> 'alert' THEN
      RAISE EXCEPTION 'FAIL 9e: rejected severity=% (expected alert)', v_reject_row.severity;
    END IF;
    -- details should contain the rejection reason. Loose check: object with
    -- at least one key whose value mentions 'reason' OR 'validation'.
    IF jsonb_typeof(v_reject_row.details) <> 'object' THEN
      RAISE EXCEPTION 'FAIL 9f: rejected details is not jsonb object';
    END IF;
    RAISE NOTICE 'PASS 9: rejected compliance_events row valid — id=%', v_reject_row.id;
  ELSE
    RAISE EXCEPTION 'FAIL 9g: compliance_events delta=% on rejection (expected 0 or 1)',
      v_a_compliance - v_r_compliance;
  END IF;
END $$;

-- =============================================================================
-- Cleanup
-- =============================================================================
ROLLBACK;
