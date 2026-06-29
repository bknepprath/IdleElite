class_name ModuleSortMenuUi


static func build(z_index: int, level_toggle: Callable, priority_toggle: Callable, depress: Callable, app_font: Font, bold_font: Font, ink: Color) -> Dictionary:
	var menu := Control.new()
	menu.custom_minimum_size = Vector2(560, 720)
	menu.size = menu.custom_minimum_size
	menu.z_index = z_index
	menu.z_as_relative = false
	menu.visible = false
	menu.mouse_filter = Control.MOUSE_FILTER_STOP

	var visual := Control.new()
	visual.name = "ModuleSortMenuVisual"
	visual.set_anchors_preset(Control.PRESET_FULL_RECT)
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(visual)

	var row := VBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 34)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(row)

	var low_level_button := _button("Level: Low", level_toggle, depress, app_font, bold_font, ink)
	row.add_child(low_level_button)

	var combo_button := _button("Combo", priority_toggle.bind("combo"), depress, app_font, bold_font, ink)
	combo_button.set_meta("module_sort_priority_kind", "combo")
	combo_button.set_meta("module_sort_label", "Combo")
	row.add_child(combo_button)

	var collection_button := _button("Collection", priority_toggle.bind("collection"), depress, app_font, bold_font, ink)
	collection_button.set_meta("module_sort_priority_kind", "collection")
	collection_button.set_meta("module_sort_label", "Collection")
	row.add_child(collection_button)

	return {
		"menu": menu,
		"visual": visual,
		"low_level_button": low_level_button,
		"combo_button": combo_button,
		"collection_button": collection_button
	}


static func sync_buttons(low_level_button: Button, combo_button: Button, collection_button: Button, high_level_first: bool, combo_first: bool, collection_first: bool, ink: Color) -> void:
	if low_level_button != null and is_instance_valid(low_level_button):
		_sync_button(low_level_button, "Level: High" if high_level_first else "Level: Low", false, ink)
	_sync_priority_button(combo_button, combo_first, ink)
	_sync_priority_button(collection_button, collection_first, ink)


static func _sync_priority_button(button: Button, active: bool, ink: Color) -> void:
	if button == null or not is_instance_valid(button):
		return
	_sync_button(button, str(button.get_meta("module_sort_label", "Combo")), active, ink)


static func _button(label_text: String, callback: Callable, depress: Callable, app_font: Font, bold_font: Font, ink: Color) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(560, 195)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_text(button, label_text, 60, app_font, bold_font, ink)
	if callback.is_valid():
		button.pressed.connect(callback)
	if depress.is_valid():
		depress.call(button, 0.975)
	return button


static func _apply_text(button: Button, label_text: String, font_size: int, app_font: Font, bold_font: Font, ink: Color) -> void:
	button.text = label_text
	button.clip_contents = false
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", ink)
	button.add_theme_color_override("font_hover_color", ink)
	button.add_theme_color_override("font_pressed_color", ink)
	button.add_theme_color_override("font_outline_color", Color.WHITE)
	button.add_theme_constant_override("outline_size", 6)
	if bold_font != null:
		button.add_theme_font_override("font", bold_font)
	elif app_font != null:
		button.add_theme_font_override("font", app_font)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func _sync_button(button: Button, label_text: String, active: bool, ink: Color) -> void:
	button.text = label_text
	button.add_theme_stylebox_override("normal", _style(active, false, ink))
	button.add_theme_stylebox_override("hover", _style(active, false, ink))
	button.add_theme_stylebox_override("pressed", _style(active, true, ink))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func _style(active: bool, pressed := false, ink := Color.BLACK) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d8d8d8") if active else Color("#ffffff")
	if pressed:
		style.bg_color = style.bg_color.darkened(0.06)
	style.border_color = ink
	style.set_border_width_all(10)
	style.set_corner_radius_all(999)
	style.content_margin_left = 44
	style.content_margin_right = 44
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	style.shadow_size = 0
	style.shadow_color = Color.TRANSPARENT
	return style
