# Recent Context

**Purpose:** Current-state snapshot. What's true RIGHT NOW. Buddy reads this after `SESSION_LOG.md` to get the lay of the land without needing the auto-compaction summary or fat userMemories.

**Rules:**
- This file gets rewritten in place when state changes — not append-only
- If a section grows past ~15 lines, it's a sign it should move to its own `.coordination/` file
- Sprint history older than ~14 days lives in `SESSION_LOG.md` pruned entries OR existing per-ticket files, not here
- Pair with `SESSION_LOG.md` (chronology) and userMemories (identity)

---

## Right now

**Sprint:** MyInspector demo polish toward CP Engineers pitch ~5/21-5/22 (Stan, gated on Jeff approving first).
**Demo readiness:** ~85% to v1.0 as of 5/13 evening — OPS Dashboard + MI-302 Construction PM frontends shipped, dashboard is now genuinely single-pane-of-glass. Demo URL `myinspector-git-demo-banner-jserranojr340-9100s-projects.vercel.app`.
**HEAD:** `e660e6a` on both `demo-banner` and `mi-demo-seed`. Branches synced. Both Vercel deploys READY.
**Demo health:** 23/23 GREEN as of 5/8 ~04:30 EDT (last full pre-flight). Two new top-level surfaces added 5/13 (OPS Dashboard rewrite + Construction PM tab) — re-run pre-flight before Jeff demo recommended.
**Lawyer engagement:** Rabiyu engagement letter under review (received + reviewed 5/13). $5k retainer + 3 open questions queued before signing — see `.coordination/LEGAL_STATE.md` for full state.

## People in play

- **Stan** — CP Engineers owner. Target of pitch deck (11 slides locked, pricing: Essentials $99 / Pro $299 / Enterprise $1,499/mo).
- **Jeff** — possible additional pitch attendee.
- **Justin** (EIT) + **Tyler** (former home inspector) — beta testers. Names removed from pitch materials per legal flag; formal agreements needed before any public mention.
- **Abdul** — ASTM materials testing design partner. Validated 5/12.
- **Rabiyu** — lawyer, Wed 5/13 call.
- **Brett** — earlier outreach (see `buddy_brett_pre_staging_2026-05-09.md`).

## Tickets in flight

- **MI-200 (RLS)** — closed 4/27
- **MI-202 (audit_log + 4-layer immutability)** — build started 4/28, status check needed
- **MI-101 tapcard cluster** — MI-100/101/101.5/102/103/104/107 closed; MI-105 deferred
- **MI-115 aerial map** — shipped, integrated into property detail
- **MI-403 Field Guides** — pending SRVLINEFITTINGS_DIAGRAM.pdf upload (Jorge action)
- **MI-401-v2 GIS/Restorations** — read-only restoration sub-tab live; row click → Property Detail shipped 5/13
- **MI-OPS-DASHBOARD** — Units 1 (backend: 4 tables + RLS + seed) + 2 (frontend: schedule grid + tiles) SHIPPED 5/13. Unit 3 (PTO request flow + edit flows) deferred — plan at `.coordination/MI-OPS-DASHBOARD_BUILD_PLAN.md`. Q-OPS-1..10 ratification pending.
- **MI-OPS-HE Hours / Expenses** — Unit 1 backend SHIPPED 5/13 ~10:15pm EDT (migrations `expense_entries_schema_v1` + `expense_entries_demo_seed` 20 rows across 5 statuses). Triggered by Jorge eye-test gap (PTO not clickable + no calendar = need write surface). Architecture: Dashboard tiles navigate to Hours/Expenses tab (no inline modals); single tab w/ 3 sub-views (Hours / Expenses / PTO); supervisor pending-approval queue toggle; mock-sync to Ajeera/ADP with 2s delay + status flip + audit log. Unit 2 frontend CC work order ON DISK at `.coordination/cc_ops_he_unit2_2026-05-13.md`. Unit 3 pending Q-OPS-HE-b..h ratification (Q-OPS-HE-a ratified in chat). Build plan + Set C ratifications doc on disk. **Strategic rollup: ~$15,200/year labor savings at CP's 20-inspector scale; Enterprise $1,499/mo breaks even on labor alone in 14 months.**
- **MI-302 Construction PM** — Units 1 (backend already shipped pre-5/13) + 2 (frontend: 3 sub-views read-only, GPS warning UI, in-progress timer) SHIPPED 5/13. Unit 3 BLOCKED on Q-302-j Bill patent-claim review (schema = company-level, not per-worker — may conflict with claim). Plan at `.coordination/MI-302_CM-PM_BUILD_PLAN.md` §9.
- **Demo photo replacement** — 49 photos swapped placeholder → Pexels CDN URLs 5/13

