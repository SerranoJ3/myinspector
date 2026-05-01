# MyInspector — Current State

> **Purpose:** Single source of truth for session continuity. Read at session open. Update at session close.
> **CLAUDE.md** holds locked principles. **STATE.md** holds live state.
> Conflict with Claude memory: this file wins.

**Last updated:** April 30, 2026 ~8:30pm EDT
**Updated by:** Jorge + Claude (post-CDM Smith email + tonight's setup)

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
| MI-202 Audit log + 4-layer immutability stack | Active | — | Active build |
| **MI-109 CS Replacement Authorization Gate** | NEW | 1.5 | **CRITICAL — first ticket post-setup** |
| **MI-108 No-Work Submission Workflow** | NEW | 2 | HIGH |
| MI-203 (next gate ticket) | Queued | — | — |
| Soft-delete view rebuild | Queued | — | — |
| `legal_holds` table + workflow | Queued | — | — |
| Demo tenant + `firm_safe_to_display` | Queued | — | v0.1 hard requirement |

**MI-109 detail (CRITICAL):** When inspector marks a CS replacement on a phase submission, app must require Carlo authorization before submit. Required: date, time, reason text (min ~20 chars), supervisor name (Carlo Domenick by default but editable). Audit log every attempt — successful and rejected. **No exception path.** Source: CDM-Smith email rule (c).

**MI-108 detail:** No-work submissions require house photo + whiteboard photo + reason text. Source: CDM-Smith email rule (a).

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

## Known false positives
- Whiteboard AI accepts laptop screen as whiteboard (1 case observed). Queued for prompt tuning with sample photos.

---

## Last 3 sessions
1. **4/28 evening** — MI-202 build kickoff. Audit log + 4-layer immutability spec locked. 90-min focused build delivered ~20-23 SQL milestones. Velocity benchmark established. Schema migration shipped, code-schema alignment verified (~70 audit entries).
2. **4/29 ~10pm** — Bulletproof Setup Plan v1 drafted. Tooling brief, memory audit, walkthrough docs prepared. Code tab confirmed open in Claude Desktop.
3. **4/30** — CDM-Smith email from Jeff Longberg surfaced 5 compliance rules. **MI-108 + MI-109 entered the queue.** MI-109 elevated to top priority. User research meeting plan drafted for data entry team. Tonight: Git installed, Claude Code CLI installed (v2.1.123), Agent Teams flag enabled, repo cloned locally, CLAUDE.md + STATE.md committed. Supabase MCP attempted but OAuth flow failed on Windows — agents work without it for MI-109 (local files + git CLI sufficient). GitHub MCP skipped (Copilot subscription required, not blocking).

## Next session opens with
1. Read `CLAUDE.md` then `STATE.md`
2. **Build MI-109 first** — agent team candidate (3 teammates: backend / frontend / tests)
3. Then MI-108
4. Then column-fix pass (4 bugs above)
5. Then MI-100 cluster (gated on 3 reference images from Jorge)

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
- Founded: 4:20pm April 20, 2026. 10 days in = ~17% scope.

---

## Update protocol
- **Session close:**
  - Update "Last 3 sessions" (push oldest off)
  - Update active tickets, bugs, blockers
  - `git add STATE.md && git commit -m "STATE: <date> session close" && git push`
- **Session open:**
  - `git pull`
  - Read CLAUDE.md, then STATE.md
  - Confirm tools live with `claude mcp list` (when MCPs working)
- **Conflict with Claude memory:** STATE.md wins. Memory updates lag.

---

## Tomorrow morning paste-prompt for agent team kickoff

```
Create an agent team to build MI-109 — CS Replacement Authorization Gate.

Read CLAUDE.md and STATE.md first.

Spec: When an inspector marks a CS replacement on a phase submission, the app must require Carlo authorization before submit. Required fields: date, time, reason text (min 20 chars), supervisor name (Carlo Domenick by default but editable). Audit log every attempt — successful and rejected — into the existing audit_log table from MI-202.

Three teammates:
1. Backend — schema migration + RLS policies + Edge Function for the auth submit
2. Frontend — modal UI on Submit Phase, validation, error states
3. Tests — RLS test, audit log integrity test, E2E flow test

Lead synthesizes findings, opens a single PR, does NOT merge — wait for Jorge's review.

Begin.
```
