# Coordination Decisions — MyInspector

> Append-only chronological log of resolved architectural / process decisions.
> Per `.coordination/README.md` write conventions.
> Never edit prior entries. Supersede via new entry pointing back.

---

## 2026-05-02 13:15 EDT — `.coordination/` channel goes live (SG-001 Node 2)

**Decision:** Activate `.coordination/` file channel as canonical Buddy ↔ Lead handoff per the README convention spec. First commit instantiates `status.md`, `decisions.md`, `questions.md`, `buddy_context.md`.

**Reasoning:** Today's session demonstrated courier overhead is now the #1 bottleneck (Buddy → Jorge → terminal/SQL/browser → Jorge → Buddy ate 50%+ of session budget on MI-109 close). Filesystem MCP (Node 1, shipped 5/2 late) solved Buddy *reads*; this Node 2 step solves Buddy ↔ Lead *writes-via-shared-channel*. Convention only — no new tech.

**Source:** Jorge — direct ask 2026-05-02 12:55 EDT ("we waste too much usage and tokens screen shotting and copy and pasting large codes"); reinforced by Pass 1 friction inventory across past chats.

**Affects:** All future tickets. Working pattern from this commit forward.

---

## 2026-05-02 13:15 EDT — MI-109 closed via SQL coverage; manual e2e walk deferred

**Decision:** MI-109 PR #3 merged to main as `e76fac2` based on SQL test coverage (rls_test 9/9 + audit_integrity_test 8/8) without walking the 50-step manual e2e checklist. Manual e2e deferred to MI-109.5, gated on isolated staging tenant (which itself is gated on SG-001 Node 2/3 enabling the seed-test-tenant workflow).

**Reasoning:** Vercel preview deployment hits prod Supabase (single project, no separate staging). Walking the e2e on the preview would write immutable audit_log rows on prod against real LCRI job phase_submissions. SQL coverage already proved every code path the UI walk would exercise. Bulletproof per BUDDY_STANDARD priority order: bulletproof > accurate > efficient. Walking the UI walk on prod was none of those.

**Source:** Buddy proposed (b1) plan; Jorge confirmed "I trust you" 2026-05-02 12:30 EDT.

**Affects:** MI-109 (closed), MI-109.5 (new, queued), all future compliance gates that share this single-tenant staging constraint until Node 2/3 unlock isolated test tenant.

---

## 2026-05-02 ~11:00 EDT — Tagged dollar-quotes (`$TESTBODY$`) over anonymous (`$$`) in test SQL

**Decision:** Use tagged dollar-quote delimiters (`$TESTBODY$ ... $TESTBODY$`) for all PL/pgSQL DO blocks in `tests/mi109/audit_integrity_test.sql` instead of anonymous `$$ ... $$`.

**Reasoning:** Filesystem MCP `edit_file` tool corrupts `$$` on writes (eats one of the dollar signs in the new content during JSON serialization). Tagged dollar-quotes are functionally identical PostgreSQL syntax — no behavior change — but survive the tool's serialization pipeline cleanly. Defensive against future edits to the same file.

**Source:** Discovered in flight during gate #1 of Rule #9 doc fixes (5/2 ~11:00 EDT). Verified by reading the file back after the corrupted write.

**Affects:** `tests/mi109/audit_integrity_test.sql`. Pattern recommended for any future SQL file Buddy edits via filesystem MCP.

---

## 2026-05-02 ~10:00 EDT — Real bug fix: audit_log delta on accepted CS auth path is +2, not +1

**Decision:** Update `tests/mi109/audit_integrity_test.sql` step 3b expected `audit_log delta = +2` (was `+1`); update `tests/mi109/e2e_checklist.md` side-effects table accepted row `audit_log` column to `+2`.

**Reasoning:** The accepted RPC path produces TWO Owner Data writes — `INSERT INTO cs_replacement_authorizations` (audited via that table's `write_audit_log_trg`) AND `UPDATE phase_submissions SET cs_replacement = true` (audited via `phase_submissions`'s own audit trigger). Both fire `write_audit_log` per CLAUDE.md audit chain layer 2. Test was off-by-one on expectation; audit chain was working as designed.

