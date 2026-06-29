# Plan v0.5.0

## Intent

v0.5.0 should make the skill pages feel more authored, more gated, and less bloated internally. The update is built around four pillars:

- Clean up existing code so future systems are easier to extend.
- Add buildable modules that start as blueprints and become normal modules after a one-tap resource build.
- Add low-XP recovery modules whose main value is stamina restoration.
- Expand combat progression with better fighting module shapes, monster waves, and boss fights.

## Non-Goals

- Do not rewrite the whole skill system in one pass.
- Do not rename save keys, public action IDs, asset paths, or serialized data without compatibility handling.
- Do not ship final monster/boss art until the module systems and gameplay contracts are stable.
- Do not rebalance the whole game economy before build costs, recovery value, and berry bonuses can be tested together.

## Phase 0: Refactor and Dead Code Cleanup

Goal: remove obvious bloat before adding new systems, but keep the scope controlled.

Tasks:

- Audit `scripts/main.gd` for unreferenced helpers, duplicate module UI branches, stale one-off fixes, and confusing local names.
- Prioritize dead code removal where `rg` proves no references remain.
- Collapse repeated module/action checks into small domain helpers only when the pattern is already repeated enough to justify it.
- Shorten giant sentence-like variables into clear role names.
- Refactor the tutorial flow to remove jank.
- Explore replacing click input maps with real buttons where possible.
- Keep behavior changes separate from pure cleanup whenever possible.

Validation:

- Run static searches for renamed/removed symbols.
- Run `.\scripts\check-project.ps1`.
- Screenshot any player-visible UI touched by cleanup.

## Phase 1: Buildable Module System

Goal: some modules should appear as blueprints first, then require one tap and a resource cost before becoming usable.

Player flow:

- A locked buildable module appears in the skill page as a blueprint.
- The player taps it once to spend resources and build it.
- The build grants a satisfying build XP reward.
- After building, the module becomes a normal module permanently.

Suggested data contract:

```json
{
  "build": {
    "cost": { "softwood": 5 },
    "xp": 20,
    "label": "Build"
  }
}
```

Rules:

- Build state should be saved per module/action ID.
- Build cost is paid once.
- Build XP should be meaningful but not better than doing the main activity repeatedly.
- Built modules should use the existing normal module flow after construction.
- Blueprint visuals should be distinct but not treated as a separate activity type forever.
- Experiment with a new slide-in animation for newly revealed modules instead of fade-in.

Initial candidates:

- Recovery modules that are physical places or fixtures, like Steam Sauna.
- Some advanced fighting/boss-related training modules.
- Skill-specific utility modules where building makes the world feel like it is expanding.

## Phase 2: Recovery Module Flavor

Goal: add a new module flavor that gives poor XP but restores stamina, making rest and active recovery useful.

Behavior:

- Low XP reward.
- Primary reward is stamina recharge.
- Some restore the current skill only.
- Some restore another skill or the lowest stamina skill.
- Rare higher-tier versions can restore multiple skills.
- Firepit cooldown restart should preserve the current cooling-down regen bonus and build upward from there instead of resetting to 4%.

Examples:

- Fitness: Steam Sauna, Cold Shower, Ice Bath, Mobility Flow.
- Woodcutting: Truffle Hunting, Forest Picnic, Sap Tea Break.
- Fishing: Dock Nap, Warm Chowder, Tidepool Breather.
- Fighting: Wrap Hands, Recovery Bath, Monk Breathing.
- Thieving: Safehouse Nap, Quiet Alley Reset.
- Mining: Lantern Break, Hot Spring Tunnel.
- Crafting/Smithing-style pages: Workshop Tea, Tool Polishing.

Buildable recovery candidates:

- Steam Sauna.
- Cold Plunge.
- Safehouse Cot.
- Forest Rest Hut.
- Recovery Shrine.

Balance notes:

- Recovery modules should feel useful without replacing natural stamina regen.
- Best early version: small self-stamina recharge.
- Mid tiers can target lowest stamina.
- Late tiers can include multi-skill recovery with longer cooldowns or higher stamina cost.

## Phase 3: Fighting Module Progression

Goal: take the Fight Chickens prototype and turn it into a real fighting progression.

Shape direction:

- Vampire-survivor-style fighting modules should become diamond-shaped.
- The diamond shape should visually separate combat arenas from normal rectangular activity modules.
- Final visual details can wait until the next design pass.

Progression draft:

- Chickens: first chaotic swarm prototype.
- Angry Roosters: faster, more aggressive chicken variant.
- Street Rats: small swarm pressure.
- Giant Rats: tougher early enemy.
- Coyotes: faster mid-tier threat.
- Werewolves: bigger, more dangerous, night-themed.
- Cave Trolls: slow heavy pressure.
- Wyverns: flying or lunging pressure.
- Dragons: late-tier spectacle enemy.

