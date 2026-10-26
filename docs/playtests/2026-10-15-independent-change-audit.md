# Independent review of October 14 audit fixes

Reviewed October 15, 2026, America/Chicago.

## Scope and result

Reviewed the other agent's 31-script patch against its pre-fix backup, plus its two release-note changes. The active source is `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p`, branch `codex/progression-070`, HEAD `418d5398`. The top-level 4K checkout is archived. The current Git diff includes weeks of work and is not the correct boundary for this four-hour review.

The patch improves several credible bottlenecks and fixes: repeated achievement and project calculations, synchronous saves on common inputs, offline stamina simulation, cold-load ordering, queue selection, deferred-call loops, touch ownership, and chat scroll following. One new correctness defect was independently reproduced. This is not release acceptance.

No game code was changed during this review. Tests used isolated user-data directories, disabled online requests, and headless Godot through the safety wrapper. No import, export, deployment, visible game, browser, or phone validation was performed.

## Finding: preserve fractional Fire Pit fuel debt through save/load (P2)

`scripts/gameplay/passive_modules_runtime.gd:420-430` introduces `fuel_due` to accumulate the fractions of Scrapwood that the one-second tick cannot charge to the wallet. Both `for_save()` and `restore_from_save()` pass through `SaveStateNormalizers.firepit_state()`, whose explicit dictionary at `scripts/save_state/normalizers.gd:46-56` omits that field.

Independent reproduction with the production runtime:

1. Unlock the Fire Pit and give it 20 Scrapwood.
2. Run one second of fuel consumption.
3. Serialize through the production `for_save()` and restore through `restore_from_save()`.
4. Live debt is `0.03333333333333`; the serialized and restored debt fields are absent.

Each reload can forgive the unpaid fractional fuel while retaining burn progress. The advertised one-Scrapwood-per-30-seconds accounting therefore does not hold across restarts. Persist a bounded `fuel_due`, default it to zero for older saves, and test interruption after one and two seconds as well as uninterrupted ticking.

Evidence: `.codex-tmp/independent-audit/review_edges.gd`, `.codex-tmp/independent-audit/edges-v2.log`.

## Independent checks

| Check | Result |
| --- | --- |
| Save hardening, production test | PASS |
| Legacy v1 save update and cloud-restore regression protections, production test | PASS |
| Activity database contracts | PASS |
| Crash-safety contracts | PASS |
| 1080p migration contracts | PASS |
| Performance resource contracts | FAIL: six stale image-import settings |
| Fractional Fire Pit debt round trip | Defect reproduced |
| Sampled per-completion versus deferred project-resource awards | No discrepancy found in sampled level 1, 3, and 8 states; not a proof over all unlock transitions |

The resource-contract failure lists:

- `assets/content/events/halloween/decorations.png.import`
- `assets/content/events/halloween/doorstep.png.import`
- `assets/content/events/halloween/items.png.import`
- `assets/content/ui/project-stone-states.png.import`
- `assets/content/ui/project-timber-states.png.import`
- `assets/content/ui/boot/progression-070.png.import`

These imports were not changed in the reviewed patch; the other agent also recorded this baseline failure. They remain unresolved rather than new regressions from these fixes.

The first custom fixture attempt timed out during shutdown and did not load the full action catalog. Its empty-state result was discarded. The corrected fixture explicitly loads the production catalog, reproduces the fuel defect, and exits successfully. Logs for both attempts are retained.

## Material behavior changes and remaining limits

- Offline stamina-limited activities now follow live stamina rules at the existing 30% XP/mastery rate. The other agent measured approximately 3.3 times the previous long-absence completions in late-game examples. This is a balance change, not only an optimization; the rate needs acceptance before release.
- Frequent inputs now mark the save dirty and rely on the existing 15-second autosave and lifecycle saves. An abrupt process termination can lose recent input state that formerly forced an immediate save. The checksum, staged write, backups, and progress-regression guard remain; the independent save tests passed.
- The other agent reports 65 passing project checks out of 93, with 25 baseline failures and three requiring a visible game. Those aggregate counts were not independently rerun here. Its strict skills-page performance check still fails, and some catch-up work remains synchronous.
- Touch ownership, slow scrolling, Fishing catch-up while scrolling, chat following, and queue UI changes have no new real-game screenshot or physical-phone acceptance in this review. Headless results cannot establish their visual correctness or clear Samsung rendering risks.
- Live authentication and cloud retry behavior were not exercised against Firebase. Static review and offline save tests cannot establish live service compatibility.
- The four-hour fixes are local working-tree changes. The earlier GitHub consolidation is a separate snapshot; this review did not publish or reconcile branches.

Source evidence: `H:/Codex/Projects/IdleElite/outputs/onigiri-audit-2026-10-14/AUDIT.md` and `fixes.patch`. A small review copy is at `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/recent-change-review/`. Independent logs are in the active checkout's `.codex-tmp/independent-audit/`.
