extends RefCounted

const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const PassiveModulesRuntime = preload("res://scripts/gameplay/passive_modules_runtime.gd")
const TUTORIAL_ARROW_TEXTURE = preload("res://assets/content/ui/tutorial-arrow-curved.png")
const TUTORIAL_ARROW_SIZE := Vector2(130, 210)
const TUTORIAL_ARROW_SAFE_MARGIN := 12.0
const TUTORIAL_COPY_FONT_SIZE := 52

var host
var tutorial_layer: CanvasLayer
var tutorial_overlay: Control
var tutorial_panel: PanelContainer
var tutorial_target_ring: Panel
var tutorial_target_label: Label
var tutorial_title_label: Label
var tutorial_body_label: Label
var tutorial_step_label: Label
var tutorial_arrow: TextureRect
var tutorial_instruction_label: Label
var tutorial_arrow_float_tween: Tween
var tutorial_arrow_exit_tween: Tween
var tutorial_arrow_float_base_position := Vector2.INF
var blocking_tip_active := false
var blocking_tip_text := ""
var blocking_tip_group := ""
var blocking_tip_target: Control
var blocking_tip_shown_groups := {}
var blocking_tip_pointer_capture_active := false
var blocking_tip_pointer_capture_group := ""
var blocking_tip_pointer_capture_target: Control
var blocking_tip_pointer_capture_press: InputEvent
var blocking_tip_pointer_capture_touch_index := -1
var onboarding_mastery_tip_dismissed := false
var onboarding_medal_tip_shown := false

func _init(host_ref) -> void:
	host = host_ref

func ensure_built() -> void:
	if host._app_lifecycle_runtime().lazy_overlay_built("tutorial"):
		return
	host._app_lifecycle_runtime().mark_lazy_overlay_built("tutorial")
	build()

