# Coordination Status — MyInspector

**Last updated:** 2026-05-02 (session close, Lead — post-Phase-2a polish) EDT
**Updated by:** Lead (Claude Code CLI) — MI-101 Phase 2a + polish shipped on `mi101-phase2a` PR

---

## Current state

`main` HEAD: `6f80144` (docs session-close from prior turn). No new commits on `origin/main` since.

Three open PRs awaiting Jorge's review + Vercel preview verification:

| Ticket | Branch | Commits | PR URL |
|---|---|---|---|
| MI-203 step 2 (signup → `lookup_firm_by_code` RPC) | `mi203-step2` | `6abe03c` | https://github.com/SerranoJ3/myinspector/pull/new/mi203-step2 |
| Column-fix bug #3 (NJAW classification dropdown) | `njaw-selector` | `87173f0` | https://github.com/SerranoJ3/myinspector/pull/new/njaw-selector |
| MI-101 Phase 2a (Materials Sheet UI + polish) | `mi101-phase2a` | `04fd6b1` → `a542d5a` | https://github.com/SerranoJ3/myinspector/pull/new/mi101-phase2a |

`mi101-phase2a` has two commits on top of main: the Sections A–G form (`04fd6b1`, +839 lines on `index.html` + 3 SQL test ports + brief) and a polish stack (`a542d5a`, +136 lines: autocomplete datalists for free-text fields + history view on Property Detail with edit/restore actions). One-per-ticket honored — single PR.

## Buddy's parallel track (visible in working tree, not yet committed)

User flagged Buddy is parallel-shipping cleanup migrations + writing to `decisions.md` + `buddy_context.md`. Stashed locally (`git stash@{0}` named `buddy-wip-mid-session`) so this main commit doesn't trample Buddy's filesystem-MCP edits — will pop after this docs commit lands. Buddy is the source-of-truth for `decisions.md` mid-session per the parallel-track separation; check `decisions.md` + `buddy_context.md` latest entries after Buddy's next commit lands. Buddy will verify each of the 3 open PRs post-merge via Supabase MCP shape-check (same pattern banked for MI-100 / MI-108).

## Recently closed

- **MI-100 sector toggle** (PR #5 merged at `0327abd`)
- **MI-108 No-Work Submission Workflow** (PR #4 merged at `8a971eb`)
- **MI-109 CS Replacement Authorization Gate** (no change since `e76fac2`)
- **`compliance_events` id gap investigation** (Buddy 5/2 ~14:15 EDT)

Per buddy_context.md (working tree): MI-101 Phases 1a/1b/1c/1d/1e all shipped backend; Construction PM Oversight backend shipped; `firm_safe_to_display` flag shipped; soft-delete view rebuild done (CLAUDE.md principle #7); demo tenant seeded; dashboard.html shipped + security-audited. STATE.md is ~7 hours stale; defer to `buddy_context.md` + this file until Lead refreshes STATE.md at next major session boundary.

## Last 5 commits (origin/main)

- `6f80144` docs(.coordination): session-close — MI-203 step 2 + NJAW selector PRs pending verification
- `0327abd` feat(MI-100): Phase 2 frontend — Sector toggle (#5)
- `8a971eb` feat(MI-108): Phase 2b frontend + Phase 3 SQL tests (#4)
- `6bb1c8f` MI-108 backend + SG-001 Node 3 validation
- `dba854b` feat(SG-001 Node 2): instantiate .coordination/ channel + Rule #10 in BUDDY_STANDARD

## Open questions (in committed `questions.md`)

- **Q-2** (open) — `mi203-step2` + `njaw-selector` Vercel preview verification awaiting Jorge.
- **Q-7** (open, NEW this turn) — Materials Sheet autosave cadence (every-blur-dirty-tracking / 10s timer / explicit Save Draft sub-action / no autosave). Held from `mi101-phase2a` because audit_log volume math is ~25-30× current daily rate.

Q-3 (B2/B3 enums) and Q-4 (Phase 1c options, resolved) live on the `mi101-phase2a` branch's questions.md and will land in main when that PR merges. Q-5 (cs_replacement_authorizations immutability) and Q-6 (mentioned in buddy_context.md) are in Buddy's WIP — will land via Buddy's commit cycle.

## Blockers

- 3 reference images for MI-100 vision parsing — Jorge to provide
- Whiteboard sample photos for false-positive prompt tuning — Jorge to provide
- Isolated test tenant for MI-109.5 + MI-108 e2e walks
- **MI-108 Phase 3 test execution** — Supabase MCP `execute_sql` is read-only; INSERTs blocked even inside BEGIN/ROLLBACK. Run the three SQL files via SQL editor manually, or authorize a `create_branch` for write-capable testing.

## Next move

1. **Jorge** — spin Vercel preview for the 3 open PRs in any order:
   - `mi203-step2`: fresh signup with `QUIET-RIVER-58` succeeds; bad firm code shows error; firm name displays after login.
   - `njaw-selector`: NJAW classification dropdown visible on service_work tile, "Not specified" default, M2C/H2C/FULL/MP/TP/KILL options save to `phase_submissions.njaw_work_order_code`.
   - `mi101-phase2a`: Materials Sheet button on Property Detail; form save / edit / soft-delete / restore from history; all 3 enum chips (sky_condition / curb_box_location / service_side) accept the right values; cs_house Past Corner toggle stores negative; multi_tenant gates num_units; CHECK violations surface field-specific messages.
2. **Buddy** — once Q-2 flips to answered (preview green), ship MI-203 step 3 (single-line `DROP POLICY firms_read_anon` migration + verification queries).
3. **Buddy** — verify `mi101-phase2a` post-merge via Supabase MCP shape-check (insert a sample sheet, confirm 48-column row, confirm audit_log delta = +1, confirm hash chain populates). Same pattern as MI-100 / MI-108.
4. **Jorge** — answer Q-7 (autosave cadence) at convenience; Phase 2c absorbs implementation.
5. **MI-101 Phase 2b** (Tapcard pages) — DO NOT START without Buddy sync. Materials Sheet auto-attach behavior + parts catalog (Normal + ShortHills) are gating prerequisites per the brief's Forward Context.
6. **Construction PM Oversight frontend** — backend shipped per buddy_context.md but no frontend ticket scoped yet. Queue.
7. **STATE.md refresh** — file is ~7 hours stale at session close. Lead/Buddy at the next major session boundary.

## Active investigations / side tracks

- MI-204b — 6 unindexed `firm_id` columns identified in Buddy 5/2 PM survey (`phase_submissions`, `properties`, `cs_replacement_authorizations`, `documents`, `daily_reports`, `rfis`, `luis_conversations`). Plain `CREATE INDEX` recommended, awaiting Jorge's scope ack.
