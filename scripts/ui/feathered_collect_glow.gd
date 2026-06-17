class_name FeatheredCollectGlow
extends Control


var glow_color := Color("#ffe872")

func _draw() -> void:
	var center := size * 0.5
	var base_radius := minf(size.x, size.y) * 0.5
	for i in range(13, 0, -1):
		var t := float(i) / 13.0
		var radius := base_radius * t
		var alpha := pow(1.0 - t, 1.75) * 0.30
		var color := Color(glow_color.r, glow_color.g, glow_color.b, alpha)
		_draw_ellipse(center, Vector2(radius * 1.12, radius * 0.82), color)
	_draw_ellipse(center, Vector2(base_radius * 0.50, base_radius * 0.36), Color(glow_color.r, glow_color.g, glow_color.b, 0.11))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(48):
		var angle := TAU * float(i) / 48.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
