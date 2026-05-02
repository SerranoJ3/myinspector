# MI-109 — End-to-End Manual Checklist (v2)

> Walk this against staging (or local supabase serve). Every box must be
> checked before merging the PR. Failed boxes get filed as new tickets and
> hold the merge.

**Spec source:** CDM-Smith email rule (c) — every CS replacement on a phase
submission requires Carlo authorization (timestamp + reason ≥ 20 chars +
supervisor name). NO EXCEPTION path. Audit log every attempt.

**Authority:** decision log resolved 2026-05-02 in
`discovery/whiteboard_override_template.md`.

**Backend contract under test:**

```
public.submit_cs_authorization(
  p_phase_submission_id    uuid,
  p_supervisor_name text,
  p_authorized_at          timestamptz,
  p_reason                 text
) RETURNS jsonb              -- envelope (INV-1, pattern B)
```

**Envelope shape (INV-1):**
```
{
  status:           'accepted' | 'rejected' | 'already_recorded',
  authorization_id: uuid | null,
  error_code:       null | 'REASON_TOO_SHORT' | 'SUPERVISOR_EMPTY'
                  | 'PHASE_SUBMISSION_ID_MISSING'
                  | 'PHASE_SUBMISSION_NOT_FOUND'
                  | 'FORBIDDEN_CROSS_FIRM'
                  | 'AUTHORIZED_AT_MISSING'
                  | 'ALREADY_RECORDED',
  message:          text
}
```

`PHASE_SUBMISSION_ID_MISSING` and `AUTHORIZED_AT_MISSING` are param-null/empty
checks; `PHASE_SUBMISSION_NOT_FOUND` is reserved for DB-lookup misses (param
was a well-formed uuid but no row exists).

**AUTH_DENIED is the only RAISE path** — security-boundary failure raises
with `ERRCODE='insufficient_privilege'` and message prefix `'AUTH_DENIED:'`.

**Side effects on each path:**
| Status | cs_replacement_authorizations | audit_log | compliance_events |
|---|---|---|---|
| accepted | +1 | +2 (write_audit_log AFTER trigger fires on cs_auth INSERT + phase_submissions UPDATE; chain trigger writes prev_hash + row_hash on each) | +1 (`cs_replacement.auth.accepted`) |
| rejected | 0 | 0 | +1 (`cs_replacement.auth.rejected`) |
| already_recorded | 0 | 0 | +1 (`cs_replacement.auth.duplicate`) |
| AUTH_DENIED RAISE | 0 | 0 | 0 (RAISE rolls back compliance INSERT — accepted limitation per INV-1) |

All compliance events use `severity='alert'`, `source='MI-109'`,
`correlation_id=phase_submission_id::text`. Details jsonb contains:
`{phase_submission_id, supervisor, authorized_at, reason_length, status,
error_code (if rejected/duplicate), existing_authorization_id (already_recorded only)}`.

---

## Pre-flight

- [ ] Migration applied to staging via Supabase dashboard SQL editor (NOT
      `supabase db push`) — paste contents of
      `supabase/migrations/20260502013854_mi109_cs_auth.sql` into
      https://supabase.com/dashboard/project/wryitfoletwskkdqqwcw/sql/new
      and Run
- [ ] Frontend deployed to a Vercel preview from the branch
- [ ] Two test inspector accounts ready in firm A
      (e.g. `inspector.a1@mi109.test`, `inspector.a2@mi109.test`) and one in
      firm B (`inspector.b1@mi109.test`)
- [ ] One super_admin account ready (`profiles.firm_id IS NULL`,
      `role='super_admin'`)
- [ ] At least one `phase_submissions` row exists for firm A and one for
      firm B that the testing accounts can submit against (use one **fresh**
      submission for each test below — a submission already authorized in an
      earlier step will return `already_recorded` rather than `accepted`)

---

## Happy path (accepted authorization)

1. [ ] Log in as `inspector.a1@mi109.test`
2. [ ] Open the property in firm A whose phase requires a CS replacement
3. [ ] Open the relevant phase tile and check the **CS replacement** salient
       checkbox
4. [ ] Tap **Submit Phase**
5. [ ] **Carlo authorization modal opens** (modal must be the only path —
       there is no "submit anyway" button)
6. [ ] Default supervisor name is **Carlo Domenick** and is editable
7. [ ] Date and time inputs default to current and are editable
8. [ ] Reason textarea has a live character counter; submit button is
       **disabled until** reason length ≥ 20 chars
