class_name PassiveSerpentineProgressBar
extends Control


var value := 0.0
var target_value := 0.0
var easing_speed := 6.0
var fill_color := Color("#35d86d")
var empty_color := Color("#fff1c8")
var outline_color := Color("#171615")
var shadow_color := Color(0.08, 0.07, 0.06, 0.28)
var unlocked_empty_color := Color("#fff1c8")
var locked_empty_color := Color("#ded8c6")
var unlocked_outline_color := Color("#171615")
var locked_outline_color := Color("#56524c")
var unlocked_shadow_color := Color(0.08, 0.07, 0.06, 0.28)
var locked_shadow_color := Color(0.08, 0.07, 0.06, 0.22)

func _ready() -> void:
	set_process(false)

func set_value(next_value: float) -> void:
	var clamped := clampf(next_value, 0.0, 100.0)
	if absf(value - clamped) <= 0.001:
		return
	value = clamped
	target_value = clamped
	queue_redraw()
	set_process(false)

func set_target_value(next_value: float, instant := false) -> void:
	var clamped := clampf(next_value, 0.0, 100.0)
	if instant:
		set_value(clamped)
		return
	if absf(target_value - clamped) <= 0.001:
		return
	target_value = clamped
	_ensure_animation_process()

func _ensure_animation_process() -> void:
	if not is_processing():
		set_process(true)

func _process(delta: float) -> void:
	if absf(value - target_value) <= 0.001:
		value = target_value
		set_process(false)
		return
	var speed := easing_speed
	if target_value < value:
		speed = 5.5
	value = lerpf(value, target_value, 1.0 - exp(-speed * minf(delta, 0.1)))
	queue_redraw()

func _draw() -> void:
	if size.x <= 8.0 or size.y <= 8.0:
		return
	var points := _serpentine_points()
	if points.size() < 2:
		return
	var base_width := minf(62.0, maxf(52.0, size.y * 0.39))
	var outline_width := base_width + maxf(11.0, size.y * 0.10)
	_draw_path(points, shadow_color, outline_width + 5.0, 1.0, Vector2(0, 4))
	_draw_path(points, outline_color, outline_width, 1.0)
	_draw_path(points, empty_color, base_width, 1.0)
	var fill_pct := clampf(value / 100.0, 0.0, 1.0)
	if fill_pct > 0.0:
		_draw_fill_path_flat_end(points, fill_color, base_width, fill_pct)

func _serpentine_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	var inset := 7.0
	var width := maxf(1.0, size.x - inset * 2.0)
	var amplitude := maxf(24.0, minf(size.y * 0.20, 34.0))
	var base_width := minf(62.0, maxf(52.0, size.y * 0.39))
	var outline_width := base_width + maxf(11.0, size.y * 0.10)
	var center_y := size.y - amplitude - outline_width * 0.5 - 12.0
	var straight_pct := 0.08
	var wave_start := straight_pct
	var wave_finish := 1.0 - straight_pct
	var transition_pct := 0.12
	var cycles := 4.0
	var sample_count := maxi(48, int(size.x / 8.0))
	for i in range(sample_count + 1):
		var t := float(i) / float(sample_count)
		var x := inset + width * t
		var y := center_y
		if t > wave_start and t < wave_finish:
			var wave_t := (t - wave_start) / (wave_finish - wave_start)
			if wave_t < transition_pct:
				var ramp_t := wave_t / transition_pct
				var eased := ramp_t * ramp_t * ramp_t * (ramp_t * (ramp_t * 6.0 - 15.0) + 10.0)
				y += amplitude * eased
			elif wave_t > 1.0 - transition_pct:
				var ramp_t := (1.0 - wave_t) / transition_pct
				var eased := ramp_t * ramp_t * ramp_t * (ramp_t * (ramp_t * 6.0 - 15.0) + 10.0)
				y += amplitude * eased
			else:
				var oscillation_t := (wave_t - transition_pct) / (1.0 - transition_pct * 2.0)
				y += cos(oscillation_t * TAU * cycles) * amplitude
		points.append(Vector2(x, y))
	return points

func _draw_path(points: Array[Vector2], color: Color, width: float, fill_pct: float, offset := Vector2.ZERO, start_cap := true, end_cap := true) -> void:
	var pct := clampf(fill_pct, 0.0, 1.0)
	if pct <= 0.0 or points.size() < 2:
		return
	var total_length := _path_length(points)
	var draw_length := total_length * pct
	var remaining := draw_length
	var last_point := points[0] as Vector2
	if width > 0.0 and start_cap:
		draw_circle(last_point + offset, width * 0.5, color)
	for i in range(points.size() - 1):
		var start := points[i] as Vector2
		var finish := points[i + 1] as Vector2
		var segment := finish - start
		var segment_length := segment.length()
		if segment_length <= 0.001:
			continue
		var segment_remaining := remaining - segment_length
		var segment_finish := finish
		if remaining < segment_length:
			segment_finish = start + segment * (remaining / segment_length)
		draw_line(start + offset, segment_finish + offset, color, width, true)
		last_point = segment_finish
		if segment_remaining <= 0.0:
			if end_cap:
				draw_circle(last_point + offset, width * 0.5, color)
			return
		draw_circle(last_point + offset, width * 0.5, color)
		remaining = segment_remaining
	if end_cap:
		draw_circle(last_point + offset, width * 0.5, color)

func _draw_fill_path_flat_end(points: Array[Vector2], color: Color, width: float, fill_pct: float) -> void:
	var pct := clampf(fill_pct, 0.0, 1.0)
	if pct <= 0.0 or points.size() < 2:
		return
	var remaining := _path_length(points) * pct
	var first_point := points[0] as Vector2
	draw_circle(first_point, width * 0.5, color)
	for i in range(points.size() - 1):
		var start := points[i] as Vector2
		var finish := points[i + 1] as Vector2
		var segment := finish - start
		var segment_length := segment.length()
		if segment_length <= 0.001:
			continue
		if remaining <= segment_length:
			var segment_finish := start + segment * (remaining / segment_length)
			_draw_flat_segment(start, segment_finish, color, width)
			return
		draw_line(start, finish, color, width, true)
		draw_circle(finish, width * 0.5, color)
		remaining -= segment_length

func _draw_flat_segment(start: Vector2, finish: Vector2, color: Color, width: float) -> void:
	var segment := finish - start
	if segment.length() <= 0.001:
		return
	var tangent := segment.normalized()
	var normal := Vector2(-tangent.y, tangent.x)
	var half_width := width * 0.5
	var polygon := PackedVector2Array([
		start - normal * half_width,
		start + normal * half_width,
		finish + normal * half_width,
		finish - normal * half_width
	])
	draw_colored_polygon(polygon, color)

func _path_length(points: Array[Vector2]) -> float:
	var total := 0.0
	for i in range(points.size() - 1):
		total += ((points[i + 1] as Vector2) - (points[i] as Vector2)).length()
	return total
