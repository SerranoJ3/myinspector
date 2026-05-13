# Recent Context

**Purpose:** Current-state snapshot. What's true RIGHT NOW. Buddy reads this after `SESSION_LOG.md` to get the lay of the land without needing the auto-compaction summary or fat userMemories.

**Rules:**
- This file gets rewritten in place when state changes — not append-only
- If a section grows past ~15 lines, it's a sign it should move to its own `.coordination/` file
- Sprint history older than ~14 days lives in `SESSION_LOG.md` pruned entries OR existing per-ticket files, not here
- Pair with `SESSION_LOG.md` (chronology) and userMemories (identity)

---

## Right now

**Sprint:** MyInspector demo polish toward CP Engineers pitch ~5/21-5/22 (Stan, possibly Jeff).
**Demo readiness:** ~78-80% to v1.0 as of 5/12 evening. Demo URL `myinspector-git-demo-banner-jserranojr340-9100s-projects.vercel.app`.
**HEAD:** `1535612` on both `demo-banner` and `mi-demo-seed`. Branches synced.
**Demo health:** 23/23 GREEN as of 5/8 ~04:30 EDT (last full pre-flight). No regression observed since.
**Lawyer engagement:** Rabiyu engagement letter under review (received + reviewed 5/13). $5k retainer + 3 open questions queued before signing — see `.coordination/LEGAL_STATE.md` for full state.

## People in play

- **Stan** — CP Engineers owner. Target of pitch deck (11 slides locked, pricing: Essentials $99 / Pro $299 / Enterprise $1,499/mo).
- **Jeff** — possible additional pitch attendee.
- **Justin** (EIT) + **Tyler** (former home inspector) — beta testers. Names removed from pitch materials per legal flag; formal agreements needed before any public mention.
- **Abdul** — ASTM materials testing design partner. Validated 5/12.
- **Rabiyu** — lawyer, Wed 5/13 call.
- **Brett** — earlier outreach (see `buddy_brett_pre_staging_2026-05-09.md`).

## Tickets in flight

- **MI-200 (RLS)** — closed 4/27
- **MI-202 (audit_log + 4-layer immutability)** — build started 4/28, status check needed
- **MI-101 tapcard cluster** — MI-100/101/101.5/102/103/104/107 closed; MI-105 deferred
- **MI-115 aerial map** — shipped, integrated into property detail
- **MI-403 Field Guides** — pending SRVLINEFITTINGS_DIAGRAM.pdf upload (Jorge action)
- **MI-401-v2 GIS/Restorations** — read-only restoration sub-tab live

## Tech stack snapshot

- **Repo:** `SerranoJ3/myinspector`
- **Branches:** `demo-banner` (active dev) + `mi-demo-seed` (kept in lockstep, ff-merge only)
- **Supabase project:** `wryitfoletwskkdqqwcw` (us-east-2)
- **Production URL:** `myinspector-psi.vercel.app`
- **Tool stack:** Claude Code CLI v2.1.123 on Asus, Filesystem MCP + Supabase MCP for Buddy, n8n for cross-agent coordination
- **Schema:** 13 public tables; `phase_submissions` is the live production table (not legacy `inspections`)
- **Build environment:** Agent Teams experimental flag enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)

## Three Jorge accounts (cross-firm browsing gotcha)

| Email | Identity | Firm | Role |
|---|---|---|---|
| `demo-jorge@myinspector.io` | Demo Admin | demo (`99999999-...`) | super_admin |
| `jorge.serrano@cpengineers.com` | Jorge Serrano | CP (`d9b189a8-...`) | owner |
| `jserranojr340@live.com` | Jorge Serrano (Admin) | Serrano Group (`e99441da-...`) | super_admin god-mode |

When Jorge reports a UI bug, ALWAYS confirm which firm the data lives in before diagnosing — the "diagram not showing" issue on 5/12 turned out to be cross-firm browsing confusion, not a code bug.

## Outstanding (carry into next session)

1. **Doc-sync absorbing ~30+ commits + Lessons 10-13 banking** — STATE.md / status.md / decisions.md still behind
2. **Architecture ticket POST-DEMO:** auto-link orphan tapcards at submit time when MS exists for property (write-side fix; read-side fallback works)
3. **Distribute firm code `PIVOT-LATTICE-72`** to Justin + Tyler out-of-band (Jorge action)
4. **Tapcard PDF re-upload** for Vision-driven aesthetic match (Jorge action) — may be obsolete given 5/10 tcform polish
5. **SRVLINEFITTINGS_DIAGRAM.pdf upload** for MI-403 Field Guides publish (Jorge action)
6. **Stale `.coordination/` cleanup** — ~85 files, most are shipped handoffs; should archive to `.coordination/archive/2026-04/` and `.coordination/archive/2026-05-early/` to declutter
7. **Request CP Engineers employee handbook** from HR (input for Rabiyu handbook review — highest-priority legal action per Rabiyu)
8. **Reply to Rabiyu with 3 open questions** before signing engagement letter (see `.coordination/LEGAL_STATE.md` for question text)

## Locked principles (operating constraints)

- **Inspector-tap economy:** no feature adds inspector taps without removing more elsewhere. Inspectors do no extra work for the app.
- **Privacy:** inspector GPS tracking firm-level, default OFF. Construction PM GPS (contractor tracking) is entirely separate.
- **Code style:** brief description + file location + Ctrl+F anchor + exact find/replace block. One edit per message, Jorge "yup" before next.
- **Buddy persona:** Jorge calls Buddy "buddy"; casual reciprocal tone; push back when motion looks decoupled from direction.
- **Demo theater:** static catalogs, fake modals, no real OAuth or audit_log writes from demo pages.
- **CDM-Smith rules locked 4/30/26:** no-work = house + whiteboard photos with reason; existing MP must be noted; CS replace requires Carlo auth with date/time/reason, no exceptions.
