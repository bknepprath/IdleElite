# Pre-release interaction audit: 2026-09-07

Status: desktop interaction checks passed; Android release acceptance remains pending.
Project: native 1080x1920 worktree, viewport stretch, Compatibility renderer.
Current export preset: 0.5.3, code 38. No new release artifact was built or uploaded.

## Fixes

- The pin entry seam crossed the pin body at local y=1 while the needle was clipped at y=29. Its height now derives from the clipping boundary, and its shorter authored span is centered at the needle. Collapsed, unclipped pins do not display an entry seam.
- Unpinning on the pinned page called a removed helper on main.gd, causing a script error and leaving the page stale. Both remaining callers now use the helper on SkillDetailSurface.
- The achievement toast coroutine now checks that its host still exists after yielding, preventing a freed-object error during shutdown.
- The button census now uses actual root input only, the current viewport dimensions, and the current pinned-state owner. Removed the broad ad substring exclusion that accidentally skipped pin badges.
- Restored the existing local Firebase config from the main checkout. Updated stale UI contracts to the reviewed typography and geometry. Applied the existing performance-import policy to one new boot splash and refreshed four inventory rows, preserving prior artifact-evidence columns.

## Verification

- Final real-input census: 130 clicks across 14 scenarios; 2 skipped controls (Hard Reset and Rate on Play Store). Includes home, skill menu, settings, shop, hub, leaderboard, achievements, pinned activities, queue, and all five skills. This is a visible-control smoke census, not exhaustive coverage of every progression state or network outcome.
- Native pin regression: pin two skills, navigate with the pinned button, confirm the seam meets the actual clip edge, remove a pin with touch, assert both saved membership and the visible card disappear. Passed in the real visible game and again headlessly. Permanent regression: scripts/tests/pin_native_controls.gd.
- Fresh-start input, native fishing controls, fishing queue audit: passed.
- Pinned-page interactions, activity queue controls, module list transitions, pinned scroll anchors: passed.
- Home achievement clicks, tutorial start scroll, stamina-gauge failure feedback: passed.
- Resource lifetime, activity-card geometry, medal ceremony cleanup, bottom scroll padding, hidden preview/swipe gaps, pin visual smoke: passed.
- Save normalization, crash-report recovery, woodcutting firepit interaction, runtime assets, activity database, generated-file hygiene, UI boundaries, leaderboard cost safety, crash contracts, 1080p contracts, and performance resource contracts: passed.
- The full check-project run initially stopped at missing Firebase config, then at stale boot-splash import metadata. Both were fixed; the affected gates and remaining focused interaction/layout gates were run separately. A single uninterrupted final check-project/performance acceptance run has not been completed.
- Existing RID/ObjectDB shutdown warnings remain; resource-lifetime assertions passed. No final census or native pin regression script errors.
- Native pin captures were inspected as raw 1080x1920 PNGs: .codex-tmp/release-audit/pin-page.png and pin-removed.png. The first card's pin is partly behind the fixed header; the fully visible second pin shows the corrected seam.
- Final process check left only the user's pre-existing Project Manager (PID 18208).

## Release work still required

- ADB reported no connected device. The final Android build must be inspected on a physical Samsung phone for tearing and touch behavior.
- Restore/install the Android release build template: android/build/libs/release/godot-lib.template_release.aar is absent in this worktree. The worktree also has no upload keystore; the existing signing material remains in the main checkout.
- Build and validate the signed release AAB, then test Play installation/update, ads/consent, billing where applicable, and live service outcomes. These were not exercised by desktop button clicks. No messages or purchases were submitted.
- Rerun the final project gate and complete device acceptance before publishing.
