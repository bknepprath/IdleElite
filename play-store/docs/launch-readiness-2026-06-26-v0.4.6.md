# Idle Elite Launch Readiness - 2026-06-26 - v0.4.6
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release

- Version: `0.4.6`
- Android version code: `29`
- Bundle: `builds/android/idle-elite-release-v0.4.6-code29.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.4.6-code29.apks`
- Play Store upload pack: `builds/playstore-upload-v0.4.6-code29`
- Play Store upload zip: `builds/idle-elite-playstore-v0.4.6-code29.zip`

## Artifact Hashes

- AAB SHA-256: `4E6ED9BE96967CFA1C1E1391CAB39A81679381ADED0EB583D5BD1C87B23AE71D`
- APK set SHA-256: `5E5F4B8C549C57A4E441E76409F9A655FD280B838975B748E92676801D6DAC10`

## Validation

- `jarsigner -verify`: passed with expected self-signed upload-key warnings.
- `bundletool validate`: passed.
- `bundletool dump manifest`: passed.
- Local payload scan: passed after pruning generated Android asset-pack debug/import payload.
- `bundletool build-apks --mode=universal`: passed.
- Device smoke test: skipped; `adb devices` reported no connected devices.
- `.\scripts\check-project.ps1`: failed in save normalization on auto-unlock lockpad assertions after earlier suites passed.

## Manifest Values

- `package=com.idleelite.game`
- `versionCode=29`
- `versionName=0.4.6`
- `minSdkVersion=24`
- `targetSdkVersion=35`
- AdMob app ID: `ca-app-pub-3570919669688101~3616255490`

## Remaining Play Validation Checks

- Install from Play closed testing on a physical phone.
- Confirm rewarded ads load, cancel safely, and grant the +10% XP boost only after completion.
- Watch logcat for crashes or repeated AdMob errors.
