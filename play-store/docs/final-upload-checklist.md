# Idle Elite Google Play Upload Checklist

Candidate: **0.6.2 / code41**, stability fixes only. Artifact status and test evidence: `launch-readiness-2026-10-11-v0.6.2.md`. Code40 was submitted on October 10; current Play publication status has not been rechecked.

## Build and validation

- Build from the native 1080p worktree, not the archived 4K checkout.
- Keep the 1080x1920 viewport, `window/stretch/mode="viewport"`, and both rendering methods set to `gl_compatibility`.
- Run the project checks, crash contracts, save compatibility tests, and leaderboard cost checks. Record failures and any narrowly justified test-environment reruns.
- Review identity and save compatibility with code40. For this same-account-system update, use `build-android-release.ps1 -ExistingReleaseBaselineAab <code40-aab>` to verify the prior Firebase configuration and freshly read deployed rules. Do not repeat the old migration freeze or player-data reset.
- Keep the keystore password in the build process environment and verify `keystore/release_password=""` afterward.
- Build on E: and verify `E:\IdleElite-v0.6.2\build-source\builds\android\idle-elite-release-v0.6.2-code41.aab` with jarsigner and bundletool.
- Confirm package `com.idleelite.game`, code41, name0.6.2, minSdk24, targetSdk36, and the production AdMob app ID.
- Verify 16KB native-library and APK alignment, export exclusions, artifact sizes, and SHA-256 hashes.

## Physical Samsung preview

- Install with `scripts/install-android-phone-debug.ps1`, which updates `com.idleelite.game.preview` without uninstalling production.
- Mute preview monitoring before launch.
- Inspect the dark-mode mission count and interrupted-swipe recovery.
- Check scrolling, navigation, overlays, animation, background/resume, and cold starts. Any tearing or framebuffer corruption blocks release.
- Inspect logs for current app crashes, ANRs, and memory failures. Preserve progress through the preview update and restart.

## Closed testing and production gate

- Publication of code41 has not been requested. Prior code40 publication authorization does not cover this candidate.
- Use `release-notes-0.6.2.txt`, written in the existing changelog style.
- Update older Play-signed installs through the closed track without uninstalling. Verify username, UID, skill progress, unlocks, missions, and Hub modules before/after launch and restart.
- Test offline progress on/off, enabling it in Settings, repeated background/resume, and force-stop/cold-start. Check that elapsed time is applied once.
- Check two-device cloud conflicts with progress on each device and interrupted uploads.
- Check app/tab audio recovery, web mouse release outside the window, and swiping after an interrupted drag.
- Verify Google linking preserves the existing UID and username; verify cloud upload and recovery using a separate test install.
- Verify rewarded-ad load, cancellation without reward, and completion with the intended reward through closed testing. Do not click or farm live ads during local testing.
- Inspect the Play-delivered build for tearing and crashes, and review the pre-launch report.
- Earlier production builds have unresolved native SIGSEGV reports. The specific reported launch crash has not been reproduced; do not claim it is fixed without player-save or crash evidence.
- Keep the frame-time benchmark failures and remaining platform tests visible in the current readiness note.

Signing material, local credentials, test saves, and Firebase backups must never enter the upload pack.
