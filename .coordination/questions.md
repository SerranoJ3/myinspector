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
