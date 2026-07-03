extends RefCounted

const BerryPrepControls = preload("res://scripts/ui/berry_prep_controls.gd")
const ButtonPressState = preload("res://scripts/ui/button_press_state.gd")
const PassiveModuleStyles = preload("res://scripts/ui/passive_module_styles.gd")
const RoundedTextureRect = preload("res://scripts/ui/rounded_texture_rect.gd")

const BERRY_MODE_BORDER_TEXTURE := "res://assets/content/ui/berry-mode-borders-source.png"

var host
var berry_mode_enabled := false
var berry_mode_overlay: Control


func _init(host_ref) -> void:
	host = host_ref


func toggle_berry_mode() -> void:
	set_berry_mode_enabled(not berry_mode_enabled)


func set_berry_mode_enabled(enabled: bool) -> void:
	berry_mode_enabled = enabled
	sync_berry_mode_overlay()
	sync_berry_prep_badges()
	host._set_result("Berry mode: tap modules to toggle berry." if berry_mode_enabled else "Berry mode off.")


func toggle_berry_prep_for_action(skill_id: String, action_id: String) -> void:
	var target_key: String = host.material_runtime.berry_prep_target_key(skill_id, action_id, Callable(host, "_action_data"), Callable(host, "_action_key"))
	if target_key.is_empty():
		return
	if not host.material_runtime.toggle_berry_prep_target(skill_id, action_id, Callable(host, "_action_data"), Callable(host, "_action_key")):
		host._set_result("Berry disabled for %s." % str(host._action_data(skill_id, action_id).get("name", "this module")))
	else:
		host._set_result("Berry enabled for %s." % str(host._action_data(skill_id, action_id).get("name", "this module")))
	host._mark_save_dirty("berry mode")
	host.save_game()
	sync_berry_prep_badges()


func berry_mode_card_tap_handled(skill_id: String, action_id: String) -> bool:
	if not berry_mode_enabled:
		return false
	toggle_berry_prep_for_action(skill_id, action_id)
	return true


func route_berry_mode_leave_button_input(event: InputEvent) -> bool:
	if not berry_mode_enabled:
		return false
	var button := _berry_mode_leave_button()
	if button == null:
		return false
	var event_position := _berry_mode_pointer_position(event)
	if event_position == Vector2.INF:
		return false
	var kind := ButtonPressState.event_kind(event)
	if kind == "press":
		if not button.get_global_rect().grow(24.0).has_point(event_position):
			return false
		ButtonPressState.begin(button, "berry_leave", event_position)
		host._button_press_runtime().animate_button_depress(button, float(button.get_meta("depress_animation_scale", 0.96)))
		return true
	if kind == "drag":
		ButtonPressState.update_drag(button, "berry_leave", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP)
		return ButtonPressState.active(button, "berry_leave")
	if kind == "release":
		if not ButtonPressState.active(button, "berry_leave"):
			return false
		var should_leave := ButtonPressState.finish(button, "berry_leave", event_position, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, 24.0)
		host._button_press_runtime().animate_button_release(button)
		if should_leave:
			set_berry_mode_enabled(false)
		return true
	return false


func _berry_mode_leave_button() -> Button:
	if berry_mode_overlay == null or not is_instance_valid(berry_mode_overlay):
		return null
	return berry_mode_overlay.find_child("BerryModeLeaveButton", true, false) as Button


func _berry_mode_pointer_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return Vector2.INF
		return mouse_event.global_position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).global_position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2.INF


func attempt_apply_berry_prep(skill_id: String, action_id: String, _popover_id := 0) -> void:
	toggle_berry_mode()


func sync_berry_prep_badges() -> void:
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	for raw_button in tree.get_nodes_in_group("berry_prep_buttons"):
		var button := raw_button as Button
		if button == null or not is_instance_valid(button):
			continue
		var label: Label = host._valid_label_ref(instance_from_id(int(button.get_meta("berry_prep_hint_label_id", 0))))
		if label == null:
			continue
		host._set_label_text_if_changed(label, "")
	for raw_box in tree.get_nodes_in_group("berry_prep_xp_chip_boxes"):
		_sync_berry_prep_xp_chip(raw_box as Control)


