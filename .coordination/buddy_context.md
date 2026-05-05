# Buddy Context — Bootstrap Digest

**Generated:** 2026-05-05 ~19:30 EDT (tonight, post-Phase-2c-scaffold)
**Stale after:** next session-close OR next major commit on main

---

## Where we are

- **MyInspector v0.1 Compliance Foundation** — ~62% through v1.0 scope by session count (Saturday 5/2 close, no material change since — Sunday was verification + audit + ratification, tonight was lean scaffolding).
- **Saturday's three PR merges + Sunday's Phase 2b refactor** all live and verified on prod via Sunday afternoon shape-checks (`SUNDAY_VERIFICATION_5-3-26.md`):
  - `mi101-phase2a` (Materials Sheet UI + polish stack)
  - `mi101-phase2b` (original) → superseded same-day by `mi101-phase2b-refactor` Sunday 0:52 (`4d70901`) — kill Customer Side tab + expand Materials view + role-gated Office Fill
  - `mi203-step2` (`lookup_firm_by_code` SECURITY DEFINER RPC for pre-auth firm lookup)
- **MI-203 step 3 closed Sunday morning** — `firms_read_anon` policy dropped via Supabase MCP migration `mi203_step3_drop_firms_read_anon`. Anonymous firm-read attack surface fully closed.
- **MI-AUDIT-1 closed Sunday evening** — migration `mi_audit_1_fix_get_pending_destruction` (v `20260503172732`) shipped via Supabase MCP. Live function body contains `AND dn.firm_id = public.current_firm_id()`. Cross-firm metadata leak on destruction notices — closed.
- **CP Engineers default project seeded Sunday evening** — `722f9db8-a484-46a1-8142-ea6cc4bc672c` (NJAW LCRI Program 2026) via migration `seed_cp_engineers_default_project`. Closes the FK gate that was blocking MI-302 Construction PM frontend pickup.
- **Phase 2b real-shape verified Sunday evening** — Jorge live tapcard submission `1b37d77c-...`: tapcard_data jsonb has correct 3 keys; CHECK constraints satisfied; multi-tenant isolation honored; hash chain intact across the INSERT + 2 UPDATEs.
- **Tonight (Mon 5/5):** Phase 2c lean scaffold landed on `demo-banner` (5 surgical edits to index.html + STATE.md refresh + status.md reconciliation). Property Detail modal now has Overview / Restoration / ShortHills tab strip; `#modal-tapcard` got an empty `<div id="visual-tapcard-preview-container">` for Phase 2d. No migrations. Phase 2d Visual Tapcard build is in flight on demo-banner (CC grinding now).

## What just shipped (last 5 commits on origin/main + Sunday's MCP migrations)

