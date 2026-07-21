# Work Order — MI-403 Field Guides Tab (Help / Reference Library)

**Authored:** 2026-05-05 ~21:20 EDT
**By:** Buddy
**For:** Lead — pickup-ready
**Brief reference:** `.coordination/MI403_FIELD_GUIDES_TAB_BRIEF.md`
**Authority:** Buddy has batch trust from Jorge for the duration. Q-answers locked below.

---

## Why this matters

Inspectors need a visual reference library accessible mid-job. Source data Jorge uploaded: 10 annotated photos of NJAW-standard fittings (corporations, couplings, curb stops, reducers, spuds) labeled with thread types, sizes, and "currently utilized by" annotations. This is the kind of reference an inspector wants to pull up *while in the field* when they're not sure if what they're looking at is a reducer or a straight coupling.

v1 ships with the Service Line Fittings reference. v2 grows the library: AWWA standards, NJAW depth requirements, CDM-Smith rules cheat-sheet, photo recognition guides for whiteboard compliance.

Demo angle: depth-of-product. Shows MyInspector isn't just a data-entry app — it's a field-ops platform with reference content baked in.

---

## Locked answers (batch trust)

- **Q-403-a — Tab visibility:** All authenticated users in firm see "Field Guides" tab. Edit controls (upload new guide, manage existing) appear conditionally for super_admin only.
- **Q-403-b — Image labels:** v1 ships static images (faster). Annotations live as text in the source PDF labels — no clickable overlay system in v1. v2 layers in JSON annotation overlays once the schema is exercised on real content.
- **Q-403-c — User-suggested content:** Yes, "Suggest a guide" button in v1, but it just opens an email/feedback form — doesn't create a draft entry. v2 builds a real submission queue.

---

## Schema

Migration name: `mi403_field_guides_tables`

```sql
CREATE TABLE field_guides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text UNIQUE NOT NULL,
  title text NOT NULL,
  category text CHECK (category IN ('fittings','standards','compliance','recognition','other')),
  description text,
  display_order int DEFAULT 100,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE field_guides ENABLE ROW LEVEL SECURITY;
ALTER TABLE field_guides FORCE ROW LEVEL SECURITY;

CREATE POLICY field_guides_read_published ON field_guides FOR SELECT TO authenticated
  USING (published_at IS NOT NULL AND deleted_at IS NULL);

CREATE POLICY field_guides_write_super ON field_guides FOR ALL TO authenticated
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

CREATE INDEX field_guides_category ON field_guides (category, display_order) WHERE published_at IS NOT NULL;

CREATE TABLE field_guide_pages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  field_guide_id uuid NOT NULL REFERENCES field_guides(id) ON DELETE CASCADE,
  page_number int NOT NULL,
  image_url text NOT NULL,
  caption text,
  annotations jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (field_guide_id, page_number)
);

ALTER TABLE field_guide_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE field_guide_pages FORCE ROW LEVEL SECURITY;

CREATE POLICY field_guide_pages_read ON field_guide_pages FOR SELECT TO authenticated USING (true);

CREATE POLICY field_guide_pages_write_super ON field_guide_pages FOR ALL TO authenticated
  USING (current_user_role() = 'super_admin')
  WITH CHECK (current_user_role() = 'super_admin');

CREATE INDEX field_guide_pages_guide ON field_guide_pages (field_guide_id, page_number);
```

**No firm_id** — global reference content, same pattern as `parts_catalogs`.

Storage bucket: `field-guides`. RLS: read-public to authenticated, write super_admin only. Path convention: `{slug}/{page-number}.{ext}`.

---

## Unit 1 — Backend + content seed (~1 session, ~75 min)

1. Apply migration `mi403_field_guides_tables` via Supabase MCP

2. Create storage bucket `field-guides` with read-public-write-super_admin policy

3. Extract the 10 fitting images from `SRVLINEFITTINGS_DIAGRAM.pdf`. Lead's craft on extraction — pdf.js + canvas, or `pdftoppm` if available, or manual extraction. Store at:
   - `field-guides/service-line-fittings/01-1in-compression-corporation.jpg`
   - `field-guides/service-line-fittings/02-3-4-1-fip-comp-coupling.jpg`
   - `field-guides/service-line-fittings/03-3-4-1-mip-comp-coupling-view-1.jpg`
   - `field-guides/service-line-fittings/04-3-4-1-mip-comp-coupling-view-2.jpg`
   - `field-guides/service-line-fittings/05-1-1-comp-comp-curb-stop-new-style.jpg`
   - `field-guides/service-line-fittings/06-curb-stop-photo-unlabeled.jpg`
   - `field-guides/service-line-fittings/07-3-4-3-4-comp-comp-curb-stop-old-style.jpg`
   - `field-guides/service-line-fittings/08-curb-stop-comparison.jpg`
   - `field-guides/service-line-fittings/09-3-4-1-comp-comp-reducer-coupling.jpg`
   - `field-guides/service-line-fittings/10-reducer-vs-coupling-comparison.jpg`

4. Seed `field_guides` with the Service Line Fittings guide:

```sql
INSERT INTO field_guides (slug, title, category, description, display_order, published_at) VALUES
  ('service-line-fittings', 'Service Line Fittings — Visual Reference',
   'fittings', 'Annotated photos of NJAW-standard fittings: corporations, couplings, curb stops, reducers, spuds. Visual ID guide for field inspectors and trainees.',
   10, now());
```

5. Seed `field_guide_pages` with 10 page rows linking to the uploaded images, captions per source PDF labels:

```sql
WITH guide AS (SELECT id FROM field_guides WHERE slug = 'service-line-fittings')
INSERT INTO field_guide_pages (field_guide_id, page_number, image_url, caption) VALUES
  ((SELECT id FROM guide), 1, '...', '1" Compression Corporation — corporation body, comp nut, MIP threads, tap threads (covered by plastic)'),
  ((SELECT id FROM guide), 2, '...', '3/4" - 1" [FIP × COMP] Coupling — 1" comp nut, 1" MIP threads, 1"-3/4" [MIP × FIP] spud nut, 3/4" FIP threads'),
  ((SELECT id FROM guide), 3, '...', '3/4" - 1" [MIP × COMP] Coupling — VIEW 1 — 1" comp nut, 3/4" MIP threads, 3/4"-1" [MIP × MIP] spud, 1" MIP threads'),
  ((SELECT id FROM guide), 4, '...', '3/4" - 1" [MIP × COMP] Coupling — VIEW 2 — same fitting, side angle'),
  ((SELECT id FROM guide), 5, '...', '1" - 1" [COMP × COMP] Curb Stop (NEW STYLE — ORISEAL) — ball valve, 1" comp nuts, 1" MIP threads'),
  ((SELECT id FROM guide), 6, '...', 'Curb stop unlabeled photo — context view'),
  ((SELECT id FROM guide), 7, '...', '3/4" - 3/4" [COMP × COMP] Curb Stop (OLD STYLE) — 3/4" comp nuts, ball valve, 3/4" MIP threads'),
  ((SELECT id FROM guide), 8, '...', 'Curb Stop comparison: old style 3/4" vs new style 1" Oriseal, side by side'),
  ((SELECT id FROM guide), 9, '...', '3/4" - 1" [COMP × COMP] Reducer Coupling — 3/4" comp nut, 3/4"-1" [MIP × MIP] spud, 1" comp nut'),
  ((SELECT id FROM guide), 10, '...', '3/4"-1" Reducer vs 1"-1" Coupling comparison — visual disambiguation');
```

(Replace `'...'` with actual storage URLs after upload.)

Commit Unit 1:

```
feat(MI-403 Unit 1): field_guides tables + storage bucket + Service Line Fittings seed

- Migration mi403_field_guides_tables: 2 tables + RLS + indexes
- Storage bucket field-guides with read-public-write-super_admin policy
- 10 fitting photos extracted from SRVLINEFITTINGS_DIAGRAM.pdf and uploaded
- Service Line Fittings guide seeded with 10 pages + captions
```

---

## Unit 2 — Frontend tab (~1 session, ~75 min)

1. Add sidebar tab "Field Guides" (position toward end of nav, low-priority but always visible)
2. Tab body layout:
   - Top bar: search input + filter chips (All / Fittings / Standards / Compliance / Recognition / Other)
   - Grid view: cards (image thumbnail + title + 1-line description), 3 cols desktop, 2 cols tablet, 1 col mobile
   - "Suggest a Guide" button → opens mailto: link to `jorge@serranogroup.org` with subject "Field Guide Suggestion" (Q-403-c v1 implementation)
3. Tap card → modal-guide opens:
   - Full-screen image gallery
   - Swipe / arrow-key navigation between pages
   - Pinch-zoom on mobile, click-to-zoom on desktop
   - Caption text below image
   - Page indicator (e.g., "3 / 10")
4. Super_admin only: "Manage Guides" button (deferred — v2 implementation, no functionality in v1, just hidden behind role gate)
5. Mobile responsive: large tap targets, single-column card layout, fullscreen gallery on mobile

Commit Unit 2:

```
feat(MI-403 Unit 2): Field Guides tab UI + gallery modal + search/filter

- Sidebar tab "Field Guides" with grid card view
- Search input + category filter chips
- Gallery modal: swipe nav, pinch-zoom, page indicator
- "Suggest a Guide" mailto button (v1)
- Mobile responsive layout
```

---

## Acceptance criteria

1. Inspector opens "Field Guides" tab → sees Service Line Fittings card in grid
2. Tap card → gallery opens at page 1, can swipe/arrow through all 10 pages
3. Each page shows the fitting photo + caption text
4. Search returns results matching title/description
5. Category filter chips filter correctly
6. "Suggest a Guide" opens email client with pre-filled subject
7. Mobile layout: gallery is fullscreen, pinch-zoom works
8. RLS verified: super_admin can edit (when v2 ships); inspectors are read-only
9. Only `published_at IS NOT NULL` guides are visible to non-super_admin users (draft system works)

---

## Closing actions

- Push demo-banner to origin
- Update STATE.md: MI-403 closed
- Update status.md: Field Guides Tab in recently-shipped
- Append decisions.md entry: static images v1 / annotations v2 split, "Suggest a Guide" mailto v1
- Final session-close commit

---

## Stop conditions

- Image extraction from PDF fails (try alternate methods — manual export ok if automated extraction is finicky)
- Storage bucket creation fails (Supabase MCP issue)
- BUDDY_STANDARD locked principle conflict

## Do NOT stop for

- Image extraction method choice (Lead's craft — pdftoppm, pdf.js, manual, all acceptable)
- Gallery library choice (browser-native, swiper.js, custom — Lead's craft)
- Mobile breakpoint judgment
- Email-client mailto compatibility (v1 best-effort, v2 in-app form)

## End-of-run report

- 2 commit hashes + final close commit
- STATE / status / decisions deltas
- Open items: when v2 should ship (annotation overlays, in-app suggestion submissions)

Velocity: ~2 sessions total. Self-contained, no integration with other modules. Go.
