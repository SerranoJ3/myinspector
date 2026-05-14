# Session Log

**Purpose:** Append-only running log. Each session = one entry. Replaces what the auto-compaction summary tries (and fails) to do. Buddy reads this first thing every new session to pick up where the last one left off.

**Format per entry:** date header, 4-6 bullets max. If something needs more than 6 bullets it belongs in a separate `.coordination/` file referenced here.

**Rules:**
- Newest entries at the TOP (reverse chronological — Buddy reads top-down and stops when irrelevant)
- Never delete or rewrite past entries
- Anything older than ~14 days gets pruned to one summary line during the next session start
- Pair with `RECENT_CONTEXT.md` (current state) and existing per-ticket files in `.coordination/`

---

## 2026-05-13 (evening) — OPS Dashboard + MI-302 Construction PM frontends shipped end-to-end
- HEAD now `e660e6a` on both branches. Both Vercel deploys READY. Demo URL serves `e660e6a`.
- Two major feature plans drafted on disk (gitignored): `MI-OPS-DASHBOARD_BUILD_PLAN.md` (~350 lines, 3-unit thesis: single pane of glass replacing dashboard) + `MI-302_CM-PM_BUILD_PLAN.md` (~400 lines, patent-claim guarded). Built off BidGrid §0–§10 plan structure.
- Buddy lane: applied 2 schema migrations (`ops_dashboard_schema_v1` 4 new tables + RLS + audit, `ops_dashboard_demo_seed` 56 schedules + 40 hours + 4 PTO balances + 82 PTO transactions) + `mi302_demo_seed_v2` (5 additional contractor assignments + 10 arrivals + 9 departures + 1 in-progress shift + 2 GPS-warning entries). All via Supabase MCP `apply_migration`.
- CC lane: shipped OPS Dashboard Unit 2 (`14fb3c1`) + MI-302 Unit 2 (`e660e6a`) frontends. CC work orders consumed via disk-handoff pattern per Lesson 13.
- Demo photo replacement: 49 photo URLs across 5 categories swapped from `placehold.co` gray text-overlay placeholders to Pexels CDN URLs (curbstop / watermain / restoration / house / whiteboard). 0 stale placeholders remaining. Hotlink licensed for commercial use no attribution.
- Patent-claim discovery during MI-302 backend seeding: `contractor_assignments.contractor_role` is CHECK-constrained to `primary | subcontractor | specialty | other` (relationship type, not individual job title). Schema is COMPANY-level tracking, not per-worker. May conflict with Bill's patent claim if it required per-worker billable-hour verification. Flagged in `LEGAL_STATE.md` risk register + `MI-302_CM-PM_BUILD_PLAN.md` §9. **MI-302 Unit 3 (arrival/departure capture write paths) BLOCKED until Bill reviews one-pager.**
- Lesson 14 banked formally: "any 'did we already X' question gets verified against git refs + file content before answering, no exceptions" — surfaced from Buddy asking Jorge to run `git status` instead of reading `.git/refs` + `.git/logs/HEAD` directly via Filesystem MCP.
- Lesson 15 candidate banked: when canonical functions live under non-obvious names, query `pg_proc` first — `update_updated_at_column` exists only in `storage` schema; the public canonical is `gis_set_updated_at` (legacy name from MI-401 origin, reused across firms / heralds / phase_submissions / gis_lists / gis_list_entries). Lesson 10 deepening.
- Lesson 16 candidate banked: Postgres CTE multi-update writes against the same row in a single statement fail silently (only one write wins). Use sequential statements OR a single UPDATE with `CASE` when bulk-touching multiple columns on the same row. Surfaced during demo photo replacement — single CTE updated 36/49 photos; remaining 13 (service_work watermain + no_work whiteboard) had to ship in 3 follow-up UPDATE statements.
- Doc-sync deficit grows: STATE.md still at HEAD `1535612` per yesterday's entry; now 4 commits behind. Real STATE.md doc-sync queued for weekend or next-session-open.

