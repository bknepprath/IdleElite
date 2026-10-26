# 0.7.0 patch-notes tracker

## Clear Rockslide polish: October 25

Added distinct fragment arcs, grounded shadows, landing dust, slingshot recoil, projectile trails, break rings and fading damage numbers. Volleys reserve in-flight damage and spread onto surviving targets. Four clearance markers show progress to the next wave; the wave number highlights on advancement. Upgrade buttons show current and next values with material costs, purchase feedback and unavailable states. Failure offers Tap to retry. The activity is 900px tall to keep the three upgrade rows readable.

Gameplay and real-main capture checks pass, including fragment separation, volley targeting and advancing waves. Source-database, UI-boundary and asset-path contracts pass. Raw before/transition/settled images remain under `outputs/verification/rockslide-oct24/`. The latest desktop source is available through `scripts/play-level-50.ps1`, using a separate offline profile with all skills at least level 50. Normal saves and cloud accounts are untouched. No phone install or release publication.

## Clear Rockslide: October 24

Added a Fighting activity at level 12 inspired by the rolling-boulder shooter loop requested by the owner. The blue character automatically fires a slingshot uphill. Real projectiles reduce boulder HP, large boulders split into two bouncing fragments, and clearing a complete group awards XP, mastery and Sand while paying stamina once. Three escaped groups stop the run. Power, Speed and Volley purchases spend wood materials and change actual projectiles; upgrades and progression are saved and protected from older cloud saves. The host simulation continues while the card is unmounted. Existing activity cards and tier/neighbor indexes remain unchanged.

Gameplay, actual-main touch/capture, production/medal and save-normalization checks pass. Fourteen-screen capture audit passes. [Implementation and raw evidence](playtests/2026-10-24-rockslide.md). Local source only; no phone installation, release export or publication. Longer-session economy tuning remains open.

## Production building silhouette: October 24

- Simplified Shape Wooden Parts to the standard activity layout with an input/output row
- Added a centered V cut through production building faces, progress rails and rear plates

Evidence: [production building captures and checks](playtests/2026-10-24-production-building-shape.md)

## First-use interaction guidance: October 24

- Added nonblocking first-use arrows for the Firepit and jail, with saved dismissal after interaction
- Clarified the Firepit's one-scrapwood requirement and restored visible jail tap feedback
- Made ordinary Thieving jail immunity apply five levels above an activity's unlock

Evidence: [real-main captures and interaction checks](playtests/2026-10-24-soft-interaction-guidance.md)

Last updated: 2026-10-14. Unreleased working record, not release approval.

This is the maintained inventory for the 0.7.0 player notes in `../play-store/docs/release-notes-0.7.0.txt`. Update both after relevant changes. Record final behavior, not superseded designs. Keep planned work and outstanding acceptance separate from implemented changes. Add a dated evidence link when implementation or verification changes. Do not claim that a test pass establishes release readiness.

## Progression and Wisdom: implemented prototype, balance pending

- Added 33 activity-unlock projects across all five skills: Fighting 6, Thieving 6, Building 9, Woodcutting 6, Fishing 6.
- Kept the opening activities level-based. Later activities add visible work, resource requirements, cross-skill tasks, and Wisdom requirements.
- Successful completions advance permanent project progress. Failures and changing activities do not erase that work. Offline completions use the same progress-credit path.
- Replaced fixed source-activity tasks and inventory payments with dedicated unlock resources: Grit, Clues, Plans, Trail marks, and Lures. Multiple activities produce each type; successful completions route units to the nearest unfinished compatible blocker and carry surplus forward without double counting. Source portraits show the icon and per-success yield at bottom left.
- Replaced the wide requirement bucket with compact illustrated blocker badges and curved progress bars. Clicking chooses the unlocked source with the highest current expected production rate, accounting for cycle time and success chance, with higher level as the tie-break. Removed the Patch Fence mission presentation. Wood/stone art now preserves its original aspect ratio. Work/resources/Wisdom clearing still reveals the standard level lock where needed. Existing work and legacy material-payment credit survive save migration. Resource transfers are bounded, short-lived animations. Added five shared resource icons and one blocker sprite. Evidence: [resource blockers](art/unlock-resources-070.md).
- Expanded Wisdom sources to Fighting and Fishing, retaining per-skill Wisdom progression.
- Added project-progress save normalization and cloud regression protection; previously unlocked activities remain accessible to existing saves.
- Set the update version to 0.7.0. Progression pacing and project targets are still experimental.

Evidence: [progression prototype](playtests/2026-10-12-progression-prototype.md), [progression plan](progression-master-plan.md).

## Desktop and itch.io experience: implemented, final browser acceptance pending

- Added a wide gameplay layout with three skill pages and independent vertical scrolling; narrower windows show fewer pages.
- Fit the native startup window to the monitor work area, including borders/taskbar. Choose one, two or three columns from both physical and canvas width; 1280x720 and 1366x768 now show two full pages. Cap column enlargement on ultrawide/4K displays, keep header gauges inside compact columns, and let the drag hint wrap beside social panels. Achievement messages follow the available gameplay area after resizing and stay clear of Chat and the first-use drag hint. Existing native-resolution desktop rendering and filtered artwork are retained.
- Real-game resize tests passed from 800x600 through 3840x2160 and native fullscreen, including live training, chat, ribbon bounds and all five header gauges. Browser zoom/itch.io and physical Windows DPI changes remain unverified. Evidence: [desktop responsive checks](playtests/2026-10-13-desktop-responsive.md).
- Horizontal dragging rotates through all five skills in order, wrapping both ways. Pages slide in and out; skill selection does not use dropdowns. Scroll positions are retained.
- Returning to Skills preserves the focused skill and expanded activity/tier details. Resizing or opening Chat keeps a currently visible running skill on screen and restores its previous column when space returns. Following a project source explicitly selects that source instead of restoring the previous focus.
- Restored the mobile-style bottom icon ribbon. Revised its selected state and removed the light bottom ridge.
- Expanded the Player Hub across the available window without stretching its art. Supporting controls use the left inspector; optional Chat or High Scores use the right panel and reduce visible skill columns.
- Kept the existing high-score backend and categories. This does not promise new cross-platform account-linking support.
- Smoothed adjoining skill-header gradients, panel entry/exit motion and carousel settling with Bezier easing.
- Restyled chat, leaderboard, mission controls and side panels with consistent surfaces and soft shadows. Removed the desktop leaderboard's bright blue frame and the detached mission-board X.
- Reduced leaderboard outline weights on mobile and desktop; contained avatar art within its rounded border.
- Corrected incomplete/outside-window drags, focus-loss cancellation and offscreen pages intercepting panel scrolling.
- Rebuilt the appropriate skill page when resizing between desktop and portrait, fixing reuse of a cropped desktop column on mobile.

Evidence: [carousel and motion](playtests/2026-10-11-desktop-carousel.md), [panel polish](playtests/2026-10-11-desktop-panel-polish.md), [leaderboard outlines](playtests/2026-10-11-leaderboard-stroke.md), [activity feedback](playtests/2026-10-13-activity-feedback.md).

## First-time opening and loading screen: implemented

- Replaced the startup flex animation and procedural bridge loading illustration with ImageGen bridge-building artwork in the game's thick-outline style. The boot image is static; the native loading bar reports loading progress.
- Kept Fighting centered during the opening, with its header visible and instructions beneath Push-Ups. Hidden skill pages no longer hang off the window edges.
- Began revealing the surrounding game before Fighting level 2: Skills and Settings fade over 0.65 seconds after the first completed Push-Up; Fishing begins after the second completion.
- Fishing and Thieving each fade over 0.55 seconds, with Thieving starting 1.25 seconds later. Neighboring header colors blend in over 1.8 seconds. These replace the rejected slow entrances.
- The second Fighting module, new progression entries and activity previews fade over 0.55 seconds, including desktop rebuilds. Desktop reveals keep artwork, backing, text and locks opaque together and reveal them against the matching page background, eliminating transparency between internal layers. Temporary reveal covers are removed on completion, cancellation or target destruction; unrevealed controls cannot intercept pointer input. Scrolling existing entries keeps its short transition.
- Corrected the artwork shader so backgrounds respect inherited opacity during fades.
- Replaced the all-at-once ribbon reveal with saved, individual feature introductions: Hub at Building level 3, Shop at five bronze medals, Progress/High Scores at total level 25, Chat at total level 30, Pins after pinning an activity, and Queue after the neighboring skills appear. Locked icons remain visible as translucent black silhouettes; clicking explains the milestone or remaining introduction time. Fixed the circular requirement that hid Queue until a queue already existed. Eligible features unlock at least 30 active seconds apart. Existing players retain access.
- Reset clears desktop onboarding preferences. The latest visible opening suite passed the full Settings reset gesture and restored the centered fresh opening; earlier intermittent results remain recorded in the historical playtest note.

Evidence: [focus and reveal regression checks](playtests/2026-10-13-focus-reveal.md), [opening revisions and latest test limitations](playtests/2026-10-13-desktop-opening.md), [boot art contract](art/boot-070.md). Earlier level-2-gated reveals and code-drawn loading art are superseded.

## Activity UI, feedback and medals: implemented

- Added four restrained ImageGen backgrounds shared across 23 activities: Building workbench/timber yard, Woodcutting shaded clearing and Thieving quiet market lane. Added dedicated Wrap Hands and Sharpen the Pencil art. Existing masks and gameplay are unchanged. New imported resources total 1.43 MiB per platform before package compression; measured desktop texture payload is 2.01 MiB including mipmaps. Real-game desktop art inspection passed; the extended input check has an unresolved Count the Coins tap, and browser/phone acceptance is pending. Evidence: [art refresh and verification](art/skill-background-refresh-070.md).

- Skill XP labels now show progress within the current level, matching the fill bar. Progress shows lifetime XP; level 99 retains a lifetime total. Saved XP, level requirements and reward amounts are unchanged.
- Routine XP rises a shorter distance at a steady size, and normal successes no longer bounce the activity art. Existing critical-hit and level-up effects are retained. Running-activity styling was deliberately excluded from this pass.
- Verified current-level XP, live project credit, source navigation, preserved details/scroll, Chat and resize behavior, reward cleanup, and portrait project readability in the real game. Evidence: [progression polish](playtests/2026-10-13-progression-polish.md).

- Fixed large late-game XP totals pushing desktop header gauges outside their columns. Fit the XP label to its reserved width, retaining the full value and caching measurements until the text changes. Verified level 98 across all five skills at 1280x720, 1920x1080 and 3840x2160.
- Desktop reward popups follow their activity while columns move instead of drifting over neighboring skills. Popups end when their anchor disappears and are freed after the existing animation. An actual completion/drag check measured zero horizontal drift and verified cleanup. Evidence: [desktop polish audit](playtests/2026-10-13-desktop-polish.md).

- Fixed dark overlap dots on faded navigation arrows. Shared mobile/desktop chevrons now draw continuous rounded contours instead of overlapping line segments and circles. Verified resting and revealed desktop arrows and portrait buttons in the real game; corner navigation checks pass.
- Show remaining berry inventory centered on enabled berry badges. Successful use pulses green and cannot also trigger a red failure shake.
- Hide Pins, Queue, overall Skills and sorting controls immediately when leaving Skills.
- Fixed visual glitches while minimizing/expanding activity cards.
- Kept canceled activity bars updating every frame until drained instead of at the 0.5-second static refresh interval. The visual drain starts from the displayed fill, without an upward jump; actual canceled-progress decay and resumption rules are unchanged.
- Kept running desktop activities updating every frame even when another skill column has focus, including tired training.
- Added thin curved XP bars inside level-requirement padlocks, above the lower border. The level number is horizontally centered and raised 18 logical pixels when a progress bar is present, leaving a clear gap; there is no percentage text. Fill measures XP from the previous activity's required level to this activity's required level, so later locks do not begin almost full. Combo requirements track their own skills independently. Wisdom and project/resource requirements retain their separate UI. No new currencies or saved progression fields.
- Desktop skill navigation reuses the full-width mobile left/right buttons in the lower gameplay corners to slide all columns together. At rest only faint original chevrons remain; a brief hover or keyboard focus reveals the complete button with a 0.24-second Bezier fade/slide. A 0.65-second exit delay prevents flicker. The first touch reveals without navigating. Removed the five-skill icon strip and the permanently reserved navigation row; no column scrolling is needed to reach the arrows. A first-use drag hint fades out over 0.4 seconds after a successful drag; navigation stays hidden during the centered opening and outside Skills. See [corner navigation verification](playtests/2026-10-13-corner-navigation.md).
- Centered Fire Pit artwork, let its lock chains extend over the outer card layer, and prevented the scrapwood feeder from reopening or contracting when focus changes between desktop columns. Repeated identical layout updates no longer restart its tween.
- Reduced unlock hitches by retaining existing desktop columns/cards, mounting new activity cards over multiple frames, budgeting static card updates, separating XP-only lock updates from structural lock changes, caching medal totals, and rejecting ineligible global-medal entries before expensive action lookups. Normal completion no longer triggers a redundant nested desktop UI update.
- Short local unlock samples improved from a 296 ms worst frame to roughly 57â€“64 ms; hitches remain. These are not a 30-minute soak or proof of consistent frame pacing. See [navigation, Fire Pit and performance checks](playtests/2026-10-13-desktop-discovery-performance.md).
- Verified the new padlock layout in raw 1920x1080 desktop and 1080x1920 portrait captures; physical phone acceptance remains pending. Evidence: [progress motion and padlock prototype](playtests/2026-10-13-progress-motion.md).
- Removed click-opportunity windows from resting/stamina-restoration activities. Restyled other windows with thick rounded outlines matching the mastery treatment.
- Increased text-outline weight on level-up displays, Hub signs and buttons.
- Kept full Tier 1/Tier 2 wording on outer banners; use T1/T2 in expanded details and the yellow accuracy icon instead of the word Accuracy.
- Removed the separate medal/name column from expanded tier menus. Requirements use an inline medal and wording such as "on every T1 activity".
- Clipped tier-progress fills inside their pill shapes and kept tier-info popups within the screen.
- Show both skill colors on empty combo progress rails and front/depth faces, before an activity is running.
- Excluded all nine arena activities from mastery medals, medal totals, tier requirements and global medal buffs, including old saved arena mastery.
- Resting activities earn medals with approximately one tenth the repetitions: Heavenly takes 271 completions from zero instead of 2,707. Existing mastery is preserved.
- Fixed activity bars moving backward after an immediate refresh, reproduced on Practice Kicking and Sneak Past Tip Jar. A stale cycle-drain animation was overriding current progress; repeated samples also no longer erase the measured forward speed. Success chances and reward timing are unchanged.
- Fixed lock-chain audio calling a removed control-reference helper.

Evidence: [activity polish and mastery tests](playtests/2026-10-12-activity-polish.md), [activity feedback reproduction](playtests/2026-10-13-activity-feedback.md).

## Fishing: implemented

- Fixed timing-opportunity input stopping Fight A Shark.
- Positioned fishing tool animations in the available space between location tiles and stat boxes.
- Reduced right-side XP/fish box widths and their internal padding while retaining readable text. Restored the location zonesâ€™ original 27px outer margins, 260px method columns and existing spacing.
- Corrected the fishing animation tween leak carried forward from the stability work.

Evidence: [shark input](playtests/2026-10-11-fishing-opportunity.md), [fishing layout](playtests/2026-10-13-activity-feedback.md), [stability evidence](../play-store/docs/launch-readiness-2026-10-11-v0.6.2.md).

## Tip and reveal corrections (2026-10-13)

- Removed the fixed two-line ellipsis from pull-down tips, enlarged their text region, and shortened long instructions. Tips wait for enough pull space before fading in. All 19 fit at 1920x1080 desktop and 1080x1920 portrait in the real game.
- Prevented repeated unlock callbacks from staging an already-entered preview again; new progression slots bypass the competing parent fade, and ceremony fades cancel competing lazy-card fades.
- Locked ribbon explanations now wrap inside the viewport, remain readable for three seconds, and replace previous messages on repeated taps.
- The original appear/disappear/reappear report was not reproduced in the automated baseline. A repeated-callback regression check and post-fix real-game unlock monitoring passed; user confirmation remains necessary.

Evidence: [tips, ribbon and reveal verification](playtests/2026-10-13-tips-ribbon-reveals.md).

## Stability work carried into 0.7.0

- Safer older-save loading/migration, atomic saves, backup recovery and protection against cloud progress regression.
- Fixed the reproduced resume/page-change crash. Do not claim the original store-review crash was conclusively reproduced from the review alone.
- Corrected offline timestamp/credit handling on backgrounding, resume and cold start, including the offline-progress setting.
- Desktop and browser focus loss now checkpoints the save without suspending simulation, disconnecting chat or pausing music. Focus return does not restart the music or award offline progress. Mobile focus, actual application pause and measured processing gaps still use offline recovery.
- Genuine interruptions under one minute still earn progress without a Welcome Back modal; longer absences retain the summary. Prevented duplicate summary resize-signal connections. Desktop focus cycles were tested with offline progress both enabled and disabled; Android and browser lifecycle behavior still need platform verification.
- Preserved mission cooldowns across restarts/backgrounding.
- Granted ad boosts only after the SDK reward-earned callback.
- Fixed audio resuming after app/window changes, interrupted page swipes, outside-window dragging and dark-mode remaining counts.
- Added polling/cache cleanup and fixed the known fishing tween leak. Do not claim all long-session freezes are resolved: strict frame-time checks and final platform soak acceptance remain outstanding.
- Android target SDK is configured to 36; recheck store requirements when preparing the actual release.
- Added texture compression and unused-asset exclusions. Quote a download-size reduction only after measuring final 0.7.0 deliverables; old package sizes are not a current device-download estimate.

Evidence and unresolved checks: [stability release record](../play-store/docs/launch-readiness-2026-10-11-v0.6.2.md).

## Portraits: locally implemented, acceptance and online support pending

- First portrait revision was rejected for thin outlines and excessive detail. Revision 2 uses simpler shapes and heavier black contours.
- Two replacements: Shark Bucket and Brick Helmet Builder. Three additions: Cookie Jar Thief, Wheelbarrow Champion and Shrub Sunglasses.
- Replaced portrait IDs affect existing users; retired artwork is not preserved for current users.
- Picker, profile, chat and leaderboard use the shared portrait catalog. Local tests cover all 23 IDs.
- Do not advertise the portrait refresh as final until the revised art is accepted and IDs 20-22 are verified against deployed Firebase rules. The documented rules changes are local, not a confirmed deployment.

Evidence: [portrait revisions and deployment limitation](playtests/2026-10-11-profile-portraits.md).

## Planned or excluded: do not list as delivered

- Dual training is not implemented and was explicitly excluded from the current progression/Wisdom prototype. Requirements remain two activities, including two from the same skill, unlocked by constructing something using resources from one activity in each skill. Workshop name, quantities and source levels are proposals. See [dual-training requirements](dual-training-v070.md).
- YouTube Playables distribution remains a feasibility question, not a shipped platform. See [platform notes](desktop-v0.7.0-plan.md).
- Prototype F1-F4 chapter shortcuts, unsaved test profiles and unmuting Brian's preview are development conveniences, not player patch-note entries.

## Checks before finalizing player notes

- Accept progression pacing and portrait artwork; verify live profile/chat/high-score round trips and any required rules deployment.
- Repeat Settings reset manually and investigate the intermittent automated confirmation gesture.
- Validate older-save updates, offline/resume behavior, two-device cloud conflicts, ad completion/cancellation/blocking and audio/tab changes on their actual platforms.
- Run the final 30-minute gameplay session and resolve outstanding performance evidence; headless shutdown warnings do not establish a leak-free session.
- Verify real itch.io embed/fullscreen dragging and resizing, and physical Samsung rendering before Android release.
- Measure final download sizes. Set the public changelog date only when releasing. Do not produce or publish a release candidate without the user's request.

## October 14 progression art revision

- Removed numeric yields and fractions from source portraits and blockers; curved bars retain progress.
- Replaced the Trail marks sign with Resin, preserving its `trail-marks` data ID. Added Coins and Rivets and assigned resources by activity family, including shared sources across skills.
- Added shared ImageGen holders and cover art for timber, stone, iron, bronze, silver, gold, titanium, platinum and obsidian.
- Rejected procedural crack lines and polygon chips were removed. Current damage uses generated frames, with generated debris sprites moved by code. No procedural replacement artwork is permitted for these effects.
- Drop amounts remain deterministic on successful completion. Random drops and final pacing are not implemented or accepted.

- Kept stored inventory icons bottom-left and moved unlock-resource icons top-right. Icons and awards stop when no revealed blocker needs the resource, and return when new demand is revealed; no hidden stockpile or prefilling later blockers.

- Matched unlock-resource badge size and overlap to the inventory badges and added an eased fade when demand changes.
- Replaced the full-body Wrap Hands portrait with an ImageGen close-up of two blue hands tightening a white wrap. Simplified the left hand after feedback to remove individual finger details; retained the approved right-hand gesture. Sharpen the Pencil is the other newly added resting portrait and remains available for review.

- Corrected Sharpen the Pencil artwork: working tip enters the sharpener; eraser is on the free end.

## Construction panel refresh, October 14

- Regenerated the shared build-required wooden plaque with ImageGen to remove the pale cutout fringe. Replaced the underlined cost stack with one centered row, a larger stored-resource icon and heavy outlined text. Preserved material costs and the title-line Build control.
- Art provenance and validation: `art/build-requirement-refresh.md`.

## Barrier layout, automatic locks, and Practice Pool, October 14

- Restored the original broad generated timber and stone barriers. All nine materials now follow activity width with preserved proportions; deeper metal covers have reserved clearance.
- Reproduced Building level-two auto-unlock disappearing when Building was visible but another desktop column had focus. Both auto-unlock routing passes previously treated every unselected skill as off-screen and immediately committed its unlock. Visible side-column cards now use the existing falling-lock ceremony and commit after it finishes; completion refreshes their own column without stealing focus.
- Removed Practice Pool's No fish label, removed its oversized title override, and set its base success chance to 97% in the authoritative activity database.
- Regression evidence: `scripts/tests/auto_unlock_desktop.gd`, `.codex-tmp/auto-unlock-before.log` reproduces both failed animation assertions; `.codex-tmp/auto-unlock-fixed.log` reports `AUTO_LOCK_ANIMATION failures=[]`. Broad-barrier and Pool checks use `scripts/tests/full_width_barriers.gd`. These checks do not establish a lag-free release.


