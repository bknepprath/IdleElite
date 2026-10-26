# Portrait color correction, October 22, 2026

The source artwork was bright blue. The shared rounded portrait shader sampled the texture and multiplied it by fragment `COLOR`, which already contained the texture color. This squared RGB and alpha. Enabling that mask for ordinary activity portraits exposed the defect in the screenshots.

Changed `scripts/ui/action_art_ui.gd` to preserve fragment `COLOR` before applying the rounded alpha mask and any explicitly enabled recoloring. PNG files, palette choices, portrait sizes and gameplay values are unchanged. Godot documents the texture contribution to fragment COLOR in its [CanvasItem shader reference](https://docs.godotengine.org/en/4.6/tutorials/shaders/shader_reference/canvas_item_shader.html).

## Validation

The regression probe `scripts/tests/portrait_color_capture.gd` boots the production main scene, enters Fighting through its actual Skills menu, scrolls to Ice the Bruises and compares two rendered samples with the real source texture composited over the white portrait frame.

| Sample UV | Source RGBA, 8-bit | Rendered RGB, 8-bit |
| --- | --- | --- |
| (0.52, 0.34) | (0, 146, 251, 252) | (3, 147, 251) |
| (0.50, 0.78) | (1, 147, 251, 253) | (2, 147, 251) |

The result matches within one 8-bit channel step after alpha compositing. Probe result: `portrait-color failures=[]`. The raw 1080x1920 PNG was visually inspected. The two nearby older portraits also retain their source blue instead of the darkened version.

The required main-screen capture audit completed. Activity UI boundary and generated-file hygiene checks passed. Preview audio used Dummy, user data was isolated, and ordinary save writes and online requests were disabled. No release was packaged.

Capture dimensions, SHA-256 and samples: `outputs/verification/portrait-color/capture-manifest.json`.

![Corrected portrait color](<C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p/outputs/verification/portrait-color/ice-the-bruises.png>)

