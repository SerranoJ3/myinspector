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

**Status:** open

---

## Q-7: Materials Sheet autosave cadence — pick one before Phase 2c builds it

**Asked by:** Lead (Claude Code CLI)
**Awaiting:** Jorge
**Context:** `MI101_PHASE2_FRONTEND_BRIEF.md` invited autosave ("every ~10s OR on field blur — Lead's UI judgment") for the Materials Sheet form. Deliberately held back from `mi101-phase2a` PR (commits `04fd6b1` main feature + `a542d5a` polish stack) because audit_log volume math is meaningful: ~36 fields × ~14 inspectors × ~2-3 sheets/day = roughly 25-30x the current daily `audit_log` write rate even with dirty-tracking guards on field-blur. Hash-chain integrity scales fine, but storage + S3 Object Lock export size scales with row count, so this is a deliberate cost-vs-UX call — not a default-on UX choice.

**Three reasonable cadences with different volume tradeoffs:**

1. **Every-blur with dirty-tracking** — most responsive UX, highest volume. Each blur where the field's value actually changed = 1 UPDATE = 1 audit_log row. Estimated ~5-10 audit rows per sheet edit session.
2. **10s debounced timer** — moderate volume, tolerates short backgrounding. ~6 saves per minute of active editing while modal is open.
3. **Explicit "Save Draft" sub-action** — lowest volume (1 row per inspector intent). Adds a third button alongside Close + Save Materials Sheet. Better than the current state for forget-to-save scenarios; only fires when inspector explicitly opts in.

**Specific call needed:** pick 1 of the 3, OR ratify "no autosave, explicit Save only" (current state — ships fine for v0.1, zero extra audit volume). Phase 2c absorbs implementation once the answer lands.

**Status:** open
