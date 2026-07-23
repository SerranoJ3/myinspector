-- POUR LEDGER (B2, ratified 2026-07-23) + B1 drawing image column. ADDITIVE ONLY.
-- Applied to prod via MCP apply_migration same day; this file mirrors it into repo history.
-- Pointer model: test_submissions stays the system of record; entries point at it.
-- MI-202 pattern throughout: RLS forced, active_firm + super_admin policies, write_audit_log triggers.

create table if not exists field_reports (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid not null references firms(id),
  project_id uuid not null references projects(id),
  report_no text not null,
  report_date date not null default current_date,
  shift text,
  family text not null default 'concrete_pour',
  status text not null default 'open' check (status in ('open','in_review','finalized')),
  owner_id uuid not null references profiles(id),
  opened_at timestamptz not null default now(),
  finalized_at timestamptz,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);
alter table field_reports enable row level security;
alter table field_reports force row level security;
create policy field_reports_active_firm on field_reports
  using (deleted_at is null and firm_id in (select firm_id from profiles where id = auth.uid()));
create policy field_reports_super_admin_all on field_reports
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_field_reports_insert after insert on field_reports for each row execute function write_audit_log();
create trigger audit_field_reports_update after update on field_reports for each row execute function write_audit_log();
create trigger audit_field_reports_delete after delete on field_reports for each row execute function write_audit_log();

create table if not exists report_entries (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references field_reports(id),
  firm_id uuid not null references firms(id),
  seq int not null,
  entry_kind text not null check (entry_kind in ('ticket','test','sample','note')),
  payload jsonb not null default '{}'::jsonb,
  submission_id uuid references test_submissions(id),
  corrects_entry_id uuid references report_entries(id),
  entered_by uuid not null references profiles(id),
  entered_at timestamptz not null default now(),
  unique (report_id, seq)
);
alter table report_entries enable row level security;
alter table report_entries force row level security;
create policy report_entries_select_firm on report_entries for select
  using (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy report_entries_insert_firm on report_entries for insert
  with check (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy report_entries_super_admin_all on report_entries
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'))
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_report_entries_insert after insert on report_entries for each row execute function write_audit_log();
create trigger audit_report_entries_update after update on report_entries for each row execute function write_audit_log();
create trigger audit_report_entries_delete after delete on report_entries for each row execute function write_audit_log();

create table if not exists report_roles (
  id uuid primary key default gen_random_uuid(),
  report_id uuid not null references field_reports(id),
  firm_id uuid not null references firms(id),
  user_id uuid not null references profiles(id),
  role text not null check (role in ('writer','tickets','tests','samples')),
  assigned_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  unique (report_id, user_id, role)
);
alter table report_roles enable row level security;
alter table report_roles force row level security;
create policy report_roles_firm on report_roles
  using (firm_id in (select firm_id from profiles where id = auth.uid()))
  with check (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy report_roles_super_admin_all on report_roles
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'))
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_report_roles_insert after insert on report_roles for each row execute function write_audit_log();
create trigger audit_report_roles_update after update on report_roles for each row execute function write_audit_log();
create trigger audit_report_roles_delete after delete on report_roles for each row execute function write_audit_log();

alter table test_types add column if not exists accretive boolean not null default false;
update test_types set accretive = true where tab = 'concrete';

alter table job_drawings add column if not exists image_path text;

create or replace function next_entry_seq(p_report uuid) returns int
language sql stable as $$
  select coalesce(max(seq),0)+1 from report_entries where report_id = p_report;
$$;
