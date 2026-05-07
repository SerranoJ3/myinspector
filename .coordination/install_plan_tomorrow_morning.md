# Tomorrow Morning — Plugin & Skill Install Plan

**Authored:** 2026-05-05 ~23:55 EDT (end-of-night handoff)
**Updated:** ~23:58 EDT (cleaner install paths after Jorge clarified can't paste 5 commands in 1 prompt)
**For:** Jorge — first 5 min of tomorrow's CC session
**Goal:** install the high-leverage plugins, skip the noise, get back to shipping

---

## Plugin install — three ways, pick one

### Option A — `/plugin` browser (recommended, ~3 min)

In CC, type:

```
/plugin
```

The browser UI opens (you already know this from tonight). Tab to **Discover**. For each of these 5 plugins:

1. Type the name in the search field
2. Hit **Space** to toggle install
3. Hit **Enter** to confirm

Install all 5 in this single browser session:

- `commit-commands`
- `code-review`
- `pr-review-toolkit`
- `superpowers`
- `feature-dev`

After all 5 toggle, hit **Esc** to close. Then `/exit` and start fresh CC session — plugins activate on next session start.

### Option B — One slash command at a time (~5 min)

Each line is its own separate command. Type, hit enter, wait for "installed" confirmation, then type next. Cannot paste all 5 in one prompt.

```
/plugin install commit-commands@claude-plugins-official
```

(wait for confirmation, then)

```
/plugin install code-review@claude-plugins-official
```

(wait, then)

```
/plugin install pr-review-toolkit@claude-plugins-official
```

(wait, then)

```
/plugin install superpowers@claude-plugins-official
```

(wait, then)

```
/plugin install feature-dev@claude-plugins-official
```

Then `/exit` and start fresh CC session.

### Option C — Web UI at claude.com/plugins (~3 min)

Open `https://claude.com/plugins` in your browser, sign in with your Anthropic account, search each plugin name, click Install. Syncs to CC on next session start.

---

## Tier 1 — what you're installing and why

`commit-commands` — git workflow skills baked in. Would have caught the Phase 2a "merged" drift earlier tonight by verifying branch state before referencing as merged.

`code-review` — automated multi-agent PR review with confidence-based scoring. Catches issues before merge. Useful for every `demo-banner` → main merge going forward.

`pr-review-toolkit` — specialized review agents (comments, tests, error handling, type design, code quality, simplification). Layers on top of code-review for deeper passes.

## Tier 2 — what you're installing and why

`superpowers` (Jesse Vincent, 579K+ installs, officially accepted to Anthropic's marketplace 1/15/26) — comprehensive workflow framework. Adds slash commands:

- `/brainstorm` — Socratic spec elicitation before any code is written
- `/write-plan` — implementation plan from the spec
- `/execute-plan` — subagent-driven execution with code review checkpoints
- Enforces TDD red-green-refactor cycles
- Four-phase debugging methodology

**Honest caveat:** Superpowers is opinionated about TDD with test-first discipline. MyInspector is currently vanilla HTML/JS with no test framework. You can use Superpowers selectively — `/brainstorm` and `/write-plan` are pure wins for next-feature design, but the TDD enforcement might fight your current codebase. Use the workflow commands without forcing TDD on every change. If it gets in the way, uninstall — fully reversible.

`feature-dev` — codebase exploration agent + architecture design agent + quality review agent. Useful for the upcoming MI-401/402/403/404 ticket pickups where each one needs codebase context before drafting implementation.

---

## Tier 3 — install later, NOT tomorrow

When the relevant time comes:

`security-guidance` — install before next audit-chain ticket (MI-AUDIT-2 if it ever activates, or when adding new RLS-locked tables for Module 2 Wastewater).

`context7` (Upstash, 299K installs) — live docs lookup MCP. Pulls version-specific docs from Supabase, Vercel, Anthropic API into Claude's context. Wait until you hit a "Claude is using outdated API syntax" moment, then install.

---

## Skip (do NOT install tomorrow or ever)

- `code-simplifier` — solves a problem you don't have
- Random community plugins from the 340+ in third-party marketplaces — noisy, unverified, security risk
- `claude-opus-4-5-migration` — irrelevant, you're on 4.7

---

## Skills already in place (auto-loaded by CC tomorrow)

These are in `.claude/skills/` already:

- `verify-ground-truth-before-drafting/SKILL.md` — checklist forcing git/schema/deployment verification before drafting any work order
- `serrano-group-brand/SKILL.md` — locked palette, voice, sanitization rules (no CP/NJAW/Montana refs in public)
- `myinspector-domain-rules/SKILL.md` — 9 phase enums, 6 NJAW work order codes, CDM-Smith rules, ShortHills role inversion, whiteboard requirement matrix

CC auto-discovers all three on next session start. No action needed.

---

## After plugins load — your real first move

Open fresh CC session in repo. Three-sentence handoff to CC:

> Read `.coordination/work_order_2026-05-05_phase2d_revision_v2.md` and execute Unit 1 Step 2 + Unit 2. Buddy has batch trust. Stop only on conditions in the file.

That kicks off Phase 2d-revision Step 2 (sub-steps C-G: embed visual-tapcard-preview container in `modal-materials-sheet`, rewrite `VTC_FIELDS` against materials_sheets schema, rewrite `vtcRender` for paper-true NJAW Service Line Renewal layout, sector dispatch). Then Unit 2: autopop wiring + Materials Installed extrapolation.

Estimated runway: 60-90 min focused build for Step 2, ~1 session for Unit 2.

---

## Bring me up to speed (Buddy chat)

Open Buddy chat fresh and say:

> Read .coordination/skills then read STATE.md, the v2 work order, and the velocity analytics. Bring me up to speed.

I'll auto-discover the 3 custom skills, pick up the trajectory, and we continue exactly where we left off. No re-explanation needed.

---

## Bottom line

3-5 min of plugin installs tomorrow morning depending on which option you pick. Then restart CC. Three-sentence handoff. Phase 2d-revision Step 2 ships before lunch.

Velocity stays locked. Demo trajectory stays locked. Bring it home.
