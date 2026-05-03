# Demo Environment

> **Branch policy:** the `demo-banner` branch is the long-lived demo build.
> **It does NOT merge into `main`.** Cherry-picks across the boundary go either way
> (main → demo for new features once they're sanitized, demo → main for
> generic demo-mode infrastructure that can survive without the demo data),
> but the merge gate stays closed forever.

---

## Public demo URL

`https://demo.myinspector.io` (configured via Vercel project settings on the demo branch)

## Public demo login

Surfaced via the **"Demo login (auto-fill super_admin)"** button on the auth screen.
The button populates the email + password fields and calls `login()` immediately.

| Field | Value |
|---|---|
| Email | `demo-jorge@myinspector.io` |
| Password | `Demo2026!` |
| Role | `super_admin` (so prospects see the full UI surface) |
| Bound firm | The demo tenant — `firm_safe_to_display = true` |

**Rotation:** the demo-tenant maintenance cron (Buddy ship) rotates this password
on a schedule defined in `cron.job` / scheduled Edge Function. This document
captures the **canonical credential at the time of writing**; runtime always
wins on conflict. If the auto-fill stops working, the cron has rotated —
update this doc + the `loginAsDemo()` constants in `index.html`.

---

## Demo tenant — what's seeded

The demo firm is `id = 99999999-9999-9999-9999-999999999999`, name
`"DEMO — Sample Engineering Firm"`, firm_code `"DEMO-TENANT-99"`,
`firm_safe_to_display = true`.

Seeded by Buddy migration `demo_tenant_seed_data_v3` (verified live 2026-05-02):

- 1 project + contractor assignments
- 5 sample properties
- 13 phase submissions across 4 phases
- 3 materials sheets
- GPS arrival/departure logs (Construction PM Oversight module)
- 1 whiteboard override

Plus 3 profile rows (Demo Inspector One, Demo Inspector Two, Demo Supervisor)
attached to the firm. All emails on the synthetic domain `@demo.myinspector.local`
— **no real-domain leakage**.

---

## Demo banner

Lives at body level (above `#auth-screen` and `#app`) so it's visible on every
route the SPA serves: `/`, `/auth`, post-login app, plus any unknown route
falling back to `index.html` via Vercel SPA routing (effectively `/404`).

On the **demo branch**, the banner ships with the `visible` class baked into
the HTML and `currentFirmIsDemo = true` as the script-init default — banner is
unconditionally on. On **production main**, the same DOM toggles via
`applyDemoBannerVisibility()` driven by the authenticated firm's
`firm_safe_to_display` flag.

---

## Branch policy — demo stays separate forever

Stated in plain terms so future Lead/Buddy don't try to clean up the divergence:

1. **No merge into main.** The demo branch carries demo-only mutations
   (auto-fill credentials, always-on banner, sanitized strings, optional
   demo-only seed scripts) that have no place in production code.
2. **One-way cherry-picks main → demo** are fine when a real feature lands
   in main and the demo deploy needs to mirror it. Run the verification
   checklist (below) after each cherry-pick.
3. **One-way cherry-picks demo → main** are fine for generic demo-mode
   infrastructure (e.g., the `firm_safe_to_display` toggle behavior) that
   doesn't pull demo content along with it. Strip demo branch overrides
   (`currentFirmIsDemo = true` default, `loginAsDemo()`, baked-in `.visible`
   class) before merging the other direction.
4. **Conflicts are resolved manually** — no auto-merge. The branches will
   drift in places that are intentional; resolve case by case.

---

## Verification checklist (run before every push to demo)

Per the demo policy: empty grep output is required across the deployed surface.

1. **Repo grep** for forbidden strings:

   ```
   grep -ri "njaw\|cdm[- ]smith\|cp engineers\|quiet-river\|montana\|carlo\|maplewood\|short hills" \
     --exclude-dir=.git \
     --exclude-dir=node_modules \
     --exclude="docs/demo-environment.md" \
     --exclude="*.md" \
     --exclude="*.csv" \
     --exclude="discovery/*"
   ```

   The `--exclude` set is intentional: project documentation (CLAUDE.md,
   STATE.md, briefs, decisions/status, sales/legal drafts) legitimately
   names real customer entities and isn't deployed to the demo. The grep
   gates **deployed source** (HTML, JS, CSS, JSON, SQL fixtures) only.
   Empty output across the deployed-source set is the gate.

2. **Live demo URL grep** — view-source on `https://demo.myinspector.io`
   and run the same regex against the HTML response. On a single-file SPA
   this collapses to the same `index.html` grep above.

3. **Seeded DB content grep** — query Supabase for the demo firm's rows
   across `firms`, `profiles`, `properties`, `phase_submissions.notes`,
   `phase_submissions.no_work_reason`, `phase_submissions.sequence_note`,
   `materials_sheets.contractor_name`, `materials_sheets.foreman_name`,
   `materials_sheets.notes`, `cs_replacement_authorizations.authorizing_supervisor`,
   `contractor_assignments.contractor_name`. Empty result set is the gate.

4. **Demo login auto-fill** — open `/auth`, click "Demo login", confirm
   the email + password fields populate and the login fires. Land on
   the dashboard with super_admin chrome.

5. **Banner-everywhere** — confirm the demo banner renders on:
   - `/auth` (logged-out auth screen)
   - Post-login app (any tab)
   - Any unknown route (Vercel SPA fallback to `index.html`)

   Production main should NOT show the banner unless the authenticated
   firm has `firm_safe_to_display = true`.