func build() -> void:
	tutorial_layer = CanvasLayer.new()
	tutorial_layer.layer = host.TUTORIAL_LAYER
	host.tutorial_layer = tutorial_layer
	host.add_child(tutorial_layer)

	tutorial_overlay = Control.new()
	tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.visible = false
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_overlay.gui_input.connect(_on_tutorial_overlay_gui_input)
	host.tutorial_overlay = tutorial_overlay
	tutorial_layer.add_child(tutorial_overlay)

	tutorial_target_ring = Panel.new()
	tutorial_target_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_target_ring.visible = false
	tutorial_target_ring.add_theme_stylebox_override("panel", ActivityCardStyles.tutorial_target_ring())
	host.tutorial_target_ring = tutorial_target_ring
	tutorial_overlay.add_child(tutorial_target_ring)

	tutorial_target_label = host._label("", host.MIN_MOBILE_HELP_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_target_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	tutorial_target_label.add_theme_constant_override("outline_size", 7)
	tutorial_target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_target_label.visible = false
	host.tutorial_target_label = tutorial_target_label
	tutorial_overlay.add_child(tutorial_target_label)

	tutorial_instruction_label = host._label("Tap Push-Ups to start training.", TUTORIAL_COPY_FONT_SIZE, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_instruction_label.add_theme_constant_override("outline_size", 0)
	tutorial_instruction_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_instruction_label.z_index = 19
	tutorial_instruction_label.visible = false
	tutorial_overlay.add_child(tutorial_instruction_label)

	tutorial_arrow = TextureRect.new()
	tutorial_arrow.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tutorial_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_arrow.z_index = 18
	tutorial_arrow.visible = false
	tutorial_arrow.texture = TUTORIAL_ARROW_TEXTURE
	tutorial_arrow.flip_v = false
	tutorial_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tutorial_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tutorial_overlay.add_child(tutorial_arrow)

	var panel := PanelContainer.new()
	tutorial_panel = panel
	host.tutorial_panel = tutorial_panel
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -450
	panel.offset_right = 450
	panel.offset_top = -165
	panel.offset_bottom = -60
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", host._surface_style(host.COLOR_PANEL, 26, 23, true))
	panel.z_index = 20
	panel.visible = false
	tutorial_overlay.add_child(panel)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 10)
	panel.add_child(stack)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	header.visible = false
	stack.add_child(header)

	tutorial_step_label = host._label("", 1, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	tutorial_step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_step_label.visible = false
	host.tutorial_step_label = tutorial_step_label
	header.add_child(tutorial_step_label)

	tutorial_title_label = host._label("", 60, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if host.app_bold_font != null:
		tutorial_title_label.add_theme_font_override("font", host.app_bold_font)
	host.tutorial_title_label = tutorial_title_label
	stack.add_child(tutorial_title_label)

	tutorial_body_label = host._label("", 52, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_body_label.visible = false
	host.tutorial_body_label = tutorial_body_label
	stack.add_child(tutorial_body_label)


func _route_tutorial_panel_input(event: InputEvent) -> bool:
	if blocking_tip_pointer_capture_active and not blocking_tip_active:
		_clear_blocking_tip_pointer_capture()
	if not host._onboarding_runtime().tutorial_active and not blocking_tip_active:
		return false
	var event_position := Vector2.ZERO
	var is_press := false
	var is_release := false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		event_position = mouse_event.global_position
		is_press = mouse_event.pressed
		is_release = not mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		is_press = touch_event.pressed
		is_release = not touch_event.pressed
	else:
		return false
	if host._settings_surface()._route_onboarding_settings_nav_input(event):
		return true
	if blocking_tip_active:
		if _route_blocking_tip_input(event, event_position):
			return true
		if is_press:
			_dismiss_blocking_tip()
		return is_press or is_release
	if is_press and _tutorial_target_press_advances(event_position):
		host._onboarding_runtime()._activate_tutorial_target()
		return true
	return is_press or is_release


func _on_tutorial_overlay_gui_input(event: InputEvent) -> void:
	if _route_tutorial_panel_input(event):
		tutorial_overlay.accept_event()


func _tutorial_target_press_advances(event_position: Vector2) -> bool:
	if not host._onboarding_runtime().tutorial_step in [1, 2]:
		return false
	var target := _tutorial_target_control()
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	return target.get_global_rect().grow(18.0).has_point(event_position)


func _update_tutorial_overlay() -> void:
	if tutorial_overlay == null:
		return
	var overlay_active: bool = host._onboarding_runtime().tutorial_active or blocking_tip_active
	var starter_inline_tutorial: bool = host._onboarding_runtime()._tutorial_starter_only_detail_active(host.selected_skill_id)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_overlay, overlay_active)
	if tutorial_panel != null and is_instance_valid(tutorial_panel):
		var inline_blocking_tip := ["lock_click_tip_notes", "silver_opportunity_tip_notes", "passive_module_tip_notes"].has(blocking_tip_group)
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_panel, blocking_tip_active and not inline_blocking_tip or (host._onboarding_runtime().tutorial_active and not starter_inline_tutorial and not host._onboarding_runtime().tutorial_target_activity_started))
	if not overlay_active:
		_hide_tutorial_target_indicator()
		return
	if host._onboarding_runtime().tutorial_active and not starter_inline_tutorial:
		_fade_tip_group("activity_start_tip_notes")
		call_deferred("_fade_tip_group", "activity_start_tip_notes")
	_update_tutorial_modal_copy()
	_sync_tutorial_target_indicator()


func _sync_tutorial_target_indicator() -> void:
	if tutorial_arrow_exit_tween != null and tutorial_arrow_exit_tween.is_valid():
		return
	if tutorial_target_ring != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_target_ring, false)
	if tutorial_target_label != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_target_label, false)
	_sync_tutorial_arrow()


func _update_tutorial_modal_copy() -> void:
	if tutorial_step_label != null and is_instance_valid(tutorial_step_label):
		tutorial_step_label.text = ""
	if tutorial_title_label != null and is_instance_valid(tutorial_title_label):
		tutorial_title_label.text = blocking_tip_text if blocking_tip_active else "Click an activity to start training."
	if tutorial_body_label != null and is_instance_valid(tutorial_body_label):
		tutorial_body_label.text = ""


