# Progression master plan

Date: October 12, 2026. Status: design proposal; no gameplay or balance changes implemented by this document.

## 1. Recommended direction

Owner correction, October 12, 2026: preserve the current opening. The first few activities should require only their levels. Introduce additional unlock work progressively farther down each skill's activity list. Do not redesign the opening around construction, preparation counters, or a new cross-skill tutorial.

The progression curve should increase both the investment required and the significance of the result:

1. Opening activities: reach the level and unlock the activity using the existing flow.
2. First added requirement after the opening: a small, clear accomplishment or local task within the same skill.
3. Further down the list: a visible obstacle or modest resource project with permanent progress.
4. Established progression: longer staged projects and selected contributions from other skills.
5. Major late milestones: substantial multi-skill projects that unlock a capability or area.

Building should have the most construction stages and permanent structures. Woodcutting should emphasize physical obstruction removal. Fighting, Thieving, and Fishing should develop their own preparation, access, and accomplishment requirements as the player advances. The simple opening applies to all five skills; it does not mean only the first two skill pages receive simpler rules.

Keep XP, levels, mastery, food, and existing materials. Levels establish readiness. After the protected opening, introduce one clearly explained additional requirement at a time. Budget the combined level and project effort; do not tune each independently and accidentally double the wait. Multi-part requirements belong farther down the list, with a larger payoff.

Difficulty should rise across successive milestones, while occasional straightforward level unlocks provide breathing room. A later unlock should feel more consequential because of the work completed and what it makes possible, not only because its repetition count is larger.

## 2. Current evidence and limits

The checked development worktree contains 171 enabled authored activities: 40 Fighting, 35 Thieving, 34 Building, 33 Woodcutting, and 29 Fishing. Twenty-six have explicit multi-skill requirements. These counts exclude temporary event definitions and do not claim that every authored activity is visible to a new player.

| Current system | Evidence | Implication |
| --- | --- | --- |
| Opening | Fighting starts with Push-Ups, then Practice Kicking. The swipe prompt can follow low stamina or the gate-latch tutorial sequence. | Preserve this opening and its first skill-switch flow. Measure it as the baseline; do not add new unlock work here. |
| Early combination | Wrestle Stuck Gate Latch requires Fighting 3 and Building 2. Saw Planks requires Building 4 and Woodcutting 2. | Keep these existing level requirements; do not replace them with brace-repair or preparation tasks in the opening. |
| More early combinations | Study Blueprint requires Building 5 and Thieving 4. Split Firewood requires Woodcutting 4 and Fishing 3. | Preserve their current early level-based access. New project requirements should arrive later. |
| Unlock evaluation | Runtime evaluates skill requirements, boss requirements, Wisdom, and manual unlock state. Buildable activities have a separate construction check. | Later projects may add a deliberate requirement alongside level readiness. Audit the total gate cost and avoid unplanned stacking with existing Wisdom, boss, or construction requirements. |
| Construction | Building activities, Hub construction, and other project systems provide the intended theme. The ordinary action `build.cost` field is not universal: this database currently explicitly uses it for Duel Fence Post, at three Scrapwood. | Audit each construction path before converting it. Do not assume all named Building activities already share one build-state implementation. |
| First Hub project | Hub opens at Building 3. Fish Pond tier one currently requires Fishing 5 and eight fish. | Keep the existing optional Pond route; do not make its construction a new mandatory opening tutorial. |
| Resource competition | Fish can be eaten; Scrapwood can fuel the Firepit or fund construction. | Progress shown as deposited work must not disappear because an automatic consumer spent the same inventory. |
| Data/runtime drift | Firepit data describes one Scrapwood/minute and non-Woodcutting targets. Current runtime uses two/minute and Woodcutting-only regeneration. | Resolve the intended contract before using it to balance a cross-skill lesson. Do not silently change its power as part of a presentation pass. |
| Disabled content | Face The Rooster is disabled; the loader removes dependencies on disabled bosses. | Do not plan the opening around a currently disabled boss or accidentally restore its gate. |

Sources: `docs/activity-database.json`; `scripts/activity_data/catalog.gd`; `scripts/gameplay/activity_unlock_runtime.gd`; `scripts/gameplay/buildable_modules.gd`; `scripts/gameplay/passive_modules_runtime.gd`; `scripts/gameplay/hub_runtime.gd`; `scripts/tutorial/onboarding_runtime.gd`; `scripts/ui/navigation_shell.gd`.

