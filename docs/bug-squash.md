# Idle Elite Bug Squash Log
<!-- Idle Elite Godot docs: maintained for the Godot 4 mobile idle RPG. HTML references document current Godot systems, data, release work, and implementation plans. -->

Use this file for short project-wide bug notes, especially fixes that reveal a useful debugging rule. Bigger incidents can keep a dedicated postmortem and link back here.

## Entry Template

Date:
Area:
Symptom:
Mistake:
Root cause:
Fix:
Validation:
Rule:

## Fishing Page Scroll Hitch And Horizontal Swipe Regression

Date: 2026-06-21

Area: Fishing detail page input routing, fishing area modules, skill-page scroll, and skill-page horizontal swipe.

Symptom: dragging anywhere on the Fishing page caused a severe hitch, including normal up/down scrolling and attempts to swipe left/right to another skill. After the scroll hitch was fixed, vertical scrolling felt smooth again, but horizontal swiping away from Fishing stopped working.

Mistake:

- First fix focused on fishing method/offer buttons and removed their immediate skill-swipe/prewarm work, but missed plain fishing background presses that fell through to the generic skill-page input path.
- The first broad fishing skip fixed vertical scroll by bypassing generic skill-page input, but it also intercepted the later drag/release events after a horizontal swipe had started.
- Early regression coverage proved vertical drags did not start actions, but did not prove that a real horizontal swipe from the Fishing background could finish navigation.

Root cause: Fishing detail input had multiple overlapping routes. A fishing background press could skip fishing-specific handlers and then enter the generic skill-page handler, which immediately started skill-swipe tracking and preview/prewarm work on pointer-down. That made every click/drag feel heavy. The follow-up deferred-swipe gate correctly delayed swipe work until horizontal intent was clear, but the fishing skip path continued to run while `skill_swipe_tracking` was active, preventing the normal `_finish_skill_swipe()` release path from committing navigation.

Fix:

- Add a Fishing-only deferred swipe gate: background presses inside the Fishing detail viewport no longer start generic swipe tracking immediately.
- Let vertical drags pass through to the scroll container without starting skill-swipe tracking or preview prewarm.
- Start skill-swipe only after horizontal movement clearly wins, then stop skipping generic input once `skill_swipe_tracking` is active so the normal drag feedback and release/commit path can finish.
- Bypass unnecessary pinned-shelf/module-zone scans for Fishing scroll-surface presses.
- Track active Fishing method/offer presses with lightweight flags so background scroll frames do not scan method/offer hit candidates every drag frame.
- Keep real Fishing offer hits alive even when their fallback hit rect overlaps the bottom interactive UI band.

Validation:

- `.\scripts\test-fishing-click-flow.ps1` passed.
- `.\scripts\test-fishing-net-offer-click.ps1` passed.
- `git diff --check -- scripts/main.gd scripts/test-fishing-click-flow.ps1 scripts/test-fishing-net-offer-click.ps1` passed with only normal CRLF warnings.
- `scripts/test-fishing-click-flow.ps1` now asserts that Fishing background press/vertical drag do not start skill-swipe/prewarm, and that a horizontal swipe from the Fishing background navigates away from Fishing.

Rule: for skill-page input bugs, test both axes. A vertical-scroll fix is incomplete unless horizontal page-swipe still commits through the real release path. When deferring expensive swipe setup, let the lightweight gate own only the undecided press/drag period; once `skill_swipe_tracking` is live, hand control back to the normal swipe machinery.

## Pinning Activity Page Flash

Date: 2026-06-21

Area: activity module pinning, skill page pin badges, pinned activities page refresh, and transition covers.

Symptom: every time an activity was pinned or unpinned, the whole activities page briefly flashed out of existence before returning.

Mistake:

- First fix only removed the delayed full `_render_screen()` refresh path and missed the synchronous cover path.
- Focused tests passed because they asserted pin state and card behavior, not the absence of a visible transition blocker.
- Scroll-anchor preservation code from an older rebuild-based pin flow was left active after pins no longer needed to rebuild the skill page.

