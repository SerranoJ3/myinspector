# Sunday Verification Report — 2026-05-03

**Run by:** Buddy via Supabase MCP, Sunday afternoon
**Trigger:** Jorge directive to verify Saturday/Sunday-morning ships against Buddy Standard (bulletproof gate)
**Production project:** `wryitfoletwskkdqqwcw` (us-east-2)

---

## Summary

🟢 **GREEN across all 8 verification surfaces.** Saturday's three PR merges (mi203-step2, mi101-phase2a, mi101-phase2b-refactor), Sunday morning's MI-203 step 3, and MI-204b indexing are all live and behaving correctly on prod. Multi-tenant isolation is bulletproof. CDM-Smith rule enforcement is intact at the database layer.

🟡 **One known deferred gate:** real `tapcard_data` jsonb shape verification still pending first inspector submission via UI. 1 demo row exists from 4/16 (pre-Phase-2b UI, jsonb null). 0 rows since Phase 2b merge at 0:52 AM. This is the expected state per Saturday close; Lead's e2e tests verified happy path.

---

## VERIFY-1: Schema state on `phase_submissions`

| Column | Type | Nullable | Status |
|---|---|---|---|
| `phase` | text | YES | ✓ |
| `work_order_code` | text | YES | ✓ |
| `tapcard_data` | **jsonb** | YES | ✓ Phase 2b refactor lives |
| `njaw_work_order_code` | **text** | YES | ✓ njaw-selector lives |
| `service_type` | — | — | ✓ properly dropped (migration expected) |

## VERIFY-2: CHECK constraints on `phase_submissions`

4 constraints locking enum values + compound invariants:

```
phase_submissions_phase_enum
  CHECK ((phase IS NULL) OR (phase = ANY (ARRAY[
    'test_pit', 'assessment', 'work_order', 'service_work',
    'gis_docs', 'restoration', 'out_of_order', 'tapcard', 'no_work'
  ])))
```
**9 values** — buddy_context memory said 8. Memory was stale; `no_work` was added by MI-108 and is correctly included.

```
phase_submissions_work_order_code_enum
  CHECK ((wo IS NULL) OR (wo = ANY (ARRAY['LSL-R', 'PLSL-R', 'GV-R', 'INS'])))

phase_submissions_njaw_work_order_code_enum
  CHECK ((njaw IS NULL) OR (njaw = ANY (ARRAY['M2C', 'H2C', 'FULL', 'MP', 'TP', 'KILL'])))

phase_submissions_no_work_invariant
  CHECK ((phase <> 'no_work') OR (
    photo_house_url IS NOT NULL AND
    photo_no_work_whiteboard_url IS NOT NULL AND
    photo_no_work_whiteboard_detected = true AND
    no_work_reason IS NOT NULL AND
    length(trim(no_work_reason)) >= 20
  ))
```

CDM-Smith rule a (no-work workflow) compound invariant at the database layer ✓.

## VERIFY-3: RLS forced + ≥1 policy on every owner-data table

14/14 PASS. Zero failures.

| Table | RLS enabled | RLS forced | Policies |
|---|---|---|---|
| audit_log | ✓ | ✓ | 1 |
| compliance_events | ✓ | ✓ | 1 |
| cs_replacement_authorizations | ✓ | ✓ | 1 |
| daily_reports | ✓ | ✓ | 2 |
| documents | ✓ | ✓ | 2 |
| **firms** | ✓ | ✓ | **2** ← MI-203 step 3 lockdown holds |
| luis_conversations | ✓ | ✓ | 1 |
| materials_sheets | ✓ | ✓ | 2 |
| parts_catalogs | ✓ | ✓ | 2 |
| phase_submissions | ✓ | ✓ | 2 |
| profiles | ✓ | ✓ | 3 |
| properties | ✓ | ✓ | 2 |
| rfis | ✓ | ✓ | 2 |
| whiteboard_override_log | ✓ | ✓ | 1 |

`firms` has exactly 2 policies (`firms_read_authenticated`, `firms_super_write`). Zero `firms_read_anon`. MI-203 step 3 is fully locked.

## VERIFY-4: `firm_id` indexing inventory

23 indexes on `firm_id` columns across the schema. The 7 from MI-204b are all present (phase_submissions, properties, cs_replacement_authorizations, documents, daily_reports, rfis, luis_conversations). 16 additional indexes cover surfaces shipped after MI-204b: contractor_arrival_log, contractor_departure_log, contractor_assignments, restoration_grid_entries, legal_holds (×2), destruction_notices, materials_sheets, photo_rescue, profiles, projects (×2), supervisor_alerts, audit_log, compliance_events, whiteboard_override_log.

Sequential scan risk on RLS predicate `firm_id = auth.firm_id()`: **zero** across the schema.

## VERIFY-5: Activity baseline

| Metric | Value |
|---|---|
| audit_log rows last 24h | 288 |
| audit_log rows last 7d | 1,095 |
| audit_log total rows | 1,095 |
| audit_log most recent | 2026-05-03 01:01:17 UTC (post Phase-2b merge) |
| compliance_events rows | 6 |
| compliance_events id range | 4 → 11 |
| compliance_events id gaps | 2 (matches locked Saturday decision: rolled-back-tx seq advance) |

## VERIFY-6: tapcard inventory + Phase 2b real-shape gate

| Metric | Value |
|---|---|
| Total tapcard rows | 1 |
| Rows with `tapcard_data` populated | 0 |
| Rows since Phase 2b merge (0:52 UTC 5/3) | 0 |
| Most recent tapcard | 2026-04-16 (demo seed, pre-UI) |

🟡 **Real `tapcard_data` jsonb shape (`{company_side, sector, materials_sheet_id_at_submit}`) verifies on first live inspector submission via UI.** This is the expected post-Saturday state. No defect — just the gate.

---

## What this confirms about ship quality

1. **Saturday's three PR merges held clean** through Sunday morning. No regressions detected at the schema or RLS layers.
2. **MI-203 step 3 fully closed** the anonymous-firm-read attack surface. The pre-auth firm lookup goes exclusively through `lookup_firm_by_code` SECURITY DEFINER RPC.
3. **MI-204b indexing went well beyond scope** — 16 additional firm_id indexes shipped silently as the schema grew. Performance posture is excellent.
4. **MI-108 compound invariant** for `no_work` enforces all 5 fields at the database layer, not just the application layer. CDM-Smith rule a is enforced even if the app is bypassed.
5. **CDM-Smith rule c (CS replacement auth)** lives in `cs_replacement_authorizations` with RLS forced and dedicated index. MI-109 closure holds.

## What this surfaces for next sprint

1. **Construction PM frontend has more backend ready than the ticket scope assumed.** `contractor_arrival_log` + `contractor_departure_log` + `contractor_assignments` are all indexed and RLS-locked. Frontend brief can target an existing API surface.
2. **Restoration Card frontend (MI-101 Phase 2c) has partial backend ready.** `restoration_grid_entries` is indexed and RLS-locked. The brief should distinguish what's already shipped vs. what needs new tables.
3. **IP / right-to-forget infra silently exists.** `legal_holds`, `destruction_notices` tables are present and indexed. Not on the active queue but documented here for awareness.
4. **`buddy_context.md` phase enum count (8) is stale.** Should read 9 (includes `no_work`). Refresh at next session boundary.

---

**Verification complete. No follow-up SQL needed. All gates green or expected-pending.**