## 2026-05-13 (late evening, ~9:30pm → ~11:30pm EDT) — Eye-test → Montana scrub → MI-OPS-HE Hours/Expenses Unit 1 backend ship + bucket + decisions banked
- **Demo eye-test PASSED** on `e660e6a` for the 5-point gate (OPS Dashboard renders / Construction PM tab visible + role-gated / in-progress contractor pulsing / GPS warnings amber-flagged / 49 Pexels photos clean). One side-fix surfaced and shipped during eye-test: **Montana Construction (DEMO) flagged as real-world leak** — Montana Construction is Jorge's actual day-job contractor on the NJAW LCRI project. Rename to Meridian Construction (DEMO) shipped via migration `demo_scrub_montana_construction_real_world_contractor` + scrubbed across STATE.md (2 places) + status.md + MI-302 build plan (3 places) + Bill patent-claim one-pager. **Lesson 17 banked**: a `(DEMO)` suffix is a tag, not a filter — redact real-world names at source rather than suffix-tagging them. Same failure mode as MI-DEMO-TOWNS sweep on Thu 5/7. Standing rule extends to future modules (BidGrid contractor seed, Module 2 wastewater seed, any pitch-surfacing module).
- **Architectural gap surfaced from eye-test**: PTO not clickable on Dashboard + no calendar in the app at all. Resolved to same insight — Dashboard is a glance surface, needs a paired write surface. Jorge's playback locked the architecture: "days worked in calendar on dashboard … click to interact → Hours/Expenses tab → auto funnel to Ajeera + ADP."
- **MI-OPS-HE ticket filed + Unit 1 backend shipped same session** (Buddy via Supabase MCP, ~15 min after architecture lock): migration `expense_entries_schema_v1` (new table + RLS forced + 5 policies + audit/`gis_set_updated_at` triggers + 4 indexes) + migration `expense_entries_demo_seed` (20 entries across 5 statuses: 10 synced $564 / 3 approved $133 / 4 submitted $287 / 2 draft / 1 denied $85; 5 categories: 8 mileage / 4 per_diem / 5 receipt / 2 equipment / 1 other; legitimate generic vendors: Wawa, Home Depot, Lowe's, United Rentals, Shell, Amazon; Pat Morgan as approver).
- **MI-OPS-HE Q-OPS-HE-d pre-action**: shipped `expense-receipts` storage bucket via migration `expense_receipts_bucket_setup` — PRIVATE bucket (signed URLs only), 10MB limit, 5 allowed MIME types (JPEG/PNG/HEIC/WebP/PDF), 4 RLS policies on storage.objects (firm-scoped read, own-folder-or-supervisor insert/update, super_admin-only delete). Path convention `expense-receipts/{firm_id}/{inspector_id}/{uuid}.{ext}`. Unblocks Unit 3 receipt capture.
- **Build plan + CC work order drafted to disk** (both gitignored via newly-added `MI-OPS-HE_*.md` + existing `cc_*.md` patterns): `.coordination/MI-OPS-HE_HOURS_EXPENSES_BUILD_PLAN.md` (~470 lines, 3 units, 8 Qs, strategic rollup §10 with $15.2K/yr labor-savings math) + `.coordination/cc_ops_he_unit2_2026-05-13.md` (~470 lines, full Unit 2 spec: sidebar tab placement, 3 sub-view containers, 11 read functions, Dashboard rewiring with 3 onclick handlers + integration badge live timestamps, CSS guidance, role gating, acceptance criteria).
- **Q-OPS-HE-a ratified in chat** (single "Hours / Expenses" tab with 3 sub-views — NOT two separate tabs). Q-OPS-HE-b..h queued in `RATIFICATIONS_PENDING_2026-05-13.md` Set C with rapid-fire approve path.
- **Doc-sync absorbed**: STATE.md (Active tickets new MI-OPS-HE row, Last 3 sessions addendum on entry #1, completion percentages bump v0.1 89%/v1.0 87%/7-module 45%, Lesson 17 full writeup ~50 lines), RECENT_CONTEXT.md (Tickets-in-flight + Outstanding items 14/15/16), decisions.md (4 new entries: Montana scrub + MI-OPS-HE ticket file + Q-OPS-HE-a ratification + bucket setup), this SESSION_LOG entry, .gitignore extended (MI-OPS-HE_* + MI-OPS-DASHBOARD_* + MI-302_CM-PM_* patterns).
- **Working mode**: Jorge confirmed full-agency mode mid-session ("were a team buddy, i pick up the slack where i as a human can offer my intuition. beyond that. get it done"). Buddy executed the architectural-gap response autonomously: ship backend → write build plan → write CC work order → pre-act on Q-OPS-HE-d bucket → bank decisions → close out doc-sync. No CC involvement tonight; Unit 2 fires next session via `read .coordination/cc_ops_he_unit2_2026-05-13.md and execute`.

## 2026-05-13 (afternoon) — 5/12 work confirmed shipped + legal lane initiated
- CC sanity check confirmed pill fix + MEMORY_ARCHIVE.md from 5/12 evening DID land — bundled as cargo into two "Demo legal hygiene" commits (`5ef5f228` + `0dec675e`) and the pill-specific commit `494bdb3`. Previous 5/12 entry's "Edits sit uncommitted; CC task will commit + push" line is superseded. `cc_diagram_pill_push_2026-05-12.md` task was never executed under that name but its substance is shipped.
- Rabiyu engagement letter received + reviewed ~2:23pm EDT. $5k retainer, CP Engineers employee handbook review prioritized by Rabiyu, 3 open questions queued before signing.
- New legal-lane state file shipped: `.coordination/LEGAL_STATE.md` (~70 lines — retainer terms, open questions, Jorge actions, risk register, correspondence log). Gitignored. Commit `1535612` on both branches.
- HEAD now `1535612` on `demo-banner` + `mi-demo-seed`. Branches synced. No MI code shipped today.
- Lesson 14 candidate banked: §2 diagnose-before-fixing violated when Buddy asked Jorge to run `git status` instead of verifying repo state via filesystem MCP directly. Standing rule: any "did we already X" question gets verified against git refs + file content before answering, no exceptions.
- Doc-sync deficit: 15+ commits between `aecc952` (last documented HEAD) and `1535612` not yet absorbed into status.md / STATE.md chronological lists. Real doc-sync queued for weekend.

## 2026-05-12 (late evening) — pill fix queued + memory overhaul executed
- Diagram pill + cl_far overlap fixed via three surgical edits to `index.html` (cl_far 0.18→0.20, pill flex column→row with 3-row text col, robust regex date/time split). Edits sit uncommitted; CC task at `.coordination/cc_diagram_pill_push_2026-05-12.md` will commit + push.
- Memory overhaul **executed**: 26 entries → 8 (-69%). 18 entries archived to `MEMORY_ARCHIVE.md` at repo root, organized by topic with cross-refs to BUDDY_STANDARD.md §7 / SESSION_LOG.md / RECENT_CONTEXT.md for redundant entries. Memory #26 updated to point at the archive.
- Lesson banked: "shipped" means deploy surface has it, not just disk. Buddy declared "shipped" prematurely; Jorge reported "looks the same" because Vercel was serving commit `1c43214` (4hrs old). Going forward, verify via `Vercel:web_fetch_vercel_url` before declaring done.
- Ready for Claude product-update restart — clean state, single CC task pending execution.

## 2026-05-12 (evening) — demo polish day 2 + memory architecture
- HEAD `aecc952` on `demo-banner` and `mi-demo-seed` (both synced)
- Shipped: `3f65276` Service Area B tab gate + diagram contrast revision; `8475c34` cardinal photos to optional (House + Tapcard on test_pit, Tapcard on service_work); `aecc952` diagram drag/tap inset clamp (0.03 normalized inset, keeps assets + selection rings inside canvas)
- Data: 3 duplicate-address CP firm properties soft-deleted (167 Woodland Terrace, 456 Elm Avenue, 59 Stockman Pl)
- Verified: orphan-tapcard fallback (commit c21a7da) works on 124 Oak Street CP firm — read-side patch is solid; write-side architecture ticket parked POST-DEMO
- Convention adopted: Buddy writes CC tasks as standalone files at `.coordination/cc_*_YYYY-MM-DD.md`; Jorge tells CC `read .coordination/cc_X.md and execute` (avoids prompt truncation in CC terminal)
- Decided: memory architecture overhaul — this file + `RECENT_CONTEXT.md` become the canonical session-pickup mechanism; userMemories trimmed to identity layer

## 2026-05-11 — Rabiyu legal call rescheduled to Wed 5/13
- (carried over from prior compacted session)

## 2026-05-10 — ASTM module locked as MI back burner post-v1.0
- Abdul validated + spec'd as design partner during 5/12 phone call
- Spec at `MI-ASTM-SPEC.md` (root of repo)
- Tabs: concrete / soils / rebar / masonry / welding
- Photo-of-tag → autofill daily report; preloaded job specs + proctor/sieve
- Luis advises only, never adjudicates pass/fail (E&O risk)
- Cert/license tracker is CORE (not parked) — OSHA10+/ACI/NICET, 90/60/30 expiration alerts

---

*For sprint history before 2026-05-10, see existing `.coordination/buddy_*` handoff files and the userMemories "Brief history" section.*
