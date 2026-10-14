# Dual training for v0.7.0

Status: requirements and runtime audit. Dual training is not implemented or enabled.

## Confirmed requirements

- Two activities can train simultaneously, including two activities in the same skill.
- Unlock the second slot permanently by constructing a building with five special resources: one from a designated activity in each skill.
- Do not substitute a mastery-only unlock or require the two activities to be in different skills.
- Existing stamina, food, material consumption, success, mastery, and XP rules continue to apply to each activity.

## Proposed construction project

Name: Training Workshop. Located in the Player Hub.

Each source awards one construction component on a successful completion. Start with 500 of each component; tune after measuring the complete unlock path. No purchase requirement, random component drop chance, or time-limited source. Resource collection should work online and during enabled offline progress. Components are specific to this project and stop accumulating when it is built.

| Skill | Existing activity | Level | Component | Proposed quantity |
| --- | --- | ---: | --- | ---: |
| Fighting | Defeat Stubborn Tractor (`defeat-stubborn-tractor`) | 69 | Reinforced Gear | 500 |
| Thieving | Rob The Alien Spaceship's Bank (`rob-the-alien-spaceships-bank`) | 67 | Vault Spring | 500 |
| Building | Build Elite Tower (`build-elite-tower`) | 70 | Workshop Plan | 500 |
| Woodcutting | Harvest Moonlit Silverwood (`harvest-moonlit-silverwood`) | 70 | Silverwood Beam | 500 |
| Fishing | Chum Line (`chum-line`) | 70 | Deepwater Cord | 500 |

These are proposed values, not live activity data. Edit `docs/activity-database.json` first when implementing sources and costs, then run the database contract and audit scripts. Do not introduce live component collection before the complete unlock can be delivered.

Show five material counts and their source activities in the workshop panel. Each source links to its existing activity card. Enable Build only when all five costs can be paid. Consume the five costs and persist the completed building together in one save transaction. Repeated Build presses must not spend twice.

## Activity controls

- Before construction, activity selection retains current behavior.
- After construction, starting another activity fills the free slot without stopping the first.
- Tapping either running activity stops that activity only.
- With both slots occupied, explicitly choose which activity to replace. Do not silently stop one.
- Each running card has its own progress and stop interaction. Preserve the five-page desktop carousel and the mobile navigation.
- Shared skill stamina is consumed by both activities. Each runs at its normal calculated speed, including the existing tired slowdown. The second slot does not give free stamina or double regeneration.
- Preserve the current primary activity queue; specify and test how queue advancement interacts with an occupied second slot before enabling it.

## Runtime audit

The current engine has one `running_skill_id`, `running_action_id`, and `action_progress` on `main.gd`. References occur in gameplay, UI, saving, onboarding, queueing, and fishing. Running `_process_action` twice with those same fields would not implement independent training.

Per-session state must include action identity and progress, opportunity windows and boosts, completion streak, and fishing cast/net/boat accumulation. Shared state must remain shared: skill XP/mastery, stamina and regeneration, inventories, world timers, ad duration, missions, and building ownership. Fighting stages must also support independently addressed activities without replacing a single parked combat stage.

Relevant owners:

- `scripts/gameplay/action_runtime.gd`: start/stop, completion, opportunity state, online/offline rewards.
- `scripts/fishing/state.gd`: singleton net/boat stores and cast flags; unsafe for two fishing activities as written.
- `scripts/gameplay/fighting_runtime.gd`: one parked combat stage/action.
- `scripts/save_state/save_runtime.gd`: legacy running-action keys, offline application, serialization and migration.
- `scripts/main.gd`: global regeneration, per-frame action dispatch and UI refresh.
- `scripts/ui/skill_swipe_activity_surface.gd`, `scripts/ui/skill_detail_surface.gd`: running-card selection, progress and input routing.

Use explicitly addressed training sessions, not temporary swaps of global state. Save both sessions in one payload and import legacy single-action saves into slot one. Validate IDs and numeric fields and cap restored sessions at the earned slot count. Do not let a save restore bypass construction requirements.

Offline simulation must advance both activities on the same elapsed-time interval and spend shared resources in a deterministic order. Apply world regeneration and timestamps once. Simulating the full offline interval independently for each activity would double regeneration and misrepresent shared stamina.

## Required acceptance tests

1. Same-skill and different-skill pairs both advance and receive the correct rewards.
2. Two fishing activities retain separate cast, net, boat, haul, and tool state.
3. Two fighting activities do not replace each other's combat stage.
4. Stopping or replacing either activity leaves the other session unchanged.
5. Zero, one, and two active sessions survive save/reload, background/resume, and enabled/disabled offline progress.
6. Shared stamina, food, inventory, regeneration, and boosts are neither duplicated nor lost.
7. Legacy, corrupt, duplicated, locked, and unknown saved sessions fail safely.
8. Five-source component collection, offline collection, build payment, and repeated build presses are tested.
9. Queue advancement, jailed thieving actions, and temporary events cannot overwrite another session.
10. Real-game mobile and desktop captures show both progress controls and workshop material counts; run a bounded long-session test with both slots active.

Do not mark this feature complete or include it in release notes until the runtime integration and these tests pass.
