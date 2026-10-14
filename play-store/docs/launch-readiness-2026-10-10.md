# Idle Elite 0.6.1 / code40 release readiness

Prepared October 10, 2026. Current status: code40 / 0.6.1 submitted for full public production rollout. Google Play lists Changes in review; automated checks and approval are pending. Managed publishing is off, so approval triggers automatic publication to 100% of users in all existing target countries.

## Baseline

Play Console production is 39 (0.6.0), rolled out 100%. The public listing's August date is stale. The candidate is built from the native 1080p worktree at `.codex-tmp/worktrees/idle-elite-1080p`, with its existing October changes, not the archived 4K root checkout.

The published baseline AAB is `C:\Users\bknep\Documents\Idle Slop 1\UPLOAD_0.6.0\1-GOOGLE-PLAY-upload-this-idle-elite-v0.6.0-code39.aab`.

## Candidate changes

Includes Wisdom, skill help, Hub art, mission/reward feedback, save protections, leaderboard synchronization, chat reliability, and balance changes already present in the worktree. This release preparation also moves the trophy/cushion down onto the table and changes the Training Dummy's shared authored draw box from 180x180 to 280x280 so its construction sign is comparable to the 300x300 woodcutting totem. The shared ground anchor and rendering configuration are unchanged. The Wisdom texture now uses the required compressed import; the texture inventory and single-letter information-icon contract are synchronized.

## Compatibility and evidence

- Firebase sign-in renewed as the authorized existing account. Candidate Firebase configuration matches the published code39 AAB, and fresh authenticated reads confirm deployed rules match candidate rules.
- No Firebase data reset, migration freeze, or rules deployment was performed. The same-account-system build gate records fresh verification under ignored `release/existing-release-readiness/`.
- Real main-scene Hub captures at 1080x1920 passed at construction, first-upgrade, and final-upgrade tiers: `.codex-tmp/hub-placement-release-061/tier-0.png`, `tier-1.png`, and `tier-4.png`.
- Physical device: Samsung SM-S928U. Preview package is `com.idleelite.game.preview`; production remains code39. Monitoring is muted.
- Full validation results are in `.codex-tmp/release-061-validation-results/`. Four online fixtures require their intended off-tree simulated networking environment rather than the broad offline short-circuit. Their rerun results are recorded separately.

## Outstanding release checks

The final rebuilt preview and signed artifact validation passed. Code40 is uploaded as a draft on Closed Test #1. The strict timing benchmark remains a documented warning under the existing normal release policy in `check-project.ps1`. Brian subsequently authorized public production release and declined another phone connection. Play-signed update/Google recovery/cloud restore/ad checks were not repeated; the completed Samsung preview and compatibility checks remain the device evidence.

Production code39 has 11 user-perceived native SIGSEGV events across three Godot step crash groups. The available native library is stripped and does not resolve those addresses to source. Code40 is not claimed to fix these crashes. Keep this risk visible during closed testing and inspect the pre-launch report.

## Validation results

The continuation suite completed 35 passing checks. All four online fixtures passed when rerun in their reviewed off-tree simulated environment, giving 39 functional/contract passes in that continuation set. Earlier startup, normalization, resource, activity-database, UI-boundary, cost-safety, crash, and 1080p contract checks also passed.

The strict skills benchmark failed. Earlier this note incorrectly called that an unconditional production blocker: the existing normal `check-project.ps1` workflow explicitly treats timing-only failures as warnings unless `IDLE_ELITE_STRICT_SKILLS_PERF=1`. No test thresholds or release checks were changed to permit this release. CPU-side scroll p99/max times in milliseconds were: Thieving 17.21/21.46, Building 13.34/20.17, Fighting 22.18/35.66, Fishing 19.07/21.69, Woodcutting 15.80/22.05. Ordinary swipe p99/max was 13.37/17.32. Fishing idle p99 was 4.22 against a 4.00 limit. Thresholds were not changed. These measurements are not physical-device GPU frame times.

## Signed artifact and final preview

- AAB: `builds/android/idle-elite-release-v0.6.1-code40.aab`, 158,576,949 bytes. SHA-256: `c63e30f94ad8d2fd66cbe1d95ac5d6dc3f5e2c6b37941168cc6f59249854d958`.
- APK set: `builds/android/idle-elite-release-v0.6.1-code40.apks`. SHA-256: `26fad1cfbc5b547776df893d5e49c2532792988fa624550f128d3d019a684fbe`.
- Release safety/Firebase gates, jarsigner verification, bundletool validation, manifest/package/version/SDK/AdMob inspection, payload exclusion scan, APK 16KB zip alignment, and both native libraries' ELF alignment passed. The release preset password was restored empty; no Godot process remained.
- Final preview installed on Samsung at 21:03 local time. The actual Hub, fighting detail panel, touch scrolling, skill swipe, and background/resume captures show no tearing. Three additional cold starts stayed running; the crash buffer since installation was empty, with no fatal/ANR/OOM/script-error matches in current app logs. This bounded check does not prove the historical native crash is fixed.
- Preview UID, bound UID, and display name were retained exactly. Every skill retained or gained XP, and Hub module data remained equal. The production package remains code39 and was not uninstalled or overwritten.
- Raw physical-phone evidence: `outputs/release-0.6.1-phone/06-final-hub.png`, `07-fighting-overlay.png`, `08-scroll.png`, `09-resume.png`, and `cold-start-1.png` through `cold-start-3.png` (1080x2340).
- Brian requested the same notes as itch.io. The release notes now match the current public Update 10/9/26 / v0.6.1 section exactly; the draft's earlier cumulative notes were replaced.

Closed-test draft: https://play.google.com/console/u/0/developers/9139736059678173325/app/4975093549993322883/tracks/4701594823683330757/releases/14/prepare

Play Console accepted code40 and the exact itch.io notes in the saved closed-test draft. Review reports two warnings: missing R8/proguard deobfuscation metadata and missing native debug symbols; no blocking Play validation error was shown. The review screen is at `https://play.google.com/console/u/0/developers/9139736059678173325/app/4975093549993322883/tracks/4701594823683330757/releases/14/review`. No final review submission or rollout was performed. The Samsung disconnected after the completed smoke checks, before the optional attempt to leave it on the Hub; the existing verified captures are retained.

## Public release authorization

Brian explicitly requested completion of the public Google Play release on October 10, then declined reconnecting the Samsung for additional Play-signed checks. Proceed using the already verified candidate, preserve the exact itch.io notes, and submit a 100% production rollout. No new code, rendering, signing, or account-system change was introduced after the completed validation.

## Production submission confirmation

Submission confirmed at 2026-10-11 05:00 UTC. Publishing overview lists Production, 40 (0.6.1), Start full rollout under Changes in review. Only this production change was submitted. Rollout is 100%, available in all existing target countries, with no loss of supported devices versus code39. Managed publishing remains off; its UI confirms approved updates publish automatically. Google quick checks were still running at confirmation. This records submission, not public availability or approval.

The exact itch.io notes are attached to production. The closed-test draft remains unsubmitted. Public-release proof is outputs/release-0.6.1-phone/play-production-submitted.jpg. No additional phone tests were performed after Brian declined reconnection.
