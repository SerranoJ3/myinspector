-- DFR FIELD LAYER (spec + Addendum 1, 2026-07-23). Applied to prod via MCP same
-- night; mirrored here. Additive only.
-- Keying per Addendum 1: (project, date, technician) — each tech signs HIS day.
-- Status carries the FULL office vocabulary so the office layer bolts on later
-- without touching existing rows. MI-202 pattern throughout.

create table if not exists daily_field_reports (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid not null references firms(id),
  project_id uuid not null references projects(id),
  report_date date not null default current_date,
  technician_id uuid not null references profiles(id),
  report_no text not null,
  location_of_work text,
  narrative text,
  discrepancies boolean,
  discrepancy_summary text,
  status text not null default 'open' check (status in ('open','submitted','in_review','returned','approved','delivered')),
  opened_at timestamptz not null default now(),
  submitted_at timestamptz,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (project_id, report_date, technician_id)
);
alter table daily_field_reports enable row level security;
alter table daily_field_reports force row level security;
create policy dfr_active_firm on daily_field_reports
  using (deleted_at is null and firm_id in (select firm_id from profiles where id = auth.uid()));
create policy dfr_super_admin_all on daily_field_reports
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_daily_field_reports_insert after insert on daily_field_reports for each row execute function write_audit_log();
create trigger audit_daily_field_reports_update after update on daily_field_reports for each row execute function write_audit_log();
create trigger audit_daily_field_reports_delete after delete on daily_field_reports for each row execute function write_audit_log();

create table if not exists dfr_contributors (
  id uuid primary key default gen_random_uuid(),
  daily_report_id uuid not null references daily_field_reports(id),
  firm_id uuid not null references firms(id),
  user_id uuid not null references profiles(id),
  added_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  unique (daily_report_id, user_id)
);
alter table dfr_contributors enable row level security;
alter table dfr_contributors force row level security;
create policy dfr_contributors_firm on dfr_contributors
  using (firm_id in (select firm_id from profiles where id = auth.uid()))
  with check (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy dfr_contributors_super_admin_all on dfr_contributors
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'))
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_dfr_contributors_insert after insert on dfr_contributors for each row execute function write_audit_log();
create trigger audit_dfr_contributors_update after update on dfr_contributors for each row execute function write_audit_log();
create trigger audit_dfr_contributors_delete after delete on dfr_contributors for each row execute function write_audit_log();

-- THIRD-PARTY TICKETS — the photo IS the object; capture never blocks; APPEND-ONLY
create table if not exists field_tickets (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid not null references firms(id),
  project_id uuid not null references projects(id),
  daily_report_id uuid references daily_field_reports(id),
  ticket_type text not null default 'concrete' check (ticket_type in ('concrete','fill','other')),
  ticket_no text,
  supplier text,
  material text,
  quantity numeric,
  unit text,
  batch_time text,
  water_added text,
  truck_no text,
  image_path text not null,
  captured_by uuid not null references profiles(id),
  captured_at timestamptz not null default now(),
  ledger_entry_id uuid references report_entries(id),
  submission_id uuid references test_submissions(id),
  voided_by_ticket_id uuid references field_tickets(id)
);
alter table field_tickets enable row level security;
alter table field_tickets force row level security;
create policy field_tickets_select_firm on field_tickets for select
  using (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy field_tickets_insert_firm on field_tickets for insert
  with check (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy field_tickets_super_admin_all on field_tickets
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'))
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_field_tickets_insert after insert on field_tickets for each row execute function write_audit_log();
create trigger audit_field_tickets_update after update on field_tickets for each row execute function write_audit_log();
create trigger audit_field_tickets_delete after delete on field_tickets for each row execute function write_audit_log();

-- the pour ledger lives INSIDE the day
alter table field_reports add column if not exists daily_report_id uuid references daily_field_reports(id);