**Source:** Buddy caught during Phase 4 Step 4 dry-run — `FAIL 3b: audit_log delta=2 (expected +1)`. Diagnosed against CLAUDE.md chain spec, confirmed it's a test bug not a code bug.

**Affects:** MI-109 test suite. Pattern reminder for any future ticket that does multi-table writes within one RPC: count audit_log delta = sum of Owner Data table writes, not "1 per RPC call."

---

## 2026-05-02 (earlier) — Phase 1 audit chain reconciliation banked

**Decision:** Five audit-chain assumptions verified and locked into CLAUDE.md (Phase 1 of MI-109, 5/1 evening). Specifically:
- `audit_log` columns: `prev_hash`, `row_hash`, `created_at`, `id` (NOT `current_hash` as drafted PR descriptions implied)
- `profiles.firm_id` = canonical firm-isolation column (nullable for super_admin)
- `pgcrypto` v1.3 in `extensions` schema; bare `digest()` / `gen_random_uuid()` need `SET search_path` to include extensions
- Compliance event logger is `record_compliance_event` (6-arg signature). NO separate `audit_log_append` RPC exists — audit chain is automatic via `write_audit_log` AFTER trigger.
- Hash chain mechanism is BEFORE INSERT trigger overwriting `'PENDING'` placeholders, NOT `payload::text` encoding.

**Reasoning:** PR #2 (closed without merging) was built on un-verified assumptions about all five. Phase 1 ran SELECT verification before re-building; found and fixed each.

**Source:** Lead (Phase 1 verification work, 5/1 evening). Banked into CLAUDE.md principle #7 (`security_invoker = true` for views) + schema source-of-truth section.

**Affects:** All future compliance-table work. MI-202, MI-203, future audit-chain reads.

---

## 2026-05-02 13:55 EDT — MI-108 architectural calls (NB1/NB2/NB3/NB4/NB5)

**Decision:** MI-108 (No-Work Submission Workflow, CDM-Smith rule a) implemented as:
- **NB1:** extend `phase` enum from 8 → 9 values (add `'no_work'`). NOT a boolean flag like `cs_replacement`.
- **NB2:** TWO separate photo slots — `photo_house_url` (no whiteboard required, "standard documentation" per locked field convention) and `photo_no_work_whiteboard_url` (whiteboard required, detection enforced via `photo_no_work_whiteboard_detected` boolean set by existing `detect-whiteboard` Edge Function).
- **NB3:** schema-level enforcement via CHECK constraint (`phase_submissions_no_work_invariant`); NO RPC gate. All writes go to `phase_submissions` (single table); existing `audit_phase_submissions_insert` trigger handles audit chaining automatically.
- **NB4:** reason min length = 20 chars (mirrors MI-109 reason field).
- **NB5:** ship without inspector "I confirm whiteboard" toggle for v1; whiteboard false-positive (laptop screen detected, observed once) stays parked under existing prompt-tuning queue.

**Reasoning:**
- NB1: each "type of work" is a phase value per locked UI convention (4/21 launch day — radio options for Test Pit, Assessment, Service Work, GIS Doc, Restoration, etc.). `cs_replacement` is a flag because it *modifies* a real phase (e.g., service_work + cs_replacement=true). No-work IS the phase, not a modifier — `phase='service_work' AND no_work=true` would be nonsensical.
- NB2: per the locked NJAW/CDM-Smith field convention, house photo and whiteboard photo are DISTINCT artifacts. Whiteboard is the physical chain-of-custody object held by inspector showing address/date/foreman/inspector + (for no-work) reason. House photo is property exterior documentation. One photo cannot serve both.
- NB3: BUDDY_STANDARD priority: bulletproof > accurate > efficient. Single-table writes with audit-fire-by-trigger is bulletproof. RPC was right for MI-109 because it wrote to a separate `cs_replacement_authorizations` table; MI-108 has no second-table need. Other 8 phase types already use direct INSERT — staying consistent.
- NB4: symmetry with MI-109 reason field (same UX pattern across CDM-Smith gates).
- NB5: false-positive is a known, parked issue. Adding a confirmation toggle would shift the UX away from "AI does execution" toward inspector-double-checks. Wrong direction. Fix the AI side (prompt tuning) when sample photos are available.