func _sync_tutorial_arrow() -> void:
	if tutorial_arrow == null or not is_instance_valid(tutorial_arrow):
		return
	if tutorial_arrow_exit_tween != null and tutorial_arrow_exit_tween.is_valid():
		return
	if blocking_tip_group == "passive_module_tip_notes":
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_arrow, false)
		_sync_tutorial_instruction_label(null)
		_stop_tutorial_arrow_float()
		return
	var target := _tutorial_target_control()
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_arrow, false)
		_sync_tutorial_instruction_label(null)
		_stop_tutorial_arrow_float()
		return
	var target_rect := _blocking_tip_target_rect(target)
	var arrow_size := TUTORIAL_ARROW_SIZE
	var arrow_tip_offset := Vector2(0.47, 1.0) if not blocking_tip_group.is_empty() else Vector2(0.47, 0.98)
	var target_ratio := Vector2(0.50, -0.07)
	var target_point := target_rect.position + target_rect.size * target_ratio
	if blocking_tip_group == "lock_click_tip_notes":
		var padlock := _blocking_tip_padlock(target)
		if padlock != null:
			var lock_rect := padlock.get_global_rect()
			target_point = Vector2(lock_rect.get_center().x, lock_rect.position.y)
	var arrow_rotation := deg_to_rad(-18.0) if blocking_tip_group.is_empty() else 0.0
	var arrow_flip_v: bool = target_point.y < 300.0
	if arrow_flip_v:
		arrow_tip_offset.y = 0.0 if not blocking_tip_group.is_empty() else 0.02
		arrow_rotation = -arrow_rotation
	tutorial_arrow.flip_v = arrow_flip_v
	var arrow_pivot := arrow_size * 0.5
	var position := target_point - arrow_pivot - (arrow_size * arrow_tip_offset - arrow_pivot).rotated(arrow_rotation)
	var viewport_rect: Rect2 = host.get_viewport().get_visible_rect()
	var half := arrow_size * 0.5
	var rotation_cos := absf(cos(arrow_rotation))
	var rotation_sin := absf(sin(arrow_rotation))
	var rotated_extent := Vector2(rotation_cos * half.x + rotation_sin * half.y, rotation_sin * half.x + rotation_cos * half.y)
	var center := position + arrow_pivot
	center.x = clampf(center.x, viewport_rect.position.x + rotated_extent.x + TUTORIAL_ARROW_SAFE_MARGIN, viewport_rect.end.x - rotated_extent.x - TUTORIAL_ARROW_SAFE_MARGIN)
	center.y = clampf(center.y, viewport_rect.position.y + rotated_extent.y + TUTORIAL_ARROW_SAFE_MARGIN, viewport_rect.end.y - rotated_extent.y - TUTORIAL_ARROW_SAFE_MARGIN)
	position = center - arrow_pivot
	tutorial_arrow.position = position
	tutorial_arrow.size = arrow_size
	tutorial_arrow.pivot_offset = arrow_pivot
	tutorial_arrow.rotation = arrow_rotation
	tutorial_arrow.force_update_transform()
	tutorial_arrow.position += target_point - tutorial_arrow.get_global_transform() * (tutorial_arrow.size * arrow_tip_offset)
	tutorial_arrow.force_update_transform()
	position = tutorial_arrow.position
	tutorial_arrow.modulate = Color.WHITE
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_arrow, true)
	_sync_tutorial_instruction_label(target)
	if tutorial_arrow_float_tween == null or tutorial_arrow_float_base_position.distance_to(position) > 2.0:
		_start_tutorial_arrow_float(position)


func _sync_tutorial_instruction_label(target: Control) -> void:
	if tutorial_instruction_label == null or not is_instance_valid(tutorial_instruction_label):
		return
	var show_label: bool = (
		target != null
		and is_instance_valid(target)
		and target.is_visible_in_tree()
		and host._onboarding_runtime().tutorial_active
		and not host._onboarding_runtime().tutorial_target_activity_started
		and blocking_tip_group.is_empty()
	)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_instruction_label, show_label)
	if not show_label:
		tutorial_instruction_label.text = ""
		return
	tutorial_instruction_label.text = "Tap Push-Ups to start training."
	tutorial_instruction_label.add_theme_color_override("font_color", host.COLOR_INK)
	tutorial_instruction_label.add_theme_constant_override("outline_size", 0)
	tutorial_instruction_label.add_theme_font_size_override("font_size", TUTORIAL_COPY_FONT_SIZE)
	tutorial_instruction_label.size = Vector2(1000, 75)
	var target_rect := _blocking_tip_target_rect(target)
	var viewport_size: Vector2 = host.get_viewport().get_visible_rect().size
	var label_y := 92.0
	if blocking_tip_group.is_empty() and target_rect.position.y < viewport_size.y * 0.34:
		label_y = clampf(target_rect.end.y + 52.0, 92.0, viewport_size.y - tutorial_instruction_label.size.y - 92.0)
	tutorial_instruction_label.position = Vector2(80.0, label_y)


