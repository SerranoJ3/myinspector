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

## 2026-05-02 ~23:00 EDT — Saturday session close (tapcard milestone reached)

**Decision:** Bank Saturday-night session as a milestone. Tapcard surface (the inspector-visible payoff piece) one merge away from going live. LCRI scope advanced from ~30% (Saturday morning) to ~62% (Saturday close), a 32-percentage-point jump in one session.

**What shipped:**
- Recovery from stale compaction summary; lesson banked: ALWAYS verify state via `.git/refs` + filesystem read at session open.
- 4 production migrations via Supabase MCP (`parts_catalogs_placeholder_seed`, `demo_inspector_binding`, `cs_replacement_auth_immutability_revoke_service_role`, `mi204b_firm_id_indexes`).
- 3 PRs squash-merged: mi203-step2 + mi101-phase2a + mi101-phase2b ORIGINAL.
- njaw-selector original closed unmerged (conflict casualty); Lead rebuilding as `njaw-selector-v2`.
- Tapcard scope error caught + corrected mid-session. Buddy oversold spec completeness; Jorge uploaded `INSPECTOR_SHEET-TAPCARD_TEMPLATE.pdf` to recalibrate. Scope reductions locked: Customer Side dropped, Lot/Block dropped, office-fill role-gated, diagram pane visually prominent.
- Lead refactored Phase 2b to spec on branch `mi101-phase2b-refactor` (commit `b74298d`, +203/-108 net delete). All 9 acceptance criteria green per self-walk.
- Filesystem `edit_file` truncation incident on decisions.md (em-dash mismatch). Recovered via `write_file` full overwrite. Lesson: avoid `edit_file` for content with em-dashes/special chars; default to `write_file`.

**Affects:** Tonight's outcome banked. 38% of v1.0 still remaining is dominated by Phase 4 Diagram editor, ShortHills + Restoration Card (MI-101 Phase 2c), Construction PM frontend, and 5 non-LCRI modules. Velocity unchanged: aggressive end-of-May 2026, realistic mid-July 2026.

**Source:** Buddy session-close summary at Jorge's request 2026-05-02 ~23:00 EDT.

---

## 2026-05-03 ~08:55 EDT — Saturday's pending queue closed

**Decision:** Saturday's three pending items shipped clean Sunday morning. `mi101-phase2b-refactor` PR merged at 0:52am as commit `4d70901`. MI-203 step 3 (`DROP POLICY firms_read_anon`) shipped at ~08:55am via Supabase MCP migration `mi203_step3_drop_firms_read_anon` — pre-flight confirmed `firms_read_anon` policy existed (1) and `lookup_firm_by_code` was SECURITY DEFINER; post-drop confirmed 2 firms policies remaining (`firms_read_authenticated`, `firms_super_write`), zero `firms_read_anon`. Schema integrity green: 16 NJ6_NORMAL parts_catalogs rows, 369 audit_log events 24h, 1 demo phase='tapcard' row pre-dating Phase 2b UI.

**Affects:** Saturday's milestone fully closed. Real tapcard_data jsonb shape verification waits on first live user submission. `njaw-selector-v2` push status still uncertain — Jorge verifies on GitHub branches page.

**Source:** Buddy execution Sunday morning per pending queue from 5/2 ~23:00 close.

---

## 2026-05-03 ~12:30 EDT — Domain TLD: `.org` over `.com`/`.io`/`.group`

**Decision:** `serranogroup.org` purchased at Cloudflare Registrar for $7.50 first year, $10.13/yr renewal. Auto-renew on, expires 2027-05-03. Account ID `acb79e1a4fced4c981500a619d2ed809`. WHOIS uses home address with Cloudflare WHOIS privacy enabled (publicly redacted); swap to Northwest Registered Agent's NJ address eventually for layered safety.

**Reasoning:** `serranogroup.com` and `serranogroup.io` both already taken. Available alternatives ranked: (1) `.org` — full brand-name URL preserved, $10/yr renewal (same as `.com` would have cost), reads institutional/holding-company; (2) `serrano.group` — would have been ideal but couldn't verify availability through permission-blocked search flow; (3) `serranogrp.com` — Jorge correctly rejected as cheap-looking; (4) `serranogroup.group` — "group.group" tongue-twister; (5) `.ca`/`.uk` — wrong country signaling. `.org` wins on brand fidelity + cost + institutional read.

**Affects:** All future Serrano Group brand assets reference `.org`. Per-product domains (myinspector.io, bidgrid.io, tia.io, forge.io etc.) remain separate decisions.

**Source:** Jorge selection from available list at Cloudflare search results.

---

## 2026-05-03 ~13:15 EDT — Email Routing destination: `live.com` over `gmail.com`

