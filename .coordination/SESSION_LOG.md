# Session Log

**Purpose:** Append-only running log. Each session = one entry. Replaces what the auto-compaction summary tries (and fails) to do. Buddy reads this first thing every new session to pick up where the last one left off.

**Format per entry:** date header, 4-6 bullets max. If something needs more than 6 bullets it belongs in a separate `.coordination/` file referenced here.

**Rules:**
- Newest entries at the TOP (reverse chronological — Buddy reads top-down and stops when irrelevant)
- Never delete or rewrite past entries
- Anything older than ~14 days gets pruned to one summary line during the next session start
- Pair with `RECENT_CONTEXT.md` (current state) and existing per-ticket files in `.coordination/`

---

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
