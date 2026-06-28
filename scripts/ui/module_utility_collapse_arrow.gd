extends Control


var direction := -1
var ink_color := Color("#8a6f4e")
var stroke_width := 13.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func set_direction(next_direction: int) -> void:
	direction = 1 if next_direction >= 0 else -1
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var center := size * 0.5
	var width := size.x * 0.34
	var height := size.y * 0.42
	var points := PackedVector2Array()
	if direction < 0:
		points.append(Vector2(center.x + width * 0.42, center.y - height * 0.5))
		points.append(Vector2(center.x - width * 0.42, center.y))
		points.append(Vector2(center.x + width * 0.42, center.y + height * 0.5))
	else:
		points.append(Vector2(center.x - width * 0.42, center.y - height * 0.5))
		points.append(Vector2(center.x + width * 0.42, center.y))
		points.append(Vector2(center.x - width * 0.42, center.y + height * 0.5))
	draw_polyline(points, ink_color, stroke_width, true)
	for point in points:
		draw_circle(point, stroke_width * 0.5, ink_color)
