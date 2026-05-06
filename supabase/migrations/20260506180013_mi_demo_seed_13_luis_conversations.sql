-- mi_demo_seed_13_luis_conversations: 2 short Luis conversations.
-- SCHEMA NOTE: actual schema has user_id (not submitted_by), question/answer NOT NULL,
-- sources text[] (array). No tokens/cost columns (good — spec said tokens=0 anyway).
-- Idempotent: ON CONFLICT (id) DO NOTHING.

DO $$
DECLARE
  v_actor uuid; v_actor_email text;
  v_i1 uuid; v_i2 uuid;
BEGIN
  SELECT id, email INTO v_actor, v_actor_email
  FROM public.profiles WHERE email='demo-jorge@myinspector.io';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'email', v_actor_email)::text, true);

  SELECT id INTO v_i1 FROM public.profiles WHERE email='demo-inspector-1@myinspector.io';
  SELECT id INTO v_i2 FROM public.profiles WHERE email='demo-inspector-2@myinspector.io';

  INSERT INTO public.luis_conversations (id, user_id, project_id, firm_id, module_key, question, answer, sources)
  VALUES
    ('00000000-0001-0000-0000-000000000001',v_i1,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','99999999-9999-9999-9999-999999999999','water_utility',
     'How do I prep a homeowner for tomorrow''s service work at 12 Maple Ridge Ave?',
     'Standard pre-visit prep: knock on door 30 min before crew arrives, confirm water shutoff window (typically 2-4 hours for FULL), explain pitcher will be left if extended downtime. For 12 Maple Ridge specifically, tapcard shows FULL replacement with 1" copper — typical 2.5 hour job. Confirm parking access for crew truck and excavator.',
     ARRAY['NJAW field workflow guide §3.2','CDM-Smith homeowner-prep memo (4/30/26)']),
    ('00000000-0002-0000-0000-000000000002',v_i2,'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','99999999-9999-9999-9999-999999999999','water_utility',
     'What''s the rule for plastic pipe on customer side?',
     'Plastic (PEX-A or equivalent) is approved for customer side as of 1/2/26 per NJAW spec update. Sizing 3/4" to 2" same as copper. NOT approved for company side — copper only on company side regardless of property age. If you see existing plastic on company side, flag as out-of-spec and submit RFI.',
     ARRAY['NJAW utility rules (4/30/26 lock)','MyInspector CLAUDE.md NJAW codes section'])
  ON CONFLICT (id) DO NOTHING;
END $$;
