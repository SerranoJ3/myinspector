-- OFFICE SIDE items 1-3 (spec 2026-07-23): review queue + prose versioning +
-- firm glossary. No AI anywhere. Applied to prod via MCP; mirrored here.
-- MI-202 pattern. Additive only.
-- dfr_review_notes: return-to-tech kickback (a real status, not an email); append-only.
-- dfr_prose_versions: PROSE IS SYNTHESIZED, DATA IS SACRED (Addendum 2) — office
--   rewrites are NEW VERSIONS; the technician's original words are v1, forever.
-- firm_glossary: the visible, editable term map (config, not evidence).

create table if not exists dfr_review_notes (
  id uuid primary key default gen_random_uuid(),
  daily_report_id uuid not null references daily_field_reports(id),
  firm_id uuid not null references firms(id),
  note text not null,
  author uuid not null references profiles(id),
  created_at timestamptz not null default now()
);
alter table dfr_review_notes enable row level security;
alter table dfr_review_notes force row level security;
create policy dfr_review_notes_select_firm on dfr_review_notes for select
  using (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy dfr_review_notes_insert_firm on dfr_review_notes for insert
  with check (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy dfr_review_notes_super_admin_all on dfr_review_notes
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'))
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_dfr_review_notes_insert after insert on dfr_review_notes for each row execute function write_audit_log();
create trigger audit_dfr_review_notes_update after update on dfr_review_notes for each row execute function write_audit_log();
create trigger audit_dfr_review_notes_delete after delete on dfr_review_notes for each row execute function write_audit_log();

create table if not exists dfr_prose_versions (
  id uuid primary key default gen_random_uuid(),
  daily_report_id uuid not null references daily_field_reports(id),
  firm_id uuid not null references firms(id),
  field text not null check (field in ('narrative','discrepancy_summary')),
  version_no int not null,
  text text not null,
  source text not null check (source in ('field','office','ai_draft')),
  authored_by uuid not null references profiles(id),
  authored_at timestamptz not null default now(),
  unique (daily_report_id, field, version_no)
);
alter table dfr_prose_versions enable row level security;
alter table dfr_prose_versions force row level security;
create policy dfr_prose_versions_select_firm on dfr_prose_versions for select
  using (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy dfr_prose_versions_insert_firm on dfr_prose_versions for insert
  with check (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy dfr_prose_versions_super_admin_all on dfr_prose_versions
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'))
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_dfr_prose_versions_insert after insert on dfr_prose_versions for each row execute function write_audit_log();
create trigger audit_dfr_prose_versions_update after update on dfr_prose_versions for each row execute function write_audit_log();
create trigger audit_dfr_prose_versions_delete after delete on dfr_prose_versions for each row execute function write_audit_log();

create table if not exists firm_glossary (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid not null references firms(id),
  term_in text not null,
  term_out text not null,
  added_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (firm_id, term_in)
);
alter table firm_glossary enable row level security;
alter table firm_glossary force row level security;
create policy firm_glossary_active_firm on firm_glossary
  using (deleted_at is null and firm_id in (select firm_id from profiles where id = auth.uid()))
  with check (firm_id in (select firm_id from profiles where id = auth.uid()));
create policy firm_glossary_super_admin_all on firm_glossary
  using (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'))
  with check (exists (select 1 from profiles where id = auth.uid() and role = 'super_admin'));
create trigger audit_firm_glossary_insert after insert on firm_glossary for each row execute function write_audit_log();
create trigger audit_firm_glossary_update after update on firm_glossary for each row execute function write_audit_log();
create trigger audit_firm_glossary_delete after delete on firm_glossary for each row execute function write_audit_log();