func _blocking_tip_target_rect(target: Control) -> Rect2:
	if blocking_tip_group != "silver_opportunity_tip_notes":
		return target.get_global_rect()
	var windows_value = target.get("opportunity_windows")
	if typeof(windows_value) != TYPE_ARRAY:
		return target.get_global_rect()
	var windows := windows_value as Array
	if windows.is_empty():
		return target.get_global_rect()
	var window := windows[0] as Vector2
	var rect := target.get_global_rect()
	var start_x := rect.position.x + rect.size.x * clampf(window.x, 0.0, 1.0)
	var end_x := rect.position.x + rect.size.x * clampf(window.y, 0.0, 1.0)
	return Rect2(Vector2(start_x, rect.position.y - 9.0), Vector2(maxf(1.0, end_x - start_x), rect.size.y + 18.0))


func _blocking_tip_padlock(target: Control) -> Control:
	if target == null or not is_instance_valid(target):
		return null
	var parent := target.get_parent()
	if parent != null and parent.get("padlock") == target:
		return target
	var active_rig = target.get("active_rig")
	if active_rig != null:
		var active_padlock := active_rig.get("padlock") as Control
		if active_padlock != null:
			return active_padlock
	for child in target.get_children():
		var padlock := child.get("padlock") as Control
		if padlock != null:
			return padlock
	return null


func _route_blocking_tip_input(event: InputEvent, event_position: Vector2) -> bool:
	var is_press := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	var is_release := (event is InputEventMouseButton and not (event as InputEventMouseButton).pressed) or (event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed)
	var target := _tutorial_target_control()
	if blocking_tip_pointer_capture_active:
		if not _blocking_tip_pointer_capture_matches(event):
			return false
		target = blocking_tip_pointer_capture_target
		if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
			_clear_blocking_tip_pointer_capture()
			return true
		if not is_release:
			return true
		if blocking_tip_pointer_capture_group == "lock_click_tip_notes":
			var padlock := _blocking_tip_padlock(target)
			var inside_lock := padlock != null and padlock.get_global_rect().grow(24.0).has_point(event_position)
			if inside_lock:
				var lock_cluster: Node = target if target.has_method("handle_pointer_event") else null
				var lock_parent := target.get_parent()
				while lock_cluster == null and lock_parent != null:
					if lock_parent.has_method("handle_pointer_event") and lock_parent.has_method("set_requirement_states"):
						lock_cluster = lock_parent
					lock_parent = lock_parent.get_parent()
				if lock_cluster != null:
					lock_cluster.call("handle_pointer_event", blocking_tip_pointer_capture_press)
					lock_cluster.call("handle_pointer_event", event)
			_clear_blocking_tip_pointer_capture(false)
			return true
		if blocking_tip_pointer_capture_group == "passive_module_tip_notes":
			var module_id := PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID
			host._passive_firepit_surface()._on_firepit_button_up(module_id)
			var inside_toggle := target.get_global_rect().has_point(event_position)
			_clear_blocking_tip_pointer_capture(false)
			if inside_toggle:
				host._passive_firepit_surface()._on_firepit_toggle_pressed(module_id)
				host._onboarding_runtime()._complete_passive_module_tip_page_visit("woodcutting")
			return true
		_clear_blocking_tip_pointer_capture()
		return true
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	if blocking_tip_group == "lock_click_tip_notes":
		if not is_press:
			return false
		var padlock := _blocking_tip_padlock(target)
		if padlock == null or not padlock.get_global_rect().grow(24.0).has_point(event_position):
			return false
		_begin_blocking_tip_pointer_capture(event, target, "lock_click_tip_notes")
		return true
	if blocking_tip_group == "silver_opportunity_tip_notes":
		if not _blocking_tip_target_rect(target).grow(24.0).has_point(event_position):
			return false
		if not event is InputEventMouseButton and not event is InputEventScreenTouch:
			return true
		if not is_press:
			var action_key: String = host._onboarding_runtime().silver_opportunity_tip_action_key
			var separator: int = action_key.find(":")
			if separator > 0:
				host._action_runtime()._try_action_opportunity_click(action_key.substr(0, separator), action_key.substr(separator + 1), event_position)
		return true
	if blocking_tip_group == "passive_module_tip_notes":
		if not target.get_global_rect().grow(24.0).has_point(event_position):
			return false
		var module_id := PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID
		if not is_press:
			return false
		host._passive_firepit_surface()._on_firepit_button_down(module_id, target as Button)
		_begin_blocking_tip_pointer_capture(event, target, "passive_module_tip_notes")
		return true
	return false


