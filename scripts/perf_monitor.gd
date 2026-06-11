## Attach to any Node in the scene tree. Prints a performance report every 3 seconds.
## Also prints an immediate system report on _ready.
extends Node

const WINDOW_SIZE := 180       # frames to keep in the rolling window
const REPORT_INTERVAL := 3.0   # seconds between console reports
const JANK_THRESHOLD := 0.040  # frames longer than this (ms=40) are flagged as jank

var _deltas: Array[float] = []
var _elapsed := 0.0
var _jank_count := 0
var _frame_count := 0

func _ready() -> void:
	_print_system_report()

func _process(delta: float) -> void:
	_deltas.append(delta)
	if _deltas.size() > WINDOW_SIZE:
		_deltas.pop_front()

	_frame_count += 1
	if delta > JANK_THRESHOLD:
		_jank_count += 1

	_elapsed += delta
	if _elapsed >= REPORT_INTERVAL:
		_print_frame_report()
		_elapsed = 0.0
		_jank_count = 0
		_frame_count = 0

func _print_system_report() -> void:
	var refresh := DisplayServer.screen_get_refresh_rate()
	var vsync := DisplayServer.window_get_vsync_mode()
	var vsync_name := _vsync_name(vsync)
	var max_fps := Engine.get_max_fps()
	var os_name := OS.get_name()
	print("=== PERF MONITOR — SYSTEM ===")
	print("  OS:            ", os_name)
	print("  Screen Hz:     ", refresh)
	print("  Engine max_fps:", max_fps)
	print("  VSync mode:    ", vsync_name, " (", vsync, ")")
	print("  Physics Hz:    ", Engine.physics_ticks_per_second)
	print("  Render method: ", ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"))
	print("==============================")

func _print_frame_report() -> void:
	if _deltas.is_empty():
		return
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

	# variance / stddev
	var variance := 0.0
	for d in _deltas:
		var diff := d - avg
		variance += diff * diff
	variance /= _deltas.size()
	var stddev := sqrt(variance)

	# measured fps
	var measured_fps := 1.0 / avg if avg > 0.0 else 0.0

	print("=== PERF MONITOR — FRAME REPORT ===")
	print("  Measured FPS:  ", "%.1f" % measured_fps)
	print("  Avg delta:     ", "%.2f" % (avg * 1000.0), " ms")
	print("  Min delta:     ", "%.2f" % (min_d * 1000.0), " ms")
	print("  Max delta:     ", "%.2f" % (max_d * 1000.0), " ms")
	print("  Std dev:       ", "%.2f" % (stddev * 1000.0), " ms  (jitter)")
	print("  Jank frames:   ", _jank_count, " / ", _frame_count,
		  " (>", int(JANK_THRESHOLD * 1000), "ms)")
	print("  Draw calls:    ", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("  Objects:       ", Performance.get_monitor(Performance.OBJECT_COUNT))
	print("  Nodes:         ", Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	print("====================================")

func _vsync_name(mode: int) -> String:
	match mode:
		DisplayServer.VSYNC_DISABLED:  return "DISABLED"
		DisplayServer.VSYNC_ENABLED:   return "ENABLED"
		DisplayServer.VSYNC_ADAPTIVE:  return "ADAPTIVE"
		DisplayServer.VSYNC_MAILBOX:   return "MAILBOX"
	return "UNKNOWN"
