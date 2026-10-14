# Activity title spacing

Practice Pool's 60px title used the same 60px spacer as the smaller standard titles, crowding the stat panel below it. The shared title spacer is now 82px. Construction title rows use a 16px separation before their stats.

Moving the stat panels exposed insufficient clearance above recovery progress rails. Recovery cards now have 48px more content height, and their root height consistently includes their authored 36px depth. Artwork and expanded information positions use the same content height.

Validation: `scripts/test-activity-title-spacing.ps1` booted the muted production main scene at 1080 x 1920 with isolated test data and save/network writes disabled. It navigated all five skills and measured 138 standard/recovery cards: Fishing 6, Building 34, Woodcutting 32, Thieving 35, Fighting 31. All title gaps were at least 12px; all visible stat panels cleared progress bars by at least 12px. Stats obscured behind construction-cost overlays were excluded from the visible progress-gap assertion. Custom activity layouts are outside this shared-layout measurement.

The final run exited successfully with no failed checks and no Godot process remaining. Raw screenshots were visually inspected, including Practice Pool and normal/recovery examples. Captures and measurements are in `.codex-tmp/activity-title-spacing/`. The final Practice Pool and Building recovery PNGs are 1080 x 1920. No fonts, prices, activity rewards, renderer, or viewport settings changed.
