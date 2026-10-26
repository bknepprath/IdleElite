# Activity UI and mastery validation: 2026-10-12

## Changes and causes

- Outer plaques retain Tier 1, Tier 2, etc.; expanded requirements and rewards use T1/T2. Accuracy rewards use the existing yellow icon. Medal goals now show one inline medal followed by "on every T1 activity", without the old separate medal/name column.
- Tier progress used rectangular partial fills that escaped rounded ends. Partial fills are clipped to the full pill. Info popups mixed parent-local and global coordinates; they now use top-level canvas coordinates and clamp to the visible screen after layout.
- Combo bars only segmented the filled portion. Empty rails, body depth and connector faces now use both skill colors before any progress.
- Berry badges show the live inventory count centered inside the berries. A container-independent anchor keeps the number aligned. A successful final berry previously scheduled failure feedback afterward; success and failure are now exclusive. Success pulses green with a badge-owned tween that is canceled before new feedback.
- Skills utilities previously waited for a later refresh to hide. Navigation now hides them immediately on page change.
- Collapsing cards moved art, medals and other anchored body controls into the shrinking header. Those controls hide during collapse and restore on expansion, while the existing height/title animation remains.
- Resting activities no longer expose click-opportunity windows. Ordinary windows use rounded, heavy ink and yellow strokes.
- Level-up and Hub text have heavier outlines. Desktop mission refreshes preserve the Hub outline treatment.
- A real UI test exposed a freed Settings reset-button reference when starting an activity after leaving Settings. Disarming confirmation now validates references before casting; the existing refresh prunes dead references.
- All 9 diamond arena activities are excluded from mastery rewards, medal totals, tier requirements and global medal buffs, including old arena mastery entries in saves.
- All 20 resting activities award 10 mastery XP per completion instead of 1. Heavenly requires 271 completions from zero instead of 2,707. Existing mastery XP and levels are preserved; all earlier medal thresholds are reached with approximately one tenth the repetitions.

## Verification

- Production res://scenes/main.tscn, launched visibly through run-godot-safe.ps1 with Dummy audio and AudioServer muted; isolated test profiles; online requests and player-save writes disabled.
- Real UI inputs exercised activity start, final berry consumption, collapse/expand, Settings/Skills navigation, tier expansion/info, resting and the Mission Board sign in both layouts.
- Mobile 1080 x 1920 and desktop 1920 x 1080: ACTIVITY_POLISH failures=[]; no script errors in final runs.
- Tested all 20 rest and 9 arena records, Heavenly boundary at 270/271 completions, mastery save round trip, exclusion of old arena-only medals from totals/global buffs, and rejection of direct arena mastery grants.
- activity_progress_turnover.gd: activity-progress-turnover-ok.
- module_layout_performance.gd: module-layout-performance-ok.
- Activity database contract check and audit pass. Existing XP-curve warnings remain for chameleon-camouflage, study-blueprint and prune-orchard-row.
- Test profiles contain a pending-crash-report cleanup warning from earlier interrupted capture runs while writes are disabled. Final runs have no script errors.
- Safe-wrapper process checks found no remaining Godot processes after tests. No import, release export, publication or physical-phone test in this pass.

## Manual follow-up

Check rapid repeated collapse/reopen and tab changes on a physical phone, large berry counts, and the new rest-medal pace with an existing save. These desktop-rendered phone-layout captures do not replace Samsung release validation.

## Raw captures

All captures below come directly from the production viewport without postprocessing. Before, transition and settled animation frames for each layout are from that layout's final real-game run.

### Mobile

![mobile skills-before](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/skills-before.png>)

![mobile berry-pulse](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/berry-pulse.png>)

![mobile berry-settled](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/berry-settled.png>)

![mobile collapse-transition](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/collapse-transition.png>)

![mobile collapse-settled](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/collapse-settled.png>)

![mobile expand-transition](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/expand-transition.png>)

![mobile expand-settled](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/expand-settled.png>)

![mobile settings-first-frame](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/settings-first-frame.png>)

![mobile settings-settled](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/settings-settled.png>)

![mobile level-up](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/level-up.png>)

![mobile tier-expanded](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/tier-expanded.png>)

![mobile tier-info](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/tier-info.png>)

![mobile resting](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/resting.png>)

![mobile hub-mission](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/mobile/hub-mission.png>)


### Desktop

![desktop skills-before](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/skills-before.png>)

![desktop berry-pulse](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/berry-pulse.png>)

![desktop berry-settled](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/berry-settled.png>)

![desktop collapse-transition](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/collapse-transition.png>)

![desktop collapse-settled](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/collapse-settled.png>)

![desktop expand-transition](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/expand-transition.png>)

![desktop expand-settled](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/expand-settled.png>)

![desktop settings-first-frame](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/settings-first-frame.png>)

![desktop settings-settled](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/settings-settled.png>)

![desktop level-up](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/level-up.png>)

![desktop tier-expanded](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/tier-expanded.png>)

![desktop tier-info](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/tier-info.png>)

![desktop resting](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/resting.png>)

![desktop hub-mission](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/.codex-tmp/activity-polish/desktop/hub-mission.png>)

