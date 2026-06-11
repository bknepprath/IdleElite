# Idle Elite Launch Readiness - 2026-06-11 - v0.3.0
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.3.0`
- Android version code: `20`
- Bundle: `builds/android/idle-elite-release-v0.3.0-code20.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.3.0-code20.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `92748056` bytes
- AAB SHA-256: `788520155C141E2AF4BA905BC26BCA59BC02C3F5BC10F8F85199500D78627676`
- APK set size: `141836102` bytes
- APK set SHA-256: `7510F6872C358793A37BAC34098F29E35971B92E73CC7B3F39486EE39D8A57CA`

## Validation Completed

- `.\scripts\check-leaderboard-cost-safety.ps1`: passed after restoring the expected chat live-sync signature.
- `.\scripts\check-project.ps1`: passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.3.0-code20.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.3.0-code20.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.3.0-code20.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.3.0-code20.apks`.
- Bundle inspection confirmed local release notes, keystore paths, closed-test upload packs, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=20`
- `versionName=0.3.0`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Device Smoke Test

- Device install and launch smoke test was not run because no Android device was visible to ADB.

## Remaining Manual Checks

- Upload `builds/android/idle-elite-release-v0.3.0-code20.aab` to the Play Console closed testing track.
- Confirm the Play Store install and update path after processing completes.
- Re-run the connected phone install/launch smoke test when a device is visible to ADB.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
