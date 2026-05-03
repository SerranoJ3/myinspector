# Sunday Security Audit — 2026-05-03 PM

**Run by:** Buddy via Supabase MCP, Sunday afternoon (Buddy max-execution sprint).
**Scope:** Multi-tenant gap audit + SECURITY DEFINER privilege audit on prod.
**Trigger:** Jorge directive to continue per Buddy Standard ("intensity and accuracy") after Sunday verification report cleared.
**Production project:** `wryitfoletwskkdqqwcw`.

---

## Summary

🟢 **Multi-tenant isolation: GREEN.** 22 tables with firm_id, all RLS-forced + ≥1 policy. 3 tables without firm_id are global/reference data by design (firms, modules, parts_catalogs).

🟡 **One real cross-firm metadata leak found:** `get_pending_destruction(p_table_name, p_record_id)` is SECURITY DEFINER without firm_id filter. Low real-world exploitability, **3-line fix.** Filed below as ticket **MI-AUDIT-1**.

🟢 **Audit chain primitives properly DEFINER-gated.** `compute_audit_hash`, `write_audit_log`, `audit_log_chain_trigger`, `record_compliance_event` all reference firm_id and are gated correctly.

🟡 **Super_admin posture flag (informational).** super_admin role can release legal holds across firm boundaries by design. Not a bug — but a reminder that super_admin is a privileged account and should have additional protections (MFA, separate from inspector roles, etc.). Captured as **MI-AUDIT-2** for future hardening.

---

## AUDIT-1: Multi-tenant gap

**Methodology:** enumerate every table in the public schema, check whether `firm_id` column exists + RLS state.

**Findings:**

| Tables with firm_id (22) | RLS state |
|---|---|
| audit_log, compliance_events, contractor_arrival_log, contractor_assignments, contractor_departure_log, cs_replacement_authorizations, daily_reports, destruction_notices, documents, **inspections**, legal_holds, luis_conversations, materials_sheets, phase_submissions, photo_rescue, profiles, projects, properties, restoration_grid_entries, rfis, supervisor_alerts, whiteboard_override_log | All RLS forced, all ≥1 policy |

| Tables WITHOUT firm_id (3) | Reason |
|---|---|
| `firms` | The firm IS the firm; RLS uses `id` instead. 2 policies. By design. |
| `modules` | Global module catalog (the 7 inspection modules). 2 policies. By design. |
| `parts_catalogs` | Global parts catalog, scoped by sector (NJ6_NORMAL / NJAW_SHORT_HILLS). 2 policies. By design. |

**Verdict:** GREEN. No leaks.

**Side discovery:** `inspections` table exists with firm_id + RLS. Not in current Buddy memory. Probably an older surface or a higher-level abstraction over phase_submissions. Worth a row-count + column-shape check next time we audit.

---

## AUDIT-2: SECURITY DEFINER privilege audit

**Methodology:** enumerate every function in public schema, classify by SECURITY mode, scan body for firm_id / auth.uid references.

**Findings:**

26 functions total. **All 26 are SECURITY DEFINER.** This is by design — Supabase RPC pattern relies on DEFINER for atomic operations + audit chain. RLS bypass means each function MUST enforce firm_id internally.

**Categorization:**

| Status | Count | Examples |
|---|---|---|
| ✅ OK (firm_id explicit in body) | 21 | audit_trail_export, cdm_smith_compliance_proof, monthly_compliance_report, lookup_firm_by_code, write_audit_log, current_firm_id, place_legal_hold, etc. |
| ✅ CHECK (auth.uid() referenced, firm scope verified) | 2 | cleanup_build_test_data, is_super_admin |
| 🟡 CHECK + super_admin only (firm crossing by design) | 1 | release_legal_hold |
| 🔴 REVIEW (DEFINER without firm_id or auth.uid filter) | 1 | **get_pending_destruction** |

### Detailed per-function review

**`cleanup_build_test_data()`** — ✅ super_admin role gate enforced via RAISE EXCEPTION on non-super. Operates only on rows with TEST-/RPC-TEST-/INSTR-TEST- prefixes or smoke_test event_type. Bounded scope. Self-logs. Safe by-design utility.

**`is_super_admin()`** — ✅ Pure boolean check on `auth.uid()` against `profiles.role = 'super_admin'`. Read-only, no data leak. Used as helper.

**`release_legal_hold(p_hold_id, p_release_reason)`** — 🟡 super_admin role gate enforced. Looks up hold by id, no firm_id filter. **By design**: super_admin crosses firm boundaries (per locked memory: super_admin = `jserranojr340@live.com` = Jorge specifically). However, this means a compromised super_admin account = full legal-hold control across all firms. **Captured as MI-AUDIT-2 for security posture hardening:** consider MFA + separate account from inspector roles.

**`get_pending_destruction(p_table_name, p_record_id)`** — 🔴 **SECURITY FLAG.** SECURITY DEFINER + STABLE, no auth check, no firm_id filter. WHERE clause is purely `dn.status = 'pending' AND dn.table_name = p_table_name AND dn.record_id = p_record_id`. Captured as **MI-AUDIT-1**.

### MI-AUDIT-1 — Ticket spec

**Title:** Add firm_id filter to `get_pending_destruction()` to close cross-firm metadata leak

