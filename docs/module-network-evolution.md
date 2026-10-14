# Module Relationships

<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Updated: 2026-08-10

## Goal

Make the player understand what training one skill will unlock, supply, or improve elsewhere. The active first-hour design is specified in `early-game-relationships-and-treats.md`.

## Current Implemented Chain

```text
Building 2 -> Fighting: Wrestle Stuck Gate Latch
Woodcutting 2 -> Building: Saw Planks
Fishing 3 -> Woodcutting: Split Firewood
Fishing -> Fish -> Pond reservation or +1 stamina on a chosen non-Fishing skill
Thieving 4 -> Building: Study Blueprint
Woodcutting -> Scrapwood -> Firepit -> Woodcutting stamina recovery in current runtime
Building 5 + 8 Fish -> Hub Pond -> all-skill stamina recovery
Woodcutting 13 -> Berries -> selected eligible standard/Fishing XP and consumable rewards after parity fixes
Thieving 12 + Woodcutting 10 -> Honey -> all-skill stamina recovery
```

The database already supports multi-skill requirements, split XP rewards, combo tags, and display tags. Runtime also supports manual Fish eating and opt-in per-skill auto-eat after the first Fish is earned. The next slice is primarily relationship allocation, presentation, and first-hour guidance.

Firepit has two current contract mismatches: `docs/activity-database.json` targets `non_woodcutting_activities` and burns 1 Scrapwood per minute, while runtime and `test-woodcutting-firepit.ps1` target Woodcutting and burn 1 Scrapwood every 30 seconds. Runtime also spends 1 Scrapwood to ignite before ongoing burn. The selected product baseline is to make runtime honor both database fields, show `1 to light + 1 per minute`, and turn Firepit into an early Woodcutting-to-other-skills relationship.

The target changes continuity materially. With the selected authored combo values and relationship systems fixed, current Woodcutting-only runtime passes the 60-second limit in 31% of seeded runs, the database-aligned four-skill target passes 96%, and an all-skill target passes 98%. Start with the four-skill contract because it gives Woodcutting a distinct outgoing role and keeps Firepit separate from the permanent Pond and later Honey. If observed players cannot identify why Woodcutting is excluded, compare all-skill at the same fuel rate as the single fallback variable.

Ignition cost, XP per whole Scrapwood, heat-tier duration, bonus per tier, maximum tier, and cooling rate are currently hard-coded. The active plan adds them to the Firepit data contract and removes the direct-start path's cost bypass before tuning any value.

## Current Gap

The destination activity already shows colored requirement locks and split XP. The source skill does not consistently show what the requirement will enable, and the `+1` secondary reward on the first combo cards is visually and mechanically minor. The player can therefore satisfy a relationship accidentally and receive no clear source-to-destination receipt.

Do not increase those four rewards in the first relationship slice. With Fish, Berry, Firepit, and Pond fixed, current combo values pass the continuity limit in 96% of seeded runs versus 94% for the larger candidate values. Implement the missing source promise, exact split receipt, destination movement, and first-combo Berry first; reopen one reward only if observed players still do not value it.

Fighting also has no strong early outgoing relationship. The guided Pond route should use Wrestle Stuck Gate Latch's Building XP and first-combo Berry as Fighting's contribution to the shared account goal without claiming that Fighting changes the Pond's actual cost.

The selected plan closes that gap without changing the cost: the first successful Latch, Saw Planks, Split Firewood, and Study Blueprint completions each add one data-authored Pond support point. Pond remains Building 5 + 8 Fish, while its early permanent floor becomes +1% through +5% from zero through four unique support claims. A rational rush reaches Pond at 8:48 with only Building and Fishing, zero combo actions, and +1%; the guided route reaches +5% at 14:53. Support can be earned before or after construction.

Fishing has the strongest hidden outgoing relationship. Fish already restores stamina on any non-Fishing skill, but the same undifferentiated total pays for the Pond. A player can miss the stamina interaction or let auto-eat consume the future Pond cost. The selected candidate protects the unpaid Pond amount and exposes only the surplus to per-skill auto-eat.

The level 6-8 recovery actions do not currently form a cross-skill network: Thieving 6, Fighting 7, Woodcutting 7, and Building 8 all target their owner, and Fishing has no recovery action. Runtime supports restoring the lowest gauge, but the first authored uses appear at levels 52-58. A 100-seed sensitivity that retargets the level 6-8 actions to the lowest gauge changes no pre-Pond metric because the first one unlocks at a 38:24 median in that route. Keep these actions as self-recovery in the first slice and do not count them as relationship reasons.

