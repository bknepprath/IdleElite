# Halloween 2026 implementation and art

Status: local 0.7.0 prototype. No release package or publishing.

## Asset contract

Purpose: recognizable stored candy, three temporary construction resources, activity portrait/background, overfull stamina fill, store icon master.
Format: transparent 1536x1024 six-cell item sheet, AtlasTexture resources; opaque 1536x1024 background; separate square store master. The runtime draws the fill through circular geometry and uses authored atlas coordinates, never alpha bounds for scale.
Style: thick consistent black outlines, chunky simple shapes, featureless blue character, orange/yellow spiral wrapped candy. Reviewed approved anchors: shop-icon.png and fishing/actions/03-cast-bamboo-rod.png. Generated with the built-in ImageGen tool, not procedural illustration. Sheet pixels outside sampled object silhouettes have alpha zero. The RGB haze visible in tool previews is not painted into the real game background.
Layering: stored candy bottom-left of the action portrait; temporary construction drops top-right beside existing resource badges; candy toggle at (-86, 62), below and left of the fish toggle at its original (-33, -30), following the left side of the stamina gauge; generated spiral clipped inside the stamina bowl. Auto-eat candy has no count label. Its art uses an authored 80x80 box, rotated -45 degrees around its center inside the unchanged 99x99 hit target, leaving clearance from the gauge and fish. Its off state uses the exact fish silhouette material and #77726d at 35% opacity; the shared material preserves parent fades. No extra full-screen layer or recurring art timer.

## Prompt records

Item sheet: exactly three columns by two rows, six centered isolated transparent assets. Orange/yellow spiral wrapped candy; chunky white Webs; folded cream Cloth strips; brass Lantern parts; orange/yellow spiral disc; faceless blue figure carrying a pumpkin bucket and knocking at a wooden door. Heavy black outlines, rounded toy shapes, minimal detail, soft painted shading, no text or labels.
Sheet correction: preserve all six positions and canvas; remove external glows, haze and shadows, require alpha zero outside silhouettes; remove knocking motion marks and black rim from the spiral disc.
Background: quiet village doorstep at dusk, wide wooden door, stone frame, pumpkins, small cobweb, warm lantern, muted twilight palette, sparse paving for stats. Environment only, no characters/text/UI. Keep door and pumpkin silhouettes within the middle horizontal third for the activity crop.
Store master: close-up faceless cyan-blue rounded figure hugging an orange jack-o-lantern bucket with one orange/yellow spiral wrapped candy. Very thick black outlines, simple painted shapes, purple/orange background. No letters, inset border, rounded outer corners or small clutter.

## Saved assets

- assets/content/events/halloween/items.png and candy/webs/cloth/lantern-parts/swirl/doorway.tres
- assets/content/events/halloween/doorstep.png
- play-store/assets/halloween-2026/icon-master.png (master artwork; upload sizing pending)

## Removal contract

Set seasonal_events.halloween-2026.enabled to false, or set ends_at_unix to the approved UTC deadline. Zero means no scheduled deadline during local iteration. Do not ship with an unspecified end date. Event entries never become permanent progression prerequisites. Keep the small candy/save compatibility code and its shared sheet while players have leftovers. Preserve retired unlock and construction keys so the atomic-save regression guard does not reject legitimate saves after removal. Candy and permanent earned XP are not deleted.

## Validation

Production scene: scripts/tests/halloween_event.gd, run visibly through run-godot-safe.ps1 with Dummy audio and an isolated test profile. Captures in .codex-tmp/desktop-responsive/halloween-*.png are unmodified raw 1920x1080 and 1080x1920 viewports, inspected at both sizes. The first headless scene test stalled without a result and was stopped; no headless gameplay success is claimed. Visible tests cover resource completion, button input, one-piece overflow, exact-boundary color restoration, inclusive random outcomes, save round trip, regeneration/rest preservation, active/offline rewards, candy priority over fish, post-event leftovers and retirement compatibility.

The game reported HALLOWEEN_TEST failures=[] in .codex-tmp/halloween-acceptance-game.log. The wrapper separately reported a newly started unrelated woodcutting capture process; that process was left alone. This is a gameplay-test pass, not a clean wrapper pass. The final headless asset import completed successfully, registering doorstep.png; tracked import metadata was restored to its pre-import state. Activity database contract and asset audit passed; existing curve warnings and intentional seasonal balance deviations remain. No physical Android acceptance is claimed. Store icon master is 1254x1254 and still requires upload sizing.


## Exterior activity decorations, October 14

Contract: transparent 1536x1024 six-cell sprite sheet, 512x512 authored cells. Two web corners, one pumpkin bunting ornament, three top-down spider walking poses. Approved style anchors: shop-icon.png and fishing/actions/03-cast-bamboo-rod.png. Place on the Trick or Treat production activity face only; mouse-ignore, shared atlas, no additional timers. Spider uses one fixed 68x68 draw box and centered pivot for every pose. Cull motion outside the visible viewport. Keep the title and stats readable.

Built-in ImageGen prompt: Exactly 3 columns by 2 rows. Top-left ivory corner web; top-right matching corner web; short orange/purple bunting with pumpkin ornament. Bottom row: three consecutive walking poses of the same chunky purple-black spider facing up, eight bent legs, small orange eyes, identical center and body scale. Heavy consistent black outlines, soft painted shading, simple readable shapes. Independent transparent cells, no text, no background, no glow, no baked motion effects. Output: assets/content/events/halloween/decorations.png, generated source exec-adfdc551-d020-4d93-aa49-ba71e89c3d3c.png. Sampled outside-silhouette alpha is zero.


## Rejected decoration sets and brown spider revision

The user rejected the first purple-spider sheet for excessive detail and thin outlines, then rejected the simplified geometric sheet for looking code-generated. Neither set is attached to the production activity; the decoration attachment was removed from skill_detail_surface.gd. Do not reuse either rejected sheet as accepted art.

Latest direction: cute brown fuzzy spider. Built-in ImageGen generated one transparent portrait, then edited it to reduce fur detail, thicken black outlines, remove tiny cheek eyes, and preserve soft painted volume. Final prompt correction: preserve pose, friendly expression and brown palette; reduce fur strokes by about 85%, use large warm painted surfaces and a few silhouette tufts; triple black outline weight; two big black eyes with one cream highlight; no realistic fur, fine hairs, glow or backdrop. Preview saved to docs/art/halloween-brown-spider-preview.png from exec-4af8c661-dcaf-4e97-98a3-bf6bf8ec76a4.png. This is an art review preview, not approved animation frames or an integrated gameplay change. Exterior decorations remain unfinished pending this art direction.


## Three-tone brown spider revision

User rejected internal texture in the brown spider. Latest preview: docs/art/halloween-brown-spider-three-tone-preview.png, built-in ImageGen edit of the preceding brown spider. Original output exec-eeaa794b-a825-40ca-a476-6c9cf8836a1c.png. Prompt: preserve friendly pose and chunky anatomy; replace internal rendering with main brown #AE703D, one broad highlight #DDA066 and shadow #704325 per object; thick uniform black contour; remove fur strokes, brush texture, gradients and eye rings; fuzzy appearance only from a few large silhouette tufts; transparent background. Preview only, not yet integrated or accepted as animation frames. Updated AGENTS.md to retain the user's explicit three-tone direction.
