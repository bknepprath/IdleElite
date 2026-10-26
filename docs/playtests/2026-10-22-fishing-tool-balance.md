# Fishing tool clarity and economy, October 22, 2026

Implemented in the active 1080p checkout after Brian approved the fishing plan. No release export, phone install, commit, or online deployment was performed. Existing unrelated work remains intact.


Current revision: broad heavy-outline tool icons use chunky silhouettes. Hands retain the established blue mitten form with no individual fingers. Area headings are top-right, location labels are centered, and area height is 528px. Active equipment uses a clear right lane with cast, dip, lift, bob, ripple, and splash motion. Rod tiers are a brown wooden Stick rod, black Good rod with silver-gray bands, and purple/gold Star rod. Latest rod material proof is under `outputs/verification/fishing-rod-materials/`; the animation rebuild proof remains under `outputs/verification/fishing-active-animations/`, and the approved selector layout proof remains under `outputs/verification/fishing-chunky-tools/`. The rejected thin miniature art is archived outside game assets.

## Behavior

- Each individual location square has an attached frameless 104px tool button with a 92px icon and its own saved selection. River Bend and Rapids may use different tools. Food/min and XP/min use that location's choice before starting. Mastery uses the original 0.7.0 outline around each artwork square, with straight bars hidden. Tiny compatibility icons are removed and the header circle only displays food.
- Net gives more food and less XP than every rod at shared locations. Hands remain the free starter. Rocks accepts hands/net. Sea, Stormy Sea, and Deep Sea require boat; Starlight and Reflection require mirror. Unsupported tools show zero rates and cannot start or use the starter success guarantee to earn rewards. A deliberate switch away from an active location's required tool stops that activity. An incompatible old running state stops on the next live tick.
- Successful food awards use a 0.15 multiplier, including standalone combo food ranges. Direct currency and ordinary catch payouts share the rule. XP and timing for still-compatible tools are unchanged. Existing food balances and owned equipment are preserved on restore; no save key was renamed.
- Corrected the space-ID check to recognize the actual Starlight/Reflection IDs. Space base food values are 0.2 and 0.125 before the global 0.15 multiplier, keeping corrected mirror earnings within the reduced late-game economy.
- Food prices are now Stick rod 100, Good rod 5,000, Star rod 25,000, and mirror 100,000. Boat remains 1,000 Softwood with Fishing 50 and Building 30 required. Purchase handlers and displayed prices use the source rules; fractional balances below a price cannot buy the item.
- Standalone combos and Practice Pool ignore tool restrictions. Live and offline food match. Fixed offline Fishing combos dropping secondary-skill XP; each rewarded skill now receives its normal offline share under the unchanged 30% XP policy and integer rounding.
- Cached gameplay stats and expected rates now refresh when the ad bonus changes between 14%, 12%, 10%, and zero. Previously the cache distinguished only active/inactive ad bonuses.
- Tool help now states the net/rod tradeoff and specialist areas. Nets and boats haul automatically.

## Source and calculation

`docs/activity-database.json` was edited first. `global_rules.fishing` is authoritative for output, per-catch food values, prices, specialist areas, and per-location tool limits; the catalog configures FishingState from this data. Existing serialized food, equipment, and action IDs remain intact.

Expected rates use real long-run success chance, expected reward per success, and actual cycle duration at current bonuses. Net/boat thresholds delay payouts but retain every catch, including overflow, so they do not change long-run yield. Haul visuals overlap attempts rather than adding a separate gameplay pause. The display does not sample recent catches or use partial storage to inflate the rate. Fishing does not spend stamina; the displayed XP rate is live XP, with offline XP handled separately by its existing policy.

Fishing area height is 528px so each location has room for original-size artwork, attached corner tool buttons, resource/book badges, the original wrapping mastery outline, and readable rate rows. Tiny compatibility icons were removed in the subsequent area-selector revision. Existing artwork, viewport, stretch mode, renderer, and Android graphics settings are unchanged.

