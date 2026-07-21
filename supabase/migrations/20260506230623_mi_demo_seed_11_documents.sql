-- mi_demo_seed_11_documents: 3 document metadata rows. No storage objects.
-- SCHEMA DRIFT NOTE: spec §14 said "file_name"; actual column is "name". Spec also
-- omitted required NOT NULL "file_url" — added with placeholder URL (no Storage write).
-- Idempotent: ON CONFLICT (id) DO NOTHING.

DO $$
DECLARE
  v_actor uuid; v_actor_email text;
  v_i1 uuid;
BEGIN
  SELECT id, email INTO v_actor, v_actor_email
  FROM public.profiles WHERE email='demo-jorge@myinspector.io';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'email', v_actor_email)::text, true);

  SELECT id INTO v_i1 FROM public.profiles WHERE email='demo-inspector-1@myinspector.io';

  INSERT INTO public.documents (id, project_id, firm_id, module_key, name, file_url, file_type, description, uploaded_by)
  VALUES
    ('ffffffff-0001-0000-0000-000000000001','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','99999999-9999-9999-9999-999999999999','water_utility','Demo LSL Program Charter.pdf','https://placehold.co/file?type=pdf','application/pdf','Project charter for demo LSL replacement program.',v_actor),
    ('ffffffff-0002-0000-0000-000000000002','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','99999999-9999-9999-9999-999999999999','water_utility','Sample Tapcard Template.pdf','https://placehold.co/file?type=pdf','application/pdf','Reference tapcard template (sanitized demo copy).',v_actor),
    ('ffffffff-0003-0000-0000-000000000003','aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa','99999999-9999-9999-9999-999999999999','water_utility','CDM-Smith Rules Cheat Sheet.pdf','https://placehold.co/file?type=pdf','application/pdf','Rules a-e summarized for demo inspectors.',v_i1)
  ON CONFLICT (id) DO NOTHING;
END $$;
