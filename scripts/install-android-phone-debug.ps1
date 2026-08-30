# Export a debug Android build and install it on the connected phone.
# Uses com.idleelite.game.preview when the release-signed app is already installed.

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$buildScript = Join-Path $PSScriptRoot "build-android-preview.ps1"
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$aapt2 = Join-Path $env:LOCALAPPDATA "Android\Sdk\build-tools\36.1.0\aapt2.exe"
$java = Join-Path "C:\Program Files\Android\Android Studio\jbr\bin" "java.exe"
$ks = Join-Path $env:USERPROFILE ".android\debug.keystore"
$aab = Join-Path $projectRoot "builds\android\idle-elite-preview-debug.aab"
$apks = Join-Path $projectRoot "builds\android\idle-elite-preview-debug.apks"
$packageName = "com.idleelite.game.preview"

function Assert-CommandSucceeded {
    param([string] $Action)
    if ($LASTEXITCODE -ne 0) {
        throw "$Action failed with exit code $LASTEXITCODE"
    }
}

$gitCommonDir = (& git -C $projectRoot rev-parse --git-common-dir).Trim()
Assert-CommandSucceeded "Resolve Git common directory"
if (-not [System.IO.Path]::IsPathRooted($gitCommonDir)) {
    $gitCommonDir = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $gitCommonDir))
}
$sharedProjectRoot = Split-Path -Parent $gitCommonDir
$bundletoolCandidates = @(
    (Join-Path $projectRoot ".codex-tools\bundletool-all-1.18.3.jar"),
    (Join-Path $sharedProjectRoot ".codex-tools\bundletool-all-1.18.3.jar")
)
$bundletool = $bundletoolCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $bundletool) {
    throw "Required bundletool file was not found. Checked: $($bundletoolCandidates -join ', ')"
}

foreach ($path in @($buildScript, $adb, $aapt2, $java, $bundletool, $ks)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required file not found: $path"
    }
}

& $adb devices -l
$devices = (& $adb devices | Select-String "device$" | Where-Object { $_ -notmatch "List of devices" })
if ($devices.Count -eq 0) {
    throw "No authorized Android device found. Accept the USB debugging prompt and retry."
}

& $buildScript | Out-Host

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
    --key-pass=pass:android `
    --aapt2=$aapt2
Assert-CommandSucceeded "bundletool build-apks"

& $java -jar $bundletool install-apks --apks=$apks --adb=$adb
Assert-CommandSucceeded "bundletool install-apks"

& $adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 | Out-Host
Assert-CommandSucceeded "Launch $packageName"

Write-Output "Installed and launched $packageName from $apks"
