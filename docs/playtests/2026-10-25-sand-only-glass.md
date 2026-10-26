# Sand-only Glass production

Removed the per-batch Scrapwood input from Melt Sand in the authoritative database. Its recipe is now 2 Sand to 1 Glass. The existing dynamic factory UI automatically shows one centered Sand inventory above, one Glass inventory below and a shorter recipe row. Timing, XP, output, construction costs and the continuous V-tip connector retain their existing behavior.

Added exact legacy paid-recipe recognition for active Melt Sand reservations and queued Glass jobs. Old reservations retain their already-paid work and elapsed queue time rather than being discarded or charged again. Previously spent wood is not refunded. Arbitrary or underpaid old input dictionaries remain invalid.

Validation passed:

- Database contracts and activity audit
- `production_paths.gd`: production with zero wood, single payment, actual completion, reload/exhaustion, old active and queued reservations, rejection of malformed reservations and existing connected production/offline regressions
- Real-main `factory_inventory_capture.gd`: zero-wood start and completion, one centered input box, fixed costs, live counts, source/output controls, missing Sand guard, continuous connector pixel test and stop state
- Required Building screen audit

Inspected raw 1080x1920 proof: `outputs/verification/sand-only-glass-oct25/melt-sand-live-inventories.png`. Full result: `outputs/verification/sand-only-glass-oct25/result.json`. No phone installation or publication performed.