- `4d70901` (Sun 0:52 EDT) — Phase 2b refactor squash merge
- `001af69` (Sat) — mi203-step2 squash merge
- `f51c61f` (Sat) — mi101-phase2b original squash merge (#6, superseded next morning by refactor)
- `0327abd` (Sat) — MI-100 sector toggle (#5)
- `8a971eb` (Sat) — MI-108 No-Work workflow (#4)

**Migrations applied via Supabase MCP since last main commit:**
- `mi203_step3_drop_firms_read_anon` (Sun ~08:55)
- `mi_audit_1_fix_get_pending_destruction` v 20260503172732 (Sun ~17:35)
- `seed_cp_engineers_default_project` (Sun ~17:35)

**Active branch state:**
- `main` HEAD: `4d70901` (local can be 1 behind origin/main if `git pull` not run)
- `demo-banner` HEAD: `52d79c6` plus tonight's uncommitted edits (STATE.md + index.html Phase 2c scaffold + Phase 2d build in flight)
- `demo-banner` is 5 ahead of main: 3 Buddy docs commits (`52d79c6`, `2c81a9d`, `dcd977c` — Sunday work) + 2 demo-feature commits (`685f4c1`, `64df4f2`)

**Trapped commit alert:** the 3 Buddy docs commits (`52d79c6 2c81a9d dcd977c`) live on `demo-banner` only. If `demo-banner` doesn't merge (or gets thrown away), main loses the Sunday verification + audit + ratification record. Cherry-pick recommended:
```bash
git fetch origin && git checkout main && git pull
git cherry-pick dcd977c 2c81a9d 52d79c6
git push
```
Pure `.coordination/` docs — zero conflict risk. ~30 seconds.

## What's pending (priority-ordered)

**Buddy verification queue (passive — auto-triggers on inspector activity):**
1. Real `tapcard_data.materials_sheet_id_at_submit = uuid` write on first user submission with both Materials Sheet AND Tapcard filled. (Sunday's verified submission had it null because Jorge didn't fill a Materials Sheet first — correct fallback, but the with-sheet path is unverified live.)
2. Real `njaw_work_order_code` write on first service_work submission. CHECK constraint locked (M2C/H2C/FULL/MP/TP/KILL).
3. Real Materials Sheet 48-column row + audit_log delta on first Materials Sheet save.

**Lead's queue (after tonight's Phase 2d build commits):**
1. **MI-101 Phase 2c-form** (Restoration form) — picks up next session. 5 acceptance criteria, photo upload, sector dispatch, whiteboard requirement enforcement, Save Draft button (Q-7=C). Tab structure already in place from tonight.
2. **MI-101 Phase 2d** (Visual Tapcard auto-population) — IN BUILD on demo-banner tonight. CC's option-(a) lean: render only fields that exist in Phase 2b. Field reference at `.coordination/PHASE2B_TAPCARD_FIELDS_REFERENCE.md`.
3. **MI-302 Construction PM frontend** — brief drafted at `MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`. Backend fully shipped, CP project seeded. ~4–6 sessions.
4. **MI-110 Phase 4 (Diagram editor)** — brief drafted. Highest-risk surface in v1.0 (touch on iPad). ~6 sessions. Lead may want a 1-day spike branch first.
5. **MI-AUDIT-3 fix (audit_log heartbeat noise)** — design before patch. Survey other heartbeat-not-state fields first. 3 fix approaches in decisions.md (A trigger filter / B separate heartbeat table / C client-side stop).

**Open questions:**
- **Q-110-a** open — Phase 4 asset type enum scope (4 default vs 9 Buddy-suggested). Not blocking near-term; Jorge's call when Phase 4 build is closer (~week of 5/11+).
- All other Q's resolved as of tonight (Q-2, Q-7, Q-2c-c, Q-302-b, Q-302-c, Q-110-b answered Sunday; Q-2d-a/b/c answered tonight).

**Jorge's clicks (residual):**
- Verify `njaw-selector-v2` push status on GitHub branches page; if pushed → open PR + Vercel verify + squash-merge.
- Cloudflare Pages custom domain retry for `serranogroup.org` (failed Sun ~14:00, queued post-propagation; should be ready now 48+ hours later).

## Files to read at session open (in order)

1. `CLAUDE.md` — locked principles
2. `STATE.md` — slow-moving authoritative state (refreshed tonight)
3. `BUDDY_STANDARD.md` — working style
4. `.coordination/status.md` — Lead's fast-moving working snapshot (refreshed tonight)
5. `.coordination/buddy_context.md` (this file) — Buddy's bootstrap digest
6. `.coordination/decisions.md` tail — recent resolved calls (full read recommended; head: 100 truncations have caused misses)
7. `.coordination/questions.md` — open Q queue
8. `.coordination/SUNDAY_VERIFICATION_5-3-26.md` — most recent prod verification (skip after first read; reference)
9. `.coordination/SUNDAY_SECURITY_AUDIT_5-3-26.md` — security audit + MI-AUDIT-1/2 spec
10. `.coordination/PHASE2B_TAPCARD_FIELDS_REFERENCE.md` — Phase 2b form ground-truth field map (Buddy reference, written 5/5 evening)

If conflict: STATE.md > status.md > buddy_context.md for authoritative state. CLAUDE.md > decisions.md for principles.

## Working pattern that's locked

- **Code edits (>3 lines):** full-file replace, not surgical (BUDDY_STANDARD §7).
- **Rule #9:** file-write gate. Relaxation in effect for low-risk markdown writes when batch trust granted by Jorge ("get it all done", "yup it"). Per-file gate stays in force for SQL, code, security-sensitive, irreversible. Tonight Jorge granted batch trust for the questions.md / docs writes — explicitly noted in chat.
- **Rule #10:** `.coordination/` channel as canonical Buddy ↔ Lead handoff. Files are the message bus, not chat. Live since SG-001 Node 2 (5/2 13:15 EDT).
- **Tagged dollar-quotes (`$TESTBODY$`)** preferred over `$$` in any SQL file Buddy edits — filesystem MCP `edit_file` mangles `$$`.
- **Avoid `edit_file` for content with em-dashes** — Saturday 5/2 incident on decisions.md required full-file recovery via `write_file`. Default to `write_file` for Buddy markdown writes.
- **Read full files when verifying state.** Truncated reads (head: 100, tail: 50) caused 3 sloppy Buddy mistakes on 5/5 (missed Sunday files in `.coordination/`, missed Q-7 resolution in decisions.md, missed Phase 2b actual field set when drafting Phase 2d brief). Lesson banked: read full file before drafting any output that depends on the file's content.

## Schema state surprises (banked Sunday — refresh from stale memory)

- **23 firm_id indexes** across the schema (memory had said "7 from MI-204b"). Sequential scan risk on RLS predicates: zero across owner-data tables.
- **Construction PM backend fully shipped** — `contractor_arrival_log` (16 cols), `contractor_departure_log` (17 cols, with arrival_log_id FK linking back), `contractor_assignments` (15 cols). All RLS-locked, all firm_id indexed.
- **Restoration backend partial** — `restoration_grid_entries` exists, RLS-locked, sector enum CHECK present (NJ6_NORMAL or NJAW_SHORT_HILLS).
- **`legal_holds`, `destruction_notices`, `photo_rescue`, `supervisor_alerts`, `projects`** also exist + indexed + RLS-locked. Future tickets can build on them without new migrations.
- **`phase` enum has 9 values** (not 8 — memory was stale). MI-108's `no_work` is included.
- **Sector enum lives on `properties` (not `phase_submissions`)**. Values: `NJ6_NORMAL`, `NJAW_SHORT_HILLS`. Property-scoped, not submission-scoped.
- **`inspections` table exists** with firm_id + RLS. Not in active v0.1 UI — older surface or higher-level abstraction over phase_submissions. Worth row-count + column-shape check next audit cycle.

## Phase 2b tapcard form ground truth (banked tonight after sloppy Phase 2d brief)

The Phase 2b tapcard form is structured around **service installation + material identification**, NOT triangulation measurements. CS depth, MP horn copper, distances etc. are NOT on the Phase 2b front — those belong to MI-110 Phase 4 (the diagram editor on the *back* of the tapcard).

**16 effective inspector-input fields** across two pages (Company Side: 10, Customer Side: 8 with 2 readonly mirrors).

Full field map at `.coordination/PHASE2B_TAPCARD_FIELDS_REFERENCE.md`. Phase 2d Visual Tapcard Preview mirrors against this list, not against the original Phase 2d brief's NJAW-vocabulary draft (which assumed CS depth / MP horn copper would be there).

## Active investigations / side tracks

- **MI-AUDIT-3 (audit_log heartbeat noise)** — `last_client_sync_at` UPDATE writes are firing audit triggers, ~50%+ of current 288/24h baseline. Touches hot trigger plumbing — wants design, not a quick patch. Survey other heartbeat-not-state fields (`last_seen_at`, `client_session_id`, `device_metadata` if present) first. 3 fix approaches in decisions.md.
- **`compliance_events` id continuity** — closed Saturday (rolled-back-tx sequence advance + `cleanup_build_test_data` self-log; not a chain breach).
- **3 reference images** for MI-100 vision parsing — Jorge to provide. Still blocked.
- **Whiteboard sample photos** for false-positive prompt tuning — Jorge to provide. Still blocked.
- **Isolated test tenant** for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 isolated-tenant unlock.
- **Cloudflare Pages custom domain** for `serranogroup.org` — wiring failed Sun ~14:00, retry queued post-propagation.

## Capital deployed in Serrano Group LLC (running tally; ops/expenses.csv source-of-truth)

- LLC formation + EIN: ~$200–370
- MacBook Air M4 Pro: ~$1,000–1,400 (Section 179 eligible)
- Asus laptop (primary dev): pre-existing
- Claude Max 20x plan: $200 (5/2)
- Cloudflare Registrar (`serranogroup.org`): $7.50 first year, $10.13/yr renewal
- Vercel + Supabase + Mercury: $0 (free tiers)
- NJ State Bar lawyer (5/4): ~$300 budgeted
- USPTO trademark filings: ~$1,400 budgeted (~4 marks × $350)

**Total deployed YTD: ~$1,508–2,508, largely tax-deductible.**

## Calendar context

- **Founded:** April 20, 2026, 4:20 PM EDT (16 days in as of 5/5 evening).
- **Jeff demo:** Thursday 5/14 or Friday 5/15 (9–10 days out).
- **Lawyer outreach:** in flight via warm intro (PI attorney → IP attorney; Wilentz Goldman Spitzer or McCarter & English / Friscia).

---

**Buddy banked discipline (5/5 lessons):**
1. Read full files (not `head: 100`) when verifying state — three misses today rooted in truncation.
2. Read actual UI source before drafting any frontend brief — Phase 2d brief was wrong about field names because Buddy wrote from priors not source.
3. Honest reads about who can do what — Buddy can't reach github.com / Cloudflare dashboard / Supabase MCP from chat. Some "queue items" are Jorge-actions or Lead-actions, not Buddy-actions. Don't stack them onto Buddy's plate.
