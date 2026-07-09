# Visual Fidelity Pass

## First pass

- Use `window/stretch/mode="canvas_items"` so Godot UI draws at the output resolution instead of drawing a full viewport and scaling the final frame.
- Keep `window/stretch/aspect="expand"` for the existing portrait layout behavior.
- Use mipmapped filtering for shared visual `TextureRect` helpers and generated `ImageTexture` UI chrome.
- Treat the existing `PaperButtonStyles` `StyleBoxTexture` functions as the first reusable PNG/nine-slice chrome path.

## Next checks

1. Capture the same screens before and after each pass at the real desktop override: push-ups/fight card, skill detail, hub, tutorial/popover, and settings/shop.
2. Use MSDF for `assets/fonts/Fredoka.ttf.import` so shared UI text stays crisp across the game's large mobile font sizes.
3. Enable mipmaps on content action art, backgrounds, module art, hub sheets, icons, and UI PNGs that are routinely drawn smaller than their source size.
4. Replace only ugly repeated chrome with PNG or nine-slice skins: card frame, paper panel, button face, progress rail shell, badge frame.
5. Keep dynamic text, timers, counters, hit areas, progress, and scrolling in Godot.

## Chrome Audit

Priority order for replacing drawn chrome:

1. Activity card frame/depth: `scripts/ui/activity_card_depth.gd` and `scripts/ui/activity_card_styles.gd`.
2. Progress rail shells: `scripts/ui/clean_progress_bar.gd`, `scripts/ui/activity_progress_rail.gd`, and `scripts/ui/convergence_multi_progress_bar.gd`.
3. Navigation/button chrome: `scripts/ui/navigation_shell.gd`, `scripts/ui/skill_detail_surface.gd`, and existing `PaperButtonStyles` callers.
4. Circular gauges and badges: `scripts/ui/fish_circle.gd`, `scripts/ui/regen_circle.gd`, and `scripts/ui/skill_icon_badge.gd`.
5. Fight/minigame-specific custom draw surfaces: `scripts/ui/blue_guy_chicken_brawl_stage.gd` and `scripts/ui/rooster_punch_out_stage.gd`.

Prefer generated or imported `StyleBoxTexture`/`NinePatchRect` chrome for repeated rounded panels, button faces, badge frames, and card shells. Keep custom `_draw()` for live gauges, particles, masks, progress motion, and geometry that changes every frame.

## Activity Card Acceptance

- Normal activity cards must match the reference structure: full-bleed background art, thin black face stroke, attached red rounded 3D base, one yellow/dark progress rail under the stat chips, and no extra bottom trim or second progress strip.
- Judge from the real Godot screenshot first, then zoomed crops of the face edge, progress rail, and bottom corners. Do not approve from a full-page glance.

## Budget rule

Texture memory is roughly `width * height * 4` bytes, plus about one third more if mipmaps are enabled. Use generated PNGs for art surfaces and illustrations, not whole interactive screens.
