-- mi_demo_seed_05_projects: 1 project for demo firm.
-- Idempotent: ON CONFLICT (id) DO NOTHING.
-- Audit attribution per §16a (a): super_admin via set_config request.jwt.claims.

DO $$
DECLARE
  v_actor uuid;
  v_actor_email text;
BEGIN
  SELECT id, email INTO v_actor, v_actor_email
  FROM public.profiles
  WHERE email='demo-jorge@myinspector.io';
  IF v_actor IS NULL THEN
    RAISE EXCEPTION 'demo-jorge@myinspector.io not in profiles — Edge Function step 4 not completed?';
  END IF;
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'email', v_actor_email)::text, true);

  INSERT INTO public.projects (id, firm_id, name, client_name, module_key, status, start_date)
  VALUES (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '99999999-9999-9999-9999-999999999999',
    'Demo LSL Replacement Program 2026',
    'Sample Water Authority',
    'water_utility',
    'active',
    DATE '2026-01-15'
  )
  ON CONFLICT (id) DO NOTHING;
END $$;
