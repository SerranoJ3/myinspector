-- =============================================================================
-- MI-100 Sector Toggle — Constraint test suite
-- =============================================================================
-- Verifies the `properties_sector_enum` CHECK constraint added in
-- migration `mi100_sector_toggle` (applied 2026-05-02 via Supabase MCP).
--
-- Each test wraps in BEGIN/ROLLBACK so no test data persists.
-- Tagged dollar-quotes ($TESTBODY$) per project convention.
--
-- firm_id is provided as NULL (column nullable, FK only when non-null).
-- address is NOT NULL so we provide a test value.
--
-- Expected output: 4 PASS NOTICE lines, no errors.
-- Run as: postgres (bypasses RLS).
-- =============================================================================


-- ============================================================
-- TEST 1: INSERT with valid sector NJ6_NORMAL succeeds (default)
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_sector text;
BEGIN
  INSERT INTO public.properties (address)
  VALUES ('123 Test Street, Newark, NJ - MI100 default test')
  RETURNING id, sector INTO v_inserted_id, v_sector;

  IF v_inserted_id IS NULL THEN
    RAISE EXCEPTION 'TEST 1 FAIL: insert returned no id';
  END IF;

  IF v_sector <> 'NJ6_NORMAL' THEN
    RAISE EXCEPTION 'TEST 1 FAIL: expected sector default NJ6_NORMAL, got %', v_sector;
  END IF;

  RAISE NOTICE 'PASS test 1: default sector NJ6_NORMAL applied (id=%)', v_inserted_id;
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 2: INSERT with explicit sector NJAW_SHORT_HILLS succeeds
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_sector text;
BEGIN
  INSERT INTO public.properties (address, sector)
  VALUES ('456 Hartshorn Drive, Short Hills, NJ - MI100 explicit test', 'NJAW_SHORT_HILLS')
  RETURNING id, sector INTO v_inserted_id, v_sector;

  IF v_sector <> 'NJAW_SHORT_HILLS' THEN
    RAISE EXCEPTION 'TEST 2 FAIL: expected NJAW_SHORT_HILLS, got %', v_sector;
  END IF;

  RAISE NOTICE 'PASS test 2: explicit sector NJAW_SHORT_HILLS accepted (id=%)', v_inserted_id;
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 3: INSERT with invalid sector value — CHECK rejects
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_caught boolean := false;
BEGIN
  BEGIN
    INSERT INTO public.properties (address, sector)
    VALUES ('789 Invalid Lane - MI100 invalid sector test', 'BOGUS_SECTOR');
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 3 FAIL: invalid sector should raise check_violation';
  END IF;

  RAISE NOTICE 'PASS test 3: invalid sector value rejected by CHECK';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- TEST 4: UPDATE existing property to invalid sector — CHECK rejects
-- ============================================================
BEGIN;
DO $TESTBODY$
DECLARE
  v_inserted_id uuid;
  v_caught boolean := false;
BEGIN
  -- Seed a valid property first
  INSERT INTO public.properties (address)
  VALUES ('999 Update Test Street - MI100 update reject test')
  RETURNING id INTO v_inserted_id;

  -- Try to update to invalid sector
  BEGIN
    UPDATE public.properties
       SET sector = 'NOT_A_REAL_SECTOR'
     WHERE id = v_inserted_id;
  EXCEPTION
    WHEN check_violation THEN v_caught := true;
  END;

  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST 4 FAIL: UPDATE to invalid sector should raise check_violation';
  END IF;

  RAISE NOTICE 'PASS test 4: UPDATE to invalid sector rejected by CHECK';
END;
$TESTBODY$;
ROLLBACK;


-- ============================================================
-- Run all 4 tests above. Expected: 4 PASS NOTICE lines, no errors.
-- ============================================================