Root cause: `_pin_module_ui_key()` and `_unpin_module_ui_key()` still started pin-time transition blockers and an opaque pin refresh cover (`_begin_pin_transition_blocker("skill")`, `module_ui_pin_refresh_cover_requested`, and `_begin_module_pin_refresh_hard_cover()`) before the badge animation played. Even after replacing the delayed refresh with in-place badge/shelf sync, this immediate cover still blanked the page on every pin.

Fix:

- Removed the pin/unpin-time transition blocker and hard-cover calls.
- Stopped capturing pin scroll anchors from pin/unpin now that the source skill page no longer rebuilds for pin changes.
- Kept pin changes local: update pinned state, play the badge animation, then sync visible pin badges in place.
- On the pinned activities page, rebuild only the pinned shelf content instead of rerendering the whole page.

Validation:

- `.\scripts\test-pinned-pin-visual-smoke.ps1` passed.
- `.\scripts\test-pinned-scroll-anchor.ps1` passed.
- `.\scripts\test-pinned-page-interactions.ps1` passed.
- User confirmed the flashing was fixed in-game.

Rule: when a visual flash remains after removing a delayed rerender, search for synchronous cover/blocker paths in the tap handler itself. For pinning, avoid page-level transition covers unless the user is actually navigating to or from the Pins page; simple pin state changes should update badges and pinned-page shelf content in place.

## Pinned Page Blank Shelf And Dead Tap Regression

Date: 2026-06-21

Area: pinned activities page, active shelf layout, transition cover readiness, and pinned action-card input.

Symptom: the pinned page looked visually correct after adding the blank reserved shelf, but starting activities from the pinned activities page broke again. Earlier smoke coverage still passed because it called action-card handlers directly or rendered the pinned page by setting `current_screen = "pinned"`, bypassing the real navigation transition.

Mistake:

- Treating direct `_on_action_card_input()` calls as proof that the player's tap path worked.
- Rendering the pinned page directly in tests instead of entering through `_show_pinned_activities()`.
- Adding visual shelf behavior without checking whether the page transition cover was clearing from the actual node tree.
- Letting a flaky opportunity-window assertion distract from the real pinned-page input route.

Root cause: `_pinned_page_ready_to_reveal_under_cover()` looked for `PinnedActivitiesPage` as a descendant of `content_scroll`, but the pinned page shell and active shelf live under `skills_content`, outside the scroll container. The transition cover could therefore remain in the way longer than intended and swallow real taps even though the page appeared ready. Existing tests did not catch it because they skipped the transition-cover path.

Fix:

- Keep the inactive pinned shelf at the expanded shelf height so pinned activities keep their spacing.
- Give the inactive shelf its own neutral gray `SkillDetailGradientShelf` colors instead of fading the shelf background to transparent.
- Change `_pinned_page_ready_to_reveal_under_cover()` to check `skills_content` for `PinnedActivitiesPage` and `PinnedActivitiesActiveShelf`.
- Expand `scripts/test-pinned-page-interactions.ps1` so it enters pinned through `_show_pinned_activities()`, waits for `_page_switch_scroll_cover_active()` to clear, then taps the visible pinned card through `scene._input(...)`.
- Keep button-level and global-input checks for pinned cards, but do not rely on direct helper calls alone.
- Make the opportunity feedback smoke choose the actual opportunity-window center instead of assuming a fixed progress value.

Validation:

- `.\scripts\test-pinned-page-interactions.ps1` passed with the real navigation-path pinned tap check.
- `.\scripts\check-activity-ui-boundary-contracts.ps1` passed.
- `git diff --check -- scripts/main.gd scripts/test-pinned-page-interactions.ps1` passed.
- Post-validation process checks found no headless Godot process from the pinned-page run. Unrelated headless or visible Godot processes were reported and left alone unless clearly launched by the validation command.

