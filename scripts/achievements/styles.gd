extends RefCounted


static func card(color: Color, radius: int, margin: int, surface_style: Callable) -> StyleBoxFlat:
	return surface_style.call(color, radius, margin, true) as StyleBoxFlat


static func toast_queue_badge() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2f2a21")
	style.border_color = Color("#fff2c4")
	style.set_border_width_all(7)
	style.set_corner_radius_all(999)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style


static func skill_section() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.draw_center = false
	style.content_margin_left = 38
	style.content_margin_right = 38
	style.content_margin_top = 22
	style.content_margin_bottom = 30
	return style
