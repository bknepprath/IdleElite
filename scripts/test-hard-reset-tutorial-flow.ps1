$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\hard-reset-tutorial-flow"
$testScript = Join-Path $testDir "hard_reset_tutorial_flow_test.gd"
$savePath = Join-Path $env:APPDATA "Godot\app_userdata\Idle Elite\idle_elite_save.json"
$backupPath = Join-Path $testDir "idle_elite_save.backup.json"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )
    if (-not $Condition) {
        throw $Message
    }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$hadSave = Test-Path -LiteralPath $savePath
if ($hadSave) {
    Copy-Item -LiteralPath $savePath -Destination $backupPath -Force
}

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousBootSmoke = $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE
$previousBootSmokeSeconds = $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"
$env:IDLE_ELITE_HEADLESS_BOOT_SMOKE = "1"
$env:IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS = "60"

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 120
const TEST_FRAME_SECONDS := 1.0 / 120.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("hard-reset-tutorial-flow-start")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := _instantiate_main(packed)
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return

	scene.call("_show_settings")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
	if str(scene.get("current_screen")) != "settings":
		_fail("settings screen did not open before reset: %s" % _summary(scene))
		return

	scene.call("_reset_data")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if bool(scene.get("tutorial_active")) and _tutorial_skill_page_ready(scene):
			break

	if not bool(scene.get("tutorial_active")):
		_fail("hard reset did not restart tutorial: %s" % _summary(scene))
		return
	if not _tutorial_skill_page_ready(scene):
		_fail("hard reset should start on fight detail page, not the skill menu: %s" % _summary(scene))
		return
	if int(scene.get("tutorial_step")) != 1:
		_fail("hard reset tutorial should start on the fight activity step: %s" % _summary(scene))
		return
	var nav_bar := scene.get("nav_bar") as Control
	if nav_bar == null or not nav_bar.visible:
		_fail("hard reset tutorial should keep the bottom nav shell visible: %s" % _summary(scene))
		return
	if not _bottom_nav_locked_controls_ok(scene):
		_fail("hard reset tutorial should show all nav buttons with skills/settings bright and other nav locked: %s %s" % [_summary(scene), _bottom_nav_summary(scene)])
		return
	var tutorial_panel := scene.get("tutorial_panel") as Control
	if tutorial_panel != null and tutorial_panel.visible:
		_fail("hard reset tutorial should not show the legacy boxed tutorial panel: %s" % _summary(scene))
		return
	if not _only_starter_activity_rendered(scene):
		_fail("hard reset tutorial should render only Shove Wobbly Hay Bale: %s actions=%s" % [_summary(scene), str(_rendered_action_ids(scene))])
		return
	print("hard-reset-tutorial-flow-stage starter-ready")

	if not _press_tutorial_target(scene):
		_fail("hard reset fight activity target press was not accepted: %s" % _summary(scene))
		return
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if not str(scene.get("running_action_id")).is_empty():
			break
	if str(scene.get("running_action_id")).is_empty():
		_fail("hard reset tutorial did not start the first fight activity after target tap: %s" % _summary(scene))
		return
	if bool(scene.get("tutorial_active")):
		_fail("legacy tutorial target overlay should dismiss after the first activity starts: %s" % _summary(scene))
		return
	if bool(scene.get("onboarding_tutorial_complete")):
		_fail("starting the first activity should not complete onboarding: %s" % _summary(scene))
		return
	if nav_bar == null or not nav_bar.visible:
		_fail("bottom nav shell disappeared after the first tutorial activity starts: %s" % _summary(scene))
		return
	if not _bottom_nav_locked_controls_ok(scene):
		_fail("bottom nav should still show all buttons with skills/settings bright and other nav locked after the first tutorial activity starts: %s %s" % [_summary(scene), _bottom_nav_summary(scene)])
		return
	if _has_page_switch_module(scene):
		_fail("page-switch navigation should remain hidden after the first tutorial activity starts: %s" % _summary(scene))
		return
	if _fight_header_summary_visible(scene):
		_fail("fighting header should remain hidden immediately after the first tutorial activity starts: %s" % _summary(scene))
		return
	if _fight_stamina_visible(scene):
		_fail("fight stamina gauge should remain hidden immediately after the first tutorial activity starts: %s" % _summary(scene))
		return
	print("hard-reset-tutorial-flow-stage starter-clicked")
	for _i in range(360):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if nav_bar == null or not nav_bar.visible:
			_fail("bottom nav shell disappeared while the first tutorial activity was running: %s" % _summary(scene))
			return
		if not _bottom_nav_locked_controls_ok(scene):
			_fail("bottom nav lock state changed while the first tutorial activity was running: %s %s" % [_summary(scene), _bottom_nav_summary(scene)])
			return
		if _has_page_switch_module(scene):
			_fail("page-switch navigation appeared while the first tutorial activity was running: %s" % _summary(scene))
			return
		if bool(scene.get("onboarding_tutorial_complete")):
			_fail("first tutorial activity prematurely completed onboarding: %s" % _summary(scene))
			return
		if int(scene.get("onboarding_starter_action_completion_count")) == 0 and _fight_header_summary_visible(scene):
			_fail("fighting header appeared before the starter activity completed: %s" % _summary(scene))
			return
	for _i in range(960):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if _mastery_tip_visible(scene):
			break
	if not _mastery_tip_visible(scene):
		_fail("mastery bar tutorial message did not appear after starter completions: %s %s" % [_summary(scene), _onboarding_tip_summary(scene)])
		return
	print("hard-reset-tutorial-flow-stage mastery-tip-observed")
	var test_skills := scene.get("skills") as Dictionary
	var fight_state := test_skills.get("fight", {}) as Dictionary
	fight_state["xp"] = scene.call("_xp_for_level", 2)
	test_skills["fight"] = fight_state
	scene.set("skills", test_skills)
	scene.call("_recalculate_level", "fight", true)
	await scene.call("_refresh_visible_skill_detail_action_list", -1, "fight", true)
	for _i in range(360):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if _lock_click_tip_visible(scene):
			break
	if not _lock_click_tip_visible(scene):
		_fail("lock-pad click tutorial message did not appear when the next lock was ready: %s %s" % [_summary(scene), _onboarding_tip_summary(scene)])
		return
	if not _hover_level_two_lock_without_click(scene):
		_fail("could not hover the level 2 lock while the click-lock tutorial message was visible: %s %s" % [_summary(scene), _onboarding_tip_summary(scene)])
		return
	for _i in range(24):
		await _wait_test_frame()
	if not _lock_click_tip_visible(scene) or bool(scene.get("lock_click_tip_seen")):
		_fail("click-lock tutorial message disappeared before the lock was clicked: %s %s" % [_summary(scene), _onboarding_tip_summary(scene)])
		return
	if not bool(scene.call("_tutorial_level_two_unlock_should_use_fast_reveal", "fight", "kick-mud-off-boot")):
		_fail("level 2 tutorial module unlock should use the smooth fast reveal path")
		return
	if bool(scene.call("_tutorial_level_two_unlock_should_use_fast_reveal", "fight", "wrestle-stuck-gate-latch")):
		_fail("only the level 2 tutorial module should use the fast reveal path")
		return
	print("hard-reset-tutorial-flow-stage starter-run-observed")
	var manual_unlocks := scene.get("manual_activity_unlocks") as Dictionary
	manual_unlocks["fight:kick-mud-off-boot"] = true
	scene.set("manual_activity_unlocks", manual_unlocks)
	scene.set("tutorial_gate_latch_only_until_swipe", true)
	scene.set("activity_unlock_ceremony_count", 0)
	scene.set("locked_activity_preview_fade_play_pending", false)
	scene.set("stamina_gauge_tip_seen", true)
	scene.set("onboarding_fight_action_stats_revealed", true)
	var test_stamina := scene.get("stamina") as Dictionary
	test_stamina["fight"] = 0.0
	scene.set("stamina", test_stamina)
	scene.call("_mark_onboarding_swipe_navigation_unlocked")
	scene.call("_maybe_trigger_onboarding_swipe_tip_at_zero_stamina", "fight")
	await scene.call("_refresh_visible_skill_detail_action_list", -1, "fight", true)
	for _i in range(720):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if _has_page_switch_module(scene) and _skill_swipe_tip_between_level_two_and_three(scene):
			break
	if not _has_page_switch_module(scene):
		_fail("page-switch navigation did not appear when the swipe tutorial step became available: %s" % _summary(scene))
		return
	if not bool(scene.get("onboarding_swipe_navigation_unlocked")):
		_fail("page-switch navigation appeared before onboarding swipe navigation was unlocked: %s" % _summary(scene))
		return
	if not _skill_swipe_tip_between_level_two_and_three(scene):
		_fail("skill-swipe tutorial line was not placed between the level 2 and level 3 fight modules: %s tip_index=%s action_indices=%s" % [_summary(scene), str(_first_group_stack_index(scene, "skill_swipe_tip_notes")), str(_fight_action_stack_indices(scene))])
		return
	if not await _press_first_page_switch_button(scene):
		_fail("page-switch button press was not accepted during the swipe tutorial step: %s" % _summary(scene))
		return
	for _i in range(360):
		await _wait_test_frame()
		if str(scene.get("selected_skill_id")) != "fight":
			break
	if str(scene.get("selected_skill_id")) == "fight":
		_fail("page-switch button did not navigate away from fight during the swipe tutorial step: %s" % _summary(scene))
		return
	if not bool(scene.get("skill_swipe_tip_seen")):
		_fail("page-switch button did not advance the swipe tutorial milestone: %s" % _summary(scene))
		return
	print("hard-reset-tutorial-flow-stage page-switch-ok")

	scene.call("save_game")
	for _i in range(12):
		await _wait_test_frame()
	scene = _instantiate_main(packed)
	if not await _wait_for_boot_ready(scene):
		_fail("reloaded mid-tutorial save did not become ready")
		return
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if _tutorial_skill_page_ready(scene):
			break
	if bool(scene.get("tutorial_active")):
		_fail("mid-tutorial save should not restore the legacy boxed tutorial overlay: %s" % _summary(scene))
		return
	if not _tutorial_skill_page_ready(scene):
		_fail("mid-tutorial save did not restore to fight detail: %s" % _summary(scene))
		return
	if bool(scene.get("onboarding_tutorial_complete")):
		_fail("mid-tutorial save should keep onboarding incomplete: %s" % _summary(scene))
		return
	print("hard-reset-tutorial-flow-stage reload-ok")

	scene.call("_graduate_onboarding_tutorial")
	for _i in range(8):
		await _wait_test_frame()
	if not _completion_bottom_chrome_fade_started(scene):
		_fail("graduating onboarding did not start the bottom chrome fade from transparent: %s %s" % [_summary(scene), _bottom_chrome_summary(scene)])
		return
	for _i in range(240):
		await _wait_test_frame()
		if _tutorial_completion_visible(scene) and _completion_bottom_chrome_state_ok(scene):
			break
	if not _tutorial_completion_visible(scene):
		_fail("graduating onboarding did not reveal bottom controls: %s %s" % [_summary(scene), _bottom_nav_summary(scene)])
		return
	if not _completion_bottom_chrome_state_ok(scene):
		_fail("graduating onboarding did not leave bottom chrome collapsed with fresh-game locks: %s %s %s" % [_summary(scene), _bottom_nav_summary(scene), _bottom_chrome_summary(scene)])
		return
	print("hard-reset-tutorial-flow-stage graduation-ok")

	scene.call("_reset_data")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if bool(scene.get("tutorial_active")) and _tutorial_skill_page_ready(scene):
			break
	if not bool(scene.get("tutorial_active")) or int(scene.get("tutorial_step")) != 1:
		_fail("hard reset after completed tutorial did not restart a fresh tutorial: %s" % _summary(scene))
		return
	if not _tutorial_skill_page_ready(scene):
		_fail("hard reset after completion should return to fight detail: %s" % _summary(scene))
		return
	var reset_nav := scene.get("nav_bar") as Control
	if reset_nav == null or not reset_nav.visible:
		_fail("fresh tutorial after completed reset should keep the bottom nav shell visible: %s" % _summary(scene))
		return
	if not _bottom_nav_locked_controls_ok(scene):
		_fail("fresh tutorial after completed reset should show all nav buttons with skills/settings bright and other nav locked: %s %s" % [_summary(scene), _bottom_nav_summary(scene)])
		return
	tutorial_panel = scene.get("tutorial_panel") as Control
	if tutorial_panel != null and tutorial_panel.visible:
		_fail("fresh tutorial after completed reset should not show the legacy boxed tutorial panel: %s" % _summary(scene))
		return
	if not _only_starter_activity_rendered(scene):
		_fail("fresh tutorial after completed reset should render only Shove Wobbly Hay Bale: %s actions=%s" % [_summary(scene), str(_rendered_action_ids(scene))])
		return

	print("hard-reset-tutorial-flow-ok %s" % _summary(scene))
	quit(0)


