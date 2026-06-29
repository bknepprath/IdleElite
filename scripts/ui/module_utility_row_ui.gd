class_name ModuleUtilityRowUi

const ModuleUtilityCollapseArrow = preload("res://scripts/ui/module_utility_collapse_arrow.gd")


static func build(config: Dictionary) -> Dictionary:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	root.offset_top = -float(config.get("bottom_nav_height", 0.0)) - float(config.get("chat_strip_height", 0.0)) - float(config.get("gap", 0.0)) - float(config.get("height", 0.0))
	root.offset_bottom = -float(config.get("bottom_nav_height", 0.0)) - float(config.get("chat_strip_height", 0.0)) - float(config.get("gap", 0.0))
	root.z_index = int(config.get("z_index", 0))
	root.z_as_relative = false
	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_STOP

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(row)

	var texture := config.get("texture") as Callable
	var res_path := config.get("res_path") as Callable
	var install_shell := config.get("install_shell") as Callable
	var attach_press := config.get("attach_press") as Callable
	var button_size := config.get("button_size", Vector2.ZERO) as Vector2
	var buttons := {}
	for raw_def in config.get("buttons", []):
		var button_def := raw_def as Dictionary
		var button := nav_button(str(button_def.get("label", "")), str(button_def.get("icon", "")), button_def.get("fill", Color.WHITE) as Color, button_size, texture, res_path, install_shell, attach_press)
		buttons[str(button_def.get("id", ""))] = button
		row.add_child(button)

	var collapse := collapse_toggle(config.get("collapse_size", Vector2.ZERO) as Vector2, config.get("collapse_style") as Callable, attach_press)
	root.add_child(collapse)

	return {
		"root": root,
		"row": row,
		"buttons": buttons,
		"collapse_toggle": collapse
	}


static func nav_button(label_text: String, icon_path: String, fill: Color, button_size: Vector2, texture: Callable, res_path: Callable, install_shell: Callable, attach_press: Callable) -> Button:
	var button := Button.new()
	button.text = ""
	button.tooltip_text = ""
	button.custom_minimum_size = button_size
	button.clip_contents = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	var pop := install_shell.call(button, fill, 36.0) as Control
	var icon := TextureRect.new()
	icon.name = "ActivityButtonIcon"
	icon.texture = texture.call(icon_path)
	icon.set_meta("source_texture_path", res_path.call(icon_path) if res_path.is_valid() else icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.anchor_left = 0.0
	icon.anchor_right = 1.0
	icon.anchor_top = 0.0
	icon.anchor_bottom = 1.0
	icon.offset_left = 24
	icon.offset_right = -24
	icon.offset_top = 18
	icon.offset_bottom = -34
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 210
	pop.add_child(icon)
	button.set_meta("module_utility_fill", fill)
	button.set_meta("module_utility_nav_button", true)
	attach_press.call(button)
	return button


static func collapse_toggle(toggle_size: Vector2, style: Callable, attach_press: Callable) -> Button:
	var button := Button.new()
	button.name = "ModuleUtilityCollapseToggle"
	button.custom_minimum_size = toggle_size
	button.size = toggle_size
	button.clip_contents = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_stylebox_override("normal", style.call(false))
	button.add_theme_stylebox_override("hover", style.call(false))
	button.add_theme_stylebox_override("pressed", style.call(true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var arrow := ModuleUtilityCollapseArrow.new()
	arrow.name = "ActivityButtonArrow"
	arrow.set_anchors_preset(Control.PRESET_FULL_RECT)
	arrow.offset_left = 28
	arrow.offset_right = -28
	arrow.offset_top = 28
	arrow.offset_bottom = -28
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.z_index = 210
	button.add_child(arrow)
	attach_press.call(button)
	return button
