extends RefCounted

const PENDING_CRASH_REPORT_PATH := "user://pending-crash-report.json"
const CRASH_SESSION_MARKER_PATH := "user://last-session-marker.json"
const ANDROID_DIAGNOSTIC_EVENTS_PATH := "user://android-diagnostic-events.txt"
const MAX_ANDROID_DIAGNOSTIC_EVENTS_IN_REPORT := 80
const CRASH_SESSION_HEARTBEAT_SECONDS := 15.0
const ANDROID_LIFECYCLE_EVENTS := ["create", "start", "restart", "resume", "pause", "stop", "destroy"]
const ANDROID_CLEAN_LIFECYCLE_EVENTS := ["pause", "stop", "destroy"]

var host
var pending_crash_report_text := ""
var crash_session_id := ""
var crash_session_heartbeat_elapsed := 0.0


func _init(host_ref = null) -> void:
	host = host_ref


func start_session() -> void:
	crash_session_id = _new_crash_session_id()


func begin_boot_session() -> void:
	start_session()
	call_deferred("load_pending_crash_report")
	call_deferred("synthesize_unclean_session_crash_report")
	call_deferred("write_session_marker", "booting")


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
	return clipboard_text(pending_crash_report_text)


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
	var online_runtime = host._online_runtime()
	return {
		"startup_initialized": host.startup_initialized,
		"warmup_active": host._boot_warmup_runtime().active,
		"current_screen": host.current_screen,
		"selected_skill_id": save_runtime._selected_skill_id_for_save(),
		"running_skill_id": save_runtime._running_skill_id_for_save(),
		"running_action_id": save_runtime._running_action_id_for_save(),
		"action_progress": save_runtime._action_progress_for_save(),
		"event_running_skill_id": save_runtime._event_running_skill_id_for_save(),
		"event_running_action_id": save_runtime._event_running_action_id_for_save(),
		"event_action_progress": save_runtime._event_action_progress_for_save(),
		"chat_overlay_visible": host._profile_chat_overlay_surface().chat_overlay_visible(),
		"chat_rows": online_runtime.chat_rows.size(),
		"chat_stream_connected": online_runtime.chat_stream_connected,
		"chat_stream_connecting": online_runtime.chat_stream_connecting,
		"chat_keyboard_focus_active": host._profile_chat_overlay_surface().keyboard_focus_active(),
		"chat_keyboard_lift_pixels": host._profile_chat_overlay_surface().keyboard_lift_pixels(),
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
	if previous_android_lifecycle_was_clean(android_events):
		return
	var previous_lifecycle := previous_android_lifecycle_before_launch(android_events)
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


static func clipboard_text(raw_report: String) -> String:
	var json := JSON.new()
	if json.parse(raw_report) != OK:
		return raw_report
	var parsed = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return raw_report
	var report := parsed as Dictionary
	var lines := ["Idle Elite crash report v2"]
	var kind := str(report.get("kind", "java_exception"))
	var events := diagnostic_events(report)
	lines.append("type: %s" % kind)
	if report.has("reason"):
		lines.append("reason: %s" % str(report.get("reason", "")))
	var metadata_summary := android_metadata_summary(report, events)
	if not metadata_summary.is_empty():
		lines.append(metadata_summary)
	if report.has("timestamp_unix"):
		lines.append("time_unix: %s" % int(report.get("timestamp_unix", 0)))
	elif report.has("timestamp"):
		lines.append("time: %s" % str(report.get("timestamp", "")))
	if kind == "unclean_previous_session" and typeof(report.get("previous_session", {})) == TYPE_DICTIONARY:
		append_previous_session_summary(lines, report.get("previous_session", {}) as Dictionary, events, int(report.get("timestamp_unix", 0)))
	elif report.has("exception"):
		lines.append("exception: %s" % str(report.get("exception", "")))
		lines.append("thread: %s" % str(report.get("thread", "unknown")))
		append_stack_summary(lines, str(report.get("stack_trace", "")))
	if not events.is_empty():
		lines.append("events:")
		append_event_summary(lines, events, 8)
	return "\n".join(lines)


static func append_previous_session_summary(lines: Array, previous: Dictionary, events: Array, report_time_unix: int) -> void:
	lines.append("prev_status: %s startup=%s os=%s" % [
		str(previous.get("status", "")),
		str(previous.get("startup_initialized", false)),
		str(previous.get("os", ""))
	])
	if previous.has("timestamp_unix"):
		var previous_time_unix := int(previous.get("timestamp_unix", 0))
		var age_text := GameFormatting.duration(float(maxi(0, report_time_unix - previous_time_unix))) if report_time_unix > 0 else "unknown"
		lines.append("prev_marker: %s age=%s" % [previous_time_unix, age_text])
	lines.append("screen: %s selected=%s" % [
		str(previous.get("current_screen", "")),
		str(previous.get("selected_skill_id", ""))
	])
	lines.append("running: %s/%s progress=%s" % [
		str(previous.get("running_skill_id", "")),
		str(previous.get("running_action_id", "")),
		GameFormatting.significant_digits(float(previous.get("action_progress", 0.0)), 4)
	])
	var last := str(previous.get("last_result", ""))
	if not last.is_empty():
		lines.append("last: %s" % last)
	var previous_lifecycle := previous_android_lifecycle_before_launch(events)
	if not previous_lifecycle.is_empty():
		var lifecycle_clean := previous_lifecycle in ANDROID_CLEAN_LIFECYCLE_EVENTS
		lines.append("verdict: %s before relaunch; %s" % [
			previous_lifecycle,
			"clean lifecycle exit" if lifecycle_clean else "unclean/native-or-OS-kill suspect"
		])


static func append_stack_summary(lines: Array, stack_trace: String) -> void:
	var stack_lines := []
	for line in stack_trace.split("\n", false):
		var trimmed := str(line).strip_edges()
		if trimmed.is_empty():
			continue
		stack_lines.append(trimmed)
		if stack_lines.size() >= 3:
			break
	if stack_lines.is_empty():
		return
	lines.append("stack:")
	for stack_line in stack_lines:
		lines.append("- %s" % stack_line)


static func append_event_summary(lines: Array, events: Array, max_count: int) -> void:
	var start := maxi(0, events.size() - max_count)
	for i in range(start, events.size()):
		lines.append("- %s" % compact_android_diagnostic_event(str(events[i])))


static func compact_android_diagnostic_event(line: String) -> String:
	var event := str(line).strip_edges()
	var timestamp_separator := event.find(" ")
	var time_text := ""
	if timestamp_separator >= 0:
		var timestamp := event.substr(0, timestamp_separator)
		var time_separator := timestamp.find("T")
		time_text = timestamp.substr(time_separator + 1) if time_separator >= 0 else timestamp
		var millis_separator := time_text.find(".")
		if millis_separator >= 0:
			time_text = time_text.substr(0, millis_separator)
	var event_name := android_diagnostic_event_name(event)
	return "%s %s" % [time_text, event_name] if not time_text.is_empty() else event_name


static func android_metadata_summary(report: Dictionary, events: Array) -> String:
	if report.has("version_name") or report.has("device"):
		var parts := []
		if report.has("version_name"):
			parts.append("build=%s(%s)" % [str(report.get("version_name", "")), int(report.get("version_code", 0))])
		if report.has("device"):
			parts.append("device=%s android=%s" % [str(report.get("device", "")), int(report.get("android_sdk", 0))])
		return " ".join(parts)
	for i in range(events.size() - 1, -1, -1):
		var line := str(events[i])
		var version_index := line.find(" version=")
		if version_index < 0:
			continue
		var device_index := line.find(" device=", version_index)
		var build_text := line.substr(version_index + " version=".length(), device_index - version_index - " version=".length()) if device_index >= 0 else line.substr(version_index + " version=".length())
		var device_text := line.substr(device_index + " device=".length()) if device_index >= 0 else ""
		return "build=%s device=%s" % [build_text, device_text] if not device_text.is_empty() else "build=%s" % build_text
	return ""


static func diagnostic_events(report: Dictionary) -> Array:
	var events = report.get("android_diagnostic_events", [])
	if typeof(events) == TYPE_ARRAY and not (events as Array).is_empty():
		return events as Array
	events = report.get("diagnostic_events", [])
	if typeof(events) == TYPE_ARRAY:
		return events as Array
	return []


static func android_diagnostic_event_name(line: String) -> String:
	var event := line.strip_edges()
	var timestamp_separator := event.find(" ")
	if timestamp_separator >= 0:
		event = event.substr(timestamp_separator + 1)
	var metadata_separator := event.find(" version=")
	if metadata_separator >= 0:
		event = event.substr(0, metadata_separator)
	return event.strip_edges()


static func previous_android_lifecycle_before_launch(events: Array) -> String:
	var launch_index := -1
	for i in range(events.size()):
		if android_diagnostic_event_name(str(events[i])) == "create":
			launch_index = i
	if launch_index <= 0:
		return ""
	for i in range(launch_index - 1, -1, -1):
		var event_name := android_diagnostic_event_name(str(events[i]))
		if event_name in ANDROID_LIFECYCLE_EVENTS:
			return event_name
	return ""


static func previous_android_lifecycle_was_clean(events: Array) -> bool:
	return previous_android_lifecycle_before_launch(events) in ANDROID_CLEAN_LIFECYCLE_EVENTS
