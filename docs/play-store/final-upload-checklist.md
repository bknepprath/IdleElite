# Idle Elite Final Google Play Upload Checklist

Use this for the current closed test release candidate.

## Before Rebuilding

- Confirm the configured AdMob app ID and rewarded ad unit are the intended production IDs.
- Set `IDLE_ELITE_KEYSTORE_PASSWORD` in the shell that will run the release build if rebuilding.
- Run `.\scripts\check-project.ps1`.

## Build And Local Test

- Run `.\scripts\build-android-release.ps1` if rebuilding.
- Verify `builds/android/idle-elite-release-v0.1.8-code9.aab` exists.
- Run `jarsigner -verify builds\android\idle-elite-release-v0.1.8-code9.aab`.
- Run `.\scripts\test-release-aab.ps1 -UninstallExisting` with an emulator or phone connected.
- Launch the app and confirm the release build no longer says `Ad Not Configured`.

## Real Device Ad Test

- Install on a physical Android phone through local bundletool testing or Play closed testing.
- Open the rewarded ad prompt.
- Confirm the ad loads.
- Confirm backing out or closing the ad does not grant the boost.
- Confirm finishing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors.

## Play Console

- Create the app as `Idle Elite`.
- Confirm package name is `com.idleelite.game`.
- Enroll in Play App Signing.
- Upload `builds/android/idle-elite-release-v0.1.8-code9.aab`.
- Add the 512x512 icon from `docs/play-store/assets/app-icon-512.png`.
- Add the feature graphic from `docs/play-store/assets/feature-graphic-1024x500.png`.
- Add phone screenshots from `docs/play-store/assets/screenshot-*.png`.
- Paste listing copy from `docs/play-store/google-play-store-listing.md`.
- Host the privacy policy and paste its URL.
- Complete the Ads declaration.
- Complete Data Safety using `docs/play-store/app-content-notes.md`.
- Complete Content Rating, Target Audience, and Store Settings.
- Publish to Closed testing first.

## Keep Safe

- Preserve `release/idle-elite-upload.keystore`.
- Preserve `release/local-release-notes.md`.
- Do not paste the upload keystore password into `export_presets.cfg`; `.\scripts\build-android-release.ps1` injects it temporarily from `IDLE_ELITE_KEYSTORE_PASSWORD`.
- Do not commit `release/` or `builds/`.
