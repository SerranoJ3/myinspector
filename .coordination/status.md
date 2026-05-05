# Coordination Status — MyInspector

**Last updated:** 2026-05-05 evening EDT (Phase 2d ship)
**Updated by:** Lead (Claude Code CLI) — MI-101 Phase 2d Visual Tapcard Preview shipped on `demo-banner`

---

## Current state

**Active branch:** `demo-banner` — HEAD `91f2af4` after tonight's session-close commit; **Phase 2d feature commit pending** (about to land on top).

**Local main is 1 behind `origin/main`.** Missing commit is `4d70901` (Phase 2b refactor squash merge, Sun 0:52). Run `git fetch && git checkout main && git pull` to catch up before any new branch off main.

**`demo-banner` ahead of local main:** 6 commits (after Phase 2d commit lands: 7).
- `91f2af4` session-close 2026-05-05: STATE+status reconcile + Phase 2c lean scaffold
- `52d79c6` docs: Phase 2b real-shape verified + MI-AUDIT-3 filed
- `2c81a9d` docs(.coordination): Sunday evening batch — MI-AUDIT-1 + project seed + Q-7/2c-c/302-b/302-c/110-b ratifications
- `dcd977c` docs(.coordination): Sunday verification + spec drafts + security audit
- `685f4c1` feat(demo): demo login button + body-level banner + Lead-side string scrub
- `64df4f2` feat(demo-mode): banner visible iff firm_safe_to_display=true

**Tonight's two commits, in order:**
1. `91f2af4` — session-close (STATE refresh + status.md reconcile + Phase 2c lean scaffold)
2. (next) — Phase 2d Visual Tapcard Preview feature commit