Implementation direction:

- Reuse the chicken prototype as the base combat activity shell.
- Drive enemy behavior through data instead of one-off copies.
- Add enemy definitions for speed, health, spawn rhythm, contact damage, reward style, and art reference.
- Keep early variants cheap to produce while finalizing the feel.

Asset plan:

- Use placeholder silhouettes only while tuning behavior.
- Generate or create final assets after enemy scale, module framing, and animation needs are known.
- Validate each fighting module with screenshots because shape and readability are player-visible.

## Phase 4: Boss Fight Modules

Goal: create a new unique module type for major progression blockers.

Player fantasy:

- First-person idle fight.
- Boss monster centered in the module.
- Blue fists punch into view.
- The player clears the boss to unlock later modules.

Rules:

- Boss modules have a unique shape.
- Boss completion gates all later modules in the list that depend on that boss.
- Bosses can appear on any skill page, but most should depend on fighting level or fighting-related progress.
- Boss modules should communicate that they are barriers, not optional side activities.

First bosses:

- Fighting page first boss: Rooster.
- Later example: Rat King.

Suggested data contract:

```json
{
  "kind": "boss_fight",
  "boss": {
    "id": "rooster",
    "name": "Rooster",
    "hp": 100,
    "requires": [{ "skill": "fighting", "level": 3 }]
  },
  "blocks_after": true
}
```

Design notes:

- Boss fights should be short, clear, and punchy.
- The first-person presentation can be simple at first: boss center, fists, hit flashes, HP bar, victory state.
- The unique shape matters because players need to understand this module is a gate.

## Phase 5: Berries Resource and Apply System

Goal: add berries as a woodcutting resource with a unique prep/buff identity.

Resource source:

- Woodcutting activity rewards berries.
- Early berry source should be simple and visible.
- Later berry sources can be rare or tied to forest-themed modules.

Core idea:

- Tapping the berries resource opens an apply screen.
- The player chooses one module to apply berries to.
- The next time that module is completed, it consumes berry stock for a bonus.

Working name:

- Berry Prep.

Possible effects:

- Bonus XP on the selected module.
- Increased critical chance.
- Reduced stamina cost.
- Extra material roll.
- Double resource collection amount.
- Better failure consolation reward.

Suggested rules:

- One active berry target at a time.
- Applying berries should feel intentional, not automatic background math.
- Let the player choose how much berry stock to commit if the UI can stay simple.
- If choosing an amount is too much friction, start with one standard serving per completion.

Suggested data contract:

```json
{
  "berry_prep": {
    "target_action": "fight_chickens",
    "servings": 3,
    "effect": "xp_bonus"
  }
}
```

Design goal:

- Berries should feel like packing a snack before doing something hard.
- They should be flexible enough to support different playstyles without becoming just another flat XP potion.

## Phase 6: Validation Plan

Required checks:

- Run `.\scripts\check-project.ps1`.
- For any Godot one-off validation, use `.\run-godot-safe.ps1 --path . --quit-after 1`.
- Verify no headless Godot process is left behind after validation.
- Capture screenshots for any changed module shape, blueprint state, boss module, recovery module, or apply screen.
- Check mobile readability for all new visible text.

Data checks:

- If fishing data is touched, sync and audit:
  - `python scripts\sync-activity-database-js.py`
  - `.\scripts\audit-activity-database.ps1`
- For new activity data, audit IDs, unlock levels, requirements, and rewards before wiring UI.

## Phase 7: Mission Board Polish

Goal: make mission board task completion feel like a real reward moment.

- Add a ceremony animation for completing mission board tasks.

## Open Questions

- Should buildable modules be available immediately at unlock level, or can they appear before the player can afford them?
- Should build XP go to the module's skill, construction-style global XP, or both?
- Should recovery modules have cooldowns, stamina costs, or only opportunity cost through low XP?
- Should boss gates block every later module by list position, or only modules that explicitly reference the boss?
- Should berries apply to one completion, a fixed number of servings, or a timed buff window?
- Should berry effects be chosen by berry type later, or stay as one universal berries resource for v0.5.0?

## Suggested Build Order

1. Refactor and dead-code audit.
2. Buildable module data/state/UI.
3. Recovery module flavor and first content pass.
4. Berries resource and apply screen.
5. Fighting diamond shape.
6. Chicken prototype variations.
7. Boss fight module shell.
8. Rooster boss and first boss gate.
9. Mission board task completion ceremony animation.
10. Balance pass and screenshots.
