$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = "C:\Program Files\Godot\Godot.exe"

if (-not (Test-Path -LiteralPath $godot)) {
    throw "Godot was not found at $godot"
}

& $godot --path $projectRoot

