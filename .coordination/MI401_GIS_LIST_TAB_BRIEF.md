# MI-401 — GIS List Tab (Address Checklist)

**Status:** Brief
**Drafted:** 2026-05-05 ~20:00 EDT
**By:** Buddy
**Source-of-truth:** Jorge-uploaded `GIS_LIST_9_10_2025Part-1.pdf` (5/5 evening)

---

## TL;DR

Inspectors today carry paper notebooks copying GIS lists by hand. Replace with an in-app checklist tab. Inspector taps a checkbox per address as it's worked. Persists to DB so list survives device swap, backs up, and gives supervisors live visibility into route progress without nagging.

---

## What the paper currently looks like

Per the PDF: a printed "GIS LIST — RELEASED: 10SEPT2025" with columns INDEX | ADDRESS | STATUS | NOTES, ~14 pages, 22 rows per page, ~300 addresses total per release.

Inspector behavior today: copy onto a notebook before heading out. Cross off as worked. Nothing flows back to the office until end-of-day debrief or notebook-to-spreadsheet manual transcribe.

## What MyInspector should do

**Sidebar tab:** "GIS Lists" (between Properties and Submit Phase, gut feel — Lead's nav judgment).

**Tab body:**
- Top bar: GIS list selector dropdown (released-date sorted, most recent default), "+ New List" button (super_admin / supervisor only)
- Search bar (filter by address text)
- Filter chips: All / To-Do / In-Progress / Complete
- Table: INDEX | ADDRESS | STATUS | NOTES | inspector-assigned (avatar) | last-action timestamp
- Each row has a checkbox + status pill. Tap checkbox → status flips (To-Do → In-Progress → Complete → To-Do). Notes column is inline-editable.

**Bulk import:** super_admin / supervisor uploads PDF or Excel/CSV → parser extracts addresses → creates rows. Reuses existing CSV import infrastructure from Phase 1 (banked: index.html has bulk CSV/Excel/TSV import with fuzzy column matching).

**Mobile:** stacked card view, big tappable checkbox per card, address as the headline, notes-edit via tap-to-expand.

## Schema

New table `gis_lists`:
- `id` uuid PK
- `firm_id` uuid FK → firms (RLS-locked)
- `name` text — e.g., "GIS List — Released 10 Sept 2025"
- `release_date` date
- `created_at`, `updated_at`, `deleted_at`
- `created_by` uuid FK → auth.users

New table `gis_list_entries`:
- `id` uuid PK
- `firm_id` uuid FK → firms (RLS-locked, denormalized for fast filter)
- `gis_list_id` uuid FK → gis_lists
- `index_number` int — paper INDEX column
- `address` text — paper ADDRESS column
- `status` text CHECK IN ('to_do','in_progress','complete')
- `notes` text
- `assigned_to` uuid FK → auth.users (nullable)
- `completed_by` uuid FK → auth.users (nullable)
- `completed_at` timestamptz (nullable)
- `linked_property_id` uuid FK → properties (nullable — populated when address resolves to an existing property)
- `created_at`, `updated_at`, `deleted_at`

**RLS:** firm-scoped on both tables (existing pattern from properties / phase_submissions).

**Audit:** `audit_log` triggers on `gis_list_entries` UPDATE — status changes, notes edits, assignments. Same pattern as phase_submissions.

**Indexes:**
- `gis_list_entries (firm_id, gis_list_id)`
- `gis_list_entries (firm_id, status)`
- `gis_list_entries (firm_id, assigned_to)`
- `gis_list_entries (linked_property_id)` — for property → GIS list joinback

## Build sequence

**Session 1 (backend):**
1. Migration: create `gis_lists` + `gis_list_entries` tables + RLS policies + audit triggers + indexes
2. RLS policies: firm-scoped read/write for authenticated; super_admin sees all
3. Seed CP Engineers test data: 1 list, 10 sample addresses (use Boyden Ave / Bowdoin St addresses from the GIS PDF)

**Session 2 (frontend):**
1. New sidebar nav entry "GIS Lists"
2. Modal `modal-gis-list` — table view + filters + bulk import
3. Status toggle UI (checkbox cycles status enum)
4. Notes inline-edit
5. PDF/CSV import (reuse existing parser; add column-fuzzy-matching for INDEX/ADDRESS/STATUS/NOTES)
6. Property auto-link: when entry address fuzzy-matches an existing `properties.address_*` row, set `linked_property_id` and add a "View Property" button on the entry row

**Session 3 (polish):**
1. Mobile responsive layout
2. Address autocomplete on entry edit (use existing street autocomplete from Phase 1)
3. Supervisor view: aggregate stats per list (% complete, time-to-complete avg, inspector breakdown)

## Acceptance criteria

1. Inspector can pull up a GIS list and tap-to-toggle status per address.
2. Status changes persist; back out → re-open → state preserved.
3. Audit log captures every status change with inspector + timestamp.
4. Supervisor (super_admin role) can see all lists across all inspectors in the firm.
5. Bulk import accepts PDF or Excel/CSV; addresses parse correctly and rows create.
6. Address fuzzy-match links entries to existing properties (one-tap navigation).
7. Mobile layout usable in field conditions (large tap targets, no hover-only UI).
8. RLS verified: inspector A cannot see firm B's GIS lists.

## Velocity estimate

~3 sessions total. Tonight one of these can ship if Lead has runway after Phase 2d-revision Session 1.

## Open questions

- **Q-401-a:** GIS list status enum — is "to_do / in_progress / complete" sufficient, or does Jorge want field-recognized statuses like "scheduled / no_access / refused / cs_replaced / m2c_only"? Buddy lean: keep it 3-state for v1; add a `field_outcome` column later that hooks into the phase enum for richer reporting.
- **Q-401-b:** Should completed GIS list entries auto-create a `phase_submission` placeholder, or stay as separate planning data? Buddy lean: separate. GIS list is the route plan; phase_submissions are the actual work logs. Cross-link via `linked_property_id`, don't conflate.
