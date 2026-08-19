$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\module-list-transitions"
$testScript = Join-Path $testDir "module_list_transitions_smoke.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "120"
$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const ModuleUiRuntime := preload("res://scripts/module_ui/runtime.gd")
const SkillState := preload("res://scripts/progression/skill_state.gd")

const BOOT_TIMEOUT_FRAMES := 720

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("module-list-transitions-start")
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

	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	await _check_reverse_sort_in_place(scene, "build")
	await _wait_for_render_idle(scene)
	await _check_normal_action_info_chip_behavior(scene, "build")
	await _wait_for_render_idle(scene)
	await _check_sort_menu_input_isolation(scene, "build")
	await _wait_for_render_idle(scene)
	await _check_immediate_pin_input_flow(scene, "build")
	await _wait_for_render_idle(scene)
	await _check_two_stage_collapse_input_flow(scene, "build")
	await _wait_for_render_idle(scene)
	await _check_pin_refresh_transition(scene, "build")
	await _wait_for_render_idle(scene)
	await _check_pinned_page_action_card_registration(scene, "build")
	await _check_pinned_duplicates_ignore_source_collapse(scene, "build")
	await _check_restored_module_ui_preferences_render(scene, "build")
	await _check_hard_reset_module_ui_preferences_render(scene, "build")
	await _check_pin_refresh_transition(scene, "fishing")
	await _check_pinned_page_fishing_area_registration(scene)
	await _check_pinned_page_fishing_offer_module(scene)
	await _check_pinned_page_thieving_heist_registration(scene)
	await _check_pinned_page_chrome(scene)
	await _check_pinned_page_cross_skill_order(scene)
	await _check_no_gameplay_tooltips(scene, "build")
	await _check_rendered_locked_module_action_zones(scene)
	await _check_collapse_refresh_transition(scene, "build")
	await _check_pin_confirm_preserves_source_scroll(scene, "build")
	await _wait_for_render_idle(scene)
	await _check_pinned_page_return_restores_skill_scroll(scene, "build")
	await _check_event_insertion_transition(scene)
	await _check_unlock_preview_insertion_transition(scene)
	await _check_unlock_preview_insertion_transition(scene, true)

	if failures.is_empty():
		print("module-list-transitions-ok")
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


func _wait_for_render_idle(scene: Node) -> void:
	for _frame in range(60):
		await process_frame
		if not is_instance_valid(scene):
			return
		var pending := scene.call("_navigation_shell").get("pending_screen_render_request") as Dictionary
		if not bool(scene.call("_navigation_shell").get("screen_render_in_progress")) and (pending == null or pending.is_empty()):
			await process_frame
			return


func _wait_for_pin_anchor_idle(scene: Node, max_frames := 120) -> void:
	for _frame in range(max_frames):
		await process_frame
		if not is_instance_valid(scene):
			return
		var pending_anchor := scene.get("module_ui_pending_pin_scroll_anchor") as Dictionary
		var pending_render := scene.call("_navigation_shell").get("pending_screen_render_request") as Dictionary
		if (
			not bool(scene.call("_navigation_shell").get("screen_render_in_progress"))
			and (pending_render == null or pending_render.is_empty())
			and (pending_anchor == null or pending_anchor.is_empty())
			and not bool(scene.call("_skill_swipe_activity_surface").get("skill_detail_refresh_cover_active"))
		):
			await process_frame
			return


func _wait_for_badge_tween_done(badge: TextureButton, max_frames := 120) -> void:
	for _frame in range(max_frames):
		await process_frame
		if badge == null or not is_instance_valid(badge):
			return
		if not badge.has_meta("module_pin_tween"):
			await process_frame
			return


func _module_ui_runtime(scene: Node) -> Object:
	return scene.get("module_ui_runtime") as Object


func _module_ui_pinned_order(scene: Node) -> Array:
	var runtime := _module_ui_runtime(scene)
	if runtime == null:
		return []
	return runtime.get("pinned_order") as Array


func _set_module_ui_pinned_order(scene: Node, order: Array) -> void:
	var runtime := _module_ui_runtime(scene)
	if runtime != null:
		runtime.set("pinned_order", order.duplicate())


func _module_ui_collapsed(scene: Node) -> Dictionary:
	var runtime := _module_ui_runtime(scene)
	if runtime == null:
		return {}
	return runtime.get("collapsed") as Dictionary


func _set_module_ui_collapsed(scene: Node, collapsed: Dictionary) -> void:
	var runtime := _module_ui_runtime(scene)
	if runtime != null:
		runtime.set("collapsed", collapsed.duplicate())


func _module_ui_pin_preview_tokens(scene: Node) -> Dictionary:
	var runtime := _module_ui_runtime(scene)
	if runtime == null:
		return {}
	return runtime.get("pin_preview_tokens") as Dictionary


func _set_module_ui_pin_preview_tokens(scene: Node, tokens: Dictionary) -> void:
	var runtime := _module_ui_runtime(scene)
	if runtime != null:
		runtime.set("pin_preview_tokens", tokens.duplicate())


func _module_ui_sort_mode(scene: Node) -> String:
	var runtime := _module_ui_runtime(scene)
	if runtime == null:
		return ModuleUiRuntime.SORT_LEVEL
	return str(runtime.get("sort_mode"))


func _set_module_ui_sort_mode(scene: Node, sort_mode: String) -> void:
	var runtime := _module_ui_runtime(scene)
	if runtime != null:
		runtime.set("sort_mode", ModuleUiRuntime.normalized_sort_mode(sort_mode))


func _ui_owned_node(scene: Node, property_name: String) -> Node:
	var node := scene.get(property_name) as Node
	if node != null and is_instance_valid(node):
		return node
	var navigation_shell := scene.call("_navigation_shell") as Object
	if navigation_shell == null:
		return null
	return navigation_shell.get(property_name) as Node


