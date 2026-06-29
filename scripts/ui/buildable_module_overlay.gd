class_name BuildableModuleOverlay


static func build(parent: Control, title_text: String, meta_text: String, xp_text: String, can_afford: bool, ink_color: Color, bold_font: Font, regular_font: Font, body_font_size: int) -> Dictionary:
	if parent == null:
		return {}
	var overlay := ColorRect.new()
	overlay.color = Color("#1d6f82", 0.70)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 231
	parent.add_child(overlay)

	var cta := PanelContainer.new()
	cta.custom_minimum_size = Vector2(700, 250)
	cta.anchor_left = 0.5
	cta.anchor_right = 0.5
	cta.anchor_top = 0.5
	cta.anchor_bottom = 0.5
	cta.offset_left = -350
	cta.offset_right = 350
	cta.offset_top = -125
	cta.offset_bottom = 125
	cta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta.z_index = 233
	cta.add_theme_stylebox_override("panel", cta_style(can_afford, ink_color))
	parent.add_child(cta)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_bottom", 26)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta.add_child(margin)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 8)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)

	var title := label(title_text, 74, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
	title.add_theme_color_override("font_outline_color", ink_color)
	title.add_theme_constant_override("outline_size", 18)
	stack.add_child(title)

	var meta := label(meta_text, body_font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
	meta.add_theme_color_override("font_outline_color", ink_color)
	meta.add_theme_constant_override("outline_size", 12)
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(meta)

	var xp := label(xp_text, body_font_size, Color("#fff0a6"), HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
	xp.add_theme_color_override("font_outline_color", ink_color)
	xp.add_theme_constant_override("outline_size", 12)
	stack.add_child(xp)

	return {
		"build_overlay": overlay,
		"build_cta": cta,
		"build_cta_title": title,
		"build_cta_meta": meta,
		"build_cta_xp": xp
	}


static func label(text: String, font_size: int, color: Color, align: HorizontalAlignment, bold_font: Font, regular_font: Font) -> Label:
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = align
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if bold_font != null:
		node.add_theme_font_override("font", bold_font)
	elif regular_font != null:
		node.add_theme_font_override("font", regular_font)
	return node


static func cta_style(can_afford: bool, ink_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2f8f58") if can_afford else Color("#9a6330")
	style.border_color = ink_color
	style.set_border_width_all(8)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 28
	style.corner_radius_bottom_right = 28
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 8)
	return style
