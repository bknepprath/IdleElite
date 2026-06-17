class_name CleanProgressBar
extends Control


var value := 0.0
var value_initialized := false
var fill_color := Color.WHITE
var track_color := Color("#fff1c8")
var border_color := Color("#d9cfbc")
var border_width := 6.0
var easing_speed := 12.0
var depth_enabled := false
var depth_offset := Vector2(12.0, 10.0)
var depth_back_color := Color("#6b4422")
var depth_outline_color := Color("#171615")
var depth_shadow_color := Color(0.05, 0.04, 0.03, 0.22)

func set_value(next_value: float) -> void:
	var clamped := clampf(next_value, 0.0, 100.0)
	if value_initialized and absf(value - clamped) <= 0.001:
		return
	value_initialized = true
	value = clamped
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if depth_enabled:
		_draw_depth_bar(rect)
		return
	_draw_progress_face(rect)

func _draw_depth_bar(rect: Rect2) -> void:
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return
	var depth := Vector2(
		minf(depth_offset.x, maxf(0.0, rect.size.x * 0.12)),
		minf(depth_offset.y, maxf(0.0, rect.size.y * 0.32))
	)
	var face_rect := Rect2(rect.position, Vector2(maxf(1.0, rect.size.x - depth.x), maxf(1.0, rect.size.y - depth.y)))
	var back_rect := Rect2(face_rect.position + depth, face_rect.size)
	var face_radius := face_rect.size.y * 0.5
	var shadow_rect := back_rect
	shadow_rect.position.y += maxf(2.0, depth.y * 0.28)
	_draw_round_rect(shadow_rect, depth_shadow_color, face_radius)
	_draw_round_rect(back_rect, depth_back_color, face_radius)
	_draw_round_outline(back_rect, depth_outline_color, face_radius, border_width)
	_draw_progress_face(face_rect)

func _draw_progress_face(rect: Rect2) -> void:
	var radius := size.y * 0.5
	if depth_enabled:
		radius = rect.size.y * 0.5
	_draw_round_rect(rect, track_color, radius)
	var inner := rect.grow(-border_width)
	_draw_round_rect(inner, track_color, maxf(0.0, radius - border_width))
	var fill_width := inner.size.x * value / 100.0
	if fill_width > 0.0:
		if fill_width >= inner.size.x - 0.5:
			_draw_round_rect(inner, fill_color, maxf(0.0, radius - border_width))
		else:
			_draw_partial_round_fill(inner, fill_width, fill_color, maxf(0.0, radius - border_width))
	_draw_round_outline(rect, border_color, radius, border_width)

func _draw_round_rect(rect: Rect2, color: Color, radius: float) -> void:
	var center_y := rect.position.y + rect.size.y * 0.5
	var clamped_radius := minf(radius, rect.size.x * 0.5)
	draw_rect(Rect2(rect.position + Vector2(clamped_radius, 0), Vector2(maxf(0.0, rect.size.x - clamped_radius * 2.0), rect.size.y)), color)
	draw_circle(Vector2(rect.position.x + clamped_radius, center_y), clamped_radius, color)
	draw_circle(Vector2(rect.end.x - clamped_radius, center_y), clamped_radius, color)

func _draw_partial_round_fill(rect: Rect2, fill_width: float, color: Color, _radius: float) -> void:
	var clamped_width := clampf(fill_width, 0.0, rect.size.x)
	if clamped_width <= 0.0 or rect.size.y <= 0.0:
		return
	draw_rect(Rect2(rect.position, Vector2(clamped_width, rect.size.y)), color)

func _draw_round_outline(rect: Rect2, color: Color, radius: float, width: float) -> void:
	var half_width := width * 0.5
	var y_top := rect.position.y + half_width
	var y_bottom := rect.end.y - half_width
	var x_left := rect.position.x + radius
	var x_right := rect.end.x - radius
	draw_line(Vector2(x_left, y_top), Vector2(x_right, y_top), color, width, true)
	draw_line(Vector2(x_left, y_bottom), Vector2(x_right, y_bottom), color, width, true)
	draw_arc(Vector2(x_left, rect.position.y + radius), radius - half_width, PI, PI * 1.5, 12, color, width, true)
	draw_arc(Vector2(x_right, rect.position.y + radius), radius - half_width, PI * 1.5, TAU, 12, color, width, true)
	draw_arc(Vector2(x_left, rect.end.y - radius), radius - half_width, PI * 0.5, PI, 12, color, width, true)
	draw_arc(Vector2(x_right, rect.end.y - radius), radius - half_width, 0.0, PI * 0.5, 12, color, width, true)
