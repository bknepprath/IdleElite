# Idle Elite 0.7.1 / code43 readiness - October 21, 2026

Changelog: Ads backend update.

Current state: preparation in progress. Not uploaded to Google Play.

The AdMob app and Boost Rewarded unit were created under the existing publisher pub-4125359195200512, Google account weskillnow@gmail.com. Reward settings match the old unit: amount 1, item Boost XP + Speed. No main-account payments, tax, identity or YouTube settings were changed.

App ID: ca-app-pub-4125359195200512~1607281974
Rewarded unit: ca-app-pub-4125359195200512/8284370963
Debug test unit remains ca-app-pub-3940256099942544/5224354917.

Production baseline: builds/android/idle-elite-release-v0.7.0-code42.aab; Play Console confirms code42 is the highest uploaded bundle. Current viewport and gl_compatibility rendering settings are preserved. Extensive existing worktree changes predate this migration; the migration's own edits are ID replacements, version/export path, dual app-ads.txt lines, changelog and release documentation.

Source: C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p
Scratch: I:\Codex\Scratch\IdleElite-admob-071
H: is verified Flareon 4TB with only about 55 MB free; no storage cleanup was performed.

Outstanding:
- Publish dual-publisher app-ads.txt on idle-elite.web.app after refreshing the authorized Firebase CLI session.
- Verify app-ads.txt in AdMob; account approval and app readiness remain pending.
- Finish required check-project.ps1 validation; first invocation could not locate the old default Godot path. Rerun uses installed official Godot 4.7.1 through the safe wrapper with process-local GODOT_BIN.
- Build signed AAB with the guarded build script and code42 as the existing-release baseline; do not skip live Firebase rules verification.
- Verify signature, manifest, native page alignment, bundle validation, export exclusions, sizes and hashes.
- Physical-device test with Google test rewarded ads: load, cancellation without reward, completion grants Boost, no duplicate reward, muted monitoring, no rendering corruption.
- Stop for Brian's explicit go before production upload. Do not close the old account or remove its seller line.

The old account must remain active during rollout. A completion-reply draft must not claim closure until closure is confirmed after separate approval and balance disclosure.
