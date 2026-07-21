# MI-101 Phase 2d-Revision — Visual Tapcard Preview, Paper-True Layout

**Status:** Brief — supersedes original `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md` and the work shipped tonight in commit `79f8434`.
**Drafted:** 2026-05-05 ~19:50 EDT
**By:** Buddy
**Source-of-truth:** Jorge-uploaded paper NJAW tapcard PDF (Materials Planning page 1 + Service Line Renewal Company Side page 2), 5/5 evening
**Lead pickup:** post-tonight commits, pre-Phase-2c-form

---

## TL;DR

Phase 2d as shipped tonight (commit `79f8434`) put the Visual Tapcard Preview in the wrong modal with the wrong labels rendered against the wrong data source. Jorge's actual vision, confirmed via paper PDF tonight:

> **Page 1 = Materials Planning form (left) + Visual Tapcard preview (right), side by side. As inspector fills the materials sheet on the left, the company-side tapcard auto-fills on the right.**

Phase 2d-revision moves the Visual Tapcard Preview to inside the **Materials Sheet modal** (Phase 2a's `modal-materials-sheet`, NOT Phase 2b's `#modal-tapcard`), rewrites the SVG layout to mirror the actual NJAW Service Line Renewal Company Side paper layout, and wires autopopulation from `materials_sheets` columns.

---

## What the paper actually looks like

### Page 1 — Materials Planning (already implemented as Phase 2a Materials Sheet UI)

Two-column upper header:

**Left column:**
- ADDRESS (number / street / town)
- NAME (owner)
- SERVICE TYPE (e.g., FULL-MP, KILL, etc.)
- TEST PIT? (Y/N)
- KILL (kill location: e.g., "Kill at Main")

**Right column:**
- DATE
- CONTRACTOR (e.g., MONTANA)
- FOREMAN
- TEMPERATURE (°F)
- SKY CONDITION

**NOTES** (free text)

**Service Materials grid:**

|  | Test Pit / Old Service |  | New Service |  |  |
|---|---|---|---|---|---|
|  | Size | Pipe Material | Size | Pipe Material | Amount |
| **NJAW** | 3/4" | GALVANIZED | 1" | COPPER | 20' |
| **Customer** | 3/4" | GALVANIZED | 1" | COPPER | 40' |

**Test Pit Information:**
- Curb Box Location (e.g., City Strip)
- Curb Box Replaced? (Y/N)
- Number of Excavations

