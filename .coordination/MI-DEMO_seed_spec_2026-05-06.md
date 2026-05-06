# MI-DEMO Seed Spec — Demo Tenant Sample Data Bootstrap

**Authored (Lead reconciled v2):** 2026-05-06 ~18:05 EDT
**Authority:** Jorge granted batch trust 5/5 evening; demo-tenant work confined to demo-banner per §22
**Branch policy:** Lead executes on `mi-demo-seed` branched off `demo-banner`; merge target = `demo-banner` only; main is forbidden per §22

---

## Out of scope (companion docs from Buddy — do NOT fold in here)

This ticket is **seed data bootstrap only**. The following adjacent surfaces ship as separate specs and must not creep into §17 / §18 / §19 / §22:

- **MI-DEMO-UI v2** — banner copy refresh + write suppression toggles for demo-firm sessions. Owns: `firm_safe_to_display` UI consumers, "Sample tenant — read-only on pitch day" toggles, any frontend that masks the demo nature of the data. Cross-ref only.
- **MI-DEMO-DEPLOY** — pitch-day deploy ritual + revert procedure (Vercel alias swap, post-demo wipe schedule, Jorge-side checklist). Owns: anything that happens around a live prospect demo. Cross-ref only.

This seed spec assumes both companion docs land separately. Acceptance criteria here (§1) intentionally exclude UI behavior and deploy ritual.

---

## §1 Acceptance criteria

A demo seed run is "green" when ALL of the following hold:

1. **Auth roster:** Five `auth.users` rows exist with deterministic emails (§6); each has a corresponding `profiles` row with matching `firm_id = '99999999-9999-9999-9999-999999999999'`, role per §7, `full_name` populated, no orphan auth user.
2. **Property roster:** ≥12 properties under demo firm, sector mix ≥10 NJ6_NORMAL + ≥2 NJAW_SHORT_HILLS, every property has `address`, `municipality`, `lot_block`, `mapcall_id`, `current_phase` populated.
3. **Workflow coverage:** ≥1 phase_submission per phase enum value (9 phases — `test_pit`, `assessment`, `work_order`, `service_work`, `gis_docs`, `restoration`, `out_of_order`, `tapcard`, `no_work`); ≥1 submission per NJAW work order code (6 codes — M2C, H2C, FULL, MP, TP, KILL); ≥1 KILL with `kill_subtype` in tapcard_data.
4. **Materials sheet linkage:** ≥3 materials_sheets, each linked to a different property; at least one sheet has all 39 columns non-null where applicable; at least one sheet has `existing_mp_noted=true` (CDM-Smith rule b).
5. **Compliance gate exercises:** ≥1 `cs_replacement_authorizations` row (CDM-Smith rule c — Carlo authorization); ≥1 `phase='no_work'` submission with house photo + whiteboard reason (CDM-Smith rule a).
6. **Audit chain integrity:** Hash chain unbroken — `audit_log` row count grows monotonically during seed; final `chain_health_check()` returns no breaks; no raw SQL bypass writes.
7. **RLS isolation:** Cross-firm spot check — query `properties` as super_admin sees demo + real; query as a demo-firm-scoped service role sees only demo properties; CP Engineers and Serrano Group rows remain untouched (count delta = 0 across the run).
8. **Idempotency:** Re-running the seed produces zero net new rows on second run (UPSERT semantics with deterministic UUIDs) — see §20.
9. **Sanitization compliance:** Zero seeded rows reference CP Engineers, NJAW, Montana Construction, Conquest Construction, Justin, Tyler, Hackensack, or any real LCRI customer (per `serrano-group-brand` skill).
10. **Demo-banner deploy smoke-test:** After commit + push, Vercel preview on demo-banner alias renders the demo super_admin login successfully and Property Detail loads at least one demo property. (Pitch-day deploy ritual is MI-DEMO-DEPLOY — out of scope here.)
11. **Audit actor coverage:** New audit rows produced by the seed (~1,000 expected) populate `audit_log.actor_id` from the seeding session's auth context. Pre-existing 101 demo-firm audit rows remain NULL per §16a option (a). Final demo-firm audit_log: ~91% attributed, ~9% NULL.

---

## §2 Why & scope

Track 2 of the demo-tenant initiative (post-banner-frontend Saturday work + Sunday backend `firms_safe_to_display_flag` migration). Ships sample data for Jeff Longberg demo (Thu 5/14 or Fri 5/15) and any future prospect demo without exposing CP Engineers data.

In scope: auth users, profiles, projects, properties, phase_submissions, materials_sheets, cs_replacement_authorizations, daily_reports, documents (metadata only — see §15), rfis, luis_conversations.

