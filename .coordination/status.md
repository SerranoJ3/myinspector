# Coordination Status — MyInspector

**Last updated:** 2026-05-05 evening EDT
**Updated by:** Lead (Claude Code CLI) — 3-day reconciliation against Saturday merges + Sunday verification/audit/ship + tonight's Phase 2c lean scaffold

---

## Current state

**Active branch:** `demo-banner` — HEAD `52d79c6` (Buddy: "docs: Phase 2b real-shape verified + MI-AUDIT-3 filed", Sun 5/3 ~17:50). Tracks `origin/demo-banner` (in sync, no unpushed commits).

**Local main is 1 behind `origin/main`.** Missing commit is `4d70901` (Phase 2b refactor squash merge, Sun 0:52). Run `git fetch && git checkout main && git pull` to catch up before any new branch off main.

**`demo-banner` is 5 commits ahead of local main** (3 Buddy docs commits + 2 demo banner feature commits, in order):
- `52d79c6` docs: Phase 2b real-shape verified + MI-AUDIT-3 filed
- `2c81a9d` docs(.coordination): Sunday evening batch — MI-AUDIT-1 + project seed + Q-7/2c-c/302-b/302-c/110-b ratifications
- `dcd977c` docs(.coordination): Sunday verification + spec drafts + security audit
- `685f4c1` feat(demo): demo login button + body-level banner + Lead-side string scrub
- `64df4f2` feat(demo-mode): banner visible iff firm_safe_to_display=true

**Uncommitted on `demo-banner` (tonight 5/5):**
- `STATE.md` — full 3-day reconciliation refresh (3-day stale → current truth as of tonight)
- `index.html` — MI-101 Phase 2c lean scaffold: `.pd-tabs` CSS + `#modal-property-detail` rebuilt with Overview/Restoration/ShortHills tabs + empty `<div id="visual-tapcard-preview-container">` in `#modal-tapcard` + `pdSwitchTab(tab)` JS + `pdSwitchTab('overview')` reset on `openPropertyDetail`. No migrations, no new columns, no autopopulation logic.

**Untracked (uncommitted, untracked) files of note:**
- 4 spec briefs that should land on main: `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md` (Buddy in flight), `MI101_PHASE2_FRONTEND_BRIEF.md`, `MI101_PHASE1A_BRIEF.md`, `MI203_STEP2_BRIEF.md`, `MI_COLUMN_FIX_BRIEF.md`, `SG001_BRIEF.md`
- `dashboard.html` (Buddy verification confirmed prod-ready 5/2 PM; needs add-and-commit)
- 4 test directories: `tests/compliance_reporting/`, `tests/construction_pm/`, `tests/legal_holds/`, `tests/mi101/`
- 2 discovery files: `discovery/TAPCARD_CLUSTER_SPEC.md`, `discovery/TAPCARD_VISUAL_REFERENCE.md`
- `.claude/` directory (local agent state — should remain untracked; verify `.gitignore`)

## Open PRs / branches awaiting action

