-- =============================================================================
-- MI-109 — RLS + INSERT-only-via-grants verification
-- =============================================================================
-- Purpose: prove cs_replacement_authorizations enforces:
--   1. Cross-firm SELECT isolation (firm A user cannot read firm B rows).
--   2. INSERT only via the submit_cs_authorization RPC path; direct table INSERT
--      from authenticated role is allowed by grant but RLS WITH CHECK ties
--      firm_id and created_by to auth.uid() — so the test confirms both the
--      success and the cross-firm-write rejection.
--   3. UPDATE blocked (audit-chain Layer 1 + Layer 2).
--   4. DELETE blocked (audit-chain Layer 1 + Layer 2).
--
-- Run as:  postgres  (the migration uses SET LOCAL ROLE to simulate end-users).
-- Mode:    single transaction wrapped in BEGIN/ROLLBACK — leaves no residue.
--
-- Invariants asserted via DO blocks with RAISE EXCEPTION on mismatch. A clean
-- run prints NOTICE lines per check and ROLLBACK at the bottom. Any RAISE
-- aborts and rolls back automatically.
--
-- ASSUMPTIONS (verify before merge):
--   - public.firms (id uuid PK, name text, firm_code text)
--   - public.profiles (id uuid PK = auth.users.id, firm_id uuid, role text)
--   - public.phase_submissions (id uuid PK, firm_id uuid, cs_replacement bool)
--   - public.cs_replacement_authorizations columns: id, submission_id, firm_id,
--       supervisor_name, authorized_date, authorized_time, reason, created_by,
--       created_at — per Phase 2 backend migration
--   - auth.users seedable directly (Supabase convention; if not, swap to
--       supabase_admin role helper)
--
-- !! TESTER ACTION NEEDED — seed-row column shape !!
--   The fixture inserts in step 0 use a minimal column set. If `firms` or
--   `phase_submissions` have NOT NULL columns beyond what's listed
--   (likely candidates on phase_submissions: phase, property_id, created_by,
--   submitted_at, etc.), this test will fail at the seed step. Two options:
--     (a) Run \d public.firms and \d public.phase_submissions, extend the
--         INSERT lists with required defaults.
--     (b) Replace the seed block with calls to existing test fixture helpers
--         if MI-200 / MI-202 shipped any.
--   Tagged TODO in the seed block.
--
-- TODO (resolve when Q1, Q8-Q10 land):
--   - Hash-chain link assertions live in audit_integrity_test.sql, not here.
--   - If submit_cs_authorization RPC takes a different parameter shape than
--     {p_submission_id, p_supervisor_name, p_authorized_date, p_authorized_time,
--     p_reason}, update the rpc_call test block at the bottom.
-- =============================================================================

BEGIN;

-- Make NOTICE output more readable.
SET LOCAL client_min_messages = NOTICE;

-- -----------------------------------------------------------------------------
-- 0. Test fixtures: two firms, one user each, one phase_submission per firm
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_firm_a uuid := gen_random_uuid();
  v_firm_b uuid := gen_random_uuid();
  v_user_a uuid := gen_random_uuid();
  v_user_b uuid := gen_random_uuid();
  v_sub_a  uuid := gen_random_uuid();
  v_sub_b  uuid := gen_random_uuid();