Out of scope (this spec): Storage objects (real photo bytes — see §15 Q-DEMO-4); compliance reports; legal_holds; destruction_notices (these live empty); supervisor_alerts (let triggers populate); whiteboard_override_log (empty).

Out of scope (companion specs): UI banner mechanics → MI-DEMO-UI v2; deploy/revert ritual → MI-DEMO-DEPLOY.

---

## §3 Demo firm provenance

Already seeded:
- `firms.id = '99999999-9999-9999-9999-999999999999'`
- `name = 'DEMO — Sample Engineering Firm'`
- `firm_code = 'DEMO-TENANT-99'`
- `firm_safe_to_display = true`

Existing rows under demo firm (read 2026-05-06 ~17:30 EDT via Supabase MCP):
- 10 properties
- 27 phase_submissions
- 3 materials_sheets
- 1 project
- 3 profiles
- 101 audit_log rows (all 101 with `actor_id` NULL — see §16a)

This spec assumes existing rows are partial / inconsistent (legacy from prior demo work) and treats §17 as a wipe-then-reseed under the demo firm scope. See Q-DEMO-2 for the alternative (UPSERT-only).

---

## §4 Schema source-of-truth

Verified via Supabase MCP `information_schema.columns` 2026-05-06:

- `properties` — 19 cols (id, address, city, municipality, state, zip, lot_block, lat, lng, mapcall_id, company_material, customer_material, current_phase, firm_id, created_at, deleted_at, deleted_by, sector, project_id)
- `materials_sheets` — 39 cols (FLAT NJAW + customer old/new — no service_materials_grid jsonb)
- `phase_submissions` — 24 cols (incl. tapcard_data jsonb, materials_sheet_id, njaw_work_order_code)
- `audit_log` — 13 cols (id, occurred_at, actor_id, actor_email, firm_id, table_name, record_id, action, old_data, new_data, row_hash, prev_hash, created_at)
- `firms`, `profiles`, `projects` — verified via prior list_tables runs

Locked enums (per `myinspector-domain-rules`):
- phase: 9 values
- njaw_work_order_code: 6 values (M2C/H2C/FULL/MP/TP/KILL)
- work_order_code: 4 values (LSL-R/PLSL-R/GV-R/INS)
- sector: NJ6_NORMAL / NJAW_SHORT_HILLS

Schema drift from this list during execution = stop-and-ping per spec front matter.

---

## §5 Sanitization rules (locked)

Demo content MUST NOT include:
- CP Engineers, NJ American Water, NJAW (in customer-name positions), Montana Construction, Conquest Construction
- Real inspector first names (Justin, Tyler) or contractor crew leads
- Hackensack (CP office town)
- Any real LCRI workorder ID, MapCall ID matching prod patterns, or address matching a real property

Replacement vocabulary (synthetic):
- Inspector names: "Sam Brooks", "Riley Sample", "Drew Carter", "Avery Lane"
- Supervisor: "Pat Morgan"
- Super-admin: "Demo Admin (Jorge)"
- Contractor: "Demo Excavators LLC", "Sample Site Services"
- Foreman names: "Jordan Reed", "Casey Kim"
- Customer names (where used): "Smith Residence", "Johnson Property"

Public NJ municipality names are OK (Maplewood, Millburn, etc. are public knowledge, not customer-identifying). Synthetic street addresses required (no real addresses tied to real customers).

---

## §6 Auth users (proposed roster — Q-DEMO-1)

Default roster (5 users):

| Email | Role | Full name | Notes |
|---|---|---|---|
| `demo-jorge@myinspector.io` | super_admin | Demo Admin | Already used by demo login button per `685f4c1`; password `Demo2026!` (matches existing button) |
| `demo-supervisor@myinspector.io` | supervisor | Pat Morgan | If `supervisor` not in role enum, falls back to `super_admin` |
| `demo-inspector-1@myinspector.io` | inspector | Sam Brooks | |
| `demo-inspector-2@myinspector.io` | inspector | Riley Sample | |
| `demo-inspector-3@myinspector.io` | inspector | Drew Carter | |

Shared password: `Demo2026!` (Q-DEMO-1 — could be unique per user; Lead default is shared for demo simplicity).

All users: `firm_id = '99999999-9999-9999-9999-999999999999'`, `email_confirm = true` (skip email verify for demo).

---

## §7 Profiles plan

One `profiles` row per auth user (auto-created via auth trigger if present, else INSERT in §17). Profile fields:

- `id` = auth user id
- `firm_id` = demo firm
- `email` = matches auth
- `full_name` = per §6 table
- `role` = per §6 table
- `created_at` = NOW

