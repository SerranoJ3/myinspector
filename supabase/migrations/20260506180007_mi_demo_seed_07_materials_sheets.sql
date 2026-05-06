-- mi_demo_seed_07_materials_sheets: 5 materials_sheets across properties #1, #2, #3, #4, #9.
-- Property #1 sheet = comprehensive (44 Dunnell paper-true values, complete record).
-- Property #4 sheet = KILL minimal. Property #9 sheet = FULL with cs_replacement gate.
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

  INSERT INTO public.materials_sheets (
    id, property_id, firm_id, submitted_by, sheet_date, contractor_name, service_type,
    foreman_name, temperature_f, sky_condition, test_pit, kill_location, curb_box_location,
    curb_box_replaced, num_excavations, notes, corp_depth_inches, cs_depth_inches,
    cs_house_inches, cs_rs_inches, cs_ls_inches, cs_near_curb_inches, cs_far_curb_inches,
    cs_corp_inches, cs_mp_inches, size_of_main_inches, type_of_main, service_side,
    njaw_old_size_inches, njaw_old_material, njaw_new_size_inches, njaw_new_material,
    njaw_new_amount_feet, customer_old_size_inches, customer_old_material,
    customer_new_size_inches, customer_new_material, customer_new_amount_feet,
    multi_tenant, num_units, pitcher_delivered, downtime_hours, downtime_notified,
    existing_mp_noted, mp_horn_copper_inches
  )
  VALUES
    -- Property #1 (12 Maple Ridge Ave) — comprehensive 44-Dunnell-paper values
    ('dddddddd-0001-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','99999999-9999-9999-9999-999999999999',v_i1,
     DATE '2026-04-12','Demo Excavators LLC','FULL','Jordan Reed',72,'sunny',false,NULL,'city_strip',
     true,1,'Standard renewal — clean dig, no surprises.',53,44,
     480,180,180,42,180,84,22,
     6,'CAST IRON','long',
     0.75,'GALVANIZED',1,'COPPER',20,
     0.75,'GALVANIZED',1,'COPPER',45,
     false,NULL,false,2.5,true,
     true,18),
    -- Property #2 (44 Birch Hollow Rd) — M2C in flight
    ('dddddddd-0002-0000-0000-000000000002','bbbbbbbb-0000-0000-0000-000000000002','99999999-9999-9999-9999-999999999999',v_i2,
     DATE '2026-04-22','Sample Site Services','M2C','Casey Kim',68,'cloudy',false,NULL,'sidewalk',
     false,1,'Main-to-curb only; customer side already in spec.',48,42,
     NULL,NULL,NULL,40,170,80,NULL,
     8,'DUCTILE IRON','short',
     0.75,'COPPER',1,'COPPER',NULL,
     NULL,NULL,NULL,NULL,NULL,
     false,NULL,false,1.5,true,
     false,NULL),
    -- Property #3 (87 Oak Bend Way) — H2C done, restoration pending
    ('dddddddd-0003-0000-0000-000000000003','bbbbbbbb-0000-0000-0000-000000000003','99999999-9999-9999-9999-999999999999',v_i3,
     DATE '2026-03-30','Demo Excavators LLC','H2C','Jordan Reed',64,'cloudy',false,NULL,'lawn',
     false,1,'Curb-to-house, customer-side replacement.',50,40,
     360,150,150,38,170,NULL,18,
     6,'CAST IRON','long',
     NULL,NULL,NULL,NULL,NULL,
     0.75,'COPPER',1,'COPPER',32,
     false,NULL,false,2.0,true,
     true,15),
    -- Property #4 (156 Cedar Crest Ln) — KILL minimal
    ('dddddddd-0004-0000-0000-000000000004','bbbbbbbb-0000-0000-0000-000000000004','99999999-9999-9999-9999-999999999999',v_i1,
     DATE '2026-02-18','Sample Site Services','KILL','Casey Kim',45,'cloudy',false,'Kill at Main','city_strip',
     false,1,'Service abandonment. Subtype: ABANDON. House demolished 2025.',NULL,NULL,
     NULL,NULL,NULL,NULL,NULL,NULL,NULL,
     6,'CAST IRON','short',
     0.75,'LEAD',NULL,NULL,NULL,
     NULL,NULL,NULL,NULL,NULL,
     false,NULL,false,1.0,false,
     false,NULL),
    -- Property #9 (308 Hickory Hill Rd) — FULL + CS replacement (Carlo gate)
    ('dddddddd-0009-0000-0000-000000000009','bbbbbbbb-0000-0000-0000-000000000009','99999999-9999-9999-9999-999999999999',v_i2,
     DATE '2026-04-28','Demo Excavators LLC','FULL','Jordan Reed',76,'sunny',false,NULL,'driveway',
     true,2,'Full replacement; CS replaced under Carlo authorization (cs_house past corner).',55,46,
     -420,200,160,44,190,90,24,
     6,'CAST IRON','long',
     0.75,'LEAD',1.25,'COPPER',24,
     0.75,'LEAD',1.25,'COPPER',60,
     false,NULL,true,3.5,true,
     false,20)
  ON CONFLICT (id) DO NOTHING;
END $$;
