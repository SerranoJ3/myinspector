-- mi_demo_seed_09_cs_authorization: Carlo authorization for property #9 FULL submission.
-- Calls submit_cs_authorization RPC (INSERT-only, audit-logged, immutability gate).
-- Idempotent: skip if row already exists for this phase_submission_id.
--
-- Note: RPC signature verified via pg_proc 2026-05-06 18:30 EDT:
--   submit_cs_authorization(p_phase_submission_id uuid, p_supervisor_name text,
--                           p_authorized_at timestamptz, p_reason text)
-- Spec §13 had stale signature (split date+time fields); corrected here.

DO $$
DECLARE
  v_actor uuid; v_actor_email text;
  v_phase_sub_id uuid := 'cccccccc-0009-0002-0000-000000000020';
  v_existing int;
BEGIN
  SELECT id, email INTO v_actor, v_actor_email
  FROM public.profiles WHERE email='demo-supervisor@myinspector.io';
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_actor::text, 'email', v_actor_email)::text, true);

  SELECT COUNT(*) INTO v_existing
  FROM public.cs_replacement_authorizations
  WHERE phase_submission_id = v_phase_sub_id;

  IF v_existing = 0 THEN
    PERFORM public.submit_cs_authorization(
      v_phase_sub_id,
      'Demo Supervisor (Carlo placeholder)',
      TIMESTAMPTZ '2026-04-28 13:30:00+00',
      'Demo CS replacement — homeowner verified leak past corner per CDM-Smith rule e (cs_house_inches negative on materials_sheet). Authorization recorded for compliance audit.'
    );
  END IF;
END $$;
