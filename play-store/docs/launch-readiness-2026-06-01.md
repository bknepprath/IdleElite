# Idle Elite Launch Readiness - 2026-06-01
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


## Release Candidate

- Version: `0.1.11`
- Android version code: `12`
- Bundle: `builds/android/idle-elite-release-v0.1.11-code12.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.1.11-code12.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `82007776` bytes
- AAB SHA-256: `0946C45E53E7E4A02083383A97D72AFEF024383501718B2DD3B6D5F4C219DD05`
- APK set size: `131058813` bytes
- APK set SHA-256: `094DA481E5BDD196C70B82A74F35689FA4D10E5A40EC4467E5325E52E9655006`

## Validation Completed

- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.1.11-code12.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.1.11-code12.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.1.11-code12.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.1.11-code12.apks`.
- Bundle inspection confirmed local `builds/`, `release/`, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=12`
- `versionName=0.1.11`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Remaining Manual Checks

- Device install and launch smoke test was not run because no Android device was connected.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the rewarded ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the device pass.
