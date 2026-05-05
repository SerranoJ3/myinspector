# Phase 2b Tapcard Form — Field Reference

**Generated:** 2026-05-05 ~19:15 EDT
**By:** Buddy (post-Phase-2d-brief audit)
**Purpose:** Ground-truth field inventory for the Phase 2b tapcard form on `mi101-phase2b-refactor` (now in `main`). Buddy/Lead reference for any work that mirrors, exports, or otherwise depends on the actual fields shipped — most immediately for MI-101 Phase 2d (Visual Tapcard Preview).
**Why this exists:** The `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md` was drafted from NJAW workflow vocabulary (CS depth, MP horn copper, etc.) without first reading the actual Phase 2b form. Lead caught it during stop-and-ping on Phase 2d build kickoff. Lesson banked: any brief that mirrors existing UI state requires a ground-truth read of the source first.

---

## Source

`index.html`, lines ~1119–1300. `#modal-tapcard` body. Three pages driven by `tcSwitchPage()`:
- `tc-page-materials` (read-only summaries)
- `tc-page-company` (Company Side data entry — bulk of the form)
- `tc-page-customer` (Customer Side data entry)

---

## Materials page (`tc-page-materials`) — read-only summaries

| Container ID | Source | Notes |
|---|---|---|
| `tc-materials-summary` | Materials Sheet (Phase 2a) | Auto-populates from associated Materials Sheet |
| `tc-property-summary` | Property record | Auto-populates from property context |

No editable fields on this page. The visual tapcard preview can mirror these as header context but they are derived state, not inspector input.

---

## Company Side page (`tc-page-company`) — primary entry

| Field ID | Label | Type | Placeholder / format |
|---|---|---|---|
| `tc-co-service_number` | Service Number | text | `SVC-#####` |
| `tc-co-task_numbers` | Task Numbers | text | comma-separated OK |
| `tc-co-date` | Date | date | — |
| `tc-co-tied_in` | Tied In | text | `Y / N / details` |
| `tc-co-plug_lock` | Plug Lock | text | — |
| `tc-co-cust_mat` | Cust. Mat. | text | `Copper / Lead / ...` |
| `tc-co-size` | Size | number (step 0.25, min 0) | `0.75` |
| `tc-co-completed_by` | Completed Diagram By | text | `Name` |
| `tc-co-date_installed` | Date Installed | date | — |
| `tc-co-installed_by` | By | text | `Crew lead / inspector` |

**Dynamic blocks (Phase 2b populates these via JS):**
- `tc-co-service-rows` — service line entries
- `tc-co-owner-block` — owner display block
- `tc-co-location-block` — location display block
- `tc-mi-table` / `tc-mi-tbody` — materials line items table

---

## Customer Side page (`tc-page-customer`) — secondary entry

| Field ID | Label | Type | Placeholder / format |
|---|---|---|---|
| `tc-cu-service_number` | Service Number (auto from Company Side) | text | readonly |
| `tc-cu-date` | Date | date | — |
| `tc-cu-owner` | Owner (auto from property) | text | readonly |
| `tc-cu-material_at_meter` | Material at meter | text | `Copper / Lead / ...` |
| `tc-cu-distance_to_meter` | Distance to meter (ft) | number (step 0.5, min 0) | `ft` |
| `tc-cu-notes` | Notes | textarea (3 rows, vertical resize) | "Anything customer-side specific..." |
| `tc-cu-company_service_material` | Company Service Material | text | `Copper / Lead / ...` |
| `tc-cu-size` | Size (in) | number (step 0.25, min 0) | `0.75` |

---

## Total editable fields: 18

10 Company Side + 8 Customer Side = 18 inspector-editable fields. Two of those are `readonly` mirrors (cu-service_number from Company, cu-owner from property).

**Effective inspector input fields: 16.**

---

## What the original Phase 2d brief assumed (incorrectly)

The brief listed 14 fields — `cs_depth_in`, `cs_to_main_ft`, `cs_to_house_ft`, `mp_horn_copper`, `pipe_size`, `material_street`, `material_house`, `work_order_code`, `njaw_work_order_code`, `address`, `parcel_id`, `inspector`, `date`, `notes`. **Of those, only `notes` (→ `tc-cu-notes`) and `date` (→ `tc-co-date`) have direct equivalents.** The CS measurements (depth, distances, MP horn copper) are not on Phase 2b's tapcard front — those belong to MI-110 Phase 4 (the diagram editor on the *back* of the tapcard).

The Phase 2b form is structured around **service installation + material identification**, not **triangulation measurements**. Different surface, different vocabulary.

---

## Implication for Phase 2d Visual Tapcard Preview

The visual tapcard renders should mirror the 16 effective inspector-input fields above (plus the 2 readonly mirrors for completeness). The brief's normalized 0.0–1.0 SVG layout regions still apply; the field-to-position map needs to be rewritten against this ground-truth list during Phase 2d build (Lead is doing this per option (a) — "render only fields that DO exist in Phase 2b").

Suggested visual tapcard region mapping (Buddy proposal, Lead overrides as needed):

| SVG region (y-axis 0.0–1.0) | Fields to render |
|---|---|
| Header band (0.02–0.10) | Service Number, Task Numbers, Date |
| Service identity row (0.11–0.20) | Tied In, Plug Lock |
| Materials block (0.21–0.45) | Cust. Mat., Size (Company), Material at meter, Size (Customer), Company Service Material |
| Distance row (0.46–0.55) | Distance to meter |
| Install row (0.56–0.68) | Date Installed, Completed Diagram By, By |
| Notes block (0.69–0.85) | Notes |
| Footer (0.86–0.98) | Whiteboard indicator (existing photo state), signature placeholder, submitted-at |

Owner and address render as small contextual headers via `tc-cu-owner` and the property record (auto-populated, not part of the form input proper).

---

**Banked discipline:** before drafting any frontend brief that mirrors existing UI state, Buddy reads the actual existing UI first. Same lesson as the SUNDAY_5-3-26 file misses earlier today and the demo HTML JSX bug — pattern-matching from priors instead of reading source.
