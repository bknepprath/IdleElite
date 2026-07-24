$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $projectRoot "run-godot-safe.ps1") @args
exit $LASTEXITCODE