Rule: for pinned-page input bugs, always test the real route: pin/order a real action, enter pinned via `_show_pinned_activities()`, wait for the transition cover to clear, and send press/release through top-level `_input()` at the visible card. A direct render or direct `_on_action_card_input()` call is useful as a narrow unit check, but it cannot prove the page is tappable. When a visual shelf/header change touches page layout, re-check transition-cover readiness against the actual node owner, not the scroll child you wish owned the page.

## Thieving Heist STEAL Button And Reset Trophy Leak

Date: 2026-06-20

Area: Thieving heist cards, skill-page input routing, hard reset save restore, and Thieving trophy save repair.

Symptom: the Thieving heist STEAL button rendered as enabled, but tapping it did not trigger the heist from the player's real click path. Separately, after repeated hard resets, the hub could start with heist trophy 1 already present even when the saved Thieving level was far below the trophy's unlock level.

Mistake:

- Testing the heist attempt helper directly before proving the visible STEAL button could be clicked through `_input()`.
- Assuming the button's local `pressed`/`gui_input` handlers were enough for a card nested in the skill detail scroll layer.
- Letting the global bottom interactive UI exclusion run before heist button hit-testing, which made a visible button near the lower part of the detail viewport effectively dead.
- Clearing runtime data during hard reset without also canceling pending boot save-restore work that could run afterward.

Root cause: Thieving heist cards were registered differently from normal action cards and did not carry the same `skill_id`/`action_id` metadata used by the generic action-card input route. The main `_input()` path could therefore miss the heist button and return early when the tap overlapped the bottom interactive UI exclusion band. For the reset issue, `_reset_data()` rebuilt runtime state, but stale `pending_save_restore_data`, post-load simulation state, and save-repair flags could still apply old save data after the reset, reintroducing trophy state. Existing regular-save repair also did not clear impossible stolen heists whose saved Thieving level was below the heist unlock.

Fix:

- Add a dedicated `_route_thieving_heist_button_global_input()` path that hit-tests visible heist buttons, tracks clean press/release taps, and calls `_attempt_thieving_heist(heist_id)` on valid release.
- Route Thieving heist input before `_event_points_inside_bottom_interactive_ui(event)` in `_input()`.
- Keep a direct `button.pressed.connect(_attempt_thieving_heist.bind(heist_id))` fallback on each heist STEAL button.
- Add `_clear_pending_save_restore_work()` and call it during hard reset before state is rebuilt.
- Add regular-save repair for impossible stolen Thieving trophies, clearing stolen/cooldown state when the saved Thieving level is below the heist unlock.
- Update process-hygiene checks in focused tests to compare before/after headless Godot process IDs so unrelated already-running headless validation processes do not falsely fail the run.

Validation:

- Added `scripts/test-thieving-heist-click-flow.ps1`.
- The test renders the real Thieving page, unlocks the first heist at level 8, finds the actual enabled STEAL button, sends mouse press/release through `scene._input(...)` at the button's global center, and verifies trophy state, cooldown, or XP changes.
- `.\scripts\test-thieving-heist-click-flow.ps1` passed with `thieving-heist-click-flow-ok`.
- `.\scripts\test-performance-regressions.ps1` passed and now guards that heist input runs before the bottom UI exclusion.
- `.\scripts\test-save-normalization.ps1` passed and now covers hard-reset pending restore cancellation plus impossible trophy repair.
- Final process check showed no leftover headless Godot processes from the validation runs.

Rule: for click bugs, test the rendered button through the real top-level `_input()` route before declaring victory. If a control sits in a special lazy-rendered or scroll-layer structure, give it an explicit global hit-test route instead of assuming normal action-card metadata will catch it. For hard reset, clear pending/deferred restore and simulation work as well as the visible runtime state; otherwise old save data can leak back in after the reset appears complete.

## Fishing Shallows Click And Animation Break

