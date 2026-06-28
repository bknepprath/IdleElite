# Idle Elite Launch Readiness - 2026-06-27 - v0.4.63
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release

- Version: `0.4.63`
- Android version code: `31`
- Bundle: `builds/android/idle-elite-release-v0.4.63-code31.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.4.63-code31.apks`
- Play Store upload pack: `builds/playstore-upload-v0.4.63-code31`
- Play Store upload zip: `builds/idle-elite-playstore-v0.4.63-code31.zip`

## Artifact Hashes

- AAB SHA-256: `05694E04889CD6D1137D329BCB45BCBF158D03C08630C31C3BFE5498C90450DE`
- APK set SHA-256: `9F975C7DF8FDB2E6B0EBBBCD3325681BF17695FD87E1137D84C679DD12F3419A`

## Validation

- `jarsigner -verify`: passed with expected self-signed upload-key warnings.
- `bundletool validate`: passed.
- `bundletool dump manifest`: passed.
- Local payload scan: passed after pruning generated Android asset-pack `.godot` payload.
- `bundletool build-apks --mode=universal`: passed.
- Device release smoke test: skipped; installing `com.idleelite.game` can conflict with Play-signed production data, so no data-loss install was performed.

## Manifest Values

- `package=com.idleelite.game`
- `versionCode=31`
- `versionName=0.4.63`
- `minSdkVersion=24`
- `targetSdkVersion=35`
- AdMob app ID: `ca-app-pub-3570919669688101~3616255490`

## Remaining Play Validation Checks

- Upload the AAB to Play Console.
- Install from Play testing on a physical phone.
- Confirm rewarded ads load, cancel safely, and grant the +10% XP boost only after completion.
- Watch logcat for crashes or repeated AdMob errors.
