# Fishing and queue audit

Implemented in the 1080p worktree.

- Fishing uses native method buttons. Queue selection lets those buttons handle their own presses and remembers the selected location in the existing saved selection data.
- Queue targets resolve from game state, including when the fishing page is not mounted. Rebuilding the overview no longer changes the selected fishing method.
- Fishing consumes no stamina. In a mixed queue, it completes at least one attempt and remains active until the next training skill has full stamina, then advances. A single fishing entry stays active; multiple fishing-only entries rotate after an attempt.
- Starting a queue on its already-running action succeeds. Normal activity buttons on the queue page now start the queue.
- Queue editing has a Done button. The queue scroll area reserves space for the utility controls so its footer can be reached.
- The overview calls the fishing surface's module builder. Its total-level label updates and is included in cached-menu reference swaps.
- Latest-activity scrolling aligns the unlocked activity instead of blindly using the maximum scroll offset. Single-activity pages start at the top.
- Delayed fishing catch feedback checks that the game still exists before creating effects.

Validation:

- `scripts/test-activity-queue.ps1`: passed.
- `scripts/tests/fishing_queue_audit.gd`: passed, including actual native button presses, real fishing attempt completion, passive stamina regeneration, selected Rocks persistence, fishing-only rotation, restarting an active queue, and cached total-label updates.
- `scripts/tests/first_session_input.gd`: passed mouse/touch and drag-cancellation coverage across three window sizes.
- Both UI boundary contract scripts passed. Targeted `git diff --check` passed.
- Visible production main-scene checks confirmed normal queue-button startup, Shallows/Rocks switching, Done navigation, accessible Clear Queue, active fishing overview rendering, and total-level updates from 16 to 17 during play.
- Raw inspected proof captures are 1080 x 1920 under `.codex-tmp/input-fix-validation/fishing-audit-{page,queue,done,overview}.png`.

The headless test harness still reports RID/resource leaks at shutdown. Gameplay assertions pass; these shutdown leaks were not resolved by this audit. All owned Godot test processes were closed. The user's Project Manager was left open.

## Native fishing controls follow-up

All location methods share `_connect_fishing_button`, along with medals, method locks, equipment offers, tool selection, auto-eat, the wallet, and active-tool feedback. Activation uses native `BaseButton.pressed` on release with a shared scroll/swipe suppression check. Removed the separate global offer, lock, active-tool, and wallet click routers, plus the wallet's duplicate hit button. Equipment offer buttons cover their cards while retaining centered artwork. Page scrolling and module gestures remain separate from button activation.

`scripts/test-fishing-net-offer-click.ps1` now runs actual viewport input against the production main scene through `scripts/tests/fishing_native_controls.gd`. It covers mouse/touch wallet toggles, lock requirements, offer drag cancellation, net collection, tool selection, and purchases of the rod, both rod upgrades, boat, and mirror. All assertions passed. The first-session input regression and both UI boundary contracts also passed. The broader run exposed a stale control reference in delayed unlock animation cleanup, which was fixed and retested without script errors.

Visible native-wallet, locked-tool, Pier-lock, and net-collection interactions were checked. Raw 1080 x 1920 captures: `.codex-tmp/input-fix-validation/fishing-native-wallet.png` and `fishing-native-lock.png`.

## September 7 dead-code audit

Removed 415 additional production lines relative to the completed native-button migration:

- Removed the never-set manual fishing press state, its reset scans, and callers that checked that inactive state.
- Replaced the four-source method hit-candidate search with the existing native button group. The remaining containment checks support shared page/module gestures; they do not activate fishing methods.
- Removed permanently disabled invisible stat buttons and their construction, update, and fade bookkeeping.
- Removed the unused alternate wallet renderer and coordinate-selection machinery from the fish gauge. The production wallet remains in `FishingUiSurface`.
- Removed obsolete offer hit-test helpers, redundant native-handler guards, and unused feedback coordinates.

Production line counts: fishing UI 5260 to 4993; input routing 1558 to 1546; fish gauge 393 to 259; main 1248 to 1247; navigation 5297 to 5296. Fishing economy, save compatibility, animation presentation, and lazy rendering remain intact. No intentional appearance or gameplay-rule changes.

First-session mouse/touch/drag regression, full native equipment/wallet/lock integration, fishing queue recovery/selection regression, and both UI boundary contracts passed. The equipment integration setup now prevents high-level auto-unlock animations from moving purchase targets underneath the bottom controls. Existing shutdown resource-leak warnings remain.
