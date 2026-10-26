# Melt Sand inventories, October 25

Follow-up: the current recipe is 2 Sand to 1 Glass and has one centered Sand input inventory, superseding the two-input recipe below. See `2026-10-25-sand-only-glass.md`.

Melt Sand now opens two live input inventory boxes above its factory and one Glass inventory box below it when selected through its output menu or running. The upper boxes show Sand and Scrapwood, the existing resource ID for the branches in its recipe. All three use their existing material backgrounds, names, icons and owned-count formatting. They update after spending, production and external inventory changes.

The factory body is reduced from 440px to 360px. Its large input panel is replaced by a single compact icon recipe: 2 Sand + 1 Scrapwood → 1 Glass. XP/time remain at the top center. Recipe amounts are fixed costs/yield, distinct from the live inventory counts. The existing output mastery frame is retained with explicit clearance around the output amount; its medal moves to the top right. Ingredient controls still link to their sources, and the lower Glass box opens the existing output selector.

`presentation.inventory_layout: above-below` opts this factory into the new layout. `factory_inventory_layout.gd` owns the compact recipe, inventory boxes and their open/close transition. Shared material modules have an optional compact form with 48px names, 55px counts and 80px icons in 280x244px boxes. Existing gathering boxes retain their previous dimensions. Both inventory rows reserve their space in the list; the root offset and lazy layout estimate follow the same room amount. Clip layers prevent growing rows from overlapping neighboring activities during transitions.

Input-to-output conversion keeps its arc inside the compact factory. Completed Glass travels down into its inventory box. These effects only display actual recipe events; they grant no materials. Recipe payment, reservations, XP, time and save IDs remain unchanged. A stopped paid reservation still resumes without charging again. A fresh unpaid recipe with insufficient ingredients cannot reserve inputs or produce Glass.

Validation passed:

- Real main scene at 1080x1920, reached through actual Building navigation and output selection
- Two inventories above and one below, with owned counts 40/10/5 changing to 38/9/5 on reservation and Glass increasing to 6 on real completion
- Recipe output amount stays clear of its raised mastery frame
- Lower Glass inventory opens the output selector; tapping outside closes it without paying for another batch
- Opening/closing reserves and restores list height
- External inventory changes and fresh missing-ingredient state do not create an unpaid batch or unpaid Glass
- `production_paths.gd` passed recipe/payment/save regressions
- Previous Sand/Beeswax gathering input, collection animation and inventory checks still pass
- Required database contracts, activity audit and Building screen audit completed

Raw proof: `outputs/verification/factory-inventory-oct25/final/`, including live inventories, Glass dropping/collected, compact idle/stopped and low-inventory frames. All animation frames come from one actual-main run. No phone update, release build or publication was performed.
