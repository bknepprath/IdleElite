# Idle Elite Launch Readiness - 2026-06-06 - v0.2.12
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.2.12`
- Android version code: `17`
- Bundle: `builds/android/idle-elite-release-v0.2.12-code17.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.2.12-code17.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `99091719` bytes
- AAB SHA-256: `1D4AFF996540036D91EB30BE49246EB7666EE08228E63138F7761BA19D370032`
- APK set size: `148481496` bytes
- APK set SHA-256: `109DBE32AB97DD912B8B05A05E650C9D890410516421DC42A6626D5EA0329625`

## Validation Completed

- `.\scripts\check-leaderboard-cost-safety.ps1`: passed.
- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.2.12-code17.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.2.12-code17.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.2.12-code17.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.2.12-code17.apks`.
- Bundle inspection confirmed local `builds/`, `release/`, closed-test upload packs, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=17`
- `versionName=0.2.12`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Device Smoke Test

- Device install and launch smoke test was not run because no Android device was visible to ADB.

## Remaining Manual Checks

- Upload `builds/android/idle-elite-release-v0.2.12-code17.aab` to the Play Console closed testing track.
- Confirm the Play Store install and update path after processing completes.
- Re-run the connected phone install/launch smoke test when a device is visible to ADB.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
