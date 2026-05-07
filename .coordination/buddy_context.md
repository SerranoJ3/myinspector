# Buddy Context — Bootstrap Digest

**Generated:** 2026-05-05 ~21:35 EDT (refreshed post-CC-stop-and-ping caught documentation drift)
**Stale after:** next session-close OR next major commit on main
**v1 of this digest had errors — see "Banked discipline" section for what changed**

---

## Where we are

- **MyInspector v0.1 Compliance Foundation** — ~62% through v1.0 scope by session count.
- **Saturday's PR merges + Sunday's Phase 2b refactor** — backend everywhere, frontend partial. Specifically:
  - `mi203-step2` merged Sat (`001af69`) — `lookup_firm_by_code` SECURITY DEFINER RPC for pre-auth firm lookup
  - `mi101-phase2a` **PR opened Sat — backend migrations shipped, FRONTEND NEVER MERGED.** Lives on `mi101-phase2a` branch. Backend table `materials_sheets` is live in prod (3 rows from Phase 2a preview testing). The editable `modal-materials-sheet` UI is NOT on main. Documentation across STATE.md / status.md / buddy_context.md (v1) / decisions.md asserted "merged" — caught and corrected 2026-05-05 ~21:20 EDT by CC.
  - `mi101-phase2b` (original, 3-tab structure) merged Sat (`f51c61f`) — superseded same-day
  - `mi101-phase2b-refactor` merged Sun 0:52 (`4d70901`) — kill Customer Side tab + expand Materials view + role-gated Office Fill. **This is what's on prod main today as the Tapcard surface.**
  - `mi100-frontend` (sector toggle) merged Sat (`0327abd`)
  - `mi108-frontend` (No-Work workflow) merged Sat (`8a971eb`)
- **MI-203 step 3 closed Sunday morning** — `firms_read_anon` policy dropped via Supabase MCP migration `mi203_step3_drop_firms_read_anon`.
- **MI-AUDIT-1 closed Sunday evening** — migration `mi_audit_1_fix_get_pending_destruction` v 20260503172732 shipped.
- **CP Engineers default project seeded Sunday evening** — `722f9db8-...` (NJAW LCRI Program 2026) — closes MI-302 FK gate.
- **Phase 2b real-shape verified Sunday evening** — Jorge live tapcard submission `1b37d77c-...`.
- **Tonight (Mon 5/5):**
  - Phase 2c lean scaffold landed on `demo-banner` (`91f2af4`) — Property Detail tab strip + empty visual-tapcard container
  - Phase 2d original landed on `demo-banner` (`79f8434`) — autopop wiring inside `#modal-tapcard`. **This is the wrong surface per revised Q-2d.** Will be undone in Phase 2d-revision Unit 1.
  - 3 Sunday docs commits cherry-picked to main + pushed (`e0b00c6` / `2183e84` / `99692d0`)
  - Buddy doc parallel-track sync committed on demo-banner (`7c0e83b`) — questions.md Q-7 + Q-2d resolutions, PHASE2B_TAPCARD_FIELDS_REFERENCE.md, buddy_context.md v1
  - Phase 2d-revision v1 work order drafted by Buddy + caught with errors by CC (Phase 2a merge state, schema field names) — v2 work order on disk at `work_order_2026-05-05_phase2d_revision_v2.md`
  - 4 new feature briefs + work orders on disk: MI-401 GIS List Tab, MI-402 Towns/Contractors, MI-403 Field Guides, MI-404 Herald Tab

## Documentation drift caught tonight (2026-05-05 ~21:20 EDT)

CC's stop-and-ping during Phase 2d-revision Session 1 kickoff caught:

1. **Phase 2a frontend never merged.** STATE.md, status.md, buddy_context.md v1, decisions.md all asserted "Phase 2a closed Sat — PR merged." Verified via git: `git show main:index.html | grep modal-materials-sheet` returns 0. Cross-branch verification: only `mi101-phase2a` and `origin/mi101-phase2a` contain the modal. Backend migrations DID ship Saturday (verified — materials_sheets table has 3 rows, 39 columns). Frontend modal lives on the unmerged branch.

