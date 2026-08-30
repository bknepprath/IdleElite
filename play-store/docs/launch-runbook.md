# Idle Elite Google Play Launch Runbook
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


## Current Build Artifacts

- Play upload bundle: `builds/android/idle-elite-release-v0.5.3-code38.aab`
- Bundletool test package: `builds/android/idle-elite-release-v0.5.3-code38.apks`
- Debug APK used for emulator testing: `builds/android/idle-elite-debug.apk`
- Upload keystore: `release/idle-elite-upload.keystore`
- Local keystore details: `release/local-release-notes.md`
- Repeatable release build process: `play-store/docs/release-build-process.md`
- Final upload checklist: `play-store/docs/final-upload-checklist.md`
- Privacy policy draft: `play-store/docs/privacy-policy-draft.md`
- AdMob app-ads.txt hosting notes: `play-store/docs/app-ads-txt-setup.md`

The `release/` and `builds/` folders are ignored by Git because they contain local signing material and generated binaries.

## Verified v0.5.3 Baseline

These statements describe the current code38 artifact. They are not evidence that a future existing-player transition release has passed.

- Headless validation is pinned to the verified Godot 4.7.1 binary through `run-godot-safe.ps1` and uses isolated user data. Godot 4.5.1 is not used for this project validation.
- Android Gradle export template is installed under `android/build`.
- Poing Studios AdMob plugin is installed under `addons/admob`.
- Android AdMob plugin binaries are present under `addons/admob/android/bin`.
- Release AAB is signed and `jarsigner -verify` reports `jar verified`.
- Release AAB converts to APKs with official Google `bundletool-all-1.18.3`.
- Bundletool-generated APKs are ready for device install testing.
- Debug build ad button reaches the AdMob rewarded loader.
- Release manifest reports `versionCode=38`, `versionName=0.5.3`, `minSdk=24`, and `targetSdk=36`.
- Exported manifest contains AdMob app ID `ca-app-pub-3570919669688101~3616255490`.
- Both native libraries and the generated APK pass the Android 16 KB page-size alignment checks.
- The isolated preview package completed eight cold starts on a physical Samsung phone with no fatal, native, OOM, or ANR log entries.

## Future Existing-Player Transition Go/No-Go

- `.\scripts\check-firebase-migration-readiness.ps1` passes against a fresh ignored receipt bound to the explicitly approved transition version.
- Identity Platform anonymous cleanup is disabled; current Auth and RTDB backups are access-controlled; final Auth reconciliation and canonical-profile backfill are clean; authenticated rules are deployed.
- Firebase has an Android app for `com.idleelite.game`. The Play App Signing SHA-1 and upload-key SHA-1 are registered, Google sign-in is enabled, and the configured Web client belongs to the same project.
- A disposable locally signed production install updates to the transition build without uninstalling and retains its exact username, stable UID, XP, unlocks, and built modules.
- A Play-signed production install updates from the closed track and retains the same profile and progress after first launch and restart.
- Google linking in the Play-delivered build keeps the existing Firebase UID and username; cloud upload and second-install restore both pass.
- The frozen pre-migration save decoder regression reads a newly written save with the exact username, UID, XP, mastery, unlocks, and built modules intact. Any emergency rollback build must retain that compatibility result.

## Account Items Before Public Upload

These require the developer's Google Play account or public hosting:

1. Replace the `TODO` contact fields in `play-store/docs/privacy-policy-draft.md`.
2. Host the privacy policy at a public URL and paste that URL into Play Console.
3. Deploy `public/app-ads.txt` to the root of the developer website listed in Play Console and verify it is reachable in a browser.
4. Complete Play Console declarations: Ads, Data Safety, Content Rating, Target Audience, and Store Settings.
5. Upload the release AAB to Closed testing before Production.
6. Test the closed-test Play build on a real Android phone and confirm:
   - rewarded ad opens,
   - closing/skipping does not grant the boost,
   - completing the ad grants the +10% XP boost,
   - global chat opens, live-refreshes only while visible, and enforces the 2-second send cooldown,
   - a moderator-tombstoned test message appears as removed,
   - no crash appears in logcat.

The current source has non-sample AdMob IDs configured. Do not intentionally click or farm live ads during local testing; use the Play closed testing track for a final policy-safe ad validation pass.

Use this helper when the real AdMob IDs are available:

```powershell
.\scripts\set-admob-ids.ps1 -AdMobAppId "ca-app-pub-0000000000000000~0000000000" -RewardedUnitId "ca-app-pub-0000000000000000/0000000000"
```

## Play Console Upload Steps

1. Create a Google Play app named `Idle Elite`.
2. Package name must be `com.idleelite.game`.
3. Enroll in Play App Signing.
4. Upload `builds/android/idle-elite-release-v0.5.3-code38.aab` only for the current production baseline. A future update must use its separately approved higher version code and artifact path.
5. Store listing:
   - App icon: `play-store/assets/app-icon-512.png`
   - Feature graphic: `play-store/assets/feature-graphic-1024x500.png`
   - Phone screenshots: `play-store/assets/screenshot-*.png`
   - Listing copy: `play-store/docs/google-play-store-listing.md`
6. Complete Data Safety and Ads declarations.
7. Set the developer website to the host that serves `app-ads.txt`, then request an AdMob app-ads.txt status refresh if available.
8. Start with Closed testing before Production.

## Rebuild Commands

```powershell
$env:IDLE_ELITE_KEYSTORE_PASSWORD = "<upload keystore password>"
.\scripts\check-project.ps1
.\scripts\build-android-release.ps1
```

To install the latest debug build on a connected phone (preview package, keeps release app data):

```powershell
.\scripts\install-android-phone-debug.ps1
```

`install-android-debug.ps1` forwards to the same preview installer.

To test an update from a previous locally signed build with bundletool:

```powershell
.\scripts\test-release-aab.ps1
```

Do not use `-UninstallExisting` for update validation. A locally generated APK cannot replace the Play-signed production app because the certificates differ; test that path by updating through the Play closed track.
