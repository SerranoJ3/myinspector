# Coordination Status — MyInspector

**Last updated:** 2026-05-02 (session close, Lead) EDT
**Updated by:** Lead (Claude Code CLI) — MI-203 step 2 + NJAW selector PRs pushed; main now carries MI-100 + MI-108 + dashboard.html

---

## Current state

`main` is at `0327abd` and carries:
- **MI-100 sector toggle** (PR #5 merged)
- **MI-108 No-Work submission workflow** (PR #4 merged)
- **dashboard.html** (Buddy ship, RPC-shape verified — see `decisions.md` 5/2 PM entry)

Two open PRs awaiting Jorge's Vercel preview verification:

| Ticket | Branch | Commit | PR URL |
|---|---|---|---|
| MI-203 step 2 (signup → `lookup_firm_by_code` RPC) | `mi203-step2` | `6abe03c` | https://github.com/SerranoJ3/myinspector/pull/new/mi203-step2 |
| Column-fix bug #3 (NJAW classification dropdown) | `njaw-selector` | `87173f0` | https://github.com/SerranoJ3/myinspector/pull/new/njaw-selector |

Status posted to `.coordination/questions.md` Q-2 — Buddy holds MI-203 step 3 (drop `firms_read_anon`) until Jorge confirms preview-green.

## Recently closed

**MI-100 sector toggle (CLOSED — merged as PR #5):** sector radio toggle on property creation, sector badge on property detail, edit confirmation modal. NJ6_NORMAL default. All 39 existing properties on NJ6 via column DEFAULT.

**MI-108 No-Work Submission Workflow (CLOSED — merged as PR #4):** No-Work tile in service grid, multi-step photo+reason flow, direct INSERT to `phase_submissions` with the four new columns. Phase 3 SQL tests draft-shipped; manual SQL editor run still pending (read-only MCP blocks programmatic execution, see Blockers).

**MI-109 — CLOSED** (no change since `e76fac2`).

**Compliance_events id gap investigation — CLOSED** (Buddy 5/2 ~14:15 EDT, see decisions.md).

## Last 5 commits (main)

- `0327abd` feat(MI-100): Phase 2 frontend — Sector toggle (#5)
- `8a971eb` feat(MI-108): Phase 2b frontend + Phase 3 SQL tests (#4)
- `6bb1c8f` MI-108 backend + SG-001 Node 3 validation
- `dba854b` feat(SG-001 Node 2): instantiate .coordination/ channel + Rule #10 in BUDDY_STANDARD
- `7d52454` STATE: MI-109 closed - PR #3 merged to main as e76fac2

## Branches not yet merged

- `mi203-step2` (`6abe03c`) — awaiting Vercel preview verification
- `njaw-selector` (`87173f0`) — awaiting Vercel preview verification

## Architectural calls banked in `decisions.md`

- MI-108 NB1–NB5 (phase enum value, two photo slots, CHECK no RPC, 20-char reason, no inspector toggle)
- `compliance_events` id gap closure (sequence advance + cleanup, not a chain breach)
- dashboard.html RPC-shape verification (5/2 PM Buddy)

## Open questions
- **Q-2** (open) — MI-203 step 2 + NJAW selector preview verification awaiting Jorge.

## Blockers

- 3 reference images for MI-100 vision parsing — Jorge to provide
- Whiteboard sample photos for false-positive prompt tuning — Jorge to provide
- Isolated test tenant for MI-109.5 + MI-108 e2e walks
- **MI-108 Phase 3 test execution** — Supabase MCP `execute_sql` is read-only; INSERTs blocked even inside BEGIN/ROLLBACK. Run the three SQL files via SQL editor manually, or authorize a `create_branch` for write-capable testing.

## Next move

1. **Jorge** — spin Vercel preview for `mi203-step2` and `njaw-selector` PRs; verify per-ticket acceptance:
   - MI-203 step 2: fresh signup with `QUIET-RIVER-58` succeeds end-to-end; bad firm code shows error; logged-in firm name displays correctly
   - NJAW selector: dropdown visible on service_work tile, "Not specified" default, M2C/H2C/FULL/MP/TP/KILL options save to `phase_submissions.njaw_work_order_code`
2. **Buddy** — once Q-2 flips to answered (preview green), ship MI-203 step 3: single-line migration dropping `firms_read_anon` policy + verification queries.
3. **MI-101 Phase 2** (tapcard 3-page form) — DO NOT START without Buddy sync. Brief at repo root: `MI101_PHASE2_FRONTEND_BRIEF.md`. Multiple architectural decisions (e.g. dual-mode entry per MI-101.5) need alignment before frontend build.
4. **MI-108 Phase 3 test execution** — run via Supabase SQL editor (paste each of the three test files; expect 7 + 4 + 4 PASS notices).
5. **BUDDY_STANDARD.md Rule #10** — formalize the `.coordination/` file-channel pattern (pending from prior session).
6. **SG-001 Node 4 (GitHub MCP)** — queued; pick up whenever convenient.

## Active investigations / side tracks

- MI-204 index on `profiles.firm_id` — perf only, queued.