## Measured output

Captured the original 161 tool/location combinations before changing the runtime. The regression compares compatible non-space XP against that fixture and verifies the 0.15 food ratio. Space and newly incompatible specialists are checked separately. The matrix character and bonuses are identical before/after. Checkpoints assume tools are collected when their existing level gates allow them, with Building 30 available at the boat checkpoint. They evaluate available methods at each Fishing level, excluding standalone activities.

| Fishing level | Previous best food/min | Current best food/min | Reduction |
| --- | ---: | ---: | ---: |
| 3 | 12.075 | 1.811 | 85.00% |
| 18 | 39.375 | 5.906 | 85.00% |
| 30 | 39.375 | 5.906 | 85.00% |
| 45 | 39.375 | 5.906 | 85.00% |
| 50 | 209.250 | 24.587 | 88.25% |
| 85 | 259.935 | 38.990 | 85.00% |
| 90 | 289.462 | 43.419 | 85.00% |
| 95 | 289.462 | 43.419 | 85.00% |

The full matrix and checkpoint selections are saved in `outputs/verification/fishing-tool-balance/rates-and-checkpoints.json`. The historical regression fixture is `scripts/tests/fixtures/fishing-rates-before-2026-10-22.json`.

## Verification

- `scripts/test-fishing-tool-balance.ps1 -VisibleGame`: passed with failures=[]. Checks 161 combinations, each compatible net/rod comparison, 80,000 simulated attempts across net/rod/boat/mirror, 300 paired seeded live/offline attempts, secondary-skill XP, actual purchase handlers, fractional purchase boundaries, saved balances/equipment, unsupported starter guarantees, auto-eating, and ad-tier cache refresh. Uses the production main scene and actual touch navigation/wallet/start/stop controls.
- Actual simulated food/min vs prediction: net River Bend 5.486 vs 5.631; rod River Bend 1.545 vs 1.544; boat Open Water 34.430 vs 34.736; mirror Reflection 23.471 vs 23.612. All food and XP predictions were within 5% across 20,000 attempts per case.
- The screenshot character uses level 99 and maximum Fishing medals to check large values and real rendering; these UI numbers intentionally differ from the fixed pre-change balance matrix. Switching tools keeps the same screenshot character and location.
- `scripts/test-fishing-tool-balance.ps1 -VisibleGame -HelpOnly`: passed; actual information controls and all four updated help bodies were captured and inspected.
- Feedback/Practice Pool, October 21 gameplay/recovery, module-list/pin/queue interactions, and save-normalization regressions passed. Updated the Practice Pool queue test to equip a compatible shore tool after its specialist checks.
- Activity database contract/audit, UI boundaries, activity UI boundaries, native-1080, runtime paths, generated-file hygiene, test harness, performance regressions, crash audit/recovery, and the Firepit regression passed.
- Fourteen-screen capture audit passed at 1080x1920 under `.codex-tmp/fishing-clarity-screen-audit`.
- Full project validation stopped at the same pre-existing stale performance import settings for five ad-page assets: blue-book backdrop, backdrop-v2, frame-v1, hero-powered-up, and hero-v1. Those unrelated imports were not changed; full-suite success is not claimed.
- Previews used the Dummy audio driver and sandboxed save state with writes/online requests disabled. Final process checks found no Godot instance remaining. No physical-device or release acceptance is claimed.

## Raw proof

All delivery PNGs are unchanged 1080x1920 viewport captures from the production main scene. SHA-256 hashes in `outputs/verification/fishing-tool-balance/manifest.json` confirm byte-identical copies of the inspected raw captures.

### Net: food-focused rates

![Net: food-focused rates](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/river-net.png>)

### Rod: XP-focused rates

![Rod: XP-focused rates](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/river-rod.png>)

### Rates remain visible during fishing

![Rates remain visible during fishing](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/river-net-running.png>)

### Boat at offshore locations

![Boat at offshore locations](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/offshore-boat.png>)

