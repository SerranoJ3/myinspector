# PACK ARCHITECTURE AUDIT — Phase A of CC_ORDER_2026-07-21_MYINSPECTOR_PACK02_CMT
**Date:** 2026-07-21 · **Auditor:** CC · **Scope:** every water-specific assumption in the live schema (`wryitfoletwskkdqqwcw`) + the app (`index.html`), and where each one goes under the vertical-pack architecture (ratified 7/6).

## Context that changes the math
Every business table is at ~0 rows (pre-adoption sandbox wipe, Jorge-waived 7/6). There is
**no data-migration risk anywhere** — the only regression surface is water-app BEHAVIOR.
That surface is protected by the zero-regression rule, so the audit's ruling optimizes for
"water UI untouched" over "schema beauty."

## Table census (41 public tables)

**CORE — vertical-neutral, shared skeleton (untouched):**
`firms` · `profiles` · `projects` · `documents` · `modules` · `rfis` · `photo_rescue` ·
`supervisor_alerts` · `luis_conversations` · `schedules` · `hours_entries` · `pto_balances` ·
`pto_transactions` · `expense_entries` · `field_guides` · `field_guide_pages` ·
`inspector_credentials` · `daily_reports` (counts are generic)
+ the 7-table compliance/audit stack (`audit_log`, `compliance_events`, `legal_holds`,
`destruction_notices`, `whiteboard_override_log`, `cs_replacement_authorizations`*,
`materials_sheets`*) — *these two are water-BORN but are compliance records; they stay
where the audit chain built them.
+ (`prizm_waitlist`, `silaba_waitlist` — unrelated tenants of the shared free tier; not MI.)

**PACK 01 (WATER) DOMAIN TABLES — stay as-is, become pack-owned:**
`properties` (water asset = property; `sector` enum, mapcall_id, company/customer_material)
`phase_submissions` (the production write table — curbstop/watermain/restoration photo
slots, tapcard_data, njaw_work_order_code, cs_replacement)
`restoration_grid_entries` · `parts_catalogs` · `gis_lists` · `gis_list_entries` ·
`manholes` · `cctv_defect_observations` · `heralds` · `municipalities_contractors` ·
`contractor_assignments` · `contractor_arrival_log` · `contractor_departure_log`

**LEGACY ROOT-LEVEL WATER COLUMNS (the audit's core finding):**
`inspections` carries ~30 water/sewer columns at root (company_material, customer_material,
pavement_*, ramp_*, sewer_inspection_type, manhole ids, pipe_*, cctv_*, i_i_*,
pump_station_*, h2s_ppm). Per CLAUDE.md this table is LEGACY — "production write table is
phase_submissions, NOT inspections." It is water-shaped to the bone.

## Ruling (the Phase A decision record)

1. **No physical column relocation on live water tables.** The 5,232-line water UI reads
   those columns today; moving them buys schema purity at real regression risk against the
   zero-regression law, for tables Pack 02 never touches. Water columns are hereby
   **pack-01-owned by declaration** (this document + `vertical_packs.owned_tables`).
2. **CMT NEVER extends the water shape.** Everything Pack 02 writes goes through NEW
   config-driven tables (`test_types` registry → `test_submissions.field_data` JSONB),
   keyed to the same core skeleton (`firms`, `projects`, `profiles`, audit stack). This is
   what actually keeps Pack 03+ a content task: verticals add REGISTRY ROWS, not columns.
3. **`inspections` (legacy) is frozen** — no new writes from either pack. Flagged for
   eventual drop when Jorge rules (0 rows; kept only because dropping tables mid-order
   without his word violates the caution posture).
4. **The vertical seam in core:** `firms.active_pack` (workspace default) +
   `projects.vertical` (per-project override, P1 spec) + `vertical_packs` registry table
   (versioned — the P2 licensing insurance, schema now, machinery later).
5. **App-side:** all user-facing water strings/forms extracted into a `PACKS.water` JS
   config module (Phase B); the CMT UI renders from the DB registry (Phase C). The two
   meet at the same generic renderers.

## Water-specific app inventory (Phase B extraction targets)
- Hardcoded `module_key:'water'` (1 site) → pack constant.
- Service-type tiles: test_pit / service_work / tapcard / no_work (+ per-type dynamic
  forms with curbstop/watermain photo slots, NJAW/LSL code dropdowns) → `PACKS.water.forms`.
- Sector enum UI (NJ6_NORMAL / NJAW Short Hills) → pack content.
- Terminology surfaces (nav labels, "Properties", "Phase Submissions", report headers)
  → pack terminology map.
- Whiteboard photo-gate config (which slots require it) → pack config (CMT analog:
  required-content photo gates per test type).

## What Phase A ships (migration `pack02_001_vertical_layer`)
- `vertical_packs` registry (versioned; rows: water v1, cmt v1) with `owned_tables`,
  `terminology`, `enabled` — RLS super_admin-write / all-read.
- `firms.active_pack text NOT NULL DEFAULT 'water'` — every existing firm keeps water
  behavior with zero action (the zero-regression default).
- `projects.vertical text NULL` (NULL = inherit firm pack).
- No existing column touched, no existing table altered beyond the two additive columns.
