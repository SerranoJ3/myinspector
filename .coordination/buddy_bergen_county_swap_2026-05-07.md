# Buddy Sync Note — Bergen County properties redistribution

**Cut:** 2026-05-07 ~03:30 EDT
**Author:** Buddy (Claude.ai web)
**Surface:** 1 prod migration + `index.html` (3 surgical edits)
**Branch:** demo-banner / mi-demo-seed (extending 2385c9e)

---

## What Jorge surfaced

Demo dashboard properties list + Submit Phase property dropdown still showed West Orange, Metuchen, Maplewood, Irvington — and "those towns are everywhere in MyInspector." Per directive: redistribute to **random Bergen County, NJ towns only**. Existing property data is throwaway dev/test — once CP signs as a paying customer, their real CSV dump replaces everything.

## Why the earlier 5/7 ~00:00 EDT towns swap missed this

That migration (`20260507002311_mi_demo_seed_14_swap_towns_to_non_njaw`) only updated `properties.city` for the 12 demo-firm properties. Two gaps it didn't close:

1. **`properties.municipality` was untouched.** Demo-firm properties had `city='Hoboken'/'Bayonne'/'Jersey City'/'Trenton'` but `municipality='Maplewood'/'Millburn'` (the role-inversion target town for the sector enum). The Property Detail and Submit Phase surfaces evidently render `municipality`, so Maplewood/Millburn still surfaced everywhere.
2. **CP Engineers firm's 33 properties were entirely out of scope.** Those held the West Orange/Metuchen/Maplewood/Irvington/Edison/Woodbridge/Neptune/Washington/Bogota mix Jorge actually saw, and the migration only touched the demo firm.

Total properties needing redistribution: **56 active rows** across both firms (33 CP + 22 demo + 1 net add since the earlier count).

## Migration shipped — `redistribute_properties_to_bergen_county_2026_05_07`

Single migration, write-mode Supabase MCP. Three steps with guard rails on both ends:

1. **Pre-flight count gate** — DO block raises if active property count is outside 50-60 (sanity check against schema drift).
2. **Address string cleanup** — strips `, Sampletown NJ` suffix from any address that embedded it (5 demo properties had `404 Demo Lane, Sampletown NJ` style strings). Address column should hold street-only; town goes in city/municipality.
3. **Bergen County redistribution** — 15 Bergen towns in a CTE, deterministic modulo distribution: `((ROW_NUMBER() OVER (ORDER BY firm_id, id) - 1) % 15) → town_idx`. Updates `city`, `municipality`, `zip` in one shot. Both town columns now match.
4. **Post-flight verification** — DO block scans for residual mentions of any excluded town (Maplewood/Millburn/Short Hills/West Orange/Irvington/Metuchen/Edison/Woodbridge/Neptune/Bayonne/Hoboken/Jersey City/Trenton/Washington/Demo City/Sampletown/Bogota) in either `city` or `municipality` and raises if any survived. Plus distinct-town count gate.

### Bergen towns + zips locked

| Town | Zip | Properties |
|---|---|---|
| Hackensack | 07601 | 4 |
| Paramus | 07652 | 4 |
| Teaneck | 07666 | 4 |
| Fort Lee | 07024 | 4 |
| Englewood | 07631 | 4 |
| Ridgewood | 07450 | 4 |
| Fair Lawn | 07410 | 4 |
| Bergenfield | 07621 | 4 |
| Mahwah | 07430 | 4 |
| Cliffside Park | 07010 | 4 |
| Lyndhurst | 07071 | 4 |
| Rutherford | 07070 | 3 |
| Tenafly | 07670 | 3 |
| Closter | 07624 | 3 |
| Garfield | 07026 | 3 |

Total: 56 properties / 15 towns / 11 towns at 4 props + 4 towns at 3 props.

### Why Bergen specifically (vs Hudson/Mercer from the earlier swap)

