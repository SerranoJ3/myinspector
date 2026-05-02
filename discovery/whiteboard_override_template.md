# whiteboard_override_log + record_whiteboard_override — production template dump

> **Why this file exists:** MI-109 Phase 2 backend builds `cs_replacement_authorizations` + `submit_cs_authorization` modeled verbatim on the shipped whiteboard override pattern (MI-202). Before drafting the migration, we pull the live shape of the template so the new objects match exactly — column types, constraints, RLS policies, grants, triggers, and the RPC's auth/fallback structure.
>
> **Status:** Q1–Q10 raw query results **UNAVAILABLE** — three chat-layer truncation attempts ate the dump payload before it could reach the lead. Jorge has provided architectural takeaways in lieu of raw DDL/source. Backend builds from those + the brief; anything beyond what the notes name (column shapes, RLS USING/WITH CHECK expressions, `record_whiteboard_override` exact source) is **INVENTED** and must be flagged in the Inventions section at the bottom.
>
> The `### Q? — Result` placeholders below are kept intact as visible markers that the raw dump did not land. The **Architectural Notes from Jorge** section at the bottom is authoritative for what backend works from.

---

## Q1 — Source of `record_whiteboard_override`

```sql
SELECT pg_get_functiondef('public.record_whiteboard_override'::regproc);
```

### Q1 — Result
<!-- paste pg_get_functiondef output here -->

---

## Q2 — Columns of `whiteboard_override_log`

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema='public' AND table_name='whiteboard_override_log'
ORDER BY ordinal_position;
```

### Q2 — Result
<!-- paste rows here -->

---

## Q3 — Constraints on `whiteboard_override_log`

```sql
SELECT con.conname,
  CASE con.contype WHEN 'p' THEN 'PRIMARY KEY' WHEN 'f' THEN 'FOREIGN KEY'
                   WHEN 'u' THEN 'UNIQUE' WHEN 'c' THEN 'CHECK'
                   ELSE con.contype::text END AS type,
  pg_get_constraintdef(con.oid) AS def
FROM pg_constraint con
JOIN pg_class cls ON cls.oid=con.conrelid
JOIN pg_namespace ns ON ns.oid=cls.relnamespace
WHERE ns.nspname='public' AND cls.relname='whiteboard_override_log';
```

### Q3 — Result
<!-- paste rows here -->

---

## Q4 — Indexes on `whiteboard_override_log`

```sql
SELECT i.relname, pg_get_indexdef(i.oid)
FROM pg_index x
JOIN pg_class i ON i.oid=x.indexrelid
JOIN pg_class t ON t.oid=x.indrelid
JOIN pg_namespace ns ON ns.oid=t.relnamespace
WHERE ns.nspname='public' AND t.relname='whiteboard_override_log';
```

### Q4 — Result
<!-- paste rows here -->

---

## Q5 — RLS state + policies on `whiteboard_override_log`

```sql
SELECT 'rls_state' AS kind, NULL::text AS name,
  format('enabled=%s, forced=%s', c.relrowsecurity, c.relforcerowsecurity) AS detail,
  NULL::text AS expr
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname='whiteboard_override_log'
UNION ALL
SELECT 'policy', polname,
  format('cmd=%s, mode=%s, roles=%s',
    CASE polcmd WHEN 'r' THEN 'SELECT' WHEN 'a' THEN 'INSERT'
                WHEN 'w' THEN 'UPDATE' WHEN 'd' THEN 'DELETE' WHEN '*' THEN 'ALL' END,
    CASE WHEN polpermissive THEN 'PERMISSIVE' ELSE 'RESTRICTIVE' END,
    array_to_string(ARRAY(SELECT rolname FROM pg_roles WHERE oid=ANY(polroles)),', ')),
  format('USING (%s) WITH CHECK (%s)',
    COALESCE(pg_get_expr(polqual,polrelid),'—'),
    COALESCE(pg_get_expr(polwithcheck,polrelid),'—'))
