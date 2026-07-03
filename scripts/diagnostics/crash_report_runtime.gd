class_name CrashReportRuntime
extends RefCounted

const CrashReports = preload("res://scripts/diagnostics/crash_reports.gd")

const PENDING_CRASH_REPORT_PATH := "user://pending-crash-report.json"
const CRASH_SESSION_MARKER_PATH := "user://last-session-marker.json"
const ANDROID_DIAGNOSTIC_EVENTS_PATH := "user://android-diagnostic-events.txt"
const MAX_ANDROID_DIAGNOSTIC_EVENTS_IN_REPORT := 80
const CRASH_SESSION_HEARTBEAT_SECONDS := 15.0

var host
var pending_crash_report_text := ""
var crash_session_id := ""
var crash_session_heartbeat_elapsed := 0.0


func _init(host_ref = null) -> void:
	host = host_ref


func start_session() -> void:
	crash_session_id = _new_crash_session_id()


func pending_report_exists() -> bool:
	return not pending_crash_report_text.is_empty() or FileAccess.file_exists(PENDING_CRASH_REPORT_PATH)


func load_pending_crash_report() -> void:
	if not FileAccess.file_exists(PENDING_CRASH_REPORT_PATH):
		return
	var file := FileAccess.open(PENDING_CRASH_REPORT_PATH, FileAccess.READ)
	if file != null:
		pending_crash_report_text = file.get_as_text()
		file = null
	delete_pending_crash_report()


func pending_report_clipboard_text() -> String:
	if pending_crash_report_text.is_empty():
		load_pending_crash_report()
	return CrashReports.clipboard_text(pending_crash_report_text)


func clear_pending_report() -> void:
	pending_crash_report_text = ""
	delete_pending_crash_report()


func delete_pending_crash_report() -> void:
	var absolute_path := ProjectSettings.globalize_path(PENDING_CRASH_REPORT_PATH)
	if absolute_path.is_empty():
		return
	var err := DirAccess.remove_absolute(absolute_path)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("Could not clear pending crash report: %s" % error_string(err))


func process_session_heartbeat(delta: float) -> void:
	crash_session_heartbeat_elapsed += delta
	if crash_session_heartbeat_elapsed < CRASH_SESSION_HEARTBEAT_SECONDS:
		return
	crash_session_heartbeat_elapsed = 0.0
	write_session_marker("running")


func write_session_marker(status: String) -> void:
	var file := FileAccess.open(CRASH_SESSION_MARKER_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(crash_session_payload(status), "	"))
	file.flush()
	file.close()


func crash_session_payload(status: String) -> Dictionary:
	var payload := {
		"session_id": crash_session_id,
		"status": status,
		"timestamp_unix": _unix_now(),
		"os": OS.get_name()
	}
	payload.merge(_live_session_context(), true)
	if status != "running":
		payload["android_diagnostic_events"] = load_android_diagnostic_events()
	return payload


func _live_session_context() -> Dictionary:
	if host == null:
		return {}
	var save_runtime = host._save_runtime()
	return {
		"startup_initialized": host.startup_initialized,
		"boot_warmup_active": host.boot_warmup_active,
		"current_screen": host.current_screen,
		"selected_skill_id": save_runtime._selected_skill_id_for_save(),
		"running_skill_id": save_runtime._running_skill_id_for_save(),
		"running_action_id": save_runtime._running_action_id_for_save(),
		"action_progress": save_runtime._action_progress_for_save(),
		"event_running_skill_id": save_runtime._event_running_skill_id_for_save(),
		"event_running_action_id": save_runtime._event_running_action_id_for_save(),
		"event_action_progress": save_runtime._event_action_progress_for_save(),
		"chat_overlay_visible": host.chat_overlay != null and is_instance_valid(host.chat_overlay) and host.chat_overlay.visible,
		"chat_rows": host.chat_rows.size(),
		"chat_stream_connected": host.chat_stream_connected,
		"chat_stream_connecting": host.chat_stream_connecting,
		"chat_keyboard_focus_active": host.chat_keyboard_focus_active,
		"chat_keyboard_lift_pixels": host.chat_keyboard_lift_pixels,
		"last_result": host.last_result
	}


func load_android_diagnostic_events() -> Array:
	if OS.get_name() != "Android" or not FileAccess.file_exists(ANDROID_DIAGNOSTIC_EVENTS_PATH):
		return []
	var file := FileAccess.open(ANDROID_DIAGNOSTIC_EVENTS_PATH, FileAccess.READ)
	if file == null:
		return []
	var lines := file.get_as_text().split("\n", false)
	var events := []
	for line in lines:
		var event := str(line).strip_edges()
		if event.is_empty():
			continue
		events.append(event)
	while events.size() > MAX_ANDROID_DIAGNOSTIC_EVENTS_IN_REPORT:
		events.pop_front()
	return events


func synthesize_unclean_session_crash_report() -> void:
	if pending_report_exists() or not FileAccess.file_exists(CRASH_SESSION_MARKER_PATH):
		return
	var file := FileAccess.open(CRASH_SESSION_MARKER_PATH, FileAccess.READ)
	if file == null:
		return
	var marker_text := file.get_as_text()
	var parsed = _parse_json_silent(marker_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var marker := parsed as Dictionary
	if str(marker.get("status", "")) == "clean":
		return
	var android_events := load_android_diagnostic_events()
	if CrashReports.previous_android_lifecycle_was_clean(android_events):
		return
	var previous_lifecycle := CrashReports.previous_android_lifecycle_before_launch(android_events)
	pending_crash_report_text = JSON.stringify({
		"timestamp_unix": _unix_now(),
		"kind": "unclean_previous_session",
		"reason": "previous_android_lifecycle:%s" % (previous_lifecycle if not previous_lifecycle.is_empty() else "unknown"),
		"message": "Previous session did not mark a clean pause or close. This usually means a native crash, OS process kill, or engine-level exit before the Java crash handler could write a stack trace.",
		"previous_session": marker,
		"android_diagnostic_events": android_events
	}, "	")
	store_pending_crash_report_text()


func store_pending_crash_report_text() -> void:
	if pending_crash_report_text.is_empty():
		return
	var file := FileAccess.open(PENDING_CRASH_REPORT_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(pending_crash_report_text)


func _new_crash_session_id() -> String:
	return "%s-%s" % [_unix_now(), Time.get_ticks_msec()]


func _unix_now() -> int:
	if host != null:
		return host._unix_now()
	return int(Time.get_unix_time_from_system())


func _parse_json_silent(raw_text: String) -> Variant:
	var json := JSON.new()
	if json.parse(raw_text) != OK:
		return null
	return json.data
