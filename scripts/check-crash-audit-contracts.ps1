$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runtimeSourceExtensions = @(".cfg", ".gd", ".godot", ".json", ".ps1", ".tres", ".tscn")
$ignoredPathPrefixes = @(
    ".codex-tmp",
    ".codex-tools",
    ".git",
    ".godot",
    "android/build",
    "builds",
    "play-store",
    "release",
    "output",
    "test-results"
)

function Convert-ToProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $rootPath = (Resolve-Path -LiteralPath $projectRoot).Path.TrimEnd("\", "/")
    $fullPath = (Resolve-Path -LiteralPath $Path).Path
    Assert-True ($fullPath.StartsWith($rootPath, [System.StringComparison]::OrdinalIgnoreCase)) "Path is outside project root: $Path"
    $fullPath.Substring($rootPath.Length).TrimStart("\", "/").Replace("\", "/")
}

function Convert-ResourcePathToProjectPath {
    param([Parameter(Mandatory = $true)][string]$ResourcePath)

    Assert-True ($ResourcePath.StartsWith("res://")) "Not a project resource path: $ResourcePath"
    Join-Path $projectRoot $ResourcePath.Substring("res://".Length).Replace("/", [IO.Path]::DirectorySeparatorChar)
}

function Test-IsIgnoredPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $normalized = $RelativePath.Replace("\", "/")
    foreach ($prefix in $ignoredPathPrefixes) {
        if ($normalized -eq $prefix -or $normalized.StartsWith("$prefix/")) {
            return $true
        }
    }
    return $false
}

function Get-RuntimeSourceFiles {
    @(
        Get-ChildItem -LiteralPath $projectRoot -File -Recurse |
            Where-Object {
                $relativePath = Convert-ToProjectRelativePath $_.FullName
                ($runtimeSourceExtensions -contains $_.Extension) -and -not (Test-IsIgnoredPath $relativePath)
            } |
            ForEach-Object { Convert-ToProjectRelativePath $_.FullName } |
            Sort-Object
    )
}

function Assert-ResourcePathExists {
    param(
        [Parameter(Mandatory = $true)][string]$ResourcePath,
        [Parameter(Mandatory = $true)][string]$Owner
    )

    if ($ResourcePath -match '[%{}]' -or $ResourcePath -notmatch '^res://') {
        return
    }
    $projectPath = Convert-ResourcePathToProjectPath $ResourcePath
    Assert-True (Test-Path -LiteralPath $projectPath) "Missing resource path $ResourcePath referenced by $Owner."
}

$projectPath = Join-Path $projectRoot "project.godot"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$safeRunnerPath = Join-Path $projectRoot "run-godot-safe.ps1"
$mainScenePath = Join-Path $projectRoot "scenes\main.tscn"

Assert-True (Test-Path -LiteralPath $projectPath) "Missing project.godot."
Assert-True (Test-Path -LiteralPath $exportPresetsPath) "Missing export_presets.cfg."
Assert-True (Test-Path -LiteralPath $safeRunnerPath) "Missing run-godot-safe.ps1."
Assert-True (Test-Path -LiteralPath $mainScenePath) "Missing scenes\main.tscn."

$projectText = Get-Content -LiteralPath $projectPath -Raw
$exportText = Get-Content -LiteralPath $exportPresetsPath -Raw
$safeRunnerText = Get-Content -LiteralPath $safeRunnerPath -Raw

Assert-True ($projectText -match 'run/main_scene="res://scenes/main\.tscn"') "project.godot should launch scenes/main.tscn."
Assert-True ($projectText -match 'config/quit_on_go_back=false') "Android back button should not quit the game unexpectedly."
Assert-True ($projectText -match 'window/stretch/mode="canvas_items"') "Project stretch mode should stay canvas_items for crisp phone UI."
Assert-True ($projectText -match 'window/stretch/aspect="expand"') "Project stretch aspect should stay expand for phone layout stability."
foreach ($match in [regex]::Matches($projectText, '"(?<path>res://[^"]+)"')) {
    Assert-ResourcePathExists $match.Groups["path"].Value "project.godot"
}

Assert-True ($safeRunnerText -match 'Godot\.exe') "The safe runner should be the only script that names Godot.exe directly."
Assert-True ($safeRunnerText -match '--headless') "The safe runner should default automated runs to headless mode."
Assert-True ($safeRunnerText -match '--visible-game') "The safe runner should explicitly gate visible game launches."

$directGodotLaunches = New-Object System.Collections.Generic.List[string]
foreach ($sourceFile in Get-RuntimeSourceFiles) {
    if ($sourceFile -eq "run-godot-safe.ps1" -or $sourceFile -eq "scripts/check-crash-audit-contracts.ps1") {
        continue
    }
    $text = Get-Content -LiteralPath (Join-Path $projectRoot $sourceFile) -Raw
    if ($text -match '(?i)\bGodot\.exe\b') {
        $directGodotLaunches.Add($sourceFile)
    }
}
Assert-True ($directGodotLaunches.Count -eq 0) "Only run-godot-safe.ps1 may reference Godot.exe directly: $($directGodotLaunches -join ', ')"

Assert-True ($exportText -match 'platform="Android"') "Android export preset is missing."
Assert-True ($exportText -match 'export_filter="all_resources"') "Android export should include all resources unless explicitly excluded."
Assert-True ($exportText -match 'gradle_build/use_gradle_build=true') "Android export should use the Gradle build."
Assert-True ($exportText -match 'architectures/arm64-v8a=true') "Android release should include arm64-v8a."
Assert-True ($exportText -match 'architectures/armeabi-v7a=false') "Android release should not unexpectedly include armeabi-v7a."
Assert-True ($exportText -match 'package/unique_name="com\.idleelite\.game"') "Android release package id should remain com.idleelite.game."
Assert-True ($exportText -match 'package/signed=true') "Android release should stay signed."
Assert-True ($exportText -match 'user_data_backup/allow=false') "Android user-data backup should remain disabled for save consistency."
Assert-True ($exportText -match 'permissions/internet=true') "Android internet permission is required for leaderboard/ad integrations."
Assert-True ($exportText -match 'permissions/access_network_state=true') "Android access_network_state permission is required for network availability checks."
Assert-True ($exportText -match 'permissions/write_external_storage=false') "Android release should not request broad external storage write permission."
Assert-True ($exportText -match 'permissions/read_external_storage=false') "Android release should not request broad external storage read permission."

$includeMatch = [regex]::Match($exportText, 'include_filter="(?<filters>[^"]*)"')
Assert-True $includeMatch.Success "Android export include_filter is missing."
foreach ($includePath in $includeMatch.Groups["filters"].Value.Split(",")) {
    $trimmed = $includePath.Trim()
    if ($trimmed.Length -eq 0) {
        continue
    }
    $path = Join-Path $projectRoot $trimmed.Replace("/", [IO.Path]::DirectorySeparatorChar)
    Assert-True (Test-Path -LiteralPath $path) "Android export include_filter references missing file: $trimmed"
}

$excludeMatch = [regex]::Match($exportText, 'exclude_filter="(?<filters>[^"]*)"')
Assert-True $excludeMatch.Success "Android export exclude_filter is missing."
$excludeFilters = @($excludeMatch.Groups["filters"].Value.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })
foreach ($requiredExclude in @(".codex-tmp/*", ".codex-tools/*", "android/build/*", "play-store/*", "docs/*.html")) {
    Assert-True ($excludeFilters -contains $requiredExclude) "Android export exclude_filter is missing $requiredExclude."
}