Date: 2026-06-19

Area: Fishing skill area modules, Shallows location tile input, lazy-rendered method cards, and fishing animation state.

Symptom: the Fishing page looked clickable and button audio could play, but tapping Shallows did not reliably start fishing. In later attempts the action could appear to start through direct method calls, but the real rendered button still did not respond from the player's click path. When the click did not enter the real fishing start path, the active fishing tool layer and water animation strip stayed hidden.

Mistake:

- The first fixes tested helper methods directly instead of testing the actual rendered Shallows button through the game's `_input` path.
- A broad module-list smoke was treated as sufficient coverage even though its fishing assertions did not reproduce the player's click route.
- The first regression allowed synthetic cards that did not match the lazy-rendered fishing area structure.
- The debug loop initially focused on whether the action could start, not whether the visible animation layers turned on.

Root cause: fishing location tiles are nested inside their parent area card's `method_slots` after lazy rendering. Some code searched only top-level `action_cards`, so it could miss the real Shallows method metadata when the only mounted owner was the Beach area card. Separately, relying only on per-button `gui_input`/`pressed` signal routing was brittle for this UI layer; the player click needed a page-level hit-test route that finds the visible fishing method button and forwards press/release through the clean tap handler. Without that, a click could produce UI feedback without changing `running_action_id`, `selected_fishing_locations`, or the visible fishing animation state.

Fix:

- `_fishing_method_card_for_action()` now searches nested fishing area `method_slots` as well as top-level method cards.
- Fishing method buttons still have their local `gui_input` handler, but also keep a `pressed` fallback.
- `_input()` now routes fishing method clicks through `_route_fishing_method_button_global_input()` before lock/activity-card routing.
- The global route hit-tests visible fishing method buttons from both top-level method cards and nested area-card `method_slots`, then forwards to `_on_fishing_method_button_input()`.
- Shallows selection is restored to `selected_fishing_locations["beach"] = "shallows"` before starting `beach-shallows`, so the Beach module and active tile animation stay aligned with the running action.

Validation:

- Added `scripts/test-fishing-click-flow.ps1`.
- The test renders the real Fishing page, finds the actual enabled Shallows button, sends press/release through the game `_input` path at the button's global center, and verifies all of:
  - `running_skill_id == "fishing"`
  - `running_action_id == "beach-shallows"`
  - selected Beach location changes from `rocky` to `shallows`
  - the active fishing tool animation layer is visible
  - the water animation strip is visible
- `.\scripts\test-fishing-click-flow.ps1` passed.
- Process checks after validation showed no leftover headless Godot processes. Existing non-headless Godot windows were left alone.

Rule: for player input bugs, do not stop at direct method calls or synthetic card dictionaries. Build a regression around the real rendered control and route the event through the same top-level input path the player uses. For animation bugs, assert the visible animation state too, not just the logical running action. When lazy-rendered cards are involved, always check both the top-level registry and nested owner-card structures such as `method_slots`.

## Pinned Activity Visual Validation Failure

Date: 2026-06-19

Area: pinned activity modules, pin art placement, pinned-page interactability, info chips, collapse smoke coverage, and Godot validation workflow.

Symptom: the pinned activity pass consumed hours without producing a trustworthy user-facing result. The pin looked wrong in game, including an unacceptable visible colored square/bury mask. The armed pin placement and size were not verified visually early enough. Pinned-page interactions and info-chip behavior were discussed as if they were fixed before the visual state was proven. A smoke-test expectation for a collapsed-row `+` expand button was then treated as a product requirement, causing production collapsed UI to be changed even though collapsed buttons were not supposed to be touched.

Mistake:

- Treating headless smoke tests and code inspection as enough for a visual polish task.
- Letting a test invent or override product intent instead of checking the intended behavior first.
- Broadening the work into collapsed-row button UI after the active request was about pin placement, the purple square, pinned-page behavior, and empty info chips.
- Reporting progress from internal plumbing while the actual screen still looked bad.
- Attempting visible screenshot validation without first ensuring the Godot process situation was safe and isolated.

