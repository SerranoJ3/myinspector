-- mi_demo_seed_06_properties: 12 properties (10 NJ6_NORMAL + 2 NJAW_SHORT_HILLS).
-- Deterministic UUIDs bbbbbbbb-0000-0000-0000-00000000NNNN.
-- Idempotent: ON CONFLICT (id) DO NOTHING.

DO $$
DECLARE
  v_actor uuid; v_actor_email text;
BEGIN
  SELECT id, email INTO v_actor, v_actor_email
  FROM public.profiles WHERE email='demo-jorge@myinspector.io';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'email', v_actor_email)::text, true);

  INSERT INTO public.properties (
    id, firm_id, project_id, address, city, municipality, state, zip,
    lot_block, lat, lng, mapcall_id, sector, current_phase
  )
  VALUES
    ('bbbbbbbb-0000-0000-0000-000000000001','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','12 Maple Ridge Ave','Maplewood','Maplewood','NJ','07040','Lot 12 / Block 4',40.7312,-74.2735,'DEMO-MC-0001','NJ6_NORMAL','tapcard'),
    ('bbbbbbbb-0000-0000-0000-000000000002','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','44 Birch Hollow Rd','Maplewood','Maplewood','NJ','07040','Lot 7 / Block 18',40.7301,-74.2752,'DEMO-MC-0002','NJ6_NORMAL','service_work'),
    ('bbbbbbbb-0000-0000-0000-000000000003','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','87 Oak Bend Way','Millburn','Millburn','NJ','07041','Lot 23 / Block 9',40.7259,-74.2987,'DEMO-MC-0003','NJ6_NORMAL','restoration'),
    ('bbbbbbbb-0000-0000-0000-000000000004','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','156 Cedar Crest Ln','Maplewood','Maplewood','NJ','07040','Lot 4 / Block 22',40.7321,-74.2710,'DEMO-MC-0004','NJ6_NORMAL','gis_docs'),
    ('bbbbbbbb-0000-0000-0000-000000000005','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','203 Pine Vista Dr','Millburn','Millburn','NJ','07041','Lot 15 / Block 11',40.7268,-74.2965,'DEMO-MC-0005','NJ6_NORMAL','assessment'),
    ('bbbbbbbb-0000-0000-0000-000000000006','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','9 Willow Park Pl','Maplewood','Maplewood','NJ','07040','Lot 31 / Block 5',40.7290,-74.2741,'DEMO-MC-0006','NJ6_NORMAL','test_pit'),
    ('bbbbbbbb-0000-0000-0000-000000000007','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','71 Elm Forest Ct','Maplewood','Maplewood','NJ','07040','Lot 19 / Block 13',40.7305,-74.2728,'DEMO-MC-0007','NJ6_NORMAL','work_order'),
    ('bbbbbbbb-0000-0000-0000-000000000008','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','22 Ash Grove Ter','Millburn','Millburn','NJ','07041','Lot 8 / Block 27',40.7278,-74.2972,'DEMO-MC-0008','NJ6_NORMAL','no_work'),
    ('bbbbbbbb-0000-0000-0000-000000000009','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','308 Hickory Hill Rd','Maplewood','Maplewood','NJ','07040','Lot 27 / Block 17',40.7298,-74.2748,'DEMO-MC-0009','NJ6_NORMAL','service_work'),
    ('bbbbbbbb-0000-0000-0000-000000000010','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','55 Sycamore Ridge Blvd','Maplewood','Maplewood','NJ','07040','Lot 11 / Block 8',40.7314,-74.2725,'DEMO-MC-0010','NJ6_NORMAL','out_of_order'),
    ('bbbbbbbb-0000-0000-0000-000000000011','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','14 Cliff View Ln','Short Hills','Millburn','NJ','07078','Lot 5 / Block 33',40.7458,-74.3231,'DEMO-MC-0011','NJAW_SHORT_HILLS','service_work'),
    ('bbbbbbbb-0000-0000-0000-000000000012','99999999-9999-9999-9999-999999999999','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','28 Highland Crest Pl','Short Hills','Millburn','NJ','07078','Lot 17 / Block 41',40.7463,-74.3244,'DEMO-MC-0012','NJAW_SHORT_HILLS','tapcard')
  ON CONFLICT (id) DO NOTHING;
END $$;
