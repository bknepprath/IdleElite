# 0.7.0 progression prototype

Worktree: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`.

Experiment branch: `codex/progression-070`. Pre-experiment checkpoint: `codex/pre-progression-070`, commit `ddf96f2717f75b18250b12d0d3051fe76890a8ed`. The checkpoint includes the preceding uncommitted work without altering its staging. No release package was produced.

## Play

Open `Play Progression Prototype.vbs`, or run `scripts/play-progression-prototype.ps1`. The launcher uses the production main scene, muted audio, an isolated profile, disabled online requests, and unsaved test progress. F1 resets to the opening; F2 to the first projects; F3 to level 25; F4 to level 70. Chapter changes discard the current test session. Ordinary gameplay saves still persist project progress.

## Implemented

- 33 projects: Fighting 6, Thieving 6, Building 9, Woodcutting 6, Fishing 6.
- Successful completions visibly advance permanent local work. Failures and switching activities do not remove it. Offline completions use the same credit path.
- Source buttons navigate to the actual activity, including skills outside the visible desktop columns.
- Explicit material commitment on the first bridge; later projects introduce cross-skill work. Wisdom remains per skill and now has Fighting and Fishing sources and later gates.
- Save normalization, old-access grandfathering, and cloud regression rejection include project work.
- Current version remains 0.7.0. The flex animation and obsolete 0.6.0 engine splash are removed; bridge construction reflects actual boot progress.
- Closed a pending crash-report file before deleting it, fixing a Windows file-handle warning exposed during repeated boots.

## Verification

- Database contract and asset audit pass. The three existing lower-XP Wisdom-source warnings remain.
- Dependency audit: all sources exist; no cycles including projects required to reach source activities. Protected opening action records compare identically with the checkpoint.
- Production-scene integration passes at 1080×1920 and 1920×1080: partial restoration, counter caps, material idempotency, offline credits, grandfathered access, manual/automatic unlock, and cross-skill navigation.
- F1–F4 simulated keyboard input passes; each chapter replaces its production game scene without retaining extra root nodes.
- Stability regression suite passes. Its harness still emits known shutdown ObjectDB/resource warnings; this does not establish leak-free long sessions.
- Raw captures are in `.codex-tmp/progression-prototype/mobile` and `desktop`; the interactive launcher captures `playtest.png` at 1920×1080.

## Remaining acceptance

Play through progression pacing and task targets; these are experimental balance values. The procedural project scenes are prototype art. Dual training is excluded by explicit scope choice. This turn does not establish Android physical-device rendering acceptance or a new 30-minute performance result.
