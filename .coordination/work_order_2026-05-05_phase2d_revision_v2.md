# Work Order — Phase 2d-revision Sessions 1+2 — REVISED v2 (paper PDF + ground-truth schema + Phase 2a merge)

**Authored:** 2026-05-05 ~21:30 EDT
**By:** Buddy
**For:** Lead — pickup-ready
**Authority:** Jorge granted Buddy batch trust + Phase 2a → main merge authorization (5/5 evening, post-CC stop-and-ping caught documentation drift)
**Supersedes:** `.coordination/work_order_2026-05-05_phase2d_revision_plus_audit3.md` (v1, drafted from priors before schema verification)

---

## Why this revision exists

CC's stop-and-ping at ~21:20 EDT caught two real Buddy errors in v1:

1. **Documentation drift:** v1 work order assumed Phase 2a frontend (`modal-materials-sheet`) was merged to main. Verified via git: Phase 2a frontend lives on `mi101-phase2a` branch, never merged. Only backend migrations shipped Saturday. STATE.md, status.md, buddy_context.md, decisions.md all asserted "Phase 2a closed Sat — PR merged." That's wrong.
2. **Schema field map drift:** v1 referenced `properties.address_number`, `address_street`, `cross_street`, `lot`, `block`, `apt_bldg`, `owner_name`, `county` — none of those columns exist. Actual schema verified via Supabase MCP: `properties` has `address` (single string), `city`, `municipality`, `state`, `zip`, `lot_block` (concatenated), `lat`, `lng`, `mapcall_id`, `sector`. `materials_sheets` has flat NJAW/customer old/new columns — no `service_materials_grid` jsonb.

This revision corrects both. Lead executes against verified ground truth, no guessing.

**Source-of-truth references for this work order:**
- Paper PDFs: `/mnt/user-data/uploads/Field_Data_Template.pdf` (blank) + `/mnt/user-data/uploads/Tapcard__1_.pdf` (filled-in 44 Dunnell example)
- Schema (verified 2026-05-05 21:25 EDT via Supabase MCP `list_tables`): `properties` (19 columns), `materials_sheets` (39 columns), `phase_submissions` (24 columns)
- Source code (verified via git branch grep): `mi101-phase2a` branch contains `modal-materials-sheet`; main and demo-banner do not.

---

## Locked answers (batch trust, unchanged from v1)

- **Q-2d-revision-a:** (b) Diagram area renders as placeholder text "Diagram populated from MI-110 Phase 4 — ships next ticket"
- **Q-2d-revision-b:** (a) Materials Installed table autopops with NJAW new pipe row + extrapolates from `service_type` enum
- **Q-AUDIT-3-a:** Unknown leaning yes — preserve `last_client_sync_at`, fix via approach A (covered by separate Unit, see existing v1 work order MI-AUDIT-3 section — that ship continues independently)

---

## Verified ground truth — `properties` schema

```
id              uuid PK
address         text             -- single string, e.g. "44 Dunnell Road"
city            text             -- nullable
municipality    text             -- nullable, e.g. "Maplewood Township"
state           text             -- default 'NJ'
zip             text             -- nullable
lot_block       text             -- concatenated, e.g. "Lot 12 / Block 4"
lat             numeric          -- nullable
lng             numeric          -- nullable
mapcall_id      text             -- nullable, NJAW MapCall workorder reference
company_material   text          -- nullable
customer_material  text          -- nullable
current_phase   text             -- default 'test_pit', enum-checked elsewhere
firm_id         uuid FK firms
created_at      timestamptz
deleted_at      timestamptz
deleted_by      uuid
sector          text             -- 'NJ6_NORMAL' or 'NJAW_SHORT_HILLS', default NJ6_NORMAL
project_id      uuid FK projects
```

**NOT present (do not reference in field map):** `address_number`, `address_street`, `cross_street`, `lot` (separate from lot_block), `block` (separate), `apt_bldg`, `owner_name`, `county`, `town_section`, `development`, `street_name`, `street_number`.

---

## Verified ground truth — `materials_sheets` schema

