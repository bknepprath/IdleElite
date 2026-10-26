# Idle Elite Google Play Launch Runbook

## Latest itch.io release

0.7.2i published October 23, 2026 at https://weskillnow.itch.io/idle-elite, playable upload 19977937. Current web ZIP: `H:\Codex\Projects\IdleElite\outputs\itch-v0.7.2i-2026-10-23-release\idle-elite-v0.7.2i-itch-web.zip`. Save migration, browser checks and exact hosted-file identity passed. See `itch-release-2026-10-23-v0.7.2i.md`.

## Current submission: 0.7.2 / code44

Submitted October 23, 2026 with Brian's renewed authorization. Play shows Changes in review, automated quick checks running, full production rollout (100%), managed publishing off. Publication follows Google approval automatically. Physical Samsung and native consent checks passed; normal preview code44 was restored. Source remains the native 1080p checkout. Scratch: `H:\Codex\Scratch\IdleElite\android-0.7.2-release-oct23`. See `launch-readiness-2026-10-23-fixes.md` for artifact hash and evidence. Older candidate/authorization statements below are historical and superseded.

## AdMob migration candidate 0.7.1 / code43

Prepared October 21, 2026. Changelog: Ads backend update.

- Published baseline: 0.7.0 / code42, live in production at 100% rollout as verified in Play Console.
- Main publisher: pub-4125359195200512, weskillnow@gmail.com.
- New app ID: ca-app-pub-4125359195200512~1607281974.
- New Boost Rewarded unit: ca-app-pub-4125359195200512/8284370963; reward 1 Boost XP + Speed.
- Debug builds retain Google's test rewarded unit. Reward logic and rendering settings are unchanged by this migration.
- Keep BOTH app-ads.txt seller lines and the old AdMob account active until the new release is live, new impressions are verified over several days, remaining old-version users are assessed, and Brian explicitly approves closure after balance disclosure.
- No production upload is authorized until Brian reviews the signed artifact, diff and rewarded-ad test result and says go. Routine Google account approval and app readiness must finish before rollout.
- Source: C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p. Build scratch: I:\Codex\Scratch\IdleElite-admob-071 because the verified H: Flareon volume has insufficient free space.
- Use build-android-release.ps1 -ExistingReleaseBaselineAab builds\android\idle-elite-release-v0.7.0-code42.aab. Read existing Firebase rules; do not deploy database rules or migrate player accounts.
- See launch-readiness-2026-10-22-v0.7.1.md for current evidence and outstanding checks. Development remains 0.7.2; the existing 0.7.1 artifact was tested without rebuilding the development checkout. The older sections below are historical release records.

<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->


## Current Build Artifacts

- Current Play release: **0.7.0 / code42**, submitted October 17, 2026 for a 100% production rollout. Play lists Changes in review; automatic quick checks are pending. Managed publishing is off. Physical Samsung preview rendering was inspected; see `launch-readiness-2026-10-17-v0.7.0.md` for evidence, the initial blank launch, test failures, and remaining checks.
- itch.io web package: `H:\Codex\Projects\IdleElite\outputs\itch-v0.7.0-2026-10-17-release\idle-elite-v0.7.0-itch-web.zip`, published October 17 as upload 19836331. The public game and three-column horizontal gameplay were verified; patch notes are in the page description. See `itch-release-2026-10-17-v0.7.0.md`.
- Signed Play upload bundle: `builds\android\idle-elite-release-v0.7.0-code42.aab`.
- Previous candidate, 0.6.2 / code41, never published: `E:\IdleElite-v0.6.2\build-source\builds\android\idle-elite-release-v0.6.2-code41.aab` and its `.apks` test package. See `launch-readiness-2026-10-11-v0.6.2.md`.
- Debug APK used for emulator testing: `builds/android/idle-elite-debug.apk`
- Upload keystore: `release/idle-elite-upload.keystore`
- Local keystore details: `release/local-release-notes.md`
- Repeatable release build process: `play-store/docs/release-build-process.md`
- Final upload checklist: `play-store/docs/final-upload-checklist.md`
- Privacy policy draft: `play-store/docs/privacy-policy-draft.md`
- AdMob app-ads.txt hosting notes: `play-store/docs/app-ads-txt-setup.md`

The `release/` and `builds/` folders are ignored by Git because they contain local signing material and generated binaries.

## Current Update Workflow

The 0.7.0 release preserves the existing account system and targets API 36. It was built with the published code40 baseline. Brian authorized the October 17 production submission and separately approved deployment of the avatar 20-22 validation rules. The deployment completed, and the build verified that the fresh live rules match the project exactly and the Firebase configuration matches code40. No migration freeze or player-data reset was performed. See the October 17 readiness note for current evidence and tests that remain incomplete.

The itch.io web package is built from the working files with `scripts\build-desktop-working.ps1 -OutputRoot <new folder>`. `build-itch-release.ps1` builds the last commit, which predates the horizontal layout.

## Previous Update Status

The October 11 stability candidate (0.6.2 / code41) preserved the account system and targeted API 36. The Firebase login was refreshed and the live rules/configuration check passed for code40 to code41. No Firebase rules or player records were changed. Publishing it was not requested.

Play Console was checked October 10, 2026: production is code39 / 0.6.0 at 100%. The 0.6.1 / code40 candidate uses the existing Firebase configuration and deployed authenticated rules. Use `build-android-release.ps1 -ExistingReleaseBaselineAab <published-code39-aab>` after reviewing identity compatibility. Do not repeat the old leaderboard reset, freeze, or migration deployment. Code40 has now been submitted for a 100% public production rollout, with automatic publication after Google approval. See `launch-readiness-2026-10-10.md` for current evidence, warnings, owner authorization, and review status.

## Historical Verified v0.5.3 Baseline

These statements describe the historical code38 artifact. They are not evidence that code40 or a future existing-player transition release has passed.

- Headless validation is pinned to the verified Godot 4.7.1 binary through `run-godot-safe.ps1` and uses isolated user data. Godot 4.5.1 is not used for this project validation.
- Android Gradle export template is installed under `android/build`.
- Poing Studios AdMob plugin is installed under `addons/admob`.
- Android AdMob plugin binaries are present under `addons/admob/android/bin`.
- Release AAB is signed and `jarsigner -verify` reports `jar verified`.
- Release AAB converts to APKs with official Google `bundletool-all-1.18.3`.
- Bundletool-generated APKs are ready for device install testing.
- Debug build ad button reaches the AdMob rewarded loader.
- Release manifest reports `versionCode=38`, `versionName=0.5.3`, `minSdk=24`, and `targetSdk=36`.
- Exported manifest contains AdMob app ID `ca-app-pub-4125359195200512~1607281974`.
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


