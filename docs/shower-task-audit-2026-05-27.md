# Shower Task Audit - 2026-05-27

This is a queue of medium-to-long tasks that are safe for an agent to grind on while you are away. The project already has a lot of polish work in flight, so the bias here is toward work that either produces a useful artifact or changes code in small, testable steps.

## Current Snapshot

- `scripts/main.gd` is the whole game shell: custom controls, gesture routing, UI renderers, save/load, stamina, offline progress, passive modules, achievements, ads, music, and SFX.
- `docs/activity-database.json` is the live source for skill/action content. The game loads it at startup.
- The activity database currently has 5 skills, 126 actions, 1 passive module, and no missing art/background references.
- The working tree already has unrelated edits in `scripts/main.gd`, `project.godot`, Play Store docs, export presets, and the activity database. Future agent changes should stay narrowly scoped unless the user asks for a broader cleanup.

## Work Completed During This Audit

- Added `scripts/audit-activity-database.ps1`.
- The audit checks skill/action ids, duplicate ids, empty action lists, monotonic unlock/stamina/XP/time/success curves, missing action art/background paths, passive module shape, and drift between JSON global rules and `scripts/main.gd` constants.
- Current result: pass. No missing activity assets and no balance-curve errors.
- Added `scripts/simulate-first-five-minutes.ps1`.
- The simulator reads the activity database and runs simple expected-value openings for `StayFight`, `RotateLowStamina`, `BalancedTour`, and `ChaseNewestUnlock`.
- Current simulator caveat: it models base stamina, regen, action time, success chance, and tired-training speed, but it does not yet model crits, streak XP, mastery bonuses, manual lock-click timing, ads, or global medal buffs.

Run it with:

```powershell
.\scripts\audit-activity-database.ps1
.\scripts\simulate-first-five-minutes.ps1
.\scripts\simulate-first-five-minutes.ps1 -StaminaMode WaitForStamina
```

## Good Long-Running Tasks

### 1. Deepen The First Five Minutes Balance Simulator

The first version now exists. A good follow-up is to make it closer to the real game:

- Add crits, fifth-repeat streak XP, mastery rewards, activity medal bonuses, and global medal buffs.
- Model manual lock-click unlock timing separately from automatic level eligibility.
- Add CSV/Markdown output for tuning notes.
- Compare current tired training against wait-for-stamina and reduced-reward tired training.

Why it is worth doing: the game has enough content now that tuning by feel alone will get slippery.

### 2. Decide and Polish Tired Training

Right now `_process_action()` lets actions keep moving at 20% speed when stamina is short, then still resolves the action. This might be a friendly idle fallback, but it weakens the PRD's rotation pressure.

Useful options:

- Keep it and make the UI call it out as a deliberate `Tired Training` mode with weaker rewards.
- Make tired completions grant only mastery/failure-style progress, not full XP.
- Stop action progress at 99% until enough stamina regenerates.
- Add a setting/experiment flag so balance can be tested both ways.

Best next step: document the intended feel, then implement the smallest version and validate with the simulator above.

### 3. Main Script Section Extraction

Split `scripts/main.gd` gradually without changing behavior. Good seams:

- Embedded drawing/control classes near the top into separate scripts under `scripts/ui/`.
- Activity database loading and action math into a data helper.
- Audio/music flow into an audio helper.
- Save/load/offline progress into a state helper.

Guardrail: one extraction per commit, with `.\scripts\check-project.ps1` after each extraction. Avoid broad renames while the gameplay file is already dirty.

### 4. Activity Database Authoring Lint

Extend `scripts/audit-activity-database.ps1` from a validator into an authoring assistant:

- Report XP per second, XP per stamina, expected XP per minute after success chance, and time to unlock next action.
- Flag outliers by skill and tier.
- Warn when action names are too long for mobile cards.
- Verify generated `docs/activity-database-data.js` matches the JSON source.

This is safe, useful, and can run without launching Godot.

### 5. More Passive Modules

The passive-module UI exists and the database has one Woodcutting log collector. A contained systems task is to add the next passive module using the existing shape:

- Choose a skill identity first, such as Fishing bait prep or Build town work orders.
- Add JSON data and art references.
- Reuse the existing passive card path before adding new UI concepts.
- Validate audio volume if adding any SFX; start quieter than existing UI cues.

This should start as data/content before code expansion.

### 6. Gesture Regression Notes and Harness

The recent swipe/lock work was tricky enough to deserve repeatable coverage. A useful long task:

- Write a small Godot validation scene/script that boots headless, instantiates `Main`, and exercises page switching/unlock state transitions enough to catch obvious runtime errors.
- Keep visual gesture QA in docs until a reliable headless synthetic-input approach exists.
- Expand `docs/bug-squash-swipe-lock-postmortem.md` into a checklist for future interaction work.

Use only `.\run-godot-safe.ps1` or `.\scripts\check-project.ps1` for validation.

### 7. Launch Readiness Hygiene

The Play Store docs are active and have multiple dated readiness files. A safe documentation task:

- Consolidate the current launch blockers into one active checklist.
- Keep historical readiness notes as snapshots.
- Verify the privacy policy placeholders are still intentional before release.
- Avoid changing release/export settings unless explicitly requested.

## Suggested Agent Order

1. Run the activity database audit.
2. Run `.\scripts\check-project.ps1`.
3. Build the first-five-minutes simulator.
4. Use simulator output to decide tired-training behavior.
5. Make one small behavior or cleanup change.
6. Validate again through the safe Godot wrapper.