### Zero output with unsuitable space equipment

![Zero output with unsuitable space equipment](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/space-without-mirror.png>)

### Mirror at space locations

![Mirror at space locations](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/space-mirror.png>)

### Bamboo rod price: 100 food

![Bamboo rod price: 100 food](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/price-rod.png>)

### Reinforced rod price: 5,000 food

![Reinforced rod price: 5,000 food](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/price-reinforced_rod.png>)

### Star rod price: 25,000 food

![Star rod price: 25,000 food](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/price-star_rod.png>)

### Mirror price: 100,000 food

![Mirror price: 100,000 food](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/price-mirror.png>)

### Net help

![Net help](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/tool-help-net.png>)

### Rod help

![Rod help](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/tool-help-line.png>)

### Boat help

![Boat help](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/tool-help-boat.png>)

### Mirror help

![Mirror help](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-tool-balance/tool-help-mirror.png>)


## Area tool selector revision, October 22

Brian approved taller modules after the initial compact revision and requested a large circular selector saved separately for every area box. The final button is 168x168px with a 136x136px icon; the existing 205px location artwork is retained. Every box previews its selected tool without starting an activity. Food and XP use fixed icon columns. Tiny compatible-tool strips are removed, rectangular mastery progress is restored for unfinished mastery, and the header circle only displays food. Existing bottom water and side-tool animations remain in production.

Selections are stored in `selected_fishing_area_tools`, keyed by source area and box index. Split Reef boxes can retain different tools. Starting a location equips its saved box tool. Editing an idle box does not change a different running box; editing the active box changes its running tool. Legacy equipped-tool saves initialize sensible compatible defaults. Save normalization rejects invalid areas, indices, and tools and carries rod choices to the owned upgrade.

Validation: the visible main-scene module test passed touch selection, rate refresh before starting, independent selections, split-Reef selections, active equipment changes, save roundtrip, malformed save normalization, and retained water/side-tool layers. The full 161-combination fishing balance/reward regression, native tool/purchase touch regression, save normalization, UI/source/test-harness contracts, and fourteen-screen audit passed after this revision. The full project suite retains its previously documented unrelated ad-import blocker. All captures below are raw 1080x1920 production-game viewports.

### Independent area tools and partial mastery

![Independent area tools and partial mastery](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/modules-net-and-rod.png>)

### Area tool picker

![Area tool picker](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/module-tool-picker.png>)

### Changed tool preview

![Changed tool preview](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/module-river-rod.png>)

### Net start

![Net start](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/module-net-start.png>)

### Net transition

![Net transition](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/module-net-transition.png>)

### Net running

![Net running](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/module-net-running.png>)

### Rod running

![Rod running](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/module-rod-running.png>)

### Boat area

![Boat area](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/module-boat.png>)

### Mirror area

![Mirror area](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-area-tools/module-mirror.png>)


## Location-square revision, October 22

Brian clarified that each individual location square needs a tool selector, independently of its neighbour in the same area module. The 168px circular button is attached to that square's upper-right corner and retains a 136px tool icon. River Bend and Rapids now independently choose, preview and save their tools. Editing an idle location does not change another running location's equipment. The picker only offers tools compatible with that location. Legacy region/box save keys expand to their locations, with explicit location choices taking priority. Existing save field names remain compatible.

Restored `ActivityCardStyles.action_art_mastery_ring()` and the existing normal mastery update path directly from the 0.7.0 implementation (also verified in commit `fbb3b35a`). The straight bars stay hidden. The ring retains its existing fill animation. No replacement mastery artwork or drawing logic was added. Spacing keeps resource/book badges and adjacent medals separate from the tool controls. Area boxes are 560px tall, as authorized. Water and side-tool animation remain.

The visible production-main-scene regression passed independent neighbouring choices, pre-start rates, actual touch selection, active tool changes, editing Rapids while River Bend runs, save roundtrip, legacy save migration, partial square mastery, resource/book badge clearance, and water/side-tool layers. All PNGs are raw 1080x1920 viewports.

