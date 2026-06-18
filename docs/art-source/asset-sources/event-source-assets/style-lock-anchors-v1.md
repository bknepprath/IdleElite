# Combo And Event Asset Style Lock V1

Use this as the approval gate for combo modules, temporary event modules, and any future lock variant concept art.

## Approved Style Anchors

- `assets/content/fishing/actions/03-cast-bamboo-rod.png`
- `assets/content/hub/hub-tree-sheet.png`
- `assets/content/hub/hub-decor-sheet.png`
- `assets/content/fight/actions/01-shove-wobbly-hay-bale.png`
- `assets/content/fight/actions/06-outmuscle-angry-wheelbarrow.png`
- `assets/content/build/actions/02-patch-fence-with-confidence.png`
- `assets/content/build/actions/06-build-market-stall.png`
- `assets/content/woodcutting/actions/03-trim-overconfident-shrub.png`
- `assets/content/ui/shop.png`

Subject references may come from nearby Fishing, Thieving, Build, Fighting, and Woodcutting assets, but they do not replace the approved style anchors.

## Non-Negotiable Linework

- Thick black outer outlines.
- Consistent stroke weight across each tile.
- Clear black internal separation lines where forms overlap.
- No thin, gray, brown, colored, sketchy, uneven, or soft-only edges.

## Character Rule

- Background plates should generally include no character.
- If an action tile needs a player character, it must match the existing simple cobalt-blue stick-figure language from `assets/content/fight/actions/01-shove-wobbly-hay-bale.png` and `assets/content/build/actions/02-patch-fence-with-confidence.png`.
- When a blue character appears in an action tile, it should be one of the largest reads in the tile, not a tiny figure beside an oversized prop.
- No realistic people, detailed faces, costumes, fingers, painterly human anatomy, or non-blue player figures.

## Action Button Rule

- Action buttons are transparent cutout sprites, not full scenes.
- Use the existing 256x256 action assets as the contract: no rectangular frame, no scenic sky or ground plate, no baked background, and mostly transparent empty space around the figure or prop.
- The action art can include the blue player, a tool, an enemy, a prop, or a small effect shape, but it should not read as a complete module background.
- Generate or keep source action sheets on a flat chroma key only when needed, then convert the key color to real alpha before approval.

## Background Plate Rule

- Backgrounds must be wide module plates, not square mini-scenes.
- Use broad cartoony shapes, low detail density, and large readable foreground/midground zones.
- The approved direction is wide cartoony location plates that can support different left-to-right crop positions inside modules.
- Leave negative space for module UI overlays and locks.
- No characters in backgrounds unless specifically approved.

## Lock Part Rule

- Runtime locks use a two-piece construction: one blocky lock body plus one cane-shaped shackle band with one long side and one short side.
- Lock base art should stay neutral light gray for code tinting.
- Do not approve generated lock concepts with ornate bodies, curved three-piece shackles, heavy texture, or detailed fantasy shading.

## Contact Sheet QA Rules

- Each tile must read at phone-card size in under one second.
- Prefer one main object or action beat over many small details.
- Avoid generated words, labels, signs, numbers, UI badges, and fake text.
- Avoid photorealism, glossy 3D render style, cinematic blur, muddy contrast, and busy texture.
- Combo action tiles should show the verb clearly.
- Combo background tiles should leave room for card overlays.
- Event action tiles should communicate a temporary mission, not a permanent facility.
- Event backgrounds should be reusable plates, not complete UI compositions.
- Lock concept tiles are reference only. Runtime locks must keep using the corrected two-piece neutral lock asset unless a later item explicitly replaces it.

## Current Source Status

- V1 combo/event/lock master sheet is rejected as runtime source because it is too detailed, too scene-like for action buttons, and has incorrect lock concepts.
- V2 action sheets are rejected because they read as framed mini-scenes and did not respect the existing transparent action-button contract.
- V2 background sheets are approved as the current wide cartoony scene direction.
- V3 action sheets are the current corrected transparent cutout source direction.
- Lock runtime work stays on the corrected two-piece neutral lock assets under `assets/content/ui/`, not the generated lock contact sheet.
