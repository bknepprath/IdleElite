# Fishing tool entry, October 24

Worktree: `C:/Users/bknep/Documents/Idle Slop 1/.codex-tmp/worktrees/idle-elite-1080p`

Disabled-slot correction: location selectors and the center-stage hit button explicitly use empty disabled styles, removing the gray theme rectangle when the tool leaves its slot. Re-ran `scripts/test-fishing-tool-entry.ps1 -VisibleGame` after this correction: `fishing-tool-entry-ok`, `FISHING_TOOL_ENTRY failures=[]`. Inspected the raw 1080×1920 `net-before.png`, `net-departing.png` and `net-active.png` from the same main-scene run; the vacated slot stays transparent. No Godot process remained after validation. This correction has not been installed on the phone or published.

Implemented a location-origin tool transfer, active name/icon fade and restoration. Transfer duration is 0.58 seconds, with a curved path, authored zoom and rotation, and a blend between selector and animation textures. Identical artwork remains opaque. Rod flights retain the same shaft width as the settled animation. Fishing timing and saved gear choices are unchanged.

`scripts/test-fishing-tool-entry.ps1 -VisibleGame` runs the real `scenes/main.tscn` through the safe wrapper, muted, at 1080×1920. It uses the actual tool picker and location taps for hands, net, Stick rod, Good rod, Star rod, boat and mirror. Checks cover actual corner origins, departure, artwork handoff, active identity, stop restoration, same-tool location switching, and opening the picker by tapping the active animated tool. The latest completed run passes with an empty failure report.

Raw unmodified before, departing, morph, active and stopped PNGs: `outputs/verification/fishing-tool-entry-oct24/`. The corresponding log is `.codex-tmp/fishing-tool-entry.log`. PNG dimensions were checked. Runtime asset paths and activity/UI boundary checks pass.

`scripts/test-fishing-tool-balance.ps1 -AnimationOnly` also passes, covering all seven equipment variants and the 23 locations, full contact/haul trajectories, shallow immersion, water effects and protected UI. Rod visual bounds now use the same authored shaft envelope as its containment code rather than the transparent corners of the square sprite. The headless distinct-rod-art assertion checks unique existing asset paths because headless rendering can share fallback textures. The real visible run independently confirms the selected rod art and transfer. The known sandbox root-certificate warning is excluded; no other runtime errors remain in the passing logs.

Card rebuilds retain the flight's original start time. Fixed column geometry avoids an empty center lane while layout containers settle. Identity fades use control-owned tweens so throttled idle UI updates cannot leave partially faded labels. The hidden corner selector does not intercept taps; its active tool opens the same location's picker. New gear transfers wait until the picker/rate preview closes.

No assets were regenerated, and no viewport or renderer settings changed. No export or publication was performed.
