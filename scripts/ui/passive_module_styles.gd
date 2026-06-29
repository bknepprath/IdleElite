extends RefCounted


static func currency(panel_color: Color, ink_color: Color, surface_style: Callable) -> StyleBoxFlat:
	var style := surface_style.call(panel_color, 28, 14, true) as StyleBoxFlat
	style.border_color = ink_color
	style.border_width_left = 12
	style.border_width_right = 12
	style.border_width_top = 12
	style.border_width_bottom = 12
	style.content_margin_left = 22
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func stat(ink_color: Color, surface_style: Callable) -> StyleBoxFlat:
	var style := surface_style.call(Color.WHITE, 22, 18, true) as StyleBoxFlat
	style.border_color = ink_color
	style.border_width_left = 10
	style.border_width_right = 10
	style.border_width_top = 10
	style.border_width_bottom = 10
	style.content_margin_left = 24
	style.content_margin_right = 20
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


static func popup(panel_color: Color, ink_color: Color, surface_style: Callable) -> StyleBoxFlat:
	var style := surface_style.call(panel_color, 22, 20, true) as StyleBoxFlat
	style.border_color = ink_color
	style.border_width_left = 8
	style.border_width_right = 8
	style.border_width_top = 8
	style.border_width_bottom = 8
	return style


static func icon_button(active := false, hovered := false, ink_color := Color.BLACK, gold_color := Color.GOLD, surface_style := Callable()) -> StyleBoxFlat:
	var fill := Color("#bff4c9") if active else Color("#f3eee0")
	if hovered:
		fill = Color("#d3ffd9") if active else gold_color
	var style := surface_style.call(fill, 24, 8, true) as StyleBoxFlat
	style.border_color = Color("#178b38") if active else ink_color
	var border_width := 14 if active else 10
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	if active:
		style.shadow_color = Color(0.05, 0.30, 0.12, 0.42)
		style.shadow_size = 8
	return style


static func plank_light(active: bool, ink_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#44f078") if active else Color("#e63d35")
	style.border_color = ink_color
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	style.shadow_color = Color(0.18, 0.82, 0.28, 0.48) if active else Color(0.78, 0.12, 0.09, 0.42)
	style.shadow_size = 6
	style.shadow_offset = Vector2.ZERO
	return style


static func round_button(fill: Color, ink_color: Color, surface_style: Callable, theme_outline_color: Callable) -> StyleBoxFlat:
	var style := surface_style.call(fill, 999, 0, true) as StyleBoxFlat
	style.border_color = theme_outline_color.call(ink_color, fill)
	style.border_width_left = 8
	style.border_width_right = 8
	style.border_width_top = 6
	style.border_width_bottom = 11
	style.shadow_color = Color(0.08, 0.07, 0.06, 0.30)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


static func upgrade_button() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color.TRANSPARENT
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style
