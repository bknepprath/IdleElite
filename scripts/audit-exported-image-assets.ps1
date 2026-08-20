<#
.SYNOPSIS
Builds a read-only inventory of image sources selected by a Godot export preset.

.DESCRIPTION
Evaluates Git-tracked image sources against an all_resources preset, reads image
dimensions and existing Godot .import sidecars, and records statically
discoverable production display sizes. The script does not launch Godot, import
assets, inspect .godot cache files, or mutate project files.

ExportStatus is a deterministic preset-filter result, not proof extracted from
an AAB or PCK. ImportMetadata distinguishes committed sidecars from untracked
sidecars observed in the current worktree.
#>
param(
    [string] $PresetName = "Android Release",
    [ValidateSet("Summary", "Csv", "Json")]
    [string] $Format = "Summary",
    [switch] $IncludeExcluded,
    [switch] $CheckSnapshot,
    [string] $SnapshotPath = "docs/performance-1080p-texture-inventory.csv",
    [string] $ArtifactPath = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$projectSettingsPath = Join-Path $projectRoot "project.godot"
$activityDatabasePath = Join-Path $projectRoot "docs/activity-database.json"
$actionArtUiPath = Join-Path $projectRoot "scripts/ui/action_art_ui.gd"
$imageExtensions = @(".png", ".jpg", ".jpeg", ".webp", ".svg")
$invariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function Normalize-ProjectPath {
    param([Parameter(Mandatory = $true)][string] $Path)
    $normalized = $Path.Replace("\", "/")
    while ($normalized.StartsWith("./", [System.StringComparison]::Ordinal)) {
        $normalized = $normalized.Substring(2)
    }
    return $normalized
}

function Get-TrackedProjectPaths {
    $output = @(& git -C $projectRoot ls-files)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not enumerate Git-tracked project files."
    }
    return @($output | ForEach-Object { Normalize-ProjectPath $_ } | Sort-Object -Unique)
}

function Get-ExportPreset {
    param(
        [Parameter(Mandatory = $true)][string] $Text,
        [Parameter(Mandatory = $true)][string] $Name
    )

    $presetPattern = '(?ms)^\[preset\.(?<id>\d+)\]\r?\n(?<body>.*?)(?=^\[preset\.\d+(?:\.options)?\]|\z)'
    foreach ($match in [regex]::Matches($Text, $presetPattern)) {
        $body = $match.Groups["body"].Value
        $nameMatch = [regex]::Match($body, '(?m)^name="(?<value>[^"]*)"\r?$')
        if (-not $nameMatch.Success -or $nameMatch.Groups["value"].Value -ne $Name) {
            continue
        }
        $exportFilterMatch = [regex]::Match($body, '(?m)^export_filter="(?<value>[^"]*)"\r?$')
        $includeMatch = [regex]::Match($body, '(?m)^include_filter="(?<value>[^"]*)"\r?$')
        $excludeMatch = [regex]::Match($body, '(?m)^exclude_filter="(?<value>[^"]*)"\r?$')
        if (-not $exportFilterMatch.Success -or -not $excludeMatch.Success) {
            throw "Export preset '$Name' is missing an export_filter or exclude_filter."
        }
        return [pscustomobject]@{
            Id = [int]$match.Groups["id"].Value
            Name = $Name
            ExportFilter = $exportFilterMatch.Groups["value"].Value
            IncludeFilters = @($includeMatch.Groups["value"].Value.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            ExcludeFilters = @($excludeMatch.Groups["value"].Value.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        }
    }
    throw "Export preset '$Name' was not found."
}

function Get-ExclusionPattern {
    param(
        [Parameter(Mandatory = $true)][string] $Path,
        [Parameter(Mandatory = $true)][string[]] $Patterns
    )
    foreach ($pattern in $Patterns) {
        # Keep this aligned with check-runtime-asset-paths.ps1, which uses
        # PowerShell wildcard matching for the project's Godot export filters.
        if ($Path -like $pattern) {
            return $pattern
        }
    }
    return ""
}

function Get-ImageDimensions {
    param([Parameter(Mandatory = $true)][string] $Path)

    $image = $null
    try {
        $image = [System.Drawing.Image]::FromFile($Path)
        return [pscustomobject]@{ Width = [int]$image.Width; Height = [int]$image.Height; Status = "measured" }
    } catch {
        return [pscustomobject]@{ Width = $null; Height = $null; Status = "unknown:$($_.Exception.GetType().Name)" }
    } finally {
        if ($null -ne $image) {
            $image.Dispose()
        }
    }
}

function Get-ArtifactImageInventory {
    param([Parameter(Mandatory = $true)][string] $Path)

    $absolutePath = $Path
    if (-not [IO.Path]::IsPathRooted($absolutePath)) {
        $absolutePath = Join-Path $projectRoot $absolutePath
    }
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        throw "Android export artifact was not found: $Path"
    }

    $resourcePaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $artifactResourceEntries = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $remapsByResourcePath = @{}
    $archive = $null
    try {
        $archive = [IO.Compression.ZipFile]::OpenRead($absolutePath)
        foreach ($entry in $archive.Entries) {
            $artifactResourceMatch = [regex]::Match($entry.FullName, '(?i)(?:^|/)assets/(?<resource>(?:assets|\.godot)/.+)$')
            if ($artifactResourceMatch.Success) {
                [void]$artifactResourceEntries.Add((Normalize-ProjectPath $artifactResourceMatch.Groups["resource"].Value))
            }
            # Godot Gradle exports put remap sidecars in an install-time asset
            # pack. Their exact resource-relative path survives in the AAB,
            # unlike the hashed imported .ctex filename.
            $match = [regex]::Match(
                $entry.FullName,
                '(?i)(?:^|/)assets/(?<resource>assets/.+?\.(?:png|jpg|jpeg|webp|svg))\.import$'
            )
            if ($match.Success) {
                $resourcePath = Normalize-ProjectPath $match.Groups["resource"].Value
                [void]$resourcePaths.Add($resourcePath)
                $stream = $null
                $reader = $null
                try {
                    $stream = $entry.Open()
                    $reader = [IO.StreamReader]::new($stream)
                    $remapText = $reader.ReadToEnd()
                    $pathMatch = [regex]::Match(
                        $remapText,
                        '(?m)^path(?:\.(?<format>[A-Za-z0-9_]+))?="res://(?<payload>[^"\r\n]+\.ctex)"\r?$'
                    )
                    if ($pathMatch.Success) {
                        $format = $pathMatch.Groups["format"].Value
                        if ([string]::IsNullOrWhiteSpace($format)) {
                            $format = "default"
                        }
                        $remapsByResourcePath[$resourcePath] = [pscustomobject]@{
                            Format = $format.ToLowerInvariant()
                            Payload = Normalize-ProjectPath $pathMatch.Groups["payload"].Value
                        }
                    }
                } finally {
                    if ($null -ne $reader) {
                        $reader.Dispose()
                    } elseif ($null -ne $stream) {
                        $stream.Dispose()
                    }
                }
            }
        }
    } finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
    }

    $file = Get-Item -LiteralPath $absolutePath
    return [pscustomobject]@{
        Path = $file.FullName
        Bytes = [int64]$file.Length
        LastWriteUtc = $file.LastWriteTimeUtc.ToString("o", $invariantCulture)
        Sha256 = (Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant()
        ImagePaths = $resourcePaths
        ResourceEntries = $artifactResourceEntries
        RemapsByResourcePath = $remapsByResourcePath
    }
}

function Get-ImportSettings {
    param(
        [Parameter(Mandatory = $true)][string] $ImagePath,
        [Parameter(Mandatory = $true)][hashtable] $TrackedPathSet
    )

    $importRelativePath = "$ImagePath.import"
    $importAbsolutePath = Join-Path $projectRoot $importRelativePath
    $importMetadataStatus = "tracked"
    if (-not $TrackedPathSet.ContainsKey($importRelativePath)) {
        $importMetadataStatus = "missing"
        if (Test-Path -LiteralPath $importAbsolutePath -PathType Leaf) {
            # Godot will use an existing sidecar during the current export even
            # when Git does not track it. Observe it, but keep the status so a
            # committed snapshot exposes the reproducibility gap.
            $importMetadataStatus = "untracked-observed"
        }
    }
    if ($importMetadataStatus -eq "missing") {
        return [pscustomobject]@{
            Status = $importMetadataStatus
            SettingsKnown = $false
            Importer = "unknown"
            ResourceType = "unknown"
            Mode = $null
            ModeName = "unknown"
            HighQuality = "unknown"
            ImportedFormats = "unknown"
            VramTexture = "unknown"
            Mipmaps = "unknown"
            SizeLimit = $null
        }
    }
    if (-not (Test-Path -LiteralPath $importAbsolutePath -PathType Leaf)) {
        return [pscustomobject]@{
            Status = "tracked-file-missing"
            SettingsKnown = $false
            Importer = "unknown"
            ResourceType = "unknown"
            Mode = $null
            ModeName = "unknown"
            HighQuality = "unknown"
            ImportedFormats = "unknown"
            VramTexture = "unknown"
            Mipmaps = "unknown"
            SizeLimit = $null
        }
    }

    $text = Get-Content -Raw -LiteralPath $importAbsolutePath
    $mode = $null
    if ($text -match '(?m)^compress/mode=(?<value>\d+)\r?$') {
        $mode = [int]$Matches["value"]
    }
    $modeNames = @{
        0 = "Lossless"
        1 = "Lossy"
        2 = "VRAM Compressed"
        3 = "VRAM Uncompressed"
        4 = "Basis Universal"
    }
    $modeName = "unknown"
    if ($null -ne $mode -and $modeNames.ContainsKey($mode)) {
        $modeName = $modeNames[$mode]
    } elseif ($null -ne $mode) {
        $modeName = "Unknown mode $mode"
    }

    $importer = "unknown"
    if ($text -match '(?m)^importer="(?<value>[^"]*)"\r?$') {
        $importer = $Matches["value"]
    }
    $resourceType = "unknown"
    if ($text -match '(?m)^type="(?<value>[^"]*)"\r?$') {
        $resourceType = $Matches["value"]
    }
    $highQuality = "unknown"
    if ($text -match '(?m)^compress/high_quality=(?<value>true|false)\r?$') {
        $highQuality = $Matches["value"]
    }
    $vramTexture = "unknown"
    if ($text -match '"vram_texture":\s*(?<value>true|false)') {
        $vramTexture = $Matches["value"]
    }
    $mipmaps = "unknown"
    if ($text -match '(?m)^mipmaps/generate=(?<value>true|false)\r?$') {
        $mipmaps = $Matches["value"]
    }
    $sizeLimit = $null
    if ($text -match '(?m)^process/size_limit=(?<value>\d+)\r?$') {
        $sizeLimit = [int]$Matches["value"]
    }
    $importedFormats = ""
    if ($text -match '"imported_formats":\s*\[(?<value>[^\]]*)\]') {
        $importedFormats = (($Matches["value"].Split(",") | ForEach-Object { $_.Trim().Trim('"') } | Where-Object { $_ }) -join ";")
    }
    if ([string]::IsNullOrWhiteSpace($importedFormats)) {
        $importedFormats = "default"
    }

    return [pscustomobject]@{
        Status = $importMetadataStatus
        SettingsKnown = $true
        Importer = $importer
        ResourceType = $resourceType
        Mode = $mode
        ModeName = $modeName
        HighQuality = $highQuality
        ImportedFormats = $importedFormats
        VramTexture = $vramTexture
        Mipmaps = $mipmaps
        SizeLimit = $sizeLimit
    }
}

function Add-ReferenceOwner {
    param(
        [Parameter(Mandatory = $true)][hashtable] $ReferencesByPath,
        [Parameter(Mandatory = $true)][string] $ImagePath,
        [Parameter(Mandatory = $true)][string] $Owner
    )
    $normalized = Normalize-ProjectPath $ImagePath
    if (-not $ReferencesByPath.ContainsKey($normalized)) {
        $ReferencesByPath[$normalized] = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    }
    [void]$ReferencesByPath[$normalized].Add($Owner)
}

function Add-DisplayEvidence {
    param(
        [Parameter(Mandatory = $true)][hashtable] $EvidenceByPath,
        [Parameter(Mandatory = $true)][string] $ImagePath,
        [Parameter(Mandatory = $true)][double] $Width,
        [Parameter(Mandatory = $true)][double] $Height,
        [Parameter(Mandatory = $true)][string] $Evidence,
        [switch] $Reviewed
    )
    $normalized = Normalize-ProjectPath $ImagePath
    if (-not $EvidenceByPath.ContainsKey($normalized)) {
        $EvidenceByPath[$normalized] = [System.Collections.Generic.List[object]]::new()
    }
    $EvidenceByPath[$normalized].Add([pscustomobject]@{
        Width = $Width
        Height = $Height
        Evidence = $Evidence
        Reviewed = [bool]$Reviewed
    })
}

function Find-ActivityArtPaths {
    param(
        [AllowNull()][object] $Value,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][System.Collections.Generic.HashSet[string]] $Paths
    )
    if ($null -eq $Value -or $Value -is [string] -or $Value.GetType().IsPrimitive) {
        return
    }
    if ($Value -is [pscustomobject]) {
        foreach ($property in $Value.PSObject.Properties) {
            if ($property.Name -eq "art" -and $property.Value -is [string] -and $property.Value -match '(?i)\.(png|jpg|jpeg|webp|svg)$') {
                [void]$Paths.Add((Normalize-ProjectPath ([string]$property.Value -replace '^res://', '')))
            }
            Find-ActivityArtPaths -Value $property.Value -Paths $Paths
        }
        return
    }
    if ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            if ([string]$key -eq "art" -and $Value[$key] -is [string] -and $Value[$key] -match '(?i)\.(png|jpg|jpeg|webp|svg)$') {
                [void]$Paths.Add((Normalize-ProjectPath ([string]$Value[$key] -replace '^res://', '')))
            }
            Find-ActivityArtPaths -Value $Value[$key] -Paths $Paths
        }
        return
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        foreach ($item in $Value) {
            Find-ActivityArtPaths -Value $item -Paths $Paths
        }
    }
}

