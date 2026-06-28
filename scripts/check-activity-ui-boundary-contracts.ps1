$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $projectRoot "scripts\main.gd"
$boundaryMapPath = Join-Path $projectRoot "docs\activity-ui-boundary-map.md"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-FunctionExists {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Boundary
    )

    Assert-True ($Text -match "(?m)^func $([regex]::Escape($Name))\b") "Missing $Boundary activity UI boundary function: $Name"
}

Assert-True (Test-Path -LiteralPath $mainPath) "Missing scripts\main.gd"
Assert-True (Test-Path -LiteralPath $boundaryMapPath) "Missing docs\activity-ui-boundary-map.md"

$main = Get-Content -LiteralPath $mainPath -Raw
$boundaryMap = Get-Content -LiteralPath $boundaryMapPath -Raw

$boundaries = @{
    "skill detail shell" = @("_render_skill_detail", "_detail_stack_entry", "_build_detail_lazy_plan", "_build_detail_jump_arrows", "_add_activity_back_arrow")
    "action cards" = @("_build_detail_interactive_action_card", "_activity_card_root_height", "_activity_card_preview_root_height", "_activity_card_depth_layer", "_activity_card_shade_layer")
    "passive and special modules" = @("_build_passive_module_card", "_build_thieving_heist_card", "_build_fishing_area_module", "_build_fishing_offer_module")
    "mastery medals" = @("_mastery_level", "_mastery_progress_pct", "_mastery_medal_texture", "_mastery_medal_visual_texture", "_mastery_for_save")
    "unlocks and lockpads" = @("_unlock_padlock_pulse_texture", "_unlock_padlock_tint_mask_texture", "_action_has_pending_unlock_readiness", "_apply_pending_activity_unlock_readiness")
    "offline summary" = @("_maybe_show_offline_summary", "_offline_summary_activity_card", "_offline_summary_stat_card", "_offline_summary_mastery_row", "_offline_summary_unlock_card")
    "offline rewards" = @("_offline_active_cycle_seconds", "_offline_xp_reward", "_offline_mastery_reward", "_offline_unlocked_actions")
}

foreach ($boundary in ($boundaries.Keys | Sort-Object)) {
    foreach ($functionName in $boundaries[$boundary]) {
        Assert-FunctionExists $main $functionName $boundary
        Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
    }
}

Assert-True ($boundaryMap -match 'save data') "Activity UI boundary map should call out save data coupling."
Assert-True ($boundaryMap -match 'lazy rendering') "Activity UI boundary map should call out lazy rendering coupling."
Assert-True ($boundaryMap -match 'module UI keys') "Activity UI boundary map should call out module UI key compatibility."

$pinCollapseGate = [regex]::Match($main, '(?s)func _module_ui_key_allows_pin_or_collapse\(module_key: String\) -> bool:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True $pinCollapseGate.Success "Missing _module_ui_key_allows_pin_or_collapse body."
Assert-True ($pinCollapseGate.Groups[1].Value -match 'if key\.begins_with\("fishing_offer:"\):\s*return false') "Fishing tool offer modules must not be pinnable or collapsible."

Write-Output "activity-ui-boundary-contracts-ok"