`docs/early-game-relationships-and-treats.md` contains useful earlier design and simulation work. Its observations about purposeful rotation, source-to-destination feedback, and resource protection remain useful. Its modeled times are historical, not a new benchmark for this checkout. For example, its Pond route assumed Building 5; the current Pond checks Fishing 5. Rebaseline before adopting its timing or reward numbers. The owner-approved current opening takes precedence over proposed onboarding replacements in either document. This plan does not automatically approve earlier Berry, Fish, or Pond balance changes.

## 3. Separate the types of progress

| Type | What the player sees | Storage and spending | Example |
| --- | --- | --- | --- |
| Spendable material | Inventory amount and a clearly labeled project cost | Existing inventory; spent exactly once when committed | Scrapwood used to construct Duel Fence Post |
| Local work | A changing object plus a local count or fraction | Permanent project state; never becomes a wallet currency | Boards attached to a fence, branches removed from a route |
| Accomplishment | A completed task or distinct success | Permanent flag; cannot be spent | A lock opened, an area cleared, a tool assembled |
| Skill growth | XP, level, mastery and existing bonuses | Existing progression systems | Better performance and new mastery interactions |

Use local work for the user's requested resource that does not function as currency. It can have a local display such as `Boards fitted 4/8`, but there is no global Boards balance, new inventory page, exchange rate, or unrelated use. Its exact meaning is attached to that fence.

Failures never remove completed work. Where practice itself plausibly helps, valid completed attempts may advance local preparation even if the reward roll fails. Where the objective is an actual catch, item, defeat, or successful theft, require the relevant successful event. Define the event explicitly per project; do not issue fish or stolen goods on failure merely to fill a meter.

For existing materials, show available inventory separately from committed construction. A collection preview can decrease if the player spends its materials elsewhere; built structure cannot. The first implementation should use an explicit commit/build action with an atomic payment. Avoid adding a universal automatic reservation system before the basic loop is proven. If staged deposits are later introduced, show each commitment and preserve it permanently.

## 4. Preserve the opening, then increase the requirements

### Protected opening

Keep the current initial activities, level unlocks, onboarding, and first skill switches. Push-Ups into Practice Kicking remains level-based. Do not add a strength-preparation counter. Do not replace the gate-latch level requirements with a brace-repair task. Do not add clearing work before the starter Woodcutting activities or a catch/survey requirement before the first Fishing locations.

The opening's existing XP, mastery, resources, and feedback already teach the core loop. Preserve that pace. Existing optional systems and deliberately authored construction requirements are not automatically removed by this plan; the protection concerns adding new work to the simple opening and rewriting its successful flow.

The precise end of the protected stretch should be marked per skill during the activity audit. Do not impose one global level cutoff on all five skills. Keep the familiar first few level-only unlocks intact and identify a later activity whose fiction naturally supports the first extra requirement.

### First added requirement: short and local

After that stretch, introduce one small requirement using something the player already knows how to do. Show it before the destination becomes eligible so progress can accumulate naturally during the approach. Reaching the level should not reveal an unexpected task that starts at zero.

A candidate Building entry point is Repair Small Shack, after the initial level-based activities. Its repair could require a modest amount of local work or existing wood, with one visible result. Choose one of those mechanisms for the first project, rather than requiring both. This is a candidate for testing, not a finalized activity conversion or new cost.

The first added task should be readily achievable within the owning skill. Introduce a mandatory contribution from another skill only after the player has completed and understood a local project. Existing early combo level requirements remain unchanged.

### Following milestones: more work, greater consequence

Use a few successive later transitions to establish a gradual increase:

| Transition depth | Requirement shape | Visible progress | Payoff |
| --- | --- | --- | --- |
| Opening | Level only | Existing level/unlock presentation | Next activity |
| First post-opening project | Level plus one short local task or modest material cost | One object repaired or prepared | A useful activity with a clear new role |
| Next substantial project | Level plus a larger obstacle or resource commitment | Several persistent physical stages | A better route, structure, or supply source |
| Later chapter boundary | Level plus a staged project with a selected external contribution | Parts completed across stages | A new area or important utility |
| Late milestone | Significant progression plus a multi-skill project | A complete structure assembled over time | A major capability such as dual training |

Increase target effort and required investment across these milestones. Occasional level-only activities can sit between them. Avoid a sudden large jump at the first project, and avoid a separate multi-part project on every row.

