# Buddy Sync Note — MI-DEMO Seed Local Repo Reconciliation

**Cut:** 2026-05-06 ~19:35 EDT
**Author:** Buddy (Claude.ai web)
**Why this exists:** Buddy applied 12 migrations to prod Supabase via direct MCP write during MI-DEMO seed run. CC's local migration drafts had stale timestamps + 1 missing column on migration 08 + 3 missing migrations entirely. This note documents the exact reconciliation Buddy performed on `supabase/migrations/` so CC can review before commit + push.

## Files renamed (timestamp prefix changed to match prod `schema_migrations` versions)

CC drafted with timestamps `2026050618000N`. Buddy applied at `2026050623XXXX`. Renamed for parity so `supabase db pull` / `db push` produce no-ops against current prod.

| Old filename | New filename |
|---|---|
| `20260506180005_mi_demo_seed_05_projects.sql` | `20260506230217_mi_demo_seed_05_projects.sql` |
| `20260506180006_mi_demo_seed_06_properties.sql` | `20260506230241_mi_demo_seed_06_properties.sql` |
| `20260506180007_mi_demo_seed_07_materials_sheets.sql` | `20260506230313_mi_demo_seed_07_materials_sheets.sql` |
| `20260506180008_mi_demo_seed_08_phase_submissions.sql` | `20260506230547_mi_demo_seed_08_phase_submissions.sql` (+ content fix, see below) |
| `20260506180009_mi_demo_seed_09_cs_authorization.sql` | `20260506230601_mi_demo_seed_09_cs_authorization.sql` |
| `20260506180010_mi_demo_seed_10_daily_reports.sql` | `20260506230612_mi_demo_seed_10_daily_reports.sql` |
| `20260506180011_mi_demo_seed_11_documents.sql` | `20260506230623_mi_demo_seed_11_documents.sql` |
| `20260506180012_mi_demo_seed_12_rfis.sql` | `20260506230637_mi_demo_seed_12_rfis.sql` |
| `20260506180013_mi_demo_seed_13_luis_conversations.sql` | `20260506230653_mi_demo_seed_13_luis_conversations.sql` |

For 8 of these (05, 06, 07, 09, 10, 11, 12, 13) content is unchanged — only the filename changed.

## Files added (3 net-new migrations Buddy applied)

| Filename | What it does |
|---|---|
| `20260506224906_enable_pg_net.sql` | `CREATE EXTENSION IF NOT EXISTS pg_net;` — installed during seed run for Edge Function invocation attempts. Stays installed as a forward capability (MI-107 rule engine architecture relies on this for trigger-based Edge Function calls). |
| `20260506230138_mi_demo_seed_03_add_profiles_email.sql` | `ALTER TABLE profiles ADD COLUMN IF NOT EXISTS email text;` + backfill from `auth.users`. CC's spec §7 + Edge Function code + migrations 05-13 all assumed this column existed; it did not. Required for the email-based profile lookups in 05-13. |
| `20260506230158_mi_demo_seed_04_create_demo_auth_users_via_sql.sql` | Direct INSERT to `auth.users` + `auth.identities` + `public.profiles` for the 5 demo users. **Replaces §17 step 4** (Edge Function invoke) because the deployed `seed-demo-users` Edge Function's `auth.admin.listUsers` SDK call threw "Database error finding users" on all 5 invocations (5/5 errors, 0 created). Function deployed for future SDK-version retry; this migration replaces it functionally. |

## Migration 08 content fix

CC's draft of `mi_demo_seed_08_phase_submissions.sql` omitted `photo_no_work_whiteboard_detected` from the INSERT column list. The `phase_submissions_no_work_invariant` CHECK constraint requires this column = `TRUE` on the no_work row (#18, property #8). Without the column in the INSERT list, default NULL fails the CHECK.

Buddy added the column to the INSERT clause (24 columns total, was 23) and set `TRUE` on the no_work row (24 cols × `true` for that one row), `NULL` on all 24 other rows. Re-applied successfully on 2026-05-06 ~23:05 EDT.

The renamed file `20260506230547_mi_demo_seed_08_phase_submissions.sql` now reflects the corrected content.

## Edge Function on disk (no change)

`supabase/functions/seed-demo-users/index.ts` is unchanged. The version on disk matches what was deployed to prod. **It is functionally broken** — the `auth.admin.listUsers` call fails — but the source is preserved for future SDK-version retry. Adding a TODO/known-issues comment at the top of the file is recommended but not done in this sync.

## Verification state at sync time

- Prod `schema_migrations` records 12 new migrations matching the local filenames listed above
- `chain_health_check()` returns 12/12 PASS
- Demo firm row counts: 22 properties (10 legacy + 12 new), 52 phase_submissions (27 legacy + 25 new), 8 materials_sheets, 6 daily_reports, 3 documents, 2 RFIs, 2 Luis conversations, 2 cs_authorizations, 8 profiles (3 legacy + 5 new), 5 demo auth.users

## What CC should do with this

1. `git status` — should show 9 file renames + 3 new migration files + 1 modified migration (08) + this sync note
2. Verify the diffs match this note (renames are just path changes; 08 has the column added; 3 new files are net-new content)
3. Commit + push to `mi-demo-seed` branch on GitHub
4. Merge `mi-demo-seed` → `demo-banner` (NOT main per §22)
5. Update `decisions.md` with: MI-DEMO seed shipped; Edge Function admin SDK bug logged as known issue; pg_net extension added to schema; profiles.email column added (denormalized convenience, future sync-trigger ticket if desired)
6. Update `STATE.md` with new state (today's deltas)

## Open follow-ups (not blocking the ship)

- Edge Function `seed-demo-users` SDK bug — investigate supabase-js@2.49.x or check gotrue-admin-API version skew. Low priority since SQL bypass works.
- `profiles.email` denormalization sync — current state assumes one-time backfill is sufficient. If a future ticket changes auth.users.email, profiles.email won't auto-sync. Consider trigger or remove column.
- Legacy 3 demo profiles (`*@demo.myinspector.local`) untouched per UPSERT default. V2 returns 8 profiles instead of 5. Future ticket can wipe legacy if cleaner state desired.
- `seed-demo-users` Edge Function adds a TODO comment at file head documenting the SDK bug.
