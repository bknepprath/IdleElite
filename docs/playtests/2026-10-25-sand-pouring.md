# Extended sand pouring animation

Added six generated carry, turn, reach, tilt and recovery poses to the existing six-cell Sand animation atlas. The current sequence uses eleven distinct body poses and repeats ready at the end. It spends separate intervals carrying left, extending over the bucket, tipping partially, tipping empty and recovering. A separately generated four-frame gold-Sand effect shows the onset, falling stream, landing and final grains over progress 0.64–0.90.

The generated body/equipment sources exclude buckets, ground mounds and transient particles. Packing aligns feet to one authored (320,540) anchor on a 640px canvas and composites the same stationary bucket/mound into every body frame. The original batch uses one fixed scale; the new batch uses an explicitly reviewed 0.94 scale to match it. Every final cell is uniformly resized to 384px. No runtime per-frame scaling or alpha-bounds fit is used. The VFX uses one authored crop, box and anchor for all four frames, preserving its downward spacing; it is independent of body/equipment art and gameplay rewards.

Added `frame_overlay` support to the existing action-art effect contract. The overlay has matching portrait framing and rounded masking, follows only actual action progress, never advances on a separate timer, and clears on stop and before ready. Existing paint recolor effects keep their timer/shader behavior; ordinary progress-synced animations are unchanged.

Validation passed:

- Database contracts, activity audit and runtime asset paths
- `action_art_overlay.gd`: all four effect intervals, clearing, stop reset, no separate timer, existing recolor and ordinary synced animation regressions
- Actual visible main-scene `sand_scooping_capture.gd`: real Building navigation/portrait tap; natural dig, lift, carry and reach; all four falling-Sand frames; effect clearing; exactly two Sand awarded; stop/ready and inventory close
- Required Building screen audit
- Raw 1080x1920 idle, reach, pour and settled frames from the same final run inspected

Evidence: `outputs/verification/sand-pour-oct25/final/`; sources, contract, deterministic packing and normalization metadata: `output/imagegen/sand-pouring-oct25/`. Runtime assets are `gather-sand-atlas-v2.png`, `gather-sand-idle-v2.png` and `sand-pour-atlas.png` under `assets/content/build/animations/gather-sand/`. Original generated body sheets remain available for provenance. Preview audio muted; no phone install or publication.

The previous full `check-project.ps1` attempt remains blocked by the existing 32px Privacy control at `scripts/ui/privacy_surface.gd:175`; this task does not claim a green whole-project or release check.
