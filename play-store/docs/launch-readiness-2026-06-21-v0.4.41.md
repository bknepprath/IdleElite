# Idle Elite Launch Readiness - 2026-06-21 - v0.4.41
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.4.41`
- Android version code: `25`
- Bundle: `builds/android/idle-elite-release-v0.4.41-code25.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.4.41-code25.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `132630172` bytes
- AAB SHA-256: `5ABC3A5FD7E349F763F2DD40EF360C73AF669339D070D4E58B5F577F937E78F7`
- APK set size: `183757791` bytes
- APK set SHA-256: `EDAFE0C6B79BBBF98CCD4F6BCEFC6DDAA096CDE9EA73943AD25171096751826C`

## Validation Completed

- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.4.41-code25.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.4.41-code25.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.4.41-code25.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.4.41-code25.apks`.
- Bundle inspection confirmed local release notes, upload keystore paths, closed-test upload packs, `idle-elite-closed-test` zips, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `package=com.idleelite.game`
- `versionCode=25`
- `versionName=0.4.41`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Project Validation

- The Firebase/chat guardrails passed during the export path: `firebase-leaderboard-rules-current` and `leaderboard-cost-safety-ok`.
- Earlier full `.\scripts\check-project.ps1` reached the static and smoke gates, then failed in `test-module-list-transitions.ps1` on existing module-list and pinned-page transition assertions. That failure was not re-run for this version bump.

## Device Smoke Test

- Release install smoke was skipped because `adb devices` did not list an attached authorized device.
- No uninstall-based smoke test was run, preserving the project rule that `com.idleelite.game` is not uninstalled without explicit data-loss approval.

## Remaining Manual Checks

- Upload `builds/android/idle-elite-release-v0.4.41-code25.aab` to the Play Console closed testing track.
- Deploy the Firebase Realtime Database rules if they have not already been deployed for the public chat-read fix.
- Confirm Play Console accepts version code `25` as newer than the previous upload.
- Confirm the Play Store install and update path after processing completes.
- Run the release install/launch smoke test on an authorized Android device if desired.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
