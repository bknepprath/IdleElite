# Idle Elite 0.7.2i itch.io release

Published October 23, 2026 (America/Chicago): https://weskillnow.itch.io/idle-elite

Built the current working files through `scripts/build-desktop-working.ps1 -Version 0.7.2i`, using the reusable H: build snapshot. The Android/source version remains 0.7.2; the exported Settings screen displays Version 0.7.2i. No gameplay or renderer changes were made during packaging.

Output: `H:\Codex\Projects\IdleElite\outputs\itch-v0.7.2i-2026-10-23-release`.

- Web ZIP: `idle-elite-v0.7.2i-itch-web.zip`, 63,807,935 bytes, 9 root-level files.
- SHA256: `D9AE1F68A27CC2D8EF0FD7D992BC3E1D4F38598949521EA8346294961F675A47`.
- ZIP CRC and contents match the web export. All 606 source-manifest entries match current source. Online configuration is included; no source import changes or remaining Godot processes were found.
- Existing browser save-upgrade regression passed from published 0.7.1i through 0.7.2i and reload. Identity, skill XP, resources and legacy progress survived. Test network requests were mocked; production writes were zero.
- Browser canvas sizing passed 15 desktop/portrait/DPR cases and 5 iframe cases with zero console errors. Initial captures showed the Halloween popup; it was dismissed through ordinary input for gameplay inspection. Raw captures of desktop, small-window, Fishing and Settings screens were inspected. The Settings label is 0.7.2i.
- Accepted gameplay evidence: `fishing-accepted/072i-fishing-01-1920x1080@1.png`; version evidence: `fishing-framed/072i-fishing-settings.png`. The intermediate `fishing-final` probe reached Woodcutting and is not Fishing acceptance.
- Selected the new ZIP for browser play, hid and retained the previous 0.7.1i upload, and saved the existing page with concise 0.7.2i patch notes. Fullscreen launch and existing embed options were preserved.

## Deployment verification

Playable upload: **19977937**. The public Run game control targets `https://html-classic.itch.zone/html/19977937/index.html`. The public page shows the 0.7.2i upload and patch notes.

All four main hosted files return HTTP 200. Hosted JavaScript, PCK and WASM SHA256 hashes exactly match the validated local export. itch.io injects its HTML game wrapper into index.html. Detailed results: `hosted-file-verification.json` in the output folder.

Publication screenshot: `.codex-tmp/v072i-validation/itch-published-0.7.2i.png` in the authoritative source checkout. Public page remains open at Run game. Browser test contexts were closed. No real chat messages were sent. Gameplay acceptance used the exact local export in isolated muted Edge; hosted checks verified deployment identity.

## Superseding browser upload: ad notice and desktop layout

Published later October 23, 2026. Current playable upload is **19985177**, superseding 19977937. Public Run game targets https://html-classic.itch.zone/html/19985177/index.html.

- Package: H:/Codex/Projects/IdleElite/outputs/itch-v0.7.2i-browser-layout/idle-elite-v0.7.2i-itch-web.zip
- Size: 63,668,794 bytes; 9 root files; ZIP CRC passed
- SHA256: 7861721a95c6b126361744138cbe7f1917f31b99cb54d2189521f929eff380a5
- Includes the corrected desktop ad-page scaling and itch-only Watch ad notice linking directly to the FutureBrian game page
- Build flag application/config/itch_browser is stamped only for the itch web export; source project, Windows export and website behavior remain separate
- Actual production main-scene tests passed at 2048x1016, 1366x768, 1024x600 and 1080x1920: popup visibility, dismissal and no ad SDK/reward activation
- Hosted PCK, JS and WASM hashes match the export; hosted game boots with no captured browser warnings/errors
- Hosted save has the ad page progression-locked, so a live browser click on the notice link was not verified; source callback targets https://www.futurebrian.com/projects/idle-elite/play/
- Raw popup proof: outputs/verification/browser-ad-layout/itch-notice-2048.png and outputs/verification/itch-notice-portrait/notice.png
- Publication proof: C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/itch-072i-published-notice.png

Existing patch notes and launch settings were preserved. Muted hosted test tab was closed.
