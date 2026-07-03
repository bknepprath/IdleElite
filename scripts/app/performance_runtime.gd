extends RefCounted

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


func _process_battery_governor() -> void:
	if not _mobile_battery_governor_enabled():
		return
	var now_msec := Time.get_ticks_msec()
	if host._battery_governor_visual_work_active():
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
	var monitor_script := load("res://scripts/app/perf_monitor.gd")
	if monitor_script == null:
		push_warning("Performance monitor script is missing.")
		return null
	performance_monitor = monitor_script.new()
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
