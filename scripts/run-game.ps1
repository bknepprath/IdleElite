$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"

if (-not (Test-Path -LiteralPath $runner)) {
    throw "Godot runner was not found at $runner"
}

& $runner --headless --path $projectRoot --quit-after 1
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
