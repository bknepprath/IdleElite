extends RefCounted


static func featured_art(surface_style: Callable, line_color: Color) -> StyleBoxFlat:
	var style := surface_style.call(Color("#fffaf0"), 24, 8, true) as StyleBoxFlat
	style.border_color = line_color
	style.set_border_width_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


static func shade(alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.5, 0.5, alpha)
	style.set_corner_radius_all(66)
	return style


static func action_art(surface_style: Callable) -> StyleBoxFlat:
	var style := surface_style.call(Color.WHITE, 56, 16, true) as StyleBoxFlat
	style.border_color = Color("#eee2ce")
	style.set_border_width_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


static func action_art_border(action_art_style: StyleBoxFlat) -> StyleBoxFlat:
	var style := action_art_style.duplicate() as StyleBoxFlat
	style.draw_center = false
	return style


static func art_glow(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.28)
	style.border_color = Color(color.r, color.g, color.b, 0.95)
	style.set_border_width_all(24)
	style.set_corner_radius_all(56)
	return style


static func bonus_emphasis(flash_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.20)
	style.border_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.88)
	style.set_border_width_all(18)
	style.set_corner_radius_all(38)
	style.shadow_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.42)
	style.shadow_size = 18
	style.shadow_offset = Vector2.ZERO
	return style


static func bonus_bottom_highlight(flash_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.28)
	style.border_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.95)
	style.set_border_width_all(14)
	style.set_corner_radius_all(999)
	style.shadow_color = Color(flash_color.r, flash_color.g, flash_color.b, 0.34)
	style.shadow_size = 16
	style.shadow_offset = Vector2.ZERO
	return style


static func tutorial_target_ring() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.89, 0.24, 0.0)
	style.draw_center = false
	style.border_color = Color("#ffd94d")
	style.set_border_width_all(12)
	style.set_corner_radius_all(54)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


static func crit_glow(mega_crit := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var fill := Color("#fff052") if mega_crit else Color("#67b8ff")
	var border := Color("#ffbf1f") if mega_crit else Color("#1f9dff")
	style.draw_center = true
	style.bg_color = Color(fill.r, fill.g, fill.b, 0.34 if mega_crit else 0.31)
	style.border_color = Color(border.r, border.g, border.b, 1.0 if mega_crit else 0.96)
	style.set_border_width_all(68 if mega_crit else 46)
	style.shadow_color = Color(1.0, 0.70, 0.0, 0.82) if mega_crit else Color(0.10, 0.58, 1.0, 0.62)
	style.shadow_size = 68 if mega_crit else 42
	style.shadow_offset = Vector2.ZERO
	style.set_corner_radius_all(82 if mega_crit else 66)
	return style


static func button_face(fill: Color, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(int(round(radius)))
	style.anti_aliasing = true
	style.anti_aliasing_size = 1.25
	return style
