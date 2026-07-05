extends RefCounted

const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const TUTORIAL_ARROW_TEXTURE = preload("res://assets/content/ui/tutorial-arrow-curved.png")
const ACTIVITY_START_HIGHLIGHT_DELAY_SECONDS := 3.0
const ACTIVITY_START_HIGHLIGHT_FADE_IN_SECONDS := 3.0
const ACTIVITY_START_HIGHLIGHT_FADE_OUT_SECONDS := 0.42
const ACTIVITY_START_HIGHLIGHT_GAP := 26.0
const ACTIVITY_START_HIGHLIGHT_RING_THICKNESS := 18.0
const ACTIVITY_START_HIGHLIGHT_BLUR_SPREAD := 22.0
const ACTIVITY_START_HIGHLIGHT_BLUR_LAYERS := 12
const ACTIVITY_START_HIGHLIGHT_BORDER_COLOR := Color("#ffd84a")
const ONBOARDING_MASTERY_OVERLAY_TIP_GAP := 47.0
const ONBOARDING_MASTERY_TIP_ABOVE_CARD_GAP := 112.0
const ONBOARDING_MEDAL_TIP_LINGER_SECONDS := 3.0
const ONBOARDING_LEVEL_UP_OVERLAY_TIP_GAP := 10.0

class _StartHighlightRing:
	extends Control

	var corner_radius := 66.0
	var outer_pad := 34.0
	var gap := 26.0
	var ring_thickness := 18.0
	var blur_spread := 22.0
	var blur_layers := 12

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func set_glow_alpha(_alpha: float) -> void:
		modulate.a = 0.0
		queue_redraw()

	func _draw() -> void:
		return

	func _draw_rounded_outline(rect: Rect2, radius: float, width: float, color: Color) -> void:
		var half := width * 0.5
		var left := rect.position.x + half
		var right := rect.position.x + rect.size.x - half
		var top := rect.position.y + half
		var bottom := rect.position.y + rect.size.y - half
		if right <= left + radius * 2.0 or bottom <= top + radius * 2.0:
			return
		var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5 - half)
		draw_line(Vector2(left + r, top), Vector2(right - r, top), color, width, true)
		draw_line(Vector2(left + r, bottom), Vector2(right - r, bottom), color, width, true)
		draw_line(Vector2(left, top + r), Vector2(left, bottom - r), color, width, true)
		draw_line(Vector2(right, top + r), Vector2(right, bottom - r), color, width, true)
		draw_arc(Vector2(left + r, top + r), r, PI, PI * 1.5, 8, color, width, true)
		draw_arc(Vector2(right - r, top + r), r, PI * 1.5, PI * 2.0, 8, color, width, true)
		draw_arc(Vector2(right - r, bottom - r), r, 0.0, PI * 0.5, 8, color, width, true)
		draw_arc(Vector2(left + r, bottom - r), r, PI * 0.5, PI, 8, color, width, true)


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
var onboarding_auto_run_message_root: Control
var blocking_tip_active := false
var blocking_tip_text := ""
var blocking_tip_group := ""
var blocking_tip_target: Control
var blocking_tip_shown_groups := {}
var activity_start_highlight_token := 0
var activity_start_highlight_pending := false
var activity_start_highlight_active := false
var activity_start_highlight_border: Control
var activity_start_highlight_card_key := ""
var activity_start_highlight_fade_tween: Tween
var activity_start_highlight_frame_clip_override_active := false
var activity_start_highlight_frame_clip_saved := true
var onboarding_mastery_tip_root: Control
var onboarding_medal_tip_root: Control
var onboarding_level_up_tip_root: Control
var onboarding_swipe_overlay_tip_root: Control
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

	tutorial_target_label = host._label("", host.MIN_MOBILE_BODY_FONT_SIZE, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_target_label.add_theme_color_override("font_outline_color", host.COLOR_INK)
	tutorial_target_label.add_theme_constant_override("outline_size", 14)
	tutorial_target_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_target_label.visible = false
	host.tutorial_target_label = tutorial_target_label
	tutorial_overlay.add_child(tutorial_target_label)

	tutorial_instruction_label = host._label("Tap Push-Ups to start training.", 104, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
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
	tutorial_arrow.flip_v = true
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
	panel.offset_left = -900
	panel.offset_right = 900
	panel.offset_top = -330
	panel.offset_bottom = -120
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", host._surface_style(host.COLOR_PANEL, 52, 46, true))
	panel.z_index = 20
	panel.visible = false
	tutorial_overlay.add_child(panel)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 20)
	panel.add_child(stack)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	header.visible = false
	stack.add_child(header)

	tutorial_step_label = host._label("", 1, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	tutorial_step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_step_label.visible = false
	host.tutorial_step_label = tutorial_step_label
	header.add_child(tutorial_step_label)

	tutorial_title_label = host._label("", 88, host.COLOR_INK, HORIZONTAL_ALIGNMENT_CENTER)
	tutorial_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if host.app_bold_font != null:
		tutorial_title_label.add_theme_font_override("font", host.app_bold_font)
	host.tutorial_title_label = tutorial_title_label
	stack.add_child(tutorial_title_label)

	tutorial_body_label = host._label("", 58, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_body_label.visible = false
	host.tutorial_body_label = tutorial_body_label
	stack.add_child(tutorial_body_label)


func _route_tutorial_panel_input(event: InputEvent) -> bool:
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
	return target.get_global_rect().grow(36.0).has_point(event_position)


func _update_tutorial_overlay() -> void:
	if tutorial_overlay == null:
		return
	var overlay_active: bool = host._onboarding_runtime().tutorial_active or blocking_tip_active
	var starter_inline_tutorial: bool = host._onboarding_runtime()._tutorial_starter_only_detail_active(host.selected_skill_id)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_overlay, overlay_active)
	if tutorial_panel != null and is_instance_valid(tutorial_panel):
		var inline_blocking_tip := ["lock_click_tip_notes", "silver_opportunity_tip_notes"].has(blocking_tip_group)
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_panel, blocking_tip_active and not inline_blocking_tip or (host._onboarding_runtime().tutorial_active and not starter_inline_tutorial and not host._onboarding_runtime().tutorial_target_activity_started))
	if not overlay_active:
		_hide_tutorial_target_indicator()
		return
	if host._onboarding_runtime().tutorial_active and not starter_inline_tutorial:
		_fade_tip_group("activity_start_tip_notes")
		call_deferred("_fade_tip_group", "activity_start_tip_notes")
		_dismiss_activity_start_highlight(true)
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
	var target := _tutorial_target_control()
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_arrow, false)
		_sync_tutorial_instruction_label(null)
		_stop_tutorial_arrow_float()
		return
	var target_rect := _blocking_tip_target_rect(target)
	var arrow_size := Vector2(980, 1590)
	var arrow_tip_offset := Vector2(0.39, 0.16)
	var target_ratio := Vector2(0.50, 0.55) if blocking_tip_group == "silver_opportunity_tip_notes" else (Vector2(0.50, 0.58) if blocking_tip_group == "lock_click_tip_notes" else Vector2(0.78, 0.48))
	var target_point := target_rect.position + target_rect.size * target_ratio
	var position := target_point - Vector2(arrow_size.x * arrow_tip_offset.x, arrow_size.y * arrow_tip_offset.y)
	tutorial_arrow.position = position
	tutorial_arrow.size = arrow_size
	tutorial_arrow.pivot_offset = arrow_size * 0.5
	tutorial_arrow.rotation = 0.0
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
		and (
			(host._onboarding_runtime().tutorial_active and not host._onboarding_runtime().tutorial_target_activity_started)
			or blocking_tip_group == "lock_click_tip_notes"
			or blocking_tip_group == "silver_opportunity_tip_notes"
		)
	)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tutorial_instruction_label, show_label)
	if not show_label:
		return
	var target_rect := _blocking_tip_target_rect(target)
	tutorial_instruction_label.text = "Tap to unlock" if blocking_tip_group == "lock_click_tip_notes" else ("Silver medals unlock boosters.\nTap while the progress bar is inside it." if blocking_tip_group == "silver_opportunity_tip_notes" else "Tap Push-Ups to start training.")
	if blocking_tip_group == "lock_click_tip_notes":
		tutorial_instruction_label.add_theme_font_size_override("font_size", 104)
		tutorial_instruction_label.size = Vector2(900, 130)
		tutorial_instruction_label.position = Vector2(clampf(target_rect.get_center().x - 450.0, 80.0, 1180.0), maxf(80.0, target_rect.position.y - 980.0))
	elif blocking_tip_group == "silver_opportunity_tip_notes":
		tutorial_instruction_label.add_theme_font_size_override("font_size", 68)
		tutorial_instruction_label.size = Vector2(1780, 170)
		tutorial_instruction_label.position = Vector2(190, 70)
	else:
		tutorial_instruction_label.add_theme_font_size_override("font_size", 104)
		tutorial_instruction_label.size = Vector2(1900, 150)
		tutorial_instruction_label.position = Vector2(130, maxf(80.0, target_rect.position.y - 390.0))


