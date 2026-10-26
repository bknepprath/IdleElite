# Web rewarded ads

The existing Shop Watch ad button routes Web builds to Google's H5 Games Ad
Placement API. Android continues to use its existing AdMob/UMP implementation.

Publisher: `ca-pub-4125359195200512` (WeSkillNow)

## Deployment status

Not serving live ads. `WebRewardedBridge.LIVE_ENABLED` remains false.
The existing Google account has AdMob and AdSense for YouTube, but needs the
web-content upgrade, site review and H5 Games enrollment. On October 23, 2026,
Google rejected `https://weskillnow.itch.io/idle-elite` in the upgrade form,
requiring a top-level domain and suggesting `itch.io`, which we do not own.
Do not submit itch.io as our domain or use the obsolete publisher account.

Before enabling live ads:

1. Done: owner approved futurebrian.com; production game is published at
   https://www.futurebrian.com/projects/idle-elite/play/ and linked by the top
   Play now button on the Idle Elite project page, with no homepage button
2. Site ownership verified via ads.txt and AdSense review requested October 23,
   2026. H5 Games application submitted October 23 with the owner-authorized
   contact number; Google's page confirmed receipt and review. Both approvals
   remain pending; submission is not approval
3. Published "Idle Elite browser consent" for futurebrian.com in Google's
   European regulations message settings, with Consent, Do not consent and
   Manage options. Owner delegated the regional choice after the earlier
   auto-review block; all EEA countries, UK and Switzerland have the direct
   decline option. Existing account ad-partner defaults were preserved.
   Updated public/privacy.html for browser storage and AdSense H5, deployed
   hosting only using brian@forwardfuture.com, and verified the live policy.
   Still verify the actual browser consent/revocation experience and US privacy
   settings before enabling live ads; the disabled ad tag does not yet load CMP
4. Verify rewarded ads using Google's test mode in the real production game
5. Enable LIVE_ENABLED only when the above prerequisites are confirmed

Debug Web exports use Google's `data-adbreak-test="on"` mock ad mode. Release
exports do not load any ad SDK until LIVE_ENABLED is true. Do not publish a debug
export or treat a test reward as proof of ad revenue or publisher approval.

## Reward contract

- Only the existing Watch ad click can initiate a placement
- Only Google's adViewed callback grants the existing two-hour bonus
- Skipped/unavailable/blocked ads grant nothing
- Duplicate clicks/callbacks and stale callbacks cannot grant extra rewards
- Loading expires after 15 seconds; a displayed ad is never cut off by that timer
- Gameplay pauses and audio mutes synchronously before the ad; original state is restored afterward

## Validation

`node --test scripts/tests/web_rewarded_ads.test.cjs` exercises the exact
embedded JavaScript source against a fake SDK, without network requests.
`run-godot-safe.ps1 --headless --path . --script res://scripts/tests/web_rewarded_bonus.gd`
checks the GDScript reward/pause/audio callbacks.

Reusable build staging: `H:/Codex/Scratch/IdleElite/desktop-build`
Local web test output: `H:/Codex/Projects/IdleElite/outputs/web-rewarded-ads-oct23`

October 23 validation: all 10 JavaScript tests and the GDScript callback test
passed. A debug Web export ran the real main scene in Edge, using an isolated
test state and muted audio. Clicking the actual Watch ad control loaded Google's
official mock rewarded ad with the correct publisher ID. Gameplay paused and
muted during display. Completing it granted two hours and restored gameplay;
closing a second ad early granted no additional time. No browser script errors
were reported. This confirms integration, not live-ad eligibility or earnings.

Proof screenshots and state are in the parent workspace `.codex-tmp/`:
`web-rewarded-test-ad.png`, `web-rewarded-earned.png`,
`web-rewarded-test-state.json`. These are 1941x1022 browser viewport captures of
the running game/test ad, without cropping or compositing.

The review export is debug-only and must not be uploaded. Its test autoload is
removed from the reusable staging project after the check.

Production hosting: clean release export (no review autoload or test save) at
`H:/Codex/Projects/IdleElite/outputs/futurebrian-web-0.7.2/web`.
Website repository: `C:/Users/bknep/Documents/Personal Projects/Brian-Website`.
Published commits `a0e3f238c67589fb2ba4d7b3f6b4d0fc065c9b6a` and
`70a39fb346760715f70fe6e94ebeb0512ef4a1d4` add the game, project-page button,
ads.txt and optional `?mute=1` preview mode. Normal players retain game audio.
The live release booted and accepted actual action input with XP progression,
without browser errors; raw viewport proof is `idle-live-web-game.png`
(1941x1022) in parent `.codex-tmp/`. The website build and all 13 site audit
tests passed. No live ad SDK is loaded while approval/consent setup is pending.

References:
- https://developers.google.com/ad-placement/apis/adbreak
- https://developers.google.com/ad-placement/docs/test
- https://support.google.com/adsense/answer/6023158

Submission proof: parent `.codex-tmp/h5-application-submitted.png`.
Consent publication proof: parent `.codex-tmp/web-consent-published.png`.
The CAPTCHA first timed out; a normal form refresh and retry succeeded after
explicit user permission. No challenge bypass or alternate submission used.

## itch.io Watch ad behavior

The itch web export sets application/config/itch_browser=true. Watch ad opens a dismissible notice instead of starting the rewarded-ad flow. The FutureBrian.com button opens https://www.futurebrian.com/projects/idle-elite/play/. The flag is applied only around the itch Web export in build-desktop-working.ps1 and restored before Windows export. Source and website exports do not enable it. No SDK starts or bonus is granted by the notice. Google approval remains pending for live website ads.
