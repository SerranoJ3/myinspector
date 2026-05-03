# Buddy Context — Bootstrap Digest

**Generated:** 2026-05-03 ~13:00 EDT
**Stale after:** next session-close OR next major commit on main

---

## Where we are

- **MyInspector v0.1 Compliance Foundation** — ~62% through v1.0 scope by session count (per Saturday 5/2 close, no change since).
- **Saturday's three PR merges** all live and verified on prod via Sunday afternoon shape-checks (`SUNDAY_VERIFICATION_5-3-26.md`):
  - `mi101-phase2a` (Materials Sheet UI + polish stack)
  - `mi101-phase2b-refactor` (Tapcard refactor — 2 tabs, 41 visible fields, gradient placeholder for Phase 4)
  - `mi203-step2` (`lookup_firm_by_code` SECURITY DEFINER RPC for pre-auth firm lookup)
- **MI-203 step 3 closed Sunday morning** — `firms_read_anon` policy dropped via Supabase MCP migration `mi203_step3_drop_firms_read_anon`. Anonymous firm-read attack surface fully closed. firms table now has exactly 2 policies (read_authenticated + super_write).
- **Foundation work parked.** `serranogroup.org` registered + email routing live. Marketing site deployed to Cloudflare Pages at `steep-pine-05b2.jserranojr340.workers.dev`. Custom domain wiring pending Cloudflare propagation lag (~60 min). LinkedIn / Mercury / Tier 1 outreach all parked until Monday lawyer greenlight.

## What just shipped (last 5 commits on main, plus Sunday's MCP migration)

- `4d70901` (Sun 0:52 EDT) — Phase 2b refactor squash merge
- `mi203_step3_drop_firms_read_anon` (Sun ~08:55 EDT) — Supabase MCP migration, no main commit (migration log only)
- `e76fac2` (Sat) — MI-109 closure
- earlier: parts_catalogs seed, demo_inspector_binding, cs_replacement_auth_immutability_revoke_service_role, mi204b_firm_id_indexes (4 migrations Saturday afternoon/evening)

## What's pending (priority-ordered)

**Buddy verification queue (passive):**
1. Real `tapcard_data` jsonb shape verification on first user submission via Phase 2b UI. Currently 1 demo row pre-Phase-2b, 0 rows since merge. Triggers automatically when an inspector submits a tapcard.
2. Real `njaw_work_order_code` write on first service_work submission. CHECK constraint locked (M2C/H2C/FULL/MP/TP/KILL).
3. Real Materials Sheet 48-column row + audit_log delta on first Materials Sheet save.

**Lead's queue (Track 2 + spec drafts):**
1. Track 2 sanitized demo branch (`myinspector-demo`) — in flight as of Sunday morning. Status updates queued in `.coordination/status.md`.
2. **MI-101 Phase 2c (ShortHills + Restoration Card)** — brief drafted at `MI101_PHASE2C_BRIEF.md`. ~5 sessions. Q-7 (autosave cadence) gates the Restoration Card form half. ShortHills surfaces can build immediately.
3. **MI-110 Phase 4 (Tapcard Diagram editor)** — brief drafted at `MI110_PHASE4_BRIEF.md`. ~6 sessions. Highest-risk surface in v1.0 (touch-event handling on iPad). Lead may want a 1-day spike branch first.
4. **MI-302 Construction PM frontend** — brief drafted at `MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`. ~4–6 sessions. Backend already shipped (3 tables verified Sunday). 90% of the work is done; frontend is the gap.

**Open questions (Jorge to decide):**
- **Q-7** — Materials Sheet autosave cadence. Buddy presented 4 options (A/B/C/D) with sharpened volume math (real audit_log baseline 288/24h shows Q-7 was less catastrophic than initial estimate). Buddy recommends C (explicit Save Draft sub-action). Jorge's call.
- **Q-2c-c, d, e** — homeowner_contact_log visibility scope, ShortHills demo property seeding, ShortHills parts catalog seeding.
- **Q-110-a, b** — diagram asset type enum scope, read-only mode for pre-Phase-4 tapcards.
- **Q-302-a, b, c** — projects lifecycle gate, photo UX inline vs link, GPS distance threshold for anomaly flags.

