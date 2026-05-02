-- =============================================================================
-- MI-100 Sector Toggle — RLS test suite
-- =============================================================================
-- Verifies new `sector` column inherits existing properties RLS policies:
--   - properties_active_firm  (cmd=ALL, qual: deleted_at IS NULL AND
--     firm_id IN (SELECT firm_id FROM profiles WHERE id = auth.uid()))
--   - properties_super_admin_all  (cmd=ALL, role super_admin)
--
-- No new RLS policy in MI-100 — column inherits.
-- Pattern mirrors tests/mi108/rls_test.sql.
-- Run as: postgres
-- Tagged dollar-quotes ($TESTBODY$) per project convention.
-- =============================================================================

BEGIN;

SET LOCAL client_min_messages = NOTICE;

-- -----------------------------------------------------------------------------
-- 0. Fixtures: 2 firms, 1 inspector + super_admin in auth.users + profiles,
--    1 property per firm with explicit sectors. Inserted as postgres.
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_firm_a uuid := extensions.gen_random_uuid();
  v_firm_b uuid := extensions.gen_random_uuid();
  v_user_a uuid := extensions.gen_random_uuid();
  v_user_b uuid := extensions.gen_random_uuid();
  v_super  uuid := extensions.gen_random_uuid();
  v_prop_a uuid := extensions.gen_random_uuid();
  v_prop_b uuid := extensions.gen_random_uuid();
