# Sunday 5/3/26 — Day Plan (LIVE PROGRESS)

**Last updated:** 2026-05-03 ~10:15 EDT (Buddy mid-execution)
**Total estimated time:** ~6-8 hours across 5 parallel tracks
**Pattern:** Parallel — Lead handles Track 2 while Jorge handles Track 3, Buddy drafts Track 4, Track 5 slots in throughout

---

## ✅ Track 1 — Close Saturday's milestone — COMPLETE

- ✅ `mi101-phase2b-refactor` PR opened, Vercel verified, squash-merged at 0:52am as commit `4d70901`
- ✅ MI-203 step 3 (`DROP POLICY firms_read_anon`) shipped + verified at ~08:55am via Supabase MCP
- ✅ Schema integrity confirmed (16 parts_catalogs rows, 369 audit_log events 24h, 2 firms policies remaining)
- ⏳ `njaw-selector-v2` — Lead push status uncertain; Jorge to verify on GitHub branches page (~5 min)

## ⏳ Track 2 — Sanitized demo branch — AWAITING JORGE TO PASTE LEAD PROMPT

Lead prompt drafted + posted in Sunday morning chat. Jorge pastes into Code CLI when ready. Lead spins `myinspector-demo` branch off main, scrubs all CP/NJAW/CDM-Smith/Maplewood proprietary content, deploys to demo subdomain.

- ⬜ Jorge: paste prompt to Lead
- ⬜ Lead: build `myinspector-demo` branch
- ⬜ Lead: deploy to demo.myinspector.io (or demo-myinspector.vercel.app)
- ⬜ Buddy: post-deploy verification (no proprietary strings leaked)

## ⏳ Track 3 — Foundation pass — AWAITING JORGE FOR HIS CLICKS

### Domain + email — JORGE
- ⬜ Cloudflare Registrar: register `serranogroup.io` (~$12/yr)
- ⬜ Cloudflare Email Routing: `jorge@serranogroup.io` → `jserranojr340@live.com`
- ⬜ Test forward
- ⬜ Update email signature

### Website — BUDDY DONE, JORGE TO DEPLOY
- ✅ Website HTML drafted at `SG-BRAND-WEBSITE.html` (single-file, Tailwind via CDN, production-ready)
- ⬜ Jorge: drop file in Vercel dashboard OR push to GitHub repo `serrano-group-website` and connect to Vercel
- ⬜ Jorge: point `serranogroup.io` DNS at Vercel deployment

### Logo — BUDDY DONE, JORGE TO PICK
- ✅ 5 logo options drafted at `SG-BRAND-LOGOS.html` (Framed Serif Monogram / Stacked SG Block / Pure Wordmark / Operator Mark / Geometric Mark + Wordmark)
- ⬜ Jorge: open `SG-BRAND-LOGOS.html` in browser, pick one option, tell Buddy "I want option N"
- ⬜ Buddy: export final SVG variants (favicon, LinkedIn banner, email signature, brand PDF header)
- ⬜ Jorge: replace placeholder logo in `SG-BRAND-WEBSITE.html` with chosen variant

### LinkedIn Company Page — JORGE
- ⬜ linkedin.com/company/setup → Create
- ⬜ Use logo from Track 3 logo decision
- ⬜ About section (synthesized from website "About" copy)
- ⬜ Tagline: "AI-native software & hardware for field operations"

### Mercury bank account — JORGE
- ⬜ mercury.com → Open Account
- ⬜ Application + EIN + LLC docs
- ⬜ Wait for approval (24-48hr)

### Brand one-pager PDF — DEFERRED until logo picked
- ⬜ Buddy: generate after Jorge picks logo (Option N from Track 3 logo)

## ✅ Track 4 — Legal hygiene drafts — COMPLETE

All drafts in repo as `SG-LEGAL-*.md` files. Lawyer customizes during Mon/Tue consult.

- ✅ `SG-LEGAL-TOS.md` — 14-section Terms of Service (NJ governing law, 12-month liability cap, mutual indemnification, AAA arbitration in Essex County)
- ✅ `SG-LEGAL-PRIVACY.md` — 14-section Privacy Policy (CCPA + GDPR ready, audit-log retention carve-out)
- ✅ `SG-LEGAL-DPA.md` — 13-section Data Processing Addendum (current sub-processor list locked, SCC-ready, CCPA Service Provider section)
- ✅ `SG-LEGAL-EMAIL-LAWYER.md` — Cold email to NJ employment attorney (send Monday AM)
- ✅ `SG-LEGAL-EMAIL-BOSS.md` — Email to CP HR for offer letter + onboarding docs (send when comfortable, NO RUSH)

## ✅ Track 5 — Operational + Sales prep — COMPLETE

Sales assets + bookkeeping foundation drafted.

- ✅ `SG-SALES-PROPOSAL.md` — One-page MyInspector pilot proposal template (3 tiers: $499/$1299/$2499, 30-day money-back, ROI math, sectioned)
- ✅ `SG-SALES-TARGETS.md` — Tier 1/2/3 NJ/NY/PA engineering firm target list. **Tier 1 verified via web research:** ENGenuity Infrastructure (top fit), Remington & Vernick Engineers, CME Associates, T&M Associates, LAN Associates. Disqualified: CDM Smith, NJAW, AECOM, Langan (too large). Cold email template included.
- ✅ `SG-BOOKKEEPING-EXPENSES.csv` — Pre-populated expense tracker with Section 179 + Schedule C + IRC §195 startup-cost guidance

## ✅ Misc — COMPLETE

- ✅ `SG-README.md` — File index + convention explainer
- ✅ Buddy will also update `.coordination/status.md` + `.coordination/decisions.md` with Sunday morning ship entries

---

## Jorge's action queue (in order, ~60 minutes total)

| # | Action | Time | Notes |
|---|---|---|---|
| 1 | Paste Lead prompt for Track 2 (provided in chat) into Code CLI | 1 min | Kicks off sanitized demo build in parallel |
| 2 | Verify `njaw-selector-v2` push status on GitHub branches page | 5 min | If pushed: open PR + Vercel verify + squash-merge. If not: ping Lead. |
| 3 | Open `SG-BRAND-LOGOS.html` in browser; pick logo option | 5 min | Tell Buddy "I want option N" |
| 4 | Cloudflare Registrar: register `serranogroup.io` | 10 min | $12/yr, no upsells |
| 5 | Cloudflare Email Routing setup | 10 min | jorge@serranogroup.io → live.com |
| 6 | Drop `SG-BRAND-WEBSITE.html` into Vercel dashboard | 5 min | Or push to new GitHub repo + connect to Vercel |
| 7 | Point `serranogroup.io` DNS at Vercel | 5 min | Cloudflare DNS settings |
| 8 | LinkedIn Company Page setup | 15 min | After logo picked |
| 9 | Mercury bank account application | 30 min | Application form + EIN docs |

**Total: ~85 minutes of Jorge clicks. Everything else runs in parallel.**

---

## End-of-Sunday target state

- ✅ Tapcard refactor + njaw-selector-v2 live on prod, MI-203 step 3 shipped
- ⬜ `serranogroup.io` live with website + logo
- ⬜ `demo.myinspector.io` live with sanitized data
- ⬜ LinkedIn Company Page published
- ⬜ Mercury application submitted
- ✅ Legal templates drafted in `SG-LEGAL-*.md`
- ✅ Sales assets drafted in `SG-SALES-*.md`
- ✅ Bookkeeping foundation in `SG-BOOKKEEPING-EXPENSES.csv`
- ⬜ Lawyer email queued for Monday AM send
- ⬜ Brand one-pager PDF (after logo pick)
