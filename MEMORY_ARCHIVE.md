# Memory Archive

> **Purpose:** Reference doc for content moved out of userMemories on 2026-05-12 during the memory architecture overhaul.
> **Canonical for:** product specs, business/legal state, personal finance, dated operational data.
> **Buddy greps here** when context needs detail beyond identity/principles, after checking CLAUDE.md / STATE.md / BUDDY_STANDARD.md / .coordination/ first.

---

## Cross-References (canonical lives elsewhere)

| Topic | Canonical location |
|---|---|
| Code-work style (find/replace format, "yup" gate, etc.) | `BUDDY_STANDARD.md` §7 |
| MI back burner items (ASTM, residential, HVAC, bot hub) | `.coordination/SESSION_LOG.md` 2026-05-10 entry |
| People in play (Stan, Justin, Tyler, Abdul, Rabiyu, Brett) | `.coordination/RECENT_CONTEXT.md` "People in play" section |

---

## Product Portfolio

### BidGrid

Landscaping SaaS. Aerial + AR parcel measurement, design, AI proposals + chat. Field ops: scheduling, assignments, GPS+photo confirmation, consumables calc (fuel, seed, string per parcel). Admin: spending, materials, Excel/PDF export. Pricing $99–$599/mo. 4 phases: MVP (Claude + Stripe) → AR camera → AI chat + PDF → scale (white label, CRM Jobber/HouseCall Pro). Competitors: PRO Landscape+, SiteRecon AI, DreamzAR, BuildVision AI.

**AI learning features:** App improves over time via real usage data. Consumables calculator learns actual vs recommended usage per parcel/crew. Proposal pricing learns win/loss rates. Photo confirmation data doubles as marketing content.

**Industry depth:** Jorge previously owned a landscaping company himself and has multiple personal contacts across the landscaping industry — equal or greater domain expertise vs water/utility. Beta customer pool is warm, not cold.

### MyInspector

Water utility field-to-compliance operations platform. Separate subfolder from BidGrid under Serrano Group. Target: engineering firms doing LCRI (Lead & Copper Rule Improvements) mandate work nationwide. Jorge supervises 14 field inspectors + 13 office data entry staff for CP Engineers contracted by NJ American Water (NJAW). Contractor is Montana Construction.

**Platform scope (7 modules):** Water Utility, Wastewater/Sewer, Roadway/Pavement, ADA Compliance, Electrical Engineering, Structural Engineering, Construction PM Oversight. Construction PM module has GPS arrival/departure billable hour verification — strongest independent patent claim per Bill. Luis AI knows all 7 disciplines.

### TIA

