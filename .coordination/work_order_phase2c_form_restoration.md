# Work Order — Phase 2c-form (Restoration Form Frontend)

**Authored:** 2026-05-05 ~21:35 EDT
**By:** Buddy
**For:** Lead — pickup-ready
**Authority:** Jorge granted Buddy batch trust. Schema verified via Supabase MCP `list_tables` 2026-05-05 21:25 EDT.
**Brief reference:** Phase 2c lean scaffold already shipped tonight (`91f2af4`). Tab strip exists; this work order ships the form behind it.

---

## Why this matters

Phase 2c-form completes the Restoration phase workflow — the inspector's documentation when contractors finish patching/paving/sidewalk repair after a service line replacement. Backend (`restoration_grid_entries` table, 15 columns, RLS-locked, sector enum CHECK) shipped Saturday. The Property Detail tab strip was scaffolded tonight (`91f2af4`). What's missing: the form behind the Restoration tab + the photo upload + Save Draft.

**Production gap closed when this ships:** inspectors can document restoration phase via UI instead of paper. Currently 0 rows in `restoration_grid_entries` because no UI surface exists.

---

## Locked answers (batch trust)

- **Q-7 — Save Draft button:** (C) Save Draft persists current form state to `restoration_grid_entries` with all photos optional, allowing inspector to come back later. Submit Phase still requires whiteboard + minimum 1 photo per restoration type.
- **Q-2c-c — sector dispatch on Restoration:** NJ6_NORMAL renders 3 restoration type rows (City Strip / Street / Sidewalk per paper template). NJAW_SHORT_HILLS renders same 3 rows but role-inverted — inspector dictates dimensions to contractor instead of receiving them.
- **Q-2c-d — multiple entries per restoration type:** YES, allow multiple `restoration_grid_entries` rows per materials_sheet_id with the same `restoration_type`. Inspector can document patching at different times or different sub-areas under one Restoration phase. Each entry timestamped via `created_at`.
- **Q-2c-e — recently_paved_road flag:** boolean on the row, surface as toggle. When TRUE, surface a banner explaining municipality may require special restoration spec (e.g., extended saw cut, base coat thickness).

---

## Verified ground truth — `restoration_grid_entries` schema

```
id                      uuid PK (default extensions.gen_random_uuid())
materials_sheet_id      uuid FK → materials_sheets
sector                  text CHECK IN ('NJ6_NORMAL','NJAW_SHORT_HILLS')
restoration_type        text  -- e.g. 'city_strip', 'street', 'sidewalk'
dimension               text  -- e.g. '4x6 ft', '2x10 ft'
material                text  -- e.g. 'asphalt', 'concrete', 'topsoil_seed'
quantity                numeric CHECK >= 0
entry_notes             text
recently_paved_road     boolean
base_8inch_by_company   boolean  -- CDM-Smith spec: 8" base by NJAW contractor
saw_cut_by_company      boolean  -- saw cut by NJAW vs municipality
concrete_under_paving   boolean
firm_id                 uuid FK → firms (RLS-locked)
submitted_by            uuid FK → auth.users
created_at              timestamptz
deleted_at              timestamptz
deleted_by              uuid
```

RLS firm-scoped (already enforced via existing policy pattern). Audit triggers attached (already in place via standard pattern).

## Verified ground truth — `phase_submissions` Restoration columns

```
photo_restoration_url            text
photo_restoration_whiteboard     boolean (default false)
```

Photo storage path convention: `restoration/{property_id}/{phase_submission_id}/{uuid}.jpg` in Supabase storage `phase-photos` bucket.

---

## Unit 1 — Restoration form scaffold + 3 row template (~1 session)

1. Inside Property Detail modal, "Restoration" tab body renders 3 `<fieldset>` blocks: City Strip / Street / Sidewalk
2. Each fieldset has: `dimension` (text input), `material` (select dropdown — asphalt / concrete / topsoil_seed / pavers / other), `quantity` (numeric input with unit), `entry_notes` (textarea)
3. CDM-Smith flag toggles: `recently_paved_road`, `base_8inch_by_company`, `saw_cut_by_company`, `concrete_under_paving`
4. Photo upload zone per fieldset — drag/drop or tap to capture, supports multiple photos per restoration type
5. Sector dispatch (read from `properties.sector`):
   - NJ6_NORMAL: standard form, contractor data flow
   - NJAW_SHORT_HILLS: same form fields but with banner "Inspector dictates dimensions and material spec — confirm with contractor before submit"

Commit Unit 1:

```
feat(MI-101 Phase 2c-form Unit 1): Restoration form scaffold + 3-row template + sector dispatch

- Restoration tab body renders 3 fieldsets (City Strip / Street / Sidewalk)
- Fields: dimension, material (enum), quantity, entry_notes
- 4 CDM-Smith toggles per fieldset
- Photo upload zone per type, multiple-photos support
- Sector dispatch: NJ6_NORMAL standard, NJAW_SHORT_HILLS role-inversion banner
- Schema: restoration_grid_entries verified via Supabase MCP 2026-05-05 21:25 EDT
```

---

## Unit 2 — Save Draft + Submit Phase wiring (~1 session)

1. **Save Draft button** (per Q-7=C): writes current form state to `restoration_grid_entries` rows (one row per fieldset that has any data) plus updates `phase_submissions` with `current_phase='restoration'`. Photos upload to storage but `phase_submissions.photo_restoration_url` stays null until Submit Phase.
2. **Submit Phase button**: validates whiteboard photo present (per locked rule "open work = whiteboard required"), validates minimum 1 photo per restoration type that has dimension/material data, sets `photo_restoration_url` array + `photo_restoration_whiteboard=true`, advances `current_phase` to next state per phase enum sequence.
3. Multiple entries per type: if Save Draft fires twice with different data in City Strip fieldset, append both rows (don't overwrite). UI shows "Previous entries (2)" with view link.
4. Whiteboard compliance: leverage existing `detect-whiteboard` Edge Function on photo upload. Override path buried in supervisor menu (per locked principle — exceptions get buried override paths, not default prompts).

Commit Unit 2:

```
feat(MI-101 Phase 2c-form Unit 2): Save Draft + Submit Phase + whiteboard validation

- Save Draft writes restoration_grid_entries rows, photos upload but phase doesn't advance
- Submit Phase validates whiteboard + min 1 photo per restoration_type, advances current_phase
- Multiple entries per restoration_type append (not overwrite)
- Whiteboard compliance via existing detect-whiteboard Edge Function
- Override path buried in supervisor menu (locked principle)
```

---

## Unit 3 — History view + edit existing entries (~30 min)

1. "Previous Entries" section above the form shows existing `restoration_grid_entries` rows for this property's most recent materials_sheet_id
2. Each row collapsed by default with summary (e.g., "City Strip — 4x6 asphalt — 2026-05-04 by jorge.serrano")
3. Tap to expand → readonly view of fields + photos
4. Edit button on row (super_admin / supervisor / submitted_by author only) → form prefills with row data, save updates instead of inserts

Commit Unit 3:

```
feat(MI-101 Phase 2c-form Unit 3): history view + role-gated edit on existing entries
```

---

## Acceptance criteria

1. Inspector opens Property Detail → Restoration tab → sees 3-row restoration form
2. Fills out City Strip section, taps Save Draft → row inserted, photos upload to storage, phase doesn't advance
3. Inspector returns later, fills Street + Sidewalk, taps Submit Phase → all rows persisted, whiteboard validated, phase advances
4. ShortHills property shows role-inversion banner
5. recently_paved_road toggle surfaces special-spec banner
6. Multiple entries per restoration_type append correctly (test: save City Strip twice, see 2 rows)
7. Whiteboard validation blocks submit if no whiteboard photo present (override path works for supervisor)
8. Edit button on existing entry restricted to author + super_admin + supervisor roles

---

## Closing actions

- Push demo-banner to origin
- Update STATE.md: Phase 2c-form closed
- Update status.md: Phase 2c-form in recently-shipped
- Append decisions.md entry: Q-2c-c/d/e ratifications + Save Draft Q-7=C lock
- Final session-close commit

---

## Stop conditions

- Whiteboard validation logic ambiguity (existing detect-whiteboard fallback behavior unclear)
- Photo upload storage path conflicts with existing `phase-photos` bucket structure
- BUDDY_STANDARD locked principle conflict

## Do NOT stop for

- Material enum dropdown choices (Lead's craft from common NJ restoration materials list)
- Photo upload UX choice (drag/drop vs tap-to-capture, both fine)
- Mobile responsive layout (Lead's UI craft)
- "Previous Entries" collapse-by-default vs expanded — Lead's call

## Velocity estimate

~3 sessions total. Unit 1 (form scaffold) + Unit 2 (save/submit wiring) ships v1. Unit 3 (history + edit) is polish, ships separately if cycles tight.

## Verified ground truth footer

- Branch state verified: 2026-05-05 ~21:35 EDT — `restoration_grid_entries` does not have a UI surface; Phase 2c lean scaffold (`91f2af4`) on demo-banner has tab strip but empty Restoration tab body
- Schema verified: 2026-05-05 21:25 EDT via Supabase MCP `list_tables` — 15 columns confirmed, RLS-locked, sector enum CHECK present
- `phase_submissions.photo_restoration_url` + `photo_restoration_whiteboard` columns verified present
- detect-whiteboard Edge Function verified shipped (existing pattern from Phase 2a/2b photo capture)
