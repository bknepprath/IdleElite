# Connected production paths

Date: October 24, 2026

Status: implemented locally for review; not exported or published

Reference supplied by Brian: https://www.youtube.com/watch?v=ZreD-sazElE

## Advertisement review

The video is titled Designing woodcutting in Idle Elite. Its English automatic captions were retrieved directly from YouTube on October 24. It describes Berries doubling the next harvest and XP, Honey improving stamina recovery, and Scrapwood fueling the Firepit. Its central design question is whether gathering each support resource is worth the time it takes away from the main activity. The ending emphasizes discovering interactions that change how the player chooses to play.

The production paths below should be evaluated against that claim. Compare direct training, immediate Honey use and bottled reserves over short sessions, longer sessions and offline preparation. Count all gathering time, conversion time, stamina and fuel. A chain should not become mandatory simply because it has more steps, and an upgrade should not permanently make all alternative uses of its ingredients irrelevant.

## Existing behavior

Loot Beehive unlocks at Thieving 12 with Woodcutting 10 and awards Honey. Honey is already saved in the material wallet, but the game consumes it automatically when stamina recovery needs it. Each unit provides ten seconds of doubled regeneration under the existing eligible-skill rules. Online and offline recovery both account for it. Bottling therefore needs to add deliberate reservation and activation, rather than merely another saved inventory counter.

Fish, Berries and Honey already have different roles. Fish funds stamina consumption, Berries can double XP and material loot for selected activities, and Honey improves regeneration. Preserve those distinctions. Current unlock-resource counters are committed project work, not general crafting inventory; do not silently turn them into spendable materials.

The existing opening remains level-led. Introduce production branches after the player understands skill switching, around access to the Beehive rather than before the first activities.

## First playable path: bottled honey

| Step | Skill or existing location | Result |
| --- | --- | --- |
| Gather Sand | Building action at the shoreline, with a modest Fishing requirement | Stored Sand |
| Construct a Kiln | Building project | Access to glass processing |
| Melt Sand | Kiln activity, supplied with Woodcutting fuel | Stored Glass |
| Shape Bottles | Building recipe | Empty Bottles |
| Bottle Honey | Optional mode on Loot Beehive | Reserved Honey that the player can activate later |

Exact unlock levels, recipe costs and processing times require a production-time model before implementation. The kiln is a new optional project; existing construction targets and Firepit behavior should not change to fund it.

### Bottling interaction

- Normal Beehive operation keeps its existing Honey output and automatic recovery behavior
- A bottle control on the Beehive switches future Honey drops into bottling
- Reserve one Empty Bottle when a fill begins, then divert the next six Honey units into it before automatic consumption can spend them
- Six units produce one full bottle containing sixty seconds of the existing 2× effect; this is an initial packaging proposal, not a balance commitment
- Preserve a partially filled bottle across activity changes, restarts, cloud saves and offline play
- Tapping a full bottle deliberately adds its duration to the current Honey boost; duration adds, multiplier never stacks beyond the existing 2×
- Once activated, use the existing eligible-recovery and offline accounting rules
- Return the Empty Bottle when opened, making glass an investment in reserve capacity
- When bottles run out, stop bottling and retain the existing normal Honey behavior; clearly show the empty bottle state

This gives a concrete decision: receive regeneration now or prepare a reserve for a later session. A player can still use Honey without building the kiln. There is no spoilage timer, breakage chance or compulsory bottle cost on the current benefit.

### Presentation and animation

Keep production within activity modules. Show an ingredient icon, amount and output icon; tapping a missing ingredient goes to its source. Preserve the existing source/destination navigation pattern. Recipe inputs must be visible before starting, and a depleted input must stop processing without negative inventory.

The kiln heats visibly during a real processing cycle. Glass changes from a hot mass into a bottle. On the Beehive, a bottle fills in readable increments corresponding to saved Honey units. Its fill level must never reset visually when actual progress is retained. Keep the established blue character, mitten hands, heavy outlines and three-tone artwork.

## Further branches

