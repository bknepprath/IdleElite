# Brian Notes fixes, October 22, 2026

Working checkout: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`. The parent 2160p checkout is archived and was not used for implementation. Existing unrelated changes remain intact. No commit, release export, phone installation, or Firebase deployment was performed.

## Decisions and implementation

| Discord note | Result |
| --- | --- |
| Double the harvest animation when a berry activates | A successful doubled harvest emits two item flyers, separated by 0.30 seconds. Material awards are unchanged. |
| Default profile picture | ID 0 uses the existing blue bust. Shark remains selectable at ID 23. Four local Firebase avatar bounds and the catalog test accept 24 IDs; the rules are not deployed. |
| Neighbors | One “Neighboring activities” heading and a single row of stat values/icons replace repeated labels. |
| Make fishing make sense | Proposal only: distinct tool roles, location/tool suitability icons, real food/min and XP/min rates, an initial 85% food-output reduction and 90% lower purchase prices. No economy changes were applied. |
| Tier reward box | Brian approved the generated concept's positioning, while preserving the existing art style and top bar. Existing bronze/silver/gold art is enlarged; aligned progress bars and unboxed bonuses sit in one shared panel with one next-tier heading. The crest, mastery wording, percentage, and top progress bar remain unchanged. |
| Wisdom information control | Book icon replaces the word Wisdom on the activity meter and rewards. Count remains 12 / 25 in the review state. Expanded help contains source buttons only. A drawn dot/stem i replaces the outlined circled glyph. Numerator/denominator presentation remains open to further owner feedback. |
| Top-right minimize | Removed by explicit owner approval. No collapse zone is created; compatibility commands do not minimize. Old save flags are discarded and marked for saving, restoring all activities while retaining pins and sort preferences. |
| Firepit | Activity slot and lazy-list plan use the outer root height, including the fuel holder. |
| Glitch fix attachment | Same Firepit overlap as above. Off, igniting, and burning states no longer overlap the next activity. |
| Rat King expanded graphics/tool chance | Standalone Fishing combos use their own declared success, time, XP, and fish rewards without net/rod/boat soak state or penalties. Reward fields already declared in the activity database are preserved by the loader. Expanded art remains anchored to its activity. |
| White pixel halo | New clean Guys cover removes the source white fringe. Original animation frames remain unchanged. |

## Verification

- `scripts/test-brian-notes-oct22.ps1 -VisibleGame`: passed, failures=[] in the real production main scene. Rat King remained 75.3% and 11.76 seconds with hands, net, rod, boat, and star rod; seeded reward checks also covered mirror. Berry test consumed one and awarded two, moving 100 to 101 with exactly two flyers.
- `scripts/test-module-list-transitions.ps1`: passed, including pin interactions, legacy minimize flags, and restored saves. Updated obsolete collapse assertions to verify removal.
- `scripts/test-tier-banner-scroll.ps1`: passed menu drag, ordinary tap, and horizontal skill swipe after the new tier layout.
- `scripts/test-wisdom-feedback.ps1 -WisdomOnly`: passed.
- `scripts/tests/module_layout_performance.gd`: passed through the safe wrapper.
- Profile catalog Node test passed: 24 IDs, four online rule branches, five RGBA assets.
- Native 1080, UI boundaries, activity UI boundaries, runtime paths, generated-file hygiene, activity database contract/audit, crash audit, and save-normalization checks passed. The existing dedicated Firepit regression passed during project validation.
- `scripts/capture-screen-audit.ps1`: captured fourteen main screens successfully at 1080x1920 under `.codex-tmp/brian-notes-screen-audit`.
- Full `scripts/check-project.ps1` stopped at stale performance import settings for five pre-existing ad-page assets: blue-book backdrop, backdrop-v2, frame-v1, hero-powered-up, and hero-v1. Their files were already present in the initial status snapshot. No unrelated import settings were modified. Full-suite success is not claimed.
- All proof images below are raw 1080x1920 captures. Stable copies are byte-identical to the inspected source PNGs, with hashes in `outputs/verification/brian-notes-oct22/manifest.json`. Tests were muted with the Dummy audio driver. No Godot process remained after verification.
- No renderer, stretch mode, viewport configuration, or Android graphics settings changed. No physical-device or release acceptance is claimed.

## Proof

### Approved tier arrangement with existing art and top bar

![Approved tier arrangement with existing art and top bar](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/tier-rewards.png)

### Rat King expanded stats with net equipped

![Rat King expanded stats with net equipped](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/rat-king-success.png)

### Top-right press without minimize overlay

![Top-right press without minimize overlay](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/fight-rat-king-no-minimize.png)

### Firepit without minimize overlay

![Firepit without minimize overlay](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/firepit-no-minimize.png)

### Single neighboring activities heading

![Single neighboring activities heading](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/neighboring-activities.png)

### Default profile bust

![Default profile bust](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/default-blue-bust.png)

### Book/count and source-only help

![Book/count and source-only help](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/wisdom-icons-help.png)

### Clean Guys cover

![Clean Guys cover](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/guys-cover.png)

### Firepit before ignition

![Firepit before ignition](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/firepit-off.png)

### Firepit igniting

![Firepit igniting](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/firepit-transition.png)

### Firepit burning

![Firepit burning](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/firepit-on.png)

### Berry before completion

![Berry before completion](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/berry-before.png)

### Two separated item flyers

![Two separated item flyers](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/berry-transition.png)

### Berry animation settled

![Berry animation settled](C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/brian-notes-oct22/berry-settled.png)

## Art provenance

The Guys source master and generation contract are archived at `C:\Users\bknep\Documents\Idle Slop 1-art-source-archive\brian-notes-oct22\`. The full generated canvas was normalized offline to the authored 332x448 runtime cover size; there is no runtime per-frame alpha-bound scaling. Runtime asset: `assets/content/fight/enemies/guys/guys-cover-clean.png`.

The tier concept was generated with the built-in Image Gen tool using the owner screenshot as layout context and the approved shop icon as style context. It is a positioning reference only; no generated tier pixels are used in the interface. Preview: `C:\Users\bknep\.codex\generated_images\01a164b1-6a54-7012-a1b7-6b337aedb625\exec-d4cd5a99-23db-46a3-b87c-4d1860e4e9ca.png`.

Fishing plan: [fishing-tool-clarity-proposal-2026-10-22.md](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/docs/fishing-tool-clarity-proposal-2026-10-22.md>).

## Target-tier badge follow-up

Owner requested more top clearance and a borderless container matching the target tier banner. Added authored base fills for all 22 existing plaque artworks. The shared target label uses the next tier's fill; T4 is silver-gray and T3 is bronze. Existing banner artwork, mastery summary, percentage, and top progress bar remain unchanged. Increased the inner top inset from 8px to 24px and reduced unused row minimum height to retain the existing panel footprint. Labels remain 52px with the existing outline; containers have zero border width.

The muted real-main-scene tier capture run passed for Tier 3/T4 and Tier 2/T3. Inspected both raw 1080x1920 PNGs. Native-1080 and both UI-boundary checks passed. Proof copies are byte-identical, with hashes in `outputs/verification/tier-target-badges/manifest.json`. No renderer, viewport, gameplay, or save change was made in this follow-up.

![tier-target-4](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/tier-target-badges/tier-target-4.png>)

![tier-target-3](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/tier-target-badges/tier-target-3.png>)

Fourteen-screen capture audit passed again after the badge change: `.codex-tmp/tier-target-badge-screen-audit`. Generated-file hygiene and whitespace checks passed. No Godot process remained.

Fishing follow-up: the approved tool roles, equipped-tool rates, food reduction and reduced food prices are now implemented. See [fishing implementation and evidence](2026-10-22-fishing-tool-balance.md).
