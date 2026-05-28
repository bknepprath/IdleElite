# Idle Elite Launch Readiness - 2026-05-27

## Release Candidate

- Version: `0.1.9`
- Android version code: `10`
- Bundle: `builds/android/idle-elite-release-v0.1.9-code10.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.1.9-code10.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `72068528` bytes
- AAB SHA-256: `60B86D8386B4A22641696CD9FCE5AF31FA43DC640CEB592EC9615770C797837F`
- APK set size: `120948923` bytes
- APK set SHA-256: `EFA16B6765EFC149FD307EA7659C71793C0560473E4526B24D10C432D99F42E1`

## Validation Completed

- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.1.9-code10.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.1.9-code10.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.1.9-code10.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.1.9-code10.apks`.
- Bundle inspection confirmed local `builds/`, `release/`, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=10`
- `versionName=0.1.9`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Remaining Manual Checks

- Device install and launch smoke test was not run because no Android device was connected.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the rewarded ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the device pass.