## Halloween prototype, October 14

Implemented in the production game; not exported or published.

- Trick or Treat occupies the previously empty Thieving level 8 slot. One successful 8-second base cycle earns one candy and modest Thieving XP. It is excluded from permanent medal requirements.
- Construct its doorstep using 12 Webs from Trim Overconfident Shrub (Woodcutting 6), 8 Cloth strips from Wrap Hands (Fighting 7), and 10 Lantern parts from Hammer Nails (Building 2). These are direct blocker contributions, not inventory. Existing normal resource drops remain intact. Requirement icons navigate to the producing activity; seasonal badges fade when their requirement is filled.
- Candy restores an integer chosen uniformly from 10 through 15. Eating at or below maximum is allowed, including exactly full. Any amount above maximum blocks the next piece. Spending, resting, natural regeneration and save restoration preserve the excess correctly.
- Each non-Fishing skill has a candy auto-eat toggle below the fish along the left edge of the stamina gauge. Fish remains at its original position. Candy is smaller and rotated to follow the gauge without touching it or the fish. It has no count label; its off state uses the exact same silhouette color and 35% opacity as fish. Enabling it restores full-color art. Enabling it eats one piece if permitted; active stamina-consuming training eats another when back within normal range. Candy is attempted before fish. Shared inventory prevents simultaneous duplication.
- Overfull stamina uses an ImageGen orange/yellow spiral inside the existing gauge mask. The ordinary skill fill returns at the actual maximum, independent of the eased number animation.
- ImageGen supplied candy, Webs, Cloth strips, Lantern parts, doorway action art, spiral fill and a separate doorway background. Art lives in assets/content/events/halloween; AtlasTexture slices share one sheet. A store icon master is in play-store/assets/halloween-2026/icon-master.png, not uploaded.
- Halloween configuration lives in docs/activity-database.json, seasonal_events.halloween-2026. enabled=false removes activity/drops on the next load. An ends_at_unix deadline also stops the running event and removes it during play. Saved candy remains usable; its toggle fades away after depletion once the event is inactive. Historical unlock/construction keys remain compatible with save regression checks.

Release work still required: choose the event end timestamp (currently 0 for local iteration); review final balance and art; prepare the store icon in the required upload format; run the Android preview on the physical Samsung phone and complete the normal release checks. No release candidate, package, deployment or store upload was made.

## Readiness audit, October 14

- Kept the startup cover until the desktop hierarchy finishes mounting; made desktop startup idempotent and faded bottom-ribbon children with their backing.
- Increased supporting XP from 1 to 2 for Wrestle Stuck Gate Latch, Saw Planks and Split Firewood, retaining primary XP and requirements. Verified each through actual game input.
- Shared the immutable card-reveal shader and reduced runtime-asset audit traversal; explicitly checked dynamic construction assets.
- Desktop regression batch passed 12/12. Targeted runtime rechecks resolve asset-path, Android contract, save isolation and swipe/construction test setup issues. Strict scroll performance and several remaining release gates still fail or need acceptance.
- Full evidence, remaining failures and resolution findings: [readiness audit](playtests/2026-10-14-readiness-audit.md). No export or publication was performed. Halloween acceptance remains with its implementation work.

- Corrected the timber resource holder's authored horizontal padding so its opening, resource icon and curved progress bar share a center. Verified Repair Small Shack in real desktop and portrait gameplay; resource_holder_alignment.gd passed.

## Unlock layout stability follow-up, October 14

- Reproduced completed resource barriers losing their layout row in both desktop and portrait. Clearing a barrier now mounts the ordinary activity in the same row, retaining its reserved height and surrounding cards. Portrait project completion uses the existing in-place list update instead of rebuilding the page.
- Layout snapshots now retain control identity even when a project changes its module key. The retained row is not replayed as a new entrance. Layout transition setup runs before drawing, avoiding a visible final-position frame before animation starts.
- Real-game regression `scripts/tests/unlock_layout_stability.gd` starts the producing activity through UI input and follows barrier completion at 1920x1080 and 1080x1920. Final result: no lost row frames, no transparent row frames, maximum row movement 0 px in both sizes. Seven ribbon feature reveals also preserve button positions.
- Evidence: `.codex-tmp/unlock-stability-baseline.log`, `.codex-tmp/unlock-stability-verified.log`, raw before/transition/settled frames `.codex-tmp/desktop-responsive/unlock-stability-{1920,1080}-*.png`. Module-list transitions, pinned scroll anchor, activity progress turnover and UI/crash contracts pass. This targeted result does not clear the earlier browser, device or performance release gates.
- Expanded final regression also records zero neighboring-row visibility/position changes in both viewports; automatic side-column unlock recheck passes. Logs: `.codex-tmp/unlock-stability-neighbours.log` and `.codex-tmp/unlock-stability-auto.log`.

## Smoothness follow-up, October 14

- Resource barriers now remain opaque until the ordinary activity is mounted in the same production row. The original barrier then fades over it for 0.32 seconds, above the card artwork and locks. Repeated resource updates do not restart the fade; the outgoing control is freed afterward.
- Tall metal barriers retain their row clearance through subsequent card-state updates. The expanded real-game test initially caught jumps up to 62 px in portrait; the final tall-barrier run records 0 px movement and zero neighboring-row changes in both dimensions.
- Desktop popup closing now hides the control when its current tween finishes. Canceling a close cancels its hide callback, preventing an old close timer from cutting a later fade short.
- Real-game evidence: `scripts/tests/unlock_layout_stability.gd` (timber and iron, each at 1920x1080 and 1080x1920), `scripts/tests/modal_motion_interruption.gd` (production Profile reached through Chat), `.codex-tmp/smoothness-handoff-verified.log`, `.codex-tmp/smoothness-tall-handoff.log`, `.codex-tmp/modal-motion-verified.log`. Raw frames remain in `.codex-tmp/desktop-responsive/` with `unlock-stability-`, `unlock-tall-stability-`, and `modal-motion-` prefixes.
- The detail-refresh regression now covers resource-barrier previews as well as activity previews and verifies in-place row order. No viewport, renderer, seasonal, save-format or release-packaging changes were made. Earlier platform/performance acceptance gates remain open.

## Lag audit, October 14

- Replaced the repeated nested Fishing unlock search with one teaser lookup. Matched traced scrolling averages fell from 11.86 ms to 5.01 ms (58%); an independent 1,008-state equivalence check matches all previous decisions and runs about 16 times faster.
- Cached-card construction now consumes the same per-frame budget as mounting, preventing additional removal/layout work in that frame.
- Transient animation cleanup visits only metadata present on each node. Decorative opacity and unrelated tweens survive; reveal position/scale still reset correctly.
- Added `scripts/test-lag-regressions.ps1`, `scripts/tests/lag_regressions.gd` and the real-game `scripts/tests/desktop_lag.gd` audit. Forty screen samples, four resource-lifetime cycles, module transitions and UI/crash contracts pass. Resource-barrier handoffs retain 0 px movement and zero empty/faded/missing-row frames at 1920x1080 and 1080x1920 after the cleanup change.
- The complete performance gate still fails cold Thieving/Building scroll peaks and ordinary swipe timing; large Queue/Pinned page entry is also expensive. Real desktop Fishing scroll p99 is 27.5 ms. No browser/device release clearance is claimed. Full timings and remaining work: `docs/playtests/2026-10-14-lag-audit.md`.

## Blocked activity outline consistency, October 14

- Audited all nine resource-barrier materials against normal activity borders, titles, small resource holders and curved progress bars. The oversized black perimeter was baked into low-resolution cover art and magnified at full module width.
- Revised all 34 damage frames with ImageGen, retaining material identities, cover proportions and existing asset paths. Reduced black perimeter bands and oversized bolt outlines. Blocked titles now share the ordinary activity-title outline constant while retaining their readable 60-pixel size.
- The first full production-scene audit passed in desktop and portrait. Iron, bronze and silver needed a second outline pass and a final transparent-cutout correction after visual review caught a backdrop. Final check evidence and generated sources: `docs/art/blocked-activity-stroke-audit.md`.
- No balance, save, viewport, renderer or packaging changes. Android device and earlier performance acceptance remain separate release gates.

- Final blocker-art follow-up passed (`FULL_WIDTH_BARRIERS failures=[]`, `.codex-tmp/barrier-stroke-final.log`); inspected the final transparent metal covers at desktop and portrait sizes.

## Lag and bug audit fixes, October 14

Implemented in the working tree; verified headless. Not committed or published. On October 15, at Brian's request, a debug preview build of this tree (0.7.0, build 42, `com.idleelite.game.preview`) was installed on his Galaxy S24 Ultra with `scripts/install-android-phone-debug.ps1` for device testing: it starts with no script errors and applied offline progress on first launch. No fix has been accepted on the device yet and no release package was built. No viewport, renderer, stretch-mode, save-key or packaging changes. Findings, measurements, fix status and the changed-file list: `H:/Codex/Projects/IdleElite/outputs/onigiri-audit-2026-10-14/AUDIT.md` (same folder: `fixes.patch`, `logs/`).

- Offline progress now plays time away with the live rules, one completion at a time: banked stamina is spent at full speed, a tired activity keeps working at the low-stamina speed, and regenerated stamina pays for full-speed completions as it arrives. The previous batch formula could award less for a longer absence (same activity: 39 completions for 566 seconds, 12 for 570); completions now never decrease as the absence grows, and the result matches a frame-by-frame replay of the same time. Honey doubles regeneration only while a skill is still recovering, as in live play. Idle skills regenerate during any absence and Fighting health regenerates whether or not an activity was running. The 30% offline XP and mastery rate is unchanged.
- Balance consequence, acceptance pending: short absences and Fishing are unchanged, but long absences on stamina-limited activities earn about 3.3 times the completions the old batch formula gave (late-game examples: 76 per hour before, 253 per hour now; 8 hours of Fighting 621 before, 2,072 now). `OFFLINE_XP_MULT` is the tuning value if that is too generous. First device example, October 15 (preview profile, Brawl With Milk Pail left running tired on October 10): the capped 8 hours took Fighting from level 24 to level 32, about 18,800 XP including roughly six minutes of live play after launch.
- An 8-hour catch-up on an activity that drops unlock resources fell from about 5 seconds to about 0.5 seconds in a like-for-like run. Catch-up is not shorter for Fishing (7,200 completions, 1-2 seconds) or for cheap activities that now play more completions (Prune Orchard Row, 3,856 completions, 0.75-1.75 seconds). Unlock resources for the whole absence are awarded in one pass with the same result as awarding them one completion at a time.
- Fire Pit charges one Scrapwood per 30 seconds at every tick size. At the live one-second tick it previously charged nothing while still granting Woodcutting XP and the regeneration bonus. This restores a cost players were not paying.
- A Thieving activity that was running when it was jailed resumes when its timer ends, including when the timer ends during a swipe or scroll and when it ended while the game was closed or suspended. Offline credit starts from the release time. Starting another activity still cancels the resume.
- Cold start with an active temporary event no longer drops the event, pins, collapsed modules and the activity queue. Levels, unlock flags, built modules, mastery, Wisdom, bosses, projects and Thieving trophies are restored before anything that asks whether an activity is unlocked.
- Collapsing a Fishing area no longer breaks the Fishing page. Four more calls to methods that had moved off `main.gd` were redirected: hub spend burst, the Google sign-in button, the tutorial gate latch and the temporary-event list.
- Fishing time held back while the Fishing list is touched or scrolling is repaid afterwards instead of being lost.
- Reset Data also clears boss clears, Fighting health, banked arena XP, built modules, the activity queue and berry targets.
- Lists: slow drags and the end of a fling move the list (the sub-pixel position is no longer discarded each frame); a second finger landing on a list no longer takes the drag over or makes the list jump; a drag is dropped when the app loses focus mid-drag.
- Chat no longer jumps to the newest message while the reader is scrolled up. It follows new messages at the end of the list, after sending, and on reopening.
- Queue rotation no longer changes the selected skill while a skill page is open.
- Two retry paths that re-queued themselves within the same frame (tutorial target, swipe resume scroll) now wait a frame. Either could hang the game.
- Activity start and stop, arena kills, knockouts, rooster hits, jail-bar taps and eating a fish mark the save dirty instead of writing it on the tap. The 15-second autosave and the pause/close saves persist them. Dragging a volume slider writes the save once, on release, instead of on every pointer move. Being jailed and the first-activity tip still save at once.
- Saving parses each distinct save file once, writes the save journal once per save and no longer deep-copies the payload to encode it. Envelope, checksum, temp-file verification, backups and the regression guard are unchanged. Consequence: a process killed in the middle of a save no longer leaves a `save_requested` journal entry without a result.
- The crash-session marker is rewritten when the session state changes or once a minute, instead of every 15 seconds.
- Crit chance reads the cached achievement bonuses instead of rebuilding the achievement log on every success. Unlock-resource bookkeeping caches which projects each skill reveals. The skills menu no longer replans every Fishing area each frame while Fishing runs. The Fishing page no longer rebuilds when Softwood changes, and a fully mounted list containing a project barrier no longer rebuilds every half second.
- Skill and medal thresholds come from tables equal to the previous formulas at every level. Event activity lookups, queue validation and the stat cache no longer repeat or accumulate work.
- Smaller: an interrupted hub drag is dropped; backup tiers are no longer refreshed on every save on FAT/exFAT storage; failed cloud uploads wait 1, 2, 4 and then 5 minutes between automatic retries; project progress is never saved below what the file held.
- Not changed, device data needed first: procedural button textures generated on first use, per-card mount cost, script compile time at boot, desktop column refresh, threaded saving.

## Lag and bug audit, second round, October 15

Implemented in the working tree after the first device session; verified headless. Not committed or published. On the phone since October 15, 16:25, together with the playtest requests below: at Brian's request the working tree was installed again as the debug preview (0.7.0, build 42, `com.idleelite.game.preview`) with `scripts/install-android-phone-debug.ps1`. It starts with no script errors; the launch credited 2 hours 51 minutes away (Thieving 17 to 20); the first seven saves on the device, the first written off the main thread there, were all recorded `ok` in revision order; the debug report gave its first device figure, 77 texture loads in 99 ms and 8 drawn textures in 25 ms on the main thread in the two seconds after start. Nothing has been accepted on the device yet and no release package was built. No viewport, renderer, stretch-mode, save-key or save-format changes. One packaging-relevant change: five images now carry the project's compressed-texture import settings (below). Details: `H:/Codex/Projects/IdleElite/outputs/onigiri-audit-2026-10-14/PROGRESS.md` ("Second round") and `AUDIT.md`.

- First device session with build 42, October 15, 02:10 to 02:31, read afterwards from the game's own diagnostics: offline credit on launch, then Reset Data at 02:17, then about 14 minutes of a new game across all five skills. 120 saves, all recorded `ok`; session marker `clean`; no crash record. The phone's log no longer covered the session, so script errors in those 14 minutes cannot be ruled out from the log.
- Welcome Back: on a copy of the phone's pre-install save the time-away pass credits the same Fighting levels as the phone did (24 to 32) and the panel opens, stays until dismissed and closes on Continue. The pass itself still blocks for about a second on the development PC for that 8-hour case.
- Saving no longer holds the frame it happens on. `save_game()` on the main scene takes the snapshot on the main thread; the progress guard, encode, write, verification, backup rotation and journal run on a worker thread against a private copy. One save is in flight at most and requests made meanwhile become one follow-up. Pause, quit, focus loss, Reset Data, restore and account saves use the blocking save (`save_game_now()`), which first waits for the one in flight. Main-thread time per save on the development PC: 47 ms to 1.5 ms for a new game, 66 ms to 3.8 ms late game. Envelope, checksum, temp-file verification, backups, journal contents and the regression guard are unchanged. Headless runs and web builds keep the blocking save (`IDLE_ELITE_BACKGROUND_SAVES=1` opts a headless run in). Not yet run on a device.
- Building the save payload no longer re-derives the key of every medal and unlock flag: catalog activities remember theirs, and an event page's level is remembered while one payload is built. Payloads are byte-identical.
- The Queue page's chunky button textures (seven, drawn pixel by pixel) are drawn on a worker thread after boot instead of on the frame that first shows them (about 135 ms each on the development PC). Paper button styles that differ only in radius or margin share one texture. 203 generated images are byte-identical to the previous code's.
- The Fire Pit's dark cover is drawn with 67 rects per frame while lit instead of 512, covering the same rows.
- Reset Data also resets the music state: anything playing fades out and music unlocks again after eight completions, as on a new install. Decision pending: say if music should keep playing through a reset.
- Fire Pit, finding of the independent review (`docs/playtests/2026-10-15-independent-change-audit.md`), fixed: the fuel that had burned but was not yet charged lived in a field the save dropped, so every reload forgave up to a tenth of a Scrapwood (30 seconds of fire around one reload cost 0.9 instead of 1.0). The amount owed is now read from the saved burn total, so there is no separate field and no save-format change. Thirty combinations of tick size and reload interval each pay 10.0 Scrapwood for 300 seconds. Woodcutting XP for a burned Scrapwood now arrives on the tick that pays for it instead of one tick later.
- Unused code removed after a whole-project scan of scripts, scenes, addons, tests and check scripts: 27 functions and 17 variables, constants and signals that nothing referenced (254 lines in 15 scripts), and five script files that nothing loaded (545 lines). Six of the functions (five Welcome Back row builders and `_offline_xp_reward`) were named only by `check-activity-ui-boundary-contracts.ps1` and `docs/activity-ui-boundary-map.md`; neither names them now. Four of the files were earlier versions of the unlock-project panel (`project_scene.gd`, `project_requirement_piece.gd`, `project_requirements.gd`, `project_requirement_bucket.gd`). The fifth was `seasonal/halloween_activity_decor.gd`; it went together with the decoration sheet only it loaded (`assets/content/events/halloween/decorations.png`), which `docs/art/halloween-2026.md` records as rejected. Copies of everything removed are in the audit folder under `removed-code/`. `check-1080p-migration-contracts.ps1` lost one assertion: it required a stat-font constant that nothing had used since the expanded XP help moved to full names with wrapping.
- Five large images had never been given the project's compressed-texture import settings: two Halloween sheets, the two unlock-project state sheets and the 0.7.0 boot image. Uncompressed they take about 25 MB of GPU memory against about 6 MB compressed. `scripts/configure-performance-imports.ps1` was run for them. The export for the October 15 phone install reimported them; it changed those five `.import` files and nothing else in the project.
- Debug builds print one `TEXTURE_WORK` line per two seconds in which the main thread spent 4 ms or more loading or drawing textures. Headless runs cannot see that work; the next device session can.
- Tests: `test-thieving-heist-click-flow.ps1` and `test-tutorial-visible-flow.ps1` no longer copy, restore or delete the real desktop save (the first is headless and already isolated by `run-godot-safe.ps1`; the second now runs in its own user data folder). Ten checks that failed before this audit pass again, with no game code changed for them: each asserted something the game no longer does, or called a member that had moved off `main.gd`. They are `test-save-normalization`, `test-battery-governor`, `test-skill-first-swipe-build`, `test-thieving-heist-click-flow`, `test-berry-prep`, `test-feedback-balance`, `test-ham-feedback`, `test-game-polish`, `test-unlock-combo-visual-smoke` and `check-performance-resource-contracts`. `test-save-lifecycle-guard` gained the blocking save in its stand-in host. What still fails, and why: `AUDIT.md`, "The project's own tests".
- Measured and left unchanged: one activity card mount (about 9 to 16 ms on the development PC under load, spread over node construction, tree entry, state sync and layout with no single hot spot); the per-press button scan (0.39 ms); desktop column refresh; the time-away pass running in one frame.

## Playtest requests, October 15

Brian's notes while playing the installed preview build. Implemented in the working tree; verified headless (`fixcheck_playtest_requests.gd`, 27 checks; `audit_bottom_bounce.gd`). On the phone since October 15, 16:25 (see the section above); not yet looked at on a screen by anyone but Brian. No save-key or save-format changes.

- Bug: an activity near the bottom of a page moved up and down by 10 px about every 1.7 seconds for as long as the page was open. Cause: the material row sized a card with the plain card-height formula, while the list uses the per-activity height, which is 10 px more for a rest activity. Each tweened the card to its own number as soon as the other finished. It affected rest activities that give a material (Prune Orchard Row), locked or not. The material row now takes the card's height from the card. Checked at levels 9, 14 and 26 on all five pages: nothing moves while the list is still.
- Bug: a tap on a required item of a locked activity did nothing. The items are buttons inside the scrolling list, which takes the pointer, and they were never registered with the route that presses such buttons. They are now.
- A tap on a required item says what it is and where it comes from ("Clues / From any Thieving activity", "Grit / From Box Suspicious Feed Sack", or the first source and its level when none is unlocked yet), then goes to the best unlocked source as before.
- A tap on the resource icon of an activity goes the other way: it says what the resource is filling ("Clues 4 / 10 / for Pick Friendly Lock") and scrolls to that locked activity, switching skill page if needed. The rest of the card still starts the activity.
- New unlock type: a resource that any activity of one skill gives. A skill names it in `docs/activity-database.json` as `skill_unlock_drop`; the catalog gives it to every activity of that skill, beside the activity's own item. Thieving's Clues (the purple seal) is the first: all 36 Thieving activities now give 2 Clues per success, where 17 did. Balance consequence, acceptance pending: every Clues requirement fills from whatever Thieving activity the player prefers, so those unlocks are quicker and no longer tied to one activity. The other skills have no such resource yet; each needs one line of data and an icon.
- Resource icons on an activity's art pack into the top right corner. One that is not needed leaves no gap, and two overlap by 28 px. Before, an activity with two kinds of resource showed the second one 82 px left of the corner even when it was the only one visible.
- Mastery ring: mastery gained fills the ring over 0.55 s with a cubic ease in and out instead of jumping. A new medal level runs the ring to full, then starts it again from empty. Opening or refreshing a page still shows the value at once.

## Playtest requests, second set, and launch checks, October 15 evening

