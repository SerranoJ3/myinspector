# `.coordination/templates/`

Reusable working patterns extracted from shipped tickets. Read this README first before using any template.

**Banked:** 2026-05-02 evening — extracted from MI-100 + MI-108 + MI-109 patterns after the third gate shipped same day.
**Maintained by:** Buddy on lessons-learned. Lead reads + uses but doesn't edit unless Jorge approves.

---

## Why these exist

Saturday May 2, 2026, three compliance gates shipped on a single day — MI-109, MI-108, MI-100. Each ticket followed nearly identical patterns: schema migration → constraint test → audit integrity test → RLS test → frontend brief → ship. By gate three, the templates were obvious. So we extracted them. The first ticket to use these templates skips ~50% of Buddy's drafting cost compared to the cold-start MI-100 flow.

**The principle:** Lead reads template → fills concrete values from the migration → has working test/brief in minutes, not Buddy turns. Buddy is reserved for architectural decisions and pattern-divergence cases.

---

## What's in here

| File | Use for | Proven against |
|---|---|---|
| `test_constraint.sql.template` | Any migration with a CHECK constraint, NOT NULL+DEFAULT, or enum-style validation | MI-100, MI-108 |
| `test_audit_integrity.sql.template` | Any migration changing a column on a table that has audit triggers | MI-100, MI-108 |
| `test_rls.sql.template` | Any migration adding a column to a firm-isolated table (RLS forced + active_firm policy) | MI-100, MI-108 |
| `frontend_brief.md.template` | Any Lead handoff after a backend migration ships | MI-100, MI-108 |

---

## How to use a template

1. **Copy** the template to its target location (e.g. `tests/mi110/sector_constraint_test.sql`)
2. **Replace ALL `{{PLACEHOLDERS}}`** with concrete values. Do a final grep for `{{` before committing — any unreplaced placeholder = a bug
3. **Run** the test in Supabase SQL editor (read-only MCP doesn't support tests with writes — see `decisions.md`)
4. **Verify** the expected NOTICE count matches: 4 PASS for constraint + audit, 4 PASS + 1 fixtures NOTICE for RLS

Each template's header comment lists its specific placeholders and how to fill them. The notes section at the bottom of each template documents edge cases.

---

## When to use vs fork

**Use the template when:**
- Your migration matches the proven-against pattern (column add, CHECK constraint, RLS-inherited)
- The table has the expected infrastructure (audit triggers if using audit template; firm_id + RLS policies if using RLS template)
- Your tests are 80%+ identical to what shipped in MI-100 / MI-108

**Fork the template when:**
- You need to test something the template doesn't cover (e.g. tested cross-table writes, complex JSONB constraints, custom triggers, multi-column CHECK invariants like MI-108's `phase_submissions_no_work_invariant`)
- Your table has unusual fixtures (e.g. requires seeding 3+ FK chains)
- You're testing a NEW pattern that should later be promoted to a template of its own

**A fork that ships and proves itself is a candidate to merge back into the template** as a new variant or a generalization. When you fork, leave a comment at the top of the forked file noting why the template wasn't used. That comment is the seed for future template improvements.

---

## Required pre-checks before using a template

The audit template assumes the table has `audit_<table>_insert/update/delete` AFTER triggers. If you skip this check, the audit assertions will silently fail. Run this before drafting:

```sql
SELECT tgname FROM pg_trigger
WHERE tgrelid = 'public.<your_table>'::regclass
  AND NOT tgisinternal
  AND tgname LIKE 'audit_%';
```

If empty, do NOT use the audit template. Either skip audit testing for this ticket OR add audit triggers as part of the migration (and document the addition in `decisions.md`).

The RLS template assumes the table has `<table>_active_firm` and `<table>_super_admin_all` policies. Verify with:

```sql
SELECT polname FROM pg_policy WHERE polrelid = 'public.<your_table>'::regclass;
```

If the policy names differ, adjust the template's comment header but the test logic still works (it tests behavior, not policy names).

---

## Maintenance — when templates change

Templates are extracted from working code, not theorized. They evolve when:

1. **A pattern divergence ships and proves cleaner.** Example: MI-108's hash chain assertion (`prev_hash !~ '^[0-9a-f]+$'`) was added during draft because Buddy initially missed the chain population check. That pattern was banked into the audit template.

2. **A new project-wide convention lands** in `decisions.md` (e.g. tagged `$TESTBODY$` dollar-quotes). All templates update in one pass.

3. **A failure mode surfaces** during real test runs that the template didn't guard against. Update the template's notes section with the failure mode + the fix.

When you change a template, update its header comment with the date and what changed. Don't silently revise.

---

## What this enables

Tomorrow's typical ticket flow with templates:

1. Buddy approves the migration plan (1 turn, strategic check)
2. Buddy applies migration via Supabase MCP (1 turn)
3. Lead reads templates, fills placeholders, drafts tests + brief (Lead's CLI session, ~10-15 min, zero Buddy turns)
4. Jorge runs tests in SQL editor
5. Lead opens PR
6. Jorge merges

**Total Buddy turns per ticket: 2-3** (plan check + migration + post-merge verification), down from 8-12 in the cold-start flow. Direct token savings of ~60-70% on routine ticket execution. Buddy stays available for the architectural calls and cross-product work that actually need cross-context judgment.

---

## Anti-patterns

- **Don't use a template when the architectural pattern is novel.** Templates encode the boring 80%. Novel architectural moves need Buddy's strategic check first, then become templates after they ship.
- **Don't blindly trust placeholder substitution.** If you replace `{{TABLE}}` with `phase_submissions` and the test fails because phase_submissions has a complex invariant the template didn't anticipate, that's a fork case. Read the template's notes section.
- **Don't skip the pre-checks** (audit triggers exist, RLS policies exist). Templates assume infrastructure; verify it.
- **Don't promote a one-off to a template.** A pattern needs to be proven against at least 2 tickets before it earns template status.

---

## First validation: MI-101 Phase 1a (5/2 evening)

The first ticket to use these templates was MI-101 Phase 1a (materials_sheets table SHELL). It surfaced two real friction points worth banking:

### Friction 1: `test_constraint.sql.template` assumes CHECK enums

**Observed:** Phase 1a added a NEW table whose constraints are FK + NOT NULL, not CHECK enums. The template's 4 standard tests (default applied / explicit valid value / invalid INSERT rejected / invalid UPDATE rejected) don't map cleanly to FK-only behavior.

**Fork applied:** `tests/mi101/materials_sheets_constraint_test.sql` kept the 4-test structure but swapped CHECK assertions for FK assertions (NOT NULL violation, FK violation against random uuid, cross-table FK existence check via `pg_constraint`).

**Pattern candidate for Tier 2:** `test_constraint_fk.sql.template` — for new-table migrations where the constraint surface is FK + NOT NULL rather than CHECK. Promote when a second ticket uses the same fork pattern.

### Friction 2: `test_audit_integrity.sql.template` is UPDATE-driven

**Observed:** Phase 1a's table has no business UPDATE-able columns yet (only timestamps + soft-delete). The template tests UPDATE → audit_log delta, but there's nothing meaningful to UPDATE.

**Fork applied:** `tests/mi101/audit_integrity_test.sql` swapped UPDATE-driven assertions for INSERT-driven (INSERT produces delta=+1, failed INSERT produces delta=0, audit row shape with `old_data IS NULL` for INSERT, hash chain populated). The hash chain test was identical between fork and template.

**Pattern candidate for Tier 2:** consider splitting the audit template into two:
- `test_audit_integrity_insert.template` for new-table tickets
- `test_audit_integrity_update.template` for column-add tickets on existing tables

OR keep one template parameterized by `{{ACTION}}` (INSERT or UPDATE) with conditional assertions. Promote when a second new-table ticket lands.

### Template that worked clean: `test_rls.sql.template`

The RLS template fit Phase 1a perfectly. Only adaptation: `{{COLUMN}}` was substituted with `property_id` (the FK), since materials_sheets has no domain enum column to read back as a visibility marker. The fixtures pattern (2 firms, 2 inspectors, 1 super_admin, 2 rows) generalized cleanly — just needed an extra fixture seed for `properties` (the FK target) before seeding `materials_sheets`.

**No template change needed.** Document the FK-as-visibility-marker pattern inline in the template's notes section if it shows up again.

### Template that wasn't tested: `frontend_brief.md.template`

MI-101 Phase 1a has no frontend work — it's pure schema. So `frontend_brief.md.template` wasn't exercised. The Phase 1a doc that shipped is `MI101_PHASE1A_BRIEF.md` (status report, not a Lead handoff). The frontend brief template gets validated when Phase 1b ships (form fields → form UI → Lead handoff).

---

## Maintenance log

- 2026-05-02 evening: Tier 1 templates extracted from MI-100 + MI-108 patterns
- 2026-05-02 evening: First validation against MI-101 Phase 1a; two friction patterns banked above (FK fork, INSERT fork) as Tier 2 candidates
- 2026-05-02 evening: **Second validation against MI-101 Phase 1b** (column-add to existing table). Templates fit cleanly — no forks needed for either constraint or audit. One minor adaptation: TEST 1 of constraint template assumes a column DEFAULT (test 'default applied'); Phase 1b columns are nullable without DEFAULT, so TEST 1 + TEST 2 collapsed into 'explicit valid value' (tested `sunny` + `cloudy` for sky_condition). Bank into template notes section if it shows up again. Validates the Tier 2 pattern: column-add tickets fit templates as designed; new-table tickets need forks. Templates earn their place — ~50% Buddy turn reduction realized in real time.
- 2026-05-02 late evening: **Third validation against MI-101 Phase 1c + Phase 2 brief.** Phase 1c surfaced the "trust the mirror pattern" optimization — when a new table copies RLS / audit / legal_hold infrastructure from an existing tested table, audit + RLS test files for the new table can be deferred. Saved 2 test files of Buddy turns. Phase 2 brief surfaced the multi-section form pattern — frontend_brief.md.template assumes single-column-add UI but a 36-field form needs ~8x section expansion. Pattern candidate for Tier 2: `frontend_brief_form.md.template`. Will promote when Phase 2b's brief reuses the same expanded-form pattern. Three Tier 2 candidates accumulated this evening: `test_constraint_fk.template`, `test_audit_integrity_insert.template`, `frontend_brief_form.md.template`. None yet promoted — each needs second usage to qualify.
- _next: refine if friction surfaces twice or if a third ticket can't fit either current or forked pattern_
