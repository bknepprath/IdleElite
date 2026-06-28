extends Control


var direction := -1
var ink_color := Color("#171615")
var fill_color := Color.WHITE
var shadow_color := Color(0.0, 0.0, 0.0, 0.18)
var stroke_width := 50.0
var fill_width := 31.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func set_direction(next_direction: int) -> void:
	direction = 1 if next_direction >= 0 else -1
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var points := _chevron_points()
	if points.size() != 3:
		return
	var shadow_points := PackedVector2Array()
	for point in points:
		shadow_points.append(point + Vector2(7.0, 8.0))
	_draw_round_chevron(shadow_points, shadow_color, stroke_width)
	_draw_round_chevron(points, ink_color, stroke_width)
	_draw_round_chevron(points, fill_color, fill_width)

func _chevron_points() -> PackedVector2Array:
	var center := size * 0.5
	var half_width := size.x * 0.18
	var half_height := size.y * 0.36
	var points := PackedVector2Array()
	if direction < 0:
		points.append(Vector2(center.x + half_width, center.y - half_height))
		points.append(Vector2(center.x - half_width, center.y))
		points.append(Vector2(center.x + half_width, center.y + half_height))
	else:
		points.append(Vector2(center.x - half_width, center.y - half_height))
		points.append(Vector2(center.x + half_width, center.y))
		points.append(Vector2(center.x - half_width, center.y + half_height))
	return points

func _draw_round_chevron(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size() != 3:
		return
	var radius := width * 0.5
	draw_line(points[0], points[1], color, width, true)
	draw_line(points[1], points[2], color, width, true)
	for point in points:
		draw_circle(point, radius, color)
