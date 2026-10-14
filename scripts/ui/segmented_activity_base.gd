extends Panel

var segment_colors: Array[Color] = []

func _draw() -> void:
	if segment_colors.size() < 2: return
	var style := get_theme_stylebox("panel") as StyleBoxFlat
	if style == null: return
	var border := float(style.border_width_left)
	var inner := Rect2(Vector2(border, border), size - Vector2.ONE * border * 2)
	var radius := minf(float(style.corner_radius_bottom_right) - border, minf(inner.size.x, inner.size.y) * 0.5)
	var rows := maxi(1, ceili(inner.size.y))
	var height := inner.size.y / rows
	for row in range(rows):
		var y := inner.position.y + row * height
		var edge := y if y < inner.get_center().y else y + height
		var dy := maxf(0.0, absf(edge - inner.get_center().y) - (inner.size.y * 0.5 - radius))
		var inset := radius - sqrt(maxf(0.0, radius * radius - dy * dy))
		for index in range(1, segment_colors.size()):
			var left := maxf(inner.position.x + inset, size.x * index / segment_colors.size())
			var right := minf(inner.end.x - inset, size.x * (index + 1) / segment_colors.size())
			if right > left: draw_rect(Rect2(left, y, right - left, height), segment_colors[index].darkened(0.42))
