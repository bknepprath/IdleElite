# Idle Elite 0.7.1i itch.io validation

Date: October 19, 2026 (America/Chicago).

Status: published on itch.io on October 19, 2026, after the completed checks below.

Source: `C:\Users\bknep\Documents\Idle Slop 1\.codex-tmp\worktrees\idle-elite-1080p`.

Build: `H:\Codex\Projects\IdleElite\outputs\v0.7.1i`.

Evidence: `H:\Codex\Projects\IdleElite\outputs\v0.7.1i-validation`.

Test scripts: `.codex-tmp/v071i-validation/` in the source worktree. Existing Claude probes were reused; their original files were not changed.

## Change made during validation

`scripts/ui/skill_detail_surface.gd`, `_set_activity_card_expanded`: when applying an immediate height change, set the rendered card height before resizing its list row. Previously the row could shrink while the card retained its previous height until the container sorted it. The original Wisdom probe reproduced 2–3 unit overlaps during two transitions. The same assertions passed after the correction.

No renderer, Android export setting, save schema, game data or online configuration was changed.

## Native checks

All runs used `run-godot-safe.ps1`, isolated user data, disabled online requests and muted audio. Godot runs were sequential. No owned process remained after each check.

| Check | Result |
|---|---|
| Responsive matrix | 343 assertions passed, zero failures; 13 landscape sizes from 800×600 to 5120×2880, portrait sizes 540×960, 800×960 and 1000×900, skill reachability, chat and return to wide |
| Header and activity bounds | Gauges, all 172 activity names against the widest medals, stat boxes, numbers and navigation passed |
| Real-game layout capture | Passed at 1920×1080, 1920×1200, 1500×1000 and 800×600, plus portrait transitions and open chat |
| Pop-ups during resize | Passed in wide/portrait layouts, during card changes, after dragging and when clicking resized pop-ups |
| Desktop input regression | `DESKTOP_LAYOUT failures=[]` |
| Wisdom transitions, desktop | 8/8 cases, 45 checks, zero failures |
| Wisdom transitions, portrait | 8/8 cases, 45 checks, zero failures |
| Off-screen Wisdom rows, desktop | 6/6 cases, 27 checks, zero failures |
| Off-screen Wisdom rows, portrait | 5/5 cases, 25 checks, zero failures |
| Project Wisdom regression | `wisdom-feedback failures=[]` |
| Static contracts | Activity UI, UI boundaries, 1080p migration, test harness, generated-file hygiene and crash-audit contracts passed |

Chat opening/closing, repeated clicks, tab changes and portrait transitions passed 23 assertions. Three cases in the original probe lacked coverage because the warm page rebuild completed synchronously. The real opening showed no reversal in panel/chat opacity. A separate deterministic test held the navigation busy flag while sending real input to the production chat icon; queued opening, monotonic fade, discarding the queued dock on portrait resize and remaining closed on return to wide all passed. This busy-state coverage is injected, not evidence of a naturally slow rebuild.

Two portrait fixtures incorrectly assumed ordinary navigation always creates a new page. Their local copies now call the existing navigation reset before cases explicitly requiring fresh controls. All assertions were preserved. The initially incomplete runs remain in the evidence folder.

The first visual run opened across monitors. It was rejected and repeated at the established right-monitor position; the repeated run verified the whole window was on that monitor. Only the repeated captures are accepted.

## Rendered evidence

Raw viewport PNGs were captured from the production `res://scenes/main.tscn`, without resizing or compositing:

- `responsive-visible-r2/fixed-1920x1080.png`
- `responsive-visible-r2/fixed-1920x1200.png`
- `responsive-visible-r2/fixed-1920x1200-chat.png`
- `responsive-visible-r2/fixed-540x960-narrow.png`
- `wisdom-visible-fixed/cw-wisdom-before.png`
- `wisdom-visible-fixed/cw-wisdom-moving.png`
- `wisdom-visible-fixed/cw-wisdom-put-away.png`
- `wisdom-phone-fixed-r2/cw-wisdom-put-away.png`

The desktop Wisdom frames are 1920×1080 from the same real-game run. The portrait Wisdom frame is 1080×1920.

## Export and browser checks