Brian's notes after the 16:25 install, and his request to get the build ready for itch.io and Google Play. Implemented in the working tree; verified headless in the phone layout and in the horizontal layout (three pages side by side, 1920 x 1080). Not on the phone: the installed preview predates everything in this section. Not committed or published; no release package built. No viewport, renderer or stretch-mode changes and no renamed save keys. One addition to the save: `activity_projects.target_multipliers` (below).

- A requirement that any activity of a skill can fill now asks for three times the listed amount. Brian found Outmuscle Angry Wheelbarrow done in about six tasks. The number is one field per skill, `target_multiplier` on `skill_unlock_drop` in `docs/activity-database.json` (3 for Thieving and for Fighting), applied by the catalog to every project step that asks for that resource, in any skill. Examples: Outmuscle Angry Wheelbarrow 12 to 36 Grit, Tackle Water Trough 50 to 150 Grit, Pick Friendly Lock 10 to 30 Clues, Harvest Moonlit Silverwood 90 to 270 Clues. Item requirements (Rivets, Coins, Lures and the rest) are unchanged. Balance, acceptance pending: 3 is a first guess to be played.
- Fighting's Grit (the red fist seal) is now the second resource of that type: every one of the 40 Fighting activities gives it, beside its own item. An activity that never gave Grit gives what the nearest Grit activity below its level gives (Push-Ups 1, Wrestle Stuck Gate Latch 1, Fight Chickens 2, Duel Fence Post 2, Fight Goblins 4). This was a reading of "do any activity within a skill ... the seal icon", applied to the one other seal the game has; say if Grit should stay tied to particular activities.
- Saves written before the multiplier keep what they had. An activity counts as unlocked only while its requirement reads as met, so tripling a requirement would have locked again every activity a 0.7.0 preview save had opened with the old amount (Outmuscle Angry Wheelbarrow at 12 of 12 Grit would have read 12 of 36). The save now records the multipliers its amounts are counted against (`activity_projects.target_multipliers`, for example `{"grit": 3, "clues": 3}`), and loading a save made under a lower multiplier, or none, scales those amounts: finished stays finished and unlocked, half done stays half done (25 of 50 becomes 75 of 150). Changing the number again later is handled the same way. Item requirements and saves from 0.6.1, which hold no project work, are untouched. Checked with a save written by the pre-fix code and loaded by this code (`fixcheck_seal_migration_write.gd` and `_read.gd`), and on a copy of the phone's save of 16:27, which had no seal requirement in progress yet.
- Click-opportunity window: corner radius 0.36 of the bar's height instead of 0.5 (a full pill), so the window keeps a little of its rectangle.
- Build-required activity (Duel Fence Post is the only one): the BUILD button sits on the boards with its price, 276 x 112 px, not in the title line. It can be built below its level. Before, a padlock was created under the boards, where it could not be seen and took the tap; now no padlock is made while the boards are up, and after building the padlock shows if a level is still needed. A tap with too little Scrapwood says what is needed.
- Web build guard: the worker thread that pre-draws the Queue page's button textures is not started in a web build, which may have no threads; there the textures are drawn when first shown, as in the released version. Background saving was already off in web builds.
- Horizontal layout: the checks for this section and for the earlier playtest requests (resource badges, required-item taps, mastery ring, build module) now also run with three pages side by side. Presses are delivered every way the engine can deliver one, including the desktop and browser order (the touch event the engine makes from a mouse click, then the click). All pass. The project's own horizontal-layout scenes that can run without a window were added to the regression run.
- First run of the 0.7.0 web build in a browser, October 15, 17:55 to 18:25. Offline: headless Edge with sound off, the build served from this PC, and every request that leaves it answered in memory, so nothing reached Firebase (`fixtures/web_horizontal_check.cjs` in the audit scratch folder, modelled on `scripts/tests/web_save_upgrade.test.cjs`). The build starts in about 13 seconds with no script error in the console. It shows three skill pages at 1920 x 1080, two at 1280 x 720 and the phone layout at 540 x 960, and changes between them when the frame is resized while an activity runs. Starting an activity, Chat and High Scores beside the skills, Settings and the Hub were looked at in screenshots. Not covered by this: the real itch page, real Firebase, sound, touch, other browsers.
- Found in that run and fixed, web only: the game started shifted to the right and cut off in any frame narrower than 800 px or lower than 600 px, which includes itch's present 540 x 960 embed and a phone held upright, and stayed so until the frame was next resized. `desktop_layout.configure_window()` gave the window a minimum size of 800 x 600; in a browser the page decides the frame, and the game laid itself out for the minimum. The minimum is now set only outside the browser. The Windows build is unchanged.
- Found in that run and fixed, web only: the mouse wheel. A page listener takes every wheel event (so that the page does not scroll and the list moves by the pixel) and the game used it for one thing, the activity list of the skill page. Over Chat or High Scores docked beside the skills the wheel therefore moved a skill page; on Settings, Queue, Pinned and every other screen it did nothing; with a panel open over a skill page it moved the list behind the panel. Now the wheel goes to the list under the pointer, by the pixel like the activity list, and anything that is not one of the game's own lists gets ordinary wheel notches (small trackpad steps add up to a notch). This also changes the web build that is live today, which has the same listener.
- High Scores docked beside the skills (horizontal layout), finding F2 of the leaderboard audit, fixed: the panel was drawn when opened and not again when the rows arrived from the server, so with nothing running it showed only the player; and the list was not read again after the player's score was published, so their row kept "Local score" and an estimated rank. Every such redraw was tied to the full-page High Scores screen. The redraw on arrival, the redraw and single re-read after an accepted upload, and the redraws after a name is saved now also apply while the panel is open. How scores are sent is unchanged, and the timed re-read every 30 seconds stays with the full page, as `check-leaderboard-cost-safety.ps1` requires. The panel also keeps its scroll position when it is built again (it is rebuilt on every completion while training, which threw the list back to the top). Seen in the browser run: the list fills in with nothing running, and after the upload the row changes from "~3, Local score" to "3".
- `scripts/build-desktop-working.ps1`, the builder for uncommitted work: it named `firebase-leaderboard-config.json` among the files to copy but took its list from git, which does not list an ignored file, so the web and Windows packages it made on October 11 had no high scores, chat or name claim. It now copies the file by path and stops if a finished pack does not contain it.
- The project's browser test for returning web players passes on the new build (`scripts/tests/web_save_upgrade.test.cjs`, run from a copy that differs only in starting Edge with a fixed profile and its updater off): a save written by the build that is live on itch (`builds/itch/idle-elite-itch-web-chat-fix-2026-10-10.zip`) loads in 0.7.0 with XP, materials, the built module, player id and name kept, the unchanged score is sent again, and a reload keeps everything. No request left this PC.
- Web package built from the working files: `H:/Codex/Projects/IdleElite/outputs/v0.7.0-2026-10-15/idle-elite-v0.7.0-itch-web.zip`, 58 MB, `index.html` at the root, single-threaded (`GODOT_THREADS_ENABLED = false`, so no SharedArrayBuffer setting is needed). Not uploaded. The Android release bundle was not built: it needs the upload keystore password and a read of the live Firebase rules, both Brian's. The seven static checks `build-android-release.ps1` runs before it asks for the password all pass on this tree.
- Still to do before either build reaches players, none of it mine to do: deploy the Firebase rules that allow portraits 20 to 22 (`scripts/deploy-firebase-leaderboard-rules.ps1 -ProjectId idle-elite`; the last saved copy of the live rules stops at 19, and with that limit a player on a new portrait has score, profile and chat writes refused); set the itch embed to a landscape size; decide the Halloween end date (`ends_at_unix` is 0, which never ends); accept the build on the phone.
- Found in the browser run and fixed, every export: the Giants arena had no giant. The browser console showed the game failing to open `assets/content/fight/enemies/giants/giants-states-source.png`, and the arena drew an empty diamond. On October 11, for 0.6.2, that sheet was added to the `exclude_filter` of all three export presets as an unreferenced image. It is referenced: the activity database names it as the Giants' art, as a bare `assets/...` path that the game turns into a `res://` path at run time, and `scripts/check-runtime-asset-paths.ps1` only looked for paths written as `res://`. The released 0.6.1 bundle still contains the sheet, so 0.7.0 would have been the first release without it, on Android as well as on the web; the preview installed on the phone at 16:25 has the fault. Fixed: the entry is out of the three exclude lists (nothing else in `export_presets.cfg` changed), the asset check now also reads the bare paths in the activity database and fails on the earlier state, and `docs/performance-1080p-texture-inventory.csv` has the one row back. Of 444 asset paths named in the activity database and the game scripts this was the only one excluded from an export. Seen in the rebuilt web package: the giant is there and the console is clean.

## Overlapping activities, locked-frame taps and requirement names, October 16

Brian's five notes of October 16. Implemented in the working tree and verified in the phone layout and the horizontal layout, headless and drawn to a real window. Not on the phone and not in the web package of October 15. Not committed. No save-key or save-format changes: the ids `grit` and `clues` are unchanged.

This replaces two statements above: a tap on a required item no longer goes to its source at once (October 15, "then goes to the best unlocked source as before"), and the names Grit and Clues are no longer shown.

- Activities drawn on top of one another (note 1). Reproduced and fixed, by cause:
  - After the list changes, rows slide to their new places. The slide read each row's position and height when it began, and wrote both back when it ended. Whatever opened in between was undone, and the row below stayed drawn over the card until the list was next laid out. Reproduced on Fishing: Practice Pool's stat panel open, two levels gained; 1.5 s later the list was rebuilt and the Net offer was left 455 px up, over the open panel. A row now slides as a distance from the place the list gives it, read again each time the list sorts, and only a collapsed or squeezed row has a height written at the end.
  - The first time an activity's stat panel opened, the panel was measured before its text had been laid out. Gather Fallen Branches went from 378 px to 2,366 px and Split Firewood to 3,101 px within about 0.12 s, stayed several screens tall for half a second and threw everything below down the list and back. The panel is now measured a frame later: the tallest moment is 910 and 983 px, the same as a second opening.
  - After "open the panel, close it, stop the activity" the card kept 435 px of empty room for a materials row that was hidden (812.6 px, now 378).
  - A list rebuilt after a level-up made an open card again without its panel's room for one frame, was then too short to keep its scroll position, and planned no room for an open panel on a card that was out of view, so everything on screen moved by the panel's height. The card now takes the room at once, from the height the panel last had; the plan includes it; and a card that is closing its materials row or panel stays mounted until it has closed.
  - A rebuilt list is shown at the top for a frame and scrolled back over the next two. A slide's start is now fixed on screen for its first two frames, then travels with the list.
- First round, measured with a play probe: each page played for 24 s with an activity started every 2 s, the stat panel tapped, two levels gained every 3 s and the list scrolled, every frame compared. Before: cards up to 4,798 px tall, and the Fishing overlap above lasting until the next layout. After: no card above 1,445 px (panel and materials row both open); Fighting, Thieving and Building show nothing in the phone layout; nothing overlaps for 0.4 s or more in either layout. Shorter overlaps were left, 12 readings on the phone layout. They are failures too, and the second round below removes them.
- Second round, the same day: the short overlaps, fixed by cause.
  - A card's slot had two owners. The stat panel's animation sized it from the card, the materials row's animation sized it from the card plus the row's room, and the one that ran last in a frame undid the other. For a few frames the card or the row was drawn past the slot, onto the next activity. One place sets a slot's height now (`_apply_activity_slot_height`): the card as tall as it is at that moment, plus the room open for its materials row.
  - A row sliding to its new place after a rebuild crossed the row next to it when that row's height differed before and after: a panel still opening when the rebuild landed, or the first start of an activity with a materials row. A sliding row now keeps the list's gap to the rows before and after it (`_layout_module_list_slides`). Only two rows that both slide from old places can pass one another, which is a swap.
  - A panel left open on a card that had scrolled out of view kept its room in the list after the panel was opened on another card. The room is released when the panel moves.
  - Three smaller causes, each of which moved rows for a frame or more: Fishing planned 368 px for an activity whose card is 378 px tall; a rebuilt list was scrolled back before its scroll range had grown and was cut short for a frame; a card shown again with its panel open animated open from a closed card.
  - The stat panel itself. It is a child of its card with its own full size, and it was drawn at that size while the card grew or shrank around it. Measured in a real window before the fix: while opening, up to 258 px past the card (28% opaque there) and 229 px into the next activity, in 5 drawn frames; while closing, up to 229 px past the card and 201 px into the next activity in 9 drawn frames, or with the activity running up to 232 px over its own materials row in 9 drawn frames. The panel now sits in a clip that reaches only as far as the card has opened (`_clip_activity_stat_panel`): 0 px past the card in every drawn frame, in both layouts. A check that compares rows with rows cannot see this; it was found in a picture taken in the middle of the animation.
  - A card kept from before with its panel open, shown again after the panel had been opened on another card, drew its old panel under a closed card while it faded. It now closes at once when it is shown.
- The finished code, measured with the play probe: every page played for 30 s with an activity started every 2 s, the stat panel tapped, two levels gained every 3 s and the list scrolled. The list is read as it is drawn, every frame; with a window, right after each real draw. Rows overlapping: 0 in every run. Headless: phone layout 18,293 frames, horizontal 18,296. Drawn to a real window: phone 18,016 frames, horizontal 15,350. With a temporary event made to appear (`washed-up-locked-crate`): 0 in 3,610 frames. The first version of the probe read the list at the start of a frame, where a slot can have a new height that the list has not yet laid out. Those readings are still reported, apart: 2 in the real-window phone run, neither of them drawn.
- The probe is not blind. Made to move a row 150 px itself, it reports 4 overlaps. Made to turn the panel's clip off, it reports the panel past its card and over the next row, 5 readings.
- Entrance motion is by design and is not counted as overlap. A newly revealed row starts 12 px low and rises to its place (`_play_detail_lazy_fade_in`, `DETAIL_LAZY_SLIDE_IN_OFFSET_Y`), fading in on the phone layout and under a paper cover in the horizontal layout (`reveal_cover.gd`). Every such reading was taken while its row was being revealed, was at most 10 px below the row's own slot, and was never nearer than 18 px to the next row; the gap between rows is 28 px. There were 4 on the phone layout and 18 to 21 on the horizontal layout, where the cover was 83 to 100% opaque over the row at its largest offset. A temporary event's row grows open from nothing with its slot clipping it: the card reaches up to 183 px past the slot and none of that is drawn.
- The Fighting icon in locked frames (note 2). The fist art sits 6.5 px right of the middle of its 256 px canvas, and each frame material's holder art is off centre by its own amount (timber 13, stone 0.5, iron -12, bronze 14, silver 0, gold -13.5, titanium 13.5, platinum 0, obsidian -13); only timber was allowed for. The icon was 2.7 to 14.5 px right of the frame's opening, or 9 px left, depending on the material. Now 0.0 to 0.7 px in all nine, measured on a composite of the real art at game size.
- Locked frames: one tap explains, a double tap goes (notes 3 and 5). A tap on a requirement shows what it is and where it comes from, with "Double tap to go there" when there is somewhere to go. A second tap within half a second goes to the best unlocked source of an item. A requirement that any activity of a skill fills goes nowhere on a double tap: before, it went to one activity of that skill, which read as the only source. The resource icon on an activity's art works the same way towards the locked activity it fills.
- Going to an activity now lands on it. The page opened on its latest activity first and the scroll to the target was lost when the list unmounted the card again; seen on the phone layout (Split Firewood) and in 7 of 7 runs in the horizontal layout (Wrestle Stuck Gate Latch for Rivets).
- "Grit" (note 4). The red fist seal that any Fighting activity fills was shown as "Grit", which is not a skill or an activity. It is now shown as "Fighting" ("Fighting / Any Fighting activity counts"). The purple key seal, "Clues", is shown as "Thieving" for the same reason; Brian named only Grit, so say if Clues should stay.
- The materials row appears once its room has opened (about 0.40 s after a start, was 0.28 s) and is gone before the room closes, so it is never over the activity below while it can be seen.
- Seen in a browser, in a package built from these files for the check only (`H:/Codex/Projects/IdleElite/outputs/v0.7.0-2026-10-16-check`, built before the second round and so without it; not delivered, not uploaded; the October 15 package is unchanged and does not contain this section's fixes). At 1920 x 1080 and at 540 x 960, with a level 9 save: the Outmuscle Angry Wheelbarrow frame shows the Fighting seal in the middle of its holder; one tap on it shows "Fighting / Any Fighting activity counts" and nothing moves; a double tap on it leaves the page where it is. At 1920 x 1080 one tap on Webs in the Trick or Treat frame shows "Webs / From Trim Overconfident Shrub / Double tap to go there", and a double tap on Cloth strips scrolls the Fighting page to Wrap Hands. No console errors. Not seen there: the stone frame is the only material looked at, and a stat panel did not open, because on that save a tap on a stat starts the activity. One was opened later in a real window, below.
- Checks on the finished code: tap rules, 27 checks, pass in both layouts; the probe for a row shifting near the bottom of a page passes; `scripts/test-module-list-transitions.ps1` (`module-list-transitions-ok`) and `scripts/test-buildable-modules.ps1` (`buildable-modules-ok`) pass.
- A stat panel opening, seen in a real window in both layouts: a 405 x 720 window drawing the 1080 x 1920 phone page, and the horizontal layout at 1920 x 1080. A press and hold on the XP stat of Gather Fallen Branches opens the panel. The card goes from 378 to 861 px (910 at the top of its bounce), nothing of it is drawn over the next row in any drawn frame (the next row is 28 px below it in each picture), and the panel stays inside the card while it opens, while it closes with the activity idle and with it running, while the materials row opens under it, and through two levels and the rebuild that follows (the open card keeps 1,296 px). Pictures were taken at about 0, 50, 110, 170 and 260 ms into each opening and closing.
- `scripts/tests/unlock_layout_stability.gd` (also with `IDLE_ELITE_TALL_BARRIER_TEST=1`), `project_resources.gd` and `full_width_barriers.gd`, run drawn to a real window on the finished code: `UNLOCK_LAYOUT_STABILITY failures=[]` in both variants (at 1920 x 1080 and at 1080 x 1920: 0 frames with the slot lost or transparent, largest jump 0.0 px, 0 neighbour changes, 13 fade frames), `PROJECT_RESOURCES failures=[]`, `FULL_WIDTH_BARRIERS failures=[]`. Each ran through `run-godot-safe.ps1 --visible-game` with the Dummy audio driver, its own user data folder, and save writes and online requests off; the real save was not touched.
- Changed in those tests: they double tap a requirement where they tapped once and expected to arrive at its source (`double_click` in `first_session_input.gd`); `project_resources.gd` and `full_width_barriers.gd` put their window at the corner of the monitor it is on, where they put it at the corner of the whole desktop; the tall variant fills the Fighting seal to four short of its target, where it wrote 46 for a target that was 50 and has been 150 since October 15, which could never complete.
- A limit of those three tests: they need their window at exactly 1920 x 1080 and at 1080 x 1920, because they compare each picture with the window's size, so they cannot run in a small window. On a 2560 x 1440 monitor the tall window reaches 480 to 599 px below the monitor's bottom edge and still reports 1080 x 1920. Started without a window they wait for a frame that is never drawn until their own time limit and still return exit code 0, so an exit code alone says nothing about them: read the summary line.
- The pictures those tests write to `.codex-tmp/desktop-responsive` replaced 48 of the 166 that were there. The 166 were put back from a copy and match the hashes taken before the first run.

## Seals on activity cards, Wisdom icons and the picture of a closing card, October 17

Implemented in the working tree. In the review package named below and, since October 17 02:32, on the phone as the preview package (last entry of this section). Not committed. No save-key or save-format changes.

This replaces two statements above: the seal that any activity of a skill fills is no longer marked on that skill's activities (October 15, "A tap on the resource icon of an activity ... 'Clues 4 / 10 / for Pick Friendly Lock'" now applies to an activity's own item only), and a Wisdom source does not always show its book.

