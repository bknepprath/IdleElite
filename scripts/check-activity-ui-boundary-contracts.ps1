$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $projectRoot "scripts\main.gd"
$actionRuntimePath = Join-Path $projectRoot "scripts\gameplay\action_runtime.gd"
$activityUnlockRuntimePath = Join-Path $projectRoot "scripts\gameplay\activity_unlock_runtime.gd"
$moduleUiRuntimePath = Join-Path $projectRoot "scripts\module_ui\runtime.gd"
$activityCardStylesPath = Join-Path $projectRoot "scripts\ui\activity_card_styles.gd"
$activityLockRigPath = Join-Path $projectRoot "scripts\ui\activity_lock_rig.gd"
$activityUnlockCeremonySurfacePath = Join-Path $projectRoot "scripts\ui\activity_unlock_ceremony_surface.gd"
$skillDetailSurfacePath = Join-Path $projectRoot "scripts\ui\skill_detail_surface.gd"
$achievementOverlaySurfacePath = Join-Path $projectRoot "scripts\ui\achievement_overlay_surface.gd"
$masteryStatePath = Join-Path $projectRoot "scripts\progression\mastery_state.gd"
$achievementPresentationPath = Join-Path $projectRoot "scripts\achievements\presentation.gd"
$fishingUiSurfacePath = Join-Path $projectRoot "scripts\fishing\ui_surface.gd"
$passiveFirepitSurfacePath = Join-Path $projectRoot "scripts\ui\passive_firepit_surface.gd"
$thievingSurfacePath = Join-Path $projectRoot "scripts\thieving\surface.gd"
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

    Assert-True ($Text -match "(?m)^(?:static )?func $([regex]::Escape($Name))\b") "Missing $Boundary activity UI boundary function: $Name"
}

Assert-True (Test-Path -LiteralPath $mainPath) "Missing scripts\main.gd"
Assert-True (Test-Path -LiteralPath $actionRuntimePath) "Missing scripts\gameplay\action_runtime.gd"
Assert-True (Test-Path -LiteralPath $activityUnlockRuntimePath) "Missing scripts\gameplay\activity_unlock_runtime.gd"
Assert-True (Test-Path -LiteralPath $moduleUiRuntimePath) "Missing scripts\module_ui\runtime.gd"
Assert-True (Test-Path -LiteralPath $activityCardStylesPath) "Missing scripts\ui\activity_card_styles.gd"
Assert-True (Test-Path -LiteralPath $activityLockRigPath) "Missing scripts\ui\activity_lock_rig.gd"
Assert-True (Test-Path -LiteralPath $activityUnlockCeremonySurfacePath) "Missing scripts\ui\activity_unlock_ceremony_surface.gd"
Assert-True (Test-Path -LiteralPath $skillDetailSurfacePath) "Missing scripts\ui\skill_detail_surface.gd"
Assert-True (Test-Path -LiteralPath $achievementOverlaySurfacePath) "Missing scripts\ui\achievement_overlay_surface.gd"
Assert-True (Test-Path -LiteralPath $masteryStatePath) "Missing scripts\progression\mastery_state.gd"
Assert-True (Test-Path -LiteralPath $achievementPresentationPath) "Missing scripts\achievements\presentation.gd"
Assert-True (Test-Path -LiteralPath $fishingUiSurfacePath) "Missing scripts\fishing\ui_surface.gd"
Assert-True (Test-Path -LiteralPath $passiveFirepitSurfacePath) "Missing scripts\ui\passive_firepit_surface.gd"
Assert-True (Test-Path -LiteralPath $thievingSurfacePath) "Missing scripts\thieving\surface.gd"
Assert-True (Test-Path -LiteralPath $boundaryMapPath) "Missing docs\activity-ui-boundary-map.md"

