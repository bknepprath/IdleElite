$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testScript = "res://scripts/tests/tier_banner_scroll.gd"
$skillDetailScript = Join-Path $projectRoot "scripts\ui\skill_detail_surface.gd"
$projectSettingsPath = Join-Path $projectRoot "project.godot"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
Assert-True (Test-Path -LiteralPath $skillDetailScript) "Missing scripts\ui\skill_detail_surface.gd."

$skillDetailSource = Get-Content -Raw -LiteralPath $skillDetailScript
$hitButtonMatch = [regex]::Match(
    $skillDetailSource,
    '(?ms)^func _tier_banner_hit_button\(.*?(?=^func |\z)'
)
$hitPressedMatch = [regex]::Match(
    $skillDetailSource,
    '(?ms)^func _on_tier_banner_hit_pressed\(.*?(?=^func |\z)'
)
Assert-True $hitButtonMatch.Success "Missing tier banner hit-button builder."
Assert-True $hitPressedMatch.Success "Missing tier banner scroll-safe press handler."
Assert-True ($hitButtonMatch.Value -match 'pressed\.connect\(_on_tier_banner_hit_pressed\.bind\(callback, button\)\)') "Tier banner buttons must route through the scroll-safe press handler."
Assert-True ($hitButtonMatch.Value -notmatch 'pressed\.connect\(callback\)') "Tier banner buttons must not connect their close callback directly."
Assert-True ($hitPressedMatch.Value -match '_detail_actions_scroll_suppresses_child_click\(\)') "Tier banner press handling must reject page scroll gestures."
Assert-True ($hitPressedMatch.Value -match 'callback\.is_valid\(\)') "Tier banner press handling must validate the callback."
Assert-True ($hitPressedMatch.Value -match 'callback\.call\(\)') "Tier banner press handling must invoke clean taps."

$expandedMenuMatch = [regex]::Match(
    $skillDetailSource,
    '(?ms)^func _add_tier_banner_expanded_menu\(.*?(?=^func |\z)'
)
Assert-True $expandedMenuMatch.Success "Missing expanded tier menu builder."
Assert-True ($expandedMenuMatch.Value -notmatch '_tier_banner_hit_button|_toggle_tier_banner') "The expanded menu body must not dismiss the menu when used to scroll."

$projectSettings = Get-Content -Raw -LiteralPath $projectSettingsPath
$archived4k = (
    $projectSettings -match '(?m)^window/size/viewport_width=2160\r?$' -and
    $projectSettings -match '(?m)^window/size/viewport_height=3840\r?$'
)
if ($archived4k) {
    Write-Output "tier-banner-scroll-source-ok runtime=blocked-archived-4k"
    exit 0
}

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"
try {
    $output = & $runner --path $projectRoot --headless --script $testScript 2>&1
    $exitCode = $LASTEXITCODE
} finally {
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
}

$output | Out-Host
Assert-True ($exitCode -eq 0) "Tier banner scroll validation failed with exit code $exitCode."
Assert-True (($output -join "`n") -match "tier-banner-scroll-ok") "Tier banner scroll validation did not report success."
Assert-NoHeadlessGodotProcesses "tier banner scroll validation"
