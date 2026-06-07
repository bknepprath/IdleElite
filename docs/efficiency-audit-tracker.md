# Efficiency Audit Tracker

Started: 2026-06-07

This tracks small, testable efficiency changes from the codebase audit. Each item should be implemented and play-tested separately before moving to the next.

## Checklist

- [x] 1. Avoid per-frame convergence action scans. Play-tested and accepted.
- [x] 2. Reduce `_update_ui()` breadth with active/dirty card sets. First pass play-tested and accepted.
- [x] 3. Replace common gameplay `_render_screen()` calls with targeted refreshes. First pass play-tested and accepted.
- [x] 4. Debounce save writes while preserving immediate critical saves. First pass play-tested and accepted.
- [ ] 5. Cache atlas textures and bake avoidable runtime pixel loops. First pass implemented; awaiting play-test confirmation.
- [ ] 6. Throttle chat/network frame polling.
- [ ] 7. Reuse music players/streams across music cycles.

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
