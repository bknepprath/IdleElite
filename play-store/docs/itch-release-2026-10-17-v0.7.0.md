# Idle Elite 0.7.0 itch.io release

Published October 17, 2026 (America/Chicago): https://weskillnow.itch.io/idle-elite

- Playable upload: **19836331**, `idle-elite-v0.7.0-itch-web.zip`.
- Launch mode: **Click to launch in fullscreen**, allowing the responsive horizontal layout to use the browser's available width. Mobile-friendly mode remains enabled; orientation remains Default and SharedArrayBuffer support remains off.
- Description: appended the October 17 v0.7.0 patch notes, preserving the existing description and previous update history. Verified the new notes on the public page.
- Previous web upload 19676211 is preserved and hidden from downloads; it is no longer selected for browser play. Older uploads remain unchanged.

## Build

Source: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`.

Built current working files through `scripts/build-desktop-working.ps1`, using the existing reusable build snapshot. The previously newest horizontal archive was missing 14 changed files. No source files changed between this export and final source-manifest comparison. No gameplay code or renderer settings were edited for publication.

Output: `H:\Codex\Projects\IdleElite\outputs\itch-v0.7.0-2026-10-17-release`.

Web ZIP: 60,997,466 bytes; 9 entries, including index.html at its root. Single-threaded web export; online configuration included.

ZIP SHA-256: `CD86F3185E1F317F75F2EEF4508B98BD07A704DE2D3E6D4D1F2B4E9710B757E9`

Published index.pck was downloaded from the new itch.io upload and exactly matches the local build:
`B3C4282C3209C9E095ADA22EE4F174089CDCE5AC66943C9701EB89238B313E8D`

## Validation

- The existing web save-upgrade regression passed from the October 10 public build to this release. Name, player ID, skill XP, materials and built modules were preserved; the score was republished to the test fixture. Production writes: zero. Browser errors: zero.
- Firebase avatar IDs 20-22 were already deployed with Brian's approval during the Android release earlier this evening.
- The broader project-suite performance failure and Wisdom-test timeout recorded in the Android release report were not fixed or represented as passing during this web publication.
- Final public-page smoke test passed in a separate muted Edge browser at 1600x900, using the actual itch.io iframe and unmodified hosted files. The patch notes were present, the canvas loaded at the requested size, and no browser errors were recorded.
- The connected browser also finished loading. A normal click on Push-Ups started training; XP advanced from 0 to 3 and stamina decreased from 30 to 27. The introductory layout expanded into three visible skill columns. Evidence: `itch-live-three-column-0.7.0.jpg` (1747x1052, unmodified browser screenshot).
- The initial blank/loading frame cleared without changing the build. Both test sessions were ended; the public game page is left at its Run game button. Preview monitoring was muted. No test chat messages were sent.