$main = Get-Content -LiteralPath $mainPath -Raw
$actionRuntime = Get-Content -LiteralPath $actionRuntimePath -Raw
$activityUnlockRuntime = Get-Content -LiteralPath $activityUnlockRuntimePath -Raw
$moduleUiRuntime = Get-Content -LiteralPath $moduleUiRuntimePath -Raw
$activityCardStyles = Get-Content -LiteralPath $activityCardStylesPath -Raw
$activityLockRig = Get-Content -LiteralPath $activityLockRigPath -Raw
$activityUnlockCeremonySurface = Get-Content -LiteralPath $activityUnlockCeremonySurfacePath -Raw
$skillDetailSurface = Get-Content -LiteralPath $skillDetailSurfacePath -Raw
$achievementOverlaySurface = Get-Content -LiteralPath $achievementOverlaySurfacePath -Raw
$masteryState = Get-Content -LiteralPath $masteryStatePath -Raw
$achievementPresentation = Get-Content -LiteralPath $achievementPresentationPath -Raw
$fishingUiSurface = Get-Content -LiteralPath $fishingUiSurfacePath -Raw
$passiveFirepitSurface = Get-Content -LiteralPath $passiveFirepitSurfacePath -Raw
$thievingSurface = Get-Content -LiteralPath $thievingSurfacePath -Raw
$boundaryMap = Get-Content -LiteralPath $boundaryMapPath -Raw

$boundaries = @{
    "skill detail shell" = @("_render_skill_detail", "_detail_stack_entry", "_build_detail_jump_arrows", "_add_activity_back_arrow")
    "action cards" = @("_build_detail_interactive_action_card", "root_height", "root_height_for_action", "mat_collection_layout_height", "preview_root_height")
    "passive and special modules" = @("_build_passive_module_card", "_build_thieving_heist_card", "_build_fishing_area_module", "_build_fishing_offer_module")
    "mastery medals" = @("level", "progress_pct", "mastery_medal_texture", "mastery_medal_visual_texture", "for_save")
    "unlocks and lockpads" = @("cropped_padlock_texture", "cropped_padlock_hit_image", "_action_has_pending_unlock_readiness", "_apply_pending_activity_unlock_readiness")
}

foreach ($boundary in ($boundaries.Keys | Sort-Object)) {
    foreach ($functionName in $boundaries[$boundary]) {
        if ($functionName -eq "_build_passive_module_card") {
            Assert-FunctionExists $passiveFirepitSurface $functionName $boundary
        } elseif ($functionName -eq "_build_detail_interactive_action_card" -or $functionName -eq "_render_skill_detail" -or $functionName -eq "_detail_stack_entry" -or $functionName -eq "_build_detail_jump_arrows" -or $functionName -eq "_add_activity_back_arrow") {
            Assert-FunctionExists $skillDetailSurface $functionName $boundary
        } elseif ($functionName -eq "root_height" -or $functionName -eq "root_height_for_action" -or $functionName -eq "mat_collection_layout_height" -or $functionName -eq "preview_root_height") {
            Assert-FunctionExists $activityCardStyles $functionName $boundary
        } elseif ($functionName -eq "_build_thieving_heist_card") {
            Assert-FunctionExists $thievingSurface $functionName $boundary
        } elseif ($functionName -eq "_build_fishing_area_module" -or $functionName -eq "_build_fishing_offer_module") {
            Assert-FunctionExists $fishingUiSurface $functionName $boundary
        } elseif ($functionName -eq "level" -or $functionName -eq "progress_pct" -or $functionName -eq "for_save") {
            Assert-FunctionExists $masteryState $functionName $boundary
        } elseif ($functionName -eq "mastery_medal_texture" -or $functionName -eq "mastery_medal_visual_texture") {
            Assert-FunctionExists $achievementPresentation $functionName $boundary
        } elseif ($functionName -eq "cropped_padlock_texture" -or $functionName -eq "cropped_padlock_hit_image") {
            Assert-FunctionExists $activityLockRig $functionName $boundary
        } elseif ($functionName -eq "_action_has_pending_unlock_readiness") {
            Assert-FunctionExists $activityUnlockRuntime $functionName $boundary
        } elseif ($functionName -eq "_apply_pending_activity_unlock_readiness") {
            Assert-FunctionExists $activityUnlockCeremonySurface "apply_pending_readiness" $boundary
        } else {
            Assert-FunctionExists $main $functionName $boundary
        }
        Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
    }
}

foreach ($functionName in @("action_card_background_edge_underlay", "activity_card_depth_layer", "prism_connector_overlay", "activity_card_shade_layer", "ensure_activity_card_shade")) {
    Assert-FunctionExists $activityCardStyles $functionName "action card chrome factory"
    Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
}

