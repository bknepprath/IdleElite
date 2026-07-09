$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\hard-reset-tutorial-flow"
$testScript = Join-Path $testDir "hard_reset_tutorial_flow_test.gd"
$savePath = Join-Path $env:APPDATA "Godot\app_userdata\Idle Elite\idle_elite_save.json"
$saveBackupPath = Join-Path $env:APPDATA "Godot\app_userdata\Idle Elite\idle_elite_save.backup.json"
$backupPath = Join-Path $testDir "idle_elite_save.backup.json"
$backupSaveBackupPath = Join-Path $testDir "idle_elite_save.backup.backup.json"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$hadSave = Test-Path -LiteralPath $savePath
if ($hadSave) {
    Copy-Item -LiteralPath $savePath -Destination $backupPath -Force
    Remove-Item -LiteralPath $savePath -Force
}
$hadSaveBackup = Test-Path -LiteralPath $saveBackupPath
if ($hadSaveBackup) {
    Copy-Item -LiteralPath $saveBackupPath -Destination $backupSaveBackupPath -Force
    Remove-Item -LiteralPath $saveBackupPath -Force
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

const SkillState := preload("res://scripts/progression/skill_state.gd")

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

	scene.call("_settings_surface").call("_show_settings")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
	if str(scene.get("current_screen")) != "settings":
		_fail("settings screen did not open before reset: %s" % _summary(scene))
		return

	scene.call("_save_runtime").call("reset_data")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if bool(scene._onboarding_runtime().tutorial_active) and _tutorial_skill_page_ready(scene):
			break

	if not bool(scene._onboarding_runtime().tutorial_active):
		_fail("hard reset did not restart tutorial: %s" % _summary(scene))
		return
	if not _tutorial_skill_page_ready(scene):
		_fail("hard reset should start on fight detail page, not the skill menu: %s" % _summary(scene))
		return
	if int(scene._onboarding_runtime().tutorial_step) != 1:
		_fail("hard reset tutorial should start on the fight activity step: %s" % _summary(scene))
		return
	var nav_bar := _bottom_nav_bar(scene)
	if nav_bar == null or not nav_bar.visible:
		_fail("hard reset tutorial should keep the bottom nav shell visible: %s" % _summary(scene))
		return
	if not _bottom_nav_locked_controls_ok(scene):
		_fail("hard reset tutorial should show all nav buttons with skills/settings bright and other nav locked: %s %s" % [_summary(scene), _bottom_nav_summary(scene)])
		return
	var tutorial_panel := scene.get("tutorial_panel") as Control
	if tutorial_panel != null and tutorial_panel.visible:
		_fail("hard reset tutorial should use the inline activity target instead of the legacy blocking tutorial modal: %s" % _summary(scene))
		return
	if _floating_skip_button_visible(scene):
		_fail("hard reset tutorial should not show a SKIP button: %s" % _summary(scene))
		return
	if not _only_starter_activity_rendered(scene):
		_fail("hard reset tutorial should render only Shove Wobbly Hay Bale: %s actions=%s" % [_summary(scene), str(_rendered_action_ids(scene))])
		return
	print("hard-reset-tutorial-flow-stage starter-ready")

	if not _press_tutorial_target(scene):
		_fail("hard reset tutorial target press was not accepted: %s" % _summary(scene))
		return
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		var active_panel := scene.get("tutorial_panel") as Control
		if not str(scene.get("running_action_id")).is_empty() and active_panel != null and not active_panel.visible:
			break
	if str(scene.get("running_action_id")).is_empty():
		_fail("hard reset tutorial did not start the first fight activity after target tap: %s" % _summary(scene))
		return
	tutorial_panel = scene.get("tutorial_panel") as Control
	if tutorial_panel != null and tutorial_panel.visible:
		_fail("blocking tutorial modal should dismiss after the target tap: %s" % _summary(scene))
		return
	for _i in range(900):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if bool(scene._onboarding_runtime().onboarding_tutorial_complete) and not bool(scene._onboarding_runtime().tutorial_active):
			break
	if bool(scene._onboarding_runtime().tutorial_active):
		_fail("tutorial should complete after the first successful activity and arrow exit: %s" % _summary(scene))
		return
	if not bool(scene._onboarding_runtime().onboarding_tutorial_complete):
		_fail("first successful activity should complete onboarding after following the instruction: %s" % _summary(scene))
		return
	print("hard-reset-tutorial-flow-ok %s" % _summary(scene))
	quit(0)
	var test_skills := scene.get("skills") as Dictionary
	var fight_state := test_skills.get("fight", {}) as Dictionary
	fight_state["xp"] = SkillState.xp_for_level(2)
	test_skills["fight"] = fight_state
	scene.set("skills", test_skills)
	SkillState.recalculate_level(scene, "fight", true)
	var lock_tip_refresh = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, "fight", true)
	if lock_tip_refresh != null:
		await lock_tip_refresh
	for _i in range(360):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
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
	if not _lock_click_tip_visible(scene) or bool(scene._onboarding_runtime().lock_click_tip_seen):
		_fail("click-lock tutorial message disappeared before the lock was clicked: %s %s" % [_summary(scene), _onboarding_tip_summary(scene)])
		return
	var unlock_ceremony_surface := scene.call("_activity_unlock_ceremony_surface") as Object
	if not bool(unlock_ceremony_surface.call("_tutorial_level_two_unlock_should_use_fast_reveal", "fight", "kick-mud-off-boot")):
		_fail("level 2 tutorial module unlock should use the smooth fast reveal path")
		return
	if bool(unlock_ceremony_surface.call("_tutorial_level_two_unlock_should_use_fast_reveal", "fight", "wrestle-stuck-gate-latch")):
		_fail("only the level 2 tutorial module should use the fast reveal path")
		return
	scene.call("_settings_surface").call("toggle_auto_unlock_lockpads_enabled")
	for _i in range(240):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
	if not bool(scene.get("auto_unlock_lockpads_enabled")):
		_fail("auto-unlock toggle did not turn on during onboarding: %s" % _summary(scene))
		return
	var level_two_action := scene.call("_action_data", "fight", "kick-mud-off-boot") as Dictionary
	if bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", level_two_action)):
		_fail("auto-unlock should be paused during onboarding and must not unlock Kick Mud Off Boot: %s actions=%s" % [_summary(scene), str(_rendered_action_ids(scene))])
		return
	var rendered_after_auto_toggle := _rendered_action_ids(scene)
	if rendered_after_auto_toggle.has("wrestle-stuck-gate-latch") or rendered_after_auto_toggle.has("box-suspicious-feed-sack"):
		_fail("auto-unlock during onboarding revealed stacked future locks: %s" % str(rendered_after_auto_toggle))
		return
	if not _lock_click_tip_visible(scene):
		_fail("auto-unlock during onboarding hid the lock-click tutorial tip before the player clicked the lock: %s" % _summary(scene))
		return
	scene.set("auto_unlock_lockpads_enabled", false)
	print("hard-reset-tutorial-flow-stage starter-run-observed")
	var manual_unlocks := scene.get("manual_activity_unlocks") as Dictionary
	manual_unlocks["fight:kick-mud-off-boot"] = true
	scene.set("manual_activity_unlocks", manual_unlocks)
	scene._onboarding_runtime().tutorial_gate_latch_only_until_swipe = true
	unlock_ceremony_surface.ceremony_count = 0
	unlock_ceremony_surface.locked_preview_fade_play_pending = false
	scene._onboarding_runtime().stamina_gauge_tip_seen = true
	scene._onboarding_runtime().onboarding_fight_action_stats_revealed = true
	var test_stamina := scene.get("stamina") as Dictionary
	test_stamina["fight"] = SkillState.max_stamina(scene, "fight")
	scene.set("stamina", test_stamina)
	var onboarding_runtime := scene.call("_onboarding_runtime") as Object
	onboarding_runtime.call("_maybe_trigger_onboarding_swipe_tip_at_zero_stamina", "fight")
	var swipe_tip_refresh = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, "fight", true)
	if swipe_tip_refresh != null:
		await swipe_tip_refresh
	for _i in range(720):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if _has_page_switch_module(scene) and _skill_swipe_tip_between_level_two_and_three(scene):
			break
	if not _has_page_switch_module(scene):
		_fail("page-switch navigation did not appear when the swipe tutorial gate became available before stamina depletion: %s" % _summary(scene))
		return
	if not bool(scene._onboarding_runtime().onboarding_swipe_navigation_unlocked):
		_fail("page-switch navigation appeared before onboarding swipe navigation was unlocked by the gate prompt: %s" % _summary(scene))
		return
	if not _skill_swipe_tip_between_level_two_and_three(scene):
		_fail("skill-swipe tutorial line was not placed between the level 2 and level 3 fight modules: %s tip_index=%s action_indices=%s" % [_summary(scene), str(_first_group_stack_index(scene, "skill_swipe_tip_notes")), str(_fight_action_stack_indices(scene))])
		return
	if not await _stale_page_switch_input_clears_on_suspend(scene):
		_fail("stale page-switch input state kept stealing normal activity taps after suspend/resume: %s" % _summary(scene))
		return
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
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
	if not bool(scene._onboarding_runtime().skill_swipe_tip_seen):
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
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if _tutorial_skill_page_ready(scene):
			break
	if bool(scene._onboarding_runtime().tutorial_active):
		_fail("mid-tutorial save should not restore the legacy boxed tutorial overlay: %s" % _summary(scene))
		return
	if not _tutorial_skill_page_ready(scene):
		_fail("mid-tutorial save did not restore to fight detail: %s" % _summary(scene))
		return
	if bool(scene._onboarding_runtime().onboarding_tutorial_complete):
		_fail("mid-tutorial save should keep onboarding incomplete: %s" % _summary(scene))
		return
	print("hard-reset-tutorial-flow-stage reload-ok")

	onboarding_runtime = scene.call("_onboarding_runtime") as Object
	onboarding_runtime.call("_graduate_onboarding_tutorial")
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

	scene.call("_save_runtime").call("reset_data")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if bool(scene._onboarding_runtime().tutorial_active) and _tutorial_skill_page_ready(scene):
			break
	if not bool(scene._onboarding_runtime().tutorial_active) or int(scene._onboarding_runtime().tutorial_step) != 1:
		_fail("hard reset after completed tutorial did not restart a fresh tutorial: %s" % _summary(scene))
		return
	if not _tutorial_skill_page_ready(scene):
		_fail("hard reset after completion should return to fight detail: %s" % _summary(scene))
		return
	var reset_nav := _bottom_nav_bar(scene)
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
	var accepted := bool(tutorial_overlay_surface.call("_route_tutorial_panel_input", press))
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	tutorial_overlay_surface.call("_route_tutorial_panel_input", release)
	return accepted


