# Ponytail Main.gd Line Reductions

Target: reduce bulky or pointless code in `scripts/main.gd` without behavior changes.

| Step | Lines removed | Running total | Change |
| --- | ---: | ---: | --- |
| 1 | 15 | 15 | Removed two one-use fishing wrapper helpers and simplified the mobile battery-governor predicate. |
| 2 | 32 | 47 | Inlined single-use save wrappers for trivial clamps/flags and removed the one-line local-save wrapper. |
| 3 | 104 | 151 | Inlined another batch of single-use save clamps/cursors and removed their wrapper functions. |

Current reality: 151 net lines have been removed from `scripts/main.gd`. Prior doc/HTML cuts, blank-line deletion, and extraction-only moves were reverted because they did not match the goal.
