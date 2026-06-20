class_name SkillMenuPanelChrome
extends Control


var radius := 64.0
var border_width := 9.0
var shadow_height := 24.0
var border_color := Color("#171615")
var shadow_color := Color(0.05, 0.04, 0.03, 0.18)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	if radius <= 0.0:
		return
	_draw_bottom_shadow()
	_draw_border()

func _draw_bottom_shadow() -> void:
	var bottom := maxf(0.0, size.y - border_width * 1.35)
	var top := maxf(0.0, bottom - shadow_height)
	var r := minf(radius, minf(size.x, size.y) * 0.5)
	var curve_top := size.y - r
	var lines := maxi(1, int(minf(8.0, shadow_height)))
	var step_y := shadow_height / float(lines)
	for i in range(lines):
		var y := top + float(i) * step_y
		var depth := float(i) / maxf(1.0, float(lines - 1))
		var alpha := shadow_color.a * depth * depth
		var line_left := border_width
		var line_right := size.x - border_width
		if y > curve_top:
			var dy := y - curve_top
			var chord := sqrt(maxf(0.0, r * r - dy * dy))
			var corner_inset := r - chord
			var shadow_corner_guard := border_width + 10.0
			line_left = maxf(line_left, corner_inset + shadow_corner_guard)
			line_right = minf(line_right, size.x - corner_inset - shadow_corner_guard)
		if line_right > line_left:
			draw_line(Vector2(line_left, y), Vector2(line_right, y), Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha), step_y + 1.0, false)

func _draw_border() -> void:
	var half := border_width * 0.5
	var left := half
	var right := maxf(half, size.x - half)
	var top := half
	var bottom := maxf(half, size.y - half)
	var r := minf(radius, minf(size.x, size.y) * 0.5 - half)
	draw_line(Vector2(left + r, top), Vector2(right - r, top), border_color, border_width, true)
	draw_line(Vector2(left + r, bottom), Vector2(right - r, bottom), border_color, border_width, true)
	draw_line(Vector2(left, top + r), Vector2(left, bottom - r), border_color, border_width, true)
	draw_line(Vector2(right, top + r), Vector2(right, bottom - r), border_color, border_width, true)
	draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 8, border_color, border_width, true)
	draw_arc(Vector2(right - r, top + r), r, PI * 1.5, PI * 2.0, 8, border_color, border_width, true)
	draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 8, border_color, border_width, true)
	draw_arc(Vector2(left + r, bottom - r), r, PI * 0.5, PI, 8, border_color, border_width, true)
