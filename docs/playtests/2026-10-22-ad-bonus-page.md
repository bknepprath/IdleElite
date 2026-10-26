# Ad bonus page presentation

The subsequent illustrated frame and responsive layout supersede this first layout pass. See [2026-10-22-ad-bonus-presentation.md](2026-10-22-ad-bonus-presentation.md) for current behavior and evidence.

Rebuilt the production Shop/ad page in `scripts/ui/shop_surface.gd`.

- A single reward row shows +10% XP and 10% less activity time with their existing icons.
- The description states that each ad adds two hours and up to six hours can be stored.
- A wide gold Watch ad button shows +2 hours on one row. Its play icon, pressed face, 5% depression and spring release use the existing button feedback system and normal UI cue.
- One active-status row contains an HH:MM:SS countdown. The horizontal bar reads the actual bonus time every frame, with two-hour divisions and a six-hour maximum. The countdown changes every second; the bar drains continuously.
- When another whole two-hour reward cannot fit, the button is disabled and the next-ad countdown explains when it becomes available. Existing reward amounts, multipliers, four-hour eligibility threshold and six-hour cap are unchanged.
- The developer message and rating button are grouped near the bottom, separated by space and a rule. The page fits the phone viewport without scrolling. Body/help text is at least 52px; titles and timer are at least 60px.
- An earned reward briefly emphasizes the button and timer without floating text overlapping the controls. The success notice is now the single sentence “Added 2 hours of ad bonus.”

## Verification

`scripts/tests/ad_bonus_page_capture.gd` runs the production `res://scenes/main.tscn`, reaches Shop through the actual bottom navigation, and checks these states in its real hierarchy:

- Empty time, enabled button, zero bar and 00:00:00.
- Actual touch down, depressed button, release and settled scale.
- Live countdown and continuously decreasing bar.
- Earned SDK callback grants two hours; a duplicate callback cannot grant twice.
- Two hours fills one third of the bar.
- Six hours fills the complete bar and prevents another request.
- Expiry returns the display to zero and re-enables the button.
- Dark mode, viewport bounds, status/timer separation and developer footer placement.

Final result: `ad-bonus-page failures=[]`. The fourteen-screen audit, UI boundary, activity UI boundary, generated-file hygiene, test-harness and crash-audit contracts passed. No host Godot process remained. Preview audio used Dummy, with isolated saves and online requests disabled. No live ad was requested or watched; SDK reward callbacks were exercised with test state. The phone preview has not been rebuilt for this change.

All eight raw viewport PNGs are 1080x1920, independently measured and recorded with SHA-256 hashes in `outputs/verification/ad-bonus-page/capture-manifest.json`. No crops, composites, substitute scenes or isolated controls were used.

Inspected page states:

- [Empty](../../outputs/verification/ad-bonus-page/empty.png)
- [Active](../../outputs/verification/ad-bonus-page/active.png)
- [Two hours](../../outputs/verification/ad-bonus-page/two-hours.png)
- [Full six hours](../../outputs/verification/ad-bonus-page/full.png)
- [Dark mode](../../outputs/verification/ad-bonus-page/dark.png)

Inspected raw frames from the same touch/viewport run:

- [Before press](../../outputs/verification/ad-bonus-page/empty.png)
- [Depressed](../../outputs/verification/ad-bonus-page/button-pressed.png)
- [Release transition](../../outputs/verification/ad-bonus-page/button-release.png)
- [Settled](../../outputs/verification/ad-bonus-page/button-settled.png)