Verify role enum values via SELECT before INSERT (super_admin / supervisor / inspector — actual enum TBD; if `supervisor` absent, demote to inspector + add `is_supervisor` flag if column exists, else log Q-DEMO-1 follow-up).

---

## §8 Projects plan

One project row:
- `id` = `aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa` (deterministic)
- `firm_id` = demo
- `name` = "Demo LSL Replacement Program 2026"
- `client` = "Sample Water Authority"
- `status` = active
- `module_key` = water_utility
- `start_date` = 2026-01-15

---

## §9 Properties plan (12-15 rows)

Deterministic UUIDs `bbbbbbbb-0000-0000-0000-00000000NNNN`. Mix:

| # | Address | Municipality | Sector | Phase | Notes |
|---|---|---|---|---|---|
| 1 | 12 Maple Ridge Ave | Maplewood | NJ6_NORMAL | tapcard | FULL, complete record |
| 2 | 44 Birch Hollow Rd | Maplewood | NJ6_NORMAL | service_work | M2C in flight |
| 3 | 87 Oak Bend Way | Millburn | NJ6_NORMAL | restoration | H2C done, restoration pending |
| 4 | 156 Cedar Crest Ln | Maplewood | NJ6_NORMAL | gis_docs | KILL complete |
| 5 | 203 Pine Vista Dr | Millburn | NJ6_NORMAL | assessment | TP scheduled |
| 6 | 9 Willow Park Pl | Maplewood | NJ6_NORMAL | test_pit | TP just done |
| 7 | 71 Elm Forest Ct | Maplewood | NJ6_NORMAL | work_order | MP only |
| 8 | 22 Ash Grove Ter | Millburn | NJ6_NORMAL | no_work | CDM-Smith rule a — homeowner refused |
| 9 | 308 Hickory Hill Rd | Maplewood | NJ6_NORMAL | service_work | FULL with CS replacement (Carlo gate) |
| 10 | 55 Sycamore Ridge Blvd | Maplewood | NJ6_NORMAL | out_of_order | sequence_note populated |
| 11 | 14 Cliff View Ln | Short Hills | NJAW_SHORT_HILLS | service_work | ShortHills role inversion |
| 12 | 28 Highland Crest Pl | Short Hills | NJAW_SHORT_HILLS | tapcard | ShortHills, second |

Shared: `state='NJ'`, `zip` per municipality, synthetic `lat/lng` near actual municipality centroids (jittered ±0.005°), `mapcall_id` = `DEMO-MC-NNNN` pattern, `lot_block` = `Lot N / Block M`, `project_id` = §8 project.

---

## §10 Phase submissions plan (~25 rows across the 12 properties)

Per §1 acceptance #3: at least 1 submission per phase enum value (9), 1 per NJAW work order code (6), 1 KILL with subtype.

Distribution rules:
- Each property gets 1-3 submissions in chronological order leading up to its `current_phase`
- `submitted_by` rotates across the 3 inspector profiles
- `submitted_at` spans 2026-01-15 → 2026-05-01 (synthetic timeline)
- `tapcard_data` jsonb: minimal `{service_number, task_numbers, ...}` for 'tapcard' phase; KILL submissions include `{subtype: 'ABANDON'|'RELOCATE_FULL'|'RELOCATE_STREET'}`
- Property #8 (`no_work`): `photo_house_url` + `photo_no_work_whiteboard_url` + `no_work_reason` populated per CDM-Smith rule a
- Photos: synthetic public URLs OR null per Q-DEMO-4

Deterministic UUIDs `cccccccc-NNNN-...`.

---

## §11 Materials sheets plan (5 sheets)

Linked to properties #1, #2, #3, #4, #9 (FULL, M2C, H2C, KILL, FULL+CS-replacement). Property #1 sheet is the "complete record" — all 39 columns populated where the field type permits, used for visual tapcard QA against paper PDF (44 Dunnell example).

Specific values for property #1 (mirroring filled-in Tapcard__1_.pdf):
- service_type=FULL, contractor_name='Demo Excavators LLC', foreman_name='Jordan Reed'
- temperature_f=72, sky_condition='sunny', test_pit=false
- corp_depth_inches=53, cs_depth_inches=44, cs_house_inches=480, cs_far_curb_inches=180
- size_of_main_inches=6, type_of_main='CAST IRON', service_side='long'
- njaw_old_size_inches=0.75, njaw_old_material='GALVANIZED'
- njaw_new_size_inches=1, njaw_new_material='COPPER', njaw_new_amount_feet=20
- existing_mp_noted=true (CDM-Smith rule b)

Property #4 sheet: KILL minimal columns. Property #9 sheet: full + cs_replacement=true gate triggers §13.

