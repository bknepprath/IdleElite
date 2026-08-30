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
$fishingSurfacePath = Join-Path $projectRoot "scripts\fishing\ui_surface.gd"
$hubSurfacePath = Join-Path $projectRoot "scripts\ui\hub_surface.gd"
$skillDetailSurfacePath = Join-Path $projectRoot "scripts\ui\skill_detail_surface.gd"
$skillSwipeSurfacePath = Join-Path $projectRoot "scripts\ui\skill_swipe_activity_surface.gd"
$activityCardStylesPath = Join-Path $projectRoot "scripts\ui\activity_card_styles.gd"
$regenCirclePath = Join-Path $projectRoot "scripts\ui\regen_circle.gd"
$skillStatePath = Join-Path $projectRoot "scripts\progression\skill_state.gd"
$achievementSurfacePath = Join-Path $projectRoot "scripts\ui\achievement_overlay_surface.gd"

Assert-True (Test-Path -LiteralPath $projectPath) "Missing project.godot."
Assert-True (Test-Path -LiteralPath $mainPath) "Missing scripts\main.gd."
Assert-True (Test-Path -LiteralPath $leaderboardPresentationPath) "Missing leaderboard presentation script."
Assert-True (Test-Path -LiteralPath $profileChatSurfacePath) "Missing profile/chat surface script."
Assert-True (Test-Path -LiteralPath $fishingSurfacePath) "Missing Fishing surface script."
Assert-True (Test-Path -LiteralPath $hubSurfacePath) "Missing Hub surface script."
Assert-True (Test-Path -LiteralPath $skillDetailSurfacePath) "Missing skill detail surface script."
Assert-True (Test-Path -LiteralPath $skillSwipeSurfacePath) "Missing skill swipe activity surface script."
Assert-True (Test-Path -LiteralPath $activityCardStylesPath) "Missing activity card styles script."
Assert-True (Test-Path -LiteralPath $regenCirclePath) "Missing stamina gauge renderer."
Assert-True (Test-Path -LiteralPath $skillStatePath) "Missing skill state script."
Assert-True (Test-Path -LiteralPath $achievementSurfacePath) "Missing achievement/offline summary surface script."

$project = Get-Content -LiteralPath $projectPath -Raw
$main = Get-Content -LiteralPath $mainPath -Raw
$leaderboardPresentation = Get-Content -LiteralPath $leaderboardPresentationPath -Raw
$profileChatSurface = Get-Content -LiteralPath $profileChatSurfacePath -Raw
$fishingSurface = Get-Content -LiteralPath $fishingSurfacePath -Raw
$hubSurface = Get-Content -LiteralPath $hubSurfacePath -Raw
$skillDetailSurface = Get-Content -LiteralPath $skillDetailSurfacePath -Raw
$skillSwipeSurface = Get-Content -LiteralPath $skillSwipeSurfacePath -Raw
$activityCardStyles = Get-Content -LiteralPath $activityCardStylesPath -Raw
$regenCircle = Get-Content -LiteralPath $regenCirclePath -Raw
$skillState = Get-Content -LiteralPath $skillStatePath -Raw
$achievementSurface = Get-Content -LiteralPath $achievementSurfacePath -Raw

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
Assert-True ($renderer -eq "gl_compatibility") "Samsung-safe 1080p builds require the Compatibility renderer to prevent Vulkan framebuffer corruption."

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

