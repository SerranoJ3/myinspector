# Buddy Sync Note — Three Late-Night Ships (Wed 5/6 → Thu 5/7 ~00:30 EDT)

**Cut:** 2026-05-07 ~00:30 EDT
**Author:** Buddy (Claude.ai web)
**Context:** Jorge said "keep going" after the post-Phase-4 doc commit. Three sequential ships landed.

---

## Ship 1 — Towns swap (mi_demo_seed_14)

**Why:** Buddy seeded demo properties with Maplewood/Millburn/Short Hills towns. Jorge flagged: those are NJAW footprint and a CP Engineers prospect like Stan would clock the demo as Jorge's actual contract zone. Real bug, not a misread.

**What:**
- Migration `mi_demo_seed_14_swap_towns_to_non_njaw` applied via Supabase MCP. Version `20260507002311`.
- 12 demo properties (`bb...0001` through `bb...0012`) reassigned to clearly non-NJAW NJ municipalities:
  - Hoboken (Veolia/Suez North Hudson) — 3 properties, zip 07030
  - Jersey City (Suez) — 3 properties, zips 07302 + 07310
  - Bayonne (Suez Bayonne) — 3 properties, zip 07002
  - Trenton (Trenton Water Works) — 3 properties, zips 08608 + 08611
- Sector enum `NJAW_SHORT_HILLS` retained on bb...0011 + bb...0012 — sector is a product role-inversion type, not a municipality. Sector enum cleanup is a separate ticket.
- File on disk: `supabase/migrations/20260507002311_mi_demo_seed_14_swap_towns_to_non_njaw.sql`
- Verification: `SELECT city, COUNT(*) FROM properties WHERE firm_id='99...9' AND id::text LIKE 'bbbbbbbb-%' GROUP BY city` → 3/3/3/3 across the four towns.

---

## Ship 2 — MI-110 Phase 4 acceptance #6 (read-only diagram embed)

**Why:** Closing the open follow-up from tonight's Phase 4 ship. Engine was already in place (`diagramLoad(data, {readOnly:true})`) but no wiring into the property-detail view of previously-submitted tapcards.

**What:** 3 surgical edits to `index.html`:

1. **CSS** (~line 254): added `.pd-diagram-embed` + `.pd-diagram-pill` + `.pd-diagram-svg` for inline read-only embed styling
2. **JS** (after `diagramAttachListeners`): new `diagramReadOnlyEmbed(diagram, opts)` function — returns standalone SVG markup string for any tapcard_data.diagram payload. Multiple embeds can coexist on one page (no shared IDs). Includes XSS-safe escapeStr for label text.
3. **Property Detail submissions list** (~line 3760): each phase=='tapcard' submission with `tapcard_data.diagram` set now renders an inline read-only diagram in the card body alongside notes/photos. Pill text: `Diagram — [datetime] · [inspector]`.

**Acceptance #6 → ✅ closed.** All 7 brief acceptance criteria now covered.

---

## Ship 3 — Luis v1 polish (multi-turn + context awareness + RLS fix)

**Why:** The deep dive listed Luis v1 as ~2 sessions remaining, but the basic chat UI was already in place. Real gaps were:
1. Single-turn (no conversation history sent to API — just `messages:[{role:'user',content:q}]`)
2. No page context awareness (Luis didn't know which tapcard/property the user was looking at)
3. **RLS bug:** `luis_conversations` insert was missing `firm_id`. Verified via `pg_policies` — policy is `((firm_id = current_firm_id()) OR is_super_admin())`. NULL firm_id silently failed WITH CHECK. **Every Luis conversation written before this fix was rejected.**

**What:** 1 surgical edit to the Luis script block:

- New `luisHistory = []` global; capped at 20 messages (10 turns) to keep token usage bounded
- New `luisGetPageContext()` function: inspects DOM for open modals (tapcard, property detail, materials sheet) and returns a context string injected into the system prompt. Pulls fresh on each send (modals can open/close mid-conversation).
- New `luisResetConversation()` helper (no UI button yet; can wire a reset button in the panel header in a follow-up)
- `sendLuis` rewritten to:
  - Build `messages = [...luisHistory, {role:'user', content:q}]`
  - Build `system: LUIS_SYSTEM + luisGetPageContext()`
  - On success, push both turns to `luisHistory`, slice to last 20
  - **Insert `firm_id: currentFirmId` on `luis_conversations.insert`** (the RLS fix)

**Demo impact:** Luis can now hold multi-turn conversations AND know what the user is looking at. Sample interaction:
> User opens tapcard for 12 Hoboken (NJ6_NORMAL sector), opens Luis, asks "What work code applies here?"
> Luis (with context "filling out tapcard, sector NJ6_NORMAL"): answers about FULL/M2C/H2C/etc with grounding.
> User: "What about the whiteboard rule for that?"
> Luis (with history): answers in continuation, knows we're still on tapcard context.

---

## What CC should do

`git status` should show:
- `index.html` modified (~+90 lines: CSS additions, diagramReadOnlyEmbed function, submissions list diagram embed wire-in, Luis multi-turn + context + RLS fix)
- New file: `supabase/migrations/20260507002311_mi_demo_seed_14_swap_towns_to_non_njaw.sql`
- New file: `.coordination/buddy_three_ships_2026-05-07.md` (this note)

Suggested commit:
```
git add index.html supabase/migrations/ .coordination/buddy_three_ships_2026-05-07.md
git commit -m "feat: towns swap to non-NJAW + MI-110 acceptance #6 + Luis multi-turn/context/RLS fix"
git push origin demo-banner
```

Verify Vercel preview READY post-push.

---

## Updated state (for STATE.md / decisions.md follow-up)

### STATE.md
- MI-110 Phase 4 row → **Closed** (acceptance #6 wired, no follow-up)
- New row: MI-DEMO-TOWNS shipped (mi_demo_seed_14 migration applied)
- Luis v1 row → **Polished** (multi-turn + context + RLS fix)
- Completion bumps: v0.1 72%→74%, v1.0 62%→65%
- Banked Discipline Lesson 7 candidate: **Verify RLS policy WITH CHECK columns are populated on every insert.** Luis was silently dropping conversations for an unknown duration because firm_id wasn't on the insert. Spec said firm_id was required; code didn't include it; nobody noticed because the UI didn't show the failure.

### decisions.md
- 2026-05-07 ~00:00 EDT: Demo property towns reassigned to non-NJAW NJ municipalities (Hoboken/Jersey City/Bayonne/Trenton). Sector enum `NJAW_SHORT_HILLS` retained as product role-inversion type, not municipality. Sector enum rename queued as separate ticket.
- 2026-05-07 ~00:15 EDT: MI-110 Phase 4 acceptance #6 closed. Read-only diagram embeds render in property-detail submissions list for any phase='tapcard' submission with `tapcard_data.diagram` populated. `diagramReadOnlyEmbed()` is the public API; multiple embeds per page supported.
- 2026-05-07 ~00:25 EDT: Luis v1 polished. Multi-turn history (cap 20 messages = 10 turns), page context awareness, firm_id added to luis_conversations insert. Confirmed RLS policy `firm_id = current_firm_id() OR is_super_admin()` was rejecting all prior writes with NULL firm_id.
