extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	OS.set_environment("IDLE_ELITE_HEADLESS_SIMPLE_ACTION_BG", "1")
	var packed := load("res://scenes/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.set("running_skill_id", "woodcutting")
	scene.set("running_action_id", _first_action_id(scene, "woodcutting"))
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "woodcutting")
	var navigation: Object = scene.call("_navigation_shell") as Object
	var render_result = navigation.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame

	var detail_frame := scene.call("_skill_swipe_activity_surface").get("skill_swipe_frame") as Control
	_expect(detail_frame != null and is_instance_valid(detail_frame), "skill detail frame was not built")
	var cache_overlay := navigation.get("skill_menu_cache_overlay") as Control
	_expect(cache_overlay != null and cache_overlay.get_child_count() > 0, "skills menu cache was not prebuilt during boot")
	navigation.set("top_level_nav_locked_until_msec", 0)
	var skills_button := navigation.get("skills_utility_tab") as Button
	if skills_button == null:
		_fail("skills utility button was not built")
		return
	var started_usec := Time.get_ticks_usec()
	skills_button.emit_signal("pressed")
	var initial_usec := Time.get_ticks_usec() - started_usec
	var initial_cards := (scene.get("skill_cards") as Dictionary).size()
	var expected_cards := (scene.get("skill_defs") as Array).size()
	_expect(not bool(navigation.get("screen_render_in_progress")), "cache swap started a page render")
	_expect(initial_cards == expected_cards, "cache swap did not reveal every skill card atomically")
	_expect(str(scene.get("current_screen")) == "menu", "cache swap did not open the skills menu")
	_expect(cache_overlay.visible, "skills menu cache was not made visible")
	await process_frame
	var drawers := navigation.get("skill_menu_active_drawers") as Dictionary
	var running_drawer := drawers.get("woodcutting", {}) as Dictionary
	var drawer_slot := running_drawer.get("slot") as Control
	_expect(drawer_slot != null and drawer_slot.get_child_count() > 0, "running activity drawer was not mounted")
	var refresh_result = navigation.call("_render_screen")
	if refresh_result != null:
		await refresh_result
	_expect(scene.get("skills_content") == cache_overlay, "menu refresh replaced the cached overview")
	navigation.set("top_level_nav_locked_until_msec", 0)
	skills_button.emit_signal("pressed")
	await process_frame
	var restored_frame := scene.call("_skill_swipe_activity_surface").get("skill_swipe_frame") as Control
	_expect(str(scene.get("current_screen")) == "skill", "second skills button press did not return to the skill page")
	_expect(restored_frame == detail_frame, "returning from the skills menu rebuilt the preserved detail page")
	_expect(not cache_overlay.visible, "skills menu cache remained visible after returning")
	if failures.is_empty():
		print("skills-menu-transition-ok initial_us=%s cards=%s detail_reused=true" % [initial_usec, initial_cards])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _first_action_id(scene: Node, skill_id: String) -> String:
	for raw_action in scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", skill_id):
		var action := raw_action as Dictionary
		if not action.is_empty() and not bool(scene.call("_passive_modules_runtime").is_passive_action(action)):
			return str(action.get("id", ""))
	return ""


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
