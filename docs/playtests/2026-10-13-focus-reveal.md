# Desktop focus and reveal fixes — October 13, 2026

## Root causes and changes

- Focus-out used the same suspension path as a real platform pause. That set `suspended_at_unix`, stopped the main simulation, paused music and disconnected chat. Focus-in then applied offline progression and opened Welcome Back. Desktop and browser focus now checkpoints progress and cancels interrupted pointer gestures while the simulation continues. Focus-in ensures music is playing without restarting it. Real application pause, mobile focus suspension, cold-start restoration and measured processing gaps retain offline handling.
- Long parent-opacity fades blended each card's internal layers independently. Desktop introductory columns and new activity previews now reveal fully opaque content against the matching page/header background. Activity and column fades take 0.55 seconds; basic ribbon controls take 0.65 seconds; Thieving starts 1.25 seconds after Fishing. Both neighboring skills still begin during Fighting level one. Eligible later features remain spaced by 30 active seconds.
- Reveal controls are removed on completion, tween cancellation or target destruction. Hidden controls cannot accept pointer presses. Reveal covers never paint over a visible modal.
- Genuine offline intervals below 60 seconds still receive rewards, without a modal. Longer real absences keep Welcome Back. Repeated summary construction no longer duplicates its resize-signal connection.

## Verification

All runs used the safety wrapper. Agent tests used the Dummy audio driver and master mute, isolated user data and the production main scene. No export or release was created.

- `scripts/tests/desktop_focus_reveal.gd`: PASS (`FOCUS_REVEAL failures=[]`). Actual tutorial input; early staged reveals; solid nested layers; hidden-page input guard; centered/contained columns; reveal cleanup. Production focus notifications with offline progression off and on: activity XP continues while unfocused, return does not duplicate rewards or show Welcome Back, music playback position is retained. A simulated measured 12-second processing gap grants activity XP and consumes boost time without a modal. Application pause/resume still records/clears suspension. A genuine recorded 120-second absence grants XP, opens Welcome Back and is consumed once.
- `scripts/test-stability-regressions.ps1`: PASS. Includes save timestamps, duplicate resume protection, the real offline-progress setting toggle, persisted offline XP, mission deadlines and existing ad/fishing regression checks.
- `scripts/tests/desktop_opening.gd`: PASS (`DESKTOP_OPENING failures=[]`). Opening, level-two progression, staged feature eligibility, preference roundtrip, carousel dragging, 1280x720 / 1000x600 / 1920x1080 resizing and actual Settings reset all passed.
- `git diff --check`: passed (existing line-ending warnings only).
- No agent-owned headless or automated visible Godot process remained after testing.

Raw viewport PNGs (unaltered, each checked at 1920x1080):

- `../../.codex-tmp/desktop-opening/cold-start.png`
- `../../.codex-tmp/desktop-opening/controls-transition.png`
- `../../.codex-tmp/desktop-opening/neighbors-before.png`
- `../../.codex-tmp/desktop-opening/neighbors-transition.png`
- `../../.codex-tmp/desktop-opening/thieving-transition.png`
- `../../.codex-tmp/desktop-opening/neighbors-settled.png`
- `../../.codex-tmp/desktop-opening/level-two-transition.png`
- `../../.codex-tmp/desktop-opening/level-two-settled.png`
- `../../.codex-tmp/desktop-opening/after-reset.png`

The tested desktop opening and transitions were visually inspected. Browser tab throttling and physical Android background/resume were not exercised in this turn and remain platform checks; no renderer or stretch setting changed.
