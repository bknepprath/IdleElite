$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $projectRoot "scripts\main.gd"
$boundaryMapPath = Join-Path $projectRoot "docs\ui-runtime-boundary-map.md"

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

    Assert-True ($Text -match "(?m)^func $([regex]::Escape($Name))\b") "Missing $Boundary UI boundary function: $Name"
}

Assert-True (Test-Path -LiteralPath $mainPath) "Missing scripts\main.gd"
Assert-True (Test-Path -LiteralPath $boundaryMapPath) "Missing docs\ui-runtime-boundary-map.md"

$main = Get-Content -LiteralPath $mainPath -Raw
$boundaryMap = Get-Content -LiteralPath $boundaryMapPath -Raw

$boundaries = @{
    "home/navigation" = @("_build_home_page", "_build_nav_bar", "_nav_button", "_apply_nav_style", "_show_skills", "_show_shop")
    "shop/ads" = @("_shop_unlocked", "_shop_ad_offer_button", "_shop_ad_pressed")
    "chat transport" = @("_chat_stream_connect", "_chat_send", "_chat_apply_stream_payload", "_chat_sort_and_trim_rows")
    "chat presentation" = @("_build_chat_strip", "_build_chat_overlay", "_chat_strip_visible_on_current_screen", "_chat_row", "_chat_composer")
    "leaderboard networking/data" = @("_leaderboard_fetch_category", "_leaderboard_submit_scores", "_leaderboard_categories", "_leaderboard_score_for_category")
    "leaderboard page" = @("_render_leaderboard_page", "_leaderboard_page_frame", "_leaderboard_player_card", "_leaderboard_row")
    "profile/avatar" = @("_build_profile_overlay", "_profile_avatar_picker_button", "_profile_avatar_texture", "_profile_avatar_frame")
}

foreach ($boundary in ($boundaries.Keys | Sort-Object)) {
    foreach ($functionName in $boundaries[$boundary]) {
        Assert-FunctionExists $main $functionName $boundary
        Assert-True ($boundaryMap -match [regex]::Escape($functionName)) "UI boundary map must mention $functionName."
    }
}

Assert-True ($boundaryMap -match 'current_screen') "UI boundary map should call out top-level screen routing risk."
Assert-True ($boundaryMap -match 'Firebase') "UI boundary map should call out Firebase coupling for chat and leaderboard."
Assert-True ($boundaryMap -match 'saved avatar/profile keys') "UI boundary map should call out profile save compatibility."
Assert-True ($main -match 'skills_tab\.pressed\.connect\(_show_skills_module\)') "Bottom gray Skills nav button must open the selected skill module page."
Assert-True ($main -notmatch 'skills_tab\.pressed\.connect\(_show_skills\)') "Bottom gray Skills nav button must not open the skills overview."
$showSkillsModuleMatch = [regex]::Match($main, '(?s)func _show_skills_module\(\) -> void:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($showSkillsModuleMatch.Success) "Missing _show_skills_module body for bottom Skills nav contract."
Assert-True ($showSkillsModuleMatch.Groups[1].Value -notmatch '_begin_direct_skill_nav_cover\(\)') "Bottom gray Skills nav button must not show the direct cream transition cover."
$paperFadeMatch = [regex]::Match($main, '(?s)func _ensure_skill_swipe_paper_fade_overlay\(\) -> void:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($paperFadeMatch.Success) "Missing _ensure_skill_swipe_paper_fade_overlay body for swipe cover layering contract."
Assert-True ($paperFadeMatch.Groups[1].Value -match '_apply_skill_page_cover_bounds\(skill_swipe_paper_fade_overlay, true\)') "Swipe paper fade overlay must cover bottom interactive UI."
Assert-True ($paperFadeMatch.Groups[1].Value -match '_ensure_skill_nav_cover_layer\(\)\.add_child\(skill_swipe_paper_fade_overlay\)') "Swipe paper fade overlay must draw above bottom interactive UI."
$globalBottomCoverMatch = [regex]::Match($main, '(?s)func _global_chat_nav_cover_bottom_offset\(\) -> float:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($globalBottomCoverMatch.Success) "Missing _global_chat_nav_cover_bottom_offset body for global bottom UI layering contract."
Assert-True ($globalBottomCoverMatch.Groups[1].Value -match '\[chat_strip, nav_bar\]') "Swipe covers must stop above global chat and bottom nav."
$outgoingCoverMatch = [regex]::Match($main, '(?s)func _begin_skill_swipe_outgoing_cover\(\) -> Control:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($outgoingCoverMatch.Success) "Missing _begin_skill_swipe_outgoing_cover body for swipe release handoff contract."
Assert-True ($outgoingCoverMatch.Groups[1].Value -match 'holder\.modulate = Color\(1\.0, 1\.0, 1\.0, 0\.0\) if skill_swipe_paper_fade_hold_alpha >= 0\.99 else Color\.WHITE') "Committed swipe release must not flash the outgoing page above the paper fade."
$incomingEntryMatch = [regex]::Match($main, '(?s)func _begin_skill_swipe_incoming_entry\(start_x: float\) -> void:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($incomingEntryMatch.Success) "Missing _begin_skill_swipe_incoming_entry body for directional swipe entry contract."
Assert-True ($incomingEntryMatch.Groups[1].Value -match 'tween_method\(\s*_apply_skill_swipe_drag_offset,\s*start_x,\s*0\.0,') "Incoming skill page must slide from the swipe direction into center."
Assert-True ($main -match '_begin_skill_swipe_incoming_entry\(float\(signi\(offset\)\) \* _skill_swipe_page_span\(\)\)') "Normal skill swipe navigation must use a directional incoming entry."

Write-Output "ui-boundary-contracts-ok"