func _check_reverse_sort_in_place(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var before_order := _plan_track_order(scene)
	if before_order.size() < 4:
		_record("expected at least four module entries before reverse sort, found %s" % before_order.size())
		return
	var stack_before := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	if stack_before == null:
		_record("detail lazy stack was missing before reverse sort")
		return
	_set_module_ui_sort_mode(scene, "level_reverse")
	var refreshed := bool(scene.call("_skill_detail_surface").call("_try_refresh_detail_module_order_in_place"))
	if not refreshed:
		_record("reverse sort did not use the in-place module-order refresh")
		return
	for _i in range(3):
		await process_frame
	var after_order := _plan_track_order(scene)
	var expected := before_order.duplicate()
	expected.reverse()
	if after_order != expected:
		_record("reverse sort plan order mismatch. before=%s after=%s expected=%s" % [before_order, after_order, expected])
	var stack_after := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	if stack_after != stack_before:
		_record("reverse sort replaced the detail lazy stack instead of reordering in place")
	var active_tweens := _module_transition_tween_count(stack_after)
	if active_tweens <= 0:
		_record("reverse sort did not create any module-list transition tweens")
	for _i in range(36):
		await process_frame
	if _module_transition_tween_count(stack_after) > active_tweens:
		_record("module-list transition tweens multiplied after settling")


func _check_sort_menu_input_isolation(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.set("running_action_id", "")
	scene.set("running_skill_id", "")
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	scene.call("_navigation_shell").call("_show_module_sort_menu")
	for _i in range(4):
		await process_frame
	var menu := _ui_owned_node(scene, "module_sort_menu") as Control
	if menu == null or not is_instance_valid(menu) or not menu.visible:
		_record("sort menu isolation smoke could not show the sort menu")
		return
	var candidate_points := [
		menu.get_global_rect().get_center(),
		menu.get_global_rect().position + menu.get_global_rect().size * Vector2(0.50, 0.28),
		menu.get_global_rect().position + menu.get_global_rect().size * Vector2(0.50, 0.72),
	]
	var raw_tap_point := Vector2.ZERO
	for candidate in candidate_points:
		if bool(scene.call("_input_routing_shell").call("_event_points_inside_bottom_interactive_ui", _mouse_button_event(candidate, true))):
			raw_tap_point = candidate
			break
	if raw_tap_point == Vector2.ZERO:
		_record("sort menu isolation smoke did not find a menu point blocked by bottom interactive UI")
		return
	var cover_id := int(scene.call("_navigation_shell").call("_begin_page_switch_scroll_cover_timed"))
	await process_frame
	var transition_cover := instance_from_id(cover_id) as Control
	if transition_cover == null or not is_instance_valid(transition_cover):
		_record("sort menu isolation smoke could not create a page-switch cover")
	else:
		var expected_cover_bottom: float = scene.call("_navigation_shell").call("_global_chat_nav_cover_bottom_offset")
		if absf(transition_cover.offset_bottom - expected_cover_bottom) > 0.5:
			_record("page-switch cover bottom should stop at chat/nav with sort menu open. expected=%s actual=%s" % [expected_cover_bottom, transition_cover.offset_bottom])
		if not transition_cover.get_global_rect().has_point(raw_tap_point):
			_record("page-switch cover should cover the open sort menu area instead of being clipped above it")
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_handoff_cover_immediate")
	for _i in range(2):
		await process_frame
	if menu == null or not is_instance_valid(menu) or not menu.visible:
		_record("clearing the page-switch cover unexpectedly hid the sort menu")
		return
	var covered_card := scene.call("_input_routing_shell").call("_action_card_at_position", raw_tap_point) as Dictionary
	if covered_card.is_empty():
		var scroll := scene.call("_skill_detail_surface").get("detail_actions_scroll") as ScrollContainer
		if scroll != null:
			scroll.set("drag_scroll_position", float(mini(420, scroll.get_max_scroll_vertical())))
			scroll.set("scroll_vertical", mini(420, scroll.get_max_scroll_vertical()))
			scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
			await process_frame
			covered_card = scene.call("_input_routing_shell").call("_action_card_at_position", raw_tap_point) as Dictionary
	scene.call("_input", _mouse_button_event(raw_tap_point, true))
	scene.call("_input", _mouse_button_event(raw_tap_point, false))
	for _i in range(4):
		await process_frame
	if not str(scene.get("running_action_id")).is_empty() or not str(scene.get("running_skill_id")).is_empty():
		_record("sort menu raw input clicked through and started an activity")
	if not str(scene.call("_skill_detail_surface").get("action_card_press_key")).is_empty():
		_record("sort menu raw input left an action card press stuck")
	if not menu.visible:
		_record("sort menu raw input unexpectedly hid the sort menu")
	var reverse_button := scene.get("module_sort_reverse_button") as Button
	if reverse_button != null and is_instance_valid(reverse_button) and reverse_button.is_visible_in_tree():
		var button_point := reverse_button.get_global_rect().get_center()
		if not bool(scene.call("_input_routing_shell").call("_event_points_inside_bottom_interactive_ui", _mouse_button_event(button_point, true))):
			_record("sort menu reverse button is not treated as bottom interactive UI")
		scene.call("_input", _mouse_button_event(button_point, true))
		scene.call("_input", _mouse_button_event(button_point, false))
		for _i in range(4):
			await process_frame
		if not str(scene.get("running_action_id")).is_empty() or not str(scene.get("running_skill_id")).is_empty():
			_record("sort menu button raw input clicked through and started an activity")
		if not str(scene.call("_skill_detail_surface").get("action_card_press_key")).is_empty():
			_record("sort menu button raw input left an action card press stuck")
	if covered_card.is_empty():
		_record("sort menu isolation smoke did not find an action card underneath the menu; click-through guard was checked without overlap")
	scene.call("_navigation_shell").call("_hide_module_sort_menu")


func _check_normal_action_info_chip_behavior(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_action_runtime").set("activity_start_count", maxi(1, int(scene.call("_action_runtime").get("activity_start_count"))))
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("normal action info chip smoke could not find an action module key")
		return
	var lookup := _registered_action_card_for_module(scene, first_key)
	var card := lookup.get("card", {}) as Dictionary
	if card.is_empty():
		_record("normal action info chip smoke could not find a registered action card")
		return
	for stat_key in ["xp", "stamina", "time", "success"]:
		var label := card.get(stat_key, null) as Label
		if label == null or not is_instance_valid(label):
			_record("normal action card is missing %s stat label" % stat_key)
			continue
		if label.text.strip_edges().is_empty():
			_record("normal action card left %s stat label empty" % stat_key)
	await _assert_action_info_chips_fill(scene, card, "normal action info chip")


func _check_pin_refresh_transition(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("could not find an action module key for pin transition smoke")
		return
	var second_key := _nth_action_module_key(scene, skill_id, 1)
	if second_key.is_empty() or second_key == first_key:
		_record("could not find a second action module key for pin order smoke")
		return
	var pinned_order := _module_ui_pinned_order(scene)
	pinned_order.append(first_key)
	pinned_order.append(second_key)
	_set_module_ui_pinned_order(scene, pinned_order)
	var refresh_result = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", 0, skill_id, true)
	if refresh_result != null:
		await refresh_result
	for _i in range(4):
		await process_frame
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	var shelf := _find_named_descendant(stack, "PinnedModuleShelf")
	if shelf != null and is_instance_valid(shelf) and shelf.is_visible_in_tree():
		_record("pin refresh rendered a pinned shelf on the skill page even though pins should only appear in the pin menu")
	var normal_copy_after_pin := _find_original_module_control(stack, first_key)
	if normal_copy_after_pin == null:
		_record("pin refresh could not find the original module copy")
	else:
		var normal_key_after_pin := str(scene._skill_detail_surface()._module_list_transition_key_for_control(normal_copy_after_pin))
		if normal_key_after_pin != first_key:
			_record("original module transition key changed after pinning: %s" % normal_key_after_pin)
	if _find_original_module_control(stack, second_key) == null:
		_record("pin refresh could not find the second original module copy")
	return
	if shelf == null:
		_record("pin refresh did not render the pinned module shelf")
	else:
		var shelf_keys := _pinned_shelf_copy_keys_in_order(shelf)
		if shelf_keys != [first_key, second_key]:
			_record("pinned shelf order mismatch. expected=%s actual=%s" % [[first_key, second_key], shelf_keys])
		var shelf_title := _find_named_descendant(shelf, "PinnedModuleShelfTitle") as Label
		if shelf_title == null or not is_instance_valid(shelf_title):
			_record("pinned shelf title label was not named for placement validation")
		elif shelf_title.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER:
			_record("pinned shelf title should be centered so the pin badge does not cover it")
		if _find_named_descendant(shelf, "PinnedModuleShelfDivider") == null:
			_record("pinned shelf did not render its divider")
	if _module_transition_tween_count(stack) <= 0:
		_record("pin refresh did not create module-list transition tweens")
	var shelf_copy := _find_control_with_meta(stack, "module_ui_pinned_shelf_copy", true)
	if shelf_copy == null:
		_record("pin refresh did not mark a pinned shelf copy")
	else:
		var shelf_key := str(scene._skill_detail_surface()._module_list_transition_key_for_control(shelf_copy))
		if shelf_key != "pinned_shelf:%s" % first_key:
			_record("pinned shelf copy transition key should be distinct from the original module: %s" % shelf_key)
		var expected_card_key := "pinned_shelf:%s" % first_key
		var action_cards := scene.get("action_cards") as Dictionary
		if first_key.begins_with("action:"):
			if not action_cards.has(expected_card_key):
				_record("pinned shelf action card was not registered under its unique shelf key: %s" % expected_card_key)
			else:
				var shelf_card := action_cards.get(expected_card_key, {}) as Dictionary
				var shelf_zones := shelf_card.get("module_action_zones", {}) as Dictionary
				var shelf_collapse_zone := shelf_zones.get("collapse", null) as Control
				if shelf_collapse_zone != null and is_instance_valid(shelf_collapse_zone) and shelf_collapse_zone.is_inside_tree():
					_record("pinned shelf action card kept an active collapse zone")
				for stat_key in ["xp", "stamina", "time", "success"]:
					var label := shelf_card.get(stat_key, null) as Label
					if label == null or not is_instance_valid(label):
						_record("pinned shelf action card is missing %s stat label" % stat_key)
						continue
					if label.text.strip_edges().is_empty():
						_record("pinned shelf action card left %s stat label empty" % stat_key)
				var pop := shelf_card.get("pop", null) as Control
				if pop != null and is_instance_valid(pop) and pop.is_inside_tree():
					var stamina := scene.get("stamina") as Dictionary
					stamina[str(shelf_card.get("skill_id", ""))] = float(SkillState.max_stamina(scene, str(shelf_card.get("skill_id", ""))))
					scene.set("stamina", stamina)
					var tap_point := _card_body_tap_point(scene, pop, str(shelf_card.get("skill_id", "")), str(shelf_card.get("action_id", "")))
					scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
					var navigation_shell = scene.call("_navigation_shell")
					var shelf_direct_hit := navigation_shell.call("_pinned_shelf_action_card_at_position", tap_point) as Dictionary
					scene.call("_input", _mouse_button_event(tap_point, true))
					var captured_press_key := str(scene.call("_skill_detail_surface").get("action_card_press_key"))
					var hit_after_press := scene.call("_input_routing_shell").call("_action_card_at_position", tap_point) as Dictionary
					scene.call("_input", _mouse_button_event(tap_point, false))
					for _i in range(4):
						await process_frame
					if str(scene.get("running_skill_id")) != str(shelf_card.get("skill_id", "")) or str(scene.get("running_action_id")) != str(shelf_card.get("action_id", "")):
						_record("pinned shelf action card did not start through the real input path. screen=%s tap=%s press_key=%s direct_key=%s hit_key=%s hit_skill=%s hit_action=%s running=%s:%s" % [
							str(scene.get("current_screen")),
							tap_point,
							captured_press_key,
							str((shelf_direct_hit.get("card", {}) as Dictionary).get("card_key", "")),
							str((hit_after_press.get("card", {}) as Dictionary).get("card_key", "")),
							str(hit_after_press.get("skill_id", "")),
							str(hit_after_press.get("action_id", "")),
							str(scene.get("running_skill_id")),
							str(scene.get("running_action_id"))
						])
					else:
						scene.set("action_progress", 0.0)
						scene.set("action_opportunity_missed", true)
						scene.set("action_opportunity_consumed", false)
						scene.call("_skill_detail_surface").set("last_action_card_tap_msec", 0)
						var shelf_stop_routed := bool(navigation_shell.call("_begin_pinned_shelf_action_card_press", shelf_card, tap_point, 11))
						if not shelf_stop_routed:
							_record("pinned shelf running action card did not capture a stop tap")
						else:
							scene.call("_input", _screen_touch_event(tap_point, false, 11))
							for _i in range(4):
								await process_frame
							if not str(scene.get("running_action_id")).is_empty() or not str(scene.get("running_skill_id")).is_empty():
								_record("pinned shelf running action card tap did not stop the activity")
					var top_right_point := pop.get_global_rect().position + Vector2(pop.get_global_rect().size.x - 54.0, 54.0)
					var action_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", top_right_point) as Dictionary
					if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "collapse":
						_record("pinned shelf duplicate still routes a top-right collapse action")
					if bool(_module_ui_collapsed(scene).get(first_key, false)):
						_record("pinned shelf duplicate became collapsed during duplicate interaction smoke")
					scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
					var nav_bar := scene.get("nav_bar") as Control
					if nav_bar != null and is_instance_valid(nav_bar) and nav_bar.is_visible_in_tree():
						var nav_release_point := nav_bar.get_global_rect().get_center()
						if not bool(scene.call("_input_routing_shell").call("_event_points_inside_bottom_interactive_ui", _mouse_button_event(nav_release_point, false))):
							_record("pinned shelf bottom-release smoke did not pick a protected bottom UI point")
						scene.call("_input", _mouse_button_event(tap_point, true))
						scene.call("_input", _mouse_button_event(nav_release_point, false))
						for _i in range(4):
							await process_frame
						if not str(scene.call("_skill_detail_surface").get("action_card_press_key")).is_empty():
							_record("pinned shelf release over bottom UI left action_card_press_key stuck")
						if not str(scene.get("running_action_id")).is_empty() or not str(scene.get("running_skill_id")).is_empty():
							_record("pinned shelf release over bottom UI started the activity underneath")
				await _assert_action_info_chips_fill(scene, shelf_card, "pinned shelf action info chip")
		elif first_key.begins_with("fishing_area:"):
			if not action_cards.has(expected_card_key):
				_record("pinned shelf fishing area was not registered under its unique shelf key: %s" % expected_card_key)
			else:
				var area_card := action_cards.get(expected_card_key, {}) as Dictionary
				for stat_key in ["area_xp", "area_yield"]:
					var area_label := area_card.get(stat_key, null) as Label
					if area_label == null or not is_instance_valid(area_label):
						_record("pinned shelf fishing area is missing %s label" % stat_key)
						continue
					if area_label.text.strip_edges().is_empty():
						_record("pinned shelf fishing area left %s label empty" % stat_key)
				var method_slots := area_card.get("method_slots", {}) as Dictionary
				if method_slots.is_empty():
					_record("pinned shelf fishing area did not register method slots")
				else:
					var method_card: Dictionary = {}
					for raw_method_card in method_slots.values():
						var candidate := raw_method_card as Dictionary
						if candidate.is_empty():
							continue
						var button := candidate.get("method_button", null) as Button
						if button != null and is_instance_valid(button) and not button.disabled:
							method_card = candidate
							break
					if method_card.is_empty():
						_record("pinned shelf fishing area did not expose an enabled method button")
					else:
						var method_button := method_card.get("method_button") as Button
						var action_id := str(method_card.get("action_id", ""))
						var area_key := str(method_card.get("fishing_area_key", ""))
						var area_pop := area_card.get("pop", null) as Control
						var owner_area_id := area_pop.get_instance_id() if area_pop != null and is_instance_valid(area_pop) else 0
						scene.set("running_skill_id", "")
						scene.set("running_action_id", "")
						_tap_fishing_method_button(scene, method_button, skill_id, action_id, area_key, owner_area_id)
						for _i in range(4):
							await process_frame
						if str(area_card.get("selected_action_id", "")) != action_id:
							_record("pinned shelf fishing method press did not update the visible area card selection")
						if str(scene.get("running_skill_id")) != skill_id or str(scene.get("running_action_id")) != action_id:
							_record("pinned shelf fishing method press did not start the real fishing action")
						await _assert_fishing_method_drag_release_cancels(scene, method_button, skill_id, action_id, area_key, owner_area_id, "pinned shelf fishing method")
	var original_copy := _find_original_module_control(stack, first_key)
	if original_copy == null:
		_record("pin refresh could not find the original unpinned module copy")
	else:
		var original_key := str(scene._skill_detail_surface()._module_list_transition_key_for_control(original_copy))
		if original_key != first_key:
			_record("original module transition key changed after pinning: %s" % original_key)
	if _find_original_module_control(stack, second_key) == null:
		_record("pin refresh could not find the second original unpinned module copy")
	if first_key.begins_with("action:"):
		var expected_shelf_unpin_card_key := "pinned_shelf:%s" % first_key
		var unpin_action_cards := scene.get("action_cards") as Dictionary
		var shelf_unpin_card := unpin_action_cards.get(expected_shelf_unpin_card_key, {}) as Dictionary
		var shelf_unpin_zones := shelf_unpin_card.get("module_action_zones", {}) as Dictionary
		var shelf_pin_zone := shelf_unpin_zones.get("pin", null) as Control
		if shelf_pin_zone == null or not is_instance_valid(shelf_pin_zone):
			_record("pinned shelf action card is missing its pin action zone")
		else:
			var shelf_pin_center := shelf_pin_zone.get_global_rect().get_center()
			scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
			scene.call("_input", _mouse_button_event(shelf_pin_center, true))
			scene.call("_input", _mouse_button_event(shelf_pin_center, false))
			for _i in range(4):
				await process_frame
			if str(scene.get("running_action_id")) == str(shelf_unpin_card.get("action_id", "")):
				_record("pinned shelf pin-zone tap clicked through and started the activity")
			if _module_ui_pinned_order(scene).has(first_key):
				_record("pinned shelf pin-zone tap did not unpin the module")
		if second_key.begins_with("action:"):
			_set_module_ui_pinned_order(scene, [second_key])
			var shelf_badge_refresh = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, skill_id, true)
			if shelf_badge_refresh != null:
				await shelf_badge_refresh
			for _i in range(6):
				await process_frame
			var visible_badge_card_key := "pinned_shelf:%s" % second_key
			var visible_badge_cards := scene.get("action_cards") as Dictionary
			var visible_badge_card := visible_badge_cards.get(visible_badge_card_key, {}) as Dictionary
			var visible_badge_pop := visible_badge_card.get("pop", null) as Control
			if visible_badge_pop == null or not is_instance_valid(visible_badge_pop) or not visible_badge_pop.is_inside_tree():
				_record("pinned shelf visible-pin smoke could not find the second shelf card")
			else:
				var visible_badge_zones := visible_badge_card.get("module_action_zones", {}) as Dictionary
				var visible_badge_pin_zone := visible_badge_zones.get("pin", null) as Control
				var shelf_badge := (scene.call("_skill_detail_surface") as Object).call("_module_pin_badge", visible_badge_pop) as TextureButton
				if shelf_badge == null or not is_instance_valid(shelf_badge) or not shelf_badge.visible:
					_record("pinned shelf action card did not show a visible pin badge")
				elif visible_badge_pin_zone == null or not is_instance_valid(visible_badge_pin_zone):
					_record("pinned shelf action card did not keep a circular pin zone")
				else:
					var shelf_visible_pin_point := visible_badge_pin_zone.get_global_rect().get_center()
					scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
					scene.call("_input", _mouse_button_event(shelf_visible_pin_point, true))
					scene.call("_input", _mouse_button_event(shelf_visible_pin_point, false))
					for _i in range(2):
						await process_frame
					if not shelf_badge.has_meta("module_pin_tween"):
						_record("pinned shelf visible pin badge tap did not start the unpin move-out tween")
					elif not shelf_badge.visible or not shelf_badge.disabled:
						_record("pinned shelf visible pin should remain visible and disabled while fading out")
					scene.call("_input", _mouse_button_event(shelf_visible_pin_point, true))
					scene.call("_input", _mouse_button_event(shelf_visible_pin_point, false))
					for _i in range(2):
						await process_frame
					if int(_module_ui_pin_preview_tokens(scene).get(second_key, 0)) > 0:
						_record("pinned shelf fading pin re-tap armed a preview token")
					if _module_ui_pinned_order(scene).has(second_key):
						_record("pinned shelf fading pin re-tap re-pinned the module")
					if str(scene.get("running_action_id")) == str(visible_badge_card.get("action_id", "")):
						_record("pinned shelf fading pin re-tap clicked through and started the activity")


func _check_immediate_pin_input_flow(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("immediate pin smoke could not find an action module key")
		return
	var action_key := first_key.substr("action:".length())
	var parts := action_key.split(":", false, 2)
	if parts.size() < 2:
		_record("immediate pin smoke expected a regular action module key")
		return
	var action_cards := scene.get("action_cards") as Dictionary
	var action_card_key := "%s:%s" % [str(parts[0]), str(parts[1])]
	var card := action_cards.get(action_card_key, {}) as Dictionary
	if card.is_empty():
		_record("immediate pin smoke could not find registered action card")
		return
	var pin_zone := (card.get("module_action_zones", {}) as Dictionary).get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("immediate pin smoke could not find pin action zone")
		return
	var pin_corner := pin_zone.get_global_rect().position
	var pin_corner_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", pin_corner) as Dictionary
	if not pin_corner_hit.is_empty():
		_record("pin action zone rectangular corner should not route as a circular action hit: %s" % pin_corner_hit)
	var pin_center := pin_zone.get_global_rect().get_center()
	var card_pop := card.get("pop", null) as Control
	if card_pop == null or not is_instance_valid(card_pop):
		_record("immediate pin smoke could not find card pop for direct gui_input coverage")
		return
	var zone_local_center := pin_zone.get_global_rect().get_center() - pin_zone.get_global_rect().position
	scene.call("_navigation_shell").call("_show_module_sort_menu")
	for _i in range(2):
		await process_frame
	var sort_menu := _ui_owned_node(scene, "module_sort_menu") as Control
	if sort_menu != null and is_instance_valid(sort_menu):
		sort_menu.position = pin_center - sort_menu.size * 0.5
		sort_menu.visible = true
		scene.call("_skill_detail_surface").call("_on_module_pin_zone_gui_input", _local_mouse_button_event(zone_local_center, true), first_key, card_pop.get_instance_id())
		for _i in range(2):
			await process_frame
		if int(_module_ui_pin_preview_tokens(scene).get(first_key, 0)) > 0 or _module_ui_pinned_order(scene).has(first_key):
			_record("direct pin-zone gui_input ignored protected sort menu coverage")
			var blocked_tokens := _module_ui_pin_preview_tokens(scene)
			blocked_tokens.erase(first_key)
			_set_module_ui_pin_preview_tokens(scene, blocked_tokens)
		if bool(scene.get("module_ui_runtime").call("pin_press_active")):
			scene.get("module_ui_runtime").call("clear_module_pin_press")
		scene.call("_navigation_shell").call("_hide_module_sort_menu")
	scene.call("_skill_detail_surface").call("_on_module_pin_zone_gui_input", _local_mouse_button_event(zone_local_center, true), first_key, card_pop.get_instance_id())
	for _i in range(2):
		await process_frame
	if not bool(scene.get("module_ui_runtime").call("pin_press_active")):
		_record("direct pin-zone gui_input did not start a pin press from local zone coordinates")
	elif str(scene.get("module_ui_runtime").call("pin_press_module_key")) != first_key:
		_record("direct pin-zone gui_input started a pin press for the wrong module")
	if _module_ui_pinned_order(scene).has(first_key):
		_record("direct pin-zone press pinned the module before release")
	if int(_module_ui_pin_preview_tokens(scene).get(first_key, 0)) > 0:
		_record("direct pin-zone press armed a preview token")
	scene.get("module_ui_runtime").call("clear_module_pin_press")
	scene.call("_input", _mouse_button_event(pin_center, true))
	scene.call("_input", _mouse_button_event(pin_center, false))
	for _i in range(4):
		await process_frame
	if not _module_ui_pinned_order(scene).has(first_key):
		_record("first pin-zone tap did not pin the module")
	if str(scene.get("running_action_id")) == str(parts[1]):
		_record("first pin-zone tap clicked through and started the activity")
	if int(_module_ui_pin_preview_tokens(scene).get(first_key, 0)) > 0:
		_record("first pin-zone tap left a preview token armed")
	var pin_badge := (scene.call("_skill_detail_surface") as Object).call("_module_pin_badge", card.get("pop", null)) as TextureButton
	if pin_badge == null or not is_instance_valid(pin_badge):
		_record("first pin-zone tap did not create a pin badge")
	else:
		var expected_size: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_SIZE
		var settled_position: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
		if pin_badge.texture_normal == null:
			_record("pin badge is missing the approved pin texture")
		if not pin_badge.size.is_equal_approx(expected_size):
			_record("pin badge size mismatch. expected=%s actual=%s" % [expected_size, pin_badge.size])
		if expected_size.x < 150.0 or expected_size.y < 150.0:
			_record("pin badge should stay large enough for the current oversized visual treatment: %s" % expected_size)
		if pin_badge.stretch_mode != TextureButton.STRETCH_KEEP_ASPECT:
			_record("pin badge art should scale up to the oversized badge bounds")
		if pin_badge.has_theme_stylebox_override("normal"):
			_record("pin badge should not draw a button/circle stylebox behind the pin art")
		if _find_named_descendant(card.get("pop", null), "ModulePinBuryMask") != null:
			_record("immediate pin badge created a visible bury-mask node instead of cropping the pin art")
		var body_point := _card_body_tap_point(scene, card.get("pop", null), str(parts[0]), str(parts[1]))
		var body_hit := scene.call("_input_routing_shell").call("_action_card_at_position", body_point) as Dictionary
		if body_hit.is_empty():
			_record("oversized immediate pin badge blocked normal body hit-testing outside the pin circle")
		if not pin_badge.has_meta("module_pin_tween"):
			_record("immediate pin badge did not start its poke-in animation")
		if not pin_badge.disabled:
			_record("immediate pin badge should be disabled while its poke-in animation plays")
		if pin_badge.position.is_equal_approx(settled_position) and pin_badge.modulate.a >= 0.99:
			_record("immediate pin badge should pass through an in-between poke animation pose before settling")
	await _wait_for_badge_tween_done(pin_badge, 120)
	await _wait_for_pin_anchor_idle(scene, 120)
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var pinned_lookup := _registered_action_card_for_module(scene, first_key)
	var pinned_card := pinned_lookup.get("card", {}) as Dictionary
	var pinned_pin_zone := (pinned_card.get("module_action_zones", {}) as Dictionary).get("pin", null) as Control
	if pinned_card.is_empty() or pinned_pin_zone == null or not is_instance_valid(pinned_pin_zone):
		_record("confirmed pinned module did not keep a visible original pin zone")
		return
	var pinned_badge := (scene.call("_skill_detail_surface") as Object).call("_module_pin_badge", pinned_card.get("pop", null)) as TextureButton
	if pinned_badge == null or not is_instance_valid(pinned_badge) or not pinned_badge.visible:
		_record("confirmed pinned module did not keep a visible original pin badge")
		return
	var settled_position_after: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	if not pinned_badge.position.is_equal_approx(settled_position_after):
		_record("confirmed pin badge did not settle into its pinned corner position after refresh")
	if pinned_badge.rotation_degrees != 0.0 or not pinned_badge.scale.is_equal_approx(Vector2.ONE):
		_record("confirmed pin badge should be settled with no preview tilt or scale after refresh")
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	var pinned_pin_center := pinned_pin_zone.get_global_rect().get_center()
	scene.call("_input", _mouse_button_event(pinned_pin_center, true))
	scene.call("_input", _mouse_button_event(pinned_pin_center, false))
	for _i in range(2):
		await process_frame
	if not pinned_badge.has_meta("module_pin_tween"):
		_record("original circular pin-zone tap did not start the unpin move-out tween")
	elif not pinned_badge.visible or not pinned_badge.disabled:
		_record("original visible pinned pin should remain visible and disabled while fading out")
	scene.call("_input", _mouse_button_event(pinned_pin_center, true))
	scene.call("_input", _mouse_button_event(pinned_pin_center, false))
	for _i in range(2):
		await process_frame
	if int(_module_ui_pin_preview_tokens(scene).get(first_key, 0)) > 0:
		_record("original fading pinned pin re-tap armed a preview token")
	if _module_ui_pinned_order(scene).has(first_key):
		_record("original fading pinned pin re-tap re-pinned the module")
	if str(scene.get("running_action_id")) == str(parts[1]):
		_record("original fading pinned pin re-tap clicked through and started the activity")
	var settled_position: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
	if pinned_badge.position.is_equal_approx(settled_position) and pinned_badge.modulate.a >= 0.99:
		_record("original visible pinned pin did not visibly move or fade after unpin")
	for _i in range(8):
		await process_frame
	if _module_ui_pinned_order(scene).has(first_key):
		_record("tapping the original visible pinned pin did not unpin the module")
	if int(_module_ui_pin_preview_tokens(scene).get(first_key, 0)) > 0:
		_record("original visible pinned pin tap left a preview token armed")
	if str(scene.get("running_action_id")) == str(parts[1]):
		_record("original visible pinned pin tap clicked through and started the activity")
	for _i in range(10):
		await process_frame
	scene.set("module_ui_pending_pin_scroll_anchor", {})
	var cleanup_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if cleanup_result != null:
		await cleanup_result
	for _i in range(4):
		await process_frame


func _check_pin_confirm_preserves_source_scroll(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.set("module_ui_pending_pin_scroll_anchor", {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var scroll := scene.call("_skill_detail_surface").get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll):
		_record("pin no-bump smoke could not find detail scroll")
		return
	var target_scroll := mini(420, scroll.get_max_scroll_vertical())
	scroll.set("drag_scroll_position", float(target_scroll))
	scroll.set("scroll_vertical", target_scroll)
	for _i in range(2):
		await process_frame
	var visible_pair := _visible_normal_action_module_pair(scene, scroll, skill_id)
	if visible_pair.is_empty():
		_record("pin no-bump smoke could not find a visible normal source module")
		return
	var first_key := str(visible_pair.get("module_key", ""))
	var card_pop := visible_pair.get("control") as Control
	if first_key.is_empty() or card_pop == null or not is_instance_valid(card_pop):
		_record("pin no-bump smoke visible source module was invalid")
		return
	var source_y_before := card_pop.get_global_rect().position.y
	var scroll_before := scroll.scroll_vertical
	if scroll_before <= 0:
		return
	scene.call("_skill_detail_surface").call("_pin_module_ui_key", first_key, card_pop.get_instance_id())
	var observed_pin_cover := false
	for _cover_wait_i in range(80):
		await process_frame
		var pin_cover := scene.get("skill_swipe_handoff_cover") as Control
		if pin_cover == null or not is_instance_valid(pin_cover):
			continue
		if not bool(pin_cover.get_meta("module_pin_refresh_opaque_cover", false)):
			continue
		observed_pin_cover = true
		if pin_cover.get_child_count() != 1:
			_record("pin refresh cover should be opaque paper only, not a previous-page snapshot. child_count=%s" % pin_cover.get_child_count())
		break
	await _wait_for_pin_anchor_idle(scene, 140)
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var refreshed_scroll := scene.call("_skill_detail_surface").get("detail_actions_scroll") as ScrollContainer
	if refreshed_scroll == null or not is_instance_valid(refreshed_scroll):
		_record("pin no-bump smoke lost detail scroll after pin refresh")
		return
	var anchored_source := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", refreshed_scroll, first_key) as Control
	if anchored_source == null or not is_instance_valid(anchored_source):
		_record("pin no-bump smoke could not find the normal source module after pin")
		return
	var source_y_after := anchored_source.get_global_rect().position.y
	if absf(source_y_after - source_y_before) > 8.0:
		_record("pin no-bump smoke let the source module move. before=%s after=%s scroll_before=%s scroll_after=%s max_scroll=%s anchor_debug=%s" % [
			source_y_before,
			source_y_after,
			scroll_before,
			refreshed_scroll.scroll_vertical,
			refreshed_scroll.get_max_scroll_vertical(),
			str(scene.get("module_ui_pin_scroll_anchor_debug"))
		])
	if absf(float(refreshed_scroll.scroll_vertical - scroll_before)) > 3.0:
		_record("pin no-bump smoke changed scroll even though no pinned shelf is inserted. before=%s after=%s" % [scroll_before, refreshed_scroll.scroll_vertical])
	var pinned_source_y_before := anchored_source.get_global_rect().position.y
	var pinned_scroll_before := refreshed_scroll.scroll_vertical
	scene.call("_skill_detail_surface").call("_unpin_module_ui_key", first_key, anchored_source.get_instance_id())
	await _wait_for_pin_anchor_idle(scene, 140)
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var unpinned_scroll := scene.call("_skill_detail_surface").get("detail_actions_scroll") as ScrollContainer
	if unpinned_scroll == null or not is_instance_valid(unpinned_scroll):
		_record("pin no-bump smoke lost detail scroll after unpin refresh")
		return
	var unpinned_source := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", unpinned_scroll, first_key) as Control
	if unpinned_source == null or not is_instance_valid(unpinned_source):
		_record("pin no-bump smoke could not find the normal source module after unpin")
		return
	var unpinned_source_y := unpinned_source.get_global_rect().position.y
	if absf(unpinned_source_y - pinned_source_y_before) > 8.0:
		_record("pin no-bump smoke let the source module move after unpin. before=%s after=%s scroll_before=%s scroll_after=%s max_scroll=%s anchor_debug=%s" % [
			pinned_source_y_before,
			unpinned_source_y,
			pinned_scroll_before,
			unpinned_scroll.scroll_vertical,
			unpinned_scroll.get_max_scroll_vertical(),
			str(scene.get("module_ui_pin_scroll_anchor_debug"))
		])
	if absf(float(unpinned_scroll.scroll_vertical - pinned_scroll_before)) > 3.0:
		_record("pin no-bump smoke changed scroll after unpin even though no pinned shelf is removed. before=%s after=%s" % [pinned_scroll_before, unpinned_scroll.scroll_vertical])
	_set_module_ui_pinned_order(scene, [])
	scene.set("module_ui_pending_pin_scroll_anchor", {})
	var cleanup_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if cleanup_result != null:
		await cleanup_result
	for _i in range(4):
		await process_frame


func _check_two_stage_collapse_input_flow(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("two-stage collapse smoke could not find an action module key")
		return
	var lookup := _registered_action_card_for_module(scene, first_key)
	var card := lookup.get("card", {}) as Dictionary
	var action_id := str(lookup.get("action_id", ""))
	if card.is_empty() or action_id.is_empty():
		_record("two-stage collapse smoke could not find registered action card")
		return
	var collapse_zone := (card.get("module_action_zones", {}) as Dictionary).get("collapse", null) as Control
	if collapse_zone == null or not is_instance_valid(collapse_zone):
		_record("two-stage collapse smoke could not find collapse action zone")
		return
	var collapse_corner := collapse_zone.get_global_rect().position
	var collapse_corner_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", collapse_corner) as Dictionary
	if not collapse_corner_hit.is_empty():
		_record("collapse action zone rectangular corner should not route as a circular action hit: %s" % collapse_corner_hit)
	var collapse_center := collapse_zone.get_global_rect().get_center()
	var card_pop := card.get("pop", null) as Control
	if card_pop == null or not is_instance_valid(card_pop):
		_record("two-stage collapse smoke could not find card pop for direct gui_input coverage")
		return
	var zone_local_center := collapse_zone.get_global_rect().get_center() - collapse_zone.get_global_rect().position
	scene.call("_navigation_shell").call("_show_module_sort_menu")
	for _i in range(2):
		await process_frame
	var sort_menu := _ui_owned_node(scene, "module_sort_menu") as Control
	if sort_menu != null and is_instance_valid(sort_menu):
		sort_menu.position = collapse_center - sort_menu.size * 0.5
		sort_menu.visible = true
		scene.call("_skill_detail_surface").call("_on_module_collapse_zone_gui_input", _local_mouse_button_event(zone_local_center, true), first_key, card_pop.get_instance_id())
		for _i in range(2):
			await process_frame
		var blocked_badge := _find_named_descendant(card_pop, "ModuleCollapseConfirmBadge") as Control
		if blocked_badge != null and is_instance_valid(blocked_badge) and blocked_badge.visible:
			_record("direct collapse-zone gui_input ignored protected sort menu coverage")
			blocked_badge.visible = false
			blocked_badge.disabled = true
		scene.call("_navigation_shell").call("_hide_module_sort_menu")
	scene.call("_skill_detail_surface").call("_on_module_collapse_zone_gui_input", _local_mouse_button_event(zone_local_center, true), first_key, card_pop.get_instance_id())
	scene.call("_skill_detail_surface").call("_on_module_collapse_zone_gui_input", _mouse_button_event(collapse_center, false), first_key, card_pop.get_instance_id())
	for _i in range(2):
		await process_frame
	var direct_badge := _find_named_descendant(card_pop, "ModuleCollapseConfirmBadge") as Control
	if direct_badge == null or not is_instance_valid(direct_badge) or not direct_badge.visible:
		_record("direct collapse-zone gui_input did not show confirm from local zone coordinates")
	else:
		direct_badge.visible = false
		direct_badge.disabled = true
	scene.call("_skill_detail_surface").call("_on_module_collapse_zone_gui_input", _local_mouse_button_event(zone_local_center, true), first_key, card_pop.get_instance_id())
	scene.call("_skill_detail_surface").call("_on_module_collapse_zone_gui_input", _mouse_motion_event(collapse_center + Vector2(0, 96)), first_key, card_pop.get_instance_id())
	scene.call("_skill_detail_surface").call("_on_module_collapse_zone_gui_input", _mouse_button_event(collapse_center + Vector2(0, 96), false), first_key, card_pop.get_instance_id())
	for _i in range(2):
		await process_frame
	var dragged_badge := _find_named_descendant(card_pop, "ModuleCollapseConfirmBadge") as Control
	if dragged_badge != null and is_instance_valid(dragged_badge) and dragged_badge.visible:
		_record("dragged collapse-zone press showed confirm while scrolling")
		dragged_badge.visible = false
		dragged_badge.disabled = true
	if bool(_module_ui_collapsed(scene).get(first_key, false)):
		_record("dragged collapse-zone press collapsed the module while scrolling")
	scene.call("_input", _mouse_button_event(collapse_center, true))
	scene.call("_input", _mouse_motion_event(collapse_center + Vector2(0, 96)))
	scene.call("_input", _mouse_button_event(collapse_center + Vector2(0, 96), false))
	for _i in range(2):
		await process_frame
	var routed_dragged_badge := _find_named_descendant(card_pop, "ModuleCollapseConfirmBadge") as Control
	if routed_dragged_badge != null and is_instance_valid(routed_dragged_badge) and routed_dragged_badge.visible:
		_record("routed dragged collapse-zone press showed confirm while scrolling")
		routed_dragged_badge.visible = false
		routed_dragged_badge.disabled = true
	if bool(_module_ui_collapsed(scene).get(first_key, false)):
		_record("routed dragged collapse-zone press collapsed the module while scrolling")
	scene.call("_input", _mouse_button_event(collapse_center, true))
	scene.call("_input", _mouse_button_event(collapse_center, false))
	for _i in range(4):
		await process_frame
	if bool(_module_ui_collapsed(scene).get(first_key, false)):
		_record("first collapse-zone tap should show confirm without collapsing")
	if str(scene.get("running_action_id")) == action_id:
		_record("first collapse-zone tap clicked through and started the activity")
	if int(_module_ui_pin_preview_tokens(scene).get(first_key, 0)) > 0:
		_record("first collapse-zone tap armed a pin preview token")
	if not str(scene.call("_skill_detail_surface").get("action_card_press_key")).is_empty():
		_record("first collapse-zone tap left an action card press stuck: %s" % str(scene.call("_skill_detail_surface").get("action_card_press_key")))
		scene.call("_skill_detail_surface").set("action_card_press_key", "")
	var badge := _find_named_descendant(card.get("pop", null) as Node, "ModuleCollapseConfirmBadge") as Control
	if badge == null or not is_instance_valid(badge) or not badge.visible:
		_record("first collapse-zone tap did not show the collapse confirm badge")
	var confirm_point := collapse_center if badge == null or not is_instance_valid(badge) else badge.get_global_rect().get_center()
	var confirm_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", confirm_point) as Dictionary
	if confirm_hit.is_empty() or str(confirm_hit.get("kind", "")) != "collapse":
		_record("visible collapse confirm badge center did not route as a collapse action: %s" % confirm_hit)
	scene.call("_input", _mouse_button_event(confirm_point, true))
	scene.call("_input", _mouse_button_event(confirm_point, false))
	for _i in range(8):
		await process_frame
	if not bool(_module_ui_collapsed(scene).get(first_key, false)):
		_record("second collapse-zone tap did not collapse the module")
	if str(scene.get("running_action_id")) == action_id:
		_record("second collapse-zone tap clicked through and started the activity")
	if int(_module_ui_pin_preview_tokens(scene).get(first_key, 0)) > 0:
		_record("second collapse-zone tap armed a pin preview token")
	if not str(scene.call("_skill_detail_surface").get("action_card_press_key")).is_empty():
		_record("second collapse-zone tap left an action card press stuck: %s" % str(scene.call("_skill_detail_surface").get("action_card_press_key")))
		scene.call("_skill_detail_surface").set("action_card_press_key", "")


func _check_collapse_refresh_transition(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("could not find an action module key for collapse transition smoke")
		return
	var collapsed := _module_ui_collapsed(scene)
	collapsed[first_key] = true
	_set_module_ui_collapsed(scene, collapsed)
	var refresh_result = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, skill_id, true)
	if refresh_result != null:
		await refresh_result
	for _i in range(4):
		await process_frame
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	var collapse_created_transition := _module_transition_tween_count(stack) > 0
	var collapsed_row := _find_control_with_meta(stack, "module_ui_collapsed_squeeze", true)
	if collapsed_row == null:
		collapsed_row = _find_named_descendant(stack, "CollapsedModuleSqueeze") as Control
	if collapsed_row == null:
		_record("collapse refresh did not render a squeezed collapsed module")
	else:
		var height_settled := false
		for _wait_i in range(28):
			var expected_wait_height := float(scene.call("_skill_detail_surface").call("_module_collapsed_squeeze_height"))
			if absf(collapsed_row.custom_minimum_size.y - expected_wait_height) <= 0.5:
				height_settled = true
				break
			await process_frame
		var expected_height := float(scene.call("_skill_detail_surface").call("_module_collapsed_squeeze_height"))
		if not height_settled and absf(collapsed_row.custom_minimum_size.y - expected_height) > 0.5:
			_record("squeezed collapsed module height mismatch. expected=%s actual=%s" % [expected_height, collapsed_row.custom_minimum_size.y])
		if collapsed_row.custom_minimum_size.y >= 260.0:
			_record("squeezed collapsed module should be significantly shorter than a full module: %s" % collapsed_row.custom_minimum_size.y)
		if not bool(collapsed_row.get_meta("module_ui_collapsed_squeeze", false)):
			_record("squeezed collapsed module should keep collapsed squeeze metadata")
		if _find_named_descendant(collapsed_row, "CollapsedModuleTitle") != null:
			_record("squeezed collapsed module should not rebuild a separate collapsed title label")
		var action_title := _first_nonempty_label(collapsed_row)
		if action_title == null or not is_instance_valid(action_title):
			_record("squeezed collapsed module did not keep the original title label")
		elif action_title.text.strip_edges().is_empty():
			_record("squeezed collapsed module title label was empty")
		var row_center := collapsed_row.get_global_rect().get_center()
		scene.call("_navigation_shell").call("_show_module_sort_menu")
		for _i in range(2):
			await process_frame
		var sort_menu := _ui_owned_node(scene, "module_sort_menu") as Control
		if sort_menu != null and is_instance_valid(sort_menu):
			var row_local_blocked_point := row_center - collapsed_row.get_global_rect().position
			sort_menu.position = row_center - sort_menu.size * 0.5
			sort_menu.visible = true
			if not bool(scene.call("_input_routing_shell").call("_event_points_inside_bottom_interactive_ui", _mouse_button_event(row_center, true))):
				_record("collapsed row protected-input smoke did not cover the row center")
			scene.call("_skill_detail_surface").call("_on_collapsed_module_row_gui_input", _local_mouse_button_event(row_local_blocked_point, true), first_key, collapsed_row.get_instance_id())
			for _i in range(2):
				await process_frame
			if not bool(_module_ui_collapsed(scene).get(first_key, false)):
				_record("direct collapsed-row gui_input expanded while covered by protected sort menu")
				var recollapsed := _module_ui_collapsed(scene)
				recollapsed[first_key] = true
				_set_module_ui_collapsed(scene, recollapsed)
			scene.call("_input", _mouse_button_event(row_center, true))
			scene.call("_input", _mouse_button_event(row_center, false))
			for _i in range(4):
				await process_frame
			if not bool(_module_ui_collapsed(scene).get(first_key, false)):
				_record("collapsed module expanded while covered by protected sort menu")
			scene.call("_navigation_shell").call("_hide_module_sort_menu")
		scene.call("_input", _mouse_button_event(row_center, true))
		scene.call("_input", _mouse_button_event(row_center, false))
		for _i in range(32):
			await process_frame
		if bool(_module_ui_collapsed(scene).get(first_key, false)):
			var force_expand := _module_ui_collapsed(scene)
			force_expand.erase(first_key)
			_set_module_ui_collapsed(scene, force_expand)
		var refreshed_stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
		if bool(_module_ui_collapsed(scene).get(first_key, false)) and (_find_control_with_meta(refreshed_stack, "module_ui_collapsed_squeeze", true) != null or _find_named_descendant(refreshed_stack, "CollapsedModuleSqueeze") != null):
			_record("direct collapsed-row gui_input did not refresh back to an expanded module")
	if not collapse_created_transition:
		_record("collapse refresh did not create module-list transition tweens")


func _check_pinned_page_action_card_registration(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	(scene.get("thieving_state") as Object).set("trophies", {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	var stamina := scene.get("stamina") as Dictionary
	stamina[skill_id] = float(SkillState.max_stamina(scene, skill_id))
	scene.set("stamina", stamina)
	var skill_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if skill_render_result != null:
		await skill_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("pinned page action smoke could not find an action module key")
		return
	_set_module_ui_pinned_order(scene, [first_key])
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(12):
		await process_frame
	scene.call("_update_ui", 0.0, true)
	var expected_card_key := str(scene._navigation_shell()._pinned_page_card_key(first_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(expected_card_key):
		_record("pinned page action card was not registered under its unique page key: %s" % expected_card_key)
		return
	var card := action_cards.get(expected_card_key, {}) as Dictionary
	var action_key := first_key.substr("action:".length())
	var parts := action_key.split(":", false, 2)
	if parts.size() >= 2:
		if str(card.get("skill_id", "")) != str(parts[0]) or str(card.get("action_id", "")) != str(parts[1]):
			_record("pinned page action card lost its real skill/action metadata")
	var pop := card.get("pop", null) as Control
	if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
		_record("pinned page action card pop is not in the scene tree")
		return
	var page_zones := card.get("module_action_zones", {}) as Dictionary
	var page_collapse_zone := page_zones.get("collapse", null) as Control
	if page_collapse_zone != null and is_instance_valid(page_collapse_zone) and page_collapse_zone.is_inside_tree():
		_record("pinned page action card kept an active collapse zone")
	var page_top_right_point := pop.get_global_rect().position + Vector2(pop.get_global_rect().size.x - 54.0, 54.0)
	var page_action_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", page_top_right_point) as Dictionary
	if not page_action_hit.is_empty() and str(page_action_hit.get("kind", "")) == "collapse":
		_record("pinned page duplicate still routes a top-right collapse action")
	var card_body_point := _card_body_tap_point(scene, pop, str(card.get("skill_id", "")), str(card.get("action_id", "")))
	var hit := scene.call("_input_routing_shell").call("_action_card_at_position", card_body_point) as Dictionary
	if hit.is_empty():
		_record("pinned page action card was visible but not found by tap hit-testing")
	elif str(hit.get("skill_id", "")) != str(card.get("skill_id", "")) or str(hit.get("action_id", "")) != str(card.get("action_id", "")):
		_record("pinned page hit-test routed to the wrong action card")
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	scene.call("_input", _mouse_button_event(card_body_point, true))
	var captured_press_key := str(scene.call("_skill_detail_surface").get("action_card_press_key"))
	if captured_press_key.is_empty():
		_record("pinned page action card press did not capture an action_card_press_key")
	if bool(scene.call("_input_routing_shell").call("_event_points_inside_bottom_interactive_ui", _mouse_button_event(card_body_point, false))):
		_record("pinned page action card release point is covered by bottom interactive UI")
	if not bool(scene.call("_input_routing_shell").call("_position_inside_detail_actions_viewport", card_body_point)):
		_record("pinned page action card release point is outside the detail actions viewport")
	scene.call("_input", _mouse_button_event(card_body_point, false))
	for _i in range(4):
		await process_frame
	if str(scene.get("running_skill_id")) != str(card.get("skill_id", "")) or str(scene.get("running_action_id")) != str(card.get("action_id", "")):
		_record("pinned page action card did not start through the real input path. expected=%s:%s running=%s:%s press_key=%s result=%s" % [
			str(card.get("skill_id", "")),
			str(card.get("action_id", "")),
			str(scene.get("running_skill_id")),
			str(scene.get("running_action_id")),
			str(scene.call("_skill_detail_surface").get("action_card_press_key")),
			str(scene.get("result_text")),
		])
	else:
		scene.call("_skill_detail_surface").set("last_action_card_tap_msec", 0)
		var stop_routed := bool(scene.call("_input_routing_shell").call("_route_action_card_press", card_body_point, 9))
		if not stop_routed:
			_record("pinned page running action card did not capture a stop hold")
		else:
			for _i in range(60):
				scene.call("_action_stop_hold").process_action(1.0 / 60.0)
			scene.call("_input", _screen_touch_event(card_body_point, false, 9))
			for _i in range(4):
				await process_frame
			if not str(scene.get("running_action_id")).is_empty() or not str(scene.get("running_skill_id")).is_empty():
				_record("pinned page running action card hold did not stop the activity")
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.call("_input", _mouse_button_event(card_body_point, true))
	scene.call("_input", _mouse_motion_event(card_body_point + Vector2(0, 260)))
	scene.call("_input", _mouse_button_event(card_body_point + Vector2(0, 260), false))
	for _i in range(4):
		await process_frame
	if not str(scene.call("_skill_detail_surface").get("action_card_press_key")).is_empty():
		_record("dragged pinned-page action press left action_card_press_key stuck")
	if bool(card.get("card_3d_pressed", false)):
		_record("dragged pinned-page action press left the card visually pressed")
	for stat_key in ["xp", "stamina", "time", "success"]:
		var label := card.get(stat_key, null) as Label
		if label == null or not is_instance_valid(label):
			_record("pinned page action card is missing %s stat label" % stat_key)
			continue
		if label.text.strip_edges().is_empty():
			_record("pinned page action card left %s stat label empty" % stat_key)
	await _assert_action_info_chips_fill(scene, card, "pinned page action info chip")
	var page_pin_badge := (scene.call("_skill_detail_surface") as Object).call("_module_pin_badge", pop) as TextureButton
	var page_pin_zone := page_zones.get("pin", null) as Control
	if page_pin_badge == null or not is_instance_valid(page_pin_badge) or not page_pin_badge.visible:
		_record("pinned page action card did not show a visible pin badge")
	elif page_pin_zone == null or not is_instance_valid(page_pin_zone):
		_record("pinned page action card did not keep a circular pin zone")
	else:
		var visible_pin_point := page_pin_zone.get_global_rect().get_center()
		scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
		scene.call("_input", _mouse_button_event(visible_pin_point, true))
		scene.call("_input", _mouse_button_event(visible_pin_point, false))
		for _i in range(2):
			await process_frame
		if not page_pin_badge.has_meta("module_pin_tween"):
			_record("pinned page visible pin badge tap did not start the unpin move-out tween")
		elif not page_pin_badge.visible or not page_pin_badge.disabled:
			_record("pinned page visible pin should remain visible and disabled while fading out")
		var page_settled_position: Vector2 = ModuleUiRuntime.MODULE_PIN_BADGE_SETTLED_POSITION
		if page_pin_badge.position.is_equal_approx(page_settled_position) and page_pin_badge.modulate.a >= 0.99:
			_record("pinned page visible pin did not visibly move or fade after unpin")
		scene.call("_input", _mouse_button_event(visible_pin_point, true))
		scene.call("_input", _mouse_button_event(visible_pin_point, false))
		for _i in range(2):
			await process_frame
		if int(_module_ui_pin_preview_tokens(scene).get(first_key, 0)) > 0:
			_record("pinned page fading pin re-tap armed a preview token")
		if _module_ui_pinned_order(scene).has(first_key):
			_record("pinned page fading pin re-tap re-pinned the module")
		if str(scene.get("running_action_id")) == str(card.get("action_id", "")):
			_record("pinned page fading pin re-tap clicked through and started the activity")
		for _i in range(6):
			await process_frame
		if str(scene.get("running_action_id")) == str(card.get("action_id", "")):
			_record("pinned page visible pin badge tap clicked through and started the activity")
		if _module_ui_pinned_order(scene).has(first_key):
			_record("pinned page visible pin badge tap did not unpin the module")
		_set_module_ui_pinned_order(scene, [first_key])
		pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
		if pinned_render_result != null:
			await pinned_render_result
		for _i in range(8):
			await process_frame
		scene.call("_update_ui", 0.0, true)
		action_cards = scene.get("action_cards") as Dictionary
		card = action_cards.get(expected_card_key, {}) as Dictionary
		pop = card.get("pop", null) as Control
		if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
			_record("pinned page action card pop disappeared after visible-pin re-render")
			return
	var pin_zone := (card.get("module_action_zones", {}) as Dictionary).get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("pinned page action card is missing its pin action zone")
	else:
		var pin_center := pin_zone.get_global_rect().get_center()
		scene.call("_input", _mouse_button_event(pin_center, true))
		scene.call("_input", _mouse_button_event(pin_center, false))
		for _i in range(4):
			await process_frame
		if str(scene.get("running_action_id")) == str(card.get("action_id", "")):
			_record("pinned page pin-zone tap clicked through and started the activity")
		if _module_ui_pinned_order(scene).has(first_key):
			_record("pinned page pin-zone tap did not unpin the module")


func _check_pinned_duplicates_ignore_source_collapse(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	(scene.get("thieving_state") as Object).set("trophies", {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("pinned/collapsed duplicate smoke could not find an action module key")
		return
	_set_module_ui_pinned_order(scene, [first_key])
	_set_module_ui_collapsed(scene, {first_key: true})
	var refresh_result = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, skill_id, true)
	if refresh_result != null:
		await refresh_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	var shelf := _find_named_descendant(stack, "PinnedModuleShelf")
	if shelf != null and is_instance_valid(shelf) and shelf.is_visible_in_tree():
		_record("pinned/collapsed duplicate smoke rendered a pinned shelf on the skill page")
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(12):
		await process_frame
	scene.call("_update_ui", 0.0, true)
	var content_scroll := scene.get("content_scroll") as Control
	if content_scroll == null or not is_instance_valid(content_scroll):
		_record("pinned/collapsed duplicate smoke did not create pinned content scroll")
		return
	var page_copy := _find_control_with_meta(content_scroll, "module_ui_pinned_page_copy", true)
	if page_copy == null:
		_record("collapsed source module did not render an expanded pinned-page duplicate")
	elif _find_control_with_meta(page_copy, "module_ui_collapsed_squeeze", true) != null or _find_named_descendant(page_copy, "CollapsedModuleRow") != null or _find_named_descendant(page_copy, "CollapsedModuleSqueeze") != null:
		_record("pinned-page duplicate rendered as collapsed when the source module was collapsed")
	var expected_page_card_key := str(scene._navigation_shell()._pinned_page_card_key(first_key))
	var page_action_cards := scene.get("action_cards") as Dictionary
	if not page_action_cards.has(expected_page_card_key):
		_record("expanded pinned-page duplicate was not registered under its unique key after source collapse")


func _check_restored_module_ui_preferences_render(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("restore-render smoke could not find an action module key")
		return
	var module_ui_runtime: Object = scene.get("module_ui_runtime")
	module_ui_runtime.restore_from_save({
		"module_ui_pinned_order": [first_key],
		"module_ui_collapsed": {first_key: true},
		"module_ui_collapse_save_version": ModuleUiRuntime.COLLAPSE_SAVE_VERSION,
		"module_ui_sort_mode": "level",
	}, ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE, Callable(scene.call("_skill_detail_surface"), "_module_ui_key_allows_pin_or_collapse"))
	if _module_ui_pinned_order(scene) != [first_key]:
		_record("restore-render smoke did not restore pinned order")
	if not bool(_module_ui_collapsed(scene).get(first_key, false)):
		_record("restore-render smoke did not restore collapsed state")
	if _module_ui_sort_mode(scene) != "level":
		_record("restore-render smoke did not restore sort mode")
	var restored_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if restored_render_result != null:
		await restored_render_result
	for _i in range(10):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		_record("restore-render smoke did not create a skill detail stack")
		return
	var shelf := _find_named_descendant(stack, "PinnedModuleShelf")
	if shelf != null and is_instance_valid(shelf) and shelf.is_visible_in_tree():
		_record("restore-render smoke rendered a pinned shelf on the skill page")
	var collapsed_row := _find_control_with_meta(stack, "module_ui_collapsed_squeeze", true)
	if collapsed_row == null:
		collapsed_row = _find_named_descendant(stack, "CollapsedModuleSqueeze") as Control
	if collapsed_row == null or str(collapsed_row.get_meta("module_ui_key", "")) != first_key:
		_record("restore-render smoke did not render the restored normal module as collapsed")
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(10):
		await process_frame
	var content_scroll := scene.get("content_scroll") as Control
	if content_scroll == null or not is_instance_valid(content_scroll):
		_record("restore-render smoke did not create pinned content scroll")
		return
	var page_copy := _find_control_with_meta(content_scroll, "module_ui_key", first_key)
	if page_copy == null:
		_record("restore-render smoke did not render the restored pinned-page duplicate")
	elif _find_control_with_meta(page_copy, "module_ui_collapsed_squeeze", true) != null or _find_named_descendant(page_copy, "CollapsedModuleRow") != null or _find_named_descendant(page_copy, "CollapsedModuleSqueeze") != null:
		_record("restore-render smoke rendered the restored pinned-page duplicate collapsed")


func _check_hard_reset_module_ui_preferences_render(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_action_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("hard-reset render smoke could not find an action module key")
		return
	_set_module_ui_pinned_order(scene, [first_key])
	_set_module_ui_collapsed(scene, {first_key: true})
	_set_module_ui_sort_mode(scene, "level_reverse")
	(scene.get("module_ui_runtime") as Object).reset()
	(scene.call("_navigation_shell") as Object).set("module_utility_collapsed", false)
	if not _module_ui_pinned_order(scene).is_empty():
		_record("hard-reset render smoke did not clear pinned order")
	if not _module_ui_collapsed(scene).is_empty():
		_record("hard-reset render smoke did not clear collapsed modules")
	if _module_ui_sort_mode(scene) != "level":
		_record("hard-reset render smoke did not restore default sort mode")
	var reset_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if reset_render_result != null:
		await reset_render_result
	for _i in range(10):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		_record("hard-reset render smoke did not create a skill detail stack")
		return
	if _find_named_descendant(stack, "PinnedModuleShelf") != null:
		_record("hard-reset render smoke still rendered a pinned shelf")
	var collapsed_row := _find_named_descendant(stack, "CollapsedModuleRow") as Control
	if collapsed_row == null:
		collapsed_row = _find_control_with_meta(stack, "module_ui_collapsed_squeeze", true)
	if collapsed_row == null:
		collapsed_row = _find_named_descendant(stack, "CollapsedModuleSqueeze") as Control
	if collapsed_row != null:
		_record("hard-reset render smoke still rendered a collapsed module row")
	if _find_original_module_control(stack, first_key) == null:
		_record("hard-reset render smoke did not render the reset module in its normal expanded position")


func _check_pinned_page_fishing_area_registration(scene: Node) -> void:
	var skill_id := "fishing"
	var skills := scene.get("skills") as Dictionary
	var original_fishing_state := (skills.get(skill_id, {}) as Dictionary).duplicate(true)
	var lowered_fishing_state := original_fishing_state.duplicate(true)
	lowered_fishing_state["level"] = 1
	lowered_fishing_state["xp"] = 0
	skills[skill_id] = lowered_fishing_state
	scene.set("skills", skills)
	scene.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	var skill_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if skill_render_result != null:
		await skill_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var locked_method_action_id := ""
	var first_key := ""
	for raw_area_def in scene.call("_fishing_ui_surface").render_area_modules(skill_id):
		var area_def := raw_area_def as Dictionary
		if area_def.is_empty():
			continue
		var method_ids := scene.call("_fishing_ui_surface").area_module_method_ids(skill_id, area_def) as Array
		if method_ids.size() < 2:
			continue
		var candidate_key := str(ModuleUiRuntime.fishing_area(scene.get("fishing_runtime").area_module_key(skill_id, area_def)))
		if candidate_key.is_empty() or not bool(scene.call("_skill_detail_surface").call("_module_ui_key_allows_pin_or_collapse", candidate_key)):
			continue
		first_key = candidate_key
		scene.call("_activity_unlock_runtime").call("_mark_action_manually_unlocked", skill_id, str(method_ids[0]))
		locked_method_action_id = str(method_ids[method_ids.size() - 1])
		var manual_unlocks := scene.get("manual_activity_unlocks") as Dictionary
		manual_unlocks.erase(str(scene.call("_action_key", skill_id, locked_method_action_id)))
		scene.set("manual_activity_unlocks", manual_unlocks)
		scene.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
		break
	if not first_key.begins_with("fishing_area:"):
		_record("pinned page fishing smoke did not find a fishing area module key")
		return
	_set_module_ui_pinned_order(scene, [first_key])
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(12):
		await process_frame
	scene.call("_update_ui", 0.0, true)
	var expected_card_key := str(scene._navigation_shell()._pinned_page_card_key(first_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(expected_card_key):
		_record("pinned page fishing area was not registered under its unique page key: %s" % expected_card_key)
		return
	var area_card := action_cards.get(expected_card_key, {}) as Dictionary
	if not bool(area_card.get("is_fishing_area", false)):
		_record("pinned page fishing card key did not point to a fishing area card")
	if str(area_card.get("skill_id", "")) != skill_id:
		_record("pinned page fishing area lost its real skill metadata")
	var pop := area_card.get("pop", null) as Control
	if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
		_record("pinned page fishing area pop is not in the scene tree")
	for stat_key in ["area_xp", "area_yield"]:
		var label := area_card.get(stat_key, null) as Label
		if label == null or not is_instance_valid(label):
			_record("pinned page fishing area is missing %s label" % stat_key)
			continue
		if label.text.strip_edges().is_empty():
			_record("pinned page fishing area left %s label empty" % stat_key)
	var method_slots := area_card.get("method_slots", {}) as Dictionary
	if method_slots.is_empty():
		_record("pinned page fishing area did not register method slots")
	else:
		var method_card: Dictionary = {}
		for raw_method_card in method_slots.values():
			var candidate := raw_method_card as Dictionary
			if candidate.is_empty():
				continue
			var button := candidate.get("method_button", null) as Button
			if button != null and is_instance_valid(button) and not button.disabled:
				method_card = candidate
				break
		if method_card.is_empty():
			_record("pinned page fishing area did not expose an enabled method button")
		else:
			var method_button := method_card.get("method_button") as Button
			var action_id := str(method_card.get("action_id", ""))
			var area_key := str(method_card.get("fishing_area_key", ""))
			var area_pop := area_card.get("pop", null) as Control
			var owner_area_id := area_pop.get_instance_id() if area_pop != null and is_instance_valid(area_pop) else 0
			_assert_pinned_control_tappable(scene, method_button, "pinned page fishing method button")
			scene.set("running_skill_id", "")
			scene.set("running_action_id", "")
			_tap_fishing_method_button(scene, method_button, skill_id, action_id, area_key, owner_area_id)
			for _i in range(4):
				await process_frame
			if str(area_card.get("selected_action_id", "")) != action_id:
				_record("pinned page fishing method press did not update the visible area card selection")
			if str(scene.get("running_skill_id")) != skill_id or str(scene.get("running_action_id")) != action_id:
				_record("pinned page fishing method press did not start the real fishing action")
			await _assert_fishing_method_drag_release_cancels(scene, method_button, skill_id, action_id, area_key, owner_area_id, "pinned page fishing method")
		var locked_method_card: Dictionary = {}
		for raw_method_card in method_slots.values():
			var candidate := raw_method_card as Dictionary
			if candidate.is_empty():
				continue
			var lock_root := candidate.get("lock_root", null) as Control
			var candidate_action_id := str(candidate.get("action_id", ""))
			if not locked_method_action_id.is_empty() and candidate_action_id != locked_method_action_id:
				continue
			var candidate_action := scene.call("_action_data", skill_id, candidate_action_id) as Dictionary
			var art_panel := candidate.get("art_panel", null) as Control
			if (
				(
					lock_root != null
					and is_instance_valid(lock_root)
					and lock_root.visible
					and lock_root.is_visible_in_tree()
					or art_panel != null
					and is_instance_valid(art_panel)
					and art_panel.visible
					and art_panel.is_visible_in_tree()
				)
				and not bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", skill_id, candidate_action))
			):
				locked_method_card = candidate
				break
		if locked_method_card.is_empty():
			_record("pinned page fishing area did not expose a locked method target for pinned-page lock routing")
		else:
			scene.set("selected_skill_id", "build")
			scene.set("running_skill_id", "")
			scene.set("running_action_id", "")
			var locked_root := locked_method_card.get("lock_root") as Control
			var padlock_hit_area := locked_root.get_meta("padlock_button", null) as Control if locked_root != null and is_instance_valid(locked_root) else null
			var fallback_art_panel := locked_method_card.get("art_panel", null) as Control
			var lock_point := padlock_hit_area.get_global_rect().get_center() if padlock_hit_area != null and is_instance_valid(padlock_hit_area) else (locked_root.get_global_rect().get_center() if locked_root != null and is_instance_valid(locked_root) else fallback_art_panel.get_global_rect().get_center())
			if not bool(scene.call("_input_routing_shell").call("_position_inside_detail_actions_viewport", lock_point)):
				_record("pinned page fishing method lock point is outside the pinned-page viewport")
			var lock_routed := bool(scene.call("_input_routing_shell").call("_route_fishing_method_lock_input", _mouse_button_event(lock_point, true)))
			for _i in range(4):
				await process_frame
			if not lock_routed:
				_record("pinned page fishing method lock did not route when selected_skill_id was not fishing")
			if str(scene.get("running_skill_id")) == skill_id and str(scene.get("running_action_id")) == str(locked_method_card.get("action_id", "")):
				_record("pinned page locked fishing method tap started the locked action")
			if str(scene.get("current_screen")) != "pinned":
				_record("pinned page locked fishing method tap navigated away from the pinned page")
			scene.call("_activity_unlock_runtime").call("_mark_action_manually_unlocked", skill_id, locked_method_action_id)
	skills = scene.get("skills") as Dictionary
	skills[skill_id] = original_fishing_state
	scene.set("skills", skills)
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()


func _check_pinned_page_fishing_offer_module(scene: Node) -> void:
	var module_key := "fishing_offer:net"
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.set("fishing_net_collected", false)
	scene.set("fish_currency", 0)
	var skill_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if skill_render_result != null:
		await skill_render_result
	for _i in range(8):
		await process_frame
	if not bool(scene.call("_skill_detail_surface").call("_module_ui_key_allows_pin_or_collapse", module_key)):
		return
	_record("pinned page fishing offer smoke unexpectedly allowed net offer pinning")
	_set_module_ui_pinned_order(scene, [module_key])
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(10):
		await process_frame
	var content_scroll := scene.get("content_scroll") as Control
	if content_scroll == null or not is_instance_valid(content_scroll):
		_record("pinned page fishing offer smoke did not create content scroll")
		return
	var offer_copy := _find_control_with_meta(content_scroll, "module_ui_key", module_key)
	if offer_copy == null:
		_record("pinned page fishing offer did not render its module copy")
		return
	if not bool(offer_copy.get_meta("module_ui_pinned_page_copy", false)):
		_record("pinned page fishing offer copy was not tagged as a pinned-page duplicate")
	var skill_detail_surface: Object = scene.call("_skill_detail_surface")
	var zones := skill_detail_surface.call("_module_action_zones_for_card", offer_copy) as Dictionary
	var collapse_zone := zones.get("collapse", null) as Control
	if collapse_zone != null and is_instance_valid(collapse_zone) and collapse_zone.is_inside_tree():
		_record("pinned page fishing offer kept an active collapse zone")
	var top_right_point := offer_copy.get_global_rect().position + Vector2(offer_copy.get_global_rect().size.x - 54.0, 54.0)
	var action_hit := skill_detail_surface.call("_module_action_circle_at_position", top_right_point) as Dictionary
	if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "collapse":
		_record("pinned page fishing offer still routes a top-right collapse action")
	var pin_zone := zones.get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("pinned page fishing offer is missing its pin action zone")
	else:
		var pin_center := pin_zone.get_global_rect().get_center()
		scene.call("_input", _mouse_button_event(pin_center, true))
		scene.call("_input", _mouse_button_event(pin_center, false))
		for _i in range(4):
			await process_frame
		if _module_ui_pinned_order(scene).has(module_key):
			_record("pinned page fishing offer pin-zone tap did not unpin the module")


func _check_pinned_shelf_fishing_offer_module(scene: Node) -> void:
	var module_key := "fishing_offer:net"
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.set("fishing_net_collected", false)
	scene.set("fish_currency", 0)
	var skill_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if skill_render_result != null:
		await skill_render_result
	for _i in range(8):
		await process_frame
	if not bool(scene.call("_skill_detail_surface").call("_module_ui_key_allows_pin_or_collapse", module_key)):
		_record("pinned shelf fishing offer smoke could not make net offer pinnable")
		return
	_set_module_ui_pinned_order(scene, [module_key])
	var refresh_result = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, "fishing", true)
	if refresh_result != null:
		await refresh_result
	for _i in range(10):
		await process_frame
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	if stack == null or not is_instance_valid(stack):
		_record("pinned shelf fishing offer smoke did not keep a skill detail stack")
		return
	var shelf := _find_named_descendant(stack, "PinnedModuleShelf")
	if shelf == null:
		_record("pinned shelf fishing offer did not render the shelf")
		return
	var offer_copy := _find_control_with_meta(shelf, "module_ui_key", module_key)
	if offer_copy == null:
		_record("pinned shelf fishing offer did not render its duplicate copy")
		return
	if not bool(offer_copy.get_meta("module_ui_pinned_shelf_copy", false)):
		_record("pinned shelf fishing offer copy was not tagged as a shelf duplicate")
	var skill_detail_surface: Object = scene.call("_skill_detail_surface")
	var zones := skill_detail_surface.call("_module_action_zones_for_card", offer_copy) as Dictionary
	var collapse_zone := zones.get("collapse", null) as Control
	if collapse_zone != null and is_instance_valid(collapse_zone) and collapse_zone.is_inside_tree():
		_record("pinned shelf fishing offer kept an active collapse zone")
	var top_right_point := offer_copy.get_global_rect().position + Vector2(offer_copy.get_global_rect().size.x - 54.0, 54.0)
	var action_hit := skill_detail_surface.call("_module_action_circle_at_position", top_right_point) as Dictionary
	if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "collapse":
		_record("pinned shelf fishing offer still routes a top-right collapse action")
	var pin_zone := zones.get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("pinned shelf fishing offer is missing its pin action zone")
	else:
		var pin_center := pin_zone.get_global_rect().get_center()
		scene.call("_input", _mouse_button_event(pin_center, true))
		scene.call("_input", _mouse_button_event(pin_center, false))
		for _i in range(4):
			await process_frame
		if _module_ui_pinned_order(scene).has(module_key):
			_record("pinned shelf fishing offer pin-zone tap did not unpin the module")


func _check_pinned_page_thieving_heist_registration(scene: Node) -> void:
	var skill_id := "thieving"
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var skill_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if skill_render_result != null:
		await skill_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_heist_module_key(scene)
	if first_key.is_empty():
		_record("pinned page heist smoke did not find a thieving heist module key")
		return
	var heist_id := first_key.substr("thieving_heist:".length())
	var trophies := (scene.get("thieving_state") as Object).get("trophies") as Dictionary
	trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
	(scene.get("thieving_state") as Object).set("trophies", trophies)
	_set_module_ui_pinned_order(scene, [first_key])
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(12):
		await process_frame
	scene.call("_update_ui", 0.0, true)
	var expected_card_key := str(scene._navigation_shell()._pinned_page_card_key(first_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(expected_card_key):
		_record("pinned page heist was not registered under its unique page key: %s" % expected_card_key)
		return
	var heist_card := action_cards.get(expected_card_key, {}) as Dictionary
	if str(heist_card.get("heist_id", "")) != heist_id:
		_record("pinned page heist lost its real heist metadata")
	var pop := heist_card.get("pop", null) as Control
	if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
		_record("pinned page heist pop is not in the scene tree")
		return
	var button := heist_card.get("button", null) as Button
	if button == null or not is_instance_valid(button) or button.disabled:
		_record("pinned page heist did not expose an enabled heist button")
	else:
		_assert_pinned_control_tappable(scene, button, "pinned page heist button")
	var page_zones := heist_card.get("module_action_zones", {}) as Dictionary
	var page_collapse_zone := page_zones.get("collapse", null) as Control
	if page_collapse_zone != null and is_instance_valid(page_collapse_zone) and page_collapse_zone.is_inside_tree():
		_record("pinned page heist kept an active collapse zone")
	var top_right_point := pop.get_global_rect().position + Vector2(pop.get_global_rect().size.x - 54.0, 54.0)
	var action_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", top_right_point) as Dictionary
	if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "collapse":
		_record("pinned page heist still routes a top-right collapse action")
	var pin_zone := page_zones.get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("pinned page heist is missing its pin action zone")
	else:
		var pin_center := pin_zone.get_global_rect().get_center()
		scene.call("_input", _mouse_button_event(pin_center, true))
		scene.call("_input", _mouse_button_event(pin_center, false))
		for _i in range(4):
			await process_frame
		if _module_ui_pinned_order(scene).has(first_key):
			_record("pinned page heist pin-zone tap did not unpin the module")
	trophies = (scene.get("thieving_state") as Object).get("trophies") as Dictionary
	trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
	(scene.get("thieving_state") as Object).set("trophies", trophies)
	_set_module_ui_pinned_order(scene, [first_key])
	pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(8):
		await process_frame
	action_cards = scene.get("action_cards") as Dictionary
	heist_card = action_cards.get(expected_card_key, {}) as Dictionary
	button = heist_card.get("button", null) as Button
	if button == null or not is_instance_valid(button) or button.disabled:
		_record("pinned page heist did not expose an enabled heist button after re-render")
	else:
		var before_state := ((scene.get("thieving_state") as Object).get("trophies") as Dictionary).get(heist_id, {}) as Dictionary
		_assert_pinned_control_tappable(scene, button, "pinned page heist button after re-render")
		var page_scroll := scene.get("content_scroll") as ScrollContainer
		if page_scroll != null and is_instance_valid(page_scroll):
			page_scroll.prepare_child_tap()
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		var heist_local_point := button.get_global_rect().get_center() - button.get_global_rect().position
		await _assert_thieving_heist_drag_release_cancels(scene, button, heist_id, "pinned page heist")
		trophies = (scene.get("thieving_state") as Object).get("trophies") as Dictionary
		trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
		(scene.get("thieving_state") as Object).set("trophies", trophies)
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		scene.call("_thieving_surface").call("_on_thieving_heist_button_input", _local_mouse_button_event(heist_local_point, true), heist_id, button)
		scene.call("_thieving_surface").call("_on_thieving_heist_button_input", _local_mouse_button_event(heist_local_point, false), heist_id, button)
		for _i in range(8):
			await process_frame
		var after_state := ((scene.get("thieving_state") as Object).get("trophies") as Dictionary).get(heist_id, {}) as Dictionary
		if after_state.is_empty():
			_record("pinned page heist press did not keep trophy state")
		elif not bool(after_state.get("stolen", false)) and int(after_state.get("cooldown_until_unix", 0)) <= int(before_state.get("cooldown_until_unix", 0)):
			_record("pinned page heist button press did not apply real heist success or jail state")


func _check_pinned_shelf_thieving_heist_registration(scene: Node) -> void:
	var skill_id := "thieving"
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var skill_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if skill_render_result != null:
		await skill_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_heist_module_key(scene)
	if first_key.is_empty():
		_record("pinned shelf heist smoke did not find a thieving heist module key")
		return
	var heist_id := first_key.substr("thieving_heist:".length())
	var trophies := (scene.get("thieving_state") as Object).get("trophies") as Dictionary
	trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
	(scene.get("thieving_state") as Object).set("trophies", trophies)
	_set_module_ui_pinned_order(scene, [first_key])
	var refresh_result = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, skill_id, true)
	if refresh_result != null:
		await refresh_result
	for _i in range(10):
		await process_frame
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	var shelf := _find_named_descendant(stack, "PinnedModuleShelf")
	if shelf == null:
		_record("pinned shelf heist did not render the shelf")
		return
	var shelf_copy := _find_control_with_meta(shelf, "module_ui_key", first_key)
	if shelf_copy == null:
		_record("pinned shelf heist did not render its duplicate copy")
	elif not bool(shelf_copy.get_meta("module_ui_pinned_shelf_copy", false)):
		_record("pinned shelf heist copy was not tagged as a shelf duplicate")
	var expected_card_key := "pinned_shelf:%s" % first_key
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(expected_card_key):
		_record("pinned shelf heist was not registered under its unique shelf key: %s" % expected_card_key)
		return
	var heist_card := action_cards.get(expected_card_key, {}) as Dictionary
	if str(heist_card.get("heist_id", "")) != heist_id:
		_record("pinned shelf heist lost its real heist metadata")
	var pop := heist_card.get("pop", null) as Control
	if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
		_record("pinned shelf heist pop is not in the scene tree")
		return
	var shelf_zones := heist_card.get("module_action_zones", {}) as Dictionary
	var shelf_collapse_zone := shelf_zones.get("collapse", null) as Control
	if shelf_collapse_zone != null and is_instance_valid(shelf_collapse_zone) and shelf_collapse_zone.is_inside_tree():
		_record("pinned shelf heist kept an active collapse zone")
	var top_right_point := pop.get_global_rect().position + Vector2(pop.get_global_rect().size.x - 54.0, 54.0)
	var action_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", top_right_point) as Dictionary
	if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "collapse":
		_record("pinned shelf heist still routes a top-right collapse action")
	var pin_zone := shelf_zones.get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("pinned shelf heist is missing its pin action zone")
	else:
		var pin_center := pin_zone.get_global_rect().get_center()
		scene.call("_input", _mouse_button_event(pin_center, true))
		scene.call("_input", _mouse_button_event(pin_center, false))
		for _i in range(4):
			await process_frame
		if _module_ui_pinned_order(scene).has(first_key):
			_record("pinned shelf heist pin-zone tap did not unpin the module")
	_set_module_ui_pinned_order(scene, [first_key])
	refresh_result = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, skill_id, true)
	if refresh_result != null:
		await refresh_result
	for _i in range(8):
		await process_frame
	action_cards = scene.get("action_cards") as Dictionary
	heist_card = action_cards.get(expected_card_key, {}) as Dictionary
	pop = heist_card.get("pop", null) as Control
	var button := heist_card.get("button", null) as Button
	if button == null or not is_instance_valid(button) or button.disabled:
		_record("pinned shelf heist did not expose an enabled heist button")
	else:
		var before_state := ((scene.get("thieving_state") as Object).get("trophies") as Dictionary).get(heist_id, {}) as Dictionary
		var shelf_scroll := scene.call("_skill_detail_surface").get("detail_actions_scroll") as ScrollContainer
		if shelf_scroll != null and is_instance_valid(shelf_scroll):
			shelf_scroll.prepare_child_tap()
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		var heist_local_point := button.get_global_rect().get_center() - button.get_global_rect().position
		await _assert_thieving_heist_drag_release_cancels(scene, button, heist_id, "pinned shelf heist")
		trophies = (scene.get("thieving_state") as Object).get("trophies") as Dictionary
		trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
		(scene.get("thieving_state") as Object).set("trophies", trophies)
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		scene.call("_thieving_surface").call("_on_thieving_heist_button_input", _local_mouse_button_event(heist_local_point, true), heist_id, button)
		scene.call("_thieving_surface").call("_on_thieving_heist_button_input", _local_mouse_button_event(heist_local_point, false), heist_id, button)
		for _i in range(8):
			await process_frame
		var after_state := ((scene.get("thieving_state") as Object).get("trophies") as Dictionary).get(heist_id, {}) as Dictionary
		if after_state.is_empty():
			_record("pinned shelf heist press did not keep trophy state")
		elif not bool(after_state.get("stolen", false)) and int(after_state.get("cooldown_until_unix", 0)) <= int(before_state.get("cooldown_until_unix", 0)):
			_record("pinned shelf heist button press did not apply real heist success or jail state")
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")


func _check_pinned_page_passive_module_registration(scene: Node) -> void:
	var skill_id := "woodcutting"
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var skill_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if skill_render_result != null:
		await skill_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_passive_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("pinned page passive smoke did not find a passive module key")
		return
	var module_id := first_key.substr(("action:%s:" % skill_id).length())
	scene.call("_activity_unlock_runtime").call("_mark_action_manually_unlocked", skill_id, module_id)
	var passive_modules := scene.get("passive_modules") as Dictionary
	var now := int(scene.call("_unix_now"))
	passive_modules[module_id] = {
		"unlocked": true,
		"stored": 3,
		"last_update": now,
		"time_seconds": 30,
		"yield": 1,
		"capacity": 10,
		"seeded": true
	}
	scene.set("passive_modules", passive_modules)
	scene.set("log_currency", 0)
	_set_module_ui_pinned_order(scene, [first_key])
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(12):
		await process_frame
	scene.call("_update_ui", 0.0, true)
	var expected_card_key := str(scene._navigation_shell()._pinned_page_card_key(first_key))
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(expected_card_key):
		_record("pinned page passive module was not registered under its unique page key: %s" % expected_card_key)
		return
	var passive_card := action_cards.get(expected_card_key, {}) as Dictionary
	if not bool(passive_card.get("passive", false)):
		_record("pinned page passive card key did not point to a passive module")
	if str(passive_card.get("skill_id", "")) != skill_id:
		_record("pinned page passive card lost its real skill metadata")
	var passive_module_id := str(passive_card.get("action_id", module_id))
	if passive_module_id.is_empty():
		passive_module_id = module_id
	if passive_module_id != module_id:
		_record("pinned page passive card action id diverged from module key. key=%s card=%s" % [module_id, passive_module_id])
	var pop := passive_card.get("pop", null) as Control
	if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
		_record("pinned page passive pop is not in the scene tree")
		return
	var stats := passive_card.get("stats", {}) as Dictionary
	for stat_key in ["time", "yield", "capacity"]:
		var label := stats.get(stat_key, null) as Label
		if label == null or not is_instance_valid(label):
			_record("pinned page passive module is missing %s stat label" % stat_key)
			continue
		if label.text.strip_edges().is_empty():
			_record("pinned page passive module left %s stat label empty" % stat_key)
	var collect_button := passive_card.get("button", null) as Button
	if collect_button == null or not is_instance_valid(collect_button) or collect_button.disabled:
		_record("pinned page passive module did not expose an enabled collect button")
	else:
		_assert_pinned_control_tappable(scene, collect_button, "pinned page passive collect button")
		passive_modules = scene.get("passive_modules") as Dictionary
		var press_now := int(scene.call("_unix_now"))
		passive_modules[passive_module_id] = {
			"unlocked": true,
			"stored": 3,
			"last_update": press_now,
			"time_seconds": 30,
			"yield": 1,
			"capacity": 10,
			"seeded": true
		}
		scene.set("passive_modules", passive_modules)
		scene.set("log_currency", 0)
		scene.call("_passive_firepit_surface").call("_clear_passive_button_press")
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		var collect_local_point := collect_button.get_global_rect().get_center() - collect_button.get_global_rect().position
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point, true), "collect", passive_module_id, "", null, collect_button)
		var shelf_drag_event := InputEventMouseMotion.new()
		shelf_drag_event.position = collect_local_point + Vector2(260.0, 0.0)
		shelf_drag_event.global_position = collect_button.get_global_rect().position + shelf_drag_event.position
		shelf_drag_event.relative = Vector2(260.0, 0.0)
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", shelf_drag_event, "collect", passive_module_id, "", null, collect_button)
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point + Vector2(260.0, 0.0), false), "collect", passive_module_id, "", null, collect_button)
		for _i in range(12):
			await process_frame
		var shelf_dragged_passive_modules := scene.get("passive_modules") as Dictionary
		var shelf_dragged_state := shelf_dragged_passive_modules.get(passive_module_id, {}) as Dictionary
		if int(shelf_dragged_state.get("stored", -1)) != 3:
			_record("pinned shelf passive drag-release collected stored loot")
		if int(scene.get("log_currency")) != 0:
			_record("pinned shelf passive drag-release added log currency")
		if scene.call("_passive_firepit_surface").get("passive_button_press_source") != null or not str(scene.call("_passive_firepit_surface").get("passive_button_press_kind")).is_empty():
			_record("pinned shelf passive drag-release left passive press state stuck")
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		passive_modules = scene.get("passive_modules") as Dictionary
		passive_modules[passive_module_id] = {
			"unlocked": true,
			"stored": 3,
			"last_update": press_now,
			"time_seconds": 30,
			"yield": 1,
			"capacity": 10,
			"seeded": true
		}
		scene.set("passive_modules", passive_modules)
		scene.set("log_currency", 0)
		scene.call("_passive_firepit_surface").call("_clear_passive_button_press")
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point, true), "collect", passive_module_id, "", null, collect_button)
		var drag_event := InputEventMouseMotion.new()
		drag_event.position = collect_local_point + Vector2(260.0, 0.0)
		drag_event.global_position = collect_button.get_global_rect().position + drag_event.position
		drag_event.relative = Vector2(260.0, 0.0)
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", drag_event, "collect", passive_module_id, "", null, collect_button)
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point + Vector2(260.0, 0.0), false), "collect", passive_module_id, "", null, collect_button)
		for _i in range(12):
			await process_frame
		var dragged_passive_modules := scene.get("passive_modules") as Dictionary
		var dragged_state := dragged_passive_modules.get(passive_module_id, {}) as Dictionary
		if int(dragged_state.get("stored", -1)) != 3:
			_record("pinned page passive drag-release collected stored loot")
		if int(scene.get("log_currency")) != 0:
			_record("pinned page passive drag-release added log currency")
		if scene.call("_passive_firepit_surface").get("passive_button_press_source") != null or not str(scene.call("_passive_firepit_surface").get("passive_button_press_kind")).is_empty():
			_record("pinned page passive drag-release left passive press state stuck")
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		passive_modules = scene.get("passive_modules") as Dictionary
		passive_modules[passive_module_id] = {
			"unlocked": true,
			"stored": 3,
			"last_update": press_now,
			"time_seconds": 30,
			"yield": 1,
			"capacity": 10,
			"seeded": true
		}
		scene.set("passive_modules", passive_modules)
		scene.set("log_currency", 0)
		scene.call("_passive_firepit_surface").call("_clear_passive_button_press")
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point, true), "collect", passive_module_id, "", null, collect_button)
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point, false), "collect", passive_module_id, "", null, collect_button)
		for _i in range(12):
			await process_frame
		var next_passive_modules := scene.get("passive_modules") as Dictionary
		var next_state := next_passive_modules.get(passive_module_id, {}) as Dictionary
		if int(next_state.get("stored", -1)) != 0:
			_record("pinned page passive collect button did not clear stored loot")
		if int(scene.get("log_currency")) < 3:
			_record("pinned page passive collect button did not add stored loot to log currency")
		scene.call("_passive_firepit_surface").call("_clear_passive_button_press")
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point, false), "collect", passive_module_id, "", null, collect_button)
		for _i in range(2):
			await process_frame
		if scene.call("_passive_firepit_surface").get("passive_button_press_source") != null or not str(scene.call("_passive_firepit_surface").get("passive_button_press_kind")).is_empty():
			_record("pinned page passive collect release-without-press left passive press state stuck")
	var page_info_button := passive_card.get("info_button", null) as Button
	var page_info_popover := passive_card.get("info_popover", null) as Control
	await _assert_passive_info_popover_fills(scene, passive_module_id, page_info_button, page_info_popover, "pinned page passive info")
	var page_zones := passive_card.get("module_action_zones", {}) as Dictionary
	var page_collapse_zone := page_zones.get("collapse", null) as Control
	if page_collapse_zone != null and is_instance_valid(page_collapse_zone) and page_collapse_zone.is_inside_tree():
		_record("pinned page passive module kept an active collapse zone")
	var top_right_point := pop.get_global_rect().position + Vector2(pop.get_global_rect().size.x - 54.0, 54.0)
	var action_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", top_right_point) as Dictionary
	if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "collapse":
		_record("pinned page passive module still routes a top-right collapse action")
	var pin_zone := page_zones.get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("pinned page passive module is missing its pin action zone")
	else:
		var pin_center := pin_zone.get_global_rect().get_center()
		scene.call("_input", _mouse_button_event(pin_center, true))
		scene.call("_input", _mouse_button_event(pin_center, false))
		for _i in range(4):
			await process_frame
		if _module_ui_pinned_order(scene).has(first_key):
			_record("pinned page passive pin-zone tap did not unpin the module")


func _check_normal_woodcutting_passive_log_pile_tap(scene: Node) -> void:
	var skill_id := "woodcutting"
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_passive_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("normal woodcutting passive tap smoke did not find a passive module key")
		return
	var module_id := first_key.substr(("action:%s:" % skill_id).length())
	scene.call("_activity_unlock_runtime").call("_mark_action_manually_unlocked", skill_id, module_id)
	var lookup := _registered_action_card_for_module(scene, first_key)
	var passive_card := lookup.get("card", {}) as Dictionary
	if passive_card.is_empty():
		_record("normal woodcutting passive tap smoke did not find a registered passive card")
		return
	var loot := passive_card.get("loot", null) as Control
	if loot == null or not is_instance_valid(loot) or not loot.is_inside_tree():
		_record("normal woodcutting passive tap smoke did not find the loot container")
		return
	var collect_button := passive_card.get("button", null) as Button
	if collect_button == null or not is_instance_valid(collect_button) or collect_button.disabled:
		_record("normal woodcutting passive tap smoke did not expose an enabled collect button")
		return
	await _assert_normal_passive_collect_tap(scene, passive_card, module_id, "hotspot")
	await _assert_normal_passive_collect_tap(scene, passive_card, module_id, "loot_fallback")


func _assert_normal_passive_collect_tap(scene: Node, passive_card: Dictionary, module_id: String, tap_mode: String) -> void:
	var passive_modules := scene.get("passive_modules") as Dictionary
	var now := int(scene.call("_unix_now"))
	passive_modules[module_id] = {
		"unlocked": true,
		"stored": 3,
		"last_update": now,
		"time_seconds": 30,
		"yield": 1,
		"capacity": 10,
		"seeded": true
	}
	scene.set("passive_modules", passive_modules)
	scene.set("log_currency", 0)
	scene.call("_passive_firepit_surface").call("_clear_passive_button_press")
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
	scene.call("_update_ui", 0.0, true)
	for _i in range(4):
		await process_frame
	var loot := passive_card.get("loot", null) as Control
	if loot == null or not is_instance_valid(loot):
		_record("normal woodcutting passive %s tap lost the loot container" % tap_mode)
		return
	var tap_point := Vector2.INF
	if tap_mode == "hotspot":
		var hotspot_id := int(loot.get_meta("passive_log_collect_hotspot_id", 0))
		var hotspot := instance_from_id(hotspot_id) as Button
		if hotspot == null or not is_instance_valid(hotspot) or not hotspot.is_inside_tree():
			_record("normal woodcutting passive tap smoke did not create a log collect hotspot")
			return
		if hotspot.mouse_filter != Control.MOUSE_FILTER_STOP:
			_record("normal woodcutting passive log hotspot should stop pointer input")
		tap_point = hotspot.get_global_rect().get_center()
	else:
		var loot_rect := loot.get_global_rect()
		tap_point = loot_rect.position + loot_rect.size * Vector2(0.12, 0.12)
	if bool(scene.call("_input_routing_shell").call("_event_points_inside_bottom_interactive_ui", _mouse_button_event(tap_point, true))):
		_record("normal woodcutting passive %s tap point is covered by bottom interactive UI" % tap_mode)
	if not bool(scene.call("_input_routing_shell").call("_position_inside_detail_actions_viewport", tap_point)):
		_record("normal woodcutting passive %s tap point is outside the detail viewport" % tap_mode)
	_dispatch_viewport_tap(scene, tap_point)
	for _i in range(16):
		await process_frame
	var next_modules := scene.get("passive_modules") as Dictionary
	var next_state := next_modules.get(module_id, {}) as Dictionary
	if int(next_state.get("stored", -1)) != 0:
		_record("normal woodcutting passive %s viewport tap did not clear stored logs. stored=%s currency=%s" % [
			tap_mode,
			int(next_state.get("stored", -1)),
			int(scene.get("log_currency"))
		])
	if int(scene.get("log_currency")) < 3:
		_record("normal woodcutting passive %s viewport tap did not move stored logs into currency" % tap_mode)
	if scene.call("_passive_firepit_surface").get("passive_button_press_source") != null or not str(scene.call("_passive_firepit_surface").get("passive_button_press_kind")).is_empty():
		_record("normal woodcutting passive %s viewport tap left passive press state stuck" % tap_mode)
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")


func _check_pinned_shelf_passive_module_registration(scene: Node) -> void:
	var skill_id := "woodcutting"
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var skill_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if skill_render_result != null:
		await skill_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var first_key := _first_passive_module_key(scene, skill_id)
	if first_key.is_empty():
		_record("pinned shelf passive smoke did not find a passive module key")
		return
	var module_id := first_key.substr(("action:%s:" % skill_id).length())
	scene.call("_activity_unlock_runtime").call("_mark_action_manually_unlocked", skill_id, module_id)
	var passive_modules := scene.get("passive_modules") as Dictionary
	var now := int(scene.call("_unix_now"))
	passive_modules[module_id] = {
		"unlocked": true,
		"stored": 4,
		"last_update": now,
		"time_seconds": 30,
		"yield": 1,
		"capacity": 10,
		"seeded": true
	}
	scene.set("passive_modules", passive_modules)
	scene.set("log_currency", 0)
	_set_module_ui_pinned_order(scene, [first_key])
	var refresh_result = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, skill_id, true)
	if refresh_result != null:
		await refresh_result
	for _i in range(10):
		await process_frame
	scene.call("_update_ui", 0.0, true)
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	var shelf := _find_named_descendant(stack, "PinnedModuleShelf")
	if shelf == null:
		_record("pinned shelf passive did not render the shelf")
		return
	var shelf_copy := _find_control_with_meta(shelf, "module_ui_key", first_key)
	if shelf_copy == null:
		_record("pinned shelf passive did not render its duplicate copy")
	elif not bool(shelf_copy.get_meta("module_ui_pinned_shelf_copy", false)):
		_record("pinned shelf passive copy was not tagged as a shelf duplicate")
	var expected_card_key := "pinned_shelf:%s" % first_key
	var action_cards := scene.get("action_cards") as Dictionary
	if not action_cards.has(expected_card_key):
		_record("pinned shelf passive module was not registered under its unique shelf key: %s" % expected_card_key)
		return
	var passive_card := action_cards.get(expected_card_key, {}) as Dictionary
	if not bool(passive_card.get("passive", false)):
		_record("pinned shelf passive card key did not point to a passive module")
	if str(passive_card.get("skill_id", "")) != skill_id:
		_record("pinned shelf passive card lost its real skill metadata")
	var passive_module_id := str(passive_card.get("action_id", module_id))
	if passive_module_id.is_empty():
		passive_module_id = module_id
	if passive_module_id != module_id:
		_record("pinned shelf passive card action id diverged from module key. key=%s card=%s" % [module_id, passive_module_id])
	var pop := passive_card.get("pop", null) as Control
	if pop == null or not is_instance_valid(pop) or not pop.is_inside_tree():
		_record("pinned shelf passive pop is not in the scene tree")
		return
	var stats := passive_card.get("stats", {}) as Dictionary
	for stat_key in ["time", "yield", "capacity"]:
		var label := stats.get(stat_key, null) as Label
		if label == null or not is_instance_valid(label):
			_record("pinned shelf passive module is missing %s stat label" % stat_key)
			continue
		if label.text.strip_edges().is_empty():
			_record("pinned shelf passive module left %s stat label empty" % stat_key)
	var collect_button := passive_card.get("button", null) as Button
	if collect_button == null or not is_instance_valid(collect_button) or collect_button.disabled:
		_record("pinned shelf passive module did not expose an enabled collect button")
	else:
		passive_modules = scene.get("passive_modules") as Dictionary
		var press_now := int(scene.call("_unix_now"))
		passive_modules[passive_module_id] = {
			"unlocked": true,
			"stored": 3,
			"last_update": press_now,
			"time_seconds": 30,
			"yield": 1,
			"capacity": 10,
			"seeded": true
		}
		scene.set("passive_modules", passive_modules)
		scene.set("log_currency", 0)
		scene.call("_passive_firepit_surface").call("_clear_passive_button_press")
		scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
		var collect_local_point := collect_button.get_global_rect().get_center() - collect_button.get_global_rect().position
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point, true), "collect", passive_module_id, "", null, collect_button)
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point, false), "collect", passive_module_id, "", null, collect_button)
		for _i in range(12):
			await process_frame
		var next_passive_modules := scene.get("passive_modules") as Dictionary
		var next_state := next_passive_modules.get(passive_module_id, {}) as Dictionary
		if int(next_state.get("stored", -1)) != 0:
			_record("pinned shelf passive collect button did not clear stored loot. module=%s unlocked=%s disabled=%s connections=%s stored=%s currency=%s" % [
				passive_module_id,
				bool(scene.call("_passive_modules_runtime").is_passive_module_unlocked(passive_module_id)),
				collect_button.disabled,
				collect_button.pressed.get_connections().size(),
				int(next_state.get("stored", -1)),
				int(scene.get("log_currency"))
			])
		if int(scene.get("log_currency")) < 3:
			_record("pinned shelf passive collect button did not add stored loot to log currency")
		scene.call("_passive_firepit_surface").call("_clear_passive_button_press")
		scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(collect_local_point, false), "collect", passive_module_id, "", null, collect_button)
		for _i in range(2):
			await process_frame
		if scene.call("_passive_firepit_surface").get("passive_button_press_source") != null or not str(scene.call("_passive_firepit_surface").get("passive_button_press_kind")).is_empty():
			_record("pinned shelf passive collect release-without-press left passive press state stuck")
	var shelf_info_button := passive_card.get("info_button", null) as Button
	var shelf_info_popover := passive_card.get("info_popover", null) as Control
	await _assert_passive_info_popover_fills(scene, passive_module_id, shelf_info_button, shelf_info_popover, "pinned shelf passive info")
	var shelf_zones := passive_card.get("module_action_zones", {}) as Dictionary
	var shelf_collapse_zone := shelf_zones.get("collapse", null) as Control
	if shelf_collapse_zone != null and is_instance_valid(shelf_collapse_zone) and shelf_collapse_zone.is_inside_tree():
		_record("pinned shelf passive module kept an active collapse zone")
	var top_right_point := pop.get_global_rect().position + Vector2(pop.get_global_rect().size.x - 54.0, 54.0)
	var action_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", top_right_point) as Dictionary
	if not action_hit.is_empty() and str(action_hit.get("kind", "")) == "collapse":
		_record("pinned shelf passive module still routes a top-right collapse action")
	var pin_zone := shelf_zones.get("pin", null) as Control
	if pin_zone == null or not is_instance_valid(pin_zone):
		_record("pinned shelf passive module is missing its pin action zone")
	else:
		var pin_center := pin_zone.get_global_rect().get_center()
		scene.call("_input", _mouse_button_event(pin_center, true))
		scene.call("_input", _mouse_button_event(pin_center, false))
		for _i in range(4):
			await process_frame
		if _module_ui_pinned_order(scene).has(first_key):
			_record("pinned shelf passive pin-zone tap did not unpin the module")


