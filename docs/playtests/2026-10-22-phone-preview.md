# Android Preview install, October 22, 2026

Built and installed the current uncommitted 1080p checkout at Brian's request. Device: Samsung Galaxy S24 Ultra, SM-S928U, serial R5CX22KSM1H. Package: `com.idleelite.game.preview`, debug version 0.7.2, code 43. ADB confirmed its update at 18:20 on October 22 and a running app process after launch. The Play Store package `com.idleelite.game` was not uninstalled or modified. The existing Preview save was backed up locally before installation and loaded successfully; the Welcome Back summary showed its continuing Fishing progress.

## Build

- Used `scripts/install-android-phone-debug.ps1`, which calls `scripts/build-android-preview.ps1` and the safe Godot runner, then builds and installs the APK set with bundletool.
- AAB: `builds/android/idle-elite-preview-debug.aab`, 176,673,592 bytes.
- APK set: `builds/android/idle-elite-preview-debug.apks`, 364,239,935 bytes.
- Process-local TEMP/TMP/TMPDIR: `H:/Codex/Scratch/idle-elite/android-preview`. Verified H: as Flareon 4TB with volume ID `dc2b82fa-6536-40df-a648-9de08746a55a`, writable, with about 1.2 TB available before the build. Existing project/build paths remain authoritative on C:.
- Updated the preview builder to use the distinct Idle Elite Preview app label and restore export presets/Gradle bytes exactly in `finally`. Both original file hashes matched after building.
- Imported the seven new chunky tool icons, applied the existing performance-import configuration to those seven and five stale ad-art presets, and reimported. The performance-import check now passes. No tracked import churn needed restoration; pre/post import Git statuses and byte snapshots are retained in `.codex-tmp/phone-preview-oct22-*`.
- Crash-audit and native 1080p migration contracts passed. The latest fishing UI/art regression had already passed across seven tools and 23 locations. No full-project-suite pass is claimed here.

The source retains `window/stretch/mode="viewport"`, 1080x1920 logical viewport, and both rendering methods set to `gl_compatibility`. The actual phone log confirms OpenGL ES 3.2 Compatibility on Adreno 750. No renderer or viewport setting was changed.

## Phone verification

The installed Preview app was foreground, running `GodotAppLauncher`. Preview monitoring was muted; the phone's existing media volume was already zero and was not changed. Startup log inspection found no script/parse errors or fatal exception. The raw 1080x2340 phone launch screenshot shows an intact Welcome Back dialog and Fishing page behind it. This is launch evidence, not proof that every active animation or scrolling state renders correctly on the phone.

The phone disconnected after that capture. ADB no longer listed a device, so dismissing the dialog, scrolling and extended physical rendering checks could not be completed. Installation and launch had already been confirmed. No tearing was visible in the captured frame; temporal rendering acceptance remains limited to that observed startup state. No agent-owned Godot process remains.

Evidence: `outputs/verification/phone-preview-oct22/` contains the raw launch capture, build artifact hashes and packaged rod asset inventory. Build logs remain under `builds/android/last-preview-build.*.log`; the bounded app startup log and Preview save backup remain in ignored `.codex-tmp/`. No release upload, commit or push occurred.