Root cause: the workflow lost the distinction between internal implementation movement and player-visible improvement. For screenshot-quality UI, the source of truth is the rendered screen, not a passing bounds check. For behavior tests, the source of truth is the user's stated intent and existing design, not whatever a smoke assertion happens to say. The collapsed-row test had drifted into requiring a plus button, and that bad assertion was followed instead of corrected. The pin bury-mask approach also created visible artifact risk; it should have been screenshot-tested immediately, not discovered by user playtest.

Fix:

- Revert any production collapsed-row `+` button work from this pass.
- Update the module-list smoke so collapsed rows validate the existing row-tap expansion behavior and protected-input blocking, without requiring or adding a collapsed plus button.
- Keep the pin bury mask hidden so no purple/colored square can render on the activity card.
- Add/keep smoke checks for the approved pin texture, large static badge size, armed up/right placement, settled placement, card overlap, top-left overhang, and no visible square bury mask.
- Use pinned-page smoke coverage for real action-card starts/stops, info-chip expansion, passive collect/info behavior, heist input, fishing method input, and duplicate card registration, but do not call the feature visually polished until screenshots have been inspected.

Validation:

- `.\scripts\test-module-list-transitions.ps1` passed after the collapsed plus-button expectation was removed from the test.
- `.\scripts\test-pinned-pin-visual-smoke.ps1` passed headlessly after hiding the visible square mask and tuning static pin placement.
- `.\scripts\test-activity-card-geometry.ps1` passed in a solo rerun.
- A module-list run left two headless Godot validation/import processes behind; both were clearly headless leftovers and were terminated. A follow-up process check showed only non-headless Godot processes.
- Screenshot recapture was intentionally paused after visible-process handling proved unsafe; future screenshot work must first establish a clean/safe wrapper-launched capture path.

Rule: for any UI task whose acceptance depends on appearance, placement, polish, animation feel, or "screenshot quality," take and inspect screenshots after each meaningful visual change. Do not rely on headless tests alone. If a screenshot cannot be captured safely, state that the visual result is unverified and do not present it as done. Tests must enforce the intended behavior, not create new UI requirements. When a smoke test contradicts the stated product intent, fix the test or pause to confirm; do not change production UI to satisfy the bad assertion. For the pinned activity pass specifically, do not touch collapsed button UI unless the user explicitly reopens that area.

## Fake-3D Prism Edges

Date: 2026-06-19

Area: activity cards and bottom skill page-switch buttons.

Symptom: fake-3D controls read as two flat shapes offset down/right instead of one solid prism. Adding diagonal connector strokes helped, but early revisions created hollow black side gaps, inconsistent bottom/right stroke weights, crunchy rounded corners, and press animations where the connector strokes appeared to move opposite the face.

Mistake: treating the effect as one generic overlay that could be dropped onto every card/button. The activity cards and diagonal page-switch buttons had different shape paths, stroke owners, z-order, fill colors, and press offsets. A second mistake was letting multiple layers draw the same edge: front face stroke, back slab outline, side fill, side outline, and connector caps could all overlap or cover each other.

Root cause: the prism illusion only works when each visible edge has exactly one owner. The side face must be filled with the darker slab color, the connector strokes must run between the true front silhouette corners and the offset back silhouette, and animation must derive from the same face offset as the moving front control. On activity cards, duplicate cap strokes made the top-right and bottom-left corners look crusty. On page-switch buttons, the back slab outline and connector overlay were fighting over the bottom/right stroke weight.

Fix:

- Give diagonal page-switch buttons a shape-aware face renderer instead of using a rounded-rect stylebox.
- Draw page-switch side fills and connector strokes from a dedicated prism overlay using the button's actual trapezoid silhouette.
- Disable the offset page-switch slab's own stroke so the side/back visible outline has a single owner.
- Update the prism overlay from the same `face_offset` used by the pressed front face, so connector strokes collapse with the button instead of animating upward.
- Keep activity cards on the fast depth path: rounded back slab, two corner connector strokes, and one rounded back outline.
- Match activity-card slab connector/back-outline width to the face border weight and extend connector endpoints slightly to cover tiny cream gaps at rounded corners.

Validation:

- `.\scripts\test-activity-card-geometry.ps1` passed.
- Captured the skill page with activity cards plus page-switch buttons and inspected the full screenshot and a nav-button crop.
- Captured a mid-press page-switch state and confirmed the connector strokes move with the pressed face.
- `.\scripts\check-project.ps1` passed the static/performance-regression sections, then failed later in the live skills-page timing sample on existing frame-budget thresholds; treat that as separate from prism geometry unless it reproduces consistently after a targeted change.

Rule: for fake-3D UI, do not draw "front, back, and some lines" as independent decorations. Define the front silhouette, derive the back silhouette from the same offset, assign one layer to fill visible side faces, assign one layer to draw visible side/corner strokes, and verify both resting and pressed screenshots. If a stroke looks thin, thick, hollow, or crunchy, first look for overlapping stroke owners or side fill covering the outline before changing art or global style widths.

Snapshot before vertical-slit experiment:

- Screenshot: `.codex-tmp/skill-prism-capture.png` from the rounded-chevron pass on 2026-06-19.
- Page-switch body shape: arrow-ended outside edge, diagonal inside seam, `diagonal_width = 96.0`, `arrow_edge_width = 118.0`, `arrow_corner_radius = 26.0`.
- Page-switch row spacing: `HBoxContainer` separation `-120`.
- Chevron glyph: `stroke_width = 50.0`, `fill_width = 31.0`, `shadow_color alpha = 0.18`, glyph bounds `left/right = 18..172` or `-172..-18`, `top/bottom = 18..-46`.
- Chevron proportions before vertical-slit experiment: `half_width = size.x * 0.24`, `half_height = size.y * 0.25`.
- Reason for branch: the arrow-ended buttons looked interesting, but the diagonal inside seam made the pair feel like it was on a different perspective plane.

## Skill Icon Badge Cropping Loop

Date: 2026-06-19

Area: skill header/menu icons, Godot rounded badge clipping, and visual-asset QA.

Symptom: the new skill icons repeatedly looked different in real game screenshots than in generated/contact-sheet previews. Icons bled outside rounded badge corners, Fighting/Thieving/Building/Woodcutting/Fishing positioning took too many iterations, and Fishing especially kept showing a truncated fish/rod even after placement tweaks.

Mistake:

- Treating synthetic badge/contact-sheet previews as evidence for the real in-game look.
- Assuming `Control.clip_contents = true` would clip to the rounded Godot badge shape; it only clipped to the rectangular Control bounds.
- Trying to solve Fishing mostly through repeated `TextureRect` offset/scale tweaks and source-art cropping, which hid the real problem and even removed rod/reel pixels the icon needed to keep.
- Capturing stale already-running game windows after code edits, which made it look like offsets had not changed.
- Relying on manual/right-arrow page navigation for screenshots when layout/save state could move or miss the target; this caused repeated captures of the wrong skill page.

Root cause: there were two different clipping systems being conflated, and the symbol draw path was wrong. The Godot badge needed runtime rounded-rect clipping, while the Fishing PNG needed to remain a complete fish-plus-rod symbol with transparent padding. Rectangular `clip_contents` could never enforce rounded-corner masking, and `TextureRect` made the Fishing icon debugging misleading because repeated scale/offset changes still did not reliably prove the whole source texture was being drawn into the icon rect. The screenshot loop also lacked a reliable per-skill capture path at first, so visual conclusions were sometimes based on the wrong screen or stale process.

Fix:

- Replace rectangular-only child clipping with a badge-specific canvas shader that discards icon pixels outside the rounded badge shape before the black border draws.
- Replace `TextureRect` for skill symbols with `SkillIconSymbolDraw`, a small custom Control that explicitly draws the entire PNG into the symbol rectangle with `draw_texture_rect()`.
- Keep the Godot fill/background/border as runtime badge shapes instead of baking them into the icon art.
- Lock stable icon placements once approved, especially Fighting and Thieving.
- Tune per-skill offsets/scales only from real rendered screenshots.
- Use the existing approved Fishing winner art from `assets/content/icons/drafts/fishing-symbol-winner-v19.png`; strip only the magenta sheet background/fringe and preserve the full fish, line, rod, and reel.
- Rework `assets/content/icons/skill-symbols/fishing.png` itself without deleting the rod/reel: preserve the full fish-plus-rod symbol, add real transparent padding, and only tune scale/position from there so the whole icon remains available to the badge.
- Use the direct per-skill capture helper for stubborn pages instead of relying on swipe/right-arrow navigation when checking a specific skill header.

Validation:

- `.\run-godot-safe.ps1 --path . --import --quit` reimported the changed Fishing PNG.
- `.\run-godot-safe.ps1 --path . --quit-after 1` passed after the final icon changes.
- Direct Fishing-page screenshot confirmed the v19 Fishing winner art is visible in the badge with the whole fish, line, rod, and reel: `.codex-tmp/direct-fishing-v19-scale093.png`.
- Process checks were run after Godot commands; no-window temporary Godot processes from failed visible captures were cleaned up when clearly launched by the validation/capture attempt, while user/editor windows were left alone.

Rule: for Godot icon polish, separate runtime mask bugs from source-art framing bugs. First prove the runtime clipping shape and symbol draw mode with an actual in-game screenshot; then inspect the PNG alpha bounds before tuning offsets. If an icon keeps truncating, do not keep nudging a bad crop or deleting source pixels. Verify that the renderer is drawing the whole source texture into the intended rect, then add transparent padding or adjust scale. For screenshots, prefer a direct per-skill capture path over manual navigation, and never call a visual change complete from a stale game window or synthetic preview.

## Itch.io Web Audio Silent

Date: 2026-06-16

Area: Godot Web export on itch.io.

Symptom: the itch.io browser-playable build loaded and played normally, but all music and SFX were silent on itch.io. Browser volume, site permissions, fullscreen, focus, mute state, and first user interaction did not restore audio.

Mistake: the first assumption was that the browser audio context was not being unlocked by a trusted click/tap, so the game added a quiet first-input unlock ping. That was reasonable, but it did not fix the live itch build because the real failure was lower in Godot's Web audio playback path.

Root cause: Godot 4.3+ Web exports can fail silently with the default Web audio playback type when using project audio buses such as `Music` and `SFX`. Idle Elite creates custom audio buses at runtime, and the Web build needed stream playback instead of the default sample path.

Fix:

- Set `general/default_playback_type.web=0` under `[audio]` in `project.godot`.
- Re-export/package the Web build through `.\scripts\package-itch-web.ps1`. It validates the leaderboard rules, exports Web, and writes `builds\itch\idle-elite-itch-web-latest.zip` with `index.html` at the zip root.
- Upload `builds\itch\idle-elite-itch-web-latest.zip`, or run `.\scripts\package-itch-web.ps1 -Upload -ButlerTarget user-name/game-name:web` when Butler is configured.

Validation: uploaded `builds\idle-elite-itch-web-v0.4.0-audiofix4-stream.zip` to itch.io and confirmed sound worked in the live browser-playable page.

Rule: when a Godot Web export is completely silent on itch.io but the game otherwise runs, check `audio/general/default_playback_type.web` early. For Idle Elite, keep Web playback type set to Stream (`0`) before chasing browser mute, focus, iframe, or click-unlock fixes.

## Action Art Shader Material

Date: 2026-06-15

Area: activity card action art.

