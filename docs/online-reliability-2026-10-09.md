# Chat, returning players, and save preservation

Changes are in the native 1080p release checkout. Existing uncommitted changes were preserved. The archived 4K checkout was used for initial investigation only.

## Changes

- Chat checks HTTP status and content type, follows bounded HTTPS redirects to Firebase hosts, reconnects after closed or stalled streams, and buffers UTF-8 across packet boundaries. Firebase requires redirect support for REST streams: [Firebase REST documentation](https://firebase.google.com/docs/reference/rest/database/#section-streaming).
- Chat waits for the saved username lookup or canonical-profile update and resumes the queued message after successful verification. Claimed names are verified before the first send in a returning session.
- Returning players republish unchanged scores once per session, subject to the existing persisted 15-minute cooldown. Submission payloads preserve recorded personal bests. The existing per-category retry and acknowledged-payload logic remains intact.
- The leaderboard merges the player's actual local score into its displayed rows when their server entry is absent or behind. Lower rows shift down. The fallback is labelled `Local score`, its position is estimated, and it never changes the server cache or upload acknowledgments. A player below the fetched top 50 remains visible after those rows without a fabricated global rank. A confirmed current server row replaces the fallback.
- The rules permit converting an old XP-valued Total row into the current level score only when total XP retains the old value. The 495-level cap and monotonic skill-score/total-XP rules remain enforced.
- Cloud comparisons normalize legacy activity IDs and prioritize preserved gameplay progress over remote reset, repair, or revision markers. Uploads cannot replace an ahead-of-device cloud record with lower recorded progress.
- Cloud restoration refuses regressions before mutation, creates a recovery snapshot, preserves the authenticated identity and cloud concurrency state, completes secondary restoration, and reports success only after the local save is written. The successful write retains the prior local save in the rotated backup.

## Verification

- `scripts/test-online-reliability.ps1`: generated numeric rule expressions (8 cases), HTTP error handling, redirect host restrictions and loops, packet-split UTF-8/CRLF, returning-session publication/cooldowns, and queued chat continuation.
- `scripts/test-leaderboard-sync.ps1`: existing score acknowledgment, partial submission, stale-read, ranking, and status regressions.
- `scripts/test-save-hardening.ps1`: save hardening and real-main-scene v1 migration; extended with lower-progress remote rejection, legacy cloud aliases, identity/session preservation, durable restored XP, retained local backup, and snapshot-write failure.
- Existing online identity and Firebase runtime guard tests passed. The fresh-start fixture reported success but also emitted its out-of-tree HTTP request errors; it is not evidence of live authenticated writes.
- Generated rules and leaderboard cost contracts passed.
- The actual main scene opened chat through a pointer event on its production chat strip, received 25 public messages, and saved the raw 1080x1920 viewport to `outputs/online-reliability/live-chat-1080x1920.png`. Preview used the Dummy audio driver, isolated user data, and disabled save writes. No chat message or player score was sent.
- Local-score regression cases cover insertion, stale-row replacement, confirmation, no duplicate player, a higher server score, category tiebreaks, an unloaded board, the top-50 cutoff, and preservation of upload retries. A muted real-main-scene run navigated through the actual Home and Leaderboard controls using pointer events. Raw 1080x1920 captures are `outputs/online-reliability/local-score-1080x1920.png` and `outputs/online-reliability/confirmed-score-1080x1920.png`; the rows use isolated fixture data.

## Firebase deployment

Firebase sign-in was renewed on October 9, 2026. The live rules differed by exactly one score validation expression: the guarded conversion of old XP-valued total-level rows. The rules were deployed to `idle-elite` and read back; the deployed JSON matches the reviewed file. Previous and deployed copies are retained under `.codex-tmp/online-reliability/deploy/`. No player accounts, scores, names, or saves were deleted.

The project authentication configuration confirms anonymous sign-in is enabled and `autodeleteAnonymousUsers` is false. This setting controls automatic deletion after 30 days: [Identity Platform configuration](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v2/Config).

## Release limits

The new web package is `builds/itch/idle-elite-itch-web-v0.6.0-online-fix-2026-10-09.zip` (58,381,692 bytes; SHA-256 `eec4127dbb15d648d26551b8df5252e57958385b8e3d19fd89ae4a248620002e`). It was exported from an isolated snapshot of the current working files. The packaged runtime files match this checkout. The main pack is 49,415,200 bytes, below itch.io's 200 MB single-file limit. The build script now invalidates copied VRAM texture destinations when switching to web compression; merely changing `.import` parameters had left stale remaps in the copied cache.

`scripts/tests/web_save_upgrade.test.cjs` passed against the September 27 web ZIP and the new export on the same browser origin and actual `/userfs/godot/app_userdata/Idle Elite/` IndexedDB namespace. The fixture retained 1,000,000 XP in each of five skills, 321 softwood, its built module (under the canonical activity ID), and the player UID/name through old-build loading, upgrading, and reloading. The new build republished the unchanged total of 5,000,617 XP. All Firebase requests were fulfilled in memory, and the isolated browser used `--mute-audio` and closed afterward. This validates the browser client against simulated responses, not live authenticated database writes. Evidence: `output/playwright/online-save-upgrade/browser-upgrade-result.json`.

The web package was uploaded and saved through the existing WeSkillNow session in Edge on October 9, 2026. Upload `19656227` is selected as the browser-played file for the existing [Idle Elite project](https://weskillnow.itch.io/idle-elite). The prior uploads remain available; none were deleted. The 540x960 embed, mobile setting, automatic start, and SharedArrayBuffer setting were preserved.

Itch.io reported extraction `complete`. The public embed uses `https://html-classic.itch.zone/html/19656227/index.html`, retaining the existing host. Its entry HTML equals the uploaded file plus itch.io's appended `htmlgame.js` script. The served 49,415,200-byte `index.pck` matches the ZIP entry exactly (SHA-256 `b86123dc6dde91210241db04c7fe8c7de7b5fc7452a10401901969058e40f2ab`). Evidence is `.codex-tmp/online-reliability/deploy/itch-published-result.json` and `outputs/online-reliability/itch-published-online-fix.jpg`. Verification downloaded the public files without launching the game in the user's signed-in browser or changing that browser's player save.

Android has not been rebuilt or validated on a physical device for these changes. Live authenticated player chat and scores have not been posted as part of testing. Recovering already-missing progress requires an available local or cloud backup; this patch does not reconstruct deleted player data.