Export passed using `scripts/build-desktop-working.ps1 -Version 0.7.1i` and the official Godot 4.7.1 engine/templates. The separate build snapshot is stamped `config/version="0.7.1"` and `config/version_suffix="i"`; the source project's version stays unchanged. The real exported Settings screen displays **Version 0.7.1i**.

The itch ZIP has 9 files, 61,005,203 compressed bytes and 91,595,242 uncompressed bytes. ZIP CRC, each file against the exported web folder, file-name parity with the previous web export and all 552 source-manifest entries passed. The snapshot's 551 unstamped files also matched the source manifest.

Upload artifact: `H:\Codex\Projects\IdleElite\outputs\v0.7.1i\idle-elite-v0.7.1i-itch-web.zip`.

SHA-256: `d13d42afb8815379b4be9c5a33b3f0bf9f05eb1c3cb75b52646f8799034c1311`.

The production browser save-upgrade test passed from the prior 0.7.0 export to this exact 0.7.1i export, then through reload: all five skills retained at least 1,000,000 XP, materials and legacy module progress survived, and returning leaderboard progress was republished to the in-memory mock. No production writes were made; the browser error list was empty.

The first three layout-fixture runs were rejected. The inherited fixture fabricated over-cap mastery XP, unlock flags without prerequisites, and ordinary mastery for boss/project entries that the current game does not retain. Its local copy now uses the production mastery cap (18,628 XP), a limited unlock set and valid mastery keys. A native round-trip through `_load_game_core` and `_save_payload` confirmed `payload_regresses_game_progress=false`. No production save guard or test assertion was weakened. Failed-run logs remain available.

Final browser acceptance passed in muted, isolated Edge:

- Direct export: all 15 size/DPR cases passed, including 800×600, 16:10, 3:2, 125% scaling, 4K/5K, portrait and returning to wide. Canvas pixel dimensions matched the requested viewport at every step. The valid progressed save loaded and saved again. Zero console errors.
- Local iframe wrapper: all 6 size/DPR cases passed with the same save and error checks. This exercises an iframe filling the viewport; it is not a test of a newly uploaded package on the live itch.io page.
- Representative raw browser screenshots were visually inspected at 1920×1080, 800×600, 1920×1200, 5120×2880 and 1170×2532, plus framed 3840×2400 and 540×960. Header gauges remain within their columns; inspected activity names do not collide with medals; navigation remains visible.
- `verify-evidence.cjs` verified the original dimensions of 31 browser/native PNGs without modifying any image. No validation-owned Godot, Edge or Node process remained.

Accepted browser evidence is in `browser-direct-r4/`, `browser-framed/` and `browser-upgrade/`. Earlier `browser-direct*` folders are diagnostic failures, not acceptance results.

Scope: Windows native layout/input coverage and the actual web export in Edge/Chromium. Firefox, Safari, physical mobile browsers and live itch-hosted acceptance were not tested. Online requests were intercepted in memory. This is a web-release recommendation, not Android release acceptance.

## Publication

Published through the authenticated WeSkillNow Edge session at https://weskillnow.itch.io/idle-elite (project 4665235). Upload 19893707 is `idle-elite-v0.7.1i-itch-web.zip`. Saved and reloaded the edit page to verify that it is selected for browser play. Previous upload 19836331 remains retained and hidden for rollback.

Fullscreen launch, mobile-friendly support, default orientation, disabled scrollbars and disabled SharedArrayBuffer settings were preserved. The public page shows the new upload and its Run game control targets `https://html-classic.itch.zone/html/19893707/index.html`.

Public HTTP checks returned 200 for `index.html`, `index.js`, `index.pck` and `index.wasm`. SHA-256 hashes for JavaScript, PCK and WASM match the validated local export exactly. The HTML differs only by itch.io's injected `https://static.itch.io/htmlgame.js` script and a blank line. This verifies deployment identity; gameplay acceptance remains the isolated browser testing described above.

Publication screenshots: `H:\Codex\Projects\IdleElite\outputs\v0.7.1i-validation\itch-published.png` and `H:\Codex\Projects\IdleElite\outputs\v0.7.1i-validation\itch-live-page.png`.
