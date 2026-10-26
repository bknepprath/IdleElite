# Idle Elite 0.7.2 release readiness audit

Follow-up implementation status: [October 23 fixes](launch-readiness-2026-10-23-fixes.md). The findings below preserve the original audit evidence.

Audited October 23, 2026. Recommendation: hold production submission until the policy mismatches, release-validation failures, and packaging prerequisites below are resolved.

Source: `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p`. This is an audit, not a release build or publishing approval. No Play or AdMob settings, declarations, Firebase rules, player records, or game source were changed during this audit.

## Findings requiring action

### 1. Published privacy policy and Data safety answers are obsolete

The privacy URL configured in Play Console is https://sites.google.com/view/idle-elite-privacy-policy/home. Its current policy, dated May 23, says the game has no accounts, cloud saves, chat, or leaderboards. The current game includes all of these.

Freshly inspected Play Console answers:

- My app does not allow users to create an account: checked.
- Login with accounts created outside the app: No.
- Data deletion request path: No.
- Personal info: 0/9 data types selected.
- Messages: 0/3 data types selected.

These conflict with Firebase authentication, Google linking, claimed player names, cloud save, and global chat in the current source. The declaration had last been edited May 24. Review all collected/shared data and purposes, update the public policy, and make the accurate declarations before submission. The Settings surface also lacks an in-app privacy-policy link.

Evidence: `scripts/online/online_runtime.gd:25` (Firebase signup and Google identity endpoints), `scripts/online/chat_state.gd:102` (message payload), `scripts/ui/profile_chat_overlay_surface.gd:1728` (account/profile controls), `scripts/ui/settings_surface.gd:202` (Settings UI).