func _press_tutorial_start_button(scene: Node) -> bool:
	var tutorial_overlay_surface := scene.call("_tutorial_overlay_surface") as Object
	if tutorial_overlay_surface == null:
		return false
	var button := tutorial_overlay_surface.get("tutorial_action_button") as Button
	if button == null or not is_instance_valid(button) or not button.is_visible_in_tree():
		return false
	button.pressed.emit()
	return true


func _tutorial_completion_visible(scene: Node) -> bool:
	if bool(scene._onboarding_runtime().tutorial_active):
		return false
	if not bool(scene._onboarding_runtime().onboarding_tutorial_complete):
		return false
	var nav_bar := _bottom_nav_bar(scene)
	return nav_bar != null and nav_bar.visible and _bottom_nav_post_tutorial_controls_ok(scene)


func _completion_bottom_chrome_state_ok(scene: Node) -> bool:
	var utility_row := _module_utility_row(scene)
	var chat_strip := scene.get("chat_strip") as Control
	var collapsed := _module_utility_collapsed(scene)
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
	var utility_row := _module_utility_row(scene)
	var chat_strip := scene.get("chat_strip") as Control
	if utility_row == null or chat_strip == null:
		return false
	if not utility_row.visible or not chat_strip.visible:
		return false
	if not _module_utility_collapsed(scene):
		return false
	var utility_alpha := _effective_canvas_alpha(utility_row)
	var chat_alpha := _effective_canvas_alpha(chat_strip)
	return utility_alpha >= 0.0 and utility_alpha < 0.98 and chat_alpha >= 0.0 and chat_alpha < 0.98


