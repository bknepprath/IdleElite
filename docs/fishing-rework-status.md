# Fishing Rework - Status & Next Steps

## October 24 location-to-animation transfer

Starting a Fishing location sends its selected corner tool along a 0.58-second curved path into the shared center stage. The icon grows and turns, blending into the animation artwork where it differs. Its location name and corner icon fade out while active and return after stopping or switching. The other location retains its identity. Tapping the settled animated tool opens that location's picker. Tool changes made in the picker wait until the rate preview closes before beginning their transfer.

The transfer retains its start time across activity-card rebuilds. Its layout uses the authored column widths, and its scale uses fixed canvases rather than alpha bounds. The existing dip, line, pool palette, splash and catch systems resume after arrival. Progress, costs, rewards and saved tool choices are unchanged. Source changes only, not published. Evidence: `playtests/2026-10-24-fishing-tool-entry.md`.

The location selector and center-stage hit button now use an empty disabled-state style. Disabling these transparent buttons no longer exposes the default gray rectangle when the corner tool fades out or the rate preview replaces the animation.

<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->





Last updated: 2026-10-22 (working game; no new release package)



**Implementation & asset checklist (HTML):** [fishing-rework-implementation-guide.html](fishing-rework-implementation-guide.html)



## Shipped in game (`FISHING_REWORK_ENABLED`)



| Area | Status |

|------|--------|

| Data-driven `fishing.areas[]` + per-action `area` | Done - 10 areas, 23 methods |

| Area modules (1-3 methods, XP/yield chips, fluid strip) | Done |

| Beach, Pier, River, Sewers, Winter Lake, Reef | Done |

| Sea (rowboat, open water, chum line) | Done |

| Deep Sea, Stormy Sea | Done |

| Space Fishing finale (2 methods) | Done |

| Skill detail header: fish currency circle | Done |

| Skills menu fishing card: fish gauge + water strip | Done |

| Per-method attempt bars (archetype curves) | Done - see `docs/fishing-archetype-design.md` |

| Method short labels, catch icons, archetype mapping | Done |

| Catch burst count/stagger tuned by archetype | Done |

| JSON `rewards.fish_min/fish_max` drives fishing yield | Done |

| Corner crop on area BG (RoundedTextureRect + UV crop) | Done |

| Fishing-owned combo modules follow fishing rules: no stamina cost/spend | Done |

| Archetype-specific art sway / fluid phase thresholds | Not started |



## Explicitly Deferred



- **Building skill finale** - `build-the-building-that-builds-you` is not gated on fishing

- Teaser-only area rows (hidden future areas)

- Shiny fish + phase badge UI

- Lobster cage **passive collect** module (woodcutting-style)

- Per-method fluid timing from archetype (still one strip per area)

- Lava fishing area (brainstorm only; no actions in DB)



## Current Fishing Unlocks



| Level | Area | Location |

|-------|------|----------|

| 1 | Beach | Shallows |

| 2 | Beach | Practice Pool (normal activity; XP only, no fish) |

| 4 | Beach | Rocks |

| 7 | Pier | Dock Edge |

| 11 | Pier | Piling Line |

| 14 | River | River Bend |

| 18 | River | Rapids |

| 22 | Sewers | Drain Gate |

| 26 | Sewers | Tunnel Pool |

| 30 | Reef | Reef Pot |

| 34 | Winter Lake | Ice Hole |

| 40 | Sea | Rowboat |

| 46 | Reef | Reef Cage |

| 52 | Sea | Open Water |

| 58 | Reef | Night Reef |

| 64 | Stormy Sea | Storm Ripple |

| 70 | Sea | Chum Line |

| 74 | Reef | Pearl Bed |

| 78 | Stormy Sea | Storm Line |

| 82 | Deep Sea | Wreck Drop |

| 86 | Deep Sea | Abyss |

| 88 | Deep Sea | Deep Trench |

| 90 | Space Fishing | Starlight |

