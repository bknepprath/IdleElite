# Idle Elite Design Direction

## Android System UI

The native Android chrome must stay black. Status bar, navigation bar, splash background, and any Android-owned window background should use `#000000`, not the game paper/cream colors.

This matters most during launch, app switching, device gesture navigation, letterboxing, and any moment where Android shows pixels outside the Godot viewport. The game can use warm parchment fills inside its own UI, but platform-owned borders should read as a clean black frame.

Source-of-truth settings:

- `export_presets.cfg`: Android release `screen/background_color` and `gradle_build/custom_theme_attributes`.
- `project.godot`: boot splash background.
- `android/build/res/values/themes.xml`: generated-template fallback for direct Gradle builds.

## Art Style

Idle Elite should look like a chunky, cartoony mobile game with bold black ink. The visual language is graphic and tactile: thick strokes, simple shapes, exaggerated props, readable silhouettes, and high-contrast UI edges.

Core style rules:

- Use thick black outlines for characters, action art, icons, important UI panels, buttons, and reward objects.
- Prefer hand-drawn cartoon proportions over realistic rendering.
- Keep shapes broad and readable at phone size.
- Use warm, playful color fills, but anchor them with black borders and strong shadows.
- Avoid thin-line, low-contrast, photo-real, glossy corporate, or delicate fantasy illustration treatments.
- White or cream interior fills are allowed only when bordered clearly by black ink.

## UI Finish

Game UI should feel like physical sticker/card pieces layered on the screen. Edges can be rounded, playful, and uneven, but controls should still be clear, tappable, and readable on a 1080px-wide portrait screenshot.

Use black as the default stroke and separator color. Cream, parchment, honey, or pastel fills belong inside the game surface; they should not become Android system bars or native app borders.

## Mobile Readability

All player-facing fonts must be large enough to read comfortably on a mobile device without zooming. Validate text in a 1080px-wide portrait screenshot whenever adding or changing phone-visible UI.

Body text should not feel like fine print. For Godot UI, prefer at least 48px for player-facing body text; help popovers, info boxes, tutorials, and status panels should usually use at least 52px body text and 60px titles. If copy does not fit, enlarge the container or shorten the wording instead of shrinking below the readable size.
