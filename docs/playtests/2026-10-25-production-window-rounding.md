# Production click window rounding

Replaced the sharp clipped opportunity polygon with a rounded ribbon. It has circular fillets through both shoulders and the central V, rounded caps at each end, antialiased outlines and the existing six-pixel gold/six-pixel black treatment. A smooth central adjustment keeps the original V tip inside the frame. Both green success and red miss/shake use this same geometry. Timing intervals, forgiveness, input, rewards, progress fills, card silhouettes and ordinary opportunity frames are unchanged.

The frame uses one cached contour and interval. The draw overlay duplicates its packed point array before applying translation and closure. This prevents stationary/feedback redraws from accumulating an offset into neighboring UI. No new artwork or gameplay data is required.

Verification:

- `production_window_rounding.gd`: 10,025 outlines across 930px and 1400px widths, all live widths, narrow/expanded edge cases, noncollapsed simple polygons, smooth joins, corner continuity, V-tip containment and unchanged click boundaries
- `production_window_rounding_capture.gd`: real main scene at 1080x1920, actual menu/output selection, naturally moving Sapphire window through all bends, geometry checked every captured runtime frame, consecutive raw corner PNGs, stationary-cache checks and green/red feedback checks
- `production_window_pixels.py`: all 56 consecutive corner PNGs contain one continuous closed gold ring without detached pieces; 84 actual runtime frames passed geometry checks
- `contour_progress.gd`: production and rest fills retain monotonic area, perpendicular moving cross-sections, full completion, adjacent segment seams and resize behavior
- Activity UI boundary and runtime asset-path contracts
- Building screen audit at 1080x1920

Evidence is under `outputs/verification/production-window-rounding-oct25/final/`, with `result.json`, `pixel-audit.json`, raw corner frames and before/bend/feedback/stopped captures. Test logs are `.codex-tmp/production-window-rounding.log`, `production-window-final.log` and `production-window-contour-regression.log`.

Local changes only. No phone install, export, publication or save mutation. Preview audio is muted. The unrelated existing Privacy text-size failure in the full-project check is unchanged.