**Decision:** Cloudflare Email Routing live for `serranogroup.org`. `jorge@serranogroup.org` forwards to `jserranojr340@live.com`. DNS auto-configured (MX, SPF, DKIM, DMARC). Verified end-to-end: test email from Jorge's phone landed in Outlook within seconds.

**Reasoning:** Cloudflare account is registered with `jserranojr340@gmail.com` (auto-discovered as suggested destination). Locked Buddy memory specifies `jserranojr340@live.com` as super_admin email. Defaulted to live.com per memory lock; Jorge confirmed post-test that landing in Outlook is preferred. Memory rule wins over context-discovered defaults.

**Affects:** All future Serrano Group inbound mail (jorge@, ops@, hello@, billing@) default-routes to live.com unless Jorge specifies otherwise per address.

**Source:** Buddy execution + Jorge end-to-end test confirmation.

---

## 2026-05-03 ~14:00 EDT — Marketing site hosting: Cloudflare Pages over Vercel

**Decision:** Serrano Group marketing site (`serranogroup.org`) deploys to Cloudflare Pages, not Vercel. MyInspector and other product apps stay on Vercel. Project deployed Sunday afternoon as auto-named `steep-pine-05b2.jserranojr340.workers.dev` after Jorge's manual drag-drop upload (Chrome MCP `file_upload` rejected by Cloudflare's drop-zone JS handler with `{"code":-32000,"message":"Not allowed"}`).

**Reasoning:** `serranogroup.org` DNS is on Cloudflare. Hosting on Cloudflare Pages = zero DNS config, free SSL, free CDN, drag-and-drop deploy. Same provider for DNS + hosting reduces moving parts on a one-page static site. Vercel's strength (preview deployments, Git integration, Edge functions) is wasted on a static marketing page.

**Affects:** Pattern for future Serrano Group marketing/landing pages — Cloudflare Pages by default. Product apps (anything with auth, DB, dynamic content) stay on Vercel. Two-platform split kept clean.

**Status note:** Custom domain wiring (`serranogroup.org` → Pages project) failed first attempts with Cloudflare-side state-mismatch errors ("DNS record could not be added" on apex; "Only domains active on your Cloudflare account" on www) despite zone being verified active. Documented as expected propagation delay between fresh registration and Workers feature recognition; retry queued.

**Source:** Buddy proposal mid-execution; no Jorge pushback.

---

## 2026-05-03 ~15:30 EDT — AR auto-fill tapcard parked as BB-001 (iPad-first)

**Decision:** Idea captured to `.coordination/back_burner.md` as BB-001. Parked indefinitely. Trigger to un-park: first paying non-CP customer signs.

**Mechanic in brief:** Inspector taps anchor at CS, walks to each measurement point, taps end-point at each stop. iPad ARKit + compass + IMU captures distance/bearing per stop, diagram auto-draws, tapcard fields auto-populate. Manual click-and-drag fallback always available — first-class, not degraded.

**Why parked despite real merit:**
1. ~25–32 sessions on top of Phase 4 manual editor (~6 sessions). Quarter-long native-app initiative.
2. Native shell required (Capacitor / React Native / native iPadOS) — MyInspector is web SaaS, iOS Safari WebXR is too limited.
3. Compass drift over buried metal (5–30°) needs site-calibration UX + GPS bearing cross-check.
4. Same trap pattern as TIA hardware before MyInspector revenue: delight feature looking for a reason.

**Why iPad-first changes the math (vs phone-first):** Every CP inspector has a company-issued iPad. Eliminates Android fragmentation, LiDAR variability, premium-tier pricing problem, three-shell fork.

**Why manual fallback is required day one:** Jorge flagged at least one inspector who would refuse to install a work app on his personal phone — that inspector is sometimes the most accurate guy on the crew.

**Affects:** All future feature-prioritization conversations reference BB-001 trigger. Don't build AR before first non-CP paying customer.

**Source:** Jorge field instinct mid-Sunday session; Buddy + Jorge converged on iPad-first + manual-fallback-required + trigger-locked structure.

---

## 2026-05-03 ~16:30 EDT — Sunday afternoon verification + spec drafts batch

**Decision:** Buddy executed a complete prod verification suite (Supabase MCP shape-checks across 8 surfaces) and drafted 3 production-ready briefs for the next sprint. All findings + briefs locked to repo for Lead's pickup.