func _blocking_tip_target_rect(target: Control) -> Rect2:
	if blocking_tip_group != "silver_opportunity_tip_notes":
		return target.get_global_rect()
	var windows := target.get("opportunity_windows") as Array
	if windows.is_empty():
		return target.get_global_rect()
	var window := windows[0] as Vector2
	var rect := target.get_global_rect()
	var start_x := rect.position.x + rect.size.x * clampf(window.x, 0.0, 1.0)
	var end_x := rect.position.x + rect.size.x * clampf(window.y, 0.0, 1.0)
	return Rect2(Vector2(start_x, rect.position.y - 18.0), Vector2(maxf(1.0, end_x - start_x), rect.size.y + 36.0))


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
	if tutorial_arrow == null or not is_instance_valid(tutorial_arrow) or not tutorial_arrow.visible:
		return
	_stop_tutorial_arrow_float()
	if tutorial_arrow_exit_tween != null and tutorial_arrow_exit_tween.is_valid():
		tutorial_arrow_exit_tween.kill()
	tutorial_arrow.pivot_offset = tutorial_arrow.size * 0.5
	var start_position := tutorial_arrow.position
	var drift := Vector2(260, -160)
	var target := _tutorial_target_control()
	if target != null and is_instance_valid(target) and target.is_visible_in_tree():
		var arrow_center := tutorial_arrow.get_global_rect().get_center()
		var target_center := target.get_global_rect().get_center()
		var away := arrow_center - target_center
		if away.length() > 1.0:
			drift = away.normalized() * 300.0
	tutorial_arrow_exit_tween = host.create_tween()
	tutorial_arrow_exit_tween.set_parallel(true)
	tutorial_arrow_exit_tween.tween_property(tutorial_arrow, "position", start_position + drift, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tutorial_arrow_exit_tween.tween_property(tutorial_arrow, "rotation", tutorial_arrow.rotation + 0.22 * TAU, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tutorial_arrow_exit_tween.tween_property(tutorial_arrow, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tutorial_arrow_exit_tween.finished
	if tutorial_arrow != null and is_instance_valid(tutorial_arrow):
		tutorial_arrow.visible = false
	tutorial_arrow_exit_tween = null


func _hide_tutorial_target_indicator() -> void:
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
	if blocking_tip_group == "silver_opportunity_tip_notes" or not blocking_tip_active:
		blocking_tip_active = false
		blocking_tip_text = ""
		blocking_tip_group = ""
		blocking_tip_target = null
	_hide_tutorial_target_indicator()
	if tutorial_arrow != null and is_instance_valid(tutorial_arrow):
		tutorial_arrow.modulate.a = 0.0
		tutorial_arrow.position = Vector2(-10000, -10000)
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
	if blocking_tip_group == "silver_opportunity_tip_notes":
		var action_key: String = host._onboarding_runtime().silver_opportunity_tip_action_key
		var card := host.action_cards.get(action_key, {}) as Dictionary
		var progress: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("progress"))
		if progress != null:
			return progress
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


func _create_onboarding_overlay_tip(text: String, group_name: String, font_size := -1) -> Control:
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 270
	root.z_as_relative = false
	root.add_to_group(group_name)
	root.visible = false
	call_deferred("show_blocking_tip", text, group_name)
	return root


func _position_onboarding_overlay_tip_above_card(tip: Control, card_root: Control, gap_px: float) -> void:
	if tip == null or card_root == null or not is_instance_valid(tip) or not is_instance_valid(card_root):
		return
	var overlay_parent: Control = _activity_start_highlight_overlay_parent()
	if overlay_parent == null:
		return
	var card_rect := card_root.get_global_rect()
	var parent_rect := overlay_parent.get_global_rect()
	var tip_size := tip.size
	if tip_size.y <= 1.0:
		tip_size = tip.get_combined_minimum_size()
	var x := card_rect.position.x - parent_rect.position.x + (card_rect.size.x - tip_size.x) * 0.5
	var y := card_rect.position.y - parent_rect.position.y - tip_size.y - gap_px
	tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tip.position = Vector2(x, y)
	tip.size = tip_size


func _position_onboarding_overlay_tip_below_card(tip: Control, card_root: Control, gap_px: float) -> void:
	if tip == null or card_root == null or not is_instance_valid(tip) or not is_instance_valid(card_root):
		return
	var overlay_parent: Control = _activity_start_highlight_overlay_parent()
	if overlay_parent == null:
		return
	var card_rect := card_root.get_global_rect()
	var parent_rect := overlay_parent.get_global_rect()
	var tip_size := tip.size
	if tip_size.y <= 1.0:
		tip_size = tip.get_combined_minimum_size()
	var x := card_rect.position.x - parent_rect.position.x + (card_rect.size.x - tip_size.x) * 0.5
	var y := card_rect.position.y - parent_rect.position.y + card_rect.size.y + gap_px
	tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tip.position = Vector2(x, y)
	tip.size = tip_size


func _position_onboarding_overlay_tip_near_detail_bottom(tip: Control, bottom_gap_px: float) -> void:
	if tip == null or not is_instance_valid(tip) or host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		return
	var overlay_parent: Control = _activity_start_highlight_overlay_parent()
	if overlay_parent == null:
		return
	var detail_rect: Rect2 = host._skill_detail_surface().detail_actions_scroll.get_global_rect()
	var parent_rect := overlay_parent.get_global_rect()
	var tip_size := tip.size
	if tip_size.y <= 1.0:
		tip_size = tip.get_combined_minimum_size()
	var x := detail_rect.position.x - parent_rect.position.x + (detail_rect.size.x - tip_size.x) * 0.5
	var y := detail_rect.position.y - parent_rect.position.y + detail_rect.size.y - tip_size.y - bottom_gap_px
	tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tip.position = Vector2(x, y)
	tip.size = tip_size


func reset_onboarding_tip_state() -> void:
	onboarding_mastery_tip_root = null
	onboarding_medal_tip_root = null
	onboarding_level_up_tip_root = null
	onboarding_swipe_overlay_tip_root = null
	onboarding_mastery_tip_dismissed = false
	onboarding_medal_tip_shown = false
	blocking_tip_shown_groups.clear()


func restore_onboarding_tip_flags(data: Dictionary) -> void:
	onboarding_medal_tip_shown = bool(data.get("onboarding_medal_tip_shown", false))
	if onboarding_medal_tip_shown:
		onboarding_mastery_tip_dismissed = true


func _remove_onboarding_stack_mastery_tip_legacy() -> void:
	for node in host.get_tree().get_nodes_in_group("onboarding_mastery_tip_notes"):
		var tip := node as Control
		if tip != null and is_instance_valid(tip) and tip.get_parent() is VBoxContainer:
			tip.queue_free()
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root):
		if onboarding_mastery_tip_root.get_parent() is VBoxContainer:
			onboarding_mastery_tip_root.queue_free()
			onboarding_mastery_tip_root = null


func remove_onboarding_mastery_tip() -> void:
	_remove_onboarding_stack_mastery_tip_legacy()
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root):
		onboarding_mastery_tip_root.queue_free()
	onboarding_mastery_tip_root = null