**Measurements:**
- CORP. DEPTH (FT, IN)
- CS DEPTH (FT, IN)
- CS-HOUSE (formatted FT'IN")
- CS-RS (FT'IN")
- CS-LS (FT'IN")
- CS-NEAR CURB (FT, IN)
- CS-FAR CURB (FT, IN)
- CS-CORP (FT, IN)
- CS-MP (size " + side L/R)
- SIZE OF MAIN (in)
- TYPE OF MAIN (e.g., CAST IRON)
- SERVICE SIDE (Short Side / Long Side)

**Restoration:**

| Type | Dimension | Material |
|---|---|---|
| CITY STRIP | 3'x4' | TSG |
| STREET | 4'x6' | ASPHALT |
| SIDEWALK | 4'x4' | CONCRETE |

- MULTI-TENANT HOUSING? (Y/N)
- NUMBER OF UNITS
- PITCHER DELIVERED? (Y/N)

**Downtime:**
- HOURS
- NOTIFIED

### Page 2 — Service Line Renewal Company Side (the visual tapcard target)

This is the layout the SVG needs to mirror. Two-column upper-half with TAP ORDER box on left, LOCATION DATA block on right. Lower-half is split: Materials Installed table on left, large Diagram area on right. Footer spans both columns.

**Top-left: TAP ORDER box**
- SERVICE NUMBER (e.g., 9180635549)
- TASK NO.'S
  - PARENT
  - PRIMARY (e.g., R18-15H1.25-P-0001)
  - SECONDARY
- DATE
- SERVICE: [size] IN. MTR SET [size] IN [material] PIPE
- OLD SERVICE: [size] IN. TAP [size] IN [material] PIPE
- OLD SERVICE INSTALLATION DATE
- ABANDONED [checkbox]
- COMPANY OWNED [checkbox] / REMOVED [checkbox]

**Top-right: LOCATION DATA block (paper says "New Jersey American Water, [MUNICIPALITY]" header)**
- TOP OF [size] IN. [main material] MAIN IS [ft] FT. [in] IN. BELOW SURFACE
- AND [ft] FT. [in] IN. OF CURB ON [street name]
- TAP IS [ft] FT. [in] IN. FROM INTERSECTING CURB MEDIAN LINE ON [direction]
- DISTANCE, TAP TO CURB STOP [ft] FT. [in] IN.
- DISTANCE, CURB TO CURB STOP [ft] FT. [in] IN.
- LOCATION OF CURB BOX [feet] FROM HOUSE
- "in the [Curb Box Location]"
- METER PIT LOCATION [size]" [side] [OF] CURB STOP
- DATA FURNISHED BY [name]

**Mid-left: OWNER block**
- OWNER
- LOCATION (street number + street name)
- LOT / BLOCK
- MUNICIPALITY / TOWN SECTION
- DEVELOPMENT
- CROSS STREET
- (street name in box on right side)

**Mid-left: MATERIALS INSTALLED table**

| QUAN. | SIZE | MATERIAL INSTALLED |
|---|---|---|
| 20' | 1" | 1" COPPER TUBING (TYPE 'L') |
| 1 | 6" | PLASTIC CURB BOX TOP |
| 1 | 6" | PLASTIC CURB BOX BOTTOM |
| 1 | 1"-1" | C × C ORI CURB STOP |
| (blank) | (blank) | COMP. COMP. COUPLING |
| 1 | 1" | COMP. CORPORATION |
| 1 | 20"-30" | PVC METER PIT |
| 1 | 20" | METER PIT FRAME |
| 1 | 20" | METER PIT LID |
| 1 | 1" | METER SETTER |
| 1 | 1" | METER IDLER |
| ... | ... | (additional rows) |
| (blank) | (blank) | SALVAGED MATERIALS |

**Right side: DIAGRAM area (spans mid-to-bottom of page)**

This is the visual map of the service installation. Contains:
- C.L. (center line) markers at top and middle of street
- (H) house symbol with house number ("44") inside
- MAIN (the watermain pipe, with size shown e.g., "34'5"")
- Measurements shown along arrows: CS-HOUSE, CS-RS, CS-LS, CS-CORP
- (CS) curb stop circle
- (MP) meter pit circle, e.g., "22"" notation indicating distance from CS
- Distance labels: 40'0", 4'9", 13'1", 1'0", 37'4"
- P.L. (property line) horizontal dashed line
- B.L. (building line) horizontal dashed line
- Cross street labels along the side margins (e.g., "OAKLAND ROAD", "JEFFERSON AVENUE")
- Main street label at bottom (e.g., "DUNNELL ROAD")
- Compass / north arrow

**Footer (spans both columns)**

Row 1:
- DATE INSTALLED [date] BY [contractor name]
- POSTED TO SERVICE DATABASE BY / STOCK ENTERED BY (clerical, leave blank in v1)
- FAXED/SCANNED BY (clerical, leave blank in v1)
- TIED IN [Y/N] / PLUG LOCK INSTALLED? [Y/N]
- CUSTOMER SERVICE MATERIAL [material] SIZE [size] IN
- COMPLETED DIAGRAM BY [name]
- PURPOSE OF INSTALLATION (e.g., STANDARD RENEWAL)

**Bottom box (Job Notes / Official Use Only — render visually but populate from property + materials_sheet metadata):**
- District ID
- Operating Center (NJ6 from sector decode)
- County (from property)
- Municipality (from property)
- Service Number (mirrors top tap order)
- Premise Number (mirrors)
- Street Name (from property)
- Street Number (from property)
- Service Type (e.g., WATER NJ6)
- Date Completed
- MapCall WorkOrder #
- Lot / Block / Apt/Bldg (from property)
- SAP Notification # / SAP Work Order #
- Job Notes

---

## Field-to-position mapping (autopopulation source)

The following maps **source columns in `materials_sheets`** → **paper tapcard positions**. Where source column is `*_inches` (single integer), display logic must convert back to feet+inches notation for paper-faithful render.

### Source: `materials_sheets` (Phase 2a form)

| `materials_sheets` column | Tapcard position | Display format |
|---|---|---|
| `sheet_date` | DATE (top-left tap order) + DATE INSTALLED (footer) + Date Completed (bottom box) | MM/DD/YYYY |
| `contractor` | DATE INSTALLED ... BY [contractor] (footer) | text |
| `service_type` | Service Type (bottom box) | text |
| `kill_location` | (informational; renders as "Kill: [text]" only if service_type is KILL variant) | text |
| `temp_f` | (NOT on tapcard — materials sheet only) | — |
| `sky_condition` | (NOT on tapcard — materials sheet only) | — |
| `test_pit` (bool) | (NOT on tapcard front — materials sheet only) | — |
| `notes` | Job Notes (bottom box) | text |
| `curb_box_location` | "in the [text]" inside Location Data block | text |
| `curb_box_replaced` | (informational; not on tapcard front, may inform Materials Installed table presence of curb box rows) | — |
| `num_excavations` | (NOT on tapcard front — materials sheet only) | — |
| `existing_mp_noted` (CDM-Smith rule b) | (informational; affects compliance flag, not tapcard render) | — |
| `service_materials.njaw_old_size` | OLD SERVICE: [size] IN. TAP (top-left tap order) | "3/4"" |
| `service_materials.njaw_old_material` | OLD SERVICE: ... [material] PIPE | "GALVANIZED" |
| `service_materials.njaw_new_size` | SERVICE: [size] IN. MTR SET (top-left tap order) | "1"" |
| `service_materials.njaw_new_material` | SERVICE: ... [material] PIPE | "COPPER" |
| `service_materials.njaw_new_amount_ft` | (informational; feeds Materials Installed table line for the copper tubing run) | "20'" |
| `service_materials.cust_new_size` | CUSTOMER SERVICE MATERIAL ... SIZE [size] IN (footer) | "1"" |
| `service_materials.cust_new_material` | CUSTOMER SERVICE MATERIAL [material] (footer) | "COPPER" |
| `corp_depth_inches` | TOP OF MAIN ... [ft] FT. [in] IN. BELOW SURFACE | inches→ft+in |
| `cs_depth_inches` | (informational; informs vertical position of CS in diagram) | inches→ft+in |
| `cs_house_inches` | LOCATION OF CURB BOX [feet] FROM HOUSE + diagram measurement | inches→ft'in" notation (e.g., 480 → "40'0"") |
| `cs_rs_inches` | Diagram right-side measurement | inches→ft'in" |
| `cs_ls_inches` | Diagram left-side measurement | inches→ft'in" |
| `cs_near_curb_inches` | DISTANCE, CURB TO CURB STOP [ft] FT. [in] IN. | inches→ft+in |
| `cs_far_curb_inches` | TAP IS [ft] FT. [in] IN. FROM INTERSECTING CURB MEDIAN LINE | inches→ft+in |
| `cs_corp_inches` | DISTANCE, TAP TO CURB STOP [ft] FT. [in] IN. | inches→ft+in |
| `cs_mp_inches` | METER PIT LOCATION [size]" | inches→raw inches notation (e.g., 22 → "22"") |
| `cs_mp_side` | METER PIT LOCATION ... [LEFT/RIGHT] OF CURB STOP | "RIGHT" or "LEFT" |
| `size_of_main_inches` | TOP OF [size] IN. ... MAIN | inches integer (e.g., 6) |
| `type_of_main` | TOP OF ... [type] MAIN (also "MAIN" label in diagram) | "CAST IRON" |
| `service_side` | Diagram orientation (which side house renders on) | "Short Side" / "Long Side" |
| `multi_tenant_housing` | (informational; not on tapcard front) | — |
| `num_units` | (informational; not on tapcard front) | — |
| `pitcher_delivered` | (informational; not on tapcard front) | — |
| `downtime_hours` | (informational; not on tapcard front) | — |
| `downtime_notified` | (informational; not on tapcard front) | — |

### Source: `properties` (joined at modal load)

| `properties` column | Tapcard position |
|---|---|
| `address_number` | LOCATION (street number) + Street Number (bottom box) |
| `address_street` | LOCATION (street name) + Street Name (bottom box) + cross-reference labels in diagram |
| `municipality` | MUNICIPALITY + Municipality (bottom box) + "New Jersey American Water, [MUNICIPALITY]" header |
| `cross_street` | CROSS STREET + diagram side margin label |
| `lot` | LOT (owner block + bottom box) |
| `block` | BLOCK (owner block + bottom box) |
| `apt_bldg` | Apt/Bldg (bottom box) |
| `owner_name` | OWNER + NAME (page 1 reference) |
| `mapcall_id` | MapCall WorkOrder # (bottom box) — if column exists; otherwise blank |
| `sector` | District ID + Operating Center (bottom box) — decode `NJ6_NORMAL` → "NJ6" |
| `county` | County (bottom box) — if column exists; otherwise from municipality lookup |

### Source: Phase 2b tapcard form (`tc-co-*` IDs) — INSPECTOR INPUT, autopop into tapcard once typed

These are inspector inputs that complete the tapcard — they do NOT come from materials sheet. When inspector opens Tapcard modal (Phase 2b) and types these, the visual tapcard inside the materials_sheets modal does NOT update (different modal, different lifecycle). Phase 2b's tapcard modal can show its OWN smaller read-only summary of the visual tapcard if useful, but the autopop wiring is one-way: materials_sheet form → visual tapcard inside materials_sheets modal.

| `tc-co-*` field | Tapcard position |
|---|---|
| `tc-co-service_number` | SERVICE NUMBER + Service Number + Premise Number (bottom box) |
| `tc-co-task_numbers` | TASK NO.'S Primary (parsed comma-separated for multi-task) |
| `tc-co-date` | DATE (top-left tap order) — overrides `materials_sheets.sheet_date` if both present |
| `tc-co-tied_in` | TIED IN (footer Y/N + details) |
| `tc-co-plug_lock` | PLUG LOCK INSTALLED? (footer) |
| `tc-co-cust_mat` | CUSTOMER SERVICE MATERIAL (footer) — overrides `materials_sheets.service_materials.cust_new_material` if both present |
| `tc-co-size` | (Customer Service Material) SIZE (footer) |
| `tc-co-completed_by` | COMPLETED DIAGRAM BY (footer) |
| `tc-co-date_installed` | DATE INSTALLED (footer) |
| `tc-co-installed_by` | DATE INSTALLED ... BY [text] (footer) — overrides `materials_sheets.contractor` if both present |

### Source: Inspector profile (auth context)

| Source | Tapcard position |
|---|---|
| `auth.users.email` → name lookup | DATA FURNISHED BY (Location Data block) |

### Computed / derived

| Source | Derivation |
|---|---|
| Operating Center | Decode `properties.sector`: `NJ6_NORMAL` → "NJ6", `NJAW_SHORT_HILLS` → "Short Hills NJAW" |
| Service Type (bottom box) | Compose: water utility module → "WATER " + sector code → "WATER NJ6" |
| MapCall WorkOrder # | If `properties.mapcall_id` exists, use; otherwise blank |
| ABANDONED / COMPANY OWNED / REMOVED checkboxes | (Not autopop in v1; render as paper checkboxes, blank in v1, adds via Phase 2b inspector input layer in future) |

---

## Build scope

### Move + remove from prior Phase 2d

1. **Remove the empty `<div id="visual-tapcard-preview-container">` from `#modal-tapcard`** (added tonight in commit `91f2af4` Phase 2c lean scaffold). It's vestigial.
2. **Remove the lifecycle hooks `vtcInitOnOpen()` at `openTapcardModal` and `vtcReset()` at `closeTapcardModal`** (added tonight in commit `79f8434`). They fire against the wrong modal in revision.
3. **Remove the `currentTapcard.property = prop` stash** (added tonight). The visual tapcard will read from `currentMaterialsSheet` context instead.
4. **Keep the `vtcRender()` and helper functions if reusable; otherwise remove and rebuild fresh** — Lead's call. Most of the field-to-position math in `VTC_FIELDS` is rewritten regardless because labels and source data change.

### Build into `modal-materials-sheet`

5. **Embed the Visual Tapcard Preview as a side-pane inside the materials_sheets modal.** Layout:
   - Desktop ≥1024px: 50/50 horizontal split — materials sheet form on left, visual tapcard preview on right.
   - Tablet 768–1023px: 55/45 split (form gets the wider half).
   - Mobile <768px: stacked or sub-tabbed (Form | Preview toggle). Lead's craft.
6. **Render the SVG layout to mirror the NJAW Service Line Renewal Company Side paper** — sections per the breakdown above (Tap Order block, Location Data block, Owner block, Materials Installed table, Diagram area, Footer, Job Notes box).
7. **SVG dimensions:** keep the normalized 0.0–1.0 coordinate system Lead established in tonight's `VTC_FIELDS`. Section anchors (Lead positions to taste, paper proportions are the guide):
   - Tap Order block: top-left ~(0.02–0.40 x, 0.02–0.30 y)
   - Location Data block: top-right ~(0.42–0.98 x, 0.02–0.30 y)
   - Owner block: mid-left ~(0.02–0.40 x, 0.31–0.45 y)
   - Materials Installed table: mid-left ~(0.02–0.40 x, 0.46–0.78 y)
   - Diagram area: mid-right ~(0.42–0.98 x, 0.31–0.85 y)
   - Footer: bottom span ~(0.02–0.98 x, 0.86–0.95 y)
   - Job Notes / Official Use box: bottom span ~(0.02–0.98 x, 0.96–1.0 y) OR rendered as a separate small SVG below the main one
8. **Wire autopop from materials_sheets form input changes:**
   - Listen for `change` and `input` events on materials_sheets form fields
   - 100ms debounce on text inputs (per Q-2d-a/b/c locked tonight — same semantics as before)
   - Immediate update on enums/selects
   - Update only the affected SVG text node, not full re-render
9. **Empty fields render as thin gray underline** (~15–20px wide at the anchor position, same gray-underline empty-state locked Q-2d-c).
10. **Font:** `JetBrains Mono` primary, system mono fallback (Q-2d-a locked).
11. **No print-to-PDF in v1** (Q-2d-b locked, defer to v2).

### Sector dispatch

12. **Visual tapcard renders only for `properties.sector === 'NJ6_NORMAL'`.** ShortHills properties (`NJAW_SHORT_HILLS`) get a placeholder div with text "Visual tapcard unavailable for ShortHills sector — paper format differs." Do NOT attempt to render the NJ6 layout for ShortHills properties; ShortHills has its own paper format (page 3 of the PDF is the customer side; the ShortHills company side format is different from NJ6 normal and is out of scope for v1).

### Phase 2b tapcard modal — tertiary

13. **Phase 2b's `#modal-tapcard` does not get the visual tapcard preview in this revision.** The tapcard modal is the "fill-in-the-rest-and-submit" surface. The visual tapcard lives on the Materials Sheet modal where the bulk of the data input happens. Future revision (Phase 2d-v2 or Phase 2e) can decide whether to also surface a read-only mini-preview inside the tapcard modal — out of scope for tonight.

---

## Acceptance criteria

1. Visual tapcard renders inside the Materials Sheet modal alongside the form, not inside the Tapcard modal.
2. SVG layout mirrors the NJAW Service Line Renewal Company Side paper (Tap Order / Location Data / Owner / Materials Installed / Diagram / Footer / Job Notes box).
3. All paper labels render in paper-faithful vocabulary ("DISTANCE, TAP TO CURB STOP" not "TAP→CS Distance"; "TIED IN" not "Tied In Y/N"; etc.). Reference Page 2 of the Jorge-uploaded PDF for exact label strings.
4. Autopopulation fires on every materials sheet form input change (100ms debounce on text, immediate on enums). Source columns per the field-to-position map above.
5. Empty fields render as thin gray underlines at the anchor positions (paper-form mimic).
6. Sector dispatch: NJ6_NORMAL renders the visual tapcard; NJAW_SHORT_HILLS renders the placeholder text.
7. Layout responds at desktop (50/50), tablet (55/45 form-favoring), mobile (stacked or sub-tabbed).
8. Phase 2b tapcard modal no longer has the empty `visual-tapcard-preview-container` (vestigial cleanup).
9. No regression on existing Materials Sheet form behavior (open / save / autocomplete / history view all behave identically).
10. No regression on existing Tapcard modal behavior (open / submit / save still work; just no visual preview embedded).

---

## Inches-to-feet+inches conversion (utility function spec)

```javascript
function inchesToFtIn(inches, format = 'verbose') {
  if (inches == null) return null;
  const ft = Math.floor(inches / 12);
  const inch = inches % 12;
  if (format === 'verbose') return { ft, in: inch };  // for "X FT. Y IN."
  if (format === 'compact') return `${ft}'${inch}"`;  // for "40'0""
  if (format === 'inches-only') return `${inches}"`;  // for "22""
  return inches;
}
```

Use:
- `format='verbose'` → "DISTANCE, TAP TO CURB STOP 20 FT. 0 IN."
- `format='compact'` → "LOCATION OF CURB BOX 40'0" FROM HOUSE" + diagram measurements
- `format='inches-only'` → "METER PIT LOCATION 22""

---

## Velocity estimate

~2 sessions (~4 hours focused build):

- **Session 1:** Remove vestigial Phase 2d work from `#modal-tapcard`; embed empty container in `modal-materials-sheet`; rewrite VTC_FIELDS map against materials_sheets columns; build SVG layout for the 6 paper sections (Tap Order / Location Data / Owner / Materials Installed / Diagram / Footer + Job Notes).
- **Session 2:** Wire autopop event listeners on materials sheet form inputs; layout responsive breakpoints; sector dispatch; QA pass against the paper PDF for label accuracy + position verification.

If Lead wants to ship Session 1 alone (visual tapcard renders but doesn't yet autopopulate), that's a defensible split — the static SVG will still demonstrate the concept to Jeff next week.

---

## Open questions for Jorge

- **Q-2d-revision-a:** The Diagram area (right side of paper, contains the visual map of CS / MP / house / measurements) is the most graphically complex. Two options:
  - (a) Render the diagram dynamically (positions of CS, MP, house, etc. computed from cs_house, cs_rs, cs_ls, cs_corp measurements). Risk: misplacement looks wrong on the paper-faithful render.
  - (b) Render the diagram as a static placeholder ("Diagram populated from MI-110 Phase 4") in v1; full dynamic diagram lands in MI-110.
  - Buddy lean: (b) — MI-110 Phase 4 (Tapcard Diagram editor) is the home for diagram rendering. Phase 2d-revision should focus on text-field autopop + structural SVG layout, with the diagram area showing a "diagram placeholder" until MI-110 ships. Otherwise we're double-building the diagram surface.
- **Q-2d-revision-b:** The Materials Installed table (mid-left) maps to free-text material entries on the materials sheet. Question: does the table autopopulate with NJAW pipe rows + curb box rows + meter pit rows derived from the materials sheet data, or does it stay as a placeholder until Phase 2c-form Restoration / future tickets capture richer materials data?
  - Buddy lean: Render the table with the materials sheet's NJAW new pipe row (always present if filled) + extrapolate curb box / curb stop / meter pit rows based on `service_type` (e.g., FULL service implies all 11 standard rows; KILL implies fewer). Lead's craft on the extrapolation rules.

---

**For Lead pickup:** ratify (or override) Q-2d-revision-a/b, then build per the field-to-position map above. Brief is grounded in paper PDF + materials_sheets schema + property record schema. No more brief-from-priors.
