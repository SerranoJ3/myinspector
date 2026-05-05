# MyInspector — Current State

> **Purpose:** Single source of truth for session continuity. Read at session open. Update at session close.
> **CLAUDE.md** holds locked principles. **STATE.md** holds live state.
> Conflict with Claude memory: this file wins.

**Last updated:** May 5, 2026 ~evening EDT (post Phase 2d ship)
**Updated by:** Lead (Claude Code CLI) — Phase 2d Visual Tapcard Preview shipped on `demo-banner`; STATE refreshed with as-shipped state + 3 banked-discipline lessons from tonight

---

## Project header
- **Repo:** SerranoJ3/myinspector (main, Vercel auto-deploy)
- **Live URL:** myinspector-psi.vercel.app
- **Production domain (planned):** myinspector.io
- **Supabase project:** `myinspector` (ref `wryitfoletwskkdqqwcw`, us-east-2/Ohio)
- **Local clone:** `C:\Users\jserr_0phql\Documents\Serrano Group LLC\Code\myinspector`

---

## Active gate: v0.1 Compliance Foundation

**~62% of v1.0 scope complete by session count** (Saturday 5/2 close, no material change since — Sunday was verification + audit + ratification, tonight added Phase 2c scaffold + Phase 2d build, no new feature surface area beyond what was already queued).