## Tech stack snapshot

- **Repo:** `SerranoJ3/myinspector`
- **Branches:** `demo-banner` (active dev) + `mi-demo-seed` (kept in lockstep, ff-merge only)
- **Supabase project:** `wryitfoletwskkdqqwcw` (us-east-2)
- **Production URL:** `myinspector-psi.vercel.app`
- **Tool stack:** Claude Code CLI v2.1.123 on Asus, Filesystem MCP + Supabase MCP for Buddy, n8n for cross-agent coordination
- **Schema:** 13 public tables; `phase_submissions` is the live production table (not legacy `inspections`)
- **Build environment:** Agent Teams experimental flag enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

## Three Jorge accounts (cross-firm browsing gotcha)

| Email | Identity | Firm | Role |
|---|---|---|---|
| `demo-jorge@myinspector.io` | Demo Admin | demo (`99999999-...`) | super_admin |
| `jorge.serrano@cpengineers.com` | Jorge Serrano | CP (`d9b189a8-...`) | owner |
| `jserranojr340@live.com` | Jorge Serrano (Admin) | Serrano Group (`e99441da-...`) | super_admin god-mode |

When Jorge reports a UI bug, ALWAYS confirm which firm the data lives in before diagnosing — the "diagram not showing" issue on 5/12 turned out to be cross-firm browsing confusion, not a code bug.

## Outstanding (carry into next session)

**Progress 5/13 evening close — 7 of 14 items materially advanced (50% checkpoint).** Items 2/3/4/13 have drafts on disk awaiting Jorge to send/ratify. Items 5/6 fully shipped. Items 7 (this ticket) + architecture ticket MI-ARCH-001 filed as carry-forward.