Each branch has a distinct decision or capability. The initial local implementation includes each branch below. Upgrade directions beyond that initial behavior remain design options.

| Branch | Connected inputs | New interaction | Upgrade direction |
| --- | --- | --- | --- |
| Fishing scouting | Two Polished Lenses + two Wooden Parts → Spyglass | Inspect a location's current special catch opportunity before choosing a tool | First inspect one location; later compare both locations in the area |
| Targeted bait | Berries + Honey → bait | Direct selected catches toward a particular useful ingredient instead of ordinary food | Choose the target, then unlock a second bait recipe; keep meaningful food/XP tradeoffs |
| Beehive wax and light | Optional wax extraction + wood → candle | Reveal a concealed Thieving activity for a limited number of attempts | Build a lantern that extends exploration through more rooms; useful rewards must exist before adding the ingredient |
| River machinery | Fighting clears a jam, Woodcutting supplies timber, Building repairs a waterwheel | Unlock one finite background processing queue for the kiln | More queue capacity or a new recipe family, with inputs reserved in advance |
| Tool attachments | Glass, wood and crafted fittings | Choose a tool behavior, such as selective netting versus bulk catches | Unlock alternatives and allow free switching once crafted, rather than replacing every tool with a strictly stronger one |

Scouting and bait require explicit catch identities and rewards; current Fishing food units alone cannot support those promises. Add a small authored set of useful catches before exposing scouting or bait. Avoid an open-ended species collection system in the first honey update.

Wax needs a deliberate source or extraction choice so normal Honey collection does not create an unlimited unused byproduct. Candle attempts should be spent on actual exploration, not real-world time while the game is closed.

The waterwheel runs material processing only. It must not silently introduce the previously deferred second general training slot. Its queue is finite and stops when reserved inputs are exhausted.

## Skill roles

| Skill | Role in these paths |
| --- | --- |
| Building | Convert materials and construct devices that change available actions |
| Woodcutting | Supply structural materials and fuel, with competing uses |
| Fishing | Supply location-specific ingredients and provide catch-selection decisions |
| Thieving | Obtain specialized materials and discover alternate access routes |
| Fighting | Remove physical obstacles or complete encounters that change an area |

Use the user's proposed wordplay where an activity supports a real interaction: for example, Fight the Current can be the physical task at the waterwheel. New comic names should be reviewed alongside their animation and actual outcome.

## Upgrade rules

- Initial construction unlocks a capability
- A later upgrade changes a decision: reserve supplies, choose output, reveal an alternative or automate one bounded step
- Inputs with several uses create choices, but ordinary progression must not require completing every branch
- Each intermediate item must have an immediate purpose; a second use can arrive later
- Do not add broad success bonuses that erase the current Bronze/Silver/Gold progression
- Keep source activities worthwhile through materials, not forced repetition of an obsolete prerequisite
- Preview one reachable useful destination rather than displaying the whole production network at once

## Implementation order

1. Add the Sand → Glass → Empty Bottle → Honey reservation slice, using current Honey strength
2. Measure total time to a first full bottle and whether saved activation is worth the optional setup
3. Give Glass a second use through a small scouting feature with an actual reward target
4. Add one further resource interaction, preferably targeted bait or wax/light
5. Add finite processing automation only after the manual recipes have understandable costs and pacing

## Implementation acceptance

### Current integration constraints

Checked again after the computer restart on October 24. The current Beehive has a 1.98-second base cycle, 2 stamina per attempt and a 78% base success rate. Before bonuses and stamina interruptions, six successful Honey drops take an expected 15.23 seconds of activity time and 15.38 stamina. These are baseline expectations, not a complete production-path balance result; gathering and processing bottle materials adds further time.

The existing save writer and loader clamp `honey_stamina_seconds_remaining` to ten seconds. A sixty-second bottle cannot simply add to this field without changing its serialization contract: the next save/reload would discard most of the effect. Prefer a separate saved activated-duration bank that feeds the existing ten-second consumption mechanism, preserving legacy saves and the current online/offline regeneration rules. Cloud comparisons must recognize that both reserved bottles and activated duration are spendable state.

