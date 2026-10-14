# Tips, ribbon and reveal verification

2026-10-13. Local 0.7.0 prototype; no export or release candidate.

## Changes

- Desktop locked ribbon icons use translucent black silhouettes. Activation checks availability and shows the actual requirement, or the estimated remaining active Skills time for an eligible feature. Existing unlock milestones and saved introductions remain intact. Queue becomes eligible when neighboring skills appear; requiring an already-populated queue prevented players from reaching queue setup.
- Shared mobile/desktop requirement feedback wraps within the viewport, holds for three seconds, fades in/out, and replaces the previous message on repeated taps. Mobile gated navigation uses the same silhouette tint.
- Pull-down tips previously forced a character-count line break into a 94px box, limited to two lines with ellipsis. The readable 52px text could not fit. Tips now use natural wrapping, a 156px region, shorter long instructions and no truncation. Visibility begins only when the pull creates enough space.
- The first successful carousel drag fades the discovery instruction over 0.4 seconds. A compact panel behind the instruction keeps it readable when activities extend to the bottom edge.
- Preview playback claims occur before staging. Repeated staging cannot re-hide an entered card. New progression slots opt out of the generic parent entrance before lazy mounting; ceremony-owned reveals bypass/cancel competing lazy fades.

## Verification

`scripts/tests/desktop_reveal_tips.gd` ran visibly with Dummy audio, isolated unsaved state and the real `res://scenes/main.tscn`. Result: `REVEAL_TIPS failures=[]`. It clicked the initial activity, crossed the Fighting level-two milestone, monitored rendered card and ancestor opacity, clicked locked Hub, opened unlocked Queue, dragged the carousel, and pulled Building's actual scroll surface. All 19 tips fit with no hidden lines at desktop 1920x1080 and portrait 1080x1920. A repeated-callback check retained entered-card opacity.

The original appear/disappear/reappear animation was not reproduced in the automated baseline. Post-fix monitoring found no opacity regressions, but user confirmation of that intermittent report remains needed.

Raw viewport captures (unmodified):
- `../../.codex-tmp/desktop-discovery/ribbon-locked-requirement.png`
- `../../.codex-tmp/desktop-discovery/pull-tip-desktop.png`
- `../../.codex-tmp/desktop-discovery/pull-tip-portrait.png`
- `../../.codex-tmp/desktop-discovery/unlock-audit-0.png`, `unlock-audit-1.png`, `unlock-audit-2.png`: same-run entrance frames.
- `../../.codex-tmp/desktop-discovery/drag-hint-before.png`, `drag-hint-transition.png`, `drag-hint-settled.png`: same-run dismissal frames.

## Fishing-zone spacing correction

Restored the original 27px card-side margins and 260px method-column reservation. Location tile size and 14px inter-column gap remain unchanged. Kept the compact 192px right-side stat boxes, 48px text and 8px internal stat padding. No new animation scaling or position correction was needed.

Actual desktop Fishing input/layout passed in `desktop_activity_feedback.gd`; its desktop-to-portrait navigation check was intermittent, so this combined test is not recorded as a full pass. A fresh portrait run of `scripts/tests/fishing_zone_spacing.gd` passed with actual Shallows input: `FISHING_ZONE_SPACING failures=[]`. Collision assertions now examine visible tile rectangles and artwork, excluding empty method-column/image padding; no runtime scale depends on image bounds.

Inspected raw captures: `../../.codex-tmp/desktop-feedback/fishing-net.png` (1920x1080) and `../../.codex-tmp/desktop-feedback/fishing-zones-portrait.png` (1080x1920). Android display settings were not changed. This is desktop-rendered portrait evidence, not physical-phone acceptance. No agent-owned Godot process remained after the checks.
