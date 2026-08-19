param(
    [switch]$RequireCutover
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$projectPath = Join-Path $projectRoot "project.godot"
$mainPath = Join-Path $projectRoot "scripts\main.gd"
$leaderboardPresentationPath = Join-Path $projectRoot "scripts\leaderboard\presentation.gd"
$profileChatSurfacePath = Join-Path $projectRoot "scripts\ui\profile_chat_overlay_surface.gd"
$hubSurfacePath = Join-Path $projectRoot "scripts\ui\hub_surface.gd"

Assert-True (Test-Path -LiteralPath $projectPath) "Missing project.godot."
Assert-True (Test-Path -LiteralPath $mainPath) "Missing scripts\main.gd."
Assert-True (Test-Path -LiteralPath $leaderboardPresentationPath) "Missing leaderboard presentation script."
Assert-True (Test-Path -LiteralPath $profileChatSurfacePath) "Missing profile/chat surface script."
Assert-True (Test-Path -LiteralPath $hubSurfacePath) "Missing Hub surface script."

$project = Get-Content -LiteralPath $projectPath -Raw
$main = Get-Content -LiteralPath $mainPath -Raw
$leaderboardPresentation = Get-Content -LiteralPath $leaderboardPresentationPath -Raw
$profileChatSurface = Get-Content -LiteralPath $profileChatSurfacePath -Raw
$hubSurface = Get-Content -LiteralPath $hubSurfacePath -Raw

function Get-ProjectSettingValue {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $match = [regex]::Match($Source, "(?m)^$([regex]::Escape($Key))=(.+?)\r?$")
    Assert-True $match.Success "Missing project setting $Key."
    return $match.Groups[1].Value.Trim()
}

function Get-ProjectSettingInt {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $raw = Get-ProjectSettingValue -Source $Source -Key $Key
    $value = 0
    Assert-True ([int]::TryParse($raw, [ref]$value)) "Project setting $Key must be an integer."
    return $value
}

$viewportWidth = Get-ProjectSettingInt -Source $project -Key "window/size/viewport_width"
$viewportHeight = Get-ProjectSettingInt -Source $project -Key "window/size/viewport_height"
$stretchMode = (Get-ProjectSettingValue -Source $project -Key "window/stretch/mode").Trim('"')
$stretchAspect = (Get-ProjectSettingValue -Source $project -Key "window/stretch/aspect").Trim('"')
$renderer = (Get-ProjectSettingValue -Source $project -Key "renderer/rendering_method").Trim('"')

Assert-True ($stretchMode -eq "viewport") "Android-safe stretch mode must remain viewport."
Assert-True ($stretchAspect -eq "expand") "Migration baseline requires viewport stretch aspect expand."
Assert-True ($renderer -eq "mobile") "Migration baseline requires the Mobile renderer."

$baseCanvasMatch = [regex]::Match($main, '(?m)^const BASE_CANVAS := Vector2\(\s*(\d+)\s*,\s*(\d+)\s*\)\r?$')
Assert-True $baseCanvasMatch.Success "Could not read BASE_CANVAS from scripts\main.gd."
$baseCanvasWidth = [int]$baseCanvasMatch.Groups[1].Value
$baseCanvasHeight = [int]$baseCanvasMatch.Groups[2].Value

$productionPaths = @(
    (Join-Path $projectRoot "scripts\main.gd"),
    (Join-Path $projectRoot "scripts\app"),
    (Join-Path $projectRoot "scripts\fishing"),
    (Join-Path $projectRoot "scripts\gameplay"),
    (Join-Path $projectRoot "scripts\leaderboard"),
    (Join-Path $projectRoot "scripts\module_ui"),
    (Join-Path $projectRoot "scripts\thieving"),
    (Join-Path $projectRoot "scripts\ui")
)

$productionScripts = @()
foreach ($path in $productionPaths) {
    if (Test-Path -LiteralPath $path -PathType Leaf) {
        $productionScripts += Get-Item -LiteralPath $path
    } elseif (Test-Path -LiteralPath $path -PathType Container) {
        $productionScripts += Get-ChildItem -LiteralPath $path -Recurse -File -Filter "*.gd"
    }
}

$forbiddenScalePattern = 'CONTENT_SCALE_MODE_CANVAS_ITEMS|content_scale_mode\s*=|content_scale_size\s*=|content_scale_factor\s*='
$forbiddenScaleHits = @(
    $productionScripts |
        Select-String -Pattern $forbiddenScalePattern |
        ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line.Trim())" }
)
Assert-True ($forbiddenScaleHits.Count -eq 0) "Production scripts must not use runtime canvas scaling overrides: $($forbiddenScaleHits -join '; ')"

