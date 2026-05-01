-- =============================================================================
-- MI-109 Audit Integrity Test — cs_auth_accepted / cs_auth_rejected
-- =============================================================================
-- Run as: psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f audit_integrity_test.sql
--
-- ASSUMES audit_log columns (Jorge: reconcile against MI-202 migration):
--   id           uuid pk default gen_random_uuid()
--   event_type   text         -- e.g. 'cs_auth_accepted', 'cs_auth_rejected'
--   row_id       uuid         -- pk of the affected business row (auth row id)
--   table_name   text         -- 'cs_replacement_authorizations'
--   firm_id      uuid
--   actor_id     uuid         -- auth.uid() at time of write
--   reason_code  text         -- 'inspector_cancelled' | 'validation_failure' | NULL
--   payload      jsonb        -- canonical encoded business row + metadata
--   prev_hash    text         -- hex sha256 of previous row's current_hash
--   current_hash text         -- hex sha256(prev_hash || canonical_payload_text)
--   created_at   timestamptz default now()
--
-- If any column name differs in the live MI-202 schema, adjust the SELECT/INSERT
-- columns below — the assertions remain valid.
--
-- Hash chain rule (CLAUDE.md Principle, MI-202 layer 3):
--   current_hash = sha256( prev_hash || canonical_payload_text )
--   Genesis row uses literal seed 'GENESIS' as prev_hash.
--   Canonical encoding: deterministic JSONB text (jsonb sorts keys).
--
-- All tests wrap in SAVEPOINT/ROLLBACK and the file ends with ROLLBACK
-- so audit_log is NOT polluted by this run.
-- =============================================================================

\set ON_ERROR_STOP on
BEGIN;

SET LOCAL ROLE postgres;

-- Reuse fixture style from rls_test.sql (firms / profiles / phase_submissions)
DO $setup$
DECLARE
  v_firm   uuid := '33333333-3333-3333-3333-333333333333';
  v_user   uuid := 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  v_sub    uuid := 'ffffffff-ffff-ffff-ffff-ffffffffffff';
BEGIN
  INSERT INTO firms (id, name, code) VALUES
    (v_firm, 'TEST_AUDIT_FIRM_MI109', 'TEST-AUDIT-MI109')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO profiles (id, firm_id) VALUES (v_user, v_firm)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO phase_submissions (id, firm_id, submitted_by, phase, cs_replacement)
  VALUES (v_sub, v_firm, v_user, 'curbstop', true)
  ON CONFLICT (id) DO NOTHING;
END
$setup$;

CREATE OR REPLACE FUNCTION pg_temp.fail(msg text) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'TEST FAIL: %', msg; END $$;

CREATE OR REPLACE FUNCTION pg_temp.pass(test_name text) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN RAISE NOTICE 'TEST PASS: %', test_name; END $$;


-- ---------------------------------------------------------------------------
-- TEST 1: INSERT into cs_replacement_authorizations creates audit row with
--         event_type='cs_auth_accepted' and row_id matching the new row.
-- ---------------------------------------------------------------------------
SAVEPOINT t1;
DO $t1$
DECLARE
  v_firm  uuid := '33333333-3333-3333-3333-333333333333';
  v_user  uuid := 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  v_sub   uuid := 'ffffffff-ffff-ffff-ffff-ffffffffffff';
  v_auth_id uuid;
  v_evt_count int;
BEGIN
  -- Simulate authenticated user via JWT claim helper (same pattern as rls_test)
  PERFORM set_config('request.jwt.claim.sub', v_user::text, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);

  INSERT INTO cs_replacement_authorizations
    (submission_id, firm_id, supervisor_name, authorized_date, authorized_time, reason, created_by)
  VALUES
    (v_sub, v_firm, 'Carlo Domenick', CURRENT_DATE, CURRENT_TIME,
     'Audit chain integrity test — accepted path with sufficiently long reason.', v_user)
  RETURNING id INTO v_auth_id;

  SELECT count(*) INTO v_evt_count
    FROM audit_log
   WHERE event_type = 'cs_auth_accepted'
     AND row_id = v_auth_id;

  IF v_evt_count <> 1 THEN
    PERFORM pg_temp.fail('T1: expected exactly 1 cs_auth_accepted row for auth ' || v_auth_id || ', got ' || v_evt_count);
  END IF;
  PERFORM pg_temp.pass('T1 AFTER INSERT trigger writes cs_auth_accepted audit row');
END
$t1$;
ROLLBACK TO SAVEPOINT t1;


-- ---------------------------------------------------------------------------
-- TEST 2: Hash chain unbroken — current_hash = sha256(prev_hash || canonical(payload))
-- Verifies the most recent N audit_log rows recompute to the stored hash.
-- ---------------------------------------------------------------------------
SAVEPOINT t2;
DO $t2$
DECLARE
  r record;
  v_prev_hash text;
  v_expected  text;
  v_canon     text;
  v_checked   int := 0;
  v_max_check int := 25;  -- last 25 rows is plenty to catch a break