func remove_onboarding_medal_tip() -> void:
	if onboarding_medal_tip_root != null and is_instance_valid(onboarding_medal_tip_root):
		onboarding_medal_tip_root.queue_free()
	onboarding_medal_tip_root = null


func remove_onboarding_level_up_tip() -> void:
	if onboarding_level_up_tip_root != null and is_instance_valid(onboarding_level_up_tip_root):
		onboarding_level_up_tip_root.queue_free()
	onboarding_level_up_tip_root = null


func ensure_onboarding_mastery_tip_note() -> Control:
	if onboarding_mastery_tip_dismissed:
		return null
	_remove_onboarding_stack_mastery_tip_legacy()
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root):
		return onboarding_mastery_tip_root
	for node in host.get_tree().get_nodes_in_group("onboarding_mastery_tip_notes"):
		var existing := node as Control
		if existing != null and is_instance_valid(existing) and not existing.get_parent() is VBoxContainer:
			onboarding_mastery_tip_root = existing
			return existing
	var starter_card: Dictionary = host._skill_detail_surface()._card_for_action_id(host.TUTORIAL_STARTER_SKILL_ID, host.TUTORIAL_STARTER_ACTION_ID)
	var card_root := starter_card.get("root") as Control if not starter_card.is_empty() else null
	var overlay_parent: Control = _activity_start_highlight_overlay_parent()
	if card_root == null or overlay_parent == null:
		return null
	_begin_activity_start_highlight_frame_clip_override()
	var note := _create_onboarding_overlay_tip(
		"Gain mastery by completing actions.",
		"onboarding_mastery_tip_notes",
		host.BOTTOM_TUTORIAL_TIP_FONT_SIZE
	)
	note.modulate.a = 0.0
	overlay_parent.add_child(note)
	_position_onboarding_overlay_tip_above_card(note, card_root, ONBOARDING_MASTERY_TIP_ABOVE_CARD_GAP)
	onboarding_mastery_tip_root = note
	return note


func ensure_onboarding_medal_tip_note() -> Control:
	if onboarding_medal_tip_shown and onboarding_medal_tip_root == null:
		return null
	if onboarding_medal_tip_root != null and is_instance_valid(onboarding_medal_tip_root):
		return onboarding_medal_tip_root
	for node in host.get_tree().get_nodes_in_group("onboarding_medal_tip_notes"):
		var existing := node as Control
		if existing != null and is_instance_valid(existing):
			onboarding_medal_tip_root = existing
			return existing
	var starter_card: Dictionary = host._skill_detail_surface()._card_for_action_id(host.TUTORIAL_STARTER_SKILL_ID, host.TUTORIAL_STARTER_ACTION_ID)
	var card_root := starter_card.get("root") as Control if not starter_card.is_empty() else null
	var overlay_parent: Control = _activity_start_highlight_overlay_parent()
	if card_root == null or overlay_parent == null:
		return null
	_begin_activity_start_highlight_frame_clip_override()
	var note := _create_onboarding_overlay_tip(
		"Medals improve your activity stats.",
		"onboarding_medal_tip_notes"
	)
	note.modulate.a = 0.0
	overlay_parent.add_child(note)
	_position_onboarding_overlay_tip_above_card(note, card_root, ONBOARDING_MASTERY_OVERLAY_TIP_GAP)
	onboarding_medal_tip_root = note
	return note


func ensure_onboarding_level_up_tip(card: Dictionary) -> Control:
	if onboarding_level_up_tip_root != null and is_instance_valid(onboarding_level_up_tip_root):
		return onboarding_level_up_tip_root
	var card_root := card.get("root") as Control
	var overlay_parent: Control = _activity_start_highlight_overlay_parent()
	if card_root == null or overlay_parent == null:
		return null
	_begin_activity_start_highlight_frame_clip_override()
	var note := _create_onboarding_overlay_tip(
		"Level up to reach harder activities.",
		"onboarding_level_up_tip_notes",
		host.BOTTOM_TUTORIAL_TIP_FONT_SIZE
	)
	note.modulate.a = 0.0
	overlay_parent.add_child(note)
	_position_onboarding_overlay_tip_below_card(note, card_root, ONBOARDING_LEVEL_UP_OVERLAY_TIP_GAP)
	onboarding_level_up_tip_root = note
	return note


func sync_onboarding_mastery_tip_position() -> void:
	if onboarding_mastery_tip_root == null or not is_instance_valid(onboarding_mastery_tip_root):
		return
	var starter_card: Dictionary = host._skill_detail_surface()._card_for_action_id(host.TUTORIAL_STARTER_SKILL_ID, host.TUTORIAL_STARTER_ACTION_ID)
	var card_root := starter_card.get("root") as Control if not starter_card.is_empty() else null
	if card_root == null:
		return
	_position_onboarding_overlay_tip_above_card(
		onboarding_mastery_tip_root,
		card_root,
		ONBOARDING_MASTERY_TIP_ABOVE_CARD_GAP
	)


func sync_onboarding_medal_tip_position() -> void:
	if onboarding_medal_tip_root == null or not is_instance_valid(onboarding_medal_tip_root):
		return
	var starter_card: Dictionary = host._skill_detail_surface()._card_for_action_id(host.TUTORIAL_STARTER_SKILL_ID, host.TUTORIAL_STARTER_ACTION_ID)
	var card_root := starter_card.get("root") as Control if not starter_card.is_empty() else null
	if card_root == null:
		return
	_position_onboarding_overlay_tip_above_card(
		onboarding_medal_tip_root,
		card_root,
		ONBOARDING_MASTERY_OVERLAY_TIP_GAP
	)


func sync_onboarding_level_up_tip_position(card: Dictionary) -> void:
	if onboarding_level_up_tip_root == null or not is_instance_valid(onboarding_level_up_tip_root):
		return
	var card_root := card.get("root") as Control
	if card_root == null or not is_instance_valid(card_root):
		return
	_position_onboarding_overlay_tip_below_card(
		onboarding_level_up_tip_root,
		card_root,
		ONBOARDING_LEVEL_UP_OVERLAY_TIP_GAP
	)