func _module_utility_row(scene: Node) -> Control:
	var navigation_shell := scene.call("_navigation_shell") as Object
	if navigation_shell == null:
		return null
	return navigation_shell.get("module_utility_row") as Control


func _bottom_nav_bar(scene: Node) -> Control:
	var navigation_shell := scene.call("_navigation_shell") as Object
	if navigation_shell == null:
		return null
	return navigation_shell.get("nav_bar") as Control


func _bottom_nav_buttons_row(scene: Node) -> Control:
	var navigation_shell := scene.call("_navigation_shell") as Object
	if navigation_shell == null:
		return null
	return navigation_shell.get("bottom_nav_buttons_row") as Control


func _bottom_nav_button(scene: Node, name: String) -> Button:
	if name == "skills_tab" or name == "settings_tab":
		return scene.get(name) as Button
	var navigation_shell := scene.call("_navigation_shell") as Object
	if navigation_shell == null:
		return null
	return navigation_shell.get(name) as Button


func _module_utility_collapsed(scene: Node) -> bool:
	var navigation_shell := scene.call("_navigation_shell") as Object
	return navigation_shell != null and bool(navigation_shell.get("module_utility_collapsed"))


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
		var button := _bottom_nav_button(scene, raw_name) as Control
		if button == null or not button.is_visible_in_tree() or _effective_canvas_alpha(button) <= 0.01:
			return false
	return true