### Resource relationships after the introduction

Once the player understands permanent project work, use Woodcutting supplies for a named Building destination and fish to sustain the work. Show sources and consumption directly. Keep Practice Pool's existing XP-only role; it cannot satisfy a catch requirement.

Separate permanent progress from fuel and food. The Firepit may spend Scrapwood and auto-eat may spend fish, but neither can undo committed work. Do not advertise Firepit support for other skills until its data/runtime conflict is resolved.

Keep the existing Pond as an optional shared result. Show its actual current requirements and preserve the choice to continue a favorite skill. The earlier proposal to force a new first-hour sequence toward the Pond is withdrawn. Any staged visual treatment of the Pond must represent real committed construction, not just fish currently held in inventory.

## 5. Give each skill its own progression pattern

| Skill | Main identity after the opening | First added requirement candidate | Later form | Avoid |
| --- | --- | --- | --- | --- |
| Building | Assemble and improve permanent structures | A modest Repair Small Shack project after the level-only opening | Door, bridge, and roof projects develop into larger connected structures | Adding assembly counters to Stack Bricks and Hammer Nails immediately |
| Woodcutting | Remove obstacles and create useful supplies | A later shrub or route-clearing task | Clear Dense Grove opens routes; larger trees require more work and provide useful supplies | A clearing requirement before starter activities; identical counters at every row |
| Thieving | Prepare and execute jobs | A local lock-preparation task after the initial theft activities | Scope Out A Heist prepares a named job; larger vault projects need more preparation | Extra preparation on the first cookie/tip-jar activities; losing permanent work on failure |
| Fishing | Gain access, improve equipment, reach new waters | A later access or equipment task beyond the initial locations | More demanding river, sea, and deep-water access projects | New catch quotas before the first locations; a Building tax at every location |
| Fighting | Overcome increasingly substantial obstacles | A later physical obstacle or distinct combat accomplishment | Existing arenas and major cleared-area milestones | Replacing Push-Ups/Practice Kicking level unlocks with preparation work; relying on disabled bosses |

Building should be the strongest expression of staged construction once its simple opening is established. Woodcutting should use physical clearing at major route boundaries. The other skills should develop their own increasing requirements, retaining straightforward level unlocks between selected projects.

The Building prototype should begin after the protected opening and test an increasing sequence such as Repair Small Shack, Install Door That Mostly Opens, and Build Bridge Over Tiny Puddle. Start with the smallest project; make subsequent milestones demand more meaningful work and offer a larger result. Preserve Study Blueprint's existing planning/Wisdom role and early level requirements. Do not convert Building's first six activities wholesale into project gates.

## 6. Progression across the full game

Use depth in each skill's activity list as the main design reference. Exact level cutoffs and project costs remain to be tested per skill.

| Stage | Progression emphasis | Cross-skill complexity | Durable payoff |
| --- | --- | --- | --- |
| Protected opening | Current level-only activity unlocks and existing flow | Existing level relationships; no new project dependencies | Familiar fast access to the first activities |
| First post-opening milestones | One short additional local requirement | No newly mandatory external contribution for the first task | A visibly repaired object or useful activity |
| Developing progression | Larger local projects, real material investment, several visible stages | Introduce selected two-skill projects | Better supplies, a tool, a new route |
| Established progression | Longer staged work with intermediate results | More demanding contributions with flexible source order | New areas, useful infrastructure, specialization |
| Late progression | Major projects requiring substantial accumulated development | Rare all-five-skill projects | Capabilities such as the second training slot |

Do not simply multiply early repetition targets by ten in later chapters. Increase the scale of what changes: open an area, assemble equipment, complete a structure, establish a shortcut. Keep intermediate steps visible and persistent during a long goal.

Every ordinary activity does not need custom obstacle art. Use reusable visual families for minor transitions, and reserve bespoke sequences for signature projects. Preserve ordinary level milestones where a bespoke project would feel contrived. Every skill should still expose one understandable next useful goal.

Give older activities lasting roles through existing materials, support effects, mastery, or optional project contributions. Do not require players to repeat an obsolete starter solely because a new update failed to recognize their earlier accomplishment.

### Dual training

Keep the user's requested construction unlock: five special components, one from a designated activity in each skill, leading to two simultaneous activities from any skills, including the same skill.

Represent the five contributions as local workshop construction progress rather than five permanent wallet currencies. Each completed contribution adds a visible part. Once completed, the building remains finished; its component grind ends. The second slot is the main payoff.

