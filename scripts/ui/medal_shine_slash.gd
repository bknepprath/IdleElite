extends Control

var shine_color := Color.WHITE
var progress := 0.0
var line_width := 14.0
var coin_center_ratio := Vector2(0.5, 0.43)
var coin_radius_ratio := 0.38


func set_progress(next_progress: float) -> void:
	progress = clampf(next_progress, 0.0, 1.0)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var center := Vector2(size.x * coin_center_ratio.x, size.y * coin_center_ratio.y)
	var radius := minf(size.x, size.y) * coin_radius_ratio
	var sweep := lerpf(-radius * 1.75, radius * 1.75, progress)
	_draw_coin_clipped_band(center, radius, sweep, line_width * 3.2, Color(shine_color.r, shine_color.g, shine_color.b, shine_color.a * 0.16))
	_draw_coin_clipped_band(center, radius, sweep, line_width * 1.85, Color(shine_color.r, shine_color.g, shine_color.b, shine_color.a * 0.42))
	_draw_coin_clipped_band(center, radius, sweep, line_width * 0.58, Color(shine_color.r, shine_color.g, shine_color.b, shine_color.a * 0.92))


func _draw_coin_clipped_band(center: Vector2, radius: float, sweep: float, width: float, color: Color) -> void:
	var row_height := 3.0
	var normal_scale := sqrt(2.0)
	var y := center.y - radius
	while y <= center.y + radius:
		var dy := y - center.y
		var circle_half_width := sqrt(maxf(0.0, radius * radius - dy * dy))
		var circle_left := center.x - circle_half_width
		var circle_right := center.x + circle_half_width
		var band_center_x := center.x + sweep * normal_scale - dy
		var band_half_width := width * normal_scale * 0.5
		var left := maxf(circle_left, band_center_x - band_half_width)
		var right := minf(circle_right, band_center_x + band_half_width)
		if right > left:
			draw_line(Vector2(left, y), Vector2(right, y), color, row_height + 0.75, false)
		y += row_height
