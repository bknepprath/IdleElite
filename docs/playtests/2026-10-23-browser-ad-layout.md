# Browser ad page layout

The portrait ad presentation previously scaled with the full available width. In landscape this enlarged the page beyond the visible height and clipped the hero, countdown and footer.

Landscape now uses a centered column, bounded by the available height. Reward row heights, icon spacing and the rate button follow that scale. The existing portrait layout and Android rendering configuration remain unchanged.

Validation: production main scene reached through real ribbon clicks at 2048x1016, 1366x768 and 1024x600; all main ad controls fit without scrolling. Actual viewport captures are in outputs/verification/browser-ad-layout. Skills, settings, progress and hub were also inspected at 2048x1016. Existing ad bonus tests passed, including countdown, reward boundaries, duplicate reward protection and portrait captures from 1080x1920 through taller/wider phone ratios.

Browser publication: website commit 1d15e1a717fe604491b6682d6015314df5a0555b updates only the game pack and pack-size metadata at /projects/idle-elite/play/. Live web ads remain disabled pending Google's review. No Android package or itch package was republished.

Post-deployment: live Edge browser visually confirmed the full corrected ad page at 2552x1273, with no warning/error console entries. The live tab closed before the follow-up screenshot could be saved; the exact inspected native production captures above remain the saved proof. Live HTML references the updated 54,614,752-byte pack. Website build and all 13 site audit tests passed; no TypeScript exists to typecheck.