9. [ ] Fill all fields with a valid reason (≥ 20 chars), tap **Authorize**
10. [ ] Frontend combines its date + time into ISO 8601 (per NB3 client-side
        combine); RPC call goes out as `p_authorized_at:'YYYY-MM-DDTHH:MM:SS.sssZ'`
11. [ ] Envelope returns `{status:'accepted', authorization_id:<uuid>,
        error_code:null, message:<text>}`. Modal closes; phase submits;
        UI shows success state.
12. [ ] In Supabase SQL editor, run:
        ```sql
        SELECT count(*) FROM cs_replacement_authorizations
         WHERE phase_submission_id = '<phase_submission_id>';
        ```
        → expected: `1`
13. [ ] Run:
        ```sql
        SELECT id, prev_hash, row_hash, created_at
          FROM audit_log
         ORDER BY created_at DESC, id DESC
         LIMIT 1;
        ```
        → expected: newest row exists, `prev_hash` and `row_hash` are
        non-null and not the literal `'PENDING'` (chain trigger overwrote).
14. [ ] Run:
        ```sql
        SELECT prev_hash,
               (SELECT row_hash FROM audit_log
                 ORDER BY created_at DESC, id DESC OFFSET 1 LIMIT 1) AS predecessor_hash
          FROM audit_log
         ORDER BY created_at DESC, id DESC LIMIT 1;
        ```
        → expected: `prev_hash = predecessor_hash` (chain link). If
        `predecessor_hash` is NULL because the table was empty pre-insert,
        `prev_hash` should equal `'GENESIS'`.
15. [ ] Run:
        ```sql
        SELECT event_type, severity, source, correlation_id, details
          FROM compliance_events
         WHERE correlation_id = '<phase_submission_id>'
           AND source = 'MI-109'
         ORDER BY created_at DESC LIMIT 1;
        ```
        → expected: `event_type='cs_replacement.auth.accepted'`,
        `severity='alert'`, `source='MI-109'`,
        `details` is a jsonb object containing keys `phase_submission_id`,
        `supervisor`, `authorized_at`, `reason_length`, `status='accepted'`.

---

## Negative path 1 — reason too short (frontend gate)

16. [ ] Re-open the modal on a different (fresh) phase submission
17. [ ] Type a reason of < 20 characters
18. [ ] **Authorize** button is disabled (visually disabled, not clickable)
19. [ ] Erase reason entirely → button stays disabled
20. [ ] Type 20+ chars → button enables

## Negative path 2 — reason too short (backend gate, frontend bypassed)

21. [ ] In the browser devtools console, while authenticated as
        `inspector.a1`, call:
        ```js
        await sb.rpc('submit_cs_authorization', {
          p_phase_submission_id: '<fresh_phase_submission_id>',
          p_supervisor_name: 'Carlo Domenick',
          p_authorized_at: new Date().toISOString(),
          p_reason: 'too short'
        })
        ```
22. [ ] Response is an envelope `{status:'rejected', authorization_id:null,
        error_code:'REASON_TOO_SHORT', message:<text>}`. **No exception is
        raised** — that's the envelope pattern (INV-1).
23. [ ] No row in `cs_replacement_authorizations` for that submission_id:
        ```sql
        SELECT count(*) FROM cs_replacement_authorizations
         WHERE phase_submission_id = '<fresh_phase_submission_id>';
        ```
        → `0`
24. [ ] `compliance_events` records the rejected event:
        ```sql
        SELECT event_type, details->>'error_code' AS error_code,
               details->>'status' AS status
          FROM compliance_events
         WHERE correlation_id = '<fresh_phase_submission_id>'
           AND source = 'MI-109'
         ORDER BY created_at DESC LIMIT 1;
        ```
        → expected: `cs_replacement.auth.rejected`, `REASON_TOO_SHORT`,
        `rejected`.

## Negative path 3 — missing supervisor name

25. [ ] In the modal, clear supervisor name to empty string and type valid
        reason + date + time
26. [ ] **Authorize** disabled (frontend validation prevents submit)
27. [ ] If bypassed via devtools (`p_supervisor_name: ''`), envelope
        is `{status:'rejected', error_code:'SUPERVISOR_EMPTY', ...}`

## Negative path 4 — AUTH_DENIED for non-authorized role

28. [ ] Log in as a user whose `profiles.role` is not permitted to authorize
        (e.g. a read-only office staff role; create one as
        `staff.a1@mi109.test` if not present)
29. [ ] Trigger the modal (or call the RPC via devtools)
30. [ ] RPC **raises** with `SQLSTATE='42501'` and message starting
        `'AUTH_DENIED:'`. UI shows a permission-denied message.