function Test-IsInfoIconFontOverride {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory = $true)][int]$LineIndex
    )

    $overrideMatch = [regex]::Match(
        $Lines[$LineIndex],
        '^\s*(?<receiver>[A-Za-z_][A-Za-z0-9_]*)\.add_theme_font_size_override\(\s*"font_size"\s*,\s*29\s*\)\s*$'
    )
    if (-not $overrideMatch.Success) {
        return $false
    }

    $receiver = $overrideMatch.Groups["receiver"].Value
    $escapedReceiver = [regex]::Escape($receiver)
    $constructsButton = $false
    $setsInfoGlyph = $false
    for ($index = $LineIndex - 1; $index -ge 0; $index--) {
        $candidate = $Lines[$index]
        if ($candidate -match '^\s*func\s+') {
            break
        }
        if ($candidate -match "^\s*var\s+$escapedReceiver(?:\s*:\s*Button)?\s*(?::=|=)\s*Button\.new\(\)\s*$") {
            $constructsButton = $true
        }
        if ($candidate -match "^\s*$escapedReceiver\.text\s*=\s*`"i`"\s*$") {
            $setsInfoGlyph = $true
        }
    }

    return $constructsButton -and $setsInfoGlyph
}

$infoIconFixture = @(
    'func _fixture() -> void:',
    '    var button := Button.new()',
    '    button.text = "i"',
    '    button.add_theme_font_size_override("font_size", 29)'
)
$bodyTextFixture = @(
    'func _fixture() -> void:',
    '    var button := Button.new()',
    '    button.text = "Info"',
    '    button.add_theme_font_size_override("font_size", 29)'
)
Assert-True (Test-IsInfoIconFontOverride -Lines $infoIconFixture -LineIndex 3) "The mobile font contract must recognize the reviewed info-icon glyph override."
Assert-True (-not (Test-IsInfoIconFontOverride -Lines $bodyTextFixture -LineIndex 3)) "The mobile font contract must not exempt sub-48 button text."

$explicitSmallFontHits = @()
foreach ($script in $productionScripts) {
    $scriptLines = @(Get-Content -LiteralPath $script.FullName)
    for ($lineIndex = 0; $lineIndex -lt $scriptLines.Count; $lineIndex++) {
        $line = $scriptLines[$lineIndex]
        $fontMatch = [regex]::Match($line, $explicitFontPattern)
        if (
            $fontMatch.Success -and
            [int]$fontMatch.Groups[1].Value -lt 48 -and
            -not (Test-IsInfoIconFontOverride -Lines $scriptLines -LineIndex $lineIndex)
        ) {
            $lineNumber = $lineIndex + 1
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
    Assert-True ($profileChatSurface -match '(?m)^const CHAT_STRIP_HEIGHT := 112\r?$') "Chat strip must retain its compact audited height."
    Assert-True ($profileChatSurface -match '(?m)^const CHAT_STRIP_TEXT_FONT_SIZE := 32\r?$') "Chat strip text must use the compact native-1080 size."
    Assert-True ($profileChatSurface -match 'chat_strip_line_one = host\._label\("", CHAT_STRIP_TEXT_FONT_SIZE, Color\.WHITE, HORIZONTAL_ALIGNMENT_LEFT\)') "Chat strip text must use the compact font constant."
	Assert-True ($profileChatSurface -match '(?m)^const CHAT_STRIP_FONT_WIDTH_AXIS := 75\r?$') "Chat strip text must use the font's real width axis instead of an affine stretch."
	Assert-True ($profileChatSurface -match '(?m)^const CHAT_STRIP_FONT_EMBOLDEN := 0\.45\r?$') "Chat strip text must retain its compact bold weight."
	Assert-True ($profileChatSurface -match '(?m)^const CHAT_STRIP_ICON_SIZE := 70\.0\r?$') "Chat strip icon must remain readable beside compact message text."
	Assert-True ($profileChatSurface -match '(?m)^const CHAT_UNREAD_DOT_EDGE_INSET := -3\.0\r?$') "Chat unread dot must sit on the icon's upper-right corner."
	Assert-True ($profileChatSurface -notmatch 'variation_transform') "Chat strip text must not use a distorting affine font transform."
    Assert-True ($profileChatSurface -match 'style\.set_border_width_all\(5\)') "Chat/profile controls must not retain 4K border thickness."
    Assert-True ($profileChatSurface -match 'style\.corner_radius_bottom_right = 5 if is_self and not deleted else 9') "Chat message corners must retain half-scale 4K geometry."
	Assert-True ($fishingSurface -match '(?m)^const FISHING_METHOD_TITLE_OUTLINE := 10\r?$') "Fishing area names must retain their heavy outline."
	Assert-True ($fishingSurface -match '(?m)^const FISHING_METHOD_TITLE_WIDTH_AXIS := 75\r?$') "Fishing area names must use the font's real width axis."
	Assert-True ($fishingSurface -match '(?m)^const FISHING_METHOD_TITLE_EMBOLDEN := 1\.2\r?$') "Fishing area names must retain their audited bold weight."
	Assert-True ($fishingSurface -notmatch 'variation_transform') "Fishing area names must not use a distorting affine font transform."
	Assert-True ($fishingSurface -match '(?m)^const FISHING_METHOD_TITLE_WIDTH := 260\.0\r?$') "Fishing area names must retain their audited single-line width."
    Assert-True ($skillDetailSurface -match '"original": _format_xp_reward_parts\(base_parts\)') "XP stat details must use compact skill codes at native 1080 width."
    Assert-True ($skillDetailSurface -match 'bonus_column\.custom_minimum_size = Vector2\(200, 0\)') "Activity stat Boosts text must retain enough width to avoid single-character wrapping."
	Assert-True ($skillDetailSurface -match '(?m)^const ACTIVITY_STAT_VALUE_FONT_WIDTH_AXIS := 75\r?$') "Activity stat values must use the font's real width axis instead of an affine stretch."
	Assert-True ($skillDetailSurface -notmatch 'ACTIVITY_STAT_VALUE_FONT_WIDTH_SCALE') "Activity stat values must not restore the distorting affine width scale."
	Assert-True ($activityCardStyles -match 'title\.add_theme_font_size_override\("font_size", 60\)') "Activity titles must retain the phone-readable title size."
	Assert-True ($activityCardStyles -match '(?m)^const ACTIVITY_CARD_TITLE_WIDTH_AXIS := 75\r?$') "Activity titles must use the font's native condensed width axis."
	Assert-True ($activityCardStyles -match '(?m)^const ACTIVITY_CARD_TITLE_WEIGHT_AXIS := 700\r?$') "Activity titles must retain a bold native weight."
	Assert-True ($activityCardStyles -notmatch 'variation_transform') "Activity titles must not use a distorting affine font transform."
	Assert-True ($activityCardStyles -match 'title\.autowrap_mode = TextServer::AUTOWRAP_OFF'.Replace('::', '.')) "Activity titles must never wrap."
	Assert-True ($activityCardStyles -match 'title\.max_lines_visible = 1') "Activity titles must have a hard one-line limit."
	Assert-True ($activityCardStyles -match 'title\.text_overrun_behavior = TextServer::OVERRUN_NO_TRIMMING'.Replace('::', '.')) "Activity titles must never be ellipsized."
	Assert-True ($skillDetailSurface -match 'title_band\.offset_left = 8' -and $skillDetailSurface -match 'title_band\.offset_right = -8') "Detail activity titles must retain the audited full-width lane."
	Assert-True ($skillSwipeSurface -match 'title_band\.offset_left = 8' -and $skillSwipeSurface -match 'title_band\.offset_right = -8') "Swipe activity titles must retain the audited full-width lane."
	Assert-True ($regenCircle -match '(?m)^const CENTER_DENOMINATOR_Y_OFFSET := 150\.0\r?$') "Stamina denominator must retain clearance below its divider."
	Assert-True ($skillDetailSurface -match 'restore_scroll = detail_actions_scroll\.scroll_vertical') "Tier banners must preserve the actual activity-list scroll position."
	Assert-True ($skillDetailSurface -match 'call_deferred\("_refresh_visible_skill_detail_action_list", restore_scroll, skill_id, true, true\)') "Tier banner refreshes must allow Thieving scroll restoration."
	Assert-True ($skillDetailSurface -match 'host\._label\("Tier %s mastery: %s / %s medals"[^\r\n]+, 31, COLOR_INK') "Tier mastery summary text must retain half-scale 4K typography."
	Assert-True ($skillDetailSurface -match 'host\._label\("REWARD", 24, Color\.WHITE') "Tier reward headings must retain half-scale 4K typography."
	Assert-True ($skillDetailSurface -match 'host\._label\(main_text, 36, Color\.WHITE') "Tier reward values must retain half-scale 4K typography."
	Assert-True ($skillDetailSurface -match 'host\._label\(detail_text, 24, Color\.WHITE') "Tier reward details must retain half-scale 4K typography."
	Assert-True ($achievementSurface -match '(?m)^const OFFLINE_SUMMARY_MODAL_WIDTH := 840\.0\r?$') "Welcome Back modal width must retain half-scale 4K geometry."
	Assert-True ($achievementSurface -match '(?m)^const OFFLINE_SUMMARY_MODAL_MAX_HEIGHT := 1090\.0\r?$') "Welcome Back modal must fit the native-1080 viewport without full-panel scaling."
	Assert-True ($achievementSurface -match 'host\._label\("Away for %s"[^\r\n]+, 32, host\.COLOR_MUTED') "Welcome Back subtitle must retain half-scale 4K typography."
	Assert-True ($achievementSurface -match 'host\._label\(title, 31, host\.COLOR_INK') "Welcome Back progress-row titles must retain half-scale 4K typography."
	Assert-True ($achievementSurface -match 'func _finish_scroll_offline_summary_to_top\(\)') "Welcome Back modal must restore its initial scroll position after layout."
	Assert-True ($achievementSurface -match 'offline_summary_scroll\.scroll_vertical = 0') "Welcome Back modal must open at its header instead of its focused action button."
	Assert-True ($skillDetailSurface -match 'detail_xp_label\.autowrap_mode = TextServer::AUTOWRAP_OFF'.Replace('::', '.')) "Skill level and XP text must remain on one line."
	Assert-True ($main -match '(?m)^const SKILL_DETAIL_XP_BAR_WIDTH := 450\r?$') "Skill level and XP text must retain its audited one-line width."
	Assert-True ($skillState -match 'return "Lv %s · %s/%s"') "Skill level and XP text must use the compact one-line format."
    Assert-True ($hubSurface -match '"x": round\(decor_position\.x \* 2\.0\) \* 0\.5') "Hub decor must preserve deterministic half-pixel quantization from the 4K composition."
    Assert-True ($legacyCoordinateHits.Count -eq 0) "Exact 2160/3840 production literals remain after cutover: $($legacyCoordinateHits -join '; ')"
    Assert-True ($explicitSmallFontHits.Count -eq 0) "Explicit production font sizes below 48 px remain after cutover: $($explicitSmallFontHits -join '; ')"
}

$stateName = if ($cutoverState) { "cutover" } else { "legacy" }
Write-Output "performance-1080p-migration-contracts-ok state=$stateName viewport=${viewportWidth}x${viewportHeight} legacy_coordinate_hits=$($legacyCoordinateHits.Count) explicit_small_font_hits=$($explicitSmallFontHits.Count)"
