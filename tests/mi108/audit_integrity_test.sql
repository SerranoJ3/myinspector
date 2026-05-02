-- =============================================================================
-- MI-108 No-Work Submission Workflow — Audit integrity test suite
-- =============================================================================
-- Verifies that no_work phase_submissions inserts produce expected audit_log
-- behavior via the existing `audit_phase_submissions_insert` AFTER trigger.
--
-- Expected delta on successful no_work insert: +1 (single Owner Data write).
-- Compare to MI-109 accepted CS auth path: +2 (two-table write).
--
-- Each test wraps in BEGIN/ROLLBACK so no test rows persist. The audit_log
-- BEFORE INSERT chain trigger overwrites the prev_hash/row_hash placeholders
-- written by the AFTER trigger — verified in test 4.
--
-- firm_id is NULL (nullable, no FK violation). submitted_by is gen_random_uuid()
-- (no FK). property_id is NULL.
--
-- Run as: postgres (bypasses RLS, hash chain still fires).
-- Tagged dollar-quotes ($TESTBODY$) per project convention.
-- =============================================================================


-- ============================================================
-- TEST 1: Successful no_work insert produces audit_log delta = +1
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_before bigint;
  v_after bigint;
  v_delta bigint;
  v_inserted_id uuid;
BEGIN
  SELECT count(*) INTO v_before FROM public.audit_log;

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
    'Audit integrity test 1 — verifying delta plus one'
  ) RETURNING id INTO v_inserted_id;

  SELECT count(*) INTO v_after FROM public.audit_log;
  v_delta := v_after - v_before;

  IF v_delta <> 1 THEN
    RAISE EXCEPTION 'TEST 1 FAIL: expected audit_log delta=+1, got +%', v_delta;
  END IF;

  RAISE NOTICE 'PASS test 1: audit_log delta=+1 confirmed on no_work insert (id=%)', v_inserted_id;
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 2: Failed no_work insert (CHECK violation) produces delta = 0
-- ============================================================
-- Whole transaction aborts on check_violation; AFTER trigger never fires.
BEGIN;
DO $TESTBODY$
DECLARE
  v_before bigint;
  v_after bigint;
  v_delta bigint;
  v_caught boolean := false;
BEGIN
  SELECT count(*) INTO v_before FROM public.audit_log;

  BEGIN
    INSERT INTO public.phase_submissions (
      phase, firm_id, submitted_by, photo_house_url
    ) VALUES (
      'no_work', NULL, extensions.gen_random_uuid(),
      'https://example.com/test-house.jpg'
      -- intentionally missing whiteboard_url, detected, reason
    );
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 2 SETUP FAIL: expected check_violation, none raised';
  END IF;

  SELECT count(*) INTO v_after FROM public.audit_log;
  v_delta := v_after - v_before;

  IF v_delta <> 0 THEN
    RAISE EXCEPTION 'TEST 2 FAIL: failed insert should leave audit_log unchanged, got delta=+%', v_delta;
  END IF;

  RAISE NOTICE 'PASS test 2: failed no_work insert produced audit_log delta=0';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 3: audit_log entry has correct shape on successful no_work insert
-- ============================================================
-- Verifies action='INSERT', table_name='phase_submissions', new_data
-- contains the no_work fields.
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_audit_action text;
  v_audit_table text;
  v_audit_new jsonb;
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
    'Audit shape test 3 — verifying audit row fields'
  ) RETURNING id INTO v_inserted_id;

  SELECT action, table_name, new_data
    INTO v_audit_action, v_audit_table, v_audit_new
    FROM public.audit_log
   WHERE table_name = 'phase_submissions'
     AND record_id = v_inserted_id::text
   ORDER BY id DESC
   LIMIT 1;

  IF v_audit_action IS NULL THEN
    RAISE EXCEPTION 'TEST 3 FAIL: no audit_log row found for record_id=%', v_inserted_id;
  END IF;

  IF v_audit_action <> 'INSERT' THEN
    RAISE EXCEPTION 'TEST 3 FAIL: expected action=INSERT, got %', v_audit_action;
  END IF;

  IF v_audit_new->>'phase' <> 'no_work' THEN
    RAISE EXCEPTION 'TEST 3 FAIL: new_data.phase mismatch, got %', v_audit_new->>'phase';
  END IF;

  IF v_audit_new->>'no_work_reason' IS NULL THEN
    RAISE EXCEPTION 'TEST 3 FAIL: new_data.no_work_reason missing';
  END IF;

  IF v_audit_new->>'photo_house_url' IS NULL THEN
    RAISE EXCEPTION 'TEST 3 FAIL: new_data.photo_house_url missing';
  END IF;

  IF v_audit_new->>'photo_no_work_whiteboard_url' IS NULL THEN
    RAISE EXCEPTION 'TEST 3 FAIL: new_data.photo_no_work_whiteboard_url missing';
  END IF;

  IF (v_audit_new->>'photo_no_work_whiteboard_detected')::boolean IS NOT TRUE THEN
    RAISE EXCEPTION 'TEST 3 FAIL: new_data.photo_no_work_whiteboard_detected not true';
  END IF;

  RAISE NOTICE 'PASS test 3: audit_log row shape correct (action=INSERT, all 4 no_work fields captured in new_data)';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 4: hash chain populated by BEFORE INSERT trigger
-- ============================================================
-- The audit_phase_submissions_insert AFTER trigger writes prev_hash='PENDING'
-- and row_hash='PENDING'; the audit_log_chain BEFORE INSERT trigger overwrites
-- both with real hash values. Verify nothing remains 'PENDING' on the new row,
-- and row_hash matches lowercase hex.
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_prev text;
  v_hash text;
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
    'Hash chain test 4 — verifying BEFORE trigger overwrites placeholders'
  ) RETURNING id INTO v_inserted_id;

  SELECT prev_hash, row_hash
    INTO v_prev, v_hash
    FROM public.audit_log
   WHERE table_name = 'phase_submissions' AND record_id = v_inserted_id::text
   ORDER BY id DESC
   LIMIT 1;

  IF v_prev IS NULL OR v_hash IS NULL THEN
    RAISE EXCEPTION 'TEST 4 FAIL: prev_hash or row_hash NULL';
  END IF;

  IF v_prev = 'PENDING' THEN
    RAISE EXCEPTION 'TEST 4 FAIL: prev_hash still PENDING — BEFORE INSERT chain trigger did not overwrite';
  END IF;

  IF v_hash = 'PENDING' THEN
    RAISE EXCEPTION 'TEST 4 FAIL: row_hash still PENDING — chain trigger did not overwrite';
  END IF;

  IF v_hash !~ '^[0-9a-f]+$' THEN
    RAISE EXCEPTION 'TEST 4 FAIL: row_hash not lowercase hex — %', v_hash;
  END IF;

  RAISE NOTICE 'PASS test 4: chain populated — prev=%..., hash=%...',
    left(v_prev, 12), left(v_hash, 12);
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- Run all 4 tests above. Expected: 4 PASS NOTICE lines, no errors.
-- ============================================================