func sync_onboarding_overlay_tips() -> void:
	if host.selected_skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		remove_onboarding_level_up_tip()
		for node in host.get_tree().get_nodes_in_group("onboarding_explore_tip_notes"):
			var explore_tip := node as Control
			if explore_tip != null and is_instance_valid(explore_tip):
				_position_onboarding_explore_tip(explore_tip)
		return
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root) and not onboarding_mastery_tip_dismissed:
		sync_onboarding_mastery_tip_position()
	if onboarding_medal_tip_root != null and is_instance_valid(onboarding_medal_tip_root):
		sync_onboarding_medal_tip_position()
	if onboarding_level_up_tip_root != null and is_instance_valid(onboarding_level_up_tip_root):
		var locked_id: String = host._onboarding_runtime()._tutorial_current_locked_preview_action_id(host.TUTORIAL_STARTER_SKILL_ID)
		var locked_card: Dictionary = host._skill_detail_surface()._card_for_action_id(host.TUTORIAL_STARTER_SKILL_ID, locked_id)
		if not locked_card.is_empty():
			sync_onboarding_level_up_tip_position(locked_card)
	if onboarding_swipe_overlay_tip_root != null and is_instance_valid(onboarding_swipe_overlay_tip_root):
		_position_onboarding_overlay_tip_near_detail_bottom(onboarding_swipe_overlay_tip_root, 70.0)


func _skill_swipe_tip_present() -> bool:
	if (
		onboarding_swipe_overlay_tip_root != null
		and is_instance_valid(onboarding_swipe_overlay_tip_root)
		and onboarding_swipe_overlay_tip_root.is_inside_tree()
	):
		return true
	for node in host.get_tree().get_nodes_in_group("skill_swipe_tip_notes"):
		var tip := node as Control
		if tip != null and is_instance_valid(tip) and tip.is_inside_tree():
			return true
	return false


func _show_skill_swipe_tip_note_if_needed() -> void:
	if not host._onboarding_runtime()._skill_swipe_tip_available() or host._onboarding_runtime().skill_swipe_tip_seen:
		return
	call_deferred("_run_onboarding_swipe_tip_sequence")


func _resolve_skill_swipe_tip_stack() -> VBoxContainer:
	if host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		return null
	if host._skill_detail_surface().detail_actions_scroll.get_child_count() <= 0:
		return null
	return host._skill_detail_surface().detail_actions_scroll.get_child(0) as VBoxContainer


func _mount_skill_swipe_tip_note() -> Control:
	var stack := _resolve_skill_swipe_tip_stack()
	if stack == null:
		return null
	for node in host.get_tree().get_nodes_in_group("skill_swipe_tip_notes"):
		var existing := node as Control
		if existing == null or not is_instance_valid(existing):
			continue
		if host._skill_detail_surface()._tutorial_note_is_in_stack(existing, stack):
			onboarding_swipe_overlay_tip_root = null
			host._navigation_shell()._ensure_onboarding_page_switch_module_faded_in(stack)
			return existing
		if existing == onboarding_swipe_overlay_tip_root:
			onboarding_swipe_overlay_tip_root = existing
			fade_out_onboarding_swipe_overlay_tip(0.12)
	var content_width: float = host._skill_content_width()
	var note: Control = _bottom_tutorial_tip_note(content_width, "Some activities require multiple skills.\nSwipe left or right to see other skills.", "skill_swipe_tip_notes")
	note.modulate = Color(1, 1, 1, 0)
	host._skill_detail_surface()._detail_eager_add_skill_swipe_tip_after_anchor(stack, note, content_width, content_width)
	host._navigation_shell()._ensure_onboarding_page_switch_module_faded_in(stack)
	onboarding_swipe_overlay_tip_root = null
	return note


func _fade_in_skill_swipe_tip_note(note: Control):
	if note == null or not is_instance_valid(note):
		return
	note.modulate.a = 0.0
	var tween: Tween = host.create_tween()
	tween.tween_property(note, "modulate:a", 1.0, host.ONBOARDING_BOTTOM_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished


func _run_onboarding_swipe_tip_sequence() -> void:
	if not host._onboarding_runtime()._onboarding_swipe_tip_sequence_resumable():
		return
	if host._onboarding_runtime().onboarding_swipe_tip_sequence_running:
		return
	host._onboarding_runtime().onboarding_swipe_tip_sequence_running = true
	for attempt in range(20):
		if not host._onboarding_runtime()._onboarding_swipe_tip_sequence_resumable():
			host._onboarding_runtime().onboarding_swipe_tip_sequence_running = false
			return
		var note: Control = _mount_skill_swipe_tip_note()
		if note != null and is_instance_valid(note):
			if note.modulate.a < 0.99:
				await _fade_in_skill_swipe_tip_note(note)
			host._onboarding_runtime().onboarding_swipe_tip_sequence_running = false
			return
		await host.get_tree().process_frame
	host._onboarding_runtime().onboarding_swipe_tip_sequence_running = false
	call_deferred("_run_onboarding_swipe_tip_sequence")


func _mount_onboarding_explore_tip_note() -> Control:
	for node in host.get_tree().get_nodes_in_group("onboarding_explore_tip_notes"):
		var existing := node as Control
		if existing == null or not is_instance_valid(existing):
			continue
		if host._skill_detail_surface()._tutorial_note_is_in_stack(existing, _resolve_skill_swipe_tip_stack()):
			existing.queue_free()
			continue
		_position_onboarding_explore_tip(existing)
		return existing
	var overlay_parent: Control = _activity_start_highlight_overlay_parent()
	if overlay_parent == null:
		return null
	var note: Control = _create_onboarding_overlay_tip(
		"Other skills have unique rules and content to explore.\nHave fun!",
		"onboarding_explore_tip_notes",
		host.BOTTOM_TUTORIAL_TIP_FONT_SIZE
	)
	note.visible = false
	note.modulate = Color(1, 1, 1, 0)
	overlay_parent.add_child(note)
	_position_onboarding_explore_tip(note)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(note, true)
	Callable(host._skill_detail_surface(), "_sync_detail_actions_scroll_limit_deferred").call_deferred()
	return note


func _position_onboarding_explore_tip(tip: Control) -> void:
	if tip == null or not is_instance_valid(tip):
		return
	if bool(tip.get_meta("onboarding_explore_tip_position_locked", false)):
		return
	var overlay_parent: Control = _activity_start_highlight_overlay_parent()
	if overlay_parent == null:
		return
	var anchor: Control = _lowest_visible_module_stack_child()
	if anchor == null:
		_position_onboarding_overlay_tip_near_detail_bottom(tip, 70.0)
		return
	var anchor_rect: Rect2 = anchor.get_global_rect()
	var parent_rect: Rect2 = overlay_parent.get_global_rect()
	var detail_rect: Rect2 = host._skill_detail_surface().detail_actions_scroll.get_global_rect() if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll) else parent_rect
	var tip_size := tip.size
	if tip_size.y <= 1.0:
		tip_size = tip.get_combined_minimum_size()
	var x: float = anchor_rect.position.x - parent_rect.position.x + (anchor_rect.size.x - tip_size.x) * 0.5
	var y: float = anchor_rect.end.y - parent_rect.position.y + 34.0
	var max_y: float = detail_rect.end.y - parent_rect.position.y - tip_size.y - 58.0
	tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tip.position = Vector2(x, minf(y, max_y))
	tip.size = tip_size


