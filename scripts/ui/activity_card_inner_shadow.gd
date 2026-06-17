class_name ActivityCardInnerShadow
extends Control


var radius := 66.0
var inset := 14.0
var shadow_height := 42.0
var side_lift := 10.0
var shadow_color := Color(0.05, 0.04, 0.03, 0.24)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var left := inset
	var right := maxf(left, size.x - inset)
	var bottom := maxf(inset, size.y - inset * 0.62)
	var lines := maxi(1, int(minf(8.0, shadow_height)))
	var step_y := shadow_height / float(lines)
	for i in range(lines):
		var y := bottom - shadow_height + float(i) * step_y
		var depth := float(i) / maxf(1.0, float(lines - 1))
		var alpha := shadow_color.a * depth * depth
		var lift := side_lift * (1.0 - depth)
		var side_curve := clampf((y - (bottom - shadow_height - lift)) / maxf(1.0, shadow_height + lift), 0.0, 1.0)
		var x_inset := (1.0 - side_curve) * radius * 0.26
		var line_left := left + x_inset
		var line_right := right - x_inset
		if y > size.y - radius:
			var dy := y - (size.y - radius)
			var chord := sqrt(maxf(0.0, radius * radius - dy * dy))
			var corner_inset := radius - chord
			line_left = maxf(line_left, corner_inset + 18.0)
			line_right = minf(line_right, size.x - corner_inset - 18.0)
		if line_right > line_left:
			draw_line(Vector2(line_left, y), Vector2(line_right, y), Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha), step_y + 1.0, false)
	draw_line(Vector2(left + radius * 0.35, bottom - shadow_height - side_lift * 0.44), Vector2(right - radius * 0.35, bottom - shadow_height - side_lift * 0.44), Color(1, 1, 1, 0.08), 4.0, true)
