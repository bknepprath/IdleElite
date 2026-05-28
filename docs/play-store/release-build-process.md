# Idle Elite Release Build Process

Use this when preparing a new Google Play closed-test release. This project uses Godot, so all Godot validation and export commands must go through `run-godot-safe.ps1` or a script that calls it.

## Release Inputs

Decide these before editing files:

- Version name, for example `0.1.10`
- Android version code, for example `11`
- Artifact base name, for example `idle-elite-release-v0.1.10-code11`
- Closed-test pack name, for example `closed-test-upload-v0.1.10-code11`

Keep `version/code` monotonically increasing for Google Play.

## Files To Update

Update `export_presets.cfg`:

- `export_path="builds/android/<artifact-base-name>.aab"`
- `version/code=<android-version-code>`
- `version/name="<version-name>"`
- Keep `keystore/release_password=""` in the committed file.
- Keep local/generated folders excluded from export:
  `builds/*`, `release/*`, `google key downloads/*`, `.codex-tmp/*`, `.codex-tools/*`

Update current-release docs:

- `docs/play-store/launch-runbook.md`
- `docs/play-store/final-upload-checklist.md`
- Add a new dated readiness note, for example `docs/play-store/launch-readiness-YYYY-MM-DD.md`

Do not commit or paste files from `release/` or generated artifacts from `builds/`.

## Safe Build Commands

Run from the repo root.

```powershell
.\scripts\check-project.ps1
```

`check-project.ps1` calls `run-godot-safe.ps1` with headless Godot. After any Godot command, check for leftover Godot processes:

```powershell
Get-Process | Where-Object { $_.ProcessName -like '*Godot*' } | Select-Object Id,ProcessName,Path,MainWindowTitle
```

Leave visible editor, project manager, and visible game windows alone. Only report them unless you are certain a headless validation command left a process behind.

Set the upload keystore password in the current shell, then build:

```powershell
$env:IDLE_ELITE_KEYSTORE_PASSWORD = "<upload keystore password>"
.\scripts\build-android-release.ps1
```

The password is stored locally in ignored release notes on this machine. Do not write the password into committed files. `build-android-release.ps1` temporarily injects it into `export_presets.cfg`, exports through `run-godot-safe.ps1`, then restores the original file.

After the build, verify the preset is clean:

```powershell
Select-String -Path export_presets.cfg -Pattern 'version/code','version/name','export_path','keystore/release_password'
```

Expected: the release password line is `keystore/release_password=""`.

Godot export may dirty generated files under `android/build`. If the worktree was clean before the export and the only unexpected changes are generated `android/build` churn, restore only that path:

```powershell
git restore -- android\build
```

If there were pre-existing user changes, inspect first and do not revert unrelated work.

## Artifact Validation

Use these paths:

```powershell
$artifactBaseName = "idle-elite-release-v<version-name>-code<version-code>"
$aab = "builds\android\$artifactBaseName.aab"
$apks = "builds\android\$artifactBaseName.apks"
$bundletool = ".codex-tools\bundletool-all-1.18.3.jar"
$java = "C:\Program Files\Android\Android Studio\jbr\bin\java.exe"
$jarsigner = "C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe"
$keystore = "release\idle-elite-upload.keystore"
```

Verify signing:

```powershell
& $jarsigner -verify $aab
```

Expected: `jar verified`, with self-signed upload-key warnings.

Validate the bundle:

```powershell
& $java -jar $bundletool validate --bundle=$aab
```

Dump the manifest:

```powershell
& $java -jar $bundletool dump manifest --bundle=$aab
```

Confirm:

- `package="com.idleelite.game"`
- `android:versionCode` matches the requested code
- `android:versionName` matches the requested version
- `android:minSdkVersion="24"`
- `android:targetSdkVersion="35"`
- AdMob app ID is present: `ca-app-pub-3570919669688101~3616255490`

Check that local release/build payloads were not packed into the AAB:

```powershell
& "C:\Program Files\Android\Android Studio\jbr\bin\jar.exe" tf $aab |
    Select-String -Pattern 'closed-test-upload','idle-elite-closed-test','release/idle-elite-upload','local-release-notes','\.codex'
```

Expected: no output.

Generate the local APK set:

```powershell
if (Test-Path -LiteralPath $apks) { Remove-Item -LiteralPath $apks -Force }
& $java -jar $bundletool build-apks `
    --bundle=$aab `
    --output=$apks `
    --mode=universal `
    --ks=$keystore `
    --ks-pass=pass:$env:IDLE_ELITE_KEYSTORE_PASSWORD `
    --ks-key-alias=idleeliteupload `
    --key-pass=pass:$env:IDLE_ELITE_KEYSTORE_PASSWORD
```

Record sizes and SHA-256 hashes:

```powershell
Get-ChildItem $aab,$apks | Select-Object Name,Length,LastWriteTime
Get-FileHash -Algorithm SHA256 $aab,$apks | Format-List Path,Hash
```

## Device Smoke Test

Check for a connected device:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices
```

If a device is connected:

```powershell
.\scripts\test-release-aab.ps1 -UninstallExisting
```

Then launch and verify:

- App installs and opens.
- Rewarded ad prompt loads through the closed-test track.
- Closing or skipping the ad does not grant the boost.
- Completing the ad grants the +10% XP boost.
- Logcat does not show crashes or repeated AdMob errors.

If no device is connected, note that the device install smoke test was not run.

## Closed-Test Upload Pack

Create an ignored upload folder under `builds/closed-test-upload-v<version-name>-code<version-code>`.

Include:

- `<artifact-base-name>.aab`
- `docs/play-store/app-content-notes.md`
- `docs/play-store/final-upload-checklist.md`
- `docs/play-store/google-play-store-listing.md`
- `docs/play-store/launch-runbook.md`
- `docs/play-store/privacy-policy-draft.md`
- The dated readiness note
- `play-store-assets/app-icon-512.png`
- `play-store-assets/feature-graphic-1024x500.png`
- `play-store-assets/screenshot-*.png`
- `UPLOAD-MANIFEST.txt`

`UPLOAD-MANIFEST.txt` should include:

- Version name
- Version code
- Package name
- Primary upload file
- AAB SHA-256
- AAB size
- Validation performed
- Any validation skipped, especially device install smoke testing
- A note that signing material is intentionally excluded

Zip the upload folder:

```powershell
Compress-Archive -Path "builds\closed-test-upload-v<version-name>-code<version-code>\*" `
    -DestinationPath "builds\idle-elite-closed-test-v<version-name>-code<version-code>.zip"
Get-FileHash -Algorithm SHA256 "builds\idle-elite-closed-test-v<version-name>-code<version-code>.zip" | Format-List Path,Hash
```

Before finishing, confirm:

- No stale previous-version references remain in current release docs.
- `export_presets.cfg` has an empty release password.
- `android/build` export churn has been restored if appropriate.
- `git status --short` only shows intentional tracked doc/script/version changes.
