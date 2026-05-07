# Buddy Sync Note — Phase 2c-form Restoration Unit 2

**Cut:** 2026-05-07 ~02:00 EDT
**Author:** Buddy (Claude.ai web)
**Surface:** `index.html` only — no migrations, no schema changes
**Branch:** demo-banner (extending d871f73)

---

## What shipped

Unit 2 of the Phase 2c-form Restoration build per `.coordination/work_order_phase2c_form_restoration.md`. Strategy: **route to the existing Submit Phase flow** rather than rebuild photo upload + whiteboard validation inline. The proven dashboard Submit Phase modal already handles photo capture (renderPhotoSlot), whiteboard detection (detect-whiteboard Edge Function), CS replacement gate, audit chain, and PhotoQueue background sync. Reuse > rebuild.

Surfaces added:

1. **Live entry count** — `<div id="rg-entry-count">` in the Restoration tab footer, showing `<n> entries saved on the active Materials Sheet` or an empty-state warning. Refreshes on initial render and after every successful Save Draft.
2. **Submit Restoration Phase button** — disabled when entry count is 0; on click validates ≥1 grid entry, captures property context, closes Property Detail modal, switches to Submit panel via `showPanel('submit')`, pre-fills `#submit-property-select` (hidden) + `#submit-property-search` (visible), and programmatically calls `selectServiceType(tile, 'restoration')` to render the photo slot + dynamic fields.
3. **Inspector continues** with the standard Submit Phase flow — take Restoration Photo (with whiteboard visible), confirm whiteboard checkbox, hit Submit Phase. Existing flow handles `phase_submissions` INSERT, `properties.current_phase` advance, PhotoQueue sync, audit chain.

## File diff summary (3 surgical edits via Filesystem:edit_file)

1. **CSS additions** (~9 new rules after `.rg-btn-ghost`): `.rg-footer`, `.rg-entry-count` (+ `.rg-empty-count` variant), `.rg-submit-btn` (with hover + disabled states)
2. **rgRenderForm body extended** — appends footer div with entry-count + Submit button after the 3 fieldsets; calls `rgRefreshEntryCount()` after rendering. Plus two new functions: `rgRefreshEntryCount()` and `rgGoToSubmitPhase()`.
3. **rgSaveDraft success path** — added `rgRefreshEntryCount()` call after toast so the count + Submit button state update immediately after each Save Draft.

## Why route instead of rebuild

`handlePhotoCapture` (line 1963) reads `document.getElementById('submit-property-select').value` to determine which property the photo is being captured for. Photos are queued via `window.PhotoQueue` with `currentSubmissionUUID` and uploaded to Supabase Storage in the background. Mirroring this inline on the Restoration tab would require either:

(a) Mutating `#submit-property-select` from outside its panel (state contamination risk if user navigates back to Submit panel mid-flow)
(b) Refactoring `handlePhotoCapture` to accept an explicit propertyId parameter (touches a battle-tested function used by 8+ photo slots)
(c) Building a parallel photo-capture pipeline scoped to the Restoration tab (duplicate code, duplicate Storage path conventions, duplicate PhotoQueue wiring)

Routing to the existing flow avoids all three. UX trade-off: the inspector clicks one extra button and the Property Detail modal closes. Net win: zero new bug surface for the photo + whiteboard + audit + PhotoQueue paths.

## Acceptance criteria (running count after Unit 2)

| # | Criterion | Status |
|---|---|---|
| 1 | Inspector opens Property Detail → Restoration tab → sees 3-row form | ✅ Unit 1 |
| 2 | Save Draft writes rows; Submit Phase advances | ✅ Unit 2 (Submit via handoff) |
| 3 | Submit Phase validates whiteboard + advances current_phase | ✅ Unit 2 (inherited from existing submitPhase flow) |
| 4 | ShortHills role-inversion banner | ✅ Unit 1 |
| 5 | recently_paved_road dynamic banner | ⚠️ Toggle saves to DB but inline banner deferred (one-line addition pending) |
| 6 | Multiple entries per restoration_type append | ✅ Unit 1 |
| 7 | Whiteboard validation blocks submit | ✅ Unit 2 (inherited — `wbRequiredLabels` array in submitPhase already includes 'restoration') |
| 8 | Edit existing entry, role-gated | ⚠️ Unit 3 (history view + edit) |

