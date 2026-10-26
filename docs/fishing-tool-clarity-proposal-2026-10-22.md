# Fishing proposal, October 22

Status: implemented in the working game on October 22 after Brian approved the full fishing plan. The net/rod tradeoff, selected-tool rates, specialist boat/mirror areas, food reduction, and food-paid prices are active. Verification and raw screenshots: [2026-10-22-fishing-tool-balance.md](playtests/2026-10-22-fishing-tool-balance.md).

## Tool roles

| Tool | Best use | Tradeoff |
| --- | --- | --- |
| Hands | Early shallow water and shoreline pockets | Free, immediate catches; low food output and poor reach into deeper water. |
| Net | Food collection at compatible fishing spots | More food per minute and less XP per minute than a rod at the same suitable spot. |
| Rod | XP training at compatible fishing spots, including precision spots | More XP per minute and less food per minute than a net at the same suitable spot. |
| Boat | Specialized offshore/deep-water activities | Unlocks a distinct set of navigable spots, rather than replacing the net/rod food-vs-XP choice everywhere. Sea, Stormy Sea, and Deep Sea require the boat. |

Rod upgrades improve the same role. Boat and mirror are specialist equipment; mirror serves the Starlight and Reflection space activities. Rocks accepts hands or net. Hands remain the free starter tool. Standalone combo activities such as Fight Rat King ignore equipped fishing tools.

## Make the choice visible

Brian's selected-tool proposal replaces the earlier all-tool comparison wallet:

- Show expected food per minute and XP per minute directly on each fishing location/activity, calculated for the currently equipped tool and that location's selected method.
- Each individual location square (for example River Bend and Rapids) has its own large circular tool button attached to its top-right corner. Its choice is saved independently. Its rates update while idle and starting uses that location's saved tool.
- The skill-header fish circle displays food only. Each location has a 168px circular tool button with a 136px icon, opening the existing picker filtered to that location's compatible tools.
- Use fixed, left-aligned food and XP icon columns with compact per-minute values. Remove the tiny compatible-tool strip. Keep the existing 0.7.0 mastery outline wrapping around each artwork square. Area boxes are 560px high to fit the attached buttons, existing resource/book badges, rates and bottom water strip. The side-tool animation remains.
- Rates are mathematical long-run expectations using the actual success chance, cycle time, food value, and complete haul cycle. Do not measure a recent run, roll random samples, or require a test catch. Partially filled nets/boats do not inflate the estimate.
- Switching tools or the location's selected method changes its displayed rates. Relevant player bonus changes also recalculate rates. Random catch results do not move these estimates; identical conditions give identical numbers.
- Rates use current medal/mission/XP bonuses and normal unattended attempt speed. Fishing does not spend stamina. Haul animations overlap attempts, so no additional fictional haul delay is added. Offline XP keeps its existing 30% rule and per-reward rounding; the displayed rates are live estimates.
- Keep the tool art and existing selector. Avoid a separate explanation page or paragraphs of new text.

This gives reasons to switch by goal and location: net for food, rod for XP, hands for free early access, boat/mirror for specialist activities. A later tool must not be best everywhere.

## Output and purchase targets

Implemented an **85% reduction in food value per catch and direct combo food payouts**. Sampled progression checkpoints show an 85–88.25% reduction in the best available food per minute. Preserved XP progression so the food nerf does not also make Fishing levels take roughly seven times as long. Space food values were separately reduced to 0.2 per Starlight catch and 0.125 per Reflection catch before the global 0.15 multiplier, keeping the corrected mirror payouts inside the reduced late-game economy.

Reduced **food-paid** purchase prices by **90%**. Boat construction uses Softwood, so it is separate from the food-price adjustment:

| Purchase | Currency | Previous cost | Implemented cost |
| --- | --- | ---: | ---: |
| Rod | Food | 1,000 | 100 |
| Reinforced rod | Food | 50,000 | 5,000 |
| Star rod | Food | 250,000 | 25,000 |
| Boat | Softwood | 1,000 | 1,000, unchanged |
| Mirror | Food | 1,000,000 | 100,000 |

Kept existing unlock levels and Building requirements, including Fishing 50 and Building 30 for the boat. The net's current level unlock remains. Existing player balances and owned tools are preserved.

The food-paid price/output targets make those purchases take about two-thirds of their previous farming time at an otherwise equivalent spot: 0.10 / 0.15 = 0.67. Prices can be adjusted after actual early/mid/late progression checks.

## Verification performed

The real-main-scene regression checks all 161 tool/location combinations, verifies net/rod roles, simulates 80,000 attempts, compares 300 seeded live/offline attempts, exercises actual purchase handlers and auto-eating, and restores saved balances/equipment. Inspected raw 1080x1920 captures show pre-start rates, wallet switching, specialist areas, prices, and help. The fourteen-screen capture audit and focused gameplay/UI checks passed. Full project validation is blocked by five unrelated pre-existing ad-page import settings; this is not release acceptance.

## Corrections and implementation boundary

The first version incorrectly labeled the boat price as food. Verified against `scripts/fishing/state.gd` and the boat purchase handler in `scripts/fishing/ui_surface.gd`: boat consumes 1,000 Softwood and requires Fishing 50 plus Building 30. The subsequent approved implementation retains that wood cost and both level gates. Authoritative balance data now lives in `global_rules.fishing` in the activity database.
