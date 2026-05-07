# MI-403 — Help / Field Guides Tab

**Status:** Brief
**Drafted:** 2026-05-05 ~20:10 EDT
**By:** Buddy
**Source-of-truth:** Jorge-uploaded `SRVLINEFITTINGS_DIAGRAM.pdf` (5/5 evening)

---

## TL;DR

Sidebar tab "Field Guides" — visual reference library for inspectors and trainees. v1 ships with the Service Line Fittings reference (10 photo cards: corporations, couplings, curb stops, reducers, spuds — labeled with thread types, sizes, and "currently utilized by" annotations). v2 grows the library: AWWA standards quick-reference, NJAW depth requirements, CDM-Smith rules cheat-sheet, photo recognition guides for whiteboard compliance.

---

## What's in the source PDF

10 pages of annotated field photos covering NJAW-standard fittings:

1. **1" Compression Corporation** — labeled with corporation body, compression nut, MIP threads, tap threads (covered by plastic)
2. **3/4" - 1" [FIP × COMP] Coupling** — 1" compression nut, 1" MIP threads (utilized by 1" comp nut), 1"-3/4" [MIP × FIP] spud nut, 3/4" FIP threads
3. **3/4" - 1" [MIP × COMP] Coupling — VIEW 1** — 1" comp nut, 3/4" MIP threads, 3/4"-1" [MIP × MIP] spud, 1" MIP threads
4. **3/4" - 1" [MIP × COMP] Coupling — VIEW 2** — same fitting, side angle
5. **1" - 1" [COMP × COMP] Curb Stop (NEW STYLE — ORISEAL)** — ball valve, 1" comp nuts, 1" MIP threads
6. **(unlabeled curb stop hand photo)**
7. **3/4" - 3/4" [COMP × COMP] Curb Stop (OLD STYLE)** — 3/4" comp nuts, ball valve, 3/4" MIP threads
8. **Curb Stop comparison** — old style 3/4 vs new style 1" Oriseal, side by side
9. **3/4" - 1" [COMP × COMP] Reducer Coupling** — 3/4" comp nut, 3/4"-1" [MIP × MIP] spud, 1" comp nut
10. **3/4"-1" Reducer vs 1"-1" Coupling comparison** — visual disambiguation

This is exactly the kind of reference an inspector wants to pull up *while in the field* when they're not sure if what they're looking at is a reducer or a straight coupling.

## What MyInspector should do

**Sidebar tab:** "Field Guides" (or "Help" — Lead's nav judgment).

**Tab body — v1 layout:**
- Top bar: search input ("search guides...")
- Filter chips: All / Fittings / Standards / Compliance / Recognition (chips per guide-category)
- Grid view: cards (image thumbnail + title + 1-line description)
- Tap card → modal-guide opens with full-size annotated image + zoom + scrollable annotations

**v1 content (ships with the app):**
- "Service Line Fittings — Visual Reference" (10 pages from the source PDF)
- Each fitting on its own card; tap → full-screen annotated view
- Mobile: pinch-to-zoom on the image; tap labels to expand annotation text

**v2 content (post-MVP):**
- "Whiteboard Compliance — Photo Examples" (when the whiteboard sample photo library is built)
- "NJAW Depth Standards" (text + diagram reference for CS depth ≥36", MP horns ≥2', etc.)
- "CDM-Smith Rules Cheat Sheet" (rules a/b/d/e quick-reference)
- "Sector Identification Guide" (NJ6_NORMAL vs NJAW_SHORT_HILLS visual cues)

## Schema

New table `field_guides`:
- `id` uuid PK
- `slug` text UNIQUE — e.g., `service-line-fittings`, `whiteboard-compliance-photos`
- `title` text — display title
- `category` text CHECK IN ('fittings','standards','compliance','recognition','other')
- `description` text — short blurb for card view
- `created_at`, `updated_at`, `deleted_at`
- `published_at` timestamptz — null = draft, hidden from inspector view
- `display_order` int — for ordering within category

New table `field_guide_pages`:
- `id` uuid PK
- `field_guide_id` uuid FK → field_guides
- `page_number` int — order within guide
- `image_url` text — Supabase storage URL for the annotated image
- `caption` text — page-level caption
- `annotations` jsonb — array of {label_text, color, position_normalized: {x, y}} for clickable label overlays (v2 enhancement; v1 just renders the image as-is)

**RLS:** Read-public to authenticated (reference content). Write super_admin only.

**No firm_id** — global content. Like `parts_catalogs`.

**Storage bucket:** `field-guides` in Supabase storage. RLS: read-public, write super_admin.

## Build sequence

**Session 1 (backend + content seed, ~1 session):**
1. Migration: create `field_guides` + `field_guide_pages` tables + RLS
2. Storage bucket `field-guides` created with read-public-write-super_admin policy
3. Upload the 10 fitting photos from the source PDF to storage
4. Seed `field_guides` with the "Service Line Fittings — Visual Reference" guide entry
5. Seed `field_guide_pages` with 10 page rows linking to the uploaded images

**Session 2 (frontend, ~1 session):**
1. New sidebar tab "Field Guides"
2. Grid card view of guides (filter chips, search)
3. Modal guide view: full-screen image gallery, swipe between pages, pinch-zoom
4. Mobile responsive

**Session 3+ (v2 content, async):**
- Whiteboard examples once Jorge's sample photos land
- Other guides as content authored

## Acceptance criteria

1. Inspector can open "Field Guides" tab and see the Service Line Fittings card
2. Tapping the card opens a gallery view with all 10 fitting photos
3. Photos display correctly on mobile (large enough to read labels)
4. Search returns relevant guides
5. Filter chips filter category correctly
6. RLS verified: super_admin can edit; inspector read-only

## Velocity estimate

~2 sessions. Self-contained, no integration with other modules required.

## Open questions

- **Q-403-a:** Is the "Field Guides" tab inspector-only, or does it also surface for super_admin / supervisor with edit controls? Buddy lean: same tab for everyone, edit controls appear conditionally for super_admin/supervisor (consistent with how dashboard.html role-gates Construction PM controls).
- **Q-403-b:** Image labels — render as static text in the image (current source PDF), or as clickable overlay annotations the inspector can tap to expand? Buddy lean: v1 ships static images (faster), v2 annotates with clickable overlays once the JSON annotation schema is exercised on real content.
- **Q-403-c:** Should the tab include a "Submit a guide / suggest content" button for field inspectors to flag missing guides? Buddy lean: yes, as a v2 feedback loop. Maps the field's actual reference needs.