BEGIN
  PERFORM set_config('mi100.firm_a', v_firm_a::text, true);
  PERFORM set_config('mi100.firm_b', v_firm_b::text, true);
  PERFORM set_config('mi100.user_a', v_user_a::text, true);
  PERFORM set_config('mi100.user_b', v_user_b::text, true);
  PERFORM set_config('mi100.super',  v_super::text,  true);
  PERFORM set_config('mi100.prop_a', v_prop_a::text, true);
  PERFORM set_config('mi100.prop_b', v_prop_b::text, true);

  INSERT INTO public.firms (id, name, firm_code) VALUES
    (v_firm_a, 'TEST-FIRM-A-MI100', 'TEST-A-MI100'),
    (v_firm_b, 'TEST-FIRM-B-MI100', 'TEST-B-MI100');

  INSERT INTO auth.users (id, email, instance_id, aud, role) VALUES
    (v_user_a, 'a@mi100.test', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_user_b, 'b@mi100.test', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_super,  'admin@mi100.test', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

  INSERT INTO public.profiles (id, firm_id, role, full_name) VALUES
    (v_user_a, v_firm_a, 'inspector',   'Test Inspector A MI100'),
    (v_user_b, v_firm_b, 'inspector',   'Test Inspector B MI100'),
    (v_super,  NULL,     'super_admin', 'Test Super Admin MI100');

  INSERT INTO public.properties (id, firm_id, address, sector) VALUES
    (v_prop_a, v_firm_a, 'Test Property A - MI100 RLS', 'NJ6_NORMAL'),
    (v_prop_b, v_firm_b, 'Test Property B - MI100 RLS', 'NJAW_SHORT_HILLS');

  RAISE NOTICE 'fixtures seeded - firm_a=%, firm_b=%, prop_a=%, prop_b=%',
    v_firm_a, v_firm_b, v_prop_a, v_prop_b;
END;
$TESTBODY$;


-- -----------------------------------------------------------------------------
-- 1. Inspector A sees own firm's property + sector, NOT firm B's
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_user_a uuid := current_setting('mi100.user_a')::uuid;
  v_prop_a uuid := current_setting('mi100.prop_a')::uuid;
  v_prop_b uuid := current_setting('mi100.prop_b')::uuid;
  v_own_visible int;
  v_other_visible int;
  v_own_sector text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  SELECT count(*) INTO v_own_visible
    FROM public.properties WHERE id = v_prop_a;
  SELECT count(*) INTO v_other_visible
    FROM public.properties WHERE id = v_prop_b;
  SELECT sector INTO v_own_sector
    FROM public.properties WHERE id = v_prop_a;

  RESET ROLE;

  IF v_own_visible <> 1 THEN
    RAISE EXCEPTION 'FAIL 1a: inspector A blind to own firm property (count=%)', v_own_visible;
  END IF;
  IF v_other_visible <> 0 THEN
    RAISE EXCEPTION 'FAIL 1b: inspector A leaked firm B property (count=%)', v_other_visible;
  END IF;
  IF v_own_sector <> 'NJ6_NORMAL' THEN
    RAISE EXCEPTION 'FAIL 1c: inspector A sector read mismatch (got %)', v_own_sector;
  END IF;
  RAISE NOTICE 'PASS 1: inspector A sees own firm property + sector, blind to firm B';
END;
$TESTBODY$;


-- -----------------------------------------------------------------------------
-- 2. Inspector B sees own firm's property + sector, NOT firm A's
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_user_b uuid := current_setting('mi100.user_b')::uuid;
  v_prop_a uuid := current_setting('mi100.prop_a')::uuid;
  v_prop_b uuid := current_setting('mi100.prop_b')::uuid;
  v_own_visible int;
  v_other_visible int;
  v_own_sector text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_b::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  SELECT count(*) INTO v_own_visible
    FROM public.properties WHERE id = v_prop_b;
  SELECT count(*) INTO v_other_visible
    FROM public.properties WHERE id = v_prop_a;
  SELECT sector INTO v_own_sector
    FROM public.properties WHERE id = v_prop_b;

  RESET ROLE;

  IF v_own_visible <> 1 THEN
    RAISE EXCEPTION 'FAIL 2a: inspector B blind to own firm property (count=%)', v_own_visible;
  END IF;
  IF v_other_visible <> 0 THEN
    RAISE EXCEPTION 'FAIL 2b: inspector B leaked firm A property (count=%)', v_other_visible;
  END IF;
  IF v_own_sector <> 'NJAW_SHORT_HILLS' THEN
    RAISE EXCEPTION 'FAIL 2c: inspector B sector read mismatch (got %)', v_own_sector;
  END IF;
  RAISE NOTICE 'PASS 2: inspector B sees own firm property + sector, blind to firm A';
END;
$TESTBODY$;


-- -----------------------------------------------------------------------------
-- 3. super_admin sees BOTH firms' properties + their sectors
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_super uuid := current_setting('mi100.super')::uuid;
  v_prop_a uuid := current_setting('mi100.prop_a')::uuid;
  v_prop_b uuid := current_setting('mi100.prop_b')::uuid;
  v_a_visible int;
  v_b_visible int;
  v_a_sector text;
  v_b_sector text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_super::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  SELECT count(*), max(sector) INTO v_a_visible, v_a_sector
    FROM public.properties WHERE id = v_prop_a;
  SELECT count(*), max(sector) INTO v_b_visible, v_b_sector
    FROM public.properties WHERE id = v_prop_b;

  RESET ROLE;

  IF v_a_visible <> 1 OR v_a_sector <> 'NJ6_NORMAL' THEN
    RAISE EXCEPTION 'FAIL 3a: super_admin firm A read mismatch (visible=%, sector=%)', v_a_visible, v_a_sector;
  END IF;
  IF v_b_visible <> 1 OR v_b_sector <> 'NJAW_SHORT_HILLS' THEN
    RAISE EXCEPTION 'FAIL 3b: super_admin firm B read mismatch (visible=%, sector=%)', v_b_visible, v_b_sector;
  END IF;
  RAISE NOTICE 'PASS 3: super_admin sees both firms properties + sectors (NJ6 + SHORT_HILLS)';
END;
$TESTBODY$;


-- -----------------------------------------------------------------------------
-- 4. Anonymous (role=anon) blocked from all property rows
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_prop_a uuid := current_setting('mi100.prop_a')::uuid;
  v_prop_b uuid := current_setting('mi100.prop_b')::uuid;
  v_a_visible int;
  v_b_visible int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', NULL, true);
  EXECUTE 'SET LOCAL ROLE anon';

  SELECT count(*) INTO v_a_visible
    FROM public.properties WHERE id = v_prop_a;
  SELECT count(*) INTO v_b_visible
    FROM public.properties WHERE id = v_prop_b;

  RESET ROLE;

  IF v_a_visible <> 0 THEN
    RAISE EXCEPTION 'FAIL 4a: anon read firm A property (count=%)', v_a_visible;
  END IF;
  IF v_b_visible <> 0 THEN
    RAISE EXCEPTION 'FAIL 4b: anon read firm B property (count=%)', v_b_visible;
  END IF;
  RAISE NOTICE 'PASS 4: anon blocked from both firm properties';
END;
$TESTBODY$;

ROLLBACK;

-- =============================================================================
-- Expected: 4 PASS NOTICE lines (1, 2, 3, 4) + 1 fixtures-seeded NOTICE.
-- ROLLBACK removes all fixtures so no test data persists.
-- =============================================================================
