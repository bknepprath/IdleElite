# Idle Elite Google Play Launch Runbook

## Current Build Artifacts

- Play upload bundle: `builds/android/idle-elite-release-v0.1.4-code5.aab`
- Bundletool test package: `builds/android/idle-elite-release-v0.1.4-code5.apks`
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
- Bundletool-generated APKs install and launch on connected Android device `R5CX22KSM1H`.
- Debug build ad button reaches the AdMob rewarded loader.
- Installed release package reports `versionCode=5`, `versionName=0.1.4`, `minSdk=24`, and `targetSdk=35`.
- Exported manifest contains AdMob app ID `ca-app-pub-3570919669688101~3616255490`.

## Account Items Before Public Upload

These require the developer's Google Play account or public hosting:

1. Replace the `TODO` contact fields in `docs/play-store/privacy-policy-draft.md`.
2. Host the privacy policy at a public URL and paste that URL into Play Console.
3. Complete Play Console declarations: Ads, Data Safety, Content Rating, Target Audience, and Store Settings.
4. Upload the release AAB to Internal testing before Production.
5. Test the internal-test Play build on a real Android phone and confirm:
   - rewarded ad opens,
   - closing/skipping does not grant the boost,
   - completing the ad grants the +10% XP boost,
   - no crash appears in logcat.

The current source has non-sample AdMob IDs configured. Do not intentionally click or farm live ads during local testing; use the Play internal testing track for a final policy-safe ad validation pass.

Use this helper when the real AdMob IDs are available:

```powershell
.\scripts\set-admob-ids.ps1 -AdMobAppId "ca-app-pub-0000000000000000~0000000000" -RewardedUnitId "ca-app-pub-0000000000000000/0000000000"
```

## Play Console Upload Steps

1. Create a Google Play app named `Idle Elite`.
2. Package name must be `com.idleelite.game`.
3. Enroll in Play App Signing.
4. Upload `builds/android/idle-elite-release-v0.1.4-code5.aab`.
5. Store listing:
   - App icon: `docs/play-store/assets/app-icon-512.png`
   - Feature graphic: `docs/play-store/assets/feature-graphic-1024x500.png`
   - Phone screenshots: `docs/play-store/assets/screenshot-*.png`
   - Listing copy: `docs/play-store/google-play-store-listing.md`
6. Complete Data Safety and Ads declarations.
7. Start with Internal testing before Production.

## Rebuild Commands

```powershell
$env:IDLE_ELITE_KEYSTORE_PASSWORD = "<upload keystore password>"
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
