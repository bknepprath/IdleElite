# 0.7.0 patch-notes tracker

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
