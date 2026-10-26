# Activity unlock barriers

Superseded on 2026-10-13 by [dedicated resource blockers](unlock-resources-070.md). The wide requirement buckets and stretched barrier layout below are rejected historical iterations, not the current design.

2026-10-13. Locked project activities are covered by a complete illustrated wood or stone obstruction, roughly the size of the activity with a slightly larger irregular silhouette. This supersedes the rounded, cropped wooden face and the earlier tall checklist. The full outline and lower thickness are visible; no activity-shaped mask or ordinary colored frame is drawn around the cover. The list slot remains compact (378 logical pixels for Repair Small Shack).

## Requirements

The cover now carries a distinct thick-bordered requirement bucket. The bucket groups the exact source activity name, its existing action artwork, and a filled success counter. Repair Small Shack shows Patch Fence and 5/8 successes, rather than Boards fitted. Failed attempts do not advance it. Clicking the bucket navigates directly to that activity. The first unfinished requirement occupies the bucket; the info control opens all requirements. Materials use an explicit Add action and are charged once. Wisdom has its own count and routes to an available Wisdom activity.

Work, committed resources, and Wisdom clear the obstruction independently of level. After a short completed-state hold and fade, the production list replaces the barrier with the ordinary activity card. If levels remain, the normal level padlock and its XP bar stay in place. The existing level, boss, and manual/automatic unlock rules still control access. Restoring completed work does not bring back the cover.

## Rendering

`project_panel.gd` draws complete atlas rows in fixed authored boxes, extending 16 logical pixels horizontally and 24 below the ordinary activity root. The upper extension is 24 for timber and 44 for stone, leaving room for long titles inside the stone's irregular top. There is no activity-shaped mask and no alpha-bound scale adjustment. Fighting and Thieving use stone; Building, Woodcutting and Fishing use timber. All three damage states share each material's canonical box.

Titles use the bold game font at 60 logical pixels with an 18-pixel black outline. Requirement names and counts use 52 with a 16-pixel outline. The bucket border is 10 pixels and the progress rail border is 6. Text and rail widths are anchored to the bucket so they follow desktop and portrait resizing. Title and info insets keep them within the silhouette.

Progress eases over 0.28 seconds; damage crossfades over 0.30 seconds. Completed barriers hold for 0.30 seconds, fade over 0.22 seconds, then refresh their lazy-list entry. The shared runtime owns and deduplicates that deferred refresh so removing the old control does not cancel it. No IDs, target counts, rewards or saved fields changed. This requirement-bucket revision adds no image assets.

## Assets and prompts

Built-in ImageGen was used. Approved style anchors: `assets/content/hub/hub-decor-sheet.png` and `assets/content/build/actions/02-patch-fence-with-confidence.png`. The existing timber atlas was a composition reference only. Stone prompt: [exact generation prompt](project-stone-generation-prompt.txt).

Stone source: `C:/Users/bknep/.codex/generated_images/01a12c89-c112-70b3-966d-a5359da3677b/exec-9804f008-aec7-4635-aac0-5ac27b17436d.png` (1254x1254, transparent alpha). Three fixed source regions `(0, 31 + row * 388, 1254, 392)` were mechanically resized to 768x230 and packed into `assets/content/ui/project-stone-states.png` (768x690). Runtime keeps each entire row. PNG: 520,426 bytes; lossless imported texture: 519,434 bytes, approximately 0.50 MiB before package compression. All stone projects share it. Source master stays outside exports.

Timber source: `C:/Users/bknep/.codex/generated_images/01a12c89-c112-70b3-966d-a5359da3677b/exec-e99c1c4c-aa92-49f8-9d65-1b23da64c900.png`. Existing runtime sheet: `assets/content/ui/project-timber-states.png` (768x690), reused unchanged. This revision uses full 768x230 rows, preserving their chipped edges and lower bevel.

## Verification

`res://scripts/tests/project_bucket.gd` runs the actual `res://scenes/main.tscn` through the safe wrapper with Dummy audio, isolated test data, and network/save writes disabled. The former barrier test paths delegate to it. It checks actual source navigation/training, permanent work, wood and stone progression, barrier-to-level-padlock replacement, completed-work restoration, one-time material payment, and Wisdom completion. Source training is stopped before deterministic portrait capture.

Raw viewport files in `.codex-tmp/desktop-responsive/`, without postprocessing:
- `bucket-wood-before.png`, `bucket-wood-transition.png`, `bucket-wood-half.png`: 1920x1080 wood progression.
- `bucket-stone-before.png`, `bucket-stone-transition.png`, `bucket-stone-half.png`: 1920x1080 stone progression.
- `bucket-wood-portrait.png`, `bucket-clearing-transition.png`, `bucket-level-padlock-portrait.png`: 1080x1920 work, fade, and remaining level lock.
- `bucket-stone-portrait.png`, `bucket-stone-level-padlock.png`: 1080x1920 stone and remaining level lock.
- `bucket-materials.png`, `bucket-wisdom.png`: 1920x1080 later requirements.

Final result: `PROJECT_BUCKET failures=[]`; raw PNG dimensions verified as 1920x1080 or 1080x1920. Wood, stone, material, Wisdom, and remaining level-lock views were inspected.

This is local prototype validation, not physical Android rendering acceptance or a release build.