FROM pg_policy WHERE polrelid='public.whiteboard_override_log'::regclass;
```

### Q5 — Result
<!-- paste rows here -->

---

## Q6 — Grants on `whiteboard_override_log`

```sql
SELECT grantee, privilege_type, is_grantable
FROM information_schema.role_table_grants
WHERE table_schema='public' AND table_name='whiteboard_override_log'
ORDER BY grantee, privilege_type;
```

### Q6 — Result
<!-- paste rows here -->

---

## Q7 — Triggers on `whiteboard_override_log`

```sql
SELECT tgname, pg_get_triggerdef(t.oid) AS def
FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid
JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relname='whiteboard_override_log' AND NOT t.tgisinternal;
```

### Q7 — Result
<!-- paste rows here -->

---

## Q8 — Columns of `audit_log` (audit chain target — answers PR #2's prev_hash/current_hash question)

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema='public' AND table_name='audit_log'
ORDER BY ordinal_position;
```

### Q8 — Result
<!-- paste rows here -->

---

## Q9 — Source of `write_audit_log` and any related audit trigger functions

```sql
SELECT n.nspname AS schema, p.proname AS name, pg_get_functiondef(p.oid) AS definition
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname IN ('write_audit_log', 'audit_log_chain_trigger', 'log_audit', 'append_audit_log', 'audit_log_append')
ORDER BY p.proname;
```

### Q9 — Result
<!-- paste rows here -->

---

## Q10 — All triggers on `audit_log` (the chain hash trigger lives here)

```sql
SELECT tgname, pg_get_triggerdef(t.oid) AS def
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname='public' AND c.relname='audit_log' AND NOT t.tgisinternal;
```

### Q10 — Result
<!-- paste rows here -->

---

## Architectural Notes from Jorge (Q1–Q10 takeaways — authoritative)

> **Note 1:** TRUNCATED — chat layer ate the leading content. If note 1 turns out to be load-bearing, backend SendMessages "lead" to recover it on demand.

**Note 2 — audit_log integration mechanism:** [...trigger computes the hash.] Backend just needs to: (a) attach audit triggers to `cs_replacement_authorizations` like other Owner Data tables, (b) **NOT touch `audit_log` from the RPC**. PR #2's failure was trying to write `audit_log` directly with a wrong hash encoding.

**Note 3 — audit_log hash columns:** `prev_hash` and `row_hash` are NOT NULL on `audit_log`. `write_audit_log` inserts placeholder `'PENDING'` values knowing the BEFORE INSERT trigger overwrites with the real hash. **Don't compute the hash anywhere else — let the trigger do it.** (Note: PR #2's `current_hash` naming was wrong — production uses `row_hash`.)

**Note 4 — anon-grant posture (match-existing):** `anon` and `authenticated` both have `SELECT / REFERENCES / TRIGGER / TRUNCATE` but **NO `INSERT / UPDATE / DELETE`**. Only `postgres` + `service_role` have write privileges. This is the "INSERT-only via grants" pattern in production. Mirror exactly on `cs_replacement_authorizations`.

**Note 5 — immutability mechanism:** No UPDATE/DELETE triggers on `audit_log` itself — immutability is GRANT-enforced (only `postgres` can UPDATE/DELETE). `cs_replacement_authorizations` follows the same pattern: **grants block writes, RLS gates SELECT.** Do NOT add a BEFORE UPDATE/DELETE trigger that raises an exception.

---

### Authoritative directives banked from lead↔Jorge thread