func _begin_blocking_tip_pointer_capture(event: InputEvent, target: Control, group_name: String) -> void:
	blocking_tip_pointer_capture_active = true
	blocking_tip_pointer_capture_group = group_name
	blocking_tip_pointer_capture_target = target
	blocking_tip_pointer_capture_press = event.duplicate() as InputEvent
	blocking_tip_pointer_capture_touch_index = (event as InputEventScreenTouch).index if event is InputEventScreenTouch else -1


func _blocking_tip_pointer_capture_matches(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).index == blocking_tip_pointer_capture_touch_index
	return false


func _clear_blocking_tip_pointer_capture(call_firepit_button_up := true) -> void:
	if call_firepit_button_up and blocking_tip_pointer_capture_group == "passive_module_tip_notes":
		host._passive_firepit_surface()._on_firepit_button_up(PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID)
	blocking_tip_pointer_capture_active = false
	blocking_tip_pointer_capture_group = ""
	blocking_tip_pointer_capture_target = null
	blocking_tip_pointer_capture_press = null
	blocking_tip_pointer_capture_touch_index = -1


func _start_tutorial_arrow_float(base_position: Vector2) -> void:
	if tutorial_arrow == null or not is_instance_valid(tutorial_arrow):
		return
	_stop_tutorial_arrow_float()
	tutorial_arrow_float_base_position = base_position
	tutorial_arrow_float_tween = host.create_tween()
	tutorial_arrow_float_tween.set_loops()
	tutorial_arrow_float_tween.tween_property(tutorial_arrow, "position:y", base_position.y - 10.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tutorial_arrow_float_tween.tween_property(tutorial_arrow, "position:y", base_position.y + 10.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _stop_tutorial_arrow_float() -> void:
	if tutorial_arrow_float_tween != null:
		tutorial_arrow_float_tween.kill()
		tutorial_arrow_float_tween = null
	tutorial_arrow_float_base_position = Vector2.INF


func _play_tutorial_arrow_success_exit() -> void:
	_hide_tutorial_target_indicator()


func _hide_tutorial_target_indicator() -> void:
	_clear_blocking_tip_pointer_capture()
	if tutorial_target_ring != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_target_ring, false)
	if tutorial_target_label != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_target_label, false)
	if tutorial_arrow_exit_tween != null:
		tutorial_arrow_exit_tween.kill()
		tutorial_arrow_exit_tween = null
	if tutorial_arrow != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_arrow, false)
		tutorial_arrow.visible = false
	if tutorial_instruction_label != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_instruction_label, false)
		tutorial_instruction_label.visible = false
	_stop_tutorial_arrow_float()