foreach ($functionName in @("_maybe_show_offline_summary", "_offline_summary_activity_card", "_offline_summary_stat_card", "_offline_summary_mastery_row", "_offline_summary_unlock_card")) {
    Assert-FunctionExists $achievementOverlaySurface $functionName "offline summary presentation"
    Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
}

foreach ($functionName in @("_offline_active_cycle_seconds", "_offline_xp_reward", "_offline_mastery_reward", "_offline_unlocked_actions")) {
    Assert-FunctionExists $actionRuntime $functionName "offline rewards"
    Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
}

foreach ($functionName in @("_sync_activity_stat_popup", "_ensure_activity_stat_bonus_panel", "_activity_stat_bonus_details")) {
    Assert-FunctionExists $skillDetailSurface $functionName "stat bonus panel"
    Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
}

foreach ($functionName in @("_sync_detail_lazy_visible_cards", "_detail_lazy_unmount_item", "_detail_lazy_mount_initial_window_sync")) {
	Assert-FunctionExists $skillDetailSurface $functionName "detail lazy mount/unmount"
	Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
}

Assert-FunctionExists $skillDetailSurface "_build_detail_lazy_plan" "skill detail shell"
Assert-True ($boundaryMap -match [regex]::Escape("_build_detail_lazy_plan")) "Activity UI boundary map must mention _build_detail_lazy_plan."

foreach ($functionName in @("_activity_lock_overlay", "_on_activity_lock_clicked", "_play_activity_requirement_lock_dismissal", "_sync_activity_lock_overlay")) {
    Assert-FunctionExists $skillDetailSurface $functionName "activity lock presentation"
    Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
}

Assert-FunctionExists $fishingUiSurface "_build_fishing_offer_module" "fishing offer presentation"

foreach ($functionName in @("_route_fishing_offer_button_global_input", "_fishing_offer_button_hit")) {
    Assert-FunctionExists $fishingUiSurface $functionName "fishing offer presentation"
    Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "Activity UI boundary map must mention $functionName."
}
Assert-FunctionExists $fishingUiSurface "_play_fishing_offer_collected_transition" "fishing offer presentation"
Assert-True ($boundaryMap -match [regex]::Escape("_play_fishing_offer_collected_transition")) "Activity UI boundary map must mention _play_fishing_offer_collected_transition."

Assert-True ($boundaryMap -match 'save data') "Activity UI boundary map should call out save data coupling."
Assert-True ($boundaryMap -match 'lazy rendering') "Activity UI boundary map should call out lazy rendering coupling."
Assert-True ($boundaryMap -match 'module UI keys') "Activity UI boundary map should call out module UI key compatibility."
Assert-True ($boundaryMap -match 'Main shell/facade contract') "Activity UI boundary map should document the intentional remaining main.gd shell/facade contract."
foreach ($functionName in @("_action_key", "_action_data", "_is_event_action", "_restore_fishing_state_from_save")) {
    Assert-FunctionExists $main $functionName "main shell/facade contract"
}
foreach ($functionName in @("_scroll_to_resume_activity", "_prune_invalid_action_cards", "_skill_detail_needs_high_frequency_ui_update")) {
    Assert-True ($main -notmatch "(?m)^func $([regex]::Escape($functionName))\b") "main.gd must not re-own extracted activity/UI function $functionName."
}

$pinCollapseGate = [regex]::Match($skillDetailSurface, '(?s)func _module_ui_key_allows_pin_or_collapse\(module_key: String\) -> bool:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True $pinCollapseGate.Success "Missing _module_ui_key_allows_pin_or_collapse body."
$runtimePinCollapseGate = [regex]::Match($moduleUiRuntime, '(?s)func key_allows_pin_or_collapse\(module_key: String, action_allowed: Callable, heist_allowed: Callable, fishing_area_allowed: Callable\) -> bool:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True $runtimePinCollapseGate.Success "Missing ModuleUiRuntime.key_allows_pin_or_collapse body."
Assert-True ($runtimePinCollapseGate.Groups[1].Value -notmatch 'PREFIX_FISHING_OFFER') "Fishing tool offer modules must not be pinnable or collapsible."

Write-Output "activity-ui-boundary-contracts-ok"