Policy references: [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469), [Google Play policies](https://support.google.com/googleplay/android-developer/answer/18258653).

### 2. No account-and-associated-data deletion request path found

The game has a Hard Reset control, but `scripts/save_state/save_runtime.gd:857` resets game state and saves locally; it does not implement a request to delete Firebase authentication, cloud saves, profiles, and related server data. No account-deletion API or clearly labeled deletion request link was found in runtime source. The published policy only describes clearing local data, and Play declares no deletion request mechanism.

Provide an accessible in-app request path and a functional public deletion-request resource, with a verified fulfillment process covering associated data. A web request route is permitted; immediate destructive deletion inside the game is not the only implementation option. Do not test deletion against Brian's or a player's account.

Reference: [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111).

### 3. Ad consent flow is not wired into the game

`scripts/monetization/ad_bonus.gd:58` initializes MobileAds, and line102 loads an ad directly. Runtime source has no call to the bundled UMP consent-information/form API and no consent-aware request gate or privacy-options entry point. UMP plugin files alone do not implement consent. The new account's Privacy & messaging screen shows Create for European and US-state messages, rather than an established published-message flow.

The production track is available in 178 countries/regions. Configure the applicable regional messages, integrate the consent flow and required privacy-options entry point, and validate applicable consent/decline paths before worldwide ad serving.

Reference: [Google AdMob UMP integration](https://developers.google.com/admob/android/privacy).

### 4. Global chat lacks player report/block controls

`scripts/ui/profile_chat_overlay_surface.gd:758` renders message rows as avatars, labels, and message panels, with no report or block action. Runtime source contains profanity filtering and displays moderator-deleted messages, but no user-facing report-content/report-user/block-user flow was found. These existing safeguards do not provide the missing controls for public user-generated content. Review user-policy acceptance and moderation handling along with adding those controls.

Reference: [Google Play user-generated-content policy](https://support.google.com/googleplay/android-developer/answer/18258653).

### 5. Release validation is not green

- `scripts/check-project.ps1` failed at the performance resource contract: `assets/content/events/halloween/launch-greeting.png.import` is stale. It currently uses compress/mode=0 and compress/high_quality=false; `scripts/configure-performance-imports.ps1` requires mode2/high_quality=true for this texture. Correct its import settings and reimport through the safe wrapper, then recheck the actual popup appearance and rerun the gate.
- A separate `test-skills-page-performance.ps1` run failed. Fight scrolling peaked at 24,189 microseconds against a 22,000-microsecond maximum; Fishing scrolling had 3/210 frames above the 60 FPS budget (maximum 19,107 microseconds). These are headless benchmark results, not measured physical-phone frame rates. Investigate and meet the project budgets; do not suppress assertions to obtain a pass.
- Eight additional focused tests passed: save hardening, save lifecycle, online identity safety, stability regressions, online/chat reliability, activity-card geometry, fresh-save skill swipe, and resource lifetime.
- The full suite halted early, so the remaining full-suite tests are not certified by this audit.

Evidence: `.codex-tmp/readiness-072-oct23/focused-results.txt`, individual test logs in that directory, and captured full-suite tool output. `check-project.log` contains only the portions PowerShell redirected; the import failure was reported on the tool stream.

### 6. Production artifact and live backend verification are still required

The only newly built 0.7.2 AAB is `builds/android/idle-elite-preview-debug.aab`. Its manifest identifies `com.idleelite.game.preview` and `android:debuggable=true`; it is not the production upload artifact. There is no signed production 0.7.2 AAB in builds/android. The signed 0.7.1 candidate predates the current changes and must not be substituted.

The existing-release Firebase check compared against the published 0.7.0/code42 bundle, then failed when fetching deployed rules because Firebase CLI credentials have expired. Restore normal CLI authentication and rerun `check-firebase-existing-release.ps1`; do not bypass the live-rules gate. No rules or player records were changed.

After fixes and successful checks, build with `scripts/build-android-release.ps1 -ExistingReleaseBaselineAab builds/android/idle-elite-release-v0.7.0-code42.aab`. Validate the final production manifest, upload signer, bundle, exclusions, native-library and APK alignment, and test the Play-delivered update through a testing track before production rollout. Keep production saves intact.

## Verified positives

- Play Console shows production **0.7.0/code42**, full rollout, and the newest uploaded bundle is code42. The local 0.7.1/code43 candidate has not appeared among uploaded bundles. Code43 is currently available for 0.7.2; recheck immediately before a future upload.
- Play's current policy issue is the Android16/API36 target requirement. The current source and freshly inspected 0.7.2 preview manifest target API36, minSdk24. This addresses the candidate's API setting; Play has not accepted a new production bundle yet. [Current API requirement](https://support.google.com/googleplay/android-developer/answer/11926878).
- New AdMob account `weskillnow@gmail.com`, publisher4125359195200512: **account approved**. Idle Elite app: **Ready / Ad serving enabled**. This supersedes October22's pending-review status. Zero requests/impressions in this new account are not proof of live delivery.
- Source and preview manifest use app ID `ca-app-pub-4125359195200512~1607281974`. Release runtime unit is `ca-app-pub-4125359195200512/8284370963`; debug uses Google's test unit.
- Public app-ads.txt returned HTTP200 and contains both the approved new publisher and intentional old publisher. Do not close the old account as part of this audit.
- Bundletool validates the preview bundle. Both ARM64 ELF libraries have 16,384-byte LOAD alignment. No signing-key/local-release/build-output payload paths were found by the bundle inventory check. Final production APK ZIP alignment still needs validation; preview ELF alignment alone does not clear the full 16KB requirement. [Android 16KB guidance](https://developer.android.com/guide/practices/page-sizes).
- Earlier this session, the physical Galaxy S24 Ultra successfully updated the preview while preserving its existing save. Offline summary, Halloween greeting, outside-tap dismissal, and three active fishing frames were inspected without visible tearing. The captured process log had no script errors or fatal exceptions. See `docs/playtests/2026-10-23-android-0.7.2-preview.md` and raw evidence at `H:/Codex/Projects/IdleElite/outputs/phone-0.7.2-oct23/`.
- The phone was no longer connected during this audit, so no additional physical-device tests were run. No Play-signed 0.7.2 update, current-build rewarded-ad cancellation/completion, or two-device cloud-conflict test has been completed.
- Play's 28-day vitals summary reported data unavailable; that is not evidence of zero crashes. Previously documented native crash concerns remain unproven fixes.
- No headless Godot test process remained at audit completion. The existing visible desktop preview was preserved. Minor existing blank-line-at-EOF warnings in two release docs are cleanup items, not upload blockers.

## Recommended order

1. Correct privacy disclosures and implement privacy/deletion, consent, and chat-safety paths.
2. Correct the Halloween texture import and investigate the two performance failures; rerun release checks.
3. Reauthenticate Firebase and pass the live backend compatibility check.
4. Build and validate the signed production 0.7.2 artifact, then verify a Play-delivered update and remaining ad/cloud cases.
5. Review the resulting pre-launch report before approving production submission.

The audit did not upload, publish, deploy, reset, or delete anything.
