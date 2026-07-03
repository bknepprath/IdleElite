class_name BuildableModuleOverlay


static func build(parent: Control, title_text: String, meta_text: String, button_text: String, can_afford: bool, ink_color: Color, bold_font: Font, regular_font: Font, body_font_size: int, plank_textures: Array = [], cost: Dictionary = {}, cost_icon_paths: Dictionary = {}) -> Dictionary:
	if parent == null:
		return {}
	var overlay := rounded_panel(Color("#1d6f82", 0.88), 66, 66, 66, 66)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 239
	overlay.z_as_relative = false
	parent.add_child(overlay)

	var plank_layer: Control = null
	var plank_nodes := []
	if not plank_textures.is_empty():
		plank_layer = Control.new()
		plank_layer.name = "BuildRequiredPlankLayer"
		plank_layer.anchor_left = 0.0
		plank_layer.anchor_right = 1.0
		plank_layer.anchor_top = 0.5
		plank_layer.anchor_bottom = 0.5
		plank_layer.offset_left = 20
		plank_layer.offset_right = -20
		plank_layer.offset_top = -124
		plank_layer.offset_bottom = 314
		plank_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plank_layer.z_index = 700
		plank_layer.z_as_relative = false
		parent.add_child(plank_layer)

		var single_plank := plank_textures.size() == 1
		var layouts := [{"top": -26.0, "height": 490.0, "left": -18.0, "right": 18.0}] if single_plank else [
			{"top": 28.0, "height": 126.0, "left": 92.0, "right": -92.0},
			{"top": 156.0, "height": 168.0, "left": 54.0, "right": -54.0},
			{"top": 326.0, "height": 120.0, "left": 112.0, "right": -112.0}
		]
		for index in range(mini(plank_textures.size(), layouts.size())):
			var texture := plank_textures[index] as Texture2D
			if texture == null:
				continue
			var layout := layouts[index] as Dictionary
			var top := float(layout.get("top", 0.0))
			var height := float(layout.get("height", 120.0))
			var shadow := Panel.new()
			shadow.name = "BuildRequiredBoardShadow%02d" % [index + 1]
			shadow.anchor_left = 0.0
			shadow.anchor_right = 1.0
			shadow.offset_left = float(layout.get("left", 0.0)) + 24.0
			shadow.offset_right = float(layout.get("right", 0.0)) - 24.0
			shadow.offset_top = top + 28.0
			shadow.offset_bottom = top + height + 36.0
			var shadow_style := StyleBoxFlat.new()
			shadow_style.bg_color = Color(0, 0, 0, 0.01)
			shadow_style.corner_radius_top_left = 86
			shadow_style.corner_radius_top_right = 86
			shadow_style.corner_radius_bottom_left = 86
			shadow_style.corner_radius_bottom_right = 86
			shadow_style.shadow_color = Color(0, 0, 0, 0.24)
			shadow_style.shadow_size = 22
			shadow_style.shadow_offset = Vector2(0, 10)
			shadow.add_theme_stylebox_override("panel", shadow_style)
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shadow.z_index = index * 2
			plank_layer.add_child(shadow)
			var plank := TextureRect.new()
			plank.name = "BuildRequiredBoardPiece%02d" % [index + 1]
			plank.texture = texture
			plank.anchor_left = 0.0
			plank.anchor_right = 1.0
			plank.offset_left = float(layout.get("left", 0.0))
			plank.offset_right = float(layout.get("right", 0.0))
			plank.offset_top = top
			plank.offset_bottom = top + height
			plank.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			plank.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED if single_plank else TextureRect.STRETCH_KEEP_ASPECT_COVERED
			plank.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			plank.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plank.z_index = index * 2 + 1
			plank_layer.add_child(plank)
			plank_nodes.append(plank)

	var cta := PanelContainer.new()
	cta.custom_minimum_size = Vector2(1040, 300)
	cta.anchor_left = 0.5
	cta.anchor_right = 0.5
	cta.anchor_top = 0.5
	cta.anchor_bottom = 0.5
	cta.offset_left = -520
	cta.offset_right = 520
	cta.offset_top = -64
	cta.offset_bottom = 190
	cta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta.z_index = 730
	cta.z_as_relative = false
	cta.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	parent.add_child(cta)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cta.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	var text_stack := VBoxContainer.new()
	text_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	text_stack.add_theme_constant_override("separation", 2)
	text_stack.custom_minimum_size = Vector2(560, 204)
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_stack)

	var meta: Label = null
	var cost_heading: Label = null
	var cost_rows := []
	if cost.is_empty():
		meta = label(meta_text, maxi(body_font_size, 82), Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
		meta.add_theme_color_override("font_outline_color", ink_color)
		meta.add_theme_constant_override("outline_size", 30)
		meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_stack.add_child(meta)
	else:
		cost_heading = label("COST", maxi(body_font_size, 96), Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
		cost_heading.add_theme_constant_override("outline_size", 0)
		cost_heading.add_theme_font_size_override("font_size", maxi(body_font_size, 96))
		text_stack.add_child(cost_heading)
		var underline := ColorRect.new()
		underline.color = Color.BLACK
		underline.custom_minimum_size = Vector2(300, 14)
		underline.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_stack.add_child(underline)
		for raw_mat_id in cost.keys():
			var mat_id := str(raw_mat_id)
			var amount := float(cost.get(raw_mat_id, 0.0))
			if amount <= 0.0:
				continue
			var cost_row := HBoxContainer.new()
			cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
			cost_row.add_theme_constant_override("separation", 28)
			cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text_stack.add_child(cost_row)
			var icon_path := str(cost_icon_paths.get(mat_id, ""))
			if not icon_path.is_empty():
				var icon := TextureRect.new()
				icon.name = "BuildCostIcon_%s" % mat_id
				icon.texture = load(icon_path) as Texture2D
				icon.custom_minimum_size = Vector2(134, 134)
				icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.mouse_filter = Control.MOUSE_FILTER_STOP
				icon.pivot_offset = Vector2(67, 67)
				_wire_cost_icon_feedback(parent, icon, mat_id, bold_font, regular_font)
				cost_row.add_child(icon)
			var amount_text := "%d" % int(round(amount)) if is_equal_approx(amount, round(amount)) else str(amount)
			var amount_label := label(amount_text, maxi(body_font_size, 118), Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
			amount_label.add_theme_constant_override("outline_size", 0)
			cost_row.add_child(amount_label)
			cost_rows.append(cost_row)

	return {
		"build_overlay": overlay,
		"build_progress_cover": null,
		"build_title_backing": null,
		"build_plank_layer": plank_layer,
		"build_plank_nodes": plank_nodes,
		"build_cta": cta,
		"build_title_row": null,
		"build_button_panel": null,
		"build_module_title": null,
		"build_cta_title": null,
		"build_cta_meta": meta,
		"build_cost_heading": cost_heading,
		"build_cost_rows": cost_rows,
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


static func _wire_cost_icon_feedback(root: Control, icon: Control, mat_id: String, bold_font: Font, regular_font: Font) -> void:
	icon.gui_input.connect(Callable(BuildableModuleOverlay, "_on_cost_icon_gui_input").bind(root, icon, mat_id, bold_font, regular_font))


static func _on_cost_icon_gui_input(event: InputEvent, root: Control, icon: Control, mat_id: String, bold_font: Font, regular_font: Font) -> void:
	var pressed := false
	if event is InputEventMouseButton:
		pressed = (event as InputEventMouseButton).pressed
	elif event is InputEventScreenTouch:
		pressed = (event as InputEventScreenTouch).pressed
	if not pressed:
		return
	icon.accept_event()
	_play_cost_icon_feedback(root, icon, _resource_display_name(mat_id), bold_font, regular_font)


static func _play_cost_icon_feedback(root: Control, icon: Control, text: String, bold_font: Font, regular_font: Font) -> void:
	if root == null or icon == null or not is_instance_valid(root) or not is_instance_valid(icon):
		return
	var existing = icon.get_meta("build_cost_icon_tween", null)
	if existing is Tween and (existing as Tween).is_valid():
		(existing as Tween).kill()
	icon.scale = Vector2.ONE
	var tween := icon.create_tween()
	icon.set_meta("build_cost_icon_tween", tween)
	tween.tween_property(icon, "scale", Vector2(1.22, 1.22), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var popup := label(text, 58, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, bold_font, regular_font)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_constant_override("outline_size", 12)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 900
	popup.z_as_relative = false
	popup.size = Vector2(360, 80)
	var root_to_canvas := root.get_global_transform_with_canvas().affine_inverse()
	var icon_center := icon.get_global_transform_with_canvas() * (icon.size * 0.5)
	popup.position = root_to_canvas * icon_center - Vector2(180, 116)
	root.add_child(popup)
	var start := popup.position
	var float_tween := popup.create_tween()
	float_tween.tween_property(popup, "position", start + Vector2(0, -84), 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	float_tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	float_tween.finished.connect(Callable(BuildableModuleOverlay, "_finish_cost_icon_popup").bind(popup))


static func _finish_cost_icon_popup(popup: Control) -> void:
	if popup != null and is_instance_valid(popup):
		popup.queue_free()


static func _resource_display_name(mat_id: String) -> String:
	return mat_id.replace("_", " ").capitalize()


static func rounded_panel(color: Color, top_left: int, top_right: int, bottom_left: int, bottom_right: int) -> Panel:
	var panel := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = top_left
	style.corner_radius_top_right = top_right
	style.corner_radius_bottom_left = bottom_left
	style.corner_radius_bottom_right = bottom_right
	panel.add_theme_stylebox_override("panel", style)
	return panel


static func cta_style(can_afford: bool, ink_color: Color, art_backed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2f8f58") if can_afford else Color("#9a6330")
	style.border_color = ink_color
	style.set_border_width_all(12)
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 8)
	if art_backed:
		style.bg_color = Color("#f2c33d") if can_afford else Color("#c08c2f")
	return style
