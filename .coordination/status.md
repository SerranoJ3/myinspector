# Coordination Status — MyInspector

**Last updated:** 2026-05-15 EDT (v1.0 Polish Push doc-sync absorbing Luis whiteboard-bypass refusal + Phase 1 GIS/Restorations inert rows + Phase 2 MI-110 Phase 4 diagram polish + Phase 3 MI-403 Field Guides Unit 2 frontend + Phase 4 MI-402 Unit 2 municipality autofill). HEAD `504ca58` pre-this-commit on both `demo-banner` and `mi-demo-seed`. **MyInspector v1.0 at ~98%** — only Buddy-lane migration work remaining (`buddy_v1_migrations_2026-05-15.md`).

**Previously updated:** 2026-05-14 evening EDT (v1.0 Final Push doc-sync absorbing Phase 1 verification + Phase 2 MI-302 Unit 3 write paths + Phase 3 OPS Dashboard Unit 3 schedule cell edit ships). HEAD `a9dbb9e` pre-this-commit on both `demo-banner` and `mi-demo-seed`. **MyInspector v1.0 functionally complete (~95%).** Demo health 31/31 🟢 GREEN. Demo-ready for 5/21-5/22 pitch.

**Previously updated:** 2026-05-13 ~22:45 EDT (Rabiyu prep wave kicked off + late-session strategy lane + Lesson 20A/B/C banked). HEAD `09c6b86` on both `demo-banner` and `mi-demo-seed`. v1.0 product surface LOCKED per Jorge directive — only legal-prep docs, demo data scrubs, and marketing copy fixes (pending Jorge approval) ship in this window.

**Previously updated:** 2026-05-13 evening (50% checkpoint hit then full-completion push initiated). HEAD `e660e6a` on both `demo-banner` and `mi-demo-seed`. **Doc-sync DEFICIT REDUCED:** 5/13 evening commits absorbed below. 5/9-5/12 chronological detail (~30 commits) still pruned to summary; full per-commit list deferred to weekend window. Header-level + Last 3 sessions in STATE.md is current.

**Previously updated:** 2026-05-13 (legal lane initiated + 5/12 cargo-commits verified). HEAD `1535612` on both `demo-banner` and `mi-demo-seed`.

**Previously updated:** 2026-05-12 (doc-sync flush absorbing 5/9–5/12 demo-polish window: VTC decouple + embedded MS form on tapcard page 1 + demo-neutralize sweep + daily_reports firm_id fix + aerial map MI-115 + orphan tapcard fallback + triangulation A/B/C + group-by-property in Dashboard + All Submissions + cardinal photos optional + diagram inset clamp + Service Area B tab gate + ~30 commits total). HEAD `aecc952` on both `demo-banner` and `mi-demo-seed`.

**Previously updated:** 2026-05-09 (doc-sync flush absorbing Thu 5/7 evening → Fri 5/8 ~04:30 EDT velocity push)
**Updated by:** Lead (Claude Code CLI) — sprint absorbed via this doc-sync per Jorge's "finish it all in the most time efficient way possible" directive Thu 5/7 ~23:55 EDT. Three Lead commits in window: `e8ee1af` round-1 doc-sync (MI-101-reorg + MI-401-v2 + MI-101-reorg-v2 absorption, +142/-19), `6f15ba8` MI-101-tapcard-polish v1 (+103/-2 — pre-flight validation + state reset on close + friendly error toasts), `dbf657d` MI-101-reorg-v3 / 2x2 grid fix (+2/-1 — `.service-grid` 3-col → 2-col so 4 tiles render 2x2 not 3+1). Buddy lane (no in-tree commits — applied via Supabase MCP): V1 Herald March 2026 PDF generation, V2 MI-AUDIT-4 verified shipped, V3 MI-402 Unit 1 backend (28-row seed), V4 Module 2 Wastewater/Sewer v0 backend, V5 MI-403 Field Guides Unit 1 backend (DRAFT), V6 MI-DEMO-UI v3.1 backend RPC change. MI-AUDIT-5 a+b closed structurally. ~135 row-level demo scrubs across 4 rounds. Demo health check upgraded 14 → 23 metrics, 23/23 GREEN. Two new lessons banked tonight (10: helper-function existence verification; 11: schema-state surprise compounding).

---

## Current state

**Active branches:** `demo-banner` and `mi-demo-seed` both at `504ca58` pre-Phase-5 doc-sync (Phase 5 doc-sync commit bumps HEAD on both). main untouched per §22.

## Fri 5/15 EDT — v1.0 Polish Push addendum (Luis pre-commit + 4 phases shipped continuous-execution)

Per `.coordination/cc_v1_polish_2026-05-15.md` fired in continuous-execution mode. 5 commits + 1 doc-sync.

**Luis pre-commit `907df58` — REFUSE bypass on whiteboard photos:** system prompt extended with explicit REFUSE bullet for any request to crop out / obscure / photograph from-distance / otherwise bypass the whiteboard photo requirement on open excavations. Returns a fixed verbatim compliance response regardless of framing (hypotheticals, claims of supervisor pre-approval, expediency appeals). Hardens the existing whiteboard locked principle at the AI-advice surface.

**Phase 1 `82ef91d` (+16/-8) — GIS / Restorations inert rows clickable:**
- GIS Lists rows: always cursor:pointer + onclick; linked → `openPropertyDetail`, unlinked → friendly toast "This entry isn't linked to a property yet" via new `openGisEntryRow(entryId)` helper
- Restorations rows: always cursor:pointer + onclick; calls `openPropertyDetail(property_id, 'restoration')` to pre-position the modal
- `openPropertyDetail(propertyId, targetTab)` signature extended with optional second arg; default 'overview'