| 95 | Space Fishing | Reflection |



## Design Direction (Tool x Area)



Player unlocks **tools**, **regions**, and **locations** within each region module. Tool rack is global; location tiles replace verb/action fantasy. **Affinity** is tool x location. Spec: [fishing-tool-area-matrix.md](fishing-tool-area-matrix.md). **Module/location catalog:** [fishing-modules-and-locations-plan.md](fishing-modules-and-locations-plan.md).



## Remaining Big Wins



1. **Shiny fish** - rare flag on catch pop + album/counter

2. **Method timing** - per-archetype attempt bands (line vs net stories); fluid strip stays ambiance-only

3. **Fishing reference HTML** - keep current area, tool, and location status synced to `docs/activity-database.json` and `scripts/main.gd`

4. **Lobster passive module** - if design locks cage as non-row activity



## Data Hygiene Commands



```powershell

python scripts\fix-fishing-action-order.py

python scripts\reorganize-fishing-areas.py

.\scripts\audit-activity-database.ps1

.\scripts\check-project.ps1

```



## Phone Test Install



```powershell

.\scripts\install-android-phone-debug.ps1

```



Installs **Idle Elite Preview** (`com.idleelite.game.preview`) so the Play/release app and saves stay untouched.



## October 5, 2026 feedback changes



- Practice Pool unlocks at Fishing 2: 3 XP per 3-second cycle, 100% base success, no fish, no stamina cost. It uses a normal activity card and does not inherit fishing tool multipliers or storage. Base XP rate is 60/min, below level-2 stamina activities (about 103-150/min before bonuses).

- Fishing help opens once on the first Fishing page visit and remains available through the header info button. It explains offline progress, fish use, and Practice Pool.

- Recovery board tasks require 25% of the ordinary repetition count, rounded up. Legacy assignments migrate once, scaling target and remaining repetitions together. Recovery speed and output are unchanged.



## October 22, 2026 tool clarity and economy



- Each individual location square has an attached circular tool selector (168px button, 136px icon) and independently saved choice. River Bend and Rapids can use different tools. Food/min and XP/min use that location's tool before starting. The header circle only displays food. Tiny compatibility icons are removed. Mastery uses the existing 0.7.0 outline wrapping the artwork square; straight bars are hidden. Original artwork fits in 560px area boxes with room for resource/book badges, water strip and side-tool animation.

- Net yields more food and less XP than every rod at shared locations. Hands remain the free starter. Rocks uses hands/net. Sea, Stormy Sea, and Deep Sea require boat; Starlight/Reflection require mirror. Specialist tools cannot farm XP outside their areas. Combo activities and Practice Pool remain tool-independent.

- Earned food is multiplied by 0.15, including direct combo payouts. Space per-catch values are additionally tuned for the corrected mirror eligibility. The best available rates are 85–88.25% lower at Fishing 3/18/30/45/50/85/90/95 in the recorded baseline comparison. Existing food and owned equipment remain intact.

- Food-paid prices: Bamboo rod 100, Reinforced rod 5,000, Star rod 25,000, mirror 100,000. Boat remains 1,000 Softwood with Fishing 50 and Building 30 gates.

- Live and offline food share reward rules. Offline combo rewards now retain every rewarded skill's XP under the existing 30% offline XP policy.

- Evidence and test status: [2026-10-22-fishing-tool-balance.md](playtests/2026-10-22-fishing-tool-balance.md). The older May tool-affinity matrix is historical.



### Current selector appearance



The circular backgrounds were removed at Brian's request. Each individual location keeps its own saved tool, selected through a frameless 144px target with a darker 136px tool icon. Strong black outlines and black net openings preserve recognition against scenery. Location squares moved up 42px; area height is 548px. Rate panels, tools, badges and adjacent medals clear the original 0.7.0 wrapping mastery outline. Current evidence is the frameless revision in the October 22 fishing verification report.



### Current corner attachment and defaults



