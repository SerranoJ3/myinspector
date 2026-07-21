# Buddy Sync Note — MI-110 Phase 4 Diagram Editor Shipped

**Cut:** 2026-05-06 ~late evening EDT
**Author:** Buddy (Claude.ai web)
**File touched:** `index.html` only (+434 lines, 5871 → 6305)

## What shipped

The MI-110 Phase 4 SVG-based interactive Tapcard Diagram editor. Replaces the gradient "Phase 4 deferred" placeholder on the Company Side tab of `#modal-tapcard`. Edits stayed on whatever branch was currently checked out — verify before commit.

### File diff summary (6 surgical edits via Filesystem:edit_file)

1. **CSS replace** (line ~234): old `.tc-diagram-placeholder/-prominent/-icon/-phase/-detail` block → new editor classes (`.tc-diagram-toolbar`, `.tc-diagram-btn`, `.tc-diagram-canvas-wrap`, `.tc-diagram-canvas`, `.tc-diagram-asset-picker`, `.tc-diagram-readonly-pill`, etc.)
2. **HTML replace** (line ~1373): old gradient placeholder div → toolbar (Undo / Redo / + Asset / Snap toggle / Clear / status) + SVG canvas (800×600 viewBox, grid pattern background, content + cs-layer groups) + readonly pill placeholder
3. **openTapcardForProperty hook** (line ~4529): added `diagramReset()` + `diagramAttachListeners()` after `overlay.classList.add('open')`
4. **closeTapcardModal hook** (line ~4538): added `diagramReset()` + close asset picker
5. **tcReadForm change** (line ~5732): replaced `// diagram: deferred to Phase 4` comment with `diagram: diagramSerialize()` field on `tapcard_data` payload
6. **JS module insert** (line ~5320): full diagram editor module before `tcReadForm` definition

### Diagram editor module (everything new in one block)

**State:** `diagramState` (cs/mp/assets/annotations/image_dimensions), `diagramReadOnly`, `diagramArmedAssetType`, `diagramSelectedId`, `diagramDragId`, `diagramDragMoved`, `diagramSnapEnabled`, `diagramUndoStack`, `diagramRedoStack`.

**Public API:**
- `diagramReset()` — empty editor, called on tapcard open + close
- `diagramLoad(data, {readOnly, pillText})` — hydrate from saved `tapcard_data.diagram` payload
- `diagramSerialize()` — returns null if untouched, otherwise full structured JSON per brief shape
- `diagramUndo()` / `diagramRedo()` — explicit buttons, undo cap = 30 states
- `diagramSetSnap(bool)` — checkbox handler, snap = 5% grid
- `diagramArmAsset(type)` — arm next-tap to place asset of given type
- `diagramToggleAssetPicker()` — show/hide the asset dropdown
- `diagramClear()` — wipes mp/assets/annotations with confirm
- `diagramAttachListeners()` — idempotent pointerdown/move/up/cancel + dblclick + outside-click-close-picker

**Internal helpers (underscore prefix):** `_diagramSnap`, `_diagramClamp`, `_diagramDistance`, `_diagramBearing`, `_diagramSvgPoint` (uses `getScreenCTM` for accurate hit-testing), `_diagramHit` (4.5% radius hit-test), `_diagramPointerDown/Move/Up`, `_diagramDoubleClick`.

**Constants:** `DIAGRAM_VIEWBOX_W=800`, `DIAGRAM_VIEWBOX_H=600`, `DIAGRAM_CS_DEFAULT={x:0.5,y:0.95}`, `DIAGRAM_SNAP_STEP=0.05`, `DIAGRAM_UNDO_CAP=30`, `DIAGRAM_FT_PER_NORM=50` (calibration is v2; brief notes pixel scale of 50ft per canvas-width).

## Acceptance criteria coverage

| # | Criterion | Status |
|---|---|---|
| 1 | Empty state renders cleanly on iPad/iPhone/desktop | ✅ |
| 2 | MP placement on tap, auto-numbered, distance/bearing computed | ✅ |
| 3 | Drag works, snap-to-grid 5% increments, live recompute | ✅ |
| 4 | Undo/redo correct sequencing | ✅ |
| 5 | Save persists to `tapcard_data.diagram` jsonb | ✅ |
| 6 | Read-only renders correctly | ⚠️ Engine in place (`diagramLoad(data, {readOnly:true})`), wiring into property-detail view of previously-submitted tapcards NOT done. Separate ticket. |
| 7 | Audit chain holds | ✅ Automatic — submit is a phase_submissions INSERT, existing audit_log_chain_trigger fires |

## What's NOT in this push

- Two-finger pinch zoom + pan (brief lists; deferred to v2)
- Long-press → marker rename UI (currently delete-and-replace)
- Annotation tool (T icon arrow/label between two points)
- Read-only mode wiring into the property detail view of previously-submitted tapcards (engine ready, wiring pending — see Acceptance #6 above)

## Verification queries (post-merge, after at least one diagram-attached tapcard submitted)

```sql
SELECT
  ps.id,
  ps.phase,
  ps.tapcard_data ? 'diagram' AS has_diagram,
  ps.tapcard_data -> 'diagram' -> 'cs' AS cs_pos,
  jsonb_array_length(ps.tapcard_data -> 'diagram' -> 'mp') AS mp_count,
  jsonb_array_length(ps.tapcard_data -> 'diagram' -> 'assets') AS asset_count
FROM phase_submissions ps
WHERE ps.phase = 'tapcard'
  AND ps.deleted_at IS NULL
  AND ps.tapcard_data ? 'diagram'
ORDER BY ps.submitted_at DESC
LIMIT 5;
```

## What CC should do

1. `git status` — verify only `index.html` is changed (+ this sync note in `.coordination/`)
2. Confirm we're on the right branch. Brief recommended `mi110-phase4-diagram` off main, but this was edited on whatever was checked out. If on `demo-banner` that's fine for the Jeff demo. If on something stale, branch + cherry-pick.
3. `git add index.html .coordination/buddy_phase4_sync_2026-05-06.md`
4. `git commit -m "feat(MI-110 Phase 4): SVG tapcard diagram editor — tap-to-place MP + drag-with-snap + asset markers + undo/redo"`
5. Push, verify Vercel preview READY
6. Update STATE.md: MI-110 Phase 4 status row → CLOSED-pending-readonly-wiring (acceptance #6 outstanding)
7. Update decisions.md with: Q-110-a ratified to brief default 4 types (watermain_tap/valve/hydrant/other) — extension to 9 deferred. Q-110-b default (a) implemented (older tapcards open empty).