**Jorge's clicks:**
- Verify `njaw-selector-v2` push status on GitHub branches page; if pushed → open PR + Vercel verify + squash-merge.
- Cloudflare Pages custom domain retry at ~13:30 EDT (after propagation lag).
- LinkedIn Company Page + Mercury bank application — parked until Monday post-lawyer.
- Lawyer outreach Monday 5/4 AM via `serrano-group-site/legal/email-lawyer.md`.

## Files to read at session open (in order)

1. `CLAUDE.md` — locked principles
2. `STATE.md` — slow-moving authoritative state
3. `BUDDY_STANDARD.md` — working style
4. `.coordination/status.md` — Lead's fast-moving working snapshot
5. `.coordination/buddy_context.md` (this file) — Buddy's bootstrap digest
6. `.coordination/SUNDAY_VERIFICATION_5-3-26.md` — most recent prod verification (skip after first read; reference)
7. `.coordination/questions.md` — open Q queue (Q-7 still open, Q-2c-* and Q-110-* and Q-302-* in their respective briefs)
8. `.coordination/decisions.md` — recent resolved calls

If conflict: STATE.md > status.md for authoritative state. CLAUDE.md > decisions.md for principles.

## Working pattern that's locked

- **Code edits (>3 lines):** full-file replace, not surgical (BUDDY_STANDARD §7).
- **Rule #9:** file-write gate. Relaxation in effect for low-risk markdown writes when batch trust granted by Jorge ("get it all done", "yup it"). Per-file gate stays in force for SQL, code, security-sensitive, irreversible.
- **Tagged dollar-quotes (`$TESTBODY$`)** preferred over `$$` in any SQL file Buddy edits — filesystem MCP edit_file mangles `$$`.

## Schema state surprises (discovered Sunday)

The schema grew quietly between 5/2 evening and 5/3 afternoon. Worth knowing:

- **23 firm_id indexes** across the schema (memory had said "7 from MI-204b"). Sequential scan risk on RLS predicates: zero across owner-data tables.
- **Construction PM backend fully shipped** — `contractor_arrival_log` (16 cols), `contractor_departure_log` (17 cols, with arrival_log_id FK linking back), `contractor_assignments` (15 cols). All RLS-locked, all firm_id indexed. Frontend brief MI-302 written against this real schema.
- **Restoration backend partial** — `restoration_grid_entries` exists, RLS-locked, sector enum CHECK present (NJ6_NORMAL or NJAW_SHORT_HILLS).
- **`legal_holds`, `destruction_notices`, `photo_rescue`, `supervisor_alerts`, `projects`** also exist. Not actively used in v0.1 UI but indexed and RLS-locked. Future tickets can build on them without new migrations.
- **`phase` enum has 9 values** (not 8 — memory was stale). MI-108's `no_work` is included.
- **Sector enum lives on `properties` (not `phase_submissions`)**. Values: `NJ6_NORMAL`, `NJAW_SHORT_HILLS`. Property-scoped, not submission-scoped.

## Active investigations / side tracks

- compliance_events id continuity: 6 rows, 2-id gap. Confirmed Saturday's locked decision (sequence advance from rolled-back tx, not chain breach). Closed.
- 3 reference images for MI-100 vision parsing — Jorge to provide. Still blocked.
- Whiteboard sample photos for false-positive prompt tuning — Jorge to provide. Still blocked.
- Isolated test tenant for MI-109.5 manual e2e walk — still blocked.

## Capital deployed in Serrano Group LLC (running tally, ops/expenses.csv source-of-truth)

- LLC formation + EIN: ~$200–370 (TBD line items)
- MacBook Air M4 Pro: ~$1,000–1,400 (Section 179 eligible)
- Asus laptop (primary dev): pre-existing (no expense)
- Claude Max 20x plan: $200 paid Saturday night
- Anthropic API credits: minimal (no line item)
- Cloudflare Registrar (`serranogroup.org`): $7.50 first year, $10.13/yr renewal — 5/3/26
- Vercel + Supabase + Mercury: $0 (free tiers)
- NJ State Bar lawyer (Mon 5/4): ~$300 budgeted
- USPTO trademark filings (TBD): ~$1,400 budgeted (~4 marks × $350)

**Total deployed YTD: ~$1,508–2,508, largely tax-deductible.**
