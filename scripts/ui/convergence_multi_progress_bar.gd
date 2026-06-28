class_name ConvergenceMultiProgressBar
extends Control


var segment_values := [0.0, 0.0, 0.0, 0.0, 0.0]
var segment_colors := [
	Color("#e34b3f"),
	Color("#9b5de5"),
	Color("#f4bf35"),
	Color("#35d86d"),
	Color("#3aa7ff")
]
var empty_color := Color("#fff1c8")
var outline_color := Color("#171615")
var shadow_color := Color(0.08, 0.07, 0.06, 0.30)
var bar_pattern := "loops"

func set_segments(next_values: Array, next_colors: Array = []) -> void:
	for i in range(5):
		segment_values[i] = clampf(float(next_values[i] if i < next_values.size() else 0.0), 0.0, 1.0)
		if i < next_colors.size() and next_colors[i] is Color:
			segment_colors[i] = next_colors[i] as Color
	queue_redraw()

func set_bar_pattern(next_pattern: String) -> void:
	var normalized := next_pattern.strip_edges().to_lower()
	if normalized.is_empty():
		normalized = "loops"
	if bar_pattern == normalized:
		return
	bar_pattern = normalized
	queue_redraw()

func _draw() -> void:
	if size.x <= 12.0 or size.y <= 12.0:
		return
	var paths := _braid_paths() if bar_pattern == "braid" else _segment_paths()
	if paths.size() < 5:
		return
	var base_width := minf(78.0, maxf(72.0, size.y * 0.48))
	var outline_width := base_width + maxf(9.0, size.y * 0.075)
	if bar_pattern == "braid":
		_draw_braid_paths(paths, base_width, outline_width)
		return
	for raw_path in paths:
		var path := raw_path as Array[Vector2]
		_draw_path(path, shadow_color, outline_width + 4.0, 1.0, Vector2(0, 3), false, false)
	for raw_path in paths:
		var path := raw_path as Array[Vector2]
		_draw_path(path, outline_color, outline_width, 1.0, Vector2.ZERO, false, false)
	for raw_path in paths:
		var path := raw_path as Array[Vector2]
		_draw_path(path, empty_color, base_width, 1.0, Vector2.ZERO, false, false)
	for i in range(paths.size()):
		var fill_pct := clampf(float(segment_values[i]), 0.0, 1.0)
		if fill_pct > 0.0:
			_draw_path(paths[i] as Array[Vector2], segment_colors[i] as Color, base_width, fill_pct, Vector2.ZERO, false, false)

func _segment_paths() -> Array:
	var paths := []
	var inset := 3.0
	var available := maxf(1.0, size.x - inset * 2.0)
	var segment_width := available / 5.0
	var baseline_y := size.y * 0.24
	var crest_y := baseline_y - maxf(18.0, minf(size.y * 0.16, 28.0))
	var hidden_return_y := size.y * 0.72
	var trough_y := size.y + maxf(28.0, size.y * 0.18)
	for segment_index in range(5):
		var points: Array[Vector2] = []
		var start_x := inset + segment_width * float(segment_index)
		var end_x := inset + segment_width * (float(segment_index) + 0.82)
		var knots := [
			Vector2(start_x - segment_width * 0.18, baseline_y + maxf(22.0, size.y * 0.16)),
			Vector2(start_x, baseline_y),
			Vector2(start_x + segment_width * 0.22, crest_y),
			Vector2(start_x + segment_width * 0.43, baseline_y + maxf(10.0, size.y * 0.07)),
			Vector2(start_x + segment_width * 0.60, trough_y),
			Vector2(end_x, hidden_return_y),
			Vector2(end_x + segment_width * 0.16, hidden_return_y - maxf(12.0, size.y * 0.08))
		]
		var samples_per_span := 18
		for knot_index in range(1, knots.size() - 2):
			for i in range(samples_per_span):
				var t := float(i) / float(samples_per_span)
				points.append(_catmull_point(
					knots[knot_index - 1] as Vector2,
					knots[knot_index] as Vector2,
					knots[knot_index + 1] as Vector2,
					knots[knot_index + 2] as Vector2,
					t
				))
		points.append(knots[knots.size() - 2] as Vector2)
		paths.append(_clip_tail_at_module_bottom(points))
	return paths