function Format-Number {
    param([AllowNull()][object] $Value)
    if ($null -eq $Value) {
        return ""
    }
    return ([double]$Value).ToString("0.###", $invariantCulture)
}

function Convert-RowsToCsvText {
    param([Parameter(Mandatory = $true)][object[]] $Rows)
    return ((@($Rows | ConvertTo-Csv -NoTypeInformation) -join "`n") + "`n")
}

$trackedPaths = @(Get-TrackedProjectPaths)
$trackedPathSet = @{}
foreach ($path in $trackedPaths) {
    $trackedPathSet[$path] = $true
}

$exportPresetText = Get-Content -Raw -LiteralPath $exportPresetsPath
$preset = Get-ExportPreset -Text $exportPresetText -Name $PresetName
if ($preset.ExportFilter -ne "all_resources") {
    throw "The audit only supports export_filter=all_resources; '$PresetName' uses '$($preset.ExportFilter)'."
}

$projectSettings = Get-Content -Raw -LiteralPath $projectSettingsPath
$androidVramTarget = "not-enabled"
if ($projectSettings -match '(?m)^textures/vram_compression/import_etc2_astc=true\r?$') {
    $androidVramTarget = "etc2_astc"
}

$artifactInventory = $null
if (-not [string]::IsNullOrWhiteSpace($ArtifactPath)) {
    $artifactInventory = Get-ArtifactImageInventory -Path $ArtifactPath
}

