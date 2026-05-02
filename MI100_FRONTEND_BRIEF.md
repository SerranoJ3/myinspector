# MI-100 Frontend Brief — for Lead

**Ticket:** MI-100 (Sector toggle: NJ6_NORMAL / NJAW_SHORT_HILLS)
**Source spec:** Chat `4261836e` (Apr 30, "Making money with AI in 2026") §3 — Tapcard cluster refined spec
**Backend status:** ✅ DONE — column + CHECK constraint applied via Supabase MCP 2026-05-02 mid-afternoon
**Frontend status:** awaiting Lead
**Velocity estimate:** ~1 session at benchmark (was budgeted 3 in original spec — MCP velocity has compressed schema work)

---

## What landed (backend, for context)

**`properties` schema change:**

| Column | Type | Notes |
|---|---|---|
| `sector` | text NOT NULL DEFAULT 'NJ6_NORMAL' | added by `mi100_sector_toggle` migration |

**Constraint** `properties_sector_enum`:
```
CHECK (sector = ANY (ARRAY['NJ6_NORMAL', 'NJAW_SHORT_HILLS']))
```

**Backfill:** all 39 existing properties auto-defaulted to `NJ6_NORMAL` via the column DEFAULT. Any Millburn / Short Hills properties already in the system need to be manually flipped to `NJAW_SHORT_HILLS` post-frontend ship — that's a one-time data correction, not a migration concern.

**`phase_submissions.tapcard_data` jsonb** already exists from prior 4/29 migration — that's where MI-101's field-level tapcard data will land. Not in scope for MI-100; just noting it's there.

---

## What needs to be built (your work)

### 1. Property creation flow (`index.html`)

Add a sector toggle field to the new-property form. Two options:
- `NJ6_NORMAL` (default, pre-selected) — bulk of CP Engineers Essex County work
- `NJAW_SHORT_HILLS` — Millburn / Short Hills service territory

UX: simple radio buttons or a dropdown. Default to NJ6 so 95%+ of submissions need zero extra clicks (per the locked MyInspector core principle: inspectors don't do extra work for the app).

Send the sector value as part of the INSERT into `properties`. CHECK constraint will block any value other than the two enum options — surface the error cleanly if it ever fires (shouldn't with controlled UI, but defense in depth).

### 2. Property Detail display

Show the current sector prominently on the Property Detail view. Suggested treatment: small badge near the address header. Color treatment: gray/neutral for NJ6 (most common), distinctive accent for SHORT_HILLS so the role-inversion sector is visually flagged.

### 3. Sector edit (with confirmation)

Allow editing the sector on Property Detail. **Show a confirmation modal** before saving — once MI-101 / MI-102 ship, sector drives different tapcard form layouts and Luis interaction rules, so flipping a property's sector is a load-bearing change. Confirmation copy suggestion:

> "Changing sector from NJ6_NORMAL to NJAW_SHORT_HILLS will change the tapcard form, restoration card, and homeowner interaction rules for this property going forward. Continue?"

The UPDATE goes through existing `properties` RLS policies — firm isolation is already enforced.

### 4. Optional: properties list filter

Nice-to-have, not blocking: add a sector filter on the properties list view. If trivial to add with existing filter UI, include it. If non-trivial, defer to a follow-up ticket — don't block MI-100 ship on it.

---

## Tests (`tests/mi100/`)

Buddy will draft starting points alongside this brief. Expected files:
- `sector_constraint_test.sql` — verify CHECK rejects values other than the 2 enum options
- `rls_test.sql` — confirm sector column inherits existing `properties` RLS (firm isolation)
- `audit_integrity_test.sql` — verify UPDATE on `properties.sector` produces audit_log delta = +1 (gated on whether properties has audit triggers — Buddy will confirm during draft)

Tagged dollar-quotes (`$TESTBODY$`) per `decisions.md` 2026-05-02. Each test in BEGIN/ROLLBACK so no test data persists.

---

## Acceptance criteria

- [ ] New properties default to `sector='NJ6_NORMAL'` automatically
- [ ] Property creation UI lets inspector pick `NJAW_SHORT_HILLS` if needed (one tap toggle)
- [ ] Property Detail displays sector prominently
- [ ] Sector edit works with confirmation modal
- [ ] Existing 39 properties remain valid (all NJ6 by backfill)
- [ ] CHECK constraint rejects any sector value other than the 2 enum options
- [ ] RLS isolation holds — firm A inspector can't see/edit firm B properties' sectors

---

## Constraints / locked rules to honor

- **BUDDY_STANDARD §7:** Code edits >3 lines = full-file replace, not surgical (or exact-match Edits if file is large and changes are precisely string-bounded — the §7 refinement Lead established during MI-108)
- **MyInspector core principle:** inspectors don't do extra work. Default to NJ6, hide complexity behind the toggle.
- **MyInspector privacy principle:** sector data is firm-scoped, RLS inherits existing policy
- **No new RPCs needed** — direct UPDATE per same pattern as MI-108

---

## Open questions for Buddy/Jorge (none currently locked)

If anything ambiguous surfaces during build:
- Where exactly the sector toggle lives in property creation (modal? inline form?) — Lead's UI judgment
- Filter/sort on properties list — defer if non-trivial
- Whether to show sector on the properties list rows (or only on detail)

Write to `.coordination/questions.md` with `**Awaiting:** Jorge` if any architectural ambiguity. Otherwise default and proceed — assumption noted inline.

---

## Forward context (not in MI-100 scope, but worth knowing)

Sector drives MI-101 / MI-102 form divergence:
- **NJ6_NORMAL** (MI-101): 3-page Normal tapcard (Materials Sheet + Company Side + Customer Side). Standard NJAW field convention. Inspector documents contractor work, talks to homeowner only when needed.
- **NJAW_SHORT_HILLS** (MI-102): 2-doc set (Company Side + Restoration Card). Role inversion — inspector dictates means/methods to contractor AND interacts directly with homeowner. Different form layout, different field set, different Luis interaction rules.

MI-100 is the foundation that lets the rest of the cluster diverge cleanly. Once MI-100 ships, MI-101 build can start with sector already locked into `properties`.

---

**Ready to pick up.** Backend verified post-migration. Buddy will verify your work post-merge via Supabase MCP — same pattern as MI-108.
