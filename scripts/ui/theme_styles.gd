class_name ThemeStyles
extends RefCounted


static func label(text: String, font_size: int, color: Color, align: HorizontalAlignment, app_font: Font, app_bold_font: Font, dark_mode_enabled: bool, color_ink: Color, color_dark_ink: Color, color_muted: Color, color_dark_muted: Color, color_line: Color, color_dark_line: Color) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", text_color(color, dark_mode_enabled, color_ink, color_dark_ink, color_muted, color_dark_muted, color_line, color_dark_line))
	if app_bold_font != null:
		node.add_theme_font_override("font", app_bold_font)
	elif app_font != null:
		node.add_theme_font_override("font", app_font)
	return node


static func paper_color(dark_mode_enabled: bool, color_paper: Color, color_dark_paper: Color) -> Color:
	return color_dark_paper if dark_mode_enabled else color_paper


static func ink_color(dark_mode_enabled: bool, color_ink: Color, color_dark_ink: Color) -> Color:
	return color_dark_ink if dark_mode_enabled else color_ink


static func text_color(color: Color, dark_mode_enabled: bool, color_ink: Color, color_dark_ink: Color, color_muted: Color, color_dark_muted: Color, color_line: Color, color_dark_line: Color) -> Color:
	if not dark_mode_enabled:
		return color
	if color_close(color, color_ink):
		return color_dark_ink
	if color_close(color, color_muted):
		return color_dark_muted
	if color_close(color, color_line):
		return color_dark_line
	return color


static func surface_color(color: Color, dark_mode_enabled: bool, color_paper: Color, color_dark_paper: Color, color_panel: Color, color_dark_panel: Color, color_line: Color, color_dark_line: Color, color_dark_panel_alt: Color) -> Color:
	if not dark_mode_enabled or color.a <= 0.0:
		return color
	if color_close(color, color_paper):
		return color_dark_paper
	if color_close(color, color_panel):
		return color_dark_panel
	if color_close(color, color_line):
		return color_dark_line
	if color.r >= 0.86 and color.g >= 0.82 and color.b >= 0.76:
		var lightness := (color.r + color.g + color.b) / 3.0
		return color_dark_panel_alt if lightness < 0.94 else color_dark_panel
	return color


static func outline_color(outline_color: Color, fill_color: Color, dark_mode_enabled: bool, color_ink: Color, color_dark_line: Color, color_paper: Color, color_dark_paper: Color, color_panel: Color, color_dark_panel: Color, color_line: Color, color_dark_panel_alt: Color) -> Color:
	if not dark_mode_enabled:
		return outline_color
	if color_close(outline_color, color_ink) and surface_color(fill_color, dark_mode_enabled, color_paper, color_dark_paper, color_panel, color_dark_panel, color_line, color_dark_line, color_dark_panel_alt) != fill_color:
		return color_dark_line
	return outline_color


static func color_close(a: Color, b: Color, tolerance := 0.018) -> bool:
	return (
		absf(a.r - b.r) <= tolerance
		and absf(a.g - b.g) <= tolerance
		and absf(a.b - b.b) <= tolerance
		and absf(a.a - b.a) <= tolerance
	)


static func surface_style(color: Color, radius: int, margin := 28, elevated := false, dark_mode_enabled := false, passive_border := 0, color_paper := Color.WHITE, color_dark_paper := Color.BLACK, color_panel := Color.WHITE, color_dark_panel := Color.BLACK, color_line := Color.WHITE, color_dark_line := Color.BLACK, color_dark_panel_alt := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = surface_color(color, dark_mode_enabled, color_paper, color_dark_paper, color_panel, color_dark_panel, color_line, color_dark_line, color_dark_panel_alt)
	style.border_color = Color(0, 0, 0, 0)
	style.border_width_left = passive_border
	style.border_width_right = passive_border
	style.border_width_top = passive_border
	style.border_width_bottom = passive_border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	if elevated:
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.34 if dark_mode_enabled else 0.16)
		style.shadow_size = 12
		style.shadow_offset = Vector2(0, 8)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
