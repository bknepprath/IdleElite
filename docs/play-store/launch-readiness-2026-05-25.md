# Idle Elite Launch Readiness - 2026-05-25

## Release Candidate

- Version: `0.1.7`
- Android version code: `8`
- Bundle: `builds/android/idle-elite-release-v0.1.7-code8.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.1.7-code8.apks`
- Package name: `com.idleelite.game`

## Validation Completed

- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.1.7-code8.aab`: passed with expected self-signed upload-key warnings.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.1.7-code8.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.1.7-code8.apks`.
- `.\scripts\test-release-aab.ps1`: passed on connected Android device `R5CX22KSM1H`; installed and launched `com.idleelite.game`.

## Manifest Checks

- `versionCode=8`
- `versionName=0.1.7`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Remaining Manual Checks

- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the rewarded ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the device pass.
