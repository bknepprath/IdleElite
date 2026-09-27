# Idle Elite Final Google Play Upload Checklist
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


Use this for the current v0.5.3/code38 production baseline and for preparing a future existing-player transition release.

## Before Rebuilding

- Confirm the configured AdMob app ID and rewarded ad unit are the intended production IDs.
- Confirm `project.godot` contains `window/stretch/mode="viewport"`; never release with `canvas_items` because it causes severe full-screen pixel tearing on physical phones.
- Confirm Identity Platform anonymous-user cleanup is disabled. Generate and deploy the database-only migration freeze, take fresh Auth and RTDB snapshots under ignored `release/`, apply and dry-audit the canonical-profile backfill with writes paused, then replace the freeze with the authenticated final rules.
- Confirm the Firebase Android app uses package `com.idleelite.game`, has the Google Play App Signing SHA-1 and upload-key SHA-1 registered, has Google sign-in enabled, and uses the Web client ID from the same project.
- Create and validate the version-bound ignored receipt with `.\scripts\write-firebase-migration-readiness-receipt.ps1` and `.\scripts\check-firebase-migration-readiness.ps1`. Do not build from a copied or stale receipt.
- Set `IDLE_ELITE_KEYSTORE_PASSWORD` in the shell that will run the release build if rebuilding.
- Run `.\scripts\check-project.ps1`.
- Confirm its frozen pre-migration decoder regression reads a newly written save without changing the username, UID, XP, mastery, unlocks, or built modules.
- Run `.\scripts\check-crash-audit-contracts.ps1`.
- Run `.\scripts\check-leaderboard-cost-safety.ps1` before any Firebase-enabled build.

## Build And Local Test

- Run `.\scripts\build-android-release.ps1` if rebuilding.
- Verify `builds/android/idle-elite-release-v0.5.3-code38.aab` exists.
- Run `jarsigner -verify builds\android\idle-elite-release-v0.5.3-code38.aab`.
- Verify the generated APK passes `zipalign -c -P 16 -v 4` and every native library has at least `0x4000` ELF LOAD alignment.
- On a disposable device or emulator with the previous locally signed production APK installed, record the username, stable UID, skill XP, unlocks, and built modules. For a future transition build, run `.\scripts\test-release-aab.ps1` without `-UninstallExisting`, then confirm every recorded value remains. Do not use `-UninstallExisting` for update validation.
- Launch the app and confirm the release build no longer says `Ad Not Configured`.
- If Firebase is enabled, open chat on a phone and confirm it live-refreshes only while visible, sends at most once per 2 seconds, and renders moderator-deleted messages as removed.

## Real Device Ad Test

- Install on a physical Android phone through local bundletool testing or Play closed testing.
- Update an existing Play-signed v0.5.3 install through the closed track. Record the username and representative progress before the update and confirm both remain after the first launch and another restart.
- Connect Google in the Play-delivered build. Confirm the account links to the existing Firebase UID, the username remains unchanged, a cloud save uploads, and a second install using the same Google account can recover it.
- Scroll, change pages, open and close an overlay, and watch an animation; reject the build if any full-screen pixel tearing appears.
- Open the rewarded ad prompt.
- Confirm the ad loads.
- Confirm backing out or closing the ad does not grant the boost.
- Confirm finishing the ad grants the +10% XP boost.
- Watch logcat for crashes or repeated AdMob errors.

## Play Console

- Create the app as `Idle Elite`.
- Confirm package name is `com.idleelite.game`.
- Enroll in Play App Signing.
- Upload `builds/android/idle-elite-release-v0.5.3-code38.aab` only when intentionally rebuilding the current production version; a future update must use its separately approved higher version code.
- Reuse the previous production release's cumulative feature notes. Do not replace the feature list with patch-only bug-fix notes.
- Manually update the Play Store listing icon with the 512x512 PNG from `play-store/assets/app-icon-512.png`; uploading the AAB updates the installed launcher icon, but does not automatically replace the store listing graphic.
- Add the feature graphic from `play-store/assets/feature-graphic-1024x500.png`.
- Add phone screenshots from `play-store/assets/screenshot-*.png`.
- Paste listing copy from `play-store/docs/google-play-store-listing.md`.
- Host the privacy policy and paste its URL.
- Deploy `public/app-ads.txt` to the root of the developer website, then verify `https://<developer-website-host>/app-ads.txt` shows the AdMob seller line.
- Complete the Ads declaration.
- Complete Data Safety using `play-store/docs/app-content-notes.md`.
- Complete Content Rating, Target Audience, and Store Settings.
- Publish to Closed testing first. Do not promote to Production until the Play-signed update, Google recovery, and cloud restore checks above pass.
- Do not ship an emergency rollback from older save code unless the frozen code38 decoder regression still passes against saves written by the released build.

## Keep Safe

- Preserve `release/idle-elite-upload.keystore`.
- Preserve `release/local-release-notes.md`.
- Do not paste the upload keystore password into `export_presets.cfg`; `.\scripts\build-android-release.ps1` injects it temporarily from `IDLE_ELITE_KEYSTORE_PASSWORD`.
- Do not commit `release/` or `builds/`.
