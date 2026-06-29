class_name ActionStatusLines


static func add_line(parent: VBoxContainer, text: String, color: Color, ink_color: Color, bold_font: Font, regular_font: Font, font_size: int, outline_size: int) -> Label:
	if parent == null or text.is_empty():
		return null
	var node := Label.new()
	node.text = text
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", ink_color)
	node.add_theme_constant_override("outline_size", outline_size)
	if bold_font != null:
		node.add_theme_font_override("font", bold_font)
	elif regular_font != null:
		node.add_theme_font_override("font", regular_font)
	parent.add_child(node)
	return node
