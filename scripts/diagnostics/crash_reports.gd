class_name CrashReports

const ANDROID_LIFECYCLE_EVENTS := ["create", "start", "restart", "resume", "pause", "stop", "destroy"]
const ANDROID_CLEAN_LIFECYCLE_EVENTS := ["pause", "stop", "destroy"]


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
		var age_text := _format_duration(float(maxi(0, report_time_unix - previous_time_unix))) if report_time_unix > 0 else "unknown"
		lines.append("prev_marker: %s age=%s" % [previous_time_unix, age_text])
	lines.append("screen: %s selected=%s" % [
		str(previous.get("current_screen", "")),
		str(previous.get("selected_skill_id", ""))
	])
	lines.append("running: %s/%s progress=%s" % [
		str(previous.get("running_skill_id", "")),
		str(previous.get("running_action_id", "")),
		_format_significant_digits(float(previous.get("action_progress", 0.0)), 4)
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


static func _format_significant_digits(value: float, digits := 3) -> String:
	var safe_digits := maxi(1, digits)
	var absolute := absf(value)
	if absolute < 0.000001:
		return "0"
	var places := safe_digits - 1 - int(floor(log(absolute) / log(10.0)))
	if places < 0:
		var factor := pow(10.0, float(-places))
		return "%.0f" % (round(value / factor) * factor)
	places = mini(places, 6)
	var format := "%." + str(places) + "f"
	return _trim_trailing_decimal_zeroes(format % value)


static func _trim_trailing_decimal_zeroes(text: String) -> String:
	if text.find(".") == -1:
		return text
	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return "0" if text == "-0" else text


static func _format_duration(seconds: float) -> String:
	var total_seconds := maxi(0, int(ceil(seconds)))
	var hours := int(floor(float(total_seconds) / 3600.0))
	var minutes := int(floor(float(total_seconds % 3600) / 60.0))
	if hours > 0:
		return "%sh %sm" % [hours, minutes]
	return "%sm" % maxi(1, minutes)
