# Buddy Context — Bootstrap Digest

**Generated:** 2026-05-02 13:15 EDT
**Stale after:** next session-close OR next major commit on main

---

## Where we are

- **MyInspector v0.1 Compliance Foundation** — ~20% through the v1.0 scope by session count.
- **MI-109 (CS Replacement Authorization Gate) closed** as of `e76fac2` (5/2 ~12:50 EDT). First production compliance gate live. CDM-Smith rule (c) enforced.
- **SG-001 Node 1 (Filesystem MCP for Buddy) live** as of 5/2 late. Buddy reads CLAUDE.md / STATE.md / repo files / branch artifacts directly — no Jorge couriering files to chat.
- **SG-001 Node 2 (`.coordination/` channel) instantiating right now** — this commit. Convention pattern, no new tech. Eliminates Buddy ↔ Lead courier loop.

## What just shipped (last 3 commits on main)

- `7d52454` — STATE.md: MI-109 closed bank
- `e76fac2` — MI-109 squash merge (PR #3)
- `4eb8ca6` — STATE.md: MI-109 Phase 4 closed via SQL coverage; MI-109.5 deferred

## What's pending right after this commit

1. **SG-001 Node 3** — Supabase read-only MCP install for Buddy. Project ref `wryitfoletwskkdqqwcw`. ~20 min OAuth + scope. Eliminates the SQL paste-loop pattern that ate the most session budget today.
2. **SG-001 Node 4** (optional) — GitHub MCP install. ~20 min PAT. Eliminates browser PR detours.
3. **BUDDY_STANDARD.md Rule #10** — formalize the `.coordination/` channel use pattern (Buddy posts to `questions.md` instead of chat for non-urgent asks; Lead writes `decisions.md` after every architectural call; status snapshot updated at every session boundary). This is on Buddy to draft, then Rule #9-gate the write.
4. **MI-108** — No-Work Submission Workflow (CDM-Smith rule a). HIGH priority, 2 sessions estimated. First real test of Nodes 2+3 working together — same SQL-heavy verification flow as MI-109 but should take ~half the courier time.

## Files to read at session open (in order)

1. `CLAUDE.md` — locked principles (audit chain, RLS, NJAW rules, CDM-Smith rules, anti-patterns)
2. `STATE.md` — slow-moving authoritative state (active gate tickets, last 3 sessions, next session plan)
3. `BUDDY_STANDARD.md` — working style (priority order: bulletproof > accurate > efficient; Rule #9 file-write gate)
4. `.coordination/status.md` — fast-moving working snapshot (this file's neighbor; may be more recent than STATE.md)
5. `.coordination/questions.md` — open Q queue
6. `.coordination/decisions.md` — recent resolved calls (only if researching a specific decision; otherwise skip)

If conflict: STATE.md > status.md for authoritative state. CLAUDE.md > decisions.md for principles.

## Working pattern that's locked

- **Code edits (>3 lines):** full-file replace, not surgical (BUDDY_STANDARD §7).
- **Rule #9:** Buddy posts file-write gate ("About to write [path] — [summary]. Confirm?") before any write via filesystem MCP. Per Jorge's request 5/2 PM: this is being relaxed for low-risk doc writes (markdown doc fixes where diff was already shown and trusted). Stays in force for SQL, code, security-sensitive, irreversible.
- **Tagged dollar-quotes (`$TESTBODY$`)** preferred over `$$` in any SQL file Buddy edits — filesystem MCP edit_file mangles `$$` (decision 5/2 ~11:00 EDT).

## Active investigations (not blocking)

- `compliance_events` id gap (5 rows seen Phase 1, MI-201 audit landed at id 11 — ids 6-10 unaccounted for). Sequence-advance-from-rolled-back-inserts most likely cause. Investigate before MI-203 design.
- MI-204 — index on `profiles.firm_id`. Perf only, every RLS predicate filtering by firm_id pays seq-scan cost without it.

## Blockers (Jorge-owned)

- 3 reference images for MI-100 vision parsing
- Whiteboard sample photos for false-positive prompt tuning
- Isolated test tenant for MI-109.5 manual e2e walk
