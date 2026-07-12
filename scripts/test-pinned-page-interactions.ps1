param(
    [switch]$Capture
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\pinned-page-interactions"
$testScript = Join-Path $testDir "pinned_page_interactions_smoke.gd"
$capturePath = Join-Path $testDir "pinned-page-jailed-action.png"

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

const ActivityCardStyles := preload("res://scripts/ui/activity_card_styles.gd")
const MasteryState := preload("res://scripts/progression/mastery_state.gd")
const SkillState := preload("res://scripts/progression/skill_state.gd")
const ModuleUiRuntime := preload("res://scripts/module_ui/runtime.gd")

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
	scene.call("_achievement_overlay_surface").call("_close_offline_summary_overlay")
	for _i in range(3):
		await process_frame

	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	await _capture_clean_pinned_page_if_requested(scene)
	await _check_empty_pinned_page_decor_pins(scene)
	await _check_pinned_page_navigation_start_input(scene)
	await _check_module_utility_tabs_close_to_skill_detail(scene)
	await _check_pinned_active_shelf_expands(scene)
	await _check_regular_skill_detail_level_up_float(scene)
	await _check_pinned_page_level_up_float(scene)
	await _check_pinned_page_start_animates_visible_card(scene)
	await _check_pinned_page_material_reward_action_stays_compact(scene)
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


func _module_ui_runtime(scene: Node) -> Object:
	return scene.get("module_ui_runtime") as Object


func _set_module_ui_pinned_order(scene: Node, order: Array) -> void:
	_module_ui_runtime(scene).set("pinned_order", order)


func _module_ui_pinned_order(scene: Node) -> Array:
	return _module_ui_runtime(scene).get("pinned_order") as Array


func _sync_auto_eat_fish_toggle_buttons(scene: Node) -> void:
	scene.call("_fishing_ui_surface").call("_sync_auto_eat_fish_toggle_buttons")


func _auto_eat_fish_toggle_unlocked(scene: Node) -> bool:
	return bool(scene.call("_fishing_ui_surface").call("_auto_eat_fish_toggle_unlocked"))


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			scene.get("startup_initialized") == true
			and scene.get("boot_detail_render_in_progress") != true
			and scene.get("boot_detail_scroll_locked") != true
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_for_boot_hidden(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		var overlay := scene.get("boot_warmup_overlay") as Control
		if scene.get("boot_warmup_active") != true and (overlay == null or not overlay.visible or overlay.modulate.a <= 0.01):
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
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(6):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	scene.call("_navigation_shell").call("_show_pinned_activities")
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
	var card_key := str(scene._navigation_shell()._pinned_page_card_key(module_key))
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
		_record("pinned-page action did not start after real pinned navigation. press_key=%s transition=%s" % [str(scene.call("_skill_detail_surface").get("action_card_press_key")), str(scene.call("_skill_swipe_loading_transition_active"))])


func _check_module_utility_tabs_close_to_skill_detail(scene: Node) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "woodcutting")
	scene.set("_last_rendered_screen_key", "")
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(6):
		await process_frame
	scene.call("_navigation_shell").call("_clear_top_level_nav_lock")
	scene.call("_navigation_shell").call("_show_pinned_activities")
	if not await _wait_for_screen(scene, "pinned"):
		_record("module utility close smoke did not enter pinned screen")
		return
	scene.call("_navigation_shell").call("_clear_top_level_nav_lock")
	scene.call("_navigation_shell").call("_on_queue_utility_pressed")
	if not await _wait_for_screen(scene, "queue"):
		_record("module utility close smoke did not enter queue screen from pinned")
		return
	var navigation_shell = scene.call("_navigation_shell")
	if str(navigation_shell.queue_return_screen) != "skill":
		_record("queue utility stored another utility page as its return screen: %s" % str(navigation_shell.queue_return_screen))
		return
	scene.call("_navigation_shell").call("_clear_top_level_nav_lock")
	scene.call("_navigation_shell").call("_on_queue_utility_pressed")
	if not await _wait_for_screen(scene, "skill"):
		_record("active queue utility button returned to %s instead of skill detail" % str(scene.get("current_screen")))
		return
	if str(scene.get("selected_skill_id")) != "woodcutting":
		_record("active queue utility close did not reveal the previous skill detail; selected=%s" % str(scene.get("selected_skill_id")))


func _wait_for_screen(scene: Node, target_screen: String, max_frames := 120) -> bool:
	for _i in range(max_frames):
		scene.call("_update_ui", 0.016, false)
		await process_frame
		if (
			str(scene.get("current_screen")) == target_screen
			and not bool(scene.call("_navigation_shell").get("screen_render_in_progress"))
			and not bool(scene.call("_skill_swipe_loading_transition_active"))
		):
			return true
	return false


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
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(6):
		await process_frame
	var card_key := str(scene._navigation_shell()._pinned_page_card_key(module_key))
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
	var inside_viewport := bool(scene.call("_input_routing_shell").call("_positions_inside_detail_actions_viewport", press_positions))
	scene.call("_input", _mouse_button_event(press_position, true, press_position))
	await process_frame
	var press_key_after_down := str(scene.call("_skill_detail_surface").get("action_card_press_key"))
	var press_stat_after_down := str(scene.call("_skill_detail_surface").get("action_card_press_stat_kind"))
	scene.call("_input", _mouse_button_event(press_position, false, press_position))
	for _i in range(2):
		await process_frame
	if str(scene.get("running_skill_id")) != str(parts[0]) or str(scene.get("running_action_id")) != str(parts[1]):
		_record("pinned-page action did not start from real card press. inside=%s press_key_after_down=%s press_stat_after_down=%s final_press_key=%s" % [inside_viewport, press_key_after_down, press_stat_after_down, str(scene.call("_skill_detail_surface").get("action_card_press_key"))])
	if not card.has("depth_press_tween") and not (scene.get("action_pop_tweens") as Dictionary).has(card_key):
		_record("pinned-page action start did not animate the visible pinned-page card")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	var button_local_press_position := button.get_global_transform().affine_inverse() * press_position
	scene.call("_skill_swipe_activity_surface").call("_on_action_card_input", _mouse_button_event(button_local_press_position, true, press_position), str(parts[0]), str(parts[1]), button)
	await process_frame
	scene.call("_skill_swipe_activity_surface").call("_on_action_card_input", _mouse_button_event(button_local_press_position, false, press_position), str(parts[0]), str(parts[1]), button)
	for _i in range(2):
		await process_frame
	if str(scene.get("running_skill_id")) != str(parts[0]) or str(scene.get("running_action_id")) != str(parts[1]):
		_record("pinned-page action did not start from visible card button gui_input")
	for _i in range(2):
		await process_frame


func _check_pinned_page_material_reward_action_stays_compact(scene: Node) -> void:
	var reward_actions := _material_reward_action_modules(scene)
	if reward_actions.is_empty():
		_record("pinned-page material reward smoke could not find any unlocked collection actions")
		return
	for reward_entry in reward_actions:
		await _check_pinned_page_material_reward_entry_stays_compact(scene, reward_entry as Dictionary)


func _material_reward_action_modules(scene: Node) -> Array[Dictionary]:
	var reward_actions: Array[Dictionary] = []
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	for raw_skill_id in actions_by_skill.keys():
		var skill_id := str(raw_skill_id)
		for raw_action in actions_by_skill.get(raw_skill_id, []):
			var action := raw_action as Dictionary
			if action.is_empty() or bool(scene.call("_passive_modules_runtime").is_passive_action(action)):
				continue
			if not bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", skill_id, action)):
				continue
			if not bool(scene.call("_action_runtime").call("_action_has_mat_rewards", action)):
				continue
			var action_id := str(action.get("id", ""))
			var module_key := ModuleUiRuntime.action_for_record(skill_id, action)
			if action_id.is_empty() or module_key.is_empty():
				continue
			reward_actions.append({
				"skill_id": skill_id,
				"action_id": action_id,
				"module_key": module_key,
			})
	return reward_actions


func _check_pinned_page_material_reward_entry_stays_compact(scene: Node, reward_entry: Dictionary) -> void:
	var skill_id := str(reward_entry.get("skill_id", ""))
	var action_id := str(reward_entry.get("action_id", ""))
	var module_key := str(reward_entry.get("module_key", ""))
	if skill_id.is_empty() or action_id.is_empty() or module_key.is_empty():
		_record("pinned-page material reward smoke had malformed collection entry: %s" % str(reward_entry))
		return
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	scene.call("_action_runtime").call("_start_action", skill_id, action_id, false)
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(10):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var card_key := str(scene._navigation_shell()._pinned_page_card_key(module_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(card_key):
		_record("pinned-page material reward card was not registered: %s:%s key=%s keys=%s" % [skill_id, action_id, card_key, str(action_cards.keys())])
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	if not bool(card.get("page_copy_suppresses_collection_modules", false)):
		_record("pinned-page material reward card did not suppress page-copy collection modules for %s:%s" % [skill_id, action_id])
	var collection := card.get("mat_collection", {}) as Dictionary
	if not collection.is_empty() and bool(collection.get("visible", false)):
		_record("pinned-page material reward collection became visible inside the page action copy for %s:%s" % [skill_id, action_id])
	var entry := card.get("entry", null) as Control
	if entry == null or not is_instance_valid(entry):
		_record("pinned-page material reward card did not expose an entry for %s:%s" % [skill_id, action_id])
		return
	var compact_height := ActivityCardStyles.root_height(false, 720.0, 1080.0, 34.0)
	var actual_height := maxf(entry.custom_minimum_size.y, entry.size.y)
	if actual_height > compact_height + 140.0:
		_record("pinned-page material reward card expanded into a fat page module for %s:%s. expected<=%s actual=%s" % [skill_id, action_id, compact_height + 140.0, actual_height])
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	for _i in range(2):
		scene.call("_update_ui", 0.016, false)
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
	_set_module_ui_pinned_order(scene, [first_key, second_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	scene.call("_action_runtime").call("_start_action", str(first_parts[0]), str(first_parts[1]), false)
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var card_key := str(scene._navigation_shell()._pinned_page_card_key(second_key))
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
	scene.call("_skill_swipe_activity_surface").call("_on_action_card_input", _mouse_button_event(button_local_press_position, true, press_position), str(second_parts[0]), str(second_parts[1]), button)
	await process_frame
	var press_key_after_down := str(scene.call("_skill_detail_surface").get("action_card_press_key"))
	scene.call("_skill_swipe_activity_surface").call("_on_action_card_input", _mouse_button_event(button_local_press_position, false, press_position), str(second_parts[0]), str(second_parts[1]), button)
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
			str(scene.call("_skill_detail_surface").get("action_card_press_key"))
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
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	scene.call("_action_runtime").call("_start_action", str(parts[0]), str(parts[1]), false)
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var shelf := _find_named_descendant(scene, "PinnedActivitiesActiveShelf") as Control
	if shelf == null or not is_instance_valid(shelf):
		_record("pinned-page stop shelf smoke did not render shelf")
		return
	if shelf.custom_minimum_size.y < 650.0:
		_record("pinned-page stop shelf smoke did not expand before stop. height=%s" % shelf.custom_minimum_size.y)
	scene.call("_action_runtime").call("_stop_running_action", str(parts[0]), str(parts[1]))
	for _i in range(24):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var active_content := _find_named_descendant(scene, "PinnedActivitiesActiveShelfContent") as Control
	var navigation_shell = scene.call("_navigation_shell")
	if shelf.custom_minimum_size.y < 650.0:
		_record("pinned-page stop did not preserve blank active shelf spacing. height=%s running=%s:%s shelf_skill=%s" % [
			shelf.custom_minimum_size.y,
			str(scene.get("running_skill_id")),
			str(scene.get("running_action_id")),
			str(navigation_shell.get("pinned_active_shelf_skill_id"))
		])
	elif active_content != null and is_instance_valid(active_content) and active_content.modulate.a > 0.1:
		_record("pinned-page stop left previous active shelf content visible. alpha=%s" % active_content.modulate.a)
	var stamina_shelf := _find_named_descendant(scene, "PinnedActivitiesStaminaGaugeShelf") as Control
	if stamina_shelf == null or not is_instance_valid(stamina_shelf):
		_record("pinned-page stop did not restore the stamina gauge shelf")
	elif not stamina_shelf.is_visible_in_tree() or stamina_shelf.modulate.a < 0.9:
		_record("pinned-page stop restored hidden stamina gauge shelf. alpha=%s visible=%s" % [stamina_shelf.modulate.a, stamina_shelf.visible])
	elif _count_named_descendants_with_prefix(stamina_shelf, "PinnedActivitiesStaminaGauge_") != 4:
		_record("pinned-page stop restored wrong stamina gauge count. count=%s" % _count_named_descendants_with_prefix(stamina_shelf, "PinnedActivitiesStaminaGauge_"))


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
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	var silver_xp := MasteryState.xp_for_level(2)
	MasteryState.add_host_xp(scene, skill_id, action_id, silver_xp)
	scene.get("fishing_runtime").set("fish_currency_ever_earned", true)
	scene.get("fishing_runtime").set("fish_currency", 2.0)
	_sync_auto_eat_fish_toggle_buttons(scene)
	scene.call("_action_runtime").call("_start_action", skill_id, action_id, false)
	scene.set("action_progress", 0.60)
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var card_key := str(scene._navigation_shell()._pinned_page_card_key(module_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(card_key):
		_record("pinned-page opportunity card was not registered: %s keys=%s" % [card_key, str(action_cards.keys())])
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	var rail := card.get("progress", null) as Object
	if rail == null or not is_instance_valid(rail) or not rail.is_inside_tree():
		_record("pinned-page opportunity card did not expose a visible progress rail")
		return
	if rail.opportunity_windows.is_empty():
		return
	var opportunity_window := Vector2(rail.opportunity_windows[0])
	scene.set("action_progress", clampf((opportunity_window.x + opportunity_window.y) * 0.5, 0.0, 0.999))
	if not rail.has_opportunity_progress(float(scene.get("action_progress"))):
		_record("pinned-page opportunity rail did not expose a hittable opportunity window. windows=%s progress=%s" % [str(rail.opportunity_windows), str(scene.get("action_progress"))])
		return
	var hit := bool(scene.call("_action_runtime").call("_try_action_opportunity_click", skill_id, action_id, rail.get_global_rect().get_center()))
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
	scene.call("_reward_feedback_surface").call("_play_action_feedback", scene.call("_action_key", skill_id, action_id), true, 7, 1.0)
	for _i in range(3):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var reward_float_count_after := _count_nodes_in_group(scene, "skill_reward_float")
	if reward_float_count_after <= reward_float_count_before:
		_record("pinned-page canonical action feedback did not create XP/mastery reward floats. before=%s after=%s" % [reward_float_count_before, reward_float_count_after])


func _check_regular_skill_detail_level_up_float(scene: Node) -> void:
	var skill_id := "woodcutting"
	await _clear_skill_reward_floats(scene)
	_stage_skill_one_xp_before_level(scene, skill_id, 2)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_pinned_order(scene, [])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var xp_bar := scene._skill_detail_surface().detail_xp_bar as Control
	if xp_bar == null or not is_instance_valid(xp_bar) or not xp_bar.is_visible_in_tree():
		_record("regular skill detail level-up smoke did not render a visible XP bar")
		return
	if not bool(scene.call("_reward_feedback_surface").call("_skill_level_up_float_bar_visible", skill_id)):
		_record("regular skill detail level-up smoke did not consider the detail XP bar visible")
	var level_up_text_count_before := _count_text_descendants(scene, "LEVEL UP!")
	_grant_skill_level_crossing_xp(scene, skill_id, 2)
	for _i in range(5):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var level_up_text_count_after := _count_text_descendants(scene, "LEVEL UP!")
	if level_up_text_count_after <= level_up_text_count_before:
		_record("regular skill detail level-up did not create visible LEVEL UP! text. before=%s after=%s" % [level_up_text_count_before, level_up_text_count_after])
	var capture_path := OS.get_environment("IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG")
	if not capture_path.is_empty():
		await _capture_viewport_if_requested(capture_path.replace(".png", "-regular-level-up.png"))
	await _clear_skill_reward_floats(scene)


func _check_pinned_page_level_up_float(scene: Node) -> void:
	var module_key := _first_action_module_key(scene, "woodcutting")
	if module_key.is_empty():
		_record("could not find woodcutting action module for pinned-page level-up smoke")
		return
	var parts := module_key.substr("action:".length()).split(":", false, 2)
	if parts.size() < 2:
		_record("pinned-page level-up smoke module key was malformed: %s" % module_key)
		return
	var skill_id := str(parts[0])
	var action_id := str(parts[1])
	await _clear_skill_reward_floats(scene)
	_stage_skill_one_xp_before_level(scene, skill_id, 2)
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	scene.call("_action_runtime").call("_start_action", skill_id, action_id, false)
	for _i in range(30):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var navigation_shell = scene.call("_navigation_shell")
	var xp_bar := navigation_shell.get("pinned_active_shelf_xp_bar") as Control
	if xp_bar == null or not is_instance_valid(xp_bar) or not xp_bar.is_visible_in_tree():
		_record("pinned-page level-up smoke did not render a visible active shelf XP bar")
		return
	if str(navigation_shell.get("pinned_active_shelf_skill_id")) != skill_id:
		_record("pinned-page level-up smoke active shelf skill mismatch. expected=%s actual=%s" % [skill_id, str(navigation_shell.get("pinned_active_shelf_skill_id"))])
	if not bool(scene.call("_reward_feedback_surface").call("_skill_level_up_float_bar_visible", skill_id)):
		_record("pinned-page level-up smoke did not consider the active shelf XP bar visible")
	var level_up_text_count_before := _count_text_descendants(scene, "LEVEL UP!")
	_grant_skill_level_crossing_xp(scene, skill_id, 2)
	for _i in range(5):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var level_up_text_count_after := _count_text_descendants(scene, "LEVEL UP!")
	if level_up_text_count_after <= level_up_text_count_before:
		_record("pinned-page level-up did not create visible LEVEL UP! text. before=%s after=%s" % [level_up_text_count_before, level_up_text_count_after])
	var capture_path := OS.get_environment("IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG")
	if not capture_path.is_empty():
		await _capture_viewport_if_requested(capture_path.replace(".png", "-pinned-level-up.png"))
	await _clear_skill_reward_floats(scene)
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()


func _find_action_body_press_position(scene: Node, card: Dictionary, source_rect: Rect2) -> Vector2:
	var x_fractions: Array[float] = [0.82, 0.74, 0.66, 0.58, 0.50, 0.90]
	var y_fractions: Array[float] = [0.78, 0.68, 0.88, 0.58, 0.48]
	for y_fraction in y_fractions:
		for x_fraction in x_fractions:
			var point := source_rect.position + Vector2(source_rect.size.x * x_fraction, source_rect.size.y * y_fraction)
			var points: Array[Vector2] = [point]
			if not bool(scene.call("_input_routing_shell").call("_positions_inside_detail_actions_viewport", points)):
				continue
			if not str(scene.call("_skill_detail_surface").call("_activity_stat_kind_from_positions", card, points)).is_empty():
				continue
			if scene.call("_skill_swipe_activity_surface").call("_action_card_medal_hit_from_positions", card, points) == true:
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
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	scene.call("_thieving_surface").call("_jail_thieving_action", action_id, true, 30)
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(3):
		await process_frame
	if not bool(scene.call("_performance_runtime").call("_skill_detail_needs_high_frequency_ui_update")):
		_record("pinned-page jailed thieving state did not keep high-frequency pinned shelf refresh active")
	if not bool(scene.call("_performance_runtime").call("_battery_governor_visual_work_active")):
		_record("pinned-page jailed thieving state did not keep the battery governor in visual-work mode")
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
	var card_key := str(scene._navigation_shell()._pinned_page_card_key(module_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(card_key):
		_record("pinned-page jailed thieving card was not registered: %s screen=%s keys=%s" % [card_key, str(scene.get("current_screen")), str(action_cards.keys())])
		return
	var card := action_cards.get(card_key, {}) as Dictionary
	var overlay := card.get("jail_overlay", null) as Control
	if overlay == null or not is_instance_valid(overlay) or not overlay.is_inside_tree():
		_record("pinned-page jailed thieving card did not render jail bars")
		return
	var before := int(scene.call("_thieving_surface").call("_thieving_action_jail_remaining", action_id))
	scene.call("_thieving_surface").call("_on_thieving_action_jail_overlay_input", _mouse_button_event(overlay.get_global_rect().get_center(), true), action_id, card_key)
	for _i in range(3):
		await process_frame
	var after := int(scene.call("_thieving_surface").call("_thieving_action_jail_remaining", action_id))
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
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(8):
		await process_frame
	_suppress_capture_overlays(scene)
	await _capture_viewport_if_requested()


func _check_empty_pinned_page_decor_pins(scene: Node) -> void:
	scene.set("current_screen", "pinned")
	scene.set("selected_skill_id", "woodcutting")
	_set_module_ui_pinned_order(scene, [])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(8):
		await process_frame
	var content_scroll := scene.get("content_scroll") as Control
	if content_scroll == null or not is_instance_valid(content_scroll):
		_record("empty pinned page decor smoke did not create content scroll")
		return
	var capture_path := OS.get_environment("IDLE_ELITE_PINNED_PAGE_INTERACTIONS_PNG")
	if not capture_path.is_empty():
		await _capture_viewport_if_requested(capture_path.replace(".png", "-empty-decor.png"))
	var expected_count := int(scene.call("_navigation_shell").PINNED_ACTIVITIES_EMPTY_DECOR_PIN_COUNT)
	var actual_count := _count_named_descendants_with_prefix(content_scroll, "PinnedActivitiesEmptyDecorPin_")
	if actual_count != expected_count:
		_record("empty pinned page decor pin count mismatch. expected=%s actual=%s" % [expected_count, actual_count])
	var expected_textures: Array[String] = [str(ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE)]
	for raw_texture in ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES:
		expected_textures.append(str(raw_texture))
	var expected_size: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_SIZE
	var expected_position: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	var positions: Array[Vector2] = []
	for index in range(expected_count):
		var host := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyDecorPin_%s" % index) as Control
		var hit_zone := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyDecorPinHit_%s" % index) as Control
		var badge := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyDecorPinBadge_%s" % index) as TextureButton
		if host == null or not is_instance_valid(host):
			_record("empty pinned page decor pin host missing at index %s" % index)
			continue
		positions.append(host.position)
		if absf(host.rotation_degrees) > 0.01:
			_record("empty pinned page decor host should not rotate. index=%s rotation=%s" % [index, host.rotation_degrees])
		if hit_zone == null or not is_instance_valid(hit_zone):
			_record("empty pinned page decor hit zone missing at index %s" % index)
		elif hit_zone.mouse_filter != Control.MOUSE_FILTER_STOP:
			_record("empty pinned page decor hit zone should accept clicks. index=%s mouse_filter=%s" % [index, hit_zone.mouse_filter])
		if badge == null or not is_instance_valid(badge):
			_record("empty pinned page decor badge missing at index %s" % index)
			continue
		if not badge.visible or badge.modulate.a < 0.99:
			_record("empty pinned page decor badge should be fully visible. index=%s visible=%s alpha=%s" % [index, badge.visible, badge.modulate.a])
		if badge.texture_normal == null:
			_record("empty pinned page decor badge texture missing at index %s" % index)
		elif not expected_textures.has(str(badge.get_meta("module_pin_texture_path", ""))):
			_record("empty pinned page decor badge should use an approved module pin texture. index=%s texture=%s" % [index, str(badge.get_meta("module_pin_texture_path", ""))])
		if not badge.size.is_equal_approx(expected_size):
			_record("empty pinned page decor badge size mismatch. index=%s expected=%s actual=%s" % [index, expected_size, badge.size])
		if badge.position.distance_to(expected_position) > 0.01:
			_record("empty pinned page decor badge should use the settled module pin crop. index=%s expected=%s actual=%s" % [index, expected_position, badge.position])
		if absf(badge.rotation_degrees) > 0.01 or not badge.scale.is_equal_approx(Vector2.ONE):
			_record("empty pinned page decor badge should not randomize angle or scale. index=%s rotation=%s scale=%s" % [index, badge.rotation_degrees, badge.scale])
	var varied_positions := false
	if positions.size() > 1:
		var first_position := positions[0]
		for position in positions:
			if position.distance_to(first_position) > 1.0:
				varied_positions = true
				break
	if expected_count > 1 and not varied_positions:
		_record("empty pinned page decor pins should only randomize position, but positions did not vary")
	var first_host := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyDecorPin_0") as Control
	var first_hit_zone := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyDecorPinHit_0") as Control
	var first_badge := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyDecorPinBadge_0") as TextureButton
	if first_host != null and first_hit_zone != null and first_badge != null:
		var pinned_before := _module_ui_pinned_order(scene).duplicate()
		first_hit_zone.emit_signal("gui_input", _mouse_button_event(Vector2(16, 16), true))
		for _i in range(3):
			await process_frame
		if not first_badge.has_meta("module_pin_tween"):
			_record("empty pinned page decor pin click did not start the exit animation")
		if _module_ui_pinned_order(scene) != pinned_before:
			_record("empty pinned page decor pin click should not mutate pinned activities")
		for _i in range(40):
			await process_frame
		if first_host != null and is_instance_valid(first_host) and not first_host.is_queued_for_deletion():
			_record("empty pinned page decor pin host should be removed after exit animation")
		var after_exit_count := _count_named_descendants_with_prefix(content_scroll, "PinnedActivitiesEmptyDecorPin_")
		if after_exit_count != maxi(0, expected_count - 1):
			_record("empty pinned page decor pin exit should remove exactly one pin. expected=%s actual=%s" % [maxi(0, expected_count - 1), after_exit_count])
	scene.set("_last_rendered_screen_key", "")
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _i in range(8):
		await process_frame
	content_scroll = scene.get("content_scroll") as Control
	var regenerated_count := _count_named_descendants_with_prefix(content_scroll, "PinnedActivitiesEmptyDecorPin_")
	if regenerated_count != expected_count:
		_record("empty pinned page should regenerate a fresh pin patch on reload. expected=%s actual=%s" % [expected_count, regenerated_count])
	var regenerated_positions: Array[Vector2] = []
	for index in range(expected_count):
		var regenerated_host := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyDecorPin_%s" % index) as Control
		if regenerated_host != null and is_instance_valid(regenerated_host):
			regenerated_positions.append(regenerated_host.position)
	if regenerated_positions.size() == positions.size():
		var total_position_delta := 0.0
		for index in range(positions.size()):
			total_position_delta += positions[index].distance_to(regenerated_positions[index])
		if total_position_delta < 32.0:
			_record("empty pinned page should randomize pin positions on each empty load. total_delta=%s" % total_position_delta)


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
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("_last_rendered_screen_key", "")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
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
	var initial_stamina_shelf := _find_named_descendant(scene, "PinnedActivitiesStaminaGaugeShelf") as Control
	if initial_stamina_shelf == null or not is_instance_valid(initial_stamina_shelf):
		_record("inactive pinned shelf did not render the stamina gauge shelf")
	elif not initial_stamina_shelf.is_visible_in_tree() or initial_stamina_shelf.modulate.a < 0.9:
		_record("inactive pinned shelf stamina gauge shelf was hidden. alpha=%s visible=%s" % [initial_stamina_shelf.modulate.a, initial_stamina_shelf.visible])
	elif _count_named_descendants_with_prefix(initial_stamina_shelf, "PinnedActivitiesStaminaGauge_") != 4:
		_record("inactive pinned shelf did not render exactly four stamina gauges. count=%s" % _count_named_descendants_with_prefix(initial_stamina_shelf, "PinnedActivitiesStaminaGauge_"))
	var initial_background := _find_named_descendant(scene, "PinnedActivitiesFullBleedShelfBackground") as CanvasItem
	if initial_background == null or not is_instance_valid(initial_background):
		_record("inactive pinned shelf did not keep a background gradient")
	elif initial_background.modulate.a < 0.9:
		_record("inactive pinned shelf background gradient was hidden. alpha=%s" % initial_background.modulate.a)
	scene.call("_action_runtime").call("_start_action", skill_id, action_id, false)
	for _i in range(30):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	scene.get("fishing_runtime").set("fish_currency_ever_earned", true)
	scene.get("fishing_runtime").set("fish_currency", 2.0)
	_sync_auto_eat_fish_toggle_buttons(scene)
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
	var active_stamina_shelf := _find_named_descendant(scene, "PinnedActivitiesStaminaGaugeShelf") as Control
	if active_stamina_shelf != null and is_instance_valid(active_stamina_shelf) and active_stamina_shelf.is_visible_in_tree() and active_stamina_shelf.modulate.a > 0.1:
		_record("active pinned shelf did not hide the inactive stamina gauge shelf. alpha=%s" % active_stamina_shelf.modulate.a)
	var xp_label := _find_text_descendant(active_content, "Lv") if active_content != null else null
	if xp_label == null:
		_record("active pinned shelf did not render skill XP text")
	var navigation_shell = scene.call("_navigation_shell")
	var active_gauge := navigation_shell.get("pinned_active_shelf_regen_circle") as Control
	if active_gauge == null or not is_instance_valid(active_gauge) or not active_gauge.is_visible_in_tree():
		_record("active pinned shelf did not render an interactive stamina Gage")
	else:
		var auto_fish_toggle := _find_named_descendant(scene, "AutoEatFishToggle") as TextureButton
		if auto_fish_toggle == null or not is_instance_valid(auto_fish_toggle):
			_record("active pinned shelf did not create the Auto Fish Eat toggle")
		elif not auto_fish_toggle.is_visible_in_tree():
			_record("active pinned shelf Auto Fish Eat toggle was hidden. visible=%s unlocked=%s fish=%s ever=%s" % [
				auto_fish_toggle.visible,
				_auto_eat_fish_toggle_unlocked(scene),
				float(scene.get("fishing_runtime").get("fish_currency")),
				bool(scene.get("fishing_runtime").get("fish_currency_ever_earned"))
			])
		elif str(auto_fish_toggle.get_meta("auto_eat_skill_id", "")) != skill_id:
			_record("active pinned shelf Auto Fish Eat toggle targeted %s instead of %s" % [str(auto_fish_toggle.get_meta("auto_eat_skill_id", "")), skill_id])
		else:
			scene.get("fishing_runtime").call("set_auto_eat_fish_enabled_for_skill", scene, skill_id, false)
			_sync_auto_eat_fish_toggle_buttons(scene)
			auto_fish_toggle.emit_signal("pressed")
			if not bool(scene.get("fishing_runtime").call("auto_eat_fish_enabled_for_skill", scene, skill_id)):
				_record("active pinned shelf Auto Fish Eat toggle did not flip the active skill setting")
			var max_stamina := float(SkillState.max_stamina(scene, skill_id))
			var stamina_state := scene.get("stamina") as Dictionary
			stamina_state[skill_id] = maxf(0.0, max_stamina - 2.0)
			scene.set("stamina", stamina_state)
			SkillState.host_sync_stamina_bank(skill_id, scene)
			var before_stamina := float(SkillState.host_stamina_value(skill_id, scene))
			var before_fish := float(scene.get("fishing_runtime").get("fish_currency"))
			var tap_position := active_gauge.get_global_rect().get_center()
			scene.call("_action_runtime").call("_on_stamina_gauge_input", _mouse_button_event(tap_position, true), skill_id, active_gauge)
			scene.call("_action_runtime").call("_on_stamina_gauge_input", _mouse_button_event(tap_position, false), skill_id, active_gauge)
			for _i in range(4):
				await process_frame
			if absf(float(SkillState.host_stamina_value(skill_id, scene)) - (before_stamina + 1.0)) > 0.001:
				_record("active pinned shelf Gage tap did not eat one fish into stamina")
			if absf(float(scene.get("fishing_runtime").get("fish_currency")) - (before_fish - 1.0)) > 0.001:
				_record("active pinned shelf Gage tap did not spend one fish")
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
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
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
		if action.is_empty() or bool(scene.call("_passive_modules_runtime").is_passive_action(action)):
			continue
		if not bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", skill_id, action)):
			continue
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		if skill_id == "build" and action_id == "stack-bricks":
			continue
		keys.append(ModuleUiRuntime.action_for_record(skill_id, action))
		if keys.size() >= count:
			return keys
	return keys


func _stage_skill_one_xp_before_level(scene: Node, skill_id: String, target_level: int) -> void:
	var skills := scene.get("skills") as Dictionary
	var skill_state := (skills.get(skill_id, {}) as Dictionary).duplicate(true)
	skill_state["xp"] = maxi(0, SkillState.xp_for_level(target_level) - 1)
	skill_state["level"] = maxi(1, target_level - 1)
	skills[skill_id] = skill_state
	scene.set("skills", skills)
	SkillState.recalculate_level(scene, skill_id, false)


func _grant_skill_level_crossing_xp(scene: Node, skill_id: String, target_level: int) -> void:
	var skills := scene.get("skills") as Dictionary
	var skill_state := (skills.get(skill_id, {}) as Dictionary).duplicate(true)
	skill_state["xp"] = SkillState.xp_for_level(target_level)
	skills[skill_id] = skill_state
	scene.set("skills", skills)
	SkillState.recalculate_level(scene, skill_id, true)


func _clear_skill_reward_floats(scene: Node) -> void:
	var tree := scene.get_tree()
	if tree == null:
		return
	for raw_node in tree.get_nodes_in_group("skill_reward_float"):
		var node := raw_node as Node
		if node != null and is_instance_valid(node) and not node.is_queued_for_deletion():
			node.queue_free()
	await process_frame



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


func _count_named_descendants_with_prefix(root_node: Node, prefix: String) -> int:
	if root_node == null:
		return 0
	var count := 1 if str(root_node.name).begins_with(prefix) else 0
	for child in root_node.get_children():
		count += _count_named_descendants_with_prefix(child, prefix)
	return count


func _count_text_descendants(root_node: Node, needle: String) -> int:
	if root_node == null:
		return 0
	var count := 0
	var label := root_node as Label
	if label != null and label.text.contains(needle):
		count += 1
	for child in root_node.get_children():
		count += _count_text_descendants(child, needle)
	return count


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