31. [ ] **Note:** AUTH_DENIED rolls back the in-flight transaction, so
        `compliance_events` does NOT record the AUTH_DENIED attempt — this
        is the accepted security-boundary trade-off per INV-1. If the
        product later wants AUTH_DENIED telemetry, it must be added via an
        out-of-transaction logger; flag a follow-up ticket if relevant.

## Negative path 5 — duplicate (already_recorded)

32. [ ] Take the `phase_submission_id` from the happy path (Step 11) — it
        already has a recorded authorization
33. [ ] In devtools as `inspector.a1`:
        ```js
        await sb.rpc('submit_cs_authorization', {
          p_phase_submission_id: '<happy_path_phase_submission_id>',
          p_supervisor_name: 'Carlo Domenick',
          p_authorized_at: new Date().toISOString(),
          p_reason: 'Duplicate retry — RPC must surface already_recorded.'
        })
        ```
34. [ ] Envelope is `{status:'already_recorded', authorization_id:<uuid>,
        error_code:'ALREADY_RECORDED', message:<text>}`. The
        `authorization_id` is the **existing** row's id (recoverable from
        the 23505 catch path).
35. [ ] No new row in `cs_replacement_authorizations` (count for that
        submission_id remains `1`).
36. [ ] `compliance_events` records the duplicate:
        ```sql
        SELECT event_type,
               details->>'error_code' AS error_code,
               details->>'existing_authorization_id' AS existing_id
          FROM compliance_events
         WHERE correlation_id = '<happy_path_phase_submission_id>'
           AND source = 'MI-109'
         ORDER BY created_at DESC LIMIT 1;
        ```
        → expected: `cs_replacement.auth.duplicate`, `ALREADY_RECORDED`,
        `existing_id` matches the `authorization_id` returned on the
        original happy-path call.

## Negative path 6 — network failure mid-submit

37. [ ] In the modal as `inspector.a1`, fill all fields validly
38. [ ] Open devtools → Network → set throttling to **Offline**
39. [ ] Tap **Authorize**
40. [ ] UI shows a retry/error state without crashing
41. [ ] Set throttling back online; retry. Two acceptable outcomes per
        idempotency design:
        - If the first call never reached the server → retry returns
          `accepted`, exactly one row exists in
          `cs_replacement_authorizations`.
        - If the first call landed but the response was lost → retry
          returns `already_recorded`; still exactly one row exists.
        Verify only one row exists.

---

## Cross-firm isolation (manual mirror of rls_test.sql)

42. [ ] Log in as `inspector.b1` (firm B)
43. [ ] Manually craft a devtools call to authorize a firm-A
        `phase_submission_id` (firm A's id is known to the tester):
        ```js
        await sb.rpc('submit_cs_authorization', {
          p_phase_submission_id: '<firm_A_phase_submission_id>',
          p_supervisor_name: 'Carlo Domenick',
          p_authorized_at: new Date().toISOString(),
          p_reason: 'Cross-firm attack attempt — should be denied by RLS.'
        })
        ```
44. [ ] RPC denies. Two acceptable outcomes per INV-NB11:
        - Envelope `{status:'rejected', error_code:'FORBIDDEN_CROSS_FIRM' or
          'PHASE_SUBMISSION_NOT_FOUND', ...}`, OR
        - RAISE with `SQLSTATE='42501'`, message `'AUTH_DENIED:...'`
45. [ ] No row in `cs_replacement_authorizations` for the firm-A submission.

---

## Super_admin override path

46. [ ] Log in as super_admin (`profiles.firm_id IS NULL`)
47. [ ] Open a firm-B phase submission (fresh, no prior authorization)
        and trigger the CS-replacement modal
48. [ ] Authorize with valid fields → envelope `{status:'accepted', ...}`
49. [ ] Verify the inserted `cs_replacement_authorizations.firm_id` =
        firm B (matches the underlying `phase_submissions.firm_id`,
        not NULL):
        ```sql
        SELECT firm_id FROM cs_replacement_authorizations
         WHERE phase_submission_id = '<firm_B_phase_submission_id>'
         ORDER BY created_at DESC LIMIT 1;
        ```
        → expected: `<firm_B_uuid>`
50. [ ] `compliance_events` row for the accepted authorization has
        `correlation_id` = the firm-B `phase_submission_id` and
        `source='MI-109'`.

---

## Sign-off

- [ ] All boxes above checked
- [ ] Screenshots of (a) the modal happy path and (b) the SQL row deltas
      attached to the PR
- [ ] STATE.md updated to reflect MI-109 Phase 2 closure

**Reviewer:** ___________
**Date:** ___________
