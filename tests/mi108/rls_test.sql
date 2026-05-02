-- =============================================================================
-- MI-108 No-Work Submission Workflow — RLS test suite
-- =============================================================================
-- Verifies that no_work phase_submissions rows inherit the existing
-- phase_submissions firm-isolation RLS policies. No new policy was added
-- in the MI-108 migration — the new columns ride on top of the two existing
-- policies:
--   - phase_submissions_active_firm  (cmd=ALL, qual: deleted_at IS NULL AND
--     firm_id IN (SELECT firm_id FROM profiles WHERE id = auth.uid()))
--   - phase_submissions_super_admin_all  (cmd=ALL, role super_admin)
--
-- Pattern mirrors tests/mi109/rls_test.sql:
--   - Single BEGIN/ROLLBACK wraps fixtures + all tests
--   - JWT impersonation via set_config('request.jwt.claim.sub', uid::text, true)
--     + EXECUTE 'SET LOCAL ROLE authenticated'
--   - postgres role bypasses RLS for fixture seeding
--
-- Tests:
--   1. Inspector A in firm A sees their own firm's no_work row
--   2. Inspector B in firm B is blind to firm A's no_work row
--   3. super_admin sees both rows
--   4. anon (role=anon, no JWT sub) is blind to all rows
--
-- Run as: postgres
-- Tagged dollar-quotes ($TESTBODY$) per project convention.
-- =============================================================================

BEGIN;

SET LOCAL client_min_messages = NOTICE;

-- -----------------------------------------------------------------------------
-- 0. Fixtures: 2 firms, 1 inspector + super_admin in auth.users + profiles,
--    1 no_work phase_submission per firm. Inserted as postgres (bypasses RLS).
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_firm_a uuid := extensions.gen_random_uuid();
  v_firm_b uuid := extensions.gen_random_uuid();
  v_user_a uuid := extensions.gen_random_uuid();
  v_user_b uuid := extensions.gen_random_uuid();
  v_super  uuid := extensions.gen_random_uuid();
  v_sub_a  uuid := extensions.gen_random_uuid();
  v_sub_b  uuid := extensions.gen_random_uuid();
