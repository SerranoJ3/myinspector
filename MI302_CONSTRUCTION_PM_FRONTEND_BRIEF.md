# MI-302 Construction PM frontend brief — Contractor arrival/departure tracking

**Status:** Drafted by Buddy 2026-05-03 PM. Awaiting Jorge ratification before Lead picks up.
**Estimated:** ~4–6 sessions.
**Branch:** `mi302-construction-pm-frontend` off main.

---

## What this ships

The frontend half of the Construction PM Oversight feature. Backend is **already shipped on prod** — three tables (`contractor_assignments`, `contractor_arrival_log`, `contractor_departure_log`) are live with full schema, RLS forced, firm_id indexed, soft-delete columns. No migrations required.

This feature lets Jorge (or any supervisor) verify Montana Construction's billable hours against GPS + photo evidence at the property level. Translation: **a direct sales angle for engineering firms managing contractor billable disputes** — and an internal tool that pays for itself the first time it catches an over-billed hour.

---

## Locked product principles this honors

(From `CLAUDE.md` + locked memory.)

1. **Inspector GPS tracking is firm-level, default OFF.** Inspector tracking and contractor tracking are **entirely separate features**. This brief touches contractor tracking only. Inspector tracking is not affected. (Locked.)
2. **Contractor consent is implicit via the construction-project employment relationship**, but the feature is supervisor-driven (the inspector or supervisor logs the contractor's arrival, not the contractor self-reporting). This sidesteps consent issues with non-employee contractors.
3. **Audit chain immutable.** Each arrival/departure log entry is hash-chained per the existing audit trigger pattern.
4. **Whiteboard detection is reused** (the existing `detect-whiteboard` Edge Function). Optional on contractor arrival photos — supervisor can use it to verify that the contractor was actually at the property (not just nearby).

---

## What's already shipped (backend)

Verified 2026-05-03 PM via Supabase MCP. **All three tables are RLS-locked with firm_id indexes:**

### `contractor_assignments`

Defines who is contracted to what project. Long-lived (start_date → end_date).

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | gen_random_uuid() |
| project_id | uuid NOT NULL | FK to projects |
| contractor_name | text NOT NULL | "Montana Construction" |
| contractor_role | text | "Excavation contractor", etc. |
| start_date | date | |
| end_date | date | |
| active | boolean NOT NULL DEFAULT true | |
| notes | text | |
| firm_id | uuid NOT NULL | RLS scope |
| created_at, deleted_at, deleted_by | standard soft-delete columns |

### `contractor_arrival_log`

One row per inspector-logged contractor arrival. GPS-stamped, photo-optional.

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| contractor_assignment_id | uuid NOT NULL | FK |
| property_id | uuid | nullable for off-property events |
| arrived_at | timestamptz NOT NULL | |
| gps_lat, gps_lng | numeric NOT NULL | required GPS at log time |
| gps_accuracy_meters | numeric | |
| photo_url | text | optional |
| photo_whiteboard_detected | boolean | optional, reuses Vision pipeline |
| recorded_by_id | uuid | inspector who logged |
| recorded_by_email | text | denormalized for audit |
| notes | text | |
| firm_id | uuid NOT NULL | RLS scope |
| created_at, deleted_at, deleted_by | standard |

### `contractor_departure_log`

One row per departure. Links back to arrival via `arrival_log_id`.

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| contractor_assignment_id | uuid NOT NULL | FK |
| property_id | uuid | |
| arrival_log_id | uuid | links back to specific arrival |
| departed_at | timestamptz NOT NULL | |
| gps_lat, gps_lng, gps_accuracy_meters | required GPS | |
| photo_url | text | optional |
| recorded_by_id, recorded_by_email | inspector who logged | |
| notes | text | |
| firm_id | uuid NOT NULL | RLS scope |
| created_at, deleted_at, deleted_by | standard |

---

## Scope by surface (frontend only)

### Surface 1 — Contractor Assignments admin (firm setup)

**Where:** new tab on the existing Settings/Admin screen for super_admin role only.

**What:** CRUD for `contractor_assignments`. List view + create form + edit form + soft-delete.

**Rows:** name, role, project, start_date, end_date, active, count of arrivals logged.

**Create form fields:**
- Project (dropdown of active projects in the firm)
- Contractor name (text)
- Contractor role (text; suggestion list: "Excavation", "Restoration", "Plumbing", "Other")
- Start date (date picker)
- End date (date picker, optional)
- Notes (textarea)

**Acceptance:** super_admin can create, edit, deactivate (set active=false), and soft-delete contractor assignments. Inspector role does NOT see this tab.

### Surface 2 — Log Contractor Arrival (inspector flow)

**Where:** new button on Property Detail modal: "Log contractor arrival." Visible only when an active contractor_assignment exists for the property's project.

**Flow:**

1. Inspector taps button.
2. App requests GPS (browser geolocation API). Inspector grants permission.
3. App auto-populates: arrived_at = now(), gps_lat/lng/accuracy = current.
4. Camera capture (optional but encouraged) — same flow as existing photo capture, runs through `detect-whiteboard` if Vision API has budget.
5. Notes textarea (optional, ≤ 500 chars).
6. "Log arrival" button — saves a row to `contractor_arrival_log`.

**Default photo prompt text:** "Take a photo showing the contractor's truck or excavator + the property in the same frame."

**Acceptance:** inspector can log an arrival in ≤ 30 seconds (GPS + 1 photo + tap save). Row appears on supervisor dashboard within a few seconds.

### Surface 3 — Log Contractor Departure

**Where:** new button on Property Detail modal: "Log contractor departure." Only visible when there's an unmatched arrival (an `arrival_log` row with no corresponding `departure_log` row) for the same contractor + property.

**Flow:**

1. Same as arrival, with one addition: the form auto-links the most recent unmatched arrival via `arrival_log_id`.
2. Departure form shows duration: "On site for X hr Y min" computed from arrived_at to now().

**Acceptance:** can log departure in ≤ 30 seconds. Duration displays correctly. Departure log row links back to the right arrival.

### Surface 4 — Supervisor dashboard tile: Today's contractor activity

**Where:** new tile on the existing supervisor dashboard.

**Content:**
- Header: "Contractors on site today"
- Per-contractor rows: name, current status (on-site / off-site), last arrival time, last departure time, total minutes today
- Click-through to per-contractor detail view

### Surface 5 — Per-contractor detail view (billable-hour export)

**Where:** click-through from Surface 4.

**Content:**
- Header: "[Contractor name] — [project]"
- Date-range picker (default: today, last 7 days, last 30 days, custom range)
- Table: arrival_at, departure_at, property address, duration, GPS distance from property, photo thumbnails
- Footer: "Total billable hours in range: X.XX hr"
- Export button: CSV (rows) + PDF (summary report)

**CSV columns:** date, contractor_name, property_address, arrived_at, departed_at, duration_minutes, gps_distance_meters_from_property, arrival_photo_url, departure_photo_url, notes.

**Acceptance:** supervisor can pull a 30-day billable-hour CSV in ≤ 5 seconds, ready to compare against the contractor's invoice.

### Surface 6 — Anomaly flags (small, optional v1)

The supervisor view can flag pairings that look weird:

- **Arrival without GPS proximity to property:** > 50m from the property polygon → ⚠️ "GPS accuracy concern"
- **Arrival without paired departure:** > 12 hours since arrival → ⚠️ "Open arrival"
- **Departure without paired arrival:** ⚠️ "Departure log without arrival" (data integrity flag)

Anomalies show as small badges next to the row; clicking shows the detail.

---

## Acceptance criteria (8 items, all must pass before PR opens)

1. **Super_admin can create + edit + deactivate + soft-delete contractor assignments** via the Settings tab.
2. **Inspector can log arrival** on Property Detail modal in ≤ 30 sec real-world test.
3. **GPS captures correctly** with accuracy_meters populated.
4. **Photo upload works** end-to-end (file uploads to storage, photo_url populated, optional whiteboard_detected fires when Vision API enabled).
5. **Departure flow links back to arrival** correctly via `arrival_log_id`.
6. **Supervisor dashboard tile updates within seconds** of arrival being logged.
7. **CSV export produces parseable, billable-hour-correct data** for a 30-day date range with at least 5 arrivals + departures.
8. **Inspector role does NOT see the Settings tab** for contractor assignments. (Privacy gate per locked principle: this is supervisor/super_admin only.)

---

## What this brief deliberately does NOT include

- **Contractor self-service portal** — contractors do NOT have accounts in MyInspector v1. All logging is supervisor/inspector-driven.
- **Real-time chat with contractors** — out of scope.
- **Multi-arrival-per-property-per-day** — v1 supports one open arrival at a time per (contractor, property) pair. If a contractor leaves and comes back the same day, they need a fresh arrival log. Most-recent-unmatched logic handles this cleanly.
- **GPS geofence alerts** — v1 flags anomalies in the dashboard but doesn't push notifications. v2.
- **Vehicle/equipment tracking** — v1 is per-person/per-contractor. Equipment fleet tracking is a separate feature.
- **Wage rate calculations** — v1 reports billable hours, not dollar amounts. Wage rates live in the firm's billing system, not MyInspector.

---

## Cross-cutting decisions to lock during build (Lead surfaces in `decisions.md`)

1. **GPS permission UX.** Modal dialog before button visible vs. button always visible + permission prompt at tap. **Buddy recommendation:** button always visible + prompt at tap. Lower friction, only asks when needed.
2. **Photo storage path.** Reuse existing `phase-photos` Supabase Storage bucket vs. new `contractor-photos` bucket. **Buddy recommendation:** new bucket. Privacy boundary is meaningfully different (contractor photos can include the contractor's truck + visual ID; phase photos are work-site only). Different retention/access patterns over time.
3. **Whiteboard detection on arrival photos.** On by default vs. opt-in. **Buddy recommendation:** off by default for contractor arrival photos. Whiteboard detection is meant for inspector photos showing work-site whiteboard; contractor arrivals are a different photo subject. Save the Vision API budget for the inspector flow that needs it.

---

## Verification queries Lead should run (post-merge)

```sql
-- 1. Today's contractor activity summary
SELECT
  ca.contractor_name,
  count(DISTINCT al.id) FILTER (WHERE al.arrived_at::date = current_date) AS arrivals_today,
  count(DISTINCT dl.id) FILTER (WHERE dl.departed_at::date = current_date) AS departures_today,
  count(DISTINCT al.id) FILTER (WHERE al.deleted_at IS NULL) - count(DISTINCT dl.arrival_log_id) FILTER (WHERE dl.deleted_at IS NULL) AS open_arrivals
FROM contractor_assignments ca
LEFT JOIN contractor_arrival_log al ON al.contractor_assignment_id = ca.id AND al.deleted_at IS NULL
LEFT JOIN contractor_departure_log dl ON dl.contractor_assignment_id = ca.id AND dl.deleted_at IS NULL
WHERE ca.firm_id = (SELECT firm_id FROM profiles WHERE id = auth.uid())
  AND ca.active = true
  AND ca.deleted_at IS NULL
GROUP BY ca.id, ca.contractor_name;

-- 2. Billable-hour totals for a contractor over a date range
SELECT
  ca.contractor_name,
  date_trunc('day', al.arrived_at) AS day,
  count(*) AS arrivals,
  sum(EXTRACT(EPOCH FROM (dl.departed_at - al.arrived_at))/3600.0) AS billable_hours
FROM contractor_arrival_log al
JOIN contractor_assignments ca ON ca.id = al.contractor_assignment_id
LEFT JOIN contractor_departure_log dl ON dl.arrival_log_id = al.id AND dl.deleted_at IS NULL
WHERE al.deleted_at IS NULL
  AND al.arrived_at > current_date - interval '30 days'
GROUP BY ca.id, ca.contractor_name, date_trunc('day', al.arrived_at)
ORDER BY day DESC, ca.contractor_name;

-- 3. Open arrival anomalies (> 12h without paired departure)
SELECT
  ca.contractor_name,
  p.address,
  al.arrived_at,
  EXTRACT(EPOCH FROM (now() - al.arrived_at))/3600.0 AS hours_since_arrival
FROM contractor_arrival_log al
JOIN contractor_assignments ca ON ca.id = al.contractor_assignment_id
LEFT JOIN properties p ON p.id = al.property_id
LEFT JOIN contractor_departure_log dl ON dl.arrival_log_id = al.id AND dl.deleted_at IS NULL
WHERE al.deleted_at IS NULL
  AND dl.id IS NULL
  AND al.arrived_at < now() - interval '12 hours'
ORDER BY al.arrived_at;
```

---

## Sequencing note

This brief has minimal cross-dependency on Phase 2c or Phase 4. Lead can pick this up in parallel with either, OR in priority sequence after Phase 2c (since Phase 2c unlocks more LCRI work, while Construction PM is more about supervisor utility + sales differentiation).

**Buddy recommendation: Phase 2c first, Construction PM second, Phase 4 third.** Reasoning:
- Phase 2c unlocks an entire geographic sector (ShortHills) that's part of CP's active work
- Construction PM ships a sales-deck-grade feature with 90% of work already done (backend complete)
- Phase 4 is the highest-risk, highest-novelty work and benefits from being fresh (not late-week/late-day)

Lead's call. All three are well-specced; sequencing is a Jorge prerogative.

---

## Q-302-a (open): Project lifecycle gate

`contractor_assignments.project_id` is required NOT NULL. Are projects already populated in prod? Verified 2026-05-03 PM that `projects` table exists with `firm_id` indexed (partial). Need to confirm whether CP Engineers has at least one active project record. If not, the Settings tab will need a "create project" sub-flow, OR Lead should seed a default project in the firm-onboarding flow.

## Q-302-b (open): Photo verification UX

Should the supervisor view show arrival/departure photos inline (thumbnails + lightbox) or behind a "View photos" link?

**Buddy default: inline thumbnails (40×40) + lightbox on click.** Photos are the proof; making them one tap away keeps the supervisor honest about reviewing them.

## Q-302-c (open): GPS distance threshold for "GPS accuracy concern" anomaly

Brief proposes 50m from property polygon. Is that the right threshold for NJ urban properties? Lead can tune based on first 30 days of real data.
