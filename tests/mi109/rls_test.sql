-- =============================================================================
-- MI-109 RLS Test — cs_replacement_authorizations
-- =============================================================================
-- Run as: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f rls_test.sql
-- Or via Supabase CLI: supabase db execute --file tests/mi109/rls_test.sql
--
-- Style: plain-psql DO blocks that RAISE EXCEPTION on assertion failure.
-- Repo has no pgTAP installed; do not introduce one for this ticket.
--
-- FIXTURE ASSUMPTIONS (Jorge: reconcile against live schema before running):
--   1. `firms` table has columns: id (uuid pk), name (text), code (text)
--   2. `profiles` table has columns: id (uuid pk = auth.users.id), firm_id (uuid fk)
--   3. `phase_submissions` table has columns: id (uuid pk), firm_id (uuid fk),
--      property_id (uuid), submitted_by (uuid), phase (text), cs_replacement (bool)
--   4. `cs_replacement_authorizations` table (built by backend teammate) has:
--      id (uuid pk default gen_random_uuid()),
--      submission_id (uuid fk -> phase_submissions),
--      firm_id (uuid fk -> firms),
--      supervisor_name (text default 'Carlo Domenick'),
--      authorized_date (date),
--      authorized_time (time),
--      reason (text CHECK (length(trim(reason)) >= 20)),
--      created_by (uuid),
--      created_at (timestamptz default now())
--   5. RLS is FORCED on cs_replacement_authorizations (per CLAUDE.md MI-200).
--   6. Auth helper auth.uid() / auth.jwt() / auth.role() available (Supabase default).
--   7. A SECURITY DEFINER helper `test_set_user(uuid, text)` is NOT assumed to
--      exist; we use `set_config('request.jwt.claims', ...)` + SET ROLE which
--      Supabase honors for RLS evaluation.
--
-- Cleanup: each test wraps in a SAVEPOINT and rolls back so no rows persist.
-- The outermost BEGIN ... ROLLBACK guarantees zero side effects.
-- =============================================================================

\set ON_ERROR_STOP on
\timing off

BEGIN;

-- ---------------------------------------------------------------------------
-- Setup: two firms, two users, one phase_submission per firm
-- Run as superuser (postgres) so we can bypass RLS for fixture seed.
-- ---------------------------------------------------------------------------
SET LOCAL ROLE postgres;

DO $setup$
DECLARE
  v_firm_a uuid := '11111111-1111-1111-1111-111111111111';
  v_firm_b uuid := '22222222-2222-2222-2222-222222222222';
  v_user_a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  v_user_b uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  v_sub_a  uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  v_sub_b  uuid := 'dddddddd-dddd-dddd-dddd-dddddddddddd';
