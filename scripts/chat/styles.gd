extends RefCounted


static func world_tab(ink_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3f5068")
	style.border_color = ink_color
	style.set_border_width_all(10)
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_left = 24
	style.corner_radius_bottom_right = 24
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style


static func unread_dot() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ef2f2f")
	style.border_color = Color("#111111")
	style.set_border_width_all(6)
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	return style


static func expanded_message(deleted := false, is_self := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#e7f5ff") if is_self and not deleted else Color("#e8e8e8") if not deleted else Color("#ddd7cf")
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 10 if is_self and not deleted else 18
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


static func back_button(pressed := false, ink_color := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ef3f55").darkened(0.08 if pressed else 0.0)
	style.border_color = ink_color
	style.set_border_width_all(8)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10 + (5 if pressed else 0)
	style.content_margin_bottom = 10 - (3 if pressed else 0)
	return style


static func input(focused := false, ink_color := Color.BLACK, focus_color := Color.BLUE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = focus_color if focused else ink_color
	style.set_border_width_all(7)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 46
	style.content_margin_right = 46
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	return style


static func keyboard_preview(focus_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = focus_color
	style.set_border_width_all(8)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.content_margin_left = 44
	style.content_margin_right = 44
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	style.shadow_color = Color(0, 0, 0, 0.24)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0, 8)
	return style


static func strip() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.725, 0.725, 0.725, 1.0)
	style.draw_center = true
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style
