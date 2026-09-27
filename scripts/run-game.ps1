$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $projectRoot "run-godot-safe.ps1") --headless --path $projectRoot --quit-after 1
exit $LASTEXITCODE
