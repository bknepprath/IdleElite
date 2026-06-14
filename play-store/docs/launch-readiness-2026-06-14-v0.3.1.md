# Idle Elite Launch Readiness - 2026-06-14 - v0.3.1
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.3.1`
- Android version code: `21`
- Bundle: `builds/android/idle-elite-release-v0.3.1-code21.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.3.1-code21.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `93748329` bytes
- AAB SHA-256: `E41AA1F13AFB737B5038E6EB7057F7EC83E954BCDDDCD8BEAA49811EACAB0008`
- APK set size: `142852150` bytes
- APK set SHA-256: `1853E88FB6817F900CBDAB90E2C13E230D7D22B3A372B533E94EF5F03057570D`

## Validation Completed

- `.\scripts\check-leaderboard-cost-safety.ps1`: passed.
- Major ship smoke from the 2026-06-14 release pass: headless boot smoke passed; first-swipe build/visual checks passed; hidden-preview scroll gap passed; bottom scroll pad passed; tutorial start scroll passed; stamina off-page smoothness passed; activity card geometry passed.
- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.3.1-code21.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.3.1-code21.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.3.1-code21.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.3.1-code21.apks`.
- Bundle inspection confirmed local release notes, keystore paths, closed-test upload packs, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `versionCode=21`
- `versionName=0.3.1`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Device Smoke Test

- Release install smoke was skipped because ADB reported the connected device as `unauthorized`.
- Preview-package phone smoke from the same release session confirmed `com.idleelite.game.preview` launched and recent logs showed no fatal exception.

## Known Non-Blocking Risk

- The strict skills performance gate was not used as a release blocker for this pack per the 2026-06-14 ship criteria of blocking only on major crashes, failures, or broken core flows. The remaining strict failure was a swipe/build p99/max frame-work threshold spike, not a crash or blank-page failure.

## Remaining Manual Checks

- Upload `builds/android/idle-elite-release-v0.3.1-code21.aab` to the Play Console closed testing track.
- Confirm Play Console accepts version code `21` as newer than the previous public upload.
- Confirm the Play Store install and update path after processing completes.
- Re-authorize the connected Android device and run the release install/launch smoke test if desired.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
