-- mi_demo_seed_10_daily_reports: 6 KPI rollup reports (2 weekdays × 3 inspectors).
-- SCHEMA DRIFT NOTE: spec §14 said "free-text summaries"; actual schema is KPI rollup
-- (total_properties / completed / gaps_flagged). Adjusted to match production columns.
-- Idempotent: ON CONFLICT (id) DO NOTHING.

DO $$
DECLARE
  v_actor uuid; v_actor_email text;
  v_i1 uuid; v_i2 uuid; v_i3 uuid;
BEGIN
  SELECT id, email INTO v_actor, v_actor_email
  FROM public.profiles WHERE email='demo-jorge@myinspector.io';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'email', v_actor_email)::text, true);

  SELECT id INTO v_i1 FROM public.profiles WHERE email='demo-inspector-1@myinspector.io';
  SELECT id INTO v_i2 FROM public.profiles WHERE email='demo-inspector-2@myinspector.io';
  SELECT id INTO v_i3 FROM public.profiles WHERE email='demo-inspector-3@myinspector.io';

  INSERT INTO public.daily_reports (id, firm_id, report_date, generated_by, total_properties, completed, gaps_flagged)
  VALUES
    ('eeeeeeee-0001-0000-0000-000000000001','99999999-9999-9999-9999-999999999999',DATE '2026-04-30',v_i1,3,2,1),
    ('eeeeeeee-0002-0000-0000-000000000002','99999999-9999-9999-9999-999999999999',DATE '2026-04-30',v_i2,2,2,0),
    ('eeeeeeee-0003-0000-0000-000000000003','99999999-9999-9999-9999-999999999999',DATE '2026-04-30',v_i3,2,1,1),
    ('eeeeeeee-0004-0000-0000-000000000004','99999999-9999-9999-9999-999999999999',DATE '2026-05-01',v_i1,3,3,0),
    ('eeeeeeee-0005-0000-0000-000000000005','99999999-9999-9999-9999-999999999999',DATE '2026-05-01',v_i2,2,1,1),
    ('eeeeeeee-0006-0000-0000-000000000006','99999999-9999-9999-9999-999999999999',DATE '2026-05-01',v_i3,3,2,1)
  ON CONFLICT (id) DO NOTHING;
END $$;
