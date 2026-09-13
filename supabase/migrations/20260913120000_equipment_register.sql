-- ============================================================================
-- EQUIPMENT REGISTER (CMT pack) — 2026-09-13
-- Firm-scoped equipment calibration + document + checkout register.
-- RLS shape is IDENTICAL to public.certifications: an active-firm policy
-- (firm_id must match the caller's profile firm, soft-deleted rows hidden)
-- plus a super_admin bypass. Additive only; touches no existing table.
-- ============================================================================

-- ---- equipment ----
create table if not exists public.equipment (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid,
  asset_tag text,
  type text,
  make text,
  model text,
  serial text,
  status text not null default 'in_service'
    check (status in ('in_service','out_for_calibration','out_of_service')),
  home_location text,
  notes text,
  last_cal_date date,
  cal_due_date date,
  cal_vendor text,
  secondary_due_date date,
  secondary_label text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid
);
create index if not exists equipment_firm_idx on public.equipment(firm_id);
create index if not exists equipment_cal_due_idx on public.equipment(cal_due_date);

-- ---- equipment_documents (many per equipment) ----
create table if not exists public.equipment_documents (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid,
  equipment_id uuid references public.equipment(id) on delete cascade,
  doc_type text check (doc_type in ('calibration_cert','bill_of_lading','bridge_doc','other')),
  file text,
  doc_date date,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid
);
create index if not exists equipment_documents_firm_idx on public.equipment_documents(firm_id);
create index if not exists equipment_documents_equipment_idx on public.equipment_documents(equipment_id);

-- ---- equipment_checkouts (many per equipment) ----
-- This table IS the "signed out at the office rather than on paper" ask.
create table if not exists public.equipment_checkouts (
  id uuid primary key default gen_random_uuid(),
  firm_id uuid,
  equipment_id uuid references public.equipment(id) on delete cascade,
  person text,
  out_at timestamptz,
  out_by uuid,
  due_back date,
  in_at timestamptz,
  in_by uuid,
  condition_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid
);
create index if not exists equipment_checkouts_firm_idx on public.equipment_checkouts(firm_id);
create index if not exists equipment_checkouts_equipment_idx on public.equipment_checkouts(equipment_id);
create index if not exists equipment_checkouts_open_idx on public.equipment_checkouts(equipment_id) where in_at is null and deleted_at is null;

-- ---- RLS: identical shape to certifications, on all three tables ----
alter table public.equipment enable row level security;
alter table public.equipment_documents enable row level security;
alter table public.equipment_checkouts enable row level security;

-- equipment
create policy equipment_active_firm on public.equipment
  for all to authenticated
  using (deleted_at is null and firm_id in (select profiles.firm_id from profiles where profiles.id = auth.uid()))
  with check (firm_id in (select profiles.firm_id from profiles where profiles.id = auth.uid()));
create policy equipment_super_admin_all on public.equipment
  for all to authenticated
  using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'super_admin'))
  with check (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'super_admin'));

-- equipment_documents
create policy equipment_documents_active_firm on public.equipment_documents
  for all to authenticated
  using (deleted_at is null and firm_id in (select profiles.firm_id from profiles where profiles.id = auth.uid()))
  with check (firm_id in (select profiles.firm_id from profiles where profiles.id = auth.uid()));
create policy equipment_documents_super_admin_all on public.equipment_documents
  for all to authenticated
  using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'super_admin'))
  with check (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'super_admin'));

-- equipment_checkouts
create policy equipment_checkouts_active_firm on public.equipment_checkouts
  for all to authenticated
  using (deleted_at is null and firm_id in (select profiles.firm_id from profiles where profiles.id = auth.uid()))
  with check (firm_id in (select profiles.firm_id from profiles where profiles.id = auth.uid()));
create policy equipment_checkouts_super_admin_all on public.equipment_checkouts
  for all to authenticated
  using (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'super_admin'))
  with check (exists (select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'super_admin'));
