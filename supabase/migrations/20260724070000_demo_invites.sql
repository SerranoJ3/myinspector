-- DEMO INVITES (Jorge's ruling 2026-07-24): a temp code per outreach email.
-- Telemetry is the point: last_used_at + use_count = the warm-lead cohort
-- silence would otherwise hide. Applied to prod via MCP; mirrored here.
-- Additive; MI-202 pattern; prospects touch the table ONLY through the
-- definer RPC (no anon policies).

create table if not exists demo_invites (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  firm_name text not null,
  contact_name text,
  contact_email text,
  source text,
  notes text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '30 days',
  last_used_at timestamptz,
  use_count int not null default 0,
  created_by uuid references profiles(id)
);
alter table demo_invites enable row level security;
alter table demo_invites force row level security;
create policy demo_invites_super_admin_all on demo_invites
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'))
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_demo_invites_insert after insert on demo_invites for each row execute function write_audit_log();
create trigger audit_demo_invites_update after update on demo_invites for each row execute function write_audit_log();
create trigger audit_demo_invites_delete after delete on demo_invites for each row execute function write_audit_log();

create or replace function public.redeem_demo_invite(p_code text)
returns table(firm_name text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare v demo_invites%rowtype;
begin
  select * into v from demo_invites d
    where upper(d.code) = upper(trim(p_code)) limit 1;
  if v.id is null or v.expires_at < now() then return; end if;
  update demo_invites set use_count = use_count + 1, last_used_at = now() where id = v.id;
  return query select v.firm_name;
end;
$$;
grant execute on function public.redeem_demo_invite(text) to anon, authenticated;
