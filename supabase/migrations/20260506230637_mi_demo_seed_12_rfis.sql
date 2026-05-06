-- mi_demo_seed_12_rfis: 2 RFI rows ('open' status).
-- SCHEMA DRIFT NOTE: spec §14 implied "routed to demo-supervisor"; actual schema has
-- no routing column. submitted_by carries the originator; routing is implicit.
-- Required NOT NULL fields: rfi_number, subject. Idempotent: ON CONFLICT (id) DO NOTHING.

DO $$
DECLARE
  v_actor uuid; v_actor_email text;
  v_i1 uuid; v_i2 uuid;
BEGIN
  SELECT id, email INTO v_actor, v_actor_email
  FROM public.profiles WHERE email='demo-supervisor@myinspector.io';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'email', v_actor_email)::text, true);

  SELECT id INTO v_i1 FROM public.profiles WHERE email='demo-inspector-1@myinspector.io';
  SELECT id INTO v_i2 FROM public.profiles WHERE email='demo-inspector-2@myinspector.io';

  INSERT INTO public.rfis (id, project_id, firm_id, rfi_number, subject, description, submitted_by, status, priority, due_date)
  VALUES
    ('99990000-0001-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','99999999-9999-9999-9999-999999999999','RFI-DEMO-001','Clarification on cs_house past-corner sign convention',
     'Inspector needs guidance on negative sign for cs_house when curbstop is past corner of property line. CDM-Smith rule e references this; want confirmation for property #9 (308 Hickory Hill Rd).',
     v_i1,'open','medium',DATE '2026-05-15'),
    ('99990000-0002-0000-0000-000000000002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','99999999-9999-9999-9999-999999999999','RFI-DEMO-002','Plastic pipe acceptance for customer side',
     'Per 1/2/26 update, plastic OK on customer side. Need spec confirmation for size 1" plastic (PEX-A) at property #5 (203 Pine Vista Dr).',
     v_i2,'open','low',DATE '2026-05-20')
  ON CONFLICT (id) DO NOTHING;
END $$;