func _bottom_nav_row_visible(scene: Node) -> bool:
	var nav_bar := _bottom_nav_bar(scene)
	if nav_bar == null or not is_instance_valid(nav_bar):
		return false
	var row := _bottom_nav_buttons_row(scene)
	if row == null:
		row = _find_named_descendant(nav_bar, "BottomNavButtonsRow") as Control
	return row != null and row.is_visible_in_tree() and _effective_canvas_alpha(row) > 0.01


func _settings_nav_button_enabled(scene: Node) -> bool:
	var settings := _bottom_nav_button(scene, "settings_tab")
	return settings != null and settings.is_visible_in_tree() and _effective_canvas_alpha(settings) > 0.01 and not settings.disabled and settings.mouse_filter == Control.MOUSE_FILTER_STOP


func _skills_nav_button_enabled(scene: Node) -> bool:
	var skills := _bottom_nav_button(scene, "skills_tab")
	return skills != null and skills.is_visible_in_tree() and _effective_canvas_alpha(skills) > 0.01 and not skills.disabled and skills.mouse_filter == Control.MOUSE_FILTER_STOP and _color_nearly_equal(skills.modulate, Color.WHITE)


func _fresh_game_locked_nav_buttons_ok(scene: Node) -> bool:
	for raw_name in ["hero_tab", "hub_tab", "shop_tab"]:
		var button := _bottom_nav_button(scene, raw_name)
		if button == null or not button.is_visible_in_tree() or _effective_canvas_alpha(button) <= 0.01:
			return false
		if button.disabled or button.mouse_filter != Control.MOUSE_FILTER_STOP:
			return false
		if not _color_nearly_equal(button.modulate, Color("#3f3f3f")):
			return false
	return true