```
id                       uuid PK
property_id              uuid FK properties
firm_id                  uuid FK firms
submitted_by             uuid
created_at               timestamptz
deleted_at               timestamptz
deleted_by               uuid
sheet_date               date
contractor_name          text             -- e.g. "Montana Construction"
service_type             text             -- e.g. "FULL-MP", "KILL", etc.
foreman_name             text             -- NOT 'foreman'
temperature_f            smallint         -- NOT 'temp_f', range -50..150
sky_condition            text             -- 'sunny','cloudy','rain','snow','other'
test_pit                 boolean
kill_location            text             -- e.g. "Kill at Main"
curb_box_location        text             -- enum: 'city_strip','sidewalk','driveway','lawn'
curb_box_replaced        boolean
num_excavations          smallint
notes                    text
corp_depth_inches        smallint         -- e.g. 53 = 4'5"
cs_depth_inches          smallint
cs_house_inches          smallint         -- e.g. 480 = 40'0"
cs_rs_inches             smallint
cs_ls_inches             smallint
cs_near_curb_inches      smallint
cs_far_curb_inches       smallint
cs_corp_inches           smallint
cs_mp_inches             smallint
size_of_main_inches      numeric          -- e.g. 6
type_of_main             text             -- e.g. "CAST IRON"
service_side             text             -- enum: 'long','short'
njaw_old_size_inches     numeric          -- e.g. 0.75
njaw_old_material        text             -- e.g. "GALVANIZED"
njaw_new_size_inches     numeric          -- e.g. 1
njaw_new_material        text             -- e.g. "COPPER"
njaw_new_amount_feet     smallint         -- e.g. 20
customer_old_size_inches numeric
customer_old_material    text
customer_new_size_inches numeric
customer_new_material    text
customer_new_amount_feet smallint
multi_tenant             boolean
num_units                smallint
pitcher_delivered        boolean
downtime_hours           numeric
downtime_notified        boolean
existing_mp_noted        boolean          -- CDM-Smith rule (b)
mp_horn_copper_inches    smallint
```

**NOT present:** `service_materials_grid` jsonb. Materials data is FLAT (njaw_old_*, njaw_new_*, customer_old_*, customer_new_*).

---

## Corrected field-to-position map (paper tapcard target ← actual source columns)

### Top-left: Tap Order block
| Paper position | Source |
|---|---|
| SERVICE NUMBER | `tc-co-service_number` (Phase 2b form input — inspector types in tapcard modal) |
| TASK NO.'S Parent / Primary / Secondary | `tc-co-task_numbers` (Phase 2b form, parsed comma-sep for the 3 sub-fields) |
| DATE | `materials_sheets.sheet_date` (preferred), fallback to `tc-co-date` |
| SERVICE: [size] IN. MTR SET [size] IN [material] PIPE | Compose from `materials_sheets.njaw_new_size_inches` + `njaw_new_material` |
| OLD SERVICE: [size] IN. TAP [size] IN [material] PIPE | Compose from `materials_sheets.njaw_old_size_inches` + `njaw_old_material` |
| OLD SERVICE INSTALLATION DATE | Not in current schema — render blank in v1, future column add if needed |
| ABANDONED / COMPANY OWNED / REMOVED checkboxes | Not in v1 — render as paper checkboxes, blank state |

