# Idle Elite 0.7.0 / code 42

Release date of submission: October 17, 2026 (America/Chicago).

Google Play submission confirmed: production release 42 (0.7.0) is listed under **Changes in review**. Automatic quick checks were still running at confirmation and will forward the release for review when successful. This is not yet approved or live. The release requests a 100% rollout in all currently targeted countries. Managed publishing is off, so Google will publish after approval. The signed bundle and English patch notes have been uploaded.

Console: https://play.google.com/console/u/0/developers/9139736059678173325/app/4975093549993322883/publishing

## Artifacts

- Source: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`
- AAB: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p\builds\android\idle-elite-release-v0.7.0-code42.aab`
- AAB size: 166,827,517 bytes.
- AAB SHA-256: `59338C82B5D1D3B4A1B07B0F55DD3DEF57E9A7EAE0A70668D6EFCB5E60D9F007`
- APK set: `H:\Codex\Projects\IdleElite\outputs\google-play-v0.7.0-code42\idle-elite-release-v0.7.0-code42.apks`
- APK set size: 338,619,666 bytes.
- APK set SHA-256: `C42A2D9125596CCD34877642FBFC8840C59D127D3ED00D111B918867431A8727`
- Final Play notes: `google-play-release-notes-0.7.0.txt` (480 characters, en-US).

## Completed validation

- Built latest working source through the guarded Android release script with the published code40 / 0.6.1 bundle as the existing-account-system baseline.
- All 201 monitored source/configuration files remained unchanged during export. Existing uncommitted work was preserved; no gameplay source changes were made during packaging.
- Keystore password restored to empty in export_presets.cfg; no agent-owned Godot process remained.
- Jarsigner reported `jar verified`; expected self-signed upload-certificate and timestamp warnings remain.
- Bundletool validation passed. Package com.idleelite.game, version0.7.0/code42, minSdk24, targetSdk36, arm64-v8a, production AdMob application ID confirmed.
- No local signing material, release notes with credentials, or .codex payloads were found in the bundle.
- Universal APK generation succeeded. APK ZIP alignment passed at 16KB; both native libraries have 0x4000 LOAD-segment alignment.
- Firebase configuration matches published code40. Fresh live database rules match the candidate rules exactly.
- With Brian's explicit approval, deployed the four avatar validation limit changes from 19 to 22 to idle-elite-default-rtdb. Authentication/access conditions and player records were unchanged.
- Google Play accepted the bundle with no blocking errors and no loss of supported devices. Warnings: missing deobfuscation file and native debug symbols.

## Physical Samsung check and limits

Latest code42 debug preview was installed as com.idleelite.game.preview on Samsung SM-S928U. The production app was not uninstalled or replaced. Preview media volume was zero.

The first launch remained blank, including an initial resume. Force-stopping and cold-launching only the preview restored normal rendering and loaded its existing save. Welcome Back/offline progress displayed; vertical scrolling, a skill-page change, and a subsequent normal Home/resume rendered without visible tearing or corrupt bands in the inspected captures. The initial blank-launch cause is unresolved; this is not a claim that every startup issue is fixed. Later logcat contained Android surface/driver warnings, but no observed script error or fatal crash in that run.

Evidence: phone-preview-0.7.0-restarted.png, phone-preview-0.7.0-scrolled.png, phone-preview-0.7.0-resume-verified.png. Captures are unmodified physical-device screenshots, 1080x2340.

Full check-project.ps1 did not pass: its skills-page performance test reported `scroll/fishing mounted too many action cards for a visible skills page`. Earlier checks completed, including rendering/crash contracts, save normalization/compatibility and identity-related contracts. The separate Wisdom feedback regression timed out at 180 seconds. These failures were not hidden, waived by a passing build, or fixed during release packaging.

This submission did not include a new Play-signed update-retention test, two-device cloud conflict/recovery test, or rewarded-ad completion/cancellation test. Existing native crash reports and remaining performance tests are not claimed resolved. Closed-track and pre-launch test results should be reviewed separately.

## Source documentation

The current runbook/checklist and a dated readiness note are updated with the submission evidence. The detailed 0.7.0 patch tracker and full draft notes are preserved; the concise Play notes were gathered from them, including the October 17 fishing Wisdom and touch-collapse changes.


## Release archive

Pack: `H:\Codex\Projects\IdleElite\outputs\google-play-v0.7.0-code42\playstore-upload-v0.7.0-code42`

ZIP: `H:\Codex\Projects\IdleElite\outputs\google-play-v0.7.0-code42\idle-elite-playstore-v0.7.0-code42.zip`

ZIP size: 170840575 bytes.

ZIP SHA-256: `A9F92C8C5AB9DD7B13AA86D897E22AD781C2E63D8B98E1547E0F27C64710DE94`