The earlier proposal of 500 components from each of five level-67â€“70 activities is provisional, not an approved balance target. Measure the combined unlock path, including access to those activities and shared stamina, before adopting it. The project's difficulty should come from substantial earned progress across the five skills, not an unexpectedly large extra repetition bill after all five have already been developed.

This plan does not mark dual training implemented. Its independent session, fishing, save, and offline work remains described in `docs/dual-training-v070.md`.

## 7. Visual and interaction specification

For activities with added project requirements, keep the next goal within the actual activity list. The protected opening retains its existing presentation. The existing card is the preview, progress display, and eventual unlocked activity. Do not add a persistent project-management sidebar, replace the desktop carousel, or use widescreen space for duplicate controls.

| State | Required presentation |
| --- | --- |
| Upcoming | Recognizable destination partly obstructed or unfinished; exact source available on inspection |
| In progress | Permanent visual stages based on saved local work, plus one readable count when useful |
| Waiting on a different source | Name the missing contribution and offer direct navigation to its activity; retain completed stages |
| Ready | Clear completion state; respect existing automatic/manual unlock preference |
| Complete | Short reveal into the production activity; preserve the changed environment afterward |

Examples: boards fitted individually, a cracked obstacle losing a section, lock pins staying raised, a route becoming clear, a pier receiving its final usable section. Effects must correspond to real progress. Do not loop a destruction animation that falsely suggests permanent work is being lost or repeated.

Prefer three or four readable visual stages per minor project. A count can move each completion even when the next art stage has not been reached. Use a brief contribution effect without creating a toast for every completion. Keep completion transitions short, interruptible, and consistent with the existing smooth menu motion. Reduced-motion presentation should retain all information.

For mobile, follow the project's current minimums: body 48 px, status/help body 52 px, titles 60 px in a 1080-wide capture. Use shape/state as well as color. For desktop, keep the same goal inside each independently scrolling skill column; do not require another panel to understand it.

Art must honor the latest correction: thick, consistent black strokes, few large forms, restrained detail, and clear silhouettes at actual card size. Reuse layered boards, cracks, foliage sections, pins, and structural pieces. No full-screen art per tiny increment, and no runtime scale derived from individual frame bounds.

## 8. Balance and reward rules

- Keep the initial activities level-only. Beyond the opening, retain level readiness and introduce one main additional requirement at first: local work, materials, or a feat. More demanding chapter projects may combine stages later, with the full requirement visible before the player reaches it.
- XP and mastery remain meaningful parallel rewards. Do not simply rename XP as several different currencies.
- Increase total unlock effort progressively down the list. Measure level acquisition and project work together, including progress earned concurrently. Preserve opening timing and avoid an abrupt difficulty cliff at the first added requirement.
- New unlocks need a concrete benefit: a useful resource, support role, different activity, new place, or clearly better option. Higher numbers alone should not be every milestone.
- Do not reset permanent work on failure, death, jail, changing skills, backgrounding, or returning after a break. Existing temporary combat states can retain their existing rules; distinguish them from permanent access progress.
- Avoid randomness on the only path to a critical unlock. Real rare rewards may remain optional. Where a project needs a guaranteed special component, define that reward independently of unrelated loot RNG.
- Do not require active tapping to finish an idle progression project. Active interaction can improve the existing reward rate; it must not be the sole source of required work.
- Credit actual eligible offline completions when offline progress is enabled. Existing offline XP reductions remain explicit; do not invent a second hidden project penalty. Do not replay online rewards a second time on resume.
- Critical project credit should not scale with ad multipliers by accident. Keep existing XP boosts distinct from permanent access and construction rewards.
- Keep resource sinks and support choices understandable. Requiring fish for a goal while silently eating the same fish is a presentation and allocation problem, not a reason to add another fish currency.

Timing acceptance starts with preserving the current opening. Record its existing first-unlock and onboarding times and compare the candidate directly. For new requirements, measure the first small project, the next larger project, and a later chapter project; the increase in effort should be noticeable and accompanied by increasing payoff. Do not adopt the previous proposal's 30-90-second project unlock or mandatory 20-35-minute shared-project target for the opening.

## 9. Data and implementation design

Author project definitions in `docs/activity-database.json` first. Add a versioned schema for stable project IDs, destination activity, eligible source events, requirement type, target work or cost, credited phases, visual stages, and permanent outcome. Validate every referenced source and destination against the loaded catalog.