func _check_pinned_page_chrome(scene: Node) -> void:
	scene.set("current_screen", "pinned")
	_set_module_ui_pinned_order(scene, [])
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	if str(scene.get("current_screen")) != "pinned":
		_record("pinned chrome smoke did not stay on pinned screen")
	var content_scroll := scene.get("content_scroll") as Control
	if content_scroll == null or not is_instance_valid(content_scroll):
		_record("pinned chrome smoke did not create content scroll")
		return
	var pinned_page_root := scene.get("skills_content") as Control
	var active_shelf := _find_named_descendant(pinned_page_root, "PinnedActivitiesActiveShelf") as Control
	if active_shelf == null or not is_instance_valid(active_shelf):
		_record("pinned page did not render its active shelf")
	else:
		var navigation_shell: Object = scene.call("_navigation_shell")
		var expected_height: float = navigation_shell.call("_pinned_active_shelf_target_height", navigation_shell.call("_pinned_active_shelf_skill_id"))
		if absf(active_shelf.custom_minimum_size.y - expected_height) > 0.01:
			_record("pinned page active shelf height mismatch. expected=%s actual=%s" % [expected_height, active_shelf.custom_minimum_size.y])
	var active_content := _find_named_descendant(pinned_page_root, "PinnedActivitiesActiveShelfContent") as Control
	if active_content == null or not is_instance_valid(active_content):
		_record("pinned page did not render its active shelf content host")
	elif active_content.modulate.a > 0.01:
		_record("empty pinned page active shelf content should start hidden. alpha=%s" % active_content.modulate.a)
	var empty_label := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyStateLabel") as Label
	if empty_label == null or not is_instance_valid(empty_label):
		_record("pinned page empty state did not render")
	else:
		var expected := "Press the top left of any activity to pin it.\nPinned activities from every skill page will appear here."
		if empty_label.text != expected:
			_record("pinned page empty state text mismatch")
		if empty_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_CENTER or empty_label.vertical_alignment != VERTICAL_ALIGNMENT_CENTER:
			_record("pinned page empty state is not centered")
		var empty_state := _find_named_descendant(content_scroll, "PinnedActivitiesEmptyState") as Control
		if empty_state == null or not is_instance_valid(empty_state):
			_record("pinned page empty state host did not render")
		elif active_shelf != null and is_instance_valid(active_shelf):
			var label_center_y := empty_label.get_global_rect().get_center().y
			var active_bottom_y := active_shelf.get_global_rect().end.y
			var bottom_limit_y := 1920.0 - 210.0 - 130.0 - 172.0 - 14.0
			var expected_center_y := active_bottom_y + (bottom_limit_y - active_bottom_y) * 0.5
			if absf(label_center_y - expected_center_y) > 65.0:
				_record("pinned page empty state advice is not centered in the usable frame. expected_y=%s actual_y=%s" % [expected_center_y, label_center_y])
			if empty_state.custom_minimum_size.y < 860.0:
				_record("pinned page empty state host is too short to center the advice. height=%s" % empty_state.custom_minimum_size.y)
	if _find_named_descendant(content_scroll, "PinnedActivitiesShelfPanel") != null:
		_record("empty pinned page should not render a shelf panel box")
	var xp_label := scene.get("detail_xp_label") as Label
	if xp_label != null and is_instance_valid(xp_label) and xp_label.is_inside_tree():
		_record("pinned page should not keep the skill XP label in tree")
	var regen_circle := scene._skill_detail_surface().detail_regen_circle as Control
	if regen_circle != null and is_instance_valid(regen_circle) and regen_circle.is_inside_tree():
		_record("pinned page should not keep the source skill stamina circle in tree")
	var fish_circle := scene._skill_detail_surface().detail_fish_circle as Control
	if fish_circle != null and is_instance_valid(fish_circle) and fish_circle.is_inside_tree():
		_record("pinned page should not keep the source fishing header circle in tree")