Deterministic UUIDs `dddddddd-NNNN-...`.

---

## §12 Restoration / rainy-day plan

Property #3's `restoration` phase submission populates `photo_restoration_url` + `photo_restoration_whiteboard=true` per whiteboard rule. No `restoration_grid_entries` row in v1 demo (table backfill pending Phase 2c-form work).

---

## §13 CS replacement authorizations

One row, linked to property #9's FULL submission (the one with `cs_replacement=true`):
- Calls `submit_cs_authorization(p_phase_submission_id, p_authorization_date, p_authorization_time, p_supervisor_name, p_reason)` RPC (INSERT-only, audit-logged)
- supervisor_name = 'Demo Admin (Carlo placeholder)'
- reason ≥ 20 chars: "Demo CS replacement — homeowner verified leak past corner per CDM-Smith rule e."

This exercises the immutability gate (UPDATE/DELETE/TRUNCATE revoked from service_role 5/2/26).

---

## §14 Daily reports / documents / RFIs / Luis conversations

- **daily_reports:** 2 rows (last 2 weekdays) per inspector profile = 6 rows total. Free-text summaries.
- **documents:** 3 metadata-only rows (file_name, file_type, uploaded_by). No actual storage objects per §15.
- **rfis:** 2 rows ('open' status), routed to demo-supervisor.
- **luis_conversations:** 2 short conversations exercising both intents (homeowner-prep + field-question). Tokens/cost = 0 (synthetic; not API-billed).

---

## §15 Photo storage strategy (Q-DEMO-4)

