# Title

feat: MI-109 CS Replacement Authorization Gate

# Body

## Summary
- Implements CDM-Smith compliance rule (c) — every CS replacement requires Carlo authorization with audit logging on every attempt (accepted, rejected, already_recorded). No exception path.
- Backend: new `cs_replacement_authorizations` table (Owner Data, RLS forced + FORCE, INSERT-only via grants, audit-chained via `write_audit_log_trg`) + `cs_replacement` flag on `phase_submissions` + in-database `submit_cs_authorization` SECURITY DEFINER RPC returning a JSONB envelope.
- Frontend (`index.html`): salient checkbox + Carlo modal that gates `submitPhase()`.
- Tests: SQL RLS + audit-integrity tests, plus a 50-step manual E2E checklist with verification queries.

## Audit chain reconciliation — verified
All items below resolved during Phase 1 (5/1) and Phase 4 backend verification (5/2 late). See STATE.md.
- ✅ `audit_log` columns confirmed: `prev_hash`, `row_hash`, `created_at`, `id` (NOT `current_hash`)
- ✅ `profiles.firm_id` confirmed canonical firm-isolation column (nullable for super_admin — RLS predicates handle the NULL branch explicitly)
- ✅ `pgcrypto` v1.3 confirmed in `extensions` schema; functions using `digest()` / `gen_random_uuid()` `SET search_path` to include `extensions`
- ✅ Compliance event logging uses `public.record_compliance_event` (6-arg signature: `p_event_type, p_message, p_severity, p_details, p_source, p_correlation_id`, banked CLAUDE.md). **No `audit_log_append` RPC exists or is needed** — the audit chain is automatic via the `write_audit_log` AFTER trigger on every Owner Data table.
- ✅ Canonical encoding for the hash chain: a BEFORE INSERT trigger on `audit_log` overwrites the `'PENDING'` placeholders written by `write_audit_log` with the real `prev_hash` + `row_hash` values. Verified by `tests/mi109/audit_integrity_test.sql` step 5 (no `'PENDING'` values remain on the new row).

## Test plan
Backend verified 5/2 late. Frontend e2e + merge are what's left.
- ✅ Migration applied to staging via Supabase dashboard SQL editor (`supabase/migrations/20260502013854_mi109_cs_auth.sql`). **NOT** `supabase db push` — see migration header note.
- ✅ Post-deploy sanity queries: RLS forced + FORCE on `cs_replacement_authorizations`; anon/authenticated grants limited to `REFERENCES,SELECT,TRIGGER,TRUNCATE` (Note 4 grant model clean, no INSERT/UPDATE/DELETE leak); `write_audit_log_trg` attached; RPC signature `(uuid, text, timestamptz, text)` exact.
- ✅ `tests/mi109/rls_test.sql` against staging as `postgres` — 9/9 PASS (all 9 assertions cleared without RAISE EXCEPTION).
- ✅ `tests/mi109/audit_integrity_test.sql` against staging as `postgres` — 8/8 PASS. **Real bug caught and fixed during the run:** test step 3b expected `audit_log delta=+1` but actual is `+2` because both Owner Data writes audit (cs_auth INSERT + phase_submissions UPDATE) per CLAUDE.md chain layer 2. Test corrected; expectation now matches the audit chain spec.
- [ ] Walk all 50 boxes in `tests/mi109/e2e_checklist.md` against the Vercel preview from `mi-109-rpc-rebuild` branch (Happy 1-15, Negatives 16-41, Cross-firm 42-45, Super_admin 46-50).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