- UNIQUE constraint on `cs_replacement_authorizations(phase_submission_id)` for retry safety
- RPC catches 23505 (unique_violation) and surfaces it as `CS_AUTH_ALREADY_RECORDED`
- Severity for `record_compliance_event` calls = `'alert'` (not `'warn'`)
- Phase 3 deferral: do NOT bake permanent legal hold or revoke triggers; INSERT-only-via-grants is the most reversible default
- View posture (CLAUDE.md principle #7): if any view is created, it MUST use `security_invoker = true` — but this migration should not need any views

---

## Inventions made during build (backend MUST populate as it works)

> Anything backend implements that wasn't explicitly named in the architectural notes above is an **INVENTION**. List each here with a one-line justification + a verification path so post-build queries can confirm against production. Mirror this section in the migration file's header comment so the inventions are visible to the reviewer (Jorge) before merge.

### Pre-build escalation (load-bearing — need lead/Jorge call BEFORE migration is drafted)

> **Status:** chat channel dropped 3 message bodies. File channel from here on per lead's directive. Backend will NOT touch the migration until INV-1, INV-2, INV-3 are resolved.
> **NB1–NB13** below are non-load-bearing — backend will proceed with these defaults unless lead objects.

---

INVENTION #1: RPC return shape (uuid vs JSONB envelope) — **Contract 4 blocker**
- What it is: Whether `submit_cs_authorization` returns `uuid` (RAISE EXCEPTION on validation/auth failures) or `jsonb` envelope (`{status:'accepted'|'rejected'|'already_recorded', authorization_id?, error_code?, message?}`).
- Why it's load-bearing: A RAISE inside the RPC rolls back the same-transaction `record_compliance_event` INSERT. MI-109 spec requires "audit every attempt — successful AND rejected." If we RAISE on validation failure, rejection events do NOT persist (Postgres has no clean autonomous-transaction primitive). Schema redo cost: function signature change + frontend rewrite + tests' Contract 4 rewrite. Tests are already shipped v1 with TODO markers waiting on this.
- Depends on: `record_whiteboard_override` source (Q1 — UNAVAILABLE) OR Jorge directive.
- Specific call needed from lead/Jorge: **Recommend (B) jsonb envelope.** Reason: only shape that satisfies "audit every attempt" without out-of-transaction logging. Auth-denied (security boundary, not validation) still RAISEs. 23505 retry path → `status:'already_recorded'` envelope. Authorize (B), or override with rationale + a plan for how rejection audit logging survives the RAISE.

---

INVENTION #2: RLS policy expression for `cs_replacement_authorizations`
- What it is: Exact `USING` / `WITH CHECK` expression. Backend's proposal:
  ```
  USING (
    firm_id = (SELECT firm_id FROM profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  )
  ```
- Why it's load-bearing: Wrong expression = cross-firm leak (CLAUDE.md principle #4 violation, same class as the MI-201 leak that just shipped). If `whiteboard_override_log` uses a SECURITY DEFINER helper (e.g. `current_user_firm_id()`) for performance + SQL-Editor fallback, an inline subquery diverges from established pattern. Also: wrong super_admin column name = super_admin loses cross-firm access entirely.
- Depends on: Q5 (`whiteboard_override_log` policy expressions — UNAVAILABLE) OR Jorge directive on (a) helper-vs-inline subquery, (b) exact super_admin column/value (`profiles.role = 'super_admin'` vs alternative).
- Specific call needed from lead/Jorge: Confirm (a) inline `profiles` subquery is acceptable (matches whiteboard_override_log pattern), (b) `profiles.role = 'super_admin'` is correct. If either differs, paste the correct expression and backend matches verbatim.

---

INVENTION #3: `gen_random_uuid()` qualification convention
- What it is: Whether to write `extensions.gen_random_uuid()` (schema-qualified) or bare `gen_random_uuid()` (relying on `search_path = public, extensions, pg_temp` per CLAUDE.md).
- Why it's load-bearing: If pgcrypto isn't on the migration session's search_path at run time, bare call fails and every INSERT errors. Less catastrophic than #1/#2 — deployment-time error caught immediately on first INSERT — but still schema redo if the default has to be ALTERed later. Worth one-shotting correctly.
- Depends on: `whiteboard_override_log` column default for `id` (Q2 — UNAVAILABLE) OR Jorge convention directive.
- Specific call needed from lead/Jorge: **Default to `extensions.gen_random_uuid()` (qualified).** Authorize, or paste the convention from `whiteboard_override_log.id` default if it differs.

---

### Non-load-bearing inventions (proceeding unless lead objects)

- **INV-NB1:** `authorizing_supervisor text NOT NULL DEFAULT 'Carlo Domenick'`. Source: brief.
- **INV-NB2:** `reason text NOT NULL CHECK (length(reason) >= 20)`. Source: brief ("min ~20 chars").
- **INV-NB3:** Date + time as **separate columns** (`authorization_date date`, `authorization_time time`). Brief explicitly says date AND time fields, so going with separate.
- **INV-NB4:** `submitted_by uuid REFERENCES auth.users(id)` (nullable to allow SQL Editor fallback path).
- **INV-NB5:** `firm_id uuid REFERENCES firms(id)` NULLABLE (super_admin per CLAUDE.md).
- **INV-NB6:** `created_at timestamptz NOT NULL DEFAULT now()`.
- **INV-NB7:** UNIQUE constraint on `(phase_submission_id)` — already authorized in lead's prior message.
- **INV-NB8:** NO separate `CREATE INDEX` on `(phase_submission_id)` (UNIQUE provides it) and NO separate index on `(firm_id)` (zero rows; let MI-204 cover firm_id indexing as a pattern later).
- **INV-NB9:** NO separate `CREATE INDEX` on `(created_at)` either — defer until query patterns emerge.
- **INV-NB10:** Compliance event call shape:
  - `p_event_type='cs_replacement.auth.accepted'` | `'cs_replacement.auth.rejected'` | `'cs_replacement.auth.duplicate'`
  - `p_severity='alert'` (per banked directive)
  - `p_source='MI-109'`
  - `p_correlation_id = phase_submission_id::text`
  - `p_message` = human-readable, e.g. `'CS replacement authorization accepted by Carlo Domenick on 2026-05-01 at 14:30'`
  - `p_details` = jsonb: `{phase_submission_id, supervisor, authorized_at, reason_length, status, error_code (if rejected)}` — updated per NB3 override (single `authorized_at` replaces date+time split)
- **INV-NB11:** Validation error codes (in jsonb envelope `error_code` field): `REASON_TOO_SHORT`, `SUPERVISOR_EMPTY`, `PHASE_SUBMISSION_NOT_FOUND`, `FORBIDDEN_CROSS_FIRM` (if RLS-equivalent check needed inside RPC), `ALREADY_RECORDED`. Validation errors return rejected envelope; auth-denied RAISEs `AUTH_DENIED:...` with ERRCODE `'insufficient_privilege'`.
- **INV-NB12:** Audit triggers on `cs_replacement_authorizations` mirror whatever triggers exist on other Owner Data tables. Backend will attach the same `write_audit_log` trigger(s). Trigger function name assumed `write_audit_log` per CLAUDE.md / lead's note 2; if production trigger has a different name (e.g. `audit_owner_data_trigger`), lead flags and backend matches.
- **INV-NB13:** Migration filename uses UTC timestamp `YYYYMMDDHHMMSS` per brief — generated from current UTC at write time.

---

### Decision log (resolved 2026-05-02 session open)

- **INV-1 — RPC return shape:** **(B) JSONB envelope.** Schema:
  ```
  {
    status: 'accepted' | 'rejected' | 'already_recorded',
    authorization_id: uuid | null,    // present when status='accepted'; may be present on 'already_recorded' (existing row's id)
    error_code: text | null,          // present when status='rejected' or 'already_recorded' — values per INV-NB11
    message: text | null              // human-readable, always present
  }
  ```
  Auth-denied still RAISEs `AUTH_DENIED:` with ERRCODE `'insufficient_privilege'` (security boundary, not validation). 23505 on the UNIQUE(phase_submission_id) constraint is caught and surfaced as `status:'already_recorded'` with `error_code='ALREADY_RECORDED'` and the existing `authorization_id` if recoverable.

- **INV-2 — RLS policy expression:** Backend's proposed expression **verbatim**:
  ```sql
  USING (
    firm_id = (SELECT firm_id FROM profiles WHERE id = auth.uid())
    OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
  )
  ```
  Apply same expression as `WITH CHECK` clause for INSERT-time enforcement.

- **INV-3 — uuid generator:** **Qualified `extensions.gen_random_uuid()`** for the `id` column default.

- **NB3 override — single timestamp:** Column `authorized_at timestamptz NOT NULL` (replaces split `authorization_date date` + `authorization_time time`). RPC parameter `p_authorized_at timestamptz` (replaces `p_authorization_date` + `p_authorization_time`).

- **Frontend follow-up — NB3 client-side combine:** Option A. Frontend combines its date + time inputs into a single ISO 8601 string client-side (`new Date(date + 'T' + time).toISOString()`) and passes as `p_authorized_at`. RPC stays clean; no `make_timestamp(...)` server-side combine. Frontend revise-edit briefed in parallel.

- **NB1, NB2, NB4-NB13:** All approved as backend proposed (no objections).