BEGIN
  -- Firms
  INSERT INTO firms (id, name, code) VALUES
    (v_firm_a, 'TEST_FIRM_A_MI109', 'TEST-A-MI109'),
    (v_firm_b, 'TEST_FIRM_B_MI109', 'TEST-B-MI109')
  ON CONFLICT (id) DO NOTHING;

  -- Profiles (Supabase: profiles.id must equal auth.users.id; in test we just
  -- use raw uuids — Jorge: confirm test env permits orphan profiles or seed
  -- auth.users via supabase admin SQL first.)
  INSERT INTO profiles (id, firm_id) VALUES
    (v_user_a, v_firm_a),
    (v_user_b, v_firm_b)
  ON CONFLICT (id) DO NOTHING;

  -- Phase submissions (one per firm, cs_replacement=true)
  INSERT INTO phase_submissions (id, firm_id, submitted_by, phase, cs_replacement) VALUES
    (v_sub_a, v_firm_a, v_user_a, 'curbstop', true),
    (v_sub_b, v_firm_b, v_user_b, 'curbstop', true)
  ON CONFLICT (id) DO NOTHING;

  -- Pre-seed one auth row in firm B so cross-firm SELECT test has a target
  INSERT INTO cs_replacement_authorizations
    (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
  VALUES
    (v_sub_b, v_firm_b, 'Carlo Domenick', CURRENT_DATE, CURRENT_TIME,
     'Seed row for firm B used by RLS cross-firm isolation test.', v_user_b);
END
$setup$;

-- Helper: simulate authenticated user with a given uid + firm_id (used by RLS)
CREATE OR REPLACE FUNCTION pg_temp.assume_user(p_uid uuid)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', p_uid::text, 'role', 'authenticated')::text, true);
  PERFORM set_config('request.jwt.claim.sub', p_uid::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  EXECUTE 'SET LOCAL ROLE authenticated';
END
$$;

CREATE OR REPLACE FUNCTION pg_temp.assume_anon()
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('role', 'anon')::text, true);
  PERFORM set_config('request.jwt.claim.role', 'anon', true);
  EXECUTE 'SET LOCAL ROLE anon';
END
$$;

CREATE OR REPLACE FUNCTION pg_temp.fail(msg text) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'TEST FAIL: %', msg; END $$;

CREATE OR REPLACE FUNCTION pg_temp.pass(test_name text) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN RAISE NOTICE 'TEST PASS: %', test_name; END $$;


-- ---------------------------------------------------------------------------
-- TEST 1: anon role cannot SELECT from cs_replacement_authorizations
-- ---------------------------------------------------------------------------
SAVEPOINT t1;
DO $t1$
DECLARE v_count int;
BEGIN
  PERFORM pg_temp.assume_anon();
  SELECT count(*) INTO v_count FROM cs_replacement_authorizations;
  IF v_count > 0 THEN
    PERFORM pg_temp.fail('T1: anon SELECT returned ' || v_count || ' rows; expected 0');
  END IF;
  PERFORM pg_temp.pass('T1 anon cannot SELECT cs_replacement_authorizations');
EXCEPTION WHEN insufficient_privilege THEN
  -- Acceptable: hard deny via revoked grants
  PERFORM pg_temp.pass('T1 anon SELECT denied by privilege (also acceptable)');
END
$t1$;
ROLLBACK TO SAVEPOINT t1;


-- ---------------------------------------------------------------------------
-- TEST 2: authenticated user from firm A cannot SELECT firm B rows
-- ---------------------------------------------------------------------------
SAVEPOINT t2;
DO $t2$
DECLARE v_user_a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
        v_firm_b uuid := '22222222-2222-2222-2222-222222222222';
        v_count int;
BEGIN
  PERFORM pg_temp.assume_user(v_user_a);
  SELECT count(*) INTO v_count
    FROM cs_replacement_authorizations
    WHERE firm_id = v_firm_b;
  IF v_count <> 0 THEN
    PERFORM pg_temp.fail('T2: firm A user saw ' || v_count || ' firm B rows');
  END IF;
  PERFORM pg_temp.pass('T2 firm A cannot SELECT firm B rows');
END
$t2$;
ROLLBACK TO SAVEPOINT t2;


-- ---------------------------------------------------------------------------
-- TEST 3: authenticated user CAN INSERT a row matching their firm_id
-- ---------------------------------------------------------------------------
SAVEPOINT t3;
DO $t3$
DECLARE v_user_a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
        v_firm_a uuid := '11111111-1111-1111-1111-111111111111';
        v_sub_a  uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
BEGIN
  PERFORM pg_temp.assume_user(v_user_a);
  INSERT INTO cs_replacement_authorizations
    (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
  VALUES
    (v_sub_a, v_firm_a, 'Carlo Domenick', CURRENT_DATE, CURRENT_TIME,
     'Valid 20+ char reason for the CS replacement authorization test.', v_user_a);
  PERFORM pg_temp.pass('T3 authenticated user INSERT into own firm OK');
END
$t3$;
ROLLBACK TO SAVEPOINT t3;


-- ---------------------------------------------------------------------------
-- TEST 4: authenticated user CANNOT INSERT a row with a different firm_id
-- ---------------------------------------------------------------------------
SAVEPOINT t4;
DO $t4$
DECLARE v_user_a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
        v_firm_b uuid := '22222222-2222-2222-2222-222222222222';
        v_sub_a  uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
        v_inserted boolean := false;
BEGIN
  PERFORM pg_temp.assume_user(v_user_a);
  BEGIN
    INSERT INTO cs_replacement_authorizations
      (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
    VALUES
      (v_sub_a, v_firm_b, 'Carlo Domenick', CURRENT_DATE, CURRENT_TIME,
       'Cross-firm INSERT attempt — RLS must reject this row.', v_user_a);
    v_inserted := true;
  EXCEPTION
    WHEN insufficient_privilege THEN v_inserted := false;
    WHEN check_violation       THEN v_inserted := false;
    WHEN others                THEN
      IF SQLERRM LIKE '%row-level security%' OR SQLERRM LIKE '%violates%' THEN
        v_inserted := false;
      ELSE RAISE;
      END IF;
  END;
  IF v_inserted THEN
    PERFORM pg_temp.fail('T4: cross-firm INSERT was allowed; RLS WITH CHECK missing');
  END IF;
  PERFORM pg_temp.pass('T4 cross-firm INSERT correctly rejected');
END
$t4$;
ROLLBACK TO SAVEPOINT t4;


-- ---------------------------------------------------------------------------
-- TEST 5: UPDATE attempts fail (audit-chain trigger raises)
-- ---------------------------------------------------------------------------
SAVEPOINT t5;
DO $t5$
DECLARE v_user_b uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
        v_firm_b uuid := '22222222-2222-2222-2222-222222222222';
        v_blocked boolean := false;
BEGIN
  PERFORM pg_temp.assume_user(v_user_b);
  BEGIN
    UPDATE cs_replacement_authorizations
       SET reason = 'Tampering attempt — should be blocked by trigger or grant.'
     WHERE firm_id = v_firm_b;
  EXCEPTION
    WHEN insufficient_privilege THEN v_blocked := true;
    WHEN raise_exception        THEN v_blocked := true;
    WHEN others                 THEN
      IF SQLERRM ILIKE '%immutab%' OR SQLERRM ILIKE '%audit%' OR SQLERRM ILIKE '%not allowed%' THEN
        v_blocked := true;
      ELSE RAISE;
      END IF;
  END;
  IF NOT v_blocked THEN
    -- Last-resort check: if no exception fired, the row should still be unchanged
    -- (a no-op grant-revoke would silently update 0 rows; pg raises when grant absent).
    PERFORM pg_temp.fail('T5: UPDATE not blocked — audit chain compromised');
  END IF;
  PERFORM pg_temp.pass('T5 UPDATE blocked by trigger or revoked grant');
END
$t5$;
ROLLBACK TO SAVEPOINT t5;


-- ---------------------------------------------------------------------------
-- TEST 6: DELETE attempts fail (audit-chain trigger raises)
-- ---------------------------------------------------------------------------
SAVEPOINT t6;
DO $t6$
DECLARE v_user_b uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
        v_firm_b uuid := '22222222-2222-2222-2222-222222222222';
        v_blocked boolean := false;
BEGIN
  PERFORM pg_temp.assume_user(v_user_b);
  BEGIN
    DELETE FROM cs_replacement_authorizations WHERE firm_id = v_firm_b;
  EXCEPTION
    WHEN insufficient_privilege THEN v_blocked := true;
    WHEN raise_exception        THEN v_blocked := true;
    WHEN others                 THEN
      IF SQLERRM ILIKE '%immutab%' OR SQLERRM ILIKE '%audit%' OR SQLERRM ILIKE '%not allowed%' THEN
        v_blocked := true;
      ELSE RAISE;
      END IF;
  END;
  IF NOT v_blocked THEN
    PERFORM pg_temp.fail('T6: DELETE not blocked — audit chain compromised');
  END IF;
  PERFORM pg_temp.pass('T6 DELETE blocked by trigger or revoked grant');
END
$t6$;
ROLLBACK TO SAVEPOINT t6;


-- ---------------------------------------------------------------------------
-- TEST 7: anon role cannot INSERT
-- ---------------------------------------------------------------------------
SAVEPOINT t7;
DO $t7$
DECLARE v_firm_a uuid := '11111111-1111-1111-1111-111111111111';
        v_sub_a  uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
        v_inserted boolean := false;
BEGIN
  PERFORM pg_temp.assume_anon();
  BEGIN
    INSERT INTO cs_replacement_authorizations
      (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
    VALUES
      (v_sub_a, v_firm_a, 'Carlo Domenick', CURRENT_DATE, CURRENT_TIME,
       'Anon INSERT attempt — must be rejected by RLS or grant policy.', NULL);
    v_inserted := true;
  EXCEPTION WHEN others THEN v_inserted := false;
  END;
  IF v_inserted THEN
    PERFORM pg_temp.fail('T7: anon INSERT was allowed');
  END IF;
  PERFORM pg_temp.pass('T7 anon INSERT correctly rejected');
END
$t7$;
ROLLBACK TO SAVEPOINT t7;


-- ---------------------------------------------------------------------------
-- TEST 8: CHECK constraint rejects reason text shorter than 20 chars (trimmed)
-- ---------------------------------------------------------------------------
SAVEPOINT t8;
DO $t8$
DECLARE v_user_a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
        v_firm_a uuid := '11111111-1111-1111-1111-111111111111';
        v_sub_a  uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
        v_inserted boolean := false;
BEGIN
  PERFORM pg_temp.assume_user(v_user_a);

  -- 8a: 19 visible chars must fail
  BEGIN
    INSERT INTO cs_replacement_authorizations
      (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
    VALUES
      (v_sub_a, v_firm_a, 'Carlo Domenick', CURRENT_DATE, CURRENT_TIME,
       'too short reason!!', v_user_a);
    v_inserted := true;
  EXCEPTION WHEN check_violation THEN v_inserted := false;
  END;
  IF v_inserted THEN PERFORM pg_temp.fail('T8a: 19-char reason was accepted'); END IF;

  -- 8b: padded whitespace short reason must fail (CHECK uses trim)
  v_inserted := false;
  BEGIN
    INSERT INTO cs_replacement_authorizations
      (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
    VALUES
      (v_sub_a, v_firm_a, 'Carlo Domenick', CURRENT_DATE, CURRENT_TIME,
       '   short reason   ', v_user_a);
    v_inserted := true;
  EXCEPTION WHEN check_violation THEN v_inserted := false;
  END;
  IF v_inserted THEN PERFORM pg_temp.fail('T8b: whitespace-padded short reason accepted'); END IF;

  PERFORM pg_temp.pass('T8 CHECK constraint enforces reason length >= 20 (trimmed)');
END
$t8$;
ROLLBACK TO SAVEPOINT t8;


-- ---------------------------------------------------------------------------
-- All tests passed if we get here without RAISE EXCEPTION.
-- ---------------------------------------------------------------------------
DO $done$ BEGIN RAISE NOTICE '==== MI-109 RLS TEST SUITE: 8/8 PASSED ===='; END $done$;

ROLLBACK;  -- discard all fixture seed; tests are non-destructive
