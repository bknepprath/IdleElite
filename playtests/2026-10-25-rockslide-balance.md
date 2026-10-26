# Rockslide opening balance and rolling contact

The previous entire Speed track cost 455 Softwood and gave 120% extra firing speed. One level in Power, Speed and Volley survived for 106.5 seconds and reached wave eight. Two levels in each survived for 164.3 seconds. The opening reused identical large rocks and two fragments.

## Final behavior

The opening now alternates ordinary boulders and fast orange stones, including staggered pairs. Wave three introduces dense blue-gray armored boulders. Later patterns mix armored rocks, quick pairs/triples and ordinary boulders. Rock health, descent speed and encounter frequency rise with waves. Fast stones do not split. Ordinary boulders split into two fragments; armored boulders absorb one damage per hit and split into three. Each original rock group still pays exactly one ordinary stamina/XP/Sand reward after all its fragments are cleared. Failed or unpaid groups cannot pay twice.

Base firing remains 1.4 seconds. Each Speed level adds 12% firing speed instead of 20%. Existing paid upgrade levels remain intact. Later purchases require crafted parts and later wood rather than allowing one early stockpile to finish a stat.

| Level | Power | Speed | Volley |
|---|---|---|---|
| 1 | 15 Scrapwood | 25 Softwood | 8 Wooden Parts |
| 2 | 60 Scrapwood | 100 Softwood | 30 Wooden Parts |
| 3 | 30 Wooden Parts | 45 Wooden Parts | 80 Hardwood |
| 4 | 100 Hardwood | 150 Hardwood | 120 Wooden Parts |
| 5 | 100 Ironwood | 120 Ironwood | 140 Ironwood |
| 6 | 250 Wooden Parts | 350 Wooden Parts | 400 Wooden Parts |

## Measured pacing

These are first-knockout combat simulations with stamina replenished by the audit to isolate combat pressure. They are not real-player session-length guarantees. Upgrades are assigned before each run; no purchases happen during a simulation.

| Upgrade levels (Power/Speed/Volley) | Previous first knockout | Current first knockout | Current wave |
|---|---:|---:|---:|
| 0/0/0 | 29.7s | 19.8s | 1 |
| 1/0/0 | not measured | 35.2s | 3 |
| 0/1/0 | not measured | 25.7s | 2 |
| 0/0/1 | not measured | 36.6s | 3 |
| 0/6/0 | 52.2s | 34.8s | 3 |
| 1/1/1 | 106.5s | 38.8s | 4 |
| 2/2/2 | 164.3s | 49.4s | 7 |
| 6/6/6 | survived 300s | 69.4s | 21 |

Reports: outputs/verification/rockslide-balance-oct25/baseline.json and tuned.json. The audit is scripts/tests/rockslide_balance_audit.gd. Its shot counters are cumulative diagnostic counters across the successive cases; time, wave and clears are per run.

## Ground contact

Removed the perpetual -25 vertical-velocity bounce that made settled rocks hop. Only newly split fragments begin airborne and their bounce settles to zero. Drawing now finds the support point of each rotated rock silhouette against the actual stretched hillside slope. That point stays just inside the ground outline. Source-alpha contact hulls affect position only; the authored 512px cells and each rock type's explicit radius never change scale by frame or bounds. Projectile endpoints use the displayed rock center.

## Art

Built-in ImageGen created the fast and armored stones with three illustrated damage states each. No code-driven cracks. Delivery strips are one fixed whole-canvas resize to 1536x512. Original masters and exact prompts are saved in output/imagegen/rockslide-variety-oct25/; prompts.md records built-in tool mode and references. Patch Fence is the approved style anchor; the original rock sheet is subject context only.

Saved production assets:

- C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/assets/content/fight/rockslide/runner-damage.png
- C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/assets/content/fight/rockslide/armored-damage.png
- Contact geometry: assets/content/fight/rockslide/rock-contact-hulls.gd

## Validation

Source database contracts and structural audit passed. ROCKSLIDE_GAMEPLAY failures=[] covers exact reward accounting, armor, zero/two/three fragment counts, no stalled groups, no perpetual bounce, early mixed patterns, later material requirements, existing upgrades, save restoration, knockout/recovery and explicit stopping. The initial variable-fragment implementation exposed incorrect group counts; that was corrected before acceptance. The first contact resource used a nonconstant packed-array constructor; literal source geometry now compiles cleanly.

ROCKSLIDE_VARIETY failures=[] in the actual main scene covers mixed rocks rolling at successive angles, generated damage states, later Speed costs and fast stones appearing in the actual opening pattern. Raw 1080x1920 proof: outputs/verification/rockslide-variety-oct25/final/. ROCKSLIDE_IDLE failures=[] after tuning confirms resource taps, unaffordable inspection, purchases, the complete five-second knockout sequence, automatic wave-one restart and offscreen recovery; proof is in the recovery subfolder.

No viewport or renderer settings changed. Preview audio was muted. No release packaging or phone installation; Brian's phone-update hold remains active.
