# Selected blue-book ad backdrop

Brian rejected the wood/green border, asked for a predominantly tan page with subtle gradients and illustrations, requested four more ImageGen options, then selected the bottom-right blue book. The selected background is integrated at `assets/content/ui/ad-bonus-backdrop-blue-book.png`. The four original comparison options are preserved in `outputs/art/ad-bonus-background-options/`.

The page retains its separate character/TV/hourglass hero, live reward controls and countdown. The background uses an aspect-preserving source region anchored at the bottom, so the selected book stays visible as phone proportions change. This is background cropping at the page edges; the separate foreground hero retains its complete authored draw box. The border and green inset are gone. Light mode uses the tan image with dark-brown text; dark mode dims the image and uses cream/gold text.

The muted real-main-scene run reached the page through the actual Shop navigation and passed all existing button/reward/timer checks. It also passed at raw native viewport sizes 1080x1920, 1080x2160, 1080x2340, 1200x1920 and 1440x1920. The independently selected book point remains in the visible source region in all five cases. Short-screen touch scrolling still reaches the developer note and rating action. Final result: `ad-bonus-page failures=[]`.

Inspected the selected background behind live controls in the ordinary, tall, short-footer and dark presentations. The fourteen-screen audit, UI boundary and generated-file hygiene checks passed. The native-1080 migration contract passed; project display/render settings are unchanged. No host Godot process remained after validation. Saves and online requests were isolated/disabled, preview audio used Dummy, and no live ad was requested. No new phone build was installed.

Fourteen raw PNGs, dimensions and SHA-256 values are recorded in `outputs/verification/ad-bonus-blue-book/capture-manifest.json`. No proof screenshot was resized, cropped, composited or recreated after capture.

- [Main page](../../outputs/verification/ad-bonus-blue-book/two-hours.png)
- [Tall phone](../../outputs/verification/ad-bonus-blue-book/phone-1080x2340.png)
- [Short phone after scrolling](../../outputs/verification/ad-bonus-blue-book/phone-1440x1920-footer.png)
- [Dark mode](../../outputs/verification/ad-bonus-blue-book/dark.png)

Generation choices and contract: [ad-bonus-background-options-2026-10-22.md](../art/ad-bonus-background-options-2026-10-22.md).
