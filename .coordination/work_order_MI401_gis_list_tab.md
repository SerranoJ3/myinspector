# Work Order — MI-401 GIS List Tab (Address Checklist)

**Authored:** 2026-05-05 ~21:00 EDT
**By:** Buddy
**For:** Lead — pickup-ready
**Brief reference:** `.coordination/MI401_GIS_LIST_TAB_BRIEF.md`
**Authority:** Buddy has batch trust from Jorge for the duration. Q-answers locked below.

---

## Why this matters

Inspectors carry paper notebooks today copying GIS lists by hand from PDFs released by NJAW. Replace with in-app checklist. Inspector taps checkbox per address as worked. Persists to DB → survives device swap, backs up, gives supervisors live visibility into route progress without nagging. Replaces hand-written "lugging around a bunch of shit" — Jorge's words.

Demo angle: Jeff sees field-ops knowledge baked into the product. Recognizable workflow he already knows from his own LCRI supervision. High signal-to-noise ratio in the pitch.

---

## Locked answers (batch trust)

- **Q-401-a — Status enum scope:** Keep 3-state in v1 — `to_do / in_progress / complete`. Add `field_outcome` column later (post-v1) that hooks into the phase enum for richer reporting (e.g., scheduled / no_access / refused / cs_replaced / m2c_only). Don't bloat the v1 enum.
- **Q-401-b — Auto-create phase_submission?** No. GIS list is the route plan; phase_submissions are actual work logs. Keep them separate. Cross-link via `linked_property_id` for navigation, don't conflate the data models.

---

## Schema

Migration name: `mi401_gis_lists_tables`

```sql
CREATE TABLE gis_lists (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firm_id uuid NOT NULL REFERENCES firms(id),
  name text NOT NULL,
  release_date date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  created_by uuid REFERENCES auth.users(id)
);

ALTER TABLE gis_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE gis_lists FORCE ROW LEVEL SECURITY;

CREATE POLICY gis_lists_read_firm ON gis_lists FOR SELECT TO authenticated
  USING (firm_id = current_firm_id() AND deleted_at IS NULL);

CREATE POLICY gis_lists_write_firm ON gis_lists FOR INSERT TO authenticated
  WITH CHECK (firm_id = current_firm_id());

CREATE POLICY gis_lists_update_firm ON gis_lists FOR UPDATE TO authenticated
  USING (firm_id = current_firm_id())
  WITH CHECK (firm_id = current_firm_id());

CREATE INDEX gis_lists_firm_release ON gis_lists (firm_id, release_date DESC);

CREATE TABLE gis_list_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firm_id uuid NOT NULL REFERENCES firms(id),
  gis_list_id uuid NOT NULL REFERENCES gis_lists(id),
  index_number int,
  address text NOT NULL,
  status text NOT NULL DEFAULT 'to_do' CHECK (status IN ('to_do','in_progress','complete')),
  notes text,
  assigned_to uuid REFERENCES auth.users(id),
  completed_by uuid REFERENCES auth.users(id),
  completed_at timestamptz,
  linked_property_id uuid REFERENCES properties(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE gis_list_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE gis_list_entries FORCE ROW LEVEL SECURITY;

CREATE POLICY gis_list_entries_read_firm ON gis_list_entries FOR SELECT TO authenticated
  USING (firm_id = current_firm_id() AND deleted_at IS NULL);

CREATE POLICY gis_list_entries_write_firm ON gis_list_entries FOR INSERT TO authenticated
  WITH CHECK (firm_id = current_firm_id());

CREATE POLICY gis_list_entries_update_firm ON gis_list_entries FOR UPDATE TO authenticated
  USING (firm_id = current_firm_id())
  WITH CHECK (firm_id = current_firm_id());

CREATE INDEX gis_list_entries_firm_list ON gis_list_entries (firm_id, gis_list_id);
CREATE INDEX gis_list_entries_firm_status ON gis_list_entries (firm_id, status);
CREATE INDEX gis_list_entries_firm_assigned ON gis_list_entries (firm_id, assigned_to);
CREATE INDEX gis_list_entries_property ON gis_list_entries (linked_property_id);
```

Audit triggers: attach existing `audit_log_chain_trigger` pattern to `gis_list_entries` UPDATE — status transitions, notes edits, assignments all chain into audit_log per the locked layer-2 pattern.

---

## Unit 1 — Backend + seed (~45 min)

1. Apply migration `mi401_gis_lists_tables` via Supabase MCP
2. Attach audit triggers to `gis_list_entries` matching the existing audit chain pattern (refer to `audit_phase_submissions_insert` style, table-specific BEFORE INSERT for hash chain + AFTER INSERT/UPDATE for `write_audit_log`)
3. Seed CP Engineers test data:
   - 1 gis_list row: name "GIS List — Released 10 Sept 2025", release_date 2025-09-10
   - 22 sample entries from page 1 of source PDF (Berkeley St + Berkshire Rd + Bowdoin St addresses, INDEX 1-22)
