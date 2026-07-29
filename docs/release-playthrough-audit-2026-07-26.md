# Release Playthrough Audit — 2026-07-26

## Recommendation

Do not publish the current build.

## Release blockers

### 1. A new install skips onboarding

Severity: Critical

Reproduction:

1. Launch with an empty isolated `user://` directory.
2. Wait for boot to finish.

Observed:

- The game opens the full Fighting page with no tutorial prompt or arrow.
- The newly written save has `onboarding_tutorial_complete: true`, `skill_swipe_tip_seen: true`, and `onboarding_explore_tip_seen: true`.
- `SaveRuntime._start_new_save_file()` saves the initialized state without starting the tutorial.
- The tutorial appears only after the hard-reset path calls `_start_tutorial()`.

Expected:

- A genuinely new player should enter the same onboarding flow that the reset tutorial tests exercise.

### 2. Tutorial level-2 lock interaction fails

Severity: High

`scripts/test-tutorial-live-guidance.ps1` fails:

```text
lock first tap did not unlock fight:kick-mud-off-boot
```

This is a functional tutorial/progression failure, not only a visual assertion.

### 3. Woodcutting/Firepit layout fails the release gate

Severity: High

`scripts/check-project.ps1` stops at:

```text
running material reward action should reserve its collection module height
```

During the manual playthrough, the Woodcutting material/Firepit region also became cramped and overlapped by the fixed activity controls.

### 4. Fishing touch drag fails

Severity: High

`scripts/test-fishing-drag-spike.ps1` fails:

```text
touch-tile-up barely scrolled: 0 px, expected at least 400 px
```

Fishing net-offer interaction passes.

### 5. Release tests can report false passes

Severity: High

- `scripts/test-fishing-click-flow.ps1` contains misspelled commands such as `Tect-Path`; the whole-game harness still reports the test as passing.
- The Thieving click-flow run exceeded the safe Godot timeout and was stopped, but `test-everything.ps1` reported both the case and suite as passing.
- Buildable modules fails on removed `_register_action_card`.
- Mission completion ceremony fails on removed `_activity_data_catalog`.
- Page-switch visual testing calls removed `_select_skill`.

These failures make the current green test output unreliable.

## Player-visible issues

### Locked navigation messages overlap chat

Severity: Medium

- Home: `Total Lv 25 required!`
- Hub: `Lv 3 Building required!`
- Shop: `5 Bronze medals required!`

The messages render in the global-chat strip. The Shop message is partly clipped at the lower-right corner.

### Sort popup persists across navigation

Severity: Medium

Reproduction:

1. Open the activity sort popup from a skill page.
2. Open the skill overview without dismissing it.

Observed:

- `Level`, `Combo`, and `Collection` remain visible over the skill cards.

### Pinned-page title has insufficient dark-mode contrast

Severity: Medium

In dark mode, `Pinned Activities` is nearly invisible because light text remains over the light header gradient.

### Side-arrow page changes can land with the first activity clipped

Severity: Medium

Changing from Thieving to Building and then Woodcutting with the side arrows twice landed with the first activity partly above the visible content area. Scrolling upward repaired the view.

The separate page-switch visual test also fails its cover assertion and uses a removed helper.

## Passed checks

- Manual activity start/stop and XP progression in Fighting, Thieving, Building, Woodcutting, and Fishing.
- Locked activity presentation at level 1.
- Skill overview totals and skill-card navigation.
- Dark mode and stamina-decimal settings.
- Save/relaunch persistence.
- Offline progress summary.
- Tutorial start arrow placement: the arrow points at the Push-Ups card.
- Tutorial swipe navigation.
- Tutorial start-scroll positioning.
- Activity queue.
- Honey stamina regeneration.
- Battery governor.
- Boss fight gate.
- Recovery modules.
- Fishing net offer.
- Save normalization.
- Runtime asset paths.
- Activity database contracts.
- UI boundary contracts.
- Firebase config validation and runtime guard.
- Button census.

## Runtime warnings

- Normal game shutdown reports CanvasItem, Texture, font, ObjectDB, and resource leaks.
- A normal relaunch logged `Idle Elite recovered save progress from backup storage` even though the prior run exited normally and progress restored correctly.

## Coverage

Manual coverage used an isolated fresh profile and did not modify the real player save. It covered the first-run screen, all five skill pages, early progression, activity controls, skill arrows, overview, pinned page, filters, settings, locked top-level navigation, save/relaunch, and offline progress.

Hub, Shop, high-level combat encounters, high-level heists, late Fishing areas, ads, account creation, leaderboard submission, and release Android-device behavior were not manually unlocked during the fresh-save playthrough. Existing targeted checks were used where available.

## Evidence

- Tutorial start: `.codex-tmp/tutorial-visible-start.png`
- Tutorial after activity tap: `.codex-tmp/tutorial-visible-after-click.png`
- Whole-game test logs: `test-results/test-everything-20260726-193113`
- Thieving test logs: `test-results/test-everything-20260726-193149`
- UI test logs: `test-results/test-everything-20260726-193502`
- Data/assets/Firebase logs: `test-results/test-everything-20260726-193536`
