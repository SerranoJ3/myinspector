# Work Order — Phase 2d-revision Sessions 1+2 + MI-AUDIT-3 Fix

**Authored:** 2026-05-05 ~20:30 EDT
**By:** Buddy
**For:** Lead (Claude Code CLI) — next pickup
**Authority:** Jorge granted Buddy batch trust for the duration. Buddy's calls are ratified by default. Stop only on conditions in the "Stop Conditions" section.

---

## Pickup instructions

Read this file end-to-end before executing. All Q-answers are locked under batch trust. The brief at `.coordination/MI101_PHASE2D_REVISION_BRIEF.md` is the supplementary reference. Source-of-truth PDFs at `/mnt/user-data/uploads/Field_Data_Template.pdf` (blank) and `/mnt/user-data/uploads/Tapcard__1_.pdf` (filled-in example).

Three discrete units of work. Commit per unit. Push at end. Total estimated runway: ~4 hours focused.

---

## Locked answers (batch trust)

**Q-2d-revision-a — Diagram area in v1:** **(b) Placeholder text.** Render text reading "Diagram populated from MI-110 Phase 4 — ships next ticket" inside the diagram area's bounding box. Full dynamic diagram lands with MI-110 Phase 4 (separate ticket, ~6 sessions, brief on disk).

**Q-2d-revision-b — Materials Installed table autopop:** **(a) Extrapolation from service_type.** Function takes `materials_sheets.service_type` and `materials_sheets.new_njaw_size` as input, returns array of material rows. Suggested mapping (Lead overrides freely with field experience):

- `FULL` (full main-to-house service): 11 standard rows — 1" copper tubing (or sized off ms.new_njaw_size), plastic curb box top, plastic curb box bottom, 1"×1" curb stop, comp comp coupling, comp corporation, PVC meter pit, meter pit frame, meter pit lid, meter setter, meter idler.
- `KILL` (service abandonment): curb stop + corporation + cap rows.
- `M2C` (main-to-curb only): main-side subset — corporation + curb box + curb stop + connection between.
- `H2C` (curb-to-house only): house-side subset — copper tubing + meter pit assembly.
- `TP` (test pit): minimal — whatever was exposed during test pit.

Free-text materials column reads from `materials_sheets.service_materials_grid` jsonb where present; falls back to extrapolation otherwise.

**Q-AUDIT-3-a — `last_client_sync_at` future feature use:** **Unknown leaning yes — preserve the column.** Don't drop. Plausibly useful for stale-draft warnings, offline reconciliation, "last seen inspector" indicators in supervisor dashboard. Fix via **approach A** (trigger filter, skip audit on heartbeat-only UPDATEs) for fast ship. Approach B (move heartbeat to separate non-audited table) parked as future cleanup if approach A creates unexpected gaps.

---

## Unit 1 — Phase 2d-revision Session 1: Rebase visual tapcard onto materials_sheet modal

**Goal:** Move the visual tapcard preview off `#modal-tapcard` and onto `modal-materials-sheet` as a side-pane. Render paper-true static SVG. No autopop wiring yet (Unit 2 work).

### Tasks

1. **Remove vestigial Phase 2d work from `#modal-tapcard`:**
   - Delete the empty `<div id="visual-tapcard-preview-container">`
   - Remove `vtcInitOnOpen()` call from `openTapcardModal`
   - Remove `vtcReset()` call from `closeTapcardModal`
   - Remove `currentTapcard.property = prop` stash line
   - Remove the input event listener firing VTC render on `tc-co-*` changes (wrong surface for revision)
   - **PRESERVE** as reusable scaffolding: `VTC_FIELDS` config, render helper functions, debounce utility, inches-to-feet conversion. These survive into Unit 2.

2. **Embed visual tapcard preview as side-pane inside `modal-materials-sheet`:**
   - Desktop ≥1024px: 50/50 horizontal split — form left, preview right
   - Tablet 768–1023px: 55/45 split, form-favoring
   - Mobile <768px: stacked OR sub-tabbed (Form | Preview toggle) — Lead's UI craft

