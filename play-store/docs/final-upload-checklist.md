<!-- October 22 validation: app verified, review/account approval pending. Existing signed 0.7.1 candidate and matching debug test validated; development 0.7.2 preserved. Prior non-ad script changes and skills-page failure remain release limitations. See launch-readiness-2026-10-22-v0.7.1.md. No Play upload authorized. -->
# Idle Elite Google Play Upload Checklist

## Current submission: 0.7.2 / code44

Submitted October 23, 2026 with Brian's renewed authorization. Play shows Changes in review, automated quick checks running, full production rollout (100%), managed publishing off. Privacy-policy and Data safety updates were submitted together. Signed bundle validation, physical Samsung rendering, consent decline/reopening, and final normal-preview restoration passed. See `launch-readiness-2026-10-23-fixes.md` for hashes and evidence. Live availability is not yet confirmed. Older candidate/authorization statements below are historical and superseded.

## AdMob migration candidate 0.7.1 / code43

Prepared October 21, 2026. Changelog: Ads backend update.

- Published baseline: 0.7.0 / code42, live in production at 100% rollout as verified in Play Console.
- Main publisher: pub-4125359195200512, weskillnow@gmail.com.
- New app ID: ca-app-pub-4125359195200512~1607281974.
- New Boost Rewarded unit: ca-app-pub-4125359195200512/8284370963; reward 1 Boost XP + Speed.
- Debug builds retain Google's test rewarded unit. Reward logic and rendering settings are unchanged by this migration.
- Keep BOTH app-ads.txt seller lines and the old AdMob account active until the new release is live, new impressions are verified over several days, remaining old-version users are assessed, and Brian explicitly approves closure after balance disclosure.
- No production upload is authorized until Brian reviews the signed artifact, diff and rewarded-ad test result and says go. Routine Google account approval and app readiness must finish before rollout.
- Source: C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p. Build scratch: I:\Codex\Scratch\IdleElite-admob-071 because the verified H: Flareon volume has insufficient free space.
- Use build-android-release.ps1 -ExistingReleaseBaselineAab builds\android\idle-elite-release-v0.7.0-code42.aab. Read existing Firebase rules; do not deploy database rules or migrate player accounts.
- See launch-readiness-2026-10-21-v0.7.1.md for current evidence and outstanding checks. The older sections below are historical release records.


Current release: **0.7.0 / code42**, built from the latest working files and submitted to Google Play production on October 17, 2026. Play lists Changes in review while quick checks run. Requested rollout: 100%; managed publishing off. Previous production: 0.6.1 / code40. Evidence, test failures, and remaining checks: `launch-readiness-2026-10-17-v0.7.0.md`.

## Build and validation

- Build from the native 1080p worktree, not the archived 4K checkout.
- Keep the 1080x1920 viewport, `window/stretch/mode="viewport"`, and both rendering methods set to `gl_compatibility`.
- Run the project checks, crash contracts, save compatibility tests, and leaderboard cost checks. Record failures and any narrowly justified test-environment reruns.
- Review identity and save compatibility with code40. For this same-account-system update, use `build-android-release.ps1 -ExistingReleaseBaselineAab <code40-aab>` to verify the prior Firebase configuration and freshly read deployed rules. Do not repeat the old migration freeze or player-data reset.
- Deploy the Firebase rules that allow profile pictures 20 to 22 before any 0.7.0 build reaches players: `scripts\deploy-firebase-leaderboard-rules.ps1 -ProjectId idle-elite`. Owner approval required. The Android build stops until the live rules equal the project's, and without the deploy a player on a new picture has score, profile and chat writes refused on both platforms.
- Keep the keystore password in the build process environment and verify `keystore/release_password=""` afterward.
- Verify `builds\android\idle-elite-release-v0.7.0-code42.aab` with jarsigner and bundletool.
- Confirm package `com.idleelite.game`, code42, name0.7.0, minSdk24, targetSdk36, and the production AdMob app ID.
- Verify 16KB native-library and APK alignment, export exclusions, artifact sizes, and SHA-256 hashes.

## Physical Samsung preview

- Install with `scripts/install-android-phone-debug.ps1`, which updates `com.idleelite.game.preview` without uninstalling production.
- Mute preview monitoring before launch.
- Inspect the dark-mode mission count and interrupted-swipe recovery.
- Inspect what is new in 0.7.0: Welcome Back after time away, unlock projects and their resource badges, taps on required items, the build-required activity (BUILD on the boards, padlock afterwards), the Fire Pit, a jailed Thieving activity resuming.
- Check scrolling, navigation, overlays, animation, background/resume, and cold starts. Any tearing or framebuffer corruption blocks release.
- Inspect logs for current app crashes, ANRs, and memory failures. Preserve progress through the preview update and restart.

## Closed testing and production gate

- Brian explicitly authorized the latest code42 production submission on October 17; the release has been submitted. Do not describe it as approved or live until Play confirms that status.
- The full draft `release-notes-0.7.0.txt` is preserved. Submitted Play notes are the 480-character en-US summary in `google-play-release-notes-0.7.0.txt`.
- Update older Play-signed installs through the closed track without uninstalling. Verify username, UID, skill progress, unlocks, missions, and Hub modules before/after launch and restart.
- Test offline progress on/off, enabling it in Settings, repeated background/resume, and force-stop/cold-start. Check that elapsed time is applied once.
- Check two-device cloud conflicts with progress on each device and interrupted uploads.
- Check app/tab audio recovery, web mouse release outside the window, and swiping after an interrupted drag.
- Verify Google linking preserves the existing UID and username; verify cloud upload and recovery using a separate test install.
- Verify rewarded-ad load, cancellation without reward, and completion with the intended reward through closed testing. Do not click or farm live ads during local testing.
- Inspect the Play-delivered build for tearing and crashes, and review the pre-launch report.
- Earlier production builds have unresolved native SIGSEGV reports. The specific reported launch crash has not been reproduced; do not claim it is fixed without player-save or crash evidence.
- Keep the frame-time benchmark failures and remaining platform tests visible in the current readiness note.

## itch.io web build

- Build from the working files with `scripts\build-desktop-working.ps1 -OutputRoot <new folder>`. It stops if the finished pack does not contain the online settings file.
- Confirm `index.html` at the zip root, a size under 200 MB, and `GODOT_THREADS_ENABLED = false` in `index.html`.
- Run `scripts/tests/web_save_upgrade.test.cjs` from the build that is live on itch to the new build: progress, name and player id kept, score sent again.
- Run the new build in a browser at the frame sizes the page will use before uploading. Native desktop tests do not see browser-only faults.
- Upload by hand, tick "This file will be played in the browser" on the new upload and untick it on the old one. Leave the SharedArrayBuffer setting unchanged. A landscape frame shows the horizontal layout; the 540 x 960 frame shows the phone layout.
- On the real page: saves kept after the update, chat, high scores and the player's own row, mouse wheel, fullscreen and back, audio after a tab switch, a drag released outside the frame.

Signing material, local credentials, test saves, and Firebase backups must never enter the upload pack.

