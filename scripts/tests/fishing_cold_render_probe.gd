extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const DEFAULT_RESULT_PATH := "res://.codex-tmp/fishing-cold-render-probe/result.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_write_json({"status": "started"})
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	OS.set_environment("IDLE_ELITE_HEADLESS_SIMPLE_ACTION_BG", "1")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_write_json({"status": "failed", "error": "main scene did not load"})
		quit(1)
		return
	var main := packed.instantiate()
	root.add_child(main)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	await _wait_for_startup(main)
	_force_level_99_fishing_state(main)
	var render_started_usec := Time.get_ticks_usec()
	var render_result = main.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	var render_msec := float(Time.get_ticks_usec() - render_started_usec) / 1000.0
	var immediate_mounted := _mounted_count(main)
	var detail_surface = main.call("_skill_detail_surface")
	var plan_count := (detail_surface.detail_lazy_plan as Array).size()
	var visible_placeholders := bool(main.call("_skill_detail_has_visible_lazy_placeholders"))
	var warm_frames := 0
	var max_warm_frame_msec := 0.0
	var warm_over_50 := 0
	while warm_frames < 180:
		warm_frames += 1
		var warm_started_usec := Time.get_ticks_usec()
		await process_frame
		var warm_frame_msec := float(Time.get_ticks_usec() - warm_started_usec) / 1000.0
		max_warm_frame_msec = maxf(max_warm_frame_msec, warm_frame_msec)
		if warm_frame_msec > 50.0:
			warm_over_50 += 1
	var warmed_mounted := _mounted_count(main)
	var warmed_visible_placeholders := bool(main.call("_skill_detail_has_visible_lazy_placeholders"))
	_write_json({
		"status": "ok",
		"render_msec": render_msec,
		"immediate_mounted": immediate_mounted,
		"warmed_mounted": warmed_mounted,
		"plan": plan_count,
		"warm_frames": warm_frames,
		"max_warm_frame_msec": max_warm_frame_msec,
		"warm_over_50": warm_over_50,
		"warm_skill_id": str(detail_surface.detail_lazy_settle_warm_mount_skill_id),
		"lazy_all_mounted": bool(detail_surface.call("_detail_lazy_all_mounted")),
		"visible_placeholders": visible_placeholders,
		"warmed_visible_placeholders": warmed_visible_placeholders,
		"unmounted_entries": _unmounted_entries(main)
	})
	root.remove_child(main)
	main.queue_free()
	quit(0)


func _wait_for_startup(main: Node) -> void:
	for _i in range(720):
		if bool(main.get("startup_initialized")) and not bool(main.get("boot_detail_render_in_progress")):
			await process_frame
			return
		await process_frame


func _force_level_99_fishing_state(main: Node) -> void:
	for skill_id in ["fight", "build", "woodcutting", "thieving"]:
		_set_skill_level(main, skill_id, 1)
	_set_skill_level(main, "fishing", 99)
	main.call("_test_state_runtime")._god_mode_unlock_actions_state()
	main.call("_test_state_runtime")._god_mode_unlock_fishing_tools_state()
	main.call("_activity_unlock_runtime").sync_manual_activity_unlocks_from_levels()
	main.set("current_screen", "skill")
	main.set("selected_skill_id", "fishing")
	main.set("module_ui_sort_mode", "level")
	main.set("module_ui_collapsed", {})
	main.fishing_runtime.equipped_tool_id = "star_rod"
	main.fishing_runtime.net_collected = true
	main.fishing_runtime.rod_collected = true
	main.fishing_runtime.reinforced_rod_collected = true
	main.fishing_runtime.star_rod_collected = true
	main.fishing_runtime.boat_built = true
	main.fishing_runtime.mirror_collected = true


func _set_skill_level(main: Node, skill_id: String, level: int) -> void:
	var skills := main.get("skills") as Dictionary
	if not skills.has(skill_id):
		skills[skill_id] = {"xp": 0, "level": 1}
	(skills[skill_id] as Dictionary)["xp"] = SkillState.xp_for_level(level)
	(skills[skill_id] as Dictionary)["level"] = level
	main.set("skills", skills)
	SkillState.recalculate_level(main, skill_id, false)
	var stamina := main.get("stamina") as Dictionary
	stamina[skill_id] = float(SkillState.max_stamina(main, skill_id))
	main.set("stamina", stamina)


func _mounted_count(main: Node) -> int:
	var mounted := 0
	var detail_surface = main.call("_skill_detail_surface")
	for raw_entry in detail_surface.detail_lazy_plan as Array:
		var lazy_entry := raw_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			mounted += 1
	return mounted


func _unmounted_entries(main: Node) -> Array:
	var entries: Array = []
	var detail_surface = main.call("_skill_detail_surface")
	for raw_entry in detail_surface.detail_lazy_plan as Array:
		var lazy_entry := raw_entry as Dictionary
		if bool(lazy_entry.get("mounted", false)):
			continue
		var stack_host := lazy_entry.get("stack_host", null) as Control
		entries.append({
			"kind": str(lazy_entry.get("kind", "")),
			"track_id": str(lazy_entry.get("track_id", "")),
			"has_stack_host": stack_host != null and is_instance_valid(stack_host),
			"has_placeholder": lazy_entry.has("placeholder"),
			"height": float(lazy_entry.get("height", 0.0))
		})
	return entries




func _write_json(payload: Dictionary) -> void:
	var absolute_path := ProjectSettings.globalize_path(DEFAULT_RESULT_PATH)
	var directory := absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(directory):
		DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))