$referencesByPath = @{}
$displayEvidenceByPath = @{}
$referenceExtensions = @(".gd", ".tscn", ".tres", ".godot", ".json", ".cfg")
$referencePathPattern = '(?i)["''](?:res://)?(?<path>assets/[^"'']+?\.(?:png|jpg|jpeg|webp|svg))["'']'
$literalImageSizePattern = '(?i)_image\(\s*["'']res://(?<path>assets/[^"'']+?\.(?:png|jpg|jpeg|webp|svg))["'']\s*,\s*Vector2\(\s*(?<width>\d+(?:\.\d+)?)\s*,\s*(?<height>\d+(?:\.\d+)?)\s*\)'
$symbolPathPattern = '(?im)^\s*(?:const|var)\s+(?<symbol>[A-Z_][A-Z0-9_]*)\s*(?::\s*String(?:Name)?)?\s*(?::=|=)\s*["''](?:res://)?(?<path>assets/[^"'']+?\.(?:png|jpg|jpeg|webp|svg))["'']'
foreach ($sourcePath in $trackedPaths) {
    $extension = [IO.Path]::GetExtension($sourcePath).ToLowerInvariant()
    if ($referenceExtensions -notcontains $extension -or $sourcePath.StartsWith("scripts/tests/")) {
        continue
    }
    $absoluteSourcePath = Join-Path $projectRoot $sourcePath
    if (-not (Test-Path -LiteralPath $absoluteSourcePath -PathType Leaf)) {
        continue
    }
    $sourceText = Get-Content -Raw -LiteralPath $absoluteSourcePath
    foreach ($match in [regex]::Matches($sourceText, $referencePathPattern)) {
        Add-ReferenceOwner -ReferencesByPath $referencesByPath -ImagePath $match.Groups["path"].Value -Owner $sourcePath
    }
    foreach ($match in [regex]::Matches($sourceText, $literalImageSizePattern)) {
        Add-DisplayEvidence `
            -EvidenceByPath $displayEvidenceByPath `
            -ImagePath $match.Groups["path"].Value `
            -Width ([double]::Parse($match.Groups["width"].Value, $invariantCulture)) `
            -Height ([double]::Parse($match.Groups["height"].Value, $invariantCulture)) `
            -Evidence "$sourcePath direct _image Vector2"
    }
    foreach ($symbolMatch in [regex]::Matches($sourceText, $symbolPathPattern)) {
        $symbol = $symbolMatch.Groups["symbol"].Value
        $symbolImageSizePattern = '(?i)_image\(\s*' + [regex]::Escape($symbol) + '\s*,\s*Vector2\(\s*(?<width>\d+(?:\.\d+)?)\s*,\s*(?<height>\d+(?:\.\d+)?)\s*\)'
        foreach ($sizeMatch in [regex]::Matches($sourceText, $symbolImageSizePattern)) {
            Add-DisplayEvidence `
                -EvidenceByPath $displayEvidenceByPath `
                -ImagePath $symbolMatch.Groups["path"].Value `
                -Width ([double]::Parse($sizeMatch.Groups["width"].Value, $invariantCulture)) `
                -Height ([double]::Parse($sizeMatch.Groups["height"].Value, $invariantCulture)) `
                -Evidence "$sourcePath constant $symbol via _image Vector2"
        }
    }
}

