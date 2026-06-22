# Efficiency Audit Tracker

Started: 2026-06-07

This tracks small, testable efficiency changes from the codebase audit. Each item should be implemented and play-tested separately before moving to the next.

## Checklist

- [x] 1. Avoid per-frame convergence action scans. Play-tested and accepted.
- [x] 2. Reduce `_update_ui()` breadth with active/dirty card sets. First pass play-tested and accepted.
- [x] 3. Replace common gameplay `_render_screen()` calls with targeted refreshes. First pass play-tested and accepted.
- [x] 4. Debounce save writes while preserving immediate critical saves. First pass play-tested and accepted.
- [ ] 5. Cache atlas textures and bake avoidable runtime pixel loops. First pass implemented; awaiting play-test confirmation.
- [x] 6. Throttle chat/network frame polling. First pass implemented; awaiting play-test confirmation.
- [x] 7. Reuse music players/streams across music cycles. First pass implemented; awaiting live audio confirmation.
- [x] 8. Cache visible action-card stat refresh work. Headless strip suite found this as the current spike source; awaiting live FPS confirmation.

## Notes

### 1. Avoid Per-Frame Convergence Action Scans

Goal: stop scanning all actions every frame just to ensure convergence module state. Keep behavior unchanged by ensuring state when action data changes and leaving the frame loop with only a cheap dirty check.

Status: implemented; awaiting play-test confirmation.

Validation: `.\scripts\check-project.ps1` passed on 2026-06-07.

User test: accepted on 2026-06-07.

### 2. Reduce `_update_ui()` Breadth

Goal: reduce repeated per-frame work in the action card update loop. First pass caches action card keys and stores card metadata at registration so `_update_ui()` no longer rebuilds/splits the key list every frame.

Status: first pass implemented; play-tested and accepted.

User test: accepted on 2026-06-07.

### 3. Replace Common `_render_screen()` Calls With Targeted Refreshes

Goal: avoid running the full screen cleanup/router when only one page's content needs to update. First pass adds a leaderboard-local refresh helper and uses it for leaderboard fetch, submit, profile-name, and category changes.

Status: first pass implemented; play-tested and accepted.

User test: accepted on 2026-06-07.

### 4. Debounce Save Writes While Preserving Immediate Critical Saves

Goal: reduce full save-file writes from low-risk online status churn without delaying shutdown/pause saves or important gameplay purchases/unlocks. First pass adds an in-memory dirty-save marker and routes leaderboard retry bookkeeping plus chat stream retry/connectivity status through autosave.

Status: first pass implemented; play-tested and accepted.

User test: accepted on 2026-06-07.

### 5. Cache Atlas Textures And Bake Avoidable Runtime Pixel Loops

Goal: avoid rebuilding identical atlas slices when screens/cards are rerendered. First pass adds a shared atlas texture cache and uses it for hub sheet slices, fishing atlas regions, unlock padlock cropping, and generic spritesheet slices.

Status: first pass implemented; awaiting play-test confirmation.

### 6. Throttle Chat/Network Frame Polling

Goal: reduce live chat stream polling while keeping the compact skills chat strip functional. First pass removes the Hub chat strip and backs the stream poll timer off from 20 polls/sec to 4 polls/sec.

Status: first pass implemented; awaiting play-test confirmation.

### 8. Cache Visible Action-Card Stat Refresh Work

Goal: stop recomputing unchanged visible action-card XP, stamina, cycle time, and success values every frame. A headless stripped-variant suite showed that removing static action-card refresh matched the `no_ui` / `no_card_ui` performance profile, while stripping popup, mastery, run-feedback, regen, music, and background maintenance did not remove the spike.

Status: implemented with action stat value caching and action-card dirty keys; awaiting live FPS confirmation.

Validation: `.\scripts\test-skills-page-performance.ps1`, `.\scripts\test-performance-regressions.ps1`, `.\scripts\test-performance-monitor.ps1`, `.\scripts\check-leaderboard-cost-safety.ps1`, and `.\scripts\check-project.ps1` passed on 2026-06-12.

### 7. Reuse Music Players And Streams Across Music Cycles

Goal: avoid reloading the same music loop resources and recreating music players when a new music cycle chooses the song set that is already prepared. First pass adds a music stream cache beside the SFX stream cache and reuses the existing music player pool when the selected song set name and layer count match.

Status: implemented; awaiting live audio confirmation.
