# Future-proofing Buddy + CC for Serrano Group operations

**Authored:** 2026-05-05 ~22:50 EDT
**By:** Buddy
**Audience:** Jorge — review, decide, install
**Status:** Action list, not recommendations

---

## Tonight's failure patterns (the actual reason this list exists)

1. **Documentation drift** — STATE.md / status.md / buddy_context.md / decisions.md asserted Phase 2a frontend merged when it lived on an unmerged branch. CC caught via git verification.
2. **Schema drift** — v1 work order referenced 8 `properties` columns that don't exist. CC caught, Buddy verified post-catch via Supabase MCP.
3. **Truncated reads** — `head:100` / `tail:50` caused 3 misses (Sunday docs, Q-7 resolution, Phase 2b form fields).
4. **Chat paste truncation** — 1200-word CC prompts truncated mid-word. File-channel rule already locked.
5. **MCP capability mismatch** — CC blocked on Supabase MCP read-only while Buddy had `apply_migration` write access. ~45 min wasted.
6. **Visual demo flat** — couldn't deliver real interactive 3D Three.js demo in chat for serranogroup.org constellation evaluation.

Five of these are tool-fixable with what's already free in the Anthropic ecosystem. One (#3) is pure discipline.

---

## Recommendation 1 — install these CC plugins next session

**Source:** github.com/anthropics/claude-plugins-official (auto-available in CC). To browse: `/plugin` → Discover tab. To install: `/plugin install <name>@claude-plugins-official`.

| Plugin | What it does | Failure pattern it addresses |
|---|---|---|
| **`commit-commands`** | Git workflow skills baked in | Pattern #1 — CC can verify branch state automatically before referencing as merged |
| **`code-review`** | Automated PR review with multiple specialized agents, confidence-based scoring | Pattern #1, #2 — catches drift before merge |
| **`pr-review-toolkit`** | Specialized PR review agents (comments, tests, error handling, type design, code quality, simplification) | Phase 2a → main merge coming next session — would catch Phase 2b refactor conflicts cleanly |
| **`feature-dev`** | Feature dev workflow: codebase exploration agent + architecture design agent + quality review agent | Future ticket pickups (MI-401/402/403/404 + Phase 2c-form) |
| **`security-guidance`** | Security review agent | Audit chain trigger work, RLS verification, anything touching auth/permissions |
| **`hookify`** | Create custom hooks to enforce conversation patterns | Could lock in BUDDY_STANDARD rules as actual hooks rather than instructions |

Install command for CC next session, copy-paste:

```
/plugin install commit-commands@claude-plugins-official
/plugin install code-review@claude-plugins-official
/plugin install pr-review-toolkit@claude-plugins-official
/plugin install feature-dev@claude-plugins-official
/plugin install security-guidance@claude-plugins-official
```

Estimated runway: ~10 min to install all five + verify.

---

## Recommendation 2 — official Anthropic skills worth pulling

**Source:** github.com/anthropics/skills

Already loaded in current Buddy environment (no action needed):
- `docx`, `pdf`, `pptx`, `xlsx`, `pdf-reading`, `file-reading` — document handling
- `frontend-design` — distinctive frontend with high design quality (would have helped on the constellation demo)
- `product-self-knowledge` — Anthropic product fact-checking