3. **Rewrite SVG layout to mirror NJAW Service Line Renewal Company Side paper exactly.** Sections (positions are guides, Lead adjusts to taste, paper proportions are the constraint):
   - **Tap Order block** — top-left ~(0.02–0.40 x, 0.02–0.30 y)
   - **Location Data block** — top-right ~(0.42–0.98 x, 0.02–0.30 y) with header "New Jersey American Water, [MUNICIPALITY]"
   - **Owner block** — mid-left ~(0.02–0.40 x, 0.31–0.45 y)
   - **Materials Installed table** — mid-left ~(0.02–0.40 x, 0.46–0.78 y) — EMPTY rows in Unit 1 (Unit 2 wires extrapolation)
   - **Diagram area** — mid-right ~(0.42–0.98 x, 0.31–0.85 y) — PLACEHOLDER text per Q-2d-revision-a=(b)
   - **Footer** — bottom span ~(0.02–0.98 x, 0.86–0.95 y)
   - **Job Notes / Official Use box** — very bottom ~(0.02–0.98 x, 0.96–1.0 y) — render visually but don't populate yet

4. **Use paper-true labels exactly per the PDF.** Full label inventory (do not paraphrase, match paper string-for-string):
   - "TAP ORDER" / "SERVICE NUMBER" / "TASK NO.'S" / "PARENT" / "PRIMARY" / "SECONDARY" / "DATE"
   - "SERVICE: [size] IN. MTR SET [size] IN [material] PIPE"
   - "OLD SERVICE: [size] IN. TAP [size] IN [material] PIPE"
   - "OLD SERVICE INSTALLATION DATE"
   - "ABANDONED" (checkbox) / "COMPANY OWNED" (checkbox) / "REMOVED" (checkbox)
   - "OWNER" / "LOCATION" / "LOT" / "BLOCK" / "MUNICIPALITY" / "TOWN SECTION" / "DEVELOPMENT" / "CROSS STREET"
   - "QUAN." / "SIZE" / "MATERIAL INSTALLED" (table column headers)
   - "LOCATION DATA"
   - "TOP OF [size] IN. [material] MAIN IS [ft] FT. [in] IN. BELOW SURFACE"
   - "AND [ft] FT. [in] IN. OF CURB ON [street]"
   - "TAP IS [ft] FT. [in] IN. FROM INTERSECTING CURB MEDIAN LINE ON [direction]"
   - "DISTANCE, TAP TO CURB STOP [ft] FT. [in] IN."
   - "DISTANCE, CURB TO CURB STOP [ft] FT. [in] IN."
   - "LOCATION OF CURB BOX [feet] FROM HOUSE"
   - "in the [Curb Box Location]"
   - "METER PIT LOCATION [size]" [side] OF CURB STOP"
   - "DATA FURNISHED BY [name]"
   - "DATE INSTALLED [date] BY [contractor]"
   - "POSTED TO SERVICE DATABASE BY" / "STOCK ENTERED BY" / "FAXED/SCANNED BY" (clerical, leave blank in v1)
   - "TIED IN" / "PLUG LOCK INSTALLED?"
   - "CUSTOMER SERVICE MATERIAL [material] SIZE [size] IN"
   - "COMPLETED DIAGRAM BY [name]"
   - "PURPOSE OF INSTALLATION"
   - Job Notes box: "District ID" / "Operating Center" / "County" / "Municipality" / "Service Number" / "Premise Number" / "Street Name" / "Street Number" / "Service Type" / "Date Completed" / "MapCall WorkOrder #" / "Lot" / "Block" / "Apt/Bldg" / "SAP Notification #" / "SAP Work Order #" / "Job Notes"
   - "THIS BOX FOR OFFICIAL USE ONLY. DO NOT WRITE WITHIN THIS BOX." (footer of Job Notes box)

5. **Empty fields render as thin gray underlines** (~15–20px wide at anchor position, paper-form mimic per Q-2d-c).

6. **Monospace font** for all rendered values: 'JetBrains Mono' primary, system mono fallback (per Q-2d-a).

7. **No print-to-PDF in v1** (per Q-2d-b, defer to v2).

8. **Sector dispatch:** visual tapcard renders only when `properties.sector === 'NJ6_NORMAL'`. `NJAW_SHORT_HILLS` sector renders a placeholder div with text "Visual tapcard unavailable for ShortHills sector — paper format differs from NJ6 Normal."

### Acceptance for Unit 1

- Visual tapcard renders inside `modal-materials-sheet`, NOT inside `#modal-tapcard`
- SVG layout mirrors NJAW paper structure (6 main sections + Job Notes box)
- All paper-true labels render correctly per the inventory above
- Empty fields = gray underlines, monospace font for any populated values
- Sector dispatch correct (NJ6_NORMAL renders, ShortHills shows placeholder)
- Layout responsive at desktop / tablet / mobile breakpoints
- `#modal-tapcard` no longer has the visual-tapcard-preview-container or its lifecycle hooks (vestigial cleanup verified)
- No regression on Materials Sheet form behavior (open / save / autocomplete / history view all behave identically)
- No regression on Tapcard modal behavior (open / submit / save still work)

