# Firepit and pin follow-up, 2026-09-07

- Fixed a full-card activity Button added during lazy finalization that intercepted the firepit native Button. Passive modules now retain their own controls.
- Removed firepit activation from the passive coordinate router. Normal cards and promoted swipe previews share native button wiring.
- Prevented hold-to-extinguish release from relighting the fire.
- Enabled empty-fuel taps to reach the existing Scrapwood requirement feedback.
- Moved the info icon clear of the title and matched the corner mask to the card radius.
- Pins now use absolute draw layer 1000, with their entry seam beneath them at 999, above module borders.
- Removed the pin test's post-startup window resize. Visible tests launch with --resolution 540x960 before boot; raw production viewport captures remain 1080x1920. The 0.6.0 image is the engine boot splash, with no second production UI rendering found. A frame-by-frame capture of that engine splash was not obtained; the reported movement remains visually unverified.

Validation: firepit_native_controls.gd passed real touch ignition, exact startup fuel cost, short click, hold and release, and empty-fuel behavior. pin_native_controls.gd passed actual pin/unpin and seam geometry checks. test-woodcutting-firepit.ps1 passed fuel, buff, cooling, persistence, layout, and flame checks. Raw firepit-started.png and pin-page.png were inspected at 1080x1920. All test-owned Godot processes exited. No Android release build or physical-device validation in this follow-up.
