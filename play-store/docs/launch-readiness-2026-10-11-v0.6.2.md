# Idle Elite 0.6.2 stability candidate

Version name: **0.6.2**. Android version code: **41**. No content, economy, renderer, viewport, or account-system changes were introduced in this stability pass. The source already contained the v0.6.1 release's uncommitted changes; those were preserved.

Source: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`.
Build copy and scratch: `E:\IdleElite-v0.6.2` (C: had approximately 330 MB free).

## Findings and changes

| Report | Finding and change | Limits |
| --- | --- | --- |
| Launch crash after updating | Legacy v1 migration already existed. Added validation before converting malformed save numbers, including stamina, materials, mastery, fishing, health, missions, and module timers. Invalid primaries fall through to verified backups; unrecoverable originals remain preserved. Invalid envelope/schema numbers are rejected before conversion. Separately reproduced a native signal-11 crash when resume repair retries while navigation is busy: immediate deferred retries starve the next render frame. Repair now yields a frame, deduplicates retries, and stops during shutdown. | The same busy-resume fixture recovers and exits successfully after the fix. Valid v1 update and malformed-save recovery are covered. The specific Sep 18/Aug 19 player crash remains unconfirmed; its save and symbolized crash evidence are unavailable. |
| Lost progress | Existing checksum, temp-save, three age-tier backups, recovery snapshot, and corrupt-file quarantine retained. Removed delete-before-rename fallback. Backup rotation now copies the primary so it remains present until atomic replacement succeeds. | User data is never used by the regression fixtures. Power loss on actual Android storage still needs an update/device test. |
| Cloud conflicts | Permanent-progress regression guards and ETag conditional writes retained. For equal permanent progress, a different device's higher local revision no longer makes an older save win; saved time breaks the tie, and equal time keeps local state. | Two-device conflicts, connection loss during upload, and Play-signed account recovery need hand testing. |
| Offline progress | Hidden tabs could continue throttled gameplay/autosave frames, replacing the timestamp needed for resume. Added one suspension timestamp, stopped main gameplay accounting while suspended, and wired browser visibility/pageshow resume. Late background saves retain the suspension timestamp. Repeated pause notifications do not rotate saves again. Resume persists elapsed boost time even with offline rewards disabled. Setting changes reset passive timestamps in both directions. | Cold-start and lifecycle save fixtures cover persistence. Browser/Android suspension timing needs platform testing. |
| Long sessions | Infinite fishing-offer tweens were bound to the permanent main node. Removing their controls left callbacks alive. Each tween now belongs to its control, and cleanup explicitly kills it. Existing node caches, HTTP timeouts, request-in-flight gates, bounded chat rows, leaderboard cadence, and one chat polling timer were audited. Chat disconnects while backgrounded. | The headless profile measures CPU timing and resource lifetime; it does not measure browser WebGL, phone GPU behavior, or live chat traffic. |
| Mission timer | The timer already used a saved absolute deadline. Mission completion now schedules persistence after the entire reward transaction, and mission changes mark the save dirty. Equal-progress cloud restores cannot win just by having more revisions. | The original timer-reset report is not independently reproduced from a player save. Deadline round-trip and cloud stale-revision regressions cover the identified risks. |
| Ad boost | The non-Android code granted rewards immediately, regardless of any ad SDK. Removed this fallback. The only grant call is the reward-earned callback, guarded against duplicate callbacks and callbacks without an active show. | The web build has no configured reward SDK, so its ad button grants no reward. Real Android ad completion, cancellation, load failure, and callback timing need SDK/device testing. |
| Audio after switching apps/tabs | Desktop focus loss paused music, but desktop focus return did not resume it. Focus return now follows the suspend/resume path. Browser visibility resume also restarts music through the existing audio director. | Playback verification was muted. Audio quality and browser AudioContext behavior need an audible manual check. |
| Drag outside window / half-finished swipe | Focus cleanup released buttons but left swipe tracking and its horizontal offset. Mouse exit and suspension now cancel the tracked swipe and restore the page position. | Raw real-game captures show the pre-drag, offset, and settled states at 1080x1920. Browser pointer capture should still be tested in the embedded game. |
| Dark-mode count | Theme-aware ink became light on a paper badge whose background stays light. Use the existing light-panel label helper to preserve dark ink. | Raw production-screen PNG inspected at 1080x1920. |

## Android and download size

The preset already targets API 36, meeting the current requirement for updates effective August 31, 2026. Source: https://developer.android.com/google/play/requirements/target-sdk . Preserve `viewport` stretch and `gl_compatibility` rendering.

The v0.6.1 AAB is 158,576,949 bytes. Music already uses Ogg Vorbis and the large chain effect already uses compressed WAV import. Production textures already use platform compression. Excluded two verified unreferenced images, without deleting sources or recompressing active art:

- `assets/loading/idle-elite-berries-dragons-boot-splash-v0.5.0.png`: 1,433,191 compressed bytes in code40.
- `assets/content/fight/enemies/giants/giants-states-source.png`: 963,123 compressed bytes in code40.

Expected asset reduction: 2,396,314 compressed bytes. AAB sizes and Google Play device download estimates are different measurements.

The completed AAB is **156,192,270 bytes**, down **2,384,679 bytes (1.50%)** from code40. Both excluded images are absent from the archive. No new Play download estimate is available because this candidate has not been uploaded.

## Signed artifacts

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `E:\IdleElite-v0.6.2\build-source\builds\android\idle-elite-release-v0.6.2-code41.aab` | 156192270 | `cb4ce6ee60231b0dc2ffbbd649b74f45e90e20711c3c5bf9057efca61a1accbb` |
| `E:\IdleElite-v0.6.2\build-source\builds\android\idle-elite-release-v0.6.2-code41.apks` | 325305818 | `a4518548fd65dfd15e752300786807d6d896b806c271852dfb17d9142acc9088` |

The guarded `build-android-release.ps1` completed. Jarsigner, bundletool validation, manifest inspection, local/signing-payload exclusion checks, both native libraries' 16 KB ELF alignment, and universal APK 16 KB ZIP alignment passed. Manifest: `com.idleelite.game`, version `0.6.2`, code `41`, min SDK `24`, target SDK `36`, expected AdMob app ID. Evidence is under `E:\IdleElite-v0.6.2\scratch`: `release-build.log`, `artifact-validation.log`, `artifact-verification.json`, `release-manifest.xml`, and `zipalign.log`.

Build storage/cache was placed on E:. Limited Windows commit memory required `JAVA_TOOL_OPTIONS=-Xms32m -Xmx512m -XX:+UseSerialGC` and a 768 MB Gradle heap with one worker in the build copy only. Temporary signing-password files were removed; the release preset password is empty. No Godot process remained after export. ADB reported no connected devices. The APK set is universal and its size is not a Play device-download estimate.

## Validation evidence

Player notes: `play-store/docs/release-notes-0.6.2.txt`.

- Save hardening plus v1 update/cloud integration: `.codex-tmp/stability-save-tests-final.log`.
- Ad/lifecycle/timer/input regression: `.codex-tmp/stability-regressions.log` (the full suite also runs the expanded fishing-tween regression).
- Native busy-resume crash reproduction: `.codex-tmp/stability-busy-resume-before.log`; the isolated Godot user log records signal 11 with `_repair_after_app_resume` on the GDScript backtrace. Fixed regression: `.codex-tmp/stability-busy-resume-fixed.log`, including successful process exit.
- Expanded offline regression uses the production Settings toggle, starts a real activity, applies two minutes of absence, verifies increased and persisted XP, and rejects duplicate resume credit. The fixture waits for queued UI work before shutdown; immediate fixture teardown had timed out.
- Expanded malformed-save fixtures include fishing/health counters and passive, convergence, Hub, and mission numeric fields: `.codex-tmp/stability-save-tests-expanded.log`.
- Final save hardening and v1 migration/cloud/cold-start tests passed: `.codex-tmp/stability-save-cold-start-final.log`. Cold start commits elapsed boost time even with offline XP disabled. Migration writes preserve the old timestamp until deferred offline simulation consumes it, preventing an interrupted boot from losing that interval. The headless fixture explicitly invokes the production post-load entry point because headless boot skips deferred services.
- Required project suite: `.codex-tmp/stability-project-validation.log`; the first run stopped because the image inventory needed regeneration after the export exclusions. Remaining checks are recorded individually under `.codex-tmp/stability-suite/`.
- Baseline long-session samples: `.codex-tmp/stability-soak-before.json`. The baseline was stopped after identifying the infinite-tween leak; it is not the requested final 30-minute result.
- Real-game captures: `.codex-tmp/stability-captures/dark-mode-count.png`, `swipe-interrupted.png`, and `swipe-settled.png`.
- Final required checks ran through `scripts/check-project.ps1` and the remaining individual runners. The suite's inherited `IDLE_ELITE_DISABLE_ONLINE_REQUESTS=1` masked four expected sign-in status branches in the Firebase fixture; rerunning that synthetic-credential fixture without the override passed. All remaining functional runners passed: `.codex-tmp/stability-final-remainder-results.json`. The final strict frame-time runner still failed scroll/swipe budgets: `.codex-tmp/stability-final-test-skills-page-performance.log`. No thresholds were changed. Tracked import-file status was unchanged by validation.

## Required hand tests before publishing

1. Update an installed older Play build with an existing save. Cold-start repeatedly; confirm skill XP, inventory, identity, and missions remain intact.
2. Background/force-stop/reopen on Samsung with offline progress on and off, then toggle it on and repeat. Check elapsed rewards and the mission cooldown without duplicate credit.
3. Check two devices with the same account, including simultaneous progress, offline play, reconnects, and a failed upload. Preserve both saves for any conflict.
4. Run a 30-minute real Android/browser session with active gameplay, chat, leaderboard visits, and repeated page swipes. Headless CPU profiling cannot clear platform freezes or tearing.
5. Test reward-ad completion, cancellation, failure, and rapid taps. On web with an ad blocker, verify no boost is granted.
6. With sound explicitly enabled for the manual test, switch apps/tabs several times and check music and SFX. Drag outside the web game, release outside, return, and swipe again.

No phone was connected when checked. Physical Samsung rendering acceptance and Play-signed update/ad/account tests remain pending. Do not treat a desktop screenshot or headless pass as that acceptance.

## Build authentication

The initial signed-build attempt stopped at the live Firebase rules check because the local CLI login had expired. Brian completed reauthentication. The fresh read-only check then passed: `firebase-existing-release-ok baseline=40 release=41`. No rules or player records were written and no release guard was bypassed.

## Performance acceptance

The real-time 1,800-second headless profile completed and its owned Godot process exited: `.codex-tmp/stability-soak-final.log` and `.codex-tmp/stability-soak.json`. It ran active woodcutting and changed production pages every 10 seconds. At matching 300-second route checkpoints from minute 5 through minute 30, nodes stayed at 1,205, objects changed from 4,768 to 4,770, and the tween count stayed at 1. Orphan nodes were zero throughout. Static memory at those checkpoints grew from 169,444,386 to 170,822,664 bytes (1,378,278 bytes / 0.81%). No freeze occurred. The previous run's growing fishing-offer tween count is no longer present. The profile loaded the tween/lifecycle fixes at launch; later busy-resume and cold-start persistence refinements were verified separately by regression tests.

The strict skills-page frame-time benchmark failed on idle, scroll, and swipe timing samples. Functional geometry/swipe checks passed, but this candidate does not establish that all lag is fixed. Keep the timing failure visible; do not weaken its thresholds. The 30-minute profile is an offline headless navigation/resource-lifetime diagnostic. Short isolated regression processes ran concurrently during part of it, so frame intervals include host contention and are not a controlled GPU or phone benchmark.

## Upload pack

`E:\IdleElite-v0.6.2\artifacts\idle-elite-closed-test-v0.6.2-code41.zip`

Bytes: 157896741. SHA-256: `8404872e9e7b10c8423d6c2f8acbb1bea56c276145b075e77aac916eb2c3b0d0`. ZIP integrity and credential exclusions passed. Runtime scripts, scenes, project settings, and export presets in the build copy match the working source. Full hashes: `E:\IdleElite-v0.6.2\artifacts\UPLOAD-HASHES.json`. The signed artifacts are prepared for review and device testing; this is not publication approval.