$sceneFiles = @(
    Get-ChildItem -LiteralPath $projectRoot -Recurse -File |
        Where-Object { $_.Extension -in @(".tscn", ".tres") } |
        ForEach-Object { Convert-ToProjectRelativePath $_.FullName } |
        Where-Object { -not (Test-IsIgnoredPath $_) }
)
foreach ($sceneFile in $sceneFiles) {
    $text = Get-Content -LiteralPath (Join-Path $projectRoot $sceneFile) -Raw
    if ($null -eq $text) {
        $text = ""
    }
    foreach ($match in [regex]::Matches($text, '\bpath="(?<path>res://[^"]+)"')) {
        Assert-ResourcePathExists $match.Groups["path"].Value $sceneFile
    }
    foreach ($match in [regex]::Matches($text, '\bscript = ExtResource\("(?<id>[^"]+)"\)')) {
        $id = $match.Groups["id"].Value
        Assert-True ($text -match "\[ext_resource[^\]]+id=`"$([regex]::Escape($id))`"") "Scene $sceneFile references missing script ExtResource id $id."
    }
}

$jsonFiles = @(
    Get-ChildItem -LiteralPath $projectRoot -Recurse -File |
        Where-Object { $_.Extension -eq ".json" } |
        ForEach-Object { Convert-ToProjectRelativePath $_.FullName } |
        Where-Object { -not (Test-IsIgnoredPath $_) }
)
foreach ($jsonFile in $jsonFiles) {
    $raw = Get-Content -LiteralPath (Join-Path $projectRoot $jsonFile) -Raw
    if ($null -eq $raw) {
        $raw = ""
    }
    try {
        $null = $raw | ConvertFrom-Json
    } catch {
        throw "Invalid JSON in ${jsonFile}: $($_.Exception.Message)"
    }
}

Write-Output "crash-audit-contracts-ok"
