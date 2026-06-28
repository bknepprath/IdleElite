extends SceneTree

const DEFAULT_RESULT_PATH := "res://.codex-tmp/fishing-wallet-press/result.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_write_json({"status": "started"})
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	OS.set_environment("IDLE_ELITE_HEADLESS_SIMPLE_ACTION_BG", "1")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var main := packed.instantiate()
	root.add_child(main)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	await _wait_for_startup(main)
	_force_fishing_state(main)
	await _render_fishing(main)
	var circle := main.get("detail_fish_circle") as Control
	if circle == null or not is_instance_valid(circle) or not circle.is_inside_tree():
		_fail("missing detail_fish_circle")
		return
	var press_position := circle.get_global_rect().get_center()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = press_position
	event.global_position = press_position
	var started_usec := Time.get_ticks_usec()
	main.call("_input", event)
	var elapsed_msec := float(Time.get_ticks_usec() - started_usec) / 1000.0
	await process_frame
	var wallet_open := bool(main.get("fishing_tool_wallet_open"))
	var popup := main.get("fishing_tool_wallet_popup") as Control
	var popup_visible := popup != null and is_instance_valid(popup) and popup.is_inside_tree()
	_write_json({
		"status": "ok" if wallet_open and popup_visible else "failed",
		"wallet_open": wallet_open,
		"popup_visible": popup_visible,
		"press_msec": elapsed_msec
	})
	root.remove_child(main)
	main.queue_free()
	quit(0 if wallet_open and popup_visible else 1)


func _wait_for_startup(main: Node) -> void:
	for _i in range(720):
		if bool(main.get("startup_initialized")) and not bool(main.get("boot_detail_render_in_progress")):
			await process_frame
			return
		await process_frame


func _force_fishing_state(main: Node) -> void:
	for skill_id in ["fight", "build", "woodcutting", "thieving", "fishing"]:
		_set_skill_level(main, skill_id, 99)
	main.call("_god_mode_unlock_actions_state")
	main.call("_god_mode_unlock_fishing_tools_state")
	main.call("_sync_manual_activity_unlocks_from_levels")
	main.set("current_screen", "skill")
	main.set("selected_skill_id", "fishing")
	main.set("module_ui_sort_mode", "level")
	main.set("module_ui_collapsed", {})
	main.set("equipped_fishing_tool_id", "star_rod")
	main.set("fishing_net_collected", true)
	main.set("fishing_rod_collected", true)
	main.set("fishing_reinforced_rod_collected", true)
	main.set("fishing_star_rod_collected", true)
	main.set("fishing_boat_built", true)
	main.set("fishing_mirror_collected", true)


func _set_skill_level(main: Node, skill_id: String, level: int) -> void:
	var skills := main.get("skills") as Dictionary
	if not skills.has(skill_id):
		skills[skill_id] = {"xp": 0, "level": 1}
	(skills[skill_id] as Dictionary)["xp"] = int(main.call("_xp_for_level", level)) + 1000
	(skills[skill_id] as Dictionary)["level"] = level
	main.set("skills", skills)
	main.call("_recalculate_level", skill_id, false)
	var stamina := main.get("stamina") as Dictionary
	stamina[skill_id] = float(main.call("_max_stamina", skill_id))
	main.set("stamina", stamina)


func _render_fishing(main: Node) -> void:
	var render_result = main.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	main.call("_cancel_detail_lazy_settle_warm_mount")
	main.call("_detail_lazy_mount_initial_window_sync", true, 4)
	main.call("_sync_detail_actions_scroll_limit")
	await process_frame


func _result_path() -> String:
	var path := OS.get_environment("IDLE_ELITE_FISHING_WALLET_PRESS_RESULT").strip_edges()
	return path if not path.is_empty() else DEFAULT_RESULT_PATH


func _write_json(payload: Dictionary) -> void:
	var path := _result_path()
	var absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(absolute, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
	file.close()


func _fail(message: String) -> void:
	_write_json({"status": "failed", "error": message})
	quit(1)
