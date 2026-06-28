extends SceneTree

const DEFAULT_RESULT_PATH := "res://.codex-tmp/fishing-drag-spike/result.json"

var samples: Array = []
var active_probe_label := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_write_json({"status": "started"})
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	OS.set_environment("IDLE_ELITE_HEADLESS_SIMPLE_ACTION_BG", "1")
	OS.set_environment("IDLE_ELITE_TRACE_PROCESS_SLOW", "0")
	OS.set_environment("IDLE_ELITE_TRACE_PROCESS_SKILL", "")
	OS.set_environment("IDLE_ELITE_TRACE_FISHING_INPUT", "0")
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
	await _render_fishing(main)
	await _drag_probe(main, "cold-touch-up", true, -720.0)
	await _drag_probe_from_first_location_tile(main, "cold-mouse-tile-up", false, -720.0)
	await _warmup(main)
	await _drag_probe(main, "touch-up", true, -720.0)
	await _drag_probe(main, "touch-down", true, 720.0)
	await _drag_probe(main, "mouse-up", false, -720.0)
	await _drag_probe_from_first_location_tile(main, "touch-tile-up", true, -720.0)
	await _drag_probe_from_first_location_tile(main, "mouse-tile-up", false, -720.0)
	_write_json(_summary(main))
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
	main.call("_sync_detail_lazy_visible_cards", true, 8)
	main.call("_sync_detail_actions_scroll_limit")
	main.call("_sync_fishing_detail_render_culling", true)
	await process_frame


func _warmup(main: Node) -> void:
	var scroll := main.get("detail_actions_scroll") as ScrollContainer
	if scroll == null:
		return
	for target in [0, scroll.get_max_scroll_vertical() / 2, 0]:
		scroll.scroll_vertical = int(target)
		scroll.set("drag_scroll_position", float(target))
		main.call("_sync_detail_lazy_visible_cards", true, 8)
		main.call("_sync_fishing_detail_render_culling", true)
		for _i in range(12):
			await process_frame
	scroll.scroll_vertical = 0
	scroll.set("drag_scroll_position", 0.0)
	main.call("_sync_detail_lazy_visible_cards", true, 8)
	main.call("_sync_fishing_detail_render_culling", true)
	for _i in range(8):
		await process_frame


func _drag_probe(main: Node, label: String, use_touch: bool, drag_distance_y: float) -> void:
	var scroll := main.get("detail_actions_scroll") as ScrollContainer
	if scroll == null:
		samples.append({"probe": label, "error": "missing_scroll"})
		return
	active_probe_label = label
	var max_scroll: int = scroll.get_max_scroll_vertical()
	var start_scroll: int = int(clampi(max_scroll / 2, 300, maxi(300, max_scroll - 300)))
	scroll.scroll_vertical = start_scroll
	scroll.set("drag_scroll_position", float(start_scroll))
	await process_frame
	var rect := scroll.get_global_rect()
	var start := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.62)
	await _run_drag_sequence(main, scroll, label, use_touch, drag_distance_y, start, start_scroll)


func _drag_probe_from_first_location_tile(main: Node, label: String, use_touch: bool, drag_distance_y: float) -> void:
	var scroll := main.get("detail_actions_scroll") as ScrollContainer
	if scroll == null:
		samples.append({"probe": label, "error": "missing_scroll"})
		return
	active_probe_label = label
	await _scroll_until_location_tile_visible(main, scroll)
	var start := _first_visible_location_tile_center(main, scroll)
	if start == Vector2.INF:
		var diagnostics := _location_tile_diagnostics(main, scroll)
		diagnostics["probe"] = label
		diagnostics["error"] = "missing_location_tile"
		samples.append(diagnostics)
		active_probe_label = ""
		return
	await _run_drag_sequence(main, scroll, label, use_touch, drag_distance_y, start, int(scroll.scroll_vertical))