func _sync_berry_prep_xp_chip(xp_box: Control) -> void:
	if xp_box == null or not is_instance_valid(xp_box):
		return
	var skill_id := str(xp_box.get_meta("berry_prep_skill_id", ""))
	var action_id := str(xp_box.get_meta("berry_prep_action_id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return
	var selected: bool = host.material_runtime.berry_prep_matches(skill_id, action_id, Callable(host, "_action_data"), Callable(host, "_action_key"))
	var badge := instance_from_id(int(xp_box.get_meta("berry_prep_xp_badge_id", 0))) as Sprite2D
	var stroke := instance_from_id(int(xp_box.get_meta("berry_prep_xp_badge_stroke_id", 0))) as Sprite2D
	if not selected:
		if badge != null and is_instance_valid(badge):
			badge.queue_free()
		if stroke != null and is_instance_valid(stroke):
			stroke.queue_free()
		xp_box.set_meta("berry_prep_xp_badge_id", 0)
		xp_box.set_meta("berry_prep_xp_badge_stroke_id", 0)
		return
	if stroke == null or not is_instance_valid(stroke):
		stroke = Sprite2D.new()
		stroke.name = "BerryPrepXpChipBadgeStroke"
		stroke.modulate = Color.BLACK
		stroke.z_index = 0
		xp_box.add_child(stroke)
		xp_box.set_meta("berry_prep_xp_badge_stroke_id", stroke.get_instance_id())
	if badge == null or not is_instance_valid(badge):
		badge = Sprite2D.new()
		badge.name = "BerryPrepXpChipBadge"
		badge.texture = host.visual_texture_cache._texture_or_visual_fallback(host.material_runtime.icon_path("berries"))
		badge.z_index = 1
		xp_box.add_child(badge)
		xp_box.set_meta("berry_prep_xp_badge_id", badge.get_instance_id())
	var badge_target_size := 138.0
	if badge.texture != null:
		var texture_size: Vector2 = badge.texture.get_size()
		var texture_max: float = maxf(texture_size.x, texture_size.y)
		var badge_scale := 1.0
		if texture_max > 0.0:
			badge_scale = badge_target_size / texture_max
		badge.scale = Vector2.ONE * badge_scale
		stroke.texture = badge.texture
		stroke.scale = Vector2.ONE * badge_scale * 1.08
	var badge_position := Vector2(xp_box.size.x - 12.0, 10.0)
	badge.position = badge_position
	stroke.position = badge_position


func play_berry_prep_badge_feedback(skill_id: String, action_id: String, consumed: bool, out_of_berries: bool) -> void:
	if not consumed and not out_of_berries:
		return
	if host == null or not is_instance_valid(host) or not host.is_inside_tree():
		return
	var tree: SceneTree = host.get_tree()
	if tree == null:
		return
	for raw_box in tree.get_nodes_in_group("berry_prep_xp_chip_boxes"):
		var xp_box := raw_box as Control
		if xp_box == null or str(xp_box.get_meta("berry_prep_skill_id", "")) != skill_id or str(xp_box.get_meta("berry_prep_action_id", "")) != action_id:
			continue
		var badge := instance_from_id(int(xp_box.get_meta("berry_prep_xp_badge_id", 0))) as Sprite2D
		if badge == null or not is_instance_valid(badge):
			continue
		if consumed:
			_play_berry_badge_success(badge)
		if out_of_berries:
			if consumed:
				tree.create_timer(0.34).timeout.connect(_play_berry_badge_fail_shake.bind(badge))
			else:
				_play_berry_badge_fail_shake(badge)


func _play_berry_badge_success(badge: Sprite2D) -> void:
	if badge == null or not is_instance_valid(badge):
		return
	badge.modulate = Color("#93ff9e")
	var base_scale := badge.scale
	var tween = host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(badge, "scale", base_scale * 1.12, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate", Color.WHITE, 0.28)
	tween.chain().tween_property(badge, "scale", base_scale, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_berry_badge_fail_shake(badge: Sprite2D) -> void:
	if badge == null or not is_instance_valid(badge):
		return
	badge.modulate = Color("#ff8d8d")
	badge.rotation_degrees = 0.0
	var tween = host.create_tween()
	tween.tween_property(badge, "rotation_degrees", -5.0, 0.05)
	tween.tween_property(badge, "rotation_degrees", 5.0, 0.05)
	tween.tween_property(badge, "rotation_degrees", -4.0, 0.05)
	tween.tween_property(badge, "rotation_degrees", 3.0, 0.05)
	tween.tween_property(badge, "rotation_degrees", 0.0, 0.06)
	tween.parallel().tween_property(badge, "modulate", Color.WHITE, 0.26)


func sync_berry_mode_overlay() -> void:
	if not berry_mode_enabled:
		if berry_mode_overlay != null and is_instance_valid(berry_mode_overlay):
			berry_mode_overlay.queue_free()
		berry_mode_overlay = null
		return
	if berry_mode_overlay != null and is_instance_valid(berry_mode_overlay):
		return
	berry_mode_overlay = Control.new()
	berry_mode_overlay.name = "BerryModeOverlay"
	berry_mode_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	berry_mode_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	berry_mode_overlay.z_index = 3900
	berry_mode_overlay.z_as_relative = false
	host.add_child(berry_mode_overlay)
	_add_berry_mode_border()
	_add_berry_mode_input_blockers()
	_add_berry_mode_title()
	_add_berry_mode_leave_button()


func _add_berry_mode_border() -> void:
	var texture: Texture2D = host.visual_texture_cache._texture_or_visual_fallback(BERRY_MODE_BORDER_TEXTURE)
	if texture == null:
		return
	var slide_distance := 1920.0
	var top_clip := _add_berry_mode_border_clip("BerryModeBorderTop", texture, 0.0, 0.5, 0.0, 2.0, -slide_distance)
	var bottom_clip := _add_berry_mode_border_clip("BerryModeBorderBottom", texture, 0.5, 1.0, -1.0, 1.0, slide_distance)
	top_clip.set_meta("berry_mode_target_y", -24.0)
	bottom_clip.set_meta("berry_mode_target_y", 0.0)
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	for clip in [top_clip, bottom_clip]:
		var target_y := float(clip.get_meta("berry_mode_target_y", 0.0))
		tween.tween_property(clip, "offset_top", target_y, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(clip, "offset_bottom", target_y, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _add_berry_mode_border_clip(name: String, texture: Texture2D, anchor_top: float, anchor_bottom: float, texture_anchor_top: float, texture_anchor_bottom: float, start_offset_y: float) -> Control:
	var clip := Control.new()
	clip.name = name
	clip.anchor_left = 0.0
	clip.anchor_right = 1.0
	clip.anchor_top = anchor_top
	clip.anchor_bottom = anchor_bottom
	clip.offset_left = 0.0
	clip.offset_right = 0.0
	clip.offset_top = start_offset_y
	clip.offset_bottom = start_offset_y
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	berry_mode_overlay.add_child(clip)

	var border := TextureRect.new()
	border.name = "%sTexture" % name
	border.texture = texture
	border.anchor_left = 0.0
	border.anchor_right = 1.0
	border.anchor_top = texture_anchor_top
	border.anchor_bottom = texture_anchor_bottom
	border.offset_left = -42.0
	border.offset_top = -24.0
	border.offset_right = 42.0
	border.offset_bottom = 24.0
	border.stretch_mode = TextureRect.STRETCH_SCALE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(border)
	return clip


func _add_berry_mode_input_blockers() -> void:
	var top_blocker := Control.new()
	top_blocker.name = "BerryModeTopInputBlocker"
	top_blocker.anchor_left = 0.0
	top_blocker.anchor_right = 1.0
	top_blocker.anchor_top = 0.0
	top_blocker.anchor_bottom = 0.0
	top_blocker.offset_bottom = 620.0
	top_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	berry_mode_overlay.add_child(top_blocker)
	var bottom_blocker := Control.new()
	bottom_blocker.name = "BerryModeBottomInputBlocker"
	bottom_blocker.anchor_left = 0.0
	bottom_blocker.anchor_right = 1.0
	bottom_blocker.anchor_top = 1.0
	bottom_blocker.anchor_bottom = 1.0
	bottom_blocker.offset_top = -1100.0
	bottom_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	berry_mode_overlay.add_child(bottom_blocker)


func _add_berry_mode_title() -> void:
	var plate := PanelContainer.new()
	plate.name = "BerryModeTitlePlate"
	plate.anchor_left = 0.5
	plate.anchor_right = 0.5
	plate.anchor_top = 0.0
	plate.anchor_bottom = 0.0
	plate.offset_left = -800.0
	plate.offset_right = 800.0
	plate.offset_top = 284.0
	plate.offset_bottom = 610.0
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.z_index = 2
	plate.add_theme_stylebox_override("panel", _berry_mode_title_plate_style())
	berry_mode_overlay.add_child(plate)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 58)
	margin.add_theme_constant_override("margin_right", 58)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 32)
	plate.add_child(margin)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", -12)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	stack.add_child(_berry_mode_title_label("Select activities", 0.0))
	stack.add_child(_berry_mode_title_label("to toggle berries", 0.0))


func _berry_mode_title_plate_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d21af2")
	style.border_color = host.COLOR_INK
	style.set_border_width_all(14)
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 8)
	return style


func _berry_mode_title_label(text: String, min_width: float) -> Label:
	var title := host._label(text, 128, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER) as Label
	title.custom_minimum_size = Vector2(min_width, 136.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_color_override("font_outline_color", host.COLOR_INK)
	title.add_theme_constant_override("outline_size", 52)
	return title


func _add_berry_mode_leave_button() -> void:
	var button := Button.new()
	button.name = "BerryModeLeaveButton"
	button.text = "LEAVE MODE"
	button.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	button.offset_left = 250.0
	button.offset_right = -250.0
	button.offset_top = -780.0
	button.offset_bottom = -475.0
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 4
	button.add_theme_font_size_override("font_size", 140)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", host.COLOR_INK)
	button.add_theme_constant_override("outline_size", 46)
	if host.app_bold_font != null:
		button.add_theme_font_override("font", host.app_bold_font)
	button.add_theme_stylebox_override("normal", _berry_mode_leave_button_style(false))
	button.add_theme_stylebox_override("hover", _berry_mode_leave_button_style(false))
	button.add_theme_stylebox_override("pressed", _berry_mode_leave_button_style(true))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	host._button_press_runtime().attach_button_depress_animation(button, 0.96)
	button.pressed.connect(set_berry_mode_enabled.bind(false))
	berry_mode_overlay.add_child(button)


func _berry_mode_leave_button_style(pressed := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f2b544").darkened(0.14 if pressed else 0.0)
	style.border_color = host.COLOR_INK
	style.border_width_left = 12
	style.border_width_top = 12
	style.border_width_right = 12
	style.border_width_bottom = 28 if not pressed else 14
	style.corner_radius_top_left = 34
	style.corner_radius_top_right = 34
	style.corner_radius_bottom_left = 34
	style.corner_radius_bottom_right = 34
	style.shadow_color = Color(0, 0, 0, 0.38)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 12 if not pressed else 5)
	return style


func _build_mat_collection_row(skill_id: String, action: Dictionary, content_width: float) -> Dictionary:
	var reward_defs = host._action_runtime()._action_mat_reward_defs(action)
	var root = Control.new()
	root.anchor_left = 0.0
	root.anchor_right = 1.0
	root.anchor_top = 0.0
	root.anchor_bottom = 0.0
	root.offset_left = host.ACTION_CARD_POP_GUTTER
	root.offset_right = -host.ACTION_CARD_POP_GUTTER
	root.offset_top = host._activity_card_root_height() - host.MAT_COLLECTION_CONNECTOR_TOP_OVERLAP
	root.offset_bottom = root.offset_top + host.MAT_COLLECTION_AREA_HEIGHT
	root.clip_contents = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.modulate.a = 0.0
	root.scale = Vector2(0.94, 0.94)
	root.pivot_offset = Vector2(content_width * 0.5, host.MAT_COLLECTION_CONNECTOR_HEIGHT + host.MAT_COLLECTION_MODULE_SIZE.y * 0.5)
	root.z_index = 0

	var modules = {}
	var total_width = float(reward_defs.size()) * host.MAT_COLLECTION_MODULE_SIZE.x + maxf(0.0, float(reward_defs.size() - 1)) * host.MAT_COLLECTION_MODULE_GAP
	var start_x = (content_width - host.ACTION_CARD_POP_GUTTER * 2.0 - total_width) * 0.5
	for index in range(reward_defs.size()):
		var reward = reward_defs[index] as Dictionary
		var mat_id = str(reward.get("id", ""))
		var module_x = start_x + float(index) * (host.MAT_COLLECTION_MODULE_SIZE.x + host.MAT_COLLECTION_MODULE_GAP)
		var connector = _mat_collection_connector(host.material_runtime.color(mat_id).lerp(host._skill_theme_color(skill_id), 0.28))
		connector.position = Vector2(module_x + host.MAT_COLLECTION_MODULE_SIZE.x * 0.5 - 7.0, 0.0)
		root.add_child(connector)
		var module = _mat_collection_module(mat_id, skill_id, str(action.get("id", "")))
		module.position = Vector2(module_x, host.MAT_COLLECTION_CONNECTOR_HEIGHT)
		root.add_child(module)
		modules[mat_id] = module
	return {
		"root": root,
		"modules": modules,
		"visible": false,
		"action_id": str(action.get("id", ""))
	}


func _mat_collection_connector(color: Color) -> Control:
	var line = ColorRect.new()
	line.custom_minimum_size = Vector2(14, host.MAT_COLLECTION_CONNECTOR_HEIGHT + 10.0)
	line.size = line.custom_minimum_size
	line.color = color.darkened(0.34)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = 0
	return line


func _sync_mat_collection_row_position(card: Dictionary, visual_card_height: float) -> void:
	var collection = card.get("mat_collection", {}) as Dictionary
	if collection.is_empty():
		return
	var root = collection.get("root") as Control
	if root == null or not is_instance_valid(root):
		return
	root.offset_top = maxf(1.0, visual_card_height - host.MAT_COLLECTION_CONNECTOR_TOP_OVERLAP)
	root.offset_bottom = root.offset_top + host.MAT_COLLECTION_AREA_HEIGHT


func _mat_collection_module(mat_id: String, skill_id := "", action_id := "") -> Control:
	var panel = Control.new()
	panel.custom_minimum_size = host.MAT_COLLECTION_MODULE_SIZE
	panel.size = host.MAT_COLLECTION_MODULE_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_meta("mat_id", mat_id)
	var background = RoundedTextureRect.new()
	background.texture = host.visual_texture_cache._texture_or_visual_fallback(host.material_runtime.background_path(mat_id))
	background.radius = 42.0
	background.mask_inset = 0.0
	background.corner_mask_mode = 1
	background.art_height = host.MAT_COLLECTION_MODULE_SIZE.y
	background.feather_height = 0.0
	background.fallback_color = Color.WHITE
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = 0
	panel.add_child(background)
	var chrome = Panel.new()
	chrome.set_anchors_preset(Control.PRESET_FULL_RECT)
	chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome.z_index = 2
	chrome.add_theme_stylebox_override("panel", _mat_collection_module_style(mat_id))
	panel.add_child(chrome)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 46)
	margin.add_theme_constant_override("margin_right", 46)
	margin.add_theme_constant_override("margin_top", 42)
	margin.add_theme_constant_override("margin_bottom", 42)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.z_index = 3
	panel.add_child(margin)
	var stack = VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 22)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var name_label = host._label(host.material_runtime.display_name(mat_id), 78, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	name_label.add_theme_constant_override("outline_size", 18)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(name_label)
	var icon = host.visual_texture_cache._image(host.material_runtime.icon_path(mat_id), Vector2(360, 360))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(icon)
	var amount_label = host._label(host.material_runtime.amount_text_for_host(mat_id, -1.0, host), 110, Color("#fff3b6"), HORIZONTAL_ALIGNMENT_CENTER)
	amount_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	amount_label.add_theme_constant_override("outline_size", 24)
	amount_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(amount_label)
	if mat_id == "honey":
		panel.add_child(_mat_honey_info_button())
	elif mat_id == "berries" and not skill_id.is_empty() and not action_id.is_empty():
		panel.add_child(_mat_berry_info_button())
		panel.add_child(_mat_berry_prep_button(skill_id, action_id))
	panel.set_meta("icon_id", icon.get_instance_id())
	panel.set_meta("amount_label_id", amount_label.get_instance_id())
	return panel


func _mat_honey_info_button() -> Button:
	var button = Button.new()
	button.text = "i"
	button.tooltip_text = ""
	button.custom_minimum_size = Vector2(86, 86)
	button.size = button.custom_minimum_size
	button.position = Vector2(host.MAT_COLLECTION_MODULE_SIZE.x - 112.0, 28.0)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 32
	button.add_to_group("skill_header_info_buttons")
	button.add_theme_font_size_override("font_size", host.MIN_MOBILE_BODY_FONT_SIZE)
	host._apply_info_symbol_button_text_color(button)
	button.add_theme_stylebox_override("normal", PassiveModuleStyles.round_button(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("hover", PassiveModuleStyles.round_button(host.COLOR_PANEL.lightened(0.06), host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("pressed", PassiveModuleStyles.round_button(host.COLOR_GOLD.darkened(0.08), host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if host.app_bold_font != null:
		button.add_theme_font_override("font", host.app_bold_font)
	host._button_press_runtime().attach_button_depress_animation(button, 0.90)
	var popover = _mat_honey_info_popover()
	button.add_child(popover)
	host._passive_firepit_surface()._prewarm_passive_info_popover(popover)
	button.pressed.connect(Callable(host._passive_firepit_surface(), "_toggle_passive_info_popover").bind(popover))
	return button


func _mat_honey_info_popover() -> PanelContainer:
	var popover = PanelContainer.new()
	popover.position = Vector2(-610, 100)
	popover.custom_minimum_size = Vector2(690, 440)
	popover.size = popover.custom_minimum_size
	popover.visible = false
	popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.z_index = 4095
	popover.z_as_relative = false
	popover.add_to_group("skill_header_info_popovers")
	popover.add_theme_stylebox_override("panel", PassiveModuleStyles.popup(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style")))
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.add_child(margin)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var title = host._label("Honey Stamina", 64, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title)
	var body = host._label("Honey doubles stamina regen.\nEach honey consumed lasts 10 seconds.", 54, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(628, 310)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(body)
	return popover


func _mat_berry_info_button() -> Button:
	var button = Button.new()
	button.text = "i"
	button.tooltip_text = ""
	button.custom_minimum_size = Vector2(86, 86)
	button.size = button.custom_minimum_size
	button.position = Vector2(host.MAT_COLLECTION_MODULE_SIZE.x - 112.0, 28.0)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.z_index = 40
	button.add_to_group("skill_header_info_buttons")
	button.add_theme_font_size_override("font_size", host.MIN_MOBILE_BODY_FONT_SIZE)
	host._apply_info_symbol_button_text_color(button)
	button.add_theme_stylebox_override("normal", PassiveModuleStyles.round_button(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("hover", PassiveModuleStyles.round_button(host.COLOR_PANEL.lightened(0.06), host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("pressed", PassiveModuleStyles.round_button(host.COLOR_GOLD.darkened(0.08), host.COLOR_INK, Callable(host, "_surface_style"), Callable(host, "_theme_outline_color")))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if host.app_bold_font != null:
		button.add_theme_font_override("font", host.app_bold_font)
	host._button_press_runtime().attach_button_depress_animation(button, 0.90)
	var popover = _mat_berry_info_popover()
	button.add_child(popover)
	host._passive_firepit_surface()._prewarm_passive_info_popover(popover)
	button.pressed.connect(Callable(host._passive_firepit_surface(), "_toggle_passive_info_popover").bind(popover))
	return button


func _mat_berry_info_popover() -> PanelContainer:
	var popover = PanelContainer.new()
	popover.position = Vector2(-610, 100)
	popover.custom_minimum_size = Vector2(690, 520)
	popover.size = popover.custom_minimum_size
	popover.visible = false
	popover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.z_index = 4095
	popover.z_as_relative = false
	popover.add_to_group("skill_header_info_popovers")
	popover.add_theme_stylebox_override("panel", PassiveModuleStyles.popup(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style")))
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popover.add_child(margin)
	var stack = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(stack)
	var title = host._label("Berry Mode", 64, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(title)
	var body = host._label("Tap Berries to enter Berry Mode.\nThen tap modules to mark or unmark them.\nMarked modules consume 1 Berries per completion, double XP, and double loot.", 54, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2(628, 390)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(body)
	return popover


func _mat_berry_prep_button(skill_id: String, action_id: String) -> Button:
	var action = host._action_data(skill_id, action_id)
	var action_name = str(action.get("name", "this module"))
	return BerryPrepControls.build_button(
		skill_id,
		action_id,
		action_name,
		host.material_runtime.amount_text_for_host("berries", -1.0, host),
		host.material_runtime.berry_prep_matches(skill_id, action_id, Callable(host, "_action_data"), Callable(host, "_action_key")),
		host.COLOR_INK,
		PassiveModuleStyles.popup(host.COLOR_PANEL, host.COLOR_INK, Callable(host, "_surface_style")),
		host.app_bold_font,
		host.app_font,
		Callable(host._button_press_runtime(), "attach_button_depress_animation"),
		Callable(host._passive_firepit_surface(), "_prewarm_passive_info_popover"),
		Callable(host._passive_firepit_surface(), "_toggle_passive_info_popover"),
		Callable(self, "attempt_apply_berry_prep")
	)


func _mat_collection_module_style(mat_id: String) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.0)
	style.border_color = host.COLOR_INK
	style.set_border_width_all(10)
	style.corner_radius_top_left = 42
	style.corner_radius_top_right = 42
	style.corner_radius_bottom_left = 42
	style.corner_radius_bottom_right = 42
	style.shadow_color = Color(0, 0, 0, 0.28)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 10)
	return style


func _play_mat_collection_feedback(key: String, awarded_mats: Array) -> void:
	if awarded_mats.is_empty() or not host._reward_feedback_surface()._skill_action_reward_feedback_visible():
		return
	var card = host._reward_feedback_surface()._reward_feedback_card_for_key(key)
	if card.is_empty():
		return
	var art = host._valid_control_ref(card.get("art"))
	if art == null:
		art = host._valid_control_ref(card.get("art_panel"))
	var collection = card.get("mat_collection", {}) as Dictionary
	if art == null or collection.is_empty():
		return
	var modules = collection.get("modules", {}) as Dictionary
	var index = 0
	for raw_reward in awarded_mats:
		if typeof(raw_reward) != TYPE_DICTIONARY:
			continue
		var reward = raw_reward as Dictionary
		var mat_id = str(reward.get("id", ""))
		var amount = maxf(0.0, float(reward.get("amount", 0.0)))
		if amount <= 0.0001:
			continue
		var module = modules.get(mat_id) as Control
		if module == null or not is_instance_valid(module):
			continue
		_spawn_mat_collection_flyer(art, module, mat_id, index)
		_pulse_mat_collection_module(module, index)
		index += 1


func _spawn_mat_collection_flyer(source: Control, target: Control, mat_id: String, index: int) -> void:
	if source == null or target == null or not is_instance_valid(source) or not is_instance_valid(target):
		return
	var flyer = TextureRect.new()
	flyer.texture = host.visual_texture_cache._texture_or_visual_fallback(host.material_runtime.icon_path(mat_id))
	flyer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flyer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flyer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flyer.z_index = host.REWARD_FLOAT_Z + 16
	flyer.z_as_relative = false
	flyer.size = Vector2(360, 360)
	flyer.pivot_offset = flyer.size * 0.5
	var source_rect = source.get_global_rect()
	var target_rect = target.get_global_rect()
	var start = source_rect.get_center() - flyer.size * 0.5 + Vector2(randf_range(-34.0, 34.0), randf_range(-26.0, 18.0))
	var end = target_rect.get_center() - flyer.size * 0.5 + Vector2(randf_range(-22.0, 22.0), randf_range(-18.0, 18.0))
	var travel = end - start
	var min_arc_x = minf(start.x, end.x)
	var max_arc_x = maxf(start.x, end.x)
	var midpoint = (start + end) * 0.5
	var screen_center_x = host.get_viewport_rect().size.x * 0.5 - flyer.size.x * 0.5
	var center_pull_x = lerpf(midpoint.x, screen_center_x, 0.36)
	var arc_control_x = clampf(center_pull_x + randf_range(-42.0, 42.0), min_arc_x, max_arc_x)
	var arc_lift = maxf(190.0, minf(360.0, travel.length() * randf_range(0.32, 0.48)))
	var arc_control = Vector2(arc_control_x, minf(start.y, end.y) - arc_lift)
	flyer.position = start
	flyer.scale = Vector2(0.62, 0.62)
	flyer.rotation_degrees = randf_range(-12.0, 12.0)
	flyer.modulate = Color(1, 1, 1, 0.0)
	host.add_child(flyer)
	var tween = host.create_tween()
	flyer.set_meta("mat_flyer_tween", tween)
	tween.set_parallel(true)
	var delay = float(index) * 0.055
	tween.tween_property(flyer, "modulate:a", 1.0, 0.08).set_delay(delay)
	tween.tween_property(flyer, "scale", Vector2(1.08, 1.08), 0.16).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		Callable(self, "_apply_mat_collection_flyer_arc").bind(flyer.get_instance_id(), start, arc_control, end, flyer.rotation_degrees, flyer.rotation_degrees + randf_range(-34.0, 34.0)),
		0.0,
		1.0,
		host.MAT_COLLECTION_FLYER_ARC_SECONDS
	).set_delay(delay + 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(flyer, "scale", Vector2(0.34, 0.34), 0.22).set_delay(delay + host.MAT_COLLECTION_FLYER_ARC_SECONDS * 0.78).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(flyer, "modulate:a", 0.0, 0.14).set_delay(delay + host.MAT_COLLECTION_FLYER_ARC_SECONDS * 0.90)
	tween.finished.connect(_finish_mat_collection_flyer_tween.bind(flyer.get_instance_id()))


func _finish_mat_collection_flyer_tween(flyer_id: int) -> void:
	var flyer = host._valid_control_ref(instance_from_id(flyer_id))
	if flyer == null:
		return
	if flyer.has_meta("mat_flyer_tween"):
		flyer.remove_meta("mat_flyer_tween")
	flyer.queue_free()


func _apply_mat_collection_flyer_arc(progress: float, flyer_id: int, start: Vector2, control: Vector2, end: Vector2, start_rotation: float, end_rotation: float) -> void:
	var flyer = host._valid_control_ref(instance_from_id(flyer_id))
	if flyer == null:
		return
	var t = clampf(progress, 0.0, 1.0)
	var a = start.lerp(control, t)
	var b = control.lerp(end, t)
	flyer.position = a.lerp(b, t)
	flyer.rotation_degrees = lerpf(start_rotation, end_rotation, t)


func _pulse_mat_collection_module(module: Control, index: int) -> void:
	if module == null or not is_instance_valid(module):
		return
	host._kill_meta_tween(module, "mat_pulse_tween")
	var icon_id = int(module.get_meta("icon_id", 0))
	var icon = host._valid_control_ref(instance_from_id(icon_id))
	if icon == null:
		return
	module.scale = Vector2.ONE
	icon.pivot_offset = icon.size * 0.5
	icon.scale = Vector2.ONE
	var tween = host.create_tween()
	module.set_meta("mat_pulse_tween", tween)
	var delay = float(index) * 0.055 + host.MAT_COLLECTION_FLYER_ARC_SECONDS * 0.82
	tween.tween_property(icon, "scale", Vector2(1.18, 1.18), 0.08).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_mat_collection_module_pulse_tween.bind(module.get_instance_id(), icon.get_instance_id()))


func _finish_mat_collection_module_pulse_tween(module_id: int, icon_id: int) -> void:
	var icon = host._valid_control_ref(instance_from_id(icon_id))
	if icon != null:
		icon.scale = Vector2.ONE
	var module = host._valid_control_ref(instance_from_id(module_id))
	if module != null and module.has_meta("mat_pulse_tween"):
		module.remove_meta("mat_pulse_tween")


func _apply_mat_collection_layout_height(value: float, entry_id: int, action_id: String) -> void:
	var layout_height = maxf(1.0, value)
	var entry = host._valid_control_ref(instance_from_id(entry_id)) if entry_id != 0 else null
	if entry != null:
		entry.custom_minimum_size.y = layout_height
		entry.size.y = layout_height
		entry.update_minimum_size()
		var entry_parent = entry.get_parent() as Container
		if entry_parent != null:
			entry_parent.queue_sort()
	if not action_id.is_empty():
		var lazy_entry = host._detail_lazy_entry_for_track_id(action_id)
		if not lazy_entry.is_empty():
			lazy_entry["height"] = layout_height


func _clear_mat_collection_height_tween_meta(card_root_id: int) -> void:
	var card_root = host._valid_control_ref(instance_from_id(card_root_id)) if card_root_id != 0 else null
	if card_root != null and card_root.has_meta("mat_collection_height_tween"):
		card_root.remove_meta("mat_collection_height_tween")


func _sync_visible_mat_collection_for_action(skill_id: String, action_id: String, running: bool) -> void:
	var card: Dictionary = host._reward_feedback_surface()._visible_action_feedback_card(skill_id, action_id)
	if card.is_empty():
		return
	_sync_mat_collection_card(card, running, false)


func _sync_mat_collection_card(card: Dictionary, running: bool, instant := false) -> void:
	var collection = card.get("mat_collection", {}) as Dictionary
	if collection.is_empty():
		return
	if bool(card.get("page_copy_suppresses_collection_modules", false)):
		collection["visible"] = false
		card["mat_collection"] = collection
		var suppressed_root = collection.get("root") as Control
		if suppressed_root != null and is_instance_valid(suppressed_root):
			suppressed_root.modulate.a = 0.0
			suppressed_root.scale = Vector2(0.94, 0.94)
		return
	var card_root = card.get("root") as Control
	var collapsed = card_root != null and is_instance_valid(card_root) and bool(card_root.get_meta("module_ui_collapsed_squeeze", false))
	var visual_card_height = host._module_collapsed_squeeze_height() if collapsed else host._activity_card_root_height(bool(card.get("bonus_expanded", false)))
	var target_height = visual_card_height + (host.MAT_COLLECTION_AREA_HEIGHT if running else 0.0)
	_sync_mat_collection_row_position(card, visual_card_height)
	var seed_layout = not bool(collection.get("layout_initialized", false)) or (running and not bool(collection.get("ever_visible", false)))
	var entry = card.get("entry") as Control
	var entry_id = entry.get_instance_id() if entry != null and is_instance_valid(entry) else 0
	var action_id = str(card.get("action_id", ""))
	var current_height = target_height
	if entry != null and is_instance_valid(entry):
		current_height = maxf(entry.custom_minimum_size.y, entry.size.y)
	elif card_root != null and is_instance_valid(card_root):
		current_height = maxf(card_root.custom_minimum_size.y, card_root.size.y)
	if absf(current_height - target_height) > 0.5:
		host._kill_meta_tween(card_root, "mat_collection_height_tween")
		if instant or seed_layout or card_root == null or not is_instance_valid(card_root):
			_apply_mat_collection_layout_height(target_height, entry_id, action_id)
		else:
			var height_tween = card_root.create_tween()
			card_root.set_meta("mat_collection_height_tween", height_tween)
			height_tween.tween_method(Callable(self, "_apply_mat_collection_layout_height").bind(entry_id, action_id), current_height, target_height, host.MAT_COLLECTION_APPEAR_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if running else Tween.EASE_IN)
			height_tween.finished.connect(Callable(self, "_clear_mat_collection_height_tween_meta").bind(card_root.get_instance_id()))
	collection["layout_initialized"] = true
	if running:
		collection["ever_visible"] = true
	card["mat_collection"] = collection
	var root = collection.get("root") as Control
	if root == null or not is_instance_valid(root):
		return
	var modules = collection.get("modules", {}) as Dictionary
	for raw_mat_id in modules.keys():
		var mat_id = str(raw_mat_id)
		var module = modules.get(raw_mat_id) as Control
		if module == null or not is_instance_valid(module):
			continue
		var amount_label_id = int(module.get_meta("amount_label_id", 0))
		var amount_label = host._valid_label_ref(instance_from_id(amount_label_id))
		if amount_label != null:
			host._set_label_text_if_changed(amount_label, host.material_runtime.amount_text_for_host(mat_id, -1.0, host))
	if bool(collection.get("visible", false)) == running and not instant:
		return
	collection["visible"] = running
	card["mat_collection"] = collection
	host._kill_meta_tween(root, "mat_collection_tween")
	if instant:
		root.modulate.a = 1.0 if running else 0.0
		root.scale = Vector2.ONE if running else Vector2(0.94, 0.94)
		return
	var tween = host.create_tween()
	root.set_meta("mat_collection_tween", tween)
	tween.set_parallel(true)
	tween.tween_property(root, "modulate:a", 1.0 if running else 0.0, host.MAT_COLLECTION_APPEAR_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if running else Tween.EASE_IN)
	tween.tween_property(root, "scale", Vector2.ONE if running else Vector2(0.94, 0.94), host.MAT_COLLECTION_APPEAR_SECONDS).set_trans(Tween.TRANS_BACK if running else Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if running else Tween.EASE_IN)
	tween.finished.connect(host._remove_meta_from_instance_id.bind(root.get_instance_id(), "mat_collection_tween"))
