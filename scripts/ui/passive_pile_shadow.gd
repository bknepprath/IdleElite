class_name PassivePileShadow
extends Control


var shadow_color := Color(0.10, 0.07, 0.04, 0.20)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var center := size * 0.5
	var radius_x := size.x * 0.5
	var radius_y := size.y * 0.5
	var line_count := maxi(10, int(ceil(size.y)))
	for i in range(line_count):
		var t := float(i) / maxf(1.0, float(line_count - 1))
		var y := lerpf(-radius_y, radius_y, t)
		var normalized_y := y / maxf(1.0, radius_y)
		var width := radius_x * sqrt(maxf(0.0, 1.0 - normalized_y * normalized_y))
		var center_weight := 1.0 - absf(normalized_y)
		var alpha := shadow_color.a * pow(center_weight, 2.15)
		var color := Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha)
		draw_line(Vector2(center.x - width, center.y + y), Vector2(center.x + width, center.y + y), color, 2.0, true)
