# Idle Elite Launch Readiness - 2026-06-06 - v0.2.11 code 16
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

## Release

- Version name: `0.2.11`
- Android version code: `16`
- Package: `com.idleelite.game`
- Primary upload AAB: `builds/android/idle-elite-release-v0.2.11-code16.aab`
- Local APK set: `builds/android/idle-elite-release-v0.2.11-code16.apks`
- Closed-test pack: `builds/closed-test-upload-v0.2.11-code16`
- Closed-test zip: `builds/idle-elite-closed-test-v0.2.11-code16.zip`

## Artifact Hashes

- AAB size: `99,088,035` bytes
- AAB SHA-256: `8B1A5193C1748B30A69EE2171F6CB2CCF3C9C3E80F91FF89BEBA042AAF467CD3`
- APK set size: `148,481,496` bytes
- APK set SHA-256: `D463BB0C9A47721F1E75BC0D9C2831CEB24B0FF80D53A5905716EC704C46C896`

## Validation Results

- `.\scripts\check-project.ps1`: passed with the known Godot shutdown RID/ObjectDB warnings.
- `.\scripts\check-leaderboard-cost-safety.ps1`: passed, reported `leaderboard-cost-safety-ok`.
- Release AAB build: passed via `.\scripts\build-android-release.ps1`.
- `jarsigner -verify`: passed, reported `jar verified` with expected self-signed upload-key warnings.
- `bundletool validate`: passed.
- AAB local/generated payload exclusion check: passed, no matches for closed-test packs, release keystore files, local release notes, or `.codex` paths.
- Universal APK set generation: passed via bundletool.
- `export_presets.cfg`: confirmed clean after export with `keystore/release_password=""`.

## Manifest Values

- `package="com.idleelite.game"`
- `android:versionCode="16"`
- `android:versionName="0.2.11"`
- `android:minSdkVersion="24"`
- `android:targetSdkVersion="35"`
- AdMob app ID: `ca-app-pub-3570919669688101~3616255490`

## Device Testing

- Device install smoke test: skipped because `adb devices` reported no attached devices.
- Closed-test ad validation remains to be completed from the Google Play closed-testing track:
  - rewarded ad opens,
  - closing/skipping the ad does not grant the boost,
  - completing the ad grants the +10% XP boost,
  - no crashes or repeated AdMob errors appear in logcat.

## Notes

- Signing material remains excluded from the upload pack and from Git.
- Generated binaries remain under ignored `builds/`.
