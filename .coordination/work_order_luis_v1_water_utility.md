# Work Order — Luis AI v1 (Water Utility Field Assistant — Conversational)

**Authored:** 2026-05-05 ~22:05 EDT
**By:** Buddy
**For:** Lead — pickup-ready
**Authority:** Jorge granted Buddy batch trust. Schema verified 2026-05-05 21:25 EDT.

---

## Why Luis matters for the Jeff demo

Luis is MyInspector's built-in AI field assistant. The differentiator: every other inspection app has form fields. MyInspector has a domain-aware AI that an inspector can ASK. **"What's the depth requirement for curb stop in NJAW Maplewood?"** instead of digging through a PDF spec doc on a phone in the rain.

For Jeff demo (5/14-5/15): showing a working Luis on water utility module changes MyInspector from "good UI for inspectors" to "AI-augmented inspection platform." That's the ambition jump.

**v1 scope locked deliberately narrow:** Water Utility module only. Single discipline. Real conversation surface, real domain knowledge, real RAG against the locked NJAW field rules. v2 expands to other 6 disciplines. v3 adds vision (analyze photos, identify fittings).

---

## Verified ground truth — `luis_conversations` schema

```
id                uuid PK (default gen_random_uuid())
user_id           uuid FK → auth.users
project_id        uuid FK → projects (nullable)
module_key        text                    -- 'water_utility' for v1
question          text NOT NULL
answer            text NOT NULL
sources           text[]                  -- citation references
created_at        timestamptz NOT NULL DEFAULT now()
firm_id           uuid FK → firms
```

Schema location: `public.luis_conversations`. RLS-locked, firm-scoped. Verified 2026-05-05 21:25 EDT — table exists, 0 rows currently.

---

## Locked answers (batch trust)

- **Q-luis-a — model choice for v1:** Claude Haiku 4.5 via Anthropic API. Fast, cheap, good enough for domain Q&A with strong retrieval. Upgrade to Sonnet 4.6 or Opus 4.7 only for queries that need deeper reasoning (escalation path TBD post-v1).
- **Q-luis-b — knowledge base source-of-truth:** Two layers. (1) Locked field rules in this skill set (`myinspector-domain-rules` skill written tonight) — phase enums, work order codes, CDM-Smith rules, sector dispatch, depth requirements, parts catalogs. (2) NJAW-specific docs (Maplewood municipal spec, Carlo authorization workflow, MapCall WO conventions) loaded as RAG corpus.
- **Q-luis-c — chat surface placement:** New floating "Ask Luis" button on every screen (bottom-right, brand-gold), opens chat panel as overlay. Persistent across navigation within session. Not a separate route — inspector should be able to ask Luis WITHOUT leaving the form they're filling out.
- **Q-luis-d — citations:** Every Luis answer includes `sources` array — the rule, doc, or section the answer is grounded in. UI surfaces citations as small chips below the answer ("Per CDM-Smith rule (c)" / "NJAW Maplewood spec"). Inspectors see WHY Luis said what it said.
- **Q-luis-e — escalation path on uncertain answers:** When Luis's confidence is low or query is outside the locked rule set, response is "I'm not certain — here's what I know, and you should verify with [supervisor/Carlo/specific doc]." Never guess on safety-critical or regulatory questions.

---

## Architecture

```
Inspector taps "Ask Luis" → chat panel opens
  ↓
Inspector types question
  ↓
Frontend POST to Edge Function `luis-ask`
  ↓
Edge Function:
  1. Pulls inspector context (firm_id, project_id, current_property if any, sector)
  2. Constructs system prompt with locked field rules + property-specific context
  3. RAG retrieval against knowledge corpus (initial v1: just the locked rules embedded inline; v1.5 adds proper vector store)
  4. Calls Claude Haiku 4.5 API
  5. Parses response for citations
  6. Writes row to `luis_conversations` (audit trail)
  7. Returns answer + citations to frontend
  ↓
Chat panel renders answer + citation chips
  ↓
Inspector continues conversation (thread preserved within session)
```

---

## Unit 1 — Edge Function `luis-ask` + system prompt (~1 session)

1. Create new Supabase Edge Function `luis-ask` at `/supabase/functions/luis-ask/index.ts`
2. Function accepts: `{ question: string, context: { property_id?, sector?, current_phase? } }`
3. Function constructs system prompt with:
   - "You are Luis, the field assistant for MyInspector. You help water utility inspectors on NJAW LCRI work."
   - The locked field rules (inline for v1 — phase enums, NJAW work order codes, CDM-Smith rules, sector dispatch, depth requirements)
   - Property/sector context if provided
   - Citation requirement: "Always cite the rule or doc your answer comes from. Use the format [Source: <name>]."
4. Function calls Anthropic API (Haiku 4.5) with system prompt + user question
5. Function parses response, extracts citations, writes audit row to `luis_conversations`
6. Returns `{ answer: string, sources: string[], conversation_id: uuid }`
7. Anthropic API key stored as Supabase secret `ANTHROPIC_API_KEY` (Lead creates via `supabase secrets set`)
8. RLS on `luis_conversations`: function uses service-role key for INSERT (audit row), but inspector's own JWT for context — standard Edge Function pattern

Commit Unit 1:

```
feat(MI-luis-1 Unit 1): luis-ask Edge Function with locked rule system prompt + Haiku 4.5

- Edge Function /supabase/functions/luis-ask
- System prompt embeds locked NJAW field rules + sector dispatch
- Calls Claude Haiku 4.5 via Anthropic API
- Citation parsing + sources array
- Audit row writes to luis_conversations on every Q&A
- ANTHROPIC_API_KEY in Supabase secrets
```

---

## Unit 2 — "Ask Luis" floating button + chat panel (~1 session)

