param(
    [switch] $UninstallExisting
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$bundletool = Join-Path $projectRoot ".codex-tools\bundletool-all-1.18.3.jar"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$keystore = Join-Path $projectRoot "release\idle-elite-upload.keystore"
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$java = Join-Path "C:\Program Files\Android\Android Studio\jbr\bin" "java.exe"
$packageName = "com.idleelite.game"
$keystorePassword = $env:IDLE_ELITE_KEYSTORE_PASSWORD

function Assert-NativeCommandSucceeded {
    param(
        [string] $Action
    )

    if ($LASTEXITCODE -ne 0) {
        throw "$Action failed with exit code $LASTEXITCODE"
    }
}

if (-not (Test-Path -LiteralPath $exportPresetsPath)) {
    throw "Required file not found: $exportPresetsPath"
}
$exportPresets = Get-Content -Raw -LiteralPath $exportPresetsPath
if ($exportPresets -notmatch '(?m)^version/name="([^"]+)"') {
    throw "Could not read Android version name from $exportPresetsPath"
}
$versionName = $Matches[1]
if ($exportPresets -notmatch '(?m)^version/code=(\d+)') {
    throw "Could not read Android version code from $exportPresetsPath"
}
$versionCode = $Matches[1]
$artifactBaseName = "idle-elite-release-v$versionName-code$versionCode"
$aab = Join-Path $projectRoot "builds\android\$artifactBaseName.aab"
$apks = Join-Path $projectRoot "builds\android\$artifactBaseName.apks"

foreach ($path in @($bundletool, $aab, $keystore, $adb, $java)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required file not found: $path"
    }
}

if ([string]::IsNullOrWhiteSpace($keystorePassword)) {
    throw "Set IDLE_ELITE_KEYSTORE_PASSWORD before running this script."
}

& $adb wait-for-device
Assert-NativeCommandSucceeded "Waiting for Android device"

if ($UninstallExisting) {
    & $adb uninstall $packageName | Out-Host
    Assert-NativeCommandSucceeded "Uninstalling $packageName"
}

if (Test-Path -LiteralPath $apks) {
    Remove-Item -LiteralPath $apks -Force
}

& $java -jar $bundletool build-apks `
    --bundle=$aab `
    --output=$apks `
    --mode=universal `
    --ks=$keystore `
    --ks-pass=pass:$keystorePassword `
    --ks-key-alias=idleeliteupload `
    --key-pass=pass:$keystorePassword
Assert-NativeCommandSucceeded "Building APK set from $aab"

& $java -jar $bundletool install-apks --apks=$apks --adb=$adb
Assert-NativeCommandSucceeded "Installing APK set $apks"

& $adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Host
Assert-NativeCommandSucceeded "Launching $packageName"

Write-Output "Installed and launched $packageName from $apks"
