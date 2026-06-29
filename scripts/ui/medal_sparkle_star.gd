extends Control

var fill_color := Color.WHITE
var outline_color := Color("#171615", 0.66)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5
		queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var center := size * 0.5
	var outer := minf(size.x, size.y) * 0.48
	var inner := outer * 0.34
	var points := PackedVector2Array()
	for i in range(8):
		var radius := outer if i % 2 == 0 else inner
		var angle := -PI * 0.5 + float(i) * PI * 0.25
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_polygon(points, PackedColorArray([outline_color]))
	var inner_points := PackedVector2Array()
	for i in range(8):
		var radius := (outer - 3.5) if i % 2 == 0 else maxf(1.0, inner - 2.0)
		var angle := -PI * 0.5 + float(i) * PI * 0.25
		inner_points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_polygon(inner_points, PackedColorArray([fill_color]))
