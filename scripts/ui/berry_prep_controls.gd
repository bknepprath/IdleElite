class_name BerryPrepControls


static func build_button(skill_id: String, action_id: String, action_name: String, berry_amount_text: String, prepped: bool, ink_color: Color, popup_style: StyleBox, bold_font: Font, regular_font: Font, attach_depress: Callable, prewarm_popover: Callable, toggle_popover: Callable, apply_prep: Callable) -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = ""
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 34
	button.add_to_group("berry_prep_buttons")
	button.set_meta("skill_id", skill_id)
	button.set_meta("action_id", action_id)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", hover_style(false))
	button.add_theme_stylebox_override("pressed", hover_style(true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	attach_depress.call(button, 0.98)

	var hint := hint_label(prepped, ink_color, bold_font, regular_font)
	button.add_child(hint)
	button.set_meta("berry_prep_hint_label_id", hint.get_instance_id())

	var popover := build_popover(skill_id, action_id, action_name, berry_amount_text, prepped, ink_color, popup_style, bold_font, regular_font, attach_depress, apply_prep)
	button.add_child(popover)
	prewarm_popover.call(popover)
	button.pressed.connect(toggle_popover.bind(popover))
	return button


static func hint_label(prepped: bool, ink_color: Color, bold_font: Font, regular_font: Font) -> Label:
	var node := label("PREPPED" if prepped else "TAP TO PREP", 54, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
	node.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	node.offset_left = 44.0
	node.offset_right = -44.0
	node.offset_top = -126.0
	node.offset_bottom = -42.0
	node.add_theme_color_override("font_outline_color", ink_color)
	node.add_theme_constant_override("outline_size", 16)
	node.z_index = 35
	return node


static func build_popover(skill_id: String, action_id: String, action_name: String, berry_amount_text: String, prepped: bool, ink_color: Color, popup_style: StyleBox, bold_font: Font, regular_font: Font, attach_depress: Callable, apply_prep: Callable) -> PanelContainer:
	var popover := PanelContainer.new()
	popover.position = Vector2(-610, 100)
	popover.custom_minimum_size = Vector2(690, 530)
	popover.size = popover.custom_minimum_size
	popover.visible = false
	popover.mouse_filter = Control.MOUSE_FILTER_PASS
	popover.z_index = 4095
	popover.z_as_relative = false
	popover.add_to_group("skill_header_info_popovers")
	popover.add_theme_stylebox_override("panel", popup_style)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	popover.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	stack.mouse_filter = Control.MOUSE_FILTER_PASS
	margin.add_child(stack)

	var title := label("Berry Prep", 64, ink_color, HORIZONTAL_ALIGNMENT_LEFT, bold_font, regular_font)
	stack.add_child(title)

	var status := "Ready: %s Berries" % berry_amount_text
	if prepped:
		status = "Prepped for %s" % action_name
	var body := label("%s\nApply 1 serving to %s.\nNext success: +50%% XP." % [status, action_name], 54, ink_color, HORIZONTAL_ALIGNMENT_LEFT, bold_font, regular_font)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(628, 260)
	stack.add_child(body)

	var apply_button := Button.new()
	apply_button.text = "APPLY"
	apply_button.custom_minimum_size = Vector2(628, 112)
	apply_button.focus_mode = Control.FOCUS_NONE
	apply_button.mouse_filter = Control.MOUSE_FILTER_STOP
	apply_button.add_theme_font_size_override("font_size", 58)
	apply_button.add_theme_color_override("font_color", ink_color)
	apply_button.add_theme_color_override("font_hover_color", ink_color)
	apply_button.add_theme_color_override("font_pressed_color", ink_color)
	apply_button.add_theme_stylebox_override("normal", apply_style(false, ink_color))
	apply_button.add_theme_stylebox_override("hover", apply_style(false, ink_color).duplicate())
	apply_button.add_theme_stylebox_override("pressed", apply_style(true, ink_color))
	apply_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if bold_font != null:
		apply_button.add_theme_font_override("font", bold_font)
	attach_depress.call(apply_button, 0.96)
	apply_button.pressed.connect(apply_prep.bind(skill_id, action_id, popover.get_instance_id()))
	stack.add_child(apply_button)
	return popover


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


static func hover_style(pressed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.25, 0.45, 0.14 if pressed else 0.07)
	style.border_color = Color(1.0, 0.86, 0.50, 0.42 if pressed else 0.28)
	style.set_border_width_all(8 if pressed else 0)
	style.corner_radius_top_left = 42
	style.corner_radius_top_right = 42
	style.corner_radius_bottom_left = 42
	style.corner_radius_bottom_right = 42
	return style


static func apply_style(pressed := false, ink_color := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f2b544").darkened(0.10 if pressed else 0.0)
	style.border_color = ink_color
	style.set_border_width_all(8)
	style.corner_radius_top_left = 22
	style.corner_radius_top_right = 22
	style.corner_radius_bottom_left = 22
	style.corner_radius_bottom_right = 22
	style.shadow_color = Color(0, 0, 0, 0.22)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 5)
	return style
