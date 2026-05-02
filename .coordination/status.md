# Coordination Status — MyInspector

**Last updated:** 2026-05-02 13:15 EDT
**Updated by:** Buddy (first instantiation post-MI-109 merge, SG-001 Node 2 trigger)

---

## Current ticket
**SG-001 Node 2** — `.coordination/` file channel instantiation. In progress (this commit). After this lands: SG-001 Node 3 (Supabase read-only MCP for Buddy).

**MI-109 — CLOSED** as of `e76fac2` (squash merge to main, ~12:50 EDT). PR #3 merged. Backend live on prod since 5/2 late. Frontend Carlo modal deploys via Vercel auto on this commit cascade.

## Branch
`main`, in sync with origin after `7d52454` (STATE.md MI-109 closure bank).

## Teammates
None active. Last Agent Team run was MI-109 Phase 2 (5/2), shipped clean via `ce2c2a5` fixup.

## Last 3 commits (main)
- `7d52454` STATE: MI-109 closed - PR #3 merged to main as e76fac2
- `e76fac2` MI-109 squash merge (PR #3 — backend + frontend + tests + docs)
- `4eb8ca6` STATE: MI-109 Phase 4 closed via SQL coverage; MI-109.5 deferred; pivot next session to SG-001 Node 2

## Open questions
None. (See `questions.md` — empty queue at first instantiation.)

## Blockers
- 3 reference images for MI-100 vision parsing (tapcard form, restoration card, admin screenshot) — Jorge to provide
- Whiteboard sample photos for false-positive prompt tuning — Jorge to provide
- Isolated test tenant for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 work

## Next move
1. Finish SG-001 Node 2 — commit these four `.coordination/` files; Buddy adds Rule #10 to BUDDY_STANDARD.md formalizing the file-channel pattern
2. SG-001 Node 3 — install Supabase read-only MCP for Buddy (project ref `wryitfoletwskkdqqwcw`); ~20 min OAuth + scope; eliminates SQL paste loops forever
3. SG-001 Node 4 (optional today) — GitHub MCP install; ~20 min PAT scope; eliminates browser PR detours
4. Test the new infrastructure on MI-108 (No-Work Submission Workflow, CDM-Smith rule a) — measure courier reduction vs MI-109 baseline

## Active investigations / side tracks
- `compliance_events` id gap (5 rows seen Phase 1, MI-201 audit landed at id 11; ids 6-10 unaccounted for). Sequence-advance-from-rolled-back-inserts most likely. Not blocking.
- MI-204 index on `profiles.firm_id` — perf only, queued.
