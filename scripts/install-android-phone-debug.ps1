# Export a debug Android build and install it on the connected phone.
# Uses com.idleelite.game.preview when the release-signed app is already installed.

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$buildGradlePath = Join-Path $projectRoot "android\build\build.gradle"
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$java = Join-Path "C:\Program Files\Android\Android Studio\jbr\bin" "java.exe"
$bundletool = Join-Path $projectRoot ".codex-tools\bundletool-all-1.18.3.jar"
$ks = Join-Path $env:USERPROFILE ".android\debug.keystore"
$aab = Join-Path $projectRoot "builds\android\idle-elite-preview-debug.aab"
$apks = Join-Path $projectRoot "builds\android\idle-elite-preview-debug.apks"
$packageName = "com.idleelite.game.preview"
$presetName = "Android Release"

function Assert-CommandSucceeded {
    param([string] $Action)
    if ($LASTEXITCODE -ne 0) {
        throw "$Action failed with exit code $LASTEXITCODE"
    }
}

foreach ($path in @($runner, $exportPresetsPath, $buildGradlePath, $adb, $java, $bundletool, $ks)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required file not found: $path"
    }
}

& $adb devices -l
$devices = (& $adb devices | Select-String "device$" | Where-Object { $_ -notmatch "List of devices" })
if ($devices.Count -eq 0) {
    throw "No authorized Android device found. Accept the USB debugging prompt and retry."
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $aab) | Out-Null

$originalExportPresets = Get-Content -Raw -LiteralPath $exportPresetsPath
$originalBuildGradle = Get-Content -Raw -LiteralPath $buildGradlePath
try {
    $patched = $originalExportPresets `
        -replace '(?m)^package/unique_name="com\.idleelite\.game"$', 'package/unique_name="com.idleelite.game.preview"' `
        -replace '(?m)^package/name="Idle Elite"$', 'package/name="Idle Elite Preview"'
    Set-Content -LiteralPath $exportPresetsPath -Value $patched -NoNewline
    $patchedBuildGradle = $originalBuildGradle -replace 'applicationId getExportPackageName\(\)', 'applicationId "com.idleelite.game.preview"'
    if ($patchedBuildGradle -eq $originalBuildGradle) {
        throw "Could not patch Android applicationId for preview export."
    }
    Set-Content -LiteralPath $buildGradlePath -Value $patchedBuildGradle -NoNewline
    Push-Location $projectRoot
    & $runner --path . --export-debug $presetName $aab 2>&1 | Out-Host
    Assert-CommandSucceeded "Godot export-debug"
} finally {
    Set-Content -LiteralPath $buildGradlePath -Value $originalBuildGradle -NoNewline
    Set-Content -LiteralPath $exportPresetsPath -Value $originalExportPresets -NoNewline
    Pop-Location
}

if (Test-Path -LiteralPath $apks) {
    Remove-Item -LiteralPath $apks -Force
}

& $java -jar $bundletool build-apks `
    --bundle=$aab `
    --output=$apks `
    --mode=universal `
    --ks=$ks `
    --ks-pass=pass:android `
    --ks-key-alias=androiddebugkey `
    --key-pass=pass:android
Assert-CommandSucceeded "bundletool build-apks"

& $java -jar $bundletool install-apks --apks=$apks --adb=$adb
Assert-CommandSucceeded "bundletool install-apks"

& $adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Host
Assert-CommandSucceeded "Launch $packageName"

Write-Output "Installed and launched $packageName from $apks"
