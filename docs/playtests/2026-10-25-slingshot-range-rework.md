# Practice Slingshot draft

Replaced the former empty stage with an illustrated shooting range inside the normal rounded activity shape. The blue guy is smaller and grounded, using the existing eight-pose windup/recoil/arm recovery. A sampled distance controls the stone's true arc and landing. The camera follows longer shots, terrain pans more slowly, and it returns to the shooter. Generated pegs mark distance; a gold flag marks the saved best. The last shot's distance is shown through landing feedback, then the best distance is shown beside the flag icon while waiting. XP and stamina remain beside the title, with no generic progress rail or medal.

The draw lasts 1.7 seconds. Players may leave the range running automatically, or tap the shooter between 78% and 94% draw for an eighteen-percent range bonus. The gold fork cue and first-use arrow identify that interaction without a modal. The arrow has a 24px minimum target gap and uses existing persistent acknowledgement. Late releases remain ordinary shots; early/duplicate taps cannot skip or pay again. Landing pays XP once, followed by two small decaying rebounds and independent three-frame dust. Higher Fighting levels increase range and tighten relative dispersion.

Source assets and provenance are in `output/imagegen/slingshot-range-oct25/`. The new background, peg, flag, pebble and dust were generated using the approved Idle Elite anchors. Runtime assets are under `assets/content/fight/slingshot-range/`. Mechanical extraction uses fixed authored rectangles. The shooter retains one 210px draw box and the original shared foot anchor. Dust uses one fixed 180x135 box and ground offset for all three frames. No alpha-bound scaling is used.

Validation:

- Database contracts, activity audit, runtime asset paths and activity UI boundary contracts passed
- `slingshot_range_rework.gd`: relative range/dispersion, early rejection, single payment, clean bonus, legacy and modern paid-shot restoration, XP once on landing, insufficient stamina and automatic shooting passed
- `groves_and_range.gd`: existing grove behavior and Slingshot paid-flight/save regression checks passed
- Actual-main `slingshot_range_capture.gd`: actual navigation and shooter touch, title/stat separation, hidden generic rail/medal, all eight poses, arrow visibility/acknowledgement, high-level flight/camera/terrain, landing XP and low-level automatic shot passed
- Fighting screen audit passed at 1080x1920
- Raw proof frames at 1080x1920 are in `outputs/verification/slingshot-range-oct25/final/`, including ready, full draw, release, apex, flight, landing, rebound, return, stopped and level-six landing

The existing full-project check remains blocked by the unrelated Privacy control's 32px text check. This draft does not change rendering settings or claim Android release acceptance. No phone install, export or publication was performed. Tests use isolated storage, disabled save writes/online requests and muted audio.