In the matched selected scenarios, turning off the Fish bridge leaves a 1:35 median longest pre-Pond tired interval and passes the 60-second limit in 1% of runs. Protected surplus lowers the median to 0:24 and passes in 96%, with 10 median switches before Pond. The earlier unprotected sensitivity passes in 97% but eats eight more Fish by Pond and adds a replenishment switch; protection preserves trust in the visible project budget rather than increasing throughput.

## Next Slice

Make these relationships explicit:

| Card | Relationship |
| --- | --- |
| Building: Hammer Nails or the Building level header | `Unlocks Fighting action` |
| Fighting: Wrestle Stuck Gate Latch | Existing lock and split XP remain; added relationships: `Advances Building 5` and `Pond support +1%` |
| Woodcutting: Gather Fallen Branches | `Fuels Firepit` and `Builds Duel Fence Post` |
| Woodcutting: Firepit | After target reconciliation: `Improves four skills` |
| Building: Saw Planks | Existing lock and split XP remain; added relationship: `Pond support +1%` |
| Fishing: Shallows | `Supplies Pond` and `Supplies stamina` |
| Non-Fishing stamina gauge | Show caught Pond progress, such as `Pond: 3/8 protected`, spendable surplus, and literal `Auto Fish: On/Off` state beside the existing per-skill toggle. Keep queue and offline auto-spending off. |
| Woodcutting: Split Firewood | Existing lock and split XP remain; added relationship: `Pond support +1%` |
| Thieving: Chameleon Camouflage or the Thieving level header | `Unlocks Study Blueprint` |
| Building: Study Blueprint | Existing Thieving 4 lock and split XP remain; add the missing Thieving source promise and `Pond support +1%`. It does not change the Pond cost. |
| Locked Hub interaction or Building header | `Pond: Building 5 + 8 Fish` before the Hub opens |
| Hub Pond | `Required: Building 5 + 8 Fish`, `Support: N/4`, and the exact current/projected regeneration percentage |

When a source requirement becomes true, show one receipt naming both source and destination. Do not build a full graph screen.

The first Berry chooser should recommend Wrestle Stuck Gate Latch as the combined treat-and-relationship lesson. Keep Hammer Nails and Shallows as immediate-use alternatives labeled with Building 3 / Hub progress and one bonus Pond Fish. The 100-seed target sensitivity keeps all three above the continuity threshold; the alternatives add one median pre-Pond switch rather than improving the longest stall.

Keep Fish at its current one-stamina value in the first slice. A two-stamina sensitivity only preserves or improves continuity when paired with a second spending cap; uncapped it consumes the same 23 Fish sooner and lowers the pass rate. Use protected Pond allocation, per-skill opt-in, and aggregated receipts before adding another Fish budget.

Generate requirement, split-XP, and `relationship_rewards.pond_support_points` edges by indexing `docs/activity-database.json`. Use explicit adapters only for material sinks, other Hub upgrades, mastery buffs, and milestone rewards that are not action fields. Attach the highest-priority receipt to the existing unlock or reward event and persist its stable ID so it does not replay on load.

## UI Rule

Each card can show up to two relationship chips. Do not use a chip to repeat a requirement lock or XP value that is already visible on the same card.

Examples:

- `Unlocks Fighting action`
- `Advances Building 5`
- `Supplies Pond: 3/8 Fish`
- `Pond: 3/8 protected`
- `5 Fish available for stamina`
- `Rewards Fishing XP`
- `Fuels Firepit`
- `Improves all stamina`
- `Pond support +1%`
- `Pond support: 2/4`

Tap a chip for one short explanation.

## Skill Jobs

| Skill | Job |
| --- | --- |
| Fighting | Advances Building, adds Pond support through Latch, and contributes global mastery buffs. |
| Thieving | Enables Study Blueprint, adds Pond support, and later supplies Honey. |
| Building | Restores the Pond and hosts three partner-skill actions that improve it. |
| Woodcutting | Supplies materials and Firepit fuel and connects Building and Fishing to Pond support. |
| Fishing | Funds the base Pond, sustains a selected non-Fishing skill, and enables Split Firewood's support point. |

## Not Yet

- No full-screen graph.
- No big inventory.
- No hard lock maze.
- No new resource pile unless it has a clear sink.
- No simultaneous first-session tutorial for both Berries and Honey.

## Validate

Ask four questions after the first slice:

- Which skill should the player train next to restore the Pond?
- What changed elsewhere when the last requirement was met?
- Which activity will use the prepared Berry?
- How many caught Fish are protected for the Pond, and which skill may use the surplus?

Validate activity-data changes first:

```powershell
.\scripts\check-activity-database-contracts.ps1
.\scripts\audit-activity-database.ps1
```

Then run the safe project check for runtime changes:

```powershell
.\scripts\check-project.ps1
```