func _scroll_until_location_tile_visible(main: Node, scroll: ScrollContainer) -> void:
	var max_scroll: int = scroll.get_max_scroll_vertical()
	var step := 240
	var target := 0
	while target <= max_scroll:
		scroll.scroll_vertical = target
		scroll.set("drag_scroll_position", float(target))
		for _i in range(4):
			await process_frame
			if not bool(main.get("detail_scroll_visual_work_this_frame")):
				main.call("_sync_detail_lazy_visible_cards", true, 8)
				main.call("_sync_fishing_detail_render_culling", true)
		if _first_visible_location_tile_center(main, scroll) != Vector2.INF:
			return
		target += step
	scroll.scroll_vertical = 0
	scroll.set("drag_scroll_position", 0.0)
	main.call("_sync_detail_lazy_visible_cards", true, 8)
	main.call("_sync_fishing_detail_render_culling", true)
	await process_frame


func _first_visible_location_tile_center(main: Node, scroll: ScrollContainer) -> Vector2:
	var scroll_rect := scroll.get_global_rect()
	var cards := main.get("action_cards") as Dictionary
	for raw_card in cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		if bool(card.get("is_fishing_location", false)):
			var direct_center := _visible_location_tile_center_for_card(card, scroll_rect)
			if direct_center != Vector2.INF:
				return direct_center
		for raw_method_card in (card.get("method_slots", {}) as Dictionary).values():
			if typeof(raw_method_card) != TYPE_DICTIONARY:
				continue
			var method_card := raw_method_card as Dictionary
			if not bool(method_card.get("is_fishing_location", false)):
				continue
			var nested_center := _visible_location_tile_center_for_card(method_card, scroll_rect)
			if nested_center != Vector2.INF:
				return nested_center
	return Vector2.INF


func _visible_location_tile_center_for_card(card: Dictionary, scroll_rect: Rect2) -> Vector2:
	var hit_control := card.get("method_image_hit_control", null) as Control
	if hit_control == null or not is_instance_valid(hit_control) or not hit_control.is_inside_tree() or not hit_control.is_visible_in_tree():
		return Vector2.INF
	var hit_rect := hit_control.get_global_rect()
	if not hit_rect.intersects(scroll_rect):
		return Vector2.INF
	return hit_rect.get_center()


func _location_tile_diagnostics(main: Node, scroll: ScrollContainer) -> Dictionary:
	var cards := main.get("action_cards") as Dictionary
	var scroll_rect := scroll.get_global_rect()
	var location_cards := 0
	var method_slots := 0
	var controls := 0
	var inside_tree := 0
	var visible := 0
	var intersecting := 0
	for raw_card in cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		var candidates: Array = [card]
		for raw_method_card in (card.get("method_slots", {}) as Dictionary).values():
			if typeof(raw_method_card) == TYPE_DICTIONARY:
				method_slots += 1
				candidates.append(raw_method_card as Dictionary)
		for raw_candidate in candidates:
			var candidate := raw_candidate as Dictionary
			if not bool(candidate.get("is_fishing_location", false)):
				continue
			location_cards += 1
			var hit_control := candidate.get("method_image_hit_control", null) as Control
			if hit_control == null or not is_instance_valid(hit_control):
				continue
			controls += 1
			if hit_control.is_inside_tree():
				inside_tree += 1
			if hit_control.is_visible_in_tree():
				visible += 1
			if hit_control.get_global_rect().intersects(scroll_rect):
				intersecting += 1
	return {
		"cards": cards.size(),
		"location_cards": location_cards,
		"method_slots": method_slots,
		"hit_controls": controls,
		"hit_controls_inside_tree": inside_tree,
		"hit_controls_visible": visible,
		"hit_controls_intersecting": intersecting,
		"scroll": int(scroll.scroll_vertical),
		"mounted": int(main.call("_web_fishing_perf_probe_mounted_count")),
	}