Available example skills already on Buddy's filesystem (`/mnt/skills/examples/`):
- `skill-creator` — for creating custom skills (META — Buddy can use this to lock in tonight's discipline lessons as auto-triggering skills)
- `mcp-builder` — guide for creating MCP servers (relevant for SG-001 inter-agent comms when that unparks)
- `theme-factory` — themed artifacts (Serrano brand application)
- `internal-comms` — status reports, leadership updates, FAQs (could help with the "tell my dad about the company" type drafts)
- `canvas-design` — visual art in PNG/PDF (alternative path for serranogroup.org imagery)
- `web-artifacts-builder` — multi-component HTML artifacts with React/Tailwind/shadcn

Worth pulling into CC repo (`.claude/skills/`):
- `webapp-testing` — Playwright skill for local web app testing → MyInspector e2e tests, UI verification, regression catches
- `mcp-server` — for building custom MCP servers if SG-001 happens

Install path for CC: clone the skill folder into `.claude/skills/` in the myinspector repo (or `~/.claude/skills/` for user-scope across all projects).

---

## Recommendation 3 — custom skills Buddy should write tonight

These directly address tonight's failure patterns. Each is a `SKILL.md` + supporting files. Once written to disk, future Buddy and CC sessions auto-load them.

### Skill A — `verify-ground-truth-before-drafting`

**Trigger:** Before drafting any work order, brief, or schema/field map.

**Does:** Forces a checklist:
1. Read main branch source code (index.html, schema files) before referencing surfaces or columns
2. Run `Supabase:list_tables` (verbose) for any schema field references
3. Check git branch state for any "merged" claims
4. Verify deployment state via Vercel MCP for any "live" claims

**Prevents:** Patterns #1, #2 from tonight.

### Skill B — `serrano-group-brand`

**Trigger:** Any output for serranogroup.org, MyInspector marketing, BidGrid marketing, TIA / FORGE marketing, public-facing copy.

**Does:**
- Locks brand palette: navy `#0D1F3C`, gold `#C9A84C`, cream `#F5F2EC`
- Locks voice: direct, no buzzwords, specific over abstract, "architect not employer" framing
- Sanitization rules: no CP Engineers / NJAW / Montana Construction / Conquest Construction / Justin Esteves / Tyler Suess / Hackensack / Bergen County references in public outputs
- Product brand standards: MyInspector navy/gold, BidGrid green, TIA warm health, FORGE matte black
- Locked phrases: "architect, not employer", "named AI crew", "16 days from incorporation to live SaaS", "operator on the ground"

**Prevents:** Sanitization slips, brand drift, off-voice copy.

### Skill C — `myinspector-domain-rules`

**Trigger:** Any MyInspector ticket touching field workflows, sector dispatch, NJAW rules, CDM-Smith rules, parts catalog, work order codes.

**Does:** Encodes locked field rules:
- 8 phase enum values (test_pit, assessment, work_order, service_work, gis_docs, restoration, out_of_order, tapcard, no_work)
- 6 NJAW work order codes (M2C, H2C, FULL, MP, TP, KILL)
- KILL subtypes (ABANDON, RELOCATE_FULL, RELOCATE_STREET)
- 4 NJAW work classification codes (LSL-R, PLSL-R, GV-R, INS)
- Sector dispatch (NJ6_NORMAL vs NJAW_SHORT_HILLS)
- ShortHills role inversion (inspector dictates means/methods + interacts with homeowner direct)
- Whiteboard rules (open excavation = required; tapcard / triangulation / GIS docs / blueprints / backlog = not required)
- CDM-Smith rules a/b/c/d/e (no-work + existing MP + Carlo CS auth + MP horn copper + CS-to-house only)
- Maplewood rule (customer in-spec = street-only relocate)
- Inspector-doesn't-do-extra-work principle (infer state from actions)
- Inspector GPS tracking principle (firm-level setting, default OFF for Serrano)
- Construction PM GPS tracks contractors (Montana / Conquest), NOT inspectors

**Prevents:** Domain rule drift, redundant clarifications, errors when CC drafts new tickets.

### Skill D — `mcp-capability-map`

**Trigger:** Anytime Buddy or CC plans a database write, file modification, or external service action.

**Does:** Documents which agent has which MCP capability:
- Buddy chat: full Supabase MCP (read + apply_migration write), Filesystem MCP (read + write to user dirs), Cloudflare MCP, Vercel MCP, Gmail MCP, ClickUp MCP, web_search, web_fetch, image_search
- Buddy chat: CANNOT directly run git commands, CANNOT browse arbitrary URLs without prior fetch
- CC terminal: bash, git, npm, file edit, Supabase MCP (varies — sometimes read-only mode)
- When CC hits a write block, escalate to Buddy who likely has write access

**Prevents:** Pattern #5 from tonight (~45 min of CC circling on read-only).

---

## Recommendation 4 — additional MCPs to connect

Already connected: Supabase, Cloudflare, ClickUp, Gmail, Vercel.

Worth considering:

| MCP | Source | Why |
|---|---|---|
| **GitHub MCP** | github.com/github/github-mcp-server | Direct repo search, issue management, PR creation. CC and Buddy could check branch state without git CLI. |
| **Postgres MCP** | community (multiple options on github) | Postgres-specific code generation, query optimization, plan analysis. Supplement to Supabase MCP. |
| **Filesystem MCP (user-machine path)** | Already connected | But Buddy should be more aggressive about using it instead of asking Jorge or assuming |
| **Notion / Obsidian MCP** | Various | Could centralize cross-product memory if Jorge wants a knowledge base. Currently userMemories is Anthropic-side; user-controlled note-taking would be different surface. |
| **Stripe MCP** | github.com/stripe/agent-toolkit | When BidGrid / TIA / FORGE need payment processing |
| **Cloudflare R2 / Workers** | Already connected via Cloudflare | Underutilized — could host Serrano brand assets, web fonts, image CDN |

---

## Recommendation 5 — community marketplaces worth knowing about (verify before installing)

**aitmpl.com** — 340+ plugins, 1367 agent skills for Claude Code. Open-source CCPI package manager. Some standout collections:
- Multi-agent code review pipelines
- Notification plugins (ntfy, slack, telegram for build events)
- Context capture plugins (preserve session state across compactions)

**superpowers (Jesse Vincent)** — comprehensive community skills with `/brainstorm`, `/write-plan`, `/execute-plan` commands. Used as a development-loop layer.

**OpenSkills** — npm-installable skill manager. `npx openskills install anthropics/skills` etc.

**Caveat:** Anthropic explicitly recommends only using skills from trusted sources because skills execute arbitrary code. Verify any community skill source before installation.

---

## What this list does NOT solve

- **Discipline lapses** (tonight's pattern #3 — truncated reads). Tools don't fix discipline. Banked in `BUDDY_STANDARD` and reinforced through every catch. The `verify-ground-truth-before-drafting` skill helps, but only if Buddy actually consults it.
- **Brand sanitization risk** in private chats. Skill B helps for marketing outputs but doesn't enforce in casual conversation.
- **Velocity vs craft tradeoffs.** Plugins and skills add capability but also context overhead. Be selective — installing 50 plugins doesn't make CC faster.

---

## Recommended install order (priority-ranked)

### Tonight (after CC closes MI-AUDIT-3)

1. None. Don't disrupt CC's flow tonight. End the session clean.

### Next session (start of day)

1. CC installs `commit-commands` first (~2 min) — would already have caught the Phase 2a drift before tonight's stop-and-ping
2. CC installs `code-review` (~2 min) — useful for the Phase 2a → main merge coming up
3. Buddy writes Skill A (`verify-ground-truth-before-drafting`) to `.coordination/skills/` (~10 min Buddy work, but reduces future pattern #1/#2 mistakes)

### Within 1 week

4. Buddy writes Skill B (`serrano-group-brand`) — enables consistent marketing voice across all four products
5. Buddy writes Skill C (`myinspector-domain-rules`) — locks 8 enum values + 6 work order codes + sector rules
6. CC installs `pr-review-toolkit`, `feature-dev`, `security-guidance`
7. Connect GitHub MCP (claude.ai web)

### When relevant

8. `webapp-testing` skill into CC repo when MyInspector e2e testing comes up
9. `mcp-server` skill if SG-001 inter-agent comms unparks
10. Postgres MCP if Supabase MCP feels limited

---

## End-of-document call-to-action

The five plugins listed in Recommendation 1 plus the three custom skills in Recommendation 3 cover roughly 80% of tonight's failure surface. None of them cost money. Install order matters less than not procrastinating on installation.

Buddy can write Skills A, B, C any time — they're just markdown files. Just say go.