func _instantiate_main(packed: PackedScene) -> Node:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var scene := packed.instantiate()
	root.add_child(scene)
	return scene


func _press_tutorial_target(scene: Node) -> bool:
	var target := scene.call("_tutorial_target_control") as Control
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	var position := target.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	var accepted := bool(scene.call("_route_tutorial_panel_input", press))
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	scene.call("_route_tutorial_panel_input", release)
	return accepted


func _tutorial_completion_visible(scene: Node) -> bool:
	if bool(scene.get("tutorial_active")):
		return false
	if not bool(scene.get("onboarding_tutorial_complete")):
		return false
	var nav_bar := scene.get("nav_bar") as Control
	return nav_bar != null and nav_bar.visible and _bottom_nav_post_tutorial_controls_ok(scene)


func _completion_bottom_chrome_state_ok(scene: Node) -> bool:
	var utility_row := scene.get("module_utility_row") as Control
	var chat_strip := scene.get("chat_strip") as Control
	var collapsed := bool(scene.get("module_utility_collapsed"))
	return (
		_bottom_nav_post_tutorial_controls_ok(scene)
		and collapsed
		and utility_row != null
		and utility_row.visible
		and _effective_canvas_alpha(utility_row) > 0.96
		and chat_strip != null
		and chat_strip.visible
		and _effective_canvas_alpha(chat_strip) > 0.96
	)