func _run_drag_sequence(
	main: Node,
	scroll: ScrollContainer,
	label: String,
	use_touch: bool,
	drag_distance_y: float,
	start: Vector2,
	start_scroll: int
) -> void:
	var end := start + Vector2(0.0, drag_distance_y)
	var press_started := Time.get_ticks_usec()
	var press_timing := _push_pointer_press(main, scroll, start, true, use_touch)
	var after_press_input := Time.get_ticks_usec()
	await process_frame
	var after_press_frame := Time.get_ticks_usec()
	samples.append({
		"probe": label,
		"frame": 0,
		"phase": "press",
		"frame_ms": float(after_press_frame - press_started) / 1000.0,
		"input_ms": float(after_press_input - press_started) / 1000.0,
		"main_input_ms": float(press_timing.get("main_input_us", 0)) / 1000.0,
		"scroll_input_ms": float(press_timing.get("scroll_input_us", 0)) / 1000.0,
		"process_frame_ms": float(after_press_frame - after_press_input) / 1000.0,
		"scroll": int(scroll.scroll_vertical),
		"start_scroll": start_scroll,
		"mode": bool(main.get("fishing_scroll_mode_active")),
	})
	var previous := start
	for index in range(1, 161):
		var pos := start.lerp(end, float(index) / 160.0)
		var before := Time.get_ticks_usec()
		var motion_timing := _push_pointer_motion(main, scroll, pos, pos - previous, use_touch)
		var after_motion_input := Time.get_ticks_usec()
		await process_frame
		var after_motion_frame := Time.get_ticks_usec()
		var frame_ms := float(after_motion_frame - before) / 1000.0
		samples.append({
			"probe": label,
			"frame": index,
			"phase": "motion",
			"frame_ms": frame_ms,
			"input_ms": float(after_motion_input - before) / 1000.0,
			"main_input_ms": float(motion_timing.get("main_input_us", 0)) / 1000.0,
			"scroll_input_ms": float(motion_timing.get("scroll_input_us", 0)) / 1000.0,
			"process_frame_ms": float(after_motion_frame - after_motion_input) / 1000.0,
			"scroll": int(scroll.scroll_vertical),
			"start_scroll": start_scroll,
			"mode": bool(main.get("fishing_scroll_mode_active")),
		})
		previous = pos
	_push_pointer_press(main, scroll, end, false, use_touch)
	for _i in range(20):
		await process_frame
	active_probe_label = ""


func _push_pointer_press(main: Node, scroll: ScrollContainer, position: Vector2, pressed: bool, use_touch: bool) -> Dictionary:
	if use_touch:
		return _push_screen_touch(main, scroll, position, pressed)
	else:
		return _push_mouse_button(main, scroll, position, pressed)


func _push_pointer_motion(main: Node, scroll: ScrollContainer, position: Vector2, relative: Vector2, use_touch: bool) -> Dictionary:
	if use_touch:
		return _push_screen_drag(main, scroll, position, relative)
	else:
		return _push_mouse_motion(main, scroll, position, relative)


func _push_mouse_button(main: Node, scroll: ScrollContainer, position: Vector2, pressed: bool) -> Dictionary:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	var before_main := Time.get_ticks_usec()
	main.call("_input", event)
	var after_main := Time.get_ticks_usec()
	scroll.call("_input", event)
	var after_scroll := Time.get_ticks_usec()
	return {
		"main_input_us": after_main - before_main,
		"scroll_input_us": after_scroll - after_main,
	}


func _push_mouse_motion(main: Node, scroll: ScrollContainer, position: Vector2, relative: Vector2) -> Dictionary:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.relative = relative
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	var before_main := Time.get_ticks_usec()
	main.call("_input", event)
	var after_main := Time.get_ticks_usec()
	scroll.call("_input", event)
	var after_scroll := Time.get_ticks_usec()
	return {
		"main_input_us": after_main - before_main,
		"scroll_input_us": after_scroll - after_main,
	}


func _push_screen_touch(main: Node, scroll: ScrollContainer, position: Vector2, pressed: bool) -> Dictionary:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = position
	var before_main := Time.get_ticks_usec()
	main.call("_input", event)
	var after_main := Time.get_ticks_usec()
	scroll.call("_input", event)
	var after_scroll := Time.get_ticks_usec()
	return {
		"main_input_us": after_main - before_main,
		"scroll_input_us": after_scroll - after_main,
	}


