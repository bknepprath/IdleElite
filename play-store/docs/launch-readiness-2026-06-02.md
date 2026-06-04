# Idle Elite Launch Readiness - 2026-06-02
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


## Release Candidate

- Version: `0.1.12`
- Android version code: `13`
- Bundle: `builds/android/idle-elite-release-v0.1.12-code13.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.1.12-code13.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `83044393` bytes
- AAB SHA-256: `8DFB4D4CC0A15247330AF768029676BE46AAD34ED18F96A590E99C971B099DD3`
- APK set size: `132107486` bytes
- APK set SHA-256: `FF540BAD51137475E609D9C8FC26FFF3CDF783DF4C25DEFC4F70893A00F1C13F`

## Validation Completed

- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.1.12-code13.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.1.12-code13.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.1.12-code13.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.1.12-code13.apks`.
- Bundle inspection confirmed local `builds/`, `release/`, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=13`
- `versionName=0.1.12`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Remaining Manual Checks

- Device install and launch smoke test was not run because no Android device was connected.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the device pass.
