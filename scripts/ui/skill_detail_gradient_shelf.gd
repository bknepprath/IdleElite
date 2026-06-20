class_name SkillDetailGradientShelf
extends Control


var top_color := Color("#f6cfd0")
var bottom_color := Color("#bd5f5a")

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func set_colors(next_top_color: Color, next_bottom_color: Color) -> void:
	top_color = next_top_color
	bottom_color = next_bottom_color
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var line_count := maxi(1, int(ceil(size.y)))
	for i in range(line_count):
		var y := float(i)
		var t := y / maxf(1.0, size.y - 1.0)
		var bottom_weight := smoothstep(0.68, 1.0, t)
		var color := top_color.lerp(bottom_color, bottom_weight)
		draw_line(Vector2(0.0, y), Vector2(size.x, y), color, 1.0, false)
