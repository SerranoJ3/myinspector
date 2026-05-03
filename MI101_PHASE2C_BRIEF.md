# MI-101 PHASE 2C — ShortHills sector + Restoration Card frontend brief

**Status:** Drafted by Buddy 2026-05-03 PM. Awaiting Jorge ratification before Lead picks up.
**Estimated:** ~5 sessions (Lead's call after read).
**Gating:** Q-7 (autosave cadence) must be answered before this builds — applies to Materials Sheet inside Restoration Card's substructure.
**Branch:** `mi101-phase2c` off main after current main settles (Track 2 demo branch is non-conflicting).

---

## What this ships

Two frontier surfaces inside the existing MI-101 Phase 2 UI that close a real CP geographic + workflow gap:

1. **ShortHills sector workflow** — role-inverted inspector ↔ contractor flow with locked triangulation anchor rule.
2. **Restoration Card frontend** — open-excavation rainy-day documentation, backed by the existing `restoration_grid_entries` table.

Both use the same Property Detail modal that Phase 2a + 2b already established.

---

## Locked product principles this honors

(All from `CLAUDE.md` — re-stated here to prevent drift during build.)

1. **Inspectors do NOT do extra work for the app.** Both surfaces hide work behind a sector-aware default; UI fields appear/disappear based on sector, not inspector toggle.
2. **CS is the anchor.** Triangulation always reads MP/asset position relative to CS. Inverting roles in ShortHills does NOT invert this geometric rule.
3. **Whiteboard required only when open excavation exists.** Restoration Card surfaces during rainy-day work AND only when an excavation is open (curbstop area, watermain area, restoration).
4. **Audit chain immutable.** Every Restoration Card save = 1 audit_log row. Compound CHECK constraints (per the no_work pattern from MI-108) enforce required fields at the database layer.

---

## Scope by surface

### Surface 1 — ShortHills sector workflow (role inversion)

**Trigger:** sector field on the property = `NJAW_SHORT_HILLS` (verified enum value via prod schema check 2026-05-03 PM — CHECK constraint enforces `NJ6_NORMAL` or `NJAW_SHORT_HILLS` on `properties.sector`, `restoration_grid_entries.sector`, and `parts_catalogs.sector`). **Note:** zero ShortHills properties exist on prod as of this brief — import gate must clear before this surface is testable end-to-end.

**UI changes from default (Maplewood) flow:**

| Aspect | Maplewood / `NJ6_NORMAL` | ShortHills / `NJAW_SHORT_HILLS` |
|---|---|---|
| Inspector ↔ contractor relationship | Contractor leads means/methods, inspector verifies | **Inspector dictates means/methods**, contractor executes |
| Inspector ↔ homeowner relationship | Contractor or utility liaison primary | **Inspector talks directly to homeowner** |
| Means/methods field | Read-only (contractor input) | **Inspector-editable text field**, required on submit |
| Homeowner contact log | Hidden | **Visible**, append-only, 1 row = 1 inspector contact event |
| Triangulation anchor | CS | **CS (unchanged)** — geometric rule is invariant |
| MP description fields | Pre-populated from contractor input | **Inspector-editable**, anchored relative to CS |

**New UI surfaces inside Property Detail modal (ShortHills mode only):**

1. **Means/Methods textbox** — appears in the work_order phase form and the service_work phase form. Required on submit. 50–500 chars, soft-wrapped, plain text.
2. **Homeowner Contact log** — append-only list of (timestamp, contact_method, summary) entries. Methods enum: `in_person`, `phone`, `email`, `door_hanger`, `note_left`. Summary: 20–500 chars. Each new entry = 1 audit_log row.
3. **Inspector means/methods banner** — top-of-modal banner reading "ShortHills sector: you direct means and methods. Contractor executes." in CDM-Smith yellow. Locked, not dismissible.

**No new tables required for Means/Methods** — persists into:
- New column `phase_submissions.inspector_means_methods text` (CHECK length ≥ 50 when joined property's sector = 'NJAW_SHORT_HILLS' AND phase IN ('work_order', 'service_work'))

**Homeowner Contact log requires one new table:**
- `homeowner_contact_log` (firm_id uuid, property_id uuid, profile_id uuid, contacted_at timestamptz, method text, summary text, created_at timestamptz, deleted_at timestamptz). RLS forced + ≥1 firm-scoped policy. firm_id indexed (partial WHERE deleted_at IS NULL). Audit trigger via record_compliance_event.

**Migration: `mi101_phase2c_short_hills.sql`** — adds 1 column to phase_submissions + 1 new table + CHECK + trigger + 2 policies + 1 index. Tagged dollar-quote SQL per Buddy Standard.

**Build-time gate (locked):** Means/Methods CHECK references `properties.sector` via JOIN, which means the CHECK lives in either:
  (a) a BEFORE INSERT/UPDATE trigger that joins to properties (preferred — keeps the CHECK in the database layer), OR
  (b) application-layer validation only (fallback if trigger has perf cost). Lead picks at build time and surfaces decision in `decisions.md`.

### Surface 2 — Restoration Card frontend

**Trigger:** any of these conditions per the locked whiteboard rule:
- Phase = `restoration` AND open excavation exists
- Phase = `service_work` AND restoration sub-step active AND rainy-day=true
- Supervisor override forced via `whiteboard_override_log` row

**Backend status:** `restoration_grid_entries` table EXISTS on prod, RLS forced, firm_id indexed (partial WHERE deleted_at IS NULL). Verified 2026-05-03 PM. **No new tables required for v1 of this surface.** Verify shape:

```sql
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'restoration_grid_entries'
ORDER BY ordinal_position;
```

**UI:** Restoration Card opens from Property Detail modal as a tab (third tab, alongside Materials Sheet and Tapcard). Layout:
- Header: "Restoration — [property address]"
- Required-fields strip (locked):
  - Excavation type (enum: `curbstop`, `watermain`, `restoration_rainy_day`, `other`)
  - Excavation open since (timestamptz, defaults to now())
  - Surface to restore (enum: `asphalt`, `concrete`, `gravel`, `lawn`, `mixed`)
  - Square footage (numeric, required)
  - Photo: pre-restoration (required)
  - Photo: post-restoration (optional, surfaces only after restoration completed=true)
- Optional grid: a configurable grid of restoration entries (already-shipped backend handles this).
- Save button: "Save Restoration Card." Same UI placement as Materials Sheet save.

**Whiteboard requirement:** when Restoration Card is opened, the photo capture flow MUST include a whiteboard photo per the locked whiteboard rule. Reuse existing `detect-whiteboard` Edge Function (Claude Vision). Existing whiteboard override path (supervisor-only) remains available; no changes there.

**No new tables required** — `restoration_grid_entries` covers v1. If grid functionality needs expansion in v2, that's a separate ticket.

---

## Acceptance criteria (5 items, all must pass before PR opens)

1. **Sector dispatch works.** Setting a project's sector = `short_hills` shows the new UI surfaces; setting it back to `maplewood` (or default) hides them. Verified manually + in seed data + via Lead's e2e SQL test.
2. **Means/Methods CHECK fires.** Attempting to submit a work_order or service_work phase under sector=short_hills with means_methods length < 50 raises a CHECK violation. Test SQL inserted under BEGIN/ROLLBACK.
3. **Homeowner contact log audits cleanly.** Inserting 3 contacts produces exactly 3 audit_log rows with correct prev_hash chain. Test via Supabase MCP.
4. **Restoration Card persists.** Opening, filling required fields, saving → row in `phase_submissions` (phase='restoration') with photo URLs populated AND associated `restoration_grid_entries` row(s).
5. **Whiteboard requirement enforced when excavation open.** Saving a Restoration Card without `photo_no_work_whiteboard_url` populated AND `photo_no_work_whiteboard_detected=true` fails with a clear error message. Override path via supervisor still works.

---

## What this brief deliberately does NOT include

- **AR auto-fill on tapcard.** Parked as `BB-001` per `.coordination/back_burner.md`. Trigger to un-park is first paying non-CP customer, not Phase 2c.
- **Diagram editor (SVG drawing).** That's MI-110 Phase 4 — separate brief, separate ~6 sessions, separate PR.
- **Construction PM frontend (contractor arrival/departure).** That's MI-302 — separate brief.
- **Grid expansion in Restoration Card.** v1 uses the existing `restoration_grid_entries` shape as-is. Grid configuration features defer to v2.
- **Real-time sync between inspector + supervisor on means/methods edits.** Multi-user real-time is parked until first paying non-CP customer requires it. v1 uses last-write-wins with audit trail.

---

## Q-7 dependency (locked)

Phase 2c **requires Q-7 to be answered before the Restoration Card form ships**. The autosave cadence affects how the Restoration Card's required fields persist between modal Close and explicit Save.

If Q-7 = A or B (autosave on), the form persists transparently.
If Q-7 = C (Save Draft button), the form needs a third button.
If Q-7 = D (no autosave), the form holds in-memory until explicit Save with a "you have unsaved changes" warning on Close.

Lead: do not start the Restoration Card form until Q-7 has a `**Resolved:**` line.

ShortHills surfaces (Means/Methods textbox, Homeowner contact log) can build in parallel — they don't depend on Q-7 because they don't have draft states.

---

## Verification queries Lead should run (post-merge)

After PR merges to main and Vercel preview verifies the UI:

```sql
-- 1. Sector dispatch query: count submissions under each sector
SELECT sector, count(*)
FROM phase_submissions
WHERE deleted_at IS NULL
GROUP BY sector
ORDER BY sector;

-- 2. ShortHills means/methods CHECK active
SELECT con.conname, pg_get_constraintdef(con.oid)
FROM pg_constraint con
JOIN pg_class rel ON rel.oid = con.conrelid
WHERE rel.relname = 'phase_submissions'
  AND con.conname = 'phase_submissions_short_hills_means_methods_required';

-- 3. homeowner_contact_log RLS state
SELECT
  c.relname,
  c.relrowsecurity AS rls_enabled,
  c.relforcerowsecurity AS rls_forced,
  (SELECT count(*) FROM pg_policies WHERE tablename = c.relname) AS policy_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname = 'homeowner_contact_log';

-- 4. First Restoration Card real submission shape-check
SELECT
  ps.id,
  ps.phase,
  ps.photo_house_url IS NOT NULL AS has_house_photo,
  ps.photo_no_work_whiteboard_url IS NOT NULL AS has_whiteboard,
  ps.photo_no_work_whiteboard_detected,
  count(rge.id) AS restoration_grid_entry_count
FROM phase_submissions ps
LEFT JOIN restoration_grid_entries rge ON rge.phase_submission_id = ps.id
WHERE ps.phase = 'restoration'
  AND ps.deleted_at IS NULL
ORDER BY ps.submitted_at DESC
LIMIT 5;
```

Expected pattern: every restoration row has `has_whiteboard = true` AND `photo_no_work_whiteboard_detected = true` (unless supervisor override row exists in `whiteboard_override_log`).

---

## Open questions to surface before Lead starts

- **Q-2c-a (RESOLVED):** ~~Is `sector` already an enforced enum on `phase_submissions`, or just a free-text column?~~ Answered 2026-05-03 PM via prod schema check: sector lives on `properties` (NOT phase_submissions), enforced via CHECK with values `NJ6_NORMAL` or `NJAW_SHORT_HILLS`. Same CHECK shape on `restoration_grid_entries` and `parts_catalogs`. Sector is property-scoped — every submission for the same property has the same sector. ShortHills banner triggers off the joined `properties.sector` when the Property Detail modal opens.
- **Q-2c-b (RESOLVED):** ~~Is there a `projects.sector` column~~? No — `projects.sector` does not exist; sector is on `properties` only. UI dispatch logic reads `properties.sector` at modal load time, NOT at phase-submission save time.
- **Q-2c-c:** Should homeowner_contact_log entries be visible to other inspectors in the same firm, or scoped to the originating inspector? **Buddy default: firm-visible.** Audit trail for the firm matters more than per-inspector privacy on customer interactions, AND firm-visibility supports the supervisor dashboard pattern already shipped. Jorge can override.
- **Q-2c-d (NEW):** No ShortHills properties exist on prod (verified 2026-05-03 PM — `SELECT DISTINCT sector FROM properties` returns only `NJ6_NORMAL`). Phase 2c can build, but end-to-end testing requires Jorge to either (a) import real ShortHills property data, or (b) seed at least 3 demo ShortHills properties for testing. Lead surfaces a 1-row INSERT script if path (b) is chosen.
- **Q-2c-e (NEW):** No ShortHills parts catalog rows exist on prod (16 `NJ6_NORMAL` rows only). Restoration Card flows that read parts catalogs in ShortHills mode will return empty. This must be addressed before ShortHills Restoration Card ships — either Jorge provides ShortHills parts data OR Lead seeds placeholders matching the NJ6_NORMAL set. Decision should land in `decisions.md`.

Lead surfaces unresolved Q-2c-c/d/e to Buddy/Jorge via `questions.md` if not resolved by reading the codebase first.

---

## Sequencing note

Lead is currently on Track 2 (sanitized demo branch). Phase 2c starts AFTER Track 2 PR merges OR runs in parallel as `mi101-phase2c` branch off main. No conflict expected — different surfaces.

If Lead wants to interleave: ShortHills surfaces first (~3 sessions), then Restoration Card after Q-7 lands (~2 sessions). That sequencing front-loads the highest-confidence work.
