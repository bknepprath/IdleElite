# Idle Elite v0.5.3 Launch Readiness

## Release

- Version name: `0.5.3`
- Version code: `38`
- Package: `com.idleelite.game`
- Track: Google Play production candidate
- Previous production version: `0.5.2` (`37`)
- Google Play status: submitted for review for a 100% production rollout on August 18, 2026.
- Managed publishing: off; the release will publish automatically after approval.
- Play Console submission state: `Changes in review`; automated quick checks were still running when submitted.

## Artifacts

- AAB: `builds/android/idle-elite-release-v0.5.3-code38.aab`
- AAB size: `198,753,623` bytes
- AAB SHA-256: `9214CEB7B65F1AFFE4C9A8D34C69C446354784FB7A46241F951553869E00F21D`
- APKS: `builds/android/idle-elite-release-v0.5.3-code38.apks`
- APKS size: `248,298,165` bytes
- APKS SHA-256: `50783461C14D13EDC1319B32315C0CACA718EE322026EAF6122D450B2636F00B`

## Android Configuration

- `window/stretch/mode` remains `viewport`.
- Release export rejects any non-`viewport` stretch mode.
- Manifest reports `minSdk=24` and `targetSdk=36`.
- Manifest contains AdMob app ID `ca-app-pub-3570919669688101~3616255490`.
- Production rewarded unit is `ca-app-pub-3570919669688101/7376748559`.
- The AAB contains only the ARM64 native architecture.
- Both native libraries use `0x4000` ELF LOAD alignment, and the generated APK passes the 16 KB ZIP alignment check.
- The 198.8 MB AAB is below Google Play's current 500 MB base-module limit.

## Runtime Fixes Included

- Removed automatic extended-audio decoding during startup. Extended audio now loads when requested.
- Removed the locked-card full-screen screen-readback shader and replaced it with a static translucent style.
- Preserved viewport stretch mode to prevent the full-screen tearing reproduced with `canvas_items` on Samsung phones.

## Validation

- Crash-audit contracts passed.
- Leaderboard cost-safety checks passed.
- `jarsigner -verify` passed.
- `bundletool validate` passed.
- Manifest package, version, SDK, and AdMob metadata passed.
- Permission comparison against v0.5.2 found no added or removed permissions.
- Upload signer certificate matches the v0.5.2 artifact.
- Exported payload scan found no keystore, local release notes, upload packs, or Codex files.
- The isolated preview package completed eight cold starts on a physical Samsung SM-S928U with no fatal, native, OOM, or ANR log entries.
- Three corrected cold-start cycles received distinct Android process IDs.
- Physical-device PSS during the corrected cycles was approximately 1.29-1.31 GB, without runaway native-heap growth.
- The raw 1080x2340 device capture showed no full-screen tearing or corrupted bands.
- The installed Play-signed production app and its data were not modified.

## Release Notes

- Added visual fighting modules through level 95
- Added rest modules
- Added buildable modules
- Added berries
- Reworked the medal bonus system with clearer task tiers
- Reworked the UI
- Bug fixes

## Validation Limitations

- The exact production-package AAB was not installed locally because the phone already has the Play-signed production app. Replacing it would require uninstalling the production package and risk its save data. The isolated preview package was tested instead.
- The broader Windows headless project check terminates in Godot 4.5.1 with signal 11 while opening its `user://logs` file. The failure did not reproduce in the Android preview.
- Rewarded-ad completion and Play App Signing delivery must be verified from the Play track after upload.
- Play Console policy declarations and pre-review warnings cannot be verified from the local artifact.