Bergen County is served by Veolia (formerly Suez/United Water), explicitly **not** part of NJ American Water's footprint. Hudson and Mercer have NJAW operating areas that overlap with CP's actual contract zones (e.g., Bayonne is a Suez town but neighbors NJAW Hudson territory; Trenton Water Works isn't NJAW but the prospect lens conflates utilities). Bergen has zero NJAW LCRI exposure → cleanest demo separation from Jorge's day-job.

## Code changes — `index.html` (3 surgical edits)

1. **Line 1141** — Add Property modal `placeholder="Edison"` → `placeholder="Hackensack"`
2. **Line 1145** — Add Property modal `placeholder="08817"` (Edison zip) → `placeholder="07601"` (Hackensack zip)
3. **Lines 1188+1191, 1226+1229** — Sector picker descriptive text in BOTH Add Property modal AND Sector Edit modal. `Default — CP / Essex County` → `Default — standard workflow`. `Millburn / SH role-inversion` → `Role inversion — inspector dictates spec`. Sector enum values themselves untouched (`NJ6_NORMAL` and `NJAW_SHORT_HILLS` stay as-is — rename is a separate parked ticket).

## Why those sector descriptors got swept too

Jorge named West Orange/Metuchen/Maplewood/Irvington explicitly. He did not name Millburn or Essex County. But the sector picker's descriptive subs read `Default — CP / Essex County` and `Millburn / SH role-inversion` — which would still anchor a Bergen-demo prospect to Essex County and Millburn the moment they opened the Add Property modal. On-policy with the stated directive ("everywhere"). Generalized text actually describes the product behavior more accurately (workflow type, not municipality).

## Post-migration verification

```sql
SELECT city, municipality, zip, COUNT(*) FROM properties WHERE deleted_at IS NULL
GROUP BY city, municipality, zip ORDER BY n DESC;
-- Returns 15 distinct rows, all city = municipality, all zips Bergen County
```

Result: 15 distinct (city, municipality, zip) tuples, all Bergen towns, all properties accounted for. Zero residual NJAW-footprint references in either column. Address strings with embedded "Sampletown NJ" cleaned to street-only.

## Side surfaces verified clean (no cascade work needed)

- **`materials_sheets`** — no address/city/municipality/zip columns. Visual tapcard pulls property data via JOIN at render time, so the migration cascades automatically to all materials_sheet visuals.
- **`phase_submissions`** — no address columns. `tapcard_data` jsonb scanned for any of the 16 excluded town strings → 0 hits across all 72 submissions. No drift.
- **`audit_log`** — chain not modified. Property updates flow through normal write_audit_log trigger; rows added incrementally per UPDATE.

## Gaps + carry-forward

- **CLAUDE.md** still references `QUIET-RIVER-58` placeholder text per the parked rotation cleanup ticket. Unrelated to this migration but flagging that any STATE.md or CLAUDE.md reads after this commit will include the placeholder reference.
- **Sector enum rename** (`NJAW_SHORT_HILLS` → `ROLE_INVERTED` or similar) is still parked. Today's sub-text edits are descriptor-only; the enum value stays. Tightening the enum would require a migration with full audit chain implications (sector references in phase_submissions + properties + parts_catalogs).
- **Property count is 56 not 55** as I called out in earlier session arc. Off-by-one likely from a property added between query passes. Migration handled it correctly via the count-tolerant pre-flight gate.

## What CC should do

```
git status — should show index.html modified
git add index.html .coordination/buddy_bergen_county_swap_2026-05-07.md
git commit -m "feat(demo-sanitize): redistribute properties to Bergen County + neutralize sector descriptors"
git push origin demo-banner
git checkout mi-demo-seed && git merge demo-banner --ff-only && git push origin mi-demo-seed
```

Vercel auto-deploys from each branch push; demo-banner alias will pick up the new placeholder text + neutralized sector subs within ~1 min. Database changes were applied directly via Supabase MCP — no migration commit needed in `supabase/migrations/` since this is demo data sanitization, not schema work. Migration is recorded in Supabase's `supabase_migrations.schema_migrations` table for audit/traceability.

## Click-test focus

After deploy READY:

1. Properties tab on dashboard → all cards now show Bergen towns (Hackensack, Paramus, Teaneck, etc.). No Maplewood/Edison/Irvington/etc. surviving.
2. Submit Phase → property select dropdown → Bergen towns only.
3. Property Detail modal → Overview tab → Address line shows street + Bergen city + Bergen zip.
4. Add Property modal → city placeholder reads "Hackensack", zip placeholder reads "07601".
5. Add Property modal → Sector picker subs read "Default — standard workflow" and "Role inversion — inspector dictates spec". No "Essex County" or "Millburn" text.
6. Sector Edit modal (super_admin god mode) → same neutralized descriptors.

Demo prospect can now walk every surface without seeing CP's actual contract-zone towns.