Smart Health Companion Dispenser (Serrano Health Group). 14 pods + powder module, central tablet, heat-seal bags, AI-powered. User types: Performer, Elderly/Health-Challenged, Wellness Beginner. Tia App (alarms/reminders, all tiers), Babi caregiver app (Home Pro+ only, named after Jorge's mom Barbara / "Babi" per Teresa). Pricing: Essential $299, Home Pro $599, Premium $999. Bags $9.99/mo standard, $4.99/mo Premium lifetime.

**Hardware design:** Milwaukee battery style removable pods behind hinged tablet door (PIN/fingerprint lock), quarter-turn removable funnel, flex PEI/silicone mesh heat seal surface (3D printer bed principle) for self-cleaning bagging area, slide-out drip tray, ribbon cable service loop for screen hinge. Pods are proprietary replaceable accessories = additional revenue stream.

### FORGE

Performance supplement dispenser under Serrano Health Group LLC (same as TIA). Matte black, brushed aluminum. Same chassis as TIA. Named FORGE — rhymes with Jorge/George (founder Easter egg). App: FORGE app. Tiers: Solo $349, Elite $649, Pro $1,099. WHOOP/Oura/Garmin/Apple Watch on Elite+. Trademark Class 10+44 needed.

### TIA + FORGE Subscription Layer

| Subscription | Price | Purpose |
|---|---|---|
| TIA Connect | $9.99/mo | wearable integration |
| TIA Intelligence | $14.99/mo | AI performance coaching |
| TIA Guard | $7.99/mo | emergency wearable alerts |
| Babi Remote | $4.99/mo | caregiver app for Essential tier |
| Bag subscription | $9.99/mo standard / $4.99/mo Premium for life | consumables |

Hardware gets them in. Subscriptions keep them paying.

---

## Business & Legal

### Serrano Group Operations Model

Zero employees. Only AI bots. Jorge is sole operator unless family joins. Stack: Claude (content/strategy), Midjourney (imagery), HeyGen+ElevenLabs (video/voice), Buffer (social scheduling), Klaviyo (email), Shopify (ecommerce), Stripe (payments), n8n (automation backbone), Wave (accounting), Northwest Registered Agent (LLC). Social media brand accounts only — no personal association with Jorge Serrano for political reasons.

### LLC + Trademark Status

Full package document created and delivered. Covers: Northwest Registered Agent LLC formation (NJ), EIN, Operating Agreement, bank account setup. Trademarks: BidGrid (Class 42), MyInspector (Class 42), Tia (Class 10 + 44). Master checklist included. ~$1,400 total trademark investment. **Jorge has not yet filed anything — all steps are pending.**

### MyInspector Enterprise Pitch (5/4/26)

Pricing locked: Essentials $99 / Pro $299 / Enterprise $1,499 per firm/mo. 11-slide pitch deck delivered. Integration roadmap: Ajera + ADP + Teams Q3 2026, Procore + Bluebeam Q4 2026, Outlook live.

**MI-DEMO ticket series:** DEMO-1 integrations.html (spec ready), DEMO-2 dashboard-enterprise.html, DEMO-3 magic-moment flows.

**Demo theater principle:** static catalogs + fake modals + hardcoded feeds, no real OAuth, no audit_log writes from demo pages.

---

## Operational Rules

### NJAW Field Rules

> **Note:** verify against `CLAUDE.md` as canonical — if conflict, CLAUDE.md wins.

Codes: M2C / H2C / FULL / MP / TP / KILL (ABANDON / RELOCATE_FULL / RELOCATE_STREET).

Plastic OK customer-side from 1/2/26. Depth: CS ≥ 36", MP horns ≥ 2'. Pipe 3/4"–2".

**CDM-Smith 4/30/26 rules:**
- (a) No-work = house + whiteboard photos with reason
- (b) Existing MP must be noted
- (c) CS replace = Carlo authorization with date + time + reason. NO exceptions.
- (d) MP horn copper owns field
- (e) CS-house only 1 negative (CS past corner)

**Maplewood:** customer in-spec = street-only relocate.

---

## Sprint Metrics

### Velocity Benchmark (4/28/26 9:15 PM)

90-min focused build = 20–23 SQL milestones, ~4 min/milestone including Claude mistakes/retries. Source: MI-202 build 7:40–9:10 PM EDT 4/28/26.

**Calibrated MyInspector v1.0** (7 modules + BidGrid enterprise + residential + integrations + billing) = 57–78 sessions, NOT 150–200.

- Aggressive target: mid-June 2026
- Realistic w/ vendor delays: mid-July 2026

8 days in = 15–18% scope. Founded 4:20 PM April 20, 2026. Use this benchmark for ALL future timeline estimates.

---

## Personal Finance

### Investment Profile

Income $42/hr hourly, avg 45–50 hr/wk (~$112k/yr). Single, no dependents, age 36, 29-year horizon to 65. Maxes Roth IRA $7,500/yr + captures 5% 401k company match. Deferred-gratification investor.

**Macro view:** bearish on USD long-term (de-dollarization, China/India rise). Hedges via international equity, gold, BTC. Uses 5–7% realistic real return assumption rather than historical 10%. Already on track for $1.7–3.2M floor at 65 from Roth + 401k alone.

### Investment Strategy 2026

**Roth $7,500 split:**
- 35% US Core (VTI/VOO)
- 20% Intl/EM (VXUS + VWO)
- 27% Quantum ($2,000)
- 8% Gold (IAU)
- 5% BTC (IBIT)
- 5% Cash

**Quantum slice (inside Roth):**
- 30% QTUM ETF
- 24.5% IONQ
- 20.5% RAAQ → IQM SPAC
- 15% QBTS
- 10% LAES
- 5–10 year horizon

**AI agents plan:** n8n + Claude portfolio monitors / news watchers / rebalance calculator. **Execute trades MANUALLY** — Roth at major broker, no API, irreversible mistakes too costly.

---

*End of archive. Last updated: 2026-05-12.*
