extends RefCounted


static func dropdown(color: Color, pressed := false, ink_color := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.06 if pressed else 0.0)
	style.border_color = ink_color
	style.set_border_width_all(18)
	style.set_corner_radius_all(46)
	style.content_margin_left = 70
	style.content_margin_right = 70
	style.content_margin_top = 42 + (6 if pressed else 0)
	style.content_margin_bottom = 42 - (4 if pressed else 0)
	style.shadow_color = Color(0.08, 0.07, 0.06, 0.28 if not pressed else 0.14)
	style.shadow_size = 10 if not pressed else 4
	style.shadow_offset = Vector2(0, 8 if not pressed else 3)
	return style


static func player_card(color: Color, pressed := false, ink_color := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.06 if pressed else 0.0)
	style.border_color = ink_color
	style.set_border_width_all(16)
	style.set_corner_radius_all(58)
	style.content_margin_left = 48
	style.content_margin_right = 48
	style.content_margin_top = 40 + (6 if pressed else 0)
	style.content_margin_bottom = 40 - (4 if pressed else 0)
	style.shadow_color = Color(0.08, 0.07, 0.06, 0.32 if not pressed else 0.16)
	style.shadow_size = 12 if not pressed else 5
	style.shadow_offset = Vector2(0, 9 if not pressed else 4)
	return style


static func rank_badge() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0)
	style.border_color = Color(0, 0, 0, 0)
	style.set_border_width_all(0)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


static func avatar_frame_background(selected := false, theme_surface_color := Callable()) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff1b8") if selected else theme_surface_color.call(Color("#fffdf8"))
	style.border_color = Color.TRANSPARENT
	style.set_border_width_all(0)
	style.set_corner_radius_all(24)
	if selected:
		style.shadow_color = Color(0.09, 0.08, 0.07, 0.22)
		style.shadow_size = 10
		style.shadow_offset = Vector2(0, 8)
	return style


static func avatar_frame(_selected := false, ink_color := Color.BLACK, frame_border := 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.draw_center = false
	style.border_color = ink_color
	style.set_border_width_all(frame_border)
	style.set_corner_radius_all(24)
	return style


static func avatar_button(selected := false, pressed := false, hovered := false, theme_surface_color := Callable()) -> StyleBoxFlat:
	var style: StyleBoxFlat = avatar_frame_background(selected, theme_surface_color)
	var fill: Color = Color("#fff1b8") if selected else theme_surface_color.call(Color("#fffdf8"))
	if hovered and not pressed:
		fill = fill.lightened(0.04)
	style.bg_color = fill.darkened(0.08 if pressed else 0.0)
	if pressed:
		style.shadow_size = 4
		style.shadow_offset = Vector2(0, 3)
	return style


static func name_field(
	focused := false,
	ink_color := Color.BLACK,
	focus_color := Color.BLUE,
	theme_surface_color := Callable(),
	theme_outline_color := Callable()
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = theme_surface_color.call(Color("#fffaf0"))
	style.border_color = focus_color if focused else theme_outline_color.call(ink_color, Color("#fffaf0"))
	style.set_border_width_all(9)
	style.set_corner_radius_all(36)
	style.content_margin_left = 34
	style.content_margin_right = 34
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style