---

## Known scrub debt (Buddy queue)

### DB row content — 3 rows on the demo firm

As of 2026-05-03, the demo-firm DB rows still contain forbidden strings
that need updating before check 3 above passes:

- `phase_submissions.notes` row contains `"NJAW"` (1 row)
- `cs_replacement_authorizations.authorizing_supervisor` contains `"Carlo"` (1 row)
- `materials_sheets.notes` contains `"Carlo"` (1 row)

Buddy to ship a single small `apply_migration` updating those 3 rows
before the demo branch is considered acceptance-clean.

### DB schema — coupled identifiers in deployed JS

The Lead-side demo branch scrub (commit `<TBD after push>`) reduced
deployed-source hits in `index.html` from 37 → 20. The remaining 20 are
**DB-coupled identifiers that cannot be renamed in JS alone** — they
need a coordinated Buddy migration first. They fall into three buckets:

1. **`properties.sector` CHECK enum value `'NJAW_SHORT_HILLS'`** — appears
   in 9 JS comparisons (`if(value !== 'NJAW_SHORT_HILLS')`, sector edit
   modal logic, sector badge classifier). Renaming requires a migration
   like `ALTER TABLE properties DROP CONSTRAINT properties_sector_enum;
   ALTER TABLE properties ADD CONSTRAINT properties_sector_enum CHECK
   (sector IN ('AREA_A', 'AREA_B')); UPDATE properties SET sector = 'AREA_A'
   WHERE sector = 'NJ6_NORMAL'; UPDATE properties SET sector = 'AREA_B'
   WHERE sector = 'NJAW_SHORT_HILLS';` plus follow-up Lead PR replacing
   the constants in JS.
2. **`phase_submissions.njaw_work_order_code` column name** + matching
   `f-njaw-code` element ID + `njawCode` JS variable name. Rename column
   to `utility_work_order_code` (or similar), update CHECK enum, repoint
   the JS read + element ID. Migration + Lead frontend tweak.
3. **`materials_sheets.njaw_*_material` / `njaw_*_size_inches` /
   `njaw_*_amount_feet` columns** (5 columns on the row). Rename to
   `utility_*` or similar. Migration + Lead frontend tweak.

Plus 2 bulk-import alias map entries (`'njaw id'` and `'njaw_id'` mapping
to `mapcall_id`) which can stay as parser aliases — they're not visible
content, just CSV header normalization. **They will hit the grep though**;
either drop them on the demo branch (lose CSV import compatibility for
prospects pasting CSVs from external sources, which is a non-goal for
demo) or accept the grep hit as exempt.

**Recommended Buddy sequence:**
1. Demo-tenant maintenance cron + 3-row DB content scrub (immediate)
2. Sector enum rename migration (Lead PR follows on demo branch)
3. `phase_submissions.njaw_work_order_code` rename migration
4. `materials_sheets.njaw_*` columns rename migration

After all 4 land + the corresponding Lead PR(s) on the demo branch
update the JS, the deploy-source grep gate is achievable. Until then,
the demo branch is "as scrubbed as it can be without DB migration."

### Lead-side scrubs already shipped on demo branch

Recorded for diff-context (not requiring Buddy action):

- "Montana Construction" sidebar default → "Demo Tenant"
- "Carlo Domenick" CS-auth supervisor default → "Demo Supervisor" (×3 sites)
- "CDM-Smith compliance" modal sub → "compliance gate"
- "CP Engineers" sublabel on Work Description Code → "Internal classification"
- "NJAW Classification" label on utility code dropdown → "Utility Classification"
- "DEP/EPA/NJAW" mandate strings → "Regulatory" / "regulatory compliance"
- "NJAW Short Hills" sector display labels (×6 sites) → "Service Area B"
- "NJ6 Normal" stays as-is on user-visible labels (not a forbidden string)
- "CDM-Smith rule (a)" / "CDM-Smith rule a" comments + section titles → "compliance rule (a)" / "Compliance Rule (a)"
- "Carlo authorization required" banner subline → "Supervisor authorization required"
- HTML comment `MI-109 CARLO AUTHORIZATION MODAL` → `MI-109 SUPERVISOR AUTHORIZATION MODAL`
- "NJAW-XXXX" placeholder on MapCall input → "UTIL-XXXX"
- LUIS_SYSTEM prompt: "DEP, EPA, NJAW regulatory requirements" → "Regulatory requirements (DEP, EPA, utility-side)"
- Production-firm-by-name comment in CSS + JS init (×3 sites) → generic "production firms"

Net diff vs main: ~25 small replaces, no behavior change, no DB coupling
broken. All Lead-owned scrubs are reversible cherry-pick-back to main if
ever desired (which per the policy never happens).

---

## Cron — demo-tenant maintenance

**Status as of 2026-05-03:** `pg_cron` extension is **not yet installed** on
the project. Edge functions list shows only `luis-proxy` + `detect-whiteboard`,
neither cron-shaped. Buddy queue: install pg_cron + register the
demo-tenant-reset job (or ship a scheduled Edge Function with explicit
schedule), then update this doc with the cron schedule expression and
the verification query that confirms it's registered.

The maintenance cron's responsibilities:

- Reset the demo firm's data to seed state on a schedule (so prospects
  always see consistent fixtures, not whatever the last visitor entered)
- Rotate the public super_admin password (and update `loginAsDemo()` +
  this doc)
- Re-run the verification grep + alert if it surfaces hits
