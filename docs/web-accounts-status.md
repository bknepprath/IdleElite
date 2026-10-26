# Web accounts status

Updated October 24, 2026

## Implementation

- Optional Google sign-in is gated by `application/config/web_accounts`, off by default
- Guest play and local saves continue without Google
- Google Identity Services requests only openid, email and profile
- Existing Firebase identity linking and private cloud-save paths are reused
- Account changes archive the active saves before replacing them through a recoverable transaction
- Sign-out restores a separate guest save
- Divergent device and cloud progress requires an explicit choice, including changes to resources without XP changes
- Remote replacement keeps the existing ETag guard and history backup
- Settings exposes Account before the normal profile toolbar is unlocked
- Guest status reads Saved on this device; the primary account action is Sign in with Google
- Google saves happen automatically, with a full-width status and Sign out action
- Browser backup tools are grouped under Save backups, with Download backup and Restore backup
- Existing Google accounts load directly after authentication; a fresh guest is archived before its identity can be replaced

## Verified

- Eight JavaScript bridge and browser save-owner tests pass
- Account save-store and conflict fixtures pass
- Existing online identity safety suite passes
- Real main-scene account switch and guest restoration pass with separate fixture inventories
- Actual portrait profile and conflict controls captured and inspected at 1080 x 1920
- Latest release web export passes, with no remaining Godot process
- Google OAuth origins and Firebase authorized domains include both futurebrian.com and www.futurebrian.com
- Website privacy link and policy published in Brian-Website commit 7aed41a and verified live
- Google branding privacy URL now uses https://www.futurebrian.com/projects/idle-elite/privacy.html
- Google OAuth audience is External and In production (read-only verification on October 24)
- A fresh Google account chooser displays Idle Elite and the correct privacy-policy URL; the branding console still reports verification issues

## Published release

- Actual Google sign-in, Firebase credential exchange, cloud upload, retrieval from independent local storage, and reload persistence passed in Edge with the user's chooser clicks
- A fresh-guest sign-in edge case was found after initial publication and that release was rolled back immediately (51f6bb4)
- The corrected Firebase existing-account response now enters the account-switch transaction before adopting the Google identity
- A regression through the production authentication callback, AccountSession and main scene loads Google inventory 7 from guest inventory 123, then restores guest inventory 123 on sign-out; only HTTP transport is a fixture
- Latest compact Account and Save backups menus were inspected in the release browser build with no captured browser warnings or errors
- Published website commit d75f73d enables accounts on FutureBrian.com and includes the slightly thicker black stamina/time navigation icon outline
- Live index.pck verified byte-for-byte: 54,634,168 bytes; SHA256 b78d566b88b8204e9b903c08280c2274dd96c936d69ef4db921b1aad67c67cd4

The website uses the release export with accounts enabled only in staging. No Android release, phone installation or itch update was performed for this feature.

## Remaining Google branding work

Google sign-in functions and the chooser displays Idle Elite. The branding console still reports ownership verification issues. Search Console has no verified property for brian@forwardfuture.com; website ownership verification and any subsequent branding review remain incomplete. This is distinct from the tested authentication and cloud-save flow.

## Locations

- Preview: `H:\Codex\Projects\IdleElite\outputs\accounts-preview\web`
- Reusable staging: `H:\Codex\Scratch\IdleElite\desktop-build`
- Website release checkout: `H:\Codex\Projects\Brian-Website-release`, branch `codex/idle-elite-account-privacy`
- UI evidence: `outputs/verification/accounts/guest-profile.png`, `account-save-ready.png`, `settings-ad-icon.png` and `save-choice.png`
- Raw browser JPEG evidence in parent workspace: `.codex-tmp/accounts-release-guest-ui.jpg` and `accounts-release-backups.jpg` (2552 x 1272), plus `accounts-live-final.jpg` (2552 x 1269); live Account panel inspected with no browser warnings/errors
- Runtime result: `outputs/verification/accounts/runtime-switch-result.json`

## Reauthentication

The Google Cloud verification page said the organization requires verification. The actual Workspace session-duration policy has not been inspected or changed. Reuse the existing Edge login; do not disable authentication controls or promise that future Google verification can be eliminated.
