# MI-109 — End-to-End Manual Checklist

> Walk this against staging (or local supabase serve). Every box must be checked
> before merging the PR. Failed boxes get filed as new tickets and hold the
> merge.

**Spec source:** CDM-Smith email rule (c) — every CS replacement on a phase
submission requires Carlo authorization (date + time + reason ≥ 20 chars +
supervisor name). NO EXCEPTION path. Audit log every attempt.

**Backend contract under test:**
- Postgres RPC `public.submit_cs_authorization(p_submission_id uuid,
  p_supervisor_name text, p_authorized_date date, p_authorized_time time,
  p_reason text)` (SECURITY DEFINER)
- Side effects on accept: row in `cs_replacement_authorizations`, row in
  `audit_log` (Layer-3 trigger), row in `compliance_events`
  (`event_type='cs_replacement.auth.accepted'`, `severity='alert'`,
  `source='MI-109'`, `correlation_id=submission_id::text`)
- Side effect on reject: row in `compliance_events`
  (`event_type='cs_replacement.auth.rejected'`)

**TODO when discovery dump lands:**
- **[Q1]** Confirm whether rejection log survives RAISE EXCEPTION (envelope vs
  exception pattern) — if envelope, leave the rejection-event assertions in
  place; if exception, mark Step 11 as "informational, not enforced".
- **[Q8-Q10]** Add a chain-link verification to Step 9 (compute prev_hash on
  the new audit_log row, compare to current_hash on the previous row).

---

## Pre-flight

- [ ] Migration applied to staging (`supabase db push` from
      `mi-109-rpc-rebuild` branch)
- [ ] Frontend deployed to a Vercel preview from the branch
- [ ] Two test inspector accounts ready in firm A
      (e.g. `inspector.a1@mi109.test`, `inspector.a2@mi109.test`) and one in
      firm B (`inspector.b1@mi109.test`)
- [ ] One super_admin account ready (`profiles.firm_id IS NULL`,
      `role='super_admin'`)
- [ ] At least one `phase_submissions` row exists for firm A and one for
      firm B that the testing accounts can submit against

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
7. [ ] Date and time pickers default to current and are editable
8. [ ] Reason textarea has a live character counter; submit button is
       **disabled until** reason length ≥ 20 chars
9. [ ] Fill all fields with a valid reason (≥ 20 chars), tap **Authorize**
10. [ ] Modal closes; phase submits; UI shows success state
11. [ ] In Supabase SQL editor, run:
       ```sql
       SELECT count(*) FROM cs_replacement_authorizations
        WHERE submission_id = '<phase_submission_id>';
       ```
       → expected: `1`
12. [ ] Run:
       ```sql
       SELECT count(*) FROM audit_log
        WHERE created_at > now() - interval '5 minutes';
       ```
       → expected: incremented by ≥ 1 (Layer-3 trigger fired)
13. [ ] Run:
       ```sql
       SELECT event_type, severity, source, correlation_id
         FROM compliance_events
        WHERE correlation_id = '<phase_submission_id>'
          AND source = 'MI-109'
        ORDER BY created_at DESC
        LIMIT 1;
       ```
       → expected: `event_type='cs_replacement.auth.accepted'`, `severity='alert'`,
       `source='MI-109'`

---

## Negative path 1 — reason too short (frontend gate)

14. [ ] Re-open the modal on a different phase submission (or after server
        reset)
15. [ ] Type a reason of < 20 characters
16. [ ] **Authorize** button is disabled (visually disabled, not clickable)
17. [ ] Erase reason entirely → button stays disabled
18. [ ] Type 20+ chars → button enables

## Negative path 2 — reason too short (backend gate, frontend bypassed)

19. [ ] In the browser devtools console, while authenticated as
        `inspector.a1`, call:
        ```js
        await sb.rpc('submit_cs_authorization', {
          p_submission_id: '<phase_submission_id>',
          p_supervisor_name: 'Carlo Domenick',
          p_authorized_date: '2026-05-01',
          p_authorized_time: '14:30',
          p_reason: 'too short'
        })
        ```
