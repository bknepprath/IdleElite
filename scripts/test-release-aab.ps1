param(
    [switch] $UninstallExisting,
    [switch] $ConfirmDataLoss,
    [switch] $AllowFreshInstall,
    [switch] $AllowSameVersionReinstall
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

function Get-InstalledVersionCode {
    $packagePaths = @(& $adb shell pm path $packageName 2>$null)
    if ($LASTEXITCODE -ne 0 -or @($packagePaths | Where-Object { $_ -match '^package:' }).Count -eq 0) {
        return $null
    }

    $packageDetails = @(& $adb shell dumpsys package $packageName 2>$null)
    Assert-NativeCommandSucceeded "Reading installed package metadata for $packageName"
    $versionLine = @($packageDetails | Where-Object { $_ -match '^\s*versionCode=(\d+)' } | Select-Object -First 1)
    if ($versionLine.Count -ne 1 -or [string]$versionLine[0] -notmatch '^\s*versionCode=(\d+)') {
        throw "Could not read the installed versionCode for $packageName."
    }
    return [int]$Matches[1]
}

if (-not (Test-Path -LiteralPath $exportPresetsPath)) {
    throw "Required file not found: $exportPresetsPath"
}
$exportPresets = Get-Content -Raw -LiteralPath $exportPresetsPath
$expectedKeystorePath = 'release/idle-elite-upload.keystore'
if ($exportPresets -notmatch ('(?m)^keystore/release="' + [regex]::Escape($expectedKeystorePath) + '"$')) {
    throw "Android release preset must use the portable $expectedKeystorePath keystore path."
}
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
if ($UninstallExisting -and -not $ConfirmDataLoss) {
    throw "Uninstall blocked: pass both -UninstallExisting and -ConfirmDataLoss only for a disposable install whose data may be erased."
}

& (Join-Path $projectRoot "scripts\check-android-backup-artifact.ps1") -AabPath $aab

& $adb wait-for-device
Assert-NativeCommandSucceeded "Waiting for Android device"

$installedVersionCode = Get-InstalledVersionCode
if ($UninstallExisting) {
    if ($null -ne $installedVersionCode) {
        & $adb uninstall $packageName | Out-Host
        Assert-NativeCommandSucceeded "Uninstalling $packageName"
    }
} elseif ($null -eq $installedVersionCode) {
    if (-not $AllowFreshInstall) {
        throw "Update validation blocked: $packageName is not installed. Install the previous locally signed release first, or pass -AllowFreshInstall for an explicit fresh-install smoke test."
    }
} elseif ($installedVersionCode -gt [int]$versionCode) {
    throw "Update validation blocked: installed versionCode $installedVersionCode is newer than target versionCode $versionCode."
} elseif ($installedVersionCode -eq [int]$versionCode -and -not $AllowSameVersionReinstall) {
    throw "Update validation blocked: installed versionCode already equals target versionCode $versionCode. Install the previous locally signed release first, or pass -AllowSameVersionReinstall for a non-migration reinstall smoke test."
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

$installedTargetVersionCode = Get-InstalledVersionCode
if ($null -eq $installedTargetVersionCode -or $installedTargetVersionCode -ne [int]$versionCode) {
    throw "Installed package versionCode does not match target versionCode $versionCode."
}

& $adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Host
Assert-NativeCommandSucceeded "Launching $packageName"

if ($null -ne $installedVersionCode -and -not $UninstallExisting) {
    Write-Output "Updated and launched $packageName from versionCode $installedVersionCode to $installedTargetVersionCode using $apks"
} else {
    Write-Output "Fresh-installed and launched $packageName at versionCode $installedTargetVersionCode from $apks"
}
