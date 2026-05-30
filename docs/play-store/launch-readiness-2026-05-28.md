# Idle Elite Launch Readiness - 2026-05-28

## Release Candidate

- Version: `0.1.10`
- Android version code: `11`
- Bundle: `builds/android/idle-elite-release-v0.1.10-code11.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.1.10-code11.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `71457202` bytes
- AAB SHA-256: `C8C098A56F3657746A9F40AA1A85EB977561FD565AB4293399F87DBE4307E505`
- APK set size: `120343081` bytes
- APK set SHA-256: `02E53FEA82FD6F078044F4DC5DEC3614BC2FD2A87BD36DCD64DF2BD5AD8845C9`

## Validation Completed

- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.1.10-code11.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.1.10-code11.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.1.10-code11.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.1.10-code11.apks`.
- Bundle inspection confirmed local `builds/`, `release/`, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=11`
- `versionName=0.1.10`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Remaining Manual Checks

- Device install and launch smoke test was not run because no Android device was connected.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the rewarded ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the device pass.
