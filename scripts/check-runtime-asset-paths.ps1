$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$sourceFileExtensions = @(
    ".cfg",
    ".gd",
    ".godot",
    ".json",
    ".tres",
    ".tscn"
)
$ignoredSourcePathPrefixes = @(
    ".codex-tmp",
    ".codex-tools",
    ".git",
    ".godot",
    "android/build",
    "assets/test-results",
    "builds",
    "output",
    "outputs",
    "play-store",
    "release",
    "scripts/tests",
    "test-results",
    "tmp"
)

function Convert-ResourcePathToProjectPath {
    param([Parameter(Mandatory = $true)][string]$ResourcePath)

    $relativePath = $ResourcePath.Substring("res://".Length).Replace("/", [IO.Path]::DirectorySeparatorChar)
    Join-Path $projectRoot $relativePath
}

function Convert-ToProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $rootPath = [IO.Path]::GetFullPath($projectRoot).TrimEnd("\", "/")
    $fullPath = [IO.Path]::GetFullPath($Path)
    if (-not $fullPath.StartsWith($rootPath + [IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the project root: $Path"
    }
    $relativePath = $fullPath.Substring($rootPath.Length).TrimStart("\", "/")
    $relativePath.Replace("\", "/")
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

function Test-IsIgnoredSourcePath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $normalized = $RelativePath.Replace("\", "/")
    foreach ($prefix in $ignoredSourcePathPrefixes) {
        if ($normalized -eq $prefix -or $normalized.StartsWith("$prefix/")) {
            return $true
        }
    }
    return $false
}

$pathsByResourcePath = @{}
$exportExcludeFilters = New-Object System.Collections.Generic.List[string]
# Prune generated/build directories before descending into them, rather than
# traversing every scratch file and resolving its path only to discard it.
function Get-RuntimeSourceFiles([string]$Directory) {
    foreach ($item in Get-ChildItem -LiteralPath $Directory) {
        $relativePath = Convert-ToProjectRelativePath $item.FullName
        if (Test-IsIgnoredSourcePath $relativePath) { continue }
        if ($item.PSIsContainer) {
            Get-RuntimeSourceFiles $item.FullName
        } elseif ($sourceFileExtensions -contains $item.Extension) {
            $relativePath
        }
    }
}
$sourceFiles = @(
    Get-RuntimeSourceFiles $projectRoot | Sort-Object
)

Assert-True ($sourceFiles.Count -gt 0) "Runtime asset path check did not discover any source files."

foreach ($sourceFile in $sourceFiles) {
    $sourcePath = Join-Path $projectRoot $sourceFile
    Assert-True (Test-Path -LiteralPath $sourcePath) "Missing asset path source file: $sourceFile"

    $text = Get-Content -LiteralPath $sourcePath -Raw
    if ($null -eq $text) {
        $text = ""
    }
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

# Formatted material paths are dynamic. Expand the actual catalog so missing
# construction artwork cannot hide behind the formatter exclusion above.
$database = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'docs/activity-database.json') | ConvertFrom-Json
$materials = @($database.skills.actions | Where-Object { $_.unlock_project } | ForEach-Object { $_.unlock_project.material } | Sort-Object -Unique)
foreach ($material in $materials) {
    foreach ($stem in @('project-chip','unlock-holder')) {
        Add-ResourcePath $pathsByResourcePath "res://assets/content/ui/$stem-$material.png" 'construction material catalog'
    }
    if ($material -in @('timber','stone')) {
        Add-ResourcePath $pathsByResourcePath "res://assets/content/ui/project-$material-states.png" 'construction material catalog'
    } else {
        foreach ($frame in 0..3) {
            Add-ResourcePath $pathsByResourcePath "res://assets/content/ui/project-damage-$material-$frame.png" 'construction material catalog'
        }
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