func _completion_bottom_chrome_fade_started(scene: Node) -> bool:
	var utility_row := scene.get("module_utility_row") as Control
	var chat_strip := scene.get("chat_strip") as Control
	if utility_row == null or chat_strip == null:
		return false
	if not utility_row.visible or not chat_strip.visible:
		return false
	if not bool(scene.get("module_utility_collapsed")):
		return false
	var utility_alpha := _effective_canvas_alpha(utility_row)
	var chat_alpha := _effective_canvas_alpha(chat_strip)
	return utility_alpha >= 0.0 and utility_alpha < 0.98 and chat_alpha >= 0.0 and chat_alpha < 0.98


func _bottom_nav_locked_controls_ok(scene: Node) -> bool:
	return _bottom_nav_row_visible(scene) and _all_nav_buttons_visible(scene) and _settings_nav_button_enabled(scene) and _skills_nav_button_enabled(scene) and _non_settings_nav_buttons_locked(scene)


func _bottom_nav_post_tutorial_controls_ok(scene: Node) -> bool:
	return (
		_bottom_nav_row_visible(scene)
		and _all_nav_buttons_visible(scene)
		and _settings_nav_button_enabled(scene)
		and _skills_nav_button_enabled(scene)
		and _fresh_game_locked_nav_buttons_ok(scene)
	)


