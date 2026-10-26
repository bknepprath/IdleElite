# Gather Sand animated portrait

Follow-up: the current animation adds carry/reach/tip/recovery poses, a stationary bucket and four separately layered falling-Sand frames. See `2026-10-25-sand-pouring.md` for current assets and validation.

Replaced Gather Sand's static item portrait with six ImageGen blue guy/shovel poses: ready, dig, lever, lift, tip into a bucket and recover. The existing native `art_animation` progress-sync path runs one sequence per gathering cycle, including existing speed bonuses, and holds the ready pose when stopped. No animation-runtime change was required.

The featureless blue guy retains smooth mitten hands with no individual fingers and thick black outlines. Generated frames were mechanically extracted onto one shared 384px square canvas each and packed into a 2304x384 horizontal atlas. All frames use the same 0.75 source scale. Offline vertical translation aligns the foot baseline; source measurements affect position only, never visual scale. Artwork stays inside the production portrait mask, clear of its medal. Sand's material icon and separate success-triggered collection flyer are preserved.

Runtime assets:

- `assets/content/build/animations/gather-sand/gather-sand-atlas.png`
- `assets/content/build/animations/gather-sand/gather-sand-idle.png`

Contract, selected source, generation provenance and repeatable packing metadata: `output/imagegen/sand-scooping-oct25/`. The selected source is ignored by Godot. References were the approved Wheelbarrow and Fence style anchors, with the existing push-up blue guy and Sand item used only for character/color context.

Validation:

- Source database contracts and activity audit passed
- Headless asset import completed; tracked import descriptors were unchanged (pre-existing working edits preserved)
- `sand_scooping_capture.gd` passed in the actual visible main scene: real Building navigation and portrait tap, all six poses reached through natural action progress, inventory opening, exactly two Sand awarded, stop/reset and inventory closure
- Inspected idle, dig, tip, successful collection and stopped raw 1080x1920 screenshots from one real-game run
- Required Building screen audit passed
- Full `check-project.ps1` was attempted; it stopped on the pre-existing 32px Privacy control in `scripts/ui/privacy_surface.gd:175` during the native-1080 text audit. Earlier performance, save-normalization, asset-path, database, file-hygiene, UI-boundary, Firepit, crash and harness gates passed. The full suite is not green

Evidence: `outputs/verification/sand-scooping-oct25/`. Logs: `.codex-tmp/sand-scooping-visible.log`, `sand-scooping-contracts.log`, `sand-scooping-audit.log`, `sand-scooping-screen-audit.log` and `sand-scooping-check-project.log`.

No reward, cost, success rate, action duration, unlock, serialized ID, save format, renderer, phone install or publication changed. Preview audio was muted.
