-- =============================================================================
-- MI-100 Sector Toggle — Audit integrity test suite
-- =============================================================================
-- Verifies that property sector changes produce expected audit_log behavior
-- via the existing `audit_properties_insert` / `audit_properties_update`
-- AFTER triggers + the `audit_log_chain` BEFORE INSERT trigger.
--
-- Expected delta on successful UPDATE: +1 (single Owner Data write).
-- Run as: postgres (bypasses RLS, hash chain still fires).
-- Tagged dollar-quotes ($TESTBODY$) per project convention.
-- =============================================================================


-- ============================================================
-- TEST 1: UPDATE properties.sector produces audit_log delta = +1
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_before bigint;
  v_after bigint;
  v_delta bigint;
BEGIN
  -- Seed property (this will produce its own audit row — measure AFTER)
  INSERT INTO public.properties (address)
  VALUES ('123 Audit Test - MI100 sector update delta')
  RETURNING id INTO v_inserted_id;

  SELECT count(*) INTO v_before FROM public.audit_log;

  UPDATE public.properties
     SET sector = 'NJAW_SHORT_HILLS'
   WHERE id = v_inserted_id;

  SELECT count(*) INTO v_after FROM public.audit_log;
  v_delta := v_after - v_before;

  IF v_delta <> 1 THEN
    RAISE EXCEPTION 'TEST 1 FAIL: expected audit_log delta=+1, got +%', v_delta;
  END IF;

  RAISE NOTICE 'PASS test 1: sector UPDATE produced audit_log delta=+1 (id=%)', v_inserted_id;
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 2: Failed UPDATE (CHECK violation) produces delta = 0
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_before bigint;
  v_after bigint;
  v_delta bigint;
  v_caught boolean := false;
BEGIN
  INSERT INTO public.properties (address)
  VALUES ('123 Audit Test - MI100 failed update delta')
  RETURNING id INTO v_inserted_id;

  SELECT count(*) INTO v_before FROM public.audit_log;

  BEGIN
    UPDATE public.properties
       SET sector = 'INVALID_SECTOR_VALUE'
     WHERE id = v_inserted_id;
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 2 SETUP FAIL: expected check_violation, none raised';
  END IF;

  SELECT count(*) INTO v_after FROM public.audit_log;
  v_delta := v_after - v_before;

  IF v_delta <> 0 THEN
    RAISE EXCEPTION 'TEST 2 FAIL: failed UPDATE should leave audit_log unchanged, got delta=+%', v_delta;
  END IF;

  RAISE NOTICE 'PASS test 2: failed sector UPDATE produced audit_log delta=0';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 3: audit_log entry shape correct on sector UPDATE
-- ============================================================
-- Verifies action='UPDATE', table_name='properties', new_data contains
-- the new sector value, old_data contains the previous sector value.
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_audit_action text;
  v_audit_old jsonb;
  v_audit_new jsonb;
BEGIN
  INSERT INTO public.properties (address)
  VALUES ('123 Audit Shape Test - MI100')
  RETURNING id INTO v_inserted_id;

  UPDATE public.properties
     SET sector = 'NJAW_SHORT_HILLS'
   WHERE id = v_inserted_id;

  SELECT action, old_data, new_data
    INTO v_audit_action, v_audit_old, v_audit_new
    FROM public.audit_log
   WHERE table_name = 'properties'
     AND record_id = v_inserted_id::text
   ORDER BY id DESC
   LIMIT 1;

  IF v_audit_action IS NULL THEN
    RAISE EXCEPTION 'TEST 3 FAIL: no audit_log row found for record_id=%', v_inserted_id;
  END IF;

  IF v_audit_action <> 'UPDATE' THEN
    RAISE EXCEPTION 'TEST 3 FAIL: expected action=UPDATE, got %', v_audit_action;
  END IF;

  IF v_audit_new->>'sector' <> 'NJAW_SHORT_HILLS' THEN
    RAISE EXCEPTION 'TEST 3 FAIL: new_data.sector mismatch, got %', v_audit_new->>'sector';
  END IF;

  IF v_audit_old->>'sector' <> 'NJ6_NORMAL' THEN
    RAISE EXCEPTION 'TEST 3 FAIL: old_data.sector should be NJ6_NORMAL (default), got %', v_audit_old->>'sector';
  END IF;

  RAISE NOTICE 'PASS test 3: audit_log shape correct (UPDATE, old=NJ6_NORMAL, new=NJAW_SHORT_HILLS)';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 4: Hash chain populated on properties UPDATE audit row
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_prev text;
  v_hash text;
BEGIN
  INSERT INTO public.properties (address)
  VALUES ('123 Hash Chain Test - MI100')
  RETURNING id INTO v_inserted_id;

  UPDATE public.properties
     SET sector = 'NJAW_SHORT_HILLS'
   WHERE id = v_inserted_id;

  SELECT prev_hash, row_hash
    INTO v_prev, v_hash
    FROM public.audit_log
   WHERE table_name = 'properties' AND record_id = v_inserted_id::text
   ORDER BY id DESC
   LIMIT 1;

  IF v_prev IS NULL OR v_hash IS NULL THEN
    RAISE EXCEPTION 'TEST 4 FAIL: prev_hash or row_hash NULL';
  END IF;

  IF v_prev = 'PENDING' THEN
    RAISE EXCEPTION 'TEST 4 FAIL: prev_hash still PENDING';
  END IF;

  IF v_hash = 'PENDING' THEN
    RAISE EXCEPTION 'TEST 4 FAIL: row_hash still PENDING';
  END IF;

  IF v_hash !~ '^[0-9a-f]+$' THEN
    RAISE EXCEPTION 'TEST 4 FAIL: row_hash not lowercase hex - %', v_hash;
  END IF;

  RAISE NOTICE 'PASS test 4: chain populated - prev=%..., hash=%...',
    left(v_prev, 12), left(v_hash, 12);
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- Run all 4 tests above. Expected: 4 PASS NOTICE lines, no errors.
-- ============================================================
