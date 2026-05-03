# MI-110 PHASE 4 — Tapcard Diagram editor frontend brief

**Status:** Drafted by Buddy 2026-05-03 PM. Awaiting Jorge ratification before Lead picks up.
**Estimated:** ~6 sessions (Lead's call after read; this is the highest-risk SVG editor work in v1.0).
**Branch:** `mi110-phase4-diagram` off main, after Phase 2c lands or in parallel (separate surface, no conflict).

---

## What this ships

The interactive diagram editor that replaces the 220px gradient placeholder on the Company Side tab of the tapcard modal. Inspectors draw the triangulation diagram by hand (tap-and-drag on iPad, click-and-drag on desktop), with snap-to-grid, an anchor-locked CS marker, and persistence into the existing `tapcard_data` jsonb column.

This is the **most visually loud "incomplete" surface** in the app today. Closing it converts MyInspector from "demo with placeholder" to "complete tapcard product."

---

## Locked product principles this honors

(From `CLAUDE.md`. Re-stated to prevent drift.)

1. **CS is the anchor, always.** The CS marker on the diagram is fixed at center-bottom by default. The inspector cannot drag CS; they only place MP and asset markers relative to it. Triangulation rule is geometric, not editable.
2. **Inspectors do NOT do extra work for the app.** The editor opens with sensible defaults. Snap-to-grid is on by default. Undo/redo is one tap. No mode switches, no "select tool" pickers — every gesture is a draw or move.
3. **Manual click-and-drag is first-class** (per BB-001 locked decision). The AR auto-fill that Jorge proposed earlier is parked for after first paying non-CP customer. v1 of Phase 4 ships manual-only with no AR hooks.
4. **Mobile-first.** Touch gestures are the primary interaction. Mouse is a fallback. Test surface is iPad + iPhone, NOT desktop.
5. **Audit chain immutable.** Each diagram save = 1 audit_log row. Diagram payload (SVG markup or structured JSON, see below) is included in the audited data.

---

## Data model decision (locked)

**Path: extend the existing `tapcard_data jsonb` column on `phase_submissions`.** Do not create a new table or column.

Updated shape (Phase 2b shipped the first 3 keys; Phase 4 adds the 4th):

```json
{
  "company_side": { /* existing Phase 2b shape */ },
  "sector": "NJ6_NORMAL" | "NJAW_SHORT_HILLS",
  "materials_sheet_id_at_submit": "uuid",
  "diagram": {
    "version": 1,
    "format": "structured",
    "cs": { "x": 0.5, "y": 0.95 },
    "mp": [
      { "id": "mp-1", "x": 0.42, "y": 0.55, "label": "MP1", "distance_to_cs_ft": 8.5, "bearing_to_cs_deg": 47 }
    ],
    "assets": [
      { "id": "asset-1", "type": "watermain_tap", "x": 0.30, "y": 0.20, "label": "WM Tap" }
    ],
    "annotations": [
      { "id": "ann-1", "type": "arrow", "from": { "x": 0.50, "y": 0.95 }, "to": { "x": 0.42, "y": 0.55 }, "label": "8.5 ft" }
    ],
    "image_dimensions": { "width": 800, "height": 600 },
    "saved_at": "2026-05-03T14:00:00Z",
    "saved_by_profile_id": "uuid"
  }
}
```

**Coordinate system:** all positions normalized 0.0 → 1.0 on both axes (so the diagram scales cleanly between iPad portrait, iPhone, and desktop). The actual rendered pixel dimensions are computed at display time from `image_dimensions`.

**Why structured JSON over raw SVG markup:**

1. **Queryable.** A future "find all properties where MP is more than 30 ft from CS" query is one SQL on jsonb. Raw SVG would need parsing.
2. **Re-renderable.** The render layer is decoupled from the data layer. We can ship a v2 visual style (different colors, different markers) without migrating data.
3. **Diff-able.** Audit log can show exactly which markers moved between submissions.
4. **Portable.** Export to PDF, print to compliance package, ship to third-party reviewer — all work without SVG sanitization.

**Why NOT raw SVG:**

1. SVG injection risk. Storing user-generated SVG markup is a sanitization minefield, even within RLS.
2. Coupling. SVG markup ties the data layer to a specific rendering implementation.
3. Hard to extend. Adding a new field to a structured object is 1 line; modifying SVG markup at scale is hard.

---

## Scope by surface

### Surface 1 — Editor canvas (where the inspector draws)

**Replaces:** the 220px gradient placeholder div (Phase 2b) on the Company Side tab of the tapcard modal.

**Default state on open:**

- Canvas: 800×600 logical pixels, scales to viewport. Light grid background (10×10 grid lines, 5% opacity gray).
- CS marker: locked at center-bottom (`{x: 0.5, y: 0.95}` in normalized coords). Visual: filled circle, gold/amber color, 12px diameter, with text label "CS" below.
- Empty state: a faint "Tap to place MP" hint text near the upper third of the canvas.

**Inspector gestures:**

| Gesture | Action |
|---|---|
| **Tap on empty area** | Drop a new MP marker at that point. Auto-numbered (MP1, MP2, MP3...). Auto-computes distance + bearing from CS. |
| **Tap on existing MP** | Select it. Selected marker shows a 16px highlight ring. |
| **Drag selected MP** | Move it. Snap-to-grid in 5% increments. Distance/bearing recomputes live. |
| **Long-press selected MP** | Open marker editor: rename label, change color, delete. |
| **Tap on empty area while MP selected** | Deselect (without dropping a new MP). |
| **Two-finger pinch** | Zoom (constrained 1x–4x). |
| **Two-finger pan** | Pan (constrained to canvas bounds at current zoom). |
| **Three-finger tap** | Reset zoom + pan to default. |

**Toolbar (top of canvas, 6 buttons):**

1. **Undo** (← arrow icon, 32px) — reverts last gesture
2. **Redo** (→ arrow icon, 32px) — replays last undone gesture
3. **Add asset** (icon menu) — opens picker with 4 asset types (watermain_tap, valve, hydrant, other)
4. **Add annotation** (text "T" icon) — places a labeled arrow between two points (tap two points to define from + to)
5. **Snap toggle** (grid icon) — on by default; toggle off for free-position mode
6. **Clear all** (trash icon, requires confirmation) — wipes all MP/assets/annotations, restores empty state

### Surface 2 — Persistence + autosave (depends on Q-7)

If Q-7 = A (every-blur autosave) or B (10s timer):
- Diagram autosaves to `tapcard_data.diagram` on every gesture-end (mouseup or touchend).
- 1 audit_log row per save.
- Lossless: every save includes the full `diagram` object (not a delta), so revert-to-previous is straightforward via audit_log replay.

If Q-7 = C (Save Draft) or D (no autosave):
- Diagram persists in client-side state until explicit Save.
- Modal Close warns "you have unsaved diagram changes" if dirty.

### Surface 3 — Read-only mode (existing tapcards)

When viewing a previously-submitted tapcard, the editor opens in read-only mode:
- All gestures disabled (no add, no drag, no delete).
- Toolbar reduced to: Undo (disabled), Redo (disabled), Zoom in/out, Reset view.
- A pill at the top reads "Read-only — submitted [datetime] by [inspector]" in CDM-Smith yellow.

---

## Acceptance criteria (7 items, all must pass before PR opens)

1. **Empty state renders cleanly** on iPad portrait, iPhone, desktop — CS marker visible, grid visible, no scroll on the modal.
2. **MP placement works** by tap on iPad + iPhone, click on desktop. New MP auto-numbers (1, 2, 3...). Distance + bearing from CS populated correctly (verified with manual geometry test on 3 known points).
3. **Drag works.** Selecting an MP and dragging it updates its position. Distance + bearing recompute live. Snap-to-grid snaps to 5% increments unless toggled off.
4. **Undo/redo correct.** 5-action gesture sequence: place MP1, place MP2, drag MP1, place asset, undo undo undo undo redo → final state has only MP1 + MP2 (correctly sequenced).
5. **Save persists.** Saving a diagram with 3 MPs + 1 asset + 1 annotation produces a valid `tapcard_data.diagram` JSON object on the row, queryable via Supabase MCP.
6. **Read-only renders correctly.** Opening a previously-saved tapcard shows all markers in their saved positions with all gestures disabled.
7. **Audit chain holds.** Saving a diagram produces 1 audit_log row with prev_hash + row_hash populated correctly. Verified via Supabase MCP query.

---

## What this brief deliberately does NOT include

- **AR auto-fill** — parked as `BB-001`. Trigger to un-park is first paying non-CP customer.
- **Multi-user real-time collaborative editing** — parked. v1 is single-inspector per-session, last-write-wins.
- **PDF export of the diagram** — separate ticket. Once the structured JSON is solid, an export service is straightforward.
- **Third-party diagram review by supervisor** — supervisor sees the saved diagram in read-only mode via the existing supervisor dashboard. No new approval flow in v1.
- **Distance/bearing measurement annotations** — v1 auto-computes and displays distance + bearing on selected MP (in a small label near the marker). Manual measurement tool is v2.
- **Vector PDF underlay** — v2. v1 is blank-canvas only.

---

## Cross-cutting decisions to lock during build

(Lead surfaces these via `decisions.md` once chosen.)

1. **Library choice.** Plain SVG + vanilla JS event handlers vs. a library (Konva, Fabric.js, custom React + SVG). **Buddy recommendation:** plain SVG + vanilla — keeps the bundle small, no library churn risk, MyInspector ships as static HTML so adding a library is real cost. ~300–500 LOC for the editor itself.
2. **Touch gesture handling.** PointerEvent API (works for both touch + mouse + stylus uniformly) vs. separate touch + mouse handlers. **Buddy recommendation:** PointerEvents — cleaner code, supports stylus on iPad Pro for the Apple Pencil case Jorge mentioned in the AR conversation.
3. **Undo/redo storage.** Plain stack of full diagram states (simpler) vs. command pattern with deltas (smaller). **Buddy recommendation:** plain stack capped at 30 states — simpler, plenty of memory budget, deltas are not worth the complexity at this scale.
4. **Save throttling.** If Q-7 = A or B, autosave at gesture-end could fire many times in quick drags. Throttle saves to once per 1500ms while dragging, plus immediate save on drag-end. Lead validates final number against actual UX feel.

---

## Verification queries Lead should run (post-merge)

```sql
-- 1. First diagram-attached tapcard real shape-check
SELECT
  ps.id,
  ps.phase,
  ps.tapcard_data ? 'diagram' AS has_diagram_key,
  ps.tapcard_data -> 'diagram' -> 'cs' AS cs_position,
  jsonb_array_length(ps.tapcard_data -> 'diagram' -> 'mp') AS mp_count,
  jsonb_array_length(ps.tapcard_data -> 'diagram' -> 'assets') AS asset_count
FROM phase_submissions ps
WHERE ps.phase = 'tapcard'
  AND ps.deleted_at IS NULL
  AND ps.tapcard_data ? 'diagram'
ORDER BY ps.submitted_at DESC
LIMIT 5;

-- 2. Audit chain integrity around diagram saves (last 24h)
SELECT
  al.id,
  al.event_type,
  al.row_hash IS NOT NULL AS has_row_hash,
  al.prev_hash IS NOT NULL AS has_prev_hash,
  al.created_at
FROM audit_log al
WHERE al.event_type LIKE '%diagram%'
  AND al.created_at > now() - interval '24 hours'
ORDER BY al.created_at DESC
LIMIT 20;

-- 3. Distance/bearing sanity check (assuming pixel scale of 50ft per canvas width)
SELECT
  ps.id,
  jsonb_array_elements(ps.tapcard_data -> 'diagram' -> 'mp') AS mp
FROM phase_submissions ps
WHERE ps.phase = 'tapcard'
  AND ps.tapcard_data ? 'diagram'
LIMIT 10;
-- Then visually check that distance_to_cs_ft values are plausible (5–50 ft typical)
```

---

## Sequencing note

Phase 4 is the **highest-risk** v1 surface because:
1. SVG + touch event handling has lots of edge cases (gesture conflicts, scroll trapping, etc.)
2. The data model decision is one-way — once jsonb shape ships and inspectors save data, migrations are painful
3. Mobile testing requires real iPad + iPhone, not just dev tools simulation

**Lead's call: Phase 4 may want a 1-day spike branch first** to derisk the gesture handling and the iPad touch experience before committing to the full ~6-session build. Buddy supports this if Lead wants it.

If Lead skips the spike: budget +1 session of buffer for unexpected mobile issues.

---

## Q-110-a (open): Asset type enum scope for v1

The brief lists 4 asset types: watermain_tap, valve, hydrant, other. Are there other CDM-Smith / NJAW-required asset types that should ship in v1? Examples: meter, blowoff, sleeve, reducer.

Jorge to confirm or expand. List can be extended later via JSON schema (no migration needed since assets live in jsonb).

## Q-110-b (open): Read-only mode for prior tapcards without diagrams

Tapcards submitted before Phase 4 ships have `tapcard_data` without a `diagram` key. When an inspector opens one of these for review, what should the editor surface show?

**Options:**
- (a) Empty editor in read-only mode with a banner: "No diagram on this submission. Submitted before Phase 4."
- (b) Editable editor with no banner — inspector can add a diagram retroactively, which appends a NEW audit_log row.
- (c) Hide the diagram surface entirely on these older tapcards.

**Buddy default: (a).** Reading old data is a different concern than editing it — confusing the two surfaces is the kind of thing that breaks audit trail integrity.