20. [ ] Response surfaces an error (envelope or exception per Q1 outcome).
        Either way, no row appears in `cs_replacement_authorizations` for
        that submission_id.
21. [ ] **(Conditional on Q1)** Run:
        ```sql
        SELECT event_type FROM compliance_events
         WHERE correlation_id = '<phase_submission_id>'
           AND source = 'MI-109'
         ORDER BY created_at DESC LIMIT 1;
        ```
        → expected: `cs_replacement.auth.rejected`. If this row is absent,
        record Q1 outcome as pattern (i) and file a follow-up ticket on the
        rejection-log durability decision.

## Negative path 3 — missing supervisor name

22. [ ] In the modal, clear supervisor name to empty string and type valid
        reason + date + time
23. [ ] **Authorize** disabled (frontend validation prevents submit)
24. [ ] If bypassed via devtools (`p_supervisor_name: ''`), the RPC rejects
        with a VALIDATION_ message (or envelope error)

## Negative path 4 — AUTH_DENIED for non-authorized role

25. [ ] Log in as a user whose `profiles.role` is not permitted to authorize
        (e.g. a read-only office staff role; create one as
        `staff.a1@mi109.test` if not present)
26. [ ] Trigger the modal (or call the RPC via devtools)
27. [ ] RPC raises with `SQLSTATE='42501'` and message starts with
        `'AUTH_DENIED:'`. UI shows a permission-denied message
28. [ ] **(Conditional on Q1)** `compliance_events` records a rejected row
        with the AUTH_DENIED reason in `details`

## Negative path 5 — network failure mid-submit

29. [ ] In the modal as `inspector.a1`, fill all fields validly
30. [ ] Open devtools → Network → set throttling to **Offline**
31. [ ] Tap **Authorize**
32. [ ] UI shows a retry/error state without crashing
33. [ ] Set throttling back online; retry → succeeds (idempotency
        consideration: if the previous attempt did partially commit, the
        retry must not produce a duplicate row — verify only one row exists
        in `cs_replacement_authorizations` for that submission_id)

---

## Cross-firm isolation (manual mirror of rls_test.sql)

34. [ ] Log in as `inspector.b1` (firm B)
35. [ ] Manually craft a devtools call to authorize a firm-A
        `phase_submission_id` (firm A's id is known to the tester):
        ```js
        await sb.rpc('submit_cs_authorization', {
          p_submission_id: '<firm_A_phase_submission_id>',
          p_supervisor_name: 'Carlo Domenick',
          p_authorized_date: '2026-05-01',
          p_authorized_time: '14:30',
          p_reason: 'Cross-firm attack attempt — should be denied by RLS.'
        })
        ```
36. [ ] RPC fails (errcode 42501 or AUTH_DENIED). No row in
        `cs_replacement_authorizations` for the firm-A submission.

---

## Super_admin override path

37. [ ] Log in as super_admin (`profiles.firm_id IS NULL`)
38. [ ] Open a firm-B phase submission and trigger the CS-replacement
        modal
39. [ ] Authorize with valid fields → succeeds
40. [ ] Verify the inserted `cs_replacement_authorizations.firm_id` =
        firm B (i.e. matches the underlying `phase_submissions.firm_id`,
        not NULL):
        ```sql
        SELECT firm_id FROM cs_replacement_authorizations
         WHERE submission_id = '<firm_B_phase_submission_id>'
         ORDER BY created_at DESC LIMIT 1;
        ```
        → expected: `<firm_B_uuid>`
41. [ ] `compliance_events` row for the accepted authorization has
        `correlation_id` = the firm-B `phase_submission_id`

---

## Sign-off

- [ ] All boxes above checked
- [ ] No items left as "informational" without an open follow-up ticket
- [ ] Screenshots of (a) the modal happy path and (b) the SQL row deltas
      attached to the PR
- [ ] STATE.md updated to reflect MI-109 Phase 2 closure

**Reviewer:** ___________
**Date:** ___________
