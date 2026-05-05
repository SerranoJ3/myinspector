# MyInspector — Current State

> **Purpose:** Single source of truth for session continuity. Read at session open. Update at session close.
> **CLAUDE.md** holds locked principles. **STATE.md** holds live state.
> Conflict with Claude memory: this file wins.

**Last updated:** May 5, 2026 ~evening EDT
**Updated by:** Lead (Claude Code CLI) — 3-day reconciliation refresh against Saturday merges + Sunday verification/audit/ship + tonight's Phase 2c lean scaffold start

---

## Project header
- **Repo:** SerranoJ3/myinspector (main, Vercel auto-deploy)
- **Live URL:** myinspector-psi.vercel.app
- **Production domain (planned):** myinspector.io
- **Supabase project:** `myinspector` (ref `wryitfoletwskkdqqwcw`, us-east-2/Ohio)
- **Local clone:** `C:\Users\jserr_0phql\Documents\Serrano Group LLC\Code\myinspector`

---

## Active gate: v0.1 Compliance Foundation

**~62% of v1.0 scope complete by session count** (per Saturday 5/2 close, no material change since — Sunday was verification + audit + ratification, no new feature surface).

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
| MI-204 / MI-204b firm_id indexing | Closed Sat | 23 firm_id indexes total across schema (memory had said 7) |
| MI-101 Phase 1a-1e (backend) | Closed | All 5 sub-phases shipped via prod migrations |
| MI-101 Phase 2a (Materials Sheet UI + polish) | Closed Sat | PR `mi101-phase2a` merged |
| MI-101 Phase 2b refactor (Tapcard, 2 tabs, 41 fields) | Closed Sun 0:52 | `4d70901`. Real-shape verified Sun 17:50 (Jorge live submission) |
| MI-101 Phase 2c lean scaffold (tabs + visual preview container) | **IN PROGRESS tonight 5/5** | No migrations, no new columns. Form deferred. |
| MI-101 Phase 2c-form pickup (Restoration form) | Queued — next session | 5 acceptance criteria, photo upload, sector dispatch, whiteboard requirement |
| MI-101 Phase 2d (Visual Tapcard auto-population) | Spec drafted by Buddy (in flight) | Empty container scaffolded tonight, autopopulation logic next session |
| MI-110 Phase 4 (Tapcard Diagram editor) | Brief drafted | Highest-risk surface in v1.0 (touch events on iPad). ~6 sessions. |
| MI-302 Construction PM frontend | Brief drafted | Backend fully shipped. CP default project seeded Sun (`722f9db8...`). ~4–6 sessions. |
| MI-AUDIT-1 (firm_id filter on `get_pending_destruction`) | **Closed Sun ~17:35** | Migration `mi_audit_1_fix_get_pending_destruction` v `20260503172732`. Live function body contains `AND dn.firm_id = public.current_firm_id()`. |
| MI-AUDIT-2 (super_admin firm-crossing posture) | Informational, parked | Trigger to act: second firm beyond CP Engineers |
| MI-AUDIT-3 (audit_log heartbeat noise — `last_client_sync_at`) | Filed Sun ~17:50 | P2. 3 fix approaches (A/B/C) in decisions.md. Touches audit chain plumbing — design before patch. |
| Soft-delete view rebuild (CLAUDE.md principle #7) | Closed Sat | Migration `soft_delete_views_security_invoker_rebuild` |
| `legal_holds` workflow | Backend exists, no UI | Table indexed + RLS-locked. No active ticket. |
| Demo tenant + `firm_safe_to_display` | Closed Sat | Migrations `firms_safe_to_display_flag` + `demo_tenant_seed_data_v3` + `demo_inspector_binding` |

---

## Tapcard cluster (~37 sessions total per 4/30/26 refinement)

| Ticket | What | Sessions | Status |
|---|---|---|---|
| MI-100 | Sector toggle (NJ6_NORMAL / NJAW_SHORT_HILLS) | 3 | Closed |
| MI-101 | Normal Tapcard 3-page (CDM-Smith rules b, d, e) | 6 | Phases 1a-2b shipped; 2c lean tonight; 2c-form + 2d queued |
| MI-101.5 | Dual-mode entry (Type fields \| Photo notebook + Vision parse) | 4 | Queued post-Phase-4 |
| MI-102 | ShortHills (Company + Restoration) | 5 | Surfaces in Phase 2c — placeholder tab tonight, build queued |
| MI-103 | Vision parse refs DONE → build spec | 0 | Blocked on 3 reference images |
| MI-104 | Admin override | 4 | Queued |
| MI-105 | ShortHills customer-side | DEFERRED | Out of v1 |
| MI-107 | KILL subtypes + tiered rule engine | 5 | Queued |

**Two sectors:** `NJ6_NORMAL`, `NJAW_SHORT_HILLS`. **Sector lives on `properties` (not `phase_submissions`)** — verified Sunday. UI dispatch reads `properties.sector` via JOIN at modal load.

---

## Schema state surprises (banked Sunday — refresh from stale memory)

- **23 firm_id indexes** across schema. Memory said 7. Schema grew silently as compliance + Construction PM tables shipped.
- **Construction PM backend fully shipped:** `contractor_arrival_log` (16 cols), `contractor_departure_log` (17 cols, FK to arrival_log), `contractor_assignments` (15 cols). All RLS-forced + firm_id indexed.
- **Restoration backend partial:** `restoration_grid_entries` exists, RLS-locked, sector enum CHECK present.
- **`legal_holds`, `destruction_notices`, `photo_rescue`, `supervisor_alerts`, `projects`** all exist + indexed + RLS-locked. Not in active v0.1 UI; future tickets can build on them without new migrations.
- **`phase` enum has 9 values** (not 8 — memory was stale). MI-108's `no_work` is included.
- **Sector enum on `properties` (not `phase_submissions`).** Same CHECK on `restoration_grid_entries` and `parts_catalogs`.
- **`inspections` table exists** with firm_id + RLS — not currently used; older surface or higher-level abstraction over `phase_submissions`. Worth a row-count + column-shape check next audit cycle.

---

## Audit posture (post Sunday verification + security audit)

🟢 **Multi-tenant isolation: GREEN.** 22 tables with firm_id, all RLS-forced + ≥1 policy. 3 tables without firm_id are global by design (`firms`, `modules`, `parts_catalogs`).

🟢 **Audit chain primitives DEFINER-gated correctly.** `compute_audit_hash`, `write_audit_log`, `audit_log_chain_trigger`, `record_compliance_event` all reference firm_id or auth.uid and are scoped.

🟢 **26 SECURITY DEFINER functions audited.** 21 OK with explicit firm_id, 2 OK with auth.uid + verified scope, 1 super_admin-by-design (`release_legal_hold` → MI-AUDIT-2 informational), 1 fix shipped (`get_pending_destruction` → MI-AUDIT-1 closed Sun).

🟡 **MI-AUDIT-3 filed.** `last_client_sync_at` heartbeat writes are firing audit triggers — ~50%+ of current 288/24h baseline is heartbeat noise, not state change. P2. Design before patch (touches hot trigger). Lead surveys other heartbeat-not-state fields during fix design.

🟢 **Phase 2b real-shape verified Sunday 17:50.** Jorge live tapcard submission `1b37d77c-...`: tapcard_data jsonb has correct 3 keys (`sector`, `company_side`, `materials_sheet_id_at_submit`); CHECK constraints satisfied; multi-tenant isolation honored; hash chain intact across the INSERT + 2 UPDATEs.

🟡 **Tapcard `materials_sheet_id_at_submit` = null in the live submission.** Correct fallback when no Materials Sheet exists at submit time (Jorge confirmed he didn't fill one first). First Materials Sheet attach behavior verifies on a future submission with both surfaces used.

---

## Resolved questions (Sunday batch)

- **Q-2 (Vercel preview verification):** all 3 Saturday PRs verified post-merge.
- **Q-7 (Materials Sheet autosave cadence):** **Option C — explicit Save Draft sub-action.** Implementation: third button in materials_sheets modal. ~1.1–1.3x baseline audit_log volume.
- **Q-2c-c (homeowner_contact_log visibility):** firm-visible (not per-inspector).
- **Q-302-b (Construction PM photo UX):** inline 40×40 thumbnails + lightbox.
- **Q-302-c (GPS anomaly threshold):** 50 m from property polygon (tunable after 30 days of real data).
- **Q-110-b (pre-Phase-4 tapcards):** read-only mode with banner ("No diagram on this submission. Submitted before Phase 4.").

## Deferred / parked

- **Q-2c-d (ShortHills demo properties):** 0 ShortHills properties on prod. Parked until first real ShortHills import. Don't seed placeholders.
- **Q-2c-e (ShortHills parts catalog):** 16 NJ6_NORMAL rows only. Same parking principle. Clone with sector flipped when first real ShortHills property lands.
- **Q-110-a (Phase 4 asset type enum scope):** brief default 4 types, Buddy suggests 9. Jorge's call when Phase 4 build is closer (~week of 5/11+).

---

## Recent ships (chronological — last 4 days)

**Sat 5/2:**
- 4 migrations via Supabase MCP: `parts_catalogs_placeholder_seed`, `demo_inspector_binding`, `cs_replacement_auth_immutability_revoke_service_role`, `mi204b_firm_id_indexes`
- 3 PR squash-merges: `mi203-step2`, `mi101-phase2a`, `mi101-phase2b` (original)
- `njaw-selector` original closed unmerged (conflict casualty); `njaw-selector-v2` rebuild status uncertain at this writing
- Tapcard scope correction mid-session via Jorge's `INSPECTOR_SHEET-TAPCARD_TEMPLATE.pdf` upload — Lead refactored Phase 2b on `mi101-phase2b-refactor`
- BB-001 (AR auto-fill tapcard) parked, trigger = first paying non-CP customer

**Sun 5/3 morning:**
- `mi101-phase2b-refactor` PR merged 0:52 as `4d70901`
- MI-203 step 3 shipped ~08:55 via Supabase MCP migration `mi203_step3_drop_firms_read_anon`
- `serranogroup.org` registered at Cloudflare Registrar ($7.50 first year, $10.13/yr renewal)
- Cloudflare Email Routing: `jorge@serranogroup.org` → `jserranojr340@live.com`
- Marketing site deployed to Cloudflare Pages (`steep-pine-05b2.jserranojr340.workers.dev`); custom domain wiring queued behind Cloudflare propagation lag

**Sun 5/3 afternoon (Buddy max-execution sprint):**
- Full prod verification across 8 surfaces (`SUNDAY_VERIFICATION_5-3-26.md`) — all GREEN or expected-pending
- Security audit (`SUNDAY_SECURITY_AUDIT_5-3-26.md`): 22 firm_id tables clean; 1 finding → MI-AUDIT-1
- 3 production-ready briefs drafted: `MI101_PHASE2C_BRIEF.md`, `MI110_PHASE4_BRIEF.md`, `MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`

**Sun 5/3 evening:**
- MI-AUDIT-1 shipped via Supabase MCP migration `mi_audit_1_fix_get_pending_destruction` (v `20260503172732`)
- CP Engineers default project seeded via migration `seed_cp_engineers_default_project` (`722f9db8-a484-46a1-8142-ea6cc4bc672c`, NJAW LCRI Program 2026) — closes MI-302 frontend FK gate
- 6 Q ratifications (Q-7=C, Q-2c-c, Q-302-b/c, Q-110-b + 2 deferrals Q-2c-d/e)
- Phase 2b real-shape verified GREEN via Jorge live tapcard submission
- MI-AUDIT-3 filed (audit_log heartbeat noise from `last_client_sync_at`)

**Mon 5/5 (tonight):**
- Phase 2c direction revised by Jorge: lean scaffold only — Property Detail tabs (Overview / Restoration / ShortHills) + visual-tapcard-preview-container in `#modal-tapcard`. ShortHills tab is "Coming soon" placeholder. Restoration tab is structure only; form pickup deferred to next session as MI-101 Phase 2c-form. No migrations except the already-shipped MI-AUDIT-1. STATE.md refresh (this file) + status.md full reconciliation queued.
- MI-101 Phase 2d Visual Tapcard preview brief in flight (Buddy writing for next session).

---

## Open investigations / blockers

- **MI-AUDIT-3** — design which fields besides `last_client_sync_at` belong in the heartbeat-not-state bucket (plausibly `last_seen_at`, `client_session_id`, `device_metadata` if they exist). Survey before patch. 3 fix approaches in decisions.md.
- **3 reference images** for MI-100 vision parsing — Jorge to provide. Still blocked.
- **Whiteboard sample photos** for false-positive prompt tuning — Jorge to provide. Still blocked.
- **Isolated test tenant** for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 isolated-tenant unlock.
- **`njaw-selector-v2`** push status — Jorge to verify on GitHub branches page; if pushed → open PR + Vercel verify + merge.

## Decisions parked (not blockers)

- Memory audit execution (5 replace + 4 remove + 4 add) — runs during a chat session
- BidGrid kickoff timing — after MyInspector v0.1 close
- Mercury bank account opening — post-lawyer Mon 5/4
- Trademark filings (BidGrid, MyInspector, Tia, FORGE) — ~$1,400 budgeted
- Lawyer outreach Mon 5/4 AM via `serrano-group-site/legal/email-lawyer.md`
- LinkedIn Company Page — parked until Monday post-lawyer

---

## Capital deployed in Serrano Group LLC (running tally; ops/expenses.csv source-of-truth)

- LLC formation + EIN: ~$200–370 (TBD line items)
- MacBook Air M4 Pro: ~$1,000–1,400 (Section 179 eligible)
- Asus laptop (primary dev): pre-existing
- Claude Max 20x plan: $200 (Saturday 5/2)
- Anthropic API credits: minimal
- Cloudflare Registrar (`serranogroup.org`): $7.50 first year, $10.13/yr renewal — 5/3/26
- Vercel + Supabase + Mercury: $0 (free tiers)
- NJ State Bar lawyer (Mon 5/4): ~$300 budgeted
- USPTO trademark filings: ~$1,400 budgeted (~4 marks × $350)

**Total deployed YTD: ~$1,508–2,508, largely tax-deductible.**

---

## Last 3 sessions

1. **Sat 5/2 ~23:00** — Tapcard milestone reached. 4 migrations + 3 PR merges + Phase 2b refactor on dedicated branch. Saturday close advanced LCRI scope from ~30% to ~62%. Filesystem `edit_file` em-dash truncation incident on decisions.md (recovered via `write_file`); lesson banked: avoid `edit_file` for content with em-dashes/special chars.
2. **Sun 5/3** — Buddy max-execution sprint. Saturday queue closed (Phase 2b refactor merge + MI-203 step 3 ship). Domain + email + marketing-site infrastructure stood up. Full prod verification + security audit. 3 spec briefs drafted. MI-AUDIT-1 shipped. CP default project seeded. 6 Q ratifications. Phase 2b real-shape verified via Jorge live submission. MI-AUDIT-3 filed. decisions.md reverted/restored mid-day (lesson: Buddy writes during Lead's stash cycle anticipate stash conflicts).
3. **Mon 5/5 (tonight)** — STATE.md refresh (this), Phase 2c lean scaffold (tabs + visual preview container, no migrations), Phase 2d brief in flight, status.md full reconciliation.

## Next session opens with — MI-101 Phase 2c-form pickup

Restoration form ships clean: 5 acceptance criteria, photo upload (pre + post), sector dispatch (NJ6_NORMAL / NJAW_SHORT_HILLS), whiteboard requirement enforcement (per locked rule when open excavation exists), Save Draft button (Q-7=C). Tab structure already exists from tonight's lean scaffold.

After 2c-form: pick from MI-101 Phase 2d (Visual Tapcard auto-populate per Buddy's drafted brief), MI-302 Construction PM frontend (FK target now seeded), MI-110 Phase 4 (Diagram editor — highest risk), or MI-AUDIT-3 fix (audit chain heartbeat patch).

---

## Velocity benchmark
- 90-min focused build = 20–23 SQL milestones (~4 min/milestone)
- MyInspector v1.0 = **57–78 sessions** (7 modules + BidGrid enterprise + residential + integrations + billing)
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
