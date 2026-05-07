# MyInspector — Current State

> **Purpose:** Single source of truth for session continuity. Read at session open. Update at session close.
> **CLAUDE.md** holds locked principles. **STATE.md** holds live state.
> Conflict with Claude memory: this file wins.

**Last updated:** May 7, 2026 ~05:45 EDT (post MI-401 Unit 2 + MI-404 Unit 2 ships)
**Updated by:** Lead (CC) on `mi-demo-seed` branch (HEAD parity with `demo-banner`). Wed 5/6 → Thu 5/7 session continued: (12) `2385c9e` doc-sync; (13) `558383b` bergen redistribution; (14) `74f224a` handoff-note drop; (15) `24b430f` MI-401 Unit 2 (GIS List tab UI, +396 lines); (16) `d64407f` MI-404 Unit 2 (Herald tab UI, +347 lines). Lesson 7 (RLS WITH CHECK firm_id verification) applied on every client INSERT in both ships. Demo-critical optional pre-demo work now done — buffer fully claimed for click-test + MI-DEMO-DEPLOY ritual.

---

## Project header
- **Repo:** SerranoJ3/myinspector (main, Vercel auto-deploy)
- **Live URL:** myinspector-psi.vercel.app
- **Production domain (planned):** myinspector.io
- **Supabase project:** `myinspector` (ref `wryitfoletwskkdqqwcw`, us-east-2/Ohio)
- **Local clone:** `C:\Users\jserr_0phql\Documents\Serrano Group LLC\Code\myinspector`

---

## Active gate: v0.1 Compliance Foundation

