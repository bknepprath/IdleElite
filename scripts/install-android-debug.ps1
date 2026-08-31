$ErrorActionPreference = "Stop"

$phoneInstaller = Join-Path (Split-Path -Parent $PSScriptRoot) "scripts\install-android-phone-debug.ps1"

if (Test-Path -LiteralPath $phoneInstaller) { & $phoneInstaller; exit $LASTEXITCODE }

throw "Phone debug installer not found at $phoneInstaller"