1. **Doc-sync absorbing ~35+ commits + Lessons 10-16 banking** — STATE.md / status.md / decisions.md still behind. Lessons 14/15/16 now banked in STATE.md properly. SESSION_LOG + RECENT_CONTEXT current. CC work order at `.coordination/cc_doc_sync_2026-05-13_evening.md` ready to fire for the commit step. **Partial — STATE.md "Last 3 sessions" section + status.md + decisions.md still need 5/13 entries.**
2. **Bill patent-claim one-pager** (Jorge action) — **DRAFT READY** at `.coordination/BILL_PATENT_CLAIM_ONE_PAGER_mi302_2026-05-13.md`. 3-outcome format (A/B/C) makes Bill's reply easy. Send when ready. Required BEFORE MI-302 Unit 3 ships.
3. **Q-OPS-1 through Q-OPS-10 ratification** — **DRAFT READY** at `.coordination/RATIFICATIONS_PENDING_2026-05-13.md` (Set A). Q-OPS-1/2/7 effectively ratified by `14fb3c1` ship; 7 still need Jorge tick. Rapid-fire format — "approve all" works.
4. **Q-302-f/g/h/i ratification** — **DRAFT READY** at same file (Set B). Q-302-f ratified by `e660e6a` ship; Q-302-g flagged as MOOT (no `hourly_rate` column) with options (a) add column or (b) keep company-level; Q-302-h/i lean noted; Q-302-j blocked on Bill (item #2).
5. **Backlog migration file** — **SHIPPED** as `20260513225XXX_backlog_demo_data_writes_2026_05_13` migration. Banks the demo photo URL UPDATEs + GIS auto-link UPDATE that were applied via `execute_sql` (untracked) earlier today. Now reproducible from a fresh seed. Idempotent — safe to re-run.
6. **Project name scrub** — **SHIPPED** as `20260513222859_demo_project_name_scrub_njaw_identifiers` migration. "DEMO Lead Service Replacement Project" → "DEMO Service Line Project". "Demo LSL Replacement Program 2026" → "Demo Service Line Renewal Program 2026". NJAW identifiers fully purged.
7. **Architecture ticket POST-DEMO:** auto-link orphan tapcards at submit time when MS exists for property — **FILED** as `.coordination/MI-ARCH-001_orphan_tapcard_write_side.md`. Two implementation options analyzed (client-side vs trigger); migration plan drafted; Buddy recommends DB trigger pattern.
8. **Distribute firm code `PIVOT-LATTICE-72`** to Justin + Tyler out-of-band (Jorge action)
9. **Tapcard PDF re-upload** for Vision-driven aesthetic match (Jorge action) — may be obsolete given 5/10 tcform polish
10. **SRVLINEFITTINGS_DIAGRAM.pdf upload** for MI-403 Field Guides publish (Jorge action)
11. **Stale `.coordination/` cleanup** — ~85+ files; archive shipped handoffs to `.coordination/archive/2026-04/` and `.coordination/archive/2026-05-early/`. **NOT STARTED.**
12. **Request CP Engineers employee handbook** from HR (Rabiyu priority #1 — highest-priority legal action). Mentioned in Rabiyu reply draft (item #13) as parallel-track item.
13. **Reply to Rabiyu with 3 open questions** — **DRAFT READY** at `.coordination/RABIYU_REPLY_DRAFT_2026-05-13.md`. Body + tone notes + send timing recommendation included. Send when ready.
14. **Demo eye-test on `e660e6a`** — verify OPS dashboard renders for super_admin (schedule grid + tiles), Construction PM tab shows + hidden from inspector role, in-progress contractor pulses, 2 GPS-warning entries amber-flag. **✅ PASSED 5/13 ~10:00pm EDT** (with Montana → Meridian Construction scrub as side-fix per Lesson 17). Eye-test also surfaced architectural gap (PTO not clickable + no calendar) → MI-OPS-HE Hours / Expenses ticket filed + Unit 1 shipped same session.
15. **MI-OPS-HE Unit 2 CC work order fire** — ON DISK at `.coordination/cc_ops_he_unit2_2026-05-13.md`. Fire next session via `read .coordination/cc_ops_he_unit2_2026-05-13.md and execute`. Ships read paths + Dashboard rewiring. Ratify Q-OPS-HE-b..h in RATIFICATIONS_PENDING Set C first.
16. **MI-OPS-HE Unit 3 (write paths) build** — gated on Q-OPS-HE-b..h ratification + Unit 2 ship. Drafted post-Set-C-approval.

## Locked principles (operating constraints)

- **Inspector-tap economy:** no feature adds inspector taps without removing more elsewhere. Inspectors do no extra work for the app.
- **Privacy:** inspector GPS tracking firm-level, default OFF. Construction PM GPS (contractor tracking) is entirely separate.
- **Code style:** brief description + file location + Ctrl+F anchor + exact find/replace block. One edit per message, Jorge "yup" before next.
- **Buddy persona:** Jorge calls Buddy "buddy"; casual reciprocal tone; push back when motion looks decoupled from direction.
- **Demo theater:** static catalogs, fake modals, no real OAuth or audit_log writes from demo pages.
- **CDM-Smith rules locked 4/30/26:** no-work = house + whiteboard photos with reason; existing MP must be noted; CS replace requires Carlo auth with date/time/reason, no exceptions.