**Uncommitted on `demo-banner` (about to be committed as Phase 2d feature):**
- `index.html` — MI-101 Phase 2d build:
  - CSS: `.tc-mid` flex wrapper + `.vtc-svg` + `.vtc-mobile-tabs` + breakpoint stack (≥1024 60/40, ≥768 55/45, <768 sub-tab toggle) + `.vtc-disabled` for non-NJ6_NORMAL.
  - HTML: `#modal-tapcard` body restructured — `.vtc-mobile-tabs` strip + `.tc-mid` wraps `.tc-body` and the preview container side-by-side on ≥768px viewports.
  - JS: `VTC_FIELDS` config (24 entries, mapping Phase 2b's actual `tc-co-*` / `tc-cu-*` field IDs to normalized 0–1 SVG positions per brief regions), `vtcRender` (sector-dispatched, monospace per Q-2d-a, gray underlines for empty per Q-2d-c), `vtcDebouncedRender` (100ms input debounce per brief), delegated input/change listeners on `#modal-tapcard` root, mobile sub-tab toggle, `vtcInitOnOpen` hook in `openTapcardForProperty`, `vtcReset` hook in `closeTapcardModal`, `currentTapcard.property = prop` stash for the address/lot_block reads.
  - **Zero migrations, zero new columns, zero schema changes.** Pure presentational layer over Phase 2b state.
- `.coordination/status.md` — this file.

**Untracked (uncommitted, untracked) files of note:** unchanged from previous status — 4 spec briefs, dashboard.html, 4 test directories, 2 discovery files, .claude/ directory.

## Phase 2d acceptance status

| # | Criterion | Status |
|---|---|---|
| 1 | Visual tapcard renders for NJ6_NORMAL only; ShortHills hides Phase 2d UI | ✅ shipped — `vtcRender` sector dispatch + `.vtc-disabled` modal class |
| 2 | All form fields autopopulate as values change with debounce/immediate semantics | ✅ shipped — delegated `input` listener (100ms debounce) + `change` listener (immediate); 24 fields wired |
| 3 | Empty fields render as gray underlines | ✅ shipped — Q-2d-c default; underline width per-field, scaled to expected value width |
| 4 | Layout responds at desktop (≥1024px), tablet (768–1023px), mobile (<768px) breakpoints; mobile sub-tab toggle | ✅ shipped — 3 media queries + `data-mobile-view` attribute toggle |
| 5 | No regression on Phase 2b form behavior | ⚠️ **needs Vercel preview verification by Jorge/Buddy** — Lead's environment has no dev server + Supabase creds wired; pure-presentational change reduces risk but doesn't eliminate it |

## Open PRs / branches awaiting action

| Branch | HEAD | Status | Notes |
|---|---|---|---|
| `mi101-phase2a` | `a542d5a` | Closed (merged Sat) | — |
| `mi203-step2` | `6abe03c` | Closed (merged Sat as `001af69`) | — |
| `mi101-phase2b` | `ff5bd2e` | Closed (merged Sat as `f51c61f` #6); superseded by refactor | — |
| `mi101-phase2b-refactor` | `b74298d` | Closed (merged Sun 0:52 as `4d70901`) | — |
| `njaw-selector` | `87173f0` | Closed unmerged (conflict casualty) | Replaced by v2 |
| `njaw-selector-v2` | `ab0fa55` | Pushed to origin, PR status unverified | Jorge to confirm GitHub branches page; if PR open and Vercel preview clean, merge |
| `mi100-frontend` | `7cdfee1` | Closed (merged Sat as `0327abd` #5) | — |
| `mi108-frontend` | `e7231bd` | Closed (merged Sat as `8a971eb` #4) | — |
| `mi-109-cs-auth-gate` | `204e025` | Closed (merged Fri 5/2 as `e76fac2` PR #3) | — |
| `demo-banner` | (Phase 2d commit pending) | **Active — 7 ahead of local main after Phase 2d lands** | Holds Track 2 sanitized demo work + Sunday docs commits + tonight's session-close + Phase 2d feature. PR not opened yet. |

## Recently closed (chronological since 5/2 evening)

- **Sat 5/2 evening:** 4 prod migrations via Supabase MCP; 3 PR squash-merges to main.
- **Sun 5/3 0:52:** `mi101-phase2b-refactor` merged as `4d70901`.
- **Sun 5/3 ~08:55:** MI-203 step 3 shipped via MCP migration `mi203_step3_drop_firms_read_anon`.
- **Sun 5/3 ~12:30:** `serranogroup.org` registered + Email Routing live + marketing site on Cloudflare Pages.
- **Sun 5/3 PM:** Full prod verification (8 surfaces GREEN); multi-tenant + SECURITY DEFINER audit (1 finding → MI-AUDIT-1); 3 spec briefs drafted; BB-001 parked.
- **Sun 5/3 ~17:35:** MI-AUDIT-1 fix shipped; CP Engineers default project seeded; 6 Q ratifications.
- **Sun 5/3 ~17:50:** Phase 2b real-shape verified GREEN (Jorge live submission); MI-AUDIT-3 filed.
- **Mon 5/5 evening (commit `91f2af4`):** STATE.md 3-day reconciliation, Phase 2c lean scaffold (Property Detail tabs Overview/Restoration/ShortHills + visual-tapcard-preview-container scaffold), status.md full reconciliation.
- **Mon 5/5 evening (Phase 2d commit, pending):** MI-101 Phase 2d Visual Tapcard Preview shipped — read-only SVG mirror of `#modal-tapcard` form state. Renders for NJ6_NORMAL only (sector dispatch in `vtcRender`). Side-by-side responsive layout (60/40, 55/45, mobile sub-tab toggle). Q-2d-a/b/c ratified via Buddy defaults during build:
  - **Q-2d-a (font):** monospace (`'JetBrains Mono'`, fallbacks `ui-monospace, Consolas, monospace`).
  - **Q-2d-b (print-to-PDF):** deferred to v2; not implemented in this commit.
  - **Q-2d-c (empty-state):** thin gray underline (`#cfd6df`, 1px) at field anchor.

## Open questions (in `questions.md`)

- **Q-2 / Q-7 / Q-2c-c / Q-302-b / Q-302-c / Q-110-b** — answered Sun 5/3.
- **Q-2c-d / Q-2c-e** — deferred until first ShortHills property/parts data lands on prod.
- **Q-110-a (Phase 4 asset type enum scope)** — open; not blocking near-term.
- **Q-2d-a / Q-2d-b / Q-2d-c** — ratified tonight via Buddy defaults during Phase 2d build (locked in commit message + this status doc).
- **Q-2d "Visual tapcard placement"** (NEW) — Brief was drafted assuming "Tapcard tab on Property Detail modal." Tonight's Option B + Phase 2d build placed the visual inside `#modal-tapcard` (the dedicated tapcard modal) instead. **Buddy: refresh `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md` to match the as-built location** before another contributor reads the brief and gets confused.

## Blockers

- 3 reference images for MI-100 vision parsing — Jorge to provide.
- Whiteboard sample photos for false-positive prompt tuning — Jorge to provide.
- Isolated test tenant for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 isolated-tenant unlock.
- `njaw-selector-v2` push status — Jorge to verify GitHub branches page.
- ShortHills property + parts catalog data — gates Phase 2c-form ShortHills surfaces (placeholder remains fine without it).
- **Phase 2d Acceptance #5 (no regression) — needs browser verification on Vercel preview.** Lead's environment has no dev server + Supabase creds wired; pure-presentational change reduces risk but doesn't prove it.

## Next move

1. **Lead (now):** commit Phase 2d feature on `demo-banner` (`index.html` + this `status.md`), separate from `91f2af4`. Hold the push by default unless Jorge says push.
2. **Jorge:** spin Vercel preview on `demo-banner` and verify Phase 2d acceptance criteria 1–5:
   - Open Tapcard modal on a NJ6_NORMAL property → visual preview renders side-by-side on desktop; live-updates as form values change; empty fields show gray underlines.
   - Open Tapcard modal on a NJAW_SHORT_HILLS property → preview hidden, mobile tab strip hidden, form renders full-width.
   - Resize browser through breakpoints (mobile / tablet / desktop) → layout shifts at 768 and 1024.
   - Submit a tapcard end-to-end → confirm Phase 2b submit/save/edit/restore flow unchanged.
3. **Lead:** pull origin/main into local main (1 commit behind — `4d70901` Phase 2b refactor merge).
4. **Lead next session:** MI-101 Phase 2c-form pickup (Restoration form — 5 acceptance criteria, photo upload, sector dispatch, whiteboard requirement, Save Draft button per Q-7=C).
5. **Buddy:** refresh `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md` to match as-built location (`#modal-tapcard` not Property Detail Tapcard tab); also refresh field-to-position table to use Phase 2b's actual `tc-co-*` / `tc-cu-*` IDs.
6. **Jorge:** verify `njaw-selector-v2` PR on GitHub; if green, merge.
7. **Lead/Buddy queue:** MI-AUDIT-3 fix (audit_log heartbeat noise) — design before patch; survey other heartbeat-not-state fields first.

## Active investigations / side tracks

- **MI-AUDIT-3** filed Sun 5/3 ~17:50. P2. `last_client_sync_at` UPDATE writes are firing audit triggers — ~50%+ of current 288/24h baseline is heartbeat noise. Design before patch.
- **23 firm_id indexes** across schema (memory said 7) — banked into STATE.md schema-state-surprises section. No action.
- **`inspections` table** exists with firm_id + RLS. Not in active v0.1 UI. Worth row-count + column-shape check next audit cycle.
- **Cloudflare Pages custom domain** for `serranogroup.org` — wiring failed first attempts on Sun 5/3 ~14:00; retry queued post-propagation.
- **Phase 2d field map drift risk** — `VTC_FIELDS` array in `index.html` mirrors Phase 2b's current form. When Phase 2b's form gains/renames fields, `VTC_FIELDS` must be updated in lockstep. Comment block above `VTC_FIELDS` documents this. No automated guard.
- **3 Buddy docs commits on `demo-banner` only** (`52d79c6`, `2c81a9d`, `dcd977c`) — should land on main when demo-banner merges OR be cherry-picked beforehand, otherwise main lacks the Sunday verification + audit + ratification record.

## Pointers

- **Authoritative state:** `STATE.md` (refreshed in `91f2af4`) > this file. `CLAUDE.md` > `decisions.md` for principles.
- **Buddy bootstrap digest:** `.coordination/buddy_context.md` — last refreshed Sun 5/3 ~13:00. Phase enum count says 8; STATE.md says 9. Refresh at next session boundary.
- **Verification report:** `.coordination/SUNDAY_VERIFICATION_5-3-26.md`.
- **Security audit:** `.coordination/SUNDAY_SECURITY_AUDIT_5-3-26.md`.
- **Decisions log:** `.coordination/decisions.md` — Sunday batch + restoration note are the freshest entries; Phase 2d Q-2d-a/b/c ratifications are captured in tonight's commit messages, not yet logged in decisions.md (Buddy's queue).
- **Spec briefs:** `MI101_PHASE2C_BRIEF.md` (revised tonight to lean scaffold; restoration form deferred to Phase 2c-form pickup), `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md` (needs Buddy refresh — see Q-2d "Visual tapcard placement" above), `MI110_PHASE4_BRIEF.md`, `MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`.
