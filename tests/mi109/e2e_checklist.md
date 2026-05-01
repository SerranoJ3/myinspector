# MI-109 E2E Manual Test Checklist

**Ticket:** MI-109 — CS Replacement Authorization Gate
**Source rule:** CDM-Smith email rule (c) — "CS replacement = Carlo authorization (date + time + reason). NO EXCEPTION."
**Run against:** local Supabase, OR Vercel Preview pointed at staging Supabase. Do NOT run against production.

---

## Preconditions (one-time per test environment)

1. Logged into MyInspector as an inspector user (e.g. `justin.esteves@cpengineers.com`).
2. At least one property visible to the user's firm exists.
3. The MI-109 migration has been applied — verify with:
   ```sql
   SELECT column_name FROM information_schema.columns
    WHERE table_name = 'phase_submissions' AND column_name = 'cs_replacement';
   -- Expect 1 row.

   SELECT to_regclass('public.cs_replacement_authorizations');
   -- Expect: cs_replacement_authorizations (not NULL).
   ```
4. The `cs-auth-submit` edge function is deployed (`supabase functions list`).
5. Note the submission UUID at start of each scenario — frontend exposes it as
   `currentSubmissionUUID` in the JS console; or grab the most-recent
   `phase_submissions.id` for the test user after submit.

**Reusable verification queries** (used across scenarios):

```sql
-- Q1: phase_submissions row state for a given submission id
SELECT id, firm_id, phase, cs_replacement, submitted_by, last_client_sync_at
  FROM phase_submissions
 WHERE id = '<SUBMISSION_UUID>';

-- Q2: authorization row for a given submission id (0 or 1 expected)
SELECT id, submission_id, supervisor_name, authorized_date, authorized_time,
       reason, created_by, created_at
  FROM cs_replacement_authorizations
 WHERE submission_id = '<SUBMISSION_UUID>';

-- Q3: audit_log entries tied to a submission, in order
SELECT event_type, reason_code, actor_id, created_at, prev_hash, current_hash
  FROM audit_log
 WHERE row_id = '<SUBMISSION_UUID>'
    OR row_id IN (SELECT id FROM cs_replacement_authorizations
                   WHERE submission_id = '<SUBMISSION_UUID>')
 ORDER BY created_at ASC;
```

---

## Scenario A — Checkbox unchecked, existing flow works

**Goal:** Confirm MI-109 does not regress the normal submit path. `cs_replacement` stored as `false`.

**Steps:**
1. Open Submit Phase tab.
2. Select a property + service type that allows CS replacement (e.g. curbstop).
3. Leave "CS Replacement" checkbox **UNCHECKED**.
4. Fill required fields, attach whiteboard photo if excavation.
5. Tap Submit.

**Expected outcomes:**
- Toast: "Phase submitted successfully!" (or photo-syncing variant).
- No Carlo authorization modal appears.
- New row in `phase_submissions` with `cs_replacement = false`.
- No row in `cs_replacement_authorizations`.
- No `cs_auth_accepted` or `cs_auth_rejected` audit_log entries for this submission.

**Verify:**
- Run **Q1** → `cs_replacement = false`, row exists.
- Run **Q2** → 0 rows.
- Run **Q3** → no `cs_auth_*` rows (other audit rows from base submission OK).

---

## Scenario B — Checkbox checked, modal cancelled

**Goal:** Cancelling the Carlo modal must NOT submit the phase, but must log a `cs_auth_rejected` event.

**Steps:**
1. Open Submit Phase tab. Note `currentSubmissionUUID` from the JS console:
   ```js
   console.log(currentSubmissionUUID);
   ```
2. Fill the form; **CHECK** the "CS Replacement" checkbox.
3. Tap Submit.
4. Carlo authorization modal appears.
5. Tap Cancel (or close X).

**Expected outcomes:**
- Modal closes.
- No success toast. Inspector remains on Submit Phase tab with form data preserved.
- No row in `phase_submissions` for this attempt.
- No row in `cs_replacement_authorizations`.
- `audit_log` has one new row: `event_type='cs_auth_rejected'`, `reason_code='inspector_cancelled'`, `row_id` = the submission UUID.

**Verify:**
- Run **Q1** with the noted UUID → 0 rows (submission was not persisted).
- Run **Q2** with the noted UUID → 0 rows.
- Run **Q3** with the noted UUID → exactly 1 row with `event_type='cs_auth_rejected'` and `reason_code='inspector_cancelled'`.

---

## Scenario C — Checkbox checked, reason text < 20 characters

**Goal:** Server-side validation rejects short reason; modal stays open; `cs_auth_rejected` with `reason_code='validation_failure'` logged.

