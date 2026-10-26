# 0.7.2 readiness fixes — October 23, 2026

Active source: the 1080p checkout. On October 23, Brian renewed authorization to publish. Corrected 0.7.2/code44 was submitted for a full production rollout. Play shows **Changes in review**, with automated quick checks running. Managed publishing is off, so publication follows approval automatically. Live availability of code44 is not yet confirmed.

## Final submission and acceptance

- Follow-up: Google Play accepted release-detail edits while code44 remained in review. Notes now match the website/itch wording, including reworked Fishing tools/balance/animations and removed Fishing Wisdom requirements. Evidence: `.codex-tmp/website-072-notes/google-play-notes.png`. No release withdrawal was needed.

- Submitted three changes: production 0.7.2 (100% in all targeted countries), privacy-policy URL, and Data safety disclosures. Evidence: `.codex-tmp/readiness-072-oct23/play-code44-in-review.png`.
- Signed artifact: `builds/android/idle-elite-release-v0.7.2-code44.aab`, 177869626 bytes. SHA256: `168B4504CAA494EDF3BF3E5A29A46306DE7764C7F200852E4F497E16DA0EC017`.
- Guarded release build, bundletool validation, signature continuity with code42, target36/min24, production package, new AdMob app ID, native consent bridge, non-debuggable manifest, payload checks, and 16KB ELF/ZIP alignment passed. Logs: `final-production-build.log` and `final-production-validation.log` in the evidence directory above.
- Physical Samsung SM-S928U acceptance includes the latest fishing Wisdom removal and centered navigation. Normal preview code44 restored after consent testing; no tearing or runtime error matches in the inspected run. Raw final proof: `phone-normal-final.png`, 1080x2340. Production package/save was not uninstalled or replaced.
- Published European consent and US privacy choices under weskillnow@gmail.com / pub-4125359195200512. European decline enabled; US message covers all current/future supported states. Evidence: `admob-european-published.png` and `admob-us-published.png`.
- Native European consent displayed on Samsung, declining returned to the game, and Settings reopened the form successfully (`phone-consent-reopened.png`). Geography override existed only in a temporary preview; Java source was restored and normal preview reinstalled. The signed production artifact predates that temporary override.
- Play has no blocking validation errors. Its two warnings concern absent deobfuscation/native debug-symbol files; these remain diagnostic limitations. The code42 crash below has no established cause or demonstrated fix.

The sections below retain the earlier hold and implementation history. Their pending-build/upload/consent statements are superseded by this final acceptance record.

## Current release state

- Signed 0.7.2/code43 was built, verified, and uploaded to an unpublished production draft before the chat correction. It is stale and must not ship.
- Code43 was removed from the release draft after the user flagged the premature upload. The empty draft is saved as `0.7.2 - pending chat fixes`. The artifact remains in Play's library; do not add it back.
- Current source is 0.7.2/code44 because Play already accepted version code43. A corrected phone preview has been built, installed and checked on Samsung SM-S928U. A corrected signed production bundle has not been built or uploaded.
- Screenshot: `.codex-tmp/readiness-072-oct23/play-draft-bundle-removed.png`.

## Implemented and deployed

- Android UMP consent bridge gates Mobile Ads initialization and rewarded-ad loading/showing on SDK consent. Privacy changes invalidate cached/in-flight ads. Settings exposes available ad privacy choices.
- Settings links to privacy and account/data deletion instructions. Requests open the player's email client and do not send automatically; Hard Reset is explicitly local-only.
- Chat rules, message reports, persistent player blocking/unblocking, and blocked-message/unread filtering are implemented.
- Firebase reauthentication completed with the user-selected `brian@forwardfuture.com`. Additive report/rate-limit rules were deployed after comparing live rules.
- Hosting deployed privacy, deletion and community-rule pages. All three URLs and app-ads.txt return HTTP 200.
- Data safety disclosures and the updated privacy-policy URL were saved in Play Console, awaiting review. No declaration/release submission was made.
- Halloween texture/import inventory corrections and activity-page frame-budget/caching fixes remain in the source.

## Chat correction

- Removed every per-message ellipsis/action button. No long-press gesture is used.
- Tapping a chat name or avatar opens that player's profile with total level, skill levels, medal totals, Elite Heavenly count and total XP, plus small Block (top-left) and Report (top-right) controls. Report remains required by Google Play public-chat UGC policy. Self profiles omit moderation actions.
- The profile uses the current game theme, a compact red Close button, and outside-tap dismissal. Profile dialogs now render above the chat overlay. Report selection shows the selected message; Back returns to the profile.
- Stats read only the published leaderboard records for the selected UID, cached for 60 seconds. Private account, recovery, report and cloud-save records remain inaccessible.
- Generated Firebase rules now allow bounded per-player reads of the existing public score categories. Bulk/unbounded reads remain denied. Rules deployed successfully.

