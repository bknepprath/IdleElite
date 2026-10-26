# Desktop opening correction

The one-column tutorial still rendered all five carousel pages. Its centered column left enough space for neighboring pages to appear clipped at both window edges. The instruction label used a fixed mobile x position, and the mobile tutorial deliberately hid the Fighting header. Reset Data also retained desktop carousel preferences.

The desktop opening now shows only the centered Fighting page with its header visible and instruction beneath Push-Ups. Neighbor pages remain mounted but hidden while settled; dragging reveals them for the existing slide transition. Each page clips its contents to its own bounds. Reset Data clears carousel preferences. The progression playtest launcher now starts at F1, the fresh opening; F2–F4 remain available.

Validation: `scripts/tests/desktop_opening.gd` ran the production main scene visibly with Dummy audio and an isolated profile. Fresh boot, clicking Push-Ups, tutorial graduation, drag/settle, 1920×1080, 1280×720, 1000×600, and the actual Settings Hard Reset confirmation all passed. No game process remained after validation. Android viewport and renderer settings were not changed.

Raw viewport captures: `.codex-tmp/desktop-opening/cold-start.png`, `after-first-action.png`, `after-reset.png`, and the `drag-before`, `drag-transition`, `drag-settled` frames. Captures match their window pixel dimensions without image edits.

## Progressive desktop opening

The first click previously changed the desktop from one column to three, moving Fighting left. The shared header shader also included hidden neighbors' colors. Desktop onboarding now keeps Fighting centered with only its own header color after the click.

- Three starter completions: Skills and Settings fade in at their permanent ribbon positions.
- Fighting level 2: Fishing and Thieving fade in, staggered around the unchanged center Fighting column. The header colors blend in with them. Narrow windows retain a single column during this stage.
- First XP in another skill, or Fighting level 3: completes the initial skill introduction without revealing more ribbon buttons. The five-skill drag carousel remains available after the neighbor reveal.

The second iteration replaces the all-at-once ribbon unlock with saved per-feature introductions. Hub uses the existing Building level 3 unlock; Shop uses five bronze medals; Progress and High Scores use total level 25; Chat uses total level 30. Pins and Queue appear after the player has pinned or queued an activity. Eligible features appear one at a time, at least 30 active seconds apart, while on Skills without a modal or carousel drag. Hidden controls retain their final positions but cannot receive mouse or keyboard focus. Legacy players keep their existing interface.

Reveal timing uses cubic Bezier easing. The stage is saved in desktop preferences, survives reloads, and resets with Hard Reset. Older saves retain full desktop access. The mobile tutorial retains its existing reveal behavior. No new player-facing text was added.

The production-scene regression checks centering, intermediate fade opacity, hidden-control input, saved-stage roundtrip, old-save defaults, window bounds, carousel input, and Settings reset. Additional raw frames: `neighbors-before.png`, `neighbors-transition.png`, `neighbors-settled.png`, `controls-transition.png`, and `features-settled.png` in the same capture directory.

## Revised reveal timing, October 13

The one-click start keeps Fighting centered. After the first completed Push-Up, Skills and Settings fade over five seconds. After the second completion, Fishing fades over six seconds; Thieving starts four seconds later and also fades over six seconds. This starts at Fighting level 1. The second Fighting module fades over 4.5 seconds as it enters, including when desktop layout rebuilding mounts it. New progression entries and previews use 4.5-second fades; scrolling existing entries retains its short transition. Neighbor colors fade over the same opening sequence. Remaining ribbon features retain individual eligibility and a thirty-active-second interval.

The actual 1920 x 1080 main-scene test checks centered Fighting, fully contained columns, intermediate opacity, staggered entrances before level 2, saved reveal state, one eligible ribbon item at a time, carousel input, resizing, and reset through Settings. ImageGen produced the replacement boot illustration, with a separate background-removal revision. No procedural bridge is used in the loading screen.

Fade rendering: the rounded artwork shader now preserves inherited modulation instead of replacing it when sampling the background texture. Opening fades therefore include activity artwork as well as labels and borders. The main-scene test checks the second Fighting module at an intermediate opacity before Fighting level 2. No Android viewport, stretch, renderer, or graphics settings changed.

Final capture run: boot, early fades, centered columns, individual feature reveals, saved state and resize checks passed. The separate end-of-suite Settings reset gesture remains intermittent: its final repeat did not reset, although earlier full runs passed. Treat that automated reset path as unresolved and verify Settings reset by hand; F1 in the isolated personal prototype resets directly. The failed test also dereferenced an absent header after the missed reset; this is in the test, not a runtime game exception. The activity/fishing suite and progress-continuity check passed in their final runs.
