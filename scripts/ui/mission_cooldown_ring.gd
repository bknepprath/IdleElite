class_name MissionCooldownRing
extends Control


var progress := 0.0

func set_progress(next_progress: float) -> void:
	progress = clampf(next_progress, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var width := maxf(13.0, radius * 0.24)
	var outer_radius := radius + width * 0.72
	draw_circle(center + Vector2(0, 4), outer_radius, Color(0.04, 0.035, 0.03, 0.36))
	draw_circle(center, outer_radius, Color.BLACK)
	draw_circle(center, maxf(0.0, outer_radius - 9.0), Color("#6f6a5e"))
	draw_arc(center, radius, -PI * 0.5, PI * 1.5, 48, Color("#2e2a24"), width + 8.0, true)
	draw_arc(center, radius, -PI * 0.5, PI * 1.5, 48, Color("#a8a096"), width, true)
	if progress > 0.001:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, Color("#35d86d"), width, true)
	draw_circle(center, maxf(0.0, radius - width * 0.82), Color("#77736c"))
