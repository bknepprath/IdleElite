extends RefCounted

const MobileScrollContainer = preload("res://scripts/ui/mobile_scroll_container.gd")

const DESKTOP_TARGET_FRAME_RATE := 120
const MOBILE_TARGET_FRAME_RATE := 60
const MOBILE_IDLE_FRAME_RATE := 30
const BATTERY_GOVERNOR_IDLE_AFTER_SECONDS := 4.0
const BATTERY_GOVERNOR_LOW_PROCESSOR_SLEEP_USEC := 8000
const BATTERY_GOVERNOR_FORCE_ENV := "IDLE_ELITE_FORCE_MOBILE_BATTERY_GOVERNOR"

var host
var battery_governor_last_activity_msec := 0
var battery_governor_applied_fps := -1
var battery_governor_low_processor_applied := false
var ui_static_refresh_elapsed := 0.0
var performance_monitor: Node


func _init(host_ref) -> void:
	host = host_ref


func _screen_capped_frame_rate(frame_cap: int) -> int:
	var refresh_rate := int(DisplayServer.screen_get_refresh_rate())
	return mini(refresh_rate, frame_cap) if refresh_rate > 0 else frame_cap


func _mobile_battery_governor_enabled() -> bool:
	return OS.get_environment(BATTERY_GOVERNOR_FORCE_ENV) == "1" or OS.get_name() in ["Android", "iOS"]


func _mobile_active_frame_rate() -> int:
	return _screen_capped_frame_rate(MOBILE_TARGET_FRAME_RATE)


func _mobile_idle_frame_rate() -> int:
	return mini(_mobile_active_frame_rate(), MOBILE_IDLE_FRAME_RATE)


func _apply_performance_cap(frame_rate: int, low_processor_mode: bool) -> void:
	if battery_governor_applied_fps != frame_rate or Engine.max_fps != frame_rate:
		Engine.max_fps = frame_rate
		battery_governor_applied_fps = frame_rate
	var sleep_usec := BATTERY_GOVERNOR_LOW_PROCESSOR_SLEEP_USEC if low_processor_mode else 0
	if battery_governor_low_processor_applied != low_processor_mode or OS.low_processor_usage_mode != low_processor_mode:
		OS.low_processor_usage_mode = low_processor_mode
		battery_governor_low_processor_applied = low_processor_mode
	if OS.low_processor_usage_mode_sleep_usec != sleep_usec:
		OS.low_processor_usage_mode_sleep_usec = sleep_usec


func _record_battery_governor_activity() -> void:
	battery_governor_last_activity_msec = Time.get_ticks_msec()
	if _mobile_battery_governor_enabled():
		_apply_performance_cap(_mobile_active_frame_rate(), false)