**Phase 2 `d486b8b` (+255/-1) — MI-110 Phase 4 diagram editor polish (closes 3 deferred tickets):**
- **Pinch-zoom:** ctrl+wheel (desktop trackpad pinch) + 2-finger pinch (touch). 0.5x-3x bounds. Zoom anchored to cursor/pinch midpoint. 2-finger drag pans. Double-click empty area resets zoom. Reset Zoom toolbar button. Session-only — does NOT persist to diagram payload (per spec acceptance #4)
- **Long-press rename:** 600ms touch-hold OR right-click on marker → `prompt()` for new label → snapshot + label update + re-render
- **Annotation tool:** new ✏️ Annotate toolbar button + state `diagramAnnotateMode`; click canvas → `prompt()` for text → spawn at click coords. Annotations stored in `diagramState.annotations[]` (schema already in place from initial ship — now wired through 3 render paths: `diagramRender` / `_diagramInnerSVG` / `diagramReadOnlyEmbed`). Right-click on annotation → confirm + delete
- Annotations + renames flow through `diagramSnapshot` for undo/redo parity

**Phase 3 `d9182e8` (+161/-0) — MI-403 Field Guides Unit 2 frontend:**
- New 📚 Field Guides sidebar tab between The Herald and Certs/Licenses
- Index view: lists `field_guides` ordered by `display_order`; RLS auto-filters published for inspectors/supervisors; super_admin sees DRAFT rows with amber badge
- Detail view: renders `field_guide_pages` ordered by `page_number` with image_url + caption + prev/next nav
- Super_admin publish toggle UPDATEs `field_guides.published_at`, guarded by `pitchModeBlocked`
- Schema-reality adjustments per Lesson 2: pages carry `caption` not `body_markdown` (spec assumption); `field_guides` is global (no firm_id) so no Lesson 7 INSERT audit needed
- Service Line Fittings DRAFT guide visible to super_admin pending PDF upload + page seed (Jorge action — Buddy MCP fills once available)

**Phase 4 `504ca58` (+63/-0) — MI-402 Unit 2 municipality autofill:**
- New Municipality field on Add Property modal with `<datalist>` autocomplete sourced from `municipalities_contractors` (28 NJAW LCRI service-area towns, alpha-sorted)
- `_warmMunicipalitiesCache` caches lookup once per session; `onPropMunicipalityChange()` autofills county + contractor reference fields on match; non-listed → fields stay blank
- Schema-reality adjustments per Lesson 2: `municipalities_contractors.contractor` not `prevailing_contractor` as spec assumed; properties has `municipality` column (now persisted) but no county/contractor columns — those fields labeled "(reference)" and shown for inspector guidance only at create time
- Free-text City field intentionally preserved for non-NJAW property creation (Hoboken, Bayonne, Trenton demo properties continue to save cleanly)

**Phase 5 (this commit, doc-sync):** STATE.md / status.md / decisions.md / SESSION_LOG.md / RECENT_CONTEXT.md updated per spec §5. Completion bumps absorbed: v0.1 92%→94% / v1.0 95%→98% / 7-module 50%→52% / vision 22%→23%.

**MyInspector v1.0 at ~98%.** Frontend surface fully closed. Remaining 2% is Buddy-lane migration work via `buddy_v1_migrations_2026-05-15.md`: MI-202 audit_log final close, MI-AUDIT-5 a+b column additions + backfill, `schedules (firm_id, inspector_id, date)` UNIQUE constraint, Luis system prompt persistence into edge function context.

---

## Thu 5/14 evening EDT — v1.0 Final Push addendum (4 phases shipped continuous-execution)

Per `.coordination/cc_v1_final_push_2026-05-14.md` fired in continuous-execution mode. 4 phases + 1 doc-sync commit.

**Phase 1 (MI-DEMO-UI v3.1 signup-toast follow-up) — detected as already-in-HEAD via Lesson 14:** gate landed `f27fc46` Sat 5/9 ~14:37 EDT; lines 2981-2983 of index.html already select `Welcome to ${firm.firm_name}!` when `firm_safe_to_display === true` and fall back to generic toast otherwise. No-op + skipped per spec.

**Phase 2 — `753f3a0` MI-302 Construction PM Unit 3 write paths (+416/-2):** completes the Construction PM frontend.
- `cmpmLogArrival` — `#modal-cmpm-arrival` modal with GPS via `navigator.geolocation.getCurrentPosition()` + inline `gps_accuracy_m` + amber warning chip when `accuracy > 50m` (Q-302-e), required photo via `<input type="file" accept="image/*" capture="environment">` (Q-302-d), INSERT to `contractor_arrival_log` with `firm_id: currentFirmId` (Lesson 7) + `contractor_assignment_id` + `arrived_at` + `gps_lat/lng/accuracy_m` + `photo_url` (uploaded via `cmpmUploadContractorPhoto` to `inspection-photos` bucket at path `{firm_id}/contractor-logs/{assignment_id}/{photo_uuid}.{ext}`) + `recorded_by_id/email` + `notes`. Friendly block on photo capture failure per Q-302-i.
- `cmpmLogDeparture` — photo OPTIONAL (Q-302-d), blocked when no active arrival via state-cached `_cmpmActiveArrivalLog` check + friendly toast per Q-302-h, INSERT to `contractor_departure_log` with `arrival_log_id` auto-populated.
- `cmpmAddAssignment` — super_admin/supervisor only, INSERT to `contractor_assignments` with `firm_id` + `project_id` (firm's first active project) + `contractor_name` + `contractor_role` + `start_date` + `notes` + `active: true`.
- All three guarded by `pitchModeBlocked()`; all carry `firm_id` per Lesson 7; all wrap errors via `cmpmFriendlyError` (RLS / network / check / FK / duplicate / storage → human copy, raw to `console.error`).
- Modal HTML appended at end of body: `#modal-cmpm-actions` / `#modal-cmpm-arrival` / `#modal-cmpm-departure` / `#modal-cmpm-new-contractor`.
- Q-302-j patent-claim resolved via `.coordination/BILL_Q302J_DECISION_2026-05-14.md` Outcome B (company-level identity sufficient, no schema rework, departure photo optional confirmed correct).

**Phase 3 — `a9dbb9e` OPS Dashboard Unit 3 schedule cell edit + alerts routing (+151/-3):** completes the OPS Dashboard write surface.
- `opsOpenScheduleCellModal(inspectorId, fullName, date)` — super_admin/supervisor only, pre-fetches existing `schedules` row by `inspector_id + date`, opens modal with shift_start / shift_end / notes inputs.
- `opsSaveScheduleCell` — manual SELECT-then-UPDATE-or-INSERT pattern; no UNIQUE constraint on `(firm_id, inspector_id, date)` per `pg_constraint` verification, so `.upsert({onConflict})` not viable. INSERT carries `firm_id` + `inspector_id` + `date` + shift fields per Lesson 7; UPDATE branch handles existingId.
- `opsDeleteScheduleCell` — soft-delete via `deleted_at = now()`.
- Alerts-tile PTO chip now clickable: routes to `showPanel('hours-expenses')` + `switchHoursExpensesSubview('pto')` + `heShowPtoQueue()` if `heCanSeeQueue()` — cross-links existing MI-OPS-HE Unit 3 supervisor approval queue rather than duplicating ~150 lines per spec rationale. (PTO request flow + supervisor approve/deny already shipped `fe27af7` via `hePtoSubmitRequest` / `hePtoApprove` / `hePtoDeny` against the ACTUAL schema: `pto_transactions.transaction_type='usage'` + `request_status='requested'` — discovered via Lesson 7 + Lesson 16 patterns during MI-OPS-HE build.)
- Schedule grid cells get onclick when `currentUserIsSuperAdmin || currentUserRole === 'supervisor'`.
- Write path guarded by `pitchModeBlocked()`, carries `firm_id` per Lesson 7, wraps errors via `opsFriendlyError`.
- Q-OPS-3..10 ratified `eaffaa5`.

**Phase 4 (verification gate, no commit):**
- `git rev-parse demo-banner origin/demo-banner` both at `a9dbb9e03cdf3a80eebe5bbe29115c64c4d3afe5` — branches in parity.
- 4 spec'd function strings present in local index.html: `cmpmLogArrival` ✅ / `opsSaveScheduleCell` ✅ / `hePtoSubmitRequest` ✅ / `firm_safe_to_display === true` ×3 ✅.
- Demo pre-flight health check ran via Supabase MCP `execute_sql` against `.coordination/demo_pre_flight_health_check.sql` (294-line single-CTE query) → **31/31 🟢 GREEN** (spec required 29/29; metrics include new MI-OPS-HE expense seed + `expense_receipts_bucket_exists` + `expense_receipts_policy_count = 4`). Audit chain head `4324` at 2026-05-14 01:10:44 UTC; zero rogue writes in last 4h; zero CP-internal leakage; zero person-name / contractor-name / placeholder / mapcall / Carlo / cruft leaks.
- Vercel `web_fetch_vercel_url` returned 401 (deployment protection) → fallback per Lesson 14 to local file verification + git ref parity + Supabase MCP health check. Vercel auto-deploy hook proven track record this session.

**Phase 5 (this commit, doc-sync):** STATE.md / status.md / decisions.md / SESSION_LOG.md / RECENT_CONTEXT.md all updated per spec §5. Completion bumps absorbed: v0.1 89%→92% / v1.0 87%→95% / 7-module 45%→50% / vision 20%→22%.

**MyInspector v1.0 functionally complete (~95%).** Demo-ready for 5/21-5/22 pitch. Remaining pre-pitch work is non-code Jorge-lane: pitch-deck rebalance (drop 7-module slide, lead with Module 1 + Luis + audit) + final eye-test pass on demo URL + MI-DEMO-DEPLOY ritual finalize + Rabiyu engagement signing.

---

**Local main is 1 behind `origin/main`.** Missing commit is `4d70901` (Phase 2b refactor squash merge, Sun 0:52). Run `git fetch && git checkout main && git pull` to catch up before any new branch off main.

## Wed 5/13 evening commits on `demo-banner` (FF to `mi-demo-seed`)

Four Lead commits + four Buddy Supabase MCP migrations + seven `.coordination/` doc drafts.

**Lead lane (CC):**
- `2795af7` docs(coordination) 5/13 correction sync
- `1535612` chore(gitignore): exclude .coordination/LEGAL_STATE.md — legal/business lane scratch
- `1a926ca` fix(pitch-polish): GIS/Restorations row clickability + Luis photo-timing guidance update
- `14fb3c1` **feat(ops-dashboard)**: Unit 2 single-pane-of-glass dashboard — schedule grid (Mon-Sun × 4 inspectors) + Hours/PTO/Alerts tiles + integration badges (Ajeera/ADP visual-only) + week nav arrows + recent activity preserved
- `e660e6a` **feat(mi-302)**: Construction PM tab Unit 2 — new sidebar tab role-gated to super_admin + supervisor, 3 sub-views (Assignments / Today's Activity / Billable Hours), read-only, `+ Add Contractor` stubbed disabled, in-progress pulsing badge + live elapsed timer, GPS warnings amber-flagged

**Buddy lane (Supabase MCP, no in-tree commits):**
- `ops_dashboard_schema_v1` — 4 new tables (schedules / hours_entries / pto_balances / pto_transactions), RLS forced + 4 policies per table + 4 triggers per table (audit + updated_at via `gis_set_updated_at`)
- `ops_dashboard_demo_seed` — 56 schedules + 40 hours entries + 4 PTO balances FY2026 + 82 PTO transactions
- `mi302_demo_seed_v2` — 5 contractor assignments (Meridian / Cardinal / ProTap / Asphalt / BergenCo) + 10 arrivals + 9 departures + 1 in-progress shift + 2 GPS warnings (78m + 92m); **schema-reality correction surfaced**: company-level not per-worker, no `hourly_rate` column — flagged for Bill patent-claim review before Unit 3 ships
- `demo_project_name_scrub_njaw_identifiers` — "DEMO Lead Service Replacement Project" → "DEMO Service Line Project" + "Demo LSL Replacement Program 2026" → "Demo Service Line Renewal Program 2026"
- `backlog_demo_data_writes_2026_05_13` — banks today's `execute_sql` writes (photo URL UPDATEs + GIS auto-link UPDATE) as idempotent reproducible-seed migration

**Doc lane (`.coordination/` drafts, all gitignored):**
- `LEGAL_STATE.md` (legal-lane state mirror: Rabiyu engagement, $5k retainer, 3 open Qs, MI-302 patent-claim risk register)
- `BILL_PATENT_CLAIM_ONE_PAGER_mi302_2026-05-13.md` (3-outcome A/B/C decision format for Bill review before MI-302 Unit 3)
- `RABIYU_REPLY_DRAFT_2026-05-13.md` (3-question reply body + tone notes + send timing)
- `RATIFICATIONS_PENDING_2026-05-13.md` (Q-OPS-1..10 + Q-302-f..i with Buddy leans + Q-302-j blocked on Bill)
- `MI-ARCH-001_orphan_tapcard_write_side.md` (POST-DEMO architecture ticket for write-side fix, DB trigger Option B recommended)
- `cc_doc_sync_2026-05-13_evening.md` (CC work order to commit + push the docs)
- 49 demo photos hot-linked to Pexels CDN URLs (`execute_sql` writes; now also banked in `backlog_demo_data_writes_2026_05_13` migration). **Lesson 16 surfaced**: Postgres CTE multi-update against same row silently drops all but one write.

**Three new lessons banked in STATE.md (Lessons 14/15/16):** verify shipped state via git refs + file content via Filesystem MCP directly; query `pg_proc` for canonical Postgres function names; Postgres CTE multi-write hazard with overlapping targets.

**Completion percentages bumped (in STATE.md):** v0.1 87% → 89%; v1.0 78-80% → 85%; 7-module 40-42% → 44%; vision 19% → 20%.

### Late-evening addendum (Wed 5/13 ~21:00 → ~22:45 EDT) — Rabiyu prep wave kickoff + Mike Rodriguez scrub + Lesson 20 (A/B/C)

**Triggered by Jorge directive** to lock v1.0 scope before legal engagement: "I would do all of those things and that makes us more prepared for Rabiyu so we're not going back and forth about app additions that could change the scope of legal safety or worse making it take longer and costing me more money."

**Buddy lane (Supabase MCP):**
- Migration `demo_scrub_mike_rodriguez_foreman_name` — redacted fictional foreman name (Lesson 17 hardening).

**Doc lane (`.coordination/` drafts, all gitignored):**
- `RABIYU_PREP_PACKAGE_BUILD_PLAN.md` (~400 lines, master sequencing doc).
- `RABIYU_PREP_PACKAGE_DRAFT_2026-05-14.md` (~600 lines, 15 sections, §2 Bill placeholder).
- `cc_doc_sync_2026-05-14_rabiyu_prep.md` (CC work order for tonight's doc-sync).
- `cc_marketing_copy_softening_2026-05-14.md` (CC work order for marketing fixes — fires only on Jorge approval).

**Findings surfaced:**
- ToS DRAFT v0.1 + Privacy v0.1 + DPA already exist in `serrano-group-site/legal/` (generated by Buddy 5/3). Lesson 18 banked.
- Local `supabase/migrations/` dir ends at 5/7; post-5/7 Buddy MCP migrations live remote-only — process gap, not content leak.
- Marketing copy on `serranogroup.io`: 5-7 items flagged for Jorge review (capability-claim softenings, broken `/legal/subprocessors` link, title language).

**Decisions banked (4 entries in decisions.md):** lock v1.0 scope during legal engagement, Mike Rodriguez scrub, Rabiyu prep wave kickoff, Lesson 18.

**STATE.md:** Lesson 17 hardening + full Lesson 18.

**Demo readiness unchanged:** v0.1 ~89% / v1.0 ~87% / 7-module ~45%. Demo health 29/29 🟢 GREEN.

**Working mode:** Full agency. Same pattern as MI-OPS-HE per Jorge directive ("right now lets go. same thing we just did for that massive shipment. that worked well").

---

### Late-evening addendum (Wed 5/13 ~9:30pm → ~11:30pm EDT) — eye-test → Montana scrub → MI-OPS-HE Hours/Expenses Unit 1 ship

**Demo eye-test PASSED on `e660e6a` (5-point gate clean).** One side-fix during eye-test: Montana Construction (DEMO) flagged as real-world leak — Jorge's actual day-job contractor on NJAW LCRI project. Renamed to Meridian Construction (DEMO) via migration `demo_scrub_montana_construction_real_world_contractor` + scrubbed STATE.md (2 places) + status.md (this file, line 32) + MI-302 build plan (3 places) + Bill patent-claim one-pager. **Lesson 17 banked** in STATE.md: `(DEMO)` suffix is a tag, not a filter — redact real-world names at source.

**Architectural gap surfaced from eye-test:** PTO not clickable on Dashboard + no calendar in app. Resolved: Dashboard is a glance surface, needs paired write surface. Jorge architecture playback: "days worked in calendar on dashboard … click to interact → Hours/Expenses tab → auto funnel to Ajeera + ADP."

**MI-OPS-HE ticket filed + Unit 1 backend shipped same session** (Buddy via Supabase MCP):
- `expense_entries_schema_v1` — new table + RLS forced + 5 policies + audit/`gis_set_updated_at` triggers + 4 indexes
- `expense_entries_demo_seed` — 20 entries across 5 statuses ($564 synced / $133 approved / $287 submitted / $0 draft / $85 denied) + 5 categories (mileage / per_diem / receipt / equipment / other). Vendors: Wawa, Home Depot, Lowe's, United Rentals, Shell, Amazon. Pat Morgan as approver.
- `expense_receipts_bucket_setup` — PRIVATE bucket (signed URLs only), 10MB limit, 5 allowed MIME types, 4 RLS policies (firm-scoped read, own-or-supervisor insert/update, super_admin delete). Path convention `expense-receipts/{firm_id}/{inspector_id}/{uuid}.{ext}`. Pre-action on Q-OPS-HE-d (Buddy lean).

**Doc lane additions (all gitignored via newly-added `MI-OPS-HE_*.md` pattern + existing `cc_*.md`):**
- `.coordination/MI-OPS-HE_HOURS_EXPENSES_BUILD_PLAN.md` (~470 lines, 3 units, 8 Qs, strategic rollup §10 with $15.2K/yr labor-savings math)
- `.coordination/cc_ops_he_unit2_2026-05-13.md` (~470 lines, Unit 2 read paths + Dashboard rewiring)
- `.coordination/cc_ops_he_unit3_2026-05-13.md` (~700 lines, Unit 3 write paths + modals + mock-sync + supervisor approve/deny + 14 new pitch-mode guards)

**Q-OPS-HE-a ratified in chat** (single tab w/ 3 sub-views). Q-OPS-HE-b–h queued in `RATIFICATIONS_PENDING_2026-05-13.md` Set C.

**Lesson 17 banked in STATE.md** (full writeup ~50 lines): NEVER use `(DEMO)` suffix to sanitize a real-world name; use a fully fictional name. Future modules (BidGrid contractor seed, Module 2 wastewater seed, any pitch-surfacing module) apply Lesson 17 at seed-design time.

**Doc-sync absorbed end-of-day:** STATE.md (active tickets new MI-OPS-HE row + Last 3 sessions addendum + completion percentages v0.1 89%/v1.0 87%/7-module 45% + Lesson 17), RECENT_CONTEXT.md (Tickets-in-flight + Outstanding items 14/15/16), decisions.md (4 new entries: Montana scrub + MI-OPS-HE ticket file + Q-OPS-HE-a ratification + bucket setup), SESSION_LOG.md (late-evening entry), .gitignore (MI-OPS-HE_* + MI-OPS-DASHBOARD_* + MI-302_CM-PM_* patterns), this status.md addendum.

**Working mode:** Jorge confirmed full-agency mode ("were a team buddy, i pick up the slack where i as a human can offer my intuition. beyond that. get it done"). Buddy executed the architectural-gap response autonomously: ship backend → write build plan → write both Unit 2 + Unit 3 CC work orders → pre-act on Q-OPS-HE-d bucket → bank decisions → close out doc-sync. No CC involvement tonight; Unit 2 fires next session via `read .coordination/cc_ops_he_unit2_2026-05-13.md and execute`.

---

**Wed 5/6 → Fri 5/8 commits in order on `demo-banner`:**
1. `52adf8a` Phase 2d-revision Unit 1 Step 2 (Wed 5/6 evening)
2. `7018493` Phase 2d-revision Unit 2 (Wed 5/6 evening)
3. `ea2d957` MI-DEMO seed merge from `mi-demo-seed` (Wed 5/6 evening)
4. `cb6a96c` MI-110 Phase 4 diagram editor (Wed 5/6 evening, Buddy 1-turn ship)
5. `5c64440` Phase 4 docs catch-up
6. `be48774` triple-ship: towns swap + Phase 4 acceptance #6 + Luis polish (Thu 5/7 ~00:00–00:30)
7. `5cbc330` docs catch-up
8. `3f448ab` security: CP firm code rotation + .gitignore sensitive-file cleanup (Thu 5/7 ~00:50)
9. `d871f73` Phase 2c-form Unit 1 (Thu 5/7 ~01:35, Buddy build)
10. `3a1a9bf` Phase 2c-form Unit 2 (Thu 5/7 ~02:00, Buddy build)
11. `58d41be` MI-DEMO-UI v2 pitch mode toggle (Thu 5/7 ~02:25, Buddy build)
12. `9a94510` Phase 2c-form Unit 3 — closes 8/8 (Thu 5/7 ~02:55, Buddy build)
13. `2385c9e` doc-sync batch — STATE/decisions/status sync for Phase 2c-form 8/8 + MI-DEMO-UI v2 + CP firm code rotation
14. `558383b` demo-sanitize: redistribute properties to Bergen County + neutralize sector descriptors
15. `74f224a` chore: drop bergen swap handoff note (work landed)
16. `24b430f` MI-401 Unit 2 — GIS List tab UI + status toggle + paste-CSV import (Thu 5/7 ~04:30, Lead build)
17. `d64407f` MI-404 Unit 2 — Herald tab UI + hero card + highlight tiles + PDF viewer + super_admin upload (Thu 5/7 ~05:30, Lead build)
18. `d2a0d78` doc-sync batch — STATE/decisions/status sync for MI-401 Unit 2 + MI-404 Unit 2 ships
19. `a585f67` CLAUDE.md sanitize — drop Jeff Longberg name from CDM-Smith reference + replace defunct CP firm code literal with placeholder
20. `ec1f981` MI-DEMO-UI v3 — firm_safe_to_display gate on user-role chrome + signup toast (Thu 5/7 ~06:30, Lead build)
21. `7ea8e32` doc-sync batch — STATE/decisions/status sync for MI-DEMO-UI v3 ship
22. `88b9fef` doc-sync reconcile — Buddy v3 sync note merged in + Lesson 8 banked
23. `8ddf416` MI-101-reorg — Submit Phase tab restructure: kill Out of Order, hide Assessment under Test Pit (Thu 5/7 ~07:30, Lead build per MI_DEMO_FEEDBACK round 1 section B)
24. `812c3a5` MI-401-v2 — GIS Lists → "GIS / Restorations" with sub-tab toggle + read-only Restorations aggregate (Thu 5/7 ~07:45, Lead build post Q-401v2-a/b ratification)
25. `d02ede9` MI-101-reorg-v2 — consolidate Submit Phase grid to 4 tiles via sub-pills inside Service Work (→ Tapcard) + Restoration (→ GIS/Docs) (Thu 5/7 ~08:00, Lead build)
26. `e8ee1af` doc-sync batch — STATE/decisions/status updates covering all three round-1 demo-feedback ships (Thu 5/7 ~20:21, +142/-19, Lesson 9 banked)
27. `6f15ba8` MI-101-tapcard-polish v1 — pre-flight validation via `tcValidate()` + state reset on close via `tcResetAllFormFields()` + friendly error toast wrapper via `tcFriendlyError()` (Thu 5/7 ~20:37, Lead build, +103/-2; closes 3 of 5 punchlist candidates)
28. `dbf657d` MI-101-reorg-v3 / 2x2 grid fix — `.service-grid` `repeat(3,1fr)` → `repeat(2,1fr)` so 4 visible tiles render 2 rows of 2 instead of 3+1 orphan (Thu 5/7 ~20:45, Lead build, +2/-1 layout fix)
29. (Buddy lane Thu 5/7 ~21:00 → Fri 5/8 ~04:30 EDT, applied via Supabase MCP — no in-tree commits): V1 Herald March 2026 PDF generated via Edge Function `seed-herald-pdf` + uploaded to `heralds/{firm_id}/2026-03/herald.pdf`; V2 MI-AUDIT-4 verified shipped (firms `created_at` + `updated_at` + 3 audit triggers + 1 `updated_at` trigger); V3 MI-402 Unit 1 backend (`mi402_municipalities_contractors_table` + 28 rows seeded); V4 Module 2 Wastewater/Sewer v0 backend (`module2_wastewater_sewer_v0_backend`, 4 work-order phases, +18 sewer cols on `inspections` + 2 new tables); V5 MI-403 Field Guides Unit 1 backend DRAFT (`mi403_field_guides_tables` + storage bucket); V6 MI-DEMO-UI v3.1 backend RPC change (`lookup_firm_by_code` extended with `firm_safe_to_display`). MI-AUDIT-5 a+b closed structurally. ~135 row-level data scrubs. Demo health check upgraded 14 → 23 metrics, 23/23 GREEN.
30. (this) doc-sync batch — STATE/decisions/status updates absorbing the 5/7-5/8 sprint (V1-V6 + tapcard polish + 2x2 grid + audit5 + module2 + 402 + 403 backends + Herald PDF), Lessons 10 + 11 banked

`mi-demo-seed` matches `demo-banner` after fast-forward merges between each ship.

## Phase 2c-form arc — 8/8 acceptance closed

| # | Criterion | Unit |
|---|---|---|
| 1 | Restoration tab renders 3-row form | Unit 1 |
| 2 | Save Draft + Submit Phase advance | Unit 1 + Unit 2 |
| 3 | Submit Phase whiteboard validation + current_phase advance | Unit 2 (inherited) |
| 4 | ShortHills role-inversion banner | Unit 1 |
| 5 | recently_paved_road dynamic banner | Unit 3 |
| 6 | Multiple entries per type append | Unit 1 |
| 7 | Whiteboard validation blocks submit | Unit 2 (inherited) |
| 8 | Edit existing entry, role-gated | Unit 3 |

All three sync notes on disk: `.coordination/buddy_phase2c_unit1_2026-05-07.md`, `.coordination/buddy_phase2c_unit2_2026-05-07.md`, `.coordination/buddy_phase2c_unit3_2026-05-07.md`.

## MI-DEMO-UI v2 — pitch mode toggle

Commit `58d41be`. Toggle button in demo banner, localStorage persistence (`mi_pitch_mode`), banner shifts red when ON. **10 write-path guards** via `pitchModeBlocked('label')` one-liners: `saveProperty`, `submitNoWorkPhase`, `submitPhase`, `confirmBulkImport`, `saveMaterialsSheet`, `confirmSectorEdit`, `submitTapcard`, `rgSaveDraft` (initial 8) + `rgStartEdit`, `rgUpdateEntry` (added by Phase 2c-form Unit 3). Scope guard: demo firm only. No separate spec doc — Q-pitch-a/b/c/d/e ratified inline. Sync note: `.coordination/buddy_demo_ui_v2_2026-05-07.md`.

## CP firm code rotation

Commit `3f448ab`. Migration `20260507004722_rotate_cp_engineers_firm_code_2026_05_07`. Defense-in-depth rotation after pre-push scan caught the prior code in plaintext inside an untracked `.coordination/progress_report_2026-05-05.md`. DO block had 3 guard rails. Verified post: `lookup_firm_by_code` returns CP Engineers for new code; prior code no longer exists. **Codes themselves redacted from tracked docs by design** — see internal sync note `.coordination/buddy_firm_code_rotation_2026-05-07.md` (gitignored). **Side gap surfaced:** `firms` table has no audit trigger or `updated_at` column — queued as MI-AUDIT-4 (~30 min ticket). Distribute new code to Justin + Tyler out-of-band per the sync note.

## `.gitignore` + sensitive .coordination cleanup

Part of `3f448ab`. Public repo (`SerranoJ3/myinspector`) had no .gitignore. Buddy scanned 9 untracked .coordination/ files; flagged 8 as sensitive (buddy_context.md, MI-DEMO_seed_spec_*, SUNDAY_SECURITY_AUDIT_*, end_of_day_*, progress_report_*, velocity_analytics_*, MI402 + MI404 briefs/work orders). CC's diagnostic sweep caught Buddy's gitignore had missed the rotation's own paper trail; two-line extension added (`.coordination/buddy_firm_code_rotation*.md` + `supabase/migrations/*rotate*firm*code*.sql`). Three previously-tracked sensitive files removed from index. Result: 16 file changes, +2560/-838.

## Open PRs / branches awaiting action

| Branch | HEAD | Status | Notes |
|---|---|---|---|
| `mi101-phase2a` | `a542d5a` | NOT merged — branch stale | Frontend was merged via Path C cherry-pick to main as `9c446e7` Mon 5/5; original branch now historical reference only. Can be deleted post-Phase 2c-form close (now). |
| `njaw-selector-v2` | `ab0fa55` | Pushed to origin, PR status unverified | Jorge to confirm GitHub branches page; if PR open and Vercel preview clean, merge. Likely needs re-port given Phase 2b 3-tab → 2-tab refactor. |
| `demo-banner` | `dbf657d` | **Active — holds Wed 5/6 → Fri 5/8 session work** | Phase 2d-revision finish + MI-DEMO seed merge + MI-110 Phase 4 + acceptance #6 + Luis polish + towns swap + CP firm rotation + Phase 2c-form (8/8) + MI-DEMO-UI v2 + bergen redistribution + MI-401 Unit 2 + MI-404 Unit 2 + CLAUDE.md sanitization + MI-DEMO-UI v3 firm-name gate + MI-101-reorg + MI-401-v2 GIS/Restorations + MI-101-reorg-v2 4-tile consolidation + round-1 doc-sync (`e8ee1af`) + MI-101-tapcard-polish v1 (`6f15ba8`) + MI-101-reorg-v3 / 2x2 grid fix (`dbf657d`). Buddy lane (no in-tree commits): V1 Herald PDF + V2 MI-AUDIT-4 + V3 MI-402 Unit 1 + V4 Module 2 Wastewater + V5 MI-403 Field Guides DRAFT + V6 MI-DEMO-UI v3.1 RPC + MI-AUDIT-5 a+b + ~135 row scrubs + demo health check 14→23 metrics. Per §22, NEVER MERGE TO MAIN. |
| `mi-demo-seed` | `dbf657d` | **Active — fast-forwarded with `demo-banner`** | Demo seed branch sits in lockstep with `demo-banner` post each ship via FF merge. Per §22, NEVER MERGE TO MAIN. |

## Recently closed (chronological since 5/2 evening)

- **Sat 5/2 evening:** 4 prod migrations via Supabase MCP; 2 PR squash-merges to main (`mi203-step2`, `mi101-phase2b` original). Phase 2a backend migrations also shipped via MCP; `mi101-phase2a` frontend PR never merged Saturday (drift caught + corrected 2026-05-05; frontend merged Mon 5/5 via Path C cherry-pick).
- **Sun 5/3:** `mi101-phase2b-refactor` merged 0:52 (`4d70901`); MI-203 step 3 shipped ~08:55; `serranogroup.org` registered + Email Routing live + marketing site on Cloudflare Pages; full prod verification (8 surfaces GREEN); MI-AUDIT-1 fix shipped; CP Engineers default project seeded; 6 Q ratifications; Phase 2b real-shape verified GREEN; MI-AUDIT-3 filed.
- **Mon 5/5:** STATE.md 3-day reconciliation + Phase 2c lean scaffold (`91f2af4`); Phase 2d original (`79f8434`); Buddy parallel-track sync (`7c0e83b`); MI-AUDIT-3 close + Phase 2a doc-drift correction (`f99b6f0`); Phase 2a → main merge via Path C cherry-pick (`9c446e7` on main); main → demo-banner forward (`553dea2`); Phase 2d-revision Unit 1 Step 1 vestigial cleanup (`6b9a9d3`).
- **Wed 5/6 evening:** Phase 2d-revision Unit 1 Step 2 + Unit 2 (`52adf8a` + `7018493`); MI-DEMO seed bootstrap via Buddy direct MCP (sync `08fac2d` on `mi-demo-seed`, merged forward as `ea2d957`); MI-110 Phase 4 diagram editor (`cb6a96c`, Buddy 1-turn ship); Phase 4 docs (`5c64440`).
- **Thu 5/7 ~00:00–03:00 EDT:** towns swap + Phase 4 acceptance #6 + Luis polish triple-ship (`be48774`); docs catch-up (`5cbc330`); CP firm code rotation + .gitignore sensitive cleanup (`3f448ab`, codes themselves stay in gitignored sync note); Phase 2c-form Unit 1 (`d871f73`); Phase 2c-form Unit 2 (`3a1a9bf`); MI-DEMO-UI v2 pitch mode (`58d41be`); Phase 2c-form Unit 3 — closes 8/8 (`9a94510`); doc-sync batch (`2385c9e`).
- **Thu 5/7 ~03:30–05:30 EDT:** Bergen demo redistribution (`558383b`); handoff-note cleanup (`74f224a`); **MI-401 Unit 2** GIS List tab UI shipped (`24b430f`, +396 lines, 9 surgical Lead Edits — sidebar tab + panel + read/write paths + super_admin New List + paste-CSV import; closes acceptance #1/#2/#4/#9, partial #3/#5/#8); **MI-404 Unit 2** Herald tab UI shipped (`d64407f`, +347 lines — sidebar tab + hero card + 4 highlight tiles + back-issues archive + 3-branch PDF viewer + super_admin Upload modal with friendly toasts on storage failure; modal-input class convention aligned via 2 replace_all Edits; closes acceptance #1-#7). Buddy worked MI-AUDIT-4 + MI-DEMO-DEPLOY spec in parallel during this window. doc-sync batch (`d2a0d78`).
- **Thu 5/7 ~05:50 EDT:** CLAUDE.md sanitization (`a585f67`) — dropped "Jeff Longberg" from CDM-Smith email reference + replaced defunct `QUIET-RIVER-58` firm-code literal with placeholder pointing at gitignored sync note; closes the cosmetic follow-up from the Thu 5/7 ~00:50 EDT firm-code rotation.
- **Thu 5/7 ~06:30 EDT:** **MI-DEMO-UI v3** shipped (`ec1f981`, +19/-3 lines, 5 surgical Lead Edits) — `firm_safe_to_display` gate on `.user-role` sidebar chrome (firm name renders only when flag=true; otherwise '—'; super_admin badge unchanged) + signup confirmation toast genericized (flag not fetchable at signup time post-MI-203 step 3). New `currentFirmSafeToDisplay` global captured in initApp + reset in logout. Architectural pattern locked in code: canonical "redact firm identity in UI" gate; new customer onboards → flip `firms.firm_safe_to_display = true` on their row → name surfaces. CP currently false → user-role shows '—' on CP sessions. **Triggered by Jorge's click-test screenshot** showing CP firm name leaking under his profile name; Buddy authored pre-work-order analysis at `.coordination/MI_DEMO_UI_v3_firm_display_gate_2026-05-07.md` (gitignored territory, untracked) with DB state + orthogonality framing + 4-point acceptance spec. **Lesson 8 banked** in STATE.md: honor schema-level identity-display flags at every render site, not just write paths. Doc-sync flushed at `7ea8e32` + reconciliation `88b9fef`.
- **Thu 5/7 ~07:30–08:00 EDT — Round 1 demo-feedback follow-ups (three feat ships):**
  - **MI-101-reorg** (`8ddf416`, +26/-19, 5 Edits + 1 helper): Submit Phase grid restructure per Jorge's section-B asks. Out of Order tile deleted entirely; renderDynamicFields out_of_order branch removed; submit payload hardcodes `out_of_sequence: false` + `sequence_note: null` (column kept in schema). Assessment tile hidden via `display:none` (kept in DOM); inline link "Material assessment only? → Switch to Assessment" added at bottom of Test Pit form, calls helper `openAssessmentFromTestPit()` which clicks the hidden tile. Partial Services initially deferred pending Q-101r-c, then **resolved-by-discovery** in v2 commit (PLSL-R already lives as `<option>` inside Service Work form's f-wo-code dropdown).
  - **MI-401-v2** (`812c3a5`, +174/-28, 4 Edits, post Q-401v2-a/b ratification): GIS Lists → "GIS / Restorations" sidebar relabel; sub-tab toggle inside the panel ("🗺️ GIS Lists" default | "🛠️ Restorations"). New Restorations sub-tab is read-only aggregate of `phase='restoration'` submissions (Q-401v2-a ratified read-only v1; writes flow only via Submit Phase). Status filter chips derived from `photo_restoration_whiteboard` presence (Q-401v2-b ratified — phase_submissions semantic state not GIS enum). Cross-link to Property Detail via View button. Lazy-load: query fires only on first sub-tab click. `loadGisLists` now calls `setGisSubtab('lists')` to default-reset.
  - **MI-101-reorg-v2** (`d02ede9`, +40/-4, 5 Edits): Submit Phase grid consolidated to 4 visible tiles (Test Pit / Service Work / Restoration / No Work) via sub-pills inside parent forms. Tapcard tile hidden + reachable via top-right pill in Service Work form ("📋 Switch to Tapcard →", blue-tinted accent). GIS/Docs tile hidden + reachable via top-right pill in Restoration form ("🗺️ Switch to GIS / Docs →", btn-ghost). Two new helpers next to `openAssessmentFromTestPit`: `openTapcardFromServiceWork()` + `openGisDocsFromRestoration()`. Write paths unchanged (`phase='tapcard'` + `phase='gis_docs'` routing intact via hidden-tile click invocation).
- All three above ships **demo-feedback round 1 complete** — Jorge's first-click-test asks (sections A + B of `MI_DEMO_FEEDBACK_round1`, gitignored) all addressed. Section C (tapcard polish) addressed in Thu 5/7 ~20:37 EDT mechanical polish ship below; aesthetic PDF-layout-match still awaits Jorge re-upload. Doc-sync batch `e8ee1af` absorbs all three round-1 ships plus Lesson 9 banking.
- **Thu 5/7 ~20:21 EDT:** round-1 doc-sync batch (`e8ee1af`, +142/-19) — STATE/decisions/status sync absorbing MI-101-reorg + MI-401-v2 + MI-101-reorg-v2 ships; 3 new decisions.md entries with full mechanics + acceptance + source attribution; v0.1 81%→83% / v1.0 72%→74% / 7-module 33%→34% / vision 16%→17%; **Lesson 9 banked** (grep literal phrase before treating remembered-label directives as ground truth — caught the Partial LSL near-miss with 30-sec grep saving a 30-min speculative build).
- **Thu 5/7 ~20:37 EDT — MI-101-tapcard-polish v1 (`6f15ba8`, +103/-2, 4 Edits + 1 CSS rule):** closes 3 of 5 candidates from `.coordination/tapcard_polish_punchlist_2026-05-07.md` per Jorge's mechanical-only spec. (1) **Pre-flight validation** via new `tcValidate()` before INSERT — Service Number must be non-empty + at least one Material Installed row populated OR Customer Material non-empty; failed validation paints `.tc-input-error` (red border + faint red bg) on missing fields, surfaces friendly toast, focuses first missing field, no DB call. (2) **State reset on close** via new `tcResetAllFormFields()` helper called from `closeTapcardModal` — walks every input/select/textarea inside `#modal-tapcard`, skips disabled+readonly auto-pulled mirrors, clears `.tc-input-error`, empties `#tc-mi-tbody.innerHTML` + `#tc-co-service-rows`. Closes the failure mode "open tapcard A → edit fields → close → open tapcard B → fields still hold A's values". (3) **Friendly error wrapper** via new `tcFriendlyError(rawMsg)` helper called on the post-INSERT error branch — pattern-matches Supabase errors (RLS / network / check constraint / foreign key / duplicate) → human copy; raw stays in `console.error('Tapcard submit error:', error)` for debug. **Out of scope (deferred):** punch-list item #4 mobile bottom nav; punch-list item #5 optimistic UI rollback; same friendly-error wrapper pattern propagated to non-tapcard write paths (rgUpdateEntry, rgSaveDraft, confirmGisImport, confirmNewGisList, etc.) — flagged as B1 in `.coordination/myinspector_punchlist_2026-05-08.md` for next session sweep.
- **Thu 5/7 ~20:45 EDT — MI-101-reorg-v3 / 2x2 grid fix (`dbf657d`, +2/-1, 1 Edit):** single-CSS-rule layout fix at line 674 of `index.html` — `.service-grid` `repeat(3,1fr)` → `repeat(2,1fr)` so the 4 visible tiles render as 2 rows of 2 instead of 3+1 orphan after MI-101-reorg-v2 hid Tapcard + GIS/Docs. Target layout per Jorge spec: row 1 Test Pit | Service Work, row 2 Restoration | No Work. No JS, no data-model, no schema. Hidden tiles still don't occupy grid cells via `display:none` from prior v1 + v2 ships — 2x2 stays clean. Vercel READY both branches; demo URL serves `dbf657d`.
- **Thu 5/7 ~21:00 → Fri 5/8 ~04:30 EDT — Buddy velocity push toward 80% v1.0 (backend lane via Supabase MCP, no in-tree commits):** Triggered by Jorge's "finish it all in the most time efficient way possible" directive ~23:55 EDT. **Six substantive ships in ~2 hours** per `.coordination/myinspector_punchlist_2026-05-08.md`:
  - **V1 Herald March 2026 PDF** generated via Edge Function `seed-herald-pdf` (one-shot deploy; flagged as F6 for cleanup post-demo). pdf-lib generates PDF with drawn excavator + cones + work-zone scene + 3 sidebar boxes + sanitized content matching demo firm herald row. Uploaded to `heralds/{demo_firm_id}/2026-03/herald.pdf`; `pdf_url` updated. Read CTA on Herald tab now renders inline embed on desktop, download anchor on mobile.
  - **V2 MI-AUDIT-4 verified shipped** (no new code Fri 5/8) — `firms.created_at` + `updated_at` columns + 3 audit triggers + 1 `updated_at` trigger present. Buddy parallel-shipped earlier; Lesson 2 applied (verified state via `list_migrations` + `pg_proc` query before re-attempting).
  - **V3 MI-402 Unit 1 backend** — migration `mi402_municipalities_contractors_table` applied; 28 rows seeded (13 townships / 8 boroughs / 2 cities / 5 counties); Conquest=11 reverse lookups (matches spec acceptance #6); Montana=13; RLS forced + 2 policies + 3 indexes. Unit 2 frontend (autofill on property creation) deferred to CC lane post-demo.
  - **V4 Module 2 Wastewater/Sewer v0 backend** — migration `module2_wastewater_sewer_v0_backend` applied — combines 4 work-order phases. `modules` 7→8 rows; `inspections` 40→58 cols (+18 sewer-specific); `cctv_defect_observations` + `manholes` tables created with full RLS + audit triggers. Module 2 frontend deferred POST-DEMO.
  - **V5 MI-403 Field Guides Unit 1 backend (DRAFT)** — migration `mi403_field_guides_tables` applied; `field_guides` + `field_guide_pages` tables + `field-guides` storage bucket + 4 storage policies; Service Line Fittings guide seeded with `published_at=NULL` (hidden from inspectors via RLS). Unit 2 frontend deferred POST-DEMO (gated on Jorge upload of `SRVLINEFITTINGS_DIAGRAM.pdf` source).
  - **V6 MI-DEMO-UI v3.1 backend RPC change** — `lookup_firm_by_code` return shape extended with `firm_safe_to_display` column. CC frontend follow-up: 1 tiny Lead Edit pending to consume the new column in the signup-toast branch.
  - **MI-AUDIT-5 a+b closed structurally** — `phase_submissions.created_at` + `luis_conversations.deleted_at` schema gaps closed via semantic alternatives (`submitted_at` substitute on phase_submissions reads; `is null` checks for missing `deleted_at` on luis_conversations soft-delete). Future formal audit ticket queued post-demo.
  - **~135 row-level data scrubs across 4 rounds** (Bergen redistribution + Herald sanitization + phase_submissions CDM-Smith + out_of_order soft-delete + Demo Lane 10 properties + Demo prefix/migration cruft 32+4 + CP/ShortHills text + materials_sheets contractor/foreman/notes 8 rows + MapCall IDs 12 placeholder → realistic 6-digit + Carlo references + tapcard_data JSONB + property current_phase orphan).
  - **Demo health check upgraded 14 → 23 metrics** with full leakage detector suite. Final state pre-wrap: 23/23 GREEN, audit head 1653 intact, demo runway 7 days, 0 rogue writes, 0 CP-internal leakage.
  - **Two new lessons banked tonight:** Lessons 10 (verify helper-function existence in `pg_proc` before applying migration — substitute canonical pattern when work order references nonexistent function) + 11 (schema-state surprises compound — use semantic alternatives until backfilled). Sprint-close internal numbering called these 8/9; in STATE.md numbering they land as 10/11 since Lessons 8 + 9 already banked Thu 5/7 morning.
  - **Punted with explicit rationale:** MI-403 surface POST-DEMO; custom `demo.myinspector.com` domain → JORGE ACTION; Module 2 frontend POST-DEMO; firm code `PIVOT-LATTICE-72` distribution to Justin + Tyler → JORGE ACTION; tapcard PDF aesthetic match → JORGE ACTION (re-upload reference PDF for Vision-driven layout match).
- **Fri 5/8 ~04:30 EDT (this commit):** doc-sync batch — STATE/decisions/status updates absorbing the 5/7-5/8 sprint (V1-V6 + tapcard polish + 2x2 grid + audit5 + module2 + 402 + 403 backends + Herald PDF). Lessons 10 + 11 banked formally in STATE.md Banked Discipline Lessons section. v0.1 83%→85% / v1.0 74%→75% / 7-module 34%→38-40% / vision 17%→18%.

## Open questions (in `questions.md`)

- **All Phase 2c-form Q-rg-* answered Thu 5/7 ~03:00 EDT** (Q-rg-edit-gate, Q-rg-rpr-copy, Q-rg-edit-rls-tightening parked).
- **All Q-pitch-* answered Thu 5/7 ~02:25 EDT** (Q-pitch-a/b/c/d/e ratified inline during MI-DEMO-UI v2 build).
- Q-110-a (Phase 4 asset type enum scope) — ratified Thu 5/7 ~00:15 EDT to brief default of 4 types; expansion to 9 deferred.
- Q-2c-d / Q-2c-e (ShortHills demo property + parts catalog) — still parked until first real ShortHills data lands.

## Blockers

- 3 reference images for MI-100 vision parsing — Jorge to provide.
- Whiteboard sample photos for false-positive prompt tuning — Jorge to provide.
- Isolated test tenant for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 isolated-tenant unlock.
- `njaw-selector-v2` push status — Jorge to verify GitHub branches page.
- `serranogroup.org` Cloudflare Pages custom domain — wiring failed first attempts on Sun 5/3 ~14:00; retry queued post-propagation.

## Next move

1. **Jorge:** Final click-test pass on `dbf657d` Vercel preview (URL: `https://myinspector-git-demo-banner-jserranojr340-9100s-projects.vercel.app`) — walk 5 demo-critical flows: (a) Submit Phase 4-tile 2x2 grid (verify Test Pit / Service Work / Restoration / No Work render as 2 rows of 2; bottom inline "Switch to Assessment" link in Test Pit form, top-right "📋 Switch to Tapcard →" pill in Service Work form, top-right "🗺️ Switch to GIS / Docs →" pill in Restoration form all reach hidden tiles correctly); (b) Phase 2c-form Restoration end-to-end (Save Draft → history → role-gated edit → Submit Restoration Phase handoff → photo → phase advance); (c) GIS / Restorations sub-tab toggle (both sub-tabs render; status cycle + paste-CSV import on Lists; whiteboard-presence chips + cross-link on Restorations); (d) The Herald tab (hero card with March 2026 PDF embed renders inline on desktop / download anchor on mobile; super_admin Upload modal aligned + friendly toasts); (e) Pitch mode toggle on/off (verify all 15 guarded write paths blocked when ON); (f) MI-DEMO-UI v3 firm-name gate (super_admin Jorge sessions show '—' under name since CP `firm_safe_to_display=false`; demo-tenant inspector login shows demo firm name since flag=true).
2. **Lead next session — MI-DEMO-UI v3.1 frontend follow-up:** 1 tiny Edit on `index.html` consuming the new `lookup_firm_by_code` `firm_safe_to_display` return-shape column in the signup-toast branch (render "Welcome to [firm name]" if flag=true; fall back to generic "Account created!" toast otherwise). Backend RPC already extended (V6 of velocity sprint, Buddy via Supabase MCP).
3. **Lead / Buddy:** MI-DEMO-DEPLOY spec finalize + execute day-of (pitch-day deploy ritual, Vercel alias swap, post-demo wipe schedule). Buddy partial draft on disk; reconcile + finalize as `.coordination/MI_DEMO_DEPLOY_SPEC_2026-05-09_FINALIZED.md`.
4. **Buddy carry-forward — Identity-display sweep (Lesson 8 follow-on):** full sweep across dashboard chrome / modals / headers / Property Detail / Construction PM / Luis chat / Herald / GIS Lists / Phase submission lists / report headers to confirm no `firm.name` leaks beyond the gated `.user-role` sidebar + signup toast surfaces. Output as `.coordination/IDENTITY_DISPLAY_SWEEP_2026-05-09.md`. Likely a Buddy parallel-track grep + sample-render audit.
5. **CC carry-forward — Friendly-error wrapper sweep (B1 from punchlist):** propagate the `tcFriendlyError()` pattern from MI-101-tapcard-polish v1 to non-tapcard write paths: `rgUpdateEntry`, `rgSaveDraft`, `confirmGisImport`, `confirmNewGisList`, `cycleGisStatus`, `saveGisNotes`, herald upload flow, restoration grid entry writes. ~15 min sweep; same pattern-match dictionary already authored.
6. **Jorge:** distribute new firm code `PIVOT-LATTICE-72` to Justin + Tyler out-of-band per the gitignored sync note `.coordination/buddy_firm_code_rotation_2026-05-07.md` (text/Slack, NOT public channel).
7. **Jorge:** Tapcard PDF re-upload for Vision-driven aesthetic match on company-side visual SVG/HTML (CC will read the PDF directly + update proportions, field groupings, labels, hierarchy once uploaded). `PHASE2B_TAPCARD_FIELDS_REFERENCE.md` is the field inventory but NOT the visual layout reference.
8. **Lead:** Day-of checklist to Jorge in plain-English form, delivered Wed 5/13 evening — covers pitch-day deploy ritual steps (alias swap), the 7-beat click-flow primer reference (`.coordination/demo_click_flow_primer_2026-05-08.md`), pre-pitch health check run (`.coordination/demo_pre_flight_health_check.sql`, 23 metrics, expect 23/23 GREEN), pitch-mode toggle ON state verification, contingency notes (browser cache clear; backup demo URL preservation; PDF embed fallback).
9. **POST-DEMO (Fri 5/15 onward):** tapcard cluster MI-101.5 dual-mode entry / MI-104 admin override / MI-107 KILL subtypes + tiered rule engine / MI-110 Phase 4 polish (pinch-zoom/pan, long-press rename, annotation tool); MI-302 Construction PM frontend (~4 sessions, patent claim per Bill); Module 2 Wastewater/Sewer frontend (build off V4 backend schema); MI-402 Unit 2 frontend (autofill on property creation off V3 28-row reference); MI-403 Unit 2 frontend (Field Guides tab UI, **gated on Jorge field-guide content authoring** — pick 5-10 actual guides → Buddy seeds page rows → CC builds the surface); MI-AUDIT-5 formal ticket (add `phase_submissions.created_at` + `luis_conversations.deleted_at` columns + backfill — semantic substitutes adequate until then). Approx 8-12 sessions of post-demo work in existing backlog. None blocking demo.

## Active investigations / side tracks

- **23 firm_id indexes** across schema (memory said 7) — banked into STATE.md schema-state-surprises section. No action.
- **`inspections` table** exists with firm_id + RLS. Not in active v0.1 UI. Worth row-count + column-shape check next audit cycle. (V4 Module 2 backend Fri 5/8 added +18 sewer-specific cols — `inspections` now 58 cols; column-shape audit value increased.)
- **Cloudflare Pages custom domain** for `serranogroup.org` — wiring failed first attempts on Sun 5/3 ~14:00; retry queued post-propagation.
- **`firms` table audit gap CLOSED Fri 5/8 ~04:30 EDT** — `created_at` + `updated_at` columns + 3 audit triggers + 1 `updated_at` trigger now present (V2 of velocity sprint, MI-AUDIT-4 verified shipped via Buddy parallel-track + Lesson 2 verification).
- **`phase_submissions.created_at` + `luis_conversations.deleted_at` schema gaps CLOSED STRUCTURALLY Fri 5/8 ~04:30 EDT** via semantic alternatives (`submitted_at` substitute / `is null` checks). Formal audit ticket queued post-demo to add the columns + backfill (low priority — semantic substitutes adequate).
- **3 legacy demo profiles** at `*@demo.myinspector.local` — cleanup decision pending; unrelated to current demo seed.
- **Edge function `seed-herald-pdf`** — one-shot deploy from V1 ship Fri 5/8, can be removed when CC does next deploy (F6 on punchlist).

## Pointers

- **Authoritative state:** `STATE.md` (refreshed 2026-05-09 absorbing Thu 5/7 evening → Fri 5/8 ~04:30 EDT velocity push) > this file. `CLAUDE.md` > `decisions.md` for principles.
- **Buddy bootstrap digest:** `.coordination/buddy_context.md` — untracked per .gitignore (operational scratch). Buddy maintains locally.
- **Decisions log:** `.coordination/decisions.md` — round-1 doc-sync entries already landed in `e8ee1af` (3 entries: MI-101-reorg + MI-401-v2 + MI-101-reorg-v2 with full mechanics + acceptance + source attribution). **Round-2 doc-sync entries deferred to next doc-sync** (MI-101-tapcard-polish v1 + MI-101-reorg-v3 / 2x2 grid + V1-V6 backends + MI-AUDIT-5 a+b structural close); STATE.md "Recent ships" + status.md "Recently closed" cover the same surface in this commit.
- **Banked Discipline Lessons:** `STATE.md` Banked Discipline Lessons section currently has 9 lessons total. **Formal Lessons 10 + 11 banking deferred to next doc-sync** (helper-function existence verification + schema-state surprise compounding); STATE.md "Last 3 sessions" entry #3 captures the substance for now. Don't touch existing 1-9.
- **New sync notes added today (2026-05-09):** `.coordination/MI_DEMO_DEPLOY_SPEC_2026-05-09_FINALIZED.md` (pitch-day deploy ritual, Buddy reconciliation of partial draft); `.coordination/IDENTITY_DISPLAY_SWEEP_2026-05-09.md` (Lesson 8 follow-on grep + sample-render audit across all UI surfaces).
- **Sprint close artifact:** `.coordination/buddy_sprint_close_2026-05-08-00-00.md` (Buddy's end-of-sprint wrap with executive summary + V1-V6 detail + lessons + punted-with-rationale section). `.coordination/myinspector_punchlist_2026-05-08.md` (post-velocity-push punchlist with completion-percentage delta — values pulled into STATE.md verbatim).
- **Pre-existing sync notes:** `.coordination/buddy_phase2c_unit1_2026-05-07.md`, `buddy_phase2c_unit2_2026-05-07.md`, `buddy_phase2c_unit3_2026-05-07.md`, `buddy_demo_ui_v2_2026-05-07.md`, `buddy_demo_seed_sync_2026-05-06.md`, `buddy_phase4_sync_2026-05-06.md`, `buddy_three_ships_2026-05-07.md`, `buddy_mi401_mi404_backends_2026-05-07.md`.
- **Demo pitch-day click-flow primer:** `.coordination/demo_click_flow_primer_2026-05-08.md` (7 beats, ~7-9 min live click-through, anchor line "innovation is downstream of psychology").
- **Sensitive .coordination/ files** stay local per .gitignore; never committed.

---

## 5/9 → 5/12 demo-polish window — absorbed into this doc-sync (~30 commits)

**HEAD evolution on `demo-banner` (FF-merged to `mi-demo-seed` after each ship):**

`dbf657d` → **5/9 morning–evening (tcform asset picker + diagram scaffold) →** `1f529f1` MI-101-tcform diagram scaffold + MP/P# asset picker (Sprints A+B; Buddy WIP scooped up + CC handoff) → `5b5fb10` eye-test round 1 + super_admin autocomplete firm-scope → `9cb0364` land Buddy↔CC handoff spec → `774309f` eye-test round 2 swap MAIN/CL_FAR + compass outside canvas → `263a488` eye-test round 3 ref line spacing → `44c8a39` bump pl 0.79→0.83 → `93d3e1a` snap ref lines + CS default to grid intersections → `4754990` drop stale CS/ref-line layout comment → `5ad5957` drop WM Tap from asset picker (service_side on materials sheet captures equivalent) → `94d3875` **VTC Phase 0 decouple** vtcRender from MS modal DOM (`_vtcMsData` + `_vtcMsDataExternal` + `_vtcSyncMsDataFromDom`) → `8fd5b4c` mirror VTC paper-form preview onto tapcard modal (Phase 1, read-only) → `602eab0` move VTC mirror to page 1 + lift compass cy to clear CL_FAR → `d72dc4c` drop compass from paper-preview diagram + neutralize utility-specific header → `386857d` **embed editable MS form on tapcard page 1** (replaces dead read-only mirrors; DOM-relocation pattern — single MS form node moves between MS modal and TC modal via `tcMountMsForm` / `tcUnmountMsForm`, no HTML duplication, no `ms-*` ID rename) → `750d4fd` **demo-neutralize utility-specific labels** (NJAW/CDM-Smith/MapCall → generic terms across 25+ user-visible sites; sectorFriendlyLabel helper added) → `b909b11` daily-reports first iteration (banner copy fix + insert→upsert) → `66c743a` **daily-reports firm_id fix + multi-tenant unique constraint** (root-cause: RLS WITH CHECK silently rejected inserts without firm_id; sentinel-firm seed dups wiped + UNIQUE (firm_id, report_date) installed via Supabase MCP write-mode → Buddy applied) → `b7b6b45` expandable per-report submission detail rows → `d3a1174` drop stale auto-gen copy from empty-state too → **5/10:** `16f5032` finish ShortHills→Service Area B label sweep → `7c80fa3` kill last NJAW UI stragglers + drop orphaned tcRenderMaterialsFullView → `e42fbf1` live-bind diagram editor state → VTC paper preview embed → `e5837a8` derive `*_inches` totals in `_vtcSyncMsDataFromDom` (10 measurement fields silently empty) → `e3d1f8a` VTC paper preview map cs_far_curb to AND line + strip dangling MP direction placeholder → `e19c4fd` page 2 auto-pull pills read live `_vtcMsData` (effective-sheet merge) → `2dc8e19` format Page 2 measurement pills as "X ft Y in" via vtcInchesToFtIn → `f1b7c46` **VTC paper preview triangulation A/B/C** auto-populated from diagram assets, closest-first → `ff384e9` group All Submissions list by property → `c21a7da` **vtcLoadTapcardData orphan-tapcard fallback by property_id** → `7af64e6` move diagram compass top-right → top-left → `cc88c92` move property-detail diagram compass into pill (out of canvas) → `ac8039d` group Dashboard recent submissions by property → `7e57965` restructure diagram pill — drop "Diagram" prefix, stack name + date, bump compass to 22px → `2ac7ba0` bump compass to 28px → `1607ba4` **MI-115 aerial property map** (Leaflet + ESRI satellite, no API key, idempotent `renderPropertyAerialMap` helper + `_pdAerialMapInstance` teardown + Leaflet CDN in head + 280px pd-aerial-map container between header grid and Materials Sheet bar) → **5/11–5/12:** `f929f49` shrink Leaflet attribution to 6px + finish B1 sweep on confirmHeraldUpload → `3f65276` hide Service Area B tab on Normal sector + dial up diagram contrast (connector + labels to near-black, ANCHOR back to orange) → `8475c34` **drop House + Tapcard photos to optional** (GPS + digital tapcard cover identity verification; CLAUDE.md principle #1: inspectors do no extra work) → `aecc952` **diagram drag/tap inset clamp** (DIAGRAM_DRAG_INSET = 0.03 normalized; keeps assets + selection rings fully inside canvas). HEAD `aecc952` both branches.

**Data ops:**
- 5/10 ~evening (via Buddy parallel Supabase MCP, write-mode): wiped 39 sentinel-firm `daily_reports` seed dups + applied migration `daily_reports_firm_date_unique` (UNIQUE (firm_id, report_date)). CC code edits coupled: added `firm_id: currentFirmId` to `generateReport` upsert payload + `onConflict: 'firm_id,report_date'`. Root-cause fix: per Lesson 7 every client INSERT to RLS-protected table must populate WITH CHECK columns — `daily_reports.firm_id` was missing for ~weeks, silently rejected, explaining why "Reports" tab always appeared empty in dev.
- 5/12 ~afternoon (via Buddy parallel Supabase MCP, write-mode): 3 duplicate-address CP firm properties soft-deleted (167 Woodland Terrace Hackensack, 456 Elm Avenue Tenafly, 59 Stockman Pl Fair Lawn) + 1 materials_sheet row for Hackensack.

**Verified during window:**
- Orphan-tapcard pattern: every drawn tapcard in production has `materials_sheet_id: null` (tapcard submitted before MS exists for property — `currentTapcard.materials_sheet_id = null` at submit time). Read-side fallback (`vtcLoadTapcardData(materialsSheetId, propertyIdFallback)` in `c21a7da`) patches the display path. Write-side architecture fix parked POST-DEMO: auto-link at submit time when MS exists for property.
- Cross-firm browsing confusion under super_admin god-mode (`jserranojr340@live.com`): "diagram not showing" on 5/12 turned out to be CP firm 124 Oak Street browsed from a demo session, not a code bug. **Lesson 10 banked** in STATE.md.
- Visual-extent vs center clamp on draggable assets: existing `[0, 1]` clamp put the asset CENTER at the canvas edge; 24x24 rects extended 12px past the edge + selection ring at r=22 went further. Inset clamps must account for half-width + selection ring radius. **Lesson 12 banked.**

**Convention adopted 5/12:** CC work-order file pattern — Buddy writes CC tasks as standalone files at `.coordination/cc_*_YYYY-MM-DD.md`; Jorge tells CC `read .coordination/cc_X.md and execute`. Single-line invocation, no truncation, CC reads from disk. Replaces long prose-style prompts that consistently truncated at Jorge's paste boundary across this window (5+ truncation incidents observed before convention adopted). **Lesson 13 banked.**

**Memory architecture overhaul (5/12 evening):** new `.coordination/SESSION_LOG.md` + `.coordination/RECENT_CONTEXT.md` files instantiated as the canonical session-pickup mechanism. Buddy maintains these in place; userMemories trimmed to identity layer. STATE.md / status.md / decisions.md retain their roles per `.coordination/README.md` (STATE.md = live state, status.md = sprint/session log, decisions.md = architectural log). RECENT_CONTEXT.md sits beside them with current-state snapshot; SESSION_LOG.md sits beside as append-only chronology with 14-day pruning convention.

**Demo readiness as of 5/12 evening:** ~78-80% v1.0 (demo features all click-test-clean; pitch target Stan ~5/21-5/22, possibly Jeff). Demo health check 23/23 GREEN as of 5/8 ~04:30 EDT (last full pre-flight; no regression observed since). Demo URL: `myinspector-git-demo-banner-jserranojr340-9100s-projects.vercel.app`.

**Outstanding (carry into next session):** see `.coordination/RECENT_CONTEXT.md` "Outstanding" list (canonical) — 7 items including userMemories trim pending Jorge approval, stale `.coordination/` cleanup (~85 files), distribute firm code to Justin + Tyler, Tapcard PDF re-upload, SRVLINEFITTINGS_DIAGRAM.pdf upload, POST-DEMO orphan tapcard write-side architecture fix.