func _push_screen_drag(main: Node, scroll: ScrollContainer, position: Vector2, relative: Vector2) -> Dictionary:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = position
	event.relative = relative
	var before_main := Time.get_ticks_usec()
	main.call("_input", event)
	var after_main := Time.get_ticks_usec()
	scroll.call("_input", event)
	var after_scroll := Time.get_ticks_usec()
	return {
		"main_input_us": after_main - before_main,
		"scroll_input_us": after_scroll - after_main,
	}


func _summary(main: Node) -> Dictionary:
	var values: Array = []
	var over_16 := 0
	var over_33 := 0
	var over_50 := 0
	var max_ms := 0.0
	var probe_scroll_ranges := {}
	var probe_first_scroll_frames := {}
	var worst_samples: Array = []
	for raw_sample in samples:
		var sample := raw_sample as Dictionary
		if sample.has("error"):
			continue
		var value := float(sample.get("frame_ms", 0.0))
		values.append(value)
		max_ms = maxf(max_ms, value)
		if value > 16.67:
			over_16 += 1
		if value > 33.34:
			over_33 += 1
		if value > 50.0:
			over_50 += 1
		var worst_sample := sample.duplicate(true)
		worst_samples.append(worst_sample)
		var probe := str(sample.get("probe", "unknown"))
		var scroll_value := int(sample.get("scroll", 0))
		var range_entry := probe_scroll_ranges.get(probe, {}) as Dictionary
		if range_entry.is_empty():
			range_entry = {"min": scroll_value, "max": scroll_value}
		else:
			range_entry["min"] = mini(int(range_entry.get("min", scroll_value)), scroll_value)
			range_entry["max"] = maxi(int(range_entry.get("max", scroll_value)), scroll_value)
		probe_scroll_ranges[probe] = range_entry
		if not probe_first_scroll_frames.has(probe):
			var start_scroll := int(sample.get("start_scroll", scroll_value))
			if abs(scroll_value - start_scroll) > 0:
				probe_first_scroll_frames[probe] = int(sample.get("frame", 0))
	values.sort()
	worst_samples.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return float(left.get("frame_ms", 0.0)) > float(right.get("frame_ms", 0.0))
	)
	var probe_scroll_deltas := {}
	for raw_probe in probe_scroll_ranges.keys():
		var range_entry := probe_scroll_ranges[raw_probe] as Dictionary
		probe_scroll_deltas[str(raw_probe)] = int(range_entry.get("max", 0)) - int(range_entry.get("min", 0))
	return {
		"status": "ok",
		"mounted": int(main.call("_web_fishing_perf_probe_mounted_count")),
		"sample_count": values.size(),
		"probe_scroll_deltas": probe_scroll_deltas,
		"probe_first_scroll_frames": probe_first_scroll_frames,
		"p50_ms": _percentile(values, 0.50),
		"p95_ms": _percentile(values, 0.95),
		"p99_ms": _percentile(values, 0.99),
		"max_ms": max_ms,
		"over_16": over_16,
		"over_33": over_33,
		"over_50": over_50,
		"worst_samples": worst_samples.slice(0, mini(20, worst_samples.size())),
		"tail": samples.slice(maxi(0, samples.size() - 12), samples.size()),
	}


func _percentile(values: Array, pct: float) -> float:
	if values.is_empty():
		return 0.0
	var index := clampi(int(ceil(float(values.size()) * pct)) - 1, 0, values.size() - 1)
	return float(values[index])


func _write_json(payload: Dictionary) -> void:
	var result_path := OS.get_environment("IDLE_ELITE_FISHING_DRAG_SPIKE_RESULT")
	if result_path.is_empty():
		result_path = DEFAULT_RESULT_PATH
	var file := FileAccess.open(result_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(payload, "\t"))
		file.close()