Default (Q-DEMO-4 lead's pick): **No real bytes uploaded.** Photo URL columns populate with synthetic placeholders pointing to `https://placehold.co/600x800?text=DEMO+photo+slot+N`. Frontend's `<img>` tags load these public placeholders without auth. Storage bucket `photos/` stays empty for demo firm.

Alternative (Q-DEMO-4 expanded): Upload 4-6 sample images (a fake whiteboard, a fake property exterior) to a `demo-firm/` prefix in storage; reference real Storage URLs. More realistic but uploads must be sanitized + own-IP / public-domain images only.

---

## §16 Audit / compliance baseline

Do NOT pre-seed `audit_log` or `compliance_events` rows. Let the existing AFTER INSERT/UPDATE/DELETE triggers + `audit_log_chain_trigger` populate naturally during seed inserts. Final `chain_health_check()` must return no breaks.

`record_compliance_event` calls fire from existing app paths (e.g. CS auth INSERT) — do not call manually.

For `audit_log.actor_id` population strategy (existing 101 NULL rows + ~1,000 new rows from this seed), see §16a.

---

## §16a Audit chain actor_id strategy (Q-DEMO-5)

**Schema fact (verified 2026-05-06):** `audit_log` includes `actor_id uuid NULL` and `actor_email text NULL` alongside the chain hash columns. The `audit_log_chain_trigger` fires BEFORE INSERT only — it computes `row_hash` from the canonical pipe-delimited encoding of the NEW row (which includes `actor_id`). UPDATE bypasses the trigger, so post-insert UPDATE of `actor_id` leaves the stored `row_hash` stale relative to the now-modified canonical encoding → silent chain break detectable by `chain_health_check()`.

**Existing demo-firm audit rows:** 101 total, 100% with `actor_id` NULL (legacy from prior demo seed runs that pre-dated app-level actor population).

**Expected new rows from this seed:** ~1,000 (rough estimate: ~50 INSERTs × ~20 cascade audit rows each via per-table triggers).

**Two strategies:**

**(a) Leave existing 101 alone; populate actor_id on new INSERTs only.** App-level INSERTs in §17 set `actor_id` via the seeding session's auth context (Edge Function uses service-role + sets a session var; raw migrations set `auth.uid()` indirectly via a temporary `SET LOCAL` claim, OR explicitly pass actor_id as part of the INSERT payload where the trigger reads it). Existing 101 stay NULL. Net result: ~91% of demo-firm audit rows show real actors, ~9% show NULL ("system"). Chain stays intact; no DISABLE TRIGGER ceremony.

**(b) Wipe existing 101 + DISABLE chain trigger + DELETE 101 rows + re-INSERT 1,100 fresh rows in `occurred_at` order with full chain rebuild from scratch + RE-ENABLE trigger.** Produces 100% actor-populated demo audit log. Cleaner prospect optics, but: requires DISABLE TRIGGER on a compliance-critical table (out of band of normal write paths), requires careful occurred_at ordering to preserve realism, doubles the ceremony, and risks accidentally breaking the prod chain if the disable scope leaks.

**Lead default: (a).** Existing 101 NULL rows are background noise from prior seed cycles; the new ~1,000 will be fully attributed. A prospect (Jeff at the 5/14 demo, or any "Stan" placeholder) drilling into audit_log via super_admin view will see the 9% NULL distribution interleaved with attributed rows — reads as legitimate "system events" alongside user actions, defensible under audit.

**Stop condition for option (b) escalation:** if Jorge demands 100% actor coverage for prospect optics, escalate Q-DEMO-5 to (b) and add a separate migration `mi_demo_audit_chain_rebuild` upstream of the §17 seed sequence. That work is out of this spec's scope as drafted; would need its own dependency-order plan, DISABLE TRIGGER guard rails (`SET LOCAL session_replication_role = replica` scoped to a single transaction), and a verify-then-commit gate.

**Implementation note for option (a):** Edge Function `seed-demo-users` (§18) runs under service-role, so its auth.uid() is NULL. To populate actor_id on the auth.users → profiles INSERT, the function passes `actor_id` explicitly in the profile INSERT or invokes a `SET LOCAL claim.sub = ...` shim before each row. Subsequent INSERTs in §17 steps 5-13 are issued via `apply_migration` (service-role) — same shim pattern, set actor to one of the 5 demo user UUIDs round-robin. This keeps actor distribution realistic across the 5 users.

---

## §17 Dependency order (locked execution sequence)

```
1. Verify firm exists (SELECT firms WHERE id=demo) — must already be seeded
2. Verify role enum values (SELECT enum_range against profiles.role)
3. (Optional Q-DEMO-2 wipe) Soft-delete pre-existing demo-firm rows in dependency-reverse order:
   luis_conversations → rfis → documents → daily_reports → cs_replacement_authorizations →
   materials_sheets → phase_submissions → properties → projects → profiles → auth.users
   (TRUNCATE forbidden — `audit_log` triggers must see DELETE for chain integrity)
4. Edge Function call (§18) → creates 5 auth.users + matching profiles
5. INSERT projects (1 row, depends on firm)
6. INSERT properties (12-15 rows, depend on firm + project)
7. INSERT materials_sheets (5 rows, depend on properties + profiles for submitted_by)
8. INSERT phase_submissions (~25 rows, depend on properties + profiles + materials_sheet_id for materials phase)
9. RPC submit_cs_authorization (1 row, depends on phase_submission with cs_replacement=true)
10. INSERT daily_reports (6 rows)
11. INSERT documents (3 rows)
12. INSERT rfis (2 rows)
13. INSERT luis_conversations (2 rows)
14. Run §19 verification queries
15. Run chain_health_check() — must be intact
```

Each step is its own migration via `apply_migration` (per Q-DEMO-2 outcome). Migration names prefixed `mi_demo_seed_NN_<step>`. Each migration sets `actor_id` per §16a option (a) — round-robin across the 5 demo user UUIDs.

---

## §18 Edge Function shape

**Slug:** `seed-demo-users`

**Route:** `POST https://wryitfoletwskkdqqwcw.supabase.co/functions/v1/seed-demo-users`

**Auth model (Q-DEMO-1 sub-question):** `verify_jwt = false` + custom shared-secret header `x-demo-seed-secret` matching env var `DEMO_SEED_SECRET`. Reasoning: regular JWT can't create auth users; service-role key inside the function does the actual work. Shared secret prevents random POSTers. Set secret value via Supabase dashboard as a one-time bootstrap; rotate after demo cycle.

Alternative: `verify_jwt = true` + check caller is super_admin in `profiles`. Stronger but requires existing auth user. Lead default = shared secret for bootstrap simplicity.

**Payload:**
```json
{
  "firm_id": "99999999-9999-9999-9999-999999999999",
  "users": [
    {"email": "demo-jorge@myinspector.io", "password": "Demo2026!", "role": "super_admin", "full_name": "Demo Admin"},
    {"email": "demo-supervisor@myinspector.io", "password": "Demo2026!", "role": "supervisor", "full_name": "Pat Morgan"},
    {"email": "demo-inspector-1@myinspector.io", "password": "Demo2026!", "role": "inspector", "full_name": "Sam Brooks"},
    {"email": "demo-inspector-2@myinspector.io", "password": "Demo2026!", "role": "inspector", "full_name": "Riley Sample"},
    {"email": "demo-inspector-3@myinspector.io", "password": "Demo2026!", "role": "inspector", "full_name": "Drew Carter"}
  ],
  "wipe_existing": false
}
```

**Server logic (Deno/TS):**
1. Validate `x-demo-seed-secret` header
2. Validate `firm_id` matches `99999999-...` (refuse other firms)
3. Use `createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)` admin client
4. For each user: `admin.auth.admin.createUser({email, password, email_confirm: true, user_metadata: {full_name, firm_id, role}})`
5. UPSERT matching `profiles` row (idempotent on email); pass `actor_id` = the new user's own id (self-attribution per §16a option a)
6. Return `{created: [...uuid], skipped: [...email], errors: [...]}`

**Idempotency:** If user with email exists, return existing id; do not error. UPSERT profile.

**Secrets needed in Edge Function env:**
- `SUPABASE_URL` (already auto-injected)
- `SUPABASE_SERVICE_ROLE_KEY` (already auto-injected)
- `DEMO_SEED_SECRET` (Lead sets via dashboard before first call; Q-DEMO-1)

---

## §19 Verification queries

Run in order after §17 step 14:

```sql
-- V1: Auth roster (must return 5)
SELECT COUNT(*) FROM auth.users WHERE email LIKE 'demo-%@myinspector.io';

-- V2: Profile roster (must return 5, all firm_id matches)
SELECT COUNT(*) FROM profiles
WHERE firm_id = '99999999-9999-9999-9999-999999999999';

-- V3: Property sector mix (NJ6_NORMAL >= 10, NJAW_SHORT_HILLS >= 2)
SELECT sector, COUNT(*) FROM properties
WHERE firm_id = '99999999-9999-9999-9999-999999999999'
  AND deleted_at IS NULL GROUP BY sector;

-- V4: Phase coverage (must return all 9 enum values)
SELECT phase, COUNT(*) FROM phase_submissions
WHERE firm_id = '99999999-9999-9999-9999-999999999999'
  AND deleted_at IS NULL GROUP BY phase ORDER BY phase;

-- V5: NJAW work order code coverage (must return all 6)
SELECT njaw_work_order_code, COUNT(*) FROM phase_submissions
WHERE firm_id = '99999999-9999-9999-9999-999999999999'
  AND deleted_at IS NULL AND njaw_work_order_code IS NOT NULL
GROUP BY njaw_work_order_code ORDER BY njaw_work_order_code;

-- V6: Materials sheet count (>=3, ideally 5)
SELECT COUNT(*) FROM materials_sheets
WHERE firm_id = '99999999-9999-9999-9999-999999999999' AND deleted_at IS NULL;

-- V7: CS replacement auth count (>=1)
SELECT COUNT(*) FROM cs_replacement_authorizations csa
JOIN phase_submissions ps ON ps.id = csa.phase_submission_id
WHERE ps.firm_id = '99999999-9999-9999-9999-999999999999';

-- V8: No_work submission has whiteboard + reason
SELECT COUNT(*) FROM phase_submissions
WHERE firm_id = '99999999-9999-9999-9999-999999999999'
  AND phase = 'no_work'
  AND photo_house_url IS NOT NULL
  AND photo_no_work_whiteboard_url IS NOT NULL
  AND no_work_reason IS NOT NULL;

-- V9: Cross-firm spot check — CP and Serrano counts unchanged
SELECT firm_id, COUNT(*) FROM properties WHERE deleted_at IS NULL GROUP BY firm_id;
-- Compare to baseline taken before run

-- V10: Audit chain integrity
SELECT public.chain_health_check();  -- must return no breaks

-- V11 (per §16a): Audit actor coverage — total / attributed / NULL counts
SELECT
  COUNT(*) AS total,
  COUNT(actor_id) AS with_actor,
  COUNT(*) - COUNT(actor_id) AS null_actor,
  ROUND(100.0 * COUNT(actor_id) / NULLIF(COUNT(*),0), 1) AS pct_attributed
FROM audit_log
WHERE firm_id = '99999999-9999-9999-9999-999999999999';
-- Expected post-seed: total ~1,101; with_actor ~1,000; null_actor 101; pct_attributed ~91%
```

V1-V8 ≥ acceptance thresholds, V9 = baseline match, V10 = clean, V11 = ~91% attributed → green.

---

## §20 Idempotency strategy (Q-DEMO-2)

Lead default: **deterministic UUIDs + ON CONFLICT DO UPDATE.** Seed migrations are written so re-running them produces zero net new rows. UUIDs follow `[type-letter][type-letter][type-letter][type-letter]-NNNN-NNNN-NNNN-NNNNNNNNNNNN` pattern (b=property, c=phase_submission, d=materials_sheet, etc.).

Alternative (Q-DEMO-2): **Wipe-then-reseed.** Soft-delete all demo-firm rows in §17 step 3, then INSERT fresh. Cleaner state, but creates audit chain noise (DELETE + INSERT pairs flood `audit_log`). Lead recommends UPSERT to preserve audit chain readability.

Note: §16a option (a) interacts with idempotency. ON CONFLICT DO UPDATE on a row whose `actor_id` is being changed will fire UPDATE → bypass chain trigger → leave row_hash stale → chain break risk on re-verification. Mitigation: `ON CONFLICT DO NOTHING` on second-run rows where the first-run already populated actor_id (UPSERT becomes no-op for actor purposes), OR set actor_id only when inserting new rows. Document the chosen pattern in each migration.

---

## §21 Wipe / rollback procedure

If Q-DEMO-2 = wipe-and-reseed:

```sql
-- All scoped to demo firm; audit_log grows but does NOT lose chain integrity
UPDATE luis_conversations SET deleted_at = NOW() WHERE firm_id = 'demo' AND deleted_at IS NULL;
-- ... repeat down dependency tree
DELETE FROM auth.users WHERE email LIKE 'demo-%@myinspector.io';  -- cascades to profiles
```

If a seed run produces a bad state, run the wipe + reseed; never DROP.

(Pitch-day deploy / revert ritual is MI-DEMO-DEPLOY territory, not this spec.)

---

## §22 Demo-tenant policy (LOCKED)

1. **Demo branch isolation:** Sample data lives behind `firm_id='99999999-...'`. Demo-banner branch is the only branch where the demo login button is exposed. **NEVER MERGE demo-banner OR mi-demo-seed → main.** Per `685f4c1` commit message: "DO NOT MERGE INTO MAIN. Demo branch stays separate forever per the demo-tenant policy."
2. **`firm_safe_to_display` is the gate:** Banner visibility, demo-only UI tweaks, and any "this is sample data" copy keys off `firms.firm_safe_to_display`. Real firms have it = false. (UI mechanics owned by MI-DEMO-UI v2.)
3. **No real customer data ever in demo firm:** RLS isolates per-firm, but the policy is also social — sanitization (§5) ensures even if RLS misfires, demo content is not customer-identifiable.
4. **Demo writes are first-class:** Demo users can submit phases, save materials sheets, etc. — those writes hit `audit_log` like any other. The chain is real even if the data is synthetic. (Pitch-day write-suppression toggle, if any, is MI-DEMO-UI v2.)
5. **Demo data lifespan:** Demo rows persist through prospect demos. Wipe and reseed only when the spec changes or the data drifts visibly (e.g. dates feel stale). Track wipe history in `decisions.md`.
6. **Edge Function bootstrap:** `seed-demo-users` is a one-time bootstrap function; once auth users exist, future runs UPSERT-only. Do not re-deploy with new secrets unless rotating.
7. **Audit chain inviolable:** Per §16a, never UPDATE `actor_id` on existing audit_log rows in any seed flow. Either populate at INSERT time (option a) or rebuild via DISABLE-DELETE-INSERT-RE-ENABLE ceremony (option b, escalation only).
8. **Banked discipline:** Any work order or PR that mentions "demo" needs to declare branch target up front. PRs targeting main with demo content = automatic reject.

---

## §23 Open questions — Q-DEMO-1 through Q-DEMO-5 (Lead's defaults)

**Q-DEMO-1 — Auth users plan:** How many users, what roles, what password pattern?
- **Lead default:** 5 users per §6 table; shared password `Demo2026!` matching the existing demo login button. Edge Function gated by `x-demo-seed-secret` shared header. If `supervisor` role enum doesn't exist, demote to inspector + escalate.

**Q-DEMO-2 — Idempotency strategy:** Wipe-then-reseed vs UPSERT-with-deterministic-UUIDs?
- **Lead default:** UPSERT-with-deterministic-UUIDs (§20). Preserves audit chain readability; safe to re-run; cleaner rollback story. Note interaction with §16a — see §20 mitigation.

**Q-DEMO-3 — Sector mix:** NJ6_NORMAL only or include NJAW_SHORT_HILLS?
- **Lead default:** Both. ≥10 NJ6_NORMAL + ≥2 NJAW_SHORT_HILLS. ShortHills is in scope despite Q-2c-d-shorthills parking, because Phase 2d-revision visual tapcard already has ShortHills placeholder branch; demo needs to exercise that surface for Jeff. ShortHills demo properties stay frontend-only (no Phase 2c-form data until that ships).

**Q-DEMO-4 — Photo storage:** Real bytes in Storage or synthetic placeholders?
- **Lead default:** Synthetic `https://placehold.co/...` URLs. No Storage object writes. Demo runs cleanly without any bucket policy gymnastics; frontend renders something visible. Trade-off: no real whiteboard/curbstop photos to demo Vision detection. If Jeff needs Vision live, escalate to Q-DEMO-4-expanded with sanitized public-domain images.

**Q-DEMO-5 — Audit chain `actor_id` backfill:** Leave existing 101 NULL or wipe-and-rebuild?
- **Lead default:** (a) Leave existing 101 alone, populate `actor_id` on the ~1,000 new rows produced by this seed. End state ~91% attributed / ~9% NULL ("system"). Chain stays intact, no DISABLE TRIGGER ceremony, defensible under audit. Escalate to (b) only if Jorge demands 100% actor coverage for prospect optics — that work goes upstream as `mi_demo_audit_chain_rebuild`, scope outside this spec.

---

## §24 Stop conditions

Lead halts mid-seed and surfaces to Jorge if any of the following fires:

1. **Schema drift from §4 ground truth.** Column count mismatch on `properties` (≠19), `materials_sheets` (≠39), `phase_submissions` (≠24), or `audit_log` (≠13); missing `actor_id` / `firm_safe_to_display` / `sector` / `lot_block` / `mapcall_id` / `existing_mp_noted` columns; phase enum count ≠9 (locked at 9 per the no-work invariant constraint — db is source of truth); njaw_work_order_code enum count ≠6; sector enum missing `NJ6_NORMAL` or `NJAW_SHORT_HILLS`.
2. **Q-DEMO-1..5 default rejected.** Acceptance was given on diff approval; this is a no-op unless Jorge reverses a default mid-execution.
3. **DEMO_SEED_SECRET not set.** Edge Function deploy refuses without the env var; do not hardcode or substitute a placeholder.
4. **`profiles.role` enum missing `supervisor` or `inspector`.** §6/§7 demote-to-inspector fallback is a Q-DEMO-1 escalation, not a silent rewrite.
5. **`chain_health_check()` reports a break** at any point during or after the seed. Hash chain integrity is non-negotiable — halt, do not attempt repair via UPDATE.
6. **Cross-firm spot check fails (V9).** Any property/phase_submission/materials_sheet count delta on `firm_id` ≠ demo during the seed run = an unscoped write hit a real firm. Halt immediately, capture state, do not roll forward.
7. **`apply_migration` returns non-recoverable error.** Transient errors (lock timeout, retryable conflict) get one retry; structural errors (constraint violation, FK fail, RLS rejection) halt.
8. **Edge Function `seed-demo-users` deploy fails or returns errors[] non-empty** for users that are not "already exists" idempotency hits.
9. **`submit_cs_authorization` RPC call fails.** This exercises the compliance gate (CDM-Smith rule c); a failure here means either the RPC signature drifted or the audit-logged immutability path broke. Halt, do not retry blind.
10. **Acceptance thresholds in §1 not met after V1–V11.** If verification queries show fewer rows than acceptance requires, halt, report deltas, do not "top up" without a fresh diff cycle.
11. **Audit row count after seed is < 200 or > 5,000.** Sanity bounds on the ~1,000 expected new rows. Outside this window means something is firing too few or too many cascade triggers — halt, investigate before continuing.
12. **Branch / merge guardrail trip.** If at any point Lead is on `main` instead of `mi-demo-seed`, or attempts a push to `origin/main`, halt — §22 violation.

On stop: emit a state snapshot (last successful step in §17, current verification deltas, last `apply_migration` name + error if applicable) and wait. Do not roll back automatically; partial state is recoverable via §21 wipe.

---

## Verified ground truth (footer)

- Schema verified 2026-05-06 ~17:30 EDT via Supabase MCP `execute_sql` against `information_schema.columns` (properties 19 cols, materials_sheets 39 cols, phase_submissions 24 cols)
- `audit_log` schema verified 2026-05-06 ~18:00 EDT: 13 cols including `actor_id uuid NULL`, `actor_email text NULL`, `row_hash`, `prev_hash`
- Audit chain health function verified 2026-05-06 ~18:20 EDT via `pg_proc` lookup: `public.chain_health_check()` exists; `verify_audit_chain()` does NOT (corrected from prior draft)
- Demo firm row verified present: `id='99999999-...', firm_safe_to_display=true, firm_code='DEMO-TENANT-99'`
- Existing demo row counts verified: properties=10, phase_submissions=27, materials_sheets=3, projects=1, profiles=3, audit_log=101 (100% actor_id NULL)
- Edge Functions inventory: `luis-proxy`, `detect-whiteboard` — no `seed-demo-users` yet
- decisions.md / status.md / STATE.md surveyed for prior demo policy (commit `685f4c1` "DO NOT MERGE INTO MAIN" lock confirmed; migration `firms_safe_to_display_flag` shipped Sat; `demo_tenant_seed_data_v3` migration referenced but contents unread — Buddy spec should verify or supersede)