Symptom: action art cutouts looked harsh and over-saturated in activity cards.

Mistake: the first wrong assumption was that the source art needed a global visual retune, so a shared action-art shader was changed to desaturate/value-shift every action image. That hid the symptom, changed source art presentation globally, and did not address the user's actual suspicion that the image might be doubled or rendered through the wrong path.

Root cause: normal transparent action cutout PNGs were all getting the custom `ActionArtTextureRect` `ShaderMaterial`, even though they did not need texture masking. The target cutouts were not doubled: `build:stack-bricks`, `fight:shove-wobbly-hay-bale`, and `fight:kick-mud-off-boot` each had exactly one visible `TextureRect`, with `modulate = Color.WHITE`.

Fix:

- `ActionArtTextureRect` now defaults to the plain `TextureRect` render path.
- `_action_art_image()` calls `set_mask_material_enabled(_action_art_needs_texture_mask(path))`.
- `_action_art_needs_texture_mask()` only enables the shader for `/backgrounds/` paths, where a full background-style image may still need rounded texture clipping.
- Normal transparent cutout PNGs render with `material = null`.
- The regression guard rejects shared action-art shader color math such as saturation/value/luma shifts.

Validation: live scene-tree probes checked target action PNG node count, visibility, modulate, material, and texture path. `scripts/test-performance-regressions.ps1` passed after the fix.

Rule: when a transparent cutout looks wrong, first verify live node count, modulate, material, and texture path. Do not globally color-correct art as a UI fix. If a shader was added only for clipping, make it opt-in for art that actually needs clipping.

## Fishing Module Corner Crop

Date: 2026-05-27

Area: fishing area module background art.

Symptom: the full-size fishing area module background looked muddled after changing it from a plain `TextureRect` to `RoundedTextureRect`.

Mistake: solving corner cropping by changing the background art sampling path.

Root cause: the rounded shader cropped the corners, but it also changed how the wide fishing scene was sampled.

Fix:

- Keep the fishing module background as a `TextureRect` with `STRETCH_KEEP_ASPECT_COVERED`.
- Add a separate corner-only overlay above the background and below the border/content.
- Color that overlay with `COLOR_PAPER` so only the square corner spill is hidden.

Rule: when art already looks correct, do not solve corner cropping by changing how the image is sampled. Mask or cover only the unwanted corner pixels.

## Swipe Preview, Locked Module Reveal, And Lock Dragging

Date: 2026-05-27

Area: activity module list, skill-page swiping, locked module reveal, and lock dragging.

Root causes:

- Locked module reveal was rebuilding the page/list structure instead of animating a hidden placeholder.
- Swipe completion kept a transparent preview page as a handoff cover while the real page rendered underneath, so the real page showed through gaps and looked like duplicated modules.
- Removing the handoff cover exposed a scroll-restore jump because the new page became visible before `ScrollContainer` restored its scroll.
- Lock drag release outside the viewport cleared page-level state without forwarding release to the active `ActivityLockRig`.

Fix:

- Keep locked modules as hidden/collapsed placeholders and animate height/alpha when eligible.
- Keep the settled preview page above the real page during scroll restore, but give it an opaque `COLOR_PAPER` backing.
- Clear the cover only after the real page restores scroll.
- Track `active_activity_lock_rig` and forward outside release events to it before clearing page-level input lock state.

Rule: if a swipe glitch looks like duplicated modules, inspect layering first. Covers that hide rebuild/scroll-restore work need opaque backing. For drag gestures, forward release to the component that captured press even if the pointer leaves the original viewport.

## Validation Notes

Use the project-safe validation command:

```powershell
.\scripts\check-project.ps1
```

Expected current behavior: this exits 0 but may print Godot RID/resource leak warnings on shutdown.

Per `AGENTS.md`, after every Godot command check for leftover Godot processes. Leave visible editor/game windows alone unless clearly launched by the validation command and clearly headless.
