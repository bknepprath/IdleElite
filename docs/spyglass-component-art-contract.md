# Wooden parts and spyglass art

Wooden Parts are a shared inventory resource used by the Spyglass, Lantern, Waterwheel and Selective Net. Four Softwood become two parts. The icon groups a notched beam, peg and curved bracket; it is not a fence or a telescope-specific frame.

Keep the serialized shaping action and recipe ID `carve-spyglass-tube`, with display name Shape Wooden Parts. Migrate each prototype inventory tube into two parts. Already paid reservations and queued shaping retain their value without charging again. Owned Spyglasses remain owned.

The wooden tube is an internal assembly sprite, not a separate resource. It shares the finished spyglass's diagonal axis. Only the large front glass is visible from this angle. The far eyepiece has an opaque outer silhouette, and its assembly lens renders behind the tube.

Use transparent 512px canvases, authored draw boxes, smooth heavy outlines and simple color regions. The approved Building fence and Fighting wheelbarrow establish style only. No runtime scale derived from alpha bounds.

Generated source folder: `C:/Users/bknep/.codex/generated_images/01a164b1-6a54-7012-a1b7-6b337aedb625`

| Asset | Source PNG |
| --- | --- |
| Wooden Parts | `exec-1b5cb61c-1dd2-4ee4-bafa-169d44d5ce60.png` |
| Internal tube | `exec-ab071b8e-a794-4740-85e1-8a1101e16d16.png` |
| Finished Spyglass | `exec-3f4900d5-425c-4567-9d6a-7886f6d4dcd7.png` |
| Polished Lens | `exec-a63ec4d6-fe8a-4503-b12e-45ee38a373b3.png` |
