# Idle Elite Play Store Readiness - 2026-08-13 - v0.5.1-code36

## Release

- Version: `0.5.1`
- Version code: `36`
- Package: `com.idleelite.game`
- Primary upload: `builds/android/idle-elite-release-v0.5.1-code36.aab`
- APK set: `builds/android/idle-elite-release-v0.5.1-code36.apks`

## Artifacts

- AAB size: `198,760,054` bytes
- AAB SHA-256: `070FF0C22A7552FF47611D076F4F3FB5F7ADADD0B44419889F4AB6CFE62FEB79`
- APK set size: `248,330,933` bytes
- APK set SHA-256: `08C8E8B3DDB326C79E75D63054AD6400B435444E702FBF591DC82BFA7A1F5053`

## Validation

- `jarsigner -verify`: passed.
- `bundletool validate`: passed.
- `bundletool dump manifest`: confirmed package `com.idleelite.game`, `versionCode=36`, `versionName=0.5.1`, `minSdk=24`, `targetSdk=36`, and AdMob app ID `ca-app-pub-3570919669688101~3616255490`.
- Payload scan: passed; local release notes, signing material, Codex files, and prior upload packs are excluded.
- Universal APK set generated with bundletool.
- Device smoke test: skipped because no Android device was connected.

## Open Checks

- The broad project validation currently fails in `test-stamina-gauge-fail-shake.ps1`: a full-stamina gauge click did not create the expected popup. Earlier validation gates passed, including performance monitor, save normalization, runtime asset paths, activity database contracts, generated-file hygiene, UI boundary contracts, crash audit contracts, crash recovery, activity card geometry, achievement click, medal cleanup, tutorial start scroll, woodcutting firepit, and leaderboard cost safety.
- Rewarded-ad behavior and logcat must be checked from the Play closed-test build on a physical Android device.

## Notes

- Signing material is excluded from upload artifacts.
