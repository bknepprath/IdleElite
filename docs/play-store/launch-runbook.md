# Idle Elite Google Play Launch Runbook

## Current Build Artifacts

- Play upload bundle: `builds/android/idle-elite-release.aab`
- Bundletool test package: `builds/android/idle-elite-release.apks`
- Debug APK used for emulator testing: `builds/android/idle-elite-debug.apk`
- Upload keystore: `release/idle-elite-upload.keystore`
- Local keystore details: `release/local-release-notes.md`
- Final upload checklist: `docs/play-store/final-upload-checklist.md`
- Privacy policy draft: `docs/play-store/privacy-policy-draft.md`

The `release/` and `builds/` folders are ignored by Git because they contain local signing material and generated binaries.

## Verified Locally

- Godot project parses with `.\scripts\check-project.ps1`.
- Android Gradle export template is installed under `android/build`.
- Poing Studios AdMob plugin is installed under `addons/admob`.
- Android AdMob plugin binaries are present under `addons/admob/android/bin`.
- Release AAB is signed and `jarsigner -verify` reports `jar verified`.
- Release AAB converts to APKs with official Google `bundletool-all-1.18.3`.
- Bundletool-generated APKs install and launch on the Android emulator.
- Debug build ad button reaches the AdMob rewarded loader.
- Installed release package reports `versionCode=1`, `versionName=0.1.0`, `minSdk=24`, and `targetSdk=35`.

## Blocking Items Before Public Upload

These require the developer's Google/AdMob accounts:

1. Create or open the AdMob app for Idle Elite.
2. Replace the Android AdMob app ID in `addons/admob/android/config.gd`.
3. Create a rewarded ad unit in AdMob.
4. Replace `AD_LIVE_UNIT_ANDROID_REWARDED` in `scripts/main.gd`.
5. Build a new release AAB with `.\scripts\build-android-release.ps1`.
6. Install the debug build or an internal-test Play build on a real Android phone and confirm:
   - rewarded ad opens,
   - closing/skipping does not grant the boost,
   - completing the ad grants the +10% XP boost,
   - no crash appears in logcat.

Do not upload the current release AAB as a public production release if rewarded ads are meant to work. It intentionally shows `Ad Not Configured` in release builds until real AdMob IDs are added.

Use this helper when the real AdMob IDs are available:

```powershell
.\scripts\set-admob-ids.ps1 -AdMobAppId "ca-app-pub-0000000000000000~0000000000" -RewardedUnitId "ca-app-pub-0000000000000000/0000000000"
```

## Play Console Upload Steps

1. Create a Google Play app named `Idle Elite`.
2. Package name must be `com.idleelite.game`.
3. Enroll in Play App Signing.
4. Upload `builds/android/idle-elite-release.aab`.
5. Store listing:
   - App icon: `docs/play-store/assets/app-icon-512.png`
   - Feature graphic: `docs/play-store/assets/feature-graphic-1024x500.png`
   - Phone screenshots: `docs/play-store/assets/screenshot-*.png`
   - Listing copy: `docs/play-store/google-play-store-listing.md`
6. Complete Data Safety and Ads declarations.
7. Start with Internal testing before Production.

## Rebuild Commands

```powershell
.\scripts\check-project.ps1
.\scripts\build-android-release.ps1
```

To install the latest debug APK to a connected device:

```powershell
.\scripts\install-android-debug.ps1
```

To test an AAB locally with bundletool:

```powershell
.\scripts\test-release-aab.ps1 -UninstallExisting
```