### Independent location tools and 0.7.0 mastery outlines

![Independent location tools and 0.7.0 mastery outlines](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-location-tools/location-tools-and-mastery.png>)

### Location tool picker

![Location tool picker](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-location-tools/location-tool-picker.png>)

### Book badge clearance

![Book badge clearance](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-location-tools/location-buttons-with-badges.png>)

### Running water and side tool

![Running water and side tool](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-location-tools/location-net-running.png>)


## Frameless tool art and mastery padding, October 22

Removed the circular tool background and kept a 144x144px transparent touch target with a 136px icon for every location. Updated five selector-only tool images through the built-in ImageGen edit workflow: darker fills, stronger pure-black outer/internal strokes, and opaque black net openings. Sources preserve their recognizable tool designs and transparent outer backgrounds. Style anchor: approved `assets/content/ui/shop-icon.png`; subject references: the five original fishing-tool images. The selector applies a further 0.85 RGB tint. Original active-tool animation assets remain unchanged. Generated selector assets are project-local `assets/content/fishing/tools/selector-*-black-stroke.png`; originals and saved tool choices are preserved.

Location squares moved upward 42px from the preceding layout; area height is 548px. An explicit 32px spacer plus container separation leaves at least 20px between the full mastery outline bounds and the rate panel. Tools sit clear of their mastery outline and neighbouring medals. Spacing was checked for every medal level, including wide winged medals. Book/resource badges have separate clearance from the outline and selector. The water strip and side-tool animation remain.

The visible real-main-scene regression passed native tool taps, independent selection, save/reload, active/idle isolation, legacy selection migration, empty selector backgrounds, mastery/rate padding, all twenty neighbouring medal sizes, and real book/resource badge clearance. UI/source/test-harness and generated-file hygiene checks passed. No release package or rendering-setting change.

### Frameless net and rod with mastery padding

![Frameless net and rod with mastery padding](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-frameless-tools/frameless-tools-and-mastery.png>)

### Book and lure badge clearance

![Book and lure badge clearance](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-frameless-tools/location-buttons-with-badges.png>)

### Water strip and side-tool animation

![Water strip and side-tool animation](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-frameless-tools/location-net-running.png>)

### Boat selector

![Boat selector](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-frameless-tools/location-boat.png>)

### Mirror selector

![Mirror selector](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-frameless-tools/location-mirror.png>)


## Original-art corner badges and first-unlock defaults, October 22

Supersedes the generated selector artwork and detached selector positions above. The tool button now straddles the exact top-right corner of its individual location square. It has no circle or plate. It retains a 144px hit target and 136px icon. This corner overlap is intentional, as Brian clarified by comparison with resource and book corner badges. The rate panel still clears the full wrapping mastery outline by at least 20px. Neighbouring medals, including all winged sizes, and book/resource badges retain clearance.

The selector uses the original fishing tool textures directly. `scripts/ui/fishing_tool_stroke.gdshader` adds a 3px pure-black silhouette stroke and strengthens existing dark inner lines with a smaller sampling radius while preserving the underlying artwork and colors. Brightness is 0.88. No image generation or replacement image editing occurred in this correction. The rejected generated selector files were moved out of game assets to `outputs/art/rejected-fishing-selector-redraws/`. Active animation textures are unchanged.

`global_rules.fishing.recommended_location_tools` defines the initial recommendation for all 23 fishing locations. Shallows starts with hands; food-oriented locations use nets; precision/XP locations use the highest owned rod; offshore and Space locations use boat/mirror. Recommendations fall back to usable owned equipment. Unlock initialization writes a default only when the location has no saved selection. Locked previews no longer create or freeze a default, and another location's equipped tool no longer supplies the default. Explicit player choices survive repeated initialization, new equipment, and save/reload. Existing saved choices are preserved.

