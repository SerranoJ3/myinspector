# Coordination Questions — MyInspector

> Active queue of asks awaiting Jorge's call (or Buddy's, when Lead asks).
> Per `.coordination/README.md` write conventions.
> Status flips to `answered` with a `**Resolved:**` line; entries persist for audit trail.

---

## Q-1: SUPERSEDED — initial empty queue placeholder

**Asked by:** Buddy
**Awaiting:** N/A
**Context:** First instantiation of `questions.md` per `.coordination/README.md`. No real open questions at the moment of channel activation. This entry exists so the file is non-empty and Q-numbering starts at a sane index.
**Specific call needed:** None.
**Status:** answered
**Resolved:** 2026-05-02 13:15 EDT — placeholder by design; real Q-2+ entries follow as questions arise.

---

<!-- Q-2 onward: append below this line, one block per question -->

## Q-2: MI-203 step 2 + NJAW selector pushed — awaiting Vercel preview verification before step 3 queue

**Asked by:** Lead (Claude Code CLI)
**Awaiting:** Jorge (preview verification), then Buddy (step 3 migration)
**Context:** Both tickets per the tonight-queue are shipped on separate branches off main:

- **MI-203 step 2** — `mi203-step2` branch, commit `6abe03c`. Cuts `signup()` over to `lookup_firm_by_code` RPC (single call site at `index.html:1334`). `firm.id`/`firm.name` rename to `firms[0].firm_id`/`firms[0].firm_name`. No remaining direct `from('firms').select.eq('firm_code')` in pre-auth path (verified by grep). PR: https://github.com/SerranoJ3/myinspector/pull/new/mi203-step2
- **NJAW selector (column-fix bug #3)** — `njaw-selector` branch, commit `87173f0`. Adds 6-option NJAW classification dropdown (M2C/H2C/FULL/MP/TP/KILL + "Not specified" default) to the service_work form, persisted to `phase_submissions.njaw_work_order_code`. Lead's UI judgment: service_work only (parity with existing `work_order_code` dropdown); test_pit/restoration extension is a follow-up if Buddy wants it (3-line edit per phase). PR: https://github.com/SerranoJ3/myinspector/pull/new/njaw-selector

Bugs #1/#2/#4 from the column-fix queue were already fixed in MI-109 — verified by grep on current main, no new code required.

**Specific call needed:**
1. Jorge: spin Vercel preview for both PRs, run the per-ticket verification checks (signup with `QUIET-RIVER-58` succeeds + bad code fails + firm name displays after login; NJAW selector visible on service_work tile + value persists).
2. Once green: Buddy to ship MI-203 step 3 (single-line migration dropping `firms_read_anon` policy + verification queries that anon can no longer SELECT firms directly).

**Status:** open

---

## Q-3: B2 / B3 enum calls — confirm closed list or ratify free-text + autocomplete

**Asked by:** Buddy
**Awaiting:** Jorge
**Context:** Per `MI101_PHASE2_FRONTEND_BRIEF.md` and decisions.md 5/2 PM (S4): two `materials_sheets` columns shipped as plain text without CHECK enums:

- **B2 — `service_type`** (free text). Possible enum candidates from existing UI / phase enum surface: `test_pit`, `service_work`, `restoration`, `gis_docs`, `assessment`, `out_of_order`, `tapcard`, `no_work`. Note: overlaps with `phase_submissions.phase` enum — `service_type` may or may not be the same conceptual axis. Need Jorge's call on the relationship.
- **B3 — `kill_location`** (free text). Possible enum candidates: MI-107 KILL subtypes (`ABANDON`, `RELOCATE_FULL`, `RELOCATE_STREET`), OR a physical location descriptor (`main`, `curb`, `house`), OR something else entirely. Brief doesn't specify.

**Specific call needed:**

For each of B2 and B3, one of:
1. Confirm closed enum list. Buddy ships a small follow-up migration adding CHECK + mapping any existing rows. Frontend (Phase 2a) ships hard dropdown.
2. Ratify free-text + autocomplete suggestions permanently. No schema work; frontend ships text input + suggestion list.

Phase 2a frontend build does NOT gate on this — Lead ships free-text + suggestions either way. The answer changes only whether a future tightening migration is queued.

**Status:** open

---

## Q-4: Phase 1c restoration grid table — ratify Option 1 (shared + discriminator) or call Option 2/3

**Asked by:** Buddy
**Awaiting:** Jorge
**Context:** Per `MI101_PHASE2_FRONTEND_BRIEF.md` "Forward context" + decisions.md 5/2 PM (Phase 1c entry): Buddy recommends Option 1 (shared `restoration_grid_entries` table with `sector` NOT NULL CHECK discriminator + common columns + ShortHills-specific modifier columns nullable). Rationale fully banked in decisions.md.

Three options:
1. **Shared table + sector discriminator** — RECOMMENDED. ~80% column overlap, single deploy of RLS/audit/legal_hold, single-table cross-sector queries. Mirrors existing patterns (MI-100 sector column on properties, MI-108 nullable-modifier pattern on phase_submissions).
2. **Separate tables per sector** — `restoration_grid_entries_normal` + `restoration_grid_entries_shorthills`. Cleaner if sectors diverge significantly post-launch; doubles infra cost up front.
3. **JSONB blob on materials_sheets** — single `restoration_data jsonb` column. Loses CHECK enforcement and FK integrity. Wrong fit for compliance data.

**Specific call needed:**

One of:
1. Yup Option 1 → Buddy ships Phase 1c migration (single `apply_migration` call) on Jorge's next ack after this one.
2. Call Option 2 or 3 → Buddy reverses recommendation and re-drafts before shipping.

Phase 2a (Lead) is decoupled from this per S5 — does not gate frontend build either way.

**Status:** answered
**Resolved:** 2026-05-02 PM — superseded by ground-truth survey. Phase 1c (`restoration_grid_entries`) is ALREADY LIVE in prod with Option 1 design (shared table + `sector` NOT NULL CHECK discriminator + common cols + ShortHills-specific restoration modifier booleans). 0 rows currently. No ratification needed; no Buddy migration to ship. See decisions.md SUPERSEDES entry 5/2 PM for full as-shipped schema. Buddy's recommendation matched the design 95% (Option 1 confirmed; ShortHills modifier columns differ from Buddy's hypothetical but are correctly physical-restoration-specific). Lesson: ground-truth-verify schema before banking a recommendation predicated on something being "queued."

