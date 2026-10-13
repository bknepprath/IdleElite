# Feedback follow-up validation

## Changes

- Activity help describes duration bonuses as “less time,” matching the calculation. Nearby medals and previous-tier medals identify their source and whether they reduce time/stamina or increase success chance. Medal help and tier reward text use the same terminology.
- Expanded XP results show exact whole-number rewards instead of three-significant-digit approximations. A rounding explanation appears when an active bonus rounds back to a base reward. The actual reward calculation is unchanged; its unrounded calculation is shared with the explanation check.
- Base and boosted values retain Fredoka and black outlines; boosted values remain yellow.

## Regression coverage

`scripts/test-ham-feedback.ps1` now also checks:

- Small XP bonuses show the actual rounded reward and explain why it is unchanged; larger rewards show the increase, and unboosted rewards omit the note.
- A 1,234 XP reward remains exactly 1,234 in expanded help.
- Complete production save payloads survive JSON serialization and restoration into a fresh main-scene instance, preserving completed and pending upgrades, materials, berries, berry selections, missions, active action, and partial progress.
- A restored upgrade completes without a second material charge.
- Offline elapsed time advances the restored activity, secondary XP, berries, and missions; zero elapsed time grants no duplicate rewards.

Passed: feedback regressions, save hardening, legacy save-update integration, lifecycle save guards, crash-report recovery, crash audit contracts, repeated-navigation resource lifetime, fishing/recovery balance, full feedback UI captures, and the 14-screen audit. Short/long time panels, medals, and multi-skill XP were captured and inspected in the real main scene at 1080 × 1920. No Godot process remained after validation.

## Outstanding validation

- Strict scrolling/swiping timing checks remain failing. The first completed run failed Thieving's 22 ms maximum scroll-frame budget. The diagnostic rerun measured Thieving at 29.163 ms maximum and Woodcutting at 29.527 ms maximum (17.014 ms p99), plus a rapid Building swipe 120 FPS budget failure. No functional layout/placeholder failure or gameplay crash was reported by those runs. Timing limits were not weakened, and rendering settings were not changed.
- Repeated navigation passed with stable node and texture counts across four cycles. This does not establish physical-phone performance.
- ADB was started successfully but reported no attached device. Samsung touch, background/resume, rendering, and frame-time checks remain pending; no Android package was installed.
- The available local report records an unclean previous session without a stack trace. It does not identify Ham's crash cause. Crash-report recovery tests pass, but the unreported trigger still needs reproduction details or a device log.

Evidence: `.codex-tmp/clarity-review-captures/`, `.codex-tmp/review-performance-recheck.log`, `.codex-tmp/review-resource-lifetime.log`, and `.codex-tmp/review-*-*.log`.
