-- mi_demo_seed_04_create_demo_auth_users_via_sql
--
-- Replaces §17 step 4 (Edge Function invoke) per Buddy escalation 2026-05-06.
-- The seed-demo-users Edge Function deployed v1 ACTIVE but `auth.admin.listUsers`
-- threw "Database error finding users" on all 5 invocations (5/5 errors). Root
-- cause unknown — likely a supabase-js@2.45.4 compatibility issue with the
-- current gotrue admin API. Function deployed for future SDK-version retry;
-- this migration replaces it for the seed run.
--
-- Direct INSERT to auth.users + auth.identities + public.profiles for 5 demo
-- users with deterministic UUIDs 99999991-0000-0000-0000-00000000000N.
-- Password: Demo2026! (bcrypted via crypt() with bf salt — same algorithm
-- gotrue uses internally). aud='authenticated', role='authenticated',
-- instance_id=zero UUID (Supabase default).
--
-- Audit attribution per §16a (a): all 5 INSERTs attributed to demo-jorge
-- (super_admin self-creation + 4 user creations). request.jwt.claims set
-- once at top of DO block; audit_log_chain_trigger reads from it.

DO $$
DECLARE
  v_pwd_hash text;
  v_user record;
  v_jorge_id uuid := '99999991-0000-0000-0000-000000000001';
BEGIN
  v_pwd_hash := crypt('Demo2026!', gen_salt('bf'));

  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', v_jorge_id::text, 'email', 'demo-jorge@myinspector.io')::text, true);

  FOR v_user IN
    SELECT * FROM (VALUES
      (v_jorge_id, 'demo-jorge@myinspector.io', 'super_admin', 'Demo Admin'),
      ('99999991-0000-0000-0000-000000000002'::uuid, 'demo-supervisor@myinspector.io', 'supervisor', 'Pat Morgan'),
      ('99999991-0000-0000-0000-000000000003'::uuid, 'demo-inspector-1@myinspector.io', 'inspector', 'Sam Brooks'),
      ('99999991-0000-0000-0000-000000000004'::uuid, 'demo-inspector-2@myinspector.io', 'inspector', 'Riley Sample'),
      ('99999991-0000-0000-0000-000000000005'::uuid, 'demo-inspector-3@myinspector.io', 'inspector', 'Drew Carter')
    ) AS t(id, email, role, full_name)
  LOOP
    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_user_meta_data, raw_app_meta_data,
      created_at, updated_at, confirmation_token, recovery_token,
      email_change_token_new, email_change
    )
    VALUES (
      v_user.id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      v_user.email,
      v_pwd_hash,
      NOW(),
      jsonb_build_object(
        'sub', v_user.id::text,
        'email', v_user.email,
        'full_name', v_user.full_name,
        'firm_id', '99999999-9999-9999-9999-999999999999',
        'role', v_user.role,
        'email_verified', true,
        'phone_verified', false
      ),
      jsonb_build_object('provider','email','providers',jsonb_build_array('email')),
      NOW(), NOW(), '', '', '', ''
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO auth.identities (
      id, user_id, provider, provider_id, identity_data, created_at, updated_at, last_sign_in_at
    )
    VALUES (
      gen_random_uuid(),
      v_user.id,
      'email',
      v_user.id::text,
      jsonb_build_object(
        'sub', v_user.id::text,
        'email', v_user.email,
        'full_name', v_user.full_name,
        'email_verified', true,
        'phone_verified', false
      ),
      NOW(), NOW(), NOW()
    )
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, firm_id, email, full_name, role)
    VALUES (
      v_user.id,
      '99999999-9999-9999-9999-999999999999',
      v_user.email,
      v_user.full_name,
      v_user.role
    )
    ON CONFLICT (id) DO UPDATE
      SET firm_id = EXCLUDED.firm_id,
          email = EXCLUDED.email,
          full_name = EXCLUDED.full_name,
          role = EXCLUDED.role;
  END LOOP;
END $$;