func _all_nav_buttons_visible(scene: Node) -> bool:
	for raw_name in ["hero_tab", "hub_tab", "skills_tab", "settings_tab", "shop_tab"]:
		var button := scene.get(raw_name) as Control
		if button == null or not button.is_visible_in_tree() or _effective_canvas_alpha(button) <= 0.01:
			return false
	return true


func _bottom_nav_row_visible(scene: Node) -> bool:
	var nav_bar := scene.get("nav_bar") as Control
	if nav_bar == null or not is_instance_valid(nav_bar):
		return false
	var row := scene.get("bottom_nav_buttons_row") as Control
	if row == null:
		row = _find_named_descendant(nav_bar, "BottomNavButtonsRow") as Control
	return row != null and row.is_visible_in_tree() and _effective_canvas_alpha(row) > 0.01


func _settings_nav_button_enabled(scene: Node) -> bool:
	var settings := scene.get("settings_tab") as Button
	return settings != null and settings.is_visible_in_tree() and _effective_canvas_alpha(settings) > 0.01 and not settings.disabled and settings.mouse_filter == Control.MOUSE_FILTER_STOP


func _skills_nav_button_enabled(scene: Node) -> bool:
	var skills := scene.get("skills_tab") as Button
	return skills != null and skills.is_visible_in_tree() and _effective_canvas_alpha(skills) > 0.01 and not skills.disabled and skills.mouse_filter == Control.MOUSE_FILTER_STOP and _color_nearly_equal(skills.modulate, Color.WHITE)


