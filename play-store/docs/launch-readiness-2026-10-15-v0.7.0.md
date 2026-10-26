# Idle Elite 0.7.0 launch candidate

Version name: **0.7.0**. Android version code: **42** (as reported by the preview installed on October 15; the value is in `export_presets.cfg`). Production on Google Play is 0.6.1 / code 40. The web build live on itch.io is the October 10 chat fix.

Source: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`, working files, nothing committed.
Audit folder with all evidence: `H:\Codex\Projects\IdleElite\outputs\onigiri-audit-2026-10-14` (`LAUNCH.md` first).

This note records the state on the evening of October 15. Publication has not been requested for either platform, and nothing was uploaded or deployed.

## Artifacts

| Artifact | State |
| --- | --- |
| `H:\Codex\Projects\IdleElite\outputs\v0.7.0-2026-10-15\idle-elite-v0.7.0-itch-web.zip` | Built by `scripts/build-desktop-working.ps1` from the working files. 60,980,981 bytes, `index.html` at the root, single-threaded. SHA-256 `1C837C9B0CEB127D25DCD26912D21B8D3A7B4FB891B73CE5900D0F3ED7F47D28`. |
| `builds\android\idle-elite-release-v0.7.0-code42.aab` | **Not built.** `build-android-release.ps1 -ExistingReleaseBaselineAab <code40-aab>` needs the upload keystore password and reads the live Firebase rules first. |
| Phone preview `com.idleelite.game.preview` | Installed October 15 at 16:25. It does not contain the changes made after that. |

## Before either build reaches players

1. **Deploy the Firebase rules.** The project's rules allow profile pictures 0 to 22; the last saved copy of the live rules (October 11) allows 0 to 19. Pictures 20, 21 and 22 are listed first in the picker. Until the rules are deployed, a player on one of them has profile, score and chat writes refused. `scripts\deploy-firebase-leaderboard-rules.ps1 -ProjectId idle-elite`. Owner approval required; not done and the live rules were not read.
2. **Physical Samsung acceptance** of the current code, including tearing. Not done.
3. **The itch page frame.** It is 540 x 960 today, which shows the phone layout. A landscape frame shows the horizontal layout (two skill pages at 1280 x 720, three at 1920 x 1080). Leave the SharedArrayBuffer setting unchanged.
4. **Halloween end date.** `seasonal_events.halloween-2026.ends_at_unix` is 0, which never ends.

## What changed since the October 14 readiness audit

Details: `docs/patch-notes-0.7.0-tracker.md`, sections from "Lag and bug audit fixes, October 14" to the end, and `AUDIT.md` in the audit folder.

- Lag and bug fixes in two rounds (offline progress follows live rules, Fire Pit cost, jailed Thieving resumes, save load order, saving off the main thread, and others).
- Playtest requests of October 15, including resources that any activity of a skill gives, three times the amount for requirements of that kind, and building a module before its level.
- One addition to the save: `activity_projects.target_multipliers`, so that saves made before the larger requirements keep what they had finished.
- Web only: no minimum window size in a browser, the mouse wheel reaches the list under the pointer, and High Scores docked beside the skills is redrawn when scores arrive and after an upload.
- `scripts/build-desktop-working.ps1` now packs the online settings file and stops without it.
- Every export: `assets/content/fight/enemies/giants/giants-states-source.png` is exported again. It was excluded on October 11 as unreferenced, which left the Giants arena without its enemy; code 40 contains it and the October 15 preview bundle does not. `scripts/check-runtime-asset-paths.ps1` now also checks the bare `assets/...` paths in the activity database, and `docs/performance-1080p-texture-inventory.csv` has the row back.

No change to the viewport, stretch mode or renderer in `project.godot`, to save keys, or to how scores are sent.

## Validation evidence

- **Web build in a browser, offline.** Headless Edge, sound off, every request to Firebase answered by an in-memory stand-in. 1920 x 1080, 1280 x 720 (also at 2x), 540 x 960, resize while running, new player, returning player, wheel, drag between skills, docked Chat and High Scores, chat send, Settings, Hub. No script errors. Pictures: `web-check\` in the audit folder. Before the fixes above the same run showed the three web faults.
- **Returning web player.** `scripts/tests/web_save_upgrade.test.cjs` passes from the live itch build to this build: progress, name and player id kept, score sent again, no request left the PC.
- **Leaderboard for returning players.** Read-only code audit: `LEADERBOARD-AUDIT.md` in the audit folder. No fault in publishing found.
- **Release pre-checks.** The seven static steps `build-android-release.ps1` runs before the password pass: `logs\launch-android-static-prechecks.txt`.
- **Regression.** 35 audit checks pass. Of the project's tests, 93 were run again: 82 pass, the four leaderboard tests among them (run with online features on, which they expect; they cannot reach the backend). Nine fail as before, for recorded reasons. `test-fishing-drag-spike` and `test-fishing-opportunity-input` failed under machine load from unrelated jobs and fail the same way on the pre-fix scripts at the same moment. Logs: `logs\launch3-*` in the audit folder.

## Not validated

- The real itch page, real Firebase, sound, touch, browsers other than Edge.
- The horizontal layout on a real screen: it was seen only in screenshots from a headless browser.
- The Android release bundle: not built, so no signature, manifest, alignment or size checks.
- Everything in "Required hand tests before publishing" of `launch-readiness-2026-10-11-v0.6.2.md`. Those six still apply.
- The strict frame-time benchmark still fails, as in every record since October 10. Thresholds were not changed.

## Known and unchanged

- `scripts/check-project.ps1` cannot print `check-project-ok`: tests it runs assert an older design (`test-activity-card-geometry`, `test-tutorial-start-scroll`, and others listed in `AUDIT.md`). The Android build script does not call it.
- `scripts/test-firebase-rules-emulator.ps1` still expects picture 20 to be refused.
- On web the rewarded-ad button answers "Ad Not Configured".
- The first score upload of a session comes about 30 seconds after the game is playable, in the foreground only.
