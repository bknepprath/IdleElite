# Production and rest progress contours

Changed the shared production V and recovery U rails to advance by distance along their center paths. Their moving edges are perpendicular to the local direction instead of vertically cropping the fill. Production edges turn continuously through the three sharp joints. Existing rail silhouettes, colors, resource payments and action durations are preserved.

The cached contour and full-band polygons are rebuilt when rail geometry changes. Production opportunity windows and feedback positions use the same progress mapping as the fill; their numeric hit intervals are unchanged. Ordinary straight activity rails are unchanged.

Validation:

- `scripts/tests/contour_progress.gd`: 1,001 progress samples per shape, monotonic filled area, bounded corner changes, perpendicular cross-sections, full coverage, adjacent segment boundaries, feedback alignment and resize invalidation passed
- `scripts/tests/activity_progress_turnover.gd`: existing progress reset continuity passed
- `scripts/tests/contour_progress_capture.gd`: actual main scene, actual navigation and taps into Melt Sand and Lean On The Axe, with natural running progress, passed
- Raw 1080x1920 frames inspected before, through both slopes and near completion of each shape
- Required Building and Woodcutting screen audit passed

Evidence: `outputs/verification/contour-progress-oct25/`. Preferred slope frames: `production-44.png`, `production-52.png`, `rest-36.png`, `rest-64.png`. Before and near-complete frames were captured in the same real-game run. Preview audio was muted. No phone install, release packaging or publication was performed.

The local engine reports a system certificate-store warning; no online request is needed for these isolated tests. No script or polygon-drawing error occurred in the accepted run.