| Ticket | Status | Notes |
|---|---|---|
| MI-200 RLS forced + ≥1 policy per table | Closed 4/27 | — |
| MI-201 compliance_dashboard `security_invoker` fix | Closed 5/1 | Banked CLAUDE.md principle #7 |
| MI-202 Audit log + 5-layer immutability stack | Active build | Plumbing live; chain integrity verified Sunday |
| MI-100 Sector toggle | Closed 5/2 | PR #5 `0327abd` |
| MI-108 No-Work Submission Workflow | Closed 5/2 | PR #4 `8a971eb`, backend migration `mi108_no_work_submission_workflow` |
| MI-109 CS Replacement Authorization Gate | Closed 5/2 | PR #3 `e76fac2`, SQL coverage 17/17 |
| MI-109.5 Manual e2e UI walk on isolated staging | Queued | Gated on isolated test tenant (SG-001 Node 2/3 unlock) |
| MI-203 step 2 (signup → `lookup_firm_by_code` RPC) | Closed Sat | PR `mi203-step2` merged |
| MI-203 step 3 (DROP POLICY `firms_read_anon`) | Closed Sun ~08:55 | Migration `mi203_step3_drop_firms_read_anon`, no main commit (MCP-only) |
| MI-204 / MI-204b firm_id indexing | Closed Sat | 23 firm_id indexes total across schema |
| MI-101 Phase 1a-1e (backend) | Closed | All 5 sub-phases shipped via prod migrations |
| MI-101 Phase 2a (Materials Sheet UI + polish) | Closed Sat | PR `mi101-phase2a` merged |
| MI-101 Phase 2b refactor (Tapcard, 2 tabs, 41 fields) | Closed Sun 0:52 | `4d70901`. Real-shape verified Sun 17:50 (Jorge live submission) |
| MI-101 Phase 2c lean scaffold (tabs + visual preview container) | **Closed Mon 5/5** | Commit `91f2af4` on `demo-banner`. No migrations. |
| MI-101 Phase 2c-form pickup (Restoration form) | Queued — next session | 5 acceptance criteria, photo upload, sector dispatch, whiteboard requirement, Save Draft button per Q-7=C |
| MI-101 Phase 2d (Visual Tapcard Preview) | **Shipped tonight on `demo-banner` — in flight pending Vercel verify** | Commit `79f8434`. SVG render mirrors `#modal-tapcard` form state for NJ6_NORMAL only. Q-2d-a/b/c ratified (mono / no PDF / gray underline). Acceptance #5 (no regression on Phase 2b form) requires browser verification on Vercel preview — Lead's environment has no dev server + Supabase creds wired |
| MI-110 Phase 4 (Tapcard Diagram editor) | Brief drafted | Highest-risk surface in v1.0 (touch events on iPad). ~6 sessions. |
| MI-302 Construction PM frontend | Brief drafted | Backend fully shipped. CP default project seeded Sun (`722f9db8...`). ~4–6 sessions. |
| MI-AUDIT-1 (firm_id filter on `get_pending_destruction`) | Closed Sun ~17:35 | Migration `mi_audit_1_fix_get_pending_destruction` v `20260503172732`. Live function body contains `AND dn.firm_id = public.current_firm_id()` |
| MI-AUDIT-2 (super_admin firm-crossing posture) | Informational, parked | Trigger to act: second firm beyond CP Engineers |
| MI-AUDIT-3 (audit_log heartbeat noise — `last_client_sync_at`) | Filed Sun ~17:50 | P2. 3 fix approaches (A/B/C) in decisions.md. Touches audit chain plumbing — design before patch |
| Soft-delete view rebuild (CLAUDE.md principle #7) | Closed Sat | Migration `soft_delete_views_security_invoker_rebuild` |
| `legal_holds` workflow | Backend exists, no UI | Table indexed + RLS-locked. No active ticket. |
| Demo tenant + `firm_safe_to_display` | Closed Sat | Migrations `firms_safe_to_display_flag` + `demo_tenant_seed_data_v3` + `demo_inspector_binding` |

---

## Tapcard cluster (~37 sessions total per 4/30/26 refinement)

| Ticket | What | Sessions | Status |
|---|---|---|---|
| MI-100 | Sector toggle (NJ6_NORMAL / NJAW_SHORT_HILLS) | 3 | Closed |
| MI-101 | Normal Tapcard 3-page (CDM-Smith rules b, d, e) | 6 | Phases 1a-2b shipped; 2c lean scaffolded; 2d shipped tonight pending Vercel verify; 2c-form queued |
| MI-101.5 | Dual-mode entry (Type fields \| Photo notebook + Vision parse) | 4 | Queued post-Phase-4 |
| MI-102 | ShortHills (Company + Restoration) | 5 | Placeholder tab tonight (Phase 2c); build queued post master-parts-list |
| MI-103 | Vision parse refs DONE → build spec | 0 | Blocked on 3 reference images |
| MI-104 | Admin override | 4 | Queued |
| MI-105 | ShortHills customer-side | DEFERRED | Out of v1 |
| MI-107 | KILL subtypes + tiered rule engine | 5 | Queued |

**Two sectors:** `NJ6_NORMAL`, `NJAW_SHORT_HILLS`. **Sector lives on `properties` (not `phase_submissions`)** — verified Sunday. UI dispatch reads `properties.sector` via JOIN at modal load.

---

## Schema state surprises (banked Sunday, verified Sunday + tonight)

- **23 firm_id indexes** across schema. Memory said 7. Schema grew silently as compliance + Construction PM tables shipped.
- **Construction PM backend fully shipped:** `contractor_arrival_log` (16 cols), `contractor_departure_log` (17 cols, FK to arrival_log), `contractor_assignments` (15 cols). All RLS-forced + firm_id indexed.
- **Restoration backend partial:** `restoration_grid_entries` exists, RLS-locked, sector enum CHECK present.
- **`legal_holds`, `destruction_notices`, `photo_rescue`, `supervisor_alerts`, `projects`** all exist + indexed + RLS-locked. Not in active v0.1 UI; future tickets can build on them without new migrations.
- **`phase` enum has 9 values** (not 8 — memory was stale). MI-108's `no_work` is included. Locked.
- **Sector enum on `properties` (not `phase_submissions`).** Same CHECK on `restoration_grid_entries` and `parts_catalogs`.
- **`inspections` table exists** with firm_id + RLS — not currently used; older surface or higher-level abstraction over `phase_submissions`. Worth a row-count + column-shape check next audit cycle.
- **Phase 2b tapcard form field surface** — documented in `.coordination/PHASE2B_TAPCARD_FIELDS_REFERENCE.md` (Buddy, tonight). Ground-truth for MI-101 Phase 2d field map (`VTC_FIELDS` in index.html).

---

## Audit posture (post Sunday verification + security audit + tonight's Phase 2d ship)

🟢 **Multi-tenant isolation: GREEN.** 22 tables with firm_id, all RLS-forced + ≥1 policy. 3 tables without firm_id are global by design (`firms`, `modules`, `parts_catalogs`).

🟢 **Audit chain primitives DEFINER-gated correctly.** `compute_audit_hash`, `write_audit_log`, `audit_log_chain_trigger`, `record_compliance_event` all reference firm_id or auth.uid and are scoped.

🟢 **26 SECURITY DEFINER functions audited.** 21 OK with explicit firm_id, 2 OK with auth.uid + verified scope, 1 super_admin-by-design (`release_legal_hold` → MI-AUDIT-2 informational), 1 fix shipped (`get_pending_destruction` → MI-AUDIT-1 closed Sun).

🟡 **MI-AUDIT-3 filed.** `last_client_sync_at` heartbeat writes are firing audit triggers — ~50%+ of current 288/24h baseline is heartbeat noise, not state change. P2. Design before patch.

🟢 **Phase 2b real-shape verified Sunday 17:50.** Jorge live tapcard submission — tapcard_data jsonb has correct 3 keys; CHECK constraints satisfied; multi-tenant isolation honored; hash chain intact across the INSERT + 2 UPDATEs.

🟢 **Phase 2d is presentational only.** No new DB writes, no new RPCs, no new tables. Read-only SVG mirror of form state. Audit posture unchanged from Phase 2b.

---

## Resolved questions

- **Q-2 (Vercel preview verification):** all 3 Saturday PRs verified post-merge.
- **Q-7 (Materials Sheet autosave cadence):** **Option C — explicit Save Draft sub-action.** Phase 2c-form pickup ships with third button.
- **Q-2c-c (homeowner_contact_log visibility):** firm-visible (not per-inspector).
- **Q-302-b (Construction PM photo UX):** inline 40×40 thumbnails + lightbox.
- **Q-302-c (GPS anomaly threshold):** 50 m from property polygon.
- **Q-110-b (pre-Phase-4 tapcards):** read-only mode with banner.
- **Q-2d-a (Visual Tapcard font):** monospace (`'JetBrains Mono'` primary, system mono fallback).
- **Q-2d-b (print-to-PDF):** deferred to v2. Trigger to un-defer: first compliance officer asks at demo/pilot.
- **Q-2d-c (empty-field treatment):** thin gray underline (`#cfd6df`, 1px) at field anchor.

## Deferred / parked

- **Q-2c-d (ShortHills demo properties):** 0 ShortHills properties on prod. Parked until first real ShortHills import.
- **Q-2c-e (ShortHills parts catalog):** 16 NJ6_NORMAL rows only. Same parking principle.
- **Q-110-a (Phase 4 asset type enum scope):** brief default 4 types, Buddy suggests 9. Jorge's call when Phase 4 build is closer.

---

## Recent ships (chronological — last 4 days)

**Sat 5/2:**
- 4 migrations via Supabase MCP: `parts_catalogs_placeholder_seed`, `demo_inspector_binding`, `cs_replacement_auth_immutability_revoke_service_role`, `mi204b_firm_id_indexes`
- 3 PR squash-merges: `mi203-step2`, `mi101-phase2a`, `mi101-phase2b` (original)
- BB-001 (AR auto-fill tapcard) parked, trigger = first paying non-CP customer

**Sun 5/3 morning:**
- `mi101-phase2b-refactor` PR merged 0:52 as `4d70901`
- MI-203 step 3 shipped ~08:55 via Supabase MCP migration `mi203_step3_drop_firms_read_anon`
- `serranogroup.org` registered + Email Routing live + marketing site on Cloudflare Pages

**Sun 5/3 afternoon:**
- Full prod verification across 8 surfaces (`SUNDAY_VERIFICATION_5-3-26.md`) — all GREEN
- Security audit (`SUNDAY_SECURITY_AUDIT_5-3-26.md`): 1 finding → MI-AUDIT-1
- 3 production-ready briefs drafted: `MI101_PHASE2C_BRIEF.md`, `MI110_PHASE4_BRIEF.md`, `MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`

**Sun 5/3 evening:**
- MI-AUDIT-1 shipped via Supabase MCP migration `mi_audit_1_fix_get_pending_destruction`
- CP Engineers default project seeded — closes MI-302 frontend FK gate
- 6 Q ratifications (Q-7=C, Q-2c-c, Q-302-b/c, Q-110-b + 2 deferrals Q-2c-d/e)
- Phase 2b real-shape verified GREEN via Jorge live submission
- MI-AUDIT-3 filed (audit_log heartbeat noise from `last_client_sync_at`)

**Mon 5/5 (tonight):**
- STATE.md 3-day reconciliation refresh (commit `91f2af4`)
- Phase 2c lean scaffold shipped: Property Detail tab strip (Overview / Restoration / ShortHills) + empty `<div id="visual-tapcard-preview-container">` in `#modal-tapcard` (commit `91f2af4`)
- Phase 2d Visual Tapcard Preview shipped tonight on `demo-banner` (commit `79f8434`): SVG mirror of `#modal-tapcard` form state for NJ6_NORMAL only; Q-2d-a/b/c ratified (mono / no PDF / gray underline); Acceptance #5 pending Vercel preview verify
- Buddy parallel-track refresh on `buddy_context.md` + `questions.md` Q-2d resolutions (mid-session)
- Buddy created `.coordination/PHASE2B_TAPCARD_FIELDS_REFERENCE.md` as ground-truth for the Phase 2d field map

---

## Open investigations / blockers

- **MI-AUDIT-3** filed Sun 5/3 ~17:50. P2. Design before patch — survey other heartbeat-not-state fields before picking approach A/B/C.
- **3 reference images** for MI-100 vision parsing — Jorge to provide. Still blocked.
- **Whiteboard sample photos** for false-positive prompt tuning — Jorge to provide. Still blocked.
- **Isolated test tenant** for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 unlock.
- **`njaw-selector-v2`** push status — Jorge to verify on GitHub branches page.
- **Phase 2d Acceptance #5 (no regression)** — needs browser verification on Vercel preview.

## Decisions parked (not blockers)

- Memory audit execution (5 replace + 4 remove + 4 add)
- BidGrid kickoff timing — after MyInspector v0.1 close
- Mercury bank account opening — post-lawyer Mon 5/4
- Trademark filings (BidGrid, MyInspector, Tia, FORGE) — ~$1,400 budgeted
- Lawyer outreach Mon 5/4 AM
- LinkedIn Company Page — parked until Monday post-lawyer

---

## Capital deployed in Serrano Group LLC (running tally)

- LLC formation + EIN: ~$200–370 (TBD)
- MacBook Air M4 Pro: ~$1,000–1,400 (Section 179 eligible)
- Asus laptop (primary dev): pre-existing
- Claude Max 20x plan: $200 (Saturday 5/2)
- Anthropic API credits: minimal
- Cloudflare Registrar (`serranogroup.org`): $7.50 first year, $10.13/yr renewal
- Vercel + Supabase + Mercury: $0 (free tiers)
- NJ State Bar lawyer (Mon 5/4): ~$300 budgeted
- USPTO trademark filings: ~$1,400 budgeted

**Total deployed YTD: ~$1,508–2,508, largely tax-deductible.**

---

## Last 3 sessions

1. **Sun 5/3** — Buddy max-execution sprint. Saturday queue closed. Domain + email + marketing-site infrastructure stood up. Full prod verification + security audit. 3 spec briefs drafted. MI-AUDIT-1 shipped. CP default project seeded. 6 Q ratifications. Phase 2b real-shape verified via Jorge live submission. MI-AUDIT-3 filed.
2. **Mon 5/5 early evening (commit `91f2af4`)** — STATE.md 3-day reconciliation refresh. Phase 2c lean scaffold (Property Detail tabs + visual-tapcard-preview-container scaffold). status.md full reconciliation. MI-AUDIT-1 confirmed already-shipped (no-op).
3. **Mon 5/5 evening (commit `79f8434`)** — Phase 2d Visual Tapcard Preview shipped on `demo-banner`. 7 surgical edits to index.html (Phase 2c structural + Phase 2d build). Q-2d-a/b/c ratified via Buddy defaults during build. Buddy parallel-track refresh on buddy_context.md + questions.md mid-session. STATE refresh + 3 banked-discipline lessons (this commit).

## Next session opens with — MI-101 Phase 2c-form pickup

Restoration form ships clean: 5 acceptance criteria, photo upload (pre + post), sector dispatch (NJ6_NORMAL / NJAW_SHORT_HILLS), whiteboard requirement enforcement, Save Draft button (Q-7=C). Tab structure already exists from `91f2af4`'s lean scaffold.

After 2c-form: pick from MI-302 Construction PM frontend (FK target seeded), MI-110 Phase 4 (Diagram editor — highest risk), MI-AUDIT-3 fix (audit chain heartbeat patch), or main-merge of `demo-banner` if Track 2 demo work is ready for v0.1 cut.

---

## Velocity benchmark
- 90-min focused build = 20–23 SQL milestones (~4 min/milestone)
- MyInspector v1.0 = **57–78 sessions**
- Aggressive: end of May 2026
- Realistic: mid-July 2026
- Founded: 4:20pm April 20, 2026. **15 days in = ~62% scope per Saturday close.**

---

## Update protocol
- **Session close:**
  - Update "Last 3 sessions" (push oldest off)
  - Update active tickets, schema surprises, blockers
  - `git add CLAUDE.md STATE.md && git commit -m "STATE: <date> session close" && git push`
- **Session open:**
  - `git pull`
  - Read CLAUDE.md, STATE.md, BUDDY_STANDARD.md, `.coordination/buddy_context.md`, `.coordination/status.md`
- **Conflict with Claude memory:** STATE.md wins. Memory updates lag.

---

## Banked discipline lessons (Mon 5/5 session)

Three locked discipline rules surfaced during tonight's session. Logged here at end of STATE.md so future Lead/Buddy reads see them at the bottom of the standing-state digest.

### Lesson 1 — Stop-and-ping when a brief contradicts the codebase

**Rule:** before launching a multi-session build off a Buddy-drafted brief, grep the codebase for every component, field, framework, or DOM ID the brief references. If any are missing or contradicted by recent commits, stop and reconcile with the spec author before writing code.

**Why:** Phase 2d brief (`MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md`) specified DOM structure ("Tapcard tab on Property Detail modal") incompatible with Phase 2c Option B (Property Detail tabs are Overview / Restoration / ShortHills); specified React framework when the codebase is vanilla HTML/JS per CLAUDE.md; specified field schema (`cs_depth_in`, `mp_horn_copper`, etc.) not present in Phase 2b's actual form. Lead surfaced 4 contradictions before kickoff. The alternative path (just executing the brief) would have shipped wrong work in 3 sessions and required a redo.

**How to apply:** at brief pickup, do a 5-minute grep sweep for every brief-named identifier. Any miss = stop-and-ping. Buddy's parallel ground-truth doc (`PHASE2B_TAPCARD_FIELDS_REFERENCE.md`) is the corrective pattern — when a brief mirrors existing UI state, ground-truth the source first.

### Lesson 2 — Confirm shipped state via authoritative source before re-shipping

**Rule:** any task that overlaps a recent decisions.md entry or migrations log — read the entry, verify against prod via read-only MCP queries, then act. Re-shipping a no-op is wasteful; re-shipping a duplicate migration is destructive.

**Why:** tonight's task plan included shipping MI-AUDIT-1 (3-line firm_id filter on `get_pending_destruction`). Per the brief in `SUNDAY_SECURITY_AUDIT_5-3-26.md`, this needed shipping. But per `decisions.md` Sunday evening entry, it had already shipped via Supabase MCP migration `mi_audit_1_fix_get_pending_destruction` (v `20260503172732`). Lead verified live via `list_migrations` + `pg_get_functiondef` showing the firm_id filter is in prod. Skipped the no-op, recorded as closed instead.

**How to apply:** before any prod write, `list_migrations` + targeted `pg_get_functiondef` / `execute_sql` (read-only) is cheap and authoritative. The migration log is the truth, not the brief. Brief context can be days stale.

### Lesson 3 — Treat `.coordination/` files as multi-writer territory

**Rule:** before any branch operation (`git checkout`, `git merge`, `git rebase`), `git status` first; coordinate stash/commit/ack with Buddy before destructive moves. `.coordination/` files (especially `buddy_context.md`, `decisions.md`, `questions.md`, `status.md`) are written by both Buddy (filesystem MCP) and Lead (Claude Code) within the same session.

**Why:** tonight's `git checkout main` (mid cherry-pick flow) aborted with *"Your local changes to the following files would be overwritten by checkout: .coordination/buddy_context.md, .coordination/questions.md"*. Buddy was actively refreshing both files via filesystem MCP while Lead was building Phase 2d in Claude Code — neither side had visibility into the other's writes until git status exposed them at the destructive-action boundary.

**How to apply:** any session where Buddy is actively writing requires `git status` before every checkout-class operation. If parallel-track files are dirty and Buddy intent is unclear, surface to Jorge with options (stash / commit / pause) — don't guess. Once decided, the chosen path commits cleanly with no work lost.
