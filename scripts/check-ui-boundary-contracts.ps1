$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$navigationShell = Get-Content -LiteralPath (Join-Path $projectRoot "scripts\ui\navigation_shell.gd") -Raw
$skillSwipeActivitySurface = Get-Content -LiteralPath (Join-Path $projectRoot "scripts\ui\skill_swipe_activity_surface.gd") -Raw
$fishingUiSurface = Get-Content -LiteralPath (Join-Path $projectRoot "scripts\fishing\ui_surface.gd") -Raw

Assert-True ($navigationShell -match 'hero_tab\.pressed\.connect\(_activate_bottom_nav_target\.bind\("home", hero_tab\)\)') "Bottom gray Home nav button must route pressed through the active red-X dispatcher."
Assert-True ($navigationShell -match 'hub_tab\.pressed\.connect\(_activate_bottom_nav_target\.bind\("hub", hub_tab\)\)') "Bottom gray Hub nav button must route pressed through the active red-X dispatcher."
Assert-True ($navigationShell -match 'host\.settings_tab\.pressed\.connect\(_activate_bottom_nav_target\.bind\("settings", host\.settings_tab\)\)') "Bottom gray Settings nav button must route pressed through the active red-X dispatcher."
Assert-True ($navigationShell -match 'shop_tab\.pressed\.connect\(_activate_bottom_nav_target\.bind\("shop", shop_tab\)\)') "Bottom gray Shop nav button must route pressed through the active red-X dispatcher."
Assert-True ($navigationShell -notmatch 'settings_tab\.pressed\.connect\(host\._show_settings\)') "Bottom gray Settings red-X must not be wired directly back to Settings."
Assert-True ($navigationShell -match 'host\.skills_tab\.pressed\.connect\(_show_skills_module\)') "Bottom gray Skills nav button must open the selected skill module page."
Assert-True ($navigationShell -notmatch 'skills_tab\.pressed\.connect\(host\._show_skills\)') "Bottom gray Skills nav button must not open the skills overview."
$activateBottomNavMatch = [regex]::Match($navigationShell, '(?s)^func _activate_bottom_nav_target\(target_screen: String, source_button: Control\) -> void:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($activateBottomNavMatch.Success) "Missing _activate_bottom_nav_target body for bottom nav routing contract."
Assert-True ($activateBottomNavMatch.Groups[1].Value -match '_bottom_nav_open_close_returns_to_skill\(target_screen, source_button\)') "Active red-X bottom nav buttons must route back to the selected skill detail page."
Assert-True ($activateBottomNavMatch.Groups[1].Value -match '_show_skills_module\(\)') "Active red-X bottom nav buttons must use the skill module/detail route, not the skills overview."
$bottomNavCloseMatch = [regex]::Match($navigationShell, '(?s)^func _bottom_nav_open_close_returns_to_skill\(target_screen: String, source_button: Control\) -> bool:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($bottomNavCloseMatch.Success) "Missing _bottom_nav_open_close_returns_to_skill body for red-X bottom nav routing contract."
Assert-True ($bottomNavCloseMatch.Groups[1].Value -match 'target_screen == "skill"') "Stats/skills nav button must remain exempt from red-X close routing."
Assert-True ($bottomNavCloseMatch.Groups[1].Value -match '_is_bottom_nav_button\(nav_button\)') "Red-X close routing must only apply to built-in bottom nav buttons."
Assert-True ($bottomNavCloseMatch.Groups[1].Value -match '_bottom_nav_target_for_button\(nav_button\) != target_screen') "Red-X close routing must confirm the pressed button owns the requested target screen."
$showSkillsModuleMatch = [regex]::Match($navigationShell, '(?s)^func _show_skills_module\(\) -> void:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($showSkillsModuleMatch.Success) "Missing _show_skills_module body for bottom Skills nav contract."
Assert-True ($showSkillsModuleMatch.Groups[1].Value -notmatch '_begin_direct_skill_nav_cover\(\)') "Bottom gray Skills nav button must not show the direct cream transition cover."
Assert-True ($showSkillsModuleMatch.Groups[1].Value -match 'previous_screen == "home" or previous_screen == "achievements"') "Bottom gray Skills nav button must treat Home/Achievements as revealable top-level pages."
Assert-True ($showSkillsModuleMatch.Groups[1].Value -match 'current_screen = "skill"') "Bottom gray Skills nav button must commit to the selected skill detail screen before rendering."
$directSkillNavCoverMatch = [regex]::Match($skillSwipeActivitySurface, '(?s)^func _begin_direct_skill_nav_cover\(\) -> void:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($directSkillNavCoverMatch.Success) "Missing _begin_direct_skill_nav_cover body for direct skill transition contract."
Assert-True ($directSkillNavCoverMatch.Groups[1].Value -match '_navigation_shell\(\)\._apply_skill_page_cover_bounds\(cover, true\)') "Direct skill transition cover must stop above global chat and bottom nav."
$paperFadeMatch = [regex]::Match($skillSwipeActivitySurface, '(?s)^func _ensure_skill_swipe_paper_fade_overlay\(\) -> void:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($paperFadeMatch.Success) "Missing _ensure_skill_swipe_paper_fade_overlay body for swipe cover layering contract."
Assert-True ($paperFadeMatch.Groups[1].Value -match '_navigation_shell\(\)\._apply_skill_page_cover_bounds\(skill_swipe_paper_fade_overlay, true\)') "Swipe paper fade overlay must cover bottom interactive UI."
Assert-True ($paperFadeMatch.Groups[1].Value -match '_ensure_skill_nav_cover_layer\(\)\.add_child\(skill_swipe_paper_fade_overlay\)') "Swipe paper fade overlay must draw above bottom interactive UI."
$globalBottomCoverMatch = [regex]::Match($navigationShell, '(?s)^func _global_chat_nav_cover_bottom_offset\(\) -> float:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($globalBottomCoverMatch.Success) "Missing _global_chat_nav_cover_bottom_offset body for global bottom UI layering contract."
Assert-True ($globalBottomCoverMatch.Groups[1].Value -match '\[host\._profile_chat_overlay_surface\(\)\.chat_strip_control\(\), nav_bar\]') "Swipe covers must stop above global chat and bottom nav."
$outgoingCoverMatch = [regex]::Match($skillSwipeActivitySurface, '(?s)^func _begin_skill_swipe_outgoing_cover\(\) -> Control:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($outgoingCoverMatch.Success) "Missing _begin_skill_swipe_outgoing_cover body for swipe release handoff contract."
Assert-True ($outgoingCoverMatch.Groups[1].Value -match 'holder\.modulate = Color\(1\.0, 1\.0, 1\.0, 0\.0\) if _skill_swipe_activity_surface\(\)\._paper_fade_hold_active\(\) else Color\.WHITE') "Committed swipe release must not flash the outgoing page above the paper fade."
$incomingEntryMatch = [regex]::Match($skillSwipeActivitySurface, '(?s)^func _begin_skill_swipe_incoming_entry\(start_x: float\) -> void:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($incomingEntryMatch.Success) "Missing _begin_skill_swipe_incoming_entry body for directional swipe entry contract."
Assert-True ($incomingEntryMatch.Groups[1].Value -match 'tween_method\(\s*_apply_skill_swipe_drag_offset,\s*start_x,\s*0\.0,') "Incoming skill page must slide from the swipe direction into center."
Assert-True ($skillSwipeActivitySurface -match '_begin_skill_swipe_incoming_entry\((?:gap_entry_x if use_gap_load_transition else )?float\(signi\(offset\)\) \* _skill_swipe_page_span\(\)\)') "Normal skill swipe navigation must use a directional incoming entry."
$fishingOfferRouterMatch = [regex]::Match($fishingUiSurface, '(?s)func _route_fishing_offer_button_global_input\(event: InputEvent\) -> bool:(.*?)(?=^func |\z)', [System.Text.RegularExpressions.RegexOptions]::Multiline)
Assert-True ($fishingOfferRouterMatch.Success) "Missing fishing offer global input router."
Assert-True ($fishingOfferRouterMatch.Groups[1].Value -match '_position_inside_bottom_interactive_ui\(event_position\)') "Fishing offer global input must not consume module utility, chat, or nav taps."

Write-Output "ui-boundary-contracts-ok"