func _fresh_game_locked_nav_buttons_ok(scene: Node) -> bool:
	for raw_name in ["hero_tab", "hub_tab", "shop_tab"]:
		var button := scene.get(raw_name) as Button
		if button == null or not button.is_visible_in_tree() or _effective_canvas_alpha(button) <= 0.01:
			return false
		if button.disabled or button.mouse_filter != Control.MOUSE_FILTER_STOP:
			return false
		if not _color_nearly_equal(button.modulate, Color("#3f3f3f")):
			return false
	return true


func _non_settings_nav_buttons_locked(scene: Node) -> bool:
	for raw_name in ["hero_tab", "hub_tab", "shop_tab"]:
		var button := scene.get(raw_name) as Button
		if button == null or not button.is_visible_in_tree() or _effective_canvas_alpha(button) <= 0.01:
			return false
		if button.disabled or button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return false
		if not _color_nearly_equal(button.modulate, Color("#3f3f3f")):
			return false
	return true


func _color_nearly_equal(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01 and absf(a.a - b.a) < 0.01


func _bottom_nav_summary(scene: Node) -> String:
	var nav_bar := scene.get("nav_bar") as Control
	var row := scene.get("bottom_nav_buttons_row") as Control
	if row == null and nav_bar != null:
		row = _find_named_descendant(nav_bar, "BottomNavButtonsRow") as Control
	return "nav_present=%s nav_visible=%s row_present=%s row_visible=%s row_tree=%s row_alpha=%.3f all_buttons=%s settings_enabled=%s skills_enabled=%s other_nav_locked=%s children=%s complete=%s tutorial=%s" % [
		str(nav_bar != null),
		str(nav_bar != null and nav_bar.visible),
		str(row != null),
		str(row != null and row.visible),
		str(row != null and row.is_visible_in_tree()),
		_effective_canvas_alpha(row),
		str(_all_nav_buttons_visible(scene)),
		str(_settings_nav_button_enabled(scene)),
		str(_skills_nav_button_enabled(scene)),
		str(_non_settings_nav_buttons_locked(scene)),
		str(_child_names(nav_bar)),
		str(scene.get("onboarding_tutorial_complete")),
		str(scene.get("tutorial_active")),
	]


func _bottom_chrome_summary(scene: Node) -> String:
	var utility_row := scene.get("module_utility_row") as Control
	var chat_strip := scene.get("chat_strip") as Control
	return "utility_present=%s utility_visible=%s utility_alpha=%.3f chat_present=%s chat_visible=%s chat_alpha=%.3f collapsed=%s" % [
		str(utility_row != null),
		str(utility_row != null and utility_row.visible),
		_effective_canvas_alpha(utility_row),
		str(chat_strip != null),
		str(chat_strip != null and chat_strip.visible),
		_effective_canvas_alpha(chat_strip),
		str(scene.get("module_utility_collapsed")),
	]


func _child_names(node: Node) -> Array:
	var names := []
	if node == null:
		return names
	for child in node.get_children():
		names.append(str((child as Node).name))
	return names


func _fight_header_summary_visible(scene: Node) -> bool:
	var header := scene.get("detail_header_left_block") as Control
	return header != null and header.is_visible_in_tree() and _effective_canvas_alpha(header) > 0.01


func _fight_stamina_visible(scene: Node) -> bool:
	var fade_group := scene.get("detail_regen_circle_fade_group") as Control
	if fade_group != null and fade_group.is_visible_in_tree() and _effective_canvas_alpha(fade_group) > 0.01:
		return true
	var circle := scene.get("detail_regen_circle") as Control
	return circle != null and circle.is_visible_in_tree() and _effective_canvas_alpha(circle) > 0.01


func _effective_canvas_alpha(control: Control) -> float:
	if control == null or not is_instance_valid(control):
		return 0.0
	var alpha := control.modulate.a * control.self_modulate.a
	var parent := control.get_parent()
	while parent != null:
		if parent is CanvasItem:
			var item := parent as CanvasItem
			alpha *= item.modulate.a * item.self_modulate.a
		parent = parent.get_parent()
	return alpha


func _tutorial_skill_page_ready(scene: Node) -> bool:
	if str(scene.get("current_screen")) != "skill":
		return false
	if str(scene.get("selected_skill_id")) != "fight":
		return false
	var cards := scene.get("action_cards") as Dictionary
	return cards != null and cards.size() > 0


func _only_starter_activity_rendered(scene: Node) -> bool:
	var ids := _rendered_action_ids(scene)
	return ids.size() == 1 and ids[0] == "shove-wobbly-hay-bale"


func _mastery_tip_visible(scene: Node) -> bool:
	return _group_has_visible_node(scene, "onboarding_mastery_tip_notes")


func _lock_click_tip_visible(scene: Node) -> bool:
	return _group_has_visible_node(scene, "lock_click_tip_notes")


func _hover_level_two_lock_without_click(scene: Node) -> bool:
	var group := _lock_group_for_action(scene, "fight:kick-mud-off-boot")
	if group == null:
		return false
	var position := group.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	scene.call("_route_activity_lock_input", motion)
	scene.get_viewport().push_input(motion, false)
	return true


func _lock_group_for_action(scene: Node, action_key: String) -> Control:
	var cards := scene.get("action_cards") as Dictionary
	if cards == null or not cards.has(action_key):
		return null
	var card := cards[action_key] as Dictionary
	var overlay := card.get("lock_overlay", {}) as Dictionary
	var group := overlay.get("group") as Control
	if group != null and is_instance_valid(group) and group.is_visible_in_tree():
		return group
	return null


func _group_has_visible_node(scene: Node, group_name: String) -> bool:
	var tree := scene.get_tree()
	if tree == null:
		return false
	for raw_node in tree.get_nodes_in_group(group_name):
		var control := raw_node as Control
		if control != null and is_instance_valid(control) and control.is_visible_in_tree() and _effective_canvas_alpha(control) > 0.01:
			return true
	return false


func _onboarding_tip_summary(scene: Node) -> String:
	return "starter_count=%s fight_level=%s fight_xp=%s mastery_tip=%s medal_tip=%s lock_tip=%s stats_revealed=%s stamina_seen=%s header=%s stamina=%s header_running=%s stamina_running=%s stats_running=%s rendered=%s" % [
		str(scene.get("onboarding_starter_action_completion_count")),
		str(scene.call("_skill_level", "fight")),
		str((scene.get("skills") as Dictionary).get("fight", {}).get("xp", "?")),
		str(_mastery_tip_visible(scene)),
		str(_group_has_visible_node(scene, "onboarding_medal_tip_notes")),
		str(_lock_click_tip_visible(scene)),
		str(scene.get("onboarding_fight_action_stats_revealed")),
		str(scene.get("stamina_gauge_tip_seen")),
		str(_fight_header_summary_visible(scene)),
		str(_fight_stamina_visible(scene)),
		str(scene.get("onboarding_header_sequence_running")),
		str(scene.get("onboarding_stamina_tip_sequence_running")),
		str(scene.get("onboarding_fight_action_stats_fade_running")),
		str(_rendered_action_ids(scene)),
	]


func _rendered_action_ids(scene: Node) -> Array:
	var ids := []
	var cards := scene.get("action_cards") as Dictionary
	if cards == null:
		return ids
	for raw_key in cards.keys():
		var key := str(raw_key)
		if key.begins_with("fight:"):
			ids.append(key.substr("fight:".length()))
	ids.sort()
	return ids


func _has_page_switch_module(scene: Node) -> bool:
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not scroll.is_inside_tree() or scroll.get_child_count() <= 0:
		return false
	return _find_named_descendant(scroll.get_child(0), "PageSwitchModule") != null


func _skill_swipe_tip_between_level_two_and_three(scene: Node) -> bool:
	var action_indices := _fight_action_stack_indices(scene)
	if not action_indices.has("kick-mud-off-boot") or not action_indices.has("wrestle-stuck-gate-latch"):
		return false
	var tip_index := _first_group_stack_index(scene, "skill_swipe_tip_notes")
	return tip_index > int(action_indices["kick-mud-off-boot"]) and tip_index < int(action_indices["wrestle-stuck-gate-latch"])


func _fight_action_stack_indices(scene: Node) -> Dictionary:
	var indices := {}
	var cards := scene.get("action_cards") as Dictionary
	if cards == null:
		return indices
	for raw_key in cards.keys():
		var key := str(raw_key)
		if not key.begins_with("fight:"):
			continue
		var card := cards.get(key, {}) as Dictionary
		var entry := card.get("entry") as Control
		if entry == null or not is_instance_valid(entry):
			continue
		var stack_child := _direct_detail_stack_child(scene, entry)
		if stack_child != null:
			indices[key.substr("fight:".length())] = stack_child.get_index()
	return indices


func _first_group_stack_index(scene: Node, group_name: String) -> int:
	var tree := scene.get_tree()
	if tree == null:
		return -1
	for raw_node in tree.get_nodes_in_group(group_name):
		var control := raw_node as Control
		if control == null or not is_instance_valid(control):
			continue
		var stack_child := _direct_detail_stack_child(scene, control)
		if stack_child != null:
			return stack_child.get_index()
	return -1


func _direct_detail_stack_child(scene: Node, control: Control) -> Control:
	if control == null or not is_instance_valid(control):
		return null
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll) or scroll.get_child_count() <= 0:
		return null
	var stack := scroll.get_child(0)
	var current := control
	while current != null and is_instance_valid(current):
		if current.get_parent() == stack:
			return current
		current = current.get_parent() as Control
	return null


