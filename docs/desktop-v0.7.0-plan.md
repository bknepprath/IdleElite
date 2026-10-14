# Idle Elite v0.7.0: desktop web layout

Date: October 11, 2026.

Current status: development iteration. Brian rejected the initial desktop presentation and asked for further in-game UI work. The earlier exported packages are unapproved and superseded by source changes. Do not prepare another release candidate until explicitly requested. The current direction uses the mobile icon ribbon at the bottom, skill titles as selectors, continuous header color, and a left building inspector with optional chat on the right.

The next release incorporates the prepared v0.6.2 stability changes and establishes a permanent desktop layout for itch.io. The production desktop layout is implemented and Windows/Web release candidates have been built. The validation report is `docs/playtests/2026-10-11-desktop-v0.7.0.md`. Existing signed v0.6.2 Android artifacts remain unchanged.

## Layout

Use a responsive landscape layout with a 1600x900 preferred native startup window, fitted inside the monitor work area including window borders and the taskbar. Real-game resize checks now cover 800x600, 1000x600, 1280x720, 1366x768, 1920x1080, 2560x1440, 3440x1440 and 3840x2160, plus native fullscreen. At these sizes, 800x600 shows one column; 1000x600 through 1366x768 show two; full HD and larger show three. Optional social panels consume available column space. Browser zoom, itch.io iframe/fullscreen and physical Windows DPI changes remain acceptance checks. The design reference is not a fixed browser-window requirement. Extra width belongs to gameplay. Keep navigation compact and Settings in one existing menu; do not allocate either side to permanent settings or utility navigation. Retain a compact portrait fallback for phone browsers. Android retains its current 1080x1920 viewport, viewport stretch mode, and renderer.

| View | Gameplay area | Optional side panel |
| --- | --- | --- |
| Skills, default | Up to three full skill pages side by side, each independently scrollable and interactive | Closed |
| Skills, social panel open | One or two full skill pages according to available space | Chat / High Scores toggle |
| Player hub | The existing hub scene uses the wider gameplay area, with more room for existing buildings, characters, and interactions | Optional; reclaim the full width when closed |

Three pages means usable production skill pages, not narrow previews or summary cards. Preserve each page's selected activity and scroll position when changing visible skills or opening the social panel. The number of simultaneously active activities and all reward rules remain unchanged. At smaller widths, reduce the visible page count instead of shrinking text below readable sizes.

The user has not decided whether chat should be a permanent fixture. For the first implementation, keep the social panel closed by default and allow an explicit open/close action with Chat / High Scores tabs. A permanently visible panel remains an undecided option, not a release requirement. Do not create extra settings or persistent utility columns to occupy unused space.

Activity columns have a 1024 physical-pixel and 1550 canvas-unit width cap; unused width becomes outer margins. Compact desktop headers reclaim spacing around the existing gauge and text to prevent clipping at 4K. Existing linear/mipmap filtering remains in place. The existing activity art keeps its authored proportions. Extra width makes related controls visible together. Mouse-wheel scrolling, keyboard focus, direct skill selection, resize recovery, browser zoom, and fullscreen need explicit desktop treatment. The existing gameplay rules, progression rates, rewards, and content remain shared.

