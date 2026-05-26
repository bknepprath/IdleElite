# Device Crash Reporting

Use this when a tester says the Android app closed or crashed.

## What the App Keeps Temporarily

The Android launcher keeps only one private pending crash report:

```text
user://pending-crash-report.json
```

That maps to the app's private internal storage, not shared phone storage. On the next app launch, the game loads it into memory and immediately deletes the file. The in-memory copy is cleared when the player uses the Settings crash-report button.

The report includes stack trace, device/build info, launch/resume/stop, low-memory, and Android thermal-status breadcrumbs.

Native engine crashes may not reach the Java exception handler, so always collect logcat too.

## Player Flow

After a crash:

1. Reopen the game.
2. Open Settings.
3. Tap `Copy Crash Report`.
4. Paste it to the developer.

The app clears the in-memory report immediately after copying it.

## Collect a Report From a Plugged-In Device

```powershell
.\scripts\collect-android-crash-report.ps1
```

The script creates a zip under:

```text
builds/android/crash-reports/
```

The bundle includes `battery.txt`, `thermalservice.txt`, `cpuinfo.txt`, `meminfo.txt`, logcat, Android dropbox crashes, and a best-effort `run-as` read of the private pending report for debug builds.

If multiple devices are attached:

```powershell
.\scripts\collect-android-crash-report.ps1 -Serial DEVICE_SERIAL
```

To capture live logs while reproducing the issue:

```powershell
.\scripts\collect-android-crash-report.ps1 -LiveSeconds 90
```

For a heavier Android bugreport:

```powershell
.\scripts\collect-android-crash-report.ps1 -BugReport
```

## Current Repro Note

Reported on May 25, 2026: crash happens after one skill/activity runs out of stamina, the stamina ring is refilling, and the tester quickly swipes left or right between activities.