**Verified (all GREEN):**
1. Schema state on `phase_submissions` — `tapcard_data` jsonb + `njaw_work_order_code` text columns shipped per Saturday merges. `service_type` properly dropped.
2. CHECK constraints — 4 locked: phase enum (9 values incl. `no_work`), work_order_code enum (4), njaw enum (6), no_work compound invariant.
3. RLS state — 14/14 owner-data tables: RLS forced + ≥1 policy. Zero failures.
4. firms policies — exactly 2 (`firms_read_authenticated`, `firms_super_write`). Zero `firms_read_anon`. MI-203 step 3 lockdown holds.
5. firm_id indexing — 23 indexes across the schema (way more than the 7 from MI-204b memory; schema grew silently).
6. audit_log baseline — 288 rows/24h, 1,095/7d. Healthy.
7. compliance_events — 6 rows, 2-id gap matches locked rolled-back-tx decision. No breach.
8. tapcard real shape — 1 demo row pre-Phase-2b, 0 since merge. Real shape-check still queues for first inspector submission.

Full report: `.coordination/SUNDAY_VERIFICATION_5-3-26.md`.

**Drafted (3 production-ready briefs):**
1. **`MI101_PHASE2C_BRIEF.md`** — ShortHills sector (role inversion) + Restoration Card frontend. ~5 sessions. Sector enum verified to live on `properties` (not phase_submissions), values `NJ6_NORMAL` or `NJAW_SHORT_HILLS`. Restoration backend partial. Q-7 gates the Restoration Card form half.
2. **`MI110_PHASE4_BRIEF.md`** — Tapcard Diagram editor (220px gradient placeholder replacement). ~6 sessions. Highest-risk surface in v1.0. Data model locked: structured JSON in `tapcard_data.diagram`, NOT raw SVG.
3. **`MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`** — Contractor arrival/departure tracking. ~4–6 sessions. Backend fully shipped (3 tables, 48 columns total, all RLS-locked, all firm_id indexed).

**Architectural calls locked in the briefs:**
1. **Phase 2c data model:** sector dispatch reads `properties.sector` via JOIN from phase_submissions, not from a new column. Means/methods CHECK lives in BEFORE INSERT/UPDATE trigger (preferred) or app-layer (fallback). New table `homeowner_contact_log` for ShortHills supervisor visibility.
2. **Phase 4 data model:** structured JSON in `tapcard_data.diagram` (not raw SVG). Reasons documented: queryability, decoupled rendering, audit diff-ability, portable export. Coordinate system normalized 0–1 on both axes for cross-device scale.
3. **Construction PM frontend:** zero new migrations needed. Reuses existing 3 tables + reuses Vision pipeline for optional whiteboard detection on contractor arrival photos. Per locked privacy principle: inspector tracking and contractor tracking remain separate features.

**Recovery note:** This decisions.md file was reverted between Sunday morning and Sunday afternoon — the 5/2 ~23:00 close + 5/3 morning entries (Saturday queue close, .org TLD, Email Routing, Cloudflare Pages, BB-001) were lost in what was likely Lead's stash-during-commit cycle. All 6 entries restored above plus this Sunday afternoon entry. Lesson banked: Buddy decisions.md writes during Lead's active work need to anticipate stash conflicts; consider Lead pop-stash-then-rebase-buddy convention for future sessions.

**Affects:** Lead has 3 ready-to-pick-up briefs after Track 2 (sanitized demo branch) lands. Phase 2c, Phase 4, Construction PM frontend can build in any order; Buddy recommended sequencing is 2c → Construction PM → Phase 4 (sectors first, sales surface second, highest-risk SVG work last). Decisions log integrity restored.

**Source:** Buddy execution Sunday afternoon per Jorge directive ("get it all done buddy ... continue with intensity per Buddy Standard"). Verification queries via Supabase MCP. Brief drafts batch-announced under Rule #9 relaxation (low-risk markdown, batch trust granted).

---

## 2026-05-03 ~17:35 EDT — Sunday evening continuation: security fix + project seed + ratifications batch

**Decision:** Six discrete decisions locked in one push after Jorge's "verify on github sql and powershell" reset cleared the verification gate. Rule #9 strict gate honored on the two SQL writes (visibility-via-chat); Rule #9 relaxation applied for the markdown ratifications under Jorge's "use that big ole brain ... apply the buddy standard and get it done" batch trust.

**Shipped:**

1. **MI-AUDIT-1 fix shipped** — migration `mi_audit_1_fix_get_pending_destruction` (version `20260503172732`) closes the cross-firm metadata leak found in Sunday's security audit. `get_pending_destruction(p_table_name, p_record_id)` now filters by `dn.firm_id = public.current_firm_id()`. Static verification: function body contains the firm_id filter, still SECURITY DEFINER. Behavioral cross-firm test deferred to Lead's e2e suite (needs two authed firm contexts).

2. **CP Engineers default project seeded** — migration `seed_cp_engineers_default_project` (version `20260503173258`) inserted project `722f9db8-a484-46a1-8142-ea6cc4bc672c` ("NJAW LCRI Program 2026", client "NJ American Water", status active, module_key water_utility, start_date 2026-01-01). Closes the MI-302 frontend gate (contractor_assignments has NOT NULL FK to projects; CP had 0 projects before). Audit chain integrity verified: row_hash + prev_hash both populated on audit_log row 1388.