**~80% of v0.1 scope complete by session count** (Thu 5/7 ~05:45 EDT close, +2% from ~03:00 EDT: MI-401 Unit 2 GIS List tab UI + MI-404 Unit 2 Herald tab UI both shipped on top of the Phase 2c-form 8/8 + MI-DEMO-UI v2 baseline).

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
| MI-101 Phase 2c-form pickup (Restoration form) | **CLOSED Thu 5/7 ~03:00 EDT — 8/8 acceptance** | Three units across `demo-banner`: Unit 1 (`d871f73`, +197 lines, form scaffold + Save Draft + sector dispatch), Unit 2 (`3a1a9bf`, +94 lines, Submit Restoration Phase handoff + live entry count), Unit 3 (`9a94510`, +262/-3 lines, history view + role-gated edit + recently_paved_road inline banner). Schema-driven decision in Unit 1 (Lesson 4): photos live on `phase_submissions.photo_restoration_url` (submission-level) not `restoration_grid_entries` (verified 17 cols, no photo URL columns), so photos route through Unit 2's Submit Phase handoff path — reuses proven photo + whiteboard + audit + PhotoQueue paths, zero new bug surface. Q-rg-edit-gate locked (super_admin / supervisor / submitted_by author at UI level; RLS-level tightening deferred). Q-rg-rpr-copy locked. All 8 acceptance criteria ✅. |
| MI-101 Phase 2d (Visual Tapcard Preview, original placement) | Shipped Mon 5/5 on `demo-banner` (`79f8434`); superseded by Phase 2d-revision | Original placement on `#modal-tapcard`. Vestigial scaffolding removed in Phase 2d-revision Unit 1 Step 1 (commit `6b9a9d3`). VTC config + helpers preserved for Step 2 reuse on `modal-materials-sheet`. |
| **MI-101 Phase 2d-revision Unit 1 Step 1 (vestigial removal)** | **Closed Mon 5/5 ~late evening** | Commit `6b9a9d3` on `demo-banner`. Removed `vtc-mobile-tabs` + `tc-mid` wrapper + `visual-tapcard-preview-container` from `#modal-tapcard`; removed `vtcInitOnOpen` / `vtcReset` / `vtcAttachListeners` / `vtcMobileTab` functions + call sites + `currentTapcard.property = prop` stash. Preserved `VTC_FIELDS` config + `vtcRender` + `vtcDebouncedRender` + `vtcVal` / `vtcEsc` / `vtcWrap` helpers + CSS rules. |
| **MI-101 Phase 2d-revision Unit 1 Step 2 + Unit 2** | **Closed Wed 5/6 ~evening** | Two commits on `demo-banner`: `52adf8a` (Unit 1 Step 2 — split layout 50/50 desktop / 55/45 tablet / mobile sub-tab toggle, paper-true 6-section + Job Notes box SVG, sector dispatch via `currentMaterialsSheetProperty.sector`, helpers `vtcMs`/`vtcProp`/`vtcInchesToFtIn`/parsers) and `7018493` (Unit 2 — `vtcAttachAutopopListeners` idempotent delegated input listener, chip/toggle/recalc helper patches fire `vtcRender` directly, `tc-co-*` one-way binding, `vtcMaterialsRows` extrapolation FULL/KILL/M2C/H2C/MP/TP). Vercel preview `dpl_BbarAjj9...` from sha `7018493` confirmed READY. Schema verified pre-build (no drift; spec said `materials_sheets` 39 cols, actual 48 — caught + adjusted). |
| **MI-110 Phase 4 (Tapcard Diagram editor)** | **Closed Wed 5/6 — fully closed Thu 5/7 ~00:15 EDT** | Editor commit `cb6a96c` (+447/-13 in `index.html`, Buddy shipped in 1 turn vs 6-session brief estimate — see Lesson 6). Acceptance #6 closed in `be48774` Thu 5/7 ~00:15 EDT: `diagramReadOnlyEmbed(diagram, opts)` public API renders standalone SVG markup for any `tapcard_data.diagram` payload; Property Detail submissions list now inlines a read-only diagram beneath each `phase='tapcard'` submission card with `tapcard_data.diagram` set (multiple embeds per page, no shared IDs, XSS-safe). All 7 acceptance criteria ✅. Deferred (separate tickets): pinch-zoom/pan, long-press rename UI, annotation tool. |
| **MI-DEMO-TOWNS** | **Closed Thu 5/7 ~00:00 EDT** | Migration `20260507002311_mi_demo_seed_14_swap_towns_to_non_njaw` reassigned 12 demo properties from NJAW footprint towns (Maplewood/Millburn/Short Hills) to non-NJAW NJ municipalities: Hoboken (3), Jersey City (3), Bayonne (3), Trenton (3). Per Jorge: a CP Engineers prospect would clock the original towns as Jorge's actual NJAW LCRI contract zone. Sector enum `NJAW_SHORT_HILLS` retained on bb...0011 + bb...0012 — sector is a product role-inversion type, not a municipality. Sector enum rename queued as separate ticket. |
| MI-302 Construction PM frontend | Work order on disk (Buddy 5/5 evening) | Backend fully shipped. CP default project seeded Sun (`722f9db8...`). Q-302-b/c/d/e ratified. Patent-claim module per Bill. ~4 sessions. |
| **MI-luis-1 Luis AI v1 (Water Utility)** | **Polished Thu 5/7 ~00:25 EDT** | `luis_conversations` table + `luis-ask` Edge Function + chat panel + citation chips already in place. Polish in commit `be48774`: (1) multi-turn history (`luisHistory` global capped at 20 messages = 10 turns); (2) page-context awareness (`luisGetPageContext()` inspects open modals — tapcard/property-detail/materials-sheet — and injects a context string into the system prompt, fresh on each send); (3) **RLS bug fix:** `luis_conversations` insert was missing `firm_id` — `pg_policies` showed WITH CHECK = `(firm_id = current_firm_id() OR is_super_admin())`, so every prior insert with NULL firm_id was silently rejected. `currentFirmId` now passed on insert. Lesson 7 banked. |
| **MI-401 GIS List Tab** | **CLOSED Thu 5/7 ~04:30 EDT** | Unit 1 backend (Buddy via Filesystem MCP earlier this session): `gis_lists` + `gis_list_entries` tables + RLS forced + 3 firm-scoped policies each + audit triggers + demo/CP seed with mixed-status entries. Unit 2 frontend (`24b430f`, Lead build, +396 lines, 9 surgical Edit-tool calls): sidebar tab between Properties + Submit Phase, panel with list selector + status filter chips + search, status cycle on tap (to_do → in_progress → complete), notes save-on-blur, Property auto-link via View button, super_admin "+ New List" + paste-CSV import (header-row INDEX/ADDRESS/STATUS/NOTES). 4 pitch-mode guards added. Lesson 7: firm_id on every INSERT. Closes acceptance #1/#2/#4/#9; partial #3 (View only, no fuzzy-match candidates), #5 (paste-CSV not PDF), #8 (responsive table, no card view). #6 supervisor stats deferred to Unit 3 polish (post-demo). |
| MI-402 Towns/Contractors reference | Work order on disk | Smallest, ~30 min backend + optional frontend. |
| MI-403 Field Guides Tab | Work order on disk | Fittings reference library. ~2 sessions. |
| **MI-404 Herald Tab** | **CLOSED Thu 5/7 ~05:30 EDT** | Unit 1 backend (Buddy via Filesystem MCP earlier this session): `heralds` table + RLS forced + read-firm + super_admin-only writes + August 2025 row seeded with all highlight fields (Schmitz Tank, Jeff cited, Life Sciences spotlight, Melanie Chisholm new hire, Document-As-You-Go tip), `pdf_url` placeholder. **Buddy deviation:** work order RLS used `current_user_role()` which doesn't exist; substituted `is_super_admin()` (canonical pattern, no semantic change). Unit 2 frontend (`d64407f`, Lead build, +347 lines): sidebar tab last position in Office nav, hero card with thumbnail-or-📰-placeholder, 4 highlight tiles conditional on populated fields, back-issues archive listing all issues including current, 3-branch PDF viewer (placeholder pdf_url shows friendly inline message, mobile <768px shows download anchor, desktop renders inline embed), super_admin Upload modal with file + month/year + 5 highlight curation fields. Friendly toasts on storage/save failures (no raw errors). modal-input class convention aligned via 2 replace_all Edits. 1 pitch-mode guard added. Closes acceptance #1-#7. Pre-demo prereq: super_admin uploads actual PDF via the modal so Read CTA renders the embed. |
| Module 2 Wastewater/Sewer v0 backend | Work order on disk (Buddy 5/5 evening) | NASSCO PACP defect coding, manhole reference, CCTV defect observations. 4 migrations. Foundational for module #2 of 7. Buddy can apply directly via Supabase MCP if Lead delegates. ~1 session. |
| MI-AUDIT-1 (firm_id filter on `get_pending_destruction`) | Closed Sun ~17:35 | Migration `mi_audit_1_fix_get_pending_destruction` v `20260503172732`. Live function body contains `AND dn.firm_id = public.current_firm_id()` |
| MI-AUDIT-2 (super_admin firm-crossing posture) | Informational, parked | Trigger to act: second firm beyond CP Engineers |
| MI-AUDIT-3 (audit_log heartbeat noise — `last_client_sync_at`) | **Closed Mon 5/5 ~evening** | Migration `mi_audit_3_skip_heartbeat_audit` (approach A — trigger filter). Whitelist: `last_client_sync_at`. Pre-fix baseline 1101 rows / 916 heartbeat-only / 83% noise. TEST 1 heartbeat-skip PASSED (delta=0); TEST 2 real-state PASSED (delta=1). Chain intact: head `fd537e79...` linked to prior head `d9e39e64...`. |
| Soft-delete view rebuild (CLAUDE.md principle #7) | Closed Sat | Migration `soft_delete_views_security_invoker_rebuild` |
| `legal_holds` workflow | Backend exists, no UI | Table indexed + RLS-locked. No active ticket. |
| Demo tenant + `firm_safe_to_display` | Closed Sat | Migrations `firms_safe_to_display_flag` + `demo_tenant_seed_data_v3` + `demo_inspector_binding` |
| **MI-DEMO seed (Track 2 sample data)** | **Closed Wed 5/6 ~evening** | 12 migrations applied via Buddy direct MCP write on `mi-demo-seed` branch (Lead's MCP read-only). Demo firm now has 12 properties (10 NJ6 + 2 ShortHills), 25 phase_submissions covering all 9 phases + all 6 NJAW codes + 1 KILL-with-subtype, 5 materials_sheets, 1 cs_replacement_authorization, 6 daily_reports, 3 documents, 2 RFIs, 2 Luis conversations, 5 demo `auth.users` + matching profiles. Spec at `.coordination/MI-DEMO_seed_spec_2026-05-06.md`. Sync note at `.coordination/buddy_demo_seed_sync_2026-05-06.md`. Three side decisions banked: `pg_net` extension installed, `profiles.email` column added (with backfill from `auth.users`), `seed-demo-users` Edge Function deployed-but-broken (admin SDK `listUsers` fails — SQL bypass replaced it). §22 demo-tenant policy: NEVER MERGE TO MAIN. Branch `mi-demo-seed` merges forward to `demo-banner`. |
| MI-DEMO-UI v2 (banner copy + write suppression) | **CLOSED Thu 5/7 ~02:25 EDT** | Commit `58d41be` on `demo-banner`. Pitch mode toggle button in demo banner; localStorage persistence (`mi_pitch_mode`); banner gradient + tag pill turn red when ON; `body.pitch-mode-active` class added. **10 write-path guards** with one-line `pitchModeBlocked('label')` checks: `saveProperty`, `submitNoWorkPhase`, `submitPhase`, `confirmBulkImport`, `saveMaterialsSheet`, `confirmSectorEdit`, `submitTapcard`, `rgSaveDraft` (initial 8) + `rgStartEdit`, `rgUpdateEntry` (added by Phase 2c-form Unit 3). Scope guard: demo firm only. No separate spec doc — built directly off seed spec §22 cross-reference per Lesson 6. Q-pitch-a/b/c/d/e ratified inline. |
| MI-DEMO-DEPLOY (pitch-day deploy ritual) | Spec pending | Companion to MI-DEMO; deploy alias swap, post-demo wipe schedule, Jorge-side checklist. Out of scope of seed spec. |

---

## Tapcard cluster (~37 sessions total per 4/30/26 refinement)

| Ticket | What | Sessions | Status |
|---|---|---|---|
| MI-100 | Sector toggle (NJ6_NORMAL / NJAW_SHORT_HILLS) | 3 | Closed |
| MI-101 | Normal Tapcard 3-page (CDM-Smith rules b, d, e) | 6 | Phases 1a-2b shipped; 2a frontend merged 5/5; 2c lean scaffolded; 2d shipped 5/5 (re-scoped to 2d-revision); 2d-revision Unit 1 Step 1 vestigial cleanup shipped 5/5; **2d-revision Unit 1 Step 2 + Unit 2 shipped 5/6** (visual tapcard rebased onto materials_sheet modal, paper-true SVG, autopop wiring, materials-installed extrapolation); 2c-form Restoration queued |
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

**Wed 5/6 evening (Phase 2d-revision finish + MI-DEMO seed):**
- **Phase 2d-revision Unit 1 Step 2 SHIPPED** as commit `52adf8a` on `demo-banner`: visual-tapcard-preview container embedded inside `modal-materials-sheet` with split layout (50/50 desktop, 55/45 tablet, mobile sub-tab toggle); `VTC_FIELDS` rewritten against verified `materials_sheets` 48-col schema (spec said 39 — drift caught); paper-true SVG layout mirrors NJAW Service Line Renewal Company Side (6 sections + Job Notes box); helpers added (`vtcMs`/`vtcProp`/`vtcInchesToFtIn`/parsers); sector dispatch via `currentMaterialsSheetProperty.sector`; `openMaterialsSheetForProperty` + `editMaterialsSheetById` fetch joined property in parallel and call `vtcRender`; `closeMaterialsSheetModal` clears state + preview.
- **Phase 2d-revision Unit 2 SHIPPED** as commit `7018493` on `demo-banner`: `vtcAttachAutopopListeners` idempotent delegated input listener attached on first modal open (text/number debounced 100ms, date/select immediate); chip/toggle/recalc helpers patched to fire `vtcRender` directly (hidden inputs don't emit `'input'` events); `tc-co-*` form one-way binds into materials sheet visual; `vtcMaterialsRows` extrapolation maps service_type → rows (FULL 11 / KILL 3 / M2C 5 / H2C 6 / MP 5 / TP blank); paper QA against 44 Dunnell example renders correctly. Vercel preview `dpl_BbarAjj9...` from sha `7018493` confirmed READY on demo-banner alias.
- **MI-DEMO seed bootstrap SHIPPED** via Buddy direct MCP write (Lead's MCP read-only blocked apply): 12 migrations applied, demo firm now has 12 properties (10 NJ6_NORMAL + 2 NJAW_SHORT_HILLS), 25 phase_submissions covering all 9 phase enum values + all 6 NJAW work order codes + 1 KILL-with-subtype, 5 materials_sheets (property #1 = comprehensive 44 Dunnell paper-true values), 1 cs_replacement_authorization (CDM-Smith rule c exercise), 6 daily_reports, 3 documents, 2 RFIs, 2 Luis conversations, 5 demo `auth.users` + matching profiles. Spec at `.coordination/MI-DEMO_seed_spec_2026-05-06.md` (Lead reconciled v3 with §24 stop conditions). Sync note at `.coordination/buddy_demo_seed_sync_2026-05-06.md`. Sync commit `08fac2d` on `mi-demo-seed` branch (off `demo-banner`); per §22, NEVER MERGE TO MAIN — merge target is `demo-banner` only.
- **Three side decisions banked during seed run:** `pg_net` extension installed (forward capability for trigger-based Edge Function calls); `profiles.email` column added with backfill from `auth.users` (denormalized convenience for email-based lookups); `seed-demo-users` Edge Function deployed but functionally broken (`auth.admin.listUsers` SDK call fails — SQL bypass migration `20260506230158_mi_demo_seed_04_create_demo_auth_users_via_sql.sql` replaces it). Function source preserved at `supabase/functions/seed-demo-users/index.ts` for future SDK-version retry.
- **§16a actor coverage outcome:** Spec target was ~91% audit attribution from ~1,000 cascade rows. Actual: 36.5% from ~58 cascade rows. Spec drift — cascade was much smaller than estimated. Demo-firm `audit_log` final state: 159 total, 58 attributed (36.5%), 101 NULL legacy (untouched per §16a option a). Defensible under audit.
- **Companion specs queued (out of scope of seed):** MI-DEMO-UI v2 (banner copy + write suppression), MI-DEMO-DEPLOY (pitch-day deploy ritual + post-demo wipe schedule). Both pending separate spec drafts before pitch day.
- **MI-110 Phase 4 SHIPPED in 1 Buddy turn** (commit `cb6a96c` on `demo-banner`, +447/-13 net +434 in `index.html`). SVG-based interactive Tapcard Diagram editor: tap-to-place MP, drag-with-snap (5% grid), 4 asset markers (Q-110-a default), undo/redo, `tapcard_data.diagram` jsonb persistence. Acceptance #1-5+#7 ✅; #6 read-only mode wiring initially deferred (engine in place via `diagramLoad(data, {readOnly:true})`). Deferred from this push: pinch-zoom/pan, long-press rename UI, annotation tool. Vercel preview READY. **Lesson 6 banked:** brief was 6-session estimate, shipped in 1 turn — when brief is locked + repo write access exists, BUILD don't spec.

**Thu 5/7 ~00:00–00:30 EDT (late-night triple-ship — `be48774`):**
- **Demo property towns swapped from NJAW footprint to non-NJAW NJ municipalities** via migration `20260507002311_mi_demo_seed_14_swap_towns_to_non_njaw`. Maplewood/Millburn/Short Hills (NJAW LCRI contract zone — Jorge's actual day-job territory) replaced with Hoboken (3) / Jersey City (3) / Bayonne (3) / Trenton (3). Sanitization fix per Jorge: a CP Engineers prospect would clock the original towns as Jorge's contract zone. Sector enum `NJAW_SHORT_HILLS` retained on bb...0011 + bb...0012 — it's a product role-inversion type, not a municipality. Sector enum rename queued separately.
- **MI-110 Phase 4 acceptance #6 CLOSED** — `diagramReadOnlyEmbed(diagram, opts)` public API renders standalone SVG markup for any `tapcard_data.diagram` payload. Property Detail submissions list now inlines a read-only diagram beneath each `phase='tapcard'` submission card with `tapcard_data.diagram` set. Multiple embeds per page supported (no shared IDs). XSS-safe `escapeStr` on label text. All 7 brief acceptance criteria now ✅.
- **Luis v1 polished:** multi-turn (`luisHistory` cap 20 messages = 10 turns) + page-context awareness (`luisGetPageContext()` inspects open modals + injects context string into system prompt) + **RLS bug fix** (`luis_conversations.insert` was missing `firm_id`; `pg_policies` WITH CHECK = `(firm_id = current_firm_id() OR is_super_admin())` rejected every prior write silently — `currentFirmId` now passed on insert). **Lesson 7 banked:** verify RLS WITH CHECK columns are populated on every client-side INSERT.

**Thu 5/7 ~00:50 EDT (security — `3f448ab`):**
- **CP Engineers firm_code rotated** via migration `20260507004722_rotate_cp_engineers_firm_code_2026_05_07`. Defense-in-depth rotation after the prior code was found in plaintext inside an untracked `.coordination/progress_report_2026-05-05.md` (caught BEFORE git commit during pre-push scan). DO block had 3 guard rails: prior-code match, new-code uniqueness, post-UPDATE verification gate. Verified post: `lookup_firm_by_code` returns CP Engineers for new code; prior code no longer exists in any firm. Codes themselves redacted from tracked docs by design — see internal sync note `.coordination/buddy_firm_code_rotation_2026-05-07.md` (gitignored). Side gap surfaced: `firms` table has no audit trigger and no `updated_at` column — queued as MI-AUDIT-4 (~30 min ticket).
- **`.gitignore` + sensitive .coordination cleanup.** Public repo (`SerranoJ3/myinspector`) had no .gitignore. Buddy scanned 9 untracked .coordination/ files; flagged 8 sensitive (buddy_context.md, MI-DEMO_seed_spec_*, SUNDAY_SECURITY_AUDIT_*, end_of_day_*, progress_report_*, velocity_analytics_*, MI402 towns/contractors brief + work order, MI404 Herald docs). CC's diagnostic sweep caught Buddy's gitignore had missed the rotation's own paper trail; two-line extension added (`.coordination/buddy_firm_code_rotation*.md` + `supabase/migrations/*rotate*firm*code*.sql`). Three previously-tracked sensitive files removed from index. Result: 16 file changes, +2560/-838.

**Thu 5/7 ~01:35 EDT (Phase 2c-form Unit 1 — `d871f73`):**
- **Restoration form scaffold + Save Draft + sector dispatch** (+200/-3 = net +197 lines in `index.html`). Three surgical edits via Filesystem MCP: ~24 CSS rules for `.rg-*` classes; HTML replace of `pd-page-restoration` placeholder with ShortHills banner (hidden default) + dynamic `<div id="rg-form-container">`; JS module wiring `rgInit` / `rgRenderEmpty` / `rgRenderForm` / `rgClearFieldset` / `rgSetStatus` / `rgSaveDraft` + `pdSwitchTab` lazy-init hook on `tab='restoration'`. Schema deviation caught (Lesson 4): spec said photo upload per fieldset but `restoration_grid_entries` has no photo URL columns; photos belong on `phase_submissions` (submission-level). Photos deferred to Unit 2. Acceptance 4/8 met after Unit 1.

**Thu 5/7 ~02:00 EDT (Phase 2c-form Unit 2 — `3a1a9bf`):**
- **Submit Restoration Phase handoff + live entry count** (+94 lines). Footer with live entry count + Submit button (disabled when 0 entries). `rgGoToSubmitPhase` validates ≥1 entry, closes Property Detail, switches to Submit panel, pre-fills hidden + visible property selects, programmatically calls `selectServiceType(tile, 'restoration')` to render the existing photo slot + dynamic fields. Strategic call: route to existing Submit Phase flow vs rebuild inline — reuses proven photo + whiteboard + audit + PhotoQueue paths. Acceptance 7/8 met after Unit 2.

**Thu 5/7 ~02:25 EDT (MI-DEMO-UI v2 pitch mode — `58d41be`):**
- **Pitch mode write suppression toggle** (~75 lines, 11 surgical edits). Toggle button added to demo banner; localStorage persistence (`mi_pitch_mode`); banner shifts red when ON. 8 write paths guarded with `pitchModeBlocked('label')` one-liners (later +2 from Unit 3 = 10 total). Scope guard: `currentFirmIsDemo` checked in toggle + block functions — real firm sessions unaffected even if localStorage gets stuck. Q-pitch-a/b/c/d/e ratified inline (no separate spec doc per Lesson 6 — seed spec §22 cross-reference was the locked authority).

**Thu 5/7 ~02:55 EDT (Phase 2c-form Unit 3 — `9a94510`, closes 8/8):**
- **History view + role-gated edit + recently_paved_road inline banner** (+262/-3 lines, 5 surgical edits). Adds `currentUserRole` global captured in `initApp` from `profile.role`. ~33 new CSS rules for history accordion + edit mode styling + RPR banner. `rgRenderForm` extended with history section before fieldsets; per-fieldset RPR banner div + onchange wiring; per-fieldset Update Entry + Cancel buttons (hidden until `.rg-editing` class). New functions: `rgRprToggle`, `rgCanEdit`, `rgRefreshHistory`, `rgRenderHistory`, `rgToggleEntryExpand`, `rgStartEdit`, `rgCancelEdit`, `rgUpdateEntry`. Edit gate at UI level: super_admin OR supervisor OR submitted_by author. Both new write paths inherit pitch-mode guards. **Phase 2c-form 8/8 acceptance criteria CLOSED** — demo critical path now down to click-test + polish.

**Thu 5/7 ~03:30 EDT (Bergen redistribution — `558383b` + `74f224a`):**
- Demo properties redistributed to Bergen County (Hackensack/Paramus/Teaneck/Fort Lee/Englewood/Ridgewood/Fair Lawn/Bergenfield/Mahwah) + sector descriptors neutralized. `74f224a` then dropped the Bergen swap handoff note from disk after work landed. Both commits on `mi-demo-seed` first; FF merged forward to `demo-banner` later in this session per Buddy parallel-track flow.

**Thu 5/7 ~04:30 EDT (MI-401 Unit 2 GIS List tab UI — `24b430f`):**
- Buddy shipped MI-401 Unit 1 backend earlier this session via Filesystem MCP: `gis_lists` + `gis_list_entries` tables, RLS forced + 3 firm-scoped policies each, audit triggers, demo + CP firm seed with mixed-status entries (per buddy_mi401_mi404_backends_2026-05-07.md sync note). Lead shipped Unit 2 frontend as 9 surgical Edit-tool calls (+396 lines on `index.html`): sidebar tab "GIS Lists" between Properties + Submit Phase; panel with list selector + status filter chips (All/To-Do/In-Progress/Complete using btn-orange/btn-ghost class swap, no new CSS) + search; read path (`loadGisLists`/`loadGisListEntries`/`renderGisEntries`) with completion stats (`done/total complete · N in progress`); write path with status cycle (to_do → in_progress → complete, `completed_at`/`completed_by` tracked, cleared when leaving complete) + notes save-on-blur; super_admin "+ New List" modal + paste-CSV/TSV import modal (header-row INDEX/ADDRESS/STATUS/NOTES, status enum normalization). All four write paths gated by `pitchModeBlocked('label')`. **Lesson 7 explicitly applied:** every client INSERT (gis_lists.create + gis_list_entries bulk import) carries `firm_id: currentFirmId`; UPDATE paths deliberately omit firm_id since existing row's firm_id satisfies WITH CHECK. Closes acceptance #1/#2/#4/#9; partial #3 (View button on linked entries, no fuzzy-match candidates UI), #5 (paste-CSV not PDF parsing), #8 (responsive table, no separate mobile card view). #6 supervisor stats deferred to Unit 3 polish (post-demo).

**Thu 5/7 ~05:30 EDT (MI-404 Unit 2 Herald tab UI — `d64407f`):**
- Buddy shipped MI-404 Unit 1 backend earlier this session via Filesystem MCP: `heralds` table + RLS forced + read-firm + super_admin-only writes via `is_super_admin()` (deviation from work order which used non-existent `current_user_role()` — substituted canonical pattern, no semantic change), August 2025 row seeded with all highlight fields populated, `pdf_url` placeholder. Lead shipped Unit 2 frontend (+347 lines on `index.html`): sidebar tab "The Herald" last position in Office nav; hero card (thumbnail-or-📰-placeholder + title + month/year + Released [date] + Read CTA); 4 highlight tiles conditional on populated fields (Market Spotlight/Photo of the Month/Get to Know/Tip of the Month); back-issues archive listing all issues including current per acceptance #4 (single-issue state shows that issue in archive); 3-branch PDF viewer (`openHeraldPdf`: placeholder pdf_url shows friendly "PDF not yet uploaded" message, mobile <768px shows Download anchor, desktop renders inline `<embed type="application/pdf">` at 90vh); super_admin Upload New Issue modal with file + month/year + released + 5 highlight curation fields, storage upload to bucket `heralds` at path `{firm_id}/{year}-{month}/herald.pdf` with `upsert: true`, DB upsert keyed on `(firm_id, year, month)` UNIQUE for re-uploads. **Friendly toasts on storage/save failures per Jorge directive** ("friendly toast not raw error") — bucket-missing → `"Herald storage not configured yet — ping Jorge to enable the bucket"`; generic upload/save → `"Upload failed — try again or ping Jorge"`. **Class convention alignment:** initial draft used `class="modal-select"` on text/date/file inputs + textareas; Jorge flagged canonical `.modal-input` for non-select inputs; aligned via 2 `replace_all` Edit calls scoped to `id="hu-` (7 inputs + 3 textareas → modal-input; month `<select>` kept on modal-select). Bucket existence pre-verified by Jorge before wire-up. 1 pitch-mode guard added on `confirmHeraldUpload`. **Lesson 7 applied:** heralds upsert payload carries `firm_id: currentFirmId`. Closes acceptance #1-#7.

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

1. **Wed 5/6 evening (commits `52adf8a` + `7018493` on demo-banner; `08fac2d` on mi-demo-seed)** — Phase 2d-revision Unit 1 Step 2 + Unit 2 SHIPPED on `demo-banner` (visual tapcard rebased onto materials_sheet modal, paper-true SVG layout, autopop wiring + Materials Installed extrapolation, Vercel preview READY). MI-DEMO seed bootstrap SHIPPED via Buddy direct MCP write (Lead's MCP read-only): 12 migrations applied to demo firm — 12 properties, 25 phase_submissions covering all 9 phase enums + all 6 NJAW codes, 5 materials_sheets, 1 cs_authorization, 6 daily_reports, 3 documents, 2 RFIs, 2 Luis conversations, 5 demo `auth.users` + matching profiles. Three side decisions banked: `pg_net` extension installed, `profiles.email` column added with backfill, `seed-demo-users` Edge Function deployed-but-broken (admin SDK fails — SQL bypass replaces it). §22 demo-tenant policy locked: `mi-demo-seed` merges to `demo-banner` only, NEVER MAIN.
2. **Thu 5/7 ~00:00–03:00 EDT (eight commits across `demo-banner` + `mi-demo-seed`)** — Five distinct ships: (a) `be48774` triple-ship — demo property towns swapped off NJAW footprint, MI-110 Phase 4 acceptance #6 closed via `diagramReadOnlyEmbed`, Luis v1 polished (multi-turn + page context + RLS firm_id bug fix); (b) `5cbc330` docs catch-up; (c) `3f448ab` security — CP firm code rotated via migration after pre-push scan caught the prior code in plaintext inside an untracked progress_report file (codes themselves stay in gitignored sync note), plus `.gitignore` created blocking 8 sensitive .coordination/ files (with two-line extension catching the rotation's own paper trail) and 16 file changes (+2560/-838); (d) Phase 2c-form arc — Unit 1 (`d871f73`, form scaffold + Save Draft + sector dispatch, 4/8), Unit 2 (`3a1a9bf`, Submit Restoration Phase handoff + live entry count, 7/8), Unit 3 (`9a94510`, history view + role-gated edit + recently_paved_road inline banner, **8/8 closed**); (e) `58d41be` MI-DEMO-UI v2 — pitch mode write suppression toggle (~75 lines, 10 write-path guards via `pitchModeBlocked()`, scope-guarded to demo firm). Side gap surfaced: `firms` table has no audit trigger or `updated_at` column — queued as MI-AUDIT-4. Lesson 6 (BUILD don't spec) applied throughout the Phase 2c-form arc + MI-DEMO-UI v2; Lesson 7 (RLS WITH CHECK column verification) applied on every grid-entry insert path.
3. **Thu 5/7 ~03:30–05:45 EDT (six commits — `2385c9e` + `558383b` + `74f224a` + `24b430f` + `d64407f` + this doc-sync)** — Three distinct ships: (a) `2385c9e` doc-sync absorbing the Phase 2c-form 8/8 + MI-DEMO-UI v2 + CP firm code rotation arc; (b) `558383b` + `74f224a` Bergen demo property redistribution + handoff-note cleanup landed on mi-demo-seed; (c) **MI-401 Unit 2 + MI-404 Unit 2 demo-strategic features both shipped via Lead Edit-tool builds off Buddy Unit 1 backend handoff:** `24b430f` MI-401 (GIS List tab UI, +396 lines, 9 surgical Edits — sidebar + panel + read/write + super_admin New List + paste-CSV import; closes #1/#2/#4/#9, partial #3/#5/#8) and `d64407f` MI-404 (Herald tab UI, +347 lines — sidebar + hero + 4 highlight tiles + back-issues + 3-branch PDF viewer + super_admin Upload modal with friendly toasts + modal-input class alignment; closes #1-#7). Buddy worked MI-AUDIT-4 + MI-DEMO-DEPLOY spec in parallel during this window. Lesson 7 (firm_id on every client INSERT) applied throughout. Workflow shift mid-session: Lead switched from "propose Ctrl+F find/replace blocks" to "apply via Edit tool" per Jorge directive after first 11 proposals had been accumulating without disk landing — caught at the MI-401 checkpoint commit attempt when `git status` showed no index.html modifications. Lesson candidate (un-banked): verify edits land on disk via git status before accumulating proposals — short-circuits the "propose-without-applying" failure mode. CLAUDE.md sanitization (Jeff Longberg name removal) still unstaged on local working tree, queued for separate commit.

## Next session opens with — Vercel preview click-test (now spans 5 demo-critical flows) + MI-DEMO-DEPLOY ritual + Herald PDF upload

Demo-critical features all shipped:
- Phase 2c-form Restoration (8/8 acceptance) — Thu 5/7 ~03:00 EDT
- MI-DEMO-UI v2 pitch mode — Thu 5/7 ~02:25 EDT
- MI-401 GIS List tab — Thu 5/7 ~04:30 EDT
- MI-404 Herald tab — Thu 5/7 ~05:30 EDT

Demo critical path now reduced to:

1. **Vercel preview click-test pass** — Jorge to walk:
   - Phase 2c-form: open Property Detail → Restoration tab → Save Draft on a fieldset → verify history → try edit gate → try Submit Restoration Phase handoff → take photo via existing Submit Phase flow → verify phase advance
   - GIS Lists tab: open as inspector → status cycle on a few entries (verify completed_at/by populates) → notes save-on-blur → filter chips → search → as super_admin try "+ New List" + paste-CSV import → verify entries appear with status enum normalized
   - The Herald tab: open as inspector → verify August 2025 hero card with thumbnail-or-placeholder + Photo of Month tile reading the Schmitz Tank caption with Jeff cited → tap Read CTA → verify friendly "PDF not yet uploaded" message (until Jorge uploads the real PDF) → as super_admin upload the actual August 2025 PDF via the Upload modal → verify hero card refreshes + Read CTA renders inline embed
   - Pitch mode toggle: on/off in demo banner; verify all 15 write paths blocked when ON across MI-401 + MI-404 + Phase 2c-form + the original 10
   - CLAUDE.md sanitization commit (Jeff Longberg removed from CDM-Smith section); verify `git status` clean before demo
2. **MI-DEMO-DEPLOY** — pitch-day deploy ritual (Vercel alias swap, post-demo wipe schedule, Jorge-side checklist). Buddy was drafting the spec in parallel during the MI-401/404 build window — reconcile drafted spec with actual demo-tenant state before execution.
3. **MI-AUDIT-4** — firms audit trigger + `updated_at` column. Buddy worked this in parallel during the MI-401/404 build window — verify shipped state via `list_migrations` before re-shipping (Lesson 2 applies).
4. **CLAUDE.md cosmetic** — replace defunct firm-code literal with a placeholder reference (codes themselves stay out of tracked docs).
5. **Distribute new firm code** to Justin + Tyler out-of-band per the gitignored sync note (text/Slack, NOT public channel).
6. **Optional pre-demo polish (if buffer remains, none demo-blocking):** MI-401 Unit 3 (supervisor stats + address autocomplete + CSV export); MI-401 fuzzy-match candidates UI; MI-401 mobile card view; MI-402 Towns/Contractors reference (~30 min); MI-403 Field Guides Tab (~2 sessions).

Post-demo: MI-302 Construction PM frontend (~4 sessions, patent claim), Module 2 Wastewater/Sewer backend (~1 session, 4 migrations), MI-110 Phase 4 polish (pinch-zoom, long-press rename, annotation tool — all deferred from initial ship).

---

## Velocity benchmark
- 90-min focused build = 20–23 SQL milestones (~4 min/milestone)
- MyInspector v1.0 = **57–78 sessions**
- Aggressive: end of May 2026
- Realistic: mid-July 2026
- Founded: 4:20pm April 20, 2026. **17 days in = ~78% v0.1 + ~69% v1.0 per Thu 5/7 ~03:00 EDT close.**

## Completion percentages (per progress_report_2026-05-05.md, +deltas through Thu 5/7 ~03:00 EDT)

- v0.1 Compliance Foundation: **~80%** (was ~78%, +2% from MI-401 + MI-404 Unit 2 ships — both demo-strategic features land same session)
- v1.0 (commercial-ready Water Utility): **~71%** (was ~69%, +2% — GIS List paper-replacement is a recognizable inspector workflow; Herald tab is the warm-room hero card for the Jeff demo)
- Full 7-module platform: **~33%** (was ~32%, +1%)
- Full architected vision (incl. integrations, mobile native, all 7 modules, Luis cross-discipline, residential): **~16%** (was ~15%, +1%)

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

## Banked discipline lessons (Mon 5/5 + Wed 5/6 + Thu 5/7 — 7 lessons total)

Seven locked discipline rules surfaced. Lessons 1-5 from the Mon 5/5 session; Lesson 6 added Wed 5/6 after MI-110 Phase 4 shipped in 1 Buddy turn vs the 6-session brief estimate; Lesson 7 added Thu 5/7 after RLS WITH CHECK silently dropped every Luis conversation INSERT for an unknown duration. Logged at end of STATE.md so future Lead/Buddy reads see them at the bottom of the standing-state digest.

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

### Lesson 6 — When brief is locked + repo write access exists, BUILD don't spec

**Rule:** if a feature brief is fully locked (acceptance criteria explicit, schema verified, Q-answers ratified, no outstanding ambiguity) AND the actor has repo write access, skip the spec-and-review-and-handoff cycle and ship the build directly. The spec exists in the brief; the review is the diff; the handoff is the commit.

**Why:** MI-110 Phase 4 brief (`MI110_PHASE4_BRIEF.md`) was drafted Sunday afternoon with 7 acceptance criteria, structured-JSON data model locked (`tapcard_data.diagram` jsonb, normalized 0-1 coordinates), Q-110-a/b ratified, no schema migrations needed. Brief estimated 6 sessions. Buddy shipped the full editor in 1 turn (~434 net new lines in index.html, 6 surgical edits via Filesystem MCP) Wed 5/6 evening — the brief was already the spec, the diff was the proof, the commit was the handoff. Estimate was 6× too conservative because it assumed a spec-draft + review + handoff loop that wasn't needed.

**How to apply:** before drafting a work order, check: (1) is the brief locked end-to-end? (2) are all schemas verified? (3) are all Q-answers ratified? (4) does the executing actor have repo write access (filesystem MCP for Buddy, edit tools for CC)? If all four = yes, skip the work-order step and ship the build. If any = no, draft the work order. Trade-off: builds shipped this way still need a sync note documenting what was applied + what was deferred (acceptance #6 read-only-wiring for MI-110), so post-build documentation is non-negotiable. The savings come from eliminating the spec-review-handoff loop, not from skipping documentation.

**Counter-cases (still draft a work order):** any feature touching production schema migrations (audit chain side-effects), any cross-firm or cross-tenant logic where RLS can drift, any compliance gate (Carlo authorization, no_work invariants), any branch-merge ceremony where §22 or similar policy gates apply. For those: spec-first is still correct because the cost of a wrong build is higher than the cost of a draft.

### Lesson 7 — Verify RLS WITH CHECK columns are populated on every INSERT

**Rule:** before shipping any client-side INSERT to a table with RLS, query `pg_policies` for the WITH CHECK expression and verify every column referenced is populated by the client code. RLS rejection on missing WITH CHECK columns is silent at the SQL level — Supabase returns success-shaped responses for inserts that policy actually rejected, and the row never lands. UI doesn't surface the failure unless the code explicitly inspects `error` on the insert response.

**Why:** Luis v1 chat panel was deployed with `luis_conversations.insert({ user_id, project_id, module_key, question, answer, sources })` — missing `firm_id`. `pg_policies` showed the WITH CHECK as `(firm_id = current_firm_id()) OR is_super_admin()`. NULL firm_id failed the check, but the client treated the response as success because no thrown error surfaced. **Every Luis conversation written before the Thu 5/7 ~00:25 EDT fix was silently dropped.** Unknown how long the bug had been live; whoever was using Luis on prod (Jorge during demo prep) saw the chat work in-session but rows never persisted.

**How to apply:** at any client-side INSERT against an RLS-protected table:
1. Query `pg_policies` for the WITH CHECK expression on that table
2. Cross-reference every column the policy references (typically `firm_id`, sometimes `submitted_by`, `actor_id`, `created_by`)
3. Verify the client INSERT payload includes ALL of them, populated from authenticated session context (`currentFirmId`, `currentInspectorId`, etc.)
4. After deploy, run a ground-truth row-count check (`SELECT COUNT(*) FROM <table> WHERE created_at > <deploy_time>`) to confirm rows are actually landing, not just the API returning success-shape.

**Banked rationale:** RLS is fail-closed by design (rejected rows don't leak to other firms), but it's silent-fail when the client doesn't inspect errors. The cost of a missing column is "feature appears to work, no data persisted" — exactly the worst failure mode for a demo or production user. The 4-step check above takes ~2 minutes and prevents the whole class of bug.

**Counter-cases:** server-side INSERTs running as `service_role` bypass RLS entirely, so this lesson doesn't apply (different attack surface). Apply only to client-side / user-JWT-context INSERTs.