## Validation

- Earlier full project functional checks passed. Strict activity-page performance passed three consecutive runs, followed by fresh-save, first-swipe, adjacent-page and pinned-page regressions.
- Android UMP 4.0.0 Java compilation passed.
- All 165 local Firebase emulator tests passed after adding public-stat reads and tests that private profiles and unknown/retired categories remain denied.
- Leaderboard cost-safety/generated-rule checks passed.
- Chat input regression passed mouse, touch and Enter sending, failed-send recovery, tapping a real chat identity to open the profile above chat, published-stat rendering, returning to chat, and absence of per-message action boxes. Log: `.codex-tmp/readiness-072-oct23/chat-profile-test-5.log`. Headless shutdown produced the existing allowed RID/resource-leak warnings; no functional test failures remained.
- Stale code43 bundle passed signature, package/version, target36, upload-key continuity, 16KB ELF/ZIP alignment, and payload checks. These do not validate the changed code44 source.
- Samsung SM-S928U is connected. Code43 physically displayed stable rendering but exposed the rejected chat controls. Code44 preview showed stable rendering on the same Samsung. Verified loaded public stats, compact moderation controls, red Close, outside-tap dismissal, and the replacement ad-navigation icon. No Godot/AndroidRuntime errors appeared in the inspected logcat window. Raw phone captures: 08-profile-current.png, 09-outside-dismiss.png, 10-close-dismiss.png.

## Remaining release gates

- The corrected chat/profile UI passed focused physical-device checks. Await owner review, then build and validate a new signed production artifact. Do not use code43.
- AdMob regional privacy-message configuration remains incomplete: the European editor failed to initialize in the embedded UI. Ads remain fail-closed when consent is unavailable. Native consent flow still requires device acceptance.
- Uploads remain held while the user reviews the chat correction. Play production is unchanged.
- Play reported five native SIGSEGV events affecting one code42 user on Pixel 9 Pro XL / Android17 SDK37, libgodot_android.so BuildId 5a324c511a175243faee09dcee1f3c349a5fed15. The unsymbolicated trace does not establish a cause or a fix in 0.7.2. Issue: 3f75f65f8b651b676a732650513d1aec.

Build scratch: `H:\Codex\Scratch\IdleElite\android-0.7.2-release-oct23` on the verified Flareon 4TB volume. Phone captures: `H:\Codex\Projects\IdleElite\outputs\phone-0.7.2-release-oct23`.

## Fishing and ad-icon follow-up

- Added a small contact splash for each net dip and retained the larger withdrawal/catch splash. Independent burst lifetimes prevent the returning net from erasing the catch splash. Catch particles remain tied to withdrawal only.
- Real-game river and sewer tests passed shallow immersion, contact timing, catch timing, independent lifetime and pool-color checks. Raw 1080x1920 frames: H:\Codex\Projects\IdleElite\outputs\fishing-net-dip-oct23-v3. Log: .codex-tmp/readiness-072-oct23/net-dip-visible-v3.log.
- Generated and integrated a unified 3D yellow stamina bolt/hourglass nav icon, using the ad-page character art as the style reference. Verified on desktop and physical phone. No rendering settings changed.
- All agent-owned Godot processes exited after testing/building. Phone preview remains installed for owner testing. Production upload remains held.

## Subsequent source changes, not yet installed on phone

- Centered the five bottom-nav slots in gameplay and chat. Removed the star's wider slot, which displaced the middle icon by 12 pixels. The ad icon now uses the default 92px draw box to match the visible width of the padded star asset.
- Removed Fishing Wisdom rewards, requirements and book UI. Chum Line and Deep Trench retain their level/project-resource gates. Exhaustive database scan found no other skill requiring Fishing Wisdom. Historical saved Fishing Wisdom remains inert and round-trips for compatibility.
- Database contracts and content audit passed. Focused live-game Wisdom removal, save compatibility and ribbon symmetry passed. Required progression regression passed (`PROJECT_RESOURCES failures=[]` in `.codex-tmp/readiness-072-oct23/progression-without-fishing-wisdom-v2.log`). Its desktop input fixture was corrected to scroll the mounted source into view before physically clicking it. The earlier headless attempt could not complete its rendered-frame captures and was stopped; the visible rerun passed.
- Raw 1080x1920 evidence: `H:/Codex/Projects/IdleElite/outputs/fishing-without-wisdom-oct23-balanced/`. These changes require a new phone preview before claiming physical-device acceptance. No production upload was made.
