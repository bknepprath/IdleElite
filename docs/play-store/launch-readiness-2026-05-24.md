# Idle Elite Play Store Readiness - 2026-05-24

## Automated Checks Run

- `.\scripts\check-project.ps1`: passed. Godot 4.5.1 loaded the project headlessly.
- `.\scripts\build-android-release.ps1`: passed after updating it to inject the release keystore password temporarily from `IDLE_ELITE_KEYSTORE_PASSWORD`.
- `jarsigner -verify builds\android\idle-elite-release-v0.1.2-code3.aab`: passed with expected self-signed upload-key warnings.
- `bundletool dump manifest --bundle=builds\android\idle-elite-release-v0.1.2-code3.aab`: passed.
- `bundletool build-apks --mode=universal`: passed and produced `builds/android/idle-elite-release-v0.1.2-code3.apks`.

## Current Release Artifact

- Bundle: `builds/android/idle-elite-release-v0.1.2-code3.aab`
- APK set for local testing: `builds/android/idle-elite-release-v0.1.2-code3.apks`
- Package: `com.idleelite.game`
- Version: `0.1.1`
- Version code: `2`
- Min SDK: `24`
- Target SDK: `35`
- Bundle size: `125878503` bytes
- Universal APK set size: `175368325` bytes

## Store Assets Verified

- `docs/play-store/assets/app-icon-512.png`: 512 x 512 PNG, 148.6 KB.
- `docs/play-store/assets/feature-graphic-1024x500.png`: 1024 x 500 PNG, 134.2 KB.
- `docs/play-store/assets/screenshot-01-train-five-skills-1080x1920.png`: 1080 x 1920 PNG.
- `docs/play-store/assets/screenshot-02-stamina-choices-1080x1920.png`: 1080 x 1920 PNG.
- `docs/play-store/assets/screenshot-03-level-up-1080x1920.png`: 1080 x 1920 PNG.
- `docs/play-store/assets/screenshot-04-offline-progress-1080x1920.png`: 1080 x 1920 PNG.
- `docs/play-store/assets/screenshot-05-idle-elitist-1080x1920.png`: 1080 x 1920 PNG.

## Launch Blockers

- Replace the sample AdMob application ID in `addons/admob/android/config.gd`; the current exported manifest contains `ca-app-pub-3940256099942544~3347511713`.
- Wire real rewarded ads or remove/disable ad claims before production. The current app button in `scripts/main.gd` only reports that rewarded ads are enabled in Android builds.
- Replace `TODO` developer name and contact email in `docs/play-store/privacy-policy-draft.md`, host the policy publicly, and paste its URL into Play Console.
- Complete Play Console account-only declarations: Ads, Data Safety, Content Rating, Target Audience, and Store Settings.
- Test a final build on a real Android phone or Play internal testing track before production.

## Current Google Play Requirements Checked

- Google's current target API guidance says new apps and updates must target Android 15 / API level 35 or higher. This build targets API 35.
- Google Play requires Android App Bundles for new apps. This project produces an `.aab`.
- Because AdMob is included, the Data Safety and Ads declarations must account for advertising identifiers and ad-related SDK data.

Sources:

- https://developer.android.com/google/play/requirements/target-sdk
- https://developer.android.com/guide/app-bundle
- https://developers.google.com/admob/android/privacy/play-data-disclosure
