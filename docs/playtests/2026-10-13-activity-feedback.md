# Activity feedback and fishing layout

Practice Kicking and Sneak Past Tip Jar reproduced the same visual regression: a cycle drain survived an instant UI refresh. After restoring real progress to 50%, the old animation displayed 94.255% and fell to 89.414% on the next frame while real progress advanced to 51%. Instant refresh now clears the stale drain; the same sequence displays 50% then 50.319%. Duplicate progress samples no longer replace the measured forward speed with zero. Completion timing, rewards, and success chances are unchanged.

The existing player log also contained 24 calls to a removed main-scene `_valid_control_ref` method from lock-chain audio. Audio now calls the lifecycle runtime's valid-control helper. The interactive progression launcher uses the real audio driver and no longer forces Master mute, as requested. Automated reviews still use Dummy audio.

Fishing tool layers are positioned in the available water between the actual location-tile row and stats, instead of a fixed right offset that overlaps the stats. Stat boxes are 192px wide instead of 256px, use 48px text, and have 8px internal horizontal padding. Card-side content margins are 14px instead of 27px. Existing authored tool sizes and animation paths are retained.

Desktop-to-portrait inspection exposed reuse of a desktop skill column in the mobile page cache and two stale bottom-nav constant references. Resizing across the layout boundary now rebuilds the skill page and uses the navigation runtime's constant. Android rendering configuration is unchanged.

Regression: `scripts/tests/desktop_activity_feedback.gd` uses real main-scene controls and actual clicks for both activities and Shallows. Deterministic cycle/reset samples test backward motion; fishing checks tool/stat separation, mobile text size, and viewport bounds. Raw captures live in `.codex-tmp/desktop-feedback/` at 1920×1080 and 1080×1920. This reproduces a visual refresh defect, not evidence of network lag or incorrect random failure rates.

Final feedback verification: the visible main-scene suite passed with no script errors. Both activity refreshes display 50.000% then 50.319%; the continuity unit check also passed. Fishing stats and the animated net were visibly checked in 1920 x 1080 desktop and 1080 x 1920 portrait captures. Method columns reserve 224px instead of 260px. The fixture waits for entry animations before sending activity input.

Later correction: restored the zone-side 27px margins and 260px method columns at Brian's request. Only the right-side stat boxes retain reduced padding/size. See `2026-10-13-tips-ribbon-reveals.md` for current verification and the intermittent resize-test limitation.
