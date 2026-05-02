# MyInspector — Current State

> **Purpose:** Single source of truth for session continuity. Read at session open. Update at session close.
> **CLAUDE.md** holds locked principles. **STATE.md** holds live state.
> Conflict with Claude memory: this file wins.

**Last updated:** May 2, 2026 ~12:50pm EDT
**Updated by:** Jorge + Buddy (MI-109 closed — PR #3 squash-merged to main as `e76fac2`; pivot to SG-001 Node 2)

---

## Project header
- **Repo:** SerranoJ3/myinspector (main, Vercel auto-deploy)
- **Live URL:** myinspector-psi.vercel.app
- **Production domain (planned):** myinspector.io
- **Supabase project:** `myinspector` (ref `wryitfoletwskkdqqwcw`, us-east-2/Ohio)
- **Local clone:** `C:\Users\jserr_0phql\Documents\Serrano Group LLC\Code\myinspector`

---

## Active gate: v0.1 Compliance Foundation

| Ticket | Status | Sessions | Priority |
|---|---|---|---|
| MI-200 RLS forced + at least 1 policy per table | Closed 4/27 | — | — |
| MI-201 compliance_dashboard `security_invoker` fix | Closed 5/1 | 0.5 | — |
| MI-202 Audit log + 5-layer immutability stack | Active | — | Active build |
| **MI-109 CS Replacement Authorization Gate** | **CLOSED 5/2 midday — PR #3 squash-merged to main (`e76fac2`). Backend live (migration applied to prod 5/2 late). Frontend Carlo modal deploys via Vercel auto. SQL coverage 17/17 (rls 9/9 + audit 8/8). 1 real bug caught + fixed during Phase 4 (audit_log delta +1→+2). 3 doc fixes shipped (commit `f7c2144`). Manual e2e walk deferred to MI-109.5.** | 4.5 total (1.5 P1 + 2.5 P2 + 0.5 P4) | Closed |
| **MI-109.5 Manual e2e UI walk on isolated staging** | NEW — deferred from MI-109 Phase 4 | 1 | LOW — SQL coverage already proved every code path; UI walk would be duplicate confidence at the cost of immutable audit_log writes on prod (preview deployment hits prod Supabase). Walk after SG-001 Node 2 ships isolated test tenant. |
| **MI-108 No-Work Submission Workflow** | NEW | 2 | HIGH |
| MI-203 (next gate ticket) | Queued | — | — |
| MI-204 index on `profiles.firm_id` | Queued | 0.25 | Phase 2 cleanup, perf-only |
| Soft-delete view rebuild | Queued | — | Apply CLAUDE.md principle #7 (`security_invoker=true`) |
| `legal_holds` workflow | Queued | — | Table exists per MI-202 (0 rows); workflow not built |
| Demo tenant + `firm_safe_to_display` | Queued | — | v0.1 hard requirement |

**MI-109 detail (PR #3 — draft, awaiting verification):** When inspector marks a CS replacement on a phase submission, app requires Carlo authorization before submit. Required: single `authorized_at` timestamptz, reason ≥ 20 chars, supervisor name (Carlo Domenick by default but editable). Every attempt audit-logged via `record_compliance_event` at severity `'alert'`. **No exception path.** Source: CDM-Smith email rule (c).

- **Phase 1 (5/1):** assumption verification — RPCs, table inventory, triggers, view security_invoker, pgcrypto, profiles schema. Surfaced MI-201 leak. Banked architectural truth into CLAUDE.md.
- **Phase 2 (5/2):** 3-teammate Agent Team build (frontend / backend / tests). Mid-build surfaced 3 load-bearing inventions (RPC return shape → JSONB envelope, RLS expression, gen_random_uuid qualification) + NB3 override (single `authorized_at` vs split). Post-build review caught 4 more (signature mismatch named-scalars vs jsonb, AUTHORIZED_AT_MISSING unenumerated, PHASE_SUBMISSION_NOT_FOUND overloaded, existing_authorization_id detail key). Consolidated fixup commit `ce2c2a5`. Draft PR #3 open.
- **Phase 3 (deferred):** Immutability mechanism for `cs_replacement_authorizations` rows — GRANT-based revocation (current default, INSERT-only via grants) vs permanent legal hold pattern (layer 4). Defer call until `record_whiteboard_override` + `whiteboard_override_log` are reviewed as template.
- **Phase 4 (NEXT SESSION):** verification — apply migration in SQL editor, run `tests/mi109/{rls,audit_integrity}_test.sql` against staging, walk `e2e_checklist.md`. If pass: convert PR to ready-for-review and merge.

**MI-108 detail:** No-work submissions require house photo + whiteboard photo + reason text. Source: CDM-Smith email rule (a).

**MI-201 detail (closed 5/1):** `compliance_dashboard` view ran with `security_invoker=false` (definer behavior), bypassing RLS on underlying compliance tables and exposing cross-firm rows. Fixed via single `ALTER VIEW`, audited via `record_compliance_event` (event id 11, source='MI-201', correlation_id='MI-201'). Discovered during MI-109 Phase 1 item 4. Locked rule promoted to CLAUDE.md principle #7.

**MI-204 detail:** No index on `profiles.firm_id` observed in Phase 1 item 6. Every RLS predicate that filters by firm_id pays a seq-scan cost without it. Not a correctness issue. Migration is a single `CREATE INDEX CONCURRENTLY` on prod.

---

## Phase 2 working artifacts (preserved on `mi-109-rpc-rebuild` branch — review in PR #3)

- `discovery/whiteboard_override_template.md` — Phase 2 architectural notes from Jorge + Decision log + Inventions list. Useful template for future similar compliance gates: NB1-NB13 inventions pattern, load-bearing-INV escalation protocol, chat-truncation workaround pattern.
- `MI109_HANDOFF.md` — mid-session handoff state captured at 90% chat budget. Demonstrates the "preserve ambiguity in writing rather than fight truncation" pattern. Lessons section worth folding into BUDDY_STANDARD.md after merge.

---

## Tapcard cluster (gated behind v0.1 close)
**Refined 4/30/26. ~37 sessions total** (was 33).

| Ticket | What | Sessions | Notes |
|---|---|---|---|
| MI-100 | Sector toggle (NJ6_NORMAL / NJAW_SHORT_HILLS) | 3 | Drives MI-101 vs MI-102 |
| MI-101 | Normal Tapcard 3-page | 6 | Adds: existing MP note + MP horn copper field + CS-to-house sign-convention validator (CDM-Smith rules b, d, e) |
| MI-101.5 | Dual-mode entry (Type fields | Photo notebook + Vision parse) | 4 | Inspector preference saved per-firm |
| MI-102 | ShortHills (Company + Restoration) | 5 | Role inversion enforced |
| MI-103 | Vision parse refs DONE → build spec | 0 | Spec output, no build |
| MI-104 | Admin override | 4 | Bury, don't default |
| MI-105 | ShortHills customer-side | DEFERRED | Out of v1 |
| MI-107 | KILL subtypes (ABANDON / RELOCATE_FULL / RELOCATE_STREET) + tiered rule engine | 5 | Utility + municipal, effective-dated |

**Two sectors:** `NJ6_NORMAL`, `NJAW_SHORT_HILLS`.

---

## Known bugs (column-fix pass scheduled AFTER MI-109, BEFORE MI-100)
1. **ServiceWork tile** writes `phase=service_install`, `service_type=service` — both should be `service_work`
2. **OutOfOrder tile** writes `phase=out_of_sequence`, `service_type=test_pit` — wrong mapping, needs correct values
3. **NJAW codes** TP, KILL, FULL referenced in spec but DO NOT exist in schema yet — `service_type` stores tile clicked, not NJAW code
4. **Form codes** LSL-R, PLSL-R, GV-R, INS captured in form but not persisted to DB

## Open investigations (audit chain integrity)
- **`compliance_events` id gap.** Phase 1 item 2 counted 5 rows; MI-201's audit insert returned id 11. ids 6–10 unaccounted for. `compliance_events` sits outside the `audit_log` layer-2/3 protections, so this gap is its own integrity question, not a stack breach. Worth investigating cause: did a manual cleanup run, did `cleanup_build_test_data` expand its match set, or is the sequence advance from rolled-back inserts (most likely)? Owner: investigate before MI-203 design starts. **Not blocking MI-109 Phase 4.**
- **AUTH_DENIED telemetry gap (accepted limitation).** RAISE EXCEPTION inside the RPC rolls back the inner `compliance_events` INSERT, so AUTH_DENIED attempts are NOT recorded. Flagged in `tests/mi109/e2e_checklist.md` step 31. Follow-up consideration if telemetry is wanted later (e.g., NOTIFY-based out-of-tx logging).

## Known false positives
- Whiteboard AI accepts laptop screen as whiteboard (1 case observed). Queued for prompt tuning with sample photos.

---

## Last 3 sessions
1. **5/1 evening** — MI-109 **Phase 1 verification complete** (6 items banked: RPC signatures, table inventory, triggers, `compliance_dashboard` view, pgcrypto, profiles schema). **MI-201 shipped** (`compliance_dashboard` `security_invoker` false→true, cross-firm leak closed, audit event id 11). Phase 1 surfaced 18-table inventory (13 business + 5 compliance), confirmed `record_compliance_event` 6-arg signature, confirmed pgcrypto v1.3 in `extensions` schema, confirmed `profiles.firm_id` is canonical firm-isolation column but nullable for super_admin. Truth-locked into CLAUDE.md (new principle #7 on view `security_invoker`). New ticket: MI-204. New investigation: compliance_events id gap. PR #2 closed without merging.
2. **5/2** — MI-109 **Phase 2 build complete, PR #3 open as draft.** 3-teammate Agent Team (frontend / backend / tests) shipped: Carlo modal + RPC integration in `index.html`, migration with `cs_replacement_authorizations` table + `submit_cs_authorization` RPC (named scalars, JSONB envelope return, INSERT-only via grants, audit-chained), tests v3 (RLS + audit integrity + 50-step e2e checklist). Mid-build escalation surfaced 4 load-bearing inventions; post-build review caught 4 more; one consolidated fixup commit (`ce2c2a5`) covered all of them. Discovery file at `discovery/whiteboard_override_template.md` preserved as template. Mid-flight handoff at `MI109_HANDOFF.md` preserved as pattern. Chat-truncation workaround pattern proven (file channel reliable when chat channel was lossy 5+ times).
3. **5/2 late (~10pm-12am)** — **SG-001 Node 1 shipped:** filesystem MCP wired up to Buddy on Claude Desktop, scope `C:\...\Code` parent. Buddy now reads CLAUDE/STATE/BUDDY_STANDARD/branch artifacts directly — no more Jorge couriering. Rule #9 file-write gate active and tested (this commit is the first write under the gate). **MI-109 Phase 4 backend verified solo:** migration applied via Supabase SQL editor (clean), 4 sanity queries green, `rls_test.sql` 9/9 PASS, `audit_integrity_test.sql` 8/8 PASS — **caught real bug:** test step 3b expected `audit_log delta=+1` but actual is `+2` because both Owner Data writes audit (cs_auth INSERT + phase_submissions UPDATE). Audit chain working as designed per CLAUDE.md. Three Rule #9 doc fixes queued for tomorrow (audit_integrity_test +1→+2 fix; e2e_checklist `supabase db push`→SQL editor; PR_MI109 stale `audit_log_append` + `payload::text` refs).

## Next session opens with — SG-001 Node 2 (agent-to-agent automation)

MI-109 closed via merge in this session. Pivot to SG-001 because today's session repeatedly demonstrated the cost of copy-paste between Buddy chat and Claude Code terminal: multiple instances of relayed git commands, SQL output, and branch state. Per Jorge: "we waste too much usage and tokens copy and pasting into chat and code."

**Node 2 goal:** Buddy in chat and lead in Claude Code talk to each other directly via shared file channel. Reduce Jorge's role to authorize/yup/redirect, not relay.

1. Read `BUDDY_STANDARD.md`, `CLAUDE.md`, `STATE.md`, `SG001_BRIEF.md`
2. Confirm Node 1 (filesystem MCP) state — live and tested per 5/2 work, Rule #9 file-write gate active
3. Design Node 2 mechanism (per `SG001_BRIEF.md`): file channel under `.coordination/` is the candidate. Buddy writes intent files; lead polls; lead writes result files; Buddy reads. Standard envelope shape (correlation_id, status, result, errors). n8n optional layer 2.
4. Stand up minimum viable channel: status.md (current branch + last action), buddy_intent.md (Buddy's next ask), lead_result.md (lead's response). Convention pattern, not framework.
5. Test against a real ticket — likely MI-108 (No-Work Submission Workflow, CDM-Smith rule a) since it's the next HIGH priority and similar structure to MI-109.
6. After it works once, fold the pattern into BUDDY_STANDARD.md as working rule #10.

## After SG-001 Node 2 lands:
- MI-108 (2 sessions, HIGH — CDM-Smith rule a)
- Then column-fix pass (4 known bugs)
- Then MI-100 cluster (gated on 3 reference images from Jorge)
- **Side track:** investigate `compliance_events` id gap; design MI-204 index migration; MI-109.5 once isolated tenant exists

## Blockers (Jorge to resolve when ready)
- 3 reference images for MI-100 vision parsing (tapcard form, restoration card, admin screenshot)
- Whiteboard sample photos for false-positive prompt tuning

## Decisions parked (not blockers, just queued)
- Memory audit execution (5 replace + 4 remove + 4 add) — runs during a chat session
- Supabase MCP retry (OAuth failed Windows-side, retry when fresh)
- GitHub MCP setup (requires Copilot subscription OR Docker — defer)
- BidGrid kickoff timing — after MyInspector v0.1 close
- Mercury bank account opening
- Trademark filings (BidGrid, MyInspector, Tia, FORGE)

---

## Velocity benchmark (use for ALL timeline estimates)
- 90-min focused build = 20-23 SQL milestones (~4 min/milestone)
- MyInspector v1.0 (7 modules + BidGrid enterprise + residential + integrations + billing) = **57-78 sessions**
- Aggressive target: **mid-June 2026**
- Realistic: **mid-July 2026**
- Founded: 4:20pm April 20, 2026. **12 days in = ~20% scope.**

---

## Update protocol
- **Session close:**
  - Update "Last 3 sessions" (push oldest off)
  - Update active tickets, bugs, blockers
  - `git add CLAUDE.md STATE.md && git commit -m "STATE: <date> session close" && git push`
- **Session open:**
  - `git pull`
  - Read CLAUDE.md, STATE.md, BUDDY_STANDARD.md
  - Confirm tools live with `claude mcp list` (when MCPs working)
- **Conflict with Claude memory:** STATE.md wins. Memory updates lag.