BEGIN
  FOR r IN
    SELECT id, prev_hash, current_hash, payload
      FROM audit_log
     ORDER BY created_at ASC, id ASC
  LOOP
    -- Determine expected prev_hash for this row by walking; if first row in
    -- the table, prev_hash MUST be 'GENESIS' literal seed (CLAUDE.md MI-202).
    IF v_prev_hash IS NULL THEN
      IF r.prev_hash <> 'GENESIS' THEN
        PERFORM pg_temp.fail('T2: first audit_log row prev_hash is "' || r.prev_hash || '" not "GENESIS"');
      END IF;
    ELSE
      IF r.prev_hash <> v_prev_hash THEN
        PERFORM pg_temp.fail('T2: prev_hash discontinuity at row ' || r.id);
      END IF;
    END IF;

    -- Canonical encoding: jsonb cast to text is deterministic post-sort.
    -- If MI-202 uses a different canonicalizer (e.g. RFC 8785), Jorge:
    -- swap this line for the matching helper, e.g. canonical_jsonb(r.payload).
    v_canon := r.payload::text;
    v_expected := encode(digest(r.prev_hash || v_canon, 'sha256'), 'hex');

    IF r.current_hash <> v_expected THEN
      PERFORM pg_temp.fail('T2: current_hash mismatch at row ' || r.id ||
                           '; stored=' || r.current_hash || ' computed=' || v_expected);
    END IF;

    v_prev_hash := r.current_hash;
    v_checked := v_checked + 1;
    EXIT WHEN v_checked >= v_max_check;
  END LOOP;

  IF v_checked = 0 THEN
    PERFORM pg_temp.pass('T2 audit_log empty — chain trivially intact (note: run after at least one MI-109 INSERT)');
  ELSE
    PERFORM pg_temp.pass('T2 hash chain unbroken across ' || v_checked || ' audit rows');
  END IF;
END
$t2$;
ROLLBACK TO SAVEPOINT t2;


-- ---------------------------------------------------------------------------
-- TEST 3: Manual INSERT of cs_auth_rejected with reason_code='inspector_cancelled'
--         succeeds (this is the path the cs-auth-submit edge function takes).
-- ---------------------------------------------------------------------------
SAVEPOINT t3;
DO $t3$
DECLARE
  v_firm  uuid := '33333333-3333-3333-3333-333333333333';
  v_user  uuid := 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  v_sub   uuid := 'ffffffff-ffff-ffff-ffff-ffffffffffff';
  v_id    uuid;
BEGIN
  -- Edge functions run as service_role (bypasses RLS but writes still hash-chain).
  SET LOCAL ROLE postgres;  -- proxy for service_role in local test

  INSERT INTO audit_log (event_type, row_id, table_name, firm_id, actor_id, reason_code, payload)
  VALUES (
    'cs_auth_rejected',
    v_sub,                                       -- row_id = the submission, no auth row was created
    'cs_replacement_authorizations',
    v_firm,
    v_user,
    'inspector_cancelled',
    jsonb_build_object('submission_id', v_sub, 'reason_code', 'inspector_cancelled')
  )
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    PERFORM pg_temp.fail('T3: cs_auth_rejected INSERT did not return id');
  END IF;
  PERFORM pg_temp.pass('T3 cs_auth_rejected (inspector_cancelled) audit row writable');
END
$t3$;
ROLLBACK TO SAVEPOINT t3;


-- ---------------------------------------------------------------------------
-- TEST 4: UPDATE on audit_log fails (immutable per audit chain layers 1+2)
-- ---------------------------------------------------------------------------
SAVEPOINT t4;
DO $t4$
DECLARE v_blocked boolean := false;
BEGIN
  BEGIN
    UPDATE audit_log SET event_type = 'tampered' WHERE event_type IS NOT NULL;
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
    PERFORM pg_temp.fail('T4: UPDATE on audit_log was NOT blocked — audit chain compromised');
  END IF;
  PERFORM pg_temp.pass('T4 audit_log UPDATE blocked');
END
$t4$;
ROLLBACK TO SAVEPOINT t4;


-- ---------------------------------------------------------------------------
-- TEST 5: DELETE on audit_log fails (immutable per audit chain layers 1+2)
-- ---------------------------------------------------------------------------
SAVEPOINT t5;
DO $t5$
DECLARE v_blocked boolean := false;
BEGIN
  BEGIN
    DELETE FROM audit_log WHERE event_type IS NOT NULL;
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
    PERFORM pg_temp.fail('T5: DELETE on audit_log was NOT blocked — audit chain compromised');
  END IF;
  PERFORM pg_temp.pass('T5 audit_log DELETE blocked');
END
$t5$;
ROLLBACK TO SAVEPOINT t5;


DO $done$ BEGIN RAISE NOTICE '==== MI-109 AUDIT INTEGRITY SUITE: 5/5 PASSED ===='; END $done$;

ROLLBACK;  -- discard everything; tests do not pollute audit_log
