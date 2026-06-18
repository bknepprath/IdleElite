$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceFiles = @(
    "project.godot",
    "export_presets.cfg",
    "scripts/main.gd",
    "scripts/ui/boot_flex_loading_animation.gd",
    "docs/activity-database.json"
)

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Convert-ResourcePathToProjectPath {
    param([Parameter(Mandatory = $true)][string]$ResourcePath)

    $relativePath = $ResourcePath.Substring("res://".Length).Replace("/", [IO.Path]::DirectorySeparatorChar)
    Join-Path $projectRoot $relativePath
}

function Add-ResourcePath {
    param(
        [Parameter(Mandatory = $true)][hashtable]$PathsByResourcePath,
        [Parameter(Mandatory = $true)][string]$ResourcePath,
        [Parameter(Mandatory = $true)][string]$SourceFile
    )

    if ($ResourcePath -notmatch '^res://(assets|docs)/') {
        return
    }
    if ($ResourcePath -match '[%{}]') {
        return
    }
    if (-not $PathsByResourcePath.ContainsKey($ResourcePath)) {
        $PathsByResourcePath[$ResourcePath] = New-Object System.Collections.Generic.List[string]
    }
    $PathsByResourcePath[$ResourcePath].Add($SourceFile)
}

$pathsByResourcePath = @{}

foreach ($sourceFile in $sourceFiles) {
    $sourcePath = Join-Path $projectRoot $sourceFile
    Assert-True (Test-Path -LiteralPath $sourcePath) "Missing asset path source file: $sourceFile"

    $text = Get-Content -LiteralPath $sourcePath -Raw
    foreach ($match in [regex]::Matches($text, '["''](?<path>res://[^"'']+)["'']')) {
        Add-ResourcePath $pathsByResourcePath $match.Groups["path"].Value $sourceFile
    }
}

$missing = New-Object System.Collections.Generic.List[string]
foreach ($resourcePath in ($pathsByResourcePath.Keys | Sort-Object)) {
    $projectPath = Convert-ResourcePathToProjectPath $resourcePath
    if (-not (Test-Path -LiteralPath $projectPath)) {
        $owners = ($pathsByResourcePath[$resourcePath] | Sort-Object -Unique) -join ", "
        $missing.Add("$resourcePath referenced by $owners")
    }
}

if ($missing.Count -gt 0) {
    $missing | ForEach-Object { Write-Output "missing-runtime-asset-path $_" }
    throw "Runtime asset path check found $($missing.Count) missing paths."
}

Write-Output "runtime-asset-paths-ok"