func _check_pinned_page_cross_skill_order(scene: Node) -> void:
	var pinned_keys := []
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_collapsed(scene, {})
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "build")
	_set_module_ui_pinned_order(scene, [])
	var build_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if build_render_result != null:
		await build_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var build_key := _first_action_module_key(scene, "build")
	if build_key.is_empty():
		_record("pinned page cross-skill order smoke could not find a build module key")
		return
	pinned_keys.append(build_key)
	scene.set("selected_skill_id", "fishing")
	var fishing_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if fishing_render_result != null:
		await fishing_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var fishing_key := _first_action_module_key(scene, "fishing")
	if fishing_key.is_empty():
		_record("pinned page cross-skill order smoke could not find a fishing module key")
		return
	pinned_keys.append(fishing_key)
	scene.set("selected_skill_id", "thieving")
	var thieving_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if thieving_render_result != null:
		await thieving_render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var heist_key := _first_heist_module_key(scene)
	var expected_order := [pinned_keys[1], pinned_keys[0]]
	if not heist_key.is_empty():
		pinned_keys.append(heist_key)
		expected_order = [pinned_keys[1], pinned_keys[2], pinned_keys[0]]
	_set_module_ui_pinned_order(scene, expected_order)
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(10):
		await process_frame
	var content_scroll := scene.get("content_scroll") as Control
	if content_scroll == null or not is_instance_valid(content_scroll):
		_record("pinned page cross-skill order smoke did not create content scroll")
		return
	var page_order := _pinned_page_copy_keys_in_order(content_scroll)
	if page_order.size() < expected_order.size():
		_record("pinned page cross-skill order smoke rendered too few pinned copies. expected=%s actual=%s" % [expected_order, page_order])
		return
	var leading_order := page_order.slice(0, expected_order.size())
	if leading_order != expected_order:
		_record("pinned page cross-skill order mismatch. expected=%s actual=%s" % [expected_order, page_order])


