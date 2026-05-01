# CLAUDE.md — MyInspector Project Context

> Read this file before any work on this codebase.
> Then read `STATE.md` for current session state and active tickets.
> If conflict: STATE.md wins for dynamic state, CLAUDE.md wins for locked principles.

---

## What this is
**MyInspector** — water utility field-to-compliance SaaS platform.
- Live: myinspector-psi.vercel.app
- Production domain (planned): myinspector.io
- Built solo by Jorge Serrano, sole operator of Serrano Group LLC.
- Production users: CP Engineers (NJAW LCRI project), 14 inspectors, 13 office staff. Real money, real legal exposure.

This is **production**. Treat all data and writes accordingly.

---

## Stack
- **Frontend:** Vanilla HTML/CSS/JS, single-file `index.html`. No framework. No build step.
- **Backend:** Supabase (Postgres + Edge Functions + Storage + Auth)
  - Project ref: `wryitfoletwskkdqqwcw` (us-east-2 / Ohio)
  - Project name: `myinspector`
- **Deploy:** Vercel auto-deploy from `main`
- **AI services:**
  - Luis (field assistant): Claude Haiku via Edge Function `luis-proxy` (key in `ANTHROPIC_API_KEY` secret)
  - Whiteboard detection: Claude Vision via Edge Function `detect-whiteboard`

## Schema source of truth
- **Production write table: `phase_submissions`** (NOT legacy `inspections` — that table exists but is not the live target)
- **13 public tables:** `properties`, `phase_submissions`, `daily_reports`, `modules`, `projects`, `inspections`, `documents`, `luis_conversations`, `rfis`, `firms`, `profiles`, `photo_rescue`, `supervisor_alerts`
- **RLS:** forced on all 13 tables (MI-200 closed 4/27/26). At least 1 policy per table. Cross-firm isolation verified.
- **Audit chain:** 4-layer immutability stack via MI-202
  1. No UPDATE/DELETE grant on Owner Data tables
  2. BEFORE UPDATE/DELETE trigger raises exception
  3. SHA-256 hash chain (`'GENESIS'` literal seed, deterministic canonical encoding)
  4. Nightly S3 Object Lock Compliance, retention 10y + 30d
- **Schema changes:** migration files only. No raw SQL writes. Changes outside migration history break the audit chain.

---

## Locked principles (do not violate)

### 1. Inspectors do no extra work
Infer state from actions already taken. If a feature adds inspector taps without removing more, it fails the core test. Exceptions get buried override paths, not default prompts.

> Jorge's rule: "I'm building this to help my guys, not add to their day."

### 2. Whiteboard rule
Required ONLY when open excavation exists:
- Required: curbstop area, watermain area, restoration (incl. rainy day)
- Not required: tapcard/triangulation, GIS docs, exterior, blueprints, backlog collection

Rule: hole in the ground = whiteboard. No hole = no whiteboard.

### 3. Inspector GPS = OFF by default, firm-level toggle
Construction PM GPS (tracking contractors, NOT inspectors, for billable-hour verification) is a separate system. Keep clearly separated in code — different tables, different policies.

> Jorge's rule: "I don't want my guys getting in trouble for being an hour late cuz they dropped their kid off at school."

### 4. Production database access
- Read-only by default for any agent or automation.
- Per-write approval required for any DB-modifying tool call.
- No automated production writes. Schema changes go through migration files only.

### 5. Triangulation anchor rule
**CS is the anchor** (pre-existing fixed point). MP and other installed assets described relative to CS.
- Correct: "MP is 4'6\" left of CS"
- Wrong: "CS is 4'6\" right of MP"

### 6. ShortHills sector role inversion
Same NJAW utility rules apply across all sectors. What differs is the role:
- **NJAW Normal / Maplewood / most towns:** contractor (Montana / Conquest / etc.) interacts with homeowner + handles means and methods
- **ShortHills sector:** inspector dictates means and methods to contractor + interacts with homeowner directly

Tapcard report format and role permissions differ accordingly. See MI-100 for sector toggle.

---

## NJAW utility rules (locked 4/30/26)
- **Codes:** M2C, H2C, FULL, MP, TP, KILL
  - KILL subtypes: ABANDON, RELOCATE_FULL, RELOCATE_STREET (see MI-107)
- **Plastic OK** on customer side from 1/2/26
- **Depth:** CS minimum 36", MP horns minimum 2'
- **Pipe:** 3/4" – 2"
- **Maplewood special case:** customer side already in spec = street-only relocate

## CDM-Smith compliance rules (4/30/26 client email — Jeff Longberg)
1. **No-work submission** = house photo + whiteboard photo with reason text (MI-108)
2. **Existing MP** must be noted on submission (MI-101 field add)
3. **CS replacement** = Carlo authorization (date + time + reason) — **NO EXCEPTION** (MI-109)
4. **MP horn copper** has its own field on tapcard (MI-101 field add)
5. **CS-to-house** only 1 negative is valid (CS past corner) — sign convention validator (MI-101 field add)

These rules came directly from the client. They are compliance, not preference. Build them as written.

---

## Build conventions

### Code-edit reply format (locked)
- Brief description + file location + Ctrl+F anchor + exact find/replace block
- One edit per message; user acknowledges with "yup" before next
- No filler, no re-asking context, no multi-option committees when a confident recommendation exists
- Code changes more than 3 lines = full-file replace, not surgical edits

### Velocity benchmark
90-min focused build = 20-23 SQL milestones (~4 min/milestone, including mistakes/retries).
Use this for ALL timeline estimates.

### Commit hygiene
- Conventional-ish commits (feat:, fix:, chore:, refactor:)
- One logical change per commit when possible
- Never force-push `main`
- Never commit secrets, PATs, or `.env` content

---

## Firm codes
- **CP Engineers:** `QUIET-RIVER-58`
- **Serrano Group:** `SERRANO-ADMIN-ONLY`

## Key accounts
- `jorge.serrano@cpengineers.com` (owner)
- `justin.esteves@cpengineers.com` (inspector)
- `tyler.suess@cpengineers.com` (inspector)
- `jserranojr340@live.com` (super_admin)

---

## Agent-team specific guidance

### Spawn rules
- Lead always reads `CLAUDE.md` and `STATE.md` first; teammates read both before claiming a task
- Lead breaks tickets into clear, file-scoped subtasks (frontend / backend / tests, or by module)
- Teammates do NOT modify shared files concurrently — task assignment must avoid file overlap
- Lead opens ONE PR per ticket; does NOT merge — Jorge reviews and merges manually

### Out of scope for agent teams (do not act on)
- Production database writes
- Schema changes outside migration files
- Vercel deploy operations
- Anything touching the audit chain (use migration files, not direct queries)
- Trademark / legal / financial decisions
- Any work that adds inspector taps without removing more

### Pause and escalate when
- A task requires a production DB write
- A task requires a schema change that affects existing audit-logged rows
- A locked principle conflicts with the spec
- The CDM-Smith compliance rules conflict with proposed implementation
- Carlo authorization (CS replacement) flow is unclear

---

## Anti-patterns (red flags — stop and ask)
- "Add a status dropdown for inspectors to set X" — violates Principle 1
- "Auto-track inspector location for productivity" — violates Principle 3
- "Quick fix via direct SQL" — violates audit chain rule
- "Skip the whiteboard rule for this case" — only valid if no excavation
- "Treat ShortHills like other sectors" — role inversion is real, not optional

---

**Last updated:** April 30, 2026
**Source of truth for principles. STATE.md for live state.**