| Branch | HEAD | Status | Notes |
|---|---|---|---|
| `mi101-phase2a` | `a542d5a` | Merged Sat (Materials Sheet UI + polish) | Closed |
| `mi203-step2` | `6abe03c` | Merged Sat as `001af69` | Closed |
| `mi101-phase2b` | `ff5bd2e` | Merged Sat as `f51c61f` (#6) | Closed; superseded by refactor on Sun |
| `mi101-phase2b-refactor` | `b74298d` | Merged Sun 0:52 as `4d70901` | Closed (refactor: kill Customer Side tab + expand Materials view + role-gated Office Fill) |
| `njaw-selector` | `87173f0` | Closed unmerged (conflict casualty) | Replaced by v2 |
| `njaw-selector-v2` | `ab0fa55` | Pushed to origin, PR status unverified | Jorge to confirm GitHub branches page; if PR open and Vercel preview clean, merge |
| `mi100-frontend` | `7cdfee1` | Merged Sat as `0327abd` (#5) | Closed |
| `mi108-frontend` | `e7231bd` | Merged Sat as `8a971eb` (#4) | Closed |
| `mi-109-cs-auth-gate` | `204e025` | Merged Fri 5/2 as `e76fac2` (PR #3) | Closed |
| `demo-banner` | `52d79c6` | **Active — tonight's work lives here** | Track 2 sanitized demo work + Sunday docs + tonight's Phase 2c scaffold. PR not opened yet. |

## Recently closed (chronological since last status refresh on 5/2)

- **Sat 5/2 evening:** 4 prod migrations via Supabase MCP (`parts_catalogs_placeholder_seed`, `demo_inspector_binding`, `cs_replacement_auth_immutability_revoke_service_role`, `mi204b_firm_id_indexes`). 3 PR squash-merges on main (`mi203-step2` → `001af69`, `mi101-phase2a` polish stack, `mi101-phase2b` original → `f51c61f`).
- **Sun 5/3 0:52:** `mi101-phase2b-refactor` PR squash-merged to main as `4d70901`. Tapcard cluster shipped to spec.
- **Sun 5/3 ~08:55:** MI-203 step 3 (drop `firms_read_anon` policy) shipped via Supabase MCP migration `mi203_step3_drop_firms_read_anon`. No main commit (migration log only). Anonymous firm-read attack surface fully closed.
- **Sun 5/3 ~12:30:** `serranogroup.org` registered at Cloudflare Registrar; Email Routing live (`jorge@serranogroup.org` → `jserranojr340@live.com`); marketing site deployed to Cloudflare Pages.
- **Sun 5/3 PM:** Full prod verification across 8 surfaces (`SUNDAY_VERIFICATION_5-3-26.md`) — all GREEN. Multi-tenant + SECURITY DEFINER audit (`SUNDAY_SECURITY_AUDIT_5-3-26.md`) — 1 finding (MI-AUDIT-1), 1 informational (MI-AUDIT-2). 3 spec briefs drafted: `MI101_PHASE2C_BRIEF.md`, `MI110_PHASE4_BRIEF.md`, `MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`. BB-001 (AR auto-fill tapcard) parked.
- **Sun 5/3 ~17:35:** MI-AUDIT-1 shipped via Supabase MCP migration `mi_audit_1_fix_get_pending_destruction` (v `20260503172732`). CP Engineers default project seeded via `seed_cp_engineers_default_project` (closes MI-302 frontend FK gate). 6 Q ratifications: Q-7=C (Save Draft sub-action), Q-2c-c (firm-visible homeowner contact log), Q-302-b (inline 40×40 thumbnails + lightbox), Q-302-c (50m GPS anomaly threshold), Q-110-b (read-only banner for pre-Phase-4 tapcards), Q-2c-d/e deferred.
- **Sun 5/3 ~17:50:** Phase 2b real-shape verified GREEN via Jorge live tapcard submission. MI-AUDIT-3 filed (audit_log heartbeat noise from `last_client_sync_at` writes — P2, design before patch).
- **Mon 5/5 evening (tonight):** STATE.md full 3-day reconciliation refresh. MI-101 Phase 2c lean scaffold shipped (5 in-file edits to index.html, no migrations). MI-AUDIT-1 ship task confirmed already-shipped (no-op). status.md full reconciliation (this file).

## Open questions (in `questions.md`)

- **Q-2** answered Sun 5/3 ~12:30 EDT.
- **Q-7** answered Sun 5/3 ~17:35 EDT — Option C locked.
- **Q-2c-c, Q-302-b, Q-302-c, Q-110-b** answered Sun 5/3 ~17:35 EDT.
- **Q-2c-d / Q-2c-e** deferred — no ShortHills properties/parts on prod yet; un-defer when first ShortHills property imports.
- **Q-110-a** open (Phase 4 asset type enum scope: 4 vs 9 types). Not blocking near-term; Jorge's call when Phase 4 build is closer (~week of 5/11+).
- **Q-2d-a / Q-2d-b / Q-2d-c** open (Phase 2d Visual Tapcard font / print-to-PDF / empty-state) — surfaces during Phase 2d brief ratification.

## Blockers

- 3 reference images for MI-100 vision parsing — Jorge to provide.
- Whiteboard sample photos for false-positive prompt tuning — Jorge to provide.
- Isolated test tenant for MI-109.5 manual e2e walk — gated on SG-001 Node 2/3 isolated-tenant unlock.
- `njaw-selector-v2` push status — Jorge to verify on GitHub branches page; if pushed → open PR + Vercel verify + merge.
- ShortHills property + parts catalog data — gates Phase 2c-form ShortHills surfaces (placeholder tab tonight is fine without it).

## Next move

1. **Lead (now):** commit tonight's work on `demo-banner` (STATE.md + index.html Phase 2c scaffold). Decide whether to open a PR for `demo-banner` against main or merge locally — depends on whether the demo banner feature is ready for v0.1 cut.
2. **Lead:** pull origin/main into local main (1 commit behind — Phase 2b refactor merge `4d70901`).
3. **Jorge:** verify `njaw-selector-v2` PR on GitHub; if green, merge to main.
4. **Jorge:** ratify Phase 2d brief (`MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md`) — answer Q-2d-a/b/c so Lead can pick up Phase 2d build.
5. **Lead next session:** MI-101 Phase 2c-form pickup (Restoration form — 5 acceptance criteria, photo upload, sector dispatch, whiteboard requirement, Save Draft button per Q-7=C).
6. **Buddy queue:** verify Phase 2c lean scaffold on Vercel preview when Lead opens demo-banner PR or merges to main; finalize Phase 2d brief ratification batch.
7. **Side-track Lead queue:** MI-AUDIT-3 fix (audit_log heartbeat noise) — design before patch; survey other heartbeat-not-state fields first; pick approach A (trigger filter) / B (separate heartbeat table) / C (client-side stop).

## Active investigations / side tracks

- **MI-AUDIT-3** filed Sun 5/3 ~17:50. P2. `last_client_sync_at` UPDATE writes are firing audit triggers — ~50%+ of current 288/24h baseline is heartbeat noise. Touches hot trigger plumbing — wants design, not a quick patch.
- **`compliance_events` id gap investigation** — closed Sat 5/2 ~14:15 EDT (rolled-back-tx sequence advance + `cleanup_build_test_data` self-log; not a chain breach).
- **23 firm_id indexes** across schema (memory had said 7) — banked into STATE.md schema-state-surprises section. No action.
- **`inspections` table** exists with firm_id + RLS. Not in active v0.1 UI. Worth row-count + column-shape check next audit cycle.
- **Cloudflare Pages custom domain** for `serranogroup.org` — wiring failed first attempts on Sun 5/3 ~14:00; retry queued post-propagation.
- **3 Buddy docs commits on `demo-banner`** (`52d79c6`, `2c81a9d`, `dcd977c`) — landed on demo-banner, not main. Should rebase onto main or cherry-pick when demo-banner merges, otherwise main lacks the Sunday verification + audit + ratification record.

## Pointers

- **Authoritative state:** `STATE.md` (refreshed tonight) > this file. `CLAUDE.md` > `decisions.md` for principles.
- **Buddy's bootstrap digest:** `.coordination/buddy_context.md` — last refreshed Sun 5/3 ~13:00. Phase enum count (says 8) is stale → STATE.md says 9. Refresh at next session boundary.
- **Verification report:** `.coordination/SUNDAY_VERIFICATION_5-3-26.md`.
- **Security audit:** `.coordination/SUNDAY_SECURITY_AUDIT_5-3-26.md`.
- **Decisions log:** `.coordination/decisions.md` (Sunday batch + restoration note are the freshest entries).
- **Spec briefs queued for ratification:** `MI101_PHASE2C_BRIEF.md` (revised tonight to lean scaffold path), `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md` (new tonight, Buddy in flight), `MI110_PHASE4_BRIEF.md`, `MI302_CONSTRUCTION_PM_FRONTEND_BRIEF.md`.
