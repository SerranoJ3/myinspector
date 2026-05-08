# Coordination Status — MyInspector

**Last updated:** 2026-05-07 ~08:15 EDT (post MI-101-reorg + MI-401-v2 + MI-101-reorg-v2 ships)
**Updated by:** Lead (Claude Code CLI) — doc-sync flush covering three demo-feedback-driven feat commits: `8ddf416` MI-101-reorg (kill Out of Order, hide Assessment under Test Pit), `812c3a5` MI-401-v2 (GIS Lists → "GIS / Restorations" with sub-tab toggle + read-only Restorations aggregate), `d02ede9` MI-101-reorg-v2 (consolidate to 4 tiles via sub-pills in Service Work + Restoration). All three close round 1 of Jorge's first-click-test feedback (`MI_DEMO_FEEDBACK_round1`). Lesson 9 candidate banked.

---

## Current state

**Active branches:** `demo-banner` and `mi-demo-seed` both at `d02ede9` (MI-101-reorg-v2 — Submit Phase grid consolidated to 4 tiles via sub-pills). main untouched per §22.

**Local main is 1 behind `origin/main`.** Missing commit is `4d70901` (Phase 2b refactor squash merge, Sun 0:52). Run `git fetch && git checkout main && git pull` to catch up before any new branch off main.

**Wed 5/6 → Thu 5/7 commits in order on `demo-banner`:**
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
26. (this) doc-sync batch — STATE/decisions/status updates covering all three round-1 demo-feedback ships

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
| `demo-banner` | `d02ede9` | **Active — holds Wed 5/6 → Thu 5/7 session work** | Phase 2d-revision finish + MI-DEMO seed merge + MI-110 Phase 4 + acceptance #6 + Luis polish + towns swap + CP firm rotation + Phase 2c-form (8/8) + MI-DEMO-UI v2 + bergen redistribution + MI-401 Unit 2 + MI-404 Unit 2 + CLAUDE.md sanitization + MI-DEMO-UI v3 firm-name gate + MI-101-reorg + MI-401-v2 GIS/Restorations + MI-101-reorg-v2 4-tile consolidation. Per §22, NEVER MERGE TO MAIN. |
| `mi-demo-seed` | `d02ede9` | **Active — fast-forwarded with `demo-banner`** | Demo seed branch sits in lockstep with `demo-banner` post each ship via FF merge. Per §22, NEVER MERGE TO MAIN. |

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
- All three above ships **demo-feedback round 1 complete** — Jorge's first-click-test asks (sections A + B of `MI_DEMO_FEEDBACK_round1`, gitignored) all addressed. Section C (tapcard polish) still awaits Jorge specs. Doc-sync batch (this commit) absorbs all three plus Lesson 9 candidate banking.

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

1. **Jorge:** distribute new firm code to Justin + Tyler out-of-band per the gitignored sync note `.coordination/buddy_firm_code_rotation_2026-05-07.md` (text/Slack, NOT public channel).
2. **Jorge:** Vercel preview click-test pass on `demo-banner` alias — round 2 of demo-feedback. Walk:
   - **Submit Phase grid** (verify 4 tiles: Test Pit / Service Work / Restoration / No Work): click Test Pit → bottom inline "Switch to Assessment" link works; click Service Work → top-right "📋 Switch to Tapcard →" pill works; click Restoration → top-right "🗺️ Switch to GIS / Docs →" pill works.
   - **GIS / Restorations tab** (verify v2 restructure): sidebar shows "🗺️ GIS / Restorations"; tab opens to GIS Lists sub-tab; click "🛠️ Restorations" pill → table renders reverse-chrono with whiteboard-presence chips (All / With whiteboard / Missing); search filters across address+city+work code; clicking View opens Property Detail.
   - Phase 2c-form flow + The Herald tab.
   - **MI-DEMO-UI v3 firm-name gate**: login as demo-tenant inspector → user-role shows demo firm name; login as CP inspector → user-role shows '—'; super_admin badge always renders; signup flow shows generic toast.
   - For Herald: open tab as inspector to verify August 2025 hero card + Photo of Month tile, then super_admin to upload the actual August 2025 PDF via the Upload modal.
3. **Lead / Buddy:** MI-DEMO-DEPLOY spec finalize + execute day-of (pitch-day deploy ritual, Vercel alias swap, post-demo wipe schedule). Buddy was drafting in parallel during MI-401/404 build window.
4. **Lead next session:** MI-AUDIT-4 (firms audit trigger + `updated_at` column, ~30 min security gap close) — Buddy may have shipped this already in the parallel-track work; reconcile before re-shipping (Lesson 2).
5. **Optional polish (if buffer remains, none demo-blocking):** MI-401 Unit 3 (supervisor stats + address autocomplete + CSV export); MI-401 fuzzy-match candidates UI; MI-401 mobile card view; MI-DEMO-UI v3.1 — backend RPC change to surface `firm_safe_to_display` in `lookup_firm_by_code` so the signup toast can be selectively gated rather than always-generic.
6. **Identity-display sweep (Buddy v3 carry-forward):** post-v3 ship, full sweep of every UI surface that could surface identifying material — verify dashboard chrome / modals / headers / Property Detail / Construction PM / Luis chat / Herald / GIS Lists / Phase submission lists / report headers don't leak `firm.name` or equivalent. Likely a Buddy parallel-track grep + sample-render audit.
7. **Pattern extension (Buddy v3 carry-forward):** consider whether `person_safe_to_display`, `project_safe_to_display` flags should join `firm_safe_to_display` as schema-level identity-display gates. Punt to a dedicated ticket when first cross-firm reporting surface lands.
8. **Demo pre-flight health check (Buddy v3 carry-forward):** add a `firm_unsafe_displayed` metric to `.coordination/demo_pre_flight_health_check.sql` (mechanism punted; metric belongs in the pre-flight checklist).

## Active investigations / side tracks

- **23 firm_id indexes** across schema (memory said 7) — banked into STATE.md schema-state-surprises section. No action.
- **`inspections` table** exists with firm_id + RLS. Not in active v0.1 UI. Worth row-count + column-shape check next audit cycle.
- **Cloudflare Pages custom domain** for `serranogroup.org` — wiring failed first attempts on Sun 5/3 ~14:00; retry queued post-propagation.
- **`firms` table audit gap** — no audit trigger, no `updated_at` column. Tonight's CP firm_code rotation surfaced this. Queued as MI-AUDIT-4 (~30 min).
- **3 legacy demo profiles** at `*@demo.myinspector.local` — cleanup decision pending; unrelated to current demo seed.

## Pointers

- **Authoritative state:** `STATE.md` (refreshed Thu 5/7 ~03:00 EDT) > this file. `CLAUDE.md` > `decisions.md` for principles.
- **Buddy bootstrap digest:** `.coordination/buddy_context.md` — untracked per .gitignore (operational scratch). Buddy maintains locally.
- **Decisions log:** `.coordination/decisions.md` — 4 new entries appended in this commit (Phase 2c-form Unit 1 + Unit 2 + Unit 3 + MI-DEMO-UI v2).
- **Sync notes:** `.coordination/buddy_phase2c_unit1_2026-05-07.md`, `buddy_phase2c_unit2_2026-05-07.md`, `buddy_phase2c_unit3_2026-05-07.md`, `buddy_demo_ui_v2_2026-05-07.md`. Plus pre-existing `buddy_demo_seed_sync_2026-05-06.md`, `buddy_phase4_sync_2026-05-06.md`, `buddy_three_ships_2026-05-07.md`.
- **Sensitive .coordination/ files** stay local per .gitignore; never committed.
