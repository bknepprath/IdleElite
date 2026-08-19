# Idle Elite Planning Board

<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Updated: 2026-08-10

Use this page to find the active product plan. Current activity facts come from `docs/activity-database.json`; proposed behavior remains in planning documents until it is implemented and validated.

## Current Focus

The active product problem is first-hour rotation without intention. The highest-leverage throughput hypothesis uses Fish to sustain the selected non-Fishing relationship target. Protecting the eight Fish required by the Pond keeps that shared goal truthful and prevents a late replenishment detour. Berries teach targeted reward choice; Honey remains later.

Primary plan:

- `early-game-relationships-and-treats.md`

Supporting documents:

- `module-network-evolution.md` for the current and next relationship slice.
- `product-requirements.md` for product-wide requirements and success metrics.
- `idle-elite-design.md` for visual and mobile-readability direction.
- `plan-v0.5.0.md` for the historical implementation plan that introduced buildable, recovery, combat, Berry Prep, and mission-ceremony work.
- `activity-database-contract.md` for authoritative activity-data change order.

## Current Database Baseline

```text
Fighting: 41 actions
Thieving: 35 actions
Building: 34 actions
Woodcutting: 33 actions
Fishing: 28 actions
Temporary events: 5
```

The first implemented cross-skill requirements are:

- Building 2 enables Fighting: Wrestle Stuck Gate Latch.
- Woodcutting 2 enables Building: Saw Planks.
- Fishing 3 enables Woodcutting: Split Firewood.
- Thieving 4 enables Building: Study Blueprint.

The 2026-08-10 100-seed first-hour matrix found:

- Guided current mechanics: median Pond 17:24; median longest pre-Pond tired interval 1:25; 0% of runs meet the 60-second limit.
- Candidate relationships without the Fish bridge: median Pond 17:16; median longest interval 1:16; 11% meet the limit.
- Selected current-combo, linked-Pond, use-gated-Berry route with protected surplus: median Pond 14:53; median longest interval 0:24; 96% meet the limit; median 10 switches before Pond. The matched no-Fish control is 17:22, 1:35, and 1%.
- Unprotected auto-eat: median Pond 14:59; median longest interval 0:22; 97% meet the limit; 31 median Fish eaten by Pond and 11 median pre-Pond switches. Protection preserves the project budget rather than improving raw speed.
- Selected Fish-spend sensitivity: a 12-Fish cap meets the 60-second limit in 23% of runs, 18 meets it in 79%, 21 meets it in 94%, and 22 meets it in 96%. The unrestricted candidate uses a median of 23 by Pond and meets it in 96%.
- The selected guided relationship-powered Pond reaches 14:53 and +5%, while a rational Building/Fishing rush restores it at 8:48 with 2/5 skills, 0/4 combo actions, and a truthful +1%. Unique combo successes raise the early floor before or after construction.
- Switching the selected simulator from runtime mastery to the documented success formula moves Pond from 14:53 to 14:52, keeps Fence at 21:43, and keeps the 96% continuity pass rate; resolve the contract separately from the Fish interaction.
- Retargeting the current level 6-8 recovery actions from `self` to `lowest` does not change the no-Fish candidate: the first recovery unlock is 38:24 median, after Pond, and the guided route uses none. Keep recovery separate from the pre-Pond relationship fix.
- First-Berry sensitivity keeps all three recommendations viable. Latch reaches Pond at 14:53/96% with 10 median pre-Pond switches; Shallows matches timing and continuity but adds one switch, while Hammer reaches 14:55/94% with one extra switch. Recommend Latch and label the other two as immediate-use alternatives.
- Doubling Fish to two stamina without a cap still spends 23 Fish and lowers the continuity pass rate to 86%. Caps of 12 and 15 Fish restore 94% and 96%, but add an arbitrary second budget. Keep the current +1 effect and aggregate its feedback in the first slice.
- Firepit targeting is not cosmetic: current Woodcutting-only runtime passes the continuity limit in 31% of runs, the database-aligned four-skill target passes 96%, and an all-skill target passes 98%. Test the database contract first for role clarity; use all-skill only as the target-comprehension fallback.
- Pond refills of +3, +5, and +10 all yield the same 21:48 Fence median while restoring 9, 15, or 30 total stamina. Keep +5 as a visual hypothesis and compare +3 versus +5 in the real game; do not use +10 for timing.
- Current combo values with the selected systems pass continuity in 96% of runs and reach Fence at 21:43; the larger secondary-XP candidates pass in 94% and reach Fence at 21:48. Keep current activity data until complete relationship receipts are observed.
- One milestone Berry reaches Pond at 15:02 and passes continuity in 95%; two and three reach 14:53 and pass in 96%. Keep the second as a measured repetition lesson, gate the third on Pond plus two successful uses, and remove the extra sequence if comprehension does not improve.

