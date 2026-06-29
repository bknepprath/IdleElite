extends Control

var line_color := Color("#171615")
var line_width := 14.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var y := size.y * 0.5
	var inset := size.x * 0.26
	draw_line(Vector2(inset, y), Vector2(size.x - inset, y), line_color, line_width, true)
	draw_circle(Vector2(inset, y), line_width * 0.5, line_color)
	draw_circle(Vector2(size.x - inset, y), line_width * 0.5, line_color)