func _lowest_visible_module_stack_child() -> Control:
	var stack: Control = host._skill_detail_surface()._detail_actions_stack()
	if stack == null or not is_instance_valid(stack):
		return null
	var best: Control = null
	var best_bottom := -INF
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null or not is_instance_valid(child):
			continue
		if not host._skill_detail_surface()._detail_stack_child_is_module_content(child):
			continue
		var rect: Rect2 = child.get_global_rect()
		if rect.size.y <= 1.0:
			continue
		if rect.end.y > best_bottom:
			best_bottom = rect.end.y
			best = child
	return best


func _fade_in_onboarding_explore_tip_note(note: Control):
	if note == null or not is_instance_valid(note):
		return
	note.set_meta("onboarding_explore_tip_position_locked", false)
	_position_onboarding_explore_tip(note)
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(note, true)
	note.set_meta("onboarding_explore_tip_position_locked", true)
	note.modulate.a = 0.0
	var tween: Tween = host.create_tween()
	tween.tween_property(note, "modulate:a", 1.0, host.ONBOARDING_BOTTOM_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished


func _run_onboarding_explore_tip_sequence() -> void:
	if host._onboarding_runtime().onboarding_tutorial_complete:
		return
	if host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		return
	if host._onboarding_runtime().onboarding_explore_tip_sequence_running:
		return
	host._onboarding_runtime().onboarding_explore_tip_sequence_running = true
	var note: Control = _mount_onboarding_explore_tip_note()
	if note != null and is_instance_valid(note):
		await host.get_tree().process_frame
		if note.modulate.a < 0.99:
			await _fade_in_onboarding_explore_tip_note(note)
		if not host._onboarding_runtime().onboarding_explore_tip_seen:
			host._onboarding_runtime().onboarding_explore_tip_seen = true
			host.save_game()
	else:
		call_deferred("_run_onboarding_explore_tip_sequence")
	host._onboarding_runtime().onboarding_explore_tip_sequence_running = false


func remove_onboarding_swipe_overlay_tip() -> void:
	if onboarding_swipe_overlay_tip_root != null and is_instance_valid(onboarding_swipe_overlay_tip_root):
		onboarding_swipe_overlay_tip_root.queue_free()
	onboarding_swipe_overlay_tip_root = null


func fade_out_onboarding_swipe_overlay_tip(duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = host.ONBOARDING_BOTTOM_TIP_FADE_SECONDS
	var tip: Control = onboarding_swipe_overlay_tip_root
	if tip == null or not is_instance_valid(tip):
		onboarding_swipe_overlay_tip_root = null
		return
	var tween: Tween = host.create_tween()
	tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "swipe"))


func fade_out_onboarding_explore_tip(duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = host.ONBOARDING_BOTTOM_TIP_FADE_SECONDS
	for node in host.get_tree().get_nodes_in_group("onboarding_explore_tip_notes"):
		var tip := node as Control
		if tip == null or not is_instance_valid(tip) or tip.is_queued_for_deletion():
			continue
		_position_onboarding_explore_tip(tip)
		tip.set_meta("onboarding_explore_tip_position_locked", true)
		_reparent_tip_to_unclipped_fade_layer(tip)
		tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tween: Tween = host.create_tween()
		tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "explore"))


func _reparent_tip_to_unclipped_fade_layer(tip: Control) -> void:
	if tip == null or not is_instance_valid(tip):
		return
	var current_parent := tip.get_parent()
	if current_parent == host:
		return
	var global_rect: Rect2 = tip.get_global_rect()
	if current_parent != null:
		current_parent.remove_child(tip)
	host.add_child(tip)
	tip.z_as_relative = false
	tip.z_index = 4095
	tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tip.position = global_rect.position - host.get_global_rect().position
	tip.size = global_rect.size
	tip.clip_contents = false
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(tip, true)


func fade_out_onboarding_mastery_tip(duration: float) -> void:
	if onboarding_mastery_tip_dismissed:
		return
	onboarding_mastery_tip_dismissed = true
	var tip: Control = onboarding_mastery_tip_root
	if tip == null or not is_instance_valid(tip):
		onboarding_mastery_tip_root = null
		return
	var tween: Tween = host.create_tween()
	tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "mastery"))


func fade_out_onboarding_medal_tip(duration: float) -> void:
	if not onboarding_medal_tip_shown and onboarding_medal_tip_root == null:
		return
	onboarding_medal_tip_shown = true
	var tip: Control = onboarding_medal_tip_root
	if tip == null or not is_instance_valid(tip):
		onboarding_medal_tip_root = null
		return
	var tween: Tween = host.create_tween()
	tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "medal"))


func fade_out_onboarding_level_up_tip(duration: float = -1.0) -> void:
	if duration < 0.0:
		duration = host.ACTIVITY_PREVIEW_FADE_IN_SECONDS
	var tip: Control = onboarding_level_up_tip_root
	if tip == null or not is_instance_valid(tip):
		onboarding_level_up_tip_root = null
		return
	onboarding_level_up_tip_root = null
	var tween: Tween = host.create_tween()
	tween.tween_property(tip, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_onboarding_tip_fade.bind(tip.get_instance_id(), "level_up"))


func _finish_onboarding_tip_fade(tip_id: int, tip_kind: String) -> void:
	var tip: Control = host._app_lifecycle_runtime().valid_control_ref(instance_from_id(tip_id))
	if tip != null:
		tip.queue_free()
	match tip_kind:
		"mastery":
			onboarding_mastery_tip_root = null
		"medal":
			onboarding_medal_tip_root = null
		"level_up":
			onboarding_level_up_tip_root = null
		"swipe":
			onboarding_swipe_overlay_tip_root = null
		"explore":
			host._onboarding_runtime().onboarding_explore_tip_sequence_running = false


func maybe_show_onboarding_medal_tip(old_level: int, new_level: int, skill_id: String, action_id: String) -> void:
	if onboarding_medal_tip_shown:
		return
	if not host._onboarding_runtime()._onboarding_path_active():
		return
	if skill_id != host.TUTORIAL_STARTER_SKILL_ID or action_id != host.TUTORIAL_STARTER_ACTION_ID:
		return
	if old_level >= 1 or new_level < 1:
		return
	call_deferred("_run_onboarding_medal_tip_sequence")


