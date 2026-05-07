# Brief — Wastewater / Sewer Module v0 Schema (Module 2 of 7)

**Authored:** 2026-05-05 ~21:55 EDT
**By:** Buddy
**For:** Lead — pickup-ready (next session OR parallel with Phase 2d-revision)
**Authority:** Jorge granted Buddy batch trust. New module backend; complements existing Water Utility module schema.

---

## Why this matters

MyInspector is architected as a **7-module engineering inspection platform**. Tonight, Water Utility is ~65% v1.0 complete (LCRI workflow). The other 6 modules are unstarted. **Wastewater / Sewer is the highest-leverage second module** because:

1. NJ municipalities and water authorities frequently bundle water + sewer inspection contracts (one inspector, two scopes)
2. Schema overlaps significantly with water utility — properties, photo capture, sector dispatch, audit chain all reusable
3. Engineering firms already serving NJAW (Jorge's customer profile) often serve county sewer districts too — same buyer, expanded scope
4. Demo to Jeff: showing 2 modules instead of 1 changes the perceived ambition of the platform from "single-purpose tool" to "multi-discipline platform"

**Backend-only scope tonight.** Frontend ships in a separate ticket later. This is foundational migration work.

---

## Module design philosophy

The 7-module architecture lives on a single `inspections` table (already shipped, 40 columns) keyed by `module_key`. New modules add:
- A new value to a `modules` table (already shipped, 7 rows seeded)
- Module-specific columns on `inspections` (or sub-table if shape diverges significantly)
- Sector dispatch if applicable (some modules are state-wide, others sector-scoped)

**Wastewater / Sewer module key:** `wastewater_sewer`

Inspection types within this module (initial v0 enum):
- `manhole_inspection`
- `pipe_condition_assessment`
- `flow_monitoring`
- `cctv_inspection`
- `i_and_i_assessment` (Inflow & Infiltration)
- `lateral_inspection`
- `pump_station_inspection`
- `lift_station_inspection`

These map to NJDEP and EPA NPDES (National Pollutant Discharge Elimination System) inspection categories — common sewer inspection scope across NJ municipalities.

---

## Schema additions

### Migration 1 — register module

```sql
INSERT INTO public.modules (key, name, description, active) VALUES
  ('wastewater_sewer', 'Wastewater / Sewer',
   'Wastewater collection system inspection — manholes, pipe condition, flow monitoring, CCTV, I&I, laterals, pump and lift stations.',
   true);
```

### Migration 2 — extend `inspections` table for sewer-specific fields

Most fields already exist (gps, photos, whiteboard, contractor_name, percent_complete, billable_hours). New columns needed:

```sql
ALTER TABLE public.inspections
  ADD COLUMN IF NOT EXISTS sewer_inspection_type text
    CHECK (sewer_inspection_type IS NULL OR sewer_inspection_type = ANY (ARRAY[
      'manhole_inspection',
      'pipe_condition_assessment',
      'flow_monitoring',
      'cctv_inspection',
      'i_and_i_assessment',
      'lateral_inspection',
      'pump_station_inspection',
      'lift_station_inspection'
    ])),
  ADD COLUMN IF NOT EXISTS manhole_id text,
  ADD COLUMN IF NOT EXISTS upstream_manhole_id text,
  ADD COLUMN IF NOT EXISTS downstream_manhole_id text,
  ADD COLUMN IF NOT EXISTS pipe_diameter_inches numeric CHECK (pipe_diameter_inches IS NULL OR pipe_diameter_inches > 0),
  ADD COLUMN IF NOT EXISTS pipe_material text,
  ADD COLUMN IF NOT EXISTS pipe_condition_rating int CHECK (pipe_condition_rating IS NULL OR pipe_condition_rating BETWEEN 1 AND 5),
  ADD COLUMN IF NOT EXISTS structural_defect_codes text[],  -- NASSCO PACP defect codes
  ADD COLUMN IF NOT EXISTS oandm_defect_codes text[],       -- NASSCO O&M codes
  ADD COLUMN IF NOT EXISTS flow_depth_inches numeric CHECK (flow_depth_inches IS NULL OR flow_depth_inches >= 0),
  ADD COLUMN IF NOT EXISTS flow_velocity_fps numeric CHECK (flow_velocity_fps IS NULL OR flow_velocity_fps >= 0),
  ADD COLUMN IF NOT EXISTS cctv_video_url text,
  ADD COLUMN IF NOT EXISTS cctv_distance_traveled_feet numeric CHECK (cctv_distance_traveled_feet IS NULL OR cctv_distance_traveled_feet >= 0),
  ADD COLUMN IF NOT EXISTS i_i_signs_observed boolean,
  ADD COLUMN IF NOT EXISTS i_i_severity text CHECK (i_i_severity IS NULL OR i_i_severity = ANY (ARRAY['none','minor','moderate','severe'])),
  ADD COLUMN IF NOT EXISTS pump_station_id text,
  ADD COLUMN IF NOT EXISTS pump_status text CHECK (pump_status IS NULL OR pump_status = ANY (ARRAY['operational','degraded','offline','maintenance'])),
  ADD COLUMN IF NOT EXISTS h2s_ppm numeric CHECK (h2s_ppm IS NULL OR h2s_ppm >= 0);
```

These columns coexist with the water utility columns (which are largely null for sewer inspections, and vice versa). Module key on the row determines which fields are meaningful.

### Migration 3 — sub-table for CCTV defect log (one row per defect observed)

```sql
CREATE TABLE public.cctv_defect_observations (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  inspection_id uuid NOT NULL REFERENCES public.inspections(id),
  firm_id uuid NOT NULL REFERENCES public.firms(id),
  observed_at_distance_feet numeric NOT NULL CHECK (observed_at_distance_feet >= 0),
  defect_code text NOT NULL,                -- NASSCO PACP code, e.g. 'CL-J' (crack longitudinal joint)
  defect_category text CHECK (defect_category = ANY (ARRAY['structural','o_and_m','construction','miscellaneous'])),
  severity int CHECK (severity BETWEEN 1 AND 5),
  clock_position int CHECK (clock_position BETWEEN 1 AND 12),  -- 1-12 like a clock face for radial position
  notes text,
  photo_url text,
  video_clip_url text,
  observed_by uuid REFERENCES auth.users(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by uuid REFERENCES auth.users(id)
);

ALTER TABLE public.cctv_defect_observations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cctv_defect_observations FORCE ROW LEVEL SECURITY;

CREATE POLICY cctv_defect_obs_read_firm ON public.cctv_defect_observations
  FOR SELECT TO authenticated USING (firm_id = current_firm_id() AND deleted_at IS NULL);

CREATE POLICY cctv_defect_obs_write_firm ON public.cctv_defect_observations
  FOR INSERT TO authenticated WITH CHECK (firm_id = current_firm_id());

CREATE POLICY cctv_defect_obs_update_firm ON public.cctv_defect_observations
  FOR UPDATE TO authenticated
  USING (firm_id = current_firm_id())
  WITH CHECK (firm_id = current_firm_id());

CREATE INDEX cctv_defect_obs_inspection ON public.cctv_defect_observations (inspection_id);
CREATE INDEX cctv_defect_obs_firm_created ON public.cctv_defect_observations (firm_id, created_at DESC);

-- Audit triggers (matching standard pattern from existing tables)
CREATE TRIGGER audit_cctv_defect_obs_iud
  AFTER INSERT OR UPDATE OR DELETE ON public.cctv_defect_observations
  FOR EACH ROW EXECUTE FUNCTION public.write_audit_log();
```

### Migration 4 — manhole reference data table

Manholes are persistent geographic assets. Inspections reference them. Don't store manhole properties redundantly per inspection — track manholes as first-class entities.

```sql
CREATE TABLE public.manholes (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  firm_id uuid NOT NULL REFERENCES public.firms(id),
  manhole_id_external text NOT NULL,        -- municipality's manhole ID e.g., 'MH-1042'
  street_address text,
  cross_street text,
  municipality text,
  county text,
  lat numeric CHECK (lat IS NULL OR (lat >= -90 AND lat <= 90)),
  lng numeric CHECK (lng IS NULL OR (lng >= -180 AND lng <= 180)),
  rim_elevation_feet numeric,
  invert_elevation_feet numeric,
  depth_feet numeric CHECK (depth_feet IS NULL OR depth_feet >= 0),
  diameter_inches numeric CHECK (diameter_inches IS NULL OR diameter_inches > 0),
  material text,           -- e.g., 'precast_concrete','brick','block'
  cover_type text,         -- e.g., 'standard','watertight','vented'
  notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by uuid REFERENCES auth.users(id),
  UNIQUE (firm_id, manhole_id_external)
);

ALTER TABLE public.manholes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manholes FORCE ROW LEVEL SECURITY;

CREATE POLICY manholes_read_firm ON public.manholes
  FOR SELECT TO authenticated USING (firm_id = current_firm_id() AND deleted_at IS NULL);
CREATE POLICY manholes_write_firm ON public.manholes
  FOR INSERT TO authenticated WITH CHECK (firm_id = current_firm_id());
CREATE POLICY manholes_update_firm ON public.manholes
  FOR UPDATE TO authenticated
  USING (firm_id = current_firm_id())
  WITH CHECK (firm_id = current_firm_id());

CREATE INDEX manholes_firm_external ON public.manholes (firm_id, manhole_id_external);
CREATE INDEX manholes_firm_municipality ON public.manholes (firm_id, municipality);

CREATE TRIGGER audit_manholes_iud
  AFTER INSERT OR UPDATE OR DELETE ON public.manholes
  FOR EACH ROW EXECUTE FUNCTION public.write_audit_log();
```

---

## NASSCO PACP defect codes (industry standard)

Wastewater/sewer CCTV inspection in the US follows NASSCO PACP (Pipeline Assessment Certification Program) coding. The codes are public-domain industry standard. v0 stores them as text (Lead doesn't need to enumerate all 200+ codes in CHECK constraint — store the strings, validate via lookup table in v1).

Common codes for v0 reference (Lead doesn't need to memorize these — just store):
- CL-J: Crack Longitudinal Joint
- CC: Crack Circumferential
- CM: Crack Multiple
- F: Fracture
- BSV: Broken
- DAR: Deposit Attached
- DSGV: Deposit Settled Gravel
- ISG: Infiltration Stain
- IDG: Infiltration Dripper
- RBJ: Roots Barrel Joint

Future v1 work: load full PACP code reference table for dropdown autocomplete in inspector UI.

---

## RLS posture verification

All new tables use the firm-scoped read/write pattern matching existing schema. `current_firm_id()` and `current_user_role()` helper functions already shipped. Audit triggers attach via `write_audit_log` (already exists, MI-AUDIT-3 enhanced tonight). Hash chain trigger continues to fire.

---

## Acceptance criteria

1. Migrations 1-4 apply clean via Supabase MCP
2. `modules` table now has 8 rows (was 7), `wastewater_sewer` row visible
3. `inspections` table has new sewer-specific columns; existing rows unaffected
4. `cctv_defect_observations` and `manholes` tables created with RLS forced
5. Audit triggers fire on INSERT/UPDATE/DELETE for both new tables (test with a sample row + verify audit_log delta)
6. RLS verified: insert into manholes from one firm, query from another firm returns 0 rows
7. CHECK constraints fire on bad data (e.g., severity=6 rejected)

---

## What this work order does NOT include

- Frontend UI for sewer inspections (separate ticket, MI-303 for example)
- Sample data seeding (Lead may seed 1-2 manholes for CP Engineers as test data, optional)
- PACP defect code reference table (v1 work, separate migration)
- Integration with municipality manhole datasets (post-v1)
- Pump station SCADA integration (post-v1, requires custom MCP or webhook design)

This is foundational backend only. Frontend ships separately when the schema is verified live.

---

## Stop conditions

- Migration 2 (`ALTER TABLE inspections`) hits unexpected schema state — stop, surface diff
- BUDDY_STANDARD locked principle conflict
- Audit trigger attach fails on new tables (would indicate `write_audit_log` ABI break — should not happen post-MI-AUDIT-3)

## Do NOT stop for

- PACP defect code list completeness (v0 stores strings, v1 enumerates)
- Manhole field coverage edge cases (Lead's call on additional columns)
- Whether to seed sample data (Lead's call)

## Velocity estimate

~1 session to apply all 4 migrations + verify acceptance. Buddy can execute directly via Supabase MCP `apply_migration` if Lead chooses to delegate.

## Verified ground truth footer

- `modules` table has 7 rows currently — verified 2026-05-05 21:25 EDT via Supabase MCP
- `inspections` table 40 columns currently — adding ~16 new columns brings to ~56
- `current_firm_id()` and `current_user_role()` helpers verified shipped (used by all existing RLS policies)
- `write_audit_log` function verified post-MI-AUDIT-3 enhancement (heartbeat skip filter live as of f99b6f0 commit)
- No existing manholes or cctv_defect_observations tables — verified clean creation
