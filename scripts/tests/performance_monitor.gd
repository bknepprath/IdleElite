extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var runtime_script = load("res://scripts/app/performance_runtime.gd")
	_expect(runtime_script != null, "Performance runtime script should load.")
	if runtime_script == null:
		_finish()
		return

	var monitor = runtime_script._PerfMonitor.new()
	root.add_child(monitor)
	monitor.set_process(false)
	monitor.set_overlay_visible(true)
	await process_frame

	for i in range(60):
		monitor.record_frame(1.0 / 60.0)
	for i in range(5):
		monitor.record_frame(0.050)

	var report: Dictionary = monitor.current_report()
	_expect(monitor.has_overlay(), "Overlay nodes should be created when enabled.")
	_expect(monitor.is_overlay_visible(), "Overlay should report visible after being enabled.")
	_expect(int(report.get("sample_frames", 0)) == 65, "Report should include every sampled frame.")
	_expect(int(report.get("jank_frames", 0)) == 5, "Report should count frames slower than the jank threshold.")
	_expect(float(report.get("measured_fps", 0.0)) > 0.0, "Report should calculate measured FPS.")
	_expect(float(report.get("max_ms", 0.0)) >= 50.0, "Report should expose max frame time in milliseconds.")
	_expect(str(monitor.report_text()).contains("PERF REPORT"), "Overlay text should include a screenshot-friendly heading.")
	_expect(str(monitor.report_text()).contains("FPS"), "Overlay text should include FPS.")

	for i in range(200):
		monitor.record_frame(1.0 / 120.0)
	report = monitor.current_report()
	_expect(int(report.get("sample_frames", 0)) == 180, "Report sample count should match the rolling window.")
	_expect(int(report.get("jank_frames", 0)) == 0, "Report jank count should match the rolling window.")

	monitor.set_overlay_visible(false)
	_expect(not monitor.is_overlay_visible(), "Overlay should report hidden after being disabled.")
	monitor.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("performance-monitor-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