func _run_onboarding_medal_tip_sequence() -> void:
	if onboarding_medal_tip_shown:
		return
	if not host._onboarding_runtime()._onboarding_path_active():
		return
	if host.selected_skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		return
	if (
		onboarding_mastery_tip_root != null
		and is_instance_valid(onboarding_mastery_tip_root)
		and not onboarding_mastery_tip_dismissed
	):
		fade_out_onboarding_mastery_tip(0.45)
		await host.get_tree().create_timer(0.22).timeout
	var note := ensure_onboarding_medal_tip_note()
	if note != null and is_instance_valid(note):
		var tween: Tween = host.create_tween()
		tween.tween_property(note, "modulate:a", 1.0, host.ONBOARDING_FIGHT_ACTION_STATS_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
		onboarding_medal_tip_shown = true
		host.save_game()
		await host.get_tree().create_timer(ONBOARDING_MEDAL_TIP_LINGER_SECONDS).timeout
		if onboarding_medal_tip_root != null and is_instance_valid(onboarding_medal_tip_root):
			fade_out_onboarding_medal_tip(host.ONBOARDING_BOTTOM_TIP_FADE_SECONDS)


func sync_onboarding_level_up_tip_position_by_key(_tip_progress: float, card_key: String) -> void:
	var card := host.action_cards.get(card_key, {}) as Dictionary
	if card.is_empty():
		return
	sync_onboarding_level_up_tip_position(card)


func _activity_start_tutorial_active() -> bool:
	if host._onboarding_runtime().tutorial_active:
		return false
	return (
		host.current_screen == "skill"
		and host._onboarding_runtime()._skill_detail_shows_tutorial_tips()
		and not host._onboarding_runtime().activity_start_tip_seen
		and host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID
	)


func _schedule_activity_start_highlight_if_needed(skill_id: String, action_id: String) -> void:
	return
	if skill_id != host.TUTORIAL_STARTER_SKILL_ID or action_id != host.TUTORIAL_STARTER_ACTION_ID:
		return
	if not _activity_start_tutorial_active():
		return
	if activity_start_highlight_pending or activity_start_highlight_active:
		return
	call_deferred("_schedule_activity_start_highlight")


func _schedule_activity_start_highlight() -> void:
	if not _activity_start_tutorial_active():
		return
	activity_start_highlight_token += 1
	activity_start_highlight_pending = true
	var token := activity_start_highlight_token
	_run_activity_start_highlight_schedule(token)


func _run_activity_start_highlight_schedule(token: int) -> void:
	await host.get_tree().create_timer(ACTIVITY_START_HIGHLIGHT_DELAY_SECONDS).timeout
	if token != activity_start_highlight_token:
		return
	if not activity_start_highlight_pending or not _activity_start_tutorial_active():
		activity_start_highlight_pending = false
		return
	activity_start_highlight_pending = false
	_begin_activity_start_highlight_fade_in(token, 0)


func _begin_activity_start_highlight_fade_in(token: int, attempt: int) -> void:
	if token != activity_start_highlight_token or not _activity_start_tutorial_active():
		return
	var key: String = host._action_key(host.TUTORIAL_STARTER_SKILL_ID, host.TUTORIAL_STARTER_ACTION_ID)
	if not host.action_cards.has(key):
		if attempt >= 90:
			return
		await host.get_tree().process_frame
		_begin_activity_start_highlight_fade_in(token, attempt + 1)
		return
	var card := host.action_cards[key] as Dictionary
	_attach_activity_start_highlight_border(card)
	activity_start_highlight_active = true
	activity_start_highlight_card_key = key
	var border := activity_start_highlight_border
	if border == null or not is_instance_valid(border):
		return
	border.set_glow_alpha(0.0)
	if activity_start_highlight_fade_tween != null:
		activity_start_highlight_fade_tween.kill()
	activity_start_highlight_fade_tween = host.create_tween()
	activity_start_highlight_fade_tween.tween_method(
		border.set_glow_alpha,
		0.0,
		1.0,
		ACTIVITY_START_HIGHLIGHT_FADE_IN_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _activity_start_highlight_glow_extent() -> float:
	return ACTIVITY_START_HIGHLIGHT_GAP + ACTIVITY_START_HIGHLIGHT_RING_THICKNESS + ACTIVITY_START_HIGHLIGHT_BLUR_SPREAD + 8.0


func _activity_start_highlight_overlay_parent() -> Control:
	if host._skill_swipe_activity_surface().skill_swipe_frame != null and is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_frame):
		return host._skill_swipe_activity_surface().skill_swipe_frame
	if host._skill_swipe_activity_surface().skill_swipe_page != null and is_instance_valid(host._skill_swipe_activity_surface().skill_swipe_page):
		return host._skill_swipe_activity_surface().skill_swipe_page
	return null


func _begin_activity_start_highlight_frame_clip_override() -> void:
	var frame: Control = host._skill_swipe_activity_surface().skill_swipe_frame
	if frame == null or not is_instance_valid(frame) or activity_start_highlight_frame_clip_override_active:
		return
	activity_start_highlight_frame_clip_saved = frame.clip_contents
	frame.clip_contents = false
	activity_start_highlight_frame_clip_override_active = true


func _restore_activity_start_highlight_frame_clip() -> void:
	if not activity_start_highlight_frame_clip_override_active:
		return
	var frame: Control = host._skill_swipe_activity_surface().skill_swipe_frame
	if frame != null and is_instance_valid(frame):
		frame.clip_contents = activity_start_highlight_frame_clip_saved
	activity_start_highlight_frame_clip_override_active = false


func _position_activity_start_highlight_border(
	highlight: _StartHighlightRing,
	card_root: Control,
	overlay_parent: Control
) -> void:
	var glow_extent := _activity_start_highlight_glow_extent()
	var card_rect := card_root.get_global_rect()
	var parent_rect := overlay_parent.get_global_rect()
	highlight.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	highlight.position = card_rect.position - parent_rect.position - Vector2(glow_extent, glow_extent)
	highlight.size = card_rect.size + Vector2(glow_extent * 2.0, glow_extent * 2.0)
	highlight.outer_pad = glow_extent
	highlight.queue_redraw()


func _sync_activity_start_highlight_position() -> void:
	if not activity_start_highlight_active:
		return
	if activity_start_highlight_border == null or not is_instance_valid(activity_start_highlight_border):
		return
	if activity_start_highlight_card_key.is_empty() or not host.action_cards.has(activity_start_highlight_card_key):
		return
	var card := host.action_cards[activity_start_highlight_card_key] as Dictionary
	var card_root := card.get("root") as Control
	var overlay_parent := activity_start_highlight_border.get_parent() as Control
	if card_root == null or not is_instance_valid(card_root) or overlay_parent == null:
		return
	_position_activity_start_highlight_border(
		activity_start_highlight_border as _StartHighlightRing,
		card_root,
		overlay_parent
	)


func _attach_activity_start_highlight_border(card: Dictionary) -> void:
	_remove_activity_start_highlight_border_node()
	var card_root := card.get("root") as Control
	if card_root == null or not is_instance_valid(card_root):
		return
	var overlay_parent := _activity_start_highlight_overlay_parent()
	if overlay_parent == null:
		return
	_begin_activity_start_highlight_frame_clip_override()
	var highlight := _StartHighlightRing.new()
	highlight.name = "ActivityStartHighlightBorder"
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.z_index = 280
	highlight.z_as_relative = false
	highlight.corner_radius = 66.0
	highlight.gap = ACTIVITY_START_HIGHLIGHT_GAP
	highlight.ring_thickness = ACTIVITY_START_HIGHLIGHT_RING_THICKNESS
	highlight.blur_spread = ACTIVITY_START_HIGHLIGHT_BLUR_SPREAD
	highlight.blur_layers = ACTIVITY_START_HIGHLIGHT_BLUR_LAYERS
	highlight.set_glow_alpha(0.0)
	overlay_parent.add_child(highlight)
	_position_activity_start_highlight_border(highlight, card_root, overlay_parent)
	activity_start_highlight_border = highlight


func _remove_activity_start_highlight_border_node() -> void:
	if activity_start_highlight_border != null and is_instance_valid(activity_start_highlight_border):
		activity_start_highlight_border.queue_free()
	activity_start_highlight_border = null
	activity_start_highlight_card_key = ""
	_restore_activity_start_highlight_frame_clip()


func _fade_out_activity_start_highlight() -> void:
	if activity_start_highlight_border == null or not is_instance_valid(activity_start_highlight_border):
		_remove_activity_start_highlight_border_node()
		activity_start_highlight_active = false
		activity_start_highlight_pending = false
		return
	activity_start_highlight_active = false
	activity_start_highlight_pending = false
	var border := activity_start_highlight_border
	activity_start_highlight_border = null
	activity_start_highlight_card_key = ""
	if activity_start_highlight_fade_tween != null:
		activity_start_highlight_fade_tween.kill()
	activity_start_highlight_fade_tween = host.create_tween()
	activity_start_highlight_fade_tween.tween_method(
		border.set_glow_alpha,
		border.modulate.a,
		0.0,
		ACTIVITY_START_HIGHLIGHT_FADE_OUT_SECONDS
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	activity_start_highlight_fade_tween.tween_callback(_finish_activity_start_highlight_fade.bind(border.get_instance_id()))


func _dismiss_activity_start_highlight(instant := false) -> void:
	activity_start_highlight_token += 1
	activity_start_highlight_pending = false
	activity_start_highlight_active = false
	if activity_start_highlight_fade_tween != null:
		activity_start_highlight_fade_tween.kill()
	activity_start_highlight_fade_tween = null
	if activity_start_highlight_border == null or not is_instance_valid(activity_start_highlight_border):
		activity_start_highlight_border = null
		activity_start_highlight_card_key = ""
		return
	if instant:
		_remove_activity_start_highlight_border_node()
	else:
		_fade_out_activity_start_highlight()


func _finish_activity_start_highlight_fade(border_id: int) -> void:
	var border: Node = host._app_lifecycle_runtime().valid_node_ref(instance_from_id(border_id))
	if border != null:
		border.queue_free()
	_restore_activity_start_highlight_frame_clip()


func _on_activity_start_tutorial_card_tapped(skill_id: String, action_id: String) -> void:
	if host._onboarding_runtime().activity_start_tip_seen:
		return
	if skill_id != host.TUTORIAL_STARTER_SKILL_ID or action_id != host.TUTORIAL_STARTER_ACTION_ID:
		return
	if activity_start_highlight_pending:
		activity_start_highlight_pending = false
		activity_start_highlight_token += 1
		return
	if activity_start_highlight_active:
		_fade_out_activity_start_highlight()


func _show_lock_click_tip_note_if_needed() -> void:
	if not host._onboarding_runtime()._skill_detail_shows_tutorial_tips():
		return
	if host.current_screen != "skill" or host._skill_detail_surface().detail_actions_scroll == null or host._onboarding_runtime().lock_click_tip_seen:
		return
	if not host.get_tree().get_nodes_in_group("lock_click_tip_notes").is_empty():
		return
	var stack := host._skill_detail_surface()._detail_actions_stack() as VBoxContainer
	if stack == null:
		return
	for action in host._activity_unlock_runtime()._visible_actions_for_skill(host.selected_skill_id):
		var action_data := action as Dictionary
		if not host._skill_detail_surface()._should_show_lock_click_tip(host.selected_skill_id, action_data):
			continue
		var action_id := str(action_data.get("id", ""))
		if action_id.is_empty() or not host._skill_detail_surface().detail_action_card_nodes.has(action_id):
			continue
		var card_node := host._skill_detail_surface().detail_action_card_nodes[action_id] as Control
		if card_node == null or not is_instance_valid(card_node):
			continue
		var card_key: String = host._action_key(host.selected_skill_id, action_id)
		var card := host.action_cards.get(card_key, {}) as Dictionary
		var lock_overlay := card.get("lock_overlay", {}) as Dictionary
		var lock_target: Control = host._app_lifecycle_runtime().valid_control_ref(lock_overlay.get("group"))
		var note := _bottom_tutorial_tip_note(host._skill_content_width(), "Tap to unlock", "lock_click_tip_notes", lock_target)
		note.modulate = Color(1, 1, 1, 0)
		stack.add_child(note)
		stack.move_child(note, clampi(card_node.get_index() + 1, 0, stack.get_child_count() - 1))
		var tween: Tween = host.create_tween()
		tween.tween_property(note, "modulate:a", 1.0, host.TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		return


func _bottom_tutorial_tip_note(content_width: float, text: String, group_name: String, target: Control = null) -> Control:
	var root: Control = Control.new()
	root.custom_minimum_size = Vector2(content_width, 0.0)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_to_group(group_name)
	root.visible = false
	call_deferred("show_blocking_tip", text, group_name, target)
	return root


func _stamina_gauge_tip_label_position() -> Vector2:
	if (
		host._skill_detail_surface().detail_regen_circle != null
		and is_instance_valid(host._skill_detail_surface().detail_regen_circle)
		and host._skill_detail_surface().detail_header_body != null
		and is_instance_valid(host._skill_detail_surface().detail_header_body)
	):
		var circle_rect: Rect2 = host._skill_detail_surface().detail_regen_circle.get_global_rect()
		var body_rect: Rect2 = host._skill_detail_surface().detail_header_body.get_global_rect()
		var label_width: float = host.ONBOARDING_STAMINA_TIP_LABEL_WIDTH
		var gap := 16.0
		var local_x := circle_rect.position.x - body_rect.position.x - label_width - gap
		var local_y := circle_rect.position.y - body_rect.position.y - 52.0
		return Vector2(local_x, local_y)
	return Vector2(620, 520)


func _add_stamina_cost_tip(parent: Control, fade_in := false) -> void:
	host.stamina_gauge_tip_root = null
	if not host._onboarding_runtime()._skill_detail_shows_tutorial_tips():
		return
	var root: Control = Control.new()
	root.custom_minimum_size = Vector2.ZERO
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	root.z_index = 64
	root.add_to_group("stamina_cost_tip_notes")
	parent.add_child(root)
	host.stamina_gauge_tip_root = root
	call_deferred("show_blocking_tip", "This is your fight stamina.", "stamina_cost_tip_notes", host._skill_detail_surface().detail_regen_circle)


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
	var runtime = host._onboarding_runtime()
	if not runtime._onboarding_fight_header_sequence_active():
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
		return
	var summary_visible: bool = runtime.onboarding_fight_summary_revealed
	var stamina_visible: bool = runtime.onboarding_fight_stamina_revealed
	if host._skill_detail_surface().detail_header_left_block != null and is_instance_valid(host._skill_detail_surface().detail_header_left_block):
		host._skill_detail_surface().detail_header_left_block.modulate = Color(1, 1, 1, 1.0 if summary_visible else 0.0)
	var regen_fade_target := _detail_regen_circle_fade_target()
	if regen_fade_target != null:
		regen_fade_target.modulate = Color(1, 1, 1, 1.0 if stamina_visible else 0.0)
	if host._skill_detail_surface().detail_regen_circle != null and is_instance_valid(host._skill_detail_surface().detail_regen_circle):
		host._skill_detail_surface().detail_regen_circle.modulate = Color.WHITE
		host._skill_detail_surface().detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP if stamina_visible else Control.MOUSE_FILTER_IGNORE
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


func _fade_onboarding_header_control(control: CanvasItem, target_alpha: float, duration: float):
	if control == null or not is_instance_valid(control):
		return
	var control_id := control.get_instance_id()
	var tween: Tween = host.create_tween()
	tween.tween_method(
		host._app_lifecycle_runtime().set_canvas_item_alpha_safe.bind(control_id),
		control.modulate.a,
		target_alpha,
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await host.get_tree().create_timer(maxf(0.0, duration)).timeout


func _clear_onboarding_auto_run_message(instant := false) -> void:
	if onboarding_auto_run_message_root == null or not is_instance_valid(onboarding_auto_run_message_root):
		onboarding_auto_run_message_root = null
		return
	var root := onboarding_auto_run_message_root
	onboarding_auto_run_message_root = null
	if instant:
		root.queue_free()
	else:
		_fade_tip_control(root)


func _wait_for_detail_lazy_stack(token: int, attempt := 0):
	if host._skill_detail_surface()._resolve_detail_lazy_stack() != null:
		return
	if attempt >= 45 or token != host._onboarding_runtime().onboarding_header_sequence_token:
		return
	await host.get_tree().process_frame
	_wait_for_detail_lazy_stack(token, attempt + 1)


func _show_onboarding_auto_run_message(token: int):
	if token != host._onboarding_runtime().onboarding_header_sequence_token:
		return
	_clear_onboarding_auto_run_message(true)
	await _wait_for_detail_lazy_stack(token)
	if token != host._onboarding_runtime().onboarding_header_sequence_token:
		return
	var stack: VBoxContainer = host._skill_detail_surface()._resolve_detail_lazy_stack()
	if stack == null:
		return
	var content_width: float = host._skill_content_width()
	var actions_width: float = content_width
	var note := _bottom_tutorial_tip_note(
		content_width,
		"Your action will continue to run automatically.",
		"onboarding_auto_run_tip_notes"
	)
	var entry: Control = host._skill_detail_surface()._detail_eager_add_tutorial_note_after_action(host.TUTORIAL_STARTER_ACTION_ID, note, content_width, actions_width)
	onboarding_auto_run_message_root = entry if entry != null else note
	onboarding_auto_run_message_root.modulate = Color(1, 1, 1, 0)
	await _fade_onboarding_header_control(onboarding_auto_run_message_root, 1.0, host.ACTIVITY_START_TIP_FADE_SECONDS)


func _onboarding_fight_action_stats_should_hide() -> bool:
	return false


func _finish_onboarding_regen_intro_fill(circle_id: int, fill_target: float) -> void:
	var circle = instance_from_id(circle_id)
	if circle == null or not is_instance_valid(circle):
		return
	circle.intro_fill_lock = false
	circle.target_value = fill_target
	circle.value_initialized = true
	circle.set_process(true)


func _onboarding_fight_action_stats_targets() -> Array[Control]:
	var targets: Array[Control] = []
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card: Dictionary = host.action_cards[key]
		if str(card.get("skill_id", "")) != host.TUTORIAL_STARTER_SKILL_ID:
			continue
		var stat_row := _valid_card_control(card, "stat_row")
		if stat_row != null:
			targets.append(stat_row)
		var mastery_bar := _valid_card_control(card, "mastery")
		if mastery_bar != null and mastery_bar.visible:
			targets.append(mastery_bar)
	return targets


func _valid_card_control(card: Dictionary, key: String) -> Control:
	return host._app_lifecycle_runtime().valid_control_ref(card.get(key, null))


func _apply_onboarding_fight_action_card_stats_visibility(card: Dictionary, skill_id: String = "") -> void:
	if skill_id.is_empty():
		skill_id = str(card.get("skill_id", ""))
	if skill_id != host.TUTORIAL_STARTER_SKILL_ID:
		return
	var should_hide_stats := _onboarding_fight_action_stats_should_hide()
	var alpha := 0.0 if should_hide_stats else 1.0
	var stat_row := _valid_card_control(card, "stat_row")
	if stat_row != null:
		stat_row.modulate = Color(1, 1, 1, alpha)
	host._skill_detail_surface()._sync_action_stat_box_input_enabled(card, not should_hide_stats)
	var mastery_bar := _valid_card_control(card, "mastery")
	if mastery_bar != null:
		mastery_bar.modulate = Color(1, 1, 1, alpha)


func _apply_onboarding_fight_action_stats_visibility_all() -> void:
	var runtime = host._onboarding_runtime()
	if runtime.onboarding_fight_action_stats_fade_running:
		return
	if not runtime._onboarding_path_active():
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
		remove_onboarding_mastery_tip()
		remove_onboarding_medal_tip()
		remove_onboarding_swipe_overlay_tip()
		remove_onboarding_level_up_tip()
		return
	if not runtime._onboarding_fight_header_sequence_active() and not runtime.onboarding_fight_action_stats_revealed:
		return
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card: Dictionary = host.action_cards[key]
		if str(card.get("skill_id", "")) != host.TUTORIAL_STARTER_SKILL_ID:
			continue
		_apply_onboarding_fight_action_card_stats_visibility(card, host.TUTORIAL_STARTER_SKILL_ID)
	if onboarding_mastery_tip_root != null and is_instance_valid(onboarding_mastery_tip_root) and not onboarding_mastery_tip_dismissed:
		var mastery_alpha := 0.0 if _onboarding_fight_action_stats_should_hide() else 1.0
		if runtime.onboarding_fight_action_stats_revealed:
			mastery_alpha = 1.0
		onboarding_mastery_tip_root.modulate = Color(1, 1, 1, mastery_alpha)


func _fade_onboarding_fight_action_stats_in(token: int):
	var runtime = host._onboarding_runtime()
	if runtime.onboarding_fight_action_stats_revealed or runtime.onboarding_fight_action_stats_fade_running:
		return
	var mastery_tip: Control = ensure_onboarding_mastery_tip_note()
	var targets := _onboarding_fight_action_stats_targets()
	if targets.is_empty() and mastery_tip == null:
		runtime.onboarding_fight_action_stats_revealed = true
		host.save_game()
		return
	for target in targets:
		if target != null and is_instance_valid(target):
			target.modulate.a = 0.0
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if host.action_cards.has(key):
			var card: Dictionary = host.action_cards[key]
			if str(card.get("skill_id", "")) == host.TUTORIAL_STARTER_SKILL_ID:
				host._skill_detail_surface()._sync_action_stat_box_input_enabled(card, false)
	if mastery_tip != null and is_instance_valid(mastery_tip):
		mastery_tip.modulate.a = 0.0
		sync_onboarding_mastery_tip_position()
	runtime.onboarding_fight_action_stats_fade_running = true
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		tween.tween_method(
			host._app_lifecycle_runtime().set_canvas_item_alpha_safe.bind(target.get_instance_id()),
			target.modulate.a,
			1.0,
			host.ONBOARDING_FIGHT_ACTION_STATS_FADE_SECONDS
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if mastery_tip != null and is_instance_valid(mastery_tip):
		tween.tween_method(
			host._app_lifecycle_runtime().set_canvas_item_alpha_safe.bind(mastery_tip.get_instance_id()),
			mastery_tip.modulate.a,
			1.0,
			host.ONBOARDING_FIGHT_ACTION_STATS_FADE_SECONDS
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await host.get_tree().create_timer(host.ONBOARDING_FIGHT_ACTION_STATS_FADE_SECONDS).timeout
	runtime.onboarding_fight_action_stats_fade_running = false
	if token != runtime.onboarding_header_sequence_token:
		return
	runtime.onboarding_fight_action_stats_revealed = true
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if host.action_cards.has(key):
			var card: Dictionary = host.action_cards[key]
			if str(card.get("skill_id", "")) == host.TUTORIAL_STARTER_SKILL_ID:
				host._skill_detail_surface()._sync_action_stat_box_input_enabled(card, true)
	host.save_game()
	runtime.call_deferred("_maybe_trigger_onboarding_swipe_tip_at_zero_stamina", host.TUTORIAL_STARTER_SKILL_ID)