Validation passed: actual touch selection, exact corner anchor and square ownership, original-texture identity, shader material use, recommendation/owned-gear fallback, unrelated equipped-tool isolation, locked preview immutability, first-unlock initialization, player overrides across gear acquisition and save/reload, mastery/rate padding, all twenty neighbouring medal sizes, live book/resource badge clearance, active/idle isolation and save normalization. Source/database/UI/test-harness/hygiene checks passed. The full project suite retains the earlier unrelated ad-import blocker; no release package or device acceptance is claimed.

### Original art, corner overlap and location defaults

![Original art, corner overlap and location defaults](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-corner-tools/corner-tools-defaults.png>)

### Location tool picker

![Location tool picker](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-corner-tools/corner-tool-picker.png>)

### Corner selector and book badge clearance

![Corner selector and book badge clearance](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-corner-tools/location-buttons-with-badges.png>)

### Boat corner badges

![Boat corner badges](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-corner-tools/location-boat.png>)

### Mirror corner badges

![Mirror corner badges](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-corner-tools/location-mirror.png>)



## Miniature tool icons and active River Bend, October 22 (art rejected; superseded)

Generated five fresh transparent selector icons with the built-in ImageGen tool: net, rod, hands, boat and mirror. The prompt contract was a centered chunky cartoon tool, broad main/highlight/shadow color areas, moderate black contours, minimal interior lines, no texture or scenery, and readability at 92px. The approved shop icon informed the UI style; existing detailed tool artwork was used only as subject context. The net uses a few open rope cells; the rod has one broad green shaft, two bindings, a bobber and hook. Final assets are `assets/content/fishing/tools/selector-small-{net,rod,hands,boat,mirror}.png`; generation prompts and sources are recorded in `outputs/art/fishing-small-tools/generation.json`.

The selector draws at 92x92 inside a 104x104 transparent tap target, anchored exactly halfway across the square's top-right corner. The picker uses the same new art. Removed the code-applied darkening/stroke material from selectors. Original active fishing equipment and water animation remain. No balance, saved preference or recommended-default logic changed.

Centered location labels in the artwork square and kept them visible while fishing. Centered the area heading in its top band. Preserved the 0.7.0 mastery outline and 20px minimum gap above the rate panel. The fully raised water host is clipped to its bottom 44px and clears both River rate panels by at least 16px.

Validation: the production-main-scene visible module regression passed with actual menu/picker/location taps, active net and rod states, independent saved selections, recommended unlock defaults, badge and medal clearance, centered visible labels, water clipping and rate-panel clearance. Before/transition/settled raw captures were inspected at 1080x1920, including `module-net-start.png`, `module-net-transition.png`, `module-net-running.png`, and `module-rod-running.png`. Stable raw evidence is in `outputs/verification/fishing-small-tools/`; `manifest.json` records dimensions and SHA-256 hashes. UI boundary, activity UI boundary, test harness and generated-file hygiene checks passed. The fourteen-screen production-main-scene capture audit also passed (`.codex-tmp/fishing-small-screen-audit`). No agent-owned Godot process remained. The earlier full-project blocker remains unrelated stale import settings on five existing ad assets. No release or phone build was made.


## Chunky tool revision and compact areas, October 22

Brian rejected the previous miniature art: it was too thin, changed the style, and introduced individual fingers. Replaced all five selector icons using built-in ImageGen edits of the original production tools, with the approved shop icon as a separate style anchor. The hands preserve the original blue mitten silhouette, one hand mass and one thumb bump. Net ropes, bamboo shaft, boat hull and mirror-net frame are broader with heavy pure-black outlines and simplified internal divisions. The original brown/blue-purple mirror-net materials are restored. No runtime darkening/stroke material is applied. Previous rejected `selector-small-*` art is archived under `outputs/art/rejected-fishing-miniature-icons/` and no longer referenced by game code. New final assets are `assets/content/fishing/tools/selector-chunky-{hands,net,rod,boat,mirror}.png`; exact prompts, original subject references and style anchor are saved in `outputs/art/fishing-chunky-tools/generation.json`.

