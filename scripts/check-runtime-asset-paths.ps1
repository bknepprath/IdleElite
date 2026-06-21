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
$exportExcludeFilters = New-Object System.Collections.Generic.List[string]

foreach ($sourceFile in $sourceFiles) {
    $sourcePath = Join-Path $projectRoot $sourceFile
    Assert-True (Test-Path -LiteralPath $sourcePath) "Missing asset path source file: $sourceFile"

    $text = Get-Content -LiteralPath $sourcePath -Raw
    if ($sourceFile -eq "export_presets.cfg") {
        foreach ($match in [regex]::Matches($text, 'exclude_filter="(?<filters>[^"]*)"')) {
            foreach ($filter in $match.Groups["filters"].Value.Split(",")) {
                $trimmed = $filter.Trim()
                if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
                    $exportExcludeFilters.Add($trimmed)
                }
            }
        }
    }
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

$excludedRuntimeAssets = New-Object System.Collections.Generic.List[string]
foreach ($resourcePath in ($pathsByResourcePath.Keys | Sort-Object)) {
    $projectRelativePath = $resourcePath.Substring("res://".Length)
    foreach ($filter in $exportExcludeFilters) {
        if ($projectRelativePath -like $filter) {
            $owners = ($pathsByResourcePath[$resourcePath] | Sort-Object -Unique) -join ", "
            $excludedRuntimeAssets.Add("$resourcePath referenced by $owners is excluded by $filter")
        }
    }
}

if ($excludedRuntimeAssets.Count -gt 0) {
    $excludedRuntimeAssets | ForEach-Object { Write-Output "excluded-runtime-asset $_" }
    throw "Runtime asset path check found $($excludedRuntimeAssets.Count) exported runtime assets blocked by export filters."
}

Write-Output "runtime-asset-paths-ok"