---

## Q-5: cs_replacement_authorizations immutability — close MI-109 Phase 3 deferral or accept gap

**Asked by:** Buddy
**Awaiting:** Jorge
**Context:** Per decisions.md 5/2 PM (cs_replacement_authorizations immutability gap entry): MI-109 Phase 3 deferral on layer-4 immutability is incompletely closed. `anon` and `authenticated` callers cannot mutate the table (INSERT/UPDATE/DELETE all revoked) — browser-side path safe. But `service_role` retains full CRUD (Supabase default GRANT posture, never narrowed) AND there is no `enforce_legal_hold` trigger. So any backend tooling holding the service_role key can modify or delete Carlo authorization records.

Mutations would fire `write_audit_log_trg` (forensically recoverable from audit_log payload), but the live row remains modifiable. CDM-Smith rule (c) "no exception" is preserved in audit-trail form, not in live-row form.

No immediate production risk: service_role key is never client-exposed. But the gap should be closed before scaling backend tooling that uses service_role.

**Specific call needed:**

One of:

1. **Revoke UPDATE + DELETE from `service_role`** on `cs_replacement_authorizations`. Buddy verifies no legitimate admin tooling currently uses these, then ships a single-line migration `REVOKE UPDATE, DELETE ON public.cs_replacement_authorizations FROM service_role;`. True GRANT-based immutability — only `postgres` superuser can mutate after.

2. **Add `enforce_legal_hold` trigger** matching the pattern on the 5 other Owner Data tables (contractor_*, materials_sheets, restoration_grid_entries). Single migration adding the trigger. Mutations remain technically possible but are gated behind legal_hold.

3. **Accept the gap and document.** Bank a CLAUDE.md note that cs_replacement_authorizations relies on audit_log + service_role-key-secrecy for immutability rather than GRANT or legal_hold patterns. No migration; just documentation.

**Buddy recommendation:** Option 1 (revoke UPDATE/DELETE from service_role). Cleanest closure of the MI-109 Phase 3 intent ("INSERT-only via grants"). Lowest moving-parts solution. Option 2 adds machinery for a use case (legal hold lifting an immutability) that doesn't apply to Carlo authorizations — they should never be liftable per CDM-Smith rule (c). Option 3 documents an architectural debt without closing it.

**Status:** open
