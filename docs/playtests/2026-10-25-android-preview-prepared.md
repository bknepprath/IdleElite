# Android preview preparation, October 25

User requested installation of the latest checkout after the hub upgrade audit. The current preview was built and packaged successfully, but installation is pending a phone connection. Do not treat this document as installation or physical-device rendering acceptance.

- ADB listed no USB device or mDNS wireless service
- Previous Wi-Fi endpoint 192.168.1.199:36155 timed out
- Requested USB connection/unlock or the current Wireless debugging IP address and port
- No app was uninstalled, installed, launched, cleared or seeded; no phone save was changed

Artifacts in the authoritative worktree:

- `builds/android/idle-elite-preview-debug.aab`, 191711956 bytes
- `builds/android/idle-elite-preview-debug.apks`, 392880427 bytes
- SHA-256 records: `.codex-tmp/phone-preview-artifact-hashes.json`

The guarded `build-android-preview.ps1` completed, bundletool produced the signed universal APK set, and the AAB ZIP CRC check passed. Verified packaged new hub sign texture, hub runtime and shared grove geometry. Crash-audit contracts passed. Export presets, Gradle source and project settings hashes matched their pre-build values. No tracked import metadata required restoration and no agent-owned headless Godot remained.

Process-local scratch: `H:/Codex/Scratch/idle-elite/android-preview-temp`, verified writable on the expected Flareon 4TB volume. Build settings remain 1080x1920, viewport stretch and GL Compatibility.

Installer now accepts `-SkipBuild` to reuse this verified preview bundle and refuses ambiguous multiple-device installs. Default behavior still rebuilds. Once one intended phone is connected, back up its existing Preview save before running `scripts/install-android-phone-debug.ps1 -SkipBuild`, then inspect the actual running phone build. Never seed or replace the player's hub levels as part of installation.

## Installed after USB connection

Installed successfully on Samsung Galaxy S24 Ultra SM-S928U, serial R5CX22KSM1H, through `install-android-phone-debug.ps1 -SkipBuild`. Android reports package `com.idleelite.game.preview`, version 0.7.2, code 44. Neither app was uninstalled or cleared; the production package was not modified.

Before installation, backed up seven Preview save-family files in `.codex-tmp/phone-preview-oct25-backup/preview-save-family.tar`. After installation and a normal lifecycle save, all hub levels matched the backup and no skill XP regressed (total XP advanced from 41824 to 46638 during normal offline/active progress). No test state or levels were injected. `preservation-result.json` records the checks.

Inspected actual Rockslide, Settings and Hub screens on the phone. Raw captures are 1080x2340 in `outputs/verification/phone-preview-oct25/`; `hub-final.png` shows the latest signs with existing progression. No tearing or canvas corruption was visible in the inspected frames, and the app log showed OpenGL ES 3.2 Compatibility on Adreno 750 with no script/parse errors or fatal exception. This is a focused installation/rendering check, not full release acceptance.

Game audio is muted for preview inspection (SFX was already muted, Music was toggled off through Settings). The phone's original media volume of 7 was restored. Preview remains open on the hub for Brian to test.
