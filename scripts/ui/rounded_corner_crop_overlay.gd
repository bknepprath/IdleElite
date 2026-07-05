extends Control


var radius := 66.0
var cover_color := Color("#f8f1e5")

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var r := minf(radius, minf(size.x, size.y) * 0.5)
	var step := 1.0
	var y := 0.0
	while y < r:
		var sample_y := y + step * 0.5
		var dy := sample_y - r
		var inset := r - sqrt(maxf(0.0, r * r - dy * dy))
		if inset > 0.0:
			draw_rect(Rect2(Vector2(0.0, y), Vector2(inset, step)), cover_color)
			draw_rect(Rect2(Vector2(size.x - inset, y), Vector2(inset, step)), cover_color)
			draw_rect(Rect2(Vector2(0.0, size.y - y - step), Vector2(inset, step)), cover_color)
			draw_rect(Rect2(Vector2(size.x - inset, size.y - y - step), Vector2(inset, step)), cover_color)
		y += step
