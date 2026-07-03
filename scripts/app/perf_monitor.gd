## Attach to any Node in the scene tree. Prints a performance report every 3 seconds.
## Can also show a screenshot-friendly overlay for device performance reports.
extends Node

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
	_overlay_panel.offset_left = 28
	_overlay_panel.offset_top = 28
	_overlay_panel.custom_minimum_size = Vector2(880, 430)
	_overlay_panel.add_theme_stylebox_override("panel", _overlay_style())
	_overlay_layer.add_child(_overlay_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	_overlay_panel.add_child(margin)

	_overlay_label = Label.new()
	_overlay_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_overlay_label.add_theme_font_size_override("font_size", 42)
	_overlay_label.add_theme_color_override("font_color", Color.WHITE)
	_overlay_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	_overlay_label.add_theme_constant_override("shadow_offset_x", 2)
	_overlay_label.add_theme_constant_override("shadow_offset_y", 2)
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
	style.border_width_left = 4
	style.border_width_top = 4
	style.border_width_right = 4
	style.border_width_bottom = 4
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style


func _vsync_name(mode: int) -> String:
	match mode:
		DisplayServer.VSYNC_DISABLED: return "DISABLED"
		DisplayServer.VSYNC_ENABLED: return "ENABLED"
		DisplayServer.VSYNC_ADAPTIVE: return "ADAPTIVE"
		DisplayServer.VSYNC_MAILBOX: return "MAILBOX"
	return "UNKNOWN"