func _clear_silver_opportunity_tip_overlay() -> void:
	_clear_blocking_tip_pointer_capture()
	if blocking_tip_group == "silver_opportunity_tip_notes" or not blocking_tip_active:
		blocking_tip_active = false
		blocking_tip_text = ""
		blocking_tip_group = ""
		blocking_tip_target = null
	_hide_tutorial_target_indicator()
	if tutorial_arrow != null and is_instance_valid(tutorial_arrow):
		tutorial_arrow.modulate.a = 0.0
		tutorial_arrow.position = Vector2(-5000, -5000)
		tutorial_arrow.visible = false
	if tutorial_instruction_label != null and is_instance_valid(tutorial_instruction_label):
		tutorial_instruction_label.visible = false
	if tutorial_overlay != null and is_instance_valid(tutorial_overlay) and not host._onboarding_runtime().tutorial_active and not blocking_tip_active:
		tutorial_overlay.visible = false


func _tutorial_target_control() -> Control:
	if blocking_tip_active:
		if blocking_tip_target != null and is_instance_valid(blocking_tip_target) and blocking_tip_target.is_visible_in_tree():
			return blocking_tip_target
		return _blocking_tip_default_target()
	match host._onboarding_runtime().tutorial_step:
		0:
			if host.current_screen != "menu":
				return host.skills_tab
			var skill_id := _tutorial_target_skill_id()
			var card := host.skill_cards.get(skill_id, {}) as Dictionary
			return host._app_lifecycle_runtime().valid_control_ref(card.get("button"))
		1:
			if host.current_screen != "skill":
				return null
			var action_id := _tutorial_target_action_id()
			var key: String = host._action_key(host.selected_skill_id, action_id)
			if host.action_cards.has(key):
				var card := host.action_cards[key] as Dictionary
				var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
				if pop != null:
					return pop
				return host._app_lifecycle_runtime().valid_control_ref(card.get("button"))
		2:
			if host.current_screen != "skill":
				return null
			var key: String = host._action_key(host.running_skill_id, host.running_action_id)
			if host.action_cards.has(key):
				var card := host.action_cards[key] as Dictionary
				var mastery_bar: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("mastery"))
				if mastery_bar != null:
					return mastery_bar
			for action in host._activity_unlock_runtime()._visible_actions_for_skill(host.selected_skill_id):
				var action_dict := action as Dictionary
				if not host._activity_unlock_runtime()._is_action_unlocked(host.selected_skill_id, action_dict):
					continue
				key = host._action_key(host.selected_skill_id, str(action_dict.get("id", "")))
				if not host.action_cards.has(key):
					continue
				var card := host.action_cards[key] as Dictionary
				var mastery_bar: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("mastery"))
				if mastery_bar != null:
					return mastery_bar
	return null


func show_blocking_tip(text: String, group_name: String, target: Control = null) -> void:
	if host._onboarding_runtime().tutorial_active or text.strip_edges().is_empty() or bool(blocking_tip_shown_groups.get(group_name, false)):
		return
	ensure_built()
	blocking_tip_shown_groups[group_name] = true
	blocking_tip_active = true
	blocking_tip_text = text
	blocking_tip_group = group_name
	blocking_tip_target = target if target != null and is_instance_valid(target) else _blocking_tip_default_target()
	_update_tutorial_overlay()


func _dismiss_blocking_tip() -> void:
	_clear_blocking_tip_pointer_capture()
	var group_name := blocking_tip_group
	blocking_tip_active = false
	blocking_tip_text = ""
	blocking_tip_group = ""
	blocking_tip_target = null
	_hide_tutorial_target_indicator()
	if not group_name.is_empty():
		_fade_tip_group(group_name, false, true)
	_update_tutorial_overlay()