### Commit message for Unit 1

```
feat(MI-101 Phase 2d-revision Session 1): rebase visual tapcard onto materials_sheet modal, paper-true layout

- Remove visual-tapcard-preview-container + lifecycle hooks from #modal-tapcard (vestigial after revision)
- Embed visual tapcard preview as side-pane inside modal-materials-sheet
- Paper-true SVG layout mirroring NJAW Service Line Renewal Company Side
- Diagram area placeholder per Q-2d-revision-a=(b); MI-110 Phase 4 ships dynamic diagram
- Sector dispatch: NJ6_NORMAL renders, ShortHills shows placeholder text
- Empty-state gray underlines + monospace + no PDF (Q-2d-a/b/c locks)
- Static render in this commit; autopop wiring lands in Session 2 (next commit)
```

---

## Unit 2 — Phase 2d-revision Session 2: Wire autopop + materials installed extrapolation

**Goal:** Bring the static SVG from Unit 1 to life — values flow as inspector fills the materials sheet form. Materials Installed table renders extrapolated rows per service_type.

### Tasks

1. **Build inches-to-feet+inches conversion utility** per brief spec. Three output formats:
   - `verbose`: returns `{ ft, in }` object → "X FT. Y IN." renders
   - `compact`: returns `"X'Y""` string → "40'0"" renders
   - `inches-only`: returns `'X"'` string → "22"" renders

2. **Wire autopop event listeners on `materials_sheets` form input changes:**
   - 100ms debounce on text inputs
   - Immediate update on enums / selects
   - Update ONLY the affected SVG text node, not full re-render
   - Use field source map per brief table (`materials_sheets` columns → tapcard positions)

3. **Property record fields wire from joined property at modal open:** `address_number`, `address_street`, `municipality`, `cross_street`, `lot`, `block`, `apt_bldg`, `owner_name`, `mapcall_id` (if present), `county` (if present), `sector` (decoded for District ID + Operating Center).

4. **Materials Installed table extrapolation per Q-2d-revision-b=(a):**
   - Build extrapolation function: `service_type` input → array of standard rows
   - Render rows into the table with auto-sized SIZE column from `ms.new_njaw_size`
   - Free-text materials column reads from `materials_sheets.service_materials_grid` jsonb where present; falls back to extrapolation otherwise

5. **Phase 2b tapcard form (`tc-co-*`) wires one-way INTO the visual tapcard inside materials_sheets modal.** When inspector switches between modals during a session, the visual reflects current state of both surfaces. Lead's craft on the binding mechanism — shared reactive state via small pub-sub helper, OR re-read DOM values whenever materials_sheets modal opens. Either is acceptable. Document the choice in the commit message.

6. **QA pass against the paper PDF:** open `/mnt/user-data/uploads/Tapcard__1_.pdf` side-by-side with the rendered visual. Verify every label string matches paper exactly. Verify every position roughly mirrors paper proportions. Use the filled-in example values from page 2 of the PDF (44 Dunnell Road, Maplewood) as a manual test card — fill the materials sheet with those values and watch the visual tapcard match the paper output.

### Acceptance for Unit 2

- Visual tapcard fields autopopulate as inspector fills materials sheet form (live, debounced)
- Inches columns convert correctly to feet+inches notation per format
- Materials Installed table renders extrapolated rows for FULL / KILL / M2C / H2C / TP service types
- `tc-co-*` field changes from Phase 2b modal also propagate to visual tapcard
- Paper PDF QA pass: filled-in example renders correctly against the paper
- No regression on existing Materials Sheet save / Tapcard submit flows

### Commit message for Unit 2

```
feat(MI-101 Phase 2d-revision Session 2): autopop wiring + materials installed extrapolation + paper-true QA

- Inches-to-feet+inches conversion utility (verbose / compact / inches-only formats)
- Autopop wiring: 100ms debounce text, immediate enum, materials_sheets columns → tapcard positions
- Property record fields wire from joined property at modal open
- Materials Installed table extrapolation function: service_type → standard rows
- tc-co-* one-way binding into visual tapcard inside materials_sheets modal
- QA pass against paper PDF: 44 Dunnell Road filled-in example renders correctly
```

---

## Unit 3 — MI-AUDIT-3 fix: Trigger filter for heartbeat-only UPDATEs (approach A)

**Goal:** Stop `audit_log` from logging heartbeat-only UPDATEs (where the only delta is `last_client_sync_at` or other whitelisted heartbeat fields). Cuts ~50% of current 288/24h baseline noise. Restores audit_log as deliberate-action-only.

### Tasks