4. Verification: query `gis_list_entries` count = 22, all status='to_do', all firm_id matches CP

Commit Unit 1:

```
feat(MI-401 Unit 1): gis_lists + gis_list_entries tables + RLS + audit + CP seed

- Migration mi401_gis_lists_tables: 2 tables + RLS forced + per-firm policies + audit triggers
- 4 indexes: firm/release, firm/list, firm/status, firm/assigned, property
- Seed CP Engineers: 1 list + 22 sample entries (Berkeley/Berkshire/Bowdoin)
- 3-state enum locked (to_do/in_progress/complete); field_outcome column deferred to post-v1
```

---

## Unit 2 — Frontend tab (~1 session, ~90 min)

1. Sidebar tab "GIS Lists" — between Properties and Submit Phase (Lead's nav judgment if different position serves better)
2. Modal `modal-gis-list`:
   - Top bar: list selector dropdown (release_date sorted, most recent default), "+ New List" button (super_admin / supervisor only), search input, filter chips (All / To-Do / In-Progress / Complete)
   - Table view (desktop): INDEX | ADDRESS | STATUS | NOTES | ASSIGNED | LAST-ACTION columns
   - Card view (mobile): stacked cards, big tappable checkbox, address as headline, notes-edit via tap-to-expand
   - Status toggle: tap checkbox cycles to_do → in_progress → complete → to_do. Update writes to DB, fires audit row.
   - Notes inline-edit with save-on-blur
3. Property auto-link: when entry address fuzzy-matches an existing `properties.address_*` row, set `linked_property_id` and add "View Property" button on the entry row that navigates to Property Detail
4. Bulk import: super_admin / supervisor uploads PDF or CSV/Excel → reuse existing CSV import infrastructure with column-fuzzy-matching for INDEX / ADDRESS / STATUS / NOTES

Commit Unit 2:

```
feat(MI-401 Unit 2): GIS List tab UI + status toggle + bulk import + property auto-link

- Sidebar tab "GIS Lists" with list selector + filters + search
- Desktop table view + mobile card view with status toggle
- Notes inline-edit with save-on-blur
- Property auto-link via address fuzzy-match
- Bulk PDF/CSV import for super_admin (reuses Phase 1 column-matcher)
- Mobile responsive layout
```

---

## Unit 3 — Polish (optional, ~30 min)

1. Address autocomplete on entry edit (reuse existing street autocomplete from Phase 1)
2. Supervisor view: aggregate stats per list (% complete, time-to-complete avg, inspector breakdown)
3. Export to CSV button for completed lists (audit trail export)

Commit Unit 3 if shipped:

```
feat(MI-401 Unit 3): polish — autocomplete + supervisor stats + CSV export
```

---

## Acceptance criteria

1. Inspector opens "GIS Lists" tab → sees list selector populated, default selection is most recent release
2. Tap status checkbox → status cycles correctly, DB updates, audit row fires
3. Tap address → if linked, navigates to Property Detail; if not linked, shows fuzzy-match candidates
4. Notes edit → save-on-blur persists
5. Super_admin uploads new PDF → entries parse correctly, list created, rows visible
6. Supervisor view shows aggregate stats correctly (Unit 3, optional)
7. RLS verified: inspector A (firm A) cannot see firm B's GIS lists
8. Mobile layout usable in field conditions (large tap targets, no hover-only UI)
9. Audit log captures every status change with inspector + timestamp

---

## Closing actions

- Push demo-banner to origin
- Update STATE.md: MI-401 closed
- Update status.md: GIS List Tab in recently-shipped
- Append decisions.md entry: 3-state enum locked, no auto-create phase_submission, audit chain on UPDATE
- Final session-close commit

---

## Stop conditions

- Migration fails (likely a DDL conflict, not a scope question — fix and retry)
- Audit trigger creation fails (chain integrity breach risk — stop and ping Buddy)
- BUDDY_STANDARD locked principle conflict

## Do NOT stop for

- PDF parser ambiguity on column extraction (use fuzzy match, document failures in commit)
- Mobile breakpoint judgment (Lead's UI craft)
- Address fuzzy-match threshold (Lead's call, document choice)
- Aggregate stats algorithm choice (Lead's analytics craft)

## End-of-run report

- 2-3 commit hashes + final close commit
- STATE / status / decisions deltas
- Open items (e.g., supervisor stats query optimization, address fuzzy-match accuracy)

Velocity: ~3 sessions total. Unit 1 + Unit 2 ships v1; Unit 3 is polish. Go.