Material rewards pass through `_award_action_mat_rewards` in both live and offline completion paths. Bottling must divert the awarded Honey before it enters the automatically consumable wallet, including increased yields from Berries. Recipe input reservations and partially filled bottles need their own saved state. The implementation now meets these requirements through a separate saved production state and the existing material reward path.

- Author activities and recipe definitions in `docs/activity-database.json` first
- Give new inventory materials stable IDs; update wallet serialization, normalization and cloud comparisons
- Deduct each recipe input once and award output once, including interrupted, failed and offline cycles
- Distinguish reserved recipe inputs from available inventory so auto-eating and fuel cannot spend them twice
- Preserve all existing Honey balances, active boost time and previously unlocked content
- Save partial bottle fills and return exactly one bottle per opened full bottle
- Verify manual activation, duration addition, no 4× stacking and existing full-stamina behavior
- Model fuel competition with Firepit and construction before choosing costs
- Audit new activity ordering, neighboring-medal contributions and tier completion so inserting recipes does not accidentally undo earned progression
- Verify new controls and recipe readability in the real production main scene, muted, at phone dimensions
- Keep this design listed as proposed until implementation and runtime checks pass


## Implemented local behavior, October 24

The playable implementation adds 14 actions, 13 materials and 15 functional production presentations; existing Fishing, combat arenas and passive scenes remain distinct. The owner rejected cosmetic replacements such as Pocket Couch Coins, so 32 legacy activities have returned to standard portrait cards. The catalog no longer forces a special presentation every third activity. Production scenes retain their resource and equipment controls.

Honey remains unchanged when Store is off. Store reserves an Empty Bottle at the first diverted unit, preserves partial fills, and packs six Honey into one bottle. Use returns that bottle and banks sixty seconds of the existing 2× recovery, feeding ten-second doses. It never creates a 4× multiplier. No bottle available means new Honey continues to the normal wallet.

Four Softwood become two shared Wooden Parts. Spyglass assembly uses two Polished Lenses and two parts; Lanterns, the Waterwheel and the Selective Net also use parts. The tube exists only as an internal assembly sprite. Its far eyepiece lens sits behind the opaque body; the finished sprite shows only the front lens. Prototype tubes migrate into two parts each, and paid work is retained without another charge. Existing owned Spyglasses remain owned. Scout cycles supported Fishing locations; Bait saves the location choice. A successful targeted haul consumes one Bait, halves ordinary food and grants that location's material. An enabled, owned Selective Net doubles the targeted material on net catches.

Beeswax and Scrapwood make Candles. A Lantern costs three Glass, one Hardwood and one Wooden Part. Exploring consumes one Candle per attempt, or one per three attempts with a Lantern. Successful exploration awards two Glass and one Hardwood. Eight successful Fight the Current cycles clear the river mechanism. Repair Waterwheel then reserves 22 Softwood, four Wooden Parts and four Glass once, and finishes after eight work cycles. Its queue holds twelve prepaid jobs, runs one at a time live or offline, and grants materials without background XP. Queuable recipes are glass, bottles, lenses, wooden parts, candles and bait. The kiln must actually be built before queuing glass. A Selective Net costs twelve Pearl Scales and three Wooden Parts.

Base-time comparison: the first reusable bottle capacity costs an expected 4 / 0.92 + 5 + 4 = 13.35 seconds of Sand gathering, melting and shaping, plus Scrapwood gathering and kiln construction. Subsequent bottle uses reuse that same glass investment. Six Honey still require 15.23 expected seconds before jail, stamina interruptions and bonuses. Bottling adds reserve capacity and deliberate use, rather than more Honey value. Exploration and the waterwheel give later alternative Glass supplies; active skill XP and passive processing are separate choices. These are starting values for playtesting, not a finished economy assessment.

Verification and raw production-scene evidence are tracked in [production implementation status](production-implementation-status.md). No release package, deployment or publication is authorized by this local work.
