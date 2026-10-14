# Skill background and rest art refresh

Date: 2026-10-13. Runtime assets for the existing 0.7.0 prototype.

## Contract

Four reusable, opaque background plates at 768x344: Building workbench, Building timber yard, Woodcutting shaded clearing, Thieving quiet market lane. Broad quiet shapes, subdued earthy palette, no characters/text/UI, thick black shape boundaries, sparse props at edges. Preserve space behind activity name and stat chips. Backgrounds support rather than compete with the activity art. Assign by activity subject, not random rotation.

Two transparent 256x256 static action sprites: Wrap Hands (blue faceless character winding a white hand wrap) and Sharpen the Pencil (blue faceless character using a handheld sharpener on a large yellow pencil). Bold rounded silhouette, heavy black outline, minimal detail, no transient VFX. Existing action-card layout, masking and draw box remain unchanged.

Approved style anchors inspected: `assets/content/build/actions/02-patch-fence-with-confidence.png`, `assets/content/fishing/actions/03-cast-bamboo-rod.png`, `assets/content/hub/hub-tree-sheet.png`. Background layout/context only: `assets/content/build/backgrounds/01-early.png`. The legacy hay-bale anchor path is absent in this worktree; the existing approved anchors above are used instead.

ImageGen creates the artwork. Final assets are stored next to related content and referenced by the authoritative activity database. Existing assets are preserved. Share each background across related activities rather than adding a texture per card. Keep source masters out of runtime exports. Six RGBA textures total 4.53 MiB at base resolution, approximately 6.04 MiB including full mipmaps before GPU compression. Measure actual source and imported sizes after integration.

## Integration and measured budget

The mapping in `skill-background-refresh-070-mapping.json` records 25 field changes across 24 activities, including 23 background assignments. Stack Bricks retains the brick background. Building workshop/blueprint/rest activities share the workbench; fence, timber and structure activities share the timber yard. Woodcutting rests share the shaded clearing, and Thieving rests share the quiet market lane. Wrap Hands and Sharpen the Pencil receive dedicated action art. Other borrowed rest sprites remain for a later art pass.

Backgrounds use high-quality GPU compression and mipmaps; sprites retain lossless alpha and mipmaps. Existing texture caching shares resources between cards. No gameplay, runtime sizing, animation scale, renderer or viewport settings changed for this refresh.

Measured totals in `skill-background-refresh-070-budget.json`: 1,513,449 source PNG bytes; 1,498,398 imported resource bytes per platform set (1.43 MiB before package compression); 2,110,888 bytes of desktop texture payload including mipmaps (2.01 MiB). These are asset measurements, not total process memory or a measured store-download increase. No release export was made.

ImageGen source masters remain outside runtime exports in `C:/Users/bknep/.codex/generated_images/01a12c89-c112-70b3-966d-a5359da3677b/`:

| Runtime image | Source master |
| --- | --- |
| workbench | exec-3b4c6c83-ef5c-4c84-818a-d2f692012001.png |
| timber-yard | exec-695f0520-7361-481f-be35-68840ea97c60.png |
| shaded-clearing | exec-12850ba1-b918-4621-bcb9-a0a453e100ac.png |
| quiet-market-lane | exec-d8a6846b-5e73-4a07-af10-dc4c721b8d5d.png |
| wrap-hands | exec-71bf81a6-357e-4ada-a9bf-bc4b5fc69c45.png |
| sharpen-the-pencil | exec-be026eda-b239-443b-8264-2d1556389a87.png |

Full canvases were downsampled to the established runtime dimensions without per-frame alpha-bound scaling. A first timber-yard generation was replaced to strengthen the black outlines.

## Verification and remaining checks

- Activity database contracts pass; the activity audit finds 5 skills, 172 actions and no missing assets. Existing XP-order warnings were not changed by this art pass.
- Headless imports completed. Tracked import settings were compared before/after; no tracked import drift needed restoring.
- Muted real-game review at 1920x1080 through `res://scenes/main.tscn` shows all six assets in their production cards. Backgrounds remain behind readable titles/stats; the new sprites fit the existing white masks. Exact raw viewport captures: `../../.codex-tmp/desktop-responsive/art-rest-workbench-lane.png` and `../../.codex-tmp/desktop-responsive/art-timber-clearing.png`.
- `scripts/tests/skill_art_refresh.gd` verifies the six texture loads, mipmaps, payload and mapped paths. Actual UI clicks start Wrap Hands, Sharpen the Pencil, Patch Fence and Lean on the Axe. Count the Coins is unlocked and its correct card button receives hover, but the automated click does not reach the start handler. This test is therefore not an all-pass result. The root cause remains unresolved; manual input confirmation is still needed. No gameplay/input workaround was introduced for an artwork change.
- The repository-wide performance-import check flags the preexisting `assets/content/ui/boot/progression-070.png.import` configuration. All six new imports meet this refresh's settings. The boot import was left unchanged.
- Browser rendering and physical-phone acceptance remain unverified. Agent-owned game test processes exited after capture.