BEGIN
  -- Stash for downstream blocks.
  PERFORM set_config('mi109.firm_a',  v_firm_a::text, true);
  PERFORM set_config('mi109.firm_b',  v_firm_b::text, true);
  PERFORM set_config('mi109.user_a',  v_user_a::text, true);
  PERFORM set_config('mi109.user_b',  v_user_b::text, true);
  PERFORM set_config('mi109.sub_a',   v_sub_a::text,  true);
  PERFORM set_config('mi109.sub_b',   v_sub_b::text,  true);

  -- TODO: extend column lists below to match live schema if these inserts
  -- fail with NOT NULL violations. Likely additions:
  --   firms: created_at default ok; otherwise add (created_at, ...)
  --   phase_submissions: phase, property_id, created_by, submitted_at — confirm
  --     against \d public.phase_submissions before running on staging.
  INSERT INTO public.firms (id, name, firm_code)
    VALUES (v_firm_a, 'TEST-FIRM-A-MI109', 'TEST-A-MI109'),
           (v_firm_b, 'TEST-FIRM-B-MI109', 'TEST-B-MI109');

  -- auth.users seed — minimal columns needed for FK resolution.
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
-- 1. As user A: INSERT into cs_replacement_authorizations with firm_id=A
--    Expected: success (RLS WITH CHECK satisfied)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_firm_a uuid := current_setting('mi109.firm_a')::uuid;
  v_sub_a  uuid := current_setting('mi109.sub_a')::uuid;
  v_new_id uuid;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  INSERT INTO public.cs_replacement_authorizations
    (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
  VALUES
    (v_sub_a, v_firm_a, 'Carlo Domenick', current_date, current_time::time,
     'CS replacement required because curbstop sheared during excavation per CDM-Smith rule c.',
     v_user_a)
  RETURNING id INTO v_new_id;

  PERFORM set_config('mi109.row_a', v_new_id::text, true);
  RESET ROLE;
  RAISE NOTICE 'PASS 1: user A inserted cs_replacement_authorizations id=%', v_new_id;
EXCEPTION WHEN OTHERS THEN
  RESET ROLE;
  RAISE EXCEPTION 'FAIL 1: user A INSERT for own firm rejected — % / %', SQLSTATE, SQLERRM;
END $$;

-- -----------------------------------------------------------------------------
-- 2. As user A: INSERT with firm_id=B (cross-firm write attempt)
--    Expected: failure — RLS WITH CHECK violation (errcode 42501)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_firm_b uuid := current_setting('mi109.firm_b')::uuid;
  v_sub_b  uuid := current_setting('mi109.sub_b')::uuid;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  BEGIN
    INSERT INTO public.cs_replacement_authorizations
      (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
    VALUES
      (v_sub_b, v_firm_b, 'Carlo Domenick', current_date, current_time::time,
       'Attempted cross-firm write — should be blocked by RLS WITH CHECK.',
       v_user_a);
    RESET ROLE;
    RAISE EXCEPTION 'FAIL 2: cross-firm INSERT succeeded (RLS WITH CHECK should have blocked)';
  EXCEPTION
    WHEN insufficient_privilege OR check_violation THEN
      RESET ROLE;
      RAISE NOTICE 'PASS 2: cross-firm INSERT blocked — %', SQLERRM;
    WHEN OTHERS THEN
      RESET ROLE;
      -- RLS violation in PG raises errcode 42501; some setups raise 42501 with
      -- 'new row violates row-level security policy' message.
      IF SQLSTATE = '42501' THEN
        RAISE NOTICE 'PASS 2: cross-firm INSERT blocked (errcode 42501) — %', SQLERRM;
      ELSE
        RAISE EXCEPTION 'FAIL 2: cross-firm INSERT failed for wrong reason (errcode % / %)', SQLSTATE, SQLERRM;
      END IF;
  END;
END $$;

-- -----------------------------------------------------------------------------
-- 3. As user A: SELECT — sees only firm A rows
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_firm_a uuid := current_setting('mi109.firm_a')::uuid;
  v_visible_count int;
  v_off_firm_count int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  SELECT count(*) INTO v_visible_count
    FROM public.cs_replacement_authorizations;
  SELECT count(*) INTO v_off_firm_count
    FROM public.cs_replacement_authorizations
    WHERE firm_id <> v_firm_a;

  RESET ROLE;

  IF v_visible_count < 1 THEN
    RAISE EXCEPTION 'FAIL 3: user A sees zero rows; expected at least the row inserted in step 1';
  END IF;
  IF v_off_firm_count <> 0 THEN
    RAISE EXCEPTION 'FAIL 3: user A sees % off-firm rows; expected 0', v_off_firm_count;
  END IF;
  RAISE NOTICE 'PASS 3: user A sees only firm A rows (count=%)', v_visible_count;
END $$;

-- -----------------------------------------------------------------------------
-- 4. As user A: UPDATE on own row — must fail (no UPDATE grant + Layer 2 trigger)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_row_a  uuid := current_setting('mi109.row_a')::uuid;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  BEGIN
    UPDATE public.cs_replacement_authorizations
       SET reason = 'Tampering attempt — should fail.'
     WHERE id = v_row_a;
    RESET ROLE;
    RAISE EXCEPTION 'FAIL 4: UPDATE succeeded; INSERT-only grant + Layer 2 trigger should have blocked';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RESET ROLE;
      RAISE NOTICE 'PASS 4: UPDATE blocked (insufficient_privilege) — %', SQLERRM;
    WHEN OTHERS THEN
      RESET ROLE;
      IF SQLSTATE IN ('42501') THEN
        RAISE NOTICE 'PASS 4: UPDATE blocked (errcode 42501) — %', SQLERRM;
      ELSE
        RAISE EXCEPTION 'FAIL 4: UPDATE failed for wrong reason (errcode % / %)', SQLSTATE, SQLERRM;
      END IF;
  END;
END $$;

-- -----------------------------------------------------------------------------
-- 5. As user A: DELETE on own row — must fail
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_row_a  uuid := current_setting('mi109.row_a')::uuid;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  BEGIN
    DELETE FROM public.cs_replacement_authorizations WHERE id = v_row_a;
    RESET ROLE;
    RAISE EXCEPTION 'FAIL 5: DELETE succeeded; INSERT-only grant + Layer 2 trigger should have blocked';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RESET ROLE;
      RAISE NOTICE 'PASS 5: DELETE blocked (insufficient_privilege) — %', SQLERRM;
    WHEN OTHERS THEN
      RESET ROLE;
      IF SQLSTATE = '42501' THEN
        RAISE NOTICE 'PASS 5: DELETE blocked (errcode 42501) — %', SQLERRM;
      ELSE
        RAISE EXCEPTION 'FAIL 5: DELETE failed for wrong reason (errcode % / %)', SQLSTATE, SQLERRM;
      END IF;
  END;
END $$;

-- -----------------------------------------------------------------------------
-- 6. As user A: SELECT a known firm B row id directly — must return 0 rows
--     (we seed a row directly as postgres so the id exists, then attempt to
--      read it as user A through RLS)
-- -----------------------------------------------------------------------------
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_firm_b uuid := current_setting('mi109.firm_b')::uuid;
  v_user_b uuid := current_setting('mi109.user_b')::uuid;
  v_sub_b  uuid := current_setting('mi109.sub_b')::uuid;
  v_row_b  uuid := gen_random_uuid();
  v_seen   int;
BEGIN
  -- Bypass RLS as postgres to seed the firm B row.
  INSERT INTO public.cs_replacement_authorizations
    (id, submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
  VALUES
    (v_row_b, v_sub_b, v_firm_b, 'Carlo Domenick', current_date, current_time::time,
     'Firm B row seeded for cross-firm read test — should not be visible to user A.',
     v_user_b);

  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  SELECT count(*) INTO v_seen
    FROM public.cs_replacement_authorizations
   WHERE id = v_row_b;

  RESET ROLE;

  IF v_seen <> 0 THEN
    RAISE EXCEPTION 'FAIL 6: user A read firm B row by id (count=%); RLS should have hidden it', v_seen;
  END IF;
  RAISE NOTICE 'PASS 6: user A cannot read firm B row by id (count=0)';
END $$;

-- -----------------------------------------------------------------------------
-- 7. RPC happy path: as user A, call submit_cs_authorization on firm A submission
--    Expected: success (returns uuid OR jsonb envelope per Contract 4 — assert
--    on side-effect: row exists in cs_replacement_authorizations afterwards)
-- -----------------------------------------------------------------------------
-- TODO (Q1 deferred): once record_whiteboard_override pattern lands, decide
-- whether submit_cs_authorization returns uuid or jsonb envelope. For now we
-- assert on the row existing post-call rather than the return shape.
DO $$
DECLARE
  v_user_a uuid := current_setting('mi109.user_a')::uuid;
  v_firm_a uuid := current_setting('mi109.firm_a')::uuid;
  v_sub_a  uuid := current_setting('mi109.sub_a')::uuid;
  v_count_before int;
  v_count_after  int;
BEGIN
  SELECT count(*) INTO v_count_before
    FROM public.cs_replacement_authorizations
   WHERE submission_id = v_sub_a;

  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE format('SET LOCAL ROLE authenticated');

  PERFORM public.submit_cs_authorization(
    p_submission_id   => v_sub_a,
    p_supervisor_name => 'Carlo Domenick',
    p_authorized_date => current_date,
    p_authorized_time => current_time::time,
    p_reason          => 'RPC happy-path test — reason is at least twenty characters per validation rule.'
  );

  RESET ROLE;

  SELECT count(*) INTO v_count_after
    FROM public.cs_replacement_authorizations
   WHERE submission_id = v_sub_a;

  IF v_count_after <> v_count_before + 1 THEN
    RAISE EXCEPTION 'FAIL 7: RPC happy path did not insert exactly one row (before=%, after=%)',
      v_count_before, v_count_after;
  END IF;
  RAISE NOTICE 'PASS 7: RPC inserted one row (before=%, after=%)', v_count_before, v_count_after;
END $$;

-- =============================================================================
-- Cleanup: rollback removes all test fixtures + rows.
-- =============================================================================
ROLLBACK;