2. **Schema field map drift.** v1 Phase 2d-revision work order referenced `properties.address_number`, `address_street`, `cross_street`, `lot`, `block`, `apt_bldg`, `owner_name`, `county` — none of those columns exist. Actual `properties` schema (verified via Supabase MCP `list_tables` 2026-05-05 21:25 EDT): `id, address (single string), city, municipality, state, zip, lot_block (concatenated), lat, lng, mapcall_id, company_material, customer_material, current_phase, firm_id, created_at, deleted_at, deleted_by, sector, project_id`. 19 columns total. `materials_sheets` schema: 39 columns, flat NJAW/customer old/new (no service_materials_grid jsonb).

3. **Implication:** Production today — inspectors cannot create materials_sheets via UI on main. The 3 existing rows came from Phase 2a preview deployment testing. Phase 2d-revision v2 work order adds Unit 0 (Phase 2a → main merge) as precondition.

## What's pending (priority-ordered, post-correction)

**Tonight (CC, in flight):** Path C — MI-AUDIT-3 trigger filter only. Phase 2d-revision held for v2 work order pickup next session.

**Next session (CC, from `work_order_2026-05-05_phase2d_revision_v2.md`):**
- Unit 0: Phase 2a → main merge (~30-45 min, rebase + conflict resolution + Vercel verify + squash-merge)
- Unit 1: Phase 2d-revision Session 1 — rebase visual tapcard onto `modal-materials-sheet` (now exists post-Unit-0)
- Unit 2: Phase 2d-revision Session 2 — autopop wiring + materials installed extrapolation
- Unit 3: Documentation drift correction across STATE.md / status.md / buddy_context.md / decisions.md

**Lead's queue post-Phase-2d-revision:**
1. **MI-101 Phase 2c-form** (Restoration form) — 5 acceptance criteria, photo upload, sector dispatch, whiteboard requirement, Save Draft button (Q-7=C). Tab structure already scaffolded in `91f2af4`.
2. **MI-401 GIS List Tab** — paper-replacement workflow. ~3 sessions. Work order on disk.
3. **MI-404 Herald Tab** — Jeff is in the August 2025 issue (Schmitz Tank, NICET cert mention). Demo strategic. ~2 sessions. Work order on disk.
4. **MI-402 Towns/Contractors** — smallest, ~30 min backend + optional frontend. Work order on disk.
5. **MI-403 Field Guides Tab** — fittings reference library. ~2 sessions. Work order on disk.
6. **MI-302 Construction PM frontend** — backend fully shipped, CP project seeded. ~4-6 sessions.
7. **MI-110 Phase 4 Diagram editor** — highest-risk surface. ~6 sessions.

**Open questions:**
- **Q-110-a** open — Phase 4 asset type enum scope. Not blocking near-term.
- All other Q's resolved.

**Jorge's clicks (residual):**
- `serranogroup.org` Cloudflare Pages custom domain retry (verified failing tonight, NXDOMAIN — DNS not wired post-propagation, retry needed)
- `njaw-selector-v2` PR — verified pushed and Vercel-deployed; STALE re: Phase 2b refactor 3-tab → 2-tab structure. Re-port the dropdown to a fresh branch off current main rather than merge stale branch.

## Files to read at session open (in order)

1. `CLAUDE.md` — locked principles
2. `STATE.md` — slow-moving authoritative state
3. `BUDDY_STANDARD.md` — working style
4. `.coordination/status.md` — Lead's fast-moving working snapshot
5. `.coordination/buddy_context.md` (this file) — Buddy's bootstrap digest
6. `.coordination/decisions.md` (FULL READ — head: 100 truncations have caused misses; banked discipline)
7. `.coordination/questions.md` — open Q queue
8. `.coordination/work_order_2026-05-05_phase2d_revision_v2.md` — next-session pickup work order
9. `.coordination/SUNDAY_VERIFICATION_5-3-26.md` — most recent prod verification
10. `.coordination/SUNDAY_SECURITY_AUDIT_5-3-26.md` — security audit + MI-AUDIT-1/2 spec
11. Source PDFs at `/mnt/user-data/uploads/`: `Field_Data_Template.pdf` (blank tapcard) + `Tapcard__1_.pdf` (filled-in 44 Dunnell example)