BEGIN
  PERFORM set_config('mi108.firm_a', v_firm_a::text, true);
  PERFORM set_config('mi108.firm_b', v_firm_b::text, true);
  PERFORM set_config('mi108.user_a', v_user_a::text, true);
  PERFORM set_config('mi108.user_b', v_user_b::text, true);
  PERFORM set_config('mi108.super',  v_super::text,  true);
  PERFORM set_config('mi108.sub_a',  v_sub_a::text,  true);
  PERFORM set_config('mi108.sub_b',  v_sub_b::text,  true);

  INSERT INTO public.firms (id, name, firm_code) VALUES
    (v_firm_a, 'TEST-FIRM-A-MI108', 'TEST-A-MI108'),
    (v_firm_b, 'TEST-FIRM-B-MI108', 'TEST-B-MI108');

  INSERT INTO auth.users (id, email, instance_id, aud, role) VALUES
    (v_user_a, 'a@mi108.test', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_user_b, 'b@mi108.test', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
    (v_super,  'admin@mi108.test', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');

  INSERT INTO public.profiles (id, firm_id, role, full_name) VALUES
    (v_user_a, v_firm_a, 'inspector',   'Test Inspector A MI108'),
    (v_user_b, v_firm_b, 'inspector',   'Test Inspector B MI108'),
    (v_super,  NULL,     'super_admin', 'Test Super Admin MI108');

  -- Two no_work submissions, one per firm. All four CHECK fields populated.
  INSERT INTO public.phase_submissions (
    id, firm_id, submitted_by, phase,
    photo_house_url, photo_no_work_whiteboard_url,
    photo_no_work_whiteboard_detected, no_work_reason
  ) VALUES
    (v_sub_a, v_firm_a, v_user_a, 'no_work',
     'https://example.com/firm-a-house.jpg',
     'https://example.com/firm-a-whiteboard.jpg',
     true,
     'RLS test — firm A no work submission for visibility checks'),
    (v_sub_b, v_firm_b, v_user_b, 'no_work',
     'https://example.com/firm-b-house.jpg',
     'https://example.com/firm-b-whiteboard.jpg',
     true,
     'RLS test — firm B no work submission for cross-firm checks');

  RAISE NOTICE 'fixtures seeded — firm_a=%, firm_b=%, sub_a=%, sub_b=%',
    v_firm_a, v_firm_b, v_sub_a, v_sub_b;
END;
$TESTBODY$;


-- -----------------------------------------------------------------------------
-- 1. Inspector A sees own firm's no_work row, NOT firm B's
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_user_a uuid := current_setting('mi108.user_a')::uuid;
  v_sub_a  uuid := current_setting('mi108.sub_a')::uuid;
  v_sub_b  uuid := current_setting('mi108.sub_b')::uuid;
  v_own_visible int;
  v_other_visible int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_a::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  SELECT count(*) INTO v_own_visible
    FROM public.phase_submissions WHERE id = v_sub_a;
  SELECT count(*) INTO v_other_visible
    FROM public.phase_submissions WHERE id = v_sub_b;

  RESET ROLE;

  IF v_own_visible <> 1 THEN
    RAISE EXCEPTION 'FAIL 1a: inspector A blind to own firm no_work row (count=%)', v_own_visible;
  END IF;
  IF v_other_visible <> 0 THEN
    RAISE EXCEPTION 'FAIL 1b: inspector A leaked firm B no_work row (count=%)', v_other_visible;
  END IF;
  RAISE NOTICE 'PASS 1: inspector A sees own firm no_work, blind to firm B';
END;
$TESTBODY$;


-- -----------------------------------------------------------------------------
-- 2. Inspector B sees own firm's no_work row, NOT firm A's
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_user_b uuid := current_setting('mi108.user_b')::uuid;
  v_sub_a  uuid := current_setting('mi108.sub_a')::uuid;
  v_sub_b  uuid := current_setting('mi108.sub_b')::uuid;
  v_own_visible int;
  v_other_visible int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_user_b::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  SELECT count(*) INTO v_own_visible
    FROM public.phase_submissions WHERE id = v_sub_b;
  SELECT count(*) INTO v_other_visible
    FROM public.phase_submissions WHERE id = v_sub_a;

  RESET ROLE;

  IF v_own_visible <> 1 THEN
    RAISE EXCEPTION 'FAIL 2a: inspector B blind to own firm no_work row (count=%)', v_own_visible;
  END IF;
  IF v_other_visible <> 0 THEN
    RAISE EXCEPTION 'FAIL 2b: inspector B leaked firm A no_work row (count=%)', v_other_visible;
  END IF;
  RAISE NOTICE 'PASS 2: inspector B sees own firm no_work, blind to firm A (cross-firm isolation holds)';
END;
$TESTBODY$;


-- -----------------------------------------------------------------------------
-- 3. super_admin sees BOTH firm A and firm B no_work rows
--    (phase_submissions_super_admin_all policy uses role='super_admin' check)
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_super uuid := current_setting('mi108.super')::uuid;
  v_sub_a uuid := current_setting('mi108.sub_a')::uuid;
  v_sub_b uuid := current_setting('mi108.sub_b')::uuid;
  v_a_visible int;
  v_b_visible int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', v_super::text, true);
  EXECUTE 'SET LOCAL ROLE authenticated';

  SELECT count(*) INTO v_a_visible
    FROM public.phase_submissions WHERE id = v_sub_a;
  SELECT count(*) INTO v_b_visible
    FROM public.phase_submissions WHERE id = v_sub_b;

  RESET ROLE;

  IF v_a_visible <> 1 THEN
    RAISE EXCEPTION 'FAIL 3a: super_admin blind to firm A no_work row (count=%)', v_a_visible;
  END IF;
  IF v_b_visible <> 1 THEN
    RAISE EXCEPTION 'FAIL 3b: super_admin blind to firm B no_work row (count=%)', v_b_visible;
  END IF;
  RAISE NOTICE 'PASS 3: super_admin sees both firm A and firm B no_work rows';
END;
$TESTBODY$;


-- -----------------------------------------------------------------------------
-- 4. Anonymous (role=anon) blocked from all no_work rows
-- -----------------------------------------------------------------------------
DO $TESTBODY$
DECLARE
  v_sub_a uuid := current_setting('mi108.sub_a')::uuid;
  v_sub_b uuid := current_setting('mi108.sub_b')::uuid;
  v_a_visible int;
  v_b_visible int;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', NULL, true);
  EXECUTE 'SET LOCAL ROLE anon';

  SELECT count(*) INTO v_a_visible
    FROM public.phase_submissions WHERE id = v_sub_a;
  SELECT count(*) INTO v_b_visible
    FROM public.phase_submissions WHERE id = v_sub_b;

  RESET ROLE;

  IF v_a_visible <> 0 THEN
    RAISE EXCEPTION 'FAIL 4a: anon read firm A no_work row (count=%)', v_a_visible;
  END IF;
  IF v_b_visible <> 0 THEN
    RAISE EXCEPTION 'FAIL 4b: anon read firm B no_work row (count=%)', v_b_visible;
  END IF;
  RAISE NOTICE 'PASS 4: anon blocked from both no_work rows';
END;
$TESTBODY$;

ROLLBACK;

-- =============================================================================
-- Expected: 4 PASS NOTICE lines (1, 2, 3, 4) plus the fixtures-seeded NOTICE.
-- ROLLBACK removes all fixtures so no test data persists in production.
-- =============================================================================
