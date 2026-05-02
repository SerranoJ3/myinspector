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

---

## 2026-05-02 PM — MI-101 Phase 2a Buddy sync (status.md "Next move" §3 unblock)

**Decision:** MI-101 Phase 2a Materials Sheet UI is cleared from Buddy's side for Lead to pick up next session. Five sub-calls below resolve the architectural ambiguities the brief flagged or that surfaced post-brief.

**Sub-calls (S1–S5):**

- **S1 — Phase 2a scope is Materials Sheet UI ONLY. MI-101.5 (dual-mode entry — type fields | photo notebook + Vision parse) is deferred to its own ticket post-Phase 2a ship.** Velocity rationale: shipping pure type-fields first is the bulletproof path; Vision parse is a bolt-on that benefits from the type-fields baseline being live + tested in field. STATE.md tapcard cluster already lists MI-101.5 as a separate ticket (4 sessions) — keeping that separation honors the locked plan.

- **S2 — NJAW selector (column-fix bug #3) stays on `service_work` tile only.** Lead's UI judgment in the shipped PR matches Jorge's locked NJAW codes scope: M2C/H2C/FULL/MP/TP/KILL describe service-line work, not the activities around it (test_pit, restoration). Extension to test_pit / restoration phases is a 3-line edit per phase per Lead's note; queued as a reactive follow-up if field feedback says inspectors need it. Not a v1 blocker.

- **S3 — Column-fix bugs #1/#2/#4 confirmed already-resolved by MI-109; column-fix queue closed.** Per Lead's session-close grep on `main`: `service_install`, `service_type=service`, `out_of_sequence` (bugs #1/#2 mappings) are not present on hot paths; `work_order_code` is already in the INSERT payload (closing bug #4). Only bug #3 (NJAW selector) needed code, which shipped on `njaw-selector` (commit `87173f0`). Column-fix tracking item removable from STATE.md "Known bugs" list at next session close.

- **S4 — B2 (`service_type`) and B3 (`kill_location`) remain free-text with autocomplete suggestions for Phase 2a.** No CHECK enum enforced at schema layer per brief. Tracked as Q-3 in questions.md awaiting Jorge's call: confirm closed enum (triggers small followup migration adding CHECK + data map) OR ratify free-text permanently. Phase 2a does NOT gate on this — the form ships free-text + suggestions either way; Jorge's call only changes whether a future tightening migration is queued.

- **S5 — Phase 1c (restoration grid table) does NOT gate Phase 2a.** Materials Sheet (Phase 2a) and restoration grid entries (Phase 1c) are independent data structures with no FK dependency. Phase 1c remains queued pending Jorge's call between option 1 (shared table + sector discriminator), option 2 (separate tables per sector), or option 3 (jsonb). Lead ships Phase 2a in parallel to or before Phase 1c is decided.

**Reasoning:** Per BUDDY_STANDARD priority order (bulletproof > accurate > efficient), shipping a tightly-scoped Phase 2a (S1) on a pure type-fields path closes the same compliance/UX value as a wider scope without introducing Vision-parse or restoration-grid integration risk. S2/S3 remove implicit scope creep ("should we extend NJAW further?", "are there bugs left?") that would otherwise stall the build by 30+ minutes per ambiguity. S4 surfaces the only remaining Jorge-side call as a non-blocking question — the form ships either way. S5 explicitly decouples Phase 2a from Phase 1c so neither blocks the other.

**Source:** Buddy review 2026-05-02 PM of `MI101_PHASE2_FRONTEND_BRIEF.md` + STATE.md tapcard cluster table + `.coordination/status.md` Next move §3 + Lead's session-close note ("MI-101 Phase 2 explicitly held per your instruction — Buddy sync first"). Cross-referenced with CLAUDE.md locked principles (#1 inspectors do no extra work, #5 triangulation anchor, #6 ShortHills role inversion) — none conflict with Phase 2a as scoped.

**Affects:** Unblocks MI-101 Phase 2a for Lead's next session. Closes column-fix queue (#1/#2/#4 done by MI-109, #3 done by `njaw-selector` PR). Surfaces Q-3 as the only remaining Jorge call on Phase 2a content. Phase 1c remains its own decision track. MI-101.5 remains its own ticket.

---

## 2026-05-02 PM — Phase 1c (restoration grid) Buddy recommendation: Option 1 (shared table + sector discriminator)

**Decision (recommendation, awaiting Jorge ratification via Q-4):** Phase 1c ships `restoration_grid_entries` as a single shared table with a `sector` NOT NULL CHECK column discriminating NJ6_NORMAL vs NJAW_SHORT_HILLS, common columns covering ~80% of both sectors' data, and ShortHills-specific modifier columns nullable. Option 1 of three surfaced in MI-101 brief.

**Schema sketch:**
- `id uuid pk`, `materials_sheet_id uuid not null fk → materials_sheets`, `firm_id uuid not null fk → firms`, `sector text not null check (sector in ('NJ6_NORMAL','NJAW_SHORT_HILLS'))`
- Common columns (both sectors): `entry_type text`, `dimension_inches numeric`, `material text`, `quantity numeric`, `unit text`, `notes text`
- ShortHills-only modifiers (nullable for NJ6_NORMAL): `restoration_subtype text`, `homeowner_present boolean`, `inspector_directed boolean`
- Standard infra: `created_at`, `submitted_by`, `deleted_at`, `deleted_by` (mirror-properties pattern per A3 banked 5/2 evening)
- Index: `idx_restoration_grid_entries_firm_id ON ... (firm_id) WHERE deleted_at IS NULL` (matches MI-204 partial-index convention from day 1 — learning from the `phase_submissions.firm_id` miss)

**Why Option 1 over 2/3:**

- **vs Option 2 (separate tables per sector):** ~80% column overlap means Option 2 duplicates RLS policies, audit triggers, legal_hold infrastructure, and migration scaffolding twice. Cross-sector firm-wide reporting becomes a UNION instead of a single SELECT. The `sector` discriminator already exists in production (MI-100 sector toggle, NJ6_NORMAL default on 39 properties via column DEFAULT) — adding it to the restoration table is convention reuse, not new design surface.
- **vs Option 3 (JSONB blob on materials_sheets):** loses CHECK constraint enforcement, FK integrity (multiple grid entries per sheet require array indexing), and queryability (filtering "show all NJ6 restoration entries" against jsonb is a `@>` predicate vs simple equality). Compliance data wants schema constraints, not flexible blobs. JSONB is right for ad-hoc data (e.g., `phase_submissions.tapcard_data` per STATE.md) where shape varies per submission; restoration grid has fixed shape per sector.
- **Option 1 nullable-modifier pattern is already validated:** `phase_submissions` uses nullable columns gated on phase value (no_work-only fields are nullable for non-no_work rows, enforced via the `phase_submissions_no_work_invariant` CHECK shipped in MI-108). Same pattern applies cleanly here: ShortHills-only modifiers nullable, enforced via a sector-conditional CHECK if needed.

**Reasoning:** Per BUDDY_STANDARD priority order (bulletproof > accurate > efficient): Option 1 is bulletproof (CHECK enforcement on sector + shape), accurate (matches existing convention from MI-100/MI-108), efficient (single deploy of RLS/audit/legal_hold infrastructure). Decoupled from Phase 2a per S5 in the prior decisions.md entry — Phase 1c can ship before, parallel to, or after Phase 2a without ordering risk.

**Source:** Buddy review 2026-05-02 PM of `MI101_PHASE2_FRONTEND_BRIEF.md` "Forward context" section + STATE.md tapcard cluster table + existing schema patterns on `phase_submissions` (nullable modifier pattern) and `properties` (sector discriminator pattern from MI-100).

**Affects:** Awaiting Q-4 ratification. On Jorge's "yup option 1," Buddy drafts the Phase 1c migration (single `apply_migration` call, mirror-properties pattern, partial index from day 1 per MI-204 lesson). On Jorge calling option 2 or 3, Buddy reverses and re-drafts. Phase 2a (Lead) remains independent of this call.

---

## 2026-05-02 PM — SUPERSEDES Phase 1c Option 1 recommendation: Phase 1c already shipped per ground-truth survey

**Supersedes:** 2026-05-02 PM — Phase 1c (restoration grid) Buddy recommendation: Option 1 (shared table + sector discriminator)

**Decision:** Phase 1c (`restoration_grid_entries` table) is ALREADY LIVE in prod, shipped before Buddy's recommendation entry was banked. Ground-truth Supabase MCP query (5/2 PM) confirmed the table exists with Option 1 design (shared table + `sector text NOT NULL CHECK IN ('NJ6_NORMAL','NJAW_SHORT_HILLS')` discriminator + common columns + ShortHills-specific modifier booleans). 0 rows currently. Recommendation matches the as-shipped design conceptually (Option 1 over 2/3); ShortHills-specific modifier columns differ from Buddy's hypothetical sketch but are correctly restoration-specific.

**As-shipped schema (verified 5/2 PM):**
- `id uuid pk`, `materials_sheet_id uuid NOT NULL fk → materials_sheets ON DELETE CASCADE`, `firm_id uuid fk → firms`, `submitted_by uuid fk → auth.users`
- `sector text NOT NULL CHECK (sector IN ('NJ6_NORMAL','NJAW_SHORT_HILLS'))` — Option 1 discriminator confirmed
- Common columns: `restoration_type text`, `dimension text`, `material text`, `quantity numeric` (CHECK ≥ 0), `entry_notes text`
- ShortHills-specific modifier booleans (nullable, intended for NJAW_SHORT_HILLS rows): `saw_cut_by_company`, `concrete_under_paving`, `recently_paved_road`, `base_8inch_by_company`
- Standard infra: `created_at NOT NULL`, `deleted_at`, `deleted_by uuid fk → auth.users`
- 3 partial indexes (firm_id / materials_sheet_id / sector, all `WHERE deleted_at IS NULL`)
- 2 RLS policies: `active_firm` (per-firm via profiles join) + `super_admin_all`

**Discrepancy with Buddy's hypothetical:** Buddy sketched modifier columns as `restoration_subtype text`, `homeowner_present boolean`, `inspector_directed boolean`. As-shipped uses `saw_cut_by_company`, `concrete_under_paving`, `recently_paved_road`, `base_8inch_by_company` — physical restoration specifics rather than Buddy's hypothetical role-inversion flags. As-shipped is correct for the use case: restoration grid captures *what was done*, not *who interacted with whom*. The ShortHills role inversion (CLAUDE.md principle #6) lives at the workflow/UI layer (inspector dictates means/methods, interacts with homeowner directly), not at the restoration data layer.

**Reasoning for SUPERSEDES rather than amendment:** The prior entry's "awaiting Q-4 ratification" framing is materially wrong — there's nothing to ratify. The schema is live. Forward references to "Buddy will ship migration on yup" are false. Replacing rather than amending makes the audit trail cleaner per `.coordination/README.md` SUPERSEDES convention.

**Phase 1d also shipped (caught in the same survey):** `materials_sheets` has 48 columns + 19 CHECK constraints, not the 46 + 17 the brief claims. The 2 extra columns are `existing_mp_noted boolean` (CDM-Smith rule b) and `mp_horn_copper_inches smallint` (CDM-Smith rule d). Phase 1d migration silently landed as part of the Phase 1b/1c cycle — brief's Phase 2a frontend already references both fields under "Section B — Existing MP Noted" and "Section E — MP Horn Copper," so Lead's MI-101 Phase 2a build will pick them up correctly. Tracking gap is in STATE.md and `.coordination/status.md`, neither of which lists Phase 1d as shipped.

**Source:** Buddy ground-truth survey 2026-05-02 PM via Supabase MCP (12-check batch comparing STATE.md claims vs prod state), prompted by Jorge's directive to "make sure you know what's already done versus what needs to be done." STATE.md last updated ~12:50pm EDT, ~6+ hours stale at survey time.

**Affects:** Q-4 in questions.md is now obsolete — flipping to `answered` with resolution pointing here. Phase 1c is no longer Buddy work; Phase 2a Materials Sheet UI (Lead) builds against the existing schema. Phase 1d should be tracked as shipped at next STATE.md / status.md refresh. Pattern banked for Buddy: ALWAYS ground-truth-verify schema state before banking a recommendation predicated on something being "queued" — STATE.md staleness is the failure mode that just got caught here.

---

## 2026-05-02 PM — Dashboard RPC security posture verified (Buddy sign-off)

**Decision:** All 6 dashboard RPCs (`monthly_compliance_report`, `cdm_smith_compliance_proof`, `audit_trail_export`, `inspector_activity_summary`, `whiteboard_override_audit`, `compute_contractor_billable_hours`) are production-safe under SECURITY DEFINER mode. Cross-firm leak path verified closed.

**Threat model + verification:**

1. **Anon caller** — `pg_role` GRANT check confirms `anon` lacks EXECUTE on all 6 RPCs. Cannot reach. ✓
2. **Authenticated caller** — `auth.uid()` always set via JWT; in-function guard ALWAYS runs, looking up `profiles.role` + `profiles.firm_id` and rejecting if `caller_firm <> p_firm_id` (unless `super_admin`). `RAISE EXCEPTION` with `insufficient_privilege` errcode. ✓
3. **Service_role caller** — `auth.uid()` is NULL; guard wrapped in `IF auth.uid() IS NOT NULL THEN ... END IF` skips. Service_role bypass is intentional for admin tooling. Acceptable because the service_role key is never exposed to the browser (Supabase `publishable_key` = anon; service_role key is server-side only). ✓
4. **All 6 RPCs declared `STABLE`** — guaranteed no DB writes; cannot pollute `audit_log` or modify state at the DB engine level. ✓
5. **All 6 RPCs set `search_path = public, pg_temp`** — search-path injection prevention active per CLAUDE.md `pgcrypto` convention. ✓
6. **All 8 public views** (`compliance_dashboard` + 7 `*_active` soft-delete-filter views) confirmed `security_invoker = true` — no CLAUDE.md principle #7 violations anywhere in the view layer. ✓

**Reasoning:** Per BUDDY_STANDARD §5 (production is production) + CLAUDE.md principle #4 (read-only by default), audit was warranted before declaring the dashboard production-safe under real-traffic load. The `auth.uid() IS NULL` skip looks like a leak path on first read but is closed by the EXECUTE GRANT posture (anon cannot reach the RPC at all; only authenticated triggers the guard; service_role is trusted by design + key never client-side). Pattern is consistent across all 6 RPCs — same prologue copy/pasted with minor wording tweaks per RPC's purpose.

**Source:** Buddy verification 2026-05-02 PM via Supabase MCP. Four query batches: (1) function `security_mode` + `search_path` settings + view `security_invoker` settings, (2) function source prologues showing the firm-guard pattern, (3) EXECUTE grant matrix across `anon`/`authenticated`/`service_role`/`public` roles, (4) confirmed all 6 RPCs declared `STABLE`.

**Affects:** Closes the dashboard RPC security gate. Dashboard is fully production-safe at this snapshot. Pattern banked for reuse: any future SECURITY DEFINER RPC reading firm-scoped data MUST replicate the `auth.uid()` → `profiles` guard AND must NOT have EXECUTE granted to `anon`. CI-style verification of this invariant could be a future ticket. Side-find: STATE.md "Soft-delete view rebuild" listed as queued is also already shipped (7 `*_active` views with `security_invoker=true`) — add to STATE.md refresh list alongside Phase 1c/1d.

---

## 2026-05-02 PM — cs_replacement_authorizations immutability gap (MI-109 Phase 3 deferral revisited)

**Finding:** The GRANT-based immutability pattern banked in MI-109 Phase 3 ("INSERT-only via grants") is partially in place but incomplete. `service_role` retains full CRUD (DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE), and there is no `enforce_legal_hold` trigger on the table (verified 2026-05-02 PM via Supabase MCP).

**GRANT posture (verified):**

| Role | INSERT | UPDATE | DELETE | SELECT |
|---|---|---|---|---|
| `anon` | ❌ | ❌ | ❌ | ✓ (RLS-filtered to firm) |
| `authenticated` | ❌ | ❌ | ❌ | ✓ (RLS-filtered to firm) |
| `service_role` | ✓ | ✓ | ✓ | ✓ |
| `postgres` | ✓ | ✓ | ✓ | ✓ |

The browser-side path is fully closed (anon + authenticated cannot mutate). The server-side path via `service_role` is wide open.

**Compliance impact (CDM-Smith rule c "no exception" on Carlo authorization):**

In the current state, any backend tooling holding the `service_role` key can:
1. UPDATE an existing `cs_replacement_authorizations` row to alter `authorized_at`, `reason`, or `supervisor_name`.
2. DELETE a row outright.

These mutations would fire `write_audit_log_trg` and produce an `audit_log` row capturing the before/after payload — so the change is FORENSICALLY recoverable. But the live row can be modified silently from the application's perspective. "No exception" is preserved in spirit (audit trail) but not in form (live row immutability).

**RLS policy posture (separate finding):**

`cs_replacement_authorizations` has 1 RLS policy (`cs_replacement_auth_firm_isolation`, `cmd=*` with firm-or-super-admin OR check) vs 2 policies on most other Owner Data tables (`active_firm` + `super_admin_all`). Functionally equivalent — the OR check in the single policy covers both branches. Not a concern; just a stylistic variance worth noting for consistency-audit purposes.

**Three options for closing the gap (Q-5 in questions.md):**

1. **Revoke UPDATE + DELETE from `service_role` on `cs_replacement_authorizations`.** True GRANT-based immutability. Must first verify no legitimate admin tooling needs UPDATE/DELETE (e.g., test cleanup, manual data correction). Once shipped, all Carlo authorization records become INSERT-only at the GRANT layer; only `postgres` superuser can mutate.

2. **Add `enforce_legal_hold` trigger.** Pattern matches the other 5 silently-shipped tables (contractor_*, materials_sheets, restoration_grid_entries). Legal_hold becomes the gate — mutations allowed only when no active legal hold scopes the row/table/firm. Ships as a single migration.

3. **Accept the gap.** Document that `service_role` retains full CRUD; rely on `audit_log` + hash chain for compliance evidence. CDM-Smith rule (c) "no exception" interpreted as gate behavior (Carlo auth required for submission) + audit trail preservation, not live-row immutability.

**Reasoning for surfacing now:** Per BUDDY_STANDARD §5 (production is production) + the explicit MI-109 Phase 3 deferral note in STATE.md ("Defer call until `record_whiteboard_override` + `whiteboard_override_log` are reviewed as template"), this gap was always known but parked. Buddy's audit pass to verify dashboard RPC security re-surfaced it as part of "what's actually done vs what's claimed." Jorge call before further compliance work proceeds.

**Source:** Buddy verification 2026-05-02 PM via Supabase MCP. Two queries: (1) `information_schema.role_table_grants` for cs_replacement_authorizations + comparator (materials_sheets, which uses GRANT ALL + relies on RLS/audit/legal_hold for protection — different security model), (2) `pg_policy` and `pg_trigger` inspection.

**Affects:** Q-5 in questions.md awaits Jorge's call. MI-109 stays CLOSED as a feature-shipped ticket, but Phase 3 immutability remains DEFERRED with this finding logged. No production risk requiring immediate action (browser-side path closed; service_role key not client-exposed).
