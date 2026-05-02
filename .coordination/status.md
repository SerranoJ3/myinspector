# Coordination Status — MyInspector

**Last updated:** 2026-05-02 (later) EDT
**Updated by:** Lead (Claude Code CLI) — MI-108 Phase 2b frontend built on `mi108-frontend` branch; test execution blocked by read-only MCP

---

## Current ticket
**MI-108 — No-Work Submission Workflow (CDM-Smith rule a)**
- **Phase 1 (verification):** ✅ DONE. Schema inventory + trigger inventory + phase enum + RPC inventory all banked via Supabase MCP queries.
- **Phase 2a (backend):** ✅ DONE. Migration `mi108_no_work_submission_workflow` applied to prod 2026-05-02 ~13:50 EDT. Adds 4 columns (`photo_house_url`, `photo_no_work_whiteboard_url`, `photo_no_work_whiteboard_detected`, `no_work_reason`), extends phase enum to 9 values, adds `phase_submissions_no_work_invariant` CHECK constraint. Existing 33 submissions unaffected (gated on `phase='no_work'`).
- **Phase 2b (frontend):** ✅ BUILT on branch `mi108-frontend`. Adds No-Work tile + flow in `index.html` (~281 line addition): tile in service grid, dynamic-form section with house photo + whiteboard photo + reason textarea, direct upload to `inspection-photos` bucket using same compression (2600px / JPEG 0.85), `detect-whiteboard` Edge Function call on whiteboard photo, direct INSERT to `phase_submissions` with new columns. Pre-flight client validation mirrors `phase_submissions_no_work_invariant` CHECK so users get field-specific errors. PR pending on this commit cascade.
- **Phase 3 (tests):** ✅ DRAFTED. `tests/mi108/no_work_constraint_test.sql` (7 tests, $TESTBODY$ tags), `audit_integrity_test.sql` (4 tests including hash-chain verification), `rls_test.sql` (4 tests, full mi109-style fixture seeding with auth.users + profiles + 2 firms + 2 no_work submissions). All firm_id values use NULL (nullable column, no FK violation needed) for constraint/audit tests; RLS test seeds real firms.
- **Phase 3 (test execution):** 🔴 BLOCKED. `mcp__supabase__execute_sql` enforces a read-only transaction wrapper at the MCP layer — INSERTs raise `25006: cannot execute INSERT in a read-only transaction` even with BEGIN/ROLLBACK in the test. Two unblocking options: (a) run the three SQL files manually via Supabase SQL editor (mirrors MI-109 Phase 4 pattern), or (b) authorize a Supabase branch via `mcp__supabase__create_branch` (billable). **Awaiting Jorge's call.**

**Architectural calls banked in `decisions.md`:**
- NB1 phase enum value (not flag)
- NB2 two separate photo slots (house + whiteboard)
- NB3 CHECK constraints + direct INSERT (no RPC)
- NB4 reason min 20 chars
- NB5 ship without inspector toggle

**SG-001 — DONE for the day.** Nodes 1, 2, 3 live. Node 4 (GitHub MCP) deferred. Node 3 first-migration validation complete on this MI-108 backend write — round-trip ~4 minutes vs estimated 15-20 min pre-MCP.

**MI-109 — CLOSED** (no change since `e76fac2`).

## Branch
`mi108-frontend` — branched off `main` at `6bb1c8f`. Pending changes: index.html (+281 lines), three test files in tests/mi108/ rewritten/normalized to $TESTBODY$ tags. Not yet pushed; PR opens after this status update commits.

## Teammates
Lead (Claude Code CLI) shipped MI-108 Phase 2b + tests on `mi108-frontend`. Test execution blocked at the MCP layer — Buddy or Jorge to run the three SQL files via Supabase SQL editor before merge.

## Last 3 commits (main)
- `7d52454` STATE: MI-109 closed - PR #3 merged to main as e76fac2
- `e76fac2` MI-109 squash merge (PR #3 — backend + frontend + tests + docs)
- `4eb8ca6` STATE: MI-109 Phase 4 closed via SQL coverage; MI-109.5 deferred

(Pending today: SG-001 Node 2/3 docs + MI-108 backend brief.)

## Open questions
None.

## Blockers
- 3 reference images for MI-100 vision parsing — Jorge to provide
- Whiteboard sample photos for false-positive prompt tuning — Jorge to provide
- Isolated test tenant for MI-109.5 + MI-108 e2e walks
- **MI-108 Phase 3 test execution** — Supabase MCP `execute_sql` is read-only; INSERTs blocked even inside BEGIN/ROLLBACK. Run the three SQL files via SQL editor manually, or authorize a `create_branch` for write-capable testing.

## Next move
1. **Run MI-108 Phase 3 tests** via Supabase SQL editor against prod (mirror MI-109 Phase 4 pattern): paste `tests/mi108/no_work_constraint_test.sql`, then `audit_integrity_test.sql`, then `rls_test.sql`. Each is BEGIN/ROLLBACK-wrapped; expected output is 7 + 4 + 4 PASS NOTICE lines. If any FAIL, fix before merge.
2. **Manual UI walk** of the No-Work flow on staging/preview when isolated test tenant exists (MI-109.5-style; defer until then since prod walks burn audit_log writes).
3. **Merge PR** — Jorge reviews `mi108-frontend` PR, merges to main, Vercel auto-deploys.
4. **BUDDY_STANDARD.md Rule #10** — formalize the `.coordination/` file-channel pattern (still pending from prior session).
5. **SG-001 Node 4 (GitHub MCP)** — queued; pick up whenever convenient.

## Active investigations / side tracks
- `compliance_events` id gap (ids 6-10 unaccounted for) — Buddy can self-investigate via Supabase MCP whenever convenient.
- MI-204 index on `profiles.firm_id` — perf only, queued.