func _clip_tail_at_module_bottom(points: Array[Vector2]) -> Array[Vector2]:
	if points.size() < 2:
		return points
	var cutoff_y := size.y - 34.0
	for i in range(points.size() - 1, 0, -1):
		var current := points[i] as Vector2
		var previous := points[i - 1] as Vector2
		if previous.y > cutoff_y and current.y <= cutoff_y:
			var segment := current - previous
			var t := 0.0
			if absf(segment.y) > 0.001:
				t = clampf((cutoff_y - previous.y) / segment.y, 0.0, 1.0)
			var clipped := points.slice(0, i)
			clipped.append(previous + segment * t)
			return clipped
	return points

func _braid_paths() -> Array:
	var paths := []
	var inset := 4.0
	var available := maxf(1.0, size.x - inset * 2.0)
	var segment_width := available / 5.0
	var top_y := size.y * 0.30
	var bottom_y := size.y * 0.86
	var center_y := size.y * 0.58
	for segment_index in range(5):
		var points: Array[Vector2] = []
		var start_x := inset + segment_width * (float(segment_index) - 0.02)
		var end_x := inset + segment_width * (float(segment_index) + 1.12)
		var starts_high := segment_index % 2 == 0
		var start_y := top_y if starts_high else bottom_y
		var end_y := bottom_y if starts_high else top_y
		var mid_y := center_y + (maxf(10.0, size.y * 0.07) if starts_high else -maxf(10.0, size.y * 0.07))
		var knots := [
			Vector2(start_x - segment_width * 0.22, start_y),
			Vector2(start_x, start_y),
			Vector2(start_x + segment_width * 0.22, start_y),
			Vector2(start_x + segment_width * 0.52, mid_y),
			Vector2(start_x + segment_width * 0.86, end_y),
			Vector2(end_x, end_y),
			Vector2(end_x + segment_width * 0.20, end_y)
		]
		var samples_per_span := 18
		for knot_index in range(1, knots.size() - 2):
			for i in range(samples_per_span):
				var t := float(i) / float(samples_per_span)
				points.append(_catmull_point(
					knots[knot_index - 1] as Vector2,
					knots[knot_index] as Vector2,
					knots[knot_index + 1] as Vector2,
					knots[knot_index + 2] as Vector2,
					t
				))
		points.append(knots[knots.size() - 2] as Vector2)
		paths.append(points)
	return paths

func _draw_braid_paths(paths: Array, base_width: float, outline_width: float) -> void:
	var draw_order := [0, 2, 4, 1, 3]
	for raw_index in draw_order:
		var index := int(raw_index)
		var path := paths[index] as Array[Vector2]
		_draw_path(path, shadow_color, outline_width + 4.0, 1.0, Vector2(0, 3), false, false)
		_draw_path(path, outline_color, outline_width, 1.0, Vector2.ZERO, false, false)
		_draw_path(path, empty_color, base_width, 1.0, Vector2.ZERO, false, false)
		var fill_pct := clampf(float(segment_values[index]), 0.0, 1.0)
		if fill_pct > 0.0:
			_draw_path(path, segment_colors[index] as Color, base_width, fill_pct, Vector2.ZERO, false, false)

func _catmull_point(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return (b * 2.0 + (c - a) * t + (a * 2.0 - b * 5.0 + c * 4.0 - d) * t2 + (-a + b * 3.0 - c * 3.0 + d) * t3) * 0.5

func _draw_path(points: Array[Vector2], color: Color, width: float, fill_pct: float, offset := Vector2.ZERO, start_cap := true, end_cap := true) -> void:
	var pct := clampf(fill_pct, 0.0, 1.0)
	if pct <= 0.0 or points.size() < 2:
		return
	var total_length := _path_length(points)
	var remaining := total_length * pct
	var last_point := points[0] as Vector2
	if start_cap:
		draw_circle(last_point + offset, width * 0.5, color)
	for i in range(points.size() - 1):
		var start := points[i] as Vector2
		var finish := points[i + 1] as Vector2
		var segment := finish - start
		var segment_length := segment.length()
		if segment_length <= 0.001:
			continue
		var segment_finish := finish
		if remaining < segment_length:
			segment_finish = start + segment * (remaining / segment_length)
		draw_line(start + offset, segment_finish + offset, color, width, true)
		last_point = segment_finish
		if remaining <= segment_length:
			if end_cap:
				draw_circle(last_point + offset, width * 0.5, color)
			return
		draw_circle(last_point + offset, width * 0.5, color)
		remaining -= segment_length
	if end_cap:
		draw_circle(last_point + offset, width * 0.5, color)

func _path_length(points: Array[Vector2]) -> float:
	var total := 0.0
	for i in range(points.size() - 1):
		total += ((points[i + 1] as Vector2) - (points[i] as Vector2)).length()
	return total