**Source:** Buddy proposed via `conversation_search` past-context lookup (MI-108 + CDM-Smith rules + whiteboard convention pulls from chats 4bc876eb, 55b6155f, 1f71ca91); Jorge confirmed via "yup" 2026-05-02 13:50 EDT.

**Affects:** MI-108 (active build). Pattern set for future CDM-Smith rule (b/d/e) implementations: schema constraints + audit triggers when single-table; RPC when multi-table.

---

## 2026-05-02 ~13:50 EDT — MI-108 backend migration applied via Supabase MCP

**Decision:** Migration `mi108_no_work_submission_workflow` applied to prod via `Supabase:apply_migration` (SG-001 Node 3's first production migration). Adds 4 columns, extends phase enum to 9 values, adds `phase_submissions_no_work_invariant` CHECK constraint enforcing CDM-Smith rule (a). Verified post-write via schema introspection query.

**Reasoning:** First migration applied via Supabase MCP rather than copy-paste into SQL Editor. Validates SG-001 Node 3 end-to-end pipeline: design → architectural calls via past-context → MCP `apply_migration` → verification query → confirmation. Roundtrip ~4 minutes; pre-MCP equivalent estimated 15-20 min (migration draft + paste to chat + Jorge runs it in editor + paste output back).

**Source:** Jorge approved migration text 2026-05-02 13:50 EDT ("yup"); Buddy executed via `Supabase:apply_migration`.

**Affects:** SG-001 Node 3 validation (now production-proven). Pattern locked: Buddy applies, Buddy verifies, Lead/Jorge no longer in the SQL paste loop. MI-108 backend = DONE; frontend handed off to Lead via `MI108_FRONTEND_BRIEF.md`.

---

## 2026-05-02 ~14:15 EDT — `compliance_events` id gap fully accounted, not an integrity issue

**Decision:** The `compliance_events` table id gap (open investigation banked from MI-109 Phase 1) is fully explained by two normal-Postgres patterns, NOT a chain or integrity breach. Investigation closed. No corrective action needed.

**Findings:**
- Rows present at investigation time (5/2 ~14:15): ids 4, 7, 8, 9, 10, 11 (6 rows). Sequence at last_value=23.
- Missing ids: 1-3, 5, 6, 12-23.
- **Pattern A — intentional cleanup:** ids 1-3 wiped by `cleanup_build_test_data()` function (super-admin-only, deletes rows matching `correlation_id LIKE 'TEST-%'` / `'RPC-TEST-%'` / `'INSTR-TEST-%'` or `event_type='subsystem.smoke_test'` or `source='manual_session'`). The function self-logs at completion — id 7 is the cleanup function's own log entry (`source='cleanup_build_test_data'`, severity='notice').
- **Pattern B — sequence advance from rolled-back transactions:** ids 5, 6, 12-23. Postgres sequences advance non-transactionally; failed/rolled-back inserts still consume their id. Twelve advances since 5/1 evening (id 11 = MI-201) = MI-109 Phase 1 verification queries + Phase 2 build attempts (PR #2 closed without merging) + MI-202 build cycles. Consistent with active build pace.

**Reasoning:**
`compliance_events` has no hash chain — that protection lives on `audit_log`. Gaps in `compliance_events` are expected behavior for any rolled-back transaction. The cleanup function explicitly self-logs, so its actions are auditable inside the same table. No chain breach exists.

**Architectural input for MI-203 design:** do NOT attempt chain-protection on `compliance_events`. Keep it as the semi-volatile narrative log. If a specific compliance event needs immutable integrity guarantee, route it through `audit_log` (or both layers). Don't conflate the layers — `compliance_events` is for narrative, `audit_log` is for integrity.

**Source:** Buddy investigation 2026-05-02 ~14:15 EDT via Supabase MCP. Three queries: (1) row dump ordered by id, (2) sequence current value via `compliance_events_id_seq`, (3) `cleanup_build_test_data` function definition via `pg_get_functiondef`. Hypothesis from buddy_context.md ("sequence-advance-from-rolled-back-inserts most likely cause") confirmed and refined to two-pattern explanation.

**Affects:** Closes the open investigation parked since MI-109 Phase 1 (now removable from `status.md` Active investigations + buddy_context.md Active investigations). Banks pattern for future compliance gates: write to `compliance_events` for narrative; write to `audit_log` for integrity. Demonstrates Supabase MCP self-investigation pattern (Buddy did the whole investigation without Jorge / Lead involvement).

---

## 2026-05-02 PM — dashboard.html verified production-ready (Buddy sign-off)

**Decision:** dashboard.html shipped in the main commit cycle at `0327abd` ("Buddy's recent commit" per Lead's pre-rate-limit transcript) is production-ready. All 8 backend dependencies verified live in prod via Supabase MCP. Visual smoke test on Vercel preview still recommended (~5 min) but no longer load-bearing.

**Verified:**
- 6 RPCs exist with correct signatures: `monthly_compliance_report(uuid, int, int)`, `cdm_smith_compliance_proof(uuid, int, int)`, `audit_trail_export(uuid, date, date)`, `inspector_activity_summary(uuid, date, date)`, `whiteboard_override_audit(uuid, date, date)`, `compute_contractor_billable_hours(uuid, uuid, date, date)`.
- 5 firm-scoped RPCs return-shape smoke-tested against CP Engineers / May 2026. Every top-level JSON key the JS unpacks is present. Extra keys (e.g., `audit.summary.first_id/last_id/returned/truncated`) are ignored harmlessly.
- Nested shapes verified on the four heaviest unpacks: `monthly_report.submissions` (total/no_work_count/cs_replacement_count/by_phase/by_njaw_work_order_code — exact match); `cdm.rules[0]` (rule_id/description/total/compliant/violations/compliance_rate, `note` optional and JS handles); `audit.chain_integrity` (status/break_count/breaks); `audit.summary` (total_in_period/action_breakdown/table_breakdown).
- Backing tables present with expected columns: `contractor_assignments` (id/contractor_name/contractor_role/project_id/firm_id/deleted_at), `projects` (id/name/contract_number/firm_id/deleted_at).
- Empty-state path: CP Engineers has 0 `contractor_assignments` rows. Dashboard renders the "Construction PM Oversight not yet active" empty state and `compute_contractor_billable_hours` is not invoked. Existence + signature check accepted for the 6th RPC until first contractor row lands.

**Reasoning:** Per BUDDY_STANDARD priority order (bulletproof > accurate > efficient), exhaustive shape verification of every JSON path the JS unpacks closes the same failure modes a UI walk would. Vercel auto-deploys from main; runtime errors are surfaced via the dashboard's toast handler. Visual walk is still recommended for visual-regression confidence (component layout, mobile breakpoints) but is not gating.

**Source:** Buddy verification 2026-05-02 PM via Supabase MCP. Three query batches: (1) RPC existence + signature catalog (6 RPCs + 2 tables), (2) column shape audit on `contractor_assignments` / `projects` / `firms`, (3) return-shape smoke test on 5 firm-scoped RPCs + nested-key drilldown.

**Affects:** Closes the dashboard.html verification gate. Visual UI walk on Vercel preview moves from required to recommended. Pattern banked for reuse: future read-only dashboard panels can use this same RPC-shape-check verification instead of forcing a UI smoke test (which would burn prod `audit_log` writes via authenticated session loads).
