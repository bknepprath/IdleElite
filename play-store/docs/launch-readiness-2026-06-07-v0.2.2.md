# Idle Elite Launch Readiness - 2026-06-07 - v0.2.2
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.2.2`
- Android version code: `19`
- Bundle: `builds/android/idle-elite-release-v0.2.2-code19.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.2.2-code19.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `61629213` bytes
- AAB SHA-256: `87050AAA40C80D79C5A155603D95E16AB4D0ED2538AB30983FDC84EA1DF22E03`
- APK set size: `152409443` bytes
- APK set SHA-256: `27A04B4AD128F717478A78F2B38CAAFDEE38FFF98636213545FB14E30D7901F6`

## Validation Completed

- `.\scripts\check-leaderboard-cost-safety.ps1`: passed.
- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.2.2-code19.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.2.2-code19.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.2.2-code19.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.2.2-code19.apks`.
- Bundle inspection confirmed local `builds/`, `release/`, closed-test upload packs, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=19`
- `versionName=0.2.2`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Device Smoke Test

- Device install and launch smoke test was not run because no Android device was visible to ADB.

## Remaining Manual Checks

- Upload `builds/android/idle-elite-release-v0.2.2-code19.aab` to the Play Console closed testing track.
- Confirm the Play Store install and update path after processing completes.
- Re-run the connected phone install/launch smoke test when a device is visible to ADB.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
