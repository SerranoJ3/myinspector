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
- **18 public tables, two categories:**
  - **13 business tables:** `properties`, `phase_submissions`, `daily_reports`, `modules`, `projects`, `inspections`, `documents`, `luis_conversations`, `rfis`, `firms`, `profiles`, `photo_rescue`, `supervisor_alerts`
  - **5 compliance tables (added by MI-202):** `audit_log`, `compliance_events`, `destruction_notices`, `legal_holds`, `whiteboard_override_log`
- **RLS:** forced on all 18 tables (MI-200 closed 4/27/26 for the original 13; MI-202 added the 5 compliance tables under the same regime). Business tables enforce per-firm isolation via `firm_id`. Compliance tables enforce role-based access (typically super_admin) via `profiles.role`. At least 1 policy per table. Cross-firm isolation verified Phase 1 item 2.
- **Firm isolation:** `profiles.firm_id` (uuid, FK → `firms.id`) is the canonical firm-isolation column. Nullable for super_admin accounts — RLS predicates must handle the NULL branch explicitly.
- **Audit chain:** 5-layer immutability stack via MI-202
  1. RLS forced on all 18 tables — baseline access control before any audit logic runs
  2. AFTER INSERT/UPDATE/DELETE triggers on every Owner Data table call `write_audit_log()` — every mutation produces an audit row
  3. SHA-256 hash chain on `audit_log` via `audit_log_chain_trigger` BEFORE INSERT — `'GENESIS'` literal seed, pipe-delimited canonical encoding, `\N` for NULL, hex output
  4. Conditional immutability via `enforce_legal_hold()` BEFORE UPDATE/DELETE — blocks the change only when an active legal hold scopes that row, table, or firm
  5. Nightly S3 Object Lock Compliance export, retention 10y + 30d
- **Audit chain primitives:**
  - **`record_compliance_event` RPC** — banked signature (Phase 1 item 1):
    ```
    record_compliance_event(
      p_event_type     text,                     -- required
      p_message        text,                     -- required, no default
      p_severity       text  DEFAULT 'info',
      p_details        jsonb DEFAULT NULL,
      p_source         text  DEFAULT NULL,
      p_correlation_id text  DEFAULT NULL
    )
    ```
    Returns the new event id. Always pass `p_source` and `p_correlation_id` so events trace to a ticket.
  - **`pgcrypto`** v1.3 installed in the `extensions` schema. Functions using `digest()` / `gen_random_uuid()` must `SET search_path` to include `extensions` so bare calls resolve. MI-202 functions follow this pattern; future RPCs must too.
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

### 7. Views over Owner Data and compliance tables = `security_invoker = true`
Postgres views default to `security_invoker = false`, which runs the view as definer (typically `postgres`) and bypasses RLS on the underlying tables. On a multi-tenant compliance system that's a cross-firm leak path. Every view that reads from Owner Data or compliance tables must be created `WITH (security_invoker = true)`, or have it set immediately via `ALTER VIEW`. MI-201 closed this on `compliance_dashboard` retroactively (5/1/26) — don't recreate the bug.

---

## NJAW utility rules (locked 4/30/26)
- **Codes:** M2C, H2C, FULL, MP, TP, KILL
  - KILL subtypes: ABANDON, RELOCATE_FULL, RELOCATE_STREET (see MI-107)
- **Plastic OK** on customer side from 1/2/26
- **Depth:** CS minimum 36", MP horns minimum 2'
- **Pipe:** 3/4" – 2"
- **Maplewood special case:** customer side already in spec = street-only relocate

## CDM-Smith compliance rules (4/30/26 client email)
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
- **CP Engineers:** `<rotated 2026-05-07 — see gitignored sync note>`
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
- "Create a view for the dashboard" without `security_invoker = true` — violates Principle 7

---

**Last updated:** May 1, 2026
**Source of truth for principles. STATE.md for live state.**
