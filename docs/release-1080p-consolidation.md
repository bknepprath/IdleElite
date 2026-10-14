# Release branch consolidation (2026-09-27)

`release/1080p` is the single base for the next release. It combines:

- `codex/idle-elite-1080p-rework` plus its previously uncommitted worktree changes (saved first on `wip/1080p-rework-worktree-snapshot`)
- `codex/idle-elite-1080p-audit`
- the save, identity, crash-report, Firebase tooling and Android backup work from the 4K checkpoint `4808e81d` (ported without its 4K UI coordinates, on `port/save-identity-hardening`)

`codex/idle-elite-4k` is kept as the 4K reference. Its uncommitted cleanup was committed as `e4b80a11`.

## Why saves were being wiped

None of the save hardening had shipped. Play build code 38 (`dc0b03b1`) and itch v0.4.66 (`fdf41cdd`) use the old save code. The main causes, none of which need an update to happen:

1. **Web storage.** The game runs in a cross-site iframe on itch. Browsers can block, partition or evict that storage, and nothing warned the player.
2. **Multiple tabs.** Every tab syncs its whole in-memory filesystem back to IndexedDB, so an older tab overwrote newer progress.
3. **Failed loads.** If every copy was unreadable, the game started a new save and wrote it over them. Backups were rewritten on every save, so one bad write window could reach all of them.
4. **Android backup.** It was disabled, and cloud save was opt-in, so any reinstall lost the save.
5. **Cloud restore.** A cloud copy with a newer hard-reset generation could replace a local save that had more progress.

## What this branch changes

**Saves**
- Checksummed envelope, write-then-verify, and a fail-closed boot. All ported.
- Backups are now 1 minute / 1 hour / 1 day age tiers. They rotate by rename, so rapid autosaves only replace the primary file.
- The staged save is renamed over the primary in one step; the primary is no longer deleted first.
- The blocked-boot screen offers **Copy Save Data** for support and **Start New Game**. Start New Game needs a second tap and archives the old files to `user://save-archive-<unix>/` instead of deleting them.
- A cloud save can never replace local progress that the cloud copy lacks.
- A `200` response that isn't JSON (for example a captive portal) is no longer read as "no cloud save".
- Android backup is on, and the save journal is included.

**Web** (`scripts/save_state/web_storage_guard.gd`)
- Shows a banner when `OS.is_userfs_persistent()` is false.
- Calls `navigator.storage.persist()`.
- Saves when the tab is hidden or on `pagehide`.
- The newest tab owns the save. Older tabs pause and stop every `user://` write.
- Settings gains **Export Save** and **Import Save**, web only. An import archives the current files first.

**Leaderboard**
- Progress alone no longer marks a fresh install as a legacy account. Before this fix, new players were blocked from posting scores until they signed in with Google.
- On web, old accounts with a claimed name move to an anonymous login and then the existing support-approved name transfer (with a recovery code).
- If the batched score write is denied, the game retries each category separately and holds back only the denied ones. It no longer clears the login token.
- Removed a total-XP read that the rules always denied.
- Rules: Total Level is capped at 495, the dead legacy exception is removed, and `total_xp` can no longer decrease.

**Release safety**
- `?codex_fishing_perf` (which maxed every skill) and the rendering ablation URL flags now only work in debug builds.
- `chicken_playtest.gd` is excluded from both exports.
- `run-godot-safe.ps1` now returns Godot's real exit code. It used to return 0 for every run.

## Not done on purpose

- **The Firebase rules are committed but not deployed.**
  - The live rules still accept writes without a login, so anyone can change any player's score.
  - Deploying the new rules breaks every shipped client, because they write under `p`+32 ids.
  - Order of work:
    1. Ship this build to Play and itch.
    2. Wait for adoption.
    3. Run the freeze, reconcile and receipt steps in `docs/firebase-leaderboard-setup.md`.
    4. Run `scripts\deploy-firebase-leaderboard-rules.ps1`.
- **No server-side score validation.** Cloud Functions need the Blaze plan. Until then the rules enforce monotonic scores and the caps above, but other scores are still self-reported by the client.
- **fsync on Android.** Rename-over on ext4 is atomic, and the age tiers keep older copies intact. A real fsync would need a change to the Java plugin.
- **No physical-device testing yet.** Before release, run the Android preview build on the S24 (tearing rule in `AGENTS.md`) and a web export in Safari and in Chrome with two tabs open.
- **Renderer experiment.** `VSYNC_ADAPTIVE` in `scripts/app/performance_runtime.gd` is a suspect for the tearing. Test `VSYNC_ENABLED`, and canvas_items together with gl_compatibility, on the phone before changing either.
- **Large refactors deferred.** Typing `host`, a typed action-card object, and merging the two card builders all change UI or the test doubles, so they need real-game screenshot verification under `AGENTS.md`.