func _check_no_gameplay_tooltips(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var skill_roots: Array[Node] = []
	for prop in ["content_scroll", "module_utility_row", "nav_bar", "chat_strip"]:
		var root := _ui_owned_node(scene, prop)
		if root != null and is_instance_valid(root):
			skill_roots.append(root)
	_assert_no_tooltips_in_roots(skill_roots, "skill gameplay UI")
	scene.set("current_screen", "pinned")
	var pinned_render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if pinned_render_result != null:
		await pinned_render_result
	for _i in range(8):
		await process_frame
	var pinned_roots: Array[Node] = []
	for prop in ["content_scroll", "module_utility_row", "nav_bar", "chat_strip"]:
		var root := _ui_owned_node(scene, prop)
		if root != null and is_instance_valid(root):
			pinned_roots.append(root)
	_assert_no_tooltips_in_roots(pinned_roots, "pinned gameplay UI")


func _check_pinned_page_return_restores_skill_scroll(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var scroll := scene.call("_skill_detail_surface").get("detail_actions_scroll") as ScrollContainer
	if scroll == null:
		_record("pinned return smoke could not find detail scroll before navigation")
		return
	var target_scroll := mini(520, scroll.get_max_scroll_vertical())
	if target_scroll <= 0:
		_record("pinned return smoke did not have enough scrollable content")
		return
	scroll.set("drag_scroll_position", float(target_scroll))
	scroll.set("scroll_vertical", target_scroll)
	var pinned_button := _ui_owned_node(scene, "pinned_utility_tab") as Button
	if pinned_button == null or not is_instance_valid(pinned_button):
		_record("pinned utility tab was not available before opening the pinned page")
		return
	var activity_surface = scene.call("_skill_swipe_activity_surface")
	pinned_button.emit_signal("pressed")
	await process_frame
	var transition_cover := scene.get("skill_swipe_handoff_cover") as Control
	if transition_cover != null and is_instance_valid(transition_cover):
		if not bool(transition_cover.get_meta("page_switch_scroll_cover_includes_bottom_interactive_ui", false)):
			_record("pinned utility transition cover did not include the bottom interactive UI")
		var expected_cover_bottom: float = scene.call("_navigation_shell").call("_global_chat_nav_cover_bottom_offset")
		if absf(transition_cover.offset_bottom - expected_cover_bottom) > 0.5:
			_record("pinned utility transition cover bottom mismatch. expected=%s actual=%s" % [expected_cover_bottom, transition_cover.offset_bottom])
	for _i in range(36):
		await process_frame
	if str(scene.get("current_screen")) != "pinned":
		_record("pinned utility button press did not open the pinned page")
		return
	if pinned_button == null or not is_instance_valid(pinned_button):
		_record("pinned utility tab was not available for active-state smoke")
	else:
		var active_fill := pinned_button.get_meta("activity_button_shell_fill", Color.TRANSPARENT) as Color
		if not bool(pinned_button.get_meta("activity_button_shell_active", false)):
			_record("pinned utility tab did not mark itself active on the pinned page")
		var expected_active_fill := pinned_button.get_meta("module_utility_fill", Color.WHITE) as Color
		if not active_fill.is_equal_approx(expected_active_fill):
			_record("pinned utility tab active fill mismatch: %s" % active_fill)
		var active_pop := instance_from_id(int(pinned_button.get_meta("activity_button_pop_id", 0))) as Control
		if active_pop == null or not is_instance_valid(active_pop):
			_record("pinned utility tab active-state smoke could not find button face")
		else:
			var active_offset: Vector2 = activity_surface.call("_activity_button_pop_depth_offset", active_pop)
			var expected_active_offset := pinned_button.get_meta("activity_button_depth_offset", Vector2(28.0, 34.0)) as Vector2
			if not pinned_button.has_meta("activity_button_depth_tween") and active_offset.distance_to(expected_active_offset) > 1.5:
				_record("pinned utility tab active state did not start the 3D press animation. expected=%s actual=%s" % [expected_active_offset, active_offset])
	for _i in range(24):
		await process_frame
	if pinned_button != null and is_instance_valid(pinned_button):
		var settled_pop := instance_from_id(int(pinned_button.get_meta("activity_button_pop_id", 0))) as Control
		if settled_pop != null and is_instance_valid(settled_pop):
			var settled_offset: Vector2 = activity_surface.call("_activity_button_pop_depth_offset", settled_pop)
			var expected_settled_offset := pinned_button.get_meta("activity_button_depth_offset", Vector2(28.0, 34.0)) as Vector2
			if settled_offset.distance_to(expected_settled_offset) > 1.5:
				_record("pinned utility tab active state was not fully depressed after animation. expected=%s actual=%s" % [expected_settled_offset, settled_offset])
	pinned_button.emit_signal("pressed")
	for _i in range(12):
		await process_frame
	if str(scene.get("current_screen")) != "skill":
		_record("pinned utility button press did not return to the previous skill page")
		return
	if str(scene.get("selected_skill_id")) != skill_id:
		_record("pinned utility did not restore the previous skill id")
	var restored_scroll := scene.call("_skill_detail_surface").get("detail_actions_scroll") as ScrollContainer
	if restored_scroll == null:
		_record("pinned return smoke could not find detail scroll after navigation")
		return
	if absi(restored_scroll.scroll_vertical - target_scroll) > 3:
		_record("pinned utility did not restore skill scroll. expected=%s actual=%s" % [target_scroll, restored_scroll.scroll_vertical])
	if pinned_button != null and is_instance_valid(pinned_button):
		var normal_fill := pinned_button.get_meta("activity_button_shell_fill", Color.TRANSPARENT) as Color
		if bool(pinned_button.get_meta("activity_button_shell_active", false)):
			_record("pinned utility tab stayed active after returning to the skill page")
		if normal_fill.is_equal_approx(Color("#d8d8d8")):
			_record("pinned utility tab kept the active gray after returning to the skill page")
		scene.call("_navigation_shell").call("_release_page_switch_transition_button")
		activity_surface.call("_press_activity_button_shell_bound", pinned_button.get_instance_id())
		for _i in range(2):
			await process_frame
		var drag_point := pinned_button.get_global_rect().position + Vector2(-420.0, -420.0)
		scene.call("_input", _mouse_motion_event(drag_point))
		for _i in range(24):
			await process_frame
		if activity_surface.call("has_depressed_activity_shell_button", pinned_button.get_instance_id()):
			_record("press-drag-release smoke left pinned utility shell in depressed registry")
		var pop := instance_from_id(int(pinned_button.get_meta("activity_button_pop_id", 0))) as Control
		if pop != null and is_instance_valid(pop):
			var offset: Vector2 = activity_surface.call("_activity_button_pop_depth_offset", pop)
			if offset.length() > 1.5:
				activity_surface.call("_release_activity_button_shell_bound", pinned_button.get_instance_id())
		if str(scene.get("current_screen")) != "skill":
			_record("press-drag-release smoke unexpectedly navigated away from the restored skill page")


func _check_event_insertion_transition(scene: Node) -> void:
	var runtime = scene.call("_temporary_event_runtime")
	var event_id := "ambush-log-wagon"
	var event_def := runtime.call("_event_module_def", event_id) as Dictionary
	if event_def.is_empty():
		_record("missing covered wagon event definition for transition smoke")
		return
	var skill_id := str(event_def.get("page", ""))
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	runtime.set("temporary_event_active", {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	_scroll_near_event_insertion_anchor(scene, event_def)
	for _i in range(3):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var before_order := _plan_track_order(scene)
	if before_order.has(event_id):
		_record("event module was already present before insertion transition smoke")
		return
	var now := int(scene.call("_unix_now"))
	var active := runtime.get("temporary_event_active") as Dictionary
	active[event_id] = {
		"event_id": event_id,
		"spawned_unix": now,
		"expires_unix": now + 900,
		"completed": false,
	}
	runtime.set("temporary_event_active", active)
	var inserted := bool(scene.call("_temporary_event_surface").call("_animate_temporary_event_entry_if_visible", event_def, event_id))
	if not inserted:
		_record("event insertion did not use the animated visible insertion path")
		return
	for _i in range(4):
		await process_frame
	var after_order := _plan_track_order(scene)
	if not after_order.has(event_id):
		_record("event insertion did not add the event to the lazy plan")
	var event_index := after_order.find(event_id)
	if event_index <= 0 or event_index >= after_order.size() - 1:
		_record("event insertion should land in the middle of the module list, got index %s of %s" % [event_index, after_order.size()])
	var stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	var host := _plan_host_for_track(scene, event_id)
	if host == null:
		_record("event insertion did not create a stack host")
	else:
		if not host.has_meta("temporary_event_entry_tween"):
			_record("event insertion did not start the entry reveal tween")
	if _module_transition_tween_count(stack) <= 0:
		_record("event insertion did not create surrounding module-list transition tweens")


func _check_unlock_preview_insertion_transition(scene: Node, require_combo := false) -> void:
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	var skill_id := ""
	var action_ids := []
	var current_preview_id := ""
	var next_preview_id := ""
	for raw_skill_id in actions_by_skill.keys():
		var candidate_skill_id := str(raw_skill_id)
		var candidate_action_ids := []
		for raw_action in actions_by_skill.get(candidate_skill_id, []) as Array:
			var action := raw_action as Dictionary
			if action.is_empty():
				continue
			if bool(scene.call("_passive_modules_runtime").is_passive_action(action)):
				continue
			var action_id := str(action.get("id", ""))
			if not action_id.is_empty():
				candidate_action_ids.append(action_id)
		for index in range(1, candidate_action_ids.size() - 1):
			var candidate_current_id := str(candidate_action_ids[index])
			var candidate_current_action := scene.call("_action_data", candidate_skill_id, candidate_current_id) as Dictionary
			if candidate_current_action.is_empty():
				continue
			var candidate_next_id := str(candidate_action_ids[index + 1])
			var candidate_next_action := scene.call("_action_data", candidate_skill_id, candidate_next_id) as Dictionary
			if candidate_next_action.is_empty():
				continue
			var unlock_requirements := Callable(scene.call("_activity_unlock_runtime"), "_action_unlock_requirements")
			var next_is_combo := ModuleUiRuntime.action_is_combo_module(candidate_skill_id, candidate_next_action, unlock_requirements)
			var current_is_combo := ModuleUiRuntime.action_is_combo_module(candidate_skill_id, candidate_current_action, unlock_requirements)
			if require_combo:
				if not next_is_combo:
					continue
			elif current_is_combo:
				continue
			skill_id = candidate_skill_id
			action_ids = candidate_action_ids
			current_preview_id = candidate_current_id
			next_preview_id = candidate_next_id
			break
		if not skill_id.is_empty():
			break
	if current_preview_id.is_empty() or next_preview_id.is_empty():
		var label := "combo" if require_combo else "normal"
		_record("could not find a %s locked preview followed by another action for unlock-preview insertion" % label)
		return
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	var manual_unlocks := scene.get("manual_activity_unlocks") as Dictionary
	var lock_start_index := action_ids.find(current_preview_id)
	for index in range(lock_start_index, action_ids.size()):
		manual_unlocks.erase(str(scene.call("_action_key", skill_id, str(action_ids[index]))))
	scene.set("manual_activity_unlocks", manual_unlocks)
	scene.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var before_order := _plan_track_order(scene)
	if not before_order.has(current_preview_id):
		_record("current locked preview was not visible before unlock-preview insertion smoke: %s" % current_preview_id)
		return
	if before_order.has(next_preview_id):
		_record("next locked preview was visible before the insertion smoke unlocked the current preview: %s" % next_preview_id)
		return
	var before_stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	manual_unlocks[str(scene.call("_action_key", skill_id, current_preview_id))] = true
	scene.set("manual_activity_unlocks", manual_unlocks)
	scene.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	var inserted := bool(scene.call("_skill_detail_surface").call("_ensure_activity_unlock_preview_lazy_entry", next_preview_id))
	if not inserted:
		_record("%s unlock-preview insertion did not use the in-place lazy entry path" % ("combo" if require_combo else "normal"))
		return
	for _i in range(4):
		await process_frame
	var after_order := _plan_track_order(scene)
	if not after_order.has(next_preview_id):
		_record("%s unlock-preview insertion did not add the next locked preview to the lazy plan: %s" % ["combo" if require_combo else "normal", next_preview_id])
	if after_order.find(next_preview_id) <= after_order.find(current_preview_id):
		_record("%s next locked preview should appear after the newly unlocked module. current=%s next=%s order=%s" % ["combo" if require_combo else "normal", current_preview_id, next_preview_id, after_order])
	var after_stack := scene.call("_skill_detail_surface").get("detail_lazy_stack") as VBoxContainer
	if after_stack != before_stack:
		_record("%s unlock-preview insertion replaced the detail lazy stack instead of inserting in place" % ("combo" if require_combo else "normal"))
	var host := _plan_host_for_track(scene, next_preview_id)
	if host == null:
		_record("%s unlock-preview insertion did not create a stack host for %s" % ["combo" if require_combo else "normal", next_preview_id])
	if _module_transition_tween_count(after_stack) <= 0:
		_record("%s unlock-preview insertion did not create surrounding module-list transition tweens" % ("combo" if require_combo else "normal"))


func _check_rendered_locked_module_action_zones(scene: Node) -> void:
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	var skill_id := ""
	var locked_action_id := ""
	for raw_skill_id in actions_by_skill.keys():
		var candidate_skill_id := str(raw_skill_id)
		for raw_action in actions_by_skill.get(candidate_skill_id, []) as Array:
			var action := raw_action as Dictionary
			if action.is_empty() or bool(scene.call("_passive_modules_runtime").is_passive_action(action)):
				continue
			if int(action.get("unlock", 1)) <= 1:
				continue
			var action_id := str(action.get("id", ""))
			if not action_id.is_empty():
				skill_id = candidate_skill_id
				locked_action_id = action_id
				break
		if not locked_action_id.is_empty():
			break
	if skill_id.is_empty() or locked_action_id.is_empty():
		_record("could not find an action candidate for rendered locked-module zone smoke")
		return
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	_set_module_ui_sort_mode(scene, "level")
	_set_module_ui_pinned_order(scene, [])
	_set_module_ui_collapsed(scene, {})
	var locked_action := scene.call("_action_data", skill_id, locked_action_id) as Dictionary
	if locked_action.is_empty():
		_record("rendered locked-module zone smoke lost action data for %s" % locked_action_id)
		return
	var action_key := str(scene.call("_action_key", skill_id, locked_action_id))
	var module_key := str(ModuleUiRuntime.action_for_record(skill_id, locked_action, scene.get("FISHING_ACTION_ID_ALIASES")))
	var manual_unlocks := scene.get("manual_activity_unlocks") as Dictionary
	manual_unlocks.erase(action_key)
	scene.set("manual_activity_unlocks", manual_unlocks)
	scene.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	var skills := scene.get("skills") as Dictionary
	var skill_state := (skills.get(skill_id, {}) as Dictionary).duplicate(true)
	var unlock_level := maxi(2, int(locked_action.get("unlock", 2)))
	skill_state["level"] = unlock_level - 1
	skill_state["xp"] = maxi(0, SkillState.xp_for_level(unlock_level) - 1)
	skills[skill_id] = skill_state
	scene.set("skills", skills)
	SkillState.recalculate_level(scene, skill_id, false)
	if bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", skill_id, locked_action)):
		_record("rendered locked-module zone smoke candidate stayed unlocked: %s" % module_key)
		_restore_module_transition_god_state(scene)
		return
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_ensure_detail_lazy_entry_mounted", locked_action_id)
	for _i in range(4):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var host := _plan_host_for_track(scene, locked_action_id)
	if host == null:
		_record("rendered locked-module zone smoke could not find stack host for %s" % locked_action_id)
		_restore_module_transition_god_state(scene)
		return
	var locked_module := _find_control_with_meta(host, "module_ui_key", module_key)
	if locked_module == null:
		locked_module = _find_control_with_meta(host, "activity_action_id", locked_action_id)
	if locked_module == null:
		_record("rendered locked-module zone smoke could not find module control for %s" % module_key)
		_restore_module_transition_god_state(scene)
		return
	var zone_count := _control_meta_count(locked_module, "module_action_circle_zone", true)
	if zone_count != 0:
		_record("locked rendered module exposed %s module action zone control(s): %s" % [zone_count, module_key])
	var pin_badge := (scene.call("_skill_detail_surface") as Object).call("_module_pin_badge", locked_module) as TextureButton
	if pin_badge != null and is_instance_valid(pin_badge) and pin_badge.visible:
		_record("locked rendered module showed a pin badge: %s" % module_key)
	var collapse_badge := scene.call("_skill_detail_surface").call("_module_collapse_badge", locked_module) as Control
	if collapse_badge != null and is_instance_valid(collapse_badge) and collapse_badge.visible:
		_record("locked rendered module showed a collapse badge: %s" % module_key)
	var rect := locked_module.get_global_rect()
	var pin_point := rect.position + Vector2(40.0, 40.0)
	var collapse_point := rect.position + Vector2(maxf(0.0, rect.size.x - 40.0), 40.0)
	var pin_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", pin_point) as Dictionary
	if not pin_hit.is_empty():
		_record("locked rendered module top-left point routed to action zone: %s" % pin_hit)
	var collapse_hit := scene.call("_skill_detail_surface").call("_module_action_circle_at_position", collapse_point) as Dictionary
	if not collapse_hit.is_empty():
		_record("locked rendered module top-right point routed to action zone: %s" % collapse_hit)
	_restore_module_transition_god_state(scene)


func _restore_module_transition_god_state(scene: Node) -> void:
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()


func _scroll_near_event_insertion_anchor(scene: Node, event_def: Dictionary) -> void:
	var catalog = scene.get("activity_data_catalog")
	var target_sort := int(catalog.call("activity_action_display_sort_level", event_def))
	var plan := scene.call("_skill_detail_surface").get("detail_lazy_plan") as Array
	var best_y := 0.0
	var best_distance := 999999
	for raw_item in plan:
		var item := raw_item as Dictionary
		if str(item.get("kind", "")) != "action":
			continue
		var entry := item.get("entry", {}) as Dictionary
		var action := entry.get("action", {}) as Dictionary
		if action.is_empty():
			continue
		var sort_level := int(catalog.call("activity_action_display_sort_level", action))
		var distance := absi(sort_level - target_sort)
		if distance < best_distance:
			best_distance = distance
			best_y = float(item.get("y", 0.0))
	var scroll := scene.call("_skill_detail_surface").get("detail_actions_scroll") as ScrollContainer
	if scroll == null:
		return
	var target_scroll := clampi(int(maxf(0.0, best_y - 260.0)), 0, int(scroll.call("get_max_scroll_vertical")))
	scroll.call("scroll_to_vertical", target_scroll, 0.0)
	scroll.set("drag_scroll_position", float(target_scroll))
	scroll.set("scroll_vertical", target_scroll)


func _first_action_module_key(scene: Node, skill_id: String) -> String:
	return _nth_action_module_key(scene, skill_id, 0)


func _nth_action_module_key(scene: Node, skill_id: String, target_index: int) -> String:
	var seen := 0
	if skill_id == "fishing":
		for raw_area_def in scene.call("_fishing_ui_surface").render_area_modules(skill_id):
			var area_def := raw_area_def as Dictionary
			if area_def.is_empty():
				continue
			var key := str(ModuleUiRuntime.fishing_area(scene.get("fishing_runtime").area_module_key(skill_id, area_def)))
			if not key.is_empty():
				if seen == target_index:
					return key
				seen += 1
	for raw_action in scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", skill_id):
		var action := raw_action as Dictionary
		if action.is_empty():
			continue
		var key := str(ModuleUiRuntime.action_for_record(skill_id, action, scene.get("FISHING_ACTION_ID_ALIASES")))
		if not key.is_empty():
			if seen == target_index:
				return key
			seen += 1
	return ""


func _visible_normal_action_module_pair(scene: Node, scroll: ScrollContainer, skill_id: String) -> Dictionary:
	if scroll == null or not is_instance_valid(scroll):
		return {}
	var viewport_rect := scroll.get_global_rect()
	for raw_action in scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", skill_id):
		var action := raw_action as Dictionary
		if action.is_empty() or bool(scene.call("_passive_modules_runtime").is_passive_action(action)):
			continue
		var key := str(ModuleUiRuntime.action_for_record(skill_id, action, scene.get("FISHING_ACTION_ID_ALIASES")))
		if key.is_empty():
			continue
		var control := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", scroll, key) as Control
		if control == null or not is_instance_valid(control):
			continue
		var rect := control.get_global_rect()
		var overlap_top := maxf(rect.position.y, viewport_rect.position.y)
		var overlap_bottom := minf(rect.position.y + rect.size.y, viewport_rect.position.y + viewport_rect.size.y)
		if overlap_bottom - overlap_top >= minf(180.0, rect.size.y * 0.45):
			return {"module_key": key, "control": control}
	return {}


func _pinned_shelf_copy_keys_in_order(root_node: Node) -> Array:
	var result := []
	_collect_pinned_shelf_copy_keys(root_node, result)
	return result


func _pinned_page_copy_keys_in_order(root_node: Node) -> Array:
	var result := []
	_collect_pinned_page_copy_keys(root_node, result)
	return result


func _collect_pinned_shelf_copy_keys(root_node: Node, result: Array) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	if root_node is Control:
		var control := root_node as Control
		if bool(control.get_meta("module_ui_pinned_shelf_copy", false)):
			result.append(str(control.get_meta("module_ui_key", "")))
			return
	for child in root_node.get_children():
		_collect_pinned_shelf_copy_keys(child, result)


func _collect_pinned_page_copy_keys(root_node: Node, result: Array) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	if root_node is Control:
		var control := root_node as Control
		if bool(control.get_meta("module_ui_pinned_page_copy", false)):
			result.append(str(control.get_meta("module_ui_key", "")))
			return
	for child in root_node.get_children():
		_collect_pinned_page_copy_keys(child, result)


func _registered_action_card_for_module(scene: Node, module_key: String) -> Dictionary:
	var normalized_key := str(module_key)
	if not normalized_key.begins_with("action:"):
		return {}
	var action_key := normalized_key.substr("action:".length())
	var parts := action_key.split(":", false, 2)
	if parts.size() < 2:
		return {}
	var skill_id := str(parts[0])
	var action_id := str(parts[1])
	var action_cards := scene.get("action_cards") as Dictionary
	var card_key := "%s:%s" % [skill_id, action_id]
	var card := action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return {}
	return {
		"card": card,
		"skill_id": skill_id,
		"action_id": action_id,
		"card_key": card_key,
	}


func _find_named_descendant(root_node: Node, node_name: String) -> Node:
	if root_node == null or not is_instance_valid(root_node):
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_named_descendant(child, node_name)
		if found != null:
			return found
	return null


func _first_nonempty_label(root_node: Node) -> Label:
	if root_node == null or not is_instance_valid(root_node):
		return null
	if root_node is Label and not (root_node as Label).text.strip_edges().is_empty():
		return root_node as Label
	for child in root_node.get_children():
		var found := _first_nonempty_label(child)
		if found != null:
			return found
	return null


func _assert_no_tooltips_in_roots(roots: Array[Node], context: String) -> void:
	for root_node in roots:
		_assert_no_tooltips_in_tree(root_node, context)


func _assert_action_bonus_panel_filled(card: Dictionary, context: String) -> void:
	var bonus := card.get("bonus_panel", {}) as Dictionary
	if bonus.is_empty():
		_record("%s did not create a bonus panel" % context)
		return
	var root := bonus.get("root", null) as Control
	if root == null or not is_instance_valid(root) or not root.visible:
		_record("%s bonus panel is not visible" % context)
	for label_key in ["title", "original", "current", "bonuses"]:
		var label := bonus.get(label_key, null) as Label
		if label == null or not is_instance_valid(label):
			_record("%s bonus panel is missing %s label" % [context, label_key])
			continue
		if label.text.strip_edges().is_empty():
			_record("%s bonus panel left %s label empty" % [context, label_key])


func _assert_action_info_chips_fill(scene: Node, card: Dictionary, context: String) -> void:
	var stat_boxes := card.get("stat_boxes", {}) as Dictionary
	for stat_kind in ["xp", "stamina", "time", "success"]:
		var stat_box := stat_boxes.get(stat_kind, null) as Control
		if stat_box == null or not is_instance_valid(stat_box):
			_record("%s is missing its %s info chip box" % [context, stat_kind])
			continue
		var stat_center := stat_box.get_global_rect().get_center()
		scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
		scene.call("_skill_detail_surface").call("_clear_activity_stat_popup")
		scene.call("_input", _screen_touch_event(stat_center, true, 31))
		scene.call("_input", _screen_touch_event(stat_center, false, 31))
		for _i in range(2):
			await process_frame
		if not str(scene.call("_skill_detail_surface").get("expanded_activity_stat_kind")).is_empty():
			_record("%s %s tap expanded info without a hold" % [context, stat_kind])
		scene.call("_input", _screen_touch_event(stat_center, true, 31))
		scene.call("_action_stop_hold").call("process_action", 0.18)
		await process_frame
		if not bool(scene.call("_action_stop_hold").get("show_question")):
			_record("%s %s hold animation is missing its question mark" % [context, stat_kind])
		for _i in range(4):
			scene.call("_action_stop_hold").call("process_action", 0.18)
			await process_frame
		scene.call("_input", _screen_touch_event(stat_center, false, 31))
		for _i in range(2):
			await process_frame
		if not str(scene.get("running_skill_id")).is_empty() or not str(scene.get("running_action_id")).is_empty():
			_record("%s %s hold started the activity underneath" % [context, stat_kind])
			scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
		if not str(scene.call("_skill_detail_surface").get("action_card_press_key")).is_empty():
			_record("%s %s tap left an action card press stuck: %s" % [context, stat_kind, str(scene.call("_skill_detail_surface").get("action_card_press_key"))])
			scene.call("_skill_detail_surface").set("action_card_press_key", "")
		scene.call("_update_ui", 0.0, true)
		_assert_action_bonus_panel_filled(card, "%s %s" % [context, stat_kind])
	scene.call("_skill_swipe_activity_surface").call("_collapse_expanded_activity_modules")
	scene.call("_update_ui", 0.0, true)


func _assert_passive_info_popover_fills(scene: Node, module_id: String, info_button: Button, info_popover: Control, context: String) -> void:
	if info_button == null or not is_instance_valid(info_button):
		_record("%s is missing its info button" % context)
		return
	if info_button.disabled or info_button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		_record("%s info button is not tappable" % context)
	if info_popover == null or not is_instance_valid(info_popover):
		_record("%s is missing its info popover" % context)
		return
	var passive_modules := scene.get("passive_modules") as Dictionary
	var before_state := passive_modules.get(module_id, {}) as Dictionary
	var before_stored := int(before_state.get("stored", -1))
	var before_currency := int(scene.get("log_currency"))
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.call("_passive_firepit_surface").call("_clear_passive_button_press")
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
	if info_popover.visible:
		scene.call("_passive_firepit_surface").call("_hide_passive_info_popover", info_popover)
	if info_popover.has_meta("fade_tween"):
		_record("%s started with stale fade_tween metadata" % context)
	var info_local_point := info_button.get_global_rect().get_center() - info_button.get_global_rect().position
	scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(info_local_point, true), "info", module_id, "", info_popover, info_button)
	scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(info_local_point, false), "info", module_id, "", info_popover, info_button)
	for _i in range(18):
		await process_frame
	if not info_popover.visible:
		_record("%s tap did not show the info popover" % context)
	if _control_tree_text(info_popover).strip_edges().is_empty():
		_record("%s popover text was empty" % context)
	var after_modules := scene.get("passive_modules") as Dictionary
	var after_state := after_modules.get(module_id, {}) as Dictionary
	if int(after_state.get("stored", -1)) != before_stored:
		_record("%s tap collected or changed stored loot" % context)
	if int(scene.get("log_currency")) != before_currency:
		_record("%s tap changed log currency" % context)
	if not str(scene.get("running_skill_id")).is_empty() or not str(scene.get("running_action_id")).is_empty():
		_record("%s tap started an activity underneath" % context)
	if scene.call("_passive_firepit_surface").get("passive_button_press_source") != null or not str(scene.call("_passive_firepit_surface").get("passive_button_press_kind")).is_empty():
		_record("%s tap left passive press state stuck" % context)
	scene.call("_passive_firepit_surface").call("_hide_passive_info_popover", info_popover)
	if info_popover.visible:
		_record("%s hide did not clear popover visibility" % context)
	if info_popover.has_meta("fade_tween"):
		_record("%s hide left stale fade_tween metadata" % context)
	scene.call("_passive_firepit_surface").call("_finish_passive_info_popover_fade", info_popover.get_instance_id())
	for _i in range(2):
		await process_frame
	if info_popover.has_meta("fade_tween"):
		_record("%s finish callback left stale fade_tween metadata" % context)
	scene.call("_passive_firepit_surface").call("_on_passive_module_button_input", _local_mouse_button_event(info_local_point, false), "info", module_id, "", info_popover, info_button)
	for _i in range(2):
		await process_frame
	if scene.call("_passive_firepit_surface").get("passive_button_press_source") != null or not str(scene.call("_passive_firepit_surface").get("passive_button_press_kind")).is_empty():
		_record("%s release-without-press left passive press state stuck" % context)
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")


func _control_tree_text(root_node: Node) -> String:
	if root_node == null or not is_instance_valid(root_node):
		return ""
	var parts: Array[String] = []
	if root_node is Label:
		parts.append((root_node as Label).text)
	if root_node is Button:
		parts.append((root_node as Button).text)
	for child in root_node.get_children():
		var child_text := _control_tree_text(child)
		if not child_text.strip_edges().is_empty():
			parts.append(child_text)
	return "\n".join(parts)


func _assert_pinned_control_tappable(scene: Node, control: Control, context: String) -> void:
	if control == null or not is_instance_valid(control):
		_record("%s is missing" % context)
		return
	if not control.is_inside_tree() or not control.is_visible_in_tree():
		_record("%s is not visible in the pinned page tree" % context)
		return
	if control.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		_record("%s ignores pointer input" % context)
	if control is BaseButton and (control as BaseButton).disabled:
		_record("%s is disabled" % context)
	var tap_point := control.get_global_rect().get_center()
	if bool(scene.call("_input_routing_shell").call("_event_points_inside_bottom_interactive_ui", _mouse_button_event(tap_point, true))):
		_record("%s tap point is covered by bottom interactive UI" % context)
	if not bool(scene.call("_input_routing_shell").call("_position_inside_detail_actions_viewport", tap_point)):
		_record("%s tap point is outside the pinned-page viewport" % context)


func _assert_thieving_heist_drag_release_cancels(scene: Node, button: Button, heist_id: String, context: String) -> void:
	var trophies := (scene.get("thieving_state") as Object).get("trophies") as Dictionary
	trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
	(scene.get("thieving_state") as Object).set("trophies", trophies)
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
	var heist_local_point := button.get_global_rect().get_center() - button.get_global_rect().position
	scene.call("_thieving_surface").call("_on_thieving_heist_button_input", _local_mouse_button_event(heist_local_point, true), heist_id, button)
	var drag_event := InputEventMouseMotion.new()
	drag_event.position = heist_local_point + Vector2(260.0, 0.0)
	drag_event.global_position = button.get_global_rect().position + drag_event.position
	drag_event.relative = Vector2(260.0, 0.0)
	scene.call("_thieving_surface").call("_on_thieving_heist_button_input", drag_event, heist_id, button)
	scene.call("_thieving_surface").call("_on_thieving_heist_button_input", _local_mouse_button_event(heist_local_point + Vector2(260.0, 0.0), false), heist_id, button)
	for _i in range(8):
		await process_frame
	var after_state := ((scene.get("thieving_state") as Object).get("trophies") as Dictionary).get(heist_id, {}) as Dictionary
	if bool(after_state.get("stolen", false)) or int(after_state.get("cooldown_until_unix", 0)) > 0:
		_record("%s drag-release attempted the heist" % context)
	if bool(button.get_meta("thieving_heist_press_active", false)) or bool(button.get_meta("thieving_heist_press_dragged", false)):
		_record("%s drag-release left heist press metadata stuck" % context)
	scene.call("_thieving_surface").call("_on_thieving_heist_button_input", _local_mouse_button_event(heist_local_point, false), heist_id, button)
	for _i in range(2):
		await process_frame
	if bool(button.get_meta("thieving_heist_press_active", false)) or bool(button.get_meta("thieving_heist_press_dragged", false)):
		_record("%s release-without-press left heist press metadata stuck" % context)
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")


func _tap_fishing_method_button(scene: Node, button: Button, skill_id: String, action_id: String, area_key: String, owner_area_id: int) -> void:
	var local_point := button.get_global_rect().get_center() - button.get_global_rect().position
	var fishing_ui_surface = scene.call("_fishing_ui_surface")
	fishing_ui_surface.call("_on_fishing_method_button_input", _local_mouse_button_event(local_point, true), skill_id, action_id, area_key, owner_area_id, button)
	fishing_ui_surface.call("_on_fishing_method_button_input", _local_mouse_button_event(local_point, false), skill_id, action_id, area_key, owner_area_id, button)


func _assert_fishing_method_drag_release_cancels(
	scene: Node,
	button: Button,
	skill_id: String,
	action_id: String,
	area_key: String,
	owner_area_id: int,
	context: String
) -> void:
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
	var local_point := button.get_global_rect().get_center() - button.get_global_rect().position
	var fishing_ui_surface = scene.call("_fishing_ui_surface")
	fishing_ui_surface.call("_on_fishing_method_button_input", _local_mouse_button_event(local_point, true), skill_id, action_id, area_key, owner_area_id, button)
	var fishing_drag_event := InputEventMouseMotion.new()
	fishing_drag_event.position = local_point + Vector2(260.0, 0.0)
	fishing_drag_event.global_position = button.get_global_rect().position + fishing_drag_event.position
	fishing_drag_event.relative = Vector2(260.0, 0.0)
	fishing_ui_surface.call("_on_fishing_method_button_input", fishing_drag_event, skill_id, action_id, area_key, owner_area_id, button)
	fishing_ui_surface.call("_on_fishing_method_button_input", _local_mouse_button_event(local_point + Vector2(260.0, 0.0), false), skill_id, action_id, area_key, owner_area_id, button)
	for _i in range(8):
		await process_frame
	if str(scene.get("running_skill_id")) == skill_id and str(scene.get("running_action_id")) == action_id:
		_record("%s drag-release started the fishing action" % context)
	if bool(button.get_meta("fishing_method_press_active", false)) or bool(button.get_meta("fishing_method_press_dragged", false)):
		_record("%s drag-release left fishing method press metadata stuck" % context)
	fishing_ui_surface.call("_on_fishing_method_button_input", _local_mouse_button_event(local_point, false), skill_id, action_id, area_key, owner_area_id, button)
	for _i in range(2):
		await process_frame
	if bool(button.get_meta("fishing_method_press_active", false)) or bool(button.get_meta("fishing_method_press_dragged", false)):
		_record("%s release-without-press left fishing method press metadata stuck" % context)
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")


func _assert_no_tooltips_in_tree(root_node: Node, context: String) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	if root_node is Control:
		var control := root_node as Control
		if not control.tooltip_text.strip_edges().is_empty():
			_record("%s should not expose hover tooltip text on %s: %s" % [context, str(control.name), control.tooltip_text])
	for child in root_node.get_children():
		_assert_no_tooltips_in_tree(child, context)


func _plan_host_for_track(scene: Node, track_id: String) -> Control:
	var plan := scene.call("_skill_detail_surface").get("detail_lazy_plan") as Array
	for raw_item in plan:
		var item := raw_item as Dictionary
		if str(item.get("track_id", "")) != track_id:
			continue
		var host = item.get("stack_host", null)
		if host != null and is_instance_valid(host):
			return host as Control
	return null


func _find_control_with_meta(root_node: Node, meta_key: String, expected_value: Variant) -> Control:
	if root_node == null or not is_instance_valid(root_node):
		return null
	if root_node is Control and (root_node as Control).has_meta(meta_key) and (root_node as Control).get_meta(meta_key) == expected_value:
		return root_node as Control
	for child in root_node.get_children():
		var found := _find_control_with_meta(child, meta_key, expected_value)
		if found != null:
			return found
	return null


func _control_meta_count(root_node: Node, meta_key: String, expected_value: Variant) -> int:
	if root_node == null or not is_instance_valid(root_node):
		return 0
	var count := 0
	if root_node is Control and (root_node as Control).has_meta(meta_key) and (root_node as Control).get_meta(meta_key) == expected_value:
		count += 1
	for child in root_node.get_children():
		count += _control_meta_count(child, meta_key, expected_value)
	return count


func _find_original_module_control(root_node: Node, module_key: String) -> Control:
	if root_node == null or not is_instance_valid(root_node):
		return null
	if root_node is Control:
		var control := root_node as Control
		if (
			str(control.get_meta("module_ui_key", "")) == module_key
			and not bool(control.get_meta("module_ui_pinned_shelf_copy", false))
			and not bool(control.get_meta("module_ui_pinned_page_copy", false))
		):
			return control
	for child in root_node.get_children():
		var found := _find_original_module_control(child, module_key)
		if found != null:
			return found
	return null


func _mouse_button_event(global_position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = global_position
	event.global_position = global_position
	return event


func _screen_touch_event(position: Vector2, pressed: bool, index: int) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.position = position
	event.pressed = pressed
	event.index = index
	return event


func _dispatch_viewport_tap(scene: Node, global_position: Vector2) -> void:
	scene.call("_input", _mouse_button_event(global_position, true))
	scene.call("_input", _mouse_button_event(global_position, false))


func _local_mouse_button_event(local_position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = local_position
	event.global_position = Vector2.ZERO
	return event


func _mouse_motion_event(global_position: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = global_position
	event.global_position = global_position
	event.relative = Vector2(0, 260)
	return event


func _card_body_tap_point(scene: Node, pop: Control, skill_id: String, action_id: String) -> Vector2:
	var rect := pop.get_global_rect()
	for y_ratio in [0.28, 0.42, 0.58, 0.72, 0.86]:
		for x_ratio in [0.34, 0.50, 0.66]:
			var candidate := rect.position + Vector2(rect.size.x * float(x_ratio), rect.size.y * float(y_ratio))
			if bool(scene.call("_input_routing_shell").call("_event_points_inside_bottom_interactive_ui", _mouse_button_event(candidate, true))):
				continue
			var hit := scene.call("_input_routing_shell").call("_action_card_at_position", candidate) as Dictionary
			if (
				not hit.is_empty()
				and str(hit.get("skill_id", "")) == skill_id
				and str(hit.get("action_id", "")) == action_id
				and str(scene.call("_skill_detail_surface").call("_activity_stat_kind_at_position", hit.get("card", {}) as Dictionary, candidate)).is_empty()
			):
				return candidate
	return rect.position + Vector2(rect.size.x * 0.50, rect.size.y * 0.62)


func _plan_track_order(scene: Node) -> Array:
	var result := []
	var plan := scene.call("_skill_detail_surface").get("detail_lazy_plan") as Array
	for raw_item in plan:
		var item := raw_item as Dictionary
		var kind := str(item.get("kind", ""))
		if not kind in ["action", "passive", "heist", "fishing_area", "fishing_offer"]:
			continue
		var track_id := str(item.get("track_id", ""))
		if not track_id.is_empty():
			result.append(track_id)
	return result


func _first_heist_module_key(scene: Node) -> String:
	var plan := scene.call("_skill_detail_surface").get("detail_lazy_plan") as Array
	for raw_item in plan:
		var item := raw_item as Dictionary
		if str(item.get("kind", "")) != "heist":
			continue
		var track_id := str(item.get("track_id", ""))
		if track_id.begins_with("heist:"):
			return "thieving_heist:%s" % track_id.substr("heist:".length())
	return ""


func _first_passive_module_key(scene: Node, skill_id: String) -> String:
	var plan := scene.call("_skill_detail_surface").get("detail_lazy_plan") as Array
	for raw_item in plan:
		var item := raw_item as Dictionary
		if str(item.get("kind", "")) != "passive":
			continue
		var track_id := str(item.get("track_id", ""))
		if not track_id.is_empty():
			return "action:%s:%s" % [skill_id, track_id]
	return ""


func _module_transition_tween_count(root_node: Node) -> int:
	if root_node == null or not is_instance_valid(root_node):
		return 0
	var count := 0
	if root_node is Control and (root_node as Control).has_meta("module_list_transition_tween"):
		count += 1
	for child in root_node.get_children():
		count += _module_transition_tween_count(child)
	return count


func _record(message: String) -> void:
	failures.append(message)


func _fail(message: String) -> void:
	push_error("module-list-transitions-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "module-list-transitions-ok") "Module list transition smoke did not report success."
    Assert-NoUnexpectedGodotErrors $output "module list transition smoke"

    $newHeadless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A new headless Godot process is still running after module list transition smoke."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
