class_name FirepitFuelRing
extends Control


var value := 0.0
var target_value := 0.0
var inner_value := 0.0
var inner_target_value := 0.0
var easing_speed := 6.0
var fill_color := Color("#ff9c2f")
var empty_color := Color("#553220")
var inner_fill_color := Color("#ffd55f")
var inner_empty_color := Color("#3a251b")
var outline_color := Color("#171615")
var shadow_color := Color(0.08, 0.07, 0.06, 0.32)
var heat_gradient_colors := [
	Color("#d63a16"),
	Color("#ff641f"),
	Color("#ff9c2f"),
	Color("#ffd45a"),
	Color("#fff08c"),
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func set_value(next_value: float) -> void:
	var clamped := clampf(next_value, 0.0, 100.0)
	if absf(value - clamped) <= 0.001 and absf(target_value - clamped) <= 0.001:
		return
	value = clamped
	target_value = clamped
	queue_redraw()
	_maybe_sleep()


func set_inner_value(next_value: float) -> void:
	var clamped := clampf(next_value, 0.0, 100.0)
	if absf(inner_value - clamped) <= 0.001 and absf(inner_target_value - clamped) <= 0.001:
		return
	inner_value = clamped
	inner_target_value = clamped
	queue_redraw()
	_maybe_sleep()


func set_target_value(next_value: float, instant := false) -> void:
	var clamped := clampf(next_value, 0.0, 100.0)
	if instant:
		set_value(clamped)
		return
	if absf(target_value - clamped) <= 0.001:
		return
	target_value = clamped
	if not is_processing():
		set_process(true)


func set_inner_target_value(next_value: float, instant := false) -> void:
	var clamped := clampf(next_value, 0.0, 100.0)
	if instant:
		set_inner_value(clamped)
		return
	if absf(inner_target_value - clamped) <= 0.001:
		return
	inner_target_value = clamped
	if not is_processing():
		set_process(true)


func _process(delta: float) -> void:
	if absf(value - target_value) <= 0.001 and absf(inner_value - inner_target_value) <= 0.001:
		value = target_value
		inner_value = inner_target_value
		_maybe_sleep()
		return
	var speed := easing_speed if target_value >= value else easing_speed * 0.9
	value = lerpf(value, target_value, 1.0 - exp(-speed * minf(delta, 0.1)))
	var inner_speed := easing_speed * 1.45 if inner_target_value >= inner_value else easing_speed * 0.85
	inner_value = lerpf(inner_value, inner_target_value, 1.0 - exp(-inner_speed * minf(delta, 0.1)))
	queue_redraw()


func _maybe_sleep() -> void:
	if absf(value - target_value) <= 0.001 and absf(inner_value - inner_target_value) <= 0.001:
		set_process(false)


func _draw() -> void:
	if size.x <= 8.0 or size.y <= 8.0:
		return
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	var tube_width := maxf(22.0, radius * 0.13)
	var outline_width := tube_width + maxf(9.0, tube_width * 0.34)
	var inner_radius := radius - outline_width * 1.06
	var inner_tube_width := maxf(20.0, tube_width * 0.70)
	var inner_outline_width := inner_tube_width + maxf(7.0, inner_tube_width * 0.34)
	var start_angle := deg_to_rad(-75.0)
	var sweep := deg_to_rad(330.0)
	var fill_pct := clampf(value / 100.0, 0.0, 1.0)
	var inner_fill_pct := clampf(inner_value / 100.0, 0.0, 1.0)
	_draw_round_arc(center + Vector2(0.0, 5.0), radius, start_angle, sweep, shadow_color, outline_width + 4.0)
	_draw_round_arc(center, radius, start_angle, sweep, outline_color, outline_width)
	_draw_round_arc(center, radius, start_angle, sweep, empty_color, tube_width)
	if fill_pct > 0.001:
		_draw_heat_arc(center, radius, start_angle, sweep * fill_pct, sweep, tube_width)
	if inner_radius > inner_outline_width:
		_draw_round_arc(center + Vector2(0.0, 3.0), inner_radius, start_angle, sweep, shadow_color.darkened(0.2), inner_outline_width + 3.0)
		_draw_round_arc(center, inner_radius, start_angle, sweep, outline_color, inner_outline_width)
		_draw_round_arc(center, inner_radius, start_angle, sweep, inner_empty_color, inner_tube_width)
		if inner_fill_pct > 0.001:
			_draw_round_arc(center, inner_radius, start_angle, sweep * inner_fill_pct, inner_fill_color, inner_tube_width)


func _draw_round_arc(center: Vector2, radius: float, start_angle: float, sweep: float, color: Color, width: float) -> void:
	if sweep <= 0.001 or color.a <= 0.0 or width <= 0.0:
		return
	var segments := maxi(12, int(ceil(absf(sweep) / TAU * 96.0)))
	var end_angle := start_angle + sweep
	draw_arc(center, radius, start_angle, end_angle, segments, color, width, true)
	var start_point := center + Vector2(cos(start_angle), sin(start_angle)) * radius
	var end_point := center + Vector2(cos(end_angle), sin(end_angle)) * radius
	draw_circle(start_point, width * 0.5, color)
	draw_circle(end_point, width * 0.5, color)


func _draw_heat_arc(center: Vector2, radius: float, start_angle: float, filled_sweep: float, full_sweep: float, width: float) -> void:
	if filled_sweep <= 0.001 or full_sweep <= 0.001 or width <= 0.0:
		return
	var segments := maxi(18, int(ceil(absf(filled_sweep) / TAU * 128.0)))
	for segment in range(segments):
		var start_t := float(segment) / float(segments)
		var end_t := float(segment + 1) / float(segments)
		var segment_start := start_angle + filled_sweep * start_t
		var segment_end := start_angle + filled_sweep * end_t
		var full_ring_t := clampf(((segment_start + segment_end) * 0.5 - start_angle) / full_sweep, 0.0, 1.0)
		draw_arc(
			center,
			radius,
			segment_start,
			segment_end,
			3,
			_heat_gradient_color(full_ring_t),
			width,
			true
		)
	var end_angle := start_angle + filled_sweep
	var end_t := clampf(filled_sweep / full_sweep, 0.0, 1.0)
	draw_circle(center + Vector2(cos(start_angle), sin(start_angle)) * radius, width * 0.5, _heat_gradient_color(0.0))
	draw_circle(center + Vector2(cos(end_angle), sin(end_angle)) * radius, width * 0.5, _heat_gradient_color(end_t))


func _heat_gradient_color(t: float) -> Color:
	if heat_gradient_colors.is_empty():
		return fill_color
	if heat_gradient_colors.size() == 1:
		return heat_gradient_colors[0]
	var scaled := clampf(t, 0.0, 1.0) * float(heat_gradient_colors.size() - 1)
	var left_index := clampi(int(floor(scaled)), 0, heat_gradient_colors.size() - 1)
	var right_index := clampi(left_index + 1, 0, heat_gradient_colors.size() - 1)
	return heat_gradient_colors[left_index].lerp(heat_gradient_colors[right_index], scaled - float(left_index))
