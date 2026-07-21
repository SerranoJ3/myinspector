# Buddy Sync Note — Phase 2c-form Restoration Unit 3

**Cut:** 2026-05-07 ~02:55 EDT
**Author:** Buddy (Claude.ai web)
**Surface:** `index.html` only — no migrations, no schema changes
**Branch:** demo-banner / mi-demo-seed (extending 58d41be)

---

## What shipped — Phase 2c-form **complete, 8/8 acceptance**

Unit 3 closes the last two acceptance criteria from the work order:

- **#5 — recently_paved_road dynamic banner:** Per-fieldset advisory banner that appears inline when the checkbox is flipped ON. Copy: *"Recently paved road — municipality may require extended saw cut + thicker base coat. Confirm spec with town engineer before submit."*
- **#8 — History view + role-gated edit:** "Previous Entries" accordion above the 3 fieldsets. Each row is a clickable summary; expand to see all fields + Edit Entry button (visible only to allowed roles). Edit prefills the matching fieldset, swaps Save Draft → Update Entry button, hides the other 2 fieldsets + footer for focus.

Unit 1 (form scaffold, Save Draft, sector dispatch) + Unit 2 (Submit Phase handoff, live entry count) + Unit 3 (history, edit, RPR banner) = full Phase 2c-form spec landed.

## Permission gate (UI level)

`rgCanEdit(entry)` returns true when any of:
- `currentUserIsSuperAdmin === true` (god mode)
- `currentUserRole === 'supervisor'` (firm-scoped supervisor)
- `entry.submitted_by === currentUser.id` (original author)

All non-allowed users see *"Edit reserved for super_admin, supervisor, or original author"* in the expanded detail panel instead of the Edit Entry button.

This is a UI-level gate. RLS still independently enforces firm scope on the UPDATE (the policy `firm_id IN (SELECT firm_id FROM profiles WHERE id = auth.uid())` covers cross-firm protection at the database). A follow-up ticket could tighten RLS to add author/role-based UPDATE constraints; not needed for v1.

`currentUserRole` global was added (set in initApp from `profile.role`) since the existing `currentUserIsSuperAdmin` boolean lost the raw role string.

## File diff summary (5 surgical edits)

1. **Globals** (+2 lines): `currentUserRole` global declared near `currentUserIsSuperAdmin`, captured in initApp's profile-load block.
2. **CSS additions** (~33 new rules after `.rg-submit-btn:disabled`): `.rg-history-section/header/list/empty/row/summary/detail/edit-btn`, `.rg-fieldset.rg-editing` styling, `.rg-action-update/-cancel` toggle visibility, `.rg-edit-banner`, `.rg-rpr-banner` (default hidden + .visible variant).
3. **rgRenderForm extended**: history section HTML before the 3 fieldsets; per-fieldset rpr-banner div + onchange wiring on the recently_paved_road checkbox; per-fieldset Update Entry + Cancel buttons (hidden until `.rg-editing` class on parent fieldset). Plus rgRefreshHistory call after render.
4. **rgSaveDraft success path**: added `rgRefreshHistory()` call so newly-saved rows appear in the history list immediately.
5. **JS module additions** (~190 lines): `rgRprToggle`, `rgCanEdit`, `rgRefreshHistory`, `rgRenderHistory`, `rgToggleEntryExpand`, `rgStartEdit`, `rgCancelEdit`, `rgUpdateEntry`. Plus `RG_MATERIAL_LABELS` constant + `rgEditingEntryId` and `rgEntriesCache` globals.

Both new write paths (`rgStartEdit`, `rgUpdateEntry`) are guarded with `pitchModeBlocked('edit entry')` / `pitchModeBlocked('restoration update')` per MI-DEMO-UI v2's discipline that every write-bearing entry point checks the pitch toggle.

## Acceptance criteria — final tally

| # | Criterion | Status |
|---|---|---|
| 1 | Inspector opens Property Detail → Restoration tab → sees 3-row form | ✅ Unit 1 |
| 2 | Save Draft writes rows; Submit Phase advances | ✅ Unit 1+2 |
| 3 | Submit Phase validates whiteboard + advances current_phase | ✅ Unit 2 (inherited from existing submitPhase) |
| 4 | ShortHills role-inversion banner | ✅ Unit 1 |
| 5 | recently_paved_road dynamic banner | ✅ **Unit 3** |
| 6 | Multiple entries per restoration_type append | ✅ Unit 1 |
| 7 | Whiteboard validation blocks submit | ✅ Unit 2 (inherited) |
| 8 | Edit existing entry, role-gated | ✅ **Unit 3** |

**8/8 met.** Phase 2c-form closed.

## Click test (after Vercel preview READY)