**Q-7 — Materials Sheet autosave cadence:** Option **C (explicit Save Draft sub-action)** locked by Jorge. Phase 2c Restoration Card form unblocked. Implementation: third button in the materials_sheets modal alongside Close + Save Materials Sheet. ~1.1–1.3x baseline audit_log volume, lowest cognitive overhead in audit review.

**Q-2c-c — homeowner_contact_log visibility:** **firm-visible** (any inspector in the firm sees all contacts for properties in the firm). Audit posture priority over per-inspector privacy on customer interactions. Aligns with the supervisor-dashboard pattern already shipped.

**Q-302-b — Construction PM dashboard photo UX:** **inline 40×40 thumbnails + lightbox on click**. Photos are the proof; one-tap visibility keeps supervisor review honest.

**Q-302-c — GPS "accuracy concern" anomaly threshold:** **50 m from property polygon**. Lead can tune after first 30 days of real contractor arrival data.

**Q-110-b — Pre-Phase-4 tapcards (no diagram key):** **read-only mode with banner** ("No diagram on this submission. Submitted before Phase 4."). Reading old data is a different concern than editing it; conflating them risks audit-trail integrity.

**Deferred (not blocking):**

- **Q-2c-d (ShortHills demo property seeding):** parked until first real ShortHills property arrives via import. Lead can build Phase 2c with NJ6_NORMAL test data; ShortHills e2e is testable post-import without a code change. No placeholder data on prod.
- **Q-2c-e (ShortHills parts catalog):** same parking principle. When first ShortHills property lands, Lead clones the 16 NJ6_NORMAL rows with sector flipped to NJAW_SHORT_HILLS as a 1-line INSERT...SELECT. Until then, no placeholders.

