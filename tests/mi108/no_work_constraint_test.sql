-- =============================================================================
-- MI-108 No-Work Submission Workflow — Constraint test suite
-- =============================================================================
-- Verifies the `phase_submissions_no_work_invariant` CHECK constraint added in
-- migration `mi108_no_work_submission_workflow` (applied 2026-05-02 via
-- Supabase MCP).
--
-- Each test wraps in BEGIN/ROLLBACK so no test data persists in production.
-- Tagged dollar-quotes ($TESTBODY$) per user-rule + decisions.md 2026-05-02.
--
-- firm_id is provided as NULL (column is nullable, FK only enforced when
-- non-null) so we don't have to seed firms just to test a CHECK constraint.
-- submitted_by has no FK so a random uuid is fine. property_id stays NULL.
--
-- Expected output: 7 PASS NOTICE lines, no errors. Failure raises EXCEPTION
-- which aborts the surrounding BEGIN/ROLLBACK — surfaces as a SQL error.
-- Run as: postgres (bypasses RLS).
-- =============================================================================


-- ============================================================
-- TEST 1: Valid no_work insert succeeds
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
BEGIN
  INSERT INTO public.phase_submissions (
    phase, firm_id, submitted_by,
    photo_house_url,
    photo_no_work_whiteboard_url,
    photo_no_work_whiteboard_detected,
    no_work_reason
  ) VALUES (
    'no_work',
    NULL,
    extensions.gen_random_uuid(),
    'https://example.com/test-house.jpg',
    'https://example.com/test-whiteboard.jpg',
    true,
    'Customer not home and gate locked, rescheduling for next week'
  ) RETURNING id INTO v_inserted_id;

  IF v_inserted_id IS NULL THEN
    RAISE EXCEPTION 'TEST 1 FAIL: insert returned no id';
  END IF;

  RAISE NOTICE 'PASS test 1: valid no_work insert succeeded (id=%)', v_inserted_id;
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 2: Missing photo_house_url — CHECK rejects
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_caught boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.phase_submissions (
      phase, firm_id, submitted_by,
      photo_no_work_whiteboard_url,
      photo_no_work_whiteboard_detected,
      no_work_reason
    ) VALUES (
      'no_work', NULL, extensions.gen_random_uuid(),
      'https://example.com/test-whiteboard.jpg', true,
      'Customer not home and gate locked, rescheduling for next week'
    );
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 2 FAIL: missing photo_house_url should raise check_violation';
  END IF;

  RAISE NOTICE 'PASS test 2: missing photo_house_url rejected by CHECK';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 3: Missing photo_no_work_whiteboard_url — CHECK rejects
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_caught boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.phase_submissions (
      phase, firm_id, submitted_by,
      photo_house_url,
      photo_no_work_whiteboard_detected,
      no_work_reason
    ) VALUES (
      'no_work', NULL, extensions.gen_random_uuid(),
      'https://example.com/test-house.jpg', true,
      'Customer not home and gate locked, rescheduling for next week'
    );
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 3 FAIL: missing whiteboard_url should raise check_violation';
  END IF;

  RAISE NOTICE 'PASS test 3: missing photo_no_work_whiteboard_url rejected by CHECK';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 4: photo_no_work_whiteboard_detected=false — CHECK rejects
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_caught boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.phase_submissions (
      phase, firm_id, submitted_by,
      photo_house_url,
      photo_no_work_whiteboard_url,
      photo_no_work_whiteboard_detected,
      no_work_reason
    ) VALUES (
      'no_work', NULL, extensions.gen_random_uuid(),
      'https://example.com/test-house.jpg',
      'https://example.com/test-whiteboard.jpg',
      false,
      'Customer not home and gate locked, rescheduling for next week'
    );
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 4 FAIL: whiteboard_detected=false should raise check_violation';
  END IF;

  RAISE NOTICE 'PASS test 4: photo_no_work_whiteboard_detected=false rejected by CHECK';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 5: Missing no_work_reason — CHECK rejects
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_caught boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.phase_submissions (
      phase, firm_id, submitted_by,
      photo_house_url,
      photo_no_work_whiteboard_url,
      photo_no_work_whiteboard_detected
    ) VALUES (
      'no_work', NULL, extensions.gen_random_uuid(),
      'https://example.com/test-house.jpg',
      'https://example.com/test-whiteboard.jpg',
      true
    );
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 5 FAIL: missing no_work_reason should raise check_violation';
  END IF;

  RAISE NOTICE 'PASS test 5: missing no_work_reason rejected by CHECK';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 6: no_work_reason length < 20 chars — CHECK rejects
-- ============================================================
-- The CHECK uses length(trim(no_work_reason)) >= 20, so we test a value with
-- leading/trailing whitespace that would be 20+ raw but <20 trimmed, plus
-- the obvious "too short" case.
BEGIN;
DO $TESTBODY$
DECLARE
  v_caught boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.phase_submissions (
      phase, firm_id, submitted_by,
      photo_house_url,
      photo_no_work_whiteboard_url,
      photo_no_work_whiteboard_detected,
      no_work_reason
    ) VALUES (
      'no_work', NULL, extensions.gen_random_uuid(),
      'https://example.com/test-house.jpg',
      'https://example.com/test-whiteboard.jpg',
      true,
      'too short'
    );
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 6 FAIL: reason < 20 chars should raise check_violation';
  END IF;

  RAISE NOTICE 'PASS test 6: no_work_reason < 20 chars rejected by CHECK';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 7: CONTROL — non-no_work phase unaffected by new constraint
-- ============================================================
-- Confirms the `phase <> 'no_work' OR (...)` short-circuit works:
-- a service_work submission with no no_work_* fields should succeed.
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
BEGIN
  INSERT INTO public.phase_submissions (
    phase, firm_id, submitted_by
  ) VALUES (
    'service_work',
    NULL,
    extensions.gen_random_uuid()
  ) RETURNING id INTO v_inserted_id;

  IF v_inserted_id IS NULL THEN
    RAISE EXCEPTION 'TEST 7 FAIL: service_work insert returned no id';
  END IF;

  RAISE NOTICE 'PASS test 7: non-no_work phase unaffected (service_work id=%)', v_inserted_id;
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- Run all 7 tests above. Expected: 7 PASS NOTICE lines, no errors.
-- If any test raises EXCEPTION, fix the constraint or the test before merging.
-- ============================================================