If conflict: STATE.md > status.md > buddy_context.md for authoritative state. CLAUDE.md > decisions.md for principles. **For branch merge state and schema columns: live verification via git + Supabase MCP wins over any documentation.**

## Working pattern that's locked

- **Code edits (>3 lines):** full-file replace, not surgical (BUDDY_STANDARD §7).
- **Rule #9:** file-write gate. Relaxation in effect for low-risk markdown writes when batch trust granted by Jorge. Per-file gate stays in force for SQL, code, security-sensitive, irreversible.
- **Rule #10:** `.coordination/` channel as canonical Buddy ↔ Lead handoff. Files are the message bus, not chat.
- **Tagged dollar-quotes (`$TESTBODY$`)** preferred over `$$` in any SQL file Buddy edits.
- **Avoid `edit_file` for content with em-dashes** — default to `write_file` for Buddy markdown writes.
- **Read full files when verifying state.** No `head: 100` / `tail: 50` truncations.
- **Long instructions → file, not chat paste.** Any work order or brief over ~200 words goes to disk via filesystem MCP. Three-sentence chat handoff: "Read .coordination/[filename] and execute. Buddy has batch trust, Q-answers locked in file. Stop conditions in file." Tonight's truncated paste failures (CC saw "ush hash" mid-word and "f spec" mid-word) prove the chat-paste failure mode is real.

## Schema state surprises — verified ground truth

**Verified via Supabase MCP `list_tables` 2026-05-05 21:25 EDT:**

- **`properties` (19 columns):** id, address (single string), city, municipality, state, zip, lot_block (concatenated), lat, lng, mapcall_id, company_material, customer_material, current_phase, firm_id, created_at, deleted_at, deleted_by, sector, project_id. **NO** address_number, address_street, cross_street, lot (separate), block (separate), apt_bldg, owner_name, county, town_section, development.
- **`materials_sheets` (39 columns):** flat schema, NJAW/customer old/new size+material+amount as separate columns (NOT a service_materials_grid jsonb). Measurements stored as `*_inches` smallint. Inspector-recognizable column names: `foreman_name` (not foreman), `temperature_f` (not temp_f), `sky_condition` (enum: sunny/cloudy/rain/snow/other), `curb_box_location` (enum: city_strip/sidewalk/driveway/lawn), `service_side` (enum: long/short).
- **`phase_submissions` (24 columns):** includes `materials_sheet_id` FK, `tapcard_data` jsonb, `njaw_work_order_code` enum (M2C/H2C/FULL/MP/TP/KILL).
- **23 firm_id indexes** across schema (memory had said 7).
- **Construction PM backend fully shipped:** `contractor_arrival_log`, `contractor_departure_log`, `contractor_assignments` — all RLS-locked, all firm_id indexed.
- **Restoration backend partial:** `restoration_grid_entries` exists, RLS-locked, sector enum CHECK present.
- **`legal_holds`, `destruction_notices`, `photo_rescue`, `supervisor_alerts`, `projects`** all exist + indexed + RLS-locked.
- **`phase` enum has 9 values** (test_pit, assessment, work_order, service_work, gis_docs, restoration, out_of_order, tapcard, no_work).
- **Sector enum lives on `properties`.** Values: NJ6_NORMAL, NJAW_SHORT_HILLS.
- **`parts_catalogs` has 16 NJ6_NORMAL rows.** ShortHills catalog still empty.
- **`inspections` table exists** (40 columns) — older surface or higher-level abstraction. Not in active v0.1 UI.
- **`audit_log` at 1101 rows.** ~50%+ heartbeat noise per MI-AUDIT-3 finding (last_client_sync_at). Approach A trigger filter is what CC's shipping tonight.

## Phase 2b tapcard form ground truth

The Phase 2b tapcard form is structured around **service installation + material identification**. CS depth, MP horn copper, distances etc. live on the materials sheet (Phase 2a backend shipped, frontend pending Unit 0 merge).