func _blocking_tip_default_target() -> Control:
	if blocking_tip_group == "lock_click_tip_notes":
		for raw_card in host.action_cards.values():
			var lock_card := raw_card as Dictionary
			var lock_overlay := lock_card.get("lock_overlay", {}) as Dictionary
			var lock_target: Control = host._app_lifecycle_runtime().valid_control_ref(lock_overlay.get("group"))
			if lock_target != null and lock_target.is_visible_in_tree() and _blocking_tip_padlock(lock_target) != null:
				return lock_target
		for node in host.get_tree().get_root().find_children("*", "", true, false):
			var lock_target := node as Control
			if lock_target != null and lock_target.has_method("handle_pointer_event") and lock_target.is_visible_in_tree() and _blocking_tip_padlock(lock_target) != null:
				return lock_target
	if blocking_tip_group == "silver_opportunity_tip_notes":
		var action_key: String = host._onboarding_runtime().silver_opportunity_tip_action_key
		var card := host.action_cards.get(action_key, {}) as Dictionary
		var progress: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("progress"))
		if progress != null:
			return progress
	if blocking_tip_group == "passive_module_tip_notes":
		var firepit_key: String = host._action_key("woodcutting", PassiveModulesRuntime.WOODCUTTING_FIREPIT_MODULE_ID)
		var firepit_card := host.action_cards.get(firepit_key, {}) as Dictionary
		var firepit_toggle: Control = host._app_lifecycle_runtime().valid_control_ref(firepit_card.get("toggle"))
		if firepit_toggle != null:
			return firepit_toggle
	if not host.running_skill_id.is_empty() and not host.running_action_id.is_empty():
		var running_key: String = host._action_key(host.running_skill_id, host.running_action_id)
		if host.action_cards.has(running_key):
			var running_card := host.action_cards[running_key] as Dictionary
			var running_pop: Control = host._app_lifecycle_runtime().valid_control_ref(running_card.get("pop"))
			if running_pop != null:
				return running_pop
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card := host.action_cards[key] as Dictionary
		var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
		if pop != null and pop.is_visible_in_tree():
			return pop
		var button: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("button"))
		if button != null and button.is_visible_in_tree():
			return button
	return null


func _tutorial_target_skill_id() -> String:
	if host.skill_cards.has(host.TUTORIAL_STARTER_SKILL_ID):
		return host.TUTORIAL_STARTER_SKILL_ID
	for def in host.skill_defs:
		var skill_id := str((def as Dictionary).get("id", ""))
		if host.skill_cards.has(skill_id):
			return skill_id
	return ""


func _tutorial_target_action_id() -> String:
	var starter_action: Dictionary = host._action_data(host.selected_skill_id, host.TUTORIAL_STARTER_ACTION_ID)
	if host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID and not starter_action.is_empty() and host._activity_unlock_runtime()._is_action_unlocked(host.selected_skill_id, starter_action):
		return host.TUTORIAL_STARTER_ACTION_ID
	for action in host._activity_unlock_runtime()._visible_actions_for_skill(host.selected_skill_id):
		var action_dict := action as Dictionary
		if host._activity_unlock_runtime()._is_action_unlocked(host.selected_skill_id, action_dict):
			return str(action_dict.get("id", ""))
	return ""


func reset_onboarding_tip_state() -> void:
	onboarding_mastery_tip_dismissed = false
	onboarding_medal_tip_shown = false
	blocking_tip_shown_groups.clear()


func restore_onboarding_tip_flags(data: Dictionary) -> void:
	onboarding_medal_tip_shown = bool(data.get("onboarding_medal_tip_shown", false))
	if onboarding_medal_tip_shown:
		onboarding_mastery_tip_dismissed = true


func _fade_in_skill_swipe_tip_note(note: Control):
	if note == null or not is_instance_valid(note):
		return
	note.modulate.a = 0.0
	var tween: Tween = host.create_tween()
	tween.tween_property(note, "modulate:a", 1.0, host.ONBOARDING_BOTTOM_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished


func _bottom_tutorial_tip_note(content_width: float, text: String, group_name: String, target: Control = null) -> Control:
	var root: Control = Control.new()
	root.custom_minimum_size = Vector2(content_width, 0.0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_to_group(group_name)
	root.visible = false
	call_deferred("show_blocking_tip", text, group_name, target)
	return root


func _fade_tip_control(control: Control, preserve_layout := false, collapse_layout := false) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not preserve_layout:
		control.queue_free()
	elif collapse_layout:
		control.custom_minimum_size.y = 0.0
		control.visible = false
	else:
		control.visible = false


func _fade_tip_group(group_name: String, preserve_layout := false, collapse_layout := false) -> bool:
	var had_tip := false
	for node in host.get_tree().get_nodes_in_group(group_name):
		had_tip = true
		_fade_tip_control(node as Control, preserve_layout, collapse_layout)
	if group_name == blocking_tip_group:
		blocking_tip_active = false
		blocking_tip_text = ""
		blocking_tip_group = ""
		blocking_tip_target = null
		_hide_tutorial_target_indicator()
	return had_tip


func _apply_onboarding_fight_header_visibility() -> void:
	if host._skill_detail_surface().detail_header_left_block != null and is_instance_valid(host._skill_detail_surface().detail_header_left_block):
		host._skill_detail_surface().detail_header_left_block.modulate = Color.WHITE
	if host._skill_detail_surface().detail_regen_circle != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle):
		host._skill_detail_surface().detail_regen_circle.modulate = Color.WHITE
		host._skill_detail_surface().detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
	if host._skill_detail_surface().detail_regen_circle_fade_group != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle_fade_group):
		host._skill_detail_surface().detail_regen_circle_fade_group.modulate = Color.WHITE
	if host._skill_detail_surface().detail_regen_circle_host != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle_host):
		host._skill_detail_surface().detail_regen_circle_host.modulate = Color.WHITE
	_apply_tutorial_starter_intro_header_visibility()


