# Back Burner

Ideas that are real but not now. Each entry locks the concept, the technical reality, and the trigger condition that would un-park it. Re-evaluate at trigger, not before.

---

## BB-001 — AR Auto-Fill Tapcard (iPad-first)

**Captured:** 2026-05-03 (Sunday afternoon, post-`.org` registration)
**Origin:** Jorge field instinct
**Status:** Parked. Trigger: first paying non-CP customer signs.

### The mechanic

Inspector stands at the curb stop (CS) → taps "Start triangulation" in the tapcard UI. Walks to each measurement target (MP, watermain tap, etc.) → taps "End point" at each stop. iPad ARKit + compass + IMU captures (distance, bearing, relative orientation) per stop. Diagram auto-draws on screen as inspector moves; tapcard fields auto-populate (CS-to-MP distance, MP-to-tap, bearing relative to CS anchor).

Manual click-and-drag fallback always available alongside — never replaced. AR is an option, not the only path.

### Why it's actually good

- Collapses 5 minutes of tape-measure + freehand sketch + transcription into ~30 seconds
- Real product differentiator vs. Procore / Bluebeam / Autodesk Construction Cloud (none do this for water-utility tapcards)
- LinkedIn-video moment when it works (sales asset)
- Aligns with locked core principle: "inspectors do NOT do extra work for the app" — AR removes work, doesn't add it

### Why iPad changes the math

Every CP inspector has a company-issued iPad. That eliminates:
- Android fragmentation (ARCore behaves differently across OEMs)
- LiDAR-availability concerns (most non-Pro Androids lack it)
- "Premium iPhone Pro tier" pricing problem
- One-shell fork only (iPad), not three (iOS phone, iPad, Android)

Personal phone use stays optional for inspectors who want it; nobody is forced to install a work app on their personal device. (Jorge flagged at least one inspector who would refuse — fallback is required from day one anyway.)

### Technical caveats (real, not hand-waved)

1. **Compass drift over buried metal.** Tapcards are written standing on top of iron service lines, manhole covers, rebar in concrete. Magnetic readings can swing 5–30° off true. Mitigation: site-calibration step at session start (compass against known bearing, e.g., curb line via GPS-derived heading) + GPS-derived bearing as a cross-check on each measurement.
2. **Native shell required.** MyInspector is a web SaaS. iOS Safari WebXR can't sustain the continuous AR tracking needed. Solutions:
   - Capacitor / React Native shell wrapping the existing web app (~6–8 sessions to scaffold)
   - Or separate native iPadOS app (~12–16 sessions)
3. **Manual fallback is required, not optional.** Click-and-draw must remain first-class — same UI quality as AR mode, not a degraded "advanced users only" hidden path. The inspector who refuses AR is sometimes the most accurate guy on the crew.

### Estimated build

- Native shell scaffold: ~6–8 sessions
- ARKit triangulation loop + UI: ~10–14 sessions
- Diagram auto-fill bridge to existing tapcard form: ~4–6 sessions
- Site-calibration UX + compass cross-check: ~3–4 sessions
- **Total: ~25–32 sessions** on top of existing Phase 4 manual editor (~6 sessions)

That's not a sprint addition. That's a quarter-long native-app initiative.

### Trigger to un-park

**First paying non-CP customer signs.** Until then, this is a delight feature looking for a reason. After first dollar, it becomes a moat — the thing prospects #2, #3, #4 ask for after seeing a demo video.

Sub-trigger: if a prospect explicitly asks during the sales process "do you have AR measurement?" — log the request here, but don't build before close.

### What we lose by parking it

Nothing operationally. Phase 4 manual SVG editor still ships first and covers the workflow. AR adds delight, not capability. Parking it does not block any compliance or revenue path.

### Locked decisions for whenever this gets built

- iPad-first, not phone-first
- Native shell over WebXR (don't fight the platform)
- Manual fallback ships at the same quality bar as AR — both modes first-class
- Site-calibration step is mandatory, not optional
- AR mode is an option per measurement, not a session-wide toggle

---

*New ideas: append below as BB-002, BB-003, etc. Keep the same structure: mechanic, why it's good, technical reality, build estimate, trigger to un-park.*