1. Open any demo property with an active materials_sheet → Restoration tab
2. Confirm "Previous Entries (N)" header above the form, list of saved rows below
3. Click a row summary → expands to show full detail grid + Edit Entry button (if allowed)
4. Click "Recently paved road" checkbox in any fieldset → orange banner appears inline
5. Uncheck → banner hides
6. Click Edit Entry on an existing row:
   - Other 2 fieldsets hide, history section + footer hide
   - Target fieldset gets blue border + "Edit mode" banner at top
   - All fields prefilled, RPR banner state synced with checkbox
   - Status text shows "Editing entry from [datetime]"
   - Update Entry + Cancel buttons appear
7. Modify a field → click Update Entry → toast confirms, fieldset clears, history list refreshes with the changed row
8. Click Edit again → click Cancel → reverts cleanly, all 3 fieldsets restored
9. Sign in as a non-author non-supervisor user → expand someone else's entry → Edit button not present, replaced by *"Edit reserved for super_admin, supervisor, or original author"* note
10. Toggle pitch mode ON in the demo banner → Edit + Update both bail with the suppression toast (from MI-DEMO-UI v2 wiring)

## Verification queries

```sql
-- Confirm an UPDATE preserved created_at + materials_sheet_id but changed targeted fields
SELECT id, materials_sheet_id, restoration_type, dimension, material, quantity,
       recently_paved_road, base_8inch_by_company, saw_cut_by_company, concrete_under_paving,
       submitted_by, created_at, deleted_at
FROM public.restoration_grid_entries
WHERE deleted_at IS NULL
ORDER BY created_at DESC LIMIT 5;
```

(There is no `updated_at` on `restoration_grid_entries` either — same gap as `firms`. The audit_log chain captures the UPDATE row-by-row.)

## What CC should do

```
git status — index.html modified (~+250 lines)
git add index.html .coordination/buddy_phase2c_unit3_2026-05-07.md
git commit -m "feat(MI-101 Phase 2c-form Unit 3): history view + role-gated edit + recently_paved banner — closes 8/8"
git push origin demo-banner
git checkout mi-demo-seed && git merge demo-banner --ff-only && git push origin mi-demo-seed
```

## Held doc-sync queue — flush after Unit 3

The arc that's been queued for one batched STATE.md / decisions.md / status.md commit:

- d871f73 — Phase 2c-form Unit 1 (Restoration form scaffold + Save Draft + sector dispatch)
- 3a1a9bf — Phase 2c-form Unit 2 (Submit Restoration Phase handoff + live entry count)
- 58d41be — MI-DEMO-UI v2 (pitch mode write suppression toggle, 8 guarded write paths)
- (this) — Phase 2c-form Unit 3 (history view + edit + RPR banner — Phase 2c-form 8/8 closed)

Suggested doc-batch coverage for CC's next push:

**STATE.md updates:**
- Header timestamp + completion-percent bumps (v0.1: 74→78, v1.0: 65→69, full platform: 30→32, full vision: 14→15)
- MI-101 Phase 2c-form row → CLOSED (8/8 acceptance)
- New row: MI-DEMO-UI v2 → CLOSED (pitch mode toggle, 8 write-path guards)
- Recent ships subsection: 4 entries (Unit 1, Unit 2, MI-DEMO-UI v2, Unit 3)
- Banked discipline updates: nothing new this session past Lessons 6 + 7 already in STATE.md

**decisions.md entries:**
- Q-pitch-a/b/c/d/e (MI-DEMO-UI v2 inline ratifications — see buddy_demo_ui_v2 sync note)
- Q-rg-edit-gate: super_admin OR supervisor OR submitted_by author for UI edit; RLS-level tightening deferred
- Q-rg-rpr-copy: locked banner text "extended saw cut + thicker base coat. Confirm spec with town engineer before submit"

**status.md "recently shipped":**
- Phase 2c-form (3 units, 8/8 acceptance) closed
- MI-DEMO-UI v2 closed

## Open follow-ups (not in this commit)

- MI-AUDIT-4 (firms audit trigger + updated_at) — still queued, ~30 min
- CLAUDE.md staleness — replace defunct `QUIET-RIVER-58` literal with `<rotated 2026-05-07>` placeholder
- Distribute new firm code `PIVOT-LATTICE-72` to Justin + Tyler out-of-band
- Click-test the live Vercel preview when Jorge has a clear minute
- restoration_grid_entries `updated_at` column gap — minor, can fold into MI-AUDIT-4 or a successor ticket

## Demo critical path status

Was 6-7 sessions at start of evening. Now:

- **Phase 2c-form**: closed
- **MI-DEMO-UI v2**: closed (pitch mode lock for live demos)
- **Luis v1**: shipped earlier this session with Lesson-7 RLS fix
- **Phase 4 diagram**: shipped earlier this session
- **Phase 2d-revision**: shipped earlier this session

What's left on the demo critical path: **click-test pass on Vercel preview + a polish session for any rough edges**. Demo is 7-8 days out (5/14-5/15 Jeff). Plenty of buffer.

Heavy ship. Stop here is correct.
