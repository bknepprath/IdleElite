# Idle Elite Final Google Play Upload Checklist
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


Use this for the current closed test release candidate.

## Before Rebuilding

- Confirm the configured AdMob app ID and rewarded ad unit are the intended production IDs.
- Set `IDLE_ELITE_KEYSTORE_PASSWORD` in the shell that will run the release build if rebuilding.
- Run `.\scripts\check-project.ps1`.
- Run `.\scripts\check-leaderboard-cost-safety.ps1` before any Firebase-enabled build.

## Build And Local Test

- Run `.\scripts\build-android-release.ps1` if rebuilding.
- Verify `builds/android/idle-elite-release-v0.4.41-code25.aab` exists.
- Run `jarsigner -verify builds\android\idle-elite-release-v0.4.41-code25.aab`.
- Run `.\scripts\test-release-aab.ps1` with an emulator or phone connected, or add `-UninstallExisting` only when data loss is acceptable.
- Launch the app and confirm the release build no longer says `Ad Not Configured`.
- If Firebase is enabled, open chat on a phone and confirm it live-refreshes only while visible, sends at most once per 2 seconds, and renders moderator-deleted messages as removed.

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
- Upload `builds/android/idle-elite-release-v0.4.41-code25.aab`.
- Manually update the Play Store listing icon with the 512x512 PNG from `play-store/assets/app-icon-512.png`; uploading the AAB updates the installed launcher icon, but does not automatically replace the store listing graphic.
- Add the feature graphic from `play-store/assets/feature-graphic-1024x500.png`.
- Add phone screenshots from `play-store/assets/screenshot-*.png`.
- Paste listing copy from `play-store/docs/google-play-store-listing.md`.
- Host the privacy policy and paste its URL.
- Deploy `public/app-ads.txt` to the root of the developer website, then verify `https://<developer-website-host>/app-ads.txt` shows the AdMob seller line.
- Complete the Ads declaration.
- Complete Data Safety using `play-store/docs/app-content-notes.md`.
- Complete Content Rating, Target Audience, and Store Settings.
- Publish to Closed testing first.

## Keep Safe

- Preserve `release/idle-elite-upload.keystore`.
- Preserve `release/local-release-notes.md`.
- Do not paste the upload keystore password into `export_presets.cfg`; `.\scripts\build-android-release.ps1` injects it temporarily from `IDLE_ELITE_KEYSTORE_PASSWORD`.
- Do not commit `release/` or `builds/`.