Keep local work in a separate persistent project-state owner. Do not register local-work counters as generic materials. Existing `built_modules`, Hub state, and manual unlock flags need an explicit compatibility map; avoid creating three independent flags that disagree about whether one activity is available.

Progress must be credited from authoritative activity completion, combat, catch, and construction events. Do not calculate it from UI animations, frame count, or a progress-bar tween. The same credit rules need online and offline paths, with batch-completion support. Material payment and unlock completion must be one atomic save operation and idempotent under repeated taps or lifecycle callbacks.

Save only needed project counters and stages. Clamp malformed values, bound entry counts, reject unknown sources safely, and preserve completed state across cloud conflicts under the existing save ownership rules. Do not use blindly summed counters from two devices; the same offline interval could otherwise be credited twice.

Migration must preserve existing access. A legitimately unlocked or built activity cannot become locked after this update. Map trusted old completion/unlock state to completed project state. For currently locked projects, preserve existing eligible partial progress where it can be reconstructed accurately. Do not infer specific catches or defeats from unrelated XP. If a new requirement would strand a nearly unlocked legacy player and cannot be reconstructed, provide a versioned legacy completion route rather than erasing their progress.

Validate the dependency graph: no cycles, no required resource whose only source is behind its destination, no dependency on disabled content, no required temporary event, and no second-slot requirement that itself requires dual training. Test all five starting skills, not only the guided Fighting route.

## 10. Delivery order and acceptance

| Phase | Deliverable | Acceptance condition |
| --- | --- | --- |
| 0 | Current-runtime baseline; mark the protected opening and existing gates per skill; resolve the intended Firepit contract before related economy changes | No new requirements in the protected stretch; data/runtime differences documented and intentionally resolved |
| 1 | One small post-opening Building project, with existing starter activities untouched | Clear requirement and visible result; modest added effort; save/resume preserves progress |
| 2 | Two subsequent Building milestones with increasing effort and payoff | The sequence becomes more demanding gradually; no first-project cliff or repeated arbitrary toll |
| 3 | Equivalent post-opening introductions in the other skills, then selected cross-skill contributions | Each skill retains its simple beginning and has a distinct progression identity |
| 4 | Extend the increasing requirements to major chapter boundaries across all skills | Full dependency audit; tested difficulty curve; useful intermediate results and level-only breathing room |
| 5 | Late workshop progression and dual-training payoff | Both the substantial construction route and actual two-activity engine pass their separate tests |

Implement one vertical slice before generating art for the full catalog. The hardest work is shared progression/save logic and economy pacing, not the counter widget. The next largest cost is readable staged art. Reusing visual families limits asset growth and download size. Cross-skill dependencies and dual training carry the largest balancing risk because they change how the whole game advances.

### Validation plan

Record the opening's first-unlock and skill-switch timing as preservation checks. Then record time and effort for the first added requirement, the following larger milestone, first cross-skill project, and later chapter payoff. Measure tired intervals and mandatory switching, not just total XP. Compare a guided player, a favorite-skill player, an offline-returning player, and a player who spends fish or wood elsewhere. Treat old simulator output as historical until it matches the current runtime.

Observe first-time players through the unchanged opening and into the first project without telling them the route. Once a project is introduced, ask what their current activity is changing, what will become available next, and why they chose another skill. Initial acceptance target: at least four of five observed players can answer these accurately. This small test is a usability check, not statistical evidence of improved retention.

Use local debug traces for prototype timing; no new production telemetry service is required for the first slice. If production analytics are later used, define the minimal events and compare stable cohorts before drawing retention conclusions.

Regression tests must cover old saves, partial projects, corrupt state, repeated build presses, shared material consumption, offline enabled/disabled, background/resume, cloud conflicts, alternate skill order, and a completed goal whose source is no longer rendered. Verify that animations and callbacks do not duplicate credit, nodes, signals, or timers.

Player-visible acceptance requires the actual production scene at 1080 Ã— 1920 and 1920 Ã— 1080, with raw before/progress/completed frames from the same run. No mockup establishes completion. Profile long sessions with several unfinished projects visible; update only changed stages and free transient effects. Android release acceptance still requires the existing physical Samsung rendering checks.

Recommended first implementation: one post-opening Building project followed by two increasingly demanding milestones. Preserve the current opening throughout. Expand only after players understand the first added requirement and the next milestones feel increasingly worthwhile.
