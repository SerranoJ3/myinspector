# MyInspector — Current State

> **Purpose:** Single source of truth for session continuity. Read at session open. Update at session close.
> **CLAUDE.md** holds locked principles. **STATE.md** holds live state.
> Conflict with Claude memory: this file wins.

**Last updated:** May 5, 2026 ~late evening EDT (post Phase 2a → main merge + Phase 2d-revision Unit 1 Step 1 ship)
**Updated by:** Buddy direct via Filesystem MCP (CC's Update tool was hitting stale-state mismatches; Buddy wrote fresh from current file state to unblock session close)

---

## Project header
- **Repo:** SerranoJ3/myinspector (main, Vercel auto-deploy)
- **Live URL:** myinspector-psi.vercel.app
- **Production domain (planned):** myinspector.io
- **Supabase project:** `myinspector` (ref `wryitfoletwskkdqqwcw`, us-east-2/Ohio)
- **Local clone:** `C:\Users\jserr_0phql\Documents\Serrano Group LLC\Code\myinspector`

---

## Active gate: v0.1 Compliance Foundation

**~67% of v1.0 scope complete by session count** (Mon 5/5 close, +5% from session start tonight: Phase 2a frontend finally merged to main, MI-AUDIT-3 trigger filter shipped, Phase 2c lean scaffold + Phase 2d original on demo-banner, Phase 2d-revision Unit 1 Step 1 vestigial cleanup shipped).

| Ticket | Status | Notes |
|---|---|---|
| MI-200 RLS forced + ≥1 policy per table | Closed 4/27 | — |
| MI-201 compliance_dashboard `security_invoker` fix | Closed 5/1 | Banked CLAUDE.md principle #7 |
| MI-202 Audit log + 5-layer immutability stack | Active build | Plumbing live; chain integrity verified Sunday + tonight (post MI-AUDIT-3) |
| MI-100 Sector toggle | Closed 5/2 | PR #5 `0327abd` |
| MI-108 No-Work Submission Workflow | Closed 5/2 | PR #4 `8a971eb`, backend migration `mi108_no_work_submission_workflow` |
| MI-109 CS Replacement Authorization Gate | Closed 5/2 | PR #3 `e76fac2`, SQL coverage 17/17 |
| MI-109.5 Manual e2e UI walk on isolated staging | Queued | Gated on isolated test tenant (SG-001 Node 2/3 unlock) |
| MI-203 step 2 (signup → `lookup_firm_by_code` RPC) | Closed Sat | PR `mi203-step2` merged |
| MI-203 step 3 (DROP POLICY `firms_read_anon`) | Closed Sun ~08:55 | Migration `mi203_step3_drop_firms_read_anon`, no main commit (MCP-only) |
| MI-204 / MI-204b firm_id indexing | Closed Sat | 23 firm_id indexes total across schema |
| MI-101 Phase 1a-1e (backend) | Closed | All 5 sub-phases shipped via prod migrations |
| **MI-101 Phase 2a (Materials Sheet)** | **Closed Mon 5/5 ~late evening** | Backend migrations live since 5/2 (materials_sheets infra). Frontend merged tonight via Path C cherry-pick: temp branch `mi101-phase2a-merge` cherry-picked `04fd6b1` + `a542d5a` onto current main, hand-resolved CSS + HTML modal conflicts, Vercel-preview verified by Jorge, then squash-merged to main as commit `9c446e7`. Production gap closed: inspectors can now create materials_sheets via UI. |
| MI-101 Phase 2b refactor (Tapcard, 2 tabs, 41 fields) | Closed Sun 0:52 | `4d70901`. Real-shape verified Sun 17:50 (Jorge live submission) |
| MI-101 Phase 2c lean scaffold (tabs + visual preview container) | Closed Mon 5/5 | Commit `91f2af4` on `demo-banner`. No migrations. |
| MI-101 Phase 2c-form pickup (Restoration form) | Queued — work order on disk | Work order `.coordination/work_order_phase2c_form_restoration.md` (Buddy, 5/5 evening). Q-7=C Save Draft locked, Q-2c-c/d/e ratifications, photo upload + sector dispatch + whiteboard validation specced. ~3 sessions. |
| MI-101 Phase 2d (Visual Tapcard Preview, original placement) | Shipped Mon 5/5 on `demo-banner` (`79f8434`); superseded by Phase 2d-revision | Original placement on `#modal-tapcard`. Vestigial scaffolding removed in Phase 2d-revision Unit 1 Step 1 (commit `6b9a9d3`). VTC config + helpers preserved for Step 2 reuse on `modal-materials-sheet`. |
| **MI-101 Phase 2d-revision Unit 1 Step 1 (vestigial removal)** | **Closed Mon 5/5 ~late evening** | Commit `6b9a9d3` on `demo-banner`. Removed `vtc-mobile-tabs` + `tc-mid` wrapper + `visual-tapcard-preview-container` from `#modal-tapcard`; removed `vtcInitOnOpen` / `vtcReset` / `vtcAttachListeners` / `vtcMobileTab` functions + call sites + `currentTapcard.property = prop` stash. Preserved `VTC_FIELDS` config + `vtcRender` + `vtcDebouncedRender` + `vtcVal` / `vtcEsc` / `vtcWrap` helpers + CSS rules. |
| **MI-101 Phase 2d-revision Unit 1 Step 2 + Unit 2** | **Queued — next session** | Work order `.coordination/work_order_2026-05-05_phase2d_revision_v2.md`. Step 2 (sub-steps C-G): embed visual-tapcard-preview container in `modal-materials-sheet` (50/50 desktop split + 55/45 tablet + mobile sub-tab toggle), rewrite `VTC_FIELDS` against materials_sheets schema per v2 field map, rewrite `vtcRender` for paper-true NJAW Service Line Renewal Company Side layout (6 sections + Job Notes box), wire static render from `openMaterialsSheetForProperty`, sector dispatch (NJ6_NORMAL renders, ShortHills shows placeholder). ~60-90 min focused build. Then Unit 2: autopop wiring + Materials Installed extrapolation per `service_type` (FULL/KILL/M2C/H2C/TP mappings locked in work order). |
| MI-110 Phase 4 (Tapcard Diagram editor) | Brief drafted | Highest-risk surface in v1.0 (touch events on iPad). ~6 sessions. |
| MI-302 Construction PM frontend | Work order on disk (Buddy 5/5 evening) | Backend fully shipped. CP default project seeded Sun (`722f9db8...`). Q-302-b/c/d/e ratified. Patent-claim module per Bill. ~4 sessions. |
| MI-luis-1 Luis AI v1 (Water Utility) | Work order on disk (Buddy 5/5 evening) | `luis_conversations` table shipped. Haiku 4.5 via Anthropic API + `luis-ask` Edge Function + brand-palette chat panel + citation chips. Demo-target for Jeff (5/14-5/15). ~2 sessions. |
| MI-401 GIS List Tab | Work order on disk | Paper-replacement workflow. ~3 sessions. |
| MI-402 Towns/Contractors reference | Work order on disk | Smallest, ~30 min backend + optional frontend. |
| MI-403 Field Guides Tab | Work order on disk | Fittings reference library. ~2 sessions. |
| MI-404 Herald Tab | Work order on disk | Jeff is in August 2025 issue (Schmitz Tank, NICET cert mention). Demo strategic. ~2 sessions. |
| Module 2 Wastewater/Sewer v0 backend | Work order on disk (Buddy 5/5 evening) | NASSCO PACP defect coding, manhole reference, CCTV defect observations. 4 migrations. Foundational for module #2 of 7. Buddy can apply directly via Supabase MCP if Lead delegates. ~1 session. |
| MI-AUDIT-1 (firm_id filter on `get_pending_destruction`) | Closed Sun ~17:35 | Migration `mi_audit_1_fix_get_pending_destruction` v `20260503172732`. Live function body contains `AND dn.firm_id = public.current_firm_id()` |
| MI-AUDIT-2 (super_admin firm-crossing posture) | Informational, parked | Trigger to act: second firm beyond CP Engineers |
| MI-AUDIT-3 (audit_log heartbeat noise — `last_client_sync_at`) | **Closed Mon 5/5 ~evening** | Migration `mi_audit_3_skip_heartbeat_audit` (approach A — trigger filter). Whitelist: `last_client_sync_at`. Pre-fix baseline 1101 rows / 916 heartbeat-only / 83% noise. TEST 1 heartbeat-skip PASSED (delta=0); TEST 2 real-state PASSED (delta=1). Chain intact: head `fd537e79...` linked to prior head `d9e39e64...`. |
| Soft-delete view rebuild (CLAUDE.md principle #7) | Closed Sat | Migration `soft_delete_views_security_invoker_rebuild` |
| `legal_holds` workflow | Backend exists, no UI | Table indexed + RLS-locked. No active ticket. |
| Demo tenant + `firm_safe_to_display` | Closed Sat | Migrations `firms_safe_to_display_flag` + `demo_tenant_seed_data_v3` + `demo_inspector_binding` |

---

## Tapcard cluster (~37 sessions total per 4/30/26 refinement)

| Ticket | What | Sessions | Status |
|---|---|---|---|
| MI-100 | Sector toggle (NJ6_NORMAL / NJAW_SHORT_HILLS) | 3 | Closed |
| MI-101 | Normal Tapcard 3-page (CDM-Smith rules b, d, e) | 6 | Phases 1a-2b shipped; 2a frontend merged 5/5 late evening; 2c lean scaffolded; 2d shipped 5/5 (re-scoped to Phase 2d-revision); 2d-revision Unit 1 Step 1 vestigial cleanup shipped 5/5; Step 2 + Unit 2 + 2c-form queued |
| MI-101.5 | Dual-mode entry (Type fields \| Photo notebook + Vision parse) | 4 | Queued post-Phase-4 |
| MI-102 | ShortHills (Company + Restoration) | 5 | Placeholder tab tonight (Phase 2c); build queued post master-parts-list |
| MI-103 | Vision parse refs DONE → build spec | 0 | Blocked on 3 reference images |
| MI-104 | Admin override | 4 | Queued |
| MI-105 | ShortHills customer-side | DEFERRED | Out of v1 |
| MI-107 | KILL subtypes + tiered rule engine | 5 | Queued |

**Two sectors:** `NJ6_NORMAL`, `NJAW_SHORT_HILLS`. **Sector lives on `properties` (not `phase_submissions`)** — verified Sunday. UI dispatch reads `properties.sector` via JOIN at modal load.

---

## Schema state surprises (banked Sunday, verified Sunday + tonight)

- **23 firm_id indexes** across schema. Memory said 7. Schema grew silently as compliance + Construction PM tables shipped.
- **Construction PM backend fully shipped:** `contractor_arrival_log` (16 cols), `contractor_departure_log` (17 cols, FK to arrival_log), `contractor_assignments` (15 cols). All RLS-forced + firm_id indexed.
- **Restoration backend partial:** `restoration_grid_entries` exists, RLS-locked, sector enum CHECK present.
- **`legal_holds`, `destruction_notices`, `photo_rescue`, `supervisor_alerts`, `projects`** all exist + indexed + RLS-locked. Not in active v0.1 UI; future tickets can build on them without new migrations.
- **`phase` enum has 9 values** (not 8 — memory was stale). MI-108's `no_work` is included. Locked.
- **Sector enum on `properties` (not `phase_submissions`).** Same CHECK on `restoration_grid_entries` and `parts_catalogs`.
- **`inspections` table exists** with firm_id + RLS — not currently used; older surface or higher-level abstraction over `phase_submissions`. Worth a row-count + column-shape check next audit cycle.
- **Phase 2b tapcard form field surface** — documented in `.coordination/PHASE2B_TAPCARD_FIELDS_REFERENCE.md` (Buddy, 5/5 evening). Ground-truth for MI-101 Phase 2d field map (`VTC_FIELDS` in index.html).
- **`last_client_sync_at` is the only heartbeat field in schema** — survey 5/5 evening confirmed no `last_seen_at`, `client_session_id`, `device_metadata`, `last_active_at`, `last_heartbeat_at`, `last_ping_at`, `last_known_location`, `last_sync_at` anywhere across 18 public tables. MI-AUDIT-3 whitelist locked to single field.
- **`properties` schema verified 5/5 ~21:25 EDT via Supabase MCP `list_tables`:** 19 columns. NO `address_number`, `address_street`, `cross_street`, `lot` (separate), `block` (separate), `apt_bldg`, `owner_name`, `county`. Address is single string; lot+block concatenated.
- **`materials_sheets` schema verified 5/5 ~21:25 EDT:** 39 columns, FLAT NJAW/customer old/new (no `service_materials_grid` jsonb). Inspector-recognizable column names (`foreman_name` not `foreman`, `temperature_f` not `temp_f`, `sky_condition` enum, `curb_box_location` enum, `service_side` enum).

---

## Audit posture (post Sunday verification + security audit + Mon 5/5 ships)

🟢 **Multi-tenant isolation: GREEN.** 22 tables with firm_id, all RLS-forced + ≥1 policy. 3 tables without firm_id are global by design (`firms`, `modules`, `parts_catalogs`).

🟢 **Audit chain primitives DEFINER-gated correctly.** `compute_audit_hash`, `write_audit_log`, `audit_log_chain_trigger`, `record_compliance_event` all reference firm_id or auth.uid and are scoped.

🟢 **26 SECURITY DEFINER functions audited.** 21 OK with explicit firm_id, 2 OK with auth.uid + verified scope, 1 super_admin-by-design (`release_legal_hold` → MI-AUDIT-2 informational), 1 fix shipped (`get_pending_destruction` → MI-AUDIT-1 closed Sun).

🟢 **MI-AUDIT-3 closed.** Migration `mi_audit_3_skip_heartbeat_audit` shipped Mon 5/5 evening (approach A trigger filter; whitelist: `last_client_sync_at`). 83% pre-fix noise eliminated (916 of 1101 30d rows). Chain intact post-migration: head `fd537e79...` linked to prior head `d9e39e64...`. Verified via 2/2 tests (heartbeat-skip = 0 audit rows; real-state = 1 audit row).

🟢 **Phase 2b real-shape verified Sunday 17:50.** Jorge live tapcard submission — tapcard_data jsonb has correct 3 keys; CHECK constraints satisfied; multi-tenant isolation honored; hash chain intact across the INSERT + 2 UPDATEs.

🟢 **Phase 2a frontend merged + production gap closed Mon 5/5 ~late evening.** Inspectors can now create `materials_sheets` rows via UI (3 existing rows pre-merge came from preview-deployment testing).

🟢 **Phase 2d-revision Unit 1 Step 1 is presentational only.** Pure DOM/JS removal from `#modal-tapcard`. No new DB writes, no new RPCs, no new tables. Audit posture unchanged.

---

## Resolved questions

- **Q-2 (Vercel preview verification):** all 3 Saturday PRs verified post-merge.
- **Q-7 (Materials Sheet autosave cadence):** **Option C — explicit Save Draft sub-action.** Phase 2c-form pickup ships with third button.
- **Q-2c-c (homeowner_contact_log visibility):** firm-visible (not per-inspector).
- **Q-2c-d (Restoration multiple entries per type):** YES — append, not overwrite. Each entry timestamped.
- **Q-2c-e (recently_paved_road flag UX):** boolean toggle surfaces special-spec banner.
- **Q-302-b (Construction PM module navigation):** new top-level "Construction PM" tab, role-gated.
- **Q-302-c (Contractor selection at arrival):** assignment-based primary, on-the-fly create fallback for super_admin/supervisor.
- **Q-302-d (Photo at arrival/departure):** REQUIRED at arrival, optional at departure.
- **Q-302-e (GPS accuracy threshold):** log all, warn inline if >50m.
- **Q-110-b (pre-Phase-4 tapcards):** read-only mode with banner.
- **Q-2d-a (Visual Tapcard font):** monospace (`'JetBrains Mono'` primary, system mono fallback).
- **Q-2d-b (print-to-PDF):** deferred to v2. Trigger to un-defer: first compliance officer asks at demo/pilot.
- **Q-2d-c (empty-field treatment):** thin gray underline (`#cfd6df`, 1px) at field anchor.
- **Q-2d-revision-a (Diagram area in v1):** placeholder text per Buddy work order 2026-05-05; full dynamic diagram lands with MI-110 Phase 4.
- **Q-2d-revision-b (Materials Installed autopop):** extrapolation from `materials_sheets.service_type` per Buddy work order 2026-05-05; mapping locked for FULL/KILL/M2C/H2C/TP.
- **Q-AUDIT-3-a (`last_client_sync_at` future use):** preserve column; fix via approach A (trigger filter). Closed Mon 5/5.
- **Q-luis-a (Luis v1 model):** Haiku 4.5 via Anthropic API.
- **Q-luis-b (Luis knowledge base):** locked field rules + NJAW-specific docs as RAG corpus.
- **Q-luis-c (chat surface placement):** floating "Ask Luis" FAB bottom-right + slide-in chat panel.
- **Q-luis-d (citations):** every answer includes sources array, UI surfaces as chips.
- **Q-luis-e (escalation):** "I'm not certain" + verify-with on safety/regulatory queries.

## Deferred / parked

- **Q-2c-d-shorthills (ShortHills demo properties):** 0 ShortHills properties on prod. Parked until first real ShortHills import.
- **Q-2c-e-shorthills (ShortHills parts catalog):** 16 NJ6_NORMAL rows only. Same parking principle.
- **Q-110-a (Phase 4 asset type enum scope):** brief default 4 types, Buddy suggests 9. Jorge's call when Phase 4 build is closer.

---

## Recent ships (chronological — last 4 days)

**Sat 5/2:**
- 4 migrations via Supabase MCP: `parts_catalogs_placeholder_seed`, `demo_inspector_binding`, `cs_replacement_auth_immutability_revoke_service_role`, `mi204b_firm_id_indexes`
- 2 PR squash-merges to main: `mi203-step2`, `mi101-phase2b` (original). `mi101-phase2a` was prepared but never merged Saturday — only Phase 2a backend migrations shipped via Supabase MCP. (Drift caught + corrected 2026-05-05; frontend merged Mon 5/5 late evening per Path C.)
- BB-001 (AR auto-fill tapcard) parked, trigger = first paying non-CP customer

**Sun 5/3 morning:**
- `mi101-phase2b-refactor` PR merged 0:52 as `4d70901`
- MI-203 step 3 shipped ~08:55 via Supabase MCP migration `mi203_step3_drop_firms_read_anon`
- `serranogroup.org` registered + Email Routing live + marketing site on Cloudflare Pages

**Sun 5/3 afternoon:**
- Full prod verification across 8 surfaces (`SUNDAY_VERIFICATION_5-3-26.md`) — all GREEN
- Security audit (`SUNDAY_SECURITY_AUDIT_5-3-26.md`): 1 finding → MI-AUDIT-1
- 3 production-ready briefs drafted: `MI101_PHASE2C_BRIEF.md`, `MI110_PHASE4_BRIEF.md`, `MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`

**Sun 5/3 evening:**
- MI-AUDIT-1 shipped via Supabase MCP migration `mi_audit_1_fix_get_pending_destruction`
- CP Engineers default project seeded — closes MI-302 frontend FK gate
- 6 Q ratifications (Q-7=C, Q-2c-c, Q-302-b/c, Q-110-b + 2 deferrals Q-2c-d/e)
- Phase 2b real-shape verified GREEN via Jorge live submission
- MI-AUDIT-3 filed (audit_log heartbeat noise from `last_client_sync_at`)

**Mon 5/5 evening (early):**
- STATE.md 3-day reconciliation refresh (commit `91f2af4`)
- Phase 2c lean scaffold shipped: Property Detail tab strip (Overview / Restoration / ShortHills) + empty `<div id="visual-tapcard-preview-container">` in `#modal-tapcard` (commit `91f2af4`)
- Phase 2d Visual Tapcard Preview shipped on `demo-banner` (commit `79f8434`): SVG mirror of `#modal-tapcard` form state for NJ6_NORMAL only; Q-2d-a/b/c ratified (mono / no PDF / gray underline); Acceptance #5 superseded by Phase 2d-revision Unit 1
- Buddy parallel-track refresh on `buddy_context.md` + `questions.md` Q-2d resolutions (mid-session)
- Buddy created `.coordination/PHASE2B_TAPCARD_FIELDS_REFERENCE.md` as ground-truth for the Phase 2d field map
- Demo HTML for Jeff sanitized + zipped (`myinspector-demo.html` + `myinspector-demo.zip`)
- 3 Sunday docs cherry-picked to main (`e0b00c6`, `2183e84`, `99692d0`)

**Mon 5/5 late evening (close batch):**
- **MI-AUDIT-3 heartbeat trigger filter shipped** via Supabase MCP migration `mi_audit_3_skip_heartbeat_audit` (Buddy applied via write-mode MCP after Lead's MCP hit read-only block; Lead drafted SQL fallback to disk). Pre-fix 916 of 1101 30d audit rows were heartbeat noise (83%). Post-fix verified: heartbeat-only UPDATE = 0 new audit rows; real-state UPDATE = 1 new audit row; chain intact (head `fd537e79...` linked to prior head `d9e39e64...`).
- **Phase 2a doc-drift corrected** in STATE/status/decisions: `mi101-phase2a` frontend PR was NEVER merged Saturday — only backend migrations shipped via Supabase MCP. Drift had propagated through STATE/status for ~3 days.
- **MI-AUDIT-3 close commit** `f99b6f0` on `demo-banner`: SQL file + verification SQL file + STATE/status/decisions corrections + v2 work order ratification.
- **Phase 2a → main merge SHIPPED via Path C** as commit `9c446e7` on main: cherry-pick of `04fd6b1` (Phase 2a frontend) + `a542d5a` (Phase 2a polish) onto current main on temp branch `mi101-phase2a-merge`, hand-resolved CSS + HTML modal conflicts, Vercel-preview verified by Jorge, then squash-merged to main. main → demo-banner merged forward as commit `553dea2` (4 conflicts: `.coordination/buddy_context.md` + `decisions.md` + `questions.md` resolved with `--ours` to keep demo-banner's tonight-state; `index.html` resolved with Phase 2c reconciliation — `ms-bar` + `pd-ms-history-section` moved INSIDE `pd-page-overview`). **Production gap closed: inspectors can now create materials_sheets via UI on prod main.**
- **Phase 2d-revision Unit 1 Step 1 SHIPPED** as commit `6b9a9d3` on `demo-banner`: vestigial removal from `#modal-tapcard` (sub-steps A+B per CC's carve recommendation; sub-steps C-G queued for Step 2 next session). Removed `vtc-mobile-tabs` + `tc-mid` wrapper + `visual-tapcard-preview-container` div + `vtcInitOnOpen` / `vtcReset` / `vtcAttachListeners` / `vtcMobileTab` functions + call sites + `currentTapcard.property = prop` stash. Preserved `VTC_FIELDS` config + `vtcRender` + `vtcDebouncedRender` + `vtcVal` / `vtcEsc` / `vtcWrap` helpers + CSS rules for Step 2 reuse.
- **4 new work orders drafted to disk** (Buddy parallel-track 45-min push): `work_order_phase2c_form_restoration.md`, `work_order_MI302_construction_pm_frontend.md`, `work_order_module2_wastewater_sewer_v0.md`, `work_order_luis_v1_water_utility.md`.
- **3 custom skills written** to `.coordination/skills/`: `verify-ground-truth-before-drafting`, `serrano-group-brand`, `myinspector-domain-rules`.
- **Strategic docs:** `future_proofing_tools_2026-05-05.md` (5 CC plugins to install + 3 custom skills + MCP recommendations); `serrano_group_homepage_copy.md` (pre-staged copy for serranogroup.org); `progress_report_2026-05-05.md` (comprehensive accounting).

---

## Open investigations / blockers

- **3 reference images** for MI-100 vision parsing — Jorge to provide. Still blocked.
- **Whiteboard sample photos** for false-positive prompt tuning — Jorge to provide. Still blocked.
- **Isolated test tenant** for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 unlock.
- **`njaw-selector-v2`** push status — Jorge to verify on GitHub branches page; may need re-port to fresh branch off current main given Phase 2b 3-tab → 2-tab refactor.
- **`serranogroup.org` Cloudflare Pages custom domain** — verified NXDOMAIN tonight, DNS not wired post-propagation. Retry needed.

## Decisions parked (not blockers)

- Memory audit execution (5 replace + 4 remove + 4 add)
- BidGrid kickoff timing — after MyInspector v0.1 close
- Mercury bank account opening — post-lawyer Mon 5/4
- Trademark filings (BidGrid, MyInspector, Tia, FORGE) — ~$1,400 budgeted
- Lawyer outreach Mon 5/4 AM (in flight via warm intro: PI attorney → IP attorney; Wilentz Goldman Spitzer or McCarter & English / Friscia)
- LinkedIn Company Page — parked until Monday post-lawyer
- Serrano Group homepage constellation visual — back-burnered tonight; copy on disk; revisit when MyInspector v1.0 stable

---

## Capital deployed in Serrano Group LLC (running tally)

- LLC formation + EIN: ~$200–370 (TBD)
- MacBook Air M4 Pro: ~$1,000–1,400 (Section 179 eligible)
- Asus laptop (primary dev): pre-existing
- Claude Max 20x plan: $200 (Saturday 5/2)
- Anthropic API credits: minimal
- Cloudflare Registrar (`serranogroup.org`): $7.50 first year, $10.13/yr renewal
- Vercel + Supabase + Mercury: $0 (free tiers)
- NJ State Bar lawyer (Mon 5/4): ~$300 budgeted
- USPTO trademark filings: ~$1,400 budgeted

**Total deployed YTD: ~$1,508–2,508, largely tax-deductible.**

---

## Last 3 sessions

1. **Mon 5/5 evening (commits `79f8434` + `7c0e83b`)** — Phase 2d Visual Tapcard Preview shipped on `demo-banner` (`79f8434`): 7 surgical edits to index.html (Phase 2c structural + Phase 2d build). Q-2d-a/b/c ratified via Buddy defaults during build. Buddy parallel-track refresh on buddy_context.md + questions.md mid-session. Followed by docs commit `7c0e83b` (Buddy): STATE refresh + Buddy parallel-track sync + Phase 2b field reference banked.
2. **Mon 5/5 late evening (MI-AUDIT-3 close commit `f99b6f0`)** — Path C ship: MI-AUDIT-3 trigger filter only. Schema survey confirmed only `last_client_sync_at` qualifies as heartbeat. Migration applied via Buddy direct Supabase MCP after Lead's MCP hit read-only block — Lead drafted SQL to disk fallback, Buddy applied direct + verified. 2/2 verification tests PASSED. Hash chain intact. Phase 2a doc-drift caught + corrected. Buddy refreshed `buddy_context.md` Phase 2a correction in parallel.
3. **Mon 5/5 close batch (commits `9c446e7` on main + `553dea2` + `6b9a9d3` on demo-banner)** — Phase 2a → main merge SHIPPED via Path C cherry-pick (production gap closed: inspectors can now create materials_sheets via UI). main → demo-banner merge-forward with conflicts resolved (Phase 2c reconciliation moved `ms-bar` + `pd-ms-history-section` INSIDE `pd-page-overview`). Phase 2d-revision Unit 1 Step 1 vestigial cleanup shipped (sub-steps A+B; C-G queued for Step 2 next session). Buddy parallel-track 45-min push: 4 new work orders drafted (Phase 2c-form, MI-302, Module 2, Luis v1) + 3 custom skills written + future-proofing strategic doc + comprehensive progress report on disk. STATE.md refreshed direct via Buddy Filesystem MCP after CC's Update tool hit stale-state mismatches 5x.

## Next session opens with — Phase 2d-revision Unit 1 Step 2 + Unit 2

Work order: `.coordination/work_order_2026-05-05_phase2d_revision_v2.md`. Step 2 (sub-steps C-G): embed visual-tapcard-preview container in `modal-materials-sheet` (50/50 desktop split + 55/45 tablet + mobile sub-tab toggle), rewrite `VTC_FIELDS` against materials_sheets schema per v2 field map, rewrite `vtcRender` for paper-true NJAW Service Line Renewal Company Side layout (6 sections + Job Notes box), wire static render from `openMaterialsSheetForProperty`, sector dispatch (NJ6_NORMAL renders, ShortHills shows placeholder). ~60-90 min focused build. Then Unit 2: autopop wiring (100ms debounce text, immediate enums) + Materials Installed table extrapolation per `service_type` (FULL/KILL/M2C/H2C/TP mappings locked in work order). Both land on `demo-banner`.

After Phase 2d-revision: pickup order from Buddy work-order queue per progress report — Phase 2c-form Restoration form (Q-7=C, ~3 sessions), then Luis AI v1 (~2 sessions, demo-target for Jeff), then optionally MI-401 GIS List (~3 sessions) and MI-404 Herald Tab (~2 sessions, Jeff in August issue) before Jeff demo on 5/14-5/15.

Post-demo: MI-302 Construction PM frontend (4 sessions, patent claim), Module 2 Wastewater/Sewer backend (1 session, 4 migrations), MI-110 Phase 4 Diagram editor (6 sessions, highest risk).

---

## Velocity benchmark
- 90-min focused build = 20–23 SQL milestones (~4 min/milestone)
- MyInspector v1.0 = **57–78 sessions**
- Aggressive: end of May 2026
- Realistic: mid-July 2026
- Founded: 4:20pm April 20, 2026. **16 days in = ~67% scope per Mon 5/5 close.**

## Completion percentages (per progress_report_2026-05-05.md)

- v0.1 Compliance Foundation: ~67% (was ~62% session start, +5% tonight)
- v1.0 (commercial-ready Water Utility): ~55%
- Full 7-module platform: ~26%
- Full architected vision (incl. integrations, mobile native, all 7 modules, Luis cross-discipline, residential): ~13%

---

## Update protocol
- **Session close:**
  - Update "Last 3 sessions" (push oldest off)
  - Update active tickets, schema surprises, blockers
  - `git add CLAUDE.md STATE.md && git commit -m "STATE: <date> session close" && git push`
- **Session open:**
  - `git pull`
  - Read CLAUDE.md, STATE.md, BUDDY_STANDARD.md, `.coordination/buddy_context.md`, `.coordination/status.md`
- **Conflict with Claude memory:** STATE.md wins. Memory updates lag.

---

## Banked discipline lessons (Mon 5/5 session — 5 lessons total)

Five locked discipline rules surfaced during tonight's session. Logged here at end of STATE.md so future Lead/Buddy reads see them at the bottom of the standing-state digest.

### Lesson 1 — Stop-and-ping when a brief contradicts the codebase

**Rule:** before launching a multi-session build off a Buddy-drafted brief, grep the codebase for every component, field, framework, or DOM ID the brief references. If any are missing or contradicted by recent commits, stop and reconcile with the spec author before writing code.

**Why:** Phase 2d brief (`MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md`) specified DOM structure ("Tapcard tab on Property Detail modal") incompatible with Phase 2c Option B (Property Detail tabs are Overview / Restoration / ShortHills); specified React framework when the codebase is vanilla HTML/JS per CLAUDE.md; specified field schema (`cs_depth_in`, `mp_horn_copper`, etc.) not present in Phase 2b's actual form. Lead surfaced 4 contradictions before kickoff. The alternative path (just executing the brief) would have shipped wrong work in 3 sessions and required a redo.

**How to apply:** at brief pickup, do a 5-minute grep sweep for every brief-named identifier. Any miss = stop-and-ping. Buddy's parallel ground-truth doc (`PHASE2B_TAPCARD_FIELDS_REFERENCE.md`) is the corrective pattern — when a brief mirrors existing UI state, ground-truth the source first.

### Lesson 2 — Confirm shipped state via authoritative source before re-shipping

**Rule:** any task that overlaps a recent decisions.md entry or migrations log — read the entry, verify against prod via read-only MCP queries, then act. Re-shipping a no-op is wasteful; re-shipping a duplicate migration is destructive.

**Why:** tonight's task plan included shipping MI-AUDIT-1 (3-line firm_id filter on `get_pending_destruction`). Per the brief in `SUNDAY_SECURITY_AUDIT_5-3-26.md`, this needed shipping. But per `decisions.md` Sunday evening entry, it had already shipped via Supabase MCP migration `mi_audit_1_fix_get_pending_destruction` (v `20260503172732`). Lead verified live via `list_migrations` + `pg_get_functiondef` showing the firm_id filter is in prod. Skipped the no-op, recorded as closed instead.

**How to apply:** before any prod write, `list_migrations` + targeted `pg_get_functiondef` / `execute_sql` (read-only) is cheap and authoritative. The migration log is the truth, not the brief. Brief context can be days stale.

### Lesson 3 — Treat `.coordination/` files as multi-writer territory

**Rule:** before any branch operation (`git checkout`, `git merge`, `git rebase`), `git status` first; coordinate stash/commit/ack with Buddy before destructive moves. `.coordination/` files (especially `buddy_context.md`, `decisions.md`, `questions.md`, `status.md`) are written by both Buddy (filesystem MCP) and Lead (Claude Code) within the same session.

**Why:** tonight's `git checkout main` (mid cherry-pick flow) aborted with *"Your local changes to the following files would be overwritten by checkout: .coordination/buddy_context.md, .coordination/questions.md"*. Buddy was actively refreshing both files via filesystem MCP while Lead was building Phase 2d in Claude Code — neither side had visibility into the other's writes until git status exposed them at the destructive-action boundary.

**How to apply:** any session where Buddy is actively writing requires `git status` before every checkout-class operation. If parallel-track files are dirty and Buddy intent is unclear, surface to Jorge with options (stash / commit / pause) — don't guess. Once decided, the chosen path commits cleanly with no work lost.

### Lesson 4 — When MCP is read-only, fall back to disk + handoff; do not bypass

**Rule:** if a Supabase MCP write call returns "Cannot apply migration in read-only mode," stop and write the migration SQL to disk for handoff. Do not retry, do not seek alternate paths, do not attempt shell-level workarounds. Disk + handoff to a write-mode actor (Buddy MCP, Supabase Dashboard, supabase CLI) is the canonical fallback.

**Why:** MI-AUDIT-3 ship Mon 5/5 evening — Lead's Supabase MCP returned read-only on `apply_migration`. Lead wrote migration to `.coordination/mi_audit_3_skip_heartbeat_audit.sql` and held for direction. Jorge confirmed Path B (disk handoff); Buddy applied via write-mode MCP. Verification ran clean: 2/2 tests PASSED, chain intact. Total elapsed ~5 min for blocked-to-applied handoff vs hours-of-debug if Lead had tried to bypass the read-only gate.

**How to apply:** `apply_migration` read-only error = immediate disk write + ping Jorge with both options (flip MCP write-mode OR hand off via disk). Do not propose alternate-channel writes (`execute_sql` workarounds, etc.) — read-only is read-only by design and bypassing it would corrupt the audit trail.

### Lesson 5 — Buddy parallel-track agency: don't anchor to "what's in the locked queue" as the limit

**Rule:** Buddy in chat has parallel agency to draft, verify, and stage work-order infrastructure across all 7 MyInspector modules + cross-cutting features simultaneously, not just the active ticket. When Lead is on a single thread (e.g., Phase 2d-revision build), Buddy uses parallel runway to prep next-session work orders against verified ground truth so paste-and-go pickups are possible.

**Why:** during tonight's MI-AUDIT-3 + Phase 2a merge work (Lead-active for ~5 hours), Buddy was operating as auditor + next-pickup drafter (Lucy + Jeff combined per the named-crew model) but anchored to the 4 already-formalized feature tickets (MI-401/402/403/404) as the pre-load limit. In reality, Phase 2c-form, MI-302, MI-110, Module 2 schema, and Luis v1 were all drafted-but-not-formalized and could ship as work orders in parallel without disrupting Lead's thread. Jorge surfaced the under-utilization explicitly: "i'm so confused why you refuse to push the envelope and get things accomplished when their clearly open and ready to be worked on."

**How to apply:** when Lead is on a focused multi-hour build, Buddy actively scans for: (1) backend-shipped tickets without frontend work orders, (2) schemas referenced in old briefs that haven't been verified against current DB state, (3) cross-module foundations (e.g., Module 2 Wastewater backend) that unlock platform breadth, (4) AI-augmented surfaces (e.g., Luis v1) that are demo-critical but not yet formalized. Buddy drafts these as work orders with verified ground-truth footers, lands them on disk, surfaces a brief end-of-push status to Jorge. The principle: parallel agency is the leverage, not the disruption — Buddy's leverage is precisely that 5 work orders can ship in parallel to Lead's 1 ticket.