func _input_event_wakes_battery_governor(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return true
	if event is InputEventScreenTouch:
		return true
	if event is InputEventScreenDrag:
		return true
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventJoypadMotion:
		var joy_motion := event as InputEventJoypadMotion
		return absf(joy_motion.axis_value) >= 0.2
	if event is InputEventMouseMotion:
		return (
			Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
		)
	return false


func _battery_governor_visual_work_active() -> bool:
	if host._boot_warmup_runtime().active or host.boot_detail_render_in_progress or host._navigation_shell().screen_render_in_progress:
		return true
	if host._skill_detail_surface().detail_scroll_visual_work_this_frame or host._skill_detail_surface().detail_lazy_mounted_this_frame:
		return true
	if host._skill_swipe_loading_transition_active():
		return true
	if host._action_stop_hold().active() or not host._skill_detail_surface().action_card_press_key.is_empty():
		return true
	if host._hub_surface().hub_drag_module_id != "" or host._hub_surface().hub_hotspot_hold_module_id != "":
		return true
	if host._profile_chat_overlay_surface().keyboard_lift_active():
		return true
	if host._tutorial_overlay_surface().activity_start_highlight_active or host._tutorial_overlay_surface().activity_start_highlight_pending:
		return true
	if host._achievement_toast_surface().transient_work_active():
		return true
	if host._navigation_shell()._page_switch_pending_transition_queued() or host.module_ui_animating_collapse_key != "":
		return true
	if host.current_screen == "pinned" and host._navigation_shell()._pinned_active_shelf_has_jailed_action():
		return true
	var navigation_shell = host._navigation_shell()
	if navigation_shell.pin_transition_blocker != null and is_instance_valid(navigation_shell.pin_transition_blocker) and navigation_shell.pin_transition_blocker.visible:
		return true
	if host._skill_detail_surface()._detail_jump_arrows_need_processing():
		return true
	return _skill_detail_has_fishing_camera_returning()


func _skill_detail_needs_high_frequency_ui_update() -> bool:
	var temporary_events = host._temporary_event_runtime()
	if host.current_screen == "menu":
		return not host.running_action_id.is_empty() or not temporary_events.event_running_action_id.is_empty()
	if host.current_screen == "queue":
		return true
	if host.current_screen == "pinned":
		var pinned_scroll := host.content_scroll as MobileScrollContainer
		return (
				not host.running_action_id.is_empty()
				or not temporary_events.event_running_action_id.is_empty()
			or host._action_stop_hold().active()
			or not host._skill_detail_surface().action_card_press_key.is_empty()
			or host._tutorial_overlay_surface().activity_start_highlight_active
			or host._tutorial_overlay_surface().activity_start_highlight_pending
			or host._activity_unlock_ceremony_surface().locked_preview_fade_play_pending
			or host._navigation_shell()._pinned_active_shelf_has_jailed_action()
			or _skill_detail_has_fishing_camera_returning()
			or (pinned_scroll != null and is_instance_valid(pinned_scroll) and (pinned_scroll.drag_scrolling or absf(pinned_scroll.velocity) >= 4.0))
			or absf(host._skill_detail_surface().detail_shelf_shadow_alpha - host._skill_detail_surface()._skill_detail_shadow_target_alpha()) > 0.01
		)
	if host.current_screen != "skill":
		return false
	if host.running_skill_id == host.selected_skill_id and not host.running_action_id.is_empty():
		return true
	if temporary_events.event_running_skill_id == host.selected_skill_id and not temporary_events.event_running_action_id.is_empty():
		return true
	if host._skill_swipe_activity_surface().skill_swipe_tracking or host._skill_swipe_activity_surface().skill_swipe_animating:
		return true
	if host._action_stop_hold().active() or not host._skill_detail_surface().action_card_press_key.is_empty():
		return true
	if host._tutorial_overlay_surface().activity_start_highlight_active or host._tutorial_overlay_surface().activity_start_highlight_pending:
		return true
	if host._activity_unlock_ceremony_surface().locked_preview_fade_play_pending:
		return true
	if host._activity_unlock_runtime().has_pending_readiness_for_skill(host.selected_skill_id) or host._activity_unlock_ceremony_surface().ceremony_count > 0:
		return true
	if host._skill_detail_surface()._detail_jump_arrows_need_processing():
		return true
	if host._skill_swipe_activity_surface()._skill_swipe_previews_need_frame_updates():
		return true
	if _skill_detail_has_fishing_camera_returning():
		return true
	if absf(host._skill_detail_surface().detail_shelf_shadow_alpha - host._skill_detail_surface()._skill_detail_shadow_target_alpha()) > 0.01:
		return true
	return false


func _skill_detail_has_fishing_camera_returning() -> bool:
	if host.current_screen != "skill" and host.current_screen != "pinned":
		return false
	for raw_card in host.action_cards.values():
		var card := raw_card as Dictionary
		if card.is_empty():
			continue
		if bool(card.get("is_fishing_area", false)) and host._fishing_ui_surface()._fishing_area_has_active_camera_return(card):
			return true
		if float(card.get("active_camera_zoom", 0.0)) > 1.0 and (
			bool(card.get("active_camera_returning", false))
			or bool(card.get("active_camera_was_running", false))
		):
			return true
	return false


func _consume_ui_static_refresh(delta: float, instant: bool) -> bool:
	if instant or delta <= 0.0:
		ui_static_refresh_elapsed = 0.0
		return true
	ui_static_refresh_elapsed += delta
	if host.current_screen == "skill" and host._skill_detail_surface().detail_lazy_mounted_this_frame:
		return false
	if host.current_screen == "skill" and host._fishing_rework_active_for_skill(host.selected_skill_id) and host._skill_detail_surface().detail_scroll_visual_work_this_frame:
		return false
	if host._skill_swipe_loading_transition_active():
		return false
	if ui_static_refresh_elapsed < host.UI_STATIC_REFRESH_INTERVAL_SECONDS:
		return false
	ui_static_refresh_elapsed = 0.0
	return true


func _process_battery_governor() -> void:
	if not _mobile_battery_governor_enabled():
		return
	var now_msec := Time.get_ticks_msec()
	if _battery_governor_visual_work_active():
		battery_governor_last_activity_msec = now_msec
	var idle_after_msec := int(BATTERY_GOVERNOR_IDLE_AFTER_SECONDS * 1000.0)
	var idle := now_msec - battery_governor_last_activity_msec >= idle_after_msec
	_apply_performance_cap(_mobile_idle_frame_rate() if idle else _mobile_active_frame_rate(), idle)


func _configure_performance_mode() -> void:
	battery_governor_last_activity_msec = Time.get_ticks_msec()
	if _mobile_battery_governor_enabled():
		_apply_performance_cap(_mobile_active_frame_rate(), false)
	else:
		_apply_performance_cap(_screen_capped_frame_rate(DESKTOP_TARGET_FRAME_RATE), false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)


func _performance_overlay_enabled_on_boot() -> bool:
	return OS.is_debug_build() and OS.get_environment("IDLE_ELITE_PERF_OVERLAY") == "1"


func _performance_overlay_active() -> bool:
	return performance_monitor != null and is_instance_valid(performance_monitor) and performance_monitor.has_method("is_overlay_visible") and bool(performance_monitor.call("is_overlay_visible"))


func _performance_overlay_toggle_text() -> String:
	return "Performance Overlay: %s" % ("ON" if _performance_overlay_active() else "OFF")


func _ensure_performance_monitor() -> Node:
	if performance_monitor != null and is_instance_valid(performance_monitor):
		return performance_monitor
	performance_monitor = _PerfMonitor.new()
	host.add_child(performance_monitor)
	return performance_monitor


func _set_performance_overlay_enabled(enabled: bool) -> void:
	var monitor := _ensure_performance_monitor()
	if monitor == null or not monitor.has_method("set_overlay_visible"):
		return
	monitor.call("set_overlay_visible", enabled)
	host._settings_surface()._refresh_god_mode_controls()


func clear_monitor_reference() -> void:
	performance_monitor = null


## Debug performance report node owned by PerformanceRuntime.
class _PerfMonitor extends Node:
	const WINDOW_SIZE := 180
	const REPORT_INTERVAL := 3.0
	const OVERLAY_INTERVAL := 0.25
	const JANK_THRESHOLD := 0.040

	var overlay_enabled := false

	var _deltas: Array[float] = []
	var _elapsed := 0.0
	var _overlay_elapsed := 0.0
	var _jank_count := 0
	var _frame_count := 0
	var _last_report := {}
	var _overlay_layer: CanvasLayer
	var _overlay_panel: PanelContainer
	var _overlay_label: Label


	func _ready() -> void:
		_print_system_report()
		if OS.is_debug_build() and OS.get_environment("IDLE_ELITE_PERF_OVERLAY") == "1":
			set_overlay_visible(true)


	func _process(delta: float) -> void:
		record_frame(delta)


	func record_frame(delta: float) -> void:
		_deltas.append(delta)
		if _deltas.size() > WINDOW_SIZE:
			_deltas.pop_front()

		_frame_count += 1
		if delta > JANK_THRESHOLD:
			_jank_count += 1

		_elapsed += delta
		_overlay_elapsed += delta
		if _elapsed >= REPORT_INTERVAL:
			_print_frame_report()
			_elapsed = 0.0
			_jank_count = 0
			_frame_count = 0

		if overlay_enabled and _overlay_elapsed >= OVERLAY_INTERVAL:
			_overlay_elapsed = 0.0
			_sync_overlay()


	func set_overlay_visible(enabled: bool) -> void:
		overlay_enabled = enabled
		if overlay_enabled:
			_ensure_overlay()
			_sync_overlay()
		if _overlay_layer != null and is_instance_valid(_overlay_layer):
			_overlay_layer.visible = overlay_enabled


	func is_overlay_visible() -> bool:
		return overlay_enabled and _overlay_layer != null and is_instance_valid(_overlay_layer) and _overlay_layer.visible


	func has_overlay() -> bool:
		return _overlay_layer != null and is_instance_valid(_overlay_layer) and _overlay_label != null and is_instance_valid(_overlay_label)


	func current_report() -> Dictionary:
		_last_report = _build_frame_report()
		return _last_report.duplicate()


	func report_text() -> String:
		return "\n".join(report_lines())


	func report_lines() -> Array[String]:
		var report := current_report()
		var refresh := float(report.get("screen_hz", 0.0))
		var target_fps := int(report.get("engine_max_fps", 0))
		return [
			"PERF REPORT",
			"FPS %.1f / target %d" % [float(report.get("measured_fps", 0.0)), target_fps],
			"Frame avg %.2f ms  max %.2f ms" % [float(report.get("avg_ms", 0.0)), float(report.get("max_ms", 0.0))],
			"Jitter %.2f ms  jank %d/%d" % [
				float(report.get("stddev_ms", 0.0)),
				int(report.get("jank_frames", 0)),
				int(report.get("sample_frames", 0))
			],
			"Draw calls %d  nodes %d" % [int(report.get("draw_calls", 0)), int(report.get("nodes", 0))],
			"Objects %d  refresh %.0f Hz" % [int(report.get("objects", 0)), refresh],
			"VSync %s  OS %s" % [str(report.get("vsync", "UNKNOWN")), str(report.get("os", "unknown"))]
		]


	func _print_system_report() -> void:
		var refresh := DisplayServer.screen_get_refresh_rate()
		var vsync := DisplayServer.window_get_vsync_mode()
		var vsync_name := _vsync_name(vsync)
		var max_fps := Engine.get_max_fps()
		var os_name := OS.get_name()
		print("=== PERF MONITOR - SYSTEM ===")
		print("  OS:            ", os_name)
		print("  Screen Hz:     ", refresh)
		print("  Engine max_fps:", max_fps)
		print("  VSync mode:    ", vsync_name, " (", vsync, ")")
		print("  Physics Hz:    ", Engine.physics_ticks_per_second)
		print("  Render method: ", ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"))
		print("=============================")


	func _print_frame_report() -> void:
		var report := current_report()
		if int(report.get("sample_frames", 0)) <= 0:
			return
		print("=== PERF MONITOR - FRAME REPORT ===")
		print("  Measured FPS:  ", "%.1f" % float(report.get("measured_fps", 0.0)))
		print("  Avg delta:     ", "%.2f" % float(report.get("avg_ms", 0.0)), " ms")
		print("  Min delta:     ", "%.2f" % float(report.get("min_ms", 0.0)), " ms")
		print("  Max delta:     ", "%.2f" % float(report.get("max_ms", 0.0)), " ms")
		print("  Std dev:       ", "%.2f" % float(report.get("stddev_ms", 0.0)), " ms  (jitter)")
		print("  Jank frames:   ", int(report.get("jank_frames", 0)), " / ", int(report.get("sample_frames", 0)),
			  " (>", int(JANK_THRESHOLD * 1000), "ms)")
		print("  Draw calls:    ", int(report.get("draw_calls", 0)))
		print("  Objects:       ", int(report.get("objects", 0)))
		print("  Nodes:         ", int(report.get("nodes", 0)))
		print("===================================")


	func _build_frame_report() -> Dictionary:
		if _deltas.is_empty():
			return {
				"sample_frames": 0,
				"measured_fps": 0.0,
				"avg_ms": 0.0,
				"min_ms": 0.0,
				"max_ms": 0.0,
				"stddev_ms": 0.0,
				"jank_frames": 0,
				"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
				"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
				"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
				"screen_hz": float(DisplayServer.screen_get_refresh_rate()),
				"engine_max_fps": int(Engine.get_max_fps()),
				"vsync": _vsync_name(DisplayServer.window_get_vsync_mode()),
				"os": OS.get_name()
			}

		var sum := 0.0
		var min_d := _deltas[0]
		var max_d := _deltas[0]
		for d in _deltas:
			sum += d
			if d < min_d:
				min_d = d
			if d > max_d:
				max_d = d
		var avg := sum / _deltas.size()

		var variance := 0.0
		for d in _deltas:
			var diff := d - avg
			variance += diff * diff
		variance /= _deltas.size()
		var stddev := sqrt(variance)
		var measured_fps := 1.0 / avg if avg > 0.0 else 0.0

		return {
			"sample_frames": _frame_count,
			"measured_fps": measured_fps,
			"avg_ms": avg * 1000.0,
			"min_ms": min_d * 1000.0,
			"max_ms": max_d * 1000.0,
			"stddev_ms": stddev * 1000.0,
			"jank_frames": _jank_count,
			"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
			"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"screen_hz": float(DisplayServer.screen_get_refresh_rate()),
			"engine_max_fps": int(Engine.get_max_fps()),
			"vsync": _vsync_name(DisplayServer.window_get_vsync_mode()),
			"os": OS.get_name()
		}


	func _ensure_overlay() -> void:
		if has_overlay():
			return
		_overlay_layer = CanvasLayer.new()
		_overlay_layer.layer = 1000
		add_child(_overlay_layer)

		_overlay_panel = PanelContainer.new()
		_overlay_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay_panel.offset_left = 14
		_overlay_panel.offset_top = 14
		_overlay_panel.custom_minimum_size = Vector2(440, 215)
		_overlay_panel.add_theme_stylebox_override("panel", _overlay_style())
		_overlay_layer.add_child(_overlay_panel)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_top", 11)
		margin.add_theme_constant_override("margin_right", 14)
		margin.add_theme_constant_override("margin_bottom", 11)
		_overlay_panel.add_child(margin)

		_overlay_label = Label.new()
		_overlay_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_overlay_label.add_theme_font_size_override("font_size", 48)
		_overlay_label.add_theme_color_override("font_color", Color.WHITE)
		_overlay_label.add_theme_color_override("font_shadow_color", Color.BLACK)
		_overlay_label.add_theme_constant_override("shadow_offset_x", 1)
		_overlay_label.add_theme_constant_override("shadow_offset_y", 1)
		margin.add_child(_overlay_label)


	func _sync_overlay() -> void:
		if not overlay_enabled:
			return
		_ensure_overlay()
		_overlay_label.text = report_text()


	func _overlay_style() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.03, 0.03, 0.03, 0.84)
		style.border_color = Color(1.0, 1.0, 1.0, 0.55)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 9
		style.corner_radius_top_right = 9
		style.corner_radius_bottom_left = 9
		style.corner_radius_bottom_right = 9
		return style


	func _vsync_name(mode: int) -> String:
		match mode:
			DisplayServer.VSYNC_DISABLED: return "DISABLED"
			DisplayServer.VSYNC_ENABLED: return "ENABLED"
			DisplayServer.VSYNC_ADAPTIVE: return "ADAPTIVE"
			DisplayServer.VSYNC_MAILBOX: return "MAILBOX"
		return "UNKNOWN"