**Phase 2b inspector inputs (16 fields):** `tc-co-service_number`, `tc-co-task_numbers`, `tc-co-date`, `tc-co-tied_in`, `tc-co-plug_lock`, `tc-co-cust_mat`, `tc-co-size`, `tc-co-completed_by`, `tc-co-date_installed`, `tc-co-installed_by`, plus 6 customer-side fields (some readonly mirrors).

Full field map at `.coordination/PHASE2B_TAPCARD_FIELDS_REFERENCE.md`. Phase 2d-revision v2 work order has the full materials_sheets → visual tapcard map.

## Active investigations / side tracks

- **MI-AUDIT-3** — IN FLIGHT tonight (CC). Approach A: trigger filter for heartbeat-only UPDATEs. Whitelist starts with `last_client_sync_at`.
- **`compliance_events` id continuity** — closed Saturday.
- **3 reference images** for MI-100 vision parsing — Jorge to provide. Still blocked.
- **Whiteboard sample photos** for false-positive prompt tuning — Jorge to provide. Still blocked.
- **Isolated test tenant** for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 isolated-tenant unlock.
- **Cloudflare Pages custom domain** for `serranogroup.org` — confirmed NXDOMAIN tonight, DNS still not wired post-propagation. Retry needed.

## Capital deployed in Serrano Group LLC

- LLC formation + EIN: ~$200–370
- MacBook Air M4 Pro: ~$1,000–1,400 (Section 179 eligible)
- Asus laptop (primary dev): pre-existing
- Claude Max 20x plan: $200 (5/2)
- Cloudflare Registrar: $7.50 first year, $10.13/yr renewal
- NJ State Bar lawyer: ~$300 budgeted
- USPTO trademark filings: ~$1,400 budgeted (~4 marks × $350)

**Total deployed YTD: ~$1,508–2,508, largely tax-deductible.**

## Calendar context

- **Founded:** April 20, 2026, 4:20 PM EDT (16 days in as of 5/5 evening).
- **Jeff demo:** Thursday 5/14 or Friday 5/15 (9-10 days out).
- **Lawyer outreach:** in flight via warm intro (PI attorney → IP attorney; Wilentz Goldman Spitzer or McCarter & English / Friscia).

---

## Buddy banked discipline (lessons)

1. **Read full files** when verifying state. No `head: 100` / `tail: 50` truncations on `decisions.md`, `status.md`, `STATE.md`, or any file under `.coordination/`. (5/5 mistake: missed Q-7 resolution and 3 Sunday files via truncated reads.)

2. **Read actual UI source before drafting any frontend brief.** (5/5 mistake: Phase 2d brief used NJAW workflow vocabulary not Phase 2b form fields.)

3. **Verify branch merge state via git/Filesystem MCP before referencing any branch as merged.** (5/5 mistake: Phase 2d-revision v1 work order assumed Phase 2a frontend was on main when it lives on an unmerged branch. CC caught.)

4. **Verify schema columns via Supabase MCP `list_tables` before writing any field-to-column map.** (5/5 mistake: v1 work order referenced 8 properties columns that don't exist. CC caught + Buddy verified post-catch.)

5. **Long instructions → file, not chat paste.** Work orders or briefs over ~200 words go to disk; chat handoff is three sentences. (5/5 mistake: 1,200-word CC prompts truncated mid-word — CC saw "ush hash" and "f spec".)

6. **Honest reads about who can do what.** Buddy CAN reach Filesystem MCP, Supabase MCP, Vercel MCP, Cloudflare MCP, Gmail MCP, image_search, web_search, web_fetch. Buddy CANNOT directly run `git` commands or browse arbitrary URLs without prior fetch results. Some "queue items" require Lead/Jorge action — but most schema/file/deployment verification is in-reach for Buddy via the MCPs already loaded. **Use them BEFORE drafting, not after CC catches the mistake.**

The pattern across all 5 lessons is the same: **verify ground truth before writing any output that depends on the truth.** Tools exist. Use them.
