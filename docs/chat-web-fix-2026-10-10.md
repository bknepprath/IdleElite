# Web chat verification, October 10, 2026

## Fixes

- Browser Fetch decodes compressed Firebase replies. Disable HTTPRequest's additional gzip decoding on web builds so successful authentication responses are accepted.
- An active first-run tutorial intercepted pointer events while chat was displayed above it. Let the chat composer and Back button receive those events.
- Preserve send failures separately from stream status, retain the draft on failure, and retry a failed profile lookup when Send is pressed again.

## Verification

- Reproduced the compressed-response authentication failure on the previous public itch.io build. Removing the already-decoded response's compression header in a diagnostic test allowed authentication and a real message write.
- `scripts/test-online-reliability.ps1` passed its numeric rules and online reliability checks.
- `scripts/test-chat-send-input.ps1` passed mouse, touch, Enter, tutorial-active typing/Send/Back, draft preservation, visible errors, and profile lookup retry checks.
- Release packaging passed Firebase rules, leaderboard cost safety, save hardening, v1 save migration, save lifecycle, and runtime asset checks.
- The web touch-scroll probe requires a debug export. It was excluded from the release export validation, rather than treating its release-build timeout as a passing test.
- Tested the rebuilt release in muted Microsoft Edge using local asset routing on the itch.io embed origin. Firebase traffic was unmodified. Authentication returned HTTP 200; the message write returned HTTP 204. The message `Web release chat test - Oct 10.` appeared as guest9319, and the composer cleared. Console reported no errors.
- Raw 1200x1100 evidence: `output/playwright/live-chat/release-r2-confirmed.png`.

## Package

`builds/itch/idle-elite-itch-web-chat-fix-2026-10-10.zip`

58,376,534 bytes. SHA-256: `875c3b04f96f4862b331726b5fdfaf915dde27333612067a21363fb871328f51`.

Built from an isolated source snapshot at `.codex-tmp/itch-chat-fix-20261010`; the source manifest is `output/playwright/live-chat/web-source-manifest.json`. No Android package was built for this work.

## Publication and final verification

- Published through the signed-in Microsoft Edge session to https://weskillnow.itch.io/idle-elite as playable web upload `19676211`. Earlier uploads were preserved.
- Downloaded the published `index.pck` and verified its SHA-256 matches the rebuilt package: `c467b74ce4bd4a9ac8d9282f1645e575eecc0f208579ab5a3a521a0c2b2877e9` (49,411,708 bytes).
- Tested the actual published embed in a fresh, muted Microsoft Edge profile with no asset routes or network mocks. Sent `Published chat test - Oct 10.` as guest0817. Authentication returned HTTP 200 and the message write returned HTTP 204, ID `m1791650586_76640660003c`. The message appeared and the composer cleared. Browser console reported zero errors and zero warnings.
- Reloaded the published game and confirmed the message remained visible in the chat strip.
- Raw 1200x1100 evidence: `output/playwright/live-chat/published-send-confirmed.png` and `output/playwright/live-chat/published-reloaded.png`.
- The temporary debugging client was closed. User was asked to disable Edge's temporary remote-debugging setting because browser tool policy blocks internal Edge pages; setting cleanup has not been confirmed.
