# Buddy Sync Note — MI-DEMO-UI v2 (Pitch Mode Write Suppression)

**Cut:** 2026-05-07 ~02:25 EDT
**Author:** Buddy (Claude.ai web)
**Surface:** `index.html` only — no migrations, no schema changes, no spec doc on disk
**Branch:** demo-banner / mi-demo-seed (extending 3a1a9bf)

---

## What shipped

MI-DEMO-UI v2 per the seed spec §22 cross-reference: **pitch-day write-suppression toggle** for demo-tenant sessions. v1 (the always-on banner) was already live; v2 adds the toggle.

When ON, every wired write path bails with a toast instead of writing. Demo state stays frozen during a live Stan/Jeff call, prospects can browse freely (reads unaffected), Jorge flips off after the call to resume edits.

### Mechanism

1. **Banner toggle button** — added to `<div class="demo-banner">` next to the existing copy. Reads "Pitch mode: OFF" / "Pitch mode: ON". Demo-firm sessions only — toggle is rendered always but `togglePitchMode()` rejects on non-demo firms (defense in depth).
2. **localStorage persistence** — key `mi_pitch_mode` = `'on'` | `'off'`. Survives reload + re-login. Jorge toggles manually; nothing auto-clears.
3. **Visual state shift** — when ON, banner gradient shifts from amber to red-amber, tag pill turns red (#c84a4a), copy updates to "Pitch mode active — all writes suppressed."
4. **Body-level class** — `body.pitch-mode-active` added when active + on demo firm. Available for future CSS hooks if Jorge wants to dim/disable buttons visually (currently writes are blocked logically only, no visual disable).
5. **Scope guard** — `currentFirmIsDemo` checked in both `togglePitchMode()` AND `pitchModeBlocked()`. Real firm sessions are unaffected even if the localStorage key gets stuck `'on'` somehow.

### Write paths guarded (8)

| Function | Action label |
|---|---|
| `saveProperty` | "property add" |
| `submitNoWorkPhase` | "No-Work submit" |
| `submitPhase` | "phase submit" |
| `confirmBulkImport` | "bulk import" |
| `saveMaterialsSheet` | "materials sheet save" |
| `confirmSectorEdit` | "sector edit" |
| `submitTapcard` | "tapcard submit" |
| `rgSaveDraft` | "restoration save" |

Each gets a one-line `if(pitchModeBlocked('label')) return;` at the top of the function. Toast on block: `"Pitch mode is ON — {label} suppressed. Toggle off in the demo banner to resume."`

The CS authorization RPC inside `submitPhase` is implicitly guarded by `submitPhase`'s guard (control flow can't reach the RPC if the function early-returns).

## File diff summary

- **CSS** (+7 rules): `.demo-banner-toggle` (button base + hover) + `.demo-banner.pitch-active` (gradient + tag + text + toggle color shifts when pitch ON)
- **HTML** (+1 line): toggle `<button>` inside `.demo-banner` div
- **JS** (~50 lines): `pitchModeActive` global + `applyPitchMode()` + `togglePitchMode()` + `pitchModeBlocked()` + `applyDemoBannerVisibility()` calls `applyPitchMode()` so the toggle re-applies on auth state change
- **JS guards** (+8 one-liners): one `pitchModeBlocked()` call at the top of each of the 8 write functions

Total: ~75 lines added across 11 surgical edits.

## Click test (after Vercel preview READY on demo-banner)

1. Sign in to demo firm (any demo user — `demo-jorge@myinspector.io / Demo2026!` works)
2. Confirm banner shows: amber gradient, "Sample tenant data — illustrative records only." + "Pitch mode: OFF" button at right
3. Click "Pitch mode: OFF" → toast "Pitch mode ON — all writes suppressed", banner gradient shifts to red-amber, tag pill turns red, copy reads "Pitch mode active — all writes suppressed.", button now reads "Pitch mode: ON"
4. Try to save a Restoration grid entry → toast `"Pitch mode is ON — restoration save suppressed. Toggle off in the demo banner to resume."` and no DB write
5. Try Submit Phase → same suppression
6. Refresh the page → banner re-renders with pitch ON state preserved (localStorage)
7. Click "Pitch mode: ON" → toast "Pitch mode OFF — writes resume", banner returns to amber, writes work normally
8. Sign out + sign back in → pitch state still in localStorage; verify it re-applies after auth load

Cross-firm spot check: sign in as a **non-demo** firm user (e.g., CP Engineers `PIVOT-LATTICE-72`). Confirm banner is hidden (existing v1 behavior). Manually run `localStorage.setItem('mi_pitch_mode','on')` in DevTools, refresh — verify writes still work for non-demo firm because `pitchModeBlocked()` short-circuits on `!currentFirmIsDemo`.

## Not in scope (carry-forward / future)

- **Visual disable of buttons** — body class `.pitch-mode-active` is present but no CSS rules dim Submit/Save buttons. Could add `body.pitch-mode-active .btn-orange { opacity: 0.5; cursor: not-allowed; }` style if Jorge wants a stronger visual signal. Currently writes are blocked on click only.
- **Holistic supabase write interception** — the 8-path guard list is comprehensive for the current write surface. New write paths added in future tickets need to add their own `pitchModeBlocked()` line. Drift risk is small but real. A v3 could monkey-patch `sb.from()` to intercept all `.insert()`/`.update()`/`.upsert()`/`.delete()` calls. Not needed tonight.
- **Override path for super_admin** — pitch mode is a hard block, even for Jorge as super_admin on the demo firm. Intentional: if Jorge needs to hot-fix during a demo, he toggles OFF first, fixes, toggles back ON. No silent bypass.
- **Auto-on schedule** — could auto-flip pitch ON 5 min before a calendar event named "Stan demo" or similar. Out of scope; manual toggle is sufficient.
- **Tab-sync** — if Jorge has the app open in two tabs and toggles in one, the other won't reflect until reload (localStorage events not wired). Not a real issue for solo operator.

## What CC should do

```
git status — index.html modified (~+75 lines)
git add index.html .coordination/buddy_demo_ui_v2_2026-05-07.md
git commit -m "feat(MI-DEMO-UI v2): pitch mode write suppression toggle for demo-tenant sessions"
git push origin demo-banner
git checkout mi-demo-seed && git merge demo-banner --ff-only && git push origin mi-demo-seed
```

Doc-sync (STATE.md, decisions.md, status.md) still held per Phase 2c-form arc plan — Phase 2c-form Unit 3 + this v2 ship can ride together when the doc batch lands.

## Decisions ratified inline (no separate spec doc)

Per the "BUILD don't spec when brief is locked + repo write access exists" lesson, I built directly off the seed spec's §22 cross-reference rather than authoring a separate MI-DEMO-UI v2 spec doc. Decisions made during build:

- **Q-pitch-a — toggle UX:** button in the banner itself, not a separate settings page. Banner-as-control is the most discoverable surface during a live demo.
- **Q-pitch-b — persistence:** localStorage (not server-side flag). Pitch mode is operator-facing demo-prep state, not user data; per-device makes sense (Jorge's laptop = demo, his phone ≠ demo).
- **Q-pitch-c — scope:** demo firm only, hard-coded check on `currentFirmIsDemo`. Pitch mode on a real firm session = nonsensical.
- **Q-pitch-d — visual disable:** body class added, no CSS dimming yet. Logical block + toast is the v2 baseline. Visual dim can layer on later if Jorge wants stronger signal.
- **Q-pitch-e — write surface coverage:** 8 paths cover the demo-visible writes. New paths added in future tickets carry the burden of adding their own guard. Documented in this sync note for downstream awareness.