Restored area headings to the top right. Reduced the pre-art spacer from 128px to 80px and the box height from 576px to 528px. Raised the active equipment layer by the same 48px so it stays aligned with the location squares. Adjusted the book/resource overhang from 150px to 112px, preserving at least 8px between those badges and the wrapping mastery outline. Location names remain centered in their individual squares and visible while running. Selector draw size remains 92px with a 104px invisible tap target on each square's top-right corner. Saved choices and first-unlock recommendations are unchanged.

Validation: the visible production-main-scene module regression passed at 1080x1920, including reduced height/top padding, right-aligned area heading, actual picker taps, independent preferences, save restoration, all medal tiers, book/resource clearance, and active net/rod fishing. Fully raised water still clears both River rate panels by at least 16px. Inspected raw start, transition and settled frames from that run, plus actual hands, boat, mirror and picker screens. Stable proof is `outputs/verification/fishing-chunky-tools/`; its manifest verifies original PNG dimensions and byte hashes. UI boundary, activity UI boundary, test harness and generated-file hygiene gates and the fourteen-screen capture audit passed (`.codex-tmp/fishing-chunky-screen-audit`). Art remains subject to Brian's visual review. No release export or phone install.

## Active fishing animations and rod upgrades, October 22

Replaced the legacy 410x215 active-equipment mask with `scripts/fishing/active_tool_stage.gd`, mounted inside each production area card. It reserves the clear right lane below the heading and above the 44px bottom water strip. Whole transformed tool canvases stay inside the reserved stage without clipping. Every tool uses one authored 200x200 draw box, scaled uniformly from available layout space. No alpha bounds, per-frame image measurements, or corrective frame scaling determine visual size.

| Equipment | Active motion |
| --- | --- |
| Bare hands | Blue mittens dip and lift; no individual fingers |
| Drag net | Scoops toward the water, then lifts on a real batch haul |
| Stick rod | Casts, rests with the hook at the water, pulls on a catch |
| Good rod | Same rod motion with distinct black/charcoal equipment |
| Star rod | Same rod motion with purple/gold equipment and a large star |
| Boat | Bobs and rocks above the ripple surface, lifts slightly on haul |
| Reflection mirror | Sweeps and lifts above a purple ripple surface |

Ripples and splashes are separate code-drawn effects; their water/sewer/ice/deep-water/storm/space colors follow the area definition. Catch bursts now originate beside the active equipment and their target positions are constrained to the right lane. The existing bottom water strip remains clipped within its own band. Tools and effects clear the heading, selectors, medals, wrapping mastery outlines, and rate panels.

Rod display names are **Stick rod**, **Good rod**, and **Star rod**, supplied by `global_rules.fishing.tool_names`. The Good rod was changed from the initial gray proposal to black at Brian's request. Generated upgrade assets are `selector-chunky-good-rod.png` and `selector-chunky-star-rod.png`; both appear in selectors, purchase offers, and active fishing. Exact prompts, references, and generated source paths are recorded in `outputs/art/fishing-rod-upgrades/generation.json`. The basic rod retains the approved green chunky image. Saved IDs, ownership fields, per-location choices, prices, food output, and XP are unchanged in this pass.

Validation completed:

- `scripts/test-fishing-tool-balance.ps1 -AnimationOnly -VisibleGame`: passed, zero failures. Started all seven equipment variants through actual location art and picker controls in `res://scenes/main.tscn`. Checked entry, reaching, waiting, real successful completion/haul, transition, settled and additional cycle phases. Verified complete transformed canvases, ten-pixel UI clearance, stop cleanup, distinct rod art and source-backed names. Started and checked all 23 ordinary locations, including sewer, ice, offshore, storm, deep-water and space areas. The fixture resets the existing starter-guarantee counter before the observed completion so screenshots consistently contain real catch feedback.
- `scripts/test-fishing-tool-balance.ps1 -ModuleOnly -VisibleGame`: passed. Independent location tools, mid-activity switching, saved choices/defaults, original wrapping mastery, resource/book/medal clearance, and water/rate-panel spacing remain valid.
- Activity database contract/audit, runtime asset paths, UI boundary, activity UI boundary, test-harness, and generated-file hygiene checks: passed. Database audit reports zero missing assets and retains its existing curve warnings.
- Required fourteen-screen production-main-scene audit: passed at 1080x1920 in `.codex-tmp/fishing-stage-screen-audit/`.