1. Bottom-right floating action button (FAB), brand-gold (#C9A84C), Luis avatar icon
2. Tap opens chat panel — slide-in from right on desktop, bottom-sheet on mobile
3. Chat panel:
   - Header: "Luis — Field Assistant" + close X
   - Message list: alternating inspector questions + Luis answers (Luis answers in cream `#F5F2EC` bubbles, inspector questions in navy `#0D1F3C` bubbles)
   - Citation chips below Luis answers, tappable to expand source detail
   - Input field at bottom + Send button
   - Loading indicator while Luis thinks
4. Chat persists within session (in-memory state; v1 doesn't reload prior conversations on refresh)
5. Context auto-pulled from current screen: if inspector is in Property Detail, context includes property_id + sector + current_phase
6. Mobile-responsive: large tap targets, native keyboard input, dismiss on swipe-down

Commit Unit 2:

```
feat(MI-luis-1 Unit 2): Ask Luis floating button + chat panel UI

- Bottom-right FAB, brand-gold, Luis avatar
- Slide-in chat panel desktop / bottom-sheet mobile
- Brand-palette message bubbles + citation chips
- Auto-context from current screen (property_id, sector, current_phase)
- In-memory session persistence
```

---

## Unit 3 — Conversation history view + supervisor analytics (~1 session, optional)

1. New "Luis History" view inside Construction PM tab or separate top-level (Lead's call)
2. Lists all `luis_conversations` for current firm, sorted by created_at DESC
3. Filterable by inspector, by module_key, by date range
4. Each row shows question + abbreviated answer + sources, expandable to full answer
5. Supervisor analytics: top 10 most-asked questions per week (signals where docs are unclear or training needed)
6. CSV export for compliance audit

Commit Unit 3 (if shipped):

```
feat(MI-luis-1 Unit 3): conversation history + supervisor analytics + CSV export
```

---

## Locked NJAW field rules embedded in v1 system prompt

(Lead pulls this verbatim from `.coordination/skills/myinspector-domain-rules/SKILL.md` — single source of truth. When that skill updates, the system prompt updates. v1.5 reads the skill at runtime; v1 inlines.)

---

## Demo script for Jeff (5/14-5/15)

Jorge or demo presenter opens MyInspector → opens a property → taps "Ask Luis". Three sample questions to walk through:

1. **"What's the curb stop depth requirement?"**
   Luis answers: "Curb stop depth must be ≥ 36 inches per NJAW LCRI spec. [Source: NJAW field rules]"

2. **"Do I need a whiteboard photo for a tapcard inspection?"**
   Luis answers: "No. Whiteboard is required only when there's open excavation. Tapcards / triangulation / GIS docs / blueprints / backlog do not require whiteboard. [Source: Whiteboard requirement matrix]"

3. **"The customer's pipe is plastic. Is that ok for replacement?"**
   Luis answers: "Yes. Plastic is acceptable from the customer side as of 1/2/26. NJAW side still requires copper. [Source: NJAW pipe material rules, effective 2026-01-02]"

That's the demo. Three questions. Three correct, cited answers. Watch Jeff's reaction.

---

## Acceptance criteria

1. Edge Function `luis-ask` deploys clean, callable from frontend with valid JWT
2. ANTHROPIC_API_KEY secret set in Supabase project (Lead verifies via Supabase dashboard)
3. Floating "Ask Luis" button visible on all inspector-role screens (not on auth/login)
4. Chat panel opens on tap, accepts question, shows loading state, renders answer
5. Citations render as chips below answer
6. Audit row writes to `luis_conversations` on every Q&A (count goes 0→N)
7. Mobile responsive (chat panel becomes bottom-sheet, large tap targets)
8. RLS verified: inspector A cannot see firm B's `luis_conversations`
9. Three demo questions return accurate cited answers (live test)
10. Chat panel context auto-pulls property_id when inspector is in Property Detail

---

## Cost estimate

Haiku 4.5 input ~$0.80/MTok, output ~$4/MTok (verify current pricing — search docs.claude.com if unsure). Average inspector question + Luis answer ≈ 500 input tokens + 300 output tokens. Per question cost: ~$0.0016.

100 inspector questions per day across the firm = ~$0.16/day = ~$5/month. Well within Serrano's operating budget. Even at 10x scale: ~$50/mo across the customer base.

Pricing tier alignment: Luis is included in Pro ($299/mo) and Enterprise ($1,499/mo) tiers per the locked enterprise pricing pitch. Essentials ($99/mo) gets a "lite" version (10 questions/inspector/day cap) — enforce via rate-limit row count check in Edge Function.

---

## Closing actions

- Push demo-banner to origin
- Update STATE.md: MI-luis-1 v1 closed
- Update status.md: Luis v1 in recently-shipped
- Append decisions.md entries for Q-luis-a/b/c/d/e ratifications
- Final session-close commit

---

## Stop conditions

- Anthropic API key issues (key invalid, rate limited at signup)
- Edge Function deployment failures
- BUDDY_STANDARD locked principle conflict

## Do NOT stop for

- System prompt wording polish (Lead's craft, document choices in commit)
- Chat panel animation choice (Lead's UI craft)
- Citation chip styling
- Mobile bottom-sheet animation

## Velocity estimate

2 sessions for Units 1+2 ship v1 demo-ready. Unit 3 ships v1.5 post-demo.

## Verified ground truth footer

- `luis_conversations` table verified present 2026-05-05 21:25 EDT — 0 rows currently
- `modules` table has `water_utility` row confirmed
- No existing Edge Function `luis-ask` — verified clean creation
- Anthropic Haiku 4.5 model string: `claude-haiku-4-5-20251001` (verified from system prompt context)
- Brand palette (navy/gold/cream) per locked Serrano brand standards