### Top-right: Location Data block
| Paper position | Source |
|---|---|
| Header "New Jersey American Water, [MUNICIPALITY]" | `properties.municipality` |
| TOP OF [size] IN. [material] MAIN IS [ft] FT. [in] IN. BELOW SURFACE | `materials_sheets.size_of_main_inches` + `type_of_main` + (`corp_depth_inches` → ft+in) |
| AND [ft] FT. [in] IN. OF CURB ON [street] | Distance unclear from paper alone — render blank in v1, document in commit |
| TAP IS [ft] FT. [in] IN. FROM INTERSECTING CURB MEDIAN LINE ON [direction] | `materials_sheets.cs_far_curb_inches` → ft+in for distance; direction not in schema, render blank |
| DISTANCE, TAP TO CURB STOP [ft] FT. [in] IN. | `materials_sheets.cs_corp_inches` → ft+in |
| DISTANCE, CURB TO CURB STOP [ft] FT. [in] IN. | `materials_sheets.cs_near_curb_inches` → ft+in |
| LOCATION OF CURB BOX [feet] FROM HOUSE | `materials_sheets.cs_house_inches` → compact `X'Y"` notation |
| "in the [Curb Box Location]" | `materials_sheets.curb_box_location` enum, decode for display: `city_strip` → "City Strip", `sidewalk` → "Sidewalk", `driveway` → "Driveway", `lawn` → "Lawn" |
| METER PIT LOCATION [size]" [side] OF CURB STOP | `materials_sheets.cs_mp_inches` (raw inches notation, e.g. `22"`) + a side enum (LEFT/RIGHT — not currently in schema, render blank in v1; add `cs_mp_side` text column in future migration if Jorge confirms) |
| DATA FURNISHED BY [name] | `auth.users.email` → resolve to inspector full name via `profiles.full_name` join, OR fallback to email username |

### Mid-left: Owner block
| Paper position | Source |
|---|---|
| OWNER | Not in current properties schema — render blank in v1 (future: add `owner_name` column or pull from a future homeowner_contact_log) |
| LOCATION | `properties.address` (single string, full address — no number/street split) |
| LOT / BLOCK | `properties.lot_block` (single concatenated string — render whole as "LOT/BLOCK [value]") |
| MUNICIPALITY / TOWN SECTION | `properties.municipality` for both columns (Town Section not in schema) |
| DEVELOPMENT | Not in schema — render blank |
| CROSS STREET | Not in schema — render blank in v1 (future column add if Jorge confirms field need) |

### Mid-left: Materials Installed table
Per Q-2d-revision-b: extrapolate rows from `materials_sheets.service_type`. Lead's craft on the rules. Suggested mapping:

- `FULL` (full main-to-house): rows scaled by `njaw_new_size_inches` —
  - QUAN `njaw_new_amount_feet`, SIZE `njaw_new_size_inches`, MATERIAL `[njaw_new_size]" [njaw_new_material] TUBING (TYPE 'L')`
  - QUAN 1, SIZE 6", MATERIAL "PLASTIC CURB BOX TOP"
  - QUAN 1, SIZE 6", MATERIAL "PLASTIC CURB BOX BOTTOM"
  - QUAN 1, SIZE `[njaw_new_size]"-[njaw_new_size]"`, MATERIAL "C × C ORI CURB STOP"
  - (blank), (blank), MATERIAL "COMP. COMP. COUPLING"
  - QUAN 1, SIZE `[njaw_new_size]"`, MATERIAL "COMP. CORPORATION"
  - QUAN 1, SIZE "20"-30"", MATERIAL "PVC METER PIT"
  - QUAN 1, SIZE "20"", MATERIAL "METER PIT FRAME"
  - QUAN 1, SIZE "20"", MATERIAL "METER PIT LID"
  - QUAN 1, SIZE `[njaw_new_size]"`, MATERIAL "METER SETTER"
  - QUAN 1, SIZE `[njaw_new_size]"`, MATERIAL "METER IDLER"
- `KILL` (service abandonment): minimal rows —
  - QUAN 1, SIZE `[njaw_new_size]"`, MATERIAL "COMP. CORPORATION"
  - QUAN 1, SIZE `[njaw_new_size]"`, MATERIAL "C × C ORI CURB STOP"
  - QUAN 1, SIZE (blank), MATERIAL "CAP"
