# Work Order — MI-302 Construction PM Frontend (Contractor Arrival/Departure GPS Tracking)

**Authored:** 2026-05-05 ~21:45 EDT
**By:** Buddy
**For:** Lead — pickup-ready
**Authority:** Jorge granted Buddy batch trust. Schema verified via Supabase MCP `list_tables` 2026-05-05 21:25 EDT.

---

## Why this matters

**Construction PM Oversight is the strongest independent patent claim per Bill** (IP agent). The differentiator: GPS-verified contractor arrival/departure with billable hour reconciliation. Engineering firms (Jorge's customer profile) currently have no automated way to verify whether contractors actually arrived when they say they arrived, or stayed for the hours they billed for. Manual disputes consume PM time. Manual reconciliation is the bottleneck.

**MyInspector solves this.** Construction PM module logs contractor arrival with GPS coordinates, photo, timestamp; departure with same. The system auto-computes actual on-site hours, flags mismatches between billable and actual.

**Backend fully shipped (verified 2026-05-05 21:25 EDT):**
- `contractor_assignments` (15 cols) — contractor + project + role + active flag, RLS-locked
- `contractor_arrival_log` (16 cols) — gps_lat/lng/accuracy + photo_url + photo_whiteboard_detected + recorded_by + RLS
- `contractor_departure_log` (17 cols) — gps_lat/lng/accuracy + arrival_log_id FK linking back + RLS
- CP Engineers default project seeded (`722f9db8-...` NJAW LCRI Program 2026)

**Frontend is what's missing.** This work order ships v1 of the Construction PM module surface.

**Critical principle (locked, NEVER violate):** Construction PM tracks CONTRACTORS (Montana, Conquest), NOT inspectors. Inspector GPS tracking is a separate firm-level setting, default OFF. This work order's GPS tracking is for contractor accountability only.

---

## Locked answers (batch trust)

- **Q-302-b — Module navigation entry point:** New top-level "Construction PM" tab in main nav (alongside Properties, Submit Phase, etc.), conditionally visible to roles `super_admin / owner / supervisor / inspector` (the inspector logs the contractor — they're the field witness).
- **Q-302-c — Contractor selection at arrival log time:** Two paths — (a) inspector picks from `contractor_assignments` rows scoped to current project, (b) inspector creates new contractor on the fly if assignment doesn't exist yet (super_admin / supervisor only). Default to (a) — assignment-based; only surface (b) when no active assignments exist for the project.
- **Q-302-d — Photo requirement at arrival/departure:** Photo REQUIRED at arrival (proof of contractor on site). Photo optional at departure. Whiteboard detection runs on arrival photo via existing `detect-whiteboard` Edge Function — flags if whiteboard is visible (signals contractor is doing whiteboard-required work, surface the relevant rule).
- **Q-302-e — GPS accuracy threshold:** Log all GPS regardless of accuracy. If `gps_accuracy_meters > 50`, surface inline warning "GPS accuracy low — consider relogging closer to the work area."

---

## Verified ground truth — Construction PM schema

```
contractor_assignments  (15 cols)
- id, project_id FK, contractor_name, contractor_role enum, start_date, end_date, active boolean
- notes, firm_id FK, created_at, deleted_at, deleted_by

contractor_arrival_log  (16 cols)
- id, contractor_assignment_id FK, property_id FK (nullable)
- arrived_at timestamptz, gps_lat, gps_lng, gps_accuracy_meters
- photo_url, photo_whiteboard_detected boolean
- recorded_by_id FK, recorded_by_email, notes
- firm_id FK, created_at, deleted_at, deleted_by

contractor_departure_log  (17 cols)
- id, contractor_assignment_id FK, property_id FK (nullable)
- arrival_log_id FK → contractor_arrival_log (links back to start)
- departed_at timestamptz, gps_lat, gps_lng, gps_accuracy_meters
- photo_url, recorded_by_id FK, recorded_by_email, notes
- firm_id FK, created_at, deleted_at, deleted_by
```

CHECK constraints: gps_lat between -90 and 90, gps_lng between -180 and 180, gps_accuracy_meters >= 0.

---

## Unit 1 — Construction PM tab + assignment list view (~1 session)

1. New top-level nav tab "Construction PM" (visible to roles super_admin/owner/supervisor/inspector, hidden for office_staff)
2. Tab body: list of active `contractor_assignments` for current firm's active project, sorted by contractor_role (primary first) then alphabetical
3. Each row: contractor_name + role badge + active dot + start_date – end_date range + "Log Arrival" button (right-aligned)
4. Filter: Active / All
5. Top bar: "+ New Assignment" button (super_admin / supervisor only) — opens modal-contractor-assignment with contractor_name input, role dropdown (primary/subcontractor/specialty/other), start_date / end_date pickers, notes textarea
6. Empty state: "No active contractor assignments. Add one to start logging arrivals."

Commit Unit 1:

```
feat(MI-302 Unit 1): Construction PM tab + assignment list + new-assignment modal

- Top-level nav tab role-gated to super_admin/owner/supervisor/inspector
- Active assignment list, sortable by role, filter by Active/All
- Inline "Log Arrival" button per row
- New Assignment modal restricted to super_admin/supervisor
```

---

## Unit 2 — Arrival log workflow (~1 session)

1. "Log Arrival" button opens modal-contractor-arrival
2. Modal pre-fills: contractor_name (readonly from assignment), recorded_by from auth context
3. Fields: property_id (optional, dropdown of active properties for current project), notes (optional)
4. Auto-capture on modal open: GPS via `navigator.geolocation` → fills gps_lat / gps_lng / gps_accuracy_meters
5. Photo capture: REQUIRED. Camera input with capture preference (rear-facing on mobile). Photo uploads to `contractor-photos` storage bucket, path `{firm_id}/{contractor_assignment_id}/arrival/{timestamp}.jpg`
6. Whiteboard detection: existing `detect-whiteboard` Edge Function runs on photo upload, sets `photo_whiteboard_detected` boolean
7. Submit button: writes row to `contractor_arrival_log`, closes modal, refreshes list view to show "On site since [time]" badge on the assignment row + "Log Departure" button replaces "Log Arrival"
8. GPS accuracy warning: if `gps_accuracy_meters > 50`, inline orange warning before submit

Commit Unit 2:

```
feat(MI-302 Unit 2): Arrival log workflow with GPS + required photo + whiteboard detection

- Auto GPS capture on modal open
- Photo required, uploads to contractor-photos bucket
- detect-whiteboard Edge Function flags whiteboard visibility
- GPS accuracy warning above 50m threshold
- Post-submit: assignment row updates to "On site since [time]" + Log Departure button
```

---

## Unit 3 — Departure log workflow + reconciliation (~1 session)

1. "Log Departure" button opens modal-contractor-departure
2. Modal pre-fills: contractor_name (readonly), arrival_log_id (auto-link to most recent arrival without departure), recorded_by
3. Fields: notes (optional)
4. Auto-capture GPS
5. Photo capture: OPTIONAL (per Q-302-d=d)
6. Submit: writes row to `contractor_departure_log`, computes elapsed time (departed_at - arrival_log.arrived_at), surfaces in confirmation message ("Logged 4h 22min on site")
7. Post-submit: assignment row reverts to "Log Arrival" state for next visit

Commit Unit 3:

```
feat(MI-302 Unit 3): Departure log workflow with auto-link to arrival + elapsed time

- Auto-links to most recent arrival via arrival_log_id FK
- Auto GPS capture, photo optional
- Computes elapsed time on submit, surfaces in confirmation
- Assignment row resets to Log Arrival state post-departure
```

---

## Unit 4 — Daily reconciliation report (~1-2 sessions, optional v1.5)

1. New "Daily Report" tab inside Construction PM
2. Date picker, defaults to today
3. Per-contractor summary: total elapsed hours, count of arrivals, count of departures
4. Mismatch flag: arrivals without matching departure (still on site, or forgot to log departure)
5. CSV export per day (super_admin / supervisor)
6. Foundation for future billable-vs-actual comparison feature (post-v1)

Commit Unit 4 (if shipped):

```
feat(MI-302 Unit 4): Daily reconciliation report + mismatch flagging + CSV export
```

---

## Acceptance criteria

1. Inspector opens Construction PM tab → sees CP Engineers' active assignments (currently 1 seeded: NJAW LCRI Program 2026)
2. Tap "Log Arrival" on an assignment → GPS auto-fills, photo capture works, submit succeeds
3. Row updates to "On site" with timestamp + Log Departure button
4. Tap "Log Departure" → submits with elapsed time
5. Multiple arrival/departure cycles per day work (return visits)
6. Whiteboard detection fires correctly when whiteboard in photo
7. GPS accuracy warning surfaces when meters > 50
8. RLS verified: inspector A (firm A) cannot see firm B's contractor logs
9. Office_staff role does not see Construction PM tab
10. Super_admin can create new assignments

---

## Closing actions

- Push demo-banner to origin (4 commits if all units ship)
- Update STATE.md: MI-302 v1 closed (or partial close if Unit 4 deferred)
- Update status.md: Construction PM frontend in recently-shipped
- Append decisions.md entries for Q-302-b/c/d/e ratifications
- Final session-close commit

---

## Stop conditions

- GPS API permission flow ambiguity (browser permission dialog handling)
- `contractor-photos` storage bucket doesn't exist (need migration to create + RLS lock)
- BUDDY_STANDARD locked principle conflict

## Do NOT stop for

- UI polish on the assignment list view (Lead's craft)
- Mobile responsive specifics (Lead's craft)
- Empty-state copy variations
- CSV export column choices (Lead's call)

## Velocity estimate

3-4 sessions total. Units 1+2+3 ship v1 ready for Jeff demo. Unit 4 ships v1.5.

## Verified ground truth footer

- Branch state: no Construction PM frontend on main or demo-banner — verified via grep for `modal-contractor-arrival` returns 0
- Schema: all 3 Construction PM tables verified present 2026-05-05 21:25 EDT via Supabase MCP `list_tables`
- Seed: contractor_assignments has 1 row (NJAW LCRI Program 2026 / contractor_name TBD per Jorge) — verified
- detect-whiteboard Edge Function: existing pattern from photo capture, reusable
- Storage bucket `contractor-photos` may need creation migration (TBD pre-execution check)