The original tool textures are restored. A code-applied black stroke strengthens each icon; no generated selector artwork is used. Each selector straddles its own location square's top-right corner, like the other corner badges. Initial tools come from `recommended_location_tools` at first unlock, using owned compatible gear. Once the player changes a tool, repeated initialization and new equipment do not replace that choice. Locked previews do not create saved defaults. Current raw evidence is in the final corner-badge/defaults section of the October 22 verification report.



### Current chunky art and active animation revision



The preceding selector appearance notes are historical. The current selector uses approved chunky transparent icons at 92px inside a frameless 104px target on each location square's top-right corner. No darkening shader is applied. Area headings are top-right, location labels are centered, and cards are 528px tall with the original wrapping mastery outline and padded rate panels.



Active equipment now uses those same chunky tools in a dedicated clear right lane, below the area heading and above the bottom water strip. The old 410x215 clipping layer is replaced by an unclipped stage with one canonical 200x200 tool canvas. Layout alone determines scale; no alpha bounds or frame-specific scale correction is used. Net scoop/lift, mitten dip, rod cast/pull, boat bob, mirror sweep, ripples, splashes, and catch bursts stay within that lane.



Rod tiers are Stick rod, Good rod, and Star rod. Stick rod is now a brown wooden branch with a cut end, knot and twig stub. Good rod has a black shaft with silver-gray raised bands and tip cap; Star rod is purple/gold with a large star and cyan bobber. Selectors, offers, collection flights and active fishing use each tier's corresponding art; Practice Pool also uses the wooden Stick rod. The October 22 rod-material correction fixed offer and collection-flight references that still used the old bamboo image. Serialized IDs (`line`, `reinforced_rod`, `star_rod`), ownership, saved location choices, prices, food output, and XP are unchanged. Latest generation provenance is `outputs/art/fishing-rod-materials/generation.json`; original upgrade provenance remains `outputs/art/fishing-rod-upgrades/generation.json`. Verification is recorded in `docs/playtests/2026-10-22-fishing-tool-balance.md`.



### Final October 22 compact composition



The earlier right-lane, 528px and lower-strip notes are historical. Current area modules are 312px high with one location on each side, a shared raised center animation, centered 48px area heading, original wrapping mastery and saved corner tool selectors. The bottom strip and permanent lower rate panels are removed. Selecting tools temporarily replaces the animation with centered food/min and XP/min, then crossfades back. Animated net/hands/rod scales are 82%/72%/82%; rods sit 18 authored pixels left. Pool foreground opacity is 96%, the rim is black, and the equipment is limited to shallow five-pixel immersion with a curved pool mask. All seven tool variants and 23 locations passed the production geometry audit; actual picker/fade proof is recorded in the October 22 evening report.


### October 23 splash synchronization

Splash launch follows the rendered tool or line leaving the surface on withdrawal, after interpolation, instead of the initial reach. Each exit fires once; a single right-side splash has no added delay. The boat wake follows its haul rock. All seven tools and a natural hands cycle passed focused timing checks. Evidence and raw frames: `docs/playtests/2026-10-23-fishing-splash-sync.md`.

October 23: completed surface-exit splash/catch synchronization, swift-to-slow fish rise and fade, and corner-anchored tool wallets. Seven-tool timing and left/right picker checks passed in the real main scene. See `playtests/2026-10-23-fishing-splash-sync.md`.

October 23 follow-up: removed Fishing Wisdom. River Bend no longer awards it or displays a book. Chum Line and Deep Trench no longer require it; their level and project-resource gates remain. Audited every skill and found no cross-skill Fishing Wisdom requirement. Historical Fishing Wisdom save balances are retained only for compatibility. Real-main-scene tests passed zero-Wisdom unlocks, remaining resource blockers, unchanged other-skill Wisdom, legacy balances and no book badge. Raw 1080x1920 proof: `H:/Codex/Projects/IdleElite/outputs/fishing-without-wisdom-oct23-balanced/river-without-wisdom.png`.