Stable evidence is `outputs/verification/fishing-active-animations/`: 31 raw, unmodified 1080x1920 PNGs from the same visible animation run, `result.json` with 35 measured states and 23 location records, logs, and a manifest containing dimensions and SHA-256 hashes. Reviewed the net before/haul/settled sequence, all tool families, both upgrade rods, and actual picker screens. Dummy audio and muted game buses were used. No agent-owned Godot process remains. No import pass, release export, phone install, commit, or deployment occurred. The earlier full-project blocker from five existing ad-art import settings remains; these focused results do not assert a full project pass or physical-phone acceptance.

### Good rod active

![Black Good rod in the real game](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-active-animations/reinforced_rod-wait.png>)

### Net before, during and after a haul

![Net waiting](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-active-animations/net-wait.png>)

![Net hauling a real catch](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-active-animations/net-haul-transition.png>)

![Net settled after hauling](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-active-animations/net-settled.png>)

## Wooden Stick rod and Good rod bands, October 22

Replaced the green bamboo Stick rod icon with a warm brown branch: irregular silhouette, one broken twig stub, one large knot and a pale cut end. Retained the fat proportions, red bobber, steel hook and heavy black linework. Good rod's shaft and grip stay black; its three raised collars/tip cap are silver-gray for contrast. Silver-gray was the stated default while the optional color question was pending. Both edits used built-in ImageGen with the current assets as edit targets; the Stick rod also used the approved shop icon as a style reference. Prompts, references, original sources, before images and final asset paths are recorded under `outputs/art/fishing-rod-materials/`.

The prior animation report incorrectly stated that purchase offers already used the distinct upgraded art. Inspection found both upgrade offers and collection flights still hardcoded to the old bamboo image. Corrected these references through the shared rod icon path helper and removed the old upgrade tint, so Stick, Good and Star offers display their actual colors. Practice Pool now references the wooden Stick rod in the activity database, edited before runtime changes. Legacy bamboo tool aliases remain accepted. Serialized IDs, ownership, saved choices, balance and animation geometry are unchanged.

Validation: `scripts/test-fishing-tool-balance.ps1 -AnimationOnly -VisibleGame` passed again with zero failures across all seven tool variants and all 23 locations, and now also captures the real purchase cards. Inspected both changed rods at selector and active sizes, all three rod offers, and Practice Pool in the production main scene. Activity database contracts/audit, runtime asset paths, UI boundaries, test-harness and generated-file hygiene passed; zero missing assets. Stable evidence is `outputs/verification/fishing-rod-materials/`, containing 12 raw 1080x1920 PNGs, result/log and a dimension/hash manifest. Before/haul/settled frames come from the same visible run. Dummy audio and muted buses were used; no Godot process remains. No layout or animation timing change, import pass, release export or phone install occurred. The earlier full-project ad-import blocker remains unchanged.

![Wooden Stick rod active](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-rod-materials/line-wait.png>)

![Good rod with silver-gray bands active](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-rod-materials/reinforced_rod-wait.png>)

![Stick rod purchase card](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-rod-materials/price-rod.png>)

![Good rod purchase card](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-rod-materials/price-reinforced_rod.png>)

![Star rod purchase card](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-rod-materials/price-star_rod.png>)

![Wooden Stick rod in Practice Pool](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/fishing-rod-materials/hands-wait.png>)
