-- mi_demo_seed_08_phase_submissions: 25 phase_submissions across 12 properties.
-- Coverage: all 9 phase enum values + all 6 NJAW work order codes + 1 KILL with subtype.
-- submitted_by rotates inspector-1/2/3. Idempotent: ON CONFLICT (id) DO NOTHING.
--
-- Drift fix 2026-05-06 ~23:05 EDT (Buddy direct apply): original draft omitted
-- photo_no_work_whiteboard_detected column from INSERT, which is required = TRUE
-- by phase_submissions_no_work_invariant CHECK on the no_work row (#18).
-- Added column to INSERT list with TRUE for no_work row, NULL elsewhere.

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

  INSERT INTO public.phase_submissions (
    id, property_id, firm_id, submitted_by, phase, work_order_code, njaw_work_order_code,
    submitted_at, notes, tapcard_data, materials_sheet_id, cs_replacement,
    photo_curbstop_url, photo_curbstop_whiteboard,
    photo_watermain_url, photo_watermain_whiteboard,
    photo_restoration_url, photo_restoration_whiteboard,
    photo_house_url, photo_no_work_whiteboard_url, photo_no_work_whiteboard_detected, no_work_reason,
    out_of_sequence, sequence_note
  )
  VALUES
    ('cccccccc-0001-0001-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','99999999-9999-9999-9999-999999999999',v_i1,'test_pit','LSL-R','TP', '2026-03-15 09:30:00+00','Test pit verified lead service. Soil dry, dig clear.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+1',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0001-0002-0000-000000000002','bbbbbbbb-0000-0000-0000-000000000001','99999999-9999-9999-9999-999999999999',v_i1,'assessment','LSL-R','TP', '2026-03-22 11:15:00+00','Property assessed. Customer briefed on schedule.','{}'::jsonb,NULL,false,NULL,false,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0001-0003-0000-000000000003','bbbbbbbb-0000-0000-0000-000000000001','99999999-9999-9999-9999-999999999999',v_i1,'service_work','LSL-R','FULL', '2026-04-12 13:45:00+00','Full LSL replacement complete.','{}'::jsonb,'dddddddd-0001-0000-0000-000000000001',false,'https://placehold.co/600x800?text=DEMO+Curbstop+1+post',true,'https://placehold.co/600x800?text=DEMO+Watermain+1',true,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0001-0004-0000-000000000004','bbbbbbbb-0000-0000-0000-000000000001','99999999-9999-9999-9999-999999999999',v_i1,'tapcard','LSL-R','FULL', '2026-04-13 10:00:00+00','Tapcard finalized.','{"service_number":"DEMO-SVC-0001","task_numbers":"DEMO-TASK-A,DEMO-TASK-B,DEMO-TASK-C","tied_in":"Y","plug_lock":"Y","cust_mat":"COPPER","size_inches":1,"date_installed":"2026-04-12","installed_by":"Demo Excavators LLC","completed_by":"Sam Brooks"}'::jsonb,'dddddddd-0001-0000-0000-000000000001',false,NULL,false,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0002-0001-0000-000000000005','bbbbbbbb-0000-0000-0000-000000000002','99999999-9999-9999-9999-999999999999',v_i2,'test_pit','LSL-R','TP', '2026-04-08 08:30:00+00','Test pit confirmed M2C scope.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+2',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0002-0002-0000-000000000006','bbbbbbbb-0000-0000-0000-000000000002','99999999-9999-9999-9999-999999999999',v_i2,'service_work','LSL-R','M2C', '2026-04-22 14:00:00+00','Main-to-curb installation complete.','{}'::jsonb,'dddddddd-0002-0000-0000-000000000002',false,'https://placehold.co/600x800?text=DEMO+Curbstop+2+post',true,'https://placehold.co/600x800?text=DEMO+Watermain+2',true,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0003-0001-0000-000000000007','bbbbbbbb-0000-0000-0000-000000000003','99999999-9999-9999-9999-999999999999',v_i3,'test_pit','LSL-R','TP', '2026-03-20 09:00:00+00','Test pit done.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+3',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0003-0002-0000-000000000008','bbbbbbbb-0000-0000-0000-000000000003','99999999-9999-9999-9999-999999999999',v_i3,'service_work','LSL-R','H2C', '2026-03-30 11:00:00+00','House-to-curb replacement complete.','{}'::jsonb,'dddddddd-0003-0000-0000-000000000003',false,'https://placehold.co/600x800?text=DEMO+Curbstop+3+post',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0003-0003-0000-000000000009','bbbbbbbb-0000-0000-0000-000000000003','99999999-9999-9999-9999-999999999999',v_i3,'restoration','LSL-R','H2C', '2026-04-05 13:00:00+00','Restoration complete: asphalt patch + grading.','{}'::jsonb,'dddddddd-0003-0000-0000-000000000003',false,NULL,false,NULL,false,'https://placehold.co/600x800?text=DEMO+Restoration+3',true,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0004-0001-0000-000000000010','bbbbbbbb-0000-0000-0000-000000000004','99999999-9999-9999-9999-999999999999',v_i1,'test_pit','LSL-R','TP', '2026-02-10 10:00:00+00','Test pit confirmed lead. House marked for demolition.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+4',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0004-0002-0000-000000000011','bbbbbbbb-0000-0000-0000-000000000004','99999999-9999-9999-9999-999999999999',v_i1,'service_work','LSL-R','KILL', '2026-02-18 09:30:00+00','Service abandoned at main per demolition coordinator.','{"subtype":"ABANDON","kill_location":"Kill at Main"}'::jsonb,'dddddddd-0004-0000-0000-000000000004',false,'https://placehold.co/600x800?text=DEMO+Curbstop+4+kill',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0004-0003-0000-000000000012','bbbbbbbb-0000-0000-0000-000000000004','99999999-9999-9999-9999-999999999999',v_i1,'gis_docs','LSL-R','KILL', '2026-02-25 10:00:00+00','GIS docs filed for kill record.','{}'::jsonb,NULL,false,NULL,false,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0005-0001-0000-000000000013','bbbbbbbb-0000-0000-0000-000000000005','99999999-9999-9999-9999-999999999999',v_i2,'test_pit','LSL-R','TP', '2026-04-25 09:00:00+00','TP done; service line scope determined.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+5',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0005-0002-0000-000000000014','bbbbbbbb-0000-0000-0000-000000000005','99999999-9999-9999-9999-999999999999',v_i2,'assessment','LSL-R','TP', '2026-05-01 10:00:00+00','Customer scheduled for service work next week.','{}'::jsonb,NULL,false,NULL,false,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0006-0001-0000-000000000015','bbbbbbbb-0000-0000-0000-000000000006','99999999-9999-9999-9999-999999999999',v_i3,'test_pit','LSL-R','TP', '2026-05-04 14:00:00+00','Test pit complete; awaiting CP scheduling.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+6',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0007-0001-0000-000000000016','bbbbbbbb-0000-0000-0000-000000000007','99999999-9999-9999-9999-999999999999',v_i1,'test_pit','LSL-R','TP', '2026-04-15 09:00:00+00','MP only scope confirmed.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+7',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0007-0002-0000-000000000017','bbbbbbbb-0000-0000-0000-000000000007','99999999-9999-9999-9999-999999999999',v_i1,'work_order','LSL-R','MP', '2026-04-26 10:30:00+00','Meter pit installed.','{}'::jsonb,NULL,false,NULL,false,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0008-0001-0000-000000000018','bbbbbbbb-0000-0000-0000-000000000008','99999999-9999-9999-9999-999999999999',v_i2,'no_work','INS',NULL, '2026-04-20 11:00:00+00','Homeowner refused entry. Photos + whiteboard captured per CDM-Smith rule a.','{}'::jsonb,NULL,false,NULL,false,NULL,false,NULL,false,'https://placehold.co/600x800?text=DEMO+House+8','https://placehold.co/600x800?text=DEMO+Whiteboard+8+refused',true,'Homeowner refused service after multiple scheduling attempts. Per CDM-Smith rule a, photos + whiteboard documented.',false,NULL),
    ('cccccccc-0009-0001-0000-000000000019','bbbbbbbb-0000-0000-0000-000000000009','99999999-9999-9999-9999-999999999999',v_i2,'test_pit','LSL-R','TP', '2026-04-18 09:00:00+00','TP confirmed CS past corner — CS replacement required.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+9',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0009-0002-0000-000000000020','bbbbbbbb-0000-0000-0000-000000000009','99999999-9999-9999-9999-999999999999',v_i2,'service_work','LSL-R','FULL', '2026-04-28 14:00:00+00','Full replacement + CS replacement under Carlo authorization (cs_replacement=true).','{}'::jsonb,'dddddddd-0009-0000-0000-000000000009',true,'https://placehold.co/600x800?text=DEMO+Curbstop+9+post',true,'https://placehold.co/600x800?text=DEMO+Watermain+9',true,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0010-0001-0000-000000000021','bbbbbbbb-0000-0000-0000-000000000010','99999999-9999-9999-9999-999999999999',v_i3,'test_pit','LSL-R','TP', '2026-04-22 09:00:00+00','TP done.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+10',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0010-0002-0000-000000000022','bbbbbbbb-0000-0000-0000-000000000010','99999999-9999-9999-9999-999999999999',v_i3,'out_of_order','LSL-R',NULL, '2026-04-30 16:00:00+00','Submitted out of sequence per supervisor approval.','{}'::jsonb,NULL,false,NULL,false,NULL,false,NULL,false,NULL,NULL,NULL,NULL,true,'Customer scheduling conflict required out-of-sequence submission. Phase swap approved by supervisor.'),
    ('cccccccc-0011-0001-0000-000000000023','bbbbbbbb-0000-0000-0000-000000000011','99999999-9999-9999-9999-999999999999',v_i1,'test_pit','LSL-R','TP', '2026-04-10 09:00:00+00','TP done. ShortHills sector — inspector dictating means/methods.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+11+SH',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0011-0002-0000-000000000024','bbbbbbbb-0000-0000-0000-000000000011','99999999-9999-9999-9999-999999999999',v_i1,'service_work','LSL-R','H2C', '2026-04-26 13:00:00+00','H2C complete. Inspector handled homeowner contact directly per ShortHills protocol.','{}'::jsonb,NULL,false,'https://placehold.co/600x800?text=DEMO+Curbstop+11+SH+post',true,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL),
    ('cccccccc-0012-0001-0000-000000000025','bbbbbbbb-0000-0000-0000-000000000012','99999999-9999-9999-9999-999999999999',v_i2,'tapcard','LSL-R','FULL', '2026-05-02 11:00:00+00','Tapcard finalized for ShortHills property.','{"service_number":"DEMO-SVC-0012","task_numbers":"DEMO-TASK-12A","tied_in":"Y","plug_lock":"Y","cust_mat":"COPPER","size_inches":1,"date_installed":"2026-04-30","installed_by":"Sample Site Services","completed_by":"Riley Sample"}'::jsonb,NULL,false,NULL,false,NULL,false,NULL,false,NULL,NULL,NULL,NULL,false,NULL)
  ON CONFLICT (id) DO NOTHING;
END $$;