$actionArtText = Get-Content -Raw -LiteralPath $actionArtUiPath
$actionArtSizeMatch = [regex]::Match($actionArtText, '(?m)^const ACTION_ART_SIZE := Vector2\(\s*(?<width>\d+(?:\.\d+)?)\s*,\s*(?<height>\d+(?:\.\d+)?)\s*\)\r?$')
if (-not $actionArtSizeMatch.Success) {
    throw "Could not discover ACTION_ART_SIZE from scripts/ui/action_art_ui.gd."
}
$actionArtWidth = [double]::Parse($actionArtSizeMatch.Groups["width"].Value, $invariantCulture)
$actionArtHeight = [double]::Parse($actionArtSizeMatch.Groups["height"].Value, $invariantCulture)
$activityDatabase = Get-Content -Raw -LiteralPath $activityDatabasePath | ConvertFrom-Json
$activityArtPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
Find-ActivityArtPaths -Value $activityDatabase -Paths $activityArtPaths
foreach ($path in $activityArtPaths) {
    Add-DisplayEvidence `
        -EvidenceByPath $displayEvidenceByPath `
        -ImagePath $path `
        -Width $actionArtWidth `
        -Height $actionArtHeight `
        -Evidence "docs/activity-database.json art via ActionArtUi.ACTION_ART_SIZE"
}

$reviewedTextureDecisions = @{
    "assets/content/ui/berry-mode-borders-1080p.png" = [pscustomobject]@{
        Width = 1080.0
        Height = 1920.0
        Decision = "re-authored-reviewed"
        Reason = "Native 1080 x 1920 full-viewport berry overlay; 2160 x 3840 source is export-excluded."
        Evidence = "material_collection_surface.gd full-viewport berry overlay"
    }
    "assets/content/thieving/heists/thieving-trophy-heist-backgrounds-1080p.png" = [pscustomobject]@{
        Width = 1080.0
        Height = 440.0
        Decision = "re-authored-reviewed-atlas"
        Reason = "Four 1080 x 619 cells are retained in one atlas; each cell is drawn in a 1080-wide, 440-high production heist card."
        Evidence = "thieving/state.gd 1080 x 619 cells; surface.gd 440-high full-width card"
    }
    "assets/content/ui/profile-avatar-game-objects-spritesheet-1080p.png" = [pscustomobject]@{
        Width = 155.0
        Height = 155.0
        Decision = "re-authored-reviewed-atlas"
        Reason = "Five-column 256 px cells are used by avatar controls whose largest literal production placement is 155 x 155; original sheet is export-excluded."
        Evidence = "profile_chat_overlay_surface.gd 256 px cells and 155 px avatar change control"
    }
    "assets/content/ui/profile-avatar-blue-guy-spritesheet-1080p.png" = [pscustomobject]@{
        Width = 155.0
        Height = 155.0
        Decision = "re-authored-reviewed-atlas"
        Reason = "Five-column 256 px cells are used by avatar controls whose largest literal production placement is 155 x 155; original sheet is export-excluded."
        Evidence = "profile_chat_overlay_surface.gd 256 px cells and 155 px avatar change control"
    }
}
$reviewedAuthoredAtlases = @{
    "assets/content/fight/enemies/cave-trolls/cave-trolls-states-source.png" = "Authored combat-state atlas; fixed frame regions preserve the shared animation canvas."
    "assets/content/fight/enemies/dragons/dragons-states-source.png" = "Authored combat-state atlas; fixed frame regions preserve the shared animation canvas."
    "assets/content/fight/enemies/giants/giants-states-source.png" = "Authored four-frame combat-state atlas; runtime regions divide the sheet into equal canonical frames."
    "assets/content/fight/enemies/goblins/goblins-states-source.png" = "Authored combat-state atlas; fixed frame regions preserve the shared animation canvas."
    "assets/content/fight/enemies/guys/guys-states-source.png" = "Authored combat-state atlas; fixed frame regions preserve the shared animation canvas."
    "assets/content/fight/enemies/rouses/rouses-states-source.png" = "Authored combat-state atlas; fixed frame regions preserve the shared animation canvas."
    "assets/content/fight/enemies/vampires/vampires-states-source.png" = "Authored combat-state atlas; fixed frame regions preserve the shared animation canvas."
    "assets/content/fight/enemies/werewolves/werewolves-states-source.png" = "Authored combat-state atlas; fixed frame regions preserve the shared animation canvas."
    "assets/content/hub/hub-barn-tiers.png" = "Five authored 512 px Hub tier cells share one atlas."
    "assets/content/hub/hub-fish-pond-tiers.png" = "Five authored 512 px Hub tier cells share one atlas."
    "assets/content/hub/hub-garden-tiers.png" = "Five authored 512 px Hub tier cells share one atlas."
    "assets/content/hub/hub-mission-sign-tiers.png" = "Five authored 512 px Hub tier cells share one atlas."
    "assets/content/hub/hub-tree-sheet.png" = "Six authored 512 px Hub tree cells share one atlas."
    "assets/content/woodcutting/modules/woodcutting-firepit-flame-sheet.png" = "Four authored 512 px flame cells share one atlas."
    "assets/content/woodcutting/modules/woodcutting-firepit-smoke-sheet.png" = "Eight authored 256 px smoke cells share one atlas."
    "assets/loading/blue-guy-flex-loading-spritesheet.png" = "Four authored 512 px loading-animation cells share one atlas."
}
foreach ($entry in $reviewedAuthoredAtlases.GetEnumerator()) {
    $reviewedTextureDecisions[$entry.Key] = [pscustomobject]@{
        Width = 1080.0
        Height = 1080.0
        Decision = "keep-reviewed-authored-atlas"
        ReasonCode = "REVIEWED_AUTHORED_ATLAS"
        Reason = $entry.Value
        Evidence = "Reviewed fixed-cell production atlas; each authored frame fits the native viewport."
    }
}
foreach ($entry in $reviewedTextureDecisions.GetEnumerator()) {
    Add-DisplayEvidence `
        -EvidenceByPath $displayEvidenceByPath `
        -ImagePath $entry.Key `
        -Width $entry.Value.Width `
        -Height $entry.Value.Height `
        -Evidence $entry.Value.Evidence `
        -Reviewed
}

$rows = [System.Collections.Generic.List[object]]::new()
$trackedImageSourceCount = 0
$excludedImageSourceCount = 0
foreach ($path in $trackedPaths) {
    $extension = [IO.Path]::GetExtension($path).ToLowerInvariant()
    if ($imageExtensions -notcontains $extension) {
        continue
    }
    $trackedImageSourceCount++
    $absolutePath = Join-Path $projectRoot $path
    if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
        continue
    }
    $exclusionPattern = Get-ExclusionPattern -Path $path -Patterns $preset.ExcludeFilters
    $exportStatus = "excluded"
    if ([string]::IsNullOrEmpty($exclusionPattern)) {
        $exportStatus = "included"
    } else {
        $excludedImageSourceCount++
    }
    if ($exportStatus -eq "excluded" -and -not $IncludeExcluded) {
        continue
    }

    $file = Get-Item -LiteralPath $absolutePath
    $dimensions = Get-ImageDimensions -Path $absolutePath
    $import = Get-ImportSettings -ImagePath $path -TrackedPathSet $trackedPathSet
    $evidence = @()
    if ($displayEvidenceByPath.ContainsKey($path)) {
        $evidence = @($displayEvidenceByPath[$path])
    }
    $staticMaxWidth = $null
    $staticMaxHeight = $null
    $displayStatus = "unknown"
    $displayEvidence = "No literal production display maximum was statically discoverable."
    if ($evidence.Count -gt 0) {
        $staticMaxWidth = ($evidence | Measure-Object -Property Width -Maximum).Maximum
        $staticMaxHeight = ($evidence | Measure-Object -Property Height -Maximum).Maximum
        $displayStatus = "partial-static"
        if (@($evidence | Where-Object Reviewed).Count -gt 0) {
            $displayStatus = "reviewed-static"
        }
        $displayEvidence = (@($evidence | ForEach-Object { $_.Evidence }) | Sort-Object -Unique) -join "; "
    }

    $owners = ""
    if ($referencesByPath.ContainsKey($path)) {
        $owners = (@($referencesByPath[$path]) | Sort-Object) -join ";"
    }

    $decision = "review-pending"
    $decisionReasonCode = "STATIC_MAX_UNRESOLVED"
    $decisionReason = "No complete static maximum-display proof exists; retain the current import while runtime or reviewed layout evidence is collected."
    if ($exportStatus -eq "excluded") {
        $decision = "exclude-from-export"
        $decisionReasonCode = "ANDROID_EXPORT_FILTER"
        $decisionReason = "Matched Android export exclusion '$exclusionPattern'."
    } elseif ($reviewedTextureDecisions.ContainsKey($path)) {
        $decision = $reviewedTextureDecisions[$path].Decision
        $decisionReasonCode = if ($reviewedTextureDecisions[$path].PSObject.Properties.Name -contains "ReasonCode") {
            $reviewedTextureDecisions[$path].ReasonCode
        } else {
            "REVIEWED_1080_DERIVATIVE"
        }
        $decisionReason = $reviewedTextureDecisions[$path].Reason
    } elseif (-not $import.SettingsKnown) {
        $decision = "blocked-import-metadata"
        $decisionReasonCode = "IMPORT_METADATA_UNAVAILABLE"
        $decisionReason = "No readable Godot import sidecar exists, so the exported texture format and effective size cannot be verified."
    } elseif ($null -ne $import.SizeLimit -and $import.SizeLimit -gt 0 -and $null -ne $dimensions.Width -and $null -ne $dimensions.Height -and [Math]::Max($dimensions.Width, $dimensions.Height) -gt $import.SizeLimit) {
        $decision = "downsample-at-import"
        $decisionReasonCode = "GODOT_SIZE_LIMIT"
        $decisionReason = "Godot process/size_limit=$($import.SizeLimit) reduces the larger source dimension during import."
    } elseif ($null -ne $dimensions.Width -and $null -ne $dimensions.Height -and $dimensions.Width -le 1080 -and $dimensions.Height -le 1920) {
        $decision = "keep-current-native-viewport-bounded"
        $decisionReasonCode = "SOURCE_WITHIN_NATIVE_VIEWPORT"
        $decisionReason = "The complete source fits within the 1080 x 1920 native viewport, so it cannot require a larger runtime draw surface."
    } elseif ($displayStatus -eq "partial-static" -and $null -ne $dimensions.Width -and $null -ne $dimensions.Height -and [Math]::Max($dimensions.Width, $dimensions.Height) -gt (2.0 * [Math]::Max($staticMaxWidth, $staticMaxHeight))) {
        $decision = "review-pending-known-placement-smaller"
        $decisionReasonCode = "PARTIAL_PLACEMENT_MUCH_SMALLER"
        $decisionReason = "The largest discovered placement is materially smaller than the source, but discovery is partial and does not prove that no larger dynamic placement exists."
    } elseif ($null -ne $dimensions.Width -and $dimensions.Width -gt 1080) {
        $decision = "review-pending-over-1080-wide"
        $decisionReasonCode = "SOURCE_OVER_VIEWPORT_WIDTH"
        $decisionReason = "The source is wider than the native viewport and has no recorded size limit or reviewed atlas decision."
    } elseif ($displayStatus -eq "partial-static") {
        $decision = "keep-current-partial-static-fit"
        $decisionReasonCode = "PARTIAL_PLACEMENT_WITHIN_2X"
        $decisionReason = "The source is within twice the largest statically discovered placement; dynamic placements remain outside the static proof."
    }

    $compressionTarget = "unknown"
    $androidFormat = "UNKNOWN"
    if ($import.SettingsKnown) {
        if ($import.Mode -eq 2) {
            $compressionTarget = "${androidVramTarget}:$($import.ImportedFormats)"
            $androidFormat = "VRAM_FORMAT_UNVERIFIED"
            if ($androidVramTarget -eq "etc2_astc" -and $import.ImportedFormats.Split(";") -contains "etc2_astc") {
                $androidFormat = "ETC2_ASTC"
            } elseif ($androidVramTarget -eq "not-enabled") {
                $androidFormat = "VRAM_TARGET_DISABLED"
            }
        } else {
            $compressionTarget = $import.ModeName
            $androidFormat = $import.ModeName.ToUpperInvariant().Replace(" ", "_")
        }
    }
    $mipmapReview = "unknown"
    if ($import.Mipmaps -eq "false") {
        $mipmapReview = "disabled"
    } elseif ($import.Mipmaps -eq "true" -and ($path -match '(?i)^assets/content/(ui|icons)/' -or $path -match '(?i)^assets/loading/')) {
        $mipmapReview = "enabled-ui-review"
    } elseif ($import.Mipmaps -eq "true") {
        $mipmapReview = "enabled"
    }

    $artifactStatus = "not-checked"
    $artifactImportFormat = "not-checked"
    $artifactPayloadStatus = "not-checked"
    if ($null -ne $artifactInventory) {
        $artifactContainsPath = $artifactInventory.ImagePaths.Contains($path)
        if ($exportStatus -eq "included") {
            $artifactStatus = "missing-from-artifact"
            if ($artifactContainsPath) {
                $artifactStatus = "included"
            }
        } else {
            $artifactStatus = "absent-as-expected"
            if ($artifactContainsPath) {
                $artifactStatus = "unexpectedly-present"
            }
        }
        if ($artifactInventory.RemapsByResourcePath.ContainsKey($path)) {
            $artifactRemap = $artifactInventory.RemapsByResourcePath[$path]
            $artifactImportFormat = $artifactRemap.Format
            $artifactPayloadStatus = "missing"
            if ($artifactInventory.ResourceEntries.Contains($artifactRemap.Payload)) {
                $artifactPayloadStatus = "present"
            }
        } elseif ($artifactContainsPath) {
            $artifactImportFormat = "unresolved"
            $artifactPayloadStatus = "unresolved"
        }
    }

    $rows.Add([pscustomobject][ordered]@{
        Path = $path
        ExportStatus = $exportStatus
        ArtifactStatus = $artifactStatus
        ArtifactImportFormat = $artifactImportFormat
        ArtifactPayloadStatus = $artifactPayloadStatus
        ExclusionPattern = $exclusionPattern
        SourceWidth = "$(if ($null -ne $dimensions.Width) { $dimensions.Width })"
        SourceHeight = "$(if ($null -ne $dimensions.Height) { $dimensions.Height })"
        DimensionStatus = $dimensions.Status
        SourceBytes = [string]$file.Length
        ImportMetadata = $import.Status
        Importer = $import.Importer
        ResourceType = $import.ResourceType
        ImportMode = "$(if ($null -ne $import.Mode) { $import.Mode })"
        ImportModeName = $import.ModeName
        ImportedFormats = $import.ImportedFormats
        VramTexture = $import.VramTexture
        CompressionTarget = $compressionTarget
        AndroidFormat = $androidFormat
        HighQuality = $import.HighQuality
        Mipmaps = $import.Mipmaps
        MipmapReview = $mipmapReview
        SizeLimit = "$(if ($null -ne $import.SizeLimit) { $import.SizeLimit })"
        StaticMaxDisplayWidth = Format-Number $staticMaxWidth
        StaticMaxDisplayHeight = Format-Number $staticMaxHeight
        DisplayDiscovery = $displayStatus
        DisplayEvidence = $displayEvidence
        DownsampleDecision = $decision
        DecisionReasonCode = $decisionReasonCode
        DecisionReason = $decisionReason
        ReferenceOwners = $owners
    })
}

$sortedRows = @($rows | Sort-Object -Property Path)
$snapshotRows = @($sortedRows | Select-Object `
    Path,
    ExportStatus,
    ArtifactStatus,
    ArtifactImportFormat,
    ArtifactPayloadStatus,
    ExclusionPattern,
    SourceWidth,
    SourceHeight,
    DimensionStatus,
    SourceBytes,
    ImportMetadata,
    ImportModeName,
    ImportedFormats,
    VramTexture,
    CompressionTarget,
    AndroidFormat,
    Mipmaps,
    MipmapReview,
    SizeLimit,
    StaticMaxDisplayWidth,
    StaticMaxDisplayHeight,
    DisplayDiscovery,
    DisplayEvidence,
    DownsampleDecision,
    DecisionReasonCode
)
$csvText = Convert-RowsToCsvText -Rows $snapshotRows

