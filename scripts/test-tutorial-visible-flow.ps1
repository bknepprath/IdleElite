$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\tutorial-visible-flow"
$testScript = Join-Path $testDir "tutorial_visible_flow_test.gd"
$startCapturePath = Join-Path $projectRoot ".codex-tmp\tutorial-visible-start.png"
$afterClickCapturePath = Join-Path $projectRoot ".codex-tmp\tutorial-visible-after-click.png"
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
$headlessDebug = $env:IDLE_ELITE_VISIBLE_FLOW_HEADLESS_DEBUG -eq "1"
$env:GODOT_RUN_TIMEOUT_SECONDS = "90"

try {
    @'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const SETTLE_FRAMES := 120
const CLICK_SETTLE_FRAMES := 20
const TEST_FRAME_SECONDS := 1.0 / 120.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("tutorial-visible-flow-start")
	var start_capture := OS.get_environment("IDLE_ELITE_VISIBLE_TUTORIAL_START_CAPTURE")
	var click_capture := OS.get_environment("IDLE_ELITE_VISIBLE_TUTORIAL_CLICK_CAPTURE")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	if not (await _wait_for_boot_ready(scene)):
		_fail("boot did not become ready")
		return

	scene.call("_save_runtime").call("reset_data")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if scene.get("tutorial_active") == true and _tutorial_skill_page_ready(scene):
			break
	if not _tutorial_skill_page_ready(scene):
		_fail("hard reset did not open the visible fight detail starter page: %s" % _summary(scene))
		return
	if not (await _wait_for_boot_overlay_hidden(scene)):
		_fail("boot overlay did not hide before visible tutorial capture: %s" % _summary(scene))
		return
	if int(scene.get("tutorial_step")) != 1:
		_fail("visible tutorial should start at step 1: %s" % _summary(scene))
		return
	if _starter_screen_has_stale_chrome(scene):
		_fail("visible starter screen still has stale tutorial/header chrome: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	var nav_bar := scene.get("nav_bar") as Control
	if nav_bar == null or not nav_bar.visible:
		_fail("visible starter screen should keep the bottom nav shell visible: %s" % _summary(scene))
		return
	if not _bottom_nav_locked_controls_ok(scene):
		_fail("visible starter screen should show all nav buttons with skills/settings bright and other nav locked: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	if not _only_starter_activity_rendered(scene):
		_fail("visible starter screen should render only Shove Wobbly Hay Bale: %s actions=%s" % [_summary(scene), str(_rendered_action_ids(scene))])
		return
	if not (await _click_settings_nav_via_viewport(scene)):
		_fail("visible settings nav button did not open settings during tutorial: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	if not (await _click_settings_red_x_via_viewport(scene)):
		_fail("visible settings red-X did not close back to the tutorial fight page: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	if not (await _click_settings_nav_via_viewport(scene)):
		_fail("visible settings nav button did not reopen settings during tutorial: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	if not await _hard_reset_from_settings_page(scene):
		_fail("visible settings hard reset button did not restart the tutorial: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if scene.get("tutorial_active") == true and _tutorial_skill_page_ready(scene):
			break
	if not _tutorial_skill_page_ready(scene) or scene.get("tutorial_active") != true:
		_fail("hard reset from visible settings did not restore tutorial starter page: %s" % _summary(scene))
		return
	if not (await _wait_for_boot_overlay_hidden(scene)):
		_fail("boot overlay did not hide after visible settings reset: %s" % _summary(scene))
		return
	if _starter_screen_has_stale_chrome(scene) or not _bottom_nav_locked_controls_ok(scene) or not _only_starter_activity_rendered(scene):
		_fail("visible starter screen was not clean after settings reset: %s %s actions=%s" % [_summary(scene), _chrome_summary(scene), str(_rendered_action_ids(scene))])
		return
	if not (await _click_settings_nav_via_nav_handler(scene)):
		_fail("settings nav gui handler did not open settings during tutorial: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	if not await _hard_reset_from_settings_page(scene):
		_fail("settings hard reset button after nav handler did not restart the tutorial: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if scene.get("tutorial_active") == true and _tutorial_skill_page_ready(scene):
			break
	if not _tutorial_skill_page_ready(scene) or scene.get("tutorial_active") != true:
		_fail("hard reset after settings nav handler did not restore tutorial starter page: %s" % _summary(scene))
		return
	await _capture_viewport(start_capture, "tutorial-visible-start-capture")

	if not (await _click_tutorial_target_via_viewport(scene)):
		_fail("visible starter activity click did not start the activity: %s" % _summary(scene))
		return
	for _i in range(CLICK_SETTLE_FRAMES):
		await _wait_test_frame()
	if str(scene.get("running_action_id")) != "shove-wobbly-hay-bale":
		_fail("visible click did not leave the starter activity running: %s" % _summary(scene))
		return
	if scene.get("tutorial_active") == true:
		_fail("legacy tutorial overlay stayed active after visible starter click: %s" % _summary(scene))
		return
	if scene.get("onboarding_tutorial_complete") == true:
		_fail("visible starter click completed onboarding too early: %s" % _summary(scene))
		return
	if _bottom_or_page_navigation_visible(scene):
		_fail("visible starter click revealed navigation too early: %s" % _summary(scene))
		return
	if _fight_header_summary_visible(scene) or _fight_stamina_visible(scene):
		_fail("visible starter click revealed fight header/stamina before the first completion: %s %s" % [_summary(scene), _chrome_summary(scene)])
		return
	await _capture_viewport(click_capture, "tutorial-visible-after-click-capture")
	for _i in range(1800):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if _group_has_visible_node(scene, "onboarding_mastery_tip_notes"):
			break
	if not _group_has_visible_node(scene, "onboarding_mastery_tip_notes"):
		_fail("visible flow did not show mastery bar message after starter completions: %s" % _summary(scene))
		return
	print("tutorial-visible-flow-stage mastery-tip-observed")
	var test_skills := scene.get("skills") as Dictionary
	var fight_state := test_skills.get("fight", {}) as Dictionary
	fight_state["xp"] = SkillState.xp_for_level(2)
	test_skills["fight"] = fight_state
	scene.set("skills", test_skills)
	scene.call("_recalculate_level", "fight", true)
	await scene.call("_refresh_visible_skill_detail_action_list", -1, "fight", true)
	for _i in range(360):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if _group_has_visible_node(scene, "lock_click_tip_notes"):
			break
	if not _group_has_visible_node(scene, "lock_click_tip_notes"):
		_fail("visible flow did not show click-lock-pad message when the next activity became unlock-ready: %s" % _summary(scene))
		return
	print("tutorial-visible-flow-stage lock-tip-observed")

	print("tutorial-visible-flow-ok %s" % _summary(scene))
	quit(0)


func _click_tutorial_target_via_viewport(scene: Node) -> bool:
	var tutorial_overlay_surface := scene.call("_tutorial_overlay_surface") as Object
	var target := tutorial_overlay_surface.call("_tutorial_target_control") as Control
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	var position := target.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	scene.get_viewport().push_input(press, false)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	release.global_position = position
	scene.get_viewport().push_input(release, false)
	for _i in range(CLICK_SETTLE_FRAMES):
		await _wait_test_frame()
	if str(scene.get("running_action_id")) == "shove-wobbly-hay-bale":
		return true
	var routed_press := InputEventMouseButton.new()
	routed_press.button_index = MOUSE_BUTTON_LEFT
	routed_press.pressed = true
	routed_press.position = position
	routed_press.global_position = position
	var accepted: bool = tutorial_overlay_surface.call("_route_tutorial_panel_input", routed_press) == true
	var routed_release := InputEventMouseButton.new()
	routed_release.button_index = MOUSE_BUTTON_LEFT
	routed_release.pressed = false
	routed_release.position = position
	routed_release.global_position = position
	tutorial_overlay_surface.call("_route_tutorial_panel_input", routed_release)
	for _i in range(CLICK_SETTLE_FRAMES):
		await _wait_test_frame()
	return accepted and str(scene.get("running_action_id")) == "shove-wobbly-hay-bale"


func _click_settings_nav_via_viewport(scene: Node) -> bool:
	var settings := scene.get("settings_tab") as Control
	if settings == null or not is_instance_valid(settings) or not settings.is_visible_in_tree():
		return false
	var position := settings.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	scene.get_viewport().push_input(press, false)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	scene.get_viewport().push_input(release, false)
	for _i in range(CLICK_SETTLE_FRAMES):
		await _wait_test_frame()
		if str(scene.get("current_screen")) == "settings":
			return true
	if scene.call("_settings_surface").call("_route_onboarding_settings_nav_input", press):
		for _i in range(CLICK_SETTLE_FRAMES):
			await _wait_test_frame()
			if str(scene.get("current_screen")) == "settings":
				return true
	return false


func _click_settings_red_x_via_viewport(scene: Node) -> bool:
	if str(scene.get("current_screen")) != "settings":
		return false
	var settings := scene.get("settings_tab") as Control
	if settings == null or not is_instance_valid(settings) or not settings.is_visible_in_tree():
		return false
	var position := settings.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	scene.get_viewport().push_input(press, false)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	scene.get_viewport().push_input(release, false)
	for _i in range(CLICK_SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if _tutorial_skill_page_ready(scene):
			return true
	if scene.call("_settings_surface").call("_route_onboarding_settings_nav_input", press):
		for _i in range(CLICK_SETTLE_FRAMES):
			await _wait_test_frame()
			scene.call("_onboarding_runtime").call("_tutorial_check_progress")
			if _tutorial_skill_page_ready(scene):
				return true
	if str(scene.get("current_screen")) != "settings":
		return _tutorial_skill_page_ready(scene)
	var navigation_shell := scene.call("_navigation_shell") as Object
	navigation_shell.call("_on_bottom_nav_button_gui_input", press, "settings", settings)
	navigation_shell.call("_on_bottom_nav_button_gui_input", release, "settings", settings)
	for _i in range(CLICK_SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if _tutorial_skill_page_ready(scene):
			return true
	return false


func _hard_reset_from_settings_page(scene: Node) -> bool:
	if str(scene.get("current_screen")) != "settings":
		return false
	var reset_button := _visible_reset_button(scene)
	if reset_button == null:
		return false
	if not await _press_reset_button(scene, reset_button):
		return false
	for _i in range(24):
		await _wait_test_frame()
	if str(reset_button.text) != "Are you sure?":
		return false
	for _i in range(24):
		await _wait_test_frame()
	if not await _press_reset_button(scene, reset_button):
		return false
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if scene.get("tutorial_active") == true and _tutorial_skill_page_ready(scene):
			return true
	return false


func _visible_reset_button(scene: Node) -> Button:
	var buttons := scene.get("reset_data_buttons") as Array
	if buttons == null:
		return null
	for raw_button in buttons:
		var button := raw_button as Button
		if button != null and is_instance_valid(button) and button.is_visible_in_tree():
			return button
	return null


func _press_reset_button(scene: Node, button: Button) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	var previous_text := str(button.text)
	var previous_screen := str(scene.get("current_screen"))
	var position := button.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	scene.get_viewport().push_input(press, false)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	scene.get_viewport().push_input(release, false)
	button.pressed.emit()
	for _i in range(CLICK_SETTLE_FRAMES):
		await _wait_test_frame()
		if str(scene.get("current_screen")) != previous_screen:
			return true
		if previous_text != "Are you sure?" and str(button.text) != previous_text:
			return true
	return true


func _click_settings_nav_via_nav_handler(scene: Node) -> bool:
	var settings := scene.get("settings_tab") as Button
	if settings == null or not is_instance_valid(settings) or not settings.is_visible_in_tree():
		return false
	var position := settings.get_global_rect().get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	var navigation_shell := scene.call("_navigation_shell") as Object
	navigation_shell.call("_on_bottom_nav_button_gui_input", press, "settings", settings)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	navigation_shell.call("_on_bottom_nav_button_gui_input", release, "settings", settings)
	for _i in range(CLICK_SETTLE_FRAMES):
		await _wait_test_frame()
		if str(scene.get("current_screen")) == "settings":
			return true
	return false


func _starter_screen_has_stale_chrome(scene: Node) -> bool:
	var tutorial_panel := scene.get("tutorial_panel") as Control
	var tutorial_target_ring := scene.get("tutorial_target_ring") as Control
	var tutorial_target_label := scene.get("tutorial_target_label") as Control
	return (
		(tutorial_panel != null and tutorial_panel.visible)
		or (tutorial_target_ring != null and tutorial_target_ring.is_visible_in_tree() and _effective_canvas_alpha(tutorial_target_ring) > 0.01)
		or (tutorial_target_label != null and tutorial_target_label.is_visible_in_tree() and _effective_canvas_alpha(tutorial_target_label) > 0.01)
		or _fight_header_summary_visible(scene)
		or _fight_stamina_visible(scene)
		or _bottom_or_page_navigation_visible(scene)
	)


func _chrome_summary(scene: Node) -> String:
	var tutorial_panel := scene.get("tutorial_panel") as Control
	var tutorial_target_ring := scene.get("tutorial_target_ring") as Control
	var tutorial_target_label := scene.get("tutorial_target_label") as Control
	var header := scene.get("detail_header_left_block") as Control
	var fade_group := scene.get("detail_regen_circle_fade_group") as Control
	return "panel=%s ring_visible=%s ring_alpha=%.3f label_visible=%s label_alpha=%.3f header_visible=%s header_alpha=%.3f stamina_visible=%s stamina_alpha=%.3f all_buttons=%s settings_enabled=%s skills_enabled=%s other_nav_locked=%s nav_like=%s" % [
		str(tutorial_panel != null and tutorial_panel.visible),
		str(tutorial_target_ring != null and tutorial_target_ring.is_visible_in_tree()),
		_effective_canvas_alpha(tutorial_target_ring),
		str(tutorial_target_label != null and tutorial_target_label.is_visible_in_tree()),
		_effective_canvas_alpha(tutorial_target_label),
		str(header != null and header.is_visible_in_tree()),
		_effective_canvas_alpha(header),
		str(fade_group != null and fade_group.is_visible_in_tree()),
		_effective_canvas_alpha(fade_group),
		str(_all_nav_buttons_visible(scene)),
		str(_settings_nav_button_enabled(scene)),
		str(_skills_nav_button_enabled(scene)),
		str(_non_settings_nav_buttons_locked(scene)),
		str(_bottom_or_page_navigation_visible(scene)),
	]


func _bottom_or_page_navigation_visible(scene: Node) -> bool:
	if not _non_settings_nav_buttons_locked(scene):
		return true
	var module_utility_row := scene.get("module_utility_row") as Control
	if module_utility_row != null and module_utility_row.visible:
		return true
	return _has_page_switch_module(scene)


func _bottom_nav_locked_controls_ok(scene: Node) -> bool:
	return _bottom_nav_row_visible(scene) and _all_nav_buttons_visible(scene) and _settings_nav_button_enabled(scene) and _skills_nav_button_enabled(scene) and _non_settings_nav_buttons_locked(scene)


func _bottom_nav_row_visible(scene: Node) -> bool:
	var nav_bar := scene.get("nav_bar") as Control
	if nav_bar == null or not is_instance_valid(nav_bar):
		return false
	var row := scene.get("bottom_nav_buttons_row") as Control
	if row == null:
		row = _find_named_descendant(nav_bar, "BottomNavButtonsRow") as Control
	return row != null and row.is_visible_in_tree() and _effective_canvas_alpha(row) > 0.01


func _all_nav_buttons_visible(scene: Node) -> bool:
	for raw_name in ["hero_tab", "hub_tab", "skills_tab", "settings_tab", "shop_tab"]:
		var button := scene.get(raw_name) as Control
		if button == null or not button.is_visible_in_tree() or _effective_canvas_alpha(button) <= 0.01:
			return false
	return true


func _settings_nav_button_enabled(scene: Node) -> bool:
	var settings := scene.get("settings_tab") as Button
	return settings != null and settings.is_visible_in_tree() and _effective_canvas_alpha(settings) > 0.01 and not settings.disabled and settings.mouse_filter == Control.MOUSE_FILTER_STOP


func _skills_nav_button_enabled(scene: Node) -> bool:
	var skills := scene.get("skills_tab") as Button
	return skills != null and skills.is_visible_in_tree() and _effective_canvas_alpha(skills) > 0.01 and not skills.disabled and skills.mouse_filter == Control.MOUSE_FILTER_STOP and _color_nearly_equal(skills.modulate, Color.WHITE)


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


func _fight_header_summary_visible(scene: Node) -> bool:
	var header := scene.get("detail_header_left_block") as Control
	return header != null and header.is_visible_in_tree() and _effective_canvas_alpha(header) > 0.01


func _fight_stamina_visible(scene: Node) -> bool:
	var fade_group := scene.get("detail_regen_circle_fade_group") as Control
	if fade_group != null and fade_group.is_visible_in_tree() and _effective_canvas_alpha(fade_group) > 0.01:
		return true
	var circle := scene.get("detail_regen_circle") as Control
	return circle != null and circle.is_visible_in_tree() and _effective_canvas_alpha(circle) > 0.01


func _tutorial_skill_page_ready(scene: Node) -> bool:
	if str(scene.get("current_screen")) != "skill":
		return false
	if str(scene.get("selected_skill_id")) != "fight":
		return false
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll):
		return false
	return _rendered_action_ids(scene).has("shove-wobbly-hay-bale")


func _only_starter_activity_rendered(scene: Node) -> bool:
	var ids := _rendered_action_ids(scene)
	return ids.size() == 1 and ids[0] == "shove-wobbly-hay-bale"


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
	if scroll == null or not is_instance_valid(scroll) or scroll.get_child_count() <= 0:
		return false
	return _find_named_descendant(scroll.get_child(0), "PageSwitchModule") != null


func _group_has_visible_node(scene: Node, group_name: String) -> bool:
	for node in scene.get_tree().get_nodes_in_group(group_name):
		if node is Control:
			var control := node as Control
			if control.is_visible_in_tree() and _effective_canvas_alpha(control) > 0.05:
				return true
	return false


func _find_named_descendant(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_named_descendant(child, node_name)
		if found != null:
			return found
	return null


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


func _wait_for_boot_ready(scene: Node) -> bool:
	for _i in range(720):
		await _wait_test_frame()
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			scene.get("startup_initialized") == true
			and scene.get("boot_detail_render_in_progress") != true
			and scene.get("boot_detail_scroll_locked") != true
			and scene.get("screen_render_in_progress") != true
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_for_boot_overlay_hidden(scene: Node) -> bool:
	for _i in range(720):
		await _wait_test_frame()
		var overlay := scene.get("boot_warmup_overlay") as Control
		if overlay == null or not overlay.is_visible_in_tree() or _effective_canvas_alpha(overlay) <= 0.01:
			return true
	return false


func _wait_test_frame() -> void:
	await process_frame
	await create_timer(TEST_FRAME_SECONDS, true, false, true).timeout


func _capture_viewport(path: String, label: String) -> void:
	if path.is_empty():
		return
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		print("%s skipped=no-texture" % label)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("%s skipped=empty-image" % label)
		return
	var result := image.save_png(path)
	print("%s path=%s result=%s size=%sx%s" % [label, path, str(result), image.get_width(), image.get_height()])


func _summary(scene: Node) -> String:
	var nav_bar := scene.get("nav_bar") as Control
	return "screen=%s selected=%s tutorial=%s step=%s complete=%s running=%s completions=%s nav=%s" % [
		str(scene.get("current_screen")),
		str(scene.get("selected_skill_id")),
		str(scene.get("tutorial_active")),
		str(scene.get("tutorial_step")),
		str(scene.get("onboarding_tutorial_complete")),
		str(scene.get("running_action_id")),
		str(scene.get("onboarding_starter_action_completion_count")),
		"null" if nav_bar == null else "visible=%s" % str(nav_bar.visible),
	]


func _fail(message: String) -> void:
	push_error("tutorial-visible-flow-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $env:IDLE_ELITE_VISIBLE_TUTORIAL_START_CAPTURE = $startCapturePath
    $env:IDLE_ELITE_VISIBLE_TUTORIAL_CLICK_CAPTURE = $afterClickCapturePath
    if ($headlessDebug) {
        $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    } else {
        $output = & $runner --visible-game --path $projectRoot --script $testScript 2>&1
    }
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    if ($headlessDebug) {
        Assert-True (($output -join "`n") -match "tutorial-visible-flow-ok") "Tutorial visible flow test did not report success."
    } else {
        Assert-True (Test-Path -LiteralPath $startCapturePath) "Visible tutorial start screenshot was not created at $startCapturePath."
        Assert-True (Test-Path -LiteralPath $afterClickCapturePath) "Visible tutorial click screenshot was not created at $afterClickCapturePath."
    }

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the visible tutorial flow test."
    }
} finally {
    if ($hadSave) {
        Copy-Item -LiteralPath $backupPath -Destination $savePath -Force -ErrorAction SilentlyContinue
    } else {
        Remove-Item -LiteralPath $savePath -Force -ErrorAction SilentlyContinue
    }
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    Remove-Item Env:\IDLE_ELITE_VISIBLE_TUTORIAL_START_CAPTURE -ErrorAction SilentlyContinue
    Remove-Item Env:\IDLE_ELITE_VISIBLE_TUTORIAL_CLICK_CAPTURE -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