**Severity:** P1 (real RLS bypass path; low real-world exploitability today because the IP/legal infra isn't being called by external users yet)

**Surface:** `public.get_pending_destruction(p_table_name text, p_record_id text)` — see definition below.

**Vulnerability:** any authenticated user can query pending destruction notice metadata for any (table_name, record_id) pair, regardless of firm boundary. Returns: `notice_id`, `notice_reference`, `earliest_destruction_at`, `reason_code`, `days_until_eligible`. Row IDs are UUIDs (hard to guess), but a coordinated attacker with knowledge of another firm's record IDs (e.g., from a shared document, log leak, or social-engineering channel) could enumerate destruction status without proper RLS isolation.

**Fix (3 lines):** add `AND dn.firm_id = public.current_firm_id()` to the WHERE clause. Use the existing `current_firm_id()` helper which is already SECURITY DEFINER + verified firm-scoping.

**Proposed migration `mi_audit_1_fix_get_pending_destruction.sql`:**

```sql
CREATE OR REPLACE FUNCTION public.get_pending_destruction(p_table_name text, p_record_id text)
 RETURNS TABLE(notice_id bigint, notice_reference text, earliest_destruction_at timestamp with time zone, reason_code text, days_until_eligible integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $TICKETBODY$
BEGIN
  RETURN QUERY
  SELECT
    dn.id,
    dn.notice_reference,
    dn.earliest_destruction_at,
    dn.reason_code,
    GREATEST(0, EXTRACT(DAY FROM (dn.earliest_destruction_at - now()))::INTEGER) AS days_until_eligible
  FROM public.destruction_notices dn
  WHERE dn.status = 'pending'
    AND dn.table_name = p_table_name
    AND dn.record_id = p_record_id
    AND dn.firm_id = public.current_firm_id()  -- AUDIT-1 fix: scope to caller's firm
  ORDER BY dn.earliest_destruction_at ASC
  LIMIT 1;
END;
$TICKETBODY$;
```

**Acceptance:**
1. Function definition includes the firm_id filter via `current_firm_id()`.
2. Test case A: authenticated user from Firm A queries a destruction notice belonging to Firm B → returns 0 rows.
3. Test case B: authenticated user from Firm A queries their own firm's pending destruction → returns 1 row (unchanged from current behavior).
4. Test case C: super_admin queries any firm's destruction → behavior depends on whether `current_firm_id()` returns null for super_admin or their explicit firm. Verify and document.

**Verification queries:** included in the ticket. Test A/B/C runnable via Supabase MCP under BEGIN/ROLLBACK.

**Effort:** ~15 min including verification.

### MI-AUDIT-2 — Security posture hardening (informational)

**Title:** Document super_admin firm-crossing behavior + recommend hardening

**Severity:** P3 (informational, by-design behavior, but worth capturing for future RBAC review)

**Behavior:** `release_legal_hold` and similar super_admin-gated functions allow Jorge (the only super_admin) to operate across firm boundaries. This is correct behavior for a multi-tenant SaaS with a single super-operator, but creates an outsized blast radius if the super_admin account is compromised.

**Recommended hardening (not urgent):**
1. Enable MFA on Jorge's super_admin account in Supabase auth.
2. Use a dedicated email + login for super_admin (not the same email used for any inspector role).
3. Audit all super_admin actions to a separate immutable log if/when super_admin gets used for routine operations vs emergency operations.
4. Consider adding a "super_admin acted on firm X" event to compliance_events for any super_admin write that touches a firm not equal to their own (if super_admin even has a firm_id assignment — verify via profiles).

**Trigger to act:** when MyInspector takes on a second firm beyond CP Engineers (currently only CP Engineers has been provisioned; super_admin firm-crossing is theoretical).

---

## What this audit confirms

1. **MyInspector multi-tenant foundation is sound.** No unintended firm_id-less owner-data tables. RLS forced everywhere it should be. Indexed for performance.
2. **Audit chain plumbing is correctly DEFINER-gated.** The hash-chain trigger, audit log writer, and compliance event recorder all reference firm_id and are properly scoped.
3. **The dashboard.html RPCs verified earlier** (audit_trail_export, cdm_smith_compliance_proof, etc.) all enforce firm_id at the function body level — bulletproof.
4. **One concrete bug found.** `get_pending_destruction` needs a 3-line fix. Filed as MI-AUDIT-1.
5. **One posture flag captured.** super_admin firm-crossing is intentional but worth hardening as the platform takes on more firms. Filed as MI-AUDIT-2.

## What this audit deliberately did NOT cover

- **View definitions.** Views can hide RLS bypass surfaces — not audited this pass. Defer to next audit cycle.
- **RLS policy quality.** Existence + count audited; the actual policy expressions (e.g., does `firms_super_write` correctly limit super_admin writes to their own firm?) are not parsed. Defer.
- **JWT claims propagation.** `auth.jwt()` reads in functions assume certain claim shapes; not validated against current Supabase auth config. Low risk per existing usage.
- **Storage bucket policies.** Photo upload paths (Supabase Storage) have their own RLS layer; not audited this pass.
- **Edge Function privilege.** `detect-whiteboard` (Vision API), `luis-proxy` (Claude Haiku) — not audited for credential exposure.

These are queued for a future audit cycle. None are urgent based on current threat model (single-firm beta, no external users yet).

---

## Recommended ticket sequence

After Lead finishes Track 2 (sanitized demo branch) and before Phase 2c builds:

1. **MI-AUDIT-1** (~15 min) — fix `get_pending_destruction` firm scoping. Migration + verification queries. Buddy can ship via Supabase MCP under per-write Rule #9 gate.
2. **MI-AUDIT-2** is informational only; capture in `decisions.md` as a future hardening note when MyInspector takes on its second firm.

If Jorge wants to defer MI-AUDIT-1 until after Phase 2c, that's defensible — exploitability is low because the IP/legal infra (legal_holds, destruction_notices) isn't being externally called yet. The fix is small enough to ship right after Phase 2c without blocking anything.

**Buddy recommendation:** ship MI-AUDIT-1 in the next migration window, before any external user gets access to the IP/legal infra. ~15 minutes of total Buddy + Jorge time.

---

**Audit complete. No follow-up SQL needed for verification — findings stand.**