func _non_settings_nav_buttons_locked(scene: Node) -> bool:
	for raw_name in ["hero_tab", "hub_tab", "shop_tab"]:
		var button := _bottom_nav_button(scene, raw_name)
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
	var nav_bar := _bottom_nav_bar(scene)
	var row := _bottom_nav_buttons_row(scene)
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
		str(scene._onboarding_runtime().onboarding_tutorial_complete),
		str(scene._onboarding_runtime().tutorial_active),
	]


func _bottom_chrome_summary(scene: Node) -> String:
	var utility_row := _module_utility_row(scene)
	var chat_strip := scene.get("chat_strip") as Control
	return "utility_present=%s utility_visible=%s utility_alpha=%.3f chat_present=%s chat_visible=%s chat_alpha=%.3f collapsed=%s" % [
		str(utility_row != null),
		str(utility_row != null and utility_row.visible),
		_effective_canvas_alpha(utility_row),
		str(chat_strip != null),
		str(chat_strip != null and chat_strip.visible),
		_effective_canvas_alpha(chat_strip),
		str(_module_utility_collapsed(scene)),
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
	var fade_group := scene._skill_detail_surface().detail_regen_circle_fade_group as Control
	if fade_group != null and fade_group.is_visible_in_tree() and _effective_canvas_alpha(fade_group) > 0.01:
		return true
	var circle := scene._skill_detail_surface().detail_regen_circle as Control
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


func _tutorial_start_actions_rendered(scene: Node) -> bool:
	var ids := _rendered_action_ids(scene)
	return ids.has("shove-wobbly-hay-bale") and ids.has("kick-mud-off-boot")


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
	scene.call("_input_routing_shell").call("_route_activity_lock_input", motion)
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


func _group_has_skip_button(scene: Node, group_name: String) -> bool:
	var tree := scene.get_tree()
	if tree == null:
		return false
	for raw_node in tree.get_nodes_in_group(group_name):
		var control := raw_node as Control
		if control == null or not is_instance_valid(control):
			continue
		for child in control.get_children():
			var button := child as Button
			if button != null and is_instance_valid(button) and button.is_visible_in_tree() and str(button.text) == "SKIP":
				return true
	return false


func _floating_skip_button_visible(scene: Node) -> bool:
	var button := scene.get("tutorial_skip_button") as Button
	return (
		button != null
		and is_instance_valid(button)
		and button.is_visible_in_tree()
		and str(button.text) == "SKIP"
	)


func _onboarding_tip_summary(scene: Node) -> String:
	return "starter_count=%s fight_level=%s fight_xp=%s mastery_tip=%s medal_tip=%s lock_tip=%s stats_revealed=%s stamina_seen=%s header=%s stamina=%s header_running=%s stamina_running=%s stats_running=%s rendered=%s" % [
		str(scene._onboarding_runtime().onboarding_starter_action_completion_count),
		str(scene.call("_skill_level", "fight")),
		str((scene.get("skills") as Dictionary).get("fight", {}).get("xp", "?")),
		str(_mastery_tip_visible(scene)),
		str(_group_has_visible_node(scene, "onboarding_medal_tip_notes")),
		str(_lock_click_tip_visible(scene)),
		str(scene._onboarding_runtime().onboarding_fight_action_stats_revealed),
		str(scene._onboarding_runtime().stamina_gauge_tip_seen),
		str(_fight_header_summary_visible(scene)),
		str(_fight_stamina_visible(scene)),
		str(scene._onboarding_runtime().onboarding_header_sequence_running),
		str(scene._onboarding_runtime().onboarding_stamina_tip_sequence_running),
		str(scene._onboarding_runtime().onboarding_fight_action_stats_fade_running),
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
	var scroll := scene._skill_detail_surface().detail_actions_scroll as ScrollContainer
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
	var scroll := scene._skill_detail_surface().detail_actions_scroll as ScrollContainer
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
		scene.call("_navigation_shell").call("_on_page_switch_button_gui_input", press, target_skill_id, button)
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = position
		release.global_position = position
		scene.call("_navigation_shell").call("_on_page_switch_button_gui_input", release, target_skill_id, button)
		for _i in range(180):
			await _wait_test_frame()
			if str(scene.get("selected_skill_id")) != "fight":
				return true
		return str(scene.get("selected_skill_id")) != "fight"
	return false


func _stale_page_switch_input_clears_on_suspend(scene: Node) -> bool:
	var button := _first_page_switch_button(scene)
	if button == null:
		return false
	var button_center := button.get_global_rect().get_center()
	var navigation_shell = scene.call("_navigation_shell")
	navigation_shell.set("page_switch_press_active", true)
	navigation_shell.set("page_switch_press_target_skill_id", str(button.get_meta("page_switch_target_skill_id", "")))
	navigation_shell.set("page_switch_press_position", button_center)
	navigation_shell.set("page_switch_press_dragged", false)
	button.set_meta("page_switch_press_active", true)
	button.set_meta("page_switch_press_position", button_center)
	button.set_meta("page_switch_press_dragged", false)
	button.set_meta("activity_button_hold_nav_press", true)
	button.set_meta("activity_button_hold_nav_target_active", true)
	scene.call("_app_lifecycle_runtime").call("_save_for_app_suspend")
	scene.call("_app_lifecycle_runtime").call("_resume_from_app_suspend")
	for _i in range(12):
		await _wait_test_frame()
	if bool(navigation_shell.get("page_switch_press_active")):
		return false
	if int(navigation_shell.get("page_switch_transition_button_id")) != 0:
		return false
	if bool(button.get_meta("page_switch_press_active", false)):
		return false
	var activity_position := _activity_card_center(scene, "fight:kick-mud-off-boot")
	if activity_position == Vector2.INF:
		return false
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = activity_position
	press.global_position = activity_position
	return not bool(scene.call("_input_routing_shell").call("_route_page_switch_button_global_input", press))


func _first_page_switch_button(scene: Node) -> Button:
	var tree := scene.get_tree()
	if tree == null:
		return null
	for raw_node in tree.get_nodes_in_group("page_switch_buttons"):
		var button := raw_node as Button
		if button != null and is_instance_valid(button) and button.is_visible_in_tree():
			return button
	return null


func _activity_card_center(scene: Node, action_key: String) -> Vector2:
	var cards := scene.get("action_cards") as Dictionary
	if cards == null or not cards.has(action_key):
		return Vector2.INF
	var card := cards.get(action_key, {}) as Dictionary
	var root := card.get("root") as Control
	if root != null and is_instance_valid(root) and root.is_visible_in_tree():
		return root.get_global_rect().get_center()
	return Vector2.INF


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
	var nav_bar := _bottom_nav_bar(scene)
	var nav_text := "none" if nav_bar == null else "visible=%s" % str(nav_bar.visible)
	return "screen=%s selected=%s tutorial=%s step=%s render=%s nav=%s" % [
		str(scene.get("current_screen")),
		str(scene.get("selected_skill_id")),
		str(scene._onboarding_runtime().tutorial_active),
		str(scene._onboarding_runtime().tutorial_step),
		str(scene.call("_navigation_shell").get("screen_render_in_progress")),
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
			and not bool(scene.call("_navigation_shell").get("screen_render_in_progress"))
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
    if ($hadSaveBackup) {
        Copy-Item -LiteralPath $backupSaveBackupPath -Destination $saveBackupPath -Force -ErrorAction SilentlyContinue
    } elseif (Test-Path -LiteralPath $saveBackupPath) {
        Remove-Item -LiteralPath $saveBackupPath -Force -ErrorAction SilentlyContinue
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
