# Hub art and expanded help revision

Owner request: 7 October 2026. Replace the overly detailed hub art, show upgrade tiers, and keep help within compact expanded controls.

## Asset contract

- Two transparent 1536 × 1024 PNG sheets, each using a 3 × 2 grid of fixed 512 × 512 cells. Cells 0–4 represent unbuilt and levels 1–4; cell 5 is unused.
- Woodcutting Totem: construction sign, single stump, two logs, three logs with axe, leaf-topped stack with crossed axes.
- Fighting Display: construction sign, red glove pedestal, glove and shield, glove and punching bag, gold glove and blue pennant.
- Style anchors: `hub-tree-sheet.png` and `hub-decor-sheet.png`. Barn tiers provided progression context.
- Fixed authored draw boxes remain 300 × 300 and 310 × 310. No alpha-derived scaling.
- The built-in image generator produced both sheets; source pixels and alpha are preserved.

## Help behavior

Stat holds expand the activity card. Medal and berry information toggle the same expanded area. Following the owner's larger-text revision, expanded information uses 52px body text and 60px titles, with the same 17px black outline as activity titles. Base and boosted values sit beneath their labels in aligned columns. Boosted values use yellow (`#ffe56b`); the "With bonuses" label and base values remain white. Fishing tool details use 32px body text within the tool selector. No full-screen shade or bottom Close button remains.

The expanded card height follows its actual information content; the material collection row and following modules move down with it.

## Help clarity revision

Fishing tool help describes the tool's behavior without internal fill formulas, timing ranges, or area-by-area XP tables. Practice Pool explicitly gives XP without catching fish. Berry help states the doubled rewards, one-berry cost per successful action, and how to select activities. Medal help separates bonuses to this activity, all activities, and all skills, using percent signs for success chance.

Expanded stats center the title and active bonuses, with base and boosted values in equal columns. Multi-skill XP uses full skill names on separate lines. An 8px black divider separates the artwork from the information panel; expanded artwork keeps rounded top corners and a straight lower edge. Help text uses a heavier black outline, and the time heading reads "Time Bonuses." Expanded row heights are also applied to the lazy-list layout host so scrolling cannot place the following activity over the information. Material collection uses that same dynamic height instead of the former fixed expanded height.

Validation: feedback gameplay and real-game help captures passed, including a running berry activity and scrolling the multi-skill XP panel. Width, progress-rail clearance, navigation clearance, and expanded row height are asserted. Module transition checks and the 14-screen audit passed. The six inspected help captures are saved unchanged at 1080 × 1920 in `.codex-tmp/help-clarity-captures/`.

The divider and text-outline revision passed feedback gameplay, real-game help captures, and the 14-screen audit. A focused real-game check expanded a one-bonus panel (237px) to a four-bonus panel (375px), asserting progress-rail clearance and reserved row height after scrolling. The unchanged raw 1080 × 1920 screenshots are in `.codex-tmp/help-stroke-captures/`.

The subsequent larger-text revision passed the same gameplay, help-layout, and 14-screen checks. Time, medal, berry, and multi-skill XP panels were inspected at 1080 × 1920; the panels retain content-driven height and clear the progress rail. Raw captures are saved in `.codex-tmp/large-help-captures/`.

The yellow boosted-value revision passed real-game short/long time-bonus and multi-skill XP captures, plus the 14-screen audit. The heading remains white and the output keeps its black outline. Raw 1080 × 1920 captures are in `.codex-tmp/yellow-help-captures/`.

The font audit found that the stat refresh removed the Fredoka override from both result labels. Removing that reset keeps the base and boosted values in the same Fredoka font as the information headings and body. Short and long bonus panels passed the real-game layout checks; corrected raw screenshots are in `.codex-tmp/font-help-captures/`.

## Generation prompts

Woodcutting:

> Create a production transparent PNG sprite sheet, 1536x1024, grid 3 columns x 2 rows of equal 512x512 cells. Use FIRST TWO input images as strict style anchors: simple hub trees and decorations, very thick BLACK outlines, large flat brown/green color areas, only one broad shadow tone, no texture, no grain, no bevels, no glossy lighting. Third image barn sheet is subject context for level progression only. Woodcutting Totem upgrade sequence, FIVE sprites in reading order and bottom-right cell EMPTY transparent. Cell 0: small plain wooden construction sign with simple axe symbol on a flat oval ochre ground patch. Cell 1: one squat smooth log with two black oval eyes, simple tree-stump silhouette. Cell 2: two smooth stacked log heads, small single leaf on side. Cell 3: three stacked rounded log heads, one large simple axe leaning against base. Cell 4: three stacked rounded log heads topped by a broad flat green leaf canopy, two simple crossed axes at base. Same three-quarter hub view, same ground baseline at y=450 inside every cell, each sprite entirely inside its cell with at least 40px clear margin. Simple expressive shapes like reference tree faces. Maximum 8 main shapes per sprite, very sparse internal lines. No carved facets, rings, bark texture, rope, metal studs, pebbles, elaborate ornaments, labels, numbers, text, UI, background or cast shadow. Preserve actual alpha transparency.

Fighting:

> Production sprite sheet on PURE TRANSPARENT alpha background. 1536x1024, exactly 3 columns x 2 rows of 512x512 cells. FIRST TWO references are strict style anchors (simple hub trees/decor). Third barn is tier progression subject context. Five extremely simple Fighting Display upgrade sprites, reading order, last bottom-right cell EMPTY. Same fixed ground baseline at cell y=450, at least 40px clear margin per cell. Cell0: tiny wooden construction sign with a flat red boxing glove symbol, oval ochre base. Cell1: one oversized RED boxing glove on a short plain brown wooden pedestal. Cell2: same red glove on a slightly taller pedestal, single flat gray shield propped against it. Cell3: same glove pedestal with simple wooden post holding one red punching bag beside it. Cell4: same composition with a plain GOLD glove instead of red and one broad blue pennant on the post. Very thick confident black outlines, basic round toy shapes, large FLAT color areas, at most one simple broad flat shadow patch. Sparse detail like the provided tree stump. No texture, wood grain, carved facets, ropes, nails, metal hardware, intricate knuckles, trophies with filigree, glossy surfaces, gradients, shine, glow or cast shadow. NO background colors, haze, ground beyond the small oval base, text, numbers, borders or UI. Transparent pixels immediately outside each black sprite outline. All tiers share the same simple frontal three-quarter angle.

## Validation

Focused gameplay and real-game input capture passed. All five hub states and compact help panels were visually inspected at raw 1080 × 1920 resolution. The capture asserts that expanded help clears each module’s progress rail and toggles closed through its actual control. Asset import and exported-texture inventory contracts passed.

Module interaction and activity-card geometry checks passed. The all-screen audit completed with 14 raw 1080 × 1920 captures. A final real-game capture also passed with the longest fishing-tool explanation and verified that it fits above the bottom navigation. No agent-owned Godot process remained after validation.
