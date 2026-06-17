# Idle Elite Launch Readiness - 2026-06-16 - v0.4.0
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.4.0`
- Android version code: `22`
- Bundle: `builds/android/idle-elite-release-v0.4.0-code22.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.4.0-code22.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `95946617` bytes
- AAB SHA-256: `DD43EE0527DB387A217BBEB86EA17CB706FE55E21A1C72B038AD983CC9687CEC`
- APK set size: `145086545` bytes
- APK set SHA-256: `C3879F47F73CADE292FF6EE9C1E670345E37B8D7BCF7EDC8493BE31ADAB5E886`

## Validation Completed

- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.4.0-code22.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.4.0-code22.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.4.0-code22.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.4.0-code22.apks`.
- Bundle inspection confirmed local release notes, keystore paths, closed-test upload packs, `idle-elite-closed-test` zips, and `.codex` payloads were excluded from the AAB.
- `.\scripts\check-project.ps1`: passed the static performance regression gate, leaderboard cost safety, activity-card geometry, tutorial start scroll, stamina fail-shake, bottom scroll pad, hidden-preview scroll gap, and save-normalization checks before failing on the skills-page performance threshold.

## Manifest Checks

- `package=com.idleelite.game`
- `versionCode=22`
- `versionName=0.4.0`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Device Smoke Test

- Release install smoke was skipped because `adb devices` did not list an attached authorized device.

## Known Non-Blocking Risk

- `.\scripts\check-project.ps1` did not report overall success because `test-skills-page-performance.ps1` flagged frame-work threshold misses in fishing scroll and build swipe paths. The failures were p99/120 FPS budget style performance gates, not crashes, blank-page failures, or bundle validation failures.

## Remaining Manual Checks

- Upload `builds/android/idle-elite-release-v0.4.0-code22.aab` to the Play Console closed testing track.
- Confirm Play Console accepts version code `22` as newer than the previous upload.
- Confirm the Play Store install and update path after processing completes.
- Run the release install/launch smoke test on an authorized Android device if desired.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