itch.io supports both a specified embedded viewport and a fullscreen launch mode. Its documentation recommends adapting the game canvas to the available viewport. Use fullscreen launch as the primary desktop experience with a usable embedded fallback. [itch.io HTML5 documentation](https://itch.io/docs/creators/html5)

## Code and compatibility findings

- `scripts/main.gd` defines `BASE_CANVAS` as 1080x1920 and `_skill_content_width()` always derives width from that portrait canvas.
- `scripts/ui/navigation_shell.gd` uses a 210-unit bottom navigation area and some portrait-height positioning. Swipes, overlays, tutorial targets, scroll limits, and cached neighbour pages need layout-aware bounds.
- `export_presets.cfg` already uses adaptive web canvas resizing. Changing that setting or the viewport alone would not redistribute the controls.
- `scripts/build-itch-release.ps1` already prepares a separate web asset build with lossy texture imports. Preserve separate Android export guards; put web-specific layout selection in a platform feature/layout policy rather than changing the shared Android defaults.
- Keep one simulation and save owner. Desktop panels are views of the same state; displaying multiple skills must not run duplicate timers or multiply rewards.
- Keep the same Firebase project, score categories, identity safeguards, conflict rules, and score submission cadence. Layout does not require a new leaderboard.
- Shared scores are different from cross-device account continuity. `_ensure_google_auth_plugin()` currently supports Android only. Reliable Android-to-browser Google login/cloud continuation requires separate browser authentication work and iframe/storage testing; do not claim a layout change provides it.
- Preserve browser save location and import compatibility. Reuse the existing itch project; verify update/reload with an existing save and cleared/blocked browser storage.

## Costs and sacrifices

| Area | Cost or tradeoff | Control |
| --- | --- | --- |
| Implementation | A substantial UI refactor, including simultaneous skill views, shared selection state, overlays, and tutorials | Prove three interactive production skill pages and a wider hub before converting the remaining screens |
| Maintenance | Two layouts require ongoing regression coverage | One gameplay core, explicit platform layout policies, shared controls where appropriate |
| Performance | More visible cards and animations can worsen the existing scroll/swipe timing failures | Virtualize lists, mount only visible panels, keep one animation per visible item, measure browser performance |
| Visual design | Portrait art and oversized touch controls do not automatically fit a desktop grid | Preserve art proportions; author desktop spacing and text sizes; validate in the production scene |
| Small screens | A fixed landscape-only policy would reduce phone-browser usability | Keep a compact fallback while making desktop landscape the default |
| Backend | Width alone adds no required backend service, but more users or continuous chat/score reads can increase usage | Reuse caches and request gates; do not poll hidden tabs or raise refresh rates |
| Competitive balance | Better visibility and faster navigation may help desktop players | Keep progression, rewards, offline caps, and simulation identical; no desktop automation bonus |
| Release timing | Combining the stability fixes with a layout rewrite delays their release and enlarges the regression surface | Retain the verified stability candidate and use its tests throughout v0.7.0 |

The implemented scope covers simultaneous skills, optional social panels, and the wide hub. Shop, Settings, Progress, Queue, and Pinned retain their existing controls under the desktop navigation. Browser account linking, YouTube certification, and full cross-platform release acceptance remain separate work. No additional hosting service is required by the layout itself; actual backend costs depend on traffic and chat use.

## Implementation order and acceptance

Fishing regression carried into this release: Ham reported on October 11 that timing-box taps stop a fishing activity; Brian identified Fight A Shark. The fishing page bypasses the generic card input router, so its standard activity cards must handle opportunity hits and misses before the release-to-toggle path. Preserve native fishing-location controls and queue selection. Regression coverage includes Practice Pool and Fight A Shark with mouse and touch input, successful and missed timing attempts, release after the timing window changes, and emulated pointer duplicates.

1. Carry forward all stability fixes and regression tests. Add a web desktop layout policy without changing Android rendering defaults.
2. Implement three interactive skill pages side by side, two pages with the optional Chat / High Scores panel, and the wider production hub. Inspect raw production-game captures at 1280x720 and 1920x1080, including any readability-driven smaller-window fallback. Verify independent scrolling, page selection, retained state, and unchanged simulation. Any proposal diagram is not implementation proof.
3. Convert remaining skills, Hub, shop, achievements, settings, tutorials, modals, pinned activities, queue, chat, and high scores. Test resize and fullscreen during interactions.
4. Verify existing-save migration and identical reward/score outcomes from identical input sequences on both layouts. Audit identity and cloud guards; decide browser account-linking scope explicitly.
5. Run real browser sessions with active gameplay and optional online panels for 30 minutes, plus background/resume, outside-window release, keyboard input, and browser zoom checks. Resolve or explicitly block on remaining timing failures.
6. Repeat Android save/lifecycle regression tests and physical Samsung acceptance. Produce v0.7.0 artifacts only after the desktop implementation is verified. Builds are authorized; publication has not been authorized.

## YouTube Playables feasibility

Godot web exports are supported in principle. Developer access is still early access, and the developer portal is invitation-only. Apply for consideration through the official interest form; an existing YouTube channel alone does not establish access. [Overview](https://developers.google.com/youtube/gaming/playables), [developer portal](https://developers.google.com/youtube/gaming/playables/developer_portal).

The standard privacy rules prohibit external service calls and login/account-creation interfaces. Accordingly, the current Firebase leaderboard, cloud account flow, and global chat cannot be carried into an ordinary Playables build unchanged. Firebase being a Google product does not make this game's database an automatically permitted API. YouTube describes a remote-data pilot for selected titles; access and allowed integrations would need explicit confirmation. [Privacy requirements](https://developers.google.com/youtube/gaming/playables/certification/requirements_privacydata), [remote-data FAQ](https://developers.google.com/youtube/gaming/playables/support/certification_faq).

A normal YouTube port would use the Playables SDK for readiness, pause/resume, audio state, load/save data, and optional score reporting. That is separate from the existing cross-platform score service. [SDK integration](https://developers.google.com/youtube/gaming/playables/reference/getting_started).

The current normative limits are initial transfer below 30 MiB, individual files below 30 MiB, total bundle below 250 MiB by default, saves below 3 MiB, and peak JavaScript heap at most 512 MB. The initial bundle should be below 15 MiB. The prose requirements take precedence over the page's inconsistent generated summary. [Stability requirements](https://developers.google.com/youtube/gaming/playables/certification/requirements_stability).

The inspected optimized October 10 itch ZIP contains a 49,411,708-byte `index.pck` (47,790,157 bytes ZIP-compressed) and a 39,513,091-byte `index.wasm` (10,263,382 bytes ZIP-compressed). This is a previous web build, not a new v0.7.0 export. Its PCK exceeds the individual-file limit even compressed; the current monolithic startup is also too large as a first-load candidate. A YouTube port needs a smaller engine build and/or supported asset splitting and lazy loading, verified in YouTube's test suite. Splitting files without changing the loader is insufficient.

YouTube has built-in ad APIs, including earned-result checks for rewarded ads, but revenue sharing remains a selected-creator pilot. Do not assume admission or revenue. [Monetization](https://developers.google.com/youtube/gaming/playables/reference/monetization).

Recommendation: make v0.7.0 the shared-score desktop itch release. Treat YouTube as a separate feasibility track, with admission and remote-data permission determined before committing to a port that promises the same high scores.