- `M2C` (main-to-curb): main-side subset — corporation + curb stop + connection coupling
- `H2C` (curb-to-house): house-side subset — copper tubing + meter pit assembly (frame, lid, setter, idler)
- `TP` (test pit): minimal — whatever was exposed in test pit (Lead's call, document defaults in commit)
- `MP` (meter pit only): meter pit assembly (PVC pit, frame, lid, setter, idler)

Reference for Lead: `parts_catalogs` table has 16 NJ6_NORMAL rows seeded — use as source-of-truth for valid SIZE / MATERIAL combinations if available.

### Mid-right: Diagram area
**Per Q-2d-revision-a=(b): render placeholder text "Diagram populated from MI-110 Phase 4 — ships next ticket".** No dynamic rendering in v1.

### Footer (bottom span)
| Paper position | Source |
|---|---|
| DATE INSTALLED [date] BY [contractor] | `materials_sheets.sheet_date` + `materials_sheets.contractor_name` (overrides: `tc-co-date_installed` + `tc-co-installed_by`) |
| POSTED TO SERVICE DATABASE BY / STOCK ENTERED BY / FAXED/SCANNED BY | Clerical, blank in v1 |
| TIED IN [Y/N] | `tc-co-tied_in` (Phase 2b form input) |
| PLUG LOCK INSTALLED? [Y/N] | `tc-co-plug_lock` |
| CUSTOMER SERVICE MATERIAL [material] SIZE [size] IN | Compose from `materials_sheets.customer_new_material` + `customer_new_size_inches` (overrides: `tc-co-cust_mat` + `tc-co-size`) |
| COMPLETED DIAGRAM BY [name] | `tc-co-completed_by` |
| PURPOSE OF INSTALLATION | Not in current schema (closest: `service_type` describes the work but isn't quite the same — render `service_type` decoded as default, e.g. `FULL` → "STANDARD RENEWAL", future column add if Jorge confirms need) |

### Bottom: Job Notes / Official Use box
| Paper position | Source |
|---|---|
| District ID | Decode `properties.sector`: `NJ6_NORMAL` → blank or "NJ6", `NJAW_SHORT_HILLS` → "ShortHills" |
| Operating Center | `properties.sector` decode: `NJ6_NORMAL` → "NJ6", `NJAW_SHORT_HILLS` → "Short Hills NJAW" |
| County | Not in `properties` schema — render blank in v1 (future: lookup from `municipalities_contractors` table per MI-402) |
| Municipality | `properties.municipality` |
| Service Number | Mirror of `tc-co-service_number` |
| Premise Number | Same value as Service Number (NJAW conflates these on the paper) |
| Street Name | Parse from `properties.address` (split on first space — first token is number, rest is street) |
| Street Number | Parse from `properties.address` (first token before space) |
| Service Type | Compose: water utility module → "WATER " + sector code → "WATER NJ6" or "WATER ShortHills" |
| Date Completed | `materials_sheets.sheet_date` or `tc-co-date_installed` |
| MapCall WorkOrder # | `properties.mapcall_id` |
| Lot / Block / Apt/Bldg | `properties.lot_block` (split if formatted "Lot X / Block Y", else render whole in Lot field) — `apt_bldg` not in schema, blank |
| SAP Notification # / SAP Work Order # | Not in schema, blank |
| Job Notes | `materials_sheets.notes` (preferred) or `phase_submissions.notes` |

---

## Unit 0 — Phase 2a → main merge (NEW — required before Units 1+2)

**Goal:** Get `mi101-phase2a` branch (which contains the `modal-materials-sheet` editable form) merged into main so Phase 2d-revision Units 1+2 can target the correct surface.

### Tasks

1. **Verify branch state pre-merge:**
   - `git fetch origin`
   - `git log mi101-phase2a..main --oneline` to see what's on main since Phase 2a branched (expect: Phase 2b refactor merge `4d70901`, possibly others)
   - `git log main..mi101-phase2a --oneline` to see Phase 2a's unique commits (expect: `04fd6b1` form + `a542d5a` polish)

2. **Strategy: rebase mi101-phase2a onto current main, then squash-merge.** Reasoning:
   - Phase 2a was branched before Phase 2b refactor merged. Conflicts likely in index.html.
   - Rebase resolves conflicts incrementally and gives a clean linear history.
   - Squash-merge into main keeps main's commit history tidy.

3. **Execute rebase:**
   - `git checkout mi101-phase2a`
   - `git rebase main`
   - Resolve any conflicts in index.html — Phase 2a adds NEW HTML/JS (modal-materials-sheet + Phase 2a form fields + Open Materials Sheet button on Property Detail). Phase 2b refactor modified EXISTING HTML/JS (#modal-tapcard tab structure). The changes should be in different regions of index.html. Conflict resolution should preserve BOTH: keep Phase 2a's new modal additions AND keep Phase 2b refactor's tapcard modal changes.
   - If conflict resolution gets ambiguous, stop and ping Buddy.

4. **Test post-rebase:**
   - Local serve (or push to a temp branch and Vercel preview)
   - Verify: Property Detail has "Open Materials Sheet" button, button opens `modal-materials-sheet` with editable form, save flow works, materials_sheets table writes succeed
   - Verify: Submit Phase → Tapcard modal still works per Phase 2b refactor (2-tab structure preserved)

5. **Squash-merge to main:**
   - `git checkout main`
   - `git merge --squash mi101-phase2a`
   - `git commit -m "feat(MI-101 Phase 2a frontend): Materials Sheet modal — Sections A-G + autocomplete + history view"`
   - `git push origin main`

6. **Bring demo-banner up to date:**
   - `git checkout demo-banner`
   - `git rebase main` (or `git merge main` — Lead's call; rebase is cleaner)
   - Resolve any conflicts (should be minimal since demo-banner's commits are mostly .coordination/ docs + the Phase 2c lean scaffold + Phase 2d original)
   - `git push origin demo-banner --force-with-lease` if rebased

### Acceptance for Unit 0

1. `mi101-phase2a` branch successfully rebased onto current main with no unresolved conflicts
2. Squash-merged to main with single feature commit
3. Vercel main deployment confirms `modal-materials-sheet` is now live
4. Materials Sheet form save → DB write succeeds (verify via Supabase MCP query: row count goes from 3 to 4 after a test save)
5. Tapcard modal behavior unchanged (Phase 2b refactor preserved)
6. demo-banner branch rebased / merged forward, ready for Units 1+2

### Stop conditions for Unit 0

- Conflict resolution ambiguity (stop and ping Buddy)
- Rebase introduces a regression on either Phase 2a OR Phase 2b refactor functionality (stop and surface)
- Vercel deploy fails post-merge

### Commit message for Unit 0

```
feat(MI-101 Phase 2a frontend): Materials Sheet modal — Sections A-G + autocomplete + history view

Brings the Phase 2a frontend (originally PR'd 5/2 as mi101-phase2a) onto main.
Documentation drift correction: previously asserted closed Sat — only backend
migrations had shipped. This commit lands the editable modal-materials-sheet
that backs all the materials_sheets writes.

Squash of:
- 04fd6b1 feat(MI-101 Phase 2a): Materials Sheet UI — Sections A-G, ~36 fields
- a542d5a feat(MI-101 Phase 2a): polish — autocomplete + history view

Rebased onto current main (post Phase 2b refactor merge 4d70901). No
overlap with Phase 2b's #modal-tapcard restructure — Phase 2a adds a new
modal entirely.
```

---

## Unit 1 — Phase 2d-revision Session 1: Rebase visual tapcard onto materials_sheet modal

[Unchanged from v1 work order in scope; ONLY the field map changes per the corrected ground truth above. All steps 1-8 from v1 remain valid:
remove vestigial work from #modal-tapcard, embed container in modal-materials-sheet (NOW EXISTS post-Unit-0), rewrite SVG layout to mirror NJAW Service Line Renewal Company Side, paper-true labels, gray underline empty states, monospace font, no print-to-PDF, sector dispatch.]

Reference v1 work order for full Unit 1 step list. Only the field map (above in this v2) supersedes.

### Commit message for Unit 1

```
feat(MI-101 Phase 2d-revision Session 1): rebase visual tapcard onto materials_sheet modal, paper-true layout

- Remove visual-tapcard-preview-container + lifecycle hooks from #modal-tapcard (vestigial after revision)
- Embed visual tapcard preview as side-pane inside modal-materials-sheet (Phase 2a frontend, merged in Unit 0)
- Paper-true SVG layout mirroring NJAW Service Line Renewal Company Side
- Diagram area placeholder per Q-2d-revision-a=(b); MI-110 Phase 4 ships dynamic diagram
- Sector dispatch: NJ6_NORMAL renders, ShortHills shows placeholder text
- Empty-state gray underlines + monospace + no PDF (Q-2d-a/b/c locks)
- Static render in this commit; autopop wiring lands in Session 2
- Field map verified against ground-truth schema (properties + materials_sheets via Supabase MCP introspection)
```

---

## Unit 2 — Phase 2d-revision Session 2: Wire autopop + materials installed extrapolation

[Unchanged from v1 in scope, with corrected field bindings per the corrected map above. v1 step list remains valid:
inches-to-feet+inches utility, autopop event listeners on materials_sheets form input changes, property record autopop at modal open, Materials Installed extrapolation per service_type, tc-co-* one-way binding, paper QA pass.]

### Commit message for Unit 2

```
feat(MI-101 Phase 2d-revision Session 2): autopop wiring + materials installed extrapolation + paper-true QA

- Inches-to-feet+inches conversion utility (verbose / compact / inches-only formats)
- Autopop wiring: 100ms debounce text, immediate enum, materials_sheets columns → tapcard positions per verified field map
- Property record fields wire from joined property at modal open (address, municipality, mapcall_id, lot_block, sector)
- Materials Installed extrapolation function: service_type → standard rows
- tc-co-* one-way binding into visual tapcard inside materials_sheets modal
- QA pass against paper PDF: 44 Dunnell Road filled-in example renders correctly against Tapcard__1_.pdf page 2
```

---

## Unit 3 — Documentation drift correction

**Goal:** Fix the false "Phase 2a closed Sat" assertions across STATE.md, status.md, buddy_context.md, decisions.md.

### Tasks

1. **STATE.md:** Update the "Active gate: v0.1 Compliance Foundation" table — Phase 2a row should read "Backend migrations Closed Sat / Frontend modal merged via Unit 0 [date]". Note Unit 0 ship hash.

2. **status.md:** Recently-shipped section — change "Sat 5/2: 3 PR squash-merges (`mi203-step2`, `mi101-phase2a`, `mi101-phase2b` original)" to "Sat 5/2: 2 PR squash-merges (`mi203-step2`, `mi101-phase2b` original) + `mi101-phase2a` backend migration shipped, frontend held". Add Unit 0's eventual merge as new entry.

3. **buddy_context.md:** Bootstrap digest — update "Saturday's three PR merges" to "Saturday's two PR merges + Phase 2a backend-only ship". Add to "Banked discipline" section: "Verify branch merge state via git, not documentation, before referencing as merged in any work output."

4. **decisions.md:** Append entry for the correction:

```
## 2026-05-05 ~21:30 EDT — Documentation drift caught: Phase 2a frontend never merged (only backend)

**Decision:** Correct STATE.md / status.md / buddy_context.md to reflect actual state — Phase 2a's `modal-materials-sheet` editable form lives on `mi101-phase2a` branch, never merged to main. Backend migrations did ship Saturday and are live in prod. Documentation drift introduced sometime after the original PR was opened; root cause likely confusion between "PR opened + verified on preview" vs "PR merged".

**Source:** Lead (Claude Code CLI) caught during Phase 2d-revision Session 1 stop-and-ping at ~21:20 EDT — the work order targeted `modal-materials-sheet` but `git show main:index.html | grep modal-materials-sheet` returned 0. Cross-branch verification confirmed only `mi101-phase2a` and `origin/mi101-phase2a` contain the modal.

**Affects:** Production today: inspectors cannot create materials_sheets via UI (only via direct SQL or Phase 2a preview deployment). The 3 existing materials_sheets rows came from preview testing. Phase 2d-revision Unit 0 (added in v2 work order) merges Phase 2a → main as precondition.

**Banked discipline:** Buddy verifies branch state via filesystem MCP `view` or git log before referencing any branch as merged in work output. Tools available — Filesystem MCP, Supabase MCP, Vercel MCP — were not used pre-draft of the v1 work order. Pattern of failure: drafting from documentation/priors instead of verifying ground truth. Same pattern as 5/5 earlier mistakes (decisions.md head:100 truncation, Phase 2d brief field-from-priors). Locked: any work order or brief touching a target surface, schema, or branch state requires MCP verification of ground truth before draft.

**Source-of-truth restored:** `properties` schema (verified 2026-05-05 21:25 EDT via Supabase MCP `list_tables`): 19 columns, no address_number/address_street/cross_street/lot/block/apt_bldg/owner_name/county. `materials_sheets` schema: 39 columns, flat NJAW/customer old/new (no service_materials_grid jsonb). v2 work order field map corrected against verified ground truth.
```

### Commit message for Unit 3

```
docs(.coordination): correct Phase 2a documentation drift — frontend never merged

- STATE.md: Phase 2a row now reflects backend-shipped / frontend-pending-merge
- status.md: Saturday merges count corrected (2 not 3)
- buddy_context.md: bootstrap digest updated; banked discipline lesson added
- decisions.md: drift correction entry + ground-truth schema verification entry

Catches a real production gap: inspectors cannot create materials_sheets via UI on prod main. The 3 existing rows came from Phase 2a preview deployment testing. Phase 2d-revision Unit 0 merges Phase 2a → main as precondition.
```

---

## Closing actions (after all units commit)

Same as v1 — push, STATE/status/decisions deltas, optional cherry-pick of Sunday docs commits onto main.

---

## Stop conditions

Same as v1, plus new:
- **Unit 0 conflict resolution ambiguity** during rebase: stop and ping Buddy

## Do NOT stop for

Same as v1.

---

## End-of-run report

- 4 commit hashes (Unit 0 merge, Unit 1, Unit 2, Unit 3 docs)
- Final session-close commit hash
- Push hash (origin/main + origin/demo-banner)
- STATE / status / decisions deltas summary
- Any open items for Buddy or Jorge follow-up

Velocity: ~4-5 hours focused. Unit 0 adds ~30-45 min for rebase + conflict resolution + post-merge verification. Use full context window. Go.
