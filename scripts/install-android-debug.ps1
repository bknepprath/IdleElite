$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
$apk = Join-Path $projectRoot "builds\android\idle-elite-debug.apk"

if (-not (Test-Path -LiteralPath $adb)) {
    throw "adb not found at $adb"
}
if (-not (Test-Path -LiteralPath $apk)) {
    throw "Debug APK not found at $apk"
}

& $adb devices -l
& $adb install -r $apk
& $adb shell monkey -p com.idleelite.game -c android.intent.category.LAUNCHER 1