if ($CheckSnapshot) {
    $absoluteSnapshotPath = Join-Path $projectRoot $SnapshotPath
    if (-not (Test-Path -LiteralPath $absoluteSnapshotPath -PathType Leaf)) {
        throw "Exported-image inventory snapshot is missing: $SnapshotPath"
    }
    $actualRows = @(Import-Csv -LiteralPath $absoluteSnapshotPath)
    $expectedRows = @($snapshotRows)
    if ($null -eq $artifactInventory) {
        # Artifact fields describe one captured AAB and cannot be regenerated in
        # a clean checkout until that AAB has been built. Keep those columns as
        # evidence in the snapshot, but validate the deterministic source,
        # preset, import, and display-decision columns when no artifact is given.
        $nonArtifactProperties = @(
            $snapshotRows[0].PSObject.Properties.Name |
                Where-Object { $_ -notin @("ArtifactStatus", "ArtifactImportFormat", "ArtifactPayloadStatus") }
        )
        $actualRows = @($actualRows | Select-Object $nonArtifactProperties)
        $expectedRows = @($expectedRows | Select-Object $nonArtifactProperties)
    }
    $actual = (Convert-RowsToCsvText -Rows $actualRows) -replace "`r`n", "`n"
    $expected = (Convert-RowsToCsvText -Rows $expectedRows) -replace "`r`n", "`n"
    if ($actual -ne $expected) {
        throw "Exported-image inventory snapshot is stale. Run this script with -Format Csv and update $SnapshotPath."
    }
    Write-Output "exported-image-inventory-ok rows=$($sortedRows.Count) preset=$PresetName"
    exit 0
}

