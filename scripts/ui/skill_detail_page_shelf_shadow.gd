class_name SkillDetailPageShelfShadow
extends Control


var shadow_height := 54.0
var shadow_color := Color(0.04, 0.035, 0.03, 0.18)
var shadow_alpha := 1.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func set_shadow_alpha(next_alpha: float) -> void:
	var clamped := clampf(next_alpha, 0.0, 1.0)
	if absf(shadow_alpha - clamped) <= 0.001:
		return
	shadow_alpha = clamped
	queue_redraw()

func _draw() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	var lines := int(minf(28.0, size.y))
	var step_y := minf(shadow_height, size.y) / maxf(1.0, float(lines))
	var border_alpha := shadow_color.a * shadow_alpha * 0.92
	draw_line(Vector2(0.0, 0.0), Vector2(size.x, 0.0), Color(shadow_color.r, shadow_color.g, shadow_color.b, border_alpha), 3.0, false)
	for i in range(lines):
		var depth := float(i) / maxf(1.0, float(lines - 1))
		var core := 1.0 - smoothstep(0.0, 0.18, depth)
		var feather := pow(1.0 - depth, 2.05)
		var alpha := shadow_color.a * shadow_alpha * maxf(core * 0.50, feather * 0.46)
		var y := 2.0 + float(i) * step_y
		draw_line(Vector2(0.0, y), Vector2(size.x, y), Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha), step_y + 2.0, false)