**Steps:**
1. Open Submit Phase tab. Note `currentSubmissionUUID`.
2. Fill the form; **CHECK** the "CS Replacement" checkbox.
3. Tap Submit. Modal opens.
4. Enter date (today), time (now), supervisor name (default "Carlo Domenick").
5. Enter reason: `too short` (9 chars).
6. Tap Authorize.

**Expected outcomes:**
- Modal stays open. Inline error appears under the reason field
  (e.g. "Reason must be at least 20 characters").
- No row in `phase_submissions`.
- No row in `cs_replacement_authorizations`.
- `audit_log` has one new row with `event_type='cs_auth_rejected'`,
  `reason_code='validation_failure'`, `row_id` = the submission UUID.
- Inspector can correct the reason and submit again (continues into Scenario D).

**Verify:**
- Run **Q1** → 0 rows.
- Run **Q2** → 0 rows.
- Run **Q3** → 1 row with `event_type='cs_auth_rejected'` and
  `reason_code='validation_failure'`.

---

## Scenario D — Checkbox checked, valid authorization

**Goal:** Happy path. `phase_submissions` saved with `cs_replacement=true`, auth row created, `cs_auth_accepted` audit row written, hash chain extended.

**Steps:**
1. Open Submit Phase tab. Note `currentSubmissionUUID`.
2. Fill the form; **CHECK** the "CS Replacement" checkbox.
3. Tap Submit. Modal opens.
4. Enter date (today), time (now), supervisor name "Carlo Domenick".
5. Enter reason: `Existing curbstop cracked beyond field repair; replacement required per inspector inspection.` (>= 20 chars).
6. Tap Authorize.

**Expected outcomes:**
- Modal closes. Success toast: "Phase submitted successfully!" (or sync variant).
- Row in `phase_submissions` with `cs_replacement = true`.
- Row in `cs_replacement_authorizations` with `submission_id = <UUID>`,
  `supervisor_name='Carlo Domenick'`, full reason text, `created_by` = current user.
- `audit_log` has one new row with `event_type='cs_auth_accepted'`,
  `row_id` = the new auth row's id.
- Hash chain advanced: `current_hash` of the new row = `sha256(prev_hash || canonical(payload))`.

**Verify:**
- Run **Q1** → `cs_replacement = true`.
- Run **Q2** → 1 row, all fields populated, `created_at` within last minute.
- Run **Q3** → 1 row with `event_type='cs_auth_accepted'`. Confirm `prev_hash`
  matches the previous row's `current_hash` (run hash chain verifier from
  `audit_integrity_test.sql` or eyeball with:
  ```sql
  SELECT id, event_type, prev_hash, current_hash
    FROM audit_log
   ORDER BY created_at DESC
   LIMIT 5;
  ```
  ).

---

## Scenario E — Re-attempt after a rejection

**Goal:** A prior rejection (Scenario B or C) must not block a subsequent fresh attempt. New attempt = new audit row; old row is preserved (audit_log immutable).

**Steps:**
1. Run Scenario C (validation_failure logged).
2. Without leaving the page, correct the reason to a valid 20+ char string.
3. Tap Authorize.

**Expected outcomes:**
- Submission succeeds (Scenario D outcomes).
- `audit_log` now has BOTH rows for this submission UUID:
  - the earlier `cs_auth_rejected` (`validation_failure`)
  - and the new `cs_auth_accepted`
- The rejected row was NOT deleted or mutated (immutability).
- Hash chain remains unbroken across both rows.

**Verify:**
- Run **Q3** with the submission UUID → at least 2 rows, both events present,
  ordered by `created_at`. The `cs_auth_accepted` row's `prev_hash` should
  match the `current_hash` of whatever row preceded it in the global chain
  (not necessarily the rejected row, since other inserts may have interleaved).
- Confirm rejected row's `current_hash` is unchanged from initial capture
  (record it after step 1 of Scenario C, re-query after step 3).

---

## Final smoke check after the suite

Run once at the end of the manual run:

```sql
-- Should return 0 rows; any orphan auth proves a bypass exists.
SELECT a.id, a.submission_id
  FROM cs_replacement_authorizations a
  LEFT JOIN phase_submissions p ON p.id = a.submission_id
 WHERE p.id IS NULL OR p.cs_replacement = false;

-- Every CS replacement submission must have exactly one auth row.
SELECT p.id
  FROM phase_submissions p
  LEFT JOIN cs_replacement_authorizations a ON a.submission_id = p.id
 WHERE p.cs_replacement = true
   AND a.id IS NULL;
-- Expect 0 rows. Any row here is a CDM-Smith compliance violation.
```

If either query returns rows, **STOP** — do not deploy. Escalate to Jorge.