## Priority Order

1. Keep `scripts/simulate-first-hour-relationships.py` deterministic and record a 100-seed matrix for each relationship hypothesis.
2. Protect the unpaid eight-Fish Pond cost from auto-eat, show the spendable surplus, and name the non-Fishing skill that consumes it.
3. Teach Fish as sustained support for the selected target, with one full first-use receipt and aggregated consecutive-use feedback.
4. Show what each source skill unlocks, supplies, or improves at the destination, including data-authored Pond support on the four early combo actions.
5. Reconcile Firepit target, ignition cost, 1-Scrapwood-per-minute rate, XP per fuel, heat tiers, and cooling through database metadata, runtime, UI copy, and its focused test; remove the direct-start cost bypass.
6. Keep Pond construction at Building 5 + 8 Fish, preserve the current base bonus array, and add the first-success relationship floor: +1 percentage point per unique early combo, up to +5%.
7. Test a capped +5 stamina completion refill with truthful increased/full gauge states; compare +3 and +5 visually without changing the relationship floor.
8. Prevent Berry Prep from multiplying its own Berry source.
9. Use one Berry eligibility rule across preview, standard actions, Fishing, queue, offline retention, and save restore. Keep offline consumption off until base offline split XP, materials, Fishing currency, batching, and summary feedback can honor the same reward.
10. Grant the first two milestone Berries, mark the Pond reward ready out of order, and award it only after two successful one-shot milestone uses. Keep persistent access in the Skills menu and add no temporary carry cap.
11. Validate Fish, Berry, and Pond comprehension before testing Honey as one explicit ten-second global timing choice or changing candidate combo data.
12. Keep the level 6-8 recovery actions self-targeted and outside relationship milestones in the first slice; any later `lowest` experiment must preview and receipt the actual destination.
13. In the first Berry chooser, recommend Latch as the integrated two-skill lesson and label Hammer Nails and Shallows with their immediate Hub or Pond outcomes.
14. Do not increase Fish stamina value or add a Fish-spend cap before first-use comprehension is tested; the current effect performs best without another budget rule.
15. Measure whether players understand Firepit's four non-Woodcutting targets. If fewer than 70% do, compare the all-skill target at the same one-Scrapwood-per-minute rate.
16. Validate the Pond's +5 completion refill on real gauges against +3; retain the smallest value that players notice with the exact-gauge receipt.
17. Keep current combo stamina, duration, and XP in the first slice. Reopen one secondary reward only if fewer than 70% of players identify or value it after the full receipt is shown.
18. Treat one milestone Berry as the mechanical minimum. Keep the second only if repeated-use comprehension improves; keep the use-gated Pond Berry only if at least 60% earn it, assign it, and start its named next relationship within two minutes without reducing Pond comprehension below 70%.

## Planning Rules

- Do not add a new resource when an existing material can express the relationship.
- Do not let a treat multiply or fund its own source.
- Do not let automatic Fish consumption spend a protected shared-goal cost.
- Keep Fish auto-spending live-only in this slice; queue and offline progress retain their current no-auto-spend behavior.
- Do not use more cross-skill locks as a substitute for visible payoff.
- Do not count self-recovery as a cross-skill reason or retarget it implicitly to simulate one.
- Keep normal activities available while the Pond project is active.
- Keep Pond support separate from construction costs and allow every point before or after restoration; a fast route must never appear incomplete.
- Show no more than two relationship chips on one activity card.
- Do not duplicate an existing lock or split-XP value with a relationship chip on the same card.
- Do not add a milestone Berry capacity or pending overflow. Show the unearned Pond reward as `use X/2`, preserve carried Berries, and award it only after both use and Pond conditions are true.
- Edit `docs/activity-database.json` first when an approved plan changes activity data.
- Store Pond support in each action's `relationship_rewards` data and persist first-success claims by stable action ID; do not duplicate the four IDs in runtime.
- Treat `plan-v0.5.0.md` as historical context, not the active priority list.

## Module Type Names

See `module-type-dictionary.html`.
