# Wrap Hands close-up

Built-in ImageGen replacement for the rejected full-body resting portrait. Two disembodied blue hands: one wrapped, the other pulling the cloth taut. Revision removes individual finger lines from the left fist; the approved right hand is retained.

Style anchor: `assets/content/build/actions/02-patch-fence-with-confidence.png`.

Source master: `C:/Users/bknep/.codex/generated_images/01a12c89-c112-70b3-966d-a5359da3677b/exec-0d4db472-b293-46c7-8323-af4d480d62d0.png`.

Integrated: `assets/content/fight/actions/wrap-hands.png`, transparent 256x256 PNG, mechanically downsampled from the generated square. Same canonical action-art box; no runtime per-frame scale correction.

[Exact generation and revision prompts](wrap-hands-closeup-prompts.json).

The other newly added resting action portrait is `assets/content/build/actions/sharpen-the-pencil.png`; corrected after review so the wooden working end is inside the sharpener and the free end has an eraser. Source: `exec-f72730f0-68fa-4108-9386-cd13a05de9f6.png` in the same generated master directory. [Correction prompt](sharpen-pencil-correction-prompt.txt).

Validation: `.codex-tmp/rest-art-final.log` confirms the production Wrap Hands and Sharpen the Pencil cards load the intended assets and start through UI input. Inspected raw 1920x1080 capture: `.codex-tmp/desktop-responsive/art-rest-workbench-lane.png`. The broader art script reports one failed automated Count the Coins tap; its cause is not established, so this is not an all-pass result for that broader script. No agent-owned Godot process remained.
