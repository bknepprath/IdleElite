# Idle Elite Play Store Readiness - 2026-06-28 - v0.4.66-code34

## Release

- Version: `0.4.66`
- Version code: `34`
- Package: `com.idleelite.game`
- Primary upload: `builds/android/idle-elite-release-v0.4.66-code34.aab`
- APK set: `builds/android/idle-elite-release-v0.4.66-code34.apks`

## Artifacts

- AAB size: `168,842,719` bytes
- AAB SHA-256: `ABBF63ECD682A3406FB10125D8B46D4E990FDDF2B5AB05821BD25D598AE3E798`
- APK set size: `220,106,550` bytes
- APK set SHA-256: `920B202E625EB42D197A99A50C26799A5F57E47587F49DA5BBB46CE7F417528E`

## Validation

- `jarsigner -verify`: passed.
- `bundletool validate`: passed.
- `bundletool dump manifest`: confirmed package `com.idleelite.game`, `versionCode=34`, `versionName=0.4.66`, `minSdk=24`, `targetSdk=35`, and AdMob app ID `ca-app-pub-3570919669688101~3616255490`.
- Payload scan: passed for local/generated project artifacts. The required Godot `.godot/exported` scene and `.godot/imported` resources are intentionally present in the Android asset pack.
- Universal APK set generated with bundletool.
- Device smoke test: passed on `SM_S928U` / `R5CX22KSM1H`; installed and launched `com.idleelite.game` from the signed APK set without uninstalling existing app data, then verified the app booted past the splash into the game screen.

## Notes

- Signing material is excluded from upload artifacts.
- The broad project validation currently fails in `test-activity-queue.ps1` on the queue page material drawer visibility assertions; the release bundle validation itself passed.
- A previous pruned AAB for this same version was rejected after device testing because it removed required Godot exported resources and stayed on the Android splash. Do not upload that earlier `33,121,309` byte AAB.
