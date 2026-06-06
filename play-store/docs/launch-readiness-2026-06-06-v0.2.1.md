# Idle Elite Launch Readiness - 2026-06-06 - v0.2.1
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.2.1`
- Android version code: `15`
- Bundle: `builds/android/idle-elite-release-v0.2.1-code15.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.2.1-code15.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `94231423` bytes
- AAB SHA-256: `CB228466C406218101916357A1FCC54E3F0CCB82D955AF662838420239658A78`
- APK set size: `143433023` bytes
- APK set SHA-256: `5EBF61271B446CA6C068AF21C8C11A0FA914EBD9E2F54C4F3D0498A4889876B1`

## Validation Completed

- `.\scripts\check-leaderboard-cost-safety.ps1`: passed.
- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.2.1-code15.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.2.1-code15.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.2.1-code15.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.2.1-code15.apks`.
- Bundle inspection confirmed local `builds/`, `release/`, closed-test upload packs, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=15`
- `versionName=0.2.1`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Device Smoke Test

- `.\scripts\test-release-aab.ps1` was attempted without `-UninstallExisting` to preserve app data.
- The connected phone dropped off ADB during the test, the command timed out, and no successful install/launch result was recorded for this release.
- The lingering `adb wait-for-device` process from that timed-out command was stopped. The normal ADB server was left running.

## Remaining Manual Checks

- Upload `builds/android/idle-elite-release-v0.2.1-code15.aab` to the Play Console closed testing track.
- Confirm the Play Store install and update path after processing completes.
- Re-run the connected phone install/launch smoke test when the device is visible to ADB.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
