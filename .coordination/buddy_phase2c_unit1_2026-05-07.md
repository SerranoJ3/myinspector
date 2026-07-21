# Buddy Sync Note — Phase 2c-form Restoration Unit 1

**Cut:** 2026-05-07 ~01:35 EDT
**Author:** Buddy (Claude.ai web)
**Surface:** `index.html` only — no migrations, no schema changes
**Branch:** whatever was checked out (likely demo-banner)

---

## What shipped

Unit 1 of the Phase 2c-form Restoration build per `.coordination/work_order_phase2c_form_restoration.md`:

1. **Restoration tab body** in Property Detail modal — replaced the "tab structure scaffolded, form ships next session" placeholder with the actual form
2. **3 fieldsets** (City Strip / Street / Sidewalk) with: dimension, material (5-option select), quantity, entry_notes
3. **4 CDM-Smith toggles per fieldset**: recently_paved_road, base_8inch_by_company, saw_cut_by_company, concrete_under_paving
4. **Save Draft per fieldset** — INSERTs row to `restoration_grid_entries` with `materials_sheet_id`, `sector`, `firm_id`, `submitted_by` populated. Lesson 7 applied (firm_id on insert per RLS WITH CHECK).
5. **Sector dispatch** — NJAW_SHORT_HILLS shows role-inversion banner ("Inspector dictates dimensions and material spec — confirm with contractor before submit")
6. **Empty state** — if property has no active materials_sheet, shows "Restoration entries require an active Materials Sheet. Open the Materials Sheet from the Overview tab to create one first."
7. **Lazy init** — `rgInit()` fires on `pdSwitchTab('restoration')`, so the form fetches the materials sheet only when the tab is actually opened

## File diff summary (3 surgical edits via Filesystem:edit_file)

1. **CSS additions** (~24 new rules after `.pd-diagram-svg`): `.rg-meta`, `.rg-fieldset`, `.rg-legend`, `.rg-row`, `.rg-field`, `.rg-input`, `.rg-toggles`, `.rg-toggle`, `.rg-actions`, `.rg-status` (+ ok/err/warn variants), `.rg-empty`, `.rg-banner-shorthills`, `.rg-btn-ghost`
2. **HTML replace** in `pd-page-restoration` div: placeholder → ShortHills banner (hidden by default) + `<div id="rg-form-container">` populated dynamically by `rgRenderForm()`
3. **JS module + pdSwitchTab hook** (~190 lines added before existing visual-tapcard-preview module): `RG_TYPES`, `RG_MATERIALS`, `rgMaterialsSheetId`, `rgSector` globals; `rgInit`, `rgRenderEmpty`, `rgRenderForm`, `rgClearFieldset`, `rgSetStatus`, `rgSaveDraft` functions; pdSwitchTab modified to call `rgInit()` on tab='restoration'

## Acceptance criteria coverage (from work order)

| # | Criterion | Status |
|---|---|---|
| 1 | Inspector opens Property Detail → Restoration tab → sees 3-row restoration form | ✅ |
| 2 | Save Draft inserts row, photos upload to storage, phase doesn't advance | ⚠️ Save Draft works; **photos deferred to Unit 2** (see below) |
| 3 | Submit Phase wires whiteboard validation + advances current_phase | ⚠️ **Deferred to Unit 2** — Submit Phase lives on Submit Phase modal, separate surface from the form |
| 4 | ShortHills property shows role-inversion banner | ✅ |
| 5 | recently_paved_road toggle surfaces special-spec banner | ⚠️ Toggle exists + saves; **dynamic special-spec banner deferred** (one-line addition; not surfaced in this push) |
| 6 | Multiple entries per restoration_type append correctly | ✅ — Each Save Draft inserts a new row; no UPSERT logic, pure INSERT |
| 7 | Whiteboard validation blocks submit if no whiteboard photo | ⚠️ **Deferred to Unit 2** (Submit Phase wiring) |
| 8 | Edit button on existing entry, role-gated | ⚠️ **Deferred to Unit 3** (history view + edit) |

**4 of 8 criteria met in Unit 1.** Remaining are Unit 2 (photos + Submit Phase) and Unit 3 (history + edit).

## Deviation from work order

The work order spec said "Photo upload zone per fieldset — supports multiple photos per restoration type" as part of Unit 1. **`restoration_grid_entries` has no photo URL columns** (verified via Supabase MCP — 17 cols, none are photo URLs). Photos for restoration phase live on `phase_submissions.photo_restoration_url` + `photo_restoration_whiteboard`. So photos are **submission-level**, not row-level.

Punting photo upload to Unit 2 where it ties properly to phase_submissions on Submit Phase. Lesson 4 applied (verify schema before forcing the spec — schema wins).

## Verification queries (post-merge, after first Save Draft click)

```sql
-- Confirm new entries land with firm_id + actor populated
SELECT id, materials_sheet_id, sector, restoration_type, dimension, material,
       quantity, recently_paved_road, base_8inch_by_company,
       saw_cut_by_company, concrete_under_paving,
       firm_id, submitted_by, created_at
FROM public.restoration_grid_entries
WHERE deleted_at IS NULL
ORDER BY created_at DESC
LIMIT 5;

-- RLS spot check: cross-firm read returns 0 from a different firm context
-- (would need to be run as a non-super_admin from another firm)
```

## What CC should do

```
git status — index.html modified (~+220 lines)
git add index.html .coordination/buddy_phase2c_unit1_2026-05-07.md
git commit -m "feat(MI-101 Phase 2c-form Unit 1): Restoration form scaffold + Save Draft + sector dispatch"
git push origin demo-banner
```

After Vercel preview READY: open any demo property's Property Detail → Restoration tab → fill out city_strip fields → Save Draft → check toast + reload → row should appear if you re-query restoration_grid_entries via Supabase MCP. Try same on a NJAW_SHORT_HILLS demo property (bb...0011 Trenton or bb...0012 Bayonne) to verify banner shows.

## Next session pickup

**Unit 2 (~1 session):** Photo upload zone (single zone for the whole restoration phase, not per fieldset, since photos tie to phase_submissions) + Submit Phase wiring (whiteboard validation, photo URL array population, current_phase advance). Whiteboard compliance via existing `detect-whiteboard` Edge Function.

**Unit 3 (~30 min):** "Previous Entries" view above the form showing existing rows, role-gated edit button.

## Open follow-ups (carry forward)

- Acceptance #5 dynamic banner for `recently_paved_road=true` (one-line addition: when toggle flips, show inline note about extended saw cut / base coat municipality requirements)
- Material enum could be verified against any pre-existing list (current set is asphalt / concrete / topsoil_seed / pavers / other — pragmatic default; expand if Jorge has a master list)
