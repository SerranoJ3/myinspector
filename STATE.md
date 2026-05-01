# MyInspector — Current State

> **Purpose:** Single source of truth for session continuity. Read at session open. Update at session close.
> **CLAUDE.md** holds locked principles. **STATE.md** holds live state.
> Conflict with Claude memory: this file wins.

**Last updated:** May 1, 2026 ~6:00pm EDT
**Updated by:** Jorge + Claude (MI-109 Phase 1 verification + MI-201 leak fix + truth-lock pass)

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
| **MI-109 CS Replacement Authorization Gate** | Phase 1 verified — Phase 2 build queued | 1.5 + Phase 2 TBD | **CRITICAL — top of queue** |
| **MI-108 No-Work Submission Workflow** | NEW | 2 | HIGH |
| MI-203 (next gate ticket) | Queued | — | — |
| MI-204 index on `profiles.firm_id` | Queued | 0.25 | Phase 2 cleanup, perf-only |
| Soft-delete view rebuild | Queued | — | Apply CLAUDE.md principle #7 (`security_invoker=true`) |
| `legal_holds` workflow | Queued | — | Table exists per MI-202 (0 rows); workflow not built |
| Demo tenant + `firm_safe_to_display` | Queued | — | v0.1 hard requirement |

**MI-109 detail (CRITICAL):** When inspector marks a CS replacement on a phase submission, app must require Carlo authorization before submit. Required: date, time, reason text (min ~20 chars), supervisor name (Carlo Domenick by default but editable). Audit log every attempt — successful and rejected. **No exception path.** Source: CDM-Smith email rule (c). **Phase 1 (assumption verification) complete 5/1.** Phase 2 = backend migration + edge function + frontend modal + tests. **Phase 3 design question (deferred):** Immutability mechanism for `cs_replacement_authorizations` rows — GRANT-based revocation (lean for simplicity + explicit audit signal) vs permanent legal hold pattern (layer 4). Defer call until `record_whiteboard_override` + `whiteboard_override_log` are reviewed as the template, since that's our shipped pattern from MI-202.

**MI-108 detail:** No-work submissions require house photo + whiteboard photo + reason text. Source: CDM-Smith email rule (a).

**MI-201 detail (closed 5/1):** `compliance_dashboard` view ran with `security_invoker=false` (definer behavior), bypassing RLS on underlying compliance tables and exposing cross-firm rows. Fixed via single `ALTER VIEW`, audited via `record_compliance_event` (event id 11, source='MI-201', correlation_id='MI-201'). Discovered during MI-109 Phase 1 item 4. Locked rule promoted to CLAUDE.md principle #7.

**MI-204 detail:** No index on `profiles.firm_id` observed in Phase 1 item 6. Every RLS predicate that filters by firm_id pays a seq-scan cost without it. Not a correctness issue. Migration is a single `CREATE INDEX CONCURRENTLY` on prod.

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
- **`compliance_events` id gap.** Phase 1 item 2 counted 5 rows; MI-201's audit insert returned id 11. ids 6–10 unaccounted for. `compliance_events` sits outside the `audit_log` layer-2/3 protections, so this gap is its own integrity question, not a stack breach. Worth investigating cause: did a manual cleanup run, did `cleanup_build_test_data` expand its match set, or is the sequence advance from rolled-back inserts (most likely)? Owner: investigate before MI-203 design starts. **Not blocking MI-109 Phase 2.**

## Known false positives
- Whiteboard AI accepts laptop screen as whiteboard (1 case observed). Queued for prompt tuning with sample photos.

---

## Last 3 sessions
1. **4/29 ~10pm** — Bulletproof Setup Plan v1 drafted. Tooling brief, memory audit, walkthrough docs prepared. Code tab confirmed open in Claude Desktop.
2. **4/30** — CDM-Smith email from Jeff Longberg surfaced 5 compliance rules. **MI-108 + MI-109 entered the queue.** MI-109 elevated to top priority. User research meeting plan drafted for data entry team. Tonight: Git installed, Claude Code CLI installed (v2.1.123), Agent Teams flag enabled, repo cloned locally, CLAUDE.md + STATE.md committed. Supabase MCP attempted but OAuth flow failed on Windows — agents work without it for MI-109 (local files + git CLI sufficient). GitHub MCP skipped (Copilot subscription required, not blocking).
3. **5/1 evening** — MI-109 **Phase 1 verification complete** (6 items banked: RPC signatures, table inventory, triggers, `compliance_dashboard` view, pgcrypto, profiles schema). **MI-201 shipped** (`compliance_dashboard` `security_invoker` false→true, cross-firm leak closed, audit event id 11). Phase 1 surfaced 18-table inventory (13 business + 5 compliance — both categories now in CLAUDE.md), confirmed `record_compliance_event` 6-arg signature (`p_event_type`, `p_message`, `p_severity`, `p_details`, `p_source`, `p_correlation_id`), confirmed pgcrypto v1.3 in `extensions` schema with `SET search_path` convention, confirmed `profiles.firm_id` is canonical firm-isolation column but nullable for super_admin. Truth-locked into CLAUDE.md (new principle #7 on view `security_invoker`; schema source of truth expanded with audit chain primitives). PR #2 verify-list reduced — `audit_log_append` resolved by context (its role is extending the chain in layer 3, not bypassing immutability); canonical encoding match remains the one open item. New ticket: MI-204 (index on `profiles.firm_id`). New investigation: compliance_events id gap.

## Next session opens with
1. Read `CLAUDE.md`, then `STATE.md`, then `BUDDY_STANDARD.md`
2. **MI-109 Phase 2 build** — backend (migration + RLS + edge function) → frontend (modal + validation) → tests. Phase 1 assumptions verified; no blockers.
3. Then MI-108
4. Then column-fix pass (4 known bugs above)
5. Then MI-100 cluster (gated on 3 reference images from Jorge)
6. **Side track when convenient:** investigate `compliance_events` id gap; design MI-204 index migration

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
- Founded: 4:20pm April 20, 2026. 11 days in = ~18% scope.

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

---

## Next paste-prompt (MI-109 Phase 2 kickoff)

```
MI-109 Phase 2 build. Phase 1 verification complete — assumptions banked in CLAUDE.md.

Read CLAUDE.md (especially: schema source of truth, audit chain primitives, locked principle #7), STATE.md, and BUDDY_STANDARD.md before any work.

Spec: When an inspector marks a CS replacement on a phase submission, the app must require Carlo authorization before submit. Required fields: date, time, reason text (min 20 chars), supervisor name (Carlo Domenick by default but editable). Audit log every attempt (accepted + rejected) via record_compliance_event with p_event_type='cs_replacement.auth.<accepted|rejected>', p_source='MI-109', p_correlation_id=<phase_submission uuid>.

Three teammates:
1. Backend — migration: cs_replacement_authorizations table (Owner Data, RLS forced, INSERT-only, audit-chained) + cs_replacement bool on phase_submissions + edge function cs-auth-submit. Use record_compliance_event signature from CLAUDE.md verbatim. Any new view created MUST use security_invoker=true (CLAUDE.md principle #7).
2. Frontend (index.html) — Carlo modal on Submit Phase, validation, error states. Inspector cannot bypass. Handle profiles.firm_id NULL branch for super_admin override flow.
3. Tests — RLS test (cross-firm isolation), audit log integrity test (every attempt logged with correct correlation_id), E2E flow test (manual checklist okay).

Lead synthesizes, opens ONE PR, does NOT merge — Jorge reviews and merges manually.

Begin.
```