$legacyCoordinatePattern = '(?<!\d)(2160(?:\.0)?|3840(?:\.0)?)(?!\d)'
$legacyCoordinateHits = @(
    $productionScripts |
        Select-String -Pattern $legacyCoordinatePattern |
        ForEach-Object { "$($_.Path):$($_.LineNumber):$($_.Line.Trim())" }
)

$explicitFontPattern = 'add_theme_font_size_override\(\s*"font_size"\s*,\s*(\d+)\s*\)'
$explicitSmallFontHits = @()
foreach ($script in $productionScripts) {
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $script.FullName) {
        $lineNumber++
        $fontMatch = [regex]::Match($line, $explicitFontPattern)
        if ($fontMatch.Success -and [int]$fontMatch.Groups[1].Value -lt 48) {
            $explicitSmallFontHits += "$($script.FullName):${lineNumber}:$($line.Trim())"
        }
    }
}

$legacyState = $viewportWidth -eq 2160 -and $viewportHeight -eq 3840 -and $baseCanvasWidth -eq 2160 -and $baseCanvasHeight -eq 3840
$cutoverState = $viewportWidth -eq 1080 -and $viewportHeight -eq 1920 -and $baseCanvasWidth -eq 1080 -and $baseCanvasHeight -eq 1920
Assert-True ($legacyState -or $cutoverState) "Viewport and BASE_CANVAS must be a complete 2160 x 3840 baseline or 1080 x 1920 cutover."

$strictCutover = $RequireCutover -or $cutoverState
if ($strictCutover) {
    Assert-True $cutoverState "1080p cutover requires project viewport and BASE_CANVAS to be 1080 x 1920."
    Assert-True ($leaderboardPresentation -match '(?m)^const BASE_FRAME_WIDTH := 1080\r?$') "Leaderboard frame width must be 1080 after cutover."
    Assert-True ($main -match '(?m)^const ACTION_CARD_POP_GUTTER := 22\r?$') "Action-card pop gutter must retain exact half-scale 4K spacing."
    Assert-True ($leaderboardPresentation -match '(?m)^const BOTTOM_SCROLL_PAD := 360\r?$') "Leaderboard bottom spacing must retain the half-scale 4K composition."
    Assert-True ($leaderboardPresentation -match 'var top_mid := Vector2\(size\.x \* 0\.50, 123\.0\)') "Leaderboard paper contour must use native-1080 coordinates."
    Assert-True ($profileChatSurface -match '(?m)^const CHAT_STRIP_HEIGHT := 130\r?$') "Chat strip height must retain exact half-scale 4K geometry."
    Assert-True ($profileChatSurface -match 'style\.set_border_width_all\(5\)') "Chat/profile controls must not retain 4K border thickness."
    Assert-True ($profileChatSurface -match 'style\.corner_radius_bottom_right = 5 if is_self and not deleted else 9') "Chat message corners must retain half-scale 4K geometry."
    Assert-True ($hubSurface -match '"x": round\(decor_position\.x \* 2\.0\) \* 0\.5') "Hub decor must preserve deterministic half-pixel quantization from the 4K composition."
    Assert-True ($legacyCoordinateHits.Count -eq 0) "Exact 2160/3840 production literals remain after cutover: $($legacyCoordinateHits -join '; ')"
    Assert-True ($explicitSmallFontHits.Count -eq 0) "Explicit production font sizes below 48 px remain after cutover: $($explicitSmallFontHits -join '; ')"
}

$stateName = if ($cutoverState) { "cutover" } else { "legacy" }
Write-Output "performance-1080p-migration-contracts-ok state=$stateName viewport=${viewportWidth}x${viewportHeight} legacy_coordinate_hits=$($legacyCoordinateHits.Count) explicit_small_font_hits=$($explicitSmallFontHits.Count)"
