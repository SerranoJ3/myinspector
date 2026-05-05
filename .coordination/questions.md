# Coordination Questions — MyInspector

> Active queue of asks awaiting Jorge's call (or Buddy's, when Lead asks).
> Per `.coordination/README.md` write conventions.
> Status flips to `answered` with a `**Resolved:**` line; entries persist for audit trail.

---

## Q-1: SUPERSEDED — initial empty queue placeholder

**Asked by:** Buddy
**Awaiting:** N/A
**Context:** First instantiation of `questions.md` per `.coordination/README.md`. No real open questions at the moment of channel activation. This entry exists so the file is non-empty and Q-numbering starts at a sane index.
**Specific call needed:** None.
**Status:** answered
**Resolved:** 2026-05-02 13:15 EDT — placeholder by design; real Q-2+ entries follow as questions arise.

---

<!-- Q-2 onward: append below this line, one block per question -->

## Q-2: MI-203 step 2 + NJAW selector pushed — awaiting Vercel preview verification before step 3 queue

**Asked by:** Lead (Claude Code CLI)
**Awaiting:** Jorge (preview verification), then Buddy (step 3 migration)
**Context:** Both tickets per the tonight-queue are shipped on separate branches off main:

- **MI-203 step 2** — `mi203-step2` branch, commit `6abe03c`. Cuts `signup()` over to `lookup_firm_by_code` RPC (single call site at `index.html:1334`). `firm.id`/`firm.name` rename to `firms[0].firm_id`/`firms[0].firm_name`. No remaining direct `from('firms').select.eq('firm_code')` in pre-auth path (verified by grep). PR: https://github.com/SerranoJ3/myinspector/pull/new/mi203-step2
- **NJAW selector (column-fix bug #3)** — `njaw-selector` branch, commit `87173f0`. Adds 6-option NJAW classification dropdown (M2C/H2C/FULL/MP/TP/KILL + "Not specified" default) to the service_work form, persisted to `phase_submissions.njaw_work_order_code`. Lead's UI judgment: service_work only (parity with existing `work_order_code` dropdown); test_pit/restoration extension is a follow-up if Buddy wants it (3-line edit per phase). PR: https://github.com/SerranoJ3/myinspector/pull/new/njaw-selector

Bugs #1/#2/#4 from the column-fix queue were already fixed in MI-109 — verified by grep on current main, no new code required.

**Specific call needed:**
1. Jorge: spin Vercel preview for both PRs, run the per-ticket verification checks (signup with `QUIET-RIVER-58` succeeds + bad code fails + firm name displays after login; NJAW selector visible on service_work tile + value persists).
2. Once green: Buddy to ship MI-203 step 3 (single-line migration dropping `firms_read_anon` policy + verification queries that anon can no longer SELECT firms directly).

**Status:** answered
**Resolved:** 2026-05-03 ~12:30 EDT — all three downstream merges shipped clean. `mi203-step2` PR merged Saturday (commit captured in 5/2 close decisions.md entry). `njaw-selector` original was conflict-cased after main moved; `njaw-selector-v2` rebuild status uncertain at this writing (Jorge to verify GitHub branches page). MI-203 step 3 (`DROP POLICY firms_read_anon`) shipped Sunday ~08:55 EDT via Supabase MCP migration `mi203_step3_drop_firms_read_anon`. Verified Sunday afternoon via VERIFY-3 in `.coordination/SUNDAY_VERIFICATION_5-3-26.md` — firms table now holds exactly 2 policies (`firms_read_authenticated`, `firms_super_write`), zero `firms_read_anon`. Anonymous firm-read attack surface fully closed.

---

## Q-7: Materials Sheet autosave cadence — pick one before Phase 2c builds it

**Asked by:** Lead (Claude Code CLI)
**Awaiting:** Jorge
**Context (refreshed 2026-05-03 PM with real audit_log baseline):** `MI101_PHASE2_FRONTEND_BRIEF.md` invited autosave for the Materials Sheet form. Deliberately held back from `mi101-phase2a` PR because audit_log volume math is meaningful. Sunday's verification pulled the actual baseline:

- **Current audit_log write rate:** 288 rows / 24h = ~12 rows/hour (mixed dev + demo + early-beta activity).
- **Current audit_log total:** 1,095 rows ever written. Storage: trivial.
- **Hash chain integrity:** scales O(1) per row (BEFORE INSERT trigger overwrites prev_hash). Zero perf concern at any cadence.

**Refreshed volume estimates per cadence (based on actual baseline):**

| Cadence | Per-sheet edit session | Per inspector / day | 14-inspector firm / day | Multiplier on current 24h rate |
|---|---|---|---|---|
| **A. Every-blur with dirty tracking** | 5–10 rows | 10–30 (2–3 sheets) | 140–420 | **1.5–2.5x** the current daily rate from this single feature |
| **B. 10s debounced timer** | 4–8 rows | 8–24 | 112–336 | **1.4–2.2x** |
| **C. Explicit "Save Draft" sub-action** | 1–2 rows | 2–6 | 28–84 | **1.1–1.3x** |
| **D. No autosave (current state)** | 1 row | 2–3 | 28–42 | baseline |

**What changed in the analysis since the brief was written:**

1. **Volume ratio is much smaller than initially feared.** "25–30x" was an overestimate; real audit_log baseline (288/24h) makes A only 1.5–2.5x — still meaningful but not catastrophic.
2. **Storage cost at A's rate:** ~150K rows/year per 14-inspector firm. At ~500 bytes/row average = ~75 MB/year. Postgres free-tier handles this with zero stress for ~10 years. Object Lock S3 export size grows similarly — still well within Cloudflare R2 / S3 free tiers for ~5 years.
3. **Hash-chain integrity at A's rate:** unchanged (O(1) per row). No perf cliff.
4. **What option A buys:** never-lose-a-keystroke UX. Inspector taps Close mid-edit → work survives.
5. **What option C buys:** lowest cognitive overhead in the audit log (1 row = 1 inspector intent). Easier to reason about during compliance review.
6. **What option D (current) costs:** mid-edit data loss if inspector navigates away or crashes. Real LCRI field condition risk.

**Buddy recommendation (not a decision — Jorge calls):**

**Option C (Explicit Save Draft sub-action).** Reasoning:
- Volume is 1.1–1.3x of baseline — negligible.
- Each row in audit_log corresponds to a deliberate inspector action, which makes audit review interpretable ("why does this sheet have 14 audit entries?" is harder to answer with A).
- Inspector retains explicit control — matches the locked core principle: "Inspectors do NOT do extra work for the app." Save Draft is opt-in, not background magic.
- v0.1 UX is preserved (close + save explicit final). v0.1.1 adds the third button.
- Future: option C does NOT preclude option A later. If beta inspectors want background saves, can layer A on top of C without schema changes.

**Option A is defensible if:** Jorge prioritizes never-lose-a-keystroke over audit interpretability. The 1.5–2.5x volume is genuinely fine on the current Supabase plan and far below any Postgres limit.

**Option D (current) is defensible if:** Phase 2c is gated tighter than expected and you want zero new audit volume per save attempt. Trade-off: occasional inspector frustration on data loss.

**Specific call needed:** A, B, C, or D. Phase 2c absorbs implementation once Jorge picks. Implementation cost difference between A/B/C/D is ~30 minutes — the call is purely about UX + audit posture, not engineering effort.

**Status:** answered
**Resolved:** 2026-05-03 ~17:35 EDT — Jorge locked **Option C (Explicit Save Draft sub-action)** per `decisions.md` Sunday evening entry. Phase 2c Restoration Card form ships with explicit Save Draft button when Lead picks up the form half (next session, gated only on this answer which is now live).

---

## Q-2d-a: Visual Tapcard Preview — font style for autopopulated values

**Asked by:** Buddy (in `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md`)
**Awaiting:** Jorge
**Context:** The Visual Tapcard Preview renders form values onto a rendered SVG that mimics the standard NJAW paper tapcard. Autopopulated text values can be rendered in either:
- (a) **Monospace** (`'JetBrains Mono'` or system mono fallback) — reads as professional document; clean numeric measurements; matches "compliance-grade artifact" feel.
- (b) **Handwriting-style** (e.g., `'Caveat'` from Google Fonts) — mimics actual inspector handwriting on paper tapcards.

**Buddy recommendation:** (a) monospace. Reasoning: handwriting fonts always undermine the compliance feel ("Comic Sans cosplay"). Inspectors will take the visual tapcard more seriously when measurements render in clean mono. Future v2 paper-aging theme works with mono — handwriting + paper-aging is the wrong direction. Implementation cost is identical between (a) and (b) — pure CSS swap.

**Specific call needed:** (a) or (b).

**Status:** answered
**Resolved:** 2026-05-05 ~19:00 EDT — Jorge locked **(a) monospace** per evening session ratification ("a, a, a"). Phase 2d build proceeds with `'JetBrains Mono'` primary, system mono fallback. CSS-level decision, zero engineering impact between options.

---

## Q-2d-b: Visual Tapcard Preview — print-to-PDF in v1 or defer to v2?

**Asked by:** Buddy (in `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md`)
**Awaiting:** Jorge
**Context:** SVG → PDF export would let compliance officers print the visual tapcard for the audit package. Adds ~1 session of build (jsPDF integration, pagination, page-break handling). Compliance package today is delivered via existing `audit_trail_export` and `cdm_smith_compliance_proof` RPCs — visual tapcard PDF would be additive, not blocking.

**Buddy recommendation:** Defer to v2. Reasoning: no customer has asked for print-to-PDF yet. Building before someone asks = gold-plating. Existing compliance RPCs cover the audit-package surface. Trigger to un-defer: first compliance officer at a prospect engineering firm asks "can we get a printable copy of the tapcard?" during demo or pilot.

**Specific call needed:** Defer to v2, or build in v1.

**Status:** answered
**Resolved:** 2026-05-05 ~19:00 EDT — Jorge locked **defer to v2** per evening session ratification ("a, a, a"). Phase 2d build does NOT include print-to-PDF. Future ticket opens when prompt-trigger fires (compliance officer asks during demo/pilot). Captured for un-defer trigger.

---

## Q-2d-c: Visual Tapcard Preview — empty-field visual treatment

**Asked by:** Buddy (in `MI101_PHASE2D_VISUAL_TAPCARD_BRIEF.md`)
**Awaiting:** Jorge
**Context:** Fields with no value yet (form not filled) need a visual treatment on the SVG. Three options:
- (a) **Thin gray underline** — paper-form mimic; matches the convention inspectors already know from the actual paper tapcard.
- (b) **Light gray placeholder text** matching field name (e.g., "CS depth").
- (c) **Truly blank** — only populated fields render.

**Buddy recommendation:** (a) thin gray underline. Reasoning: mirrors the paper-tapcard convention inspectors are used to; empty visual cue tells inspector "this field is expected" (whereas truly blank tells them nothing); placeholder text competes with real values for visual weight when fields are partially populated.

**Specific call needed:** (a), (b), or (c).

**Status:** answered
**Resolved:** 2026-05-05 ~19:00 EDT — Jorge locked **(a) thin gray underline** per evening session ratification ("a, a, a"). Phase 2d build renders empty fields as ~15-20px wide thin gray underline at the anchor position. Paper-form fidelity preserved.
