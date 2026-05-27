# Bug Squash: Swipe Preview, Locked Module Reveal, and Lock Dragging

Date: 2026-05-27

This note documents a painful debugging session around the activity module list, swipe previews, locked module reveals, and the draggable lock. The short version: several visible glitches looked like one problem, but they were separate timing and layering issues.

## Symptoms

- Fresh game should not show the level 2 locked activity until the player reaches the preview threshold.
- Locked modules should appear once any skill reaches 10 XP.
- Unlocking should happen only after clicking the lock while meeting the required level.
- Successful unlock should animate the lock and fade the module into full color.
- Swiping between skill pages caused a visual "jump" or "spaz" frame in the activity module list.
- The bad swipe frame looked like modules were loaded twice, vertically offset, or drawn two modules lower than expected.
- Removing one glitch exposed another: after swipe completion, the new page briefly jumped to the top of the activity list, then restored scroll.
- Dragging the lock down and releasing over the bottom nav could leave the lock stuck as if still held.

## What Actually Happened

### Locked Module Reveal

The first locked module originally entered the list by changing the visible action list and rebuilding the page. That created a layout/scroll jump.

The better model is:

- The first locked module can exist as a hidden/collapsed placeholder.
- When eligible, animate height/alpha instead of swapping the list structure.
- Avoid rebuilding the whole skill detail page just to reveal a locked module.

### Swipe Preview Glitch

The activity module glitch during skill swipes was not fixed by only clipping rows, freezing scroll sync, or delaying visibility. Those helped diagnose the issue but did not remove the visible artifact.

The crucial issue was the swipe handoff cover:

- During swipe completion, a preview page was kept as a temporary cover while the real page rendered underneath.
- The preview/control tree had transparent gaps between modules.
- The freshly rendered real page underneath could show through those gaps.
- That made it look like modules were duplicated or vertically offset.

The fix was to make the handoff cover behave like an opaque screenshot:

- Keep the settled preview page above the real page during restore.
- Add a full `COLOR_PAPER` backing behind that preview.
- Clear the cover only after the real page has restored scroll.

### Scroll Restore Jump

Removing the handoff cover made the newly rendered page visible before `ScrollContainer` restored its scroll position. This produced a new, clearer bug:

- Swipe finished correctly.
- New page appeared at top of activity list.
- After a short delay, it jumped back down to the intended scroll.

That confirmed the handoff cover was needed, but it needed to be opaque.

### Lock Drag Stuck

The lock drag release bug came from routing:

- While dragging, releasing outside the activity viewport cleared page-level lock state.
- But the release event was not forwarded to the active `ActivityLockRig`.
- The rig still thought `pressing_lock` / `dragging_lock` was true.

The fix was to track `active_activity_lock_rig` and forward outside release events to it before clearing page-level input lock state.

## Dead Ends

These were tried or partially useful but did not solve the core swipe glitch alone:

- Clipping only preview action rows.
- Clipping real action rows. This also cropped the lock, so real rows had to remain unclipped.
- Hiding preview modules for one frame with `visible = false`. This can skip layout and only delay the bad frame.
- Hiding preview modules with alpha while allowing layout.
- Freezing preview scroll sync after prewarm.
- Removing the swipe handoff cover entirely.

## Rules For Future Fixes

- If a swipe glitch looks like duplicated modules, inspect layering first, not just layout.
- Transparent temporary covers are dangerous when the real page underneath is changing.
- If a cover is meant to hide a page rebuild or scroll restore, give it an opaque backing.
- Avoid using `visible = false` when trying to pre-layout controls. Use alpha if the control must still participate in layout.
- Do not clip real activity card roots unless all overflow visuals are accounted for. The lock needs room outside the module.
- For drag gestures, always forward the release event to the component that captured the press, even if the pointer leaves its original viewport.

## Validation Notes

Use the project-safe validation command:

```powershell
.\scripts\check-project.ps1
```

Expected current behavior: this exits 0 but may print Godot RID/resource leak warnings on shutdown.

Per `AGENTS.md`, after every Godot command check for leftover Godot processes. Leave visible editor/game windows alone unless clearly launched by the validation command and clearly headless.
