# Idle Elite Launch Readiness - 2026-06-06
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.2.0`
- Android version code: `14`
- Bundle: `builds/android/idle-elite-release-v0.2.0-code14.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.2.0-code14.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `94229756` bytes
- AAB SHA-256: `BF9C7605249E725A78463B5A9ED1812EC83DF7383DC5154EFDC4E18DC3276D11`
- APK set size: `143433023` bytes
- APK set SHA-256: `3A2E452C9D8084F9E3104048FE4A9A16C26439BDCA68DD64232A121D44D59E37`

## Validation Completed

- `.\scripts\check-leaderboard-cost-safety.ps1`: passed.
- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.2.0-code14.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.2.0-code14.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.2.0-code14.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.2.0-code14.apks`.
- `.\scripts\test-release-aab.ps1`: passed without the uninstall path; installed and launched `com.idleelite.game` on connected device `R5CX22KSM1H`.
- Bundle inspection confirmed local `builds/`, `release/`, closed-test upload packs, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=14`
- `versionName=0.2.0`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Remaining Manual Checks

- Upload `builds/android/idle-elite-release-v0.2.0-code14.aab` to the Play Console closed testing track.
- Confirm the Play Store install and update path after processing completes.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