func _press_first_page_switch_button(scene: Node) -> bool:
	var tree := scene.get_tree()
	if tree == null:
		return false
	for raw_node in tree.get_nodes_in_group("page_switch_buttons"):
		var button := raw_node as Button
		if button == null or not is_instance_valid(button) or not button.is_visible_in_tree():
			continue
		var position := button.get_global_rect().get_center()
		var target_skill_id := str(button.get_meta("page_switch_target_skill_id", ""))
		var press := InputEventMouseButton.new()
		press.button_index = MOUSE_BUTTON_LEFT
		press.pressed = true
		press.position = position
		press.global_position = position
		scene.call("_on_page_switch_button_gui_input", press, target_skill_id, button)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = position
		release.global_position = position
		scene.call("_on_page_switch_button_gui_input", release, target_skill_id, button)
		for _i in range(180):
			await _wait_test_frame()
			if str(scene.get("selected_skill_id")) != "fight":
				return true
		return str(scene.get("selected_skill_id")) != "fight"
	return false


func _find_named_descendant(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for raw_child in root_node.get_children():
		var child := raw_child as Node
		var found := _find_named_descendant(child, node_name)
		if found != null:
			return found
	return null


func _summary(scene: Node) -> String:
	var nav_bar := scene.get("nav_bar") as Control
	var nav_text := "none" if nav_bar == null else "visible=%s" % str(nav_bar.visible)
	return "screen=%s selected=%s tutorial=%s step=%s render=%s nav=%s" % [
		str(scene.get("current_screen")),
		str(scene.get("selected_skill_id")),
		str(scene.get("tutorial_active")),
		str(scene.get("tutorial_step")),
		str(scene.get("screen_render_in_progress")),
		nav_text
	]


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await _wait_test_frame()
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and not bool(scene.get("screen_render_in_progress"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_test_frame() -> void:
	await process_frame
	await create_timer(TEST_FRAME_SECONDS, true, false, true).timeout


func _fail(message: String) -> void:
	push_error("hard-reset-tutorial-flow-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "hard-reset-tutorial-flow-ok") "Hard reset tutorial flow test did not report success."

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the hard reset tutorial flow test."
    }
} finally {
    if ($hadSave) {
        Copy-Item -LiteralPath $backupPath -Destination $savePath -Force -ErrorAction SilentlyContinue
    } elseif (Test-Path -LiteralPath $savePath) {
        Remove-Item -LiteralPath $savePath -Force -ErrorAction SilentlyContinue
    }
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousBootSmoke) {
        Remove-Item Env:\IDLE_ELITE_HEADLESS_BOOT_SMOKE -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE = $previousBootSmoke
    }
    if ($null -eq $previousBootSmokeSeconds) {
        Remove-Item Env:\IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS = $previousBootSmokeSeconds
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