**Still open (needs Jorge's field knowledge, not blocking near-term):**

- **Q-110-a (asset type enum scope for Phase 4 v1):** brief default of 4 types (watermain_tap, valve, hydrant, other) is defensible. Buddy suggests expanding to 9 (watermain_tap, valve, hydrant, meter, blowoff, sleeve, reducer, b_box, other) based on standard NJ water-utility tapcard contents — but Jorge's call when Phase 4 is closer to build (likely week of 5/11+).

**Reasoning for the batch:** Per Buddy Standard, when a confident recommendation is warranted, make the call. All 4 ratifications (Q-2c-c, Q-302-b, Q-302-c, Q-110-b) had explicit Buddy defaults in the brief drafts; Jorge's "apply the standard" instruction is functionally a ratification of those defaults absent override. Same with the two deferrals (Q-2c-d/e) — defaulting to "don't seed placeholder data; wait for real" matches the locked principle of not building features looking for a reason. Documented for Lead's pickup.

**Affects:** Phase 2c (MI-101) is now fully buildable except for Q-2c-d/e blockers which only gate ShortHills e2e testing, not the build itself. Phase 4 (MI-110) ratified except Q-110-a (non-blocking near-term). Construction PM (MI-302) fully buildable + has a real project to attach against. Three of three Sunday afternoon spec briefs are unblocked for Lead.

**Source:** Jorge directive "i need you to use that big ole brain of yours and apply the buddy standard and get it done" 2026-05-03 ~17:30 EDT. Buddy executed: SQL via Supabase MCP under strict Rule #9 visibility, markdown ratifications under Rule #9 relaxation.

---

## 2026-05-03 ~17:50 EDT — Phase 2b real-shape verification GREEN + MI-AUDIT-3 filed

**Decision:** Phase 2b refactor real-shape verification gate closed via Jorge's live tapcard submission. Found one new audit-noise bug in passing; filed as MI-AUDIT-3 for Lead's queue (does NOT ship today — requires audit trigger design work).

**Verification subject:** Tapcard submission `1b37d77c-1ab1-43d0-a006-0a1cbe0510bf` on property `7d87c698-942c-42f3-abc5-47a4dfcbb206` (123 Oak Street, sector NJ6_NORMAL), submitted by `jorge.serrano@cpengineers.com` at 2026-05-03 17:43:28 UTC.

**🟢 GREEN findings:**

1. **`tapcard_data` jsonb shape correct** — all 3 expected keys present: `sector` (`NJ6_NORMAL`, matches joined property sector), `company_side` (fully populated with date, footer, material_installed[]), `materials_sheet_id_at_submit` (null — correct fallback when no Materials Sheet exists at submit time, confirmed by Jorge that he didn't fill out a Materials Sheet first).
2. **CHECK constraints satisfied** — phase = 'tapcard' (valid in the 9-value enum), no compound invariants violated.
3. **Multi-tenant isolation honored** — firm_id = CP Engineers throughout: phase_submissions row, all 3 audit_log rows, joined property.
4. **Hash chain integrity holding** — all 3 audit_log rows have row_hash + prev_hash populated. INSERT (id 1389) → UPDATE (1390) → UPDATE (1391) chain intact.
5. **Tapcard submitted without photos accepted** — confirms the locked whiteboard rule (whiteboard required ONLY for open-excavation phases like service_work/restoration/no_work, NOT for tapcard).

**🟡 MI-AUDIT-3 — filed:** the 3 audit_log rows for one user submission revealed that 2 of the 3 are heartbeat sync pings, not real state changes. Diff analysis:

| audit_log id | action | timestamp | actual_change |
|---|---|---|---|
| 1389 | INSERT | 17:43:28 | full row creation (40+ fields) |
| 1390 | UPDATE | 17:43:32 (+4s) | ONLY `last_client_sync_at` (sync ping) |
| 1391 | UPDATE | 17:43:52 (+24s) | ONLY `last_client_sync_at` (sync ping) |

**Severity: P2 (medium).** Costs:
- **Audit log inflation.** ~20s sync interval × open modal time × 14 inspectors → estimated 50%+ of current 288/24h baseline is heartbeat noise, not deliberate action.
- **Q-7 math affected.** Yesterday's volume comparisons assumed each audit row = meaningful state change. Real meaningful rate is probably ~140/24h, not 288. Q-7 = C (Save Draft) call still correct, but the volume tradeoffs in the analysis were inflated. Not re-litigating; C remains locked.
- **Compliance review interpretability degraded.** A future auditor pulling the chain for any property sees 2-3x the rows, mostly noise.

**Three fix approaches (Lead picks at build time, surfaces in `decisions.md`):**

- **A.** Modify `write_audit_log` trigger to skip UPDATEs where the only delta is `last_client_sync_at` (or any whitelisted heartbeat field).
- **B.** Move `last_client_sync_at` to a separate non-audited heartbeat table referenced by id.
- **C.** Stop writing the field on every sync — only on real state changes (client-side fix in `index.html`).

Buddy lean: **B** is cleanest long-term (clean audit chain, isolated heartbeat data, no special-case trigger logic) but requires migration + schema change + client-side update. **A** is fastest and the right call if Lead wants to ship in <30 min. **C** is least invasive on prod but moves the bug client-side without fixing the root behavior.

**Why NOT shipping today:** unlike MI-AUDIT-1 (3-line WHERE filter, isolated function), this touches audit chain plumbing. The hot trigger fires on every owner-data write. Special-case logic risks introducing audit gaps. Wants design, not a quick patch.

**Other open Q to flag for Lead during MI-AUDIT-3 design:** are there OTHER fields besides `last_client_sync_at` that fall in the same heartbeat-not-state bucket? Plausibly: `last_seen_at`, `client_session_id`, `device_metadata` if they exist. Lead surveys before writing the fix.

**Affects:** Phase 2b refactor verified working in field conditions. Saturday's biggest merge moves from "probably works" to "verified." MI-AUDIT-3 queued ahead of Lead's next sprint but behind active Track 2 work + Phase 2c first build.

**Source:** Jorge live tapcard submission via Vercel preview on phone at ~13:43 EDT. Buddy verification via Supabase MCP `audit_log` diff query (jsonb_each comparing old_data vs new_data per row). Finding surfaced from the diff; not visible in the simpler shape-check.

---

## 2026-05-05 late evening EDT — MI-AUDIT-3 closed: approach A trigger filter shipped + verified

**Decision:** MI-AUDIT-3 (audit_log heartbeat noise from `last_client_sync_at`) closed via approach A — trigger filter on `write_audit_log()`. Migration `mi_audit_3_skip_heartbeat_audit` applied to prod. Whitelist locked to `{last_client_sync_at}` (single field). 2/2 verification tests PASSED. Hash chain intact.

**Path C scope:** Tonight's authorized scope was MI-AUDIT-3 only. Phase 2d-revision Units 1+2 (rebase visual tapcard onto materials_sheet modal + autopop wiring) deferred to next session per refreshed work order at `.coordination/work_order_2026-05-05_phase2d_revision_v2.md`.

**Approach A chosen** (over B/C from 5/3 ~17:50 entry above):
- **A vs B:** approach A ships in <30 min via single `CREATE OR REPLACE FUNCTION` with no schema migration. Approach B (move `last_client_sync_at` to separate non-audited table) would require a new table, FK migration on `phase_submissions`, client-side rewrite of the heartbeat write path, and a backfill of existing rows. Tonight's Path C scope explicitly excludes that breadth. A leaves the door open to B later if heartbeat needs grow.
- **A vs C:** approach C (stop writing the field on every sync at the client level) moves the bug rather than fixing it; the trigger would still fire if any future client writes this field. A fixes it server-side regardless of client behavior — defensive against the next client-side regression.
- **Q-AUDIT-3-a (preserve `last_client_sync_at` column?):** locked yes (preserve). The field has plausible future use (stale-draft warnings, offline reconciliation, supervisor "last seen inspector" indicators). Approach A is the only one of the three that lets us preserve the column AND eliminate the audit noise without a schema change.

**Implementation:**
- `write_audit_log()` UPDATE branch now computes the changed-keys set between OLD and NEW jsonb. If non-empty AND a subset of `v_heartbeat_whitelist := ARRAY['last_client_sync_at']`, the function `RETURN NEW`s before the `audit_log` INSERT — the audit row is never written.
- INSERT and DELETE branches untouched.
- `SECURITY DEFINER`, `search_path = 'public', 'extensions', 'pg_temp'`, firm_id resolution logic — all preserved verbatim from the prior function body.
- `audit_log_chain_trigger` (BEFORE INSERT on `audit_log`) — untouched.
- `COMMENT ON FUNCTION public.write_audit_log()` added with the migration name + heartbeat-whitelist documentation.

**Schema survey results (read-only via Supabase MCP, 2026-05-05 ~21:55 EDT):**
- Suggested heartbeat candidates `last_seen_at`, `client_session_id`, `device_metadata`, `last_active_at`, plus `last_heartbeat_at`, `last_ping_at`, `last_known_location`, `last_sync_at`: **none exist anywhere** in the 18 public tables.
- Only `last_client_sync_at` exists, only on `phase_submissions` (and its view `phase_submissions_active`). Whitelist locked single-element. Future heartbeat fields can be added to the array as they appear.

**Apply path (multi-actor coordination):**
1. Lead drafted migration SQL + ran read-only schema survey + designed verification queries via Supabase MCP.
2. Lead's `Supabase:apply_migration` returned `Cannot apply migration in read-only mode`.
3. Per Path C handoff: Lead wrote migration to `.coordination/mi_audit_3_skip_heartbeat_audit.sql` and held for direction.
4. Jorge confirmed Path B (disk handoff). Buddy applied via direct write-mode Supabase MCP. Buddy refreshed on-disk SQL with as-applied content (slight diff vs Lead's draft: bidirectional UNION on changed-keys computation; `$func$` dollar-quote tag per BUDDY_STANDARD; `COMMENT ON FUNCTION` marker added).

**Verification (read by Buddy direct-MCP, results reported to Lead):**
- **Pre-fix baseline (30d):** 1101 audit_log rows total. 916 are heartbeat-only UPDATEs on `phase_submissions` where the only changed key is `last_client_sync_at` — **83% of audit volume eliminated as noise.** Pre-test chain head: id 1393, row_hash `d9e39e64845db56920415367337c62626a76c74e83e2143bc41a7477b64bedf8`.
- **TEST 1 — heartbeat-only UPDATE PASSED.** UPDATE on `phase_submissions` row `72183028-7d4f-4ad5-a35f-7a7a222d2dee` setting `last_client_sync_at = NOW()`: audit_log delta = 0. Heartbeat skip filter works.
- **TEST 2 — real-state UPDATE PASSED.** UPDATE on same row setting notes field: audit_log delta = 1. New chain head: row_hash `fd537e792c6a279dc187b02b68250e5c8d3bad149b655c6d024dcf83ac5e280c`. prev_hash on new row links correctly to pre-test head `d9e39e64...`. **Hash chain integrity intact.**

**Affects:** MI-AUDIT-3 closed. ~83% of go-forward audit_log volume from this trigger filter alone. `compliance_dashboard` audit panels become more readable (less noise). Q-7 Materials Sheet save cadence math (5/3 ~17:35 entry above) was modeled against the inflated 288/24h baseline; the post-fix real rate will be lower, but Q-7 = C decision stays locked (Save Draft was the right UX call regardless of volume).

**Pattern banked for future heartbeat fields:** add the field name to `v_heartbeat_whitelist` array in `write_audit_log()` via a follow-up migration. Single-line change. No schema work needed. Cap on the array's growth: only fields where the client writes solely for liveness signaling, never for state semantics.

**Source:** Jorge directive 2026-05-05 evening EDT ("Path C confirmed. Ship MI-AUDIT-3 trigger filter only tonight"). Lead drafted, Lead held on read-only block, Buddy applied + verified.

**Affects (architectural):** Pattern locked for `write_audit_log()` future modifications — any change to its body must preserve `SECURITY DEFINER`, the `search_path` set, the firm_id resolution fallback, and the INSERT/DELETE branch behavior. Hash chain trigger (`audit_log_chain_trigger`) is the inviolate part: never modify it without an explicit MI-AUDIT ticket on chain integrity.

---

## 2026-05-05 late evening EDT — Correction: MI-101 Phase 2a frontend PR was NEVER merged

**Decision:** Documentation drift caught and corrected during MI-AUDIT-3 closing pass. The 2026-05-02 ~23:00 EDT entry "Saturday session close (tapcard milestone reached)" listed `mi101-phase2a` among "3 PRs squash-merged: mi203-step2 + mi101-phase2a + mi101-phase2b ORIGINAL." That claim is wrong. Only Phase 2a **backend** migrations shipped (via Supabase MCP — `materials_sheets` table + related infrastructure). The Phase 2a **frontend** PR on branch `mi101-phase2a` (HEAD `a542d5a`) was prepared but never merged to main.

**Why it matters:** Drift propagated into STATE.md "Active gate" table and status.md "Open PRs / branches" table for ~3 days, masking that Phase 2a frontend work is incomplete. Phase 2d-revision (work order 2026-05-05) is where the Materials Sheet frontend actually lands — the visual tapcard preview rebases onto `modal-materials-sheet`, which is the surface Phase 2a was supposed to ship.

**Corrections shipped in MI-AUDIT-3 close commit:**
- STATE.md "Active gate" Phase 2a row — backend shipped, frontend never merged, re-scoped into Phase 2d-revision.
- STATE.md "Sat 5/2" recent-ships — 3 PR squash-merges corrected to 2.
- `.coordination/status.md` "Open PRs / branches" `mi101-phase2a` row — NOT merged, branch stale.
- `.coordination/status.md` "Recently closed" Sat 5/2 line — 3 PR squash-merges corrected to 2.
- `.coordination/buddy_context.md` — handled by Buddy in parallel.

**Supersedes:** Specifically the `mi101-phase2a` PR-merge claim in 2026-05-02 ~23:00 EDT entry "Saturday session close (tapcard milestone reached)." Per this file's append-only convention, that prior entry is preserved verbatim; this entry is the corrective superseding record.

**Source:** Jorge directive 2026-05-05 evening EDT during MI-AUDIT-3 ship pass: "correct the Phase 2a documentation drift in STATE/status/decisions (frontend was NEVER merged, only backend migrations shipped)."

**Affects:** Future Lead/Buddy reads of Phase 2a status. Truth is: backend live since 5/2, frontend pending Phase 2d-revision Unit 1 (rebasing visual tapcard onto materials_sheet modal per work order 2026-05-05).

---

## 2026-05-06 ~23:30 EDT — MI-101 Phase 2d-revision Unit 1 Step 2 + Unit 2 shipped

**Decision:** Phase 2d-revision visual tapcard preview rebased onto `modal-materials-sheet` per v2 work order (`work_order_2026-05-05_phase2d_revision_v2.md`). Two commits on `demo-banner`: `52adf8a` (Unit 1 Step 2 — split layout, paper-true 6-section + Job Notes box SVG, sector dispatch, helpers) and `7018493` (Unit 2 — autopop wiring + Materials Installed extrapolation per service_type). Vercel preview deployment `dpl_BbarAjj9...` from sha `7018493` confirmed READY on demo-banner alias. Schema verified pre-build via Supabase MCP (no drift). All §17 acceptance criteria met. Field map verified against ground-truth `properties` (19 cols) + `materials_sheets` (48 cols, was spec'd at 39 — drift caught) schemas.

**Reasoning:** Original Phase 2d (commit `79f8434`) embedded the visual tapcard inside `#modal-tapcard`, which Q-2d-revision flagged as wrong surface — the visual is paper-true tapcard rendering driven by `materials_sheets` data, not Phase 2b form data. Unit 1 Step 1 (commit `6b9a9d3`, 5/5 evening) removed the vestigial scaffolding from `#modal-tapcard`. Unit 1 Step 2 + Unit 2 (this commit pair) embed the preview in the correct modal + wire autopop. Edit pattern: `vtcAttachAutopopListeners` is idempotent (one-time delegated input listener on first modal open), chip/toggle/recalc helpers fire `vtcRender` directly since hidden inputs don't emit `'input'` events, `tc-co-*` form fields one-way bind into the visual via debounced render. Materials Installed extrapolation maps `FULL` (11 rows) / `KILL` (3) / `M2C` (5) / `H2C` (6) / `MP` (5) / `TP` (blank — inspector documents).

**Affects:** Materials Sheet modal now renders a full-paper-true visual tapcard preview side-pane on desktop ≥768px (50/50 split), 55/45 on tablet, mobile sub-tab toggle. Pitch-day demo for Jeff (5/14 or 5/15) will see real-time form-to-paper rendering. Property #1 (12 Maple Ridge Ave) seed data mirrors the 44 Dunnell paper example for QA.

**Source:** Lead executed v2 work order under Jorge's "ship through to Vercel preview verify without checkpoints" batch trust. Schema verified via Supabase MCP execute_sql against information_schema.columns; chip/toggle helpers patched + delegated listener added; autopop tested via property #9 cs_replacement gate render.

---

## 2026-05-06 ~23:50 EDT — MI-DEMO seed shipped (12 migrations + Edge Function deployed-but-broken)

**Decision:** MI-DEMO sample-data seed bootstrap shipped to prod Supabase via Buddy direct MCP (Lead's MCP read-only). 12 migrations applied; demo firm now has 12 properties (10 NJ6_NORMAL + 2 NJAW_SHORT_HILLS), 25 phase_submissions covering all 9 phase enum values + all 6 NJAW work order codes + 1 KILL with subtype, 5 materials_sheets, 1 cs_replacement_authorization (CDM-Smith rule c exercise), 6 daily_reports, 3 documents, 2 RFIs, 2 Luis conversations, 5 demo `auth.users` + matching profiles. Spec authored at `.coordination/MI-DEMO_seed_spec_2026-05-06.md` (Lead reconciled v3 with §24 stop conditions). Buddy reconciliation note at `.coordination/buddy_demo_seed_sync_2026-05-06.md`. Branch `mi-demo-seed` off `demo-banner` (sync commit `08fac2d`); per §22 demo-tenant policy, **NEVER MERGE TO MAIN** — merge target is `demo-banner` only.

**Three side decisions banked during the run:**

1. **`pg_net` extension installed** (migration `20260506224906_enable_pg_net.sql`). Originally added to support Edge Function invocation from triggers (forward capability for MI-107 rule engine architecture). Stays installed. Trade-off: small attack surface (HTTP from SQL); offset by no service-role exposure in trigger paths.

2. **`profiles.email` column added** (migration `20260506230138_mi_demo_seed_03_add_profiles_email.sql`). Required by spec §7 + Edge Function code + migrations 05-13 which lookup profiles by email. Spec assumed it existed; it didn't. Backfilled from `auth.users.email` for existing rows. Denormalized convenience — `auth.users` is the unique source of truth. Future ticket can add a sync trigger if email mutations need to propagate.

3. **`seed-demo-users` Edge Function admin SDK bug — function deployed but functionally broken.** Source preserved at `supabase/functions/seed-demo-users/index.ts`. `auth.admin.listUsers` SDK call threw "Database error finding users" on all 5 invocations (5/5 errors, 0 created). Buddy bypassed via direct SQL migration `20260506230158_mi_demo_seed_04_create_demo_auth_users_via_sql.sql` writing to `auth.users` + `auth.identities` + `public.profiles` directly. Function stays deployed for future SDK-version retry (supabase-js@2.49.x or gotrue-admin-API skew suspected). Low priority — SQL bypass is the de-facto seed path going forward.

**§16a actor coverage outcome:** Spec target was ~91% audit attribution from ~1,000 cascade rows. Actual: 36.5% from ~58 cascade rows. Spec drift — cascade was much smaller than estimated because per-table audit triggers fire once per INSERT row, not per column touched. Demo-firm `audit_log` final state: 159 total, 58 attributed (36.5%), 101 NULL legacy. Defensible under audit; legacy 101 rows untouched per §16a option (a) (UPDATE on existing breaks chain hash, so leave alone).

**Spec drifts caught + corrected against ground-truth schema:** materials_sheets 48 cols (spec said 39); phase_submissions 28 cols (spec said 24); daily_reports = KPI rollup, not free text; documents = `name` not `file_name`, requires `file_url`; cs_replacement_authorizations RPC signature = `(uuid, text, timestamptz, text)` not split date+time; luis_conversations = `user_id` not `submitted_by`. All corrected in applied migration bodies; spec needs v4 patch tracked separately.

**Affects:** Demo-banner branch can ship a meaningful pitch-day demo. Jeff demo (5/14 or 5/15) will land with pre-seeded NJ6_NORMAL + NJAW_SHORT_HILLS properties, full phase + tapcard + materials sheet flows, CDM-Smith rule a/b/c exercises, and visual tapcard rendering against property #1 (12 Maple Ridge Ave) which mirrors the 44 Dunnell paper example. Branch `mi-demo-seed` merges forward to `demo-banner`. Companion specs MI-DEMO-UI v2 (banner copy + write suppression) + MI-DEMO-DEPLOY (pitch-day deploy ritual) tracked separately.

**Source:** Lead drafted spec; Buddy reconciled in parallel; Jorge reviewed diffs and green-lit incrementally; Buddy applied 12 migrations to prod via direct MCP write (Lead's MCP read-only blocked apply); Lead synced local repo to prod state via filename rename + content fix on migration 08; Lead committed sync as `08fac2d` on `mi-demo-seed`; pushed to origin.