- Brian, October 17: the red Fighting icon should not appear on every Fighting activity, nor the Thieving one; what counts for every activity of a skill should not be listed on each. No activity's art is marked any more with a resource that every activity of its skill gives (the Fighting and Thieving seals). The rule goes by the resource, because the data lists the seal in two ways: as the skill's resource (`skill_unlock_drop`) and, on 17 Thieving and 16 Fighting activities, as the activity's own item. An activity's own item that is not such a seal keeps its badge. The seal still fills from every success, as before. One thing went with the badge: the seal that flew from it to the locked frame on a success. Checked in both layouts at level 9: none of the 8 unlocked Thieving and 7 unlocked Fighting activities shows its skill's seal, and a success of each still fills the requirement.
- Brian, October 17: Wisdom keeps its own bar and way of working, but its icon should go when it no longer applies, once the player has unlocked every activity that asks for Wisdom. Wisdom is kept per skill, so the rule is per skill (`WisdomState.applicable`): while one of a skill's Wisdom activities is still locked, the book shows on that skill's Wisdom sources and rises with "+1" on a success; when the last is unlocked, neither is shown. Wisdom is still counted. Say if the rule should be for the whole game instead of per skill. Checked in both layouts: the book is on Study Blueprint while a Building Wisdom activity is locked and with one of the two unlocked, goes when both are unlocked (on the card already on screen and on one made afterwards), no book rises from a success then, Thieving's is unaffected, and with every Wisdom activity unlocked no source shows it.
- The picture of a card whose stat panel closes. The picture was given its closed layout on the first frame of closing, when the card was still open, so it filled the whole open card: it jumped down, the rows at its top and bottom edges were smeared above and below it, and it shrank back with the card. Measured in a real window: 342 px tall on a closed card, 360 px on an open one, 789 px on the first frame of closing. It now keeps the open layout until the card has closed: 360 px in every drawn frame of the close, then 342 px. The line between the picture and the panel now stays for as long as any of the panel shows.
- Left as it is: the picture is cut 9 px differently on an open card than on a closed one (its box is 18 px taller), so it shifts by 9 px in the first frame of opening and, now, in the last frame of closing.
- Stat panels other than XP, in a real window on the phone layout: stamina, time and success panels opened, changed from one to another and closed on seven kinds of activity (a plain one, one with medal bonuses listed, a rest activity, a Wisdom source, an activity behind a Wisdom requirement, a Fighting activity, Fishing's Practice Pool). In every drawn frame the panel stayed inside its card and nothing was drawn over the next row; 46 to 54 checks per run.
- Checked on this code in a quick round on October 17: the tap rules (29 checks) and the Wisdom icon rule (16 to 17 checks) pass in both layouts; the play probe finds 0 rows overlapping in either layout (8,260 and 6,445 frames, 15 s a page, headless); `scripts/test-save-hardening.ps1` (`save-hardening-test: PASS`, `v1-save-update-integration: PASS`) and `scripts/test-stability-regressions.ps1` pass.
- The candy system: `scripts/tests/halloween_event.gd` passes drawn to a real window (`HALLOWEEN_TEST failures=[]`). It covers the doorstep and its three requirements, Trick or Treat, one candy for a success and none once the event is switched off, the candy button clicked through the real input, one piece taking stamina 10 to 15 over the maximum and a second refused while over, save and load, candy before fish, candy earned live and from time away, and a save that outlives the event. The test now puts its window at the corner of the monitor it is on, as the other two do. The event has no end date (`ends_at_unix` is 0).
- A returning player, in a real window in both layouts with saves in an isolated folder: a save from before the unlock projects keeps every activity it had open (41 of 41), every project at or below its level counts as done (8 of 8) and none above, nothing is lost, and a second start right after the first counts no time twice. The Welcome Back panel is shown after two hours away, is inside the screen and closes on a click on Continue.
- Review package, not uploaded: `H:/Codex/Projects/IdleElite/outputs/v0.7.0-2026-10-17-review/idle-elite-v0.7.0-itch-web.zip` (60,992,608 bytes, SHA-256 `D60E96612B7E05198D3E63A665406393216A1AD75A3B02F03C0B45BFDA6BD3F0`), built from the working files and matching them (550 source files compared by hash). In a browser at 1920 x 1080 and at 540 x 960 it starts, loads a returning save and shows no console errors, with every request answered on this PC; the project's returning-web-player test passes on it (`web-save-upgrade-ok`). The packages of October 15 and 16 are unchanged.
- Stat panels in the horizontal layout, in a real window with the real mouse kept out of it (the first horizontal runs were disturbed by the real pointer resting over the window: in that layout a pointer over a column takes the focus, and any movement during a press drags the columns and ends the hold). Two of the seven kinds were run again that way: the plain activity passes 54 of 54 checks; the Fighting activity passes 53 of 54. The one failure: while the panel closed with the activity running, the picture was measured 4.2 px from its place on the card, against 3 px allowed for the card's own press movement. Not looked into further; the same run on the phone layout passes 54 of 54.
- Not run on this code: the full play-probe and unlock-frame rounds of October 16; the other five kinds of stat panel in the horizontal layout; anything watched on a phone (the build is installed, see the last entry of this section).
- Measured and left for Brian: time away runs at full speed and gives 30% of the XP, rounded for each completion and never less than 1. An activity worth 1 XP therefore earns all of it while away (1,226 XP for 1,226 successes in two hours of Gather Fallen Branches) and one worth 4 XP a quarter. The Welcome Back panel calls this "30% speed".
- Phone preview, October 17 02:32, asked for by Brian ("build a version for mobile and upload it to my phone right now"). `scripts/install-android-phone-debug.ps1` built the working files as `com.idleelite.game.preview` 0.7.0 (42) and installed it over the preview of October 15 on his SM-S928U. `com.idleelite.game` (0.6.1, 40) was not touched. Bundle: `builds/android/idle-elite-preview-debug.aab`, 168,789,247 bytes, SHA-256 `BA98CE5A50456B168BBA3AB096641A470E74B0111464E0D6B2B42E206613923D`. It is built from the same files as the review package: that package matched the working files before the build (02:14) and after it (02:34), and `git status` was the same before and after. `export_presets.cfg` and `android/build/build.gradle`, which the build rewrites for the preview name, are byte-identical to before. The phone was locked, so the game was started behind the lock screen and Android stopped it within a second: the engine started (4.7.1, OpenGL ES 3.2, `gl_compatibility`, Adreno 750), its log holds no error and no crash, and the save had not been read or written when checked (all six save files identical to the copies taken before the install; last saved October 16 12:19 with Fishing's Rapids running, so the first opening applies the time away since then, up to the cap). Brian unlocked the phone at 02:35: the game's main loop started 2.7 s later, and through 02:37 its log holds no script error, engine error or crash. The save loaded from the main file with no migration needed, 12 saves were asked for and 12 written, each revision higher than the last (2440 to 2451), and Fishing went from level 20 to 24 with the time away and the play since. The screen itself was not looked at from this PC: tearing, the overlap fixes and the icons on the phone are still to be judged there. The preview files of October 15 are kept in `H:/Codex/Scratch/idle-elite-onigiri-audit/tmp/phone-preview-before-20261017`.

## What a Fishing tile gives, October 17

Implemented in the working tree after the phone build of 02:32, so it is not on the phone. Not committed. No save-key or save-format changes.

Brian, October 17, after playing the phone build: "Audit the fishing section for items that need to be produced, need to be shown in the top right corner that they produce them. Maybe wisdom, I'm not sure. But I just noticed that there's locked activities in the fishing page, and then you jump, and then like it's invisible what's being produced."

What the audit found:

- Fishing has 29 activities. 23 are tiles, two to an area (Shallows and Rocks in Beach, and so on), drawn by `scripts/fishing/ui_surface.gd`. Six are ordinary activity cards: Practice Pool, Fight Rat King, Anchor Tiny Boat Dock, Fight Armored Catfish, Fight A Shark and Loot A Pirate Ship.
- 25 of them give Lures (21 tiles and four of the cards), Loot A Pirate Ship gives Coins, River Bend gives Wisdom, and Shallows and Practice Pool give nothing. Lures are asked for by six Fishing locks (Piling Line 12, Drain Gate 48, Ice Hole 85, Open Water 150, Chum Line 240, Deep Trench 350) and by Building's Construct Fishing Pier (25). Wisdom is asked for by Chum Line (120) and Deep Trench (300).
- A tile had no mark of any kind for what it gives. Looked at with the game set to Fishing level 12, 23, 35, 53, 71 and 89, each with that level's Fishing lock in progress: of the unlocked tiles that gave something a lock still needed, 0 of 59 were marked; the ordinary cards were, 13 of 13, in the top right corner.
- The jump. A double tap on a requirement goes to the activity that gives it fastest with the fishing tool in hand. For Lures that is usually a tile (with bare hands Rocks at levels 12 and 23 and Drain Gate at 35; with the net Dock Edge at 12, with the rod Rapids at 23, Rowboat at 53, Storm Ripple at 71 and Storm Line at 89), and for Wisdom it is always the River Bend tile. The list landed on the right area with the tile fully on screen, and nothing there said which tile gives the item. Jumps that land on an ordinary card (Plans in Building, Resin in Woodcutting, Lures from Thieving's Steal Fisherman's Lucky Hook) were marked already.
- The message that offers the jump ("Lures / From Rocks / Double tap to go there") stayed where it was for the rest of its 3.4 seconds after the jump, which put it over the tile the jump had landed on. This was so on every page, not only Fishing.

What changed:

- An unlocked tile carries the same mark as an activity card, on its top right corner: its item while a revealed lock still needs it, and on River Bend the Wisdom book while a Fishing activity that asks for Wisdom is still locked (the rule the book follows on cards). The mark hangs 30 px above the tile and 12 px to its right, not 30, because the next tile is 14 px away. A locked tile has no mark; it gets one when it is unlocked, also while the page is open.
- A tap on a tile's mark says what it is filling ("Lures 0 / 48 / for Drain Gate / Double tap to go there", "Wisdom 0 / 120 / for Chum Line / Double tap to go there") and a second tap goes to that locked frame, as on cards. A tap on the rest of the tile starts the activity as before.
- The message that offered a jump is taken down when the jump starts (`ProjectRuntime._open_page_for_jump`, all pages).
- A Fishing area folded to its title hides its tiles' marks: they hang above the tiles, into the strip that stays. Before this was added, 72% of a mark was drawn in the folded strip.
- New file `scripts/ui/wisdom_source_badge.gd`. `scripts/ui/unlock_resource_badge.gd` gained an overhang setting and a `_show_needed` step so the book can share it. `ProjectRuntime.open_project` is the second half of `open_target`, split off for the book.

Checked on this code:

- The same audit, without a window, on the final code (after the padlock fix below): 88 of 88 checks in the phone layout and 88 of 88 in the horizontal layout. Before that fix, with the fishing tools of each level owned and the rod in hand: 91 of 91 in the phone layout. In each, 59 of 59 tiles and 13 of 13 cards are marked, and every jump lands on a place that shows the mark, top right, with the message gone.
- In a real window, before the padlock fix: 28 of 28 checks in the phone layout (levels 23 and 35) and 44 of 44 in the horizontal layout (levels 23, 35 and 71). Pictures of each jump, of a tile running with its mark, of a folded area and of a tile just unlocked are in the session scratchpad under `visual-check/fishing-marks/`.
- Taps made as a finger makes them, in both layouts: one tap on a mark shows its message, starts nothing and moves nothing; a tap on the part of the mark above the tile's edge does the same; a double tap goes to the locked frame, with all of it on screen and no message left; a tap on the tile itself still starts its activity, and the mark stays while it runs.
- Ice Hole finished and its padlock opened on the open page at level 35, with Building's Fishing Pier still needing Lures: no mark while locked, its mark at once when opened.
- Earlier checks run again, before the padlock fix: the tap rules (29 of 29 in each layout) and the Wisdom icons on cards (17 of 17 in each layout); the play probe's event run finds 0 rows overlapping, its two self-tests fail as they must (4 and 5 findings), and the bottom-bounce probe passes. On the final code the play probe finds 0 rows overlapping as drawn in both layouts (15,584 frames in the phone layout, 8,524 in the horizontal one; see the reading below).
- The three unlock-frame tests, drawn to a real window, which use the jump this change touched: `UNLOCK_LAYOUT_STABILITY failures=[]` (both variants, again on the final code), `PROJECT_RESOURCES failures=[]` and `FULL_WIDTH_BARRIERS failures=[]` (before the padlock fix). Their picture folder was put back afterwards (166 of 166 files as before).

One reading of the play probe on the Fishing page, phone layout, that is not from this change:

- When Fishing reaches level 24 with the list at its bottom, Fight Rat King's new row and the Sewers area above it have their places overlapping for 2 to 6 frames (35 to 94 ms, by 86 to 167 px) near the end of the list's slide. The new row is still fully transparent then, and fades in at its own place afterwards: in the four runs made after the probe began to keep that figure it drew nothing in every one of those frames, and in the first run it drew nothing in the worst frame. Nothing is drawn over anything. It happened in each of five full runs, four with the tile marks and one with them switched off for the comparison, so the marks are not its cause; the full runs of October 16 did not show it.
- The probe counted the first of these as rows overlapping, because it compared places only. It now also keeps, for a reading about two rows, the opacity of the fainter row over all its frames, and lists a reading where that never reaches 0.08 apart ("places overlapping while one of the two rows drew nothing"). The self-test that moves a visible row over another still fails.
- Why the places cross: the slide lets two rows pass each other when both come from an old place and the upper one used to be below the lower one (`_module_list_rows_swapped`). Here the two old places were recorded 3 px apart, above the screen, which counts as swapped. Not changed. Asking for more than the list's gap between the two old places would end it; that needs the full overlap rounds again.

A padlock left on an unlocked tile, found while checking the web build:

- With the project's returning-player browser save set to level 12, the Rocks tile kept its padlock ("4") although the save counts Rocks as unlocked. A click on the padlock did nothing and the tile could not be started. The review package built before this change does the same.
- Cause: a tile's padlock is taken off by the tap that opens it and by nothing else. An activity can be unlocked with no tap: automatic padlocks open it while its page is out of sight, and a save is brought up to date when it is loaded. The page is made again only when the set of tiles on it changes, and whether a tile is locked is not part of that. The horizontal layout keeps all five pages made with three in view, so a tile unlocked on a page out of sight came back into view with a padlock that nothing could open.
- Shown in the game itself, horizontal layout: Rocks locked, then unlocked the way those paths do it. Eight seconds later the padlock was still there, the list's own check said the page was up to date, a tap started nothing, and there was no mark (3 checks failed). In the phone layout the same steps ended with the page made again within two seconds.
- Fix (`_clear_fishing_method_padlock_left_behind` in `scripts/fishing/ui_surface.gd`): when a tile's activity is unlocked and its padlock is still there 0.6 seconds later, outside an opening ceremony, the padlock is taken off and the tile is made usable. The same steps then pass in both layouts (17 of 17 checks each): a real tap on a padlock still opens it with its ceremony, and a tile unlocked with no tap loses its padlock within two seconds, starts on a tap where the padlock was, and shows its mark.

Packages and the browser:

- Review package with both changes, not uploaded: `H:/Codex/Projects/IdleElite/outputs/v0.7.0-2026-10-17-review-3/idle-elite-v0.7.0-itch-web.zip` (60,995,057 bytes, SHA-256 `10689B622B590326348CFF617E778EA5DAB322B3078DFCA34B4835761D705A7A`), built from the working files and matching them (551 source files compared by hash). `v0.7.0-2026-10-17-review-2` (04:27) has the marks without the padlock fix, and `v0.7.0-2026-10-17-review` (01:21) has neither. Every earlier package is unchanged.
- That package in a browser at 1920 x 1080, with the project's returning-player save set to level 12, every request answered on this PC and no console errors: Rocks has no padlock and carries the Lures mark, a click on the mark shows "Lures 0 / 12 / for Piling Line / Double tap to go there", and a click on the tile starts Rocks. On `review-2` a double click on Dock Edge's mark went to the Piling Line frame and took the message down. The same save on the package of 01:21 shows Dock Edge with no mark and Rocks behind the padlock that does not open.
- Not on the phone: the preview installed at 02:32 has neither change. The phone layout was checked on this PC only.

Left as it is, for Brian to judge:

- While a lock needs Lures, 21 of the 23 tiles carry the Lures mark, as nearly every Building card carries Plans. That is the same sight as the Fighting and Thieving seals had before they were taken off the cards. Lures differ in that a tap on the requirement names one activity and a double tap goes there; the seals name none.
- The Wisdom book sits top right on the tile, with the item marks. On an ordinary card it sits bottom right.
- Ordinary cards show their mark while still locked; tiles do not.
- The tops of the tiles show in a folded area's strip, as before.
- In the web version the small hover label of a requirement ("Lures") stays by the pointer after a double click has jumped, until the mouse moves.

## Playtest list, October 17 (afternoon)

Nine notes from Brian's play of the 02:32 phone build, pasted as one list. Implemented in the working tree; not committed, not built into a package, not on the phone. Every change was looked at in a real window in the light and the dark theme, in the phone layout and the horizontal layout.

1. Hub upgrade menu, "some text renders in a weird black color". Cause: since October 12 every hub label carries a 12 to 14 px stroke, meant for the white text on the Mission Board. The building bubble's title, description and cost are theme ink on a paper panel, and the stroke is black, so they were drawn as a heavy black smear (light theme) or with a black halo (dark theme). `HubSurface._label` now adds the stroke only to text that is not theme ink or muted ink. The note behind the Mission badge on an activity card had the same fault and has the same fix. The horizontal layout's left inspector is not changed: it restyles these labels itself (white with a stroke, on its pale panel).
2. Leaderboard in Dark Mode. Only the rows turned dark; the sky, the paper sheet, the dropdown, the player's card and their text stayed light. All of them now have a dark counterpart (`LeaderboardPresentation._page_color`), and the title and status text take theme ink.
3. Gain animations. Looked at every float in the game. All rose except one: the copy of an unlock item's icon (Lures, Plans, Resin and the rest), which slid to the locked frame when that was on screen and otherwise 180 px down the page. It now lifts off its badge, rises 115 px and fades, the same motion as the Wisdom book (`RewardFeedbackSurface._float_reward_icon`). Not changed, because they travel to a place and are not floats: a material flying into its box under the activity, fish and tools flying to the wallet, a stolen trophy flying to the Hub button.
4. Wisdom gain. No number. One book rises for each point earned; with more than one they leave the same place 0.14 s apart and the earlier one rises 64 px further, so two points show as two books one above the other. At most six books are drawn for one success.
5. The rest activity that gives Wisdom (Catch Breath Between Rounds, the only one). Its progress bar was drawn 48 px up the picture and the card's own curved foot showed under it as a second curved bar. Cause: on an activity with a Wisdom row the bar is pinned under the picture, measured from the height of a plain card; a rest activity's face is 48 px taller. It is now laid out as every other rest activity: the curved bar is the foot of the card, also while it runs, while its Wisdom note is open (the note opens above the bar) and while a stat panel is open. `ActivityCardStyles.wisdom_opens_above_bar` names the case. No other Wisdom activity is a rest activity, and for those the layout code computes the same values as before.
6. Candy. Trick or Treat has the same box under it as any activity that gives an item: the name, the picture and how much candy the player has, and each success flies one piece into it. Candy is still counted by the Halloween event (`halloween_2026` in the save, unchanged); the box reads that count.
7. High scores text. The stroke around the names, ranks and scores of the phone layout's rows goes from 5 to 12 (`TEXT_OUTLINE_WIDTH`). The horizontal layout's High Scores panel has plain ink and no stroke, as before.
8. The "-" button that a tap on an activity's top right corner brings up is taken down by the next press anywhere else (`SkillDetailSurface._dismiss_module_collapse_badges_on_outside_press`, called first in `Main._input`). A second press on the corner still folds the activity.
9. Fight Rat King with the drag net or the boat. Its time panel was titled "Fill" and said "Fish enter the net in batches, then the full net hauls at 10+ fish", for the boat as well, which collects at 200. It is now titled Time Bonuses like every other time panel and says, with the numbers the game plays by: "Drag net: one try takes 3.6s here. Each catch puts 1 to 6 fish in the net. At 10 fish you pull the net in and collect them." (boat: 6s, 1 to 30 fish, 200). The success panel gains one line with the net, "Drag net: 25% of the usual chance.", which is why it reads 18.8% against a base of 75.3%. The time chip is titled TIME, not FILL. The same panels serve the other Fishing activities that are cards.

Also changed, found while looking at Dark Mode: the level-up and achievement banner forced the light theme's ink onto its title and reward line, which was dark text on the dark banner. It takes theme ink now (`AchievementToastSurface._force_toast_ink`).

Tests changed to match, both in `scripts/tests/wisdom_feedback.gd`:

- It asked for a "+N" label on the Wisdom float; it now asks for one book per point and no label.
- Its rewards-only part unlocked every activity and then expected a Wisdom float. Since the icon rule of October 16 a skill with no locked activity left that asks for Wisdom shows no Wisdom, so that part could not pass whatever the float looked like ("Completion shows both Wisdom and XP" failed for all three skills). It now leaves the activities that ask for Wisdom locked before each case, as the test's full path already did. No assertion was changed for this.

Checked on this code, with the game drawn to a real window (Godot 4.7.1, isolated user data, no online requests, sound off):

- A probe that sets every skill to level 30, opens each screen named above, and for each of the nine notes both measures and takes pictures (`playtest_shots.gd` in the session scratchpad): 65 of 65 checks in each of four runs, phone layout light and dark and horizontal layout light and dark, with no script error in any engine log. Before the changes the same pictures show the smeared hub text, the half-dark leaderboard, the item icon sliding down (from y 733 to y 913), the "+1" and "+2" on the Wisdom book, the two curved bars, no Candy box, the "-" button still up after taps elsewhere, and the "Fill" panel. One edit came after these four runs: a literal 160.0 in `skill_detail_surface.gd` became the constant of the same value.
- The rest activity: its bar is at the foot of the card in all five states (closed, running, note open, note closed again, stat panel open), the same distance from the foot as Wrap Hands' bar, and the note ends above the bar.
- Wisdom: one book for Catch Breath and Chameleon Camouflage (+1), two for Prune Orchard Row (+2), none with a number; every float followed went up.
- Items: Woodcutting, Building, Fighting and a Fishing tile each lift one icon on a success, and nothing moves down.
- Candy: the box reads "Candy" and 7, and 8 one success later.
- The "-" button: up after one tap on the corner; taken down by a tap on the page header, on the middle of the same activity and on the list below it; a second tap on the corner still folds the activity. On a Fishing area the button was brought up by a mouse click on its corner and taken down the same three ways.
- Fight Rat King: with the net, the boat and bare hands no panel says "fill"; the lines are the ones quoted above.
- The note behind the Mission badge, phone layout, light and dark: theme ink and no stroke (4 of 4 checks in each).
- The project's ten static checks pass (`check-activity-ui-boundary-contracts`, `check-ui-boundary-contracts`, `check-1080p-migration-contracts`, `check-leaderboard-cost-safety`, `check-test-harness-contracts`, `check-performance-resource-contracts`, `check-crash-audit-contracts`, `check-generated-file-hygiene`, `check-runtime-asset-paths`, `check-activity-database-contracts`).
- The project's own tests: `test-module-list-transitions.ps1` passes (`module-list-transitions-ok`; it includes folding an activity with two taps on its corner) and `test-ham-feedback.ps1` passes (`ham-feedback failures=[]`). In a real window: `halloween_event.gd` (`HALLOWEEN_TEST failures=[]`), `project_resources.gd` (`PROJECT_RESOURCES failures=[]`) and the rewards part of `wisdom_feedback.gd` (`wisdom-feedback failures=[]`: a real completion in Building, Thieving and Woodcutting, one book for one point and two for two, no label on a book, the book to the right of the XP text, inside the screen, rising in its lane and gone after its fade). The pictures these tests write into the worktree's `.codex-tmp` folders were put back as they were (166 of 166 and 40 of 40 by hash); the new ones are kept in the session scratchpad.
- Earlier checks run again without a window: the tap rules, 29 of 29 in each layout; the Wisdom icons on cards, 17 of 17 in the phone layout and, in the horizontal layout, 17 of 17 in two runs on a quiet machine (two earlier runs made while other jobs loaded the PC found one and two cards not yet mounted when the last step looked for them, skipped those checks and passed the other 16 and 15; a run made to time it shows each card registered in the same frame as the scroll to it, in both layouts); the play probe finds 0 rows overlapping as drawn in the phone layout (17,900 frames; the two places-crossing readings on the Fishing page described above, both while one row drew nothing), in the horizontal layout (14,753 frames) and in its event run (3,528 frames); its self-test that moves a row fails as it must (4 findings) and so does its self-test that unclips the stat panel (4 rows overlapping as drawn); the bottom-bounce probe passes.

Not passing, and not from this work:

- `test-wisdom-feedback.ps1` as the project runs it (the whole test, without a window) does not finish within its 180 seconds. The logs of October 14 show the same (21:11 and 23:54, and that night's two baseline runs).
- Run in a real window, the same test's Wisdom-only part reports "Gate allows threshold" false for the two Fishing areas that ask for Wisdom (`chum-line`, `deep-trench`) and then stops with a script error where it reads the card `build:frame-a-treehouse-platform`, which is not on the Building page in the state the test sets up. Nothing after that line runs, so the test sits until its time limit. It stops before any check on today's changes and wrote no picture. Read, not proved by a run: the test's setup never finishes a project (Repair Small Shack and the like), `_can_unlock_action` asks for the project, and the list hides locked activities after the first one that blocks progress, so the card the test wants is never built. Repairing that part of the test is a job of its own and was not started.

The engine went missing during these checks:

- At 13:13:22 the folder that holds the Godot 4.7.1 executable named in `run-godot-safe.ps1` (`C:/Users/bknep/Documents/New project 4`) was renamed to `New project 4.moved-to-E`, and its `.codex-godot-r471` folder is no longer in it. It is not elsewhere on C:, on E: or H:, or in the recycle bin. This work did not touch it. From then on `run-godot-safe.ps1` stops with "Godot was not found", for every session and for the build scripts.
- `run-godot-safe.ps1` is not changed. The checks made after 13:13 gave it an official copy of the same build through its `GODOT_BIN` setting: `H:/Codex/Scratch/idle-elite-onigiri-audit/godot-4.7.1-official/bin/godot.exe`, from the 4.7.1-stable release on GitHub, SHA-512 equal to the release's list, signed, and reporting the same version line as before (`v4.7.1.stable.official.a13da4feb`). The worktree's file list was the same before and after the first run with it.
- Made before 13:13 with the project's own engine: the four runs of the probe and the checks listed under them down to Fight Rat King, and of the checks without a window the tap rules, the phone layout's Wisdom icons, the three play probe runs and the self-test that moves a row. Made after 13:13 with the copy: the two horizontal Wisdom icon runs that read 17 of 17, the self-test that unclips the panel, the bottom-bounce probe, the Mission badge note and the project's own tests. The ten static checks need no engine and were run again last, on the final files. Building a package needs the engine and its export templates back where the build scripts look for them; that was not tried.

## Audit continuation, October 17 (later afternoon)

Work sent back after the playtest list: the Wisdom fixture that did not finish, four overlapping rows in a probe run, and a finger tap that did not bring up a collapse button. In the working tree; not committed. This work built and installed nothing; the working tree was built and put on the phone by the release-submission session at 19:36 that evening, with these changes in it. Since 14:22 heavy jobs on this PC are given out one at a time, so each result below is one Godot run under its own grant; what still waits for a run is listed at the end.

Changed:

- `scripts/tests/wisdom_feedback.gd`, setup only. The fixture marked every activity unlocked and never finished an unlock project. An activity behind a project stays locked whatever its level and its Wisdom (`ProjectRuntime.complete` is the first term of `_can_unlock_action` and of `_is_action_unlocked`). Two things followed. Chum Line and Deep Trench are the only activities with both a Wisdom requirement and a project, so "Gate allows threshold" failed for exactly those two. On the Building page Repair Small Shack (level 6, 8 Plans) stayed locked, and the list shows no locked activity after the first one that blocks progress, so the card of Frame A Treehouse Platform was never made and the fixture stopped with a script error at the line that reads it; nothing after that line ran, which is why the fixture sat until its time limit in every run since October 14. The setup now completes every project, as `unlock_layout_stability.gd`, `build_panel_refresh.gd` and `lag_regressions.gd` do. No assertion was changed. Run without a window at 16:17: the whole fixture passes (`wisdom-feedback failures=[]`, exit 0, 106 s, no error in the engine log). The rewards-only part's pass in a real window at 13:56 is a separate result and stands as it was.
- `scripts/ui/skill_detail_surface.gd`: a finger on the pin or collapse corner of a module. A touch, and any movement of it, reaches a corner through the corner's own `gui_input` with its position counted from the corner; the press it belongs to is kept in screen positions. The release was therefore compared a screen away from its press (1,066 px in the run that showed it), counted as a drag, and dropped. A mouse release carries a screen position of its own, so a click worked. On the ordinary pages the game takes corner presses in `_input`, before the corner sees them, so nothing showed there; on the Fishing page presses inside the list are left to the controls, the pin corner has a route of its own in `_input`, and the collapse corner has none. A finger could not bring the "-" button up on a Fishing area. The event is now put in screen positions before it is compared (`_module_action_zone_screen_event`). Shown first on the code without the change, with input made by the engine itself (16:40, no window): for a finger the engine sends its emulated mouse press and then the touch; both reach the corner of the Beach area, the touch at (24, 24); after the release the "-" button is not up. With a mouse it is up after one click and a second click folds the area. A finger on the pin corner of the same area pins it. On a Woodcutting activity all four kinds of input bring the button up and fold. With the change, the same probe with the same checks (16:58, no window): `diag-finger-collapse PASS (failures=0)`; a finger brings the "-" button up on the Beach area and a second tap folds it; the same events arrive as before (the touch still at (24, 24) at the corner), only the comparison changed; mouse, pin corner and the ordinary card behave as before. The tap rules (a single tap explains, a double tap goes to the activity) had not been run again after this input change when this was written at 17:45; that run waits for a free slot.

Not a fault in the game:

- The four rows "overlapping as drawn" in the probe run named play2-unclip. That run is the probe's self-test: the probe itself turns off the clip that keeps a stat panel inside its card (`IDLE_ELITE_AUDIT_UNCLIP_PANEL=1`) and must then report the panel drawn past its card, or it could not see one. All four findings are the stat panel of Gather Fallen Branches and of Split Firewood drawn past the card while it opened or closed. The game makes that clip switched on and nothing switches it off. A run with the self-test's own settings and no switch (phone layout, Woodcutting, 30 s, 16:31): 0 rows overlapping as drawn, of any length; the stat panel of Gather Fallen Branches reaches up to 211 px past its slot for 9 frames while its card moves and none of it is drawn, which is the clip at work.

Read and left alone:

- The offline result for the shrine reports the total level before the absence as 0, which would show "Total Level Lv 0 -> N" in the Welcome Back panel. The activity database holds no shrine, so that branch cannot run today.
- A card's picture shifts 9 px in the first frame of opening a stat panel and the last frame of closing it. Its box is 18 px taller on an open card and the picture is centred in its box. Taking the shift out would move the picture on every closed card.
- The Welcome Back panel has a row "Activities Unlocked" that nothing in the game fills; only the layout test does.

Checked without the engine on the tree as it stood at 17:43: `check-activity-ui-boundary-contracts`, `check-ui-boundary-contracts`, `check-1080p-migration-contracts`, `check-test-harness-contracts`, `check-generated-file-hygiene` pass.

Still waiting for a run when this was written: the tap rules after the input change; the returning-player and time-away audit; the stat panels other than XP in the horizontal layout, and again in the phone layout because the shared card layout code changed today.

## Wisdom on the Fishing page, October 17 (evening)

Brian, about 17:50: "fix wisdom bug in fishing page". He did not say what he saw. His phone had the build of 02:32, in which the Fishing page shows nothing about Wisdom at all: the book on River Bend's tile was added later that morning (see "What a Fishing tile gives"), and a catch there raised no Wisdom book in any build. In the working tree; not committed. This work built and installed nothing; a preview build of the working tree made by the release-submission session went onto the phone at 19:36 that evening and a release bundle (code 42) followed at 19:38, and both hold this change.

- Found by reading the Fishing code, then shown in a run: a Fishing catch is finished by `FishingState.complete_action_attempt` (`scripts/fishing/state.gd`). It gives the Wisdom of a Wisdom source inside `HubRuntime.record_mission_action_completion` and then called `RewardFeedbackSurface._play_action_feedback` without the Wisdom it had given, so the book that rises for each point of Wisdom in the other four skills never rose on the Fishing page. River Bend (Fishing 14) is Fishing's one Wisdom source. The Wisdom itself was counted correctly, live and away.
- Shown on the game as it stood (18:27, real window, phone layout, light and dark theme): River Bend played with bare hands gives +1 Fishing Wisdom and shows "+5 XP" over its tile, and no book rises ("one Wisdom book rises for each point earned: 0 for 1", both themes); with the net, three catches into the net and one haul each give +1 Wisdom and raise no book. 14 checks passed, 3 failed, no error in the engine log. The probe makes the checks the project's Wisdom test makes for Building, Thieving and Woodcutting.
- Changed, `scripts/fishing/state.gd` only: the Wisdom the mission record gave is measured (the way `ActionRuntime` does it for the other skills) and passed to the gain feedback, so one book rises beside the XP for each point earned. With the net or the boat a catch shows nothing until the haul; its Wisdom is earned at the success, so its book rises then, from the tile's corner where the Wisdom book sits. No data, save key or test was changed. The file keeps the LF line endings it had.
- With the change, the same probe unchanged (19:42, real window, phone layout): `diag-fishing-wisdom-gain PASS (failures=0)`, 23 checks passed. With bare hands, in the light and in the dark theme, one book rises for the one point earned, carries no number, is inside the screen and to the right of the XP text (book from x 313, text ends at 302). With the net, two catches that only went into the net and one haul each give +1 Wisdom and raise one book. No error in the engine log. The engine-free contract checks pass on the tree with the change. The horizontal layout had not been run when this was written.
- The Wisdom test's two Fishing failures named in the afternoon report ("Gate allows threshold" for Chum Line and Deep Trench) were the test's setup, not the game; see "Audit continuation, October 17 (later afternoon)".
- Not changed, for Brian to judge: nothing asks for Fishing Wisdom before Chum Line at level 70 (120 Wisdom) and Deep Trench at 88 (300), so River Bend's book explains itself with "Wisdom N / 120 for Chum Line" for 56 levels. The project's Wisdom test checks the rising book for Building, Thieving and Woodcutting; a Fishing case can be added to it once a run is free.

## Cut-off pages in the web version, October 17 (night, after the 0.7.0 release)

Reported by a player of the published web build (Discord, #idle-elite, 9:00 PM): the stamina circle of each skill cut off at the edge of its column, number included; long activity names running under their medals; numbers past their boxes; and, four minutes later, "(i) information buttons are just the letter i". Brian asked for it to be fixed and suggested two columns on that screen or a smaller scale. The same player's remark that the ad bonus may not work is not part of this: the player said it could be blocked on their side, and nothing was looked into or changed for it. In the working tree; not committed; **in no build**: the published web build (itch upload 19836331) and the Play bundle of that evening were made before it.

- Cause. A page of the horizontal layout is the phone's page, laid out for 984 units of width. `scripts/ui/desktop_layout.gd` let a page be narrower in two ways. It capped a page at 1024 real pixels with no lower bound; in a window more than about 2000 pixels high (a 4K-class or high-density screen, fullscreen) 1024 pixels are fewer than 984 units: 910 at 3840 x 2160, 819 at 3840 x 2400, 683 at 5120 x 2880. And it showed three pages as soon as each had 900, so screens shaped 3:2 or like a MacBook got three pages of 915 to 940. A page's header needs about 875 units for its gauge to sit beside the title; an activity's name has the page's width less 297 less half its medal before it reaches the medal, and the widest name is 595 units by the engine's own measure (see the run of October 18 below; an estimate made outside the engine had said 543), so names run under the widest medal on pages narrower than 975; the stat box and the picture share what is left. In the player's picture a page is about 803 units wide (the header icon, 200 units, is 100.5 picture pixels and a card 384): only the pixel cap makes a page that narrow.
- Changed, `scripts/ui/desktop_layout.gd`: the narrowest page is 993 units. The longest name is 595 units; beside the widest medal, and with the title's outline size (17) kept clear of the medal as well as the letters, it needs a page of 992. A window with less room than that for each of three pages shows two wider pages, through the page count that was already there, and every skill is still reached by dragging or by the corner arrows. That now includes 16:10 screens, which have 979 for each of three: they show two pages of 1486. The pixel cap still stops a page growing on a large screen and no longer makes one narrower than the narrowest page allowed. (Earlier forms of this change: 970, made on October 17 before anything had run, which the engine's measure of the names on October 18 showed to be too little; then, for an hour on October 18, 981 with 28 units between pages in place of 36, which kept three pages on 16:10 screens on the strength of a measurement of the outline in one picture, 4 to 5 units in most places. That measurement gives typical thicknesses and no upper bound, so it does not carry the claim, and it was taken back: the space between pages is 36 as published. Whether a smaller minimum is safe, and with it three pages on 16:10 screens, needs pictures of the longest names beside the widest medal.) Nothing about scale was changed: the project's own contract check forbids scale overrides at run time, which rules out the smaller scale. Nothing for Android was touched (the horizontal layout does not exist there; `project.godot` is as it was).
- Changed, the same file: the information button beside a skill's name, and the one on the firepit and its like, keep the phone's round button in the horizontal layout, 56 units across. They had been stripped to the bare letter there on purpose, with the letter's own 44 unit box (18 to 25 pixels) as the only thing to click. For Brian to judge: the bare letter was a choice of the horizontal layout's design, not a rendering fault.
- By the layout's own arithmetic, pages and their width, published to changed: 1920 x 1080, 1600 x 900 and 2560 x 1440 three of 1092, 1366 x 768 and 1280 x 720 two of 1550, 1024 x 768 two of 1230, 800 x 600 one of 1550: all unchanged. 16:10 screens (1440 x 900, 1680 x 1050, 1920 x 1200) three of 979 to two of 1486 (2560 x 1600: two of 1229, where the pixel cap applies); 1500 x 1000 and 2256 x 1504 (3:2) three of 915 to two of 1390 and 1307; 3024 x 1964 three of 940 to two of 1001; 3456 x 2234 three of 880 to two of 993; 3840 x 2160 three of 910 to three of 993; 3840 x 2400 three of 819 to two of 993; 5120 x 2880 three of 683 to three of 993. The narrowest window that keeps three pages is 1947 x 1200. A narrow or upright window falls back to the phone layout as before. With the chat panel open a 16:10 window now has one page beside the chat where it had two of 953; a 16:9 window keeps two of 1124. On screens more than about 2000 pixels high the pixel cap leaves the pages narrower than the window has room for: two pages of 993 on a 3840 x 2400 screen stand in the middle with a third of the screen empty at the sides (the published build had three there, cut off). For Brian to judge from pictures. The published column of this arithmetic agrees with the engine's reading of October 18 to within 0.2 units at every size read.
- The project's window test of this layout, `scripts/tests/desktop_responsive.gd`, asserted the pixel cap without a lower bound. It now lets the cap give way at the narrowest page allowed, asserts that a page is never narrower than that, and has two more sizes (1500 x 1000 and 1680 x 1050: two pages each). No assertion was removed.
- Checked without the engine: `check-1080p-migration-contracts`, `check-ui-boundary-contracts` and `check-activity-ui-boundary-contracts` pass on the tree with the change (run again on October 18 at 02:38 with the minimum at 993).
- Run in the engine, October 18, 02:15: the layout as it was published (its three changed pieces put back on the current source), without a window, on a progressed save, at thirteen window sizes. A before reading, and it fails as the report says: 41 of 183 readings. Pages of 819 units at 3840 x 2400, 683 at 5120 x 2880, 910 at 3840 x 2160, 915 at 1500 x 1000, 940 at 3024 x 1964, and 953 for each of two beside the chat on a 16:10 screen. The header gauge cut off at the page's edge by 56 units at 3840 x 2400 and by 193 at 5120 x 2880 (whole from 910 on). Names under medals on the cards on screen at five sizes ("Borrow A Cookie Permanently" by 123 units at 3840 x 2400); of all 172 names against the widest medal, 49 under it at 819, 24 at 910, 16 at 940, 7 at 953, none at 979 and wider. The information button a bare letter at every size, 14 to 66 pixels across. No stat box or number past its box at any size, the narrowest included: the "numbers past their boxes" of the report is not found by these readings. Every skill could be brought on screen with the arrows at 1920 x 1080, 1500 x 1000 and 800 x 600, and the running activity kept running through every resize. Two of the 41 failures say nothing of the published layout's columns: the probe asked a native window for 540 x 960, which outside the browser cannot be narrower than 800 (it now lifts that minimum for the size, as the browser has none); and the phone's bottom navigation failed its line in the narrow window, for the reason found in the run of 06:21 below, not for the timing first supposed here (that the probe had looked before the game's half-second refresh: a guess, withdrawn).
- Run in the engine, October 18, 06:21: the same reading on the change (the minimum of 993), without a window. Complete (thirteen sizes, the arrows at three, the chat at three, three narrow windows, wide again), 44 seconds, no engine error: 241 readings pass and 3 fail. Every reading of the horizontal layout passes at every size. Pages as the arithmetic above says: two of 993 at 3840 x 2400, three of 993 at 3840 x 2160 and 5120 x 2880, two of 1486 at 1920 x 1200, two of 1390 at 1500 x 1000, two of 1001 at 3024 x 1964, the rest as published; beside the chat, one page at 1920 x 1200 and two of 993 at 3840 x 2160. Every header gauge is whole inside its page. No name is under its medal or closer to it than the outline's size of 17 units: of all 172 names beside the widest medal none, at every size (the least room a name has is 613 units, the longest name is 595). Stat boxes and numbers are inside. The information buttons are drawn as buttons, 56 units across, at every size. All five skills are reached with the arrows at 1920 x 1080, 1500 x 1000 and 800 x 600; the chat panel covers no page; the activity keeps running through every resize; the three pages are back at 1920 x 1080 afterwards. In the narrow windows (540 x 960, 800 x 960, 1000 x 900) the phone layout is used, its page is 984 wide, its header gauge whole and its own information button unchanged. This is geometry read without a window: not pictures, not a browser, not the itch page, not other pixel densities or zoom. The totals are not like for like with the before run, which had fewer lines.
- The 3 failures are one line in the three narrow windows, the phone's bottom navigation "shown, inside the window". The navigation is shown at once; the line fails because the navigation's panel ends 18 units below the window. That is how the bar is built, on the phone as well (`scripts/ui/navigation_shell.gd`, the same at the last commit: a slot of 210 units for a panel whose smallest height is 18 + 162 + 48 = 228, which grows downward): by that arithmetic the 18 units are part of its empty bottom margin and its buttons end 30 units above the window's bottom. The before run failed the same line with the published layout, so the change did not bring it. Nothing in the game was changed for it. The probe's line asked for more than the phone layout gives. It was replaced, after review, by lines that still write down and judge the panel (its place, its height against its own smallest height, nothing of it below the window but bottom margin) and that judge each button of the bar: its rectangle, what clips it, the region the game takes presses in, the game's own hit test, a press sent through the game's input, and a tap that opens the settings page and one that closes it.
- Run in the engine, October 18, 07:05: the narrow windows alone with those lines, then 1920 x 1080 again, without a window. Complete, 15 seconds, no engine error: 134 readings pass, none fails (a different and narrower reading than the one of 06:21; the counts are not to be compared). At 540 x 960, 800 x 960 and 1000 x 900 the bar's panel is written down as before, 228 units high in its slot of 210 with 18 units below the window, and those 18 are within its bottom margin of 48, under the row of buttons, which ends 30 units above the window's bottom. All five buttons (Hero, Hub, Skills, Settings, Shop) are shown and take presses; each is whole inside the window and cut by nothing; the region the game takes a button's presses in ends 6 units above the window's bottom; a press sent through the game's input begins on the button pressed and on no other, and is dropped when it ends away from it; a tap on Settings opens the settings page and a second tap brings the Fighting page back, at each of the three sizes. The activity keeps running, and the three pages are back at 1920 x 1080 with every reading passing. The other four buttons were pressed and let go without opening their pages.
- Pictures, before: October 18, 07:25, the published layout rule put back on the current source, in a window on the right-hand monitor (the compatibility renderer), at 1920 x 1080, 1920 x 1200, 1500 x 1000, 1600 x 900, 1366 x 768, 1280 x 720, 1024 x 768, 800 x 600, with the chat open at the first two, the three narrow windows, and 1920 x 1080 again: 14 pictures, each the window's own size. The reading that goes with them fails 22 of 282 lines, all the published rule's (the bare-letter information button at every size; pages of 979 and 953 at 1920 x 1200 and of 915 at 1500 x 1000 with names against medals, "Borrow A Cookie Permanently" under its medal by 28 units at 1500 x 1000). Measured from the pictures themselves, the pages are within 2 units of the engine's figures at every size. These pictures cannot show the cut-off stamina circles of the report: those come at windows more than about 2000 pixels high, and a window here cannot be taller than 1440. The game's own pop-ups from the test's maxed save lie over the middle of some pictures.
- Seen in the before picture at 800 x 960 and repaired, October 18, 07:49: in a window narrow enough for the phone layout that is then made wider, the neighbouring skills' pages showed at the window's sides, cut off by it, and a pop-up that was already showing stood right of the middle, cut off or outside the window. Both are places given once and not given again when the window changes its width. The pages kept beside the current one for swiping (`scripts/ui/skill_adjacent_pages.gd`) are laid out one screen's width away when they are built, and a resize keeps the page that is there; they are now laid out again when that width has moved, with their header shelves, and nothing is rebuilt. A pop-up is placed in the middle of the window it appears in, and its place was corrected for a changed width only in the horizontal layout; `scripts/ui/achievement_toast_surface.gd` now does the same in the phone layout. On a phone the width never changes and neither change does anything. Checked without the engine: the patch is 33 added lines and nothing else, and a model of the two pieces of logic has no part of a neighbour inside the window and the pop-up in the middle at every width tried. Measured in the before picture, the neighbour's card stood at 1410 units, where a layout made for a phone's width puts it. Not in the Discord report; found while checking the narrow windows for it. Both repairs have since been read in the engine (the next two entries).
- Run in the engine, October 18, 08:19: the repair of the neighbouring pages, without a window (wide, then 540 x 960, 800 x 960, 1000 x 900 and 540 x 960 again, with no change of page between). At every size both neighbouring pages are one screen's width from the current page with nothing of them inside the window; they are the same pages as before each resize, still built, with the same scroll; the current page's header shelf reaches from side to side and no neighbour's shelf is inside the window; the current page keeps its scroll and the activity keeps running. A page dragged with the game's own swipe functions while the window is resized stays where the drag has it, with its neighbours one width away, and the drag goes on; let go under the swipe's threshold and resized again as it glides back, it comes back to the middle. Each of those two cases is counted only because the game itself said, in the frame of the resize, that the drag was held and that the glide was under way. 61 readings pass. The same run failed 6 lines and left one case unexercised, all for one reason: there was no pop-up in it at all. The game queues the pop-ups of what has been earned at the end of its start, and only when it has a display (`scripts/app/boot_warmup_runtime.gd`); without a window nothing queued one. That was a gap in the test's setup, not a fault of the pop-up, and the run said nothing about the pop-up's repair either way.
- Run in the engine, October 18, 09:09: the repair of the pop-up, without a window, in a reading of the pop-up alone. Without a display the test makes the one call the game makes at its start when it has one (said in its log as test setup); the game then queues, places and animates the pop-ups itself: one showing, 35 behind it. 91 readings pass, none fails and no case is left unexercised. A pop-up that appeared in the wide window is whole inside the window and in its middle at 540 x 960, 800 x 960, 1000 x 900 and 540 x 960 again, and again after a resize made in a frame in which the game marked it as changing its card. A press in its middle where it is drawn, sent through the game's input, moves it on to its next card (once, then 33 more times until none is queued), so its press region is where it is shown; the last card pressed, it leaves in the middle of the window. A pop-up that then appears in the phone layout comes in in the middle with its parent where it always was, and stays in the middle when the window is made wider, narrower and wide again. In the wide layout the pop-up is where it was before the repair: in the middle of the part of the window the pages have, lifted above the page arrows, and beside the chat panel when that is open. Both of these runs read places, presses and the game's own state from its controls; neither made a picture.
- Found in passing, about test runs only: the switch that turns the game's saves off in a test (`IDLE_ELITE_DISABLE_SAVE_WRITES`) stops its normal saves and not the first save a new install writes at its start (`_start_new_save_file` in `scripts/save_state/save_runtime.gd`), nor the crash report's session marker. Each test run of this work therefore left one small save in its own folder, which is never the real one; the real save's time of writing was unchanged in every run. The launchers used here now say so in their output, refuse a folder inside the real profile, and list what a run left behind. Nothing in the game's save code was changed.
- **Not run yet**: pictures of the change and of the two repairs (the after pictures to match the before ones); anything in a browser or on the itch page; other pixel densities and zoom (where the cut-off circles can be pictured); a phone; a build. `desktop_responsive.gd` itself was not run: it opens at the left monitor and goes fullscreen.
- Lines for the notes of the next web upload, when there is one: "fixed skill headers and activity names being cut off on large and high-resolution screens", "screens without room for three full columns now show two wider ones", "information buttons are round buttons again in the wide layout", and "a narrow window made wider no longer shows the neighbouring pages at its edges or leaves a pop-up off to one side" (read in the engine on October 18; not yet seen in pictures or in a browser).

## The chat icon in the wide layout, and a full Wisdom bar, October 18 (late morning)

Brian, 11:14: "fix the interaction where if you click chat icon it kind of opens and closes inconsistent". And at 11:15: "make it so wisdom bar collapses when full. similar to when you fill the other blockers". In the working tree; not committed; in no build. **Neither change has been run.** No engine run has been possible on this PC since 09:09 that day (every heavy job waits for an approval that is Brian's to give), so both were made by reading the code, and what a run has to show is listed under each.

The chat icon:

- Found by reading `scripts/ui/desktop_layout.gd` (`activate_ribbon`, `set_social`). The speech-bubble icon in the wide layout's ribbon opens the panel on the right, and four things made that uneven. (1) The panel was put on the screen at once, fully drawn; then every skill page was laid out again for the narrower room, which takes several frames; only then did the panel's opening animation start, and that animation begins from nothing. So on one click the panel showed, went, and faded in again, for as long as the pages took. (2) A click on the icon while pages were being built was dropped without a trace. (3) A second click while the panel was closing was judged against the tab that was still open, asked for "closed" once more, and so did nothing. (4) A click on the tab that was already open ("Chat" on the chat panel) closed the panel and built it again.
- Changed, that file only. The new panel, and the chat inside it, stay out of sight until the opening animation starts. A request that comes while pages are being built is kept and carried out when they are done. The icon switches where the panel is heading, not where a transition in flight happens to stand: a click while it closes opens it again, and a click while it opens closes it once it has opened, so every click is one switch. A click on the tab that is already open does nothing. In the same lines: the chat's surface is left still and opaque when the panel has been put away. The closing animation used to leave it transparent, and in a window made narrow afterwards the phone layout's chat would have opened unseen.
- Not changed: the time the pages take to be laid out again when the panel opens or closes. The panel waits for it out of sight; the icon's highlight changes at once. The phone layout's chat strip was read and not touched.
- What a run has to show, in a wide window: one click, and the panel is never seen before its animation and never goes once it has come; a click while pages are being built is carried out afterwards; a click during the closing opens the panel again; "Chat" clicked on the open chat changes nothing; the same for High Scores; and after a chat opened and closed in the wide window, the chat in a window made narrow is seen when it opens.

The Wisdom bar:

- What the words are taken to mean. The bar is "Wisdom Required (n / m)" under an activity that asks for Wisdom: six activities have one (Flow Like Water, Rematch Buff Hay Bale, Scope Out a Heist, Frame a Treehouse Platform, Build a Decoy Vault, Carve the Guild's Trophy Oar; the two Fishing ones show Wisdom as a tile of their barrier). The other blockers are the padlocks on the same activity, each of which drops when its level is reached. A full Wisdom bar did not go: it stayed under the activity until everything else was done, so with a level still missing it sat there full.
- Changed (`scripts/progression/wisdom_state.gd`, `scripts/ui/wisdom_panel.gd`, `scripts/ui/skill_detail_surface.gd`). With "auto unlock" on, which is how a new game starts, the bar is put away as soon as its Wisdom is there: its words fade, it slides up behind the card, and the card closes the room it took. That is the motion it already made at an unlock, without the unlock. The activity stays locked by the padlocks that are left, with its chain and dimming; when they open it unlocks as before. An activity that is drawn when its Wisdom is already there has no bar and keeps no room for one. One rule decides it in every place (`WisdomState.requirement_bar_shown`): the bar itself, the height of the card when it is built, and the height the list plans for it.
- With "auto unlock" off nothing opens by itself, and nothing was changed there: a full bar stays, and when it is the last thing left it is the "Unlock" button the player presses. The project's Wisdom test makes its screen checks with that setting; none of its assertions was changed and it was not run.
- If the Wisdom of a skill should ever be less than a bar needs after the bar has gone, or "auto unlock" is switched off while a full bar is put away, the bar comes back; a card always shows what the rule says.
- For Brian to judge: whether a full bar should also go by itself with "auto unlock" off; and the Wisdom book on the activities that give Wisdom, which still shows while an activity asking for Wisdom is locked, also when its bar is full and only a level is missing.
- Noted at 19:05 that day while reading the project's tests, and bearing on the first of those two questions: "blocker" is this project's own word for the requirement badges on a locked activity's cover (the entry above on unlock resources: "compact illustrated blocker badges"; `scripts/ui/project_panel.gd` `blockers`), and Wisdom is one of them on the two Fishing activities. When a cover's badges are full the cover goes by itself, with "auto unlock" on or off, and leaves the standard level lock where one is needed (`project_panel.gd` `sync`; `scripts/tests/unlock_layout_stability.gd` runs with the setting off and expects the activity in the cover's place). So "similar to when you fill the other blockers" may mean those badges and not the padlocks. With "auto unlock" on, as a new game has it, the change made is the same under both readings: the full bar goes and the padlocks stay. With it off the readings differ: taken that way, a full bar would go by itself there too. Nothing was changed for it. With the setting off a full bar is what the player presses to unlock when it is the last thing left, and what should stand in its place is Brian's to say.
- What a run has to show, with "auto unlock" on and a level still missing: the bar at its last point fills, its words fade, it slides up, the card is 96 units lower, and the padlock, chain and dimming are as they were; no row of the list overlaps another while it moves or after; the same card built afresh has no bar; when the level is reached the activity unlocks with its usual ceremony and no bar comes back. With "auto unlock" off: nothing of this happens, and the project's Wisdom test passes as it did.
- Lines for the notes of the next upload, when there is one: "fixed the chat panel flickering when it opens, and clicks on the chat icon being lost" and "a full Wisdom bar now goes away by itself, like a padlock whose level is reached" (neither run yet).
- Where the checking of both stands (written after 12:40 that day): source only. No engine has loaded the four changed files, so nothing yet shows that they load. A probe for both changes and its plan are written in the session's scratch folder, not in the project: `chat_wisdom_probe.gd`, third form, SHA-256 `db70195579c96e58dc15d557d75d086a61e4585abfb7009d21535c64be15e4bb` (10 chat cases, 8 Wisdom cases), and `acceptance-plan-chat-wisdom.md`. The supervisor reviewed the probe in its three forms. It has had text checks only (nothing found), which are not the engine's parser, and it has not been run or put into any queue.
- Read in the source about three states the probe does not play; reading, not results. (1) A folded card: only an unlocked activity can be folded (`_module_ui_action_allows_pin_or_collapse`, `module_ui/runtime.gd` `is_collapsed`), and the bar's new motion runs only on a locked one, so the two do not meet; a card folded in the fraction of a second in which the bar slides away at an unlock is as it was before. (2) A page beside the one in focus in the wide layout: the bar follows the same rule there, and its row is sized directly; that page's own list plan (kept as the same array while the page is out of focus) held the row's height with the bar's 96 units, and nothing put it right, because the row already had its height when the page was shown again (repaired at 13:08, next bullet; what was written here at 12:45 about rows being mounted late was wrong: a row with a slot is mounted by the slot's own place). In the phone layout a neighbour page's cards are not updated while out of sight, so a full bar there goes when its page becomes the current one. (3) An unlock that begins while the bar is sliding does not wait for it; the padlocks and dimming are then taken off by the card's ordinary lock layout. None of the three has been seen.
- One more change for the Wisdom bar, 13:08 that day, by reading, not run (`scripts/ui/skill_detail_surface.gd`, 20 lines added: `_apply_activity_slot_height` and a new `_sync_detail_lazy_plan_height_to_row`). When a card's row already has its height, the list's plan for that row is now brought in line with it, for cards that have a Wisdom panel. Before, a bar put away on a page that was not the one shown left the bar's 96 units in that page's plan until the page was built again. The plan's height is used where a row has no slot, where a stat panel's room is given back for a card out of view, and where a slot is made again; nothing on the screen moves by the change itself.
- Found in the same reading, and repaired at 13:17 that day by reading, not run: a row whose card is out of view when its bar's state changes (the Wisdom reaches its amount, or "auto unlock" is switched) kept the bar's room until its card came back. A row that never had a card was then 96 units lower in one frame; a card kept from before put its bar away on arrival. The rows after it moved with that, which is on the screen when the player scrolls up to the activity. The list repairs the same thing for the stat panel already (`_release_unmounted_stat_panel_room`), and the repair follows it. Changed: `scripts/ui/wisdom_panel.gd` (new `settle_now`: a card out of view takes the state of its bar at once, with no motion; only for a locked activity with nothing being played on its card) and `scripts/ui/skill_detail_surface.gd` (new `_settle_unmounted_wisdom_rows`, called where the list mounts rows: a card kept from before settles its bar on its own row, a row with no card takes the height the list now plans when it differs by exactly the bar's room, and when the row is above the screen the scroll moves with it so that what is on screen stays where it is; and in `_detail_lazy_can_unmount_entry` a card whose bar is moving is not unmounted until it has finished). With "auto unlock" off nothing is put away. An unlock out of view goes as before.
- That repair was corrected at 13:43 the same day, again by reading and not run (the same two files). Two things were wrong with it as first made. It passed over a row whose card the list had made ahead of time and not yet put on the row, which is the usual state of a row near the screen: the list builds cards ahead for up to eight rows. And it was called only in the list's pass over its window, which the list makes when it is scrolled and not while it stands still, and which a jump to an activity by name, the rows filled in at a landing and the cards made ahead do not go through. Now a card made ahead has its bar settled too, with its row sized by the list's own arithmetic, and the settling is called for the one row at the place every route that brings a card back goes through (`_detail_lazy_mount_item`). Not repaired, and noted: a card that is on the page just above the screen puts its bar away by its motion, as a card on the screen does, and the rows on the screen move up with it.
- Six cases for these repairs are in the session's probe since 13:51 (`chat_wisdom_probe.gd`, a third part `rows`; fifth form, SHA-256 `94aa0d8a42d14712f7336818d0cd9545792733a94bb97d1671cc7fb58bfe6cc8`; text checks only; not run): a row above the screen with no card or a card made ahead, with a kept card, a row below the screen, the setting off, a jump to the activity by name in the frame the bar fills, and the list's plan on a page beside the one in focus. Still in words only: the setting switched by hand both ways, an unlock out of view, a card not unmounted while its bar moves.
- What a run has to show for the repairs of the afternoon, as first written down at 13:21 (the list's pass happens when the list is scrolled, not at once): with the activity above the screen and unmounted, once with no card and once with a card kept from before, the last point of Wisdom given: the row is 96 units lower, the scroll with it, and nothing on the screen moves; scrolled up to, its card comes in with no bar, no motion and no jump; the same with the row below the screen and the scroll left alone; "auto unlock" switched on and off with a full bar; nothing at all with it off; a card not unmounted while its bar moves; and on a page beside the one in focus, the list's plan equal to the row after the bar went. The whole list is in the session's scratch folder (`acceptance-plan-chat-wisdom.md`, "Cases for a row out of view"; `wisdom-row-plan-trace-and-proposal.md`).

## A version code for builds that go to itch.io, October 18 (afternoon)

Brian, in the session that afternoon: "when you make uh, versions that are for itch.io, I think that we should give that version number a code so I think that when you export this one, it should be version 0.7. Point, one, I, like with a lowercase I at the end to represent itch." So: a build for itch.io carries a lowercase i after its number, and the next export of this work is 0.7.1i. In the working tree; not committed. **Nothing has been exported and nothing run.**

- `scripts/build-desktop-working.ps1`, the builder that takes uncommitted work and makes the itch.io web zip and the Windows zip. It now has to be given `-Version`, three numbers and a lowercase i (`-Version 0.7.1i`), and refuses anything else, so that no build goes out under the number of the one before it. It names its zips by it (`idle-elite-v0.7.1i-itch-web.zip`, `idle-elite-v0.7.1i-windows.zip`), puts them in `outputs\v<Version>` unless another folder is given, writes `build-version.txt` beside them, and stops when a zip of that name is already in the folder instead of writing over it. Before the export it writes the version into the build's own copy of `project.godot`: the number (`config/version="0.7.1"`) and, as a setting of its own, the code (`config/version_suffix="i"`). The working tree's `project.godot` is not touched and still says 0.7.0. The number is kept plain because the Windows export makes its file version from it.
- The game shows the number and the code together wherever it shows its version: under Settings (`scripts/ui/settings_surface.gd`) and on the loading screen (`scripts/ui/progression_loading_screen.gd`), which had "0.7.0" written into it and now reads the build's own version. A build with no code (Android, a run from the editor) shows the number alone, as before.
- Checked without the engine: the builder parses; its test takes 0.7.1i and refuses 0.7.1 and 0.7.1I; the stamp tried in memory on the project file gives the two lines above. Not run: no export, so no zip, and no build has shown "0.7.1i" on a screen.
- Not changed: the project's own version, the Android export settings, `scripts/build-itch-release.ps1` (the builder from the last commit, which names its zip from the version and the Android code) and `play-store/docs/release-notes-0.7.0.txt`.
- For Brian: whether the project's own number should move to 0.7.1 as well, which is what an Android build made from this tree would show; and whether the rule should be written into the project's AGENTS.md so that every session follows it.

## 0.7.1i validation and export, October 19

Brian requested testing the cropping and sizing fixes and an itch.io upload recommendation. This supersedes the earlier "not run" and "not exported" status for this candidate.

- Fixed one additional reproduced defect in `scripts/ui/skill_detail_surface.gd`: immediate card-height changes now set the rendered card height before resizing its list row. The Wisdom bar could otherwise leave a 2–3 unit overlap until the next container sort.
- Native responsive checks passed 343 assertions. Headers, all 172 activity names against wide medals, statistics, input, chat, pop-ups during resize, portrait transitions and Wisdom row/animation regressions passed. Actual production-scene screenshots were captured and inspected.
- Exported `0.7.1i` with the official Godot 4.7.1 engine. The exported Settings screen shows `Version 0.7.1i`. Source `project.godot` and Android settings remain unchanged.
- The actual web export passed 15 direct and 6 local iframe size/DPR cases with zero console errors. The prior 0.7.0 export's browser save upgraded and reopened with progress preserved. All online test traffic was mocked.
- Corrected invalid synthetic probe data rather than weakening the production save protections. Earlier failed fixture runs remain in the evidence folder.
- The validated itch ZIP is `H:\Codex\Projects\IdleElite\outputs\v0.7.1i\idle-elite-v0.7.1i-itch-web.zip`. Evidence is `H:\Codex\Projects\IdleElite\outputs\v0.7.1i-validation`. Full checks, limits and SHA-256 are in `play-store/docs/itch-release-readiness-0.7.1i.md`.
- Published October 19 through Edge at https://weskillnow.itch.io/idle-elite. Upload 19893707 is selected for browser play; prior upload 19836331 is retained and hidden. Reloaded settings and the public launch target confirm the new selection. Hosted JS, PCK and WASM hashes match the validated export. Browser gameplay coverage is Edge/Chromium on Windows with simulated viewport/DPR changes; no claim of Firefox, Safari, physical mobile or live itch-hosted gameplay testing.


## Ham OSRS feedback and compact bonuses, October 21

Implemented in the active native-1080 checkout; not packaged or published. Reviewed the Ham OSRS DM from October 4 through October 21. New fixes:

- Each completed mission now has its own saved replacement deadline. Finishing another mission does not reset earlier waits. Legacy shared deadlines migrate without an added delay, including during offline completion before board synchronization.
- Offline resting activity completion now restores stamina as the live path does. The help states the actual recovery target and amount.
- Fish inventory display floors compact values, so 999,999 does not claim 1M before a 1M purchase is affordable.
- Tier reward cards put the stat icon and target tier on one row and use matching stamina/time icons. Regular activity medal taps open compact local bonuses, with “Neighbors” and without unrelated global summary rows. Global bonuses still apply.
- Superseded October 22: the global success curve was removed at the owner's correction. Individual later activity bases are tuned instead; additive bonuses and the 100% cap remain.
- Eighteen recovery portraits are now distinct, with calmer Fighting/Thieving backgrounds; the shipwright lockbox has a matching portrait. Fixed authored portrait insets and deferred size updates keep artwork inside its frame.
- Display names “Build a Storm Shelter” and “Spar with the Living Tree” match their pictures and combined skill use. Public IDs, saved progress and rewards remain compatible.

Acceptance: the full project check passed, as did the new 40-combination live/offline recovery regression, exact Thieving comparisons, cooldown/save migration tests, older Ham feedback tests, database audit, and the muted real-game capture run. Twenty-seven inspected raw PNGs are 1080x1920. No Android display setting changed. Physical Samsung validation remains outstanding before release. Feature suggestions such as equipment, rare loot, higher level caps, dual training and another skill remain unimplemented.

Evidence and item-by-item disposition: [2026-10-21-ham-feedback.md](playtests/2026-10-21-ham-feedback.md). Artwork prompt and final paths are recorded there.



## Masked portrait color correction, October 22

Fixed the shared activity-art mask multiplying the texture into fragment COLOR a second time. Godot already supplies texture-modulated COLOR, so the old shader squared color channels and alpha. Enabling the rounded mask exposed this on the new recovery portraits and ordinary activity art. The shader now preserves the existing sampled color and applies only its intended mask/recolor effects. Artwork files and authored sizes are unchanged.

Acceptance: inspected a new raw 1080x1920 capture from the real main scene. Two opaque blue samples match the source PNG composited over its white frame within one 8-bit channel step. The production-scene color regression, activity UI boundary and generated-file hygiene checks passed. Main-screen audit completed. No release packaged. Evidence: [2026-10-22-portrait-color.md](playtests/2026-10-22-portrait-color.md).


## Player hub trophy table, October 22

The spoon, jewel, idol and crown displayed on the Player Hub table now use individual authored sizes and bottom anchors. Their visible bases sit in the lower third of the tabletop, and their widths fill 69–80% of its visible width. Texture margins no longer determine their apparent alignment. Trophy acquisition, bonuses and saved positions are unchanged. The mistaken changes to Thieving heist cards were reverted.

Acceptance: all four trophy tiers were inspected in raw 1080x1920 captures of the actual Player Hub, reached through its bottom navigation. All four position, size, touch-to-open and dismissal checks passed. The required main-screen audit and UI/hygiene/1080p contract checks passed. No release packaged. Evidence: [2026-10-22-hub-trophy-table.md](playtests/2026-10-22-hub-trophy-table.md).

## Version 0.7.2 labels and AdMob configuration, October 22

The shared project version is now 0.7.2, so the loading and Settings screens show the requested version. Android and Windows export version metadata match. The Android version code remains 43. The new publisher's AdMob app ID and rewarded unit were already configured and were verified in source; the hosting setup document now records the configured developer website and app-ads.txt URLs. Both authorized sellers remain listed during migration.

Acceptance: the muted production-main-scene run passed loading/Settings label checks and rewarded-unit configuration assertions. Both inspected raw captures are 1080x1920. Crash-audit, generated-file hygiene and test-harness contracts passed. Public app-ads.txt availability and AdMob ownership verification could not be checked because network access failed. No release packaged or hosting deployment performed. Evidence: [2026-10-22-version-072.md](playtests/2026-10-22-version-072.md).

## Spoon placement follow-up, October 22

Reduced the Player Hub spoon's authored draw box from 230px to 210px (8.7%) and lowered its ground anchor by 8px so its cushion sits farther onto the table. Other trophy layouts retain their prior values. The real-main-scene capture and all four trophy position, size and touch checks passed again, as did the fourteen-screen audit and generated-file hygiene check. Inspected the updated raw 1080x1920 spoon capture. This follow-up is in source; the previously installed phone preview does not yet contain it. Evidence: [2026-10-22-hub-trophy-table.md](playtests/2026-10-22-hub-trophy-table.md).

## Ad bonus page, October 22

Replaced the stacked offer copy and three small stack lights with a wide gold Watch ad button, one compact reward row, a clear two-hour/six-hour description, and a horizontal six-hour timer bar. The visible HH:MM:SS clock ticks each second while the bar drains continuously. Existing reward mechanics and stacking limits remain intact. The button has tactile press/release feedback and a brief reward emphasis without floating text over the controls. Developer copy and the rating action sit separately near the bottom. Light and dark themes fit at 1080x1920.

Acceptance: the real-main-scene touch/capture regression passed empty, active, two-hour, full, expiry, duplicate SDK callback and dark-mode checks. Inspected raw page states and button animation frames. The fourteen-screen audit and UI, activity UI, hygiene, test-harness and crash contracts passed. No phone build or live-ad delivery verification was performed for this change. Evidence: [2026-10-22-ad-bonus-page.md](playtests/2026-10-22-ad-bonus-page.md).

## Illustrated ad bonus frame, October 22

Owner rejected this frame as resembling a pool table. It is replaced by the selected tan blue-book backdrop below.

The ad page now fills its available screen with a wood-and-brass illustrated frame, dark green inset, and new blue-character/television/hourglass artwork. Corners stay intact while rails and center adapt to the screen; the hero preserves its aspect ratio. Live text uses cream and gold with responsive sizing. The offer description is one line. Tall screens keep the developer section near the bottom; short screens scroll inside the stationary frame without losing readable text or the rating action.

Acceptance: production-main-scene verification passed at five portrait proportions, including touch scrolling on short views. Inspected raw frame, art, timer and button captures. The fourteen-screen audit and UI, activity UI, hygiene, test-harness, native-1080 and crash contracts passed. No viewport or renderer setting changed. No new phone build was installed. Evidence: [2026-10-22-ad-bonus-presentation.md](playtests/2026-10-22-ad-bonus-presentation.md).

## Selected tan blue-book backdrop, October 22

Replaced the rejected physical frame with the owner's selected blue-book ImageGen option: warm tan, soft blue/peach gradients and edge illustrations. Light-mode type is dark brown, with a dimmed background and cream/gold text in dark mode. The background preserves its aspect ratio and anchors to the bottom so the book remains visible on short phones. Live rewards, countdown, button feedback and the separate developer section remain intact.

Acceptance: the real-game reward/UI regression passed at five phone proportions, including book visibility and touch scrolling. Inspected the selected background behind live controls. The main-screen audit, UI/hygiene checks and native-1080 contract passed. No phone update was built. Evidence: [2026-10-22-ad-bonus-blue-book.md](playtests/2026-10-22-ad-bonus-blue-book.md).

## Powered-up ad artwork and text hierarchy, October 22

Replaced the television hero with a bright blue character wearing orange stripes, surrounded by flames and holding extruded versions of the game's stamina and time symbols. The selected tan blue-book background remains. At the owner's request, the duration/cap line uses 36px fine print and the developer paragraph uses 40px text, with the primary rewards, button and countdown retaining prominent sizes. The duration stays on one line and the developer paragraph fits in two across all five checked proportions.

Acceptance: the muted production-main-scene regression passed reward, timer, button, duplicate-callback, dark-mode and responsive checks. Inspected raw game screenshots. The fourteen-screen audit, UI boundary, generated-file hygiene and native-1080 contracts passed. No Godot process remained. No new phone build was installed. Evidence: [2026-10-22-ad-bonus-powered-up.md](playtests/2026-10-22-ad-bonus-powered-up.md).

## Ad bonus time tiers, October 22

Removed the thin divider above the developer section. Both ad bonuses now depend on remaining time: 10% for up to two hours, 12% above two hours through four hours, and 14% above four hours. Zero remaining time grants no bonus. The bar shows all three percentage bands with 0h/2h/4h/6h markers, and the rewards update as the running timer crosses a threshold. The two-hour grant and six-hour storage limit remain unchanged; existing saves derive the tier from their stored seconds.

Acceptance: exact-boundary, actual activity XP/duration, live tier-drop and save-restore assertions passed in the production-main-scene capture run, alongside the existing five-proportion and reward regressions. Raw screenshots were inspected in light/dark modes. Evidence: [2026-10-22-ad-bonus-tiers.md](playtests/2026-10-22-ad-bonus-tiers.md). No phone build installed.

Presentation follow-up: replaced the large percentage bands and hour labels with a slimmer bar and two subtle external 12%/14% tick annotations. Reward copy now consists of the XP/time icons with signed percentages, for example +10% and -10%. Tier behavior is unchanged. Updated raw proof is under `outputs/verification/ad-bonus-subtle-tiers/`.

Further owner refinements: the button contains only its play icon and status label. Removed duration/cap fine print and enlarged the reward icons and signed percentages. The developer note starts “Thanks for playing!” with each sentence on its own unwrapped line. Latest raw proof: `outputs/verification/ad-bonus-large-rewards/`.

## Brian Notes fixes, October 22

Added the approved tier-panel arrangement using existing art: larger medals, aligned bars and unboxed bonuses under one target-tier heading. The top mastery bar is unchanged. Removed activity minimization and restore previously minimized activities when loading. Made the default profile picture the blue bust, condensed neighboring-activity bonuses, and replaced activity Wisdom wording with book icons and source-only help. Corrected Firepit list heights, isolated standalone Fishing combos from equipped tools, preserved their declared reward fields, doubled item feedback when a berry doubles a harvest, and removed the Guys cover's white fringe.

Acceptance: the real-game 1080x1920 regression, tier drag/swipe regression, module/pin/save-restoration regression, Wisdom feedback test, catalog test, UI/native-1080/hygiene gates and fourteen-screen capture audit passed. Full project validation stopped at stale import settings on five pre-existing ad-page assets. No release or phone acceptance is claimed. The local avatar rules update has not been deployed. The fishing roles and economy were implemented in the subsequent pass below. Evidence: [2026-10-22-brian-notes.md](playtests/2026-10-22-brian-notes.md).

Tier-panel follow-up: the shared target-tier label now sits in a borderless rounded container filled with the corresponding target banner color. Increased its top inset and kept the overall panel height stable. Verified the silver T4 and bronze T3 treatments in raw production-main-scene captures at 1080x1920. Evidence: `outputs/verification/tier-target-badges/`.

## Fishing tool clarity and food economy, October 22

Locations now show equipped-tool food/min and XP/min before starting; switching tools in the existing wallet updates the rates. Compatible tool icons identify usable gear. Net is the food choice and rod is the XP choice. Boat is required offshore and mirror in Space; standalone combos and Practice Pool ignore tool restrictions.

Reduced earned Fishing food with a 0.15 multiplier and tuned the corrected space payouts. Measured best available output is 85–88.25% lower across eight progression checkpoints. Existing stocks and equipment remain intact. Food prices are 100 for Bamboo rod, 5,000 for Reinforced rod, 25,000 for Star rod, and 100,000 for mirror. Boat remains 1,000 Softwood with existing level gates. Offline combos retain every rewarded skill's XP under the existing offline policy. Gameplay/rate caches refresh across ad-bonus tiers.

Acceptance: the real-main-scene rate/reward/purchase/save/UI regression, 80,000-attempt simulation, 300 paired live/offline attempts, tool help capture, feedback/Practice Pool, October 21 gameplay, pin/queue interactions and fourteen-screen capture audit passed. Source/UI/native-1080/hygiene checks passed. Full project validation remains blocked by five unrelated pre-existing ad-page import settings. No new phone build or release acceptance. Evidence: [2026-10-22-fishing-tool-balance.md](playtests/2026-10-22-fishing-tool-balance.md).

### Fishing area tool selectors, October 22

Implemented: each fishing area box has a 168px circular tool selector with a 136px icon. Each box saves its own selection, previews food/min and XP/min while idle, and equips that selection when started. The header circle displays food. Removed tiny compatibility icons, aligned food/XP icon columns, restored rectangular mastery bars, and retained original-size artwork in approved 480px modules above the existing water strip and side-tool animation. Split region boxes retain independent selections; save normalization carries rod selections to upgrades.

Validation: visible production main-scene module regression, full fishing balance/reward regression, native fishing input/purchases, and save normalization passed. Raw 1080x1920 evidence and detailed behavior are in [fishing tool verification](playtests/2026-10-22-fishing-tool-balance.md#area-tool-selector-revision-october-22). No release package, install, commit, or deployment.

### Fishing location-square correction, October 22

Supersedes the shared area-box selector and rectangular-mastery-bar revision above. Each individual location square now has an attached 168px circular tool selector with a 136px icon, and its own saved choice. River Bend and Rapids can preview and use different tools. Old region/box selections migrate to their locations. Restored the existing 0.7.0 mastery outline wrapping each square; straight bars remain hidden. Resource/book badges and neighbouring medals stay clear of the tool buttons. Approved taller boxes are 560px; existing water and side-tool animations remain.

Visible production-main-scene checks passed neighbouring selections, active/idle isolation, save reload, legacy migration, mastery presentation and badge clearance. Raw proof is linked in [fishing verification](playtests/2026-10-22-fishing-tool-balance.md#location-square-revision-october-22).

### Fishing frameless selectors and mastery padding, October 22

Supersedes the circular location-tool treatment above. Removed selector circles; each location retains a 144px transparent hit target and 136px darker tool icon with strengthened pure-black contours and internal strokes. Net openings are opaque black. Five selector-only assets were edited through ImageGen; existing active animation art is preserved. Squares moved up 42px and area height is 548px. Added an explicit mastery/rate spacer and checked clearance against every neighbouring medal size, including winged medals, plus real book/resource badges. Independent saved selections and rates remain.

Visible production-scene input, save/reload, isolation, legacy migration and spacing checks passed. Raw 1080x1920 proof: [fishing verification](playtests/2026-10-22-fishing-tool-balance.md#frameless-tool-art-and-mastery-padding-october-22).

### Original fishing artwork, corner tool badges and defaults, October 22

Supersedes the generated selector art and detached selector layout above. Restored original tool textures and applied thicker pure-black strokes in a canvas shader. Each tool overlaps the exact top-right corner of its own location square, without a background circle. The rate panel remains padded away from the wrapping mastery outline. First unlock initializes a location-specific recommended owned tool; later initialization never overwrites a saved player choice. Locked previews no longer freeze a default and recommendations ignore another location's equipped tool. Rejected generated selector files are archived outside the game asset tree.

Visible production tests passed corner anchoring, original-art identity, native taps, recommendations/fallback, repeated initialization, save/reload persistence, gear acquisition, mastery padding, all medal widths and book/resource badge clearance. Save normalization and source/database/UI/hygiene checks passed. Evidence: [fishing verification](playtests/2026-10-22-fishing-tool-balance.md#original-art-corner-badges-and-first-unlock-defaults-october-22).


## Miniature fishing selectors, October 22 (art rejected; superseded)

Replaced the selector artwork with five fresh simplified tool icons designed for a 92px draw box and a 104px transparent tap target. Kept each tool overlapping its own location square's top-right corner and retained independent saved selections and recommended defaults. Removed the selector darkening/stroke shader. The picker uses the matching new art. Centered area headings and location names; names remain visible while active. The wrapping mastery outline and padded rate panels remain.

Acceptance: production-main-scene visible tool regression passed, including active River Bend, changing tools before and during fishing, saved choices, medal/book/resource clearance, centered names and fully raised water clearing both rate panels by at least 16px. Raw 1080x1920 proof: `outputs/verification/fishing-small-tools/module-net-running.png`. Generation prompts and final asset paths: `outputs/art/fishing-small-tools/generation.json`. UI/static/hygiene gates and the fourteen-screen capture audit passed; no release export or phone install. See `docs/playtests/2026-10-22-fishing-tool-balance.md` for current evidence.


## Chunky fishing tool art and shorter boxes, October 22

Replaced the rejected thin tool art with broad heavy-outline versions based on the original tools. Hands use the blue mitten shape with no individual fingers. Area headings are back at the top right. Reduced fishing area height from 576px to 528px by removing 48px of pre-art space; kept active equipment aligned and maintained wrapping mastery, rate-panel and book/resource padding. Independent saved choices and recommended unlock defaults remain unchanged.

Acceptance: visible main-scene regression, fourteen-screen capture audit and UI/static/hygiene gates passed, with active River Bend and actual picker/hands/boat/mirror captures. Raw 1080x1920 proof: `outputs/verification/fishing-chunky-tools/`. Exact generation prompts: `outputs/art/fishing-chunky-tools/generation.json`. Art awaits owner review. No release export or phone install. Details: `docs/playtests/2026-10-22-fishing-tool-balance.md`.

## Active fishing animations and rod tiers, October 22

Replaced the old clipped equipment layer with a clear right-side stage using the approved chunky tool art. Added tool-specific cast, dip, scoop/lift, bob and mirror-sweep motion with separate ripples/splashes. Moved catch bursts beside the equipment. Whole tool canvases remain inside the stage and clear area headings, corner buttons, mastery, medals, rate panels and the bottom water strip. Scale comes only from a canonical 200x200 draw box and available layout space.

Rod tiers are Stick rod, Good rod and Star rod. Good rod has distinct black/charcoal art; Star rod has purple/gold star art. Names are source-backed, and existing serialized IDs, owned equipment, saved location choices and economy remain intact.

Acceptance: visible production-main-scene animation audit passed for all seven equipment variants and all 23 locations, including real catches and measured motion clearance. Location selector/switch/save/mastery regression, database/assets/UI/hygiene gates, and the required fourteen-screen audit passed. Stable raw 1080x1920 before/transition/settled proof and logs: `outputs/verification/fishing-active-animations/`. Upgrade generation provenance: `outputs/art/fishing-rod-upgrades/generation.json`. No release or phone build. Earlier full-project ad-import blocker remains unrelated. Details: [fishing verification](playtests/2026-10-22-fishing-tool-balance.md#active-fishing-animations-and-rod-upgrades-october-22).

### Rod material correction, October 22

Made Stick rod a brown wooden branch with a cut end, knot and twig stub. Changed Good rod's raised bands and tip cap to silver-gray while preserving its black shaft. Built-in ImageGen edits preserve the chunky silhouettes, heavy outlines, transparent backgrounds and existing asset paths. Corrected purchase cards and collection flights that still referenced the original bamboo art; all three tiers now use their matching selector art. Practice Pool uses the wooden Stick rod. Animation geometry, save IDs, equipment, choices and economy are unchanged.

Acceptance: repeated the visible production-main-scene fishing animation check for all seven tool variants and all 23 locations, plus all rod purchase cards. Inspected the new selector/active art, Practice Pool and each offer at raw 1080x1920. Database, runtime assets, UI boundary, test-harness and hygiene gates passed. Proof: `outputs/verification/fishing-rod-materials/`; exact prompts/references/final asset paths: `outputs/art/fishing-rod-materials/generation.json`. No release or install.

### October 22 Windows 0.7.2i testing

Built the latest horizontal Windows package and verified desktop resizing, navigation, social panels and save normalization. Fixed legacy desktop recovery resurrecting progress from before a newer deliberate reset, which caused save writes to be blocked. Regression checks and a copied-profile reproduction passed. Final artifacts and testing details: [Windows 0.7.2i check](playtests/2026-10-22-desktop-0.7.2i.md). No upload or deployment.

### October 22 phone Preview install

At Brian's request, built and installed the latest 0.7.2/code43 debug Preview on his Galaxy S24 Ultra, preserving the production package and existing Preview save. Confirmed launch and a clean startup capture/log. The phone disconnected before the scrolling and extended physical rendering checks. Applied the standard texture-import configuration to the seven new tool icons and five stale ad assets; the import contract now passes. Preview export metadata restores byte-for-byte and its app label is distinct. No release upload. Evidence and exact build paths: [phone Preview check](playtests/2026-10-22-phone-preview.md).

### October 22 evening feedback and live fishing iteration

Implemented the 17 new Brian Notes comments: jail tap cue; still portraits contained in squares; synchronized info collapse; combo help colors; Chat-edge navigation taps; lower/heavier XP symbols; opt-in Fishing help; ground-pond Practice Pool art; empty locked mastery outlines; wordless green-selected tool pill; current tool offer art; simpler success/rod help; and hands as the first-unlock Rocks recommendation.

Active fishing now has independent shafts/strings/bobbers and two three-frame splash variants. The owner chose curved side sheets with random left/right/both and front/back placement, 1.1–1.3-second outward rise/fall motion, 5% larger splash pieces, smaller rod splashes, and smaller active hands. Restored and raised the contact-water oval with the whole equipment origin. Smooth analytical water surfaces provide foreground immersion for net/hands/line. Water surfaces, ripples and splash colors read the area's existing fluid palette. Rate estimates are centered as a group with left-aligned value cells for consistent icon gaps.

Dedicated visible evening regression and fourteen-screen audit passed. A subsequent seven-tool/23-location animation audit passed after waiting for stage readiness instead of a fixed entry delay. The latest palette/immersion captures are under active owner review. Full-project validation still flags the fishing scrolling card-count budget; no full-suite pass is claimed. No release export or deployment. Evidence and current limitations: [evening feedback](playtests/2026-10-22-evening-feedback.md).

### October 22 final fishing composition and success strategy

Finished the owner-directed compact layout: opposite-side location squares, raised shared center animation, larger/lower centered heading, no bottom water bar, and center-only rate estimates during tool selection with a fade back to the active tool. Added shallow immersion, an opaque front surface, a black pool rim and curved equipment containment; reduced net/hands/rod scale and shifted rods left. Preserved saved per-location choices, default recommendations, tool economy, mastery outlines and existing art direction. The seven-tool/23-location geometry audit and production picker/fade checks passed.

Removed the unrequested 90% global success curve. All level 1-10 bases remain exactly as before. Individually reduced 119 later activity bases, preserving additive medals, equipment, Barn and trophy effects and all existing guarantees. The previous tier's Bronze reward still adds five accuracy points throughout the next tier, with meaningful headroom in later activities. Four progression-profile comparisons and all populated adjacent-tier reward checks passed. Evidence: `outputs/verification/success-base-oct22/`; report: `docs/playtests/2026-10-22-evening-feedback.md`. No release export or deployment.

## October 22 action-art framing

Reviewed all 173 permanent activity definitions and five events. Authored focal crops fill the portrait while preserving medal clearance and headroom; the same crop applies throughout each animation. Practice Kicking now uses a smooth blue figure without mud. Loot a Pirate Ship retains its large scale and moves down/right to clear the medal. Production proof and validation are recorded in `docs/playtests/2026-10-22-action-art.md`.

### October 23 splash synchronization

Splash launch follows the rendered tool or line leaving the surface on withdrawal, after interpolation, instead of the initial reach. Each exit fires once; a single right-side splash has no added delay. The boat wake follows its haul rock. All seven tools and a natural hands cycle passed focused timing checks. Evidence and raw frames: `docs/playtests/2026-10-23-fishing-splash-sync.md`.

Fish harvest now starts at the pool on the tool surface-exit event, rises quickly into a slower drift and fades. Hands/mirror withdrawal follows attempt completion. Tool wallets overlay their corner selectors on either side while leaving center rate estimates visible. Seven-tool timing, real harvest, both picker inputs and three boundary/harness checks passed; raw evidence is recorded in the October 23 fishing report.

October 23 follow-up: gear choices keep the wallet open and refresh selection, corner art and rates without rebuilding the screen; outside taps close it. Rod shafts are thinner and farther left, and the line follows the rendered rod tip during the pull-back.

### October 23 Halloween startup greeting

Integrated the approved Happy Halloween popup after loading and offline-summary handling. Any tap dismisses it without activating the game beneath. Skips first-time players and active onboarding; shows once per returning-player launch while active, ends at local November 1, 2026, and never saves a permanent dismissal flag. Portrait/desktop startup, repeated launch, art/backdrop taps, post-dismissal navigation, expired-startup and date-policy checks passed. Evidence: `docs/playtests/2026-10-23-halloween-greeting.md`.


## 0.7.2 additions requested October 23

- Click players' profiles in chat to see their stats.
- Improved fishing skill rework.
- UI improvements.
- Improved ad page.

Status: source changes and phone-preview iteration; production upload held. Chat profiles show published levels, XP and medals, with compact moderation controls. Unified 3D stamina/time ad-navigation artwork is integrated and verified on phone. Net entry splashes and larger catch splashes now match the water color, including sewers; independent lifetimes preserve both bursts. Focused real-game animation and physical chat-profile checks passed. Player-facing copy is in `play-store/docs/release-notes-0.7.2.txt`.

Follow-up source changes: centered the bottom navigation ribbon by giving all five buttons equal slot widths in gameplay and chat, using the default 92px size for the tightly framed ad icon so its visible width matches the padded star. Centers at 1080px width are now 152, 346, 540, 734 and 928. Removed Fishing Wisdom awards, book badges and unlock requirements; no other skill depends on Fishing Wisdom. Focused real-game checks passed. Evidence: `H:/Codex/Projects/IdleElite/outputs/fishing-without-wisdom-oct23-balanced/`. These follow-up changes have not yet been rebuilt onto the phone.

### October 24 fishing action corners

Moved every fishing location's tool selector to its own bottom-right corner and restored unlock-resource badges to the top-right corner of that same action square. Tool sizes, saved choices and module heights are unchanged. The wallet follows the new tool position. Real main-scene portrait checks passed for placement, separate touch targets, wallet opening/outside dismissal and starting River Bend. Raw 1080 x 1920 River and Sewers captures: `outputs/verification/fishing-corners-oct24/`. Source change only; no export or deployment for this follow-up. Covered by the existing UI improvements release-note bullet.

### October 24 mastery strategy and Building cadence

- Rebalanced early success rates so later activities benefit from Silver and Gold medals
- Doubled Building action costs, duration and rewards

Added bounded accuracy support from the preceding three eligible activities, preserved tier Bronze's next-tier +5 points, and included own medals in tool-based Fishing. First activities reach 100% with two opening Bronzes; second activities with two Silvers; third activities reach 99.5–99.8% with three Silvers and 100% with nearby Gold. Values vary by skill. Later-tier saturation checks preserve substantial headroom beyond Bronze.

Building's 29 ordinary activities double stamina, XP, seconds, mastery XP and progression-resource rewards. Recovery, saved progress and project targets remain intact. Database, medal-profile, recovery, offline-resource and save checks passed, with raw 1080 x 1920 production proof. Details: [mastery strategy verification](playtests/2026-10-24-mastery-strategy.md). Source only; not exported or published.

Fishing economy and real-input checks also passed. Fixed picker overlap with wider rate estimates and ensured unfinished estimate fades continue after slow frames. Raw before/transition/settled proof is included in the same verification folder.

October 24 bottom-clearance follow-up: raised both fishing location-square layouts by 24px, carrying their attached gear, medals and resource badges upward. Raised the temporary rate preview to keep its picker clearance. Module height and active center animation are unchanged. Visible production checks passed bottom clearance, corner attachment, wallet placement, outside dismissal and starting the activity; River and Sewers were visually inspected at raw 1080 x 1920. Proof: `outputs/verification/fishing-raised-corners-oct24/`. Source only; not published.

### Proposed connected production paths, October 24

Reviewed the owner's woodcutting advertisement captions and current Honey, Berries, Firepit, material-wallet and project systems. Drafted [connected production paths](connected-production-paths.md), starting with Sand → Glass → Bottles → deliberately activated Honey reserves, with further scouting, bait, wax/light and machinery options. The owner subsequently authorized all branches. The local implementation and its evidence are recorded below; it is not published.


### Connected production and animated modules, October 24

Implemented Sand, Glass, reusable Bottles and deliberately activated Honey reserves, plus Spyglass scouting, targeted Bait, Beeswax/Candles, Lantern exploration, Selective Net equipment and a finite Waterwheel processing queue. Shared Wooden Parts supply the Spyglass, Lantern, Waterwheel and Selective Net. Spyglass art shows only the front lens from the authored angle. New equipment keeps stable saved ownership, and prototype components and paid work migrate without another charge.

Added 14 production activities and retained 15 functional production presentations. Following owner review, 32 cosmetic replacements of legacy activities, including Pocket Couch Coins, were reverted to their standard cards. Special stages are no longer inserted simply to limit runs of ordinary cards. Existing tier/neighbor medal positions remain unchanged. Input escrow, partial bottle fills, activated duration, equipment, light charges, bait choices and queued jobs persist. Background jobs grant materials without XP.

Acceptance details and current evidence: [production implementation status](production-implementation-status.md). Source changes only; no export, upload or publication.

### Fishing location tool transfer, October 24

Selected tools now fly from their location square into the fishing animation, changing artwork during the move when needed. The active location's name and corner tool fade away, then return when stopped or replaced. The animated tool opens the location's picker. Transfers continue across card rebuilds and preserve all saved gear and gameplay values. See [runtime checks and raw frames](playtests/2026-10-24-fishing-tool-entry.md). Local source only, not published.

Follow-up: removed the default gray disabled-button rectangle left in the active location's tool slot and in the center stage during rate previews. Both hit buttons remain transparent in their disabled state. Local source only, not installed or published.

### Animated groves, slingshot practice and production layout, October 25

- Added animated woodcutting groves and axe upgrades
- Added slingshot practice with distance-based XP
- Improved Clear Rockslide visuals
- Improved production layouts and progress bars

Local source only; not published. Six groves preserve the purple Ancient tree and add Ironwood. Short stumps retain each tree's roots and scale. Generated rock damage sprites replace procedural cracks. All nine Building converters share the continuous V-cut rail. Level-50 desktop test starts with 1000 of every material. Evidence: `playtests/2026-10-25-groves-production.md`.

### Tier banners during temporary XP events, October 25

Fixed the final permanent tier banner disappearing when no later activity followed it, and temporary XP events creating banners for tiers without permanent mastery activities. Banners now follow the last permanent entry of each fully revealed mastery tier, once per tier. Thieving Tier 8 remains available without an event; a level-98 XP opportunity does not create Tier 9. Event insertion retains the existing Tier 8 control, and the tier remains available after the event is removed.

Validation passed: `scripts/test-tier-banner-events.ps1` across all five skills and nine event levels, its muted visible-game `-Capture` check, `scripts/test-tier-banner-scroll.ps1`, and `scripts/check-test-harness-contracts.ps1`. The event regression is included in `scripts/check-project.ps1`. Visually inspected raw 1080 x 1920 production screenshots: `outputs/verification/tier-banners-oct25/thieving-tier-8-no-event.png`, `thieving-tier-8-with-event.png`, and `thieving-tier-8-rewards.png`. Local source only; not built, installed or published.


### Axe shop presentation, October 25

The arena axe badge now reads Level followed by its number on a shallow curve along the circle. The component shop uses a large axe edited from the existing game icon, with distinct handle, head, grip, sharpening edge and gem. Selecting a physical piece shows its next level, benefit and material price. A separate Upgrade button makes the purchase; unavailable and maximum upgrades remain inspectable.

Preserved the component costs, effects and save keys. Input regions follow the pieces, with alpha-masked selection highlights. Touch and mouse checks passed for selection without spending, exact purchase cost, next-price refresh, prerequisites, insufficient materials, caps and dismissal. Portrait and desktop checks passed. Raw proof: `outputs/verification/axe-shop-oct25/`. Local source only; no release or publication.

October 25 axe-badge follow-up: thickened the curved Level text outline to 14px and replaced the small full-axe icon with a fixed 298px crop of the original artwork, clipped to the circle interior. The ring and progress arc remain above the artwork. Touch/mouse shop interaction and portrait/desktop checks passed. Raw 1080 x 1920 proof: `outputs/verification/axe-badge-zoom-oct25/arena-level.png`. Local source only.


### Oval woodcutting arenas and earlier stump clearance, October 25

All six groves use a wide oval ground plane with a generated shrub border around the back and sides. The front remains open. Tree roots and the worker map onto the oval while preserving saved world coordinates, authored animation scale, depth sorting, axe controls and arena upgrades. The surrounding card uses the existing paper palette.

Stumps fade over 0.35 seconds and clear before regrowth, leaving a gap of the smaller of 1.5 seconds or 30 percent of the regrowth interval. Tree replacement deadlines, harvest costs, XP, rewards and saved phases are unchanged. The stump shadow fades with it.

Passed headless grove/range gameplay checks, all six portrait arenas, real ground-tap chopping, the stump before/fade/clear/gap/regrowth sequence, shop input and native desktop capture. Raw evidence and result: `outputs/verification/grove-oval-oct25/`. Source only; no export or publication.


### Slingshot animation and stats, October 25

Replaced the two-pose slingshot with eight illustrated poses shared by Rockslide and Practice. Both elastic bands stay visible through draw, forward overshoot and recoil. The supporting arm bends, rises, dips and rebounds, with a fixed ground anchor. XP and stamina share a top row, alongside Sand in Rockslide. Existing reward accounting, fire cadence and saves are preserved.

Headless gameplay and muted actual-main checks passed, including all eight live poses in both cards and title/stat spacing. Raw 1080 x 1920 proof: `outputs/verification/slingshot-oct25/`. Details: `playtests/2026-10-25-slingshot-animation.md`. Local source only; not published.


### Arena presentation and slower slingshots, October 25

Rockslide now uses a 1.4s base firing interval with slower draw/recoil. Practice uses a 1.25s wind-up. Rockslide medals, red integrity dots, numeric health and floating damage numbers are removed. Generated damaged-rock states remain, along with the existing escape and reward rules. Green upgrade buttons center their title/value and material/price rows.

Groves use raised textured ovals without surrounding square shells, floating upgrades, and header rewards/costs. Workers fade out when inactive and reappear front-center before starting. The smaller axe badge reads LV with heavier outlines and circular text. Raw proof and checks: `playtests/2026-10-25-arena-polish.md`. Local source only, not published.


October 25 grove follow-up: two base trees, slower 20–40s regrowth, clearer Max trees / Regrowth / Rarity controls in light woodcutting green, heavier button outlines, bountiful same-tier trees with triple logs, sprite-count harvest feedback and a corrected single Ironwood log icon. The compact badge reads Lv with a shallow curve; the header has no enclosing box. Local source only. Evidence: `playtests/2026-10-25-arena-polish.md`.


October 25 local grove follow-up: side shrubs overlap edge trees, a soft shadow separates the axe badge, the header shows current log inventory, and the axe swing uses foot-grounded frames. Corrected the compile error that exposed the ordinary fallback card. Actual-main input and animation checks passed; evidence: playtests/2026-10-25-arena-polish.md. Not published.


### Woodcutting activity reveal fix, October 25

- Fixed missing Woodcutting activities after Prune Orchard Row

Local tested source: an unclaimed grove no longer hides the ordinary next activity or its Resin project. Actual-main legacy-save and touch unlock checks pass. Phone build prepared for installation when the Samsung reconnects. Evidence: playtests/2026-10-25-woodcutting-progression.md. Not published.

Woodcutting reveal fix installed on the Samsung Preview over Wi-Fi; existing save restored and physical rendering checked. Prior pending-phone status is superseded. Evidence: playtests/2026-10-25-woodcutting-progression.md.


October 25 grove audio: added varied wooden axe impacts and one quiet collection cue per harvest, synchronized to actual contact and reward grants. Muted/offscreen arenas remain silent. Actual-main timing/mix and grove gameplay checks passed. Evidence: playtests/2026-10-25-grove-audio.md.

Grove audio follow-up installed on the Samsung Preview over Wi-Fi and left open for testing. Existing save preserved.


### Bonus-yield tree indicator, October 25

- Added gold twinkles to trees with increased log output

Actual-main checks passed across all six arenas, including tree falling and harvested cleanup. Raw evidence: outputs/verification/grove-gold-oct25/. Local source only; phone updates held at Brian's explicit request.


### Grove upgrade balance, October 25

- Increased tree capacity upgrade prices
- Reduced tree regrowth upgrade strength

Capacity prices doubled; growth speed per Spawn upgrade reduced from 25 to 10 percent. Existing upgrade levels retained. Source contracts/audit and gameplay/input checks passed. Evidence: outputs/verification/grove-balance-oct25/. Local only; no phone update.


### Grove shrub depth, October 25

- Fixed trees and shrubs overlapping incorrectly

All 15 shrub clusters now share floor-depth sorting with trees and the worker. Actual-main front/behind and mixed-depth checks passed, with unchanged source artwork. Evidence: outputs/verification/grove-shrub-depth-oct25/. Local only; phone updates remain on hold.

### Grove walk cycle, October 25

- Improved the woodcutting worker's leg crossover while walking

Replaced both passing poses and preserved fixed foot grounding and character scale. Actual-main right/left loops and grove gameplay checks passed. Evidence: playtests/2026-10-25-grove-walk-crossing.md. Local only; no phone update.

### Grove upgrade button names, October 25

- Renamed woodcutting arena upgrades to Trees, Rate and Luck

Display labels only; upgrade behavior and save keys remain unchanged. Actual-main proof: outputs/verification/grove-button-luck-oct25/new-base-prices.png. Local only; phone unchanged.

### Axe shop inventory, October 25

- Show available resources for the selected axe upgrade

The owned count follows the selected component's next cost material and refreshes after spending or other inventory changes. Actual-main selection, purchase, Ironwood transition, empty/max states and portrait/desktop checks passed. Evidence: outputs/verification/axe-shop-inventory-oct25/. Local only; phone unchanged.

### Axe contact positioning, October 25

- Positioned the woodcutting worker so the axe meets the tree trunk

Stopping distance follows trunk shape, bonus-tree size and arena perspective from both sides. Actual-main contact captures and grove gameplay checks passed. Evidence: outputs/verification/grove-axe-contact-oct25/final/. Local only; no phone update.

### Rockslide idle recovery, October 25

- Tap Rockslide resources to see their names
- Rockslide automatically restarts at wave one after a knockout countdown

Five-second recovery retains upgrades and earned rewards, including while the module is offscreen. Saved knockouts resume safely and manually stopping cancels recovery. Source contracts, gameplay and real-main input/animation checks passed. Evidence: playtests/2026-10-25-rockslide-idle.md. Local only; phone unchanged.

### Rockslide opening balance and variety, October 25

- Added fast stones, armored boulders and mixed rock patterns
- Rebalanced Rockslide upgrades and early difficulty
- Fixed rolling rocks floating above the hillside

Existing paid upgrades retained; later purchases now use crafted parts and later wood. Combat simulation and actual-main rolling, resource input and knockout recovery checks passed. Evidence: playtests/2026-10-25-rockslide-balance.md. Local only; phone unchanged.

### Hub upgrades, October 25

- Made hub construction signs smaller and consistent
- Reduced hub building sizes
- Fixed upgrades getting stuck with invalid construction timers

Real-main tier, input and mission construction recovery checks passed. Evidence: playtests/2026-10-25-hub-upgrade-audit.md. Local only; phone unchanged.

### Grove gold leaves, October 25

- Replaced tree stars with simple gold leaves
- Added three gold-leaf harvest bonus levels

One, two and three leaves indicate +25%, +75% and +200% logs. Existing saved bonus trees retain their full bonus. Reward, save and actual-main visual checks passed. Evidence: playtests/2026-10-25-grove-gold-leaves.md. Local only; phone unchanged.

### Gathering boxes and factory header, October 25

- Centered Melt Sand XP and time at the top
- Added collection boxes and harvest animations for Sand and Beeswax gathering

Shared gathering feedback now works independently of tier-medal exemptions. Added a Sand box background. Production and actual-main input/reward checks passed. Evidence: playtests/2026-10-25-sand-collection.md. Local only; phone unchanged.

### Melt Sand inventories, October 25

- Added live Sand and Scrapwood inventories above Melt Sand and Glass below
- Compressed the Melt Sand recipe into one icon row

Owned amounts update with spending and production. Selecting or running the factory opens the inventory boxes, and completed Glass moves into the output box. Recipe payment, missing-input and previous gathering checks passed. Evidence: playtests/2026-10-25-factory-inventories.md. Local only; phone unchanged.

### Contour progress fills, October 25

- Made production and rest progress fills follow their bar contours

Fill edges rotate with the slope and advance by path distance, with continuous turns at production V corners. Geometry, turnover and real-main animation checks passed. Evidence: playtests/2026-10-25-contour-progress.md. Local only; phone unchanged.

### Gold leaf size and placement, October 25

- Reduced gold leaf size and kept leaves clear of tree outlines

Fixed 36px draw boxes and individual anchors for all six tree types. Every leaf pixel passed ink/edge clearance checks at all three authored tree sizes. Actual-main standing, fall and harvest frames passed. Evidence: playtests/2026-10-25-grove-leaf-clearance.md. Local only; phone unchanged.

### Sand scooping animation, October 25

- Added a blue guy scooping animation to Gather Sand

Six generated body/shovel poses follow actual gathering progress and hold a ready pose when stopped. Existing resource collection and rewards are preserved. Actual-main start, all poses, reward and stop checks passed. Evidence: playtests/2026-10-25-sand-scooping.md. Local only; phone unchanged.

### Factory output connector, October 25

- Fixed the gap between Melt Sand and its Glass inventory

The line now reaches the actual rear V tip behind the card, outside the inventory clip. Real-main endpoint, rendered-pixel, recipe and stop checks passed. Evidence: playtests/2026-10-25-factory-output-connector.md. Local only; phone unchanged.

### Sand-only Glass and pouring frames, October 25

- Removed wood from the Glass recipe
- Added more sand-carrying and pouring animation frames

Melt Sand consumes 2 Sand for 1 Glass and shows one input inventory. Exact old paid batches and queued work migrate without another payment. Gather Sand uses extra carry/reach/tip/recovery poses and four independent falling-Sand frames. Production, save compatibility, actual-main visual and animation-effect regression checks passed. Evidence: playtests/2026-10-25-sand-only-glass.md and playtests/2026-10-25-sand-pouring.md. Local only; phone unchanged.

### Practice Slingshot draft, October 25

- Reworked Practice Slingshot with a shooting range, distance records and optional timed releases

The normal rounded module contains a smaller grounded shooter, eight poses, real distance pegs, a tracking camera, parallax terrain and independent landing dust/rebounds. Automatic play remains. Full-draw taps add eighteen percent range; stamina pays once and XP pays on first contact. Existing records, landing counts and paid airborne saves remain compatible. Focused gameplay, actual-main animation/touch and Fighting screen-audit checks passed. Evidence: playtests/2026-10-25-slingshot-range-rework.md. Local draft only; phone unchanged.

### Production click window rounding, October 25

- Rounded production click windows through bends and at both ends

The outlined ribbon stays smooth around both shoulders and the V tip. Live and green/red feedback share the geometry; repeated stationary draws cannot move its cached outline. Timing and click boundaries are unchanged. Geometry sweeps, consecutive real-main frames, pixel continuity, contour regressions and Building screen checks are recorded in playtests/2026-10-25-production-window-rounding.md. Local only; phone unchanged.

### Glass icon repair, October 25

- Fixed the transparent patch in the Glass icon

Preserved the original silhouette, palette, reflection and black outline. Actual-main wooden inventory and white recipe input captures confirm the repair. Evidence: playtests/2026-10-25-glass-center.md. Local only; phone unchanged.


## October 25 slingshot playtest feedback

- Removed the Slingshot XP range, repeated tutorial arrow and manual timing bonus
- Reduced new-shot XP to 2 plus 0.08 per meter, retaining exact rewards for paid airborne saves
- Audited release-time stamina payment, duplicate calls, regeneration, exhaustion and restoration; each launch pays once and now shows its exact debit
- Added a bottom-anchored record-flag move/overshoot/settle and removed the duplicate waiting PB label
- Matched static header icons to numeral height with a 4px gap in Slingshot, Rockslide, Grove and converter headers
- Fight the Current was inspected only: eight successful completions unlock Waterwheel repair, which enables a 12-job prepaid crafting queue
- Validation and raw real-main captures: docs/playtests/2026-10-25-slingshot-feedback.md
- No Android export, installation or external publication for this revision


## October 26 shared collection feedback

- Candy and ordinary material rewards now publish the same live collection receipt after the actual inventory credit
- Standard item holders share one animation rule; removed the candy-specific animation inference and ordinary-material early-return dependency
- Items follow their moving holder, finish the drop before fading and pulse the holder on arrival
- Failed/zero/capped/offline credits do not create false drops; receipts retain per-item berry harvest counts
- Audited all fifteen standard-holder activities through the real UI plus material/seasonal accounting and factory reward regressions
- Test previews default to the silent audio driver, with post-startup bus/music/SFX mute in the shared capture harness
- Evidence and validation: docs/playtests/2026-10-26-shared-collection-feedback.md
- Local implementation only; no phone update or external publication


## October 26 factory layout and bounce sequence

- Removed the compact Melt Sand recipe strip and unified all nine production converters around full input/output action boxes
- Put XP/time at the top right and attached the medal to the output action box's top-left corner
- All converter inventories open above/below, including one box for each of up to three actual ingredients
- Ingredient icons hop down to the left input, convert in a higher hop to the right output, then hop down into the lower output inventory
- Opening the full inventory group fits it between the skill header and bottom utility controls; V-to-output connectors remain continuous
- Original factory art stays hidden through UI updates and critical effects use the displayed output icon
- Recipes, input payment, output amounts, completion timing and saved progress are unchanged
- Silent actual-main visual/accounting checks and evidence: docs/playtests/2026-10-26-factory-layout-and-bounces.md
- No Android export, phone installation or external publication


## October 26 single-choice factory input

- A plain output box or output inventory starts its sole recipe immediately without a one-choice popup
- Repeated taps preserve the active batch and do not charge inputs again
- Waterwheel queue and owned equipment menus remain available when they contain additional controls
- Queue eligibility is shared between the menu and queue runtime
- Validation: production_converter.gd and factory_inventory_capture.gd, with muted real-main screenshots
- Local changes only, no phone installation or publication

## October 26 glass furnace backgrounds

- Added distinct melting and glassworking furnace backgrounds to Melt Sand and Shape Bottles
- Kept existing production controls, recipes and animations
- Passed muted real-main checks for both activities at 1080 by 1920
- Evidence: docs/playtests/2026-10-26-glass-furnaces.md

## October 26 Gather Sand Fishing XP

- Gather Sand now awards 1 base Fishing XP alongside its existing 12 Building XP and 2 Sand
- Uses the shared cross-skill reward pipeline for live and offline progress
- Database checks and muted real-main harvesting tests passed
- Evidence: outputs/verification/sand-fishing-xp-oct26

## October 26 Building progression order

- Moved Gather Sand to third, followed by Saw Planks, Patch Fence and Study Blueprint
- Moved Melt Sand after Sharpen the Pencil and Shape Bottles below the Tier 1 banner
- Adjusted early Building level gates and preserved other skill requirements and later progression
- Validation: docs/playtests/2026-10-26-building-order.md

## October 26 Honey bottling

- Restored Loot Beehive's regular activity card and Honey collection holder
- Added bottle input and separate Honey/Bottled Honey outputs after acquiring bottles
- Added independent saved bottling and automatic-use toggles
- One hand fills one bottle for the same ten-second effect, with automatic raw-honey fallback
- Preserved old full bottles, active effects and partially filled jars
- Validation: docs/playtests/2026-10-26-honey-bottling.md

## October 26 page swiping and factory quantities

- Fixed repeated neighbor-page preparation waits and prioritized the swipe direction
- Prepared tree-arena button layout before the page slides in
- Measured median post-release wait at 118 ms versus 685 ms before the fix in fourteen desktop swipes
- Moved factory quantities into lower-right action-box badges without increasing module height
- Verified all nine factories, including two-digit and three-ingredient recipes
- Evidence: docs/playtests/2026-10-26-swipe-latency.md and 2026-10-26-factory-quantities.md
