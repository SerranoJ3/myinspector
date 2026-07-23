-- SIGNUP P0 (2026-07-23): server-side profile creation — kills the client-side
-- race (signUp → unchecked failed signIn → RLS-rejected insert → orphaned user).
-- Applied to prod via MCP same night; this file mirrors it into repo history.
-- Role rule: FIRST user of a firm → owner; subsequent → inspector.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_firm_id uuid;
  v_role text;
begin
  select f.id into v_firm_id
  from public.firms f
  where upper(f.firm_code) = upper(coalesce(new.raw_user_meta_data->>'firm_code',''))
  limit 1;

  if v_firm_id is null then
    return new;
  end if;

  select case when exists (select 1 from public.profiles p where p.firm_id = v_firm_id)
              then 'inspector' else 'owner' end
  into v_role;

  insert into public.profiles (id, full_name, firm_id, role, email)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name',''),
          v_firm_id, v_role, new.email)
  on conflict (id) do nothing;

  return new;
exception when others then
  begin
    perform public.record_compliance_event(
      'signup_profile_trigger_error', SQLERRM, 'error',
      jsonb_build_object('user_id', new.id), 'handle_new_user', null);
  exception when others then null;
  end;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
