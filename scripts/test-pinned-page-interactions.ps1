param(
    [switch]$Capture
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\pinned-page-interactions"
$testScript = Join-Path $testDir "pinned_page_interactions_smoke.gd"
$capturePath = Join-Path $testDir "pinned-page-jailed-action.png"

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

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG
$env:GODOT_RUN_TIMEOUT_SECONDS = "120"
if ($Capture) {
    $env:IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG = $capturePath
}
$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("pinned-page-interactions-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return
	if not await _wait_for_boot_hidden(scene):
		_fail("boot splash did not hide before pinned-page interaction capture")
		return
	scene.call("_close_offline_summary_overlay")
	for _i in range(3):
		await process_frame

	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_max_skills_state")
	scene.call("_god_mode_unlock_actions_state")
	await _capture_clean_pinned_page_if_requested(scene)
	await _check_pinned_page_navigation_start_input(scene)
	await _check_pinned_active_shelf_expands(scene)
	await _check_pinned_page_start_animates_visible_card(scene)
	await _check_pinned_page_switches_between_text_actions(scene)
	await _check_pinned_page_stop_leaves_blank_active_shelf(scene)
	await _check_pinned_page_opportunity_feedback_targets_visible_card(scene)
	await _check_pinned_page_thieving_jail_bars_reduce_time(scene)

	if failures.is_empty():
		print("pinned-page-interactions-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_for_boot_hidden(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		var overlay := scene.get("boot_warmup_overlay") as Control
		if not bool(scene.get("boot_warmup_active")) and (overlay == null or not overlay.visible or overlay.modulate.a <= 0.01):
			return true
	return false


func _check_pinned_page_navigation_start_input(scene: Node) -> void:
	var module_key := _first_action_module_key(scene, "woodcutting")
	if module_key.is_empty():
		_record("could not find woodcutting action module for pinned-page navigation input smoke")
		return
	var parts := module_key.substr("action:".length()).split(":", false, 2)
	if parts.size() < 2:
		_record("pinned-page navigation input module key was malformed: %s" % module_key)
		return
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "woodcutting")
	scene.set("module_ui_pinned_order", [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_running_activity_for_test_mode")
	await scene.call("_render_screen", false, -1, false)
	for _i in range(6):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	scene.call("_show_pinned_activities")
	for _i in range(90):
		scene.call("_update_ui", 0.016, false)
		await process_frame
		if str(scene.get("current_screen")) == "pinned" and not bool(scene.call("_skill_swipe_loading_transition_active")):
			break
	if str(scene.get("current_screen")) != "pinned":
		_record("pinned-page navigation input smoke did not enter pinned screen")
		return
	if bool(scene.call("_skill_swipe_loading_transition_active")):
		_record("pinned-page navigation input smoke left transition cover active")
		return
	var card_key := str(scene.call("_pinned_page_card_key", module_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(card_key):
		_record("pinned-page navigation input card was not registered: %s keys=%s" % [card_key, str(action_cards.keys())])
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	var source := card.get("pop", null) as Control
	if source == null or not is_instance_valid(source):
		source = card.get("root", null) as Control
	if source == null or not is_instance_valid(source) or not source.is_inside_tree():
		_record("pinned-page navigation input card did not expose visible source")
		return
	var press_position := _find_action_body_press_position(scene, card, source.get_global_rect())
	if press_position == Vector2.INF:
		_record("could not find non-stat body tap point after pinned-page navigation")
		return
	scene.call("_input", _mouse_button_event(press_position, true, press_position))
	await process_frame
	scene.call("_input", _mouse_button_event(press_position, false, press_position))
	var started_after_release := str(scene.get("running_skill_id")) == str(parts[0]) and str(scene.get("running_action_id")) == str(parts[1])
	for _i in range(4):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	if not started_after_release and (str(scene.get("running_skill_id")) != str(parts[0]) or str(scene.get("running_action_id")) != str(parts[1])):
		_record("pinned-page action did not start after real pinned navigation. press_key=%s transition=%s" % [str(scene.get("action_card_press_key")), str(scene.call("_skill_swipe_loading_transition_active"))])


func _check_pinned_page_start_animates_visible_card(scene: Node) -> void:
	var module_key := _first_action_module_key(scene, "woodcutting")
	if module_key.is_empty():
		_record("could not find woodcutting action module for pinned-page press animation smoke")
		return
	var parts := module_key.substr("action:".length()).split(":", false, 2)
	if parts.size() < 2:
		_record("woodcutting action module key was malformed: %s" % module_key)
		return
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", "woodcutting")
	scene.set("module_ui_pinned_order", [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_running_activity_for_test_mode")
	await scene.call("_render_screen", false, -1, false)
	for _i in range(6):
		await process_frame
	var card_key := str(scene.call("_pinned_page_card_key", module_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(card_key):
		_record("pinned-page action card was not registered: %s screen=%s keys=%s" % [card_key, str(scene.get("current_screen")), str(action_cards.keys())])
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	var source := card.get("pop", null) as Control
	if source == null or not is_instance_valid(source):
		source = card.get("root", null) as Control
	if source == null or not is_instance_valid(source):
		source = card.get("button", null) as Control
	if source == null or not is_instance_valid(source) or not source.is_inside_tree():
		_record("pinned-page action card did not expose a visible input source")
		return
	var button := card.get("button", null) as Button
	if button == null or not is_instance_valid(button) or not button.is_inside_tree():
		_record("pinned-page action card did not install a body input button")
		return
	var content_scroll := scene.get("content_scroll") as MobileScrollContainer
	if content_scroll != null and is_instance_valid(content_scroll):
		content_scroll.prepare_child_tap()
	var source_rect := source.get_global_rect()
	var press_position := _find_action_body_press_position(scene, card, source_rect)
	if press_position == Vector2.INF:
		_record("could not find non-stat body tap point for pinned-page action card")
		return
	var press_positions: Array[Vector2] = [press_position]
	var inside_viewport := bool(scene.call("_positions_inside_detail_actions_viewport", press_positions))
	scene.call("_input", _mouse_button_event(press_position, true, press_position))
	await process_frame
	var press_key_after_down := str(scene.get("action_card_press_key"))
	var press_stat_after_down := str(scene.get("action_card_press_stat_kind"))
	scene.call("_input", _mouse_button_event(press_position, false, press_position))
	for _i in range(2):
		await process_frame
	if str(scene.get("running_skill_id")) != str(parts[0]) or str(scene.get("running_action_id")) != str(parts[1]):
		_record("pinned-page action did not start from real card press. inside=%s press_key_after_down=%s press_stat_after_down=%s final_press_key=%s" % [inside_viewport, press_key_after_down, press_stat_after_down, str(scene.get("action_card_press_key"))])
	if not card.has("depth_press_tween") and not (scene.get("action_pop_tweens") as Dictionary).has(card_key):
		_record("pinned-page action start did not animate the visible pinned-page card")
	scene.call("_clear_running_activity_for_test_mode")
	var button_local_press_position := button.get_global_transform().affine_inverse() * press_position
	scene.call("_on_action_card_input", _mouse_button_event(button_local_press_position, true, press_position), str(parts[0]), str(parts[1]), button)
	await process_frame
	scene.call("_on_action_card_input", _mouse_button_event(button_local_press_position, false, press_position), str(parts[0]), str(parts[1]), button)
	for _i in range(2):
		await process_frame
	if str(scene.get("running_skill_id")) != str(parts[0]) or str(scene.get("running_action_id")) != str(parts[1]):
		_record("pinned-page action did not start from visible card button gui_input")
	for _i in range(2):
		await process_frame


func _check_pinned_page_switches_between_text_actions(scene: Node) -> void:
	var module_keys := _first_action_module_keys(scene, "woodcutting", 2)
	if module_keys.size() < 2:
		_record("could not find two woodcutting actions for pinned-page action switch smoke")
		return
	var first_key := str(module_keys[0])
	var second_key := str(module_keys[1])
	var first_parts := first_key.substr("action:".length()).split(":", false, 2)
	var second_parts := second_key.substr("action:".length()).split(":", false, 2)
	if first_parts.size() < 2 or second_parts.size() < 2:
		_record("pinned-page switch smoke module key was malformed: %s / %s" % [first_key, second_key])
		return
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", "woodcutting")
	scene.set("module_ui_pinned_order", [first_key, second_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_running_activity_for_test_mode")
	scene.call("_start_action", str(first_parts[0]), str(first_parts[1]), false)
	await scene.call("_render_screen", false, -1, false)
	for _i in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var card_key := str(scene.call("_pinned_page_card_key", second_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(card_key):
		_record("pinned-page switch target card was not registered: %s keys=%s" % [card_key, str(action_cards.keys())])
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	var source := card.get("pop", null) as Control
	if source == null or not is_instance_valid(source):
		source = card.get("root", null) as Control
	if source == null or not is_instance_valid(source) or not source.is_inside_tree():
		_record("pinned-page switch target card did not expose a visible input source")
		return
	var button := card.get("button", null) as Button
	if button == null or not is_instance_valid(button) or not button.is_inside_tree():
		_record("pinned-page switch target card did not install a body input button")
		return
	var content_scroll := scene.get("content_scroll") as MobileScrollContainer
	if content_scroll != null and is_instance_valid(content_scroll):
		content_scroll.prepare_child_tap()
	var press_position := _find_action_body_press_position(scene, card, source.get_global_rect())
	if press_position == Vector2.INF:
		_record("could not find non-stat body tap point for pinned-page action switch card")
		return
	var button_local_press_position := button.get_global_transform().affine_inverse() * press_position
	scene.call("_on_action_card_input", _mouse_button_event(button_local_press_position, true, press_position), str(second_parts[0]), str(second_parts[1]), button)
	await process_frame
	var press_key_after_down := str(scene.get("action_card_press_key"))
	scene.call("_on_action_card_input", _mouse_button_event(button_local_press_position, false, press_position), str(second_parts[0]), str(second_parts[1]), button)
	for _i in range(3):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	if str(scene.get("running_skill_id")) != str(second_parts[0]) or str(scene.get("running_action_id")) != str(second_parts[1]):
		_record("pinned-page action switch did not start second card. first=%s second=%s running=%s:%s press_key_after_down=%s final_press_key=%s" % [
			str(first_parts[1]),
			str(second_parts[1]),
			str(scene.get("running_skill_id")),
			str(scene.get("running_action_id")),
			press_key_after_down,
			str(scene.get("action_card_press_key"))
		])


func _check_pinned_page_stop_leaves_blank_active_shelf(scene: Node) -> void:
	var module_key := _first_action_module_key(scene, "woodcutting")
	if module_key.is_empty():
		_record("could not find woodcutting action module for pinned-page stop shelf smoke")
		return
	var parts := module_key.substr("action:".length()).split(":", false, 2)
	if parts.size() < 2:
		_record("pinned-page stop shelf smoke module key was malformed: %s" % module_key)
		return
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", str(parts[0]))
	scene.set("module_ui_pinned_order", [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_running_activity_for_test_mode")
	scene.call("_start_action", str(parts[0]), str(parts[1]), false)
	await scene.call("_render_screen", false, -1, false)
	for _i in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var shelf := _find_named_descendant(scene, "PinnedActivitiesActiveShelf") as Control
	if shelf == null or not is_instance_valid(shelf):
		_record("pinned-page stop shelf smoke did not render shelf")
		return
	if shelf.custom_minimum_size.y < 650.0:
		_record("pinned-page stop shelf smoke did not expand before stop. height=%s" % shelf.custom_minimum_size.y)
	scene.call("_stop_running_action", str(parts[0]), str(parts[1]))
	for _i in range(24):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var active_content := _find_named_descendant(scene, "PinnedActivitiesActiveShelfContent") as Control
	if shelf.custom_minimum_size.y < 650.0:
		_record("pinned-page stop did not preserve blank active shelf spacing. height=%s running=%s:%s shelf_skill=%s" % [
			shelf.custom_minimum_size.y,
			str(scene.get("running_skill_id")),
			str(scene.get("running_action_id")),
			str(scene.get("pinned_active_shelf_skill_id"))
		])
	elif active_content != null and is_instance_valid(active_content) and active_content.modulate.a > 0.1:
		_record("pinned-page stop left previous active shelf content visible. alpha=%s" % active_content.modulate.a)


func _check_pinned_page_opportunity_feedback_targets_visible_card(scene: Node) -> void:
	var module_key := _first_action_module_key(scene, "woodcutting")
	if module_key.is_empty():
		_record("could not find woodcutting action module for pinned-page opportunity smoke")
		return
	var parts := module_key.substr("action:".length()).split(":", false, 2)
	if parts.size() < 2:
		_record("pinned-page opportunity smoke module key was malformed: %s" % module_key)
		return
	var skill_id := str(parts[0])
	var action_id := str(parts[1])
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", skill_id)
	scene.set("module_ui_pinned_order", [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_running_activity_for_test_mode")
	var silver_xp := int(scene.call("_mastery_xp_for_level", 2))
	scene.call("_add_mastery_xp", skill_id, action_id, silver_xp)
	scene.call("_start_action", skill_id, action_id, false)
	scene.set("action_progress", 0.60)
	await scene.call("_render_screen", false, -1, false)
	for _i in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var card_key := str(scene.call("_pinned_page_card_key", module_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(card_key):
		_record("pinned-page opportunity card was not registered: %s keys=%s" % [card_key, str(action_cards.keys())])
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	var rail := card.get("progress", null) as ActivityProgressRail
	if rail == null or not is_instance_valid(rail) or not rail.is_inside_tree():
		_record("pinned-page opportunity card did not expose a visible progress rail")
		return
	var opportunity_window := Vector2(rail.opportunity_windows[0])
	scene.set("action_progress", clampf((opportunity_window.x + opportunity_window.y) * 0.5, 0.0, 0.999))
	if not rail.has_opportunity_progress(float(scene.get("action_progress"))):
		_record("pinned-page opportunity rail did not expose a hittable opportunity window. windows=%s progress=%s" % [str(rail.opportunity_windows), str(scene.get("action_progress"))])
		return
	var hit := bool(scene.call("_try_action_opportunity_click", skill_id, action_id, rail.get_global_rect().get_center()))
	for _i in range(3):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	if not hit:
		_record("pinned-page opportunity click did not report a hit")
	if str(rail.opportunity_feedback_mode) != "success":
		_record("pinned-page opportunity click did not shake/play success feedback on visible rail. mode=%s" % str(rail.opportunity_feedback_mode))
	if _find_text_descendant(scene, "nice!") == null:
		_record("pinned-page opportunity click did not create visible opportunity text feedback")
	var reward_float_count_before := _count_nodes_in_group(scene, "skill_reward_float")
	scene.call("_play_action_feedback", scene.call("_action_key", skill_id, action_id), true, 7, 1.0)
	for _i in range(3):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var reward_float_count_after := _count_nodes_in_group(scene, "skill_reward_float")
	if reward_float_count_after <= reward_float_count_before:
		_record("pinned-page canonical action feedback did not create XP/mastery reward floats. before=%s after=%s" % [reward_float_count_before, reward_float_count_after])


func _find_action_body_press_position(scene: Node, card: Dictionary, source_rect: Rect2) -> Vector2:
	var x_fractions: Array[float] = [0.82, 0.74, 0.66, 0.58, 0.50, 0.90]
	var y_fractions: Array[float] = [0.78, 0.68, 0.88, 0.58, 0.48]
	for y_fraction in y_fractions:
		for x_fraction in x_fractions:
			var point := source_rect.position + Vector2(source_rect.size.x * x_fraction, source_rect.size.y * y_fraction)
			var points: Array[Vector2] = [point]
			if not bool(scene.call("_positions_inside_detail_actions_viewport", points)):
				continue
			if not str(scene.call("_activity_stat_kind_from_positions", card, points)).is_empty():
				continue
			if bool(scene.call("_action_card_medal_hit_from_positions", card, points)):
				continue
			return point
	return Vector2.INF


func _check_pinned_page_thieving_jail_bars_reduce_time(scene: Node) -> void:
	var module_key := _first_action_module_key(scene, "thieving")
	if module_key.is_empty():
		_record("could not find thieving action module for pinned-page jail smoke")
		return
	var action_id := str(module_key.substr("action:thieving:".length()))
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", "build")
	scene.set("module_ui_pinned_order", [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_running_activity_for_test_mode")
	scene.call("_jail_thieving_action", action_id, true, 30)
	await scene.call("_render_screen", false, -1, false)
	for _i in range(3):
		await process_frame
	var content_scroll := scene.get("content_scroll") as Control
	var shelf := _find_named_descendant(scene, "PinnedActivitiesActiveShelf") as Control
	if shelf == null or not is_instance_valid(shelf):
		_record("pinned-page jailed thieving state did not render active shelf")
	elif shelf.custom_minimum_size.y < 650.0:
		_record("pinned-page jailed thieving state collapsed the active shelf. height=%s" % shelf.custom_minimum_size.y)
	var active_content := _find_named_descendant(scene, "PinnedActivitiesActiveShelfContent") as Control
	if active_content == null or not is_instance_valid(active_content):
		_record("pinned-page jailed thieving state lost active shelf content")
	elif active_content.modulate.a < 0.9:
		_record("pinned-page jailed thieving active shelf content was hidden. alpha=%s" % active_content.modulate.a)
	var thieving_title := _find_text_descendant(active_content, "Thieving") if active_content != null else null
	if thieving_title == null:
		_record("pinned-page jailed thieving state did not keep the Thieving banner")
	var card_key := str(scene.call("_pinned_page_card_key", module_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(card_key):
		_record("pinned-page jailed thieving card was not registered: %s screen=%s keys=%s" % [card_key, str(scene.get("current_screen")), str(action_cards.keys())])
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	var overlay := card.get("jail_overlay", null) as Control
	if overlay == null or not is_instance_valid(overlay) or not overlay.is_inside_tree():
		_record("pinned-page jailed thieving card did not render jail bars")
		return
	var before := int(scene.call("_thieving_action_jail_remaining", action_id))
	scene.call("_on_thieving_action_jail_overlay_input", _mouse_button_event(overlay.get_global_rect().get_center(), true), action_id, card_key)
	for _i in range(3):
		await process_frame
	var after := int(scene.call("_thieving_action_jail_remaining", action_id))
	if after >= before:
		_record("pinned-page jail bar tap did not reduce jail time. before=%s after=%s" % [before, after])
	var shake_body := card.get("jail_bars_shake_body", null) as Control
	if shake_body == null or not is_instance_valid(shake_body):
			_record("pinned-page jail bar tap did not keep the visible pinned card jail bars wired")


func _capture_clean_pinned_page_if_requested(scene: Node) -> void:
	if OS.get_environment("IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG").is_empty():
		return
	var module_key := _first_action_module_key(scene, "woodcutting")
	if module_key.is_empty():
		module_key = _first_action_module_key(scene, "fight")
	if module_key.is_empty():
		return
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", "woodcutting")
	scene.set("module_ui_pinned_order", [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_running_activity_for_test_mode")
	await scene.call("_render_screen", false, -1, false)
	for _i in range(8):
		await process_frame
	_suppress_capture_overlays(scene)
	await _capture_viewport_if_requested()


func _suppress_capture_overlays(scene: Node) -> void:
	var toast_root := scene.get("achievement_toast_root") as Control
	if toast_root != null and is_instance_valid(toast_root):
		toast_root.visible = false
	var toast_layer := scene.get("achievement_toast_layer") as CanvasLayer
	if toast_layer != null and is_instance_valid(toast_layer):
		toast_layer.visible = false
	var offline_overlay := scene.get("offline_summary_overlay") as Control
	if offline_overlay != null and is_instance_valid(offline_overlay):
		offline_overlay.visible = false
	var achievements_overlay := scene.get("achievements_overlay") as Control
	if achievements_overlay != null and is_instance_valid(achievements_overlay):
		achievements_overlay.visible = false


func _check_pinned_active_shelf_expands(scene: Node) -> void:
	var module_key := _first_action_module_key(scene, "woodcutting")
	if module_key.is_empty():
		_record("active pinned shelf smoke could not find a woodcutting action")
		return
	var parts := module_key.substr("action:".length()).split(":", false, 2)
	if parts.size() < 2:
		_record("active pinned shelf smoke module key was malformed: %s" % module_key)
		return
	var skill_id := str(parts[0])
	var action_id := str(parts[1])
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", skill_id)
	scene.set("module_ui_pinned_order", [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_running_activity_for_test_mode")
	await scene.call("_render_screen", false, -1, false)
	for _i in range(5):
		await process_frame
	var initial_shelf := _find_named_descendant(scene, "PinnedActivitiesActiveShelf") as Control
	if initial_shelf == null or not is_instance_valid(initial_shelf):
		_record("inactive pinned shelf did not render shelf control")
	elif initial_shelf.custom_minimum_size.y < 650.0:
		_record("inactive pinned shelf did not reserve active shelf spacing. height=%s" % initial_shelf.custom_minimum_size.y)
	var initial_active_content := _find_named_descendant(scene, "PinnedActivitiesActiveShelfContent") as Control
	if initial_active_content != null and is_instance_valid(initial_active_content) and initial_active_content.modulate.a > 0.1:
		_record("inactive pinned shelf showed active content. alpha=%s" % initial_active_content.modulate.a)
	var initial_background := _find_named_descendant(scene, "PinnedActivitiesFullBleedShelfBackground") as CanvasItem
	if initial_background == null or not is_instance_valid(initial_background):
		_record("inactive pinned shelf did not keep a background gradient")
	elif initial_background.modulate.a < 0.9:
		_record("inactive pinned shelf background gradient was hidden. alpha=%s" % initial_background.modulate.a)
	scene.call("_start_action", skill_id, action_id, false)
	for _i in range(30):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var content_scroll := scene.get("content_scroll") as Control
	if content_scroll == null:
		_record("active pinned shelf smoke lost content scroll")
		return
	var shelf := _find_named_descendant(scene, "PinnedActivitiesActiveShelf") as Control
	if shelf == null or not is_instance_valid(shelf):
		_record("active pinned shelf did not render shelf control")
		return
	if shelf.custom_minimum_size.y < 650.0:
		_record("active pinned shelf did not expand. height=%s" % shelf.custom_minimum_size.y)
	var active_content := _find_named_descendant(scene, "PinnedActivitiesActiveShelfContent") as Control
	if active_content == null or not is_instance_valid(active_content):
		_record("active pinned shelf did not keep an active content host")
	elif active_content.modulate.a < 0.9:
		_record("active pinned shelf content did not fade in. alpha=%s" % active_content.modulate.a)
	var xp_label := _find_text_descendant(active_content, "Lv") if active_content != null else null
	if xp_label == null:
		_record("active pinned shelf did not render skill XP text")
	var background := _find_named_descendant(scene, "PinnedActivitiesFullBleedShelfBackground") as CanvasItem
	if background == null or not is_instance_valid(background):
		_record("active pinned shelf did not render full-bleed background")
	elif background.modulate.a < 0.9:
		_record("active pinned shelf background did not fade in. alpha=%s" % background.modulate.a)
	elif background.z_index < 0:
		_record("active pinned shelf background is behind the page paper. z_index=%s" % background.z_index)
	content_scroll.scroll_vertical = 80
	content_scroll.set("drag_scroll_position", 80.0)
	for _i in range(4):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var shelf_shadow := _find_named_descendant(scene, "SkillDetailFixedShelfShadow") as Control
	if shelf_shadow == null or not is_instance_valid(shelf_shadow):
		_record("active pinned shelf did not create the shared skill detail shadow")
	elif not shelf_shadow.visible:
		_record("active pinned shelf shadow did not become visible after scrolling")
	elif absf(shelf_shadow.offset_top - (shelf.custom_minimum_size.y + 18.0)) > 2.0:
		_record("active pinned shelf shadow is not attached to the divider edge. shadow=%s shelf=%s" % [shelf_shadow.offset_top, shelf.custom_minimum_size.y])
	var capture_path := OS.get_environment("IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG")
	if not capture_path.is_empty():
		await _capture_viewport_if_requested(capture_path.replace(".png", "-active-shelf.png"))
	scene.call("_clear_running_activity_for_test_mode")
	for _i in range(3):
		scene.call("_update_ui", 0.016, false)
		await process_frame


func _first_action_module_key(scene: Node, skill_id: String) -> String:
	var keys := _first_action_module_keys(scene, skill_id, 1)
	return str(keys[0]) if not keys.is_empty() else ""


func _first_action_module_keys(scene: Node, skill_id: String, count: int) -> Array[String]:
	var keys: Array[String] = []
	var actions = scene.get("actions_by_skill") as Dictionary
	for raw_action in actions.get(skill_id, []):
		var action := raw_action as Dictionary
		if action.is_empty() or bool(scene.call("_is_passive_action", action)):
			continue
		if not bool(scene.call("_is_action_unlocked", skill_id, action)):
			continue
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		if skill_id == "build" and action_id == "stack-bricks":
			continue
		keys.append("action:%s:%s" % [skill_id, action_id])
		if keys.size() >= count:
			return keys
	return keys



func _mouse_button_event(position: Vector2, pressed: bool, global_position := Vector2.INF) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = position
	event.global_position = position if global_position == Vector2.INF else global_position
	return event


func _capture_viewport_if_requested(capture_path := "") -> void:
	if capture_path.is_empty():
		capture_path = OS.get_environment("IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG")
	if capture_path.is_empty():
		return
	for _i in range(3):
		await process_frame
	var texture := root.get_texture()
	if texture == null:
		print("pinned-page-interactions-capture skipped=no-texture")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("pinned-page-interactions-capture skipped=empty-image")
		return
	var result := image.save_png(capture_path)
	if result == OK:
		print("pinned-page-interactions-capture path=%s size=%sx%s" % [capture_path, image.get_width(), image.get_height()])
	else:
		print("pinned-page-interactions-capture skipped=save-failed code=%s" % result)


func _find_named_descendant(root_node: Node, target_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == target_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_named_descendant(child, target_name)
		if found != null:
			return found
	return null


func _find_text_descendant(root_node: Node, needle: String) -> Label:
	if root_node == null:
		return null
	var label := root_node as Label
	if label != null and label.text.contains(needle):
		return label
	for child in root_node.get_children():
		var found := _find_text_descendant(child, needle)
		if found != null:
			return found
	return null


func _count_nodes_in_group(scene: Node, group_name: String) -> int:
	var tree := scene.get_tree()
	if tree == null:
		return 0
	var count := 0
	for raw_node in tree.get_nodes_in_group(group_name):
		var node := raw_node as Node
		if node != null and is_instance_valid(node) and not node.is_queued_for_deletion():
			count += 1
	return count


func _record(message: String) -> void:
	failures.append(message)


func _fail(message: String) -> void:
	push_error("pinned-page-interactions-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    if ($Capture) {
        $output = & $runner --visible-game --path $projectRoot --script $testScript 2>&1
    } else {
        $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    }
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    if (-not $Capture) {
        Assert-True (($output -join "`n") -match "pinned-page-interactions-ok") "Pinned page interactions smoke did not report success."
    }
    if ($Capture) {
        Assert-True (Test-Path -LiteralPath $capturePath) "Pinned page interactions capture was not created."
    }

    $newHeadless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A new headless Godot process is still running after pinned page interactions smoke."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCapturePath) {
        Remove-Item Env:\IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG = $previousCapturePath
    }
    if (Test-Path -LiteralPath $testDir) {
        if ($Capture) {
            Remove-Item -LiteralPath $testScript -Force -ErrorAction SilentlyContinue
        } else {
            Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