func _apply_tutorial_starter_intro_header_visibility() -> void:
	var intro_active: bool = host._onboarding_runtime()._tutorial_starter_only_detail_active(host.selected_skill_id)
	if host._skill_detail_surface().detail_header_left_block != null and is_instance_valid(host._skill_detail_surface().detail_header_left_block):
		host._skill_detail_surface().detail_header_left_block.visible = not intro_active
	if host._skill_detail_surface().detail_xp_label != null and is_instance_valid(host._skill_detail_surface().detail_xp_label):
		host._skill_detail_surface().detail_xp_label.visible = not intro_active
	if host._skill_detail_surface().detail_xp_bar != null and is_instance_valid(host._skill_detail_surface().detail_xp_bar):
		host._skill_detail_surface().detail_xp_bar.visible = not intro_active
	if not intro_active:
		return
	var regen_fade_target := _detail_regen_circle_fade_target()
	if regen_fade_target != null:
		regen_fade_target.modulate = Color(1, 1, 1, 0.0)
	if host._skill_detail_surface().detail_regen_circle_host != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle_host):
		host._skill_detail_surface().detail_regen_circle_host.modulate = Color(1, 1, 1, 0.0)
	if host._skill_detail_surface().detail_regen_circle != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle):
		host._skill_detail_surface().detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_tip_group("stamina_cost_tip_notes")
	if host.stamina_gauge_tip_root != null and is_instance_valid(host.stamina_gauge_tip_root):
		host.stamina_gauge_tip_root.queue_free()
	host.stamina_gauge_tip_root = null


func _detail_regen_circle_fade_target() -> CanvasItem:
	if host._skill_detail_surface().detail_regen_circle_fade_group != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle_fade_group):
		return host._skill_detail_surface().detail_regen_circle_fade_group
	return host._skill_detail_surface().detail_regen_circle


func _valid_card_control(card: Dictionary, key: String) -> Control:
	return host._app_lifecycle_runtime().valid_control_ref(card.get(key, null))


func _apply_onboarding_fight_action_card_stats_visibility(card: Dictionary, skill_id: String = "") -> void:
	if skill_id.is_empty():
		skill_id = str(card.get("skill_id", ""))
	if skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		return
	var stat_row := _valid_card_control(card, "stat_row")
	if stat_row != null:
		stat_row.modulate = Color.WHITE
	host._skill_detail_surface()._sync_action_stat_box_input_enabled(card, true)
	var mastery_bar := _valid_card_control(card, "mastery")
	if mastery_bar != null:
		mastery_bar.modulate = Color.WHITE


func _apply_onboarding_fight_action_stats_visibility_all() -> void:
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card: Dictionary = host.action_cards[key]
		if str(card.get("skill_id", "")) != host.TUTORIAL_STARTER_SKILL_ID:
			continue
		var stat_row := _valid_card_control(card, "stat_row")
		if stat_row != null:
			stat_row.modulate = Color.WHITE
			host._skill_detail_surface()._sync_action_stat_box_input_enabled(card, true)
		var mastery_bar := _valid_card_control(card, "mastery")
		if mastery_bar != null:
			mastery_bar.modulate = Color.WHITE