**7 of 8 met after Unit 2.** Remaining: #5 (cosmetic banner ~5 min) + #8 (Unit 3, ~30 min).

## End-to-end click test (after Vercel preview READY)

1. Open any demo property's Property Detail → Restoration tab
2. Confirm "No entries saved yet" empty-state + Submit button disabled
3. Save Draft on City Strip with dimension `4x6 ft` + material `asphalt` + a couple toggles
4. Confirm: toast appears, status text shows "Saved at HH:MM:SS", count updates to "1 entry saved", Submit button enables
5. Click "Submit Restoration Phase →"
6. Property Detail closes, Submit panel opens, property is pre-filled in search box, restoration tile is selected, photo slot is rendered with "Whiteboard required" badge
7. Take/upload a photo (with a visible whiteboard if you have one), check the whiteboard box, click Submit Phase
8. Verify: phase_submissions row inserted, properties.current_phase = 'restoration'

## Verification queries (post click-test)

```sql
-- Entry counts per materials_sheet (per-firm scoped automatically by RLS)
SELECT materials_sheet_id, COUNT(*) AS entries
FROM public.restoration_grid_entries
WHERE deleted_at IS NULL
GROUP BY materials_sheet_id
ORDER BY entries DESC;

-- Latest restoration phase submissions + linkage to grid entries
SELECT ps.id AS submission_id, ps.property_id, ps.submitted_at,
       ps.photo_restoration_whiteboard, ps.photo_restoration_url IS NOT NULL AS has_photo,
       ps.materials_sheet_id,
       (SELECT COUNT(*) FROM restoration_grid_entries rge
         WHERE rge.materials_sheet_id = ps.materials_sheet_id AND rge.deleted_at IS NULL) AS grid_entry_count
FROM public.phase_submissions ps
WHERE ps.phase = 'restoration' AND ps.deleted_at IS NULL
ORDER BY ps.submitted_at DESC
LIMIT 5;
```

## What CC should do

```
git status — index.html modified (~+95 lines)
git add index.html .coordination/buddy_phase2c_unit2_2026-05-07.md
git commit -m "feat(MI-101 Phase 2c-form Unit 2): Submit Restoration Phase handoff + live entry count"
git push origin demo-banner
```

After CC ships: hold STATE.md / decisions.md / status.md catch-up commits until Unit 3 lands so the docs sync covers the full Phase 2c-form arc in one batch (per Jorge's call earlier).

## Carry-forward to Unit 3 (~30 min next session)

1. **History view** — "Previous Entries" section above the 3 fieldsets showing all rows for the active materials_sheet, collapsed by default with summary line (`City Strip — 4x6 asphalt — 2026-05-04 by sam.brooks`). Tap to expand → readonly view of all fields.
2. **Edit gate** — Edit button on each row visible to super_admin / supervisor / submitted_by author only. Form prefills with row data, Save updates instead of inserts.
3. **Acceptance #5 cosmetic** — when `recently_paved_road` toggle flips ON in any fieldset, show inline note "Municipality may require extended saw cut + thicker base coat — confirm spec before submit." (One-line `addEventListener` per fieldset's checkbox.)

## Deviations / decisions in this Unit 2

- **Routing over inline submit** — see "Why route instead of rebuild" above. Lower risk, smaller surface, faster ship.
- **Live entry count** — wasn't in the original work order but felt obviously right: inspector needs to see how many entries are saved before clicking Submit. Empty-state copy clarifies the gate.
- **Submit button disabled when 0 entries** — defense in depth (server-side validation also fires inside `rgGoToSubmitPhase`); good UX hint.