switch ($Format) {
    "Csv" {
        Write-Output $csvText.TrimEnd("`r", "`n")
    }
    "Json" {
        Write-Output ($sortedRows | ConvertTo-Json -Depth 4)
    }
    default {
        $included = @($sortedRows | Where-Object ExportStatus -eq "included")
        $excluded = @($sortedRows | Where-Object ExportStatus -eq "excluded")
        $unknownDimensions = @($included | Where-Object DimensionStatus -ne "measured")
        $unknownImports = @($included | Where-Object ImportMetadata -in @("missing", "tracked-file-missing"))
        $untrackedImports = @($included | Where-Object ImportMetadata -eq "untracked-observed")
        $vramCompressed = @($included | Where-Object ImportMode -eq "2")
        $mipmapsDisabled = @($included | Where-Object Mipmaps -eq "false")
        $displayUnknown = @($included | Where-Object DisplayDiscovery -eq "unknown")
        $reviewPending = @($included | Where-Object DownsampleDecision -like "review-pending*")
        Write-Output "preset=$PresetName export_filter=$($preset.ExportFilter)"
        Write-Output "scope=Git-tracked image sources evaluated against the preset filters"
        if ($null -ne $artifactInventory) {
            $artifactIncluded = @($included | Where-Object ArtifactStatus -eq "included")
            $artifactMissing = @($included | Where-Object ArtifactStatus -eq "missing-from-artifact")
            $artifactPayloadMissing = @($included | Where-Object ArtifactPayloadStatus -ne "present")
            $artifactAstc = @($included | Where-Object ArtifactImportFormat -eq "astc")
            $artifactDefault = @($included | Where-Object ArtifactImportFormat -eq "default")
            Write-Output "artifact=$($artifactInventory.Path) bytes=$($artifactInventory.Bytes) sha256=$($artifactInventory.Sha256)"
            Write-Output "artifact_image_import_entries=$($artifactInventory.ImagePaths.Count) matched_included=$($artifactIncluded.Count) missing_included=$($artifactMissing.Count)"
            Write-Output "artifact_texture_payloads astc=$($artifactAstc.Count) default=$($artifactDefault.Count) missing_or_unresolved=$($artifactPayloadMissing.Count)"
        } else {
            Write-Output "artifact=not-checked (pass -ArtifactPath for AAB-level inclusion evidence)"
        }
        Write-Output "tracked_image_sources=$trackedImageSourceCount included=$($included.Count) excluded=$excludedImageSourceCount"
        Write-Output "dimensions_unknown=$($unknownDimensions.Count) imports_unknown=$($unknownImports.Count) imports_untracked_observed=$($untrackedImports.Count)"
        Write-Output "vram_compressed=$($vramCompressed.Count) mipmaps_disabled=$($mipmapsDisabled.Count)"
        Write-Output "display_max_unknown=$($displayUnknown.Count) downsample_review_pending=$($reviewPending.Count)"
        Write-Output ""
        Write-Output "Largest included source images:"
        $included |
            Sort-Object @{ Expression = { [int64]($_.SourceWidth) * [int64]($_.SourceHeight) }; Descending = $true }, Path |
            Select-Object -First 20 Path,SourceWidth,SourceHeight,ImportModeName,SizeLimit,StaticMaxDisplayWidth,StaticMaxDisplayHeight,DownsampleDecision |
            Format-Table -AutoSize
        if ($unknownImports.Count -gt 0) {
            Write-Output ""
            Write-Output "Included images with unknown tracked import settings:"
            $unknownImports | Select-Object Path,ImportMetadata | Format-Table -AutoSize
        }
        if ($untrackedImports.Count -gt 0) {
            Write-Output ""
            Write-Output "Included images whose current import settings are observable but not Git-tracked:"
            $untrackedImports | Select-Object Path,ImportModeName,AndroidFormat,Mipmaps | Format-Table -AutoSize
        }
    }
}