1. **Survey heartbeat-not-state fields via Supabase MCP schema introspection.** Suggested candidates to check across all tables: `last_seen_at`, `last_client_sync_at`, `client_session_id`, `device_metadata`, `last_active_at`. Lead's call on which qualify as "heartbeat" (definition: client pings server with no business-state change, but UPDATE fires audit trigger anyway).

2. **Implement approach A trigger filter.** Modify `write_audit_log` (or table-specific audit triggers like `audit_phase_submissions_insert` if more localized): skip audit row creation when the only delta between OLD and NEW row is in the whitelist heartbeat field set.

3. **Whitelist starts with `last_client_sync_at`.** Lead adds other heartbeat fields surveyed in Step 1 to the whitelist if they qualify.

4. **Apply migration via Supabase MCP.** Migration name: `mi_audit_3_skip_heartbeat_audit`.

5. **Verification queries (Lead writes, applies via Supabase MCP read-only):**
   - **Pre-fix baseline:** count `audit_log` rows in last 24h where the only changed field is `last_client_sync_at` (quantify the noise being eliminated).
   - **Post-fix heartbeat test:** UPDATE a phase_submissions row with ONLY `last_client_sync_at = NOW()` change. Verify zero new audit_log rows fired.
   - **Post-fix real-state test:** UPDATE the same row with a notes field change. Verify exactly one new audit_log row fires.
   - **Hash chain integrity:** verify the chain is intact post-migration with no breaks.

### Acceptance for Unit 3

- Migration `mi_audit_3_skip_heartbeat_audit` applies clean
- Heartbeat-only UPDATEs do NOT fire audit triggers (verified via test)
- Real-state UPDATEs DO fire audit triggers (verified via test)
- Hash chain integrity intact
- Pre/post-fix noise reduction documented in commit message

### Commit message for Unit 3

```
fix(MI-AUDIT-3): trigger filter for heartbeat-only UPDATEs (approach A)

- Whitelist heartbeat fields: last_client_sync_at + [others surveyed]
- write_audit_log trigger now skips audit_log INSERT when only delta is whitelist field
- Pre-fix baseline: ~50% of 288/24h audit_log rows were heartbeat noise
- Post-fix verification: heartbeat UPDATE = 0 audit rows; real-state UPDATE = 1 audit row
- Hash chain integrity intact post-migration
- Migration: mi_audit_3_skip_heartbeat_audit
```

---

## Closing actions (after all 3 units commit)

1. **Push demo-banner to origin** — single push, 3 commits forward
2. **Update STATE.md** with closures: Phase 2d-revision Sessions 1 + 2 closed, MI-AUDIT-3 closed
3. **Update `.coordination/status.md`** with same closures + any new active investigations surfaced during build
4. **Append `.coordination/decisions.md` entries** for each of the 3 commits in chronological order (Session 1 entry, Session 2 entry, MI-AUDIT-3 entry)
5. **Cherry-pick decision (optional):** if cycles allow, cherry-pick the 3 Buddy doc commits (`dcd977c`, `2c81a9d`, `52d79c6`) onto main. Pre-authorized. If skipping, leave for next session.
6. **Final session-close commit** with STATE + status + decisions updates: `docs(.coordination): session-close — Phase 2d-revision + MI-AUDIT-3 shipped`
7. **Final push**

---

## Stop conditions

Lead stops and asks Buddy ONLY for:

- Q-answer ambiguity beyond what's locked in this work order (shouldn't trigger; all known questions locked)
- New schema migration touching audit chain trigger beyond the heartbeat fix (scope creep) requires Jorge approval
- BUDDY_STANDARD locked principle conflict (file-replace rule, em-dash `edit_file` mangling, dollar-quote tagging in SQL)
- Audit chain integrity check fails post-migration (would indicate a real chain break, NOT a scope question)

## Do NOT stop for

- Render quirks during build (debug and continue)
- Field map ambiguity (use brief; if brief silent, use Lead's craft and document in commit message)
- Mobile breakpoint judgment (Lead's UI craft)
- Materials Installed extrapolation rule edge cases (Lead's field experience)
- QA findings on label vocabulary (fix in commit, document discrepancy in commit message)
- Heartbeat field whitelist additions beyond `last_client_sync_at` (Lead's survey call)

---

## End-of-run report to chat

When all units complete:

- 3 commit hashes (Session 1, Session 2, MI-AUDIT-3)
- Final session-close commit hash
- Push hash
- STATE / status / decisions deltas summary
- Any open items surfaced for Buddy or Jorge follow-up

Velocity benchmark: ~4 hours focused for the full sweep. Use full context window. Go.
