# MI-108 Frontend Brief — for Lead

**Ticket:** MI-108 (No-Work Submission Workflow)
**Source rule:** CDM-Smith email rule (a) — no-work case requires house photo + whiteboard photo + reason
**Backend status:** ✅ DONE (migration `mi108_no_work_submission_workflow` applied 2026-05-02 ~13:50 EDT via Supabase MCP)
**Frontend status:** awaiting Lead
**Velocity estimate:** 1 session at benchmark (~20 milestones)

---

## What landed (backend, for context)

**`phase_submissions` schema changes:**

| Column | Type | Notes |
|---|---|---|
| `photo_house_url` | text | nullable; required when `phase='no_work'` |
| `photo_no_work_whiteboard_url` | text | nullable; required when `phase='no_work'` |
| `photo_no_work_whiteboard_detected` | boolean DEFAULT false | must be `true` when `phase='no_work'` (set by `detect-whiteboard` Edge Function) |
| `no_work_reason` | text | nullable; required when `phase='no_work'`, length ≥ 20 chars |

**Phase enum:** 8 → 9 values. Added `'no_work'` to `phase_submissions_phase_enum` CHECK constraint.

**New invariant constraint** `phase_submissions_no_work_invariant`:
```
CHECK (
  phase <> 'no_work' OR (
    photo_house_url IS NOT NULL
    AND photo_no_work_whiteboard_url IS NOT NULL
    AND photo_no_work_whiteboard_detected = true
    AND no_work_reason IS NOT NULL
    AND length(trim(no_work_reason)) >= 20
  )
)
```

**Audit:** existing `audit_phase_submissions_insert` AFTER trigger handles audit_log entries automatically. **No manual audit chaining needed in frontend.** Expected `audit_log` delta on a no-work submission = `+1`.

**Architectural calls banked in `.coordination/decisions.md`** (2026-05-02 13:55 EDT):
- NB1: phase enum value, not a flag (parity with other phase types)
- NB2: two separate photos (house + whiteboard are distinct artifacts per locked field convention)
- NB3: direct INSERT + CHECK constraints, no RPC (single-table writes; trigger handles audit)
- NB4: reason min 20 chars (mirrors MI-109)
- NB5: ship without inspector "I confirm whiteboard" toggle (false-positive parked under existing prompt-tuning queue)

---

## What needs to be built (your work)

### 1. New "No Work" tile in Submit Phase tile grid (`index.html`)

- Add to existing tile grid alongside Test Pit, Assessment, Service Work, Restoration, GIS Doc, Out of Sequence, Tapcard, Work Order.
- Distinct visual treatment (suggest gray or red — distinguishable from work-happening tiles since this tile means "we showed up, no work happened today").
- Tap → opens No-Work submission flow (Section 2).

### 2. No-Work submission flow (modal, sequential view, or new screen — Lead's call)

**Step A — House photo capture**
- Use existing photo pipeline (compression: 2600px max long edge, JPEG quality 0.85, target 1.5–3 MB)
- Upload to Supabase storage (existing bucket pattern from MI-002 photo system)
- Store returned URL → assign to `photo_house_url`
- **No whiteboard required for this slot** — it's the property exterior documentation photo per the locked NJAW field convention
- Standard "take photo" UI; no whiteboard prompts

**Step B — Whiteboard photo capture**
- Same photo pipeline as Step A
- Upload to storage → URL → assign to `photo_no_work_whiteboard_url`
- After upload: invoke `detect-whiteboard` Edge Function with the URL
- Store edge function response (boolean) → `photo_no_work_whiteboard_detected`
- UI: explicit "Whiteboard required — must show address, date, foreman, inspector, AND reason" hint (mirrors existing curbstop/watermain whiteboard tiles)
- If detection returns `false`: show "Whiteboard not detected — retake?" with retry. Don't allow Step D submit until `detected=true` (CHECK will block anyway, but pre-empt for UX)

**Step C — Reason text field**
- Multiline text input (textarea)
- Live character counter showing N/20 minimum
- "Submit" button disabled until length ≥ 20
- Mirror the MI-109 reason field UX pattern (Carlo modal — reuse component if cleanly extractable, otherwise duplicate)

**Step D — Submit (direct INSERT to `phase_submissions`)**

Insert row:
```js
{
  phase: 'no_work',
  property_id: <selected property uuid>,
  submitted_by: <auth.uid()>,
  firm_id: <profile firm_id from auth context>,
  photo_house_url,
  photo_no_work_whiteboard_url,
  photo_no_work_whiteboard_detected,
  no_work_reason
}
```

- On CHECK violation: parse PG error (constraint name `phase_submissions_no_work_invariant`) and show clear inspector-facing message
- On success: navigate back to property detail / submissions list with success toast
- No additional audit code needed — trigger fires automatically

### 3. Tests directory — `tests/mi108/`

| File | What it tests |
|---|---|
| `no_work_constraint_test.sql` | Each invariant clause rejects bad data (missing photo_house_url, missing whiteboard_url, detected=false, reason null, reason <20 chars). Use tagged dollar-quotes (`$TESTBODY$`) per `decisions.md` 2026-05-02 ~11:00 EDT. |
| `rls_test.sql` | Firm isolation on no_work submissions (mirror `tests/mi109/rls_test.sql` shape) |
| `audit_integrity_test.sql` | Verify `audit_log` delta = `+1` on a successful no_work insert (single table, single audit row — unlike MI-109's `+2` because MI-108 only writes one Owner Data row) |
| `e2e_checklist.md` | Manual UI walk (gated on isolated test tenant; defer execution like MI-109.5) |

---

## Acceptance criteria

- [ ] No-work submission with all 4 fields valid → INSERT succeeds, `audit_log` +1
- [ ] Missing `photo_house_url` → CHECK fails, frontend shows clear error
- [ ] Missing `photo_no_work_whiteboard_url` → CHECK fails, frontend shows clear error
- [ ] `photo_no_work_whiteboard_detected = false` → CHECK fails (and frontend pre-empts before submit)
- [ ] `no_work_reason` length < 20 chars → CHECK fails (and frontend pre-empts via disabled button)
- [ ] Other phase types (test_pit, service_work, etc.) unaffected by new constraint — existing 33 rows still valid, new submissions of other types don't trigger no_work invariant
- [ ] Whiteboard false-positive risk acknowledged: laptop screens currently get detected as whiteboards; ship anyway per NB5

---

## Constraints / locked rules to honor

- **BUDDY_STANDARD §7:** Code edits >3 lines = full-file replace, not surgical
- **Photo pipeline spec:** 2600px max long edge, JPEG quality 0.85
- **`detect-whiteboard` Edge Function:** existing — don't rebuild; just call it with the whiteboard URL
- **No new RPCs needed** — direct INSERT per NB3
- **Tagged dollar-quotes** (`$TESTBODY$`) in any SQL test files

---

## Open questions for Buddy/Jorge (none currently)

If anything ambiguous surfaces during build, write to `.coordination/questions.md` with `**Awaiting:** Jorge` (or Buddy if architectural). Don't block on chat round-trip if a sensible default exists — note the assumption and proceed.

---

**Ready to pick up.** Backend verified post-migration via schema introspection query (4 columns + 2 constraints landed cleanly). Buddy will verify your work post-merge via Supabase MCP — same pattern as MI-109 Phase 4.
