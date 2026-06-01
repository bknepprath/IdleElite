$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$phoneInstaller = Join-Path $projectRoot "scripts\install-android-phone-debug.ps1"

if (Test-Path -LiteralPath $phoneInstaller) {
    & $phoneInstaller
    exit $LASTEXITCODE
}

throw "Phone debug installer not found at $phoneInstaller"
