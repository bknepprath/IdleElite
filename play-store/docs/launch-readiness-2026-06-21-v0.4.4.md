# Idle Elite Launch Readiness - 2026-06-21 - v0.4.4
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release Candidate

- Version: `0.4.4`
- Android version code: `24`
- Bundle: `builds/android/idle-elite-release-v0.4.4-code24.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.4.4-code24.apks`
- Package name: `com.idleelite.game`

## Artifact Details

- AAB size: `132629575` bytes
- AAB SHA-256: `C64119F37B0302B9F99DD2883C0E28BD394B916D330773C8412028456A574C62`
- APK set size: `183757791` bytes
- APK set SHA-256: `792B65243F9928613BC92BCA44CC9F9A5E6A21DFBB4E71441CAC6BCFF793CE2F`

## Validation Completed

- `.\scripts\build-android-release.ps1`: passed and created the release AAB.
- `jarsigner -verify builds\android\idle-elite-release-v0.4.4-code24.aab`: passed with expected self-signed upload-key warnings.
- `bundletool validate --bundle=builds\android\idle-elite-release-v0.4.4-code24.aab`: passed.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.4.4-code24.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.4.4-code24.apks`.
- Bundle inspection confirmed local release notes, upload keystore paths, closed-test upload packs, `idle-elite-closed-test` zips, and `.codex` payloads were excluded from the AAB.

## Manifest Checks

- `package=com.idleelite.game`
- `versionCode=24`
- `versionName=0.4.4`
- `minSdk=24`
- `targetSdk=35`
- AdMob application ID: `ca-app-pub-3570919669688101~3616255490`

## Project Validation

- `.\scripts\check-project.ps1` passed the early static and smoke gates: performance monitor, performance regressions, runtime asset paths, activity database contracts, generated-file hygiene, UI boundary contracts, activity UI boundary contracts, leaderboard cost safety, activity-card geometry, home achievement medal click, tutorial start scroll, stamina fail-shake, skill detail bottom scroll pad, hidden-preview scroll gap, and save normalization.
- `.\scripts\check-project.ps1` did not report overall success because `test-module-list-transitions.ps1` failed.
- The failing smoke reported module-list and pinned-page transition assertions around restored collapsed rendering, fishing offer pinning, active shelf rendering, collapsed module refresh, pin no-bump cover/movement, page switch cover creation, and pinned utility pressed-state cleanup.

## Device Smoke Test

- Release install smoke was skipped because `adb devices` did not list an attached authorized device.
- No uninstall-based smoke test was run, preserving the project rule that `com.idleelite.game` is not uninstalled without explicit data-loss approval.

## Remaining Manual Checks

- Decide whether the module-list transition smoke failure should block Play closed-test upload.
- Upload `builds/android/idle-elite-release-v0.4.4-code24.aab` to the Play Console closed testing track if accepting that validation risk.
- Confirm Play Console accepts version code `24` as newer than the previous upload.
- Confirm the Play Store install and update path after processing completes.
- Run the release install/launch smoke test on an authorized Android device if desired.
- Confirm the rewarded ad loads through the Play closed testing track.
- Confirm closing/skipping the rewarded ad does not grant the boost.
- Confirm completing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors during the Play-distributed device pass.
