class_name ConvergenceBuildOverlay


static func build(parent: Control, overlay_color: Color, ink_color: Color, bold_font: Font, regular_font: Font, body_font_size: int) -> Dictionary:
	if parent == null:
		return {}
	var overlay := ColorRect.new()
	overlay.color = overlay_color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 231
	parent.add_child(overlay)

	var overlay_label := label("", 86, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
	overlay_label.add_theme_color_override("font_outline_color", ink_color)
	overlay_label.add_theme_constant_override("outline_size", 26)
	overlay_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_label.z_index = 232
	parent.add_child(overlay_label)

	var cta := PanelContainer.new()
	cta.custom_minimum_size = Vector2(620, 210)
	cta.anchor_left = 0.5
	cta.anchor_right = 0.5
	cta.anchor_top = 0.5
	cta.anchor_bottom = 0.5
	cta.offset_left = -310
	cta.offset_right = 310
	cta.offset_top = -105
	cta.offset_bottom = 105
	cta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta.z_index = 233
	cta.add_theme_stylebox_override("panel", cta_style(ink_color))
	parent.add_child(cta)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta.add_child(margin)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 8)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)

	var title := label("BUILD SHRINE", 72, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
	title.add_theme_color_override("font_outline_color", ink_color)
	title.add_theme_constant_override("outline_size", 18)
	stack.add_child(title)

	var meta := label("", body_font_size, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
	meta.add_theme_color_override("font_outline_color", ink_color)
	meta.add_theme_constant_override("outline_size", 12)
	stack.add_child(meta)

	return {
		"convergence_overlay": overlay,
		"convergence_overlay_label": overlay_label,
		"convergence_build_cta": cta,
		"convergence_build_cta_title": title,
		"convergence_build_cta_meta": meta,
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


static func cta_style(ink_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2f8f58")
	style.border_color = ink_color
	style.set_border_width_all(8)
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 8)
	return style
