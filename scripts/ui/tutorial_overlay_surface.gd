extends RefCounted

const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")

var host
var tutorial_layer: CanvasLayer
var tutorial_overlay: Control
var tutorial_panel: PanelContainer
var tutorial_target_ring: Panel
var tutorial_target_label: Label
var tutorial_title_label: Label
var tutorial_body_label: Label
var tutorial_step_label: Label
var tutorial_skip_button: Button
var onboarding_auto_run_message_root: Control

func _init(host_ref) -> void:
	host = host_ref

func build() -> void:
	tutorial_layer = CanvasLayer.new()
	tutorial_layer.layer = host.TUTORIAL_LAYER
	host.tutorial_layer = tutorial_layer
	host.add_child(tutorial_layer)

	tutorial_overlay = Control.new()
	tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.visible = false
	tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	var panel := PanelContainer.new()
	tutorial_panel = panel
	host.tutorial_panel = tutorial_panel
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -900
	panel.offset_right = 900
	panel.offset_top = -host.BOTTOM_NAV_HEIGHT - host.TUTORIAL_PANEL_BODY_HEIGHT
	panel.offset_bottom = -host.BOTTOM_NAV_HEIGHT - host.TUTORIAL_PANEL_BOTTOM_GAP
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", host._surface_style(host.COLOR_PANEL, 52, 46, true))
	panel.z_index = 20
	tutorial_overlay.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 20)
	panel.add_child(stack)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 24)
	stack.add_child(header)

	tutorial_step_label = host._label("", host.MIN_MOBILE_BODY_FONT_SIZE, host.COLOR_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	tutorial_step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.tutorial_step_label = tutorial_step_label
	header.add_child(tutorial_step_label)

	tutorial_skip_button = host._menu_button("Skip")
	tutorial_skip_button.custom_minimum_size = Vector2(260, 118)
	tutorial_skip_button.add_theme_font_size_override("font_size", 50)
	tutorial_skip_button.mouse_filter = Control.MOUSE_FILTER_STOP
	tutorial_skip_button.pressed.connect(Callable(host._onboarding_runtime(), "_on_tutorial_action_button_pressed"))
	host.tutorial_skip_button = tutorial_skip_button
	header.add_child(tutorial_skip_button)

	tutorial_title_label = host._label("", 74, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	if host.app_bold_font != null:
		tutorial_title_label.add_theme_font_override("font", host.app_bold_font)
	host.tutorial_title_label = tutorial_title_label
	stack.add_child(tutorial_title_label)

	tutorial_body_label = host._label("", 58, host.COLOR_INK, HORIZONTAL_ALIGNMENT_LEFT)
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.tutorial_body_label = tutorial_body_label
	stack.add_child(tutorial_body_label)


func _route_tutorial_panel_input(event: InputEvent) -> bool:
	if not host.tutorial_active:
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
	if is_press and _tutorial_target_press_advances(event_position):
		host._onboarding_runtime()._activate_tutorial_target()
		return true
	return (
		tutorial_panel != null
		and is_instance_valid(tutorial_panel)
		and tutorial_panel.visible
		and (is_press or is_release)
		and tutorial_panel.get_global_rect().has_point(event_position)
	)


func _on_tutorial_overlay_gui_input(event: InputEvent) -> void:
	if _route_tutorial_panel_input(event):
		tutorial_overlay.accept_event()


func _tutorial_target_press_advances(event_position: Vector2) -> bool:
	if not host.tutorial_step in [1, 2]:
		return false
	var target := _tutorial_target_control()
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	return target.get_global_rect().grow(36.0).has_point(event_position)


func _update_tutorial_overlay() -> void:
	if tutorial_overlay == null:
		return
	host._set_canvas_item_visible_if_changed(tutorial_overlay, host.tutorial_active)
	if tutorial_panel != null and is_instance_valid(tutorial_panel):
		host._set_canvas_item_visible_if_changed(tutorial_panel, false)
	if not host.tutorial_active:
		return
	_sync_tutorial_target_indicator()


func _sync_tutorial_target_indicator() -> void:
	_hide_tutorial_target_indicator()


func _hide_tutorial_target_indicator() -> void:
	if tutorial_target_ring != null:
		host._set_canvas_item_visible_if_changed(tutorial_target_ring, false)
	if tutorial_target_label != null:
		host._set_canvas_item_visible_if_changed(tutorial_target_label, false)


func _tutorial_target_control() -> Control:
	match host.tutorial_step:
		0:
			if host.current_screen != "menu":
				return host.skills_tab
			var skill_id := _tutorial_target_skill_id()
			var card := host.skill_cards.get(skill_id, {}) as Dictionary
			return host._valid_control_ref(card.get("button"))
		1:
			if host.current_screen != "skill":
				return null
			var action_id := _tutorial_target_action_id()
			var key: String = host._action_key(host.selected_skill_id, action_id)
			if host.action_cards.has(key):
				var card := host.action_cards[key] as Dictionary
				var pop: Control = host._valid_control_ref(card.get("pop"))
				if pop != null:
					return pop
				return host._valid_control_ref(card.get("button"))
		2:
			if host.current_screen != "skill":
				return null
			var key: String = host._action_key(host.running_skill_id, host.running_action_id)
			if host.action_cards.has(key):
				var card := host.action_cards[key] as Dictionary
				var mastery_bar: Control = host._valid_control_ref(card.get("mastery"))
				if mastery_bar != null:
					return mastery_bar
			for action in host._visible_actions_for_skill(host.selected_skill_id):
				var action_dict := action as Dictionary
				if not host._is_action_unlocked(host.selected_skill_id, action_dict):
					continue
				key = host._action_key(host.selected_skill_id, str(action_dict.get("id", "")))
				if not host.action_cards.has(key):
					continue
				var card := host.action_cards[key] as Dictionary
				var mastery_bar: Control = host._valid_control_ref(card.get("mastery"))
				if mastery_bar != null:
					return mastery_bar
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
	if host.selected_skill_id == host.TUTORIAL_STARTER_SKILL_ID and not starter_action.is_empty() and host._is_action_unlocked(host.selected_skill_id, starter_action):
		return host.TUTORIAL_STARTER_ACTION_ID
	for action in host._visible_actions_for_skill(host.selected_skill_id):
		var action_dict := action as Dictionary
		if host._is_action_unlocked(host.selected_skill_id, action_dict):
			return str(action_dict.get("id", ""))
	return ""


func _create_onboarding_overlay_tip(text: String, group_name: String, font_size := -1) -> Control:
	if font_size < 0:
		font_size = host.ONBOARDING_OVERLAY_TIP_FONT_SIZE
	var root: Control = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 270
	root.z_as_relative = false
	root.add_to_group(group_name)
	var label: Label = host._label(text, font_size, Color("#4b3828"), HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_outline_color", Color("#fff4ce"))
	label.add_theme_constant_override("outline_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var content_width := maxf(320.0, host._skill_content_width() - host.ACTION_CARD_POP_GUTTER * 2.0)
	label.custom_minimum_size = Vector2(content_width, 0.0)
	label.size = label.get_minimum_size()
	root.add_child(label)
	root.custom_minimum_size = label.size
	root.size = label.size
	return root


func _position_onboarding_overlay_tip_above_card(tip: Control, card_root: Control, gap_px: float) -> void:
	if tip == null or card_root == null or not is_instance_valid(tip) or not is_instance_valid(card_root):
		return
	var overlay_parent: Control = host._onboarding_detail_overlay_parent()
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
	var overlay_parent: Control = host._onboarding_detail_overlay_parent()
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
	if tip == null or not is_instance_valid(tip) or host.detail_actions_scroll == null or not is_instance_valid(host.detail_actions_scroll):
		return
	var overlay_parent: Control = host._onboarding_detail_overlay_parent()
	if overlay_parent == null:
		return
	var detail_rect: Rect2 = host.detail_actions_scroll.get_global_rect()
	var parent_rect := overlay_parent.get_global_rect()
	var tip_size := tip.size
	if tip_size.y <= 1.0:
		tip_size = tip.get_combined_minimum_size()
	var x := detail_rect.position.x - parent_rect.position.x + (detail_rect.size.x - tip_size.x) * 0.5
	var y := detail_rect.position.y - parent_rect.position.y + detail_rect.size.y - tip_size.y - bottom_gap_px
	tip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tip.position = Vector2(x, y)
	tip.size = tip_size


func _bottom_tutorial_tip_note(content_width: float, text: String, group_name: String) -> Control:
	var root: Control = Control.new()
	root.custom_minimum_size = Vector2(content_width, 174)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_to_group(group_name)

	var label: Label = host._label(text, host.BOTTOM_TUTORIAL_TIP_FONT_SIZE, Color("#4b3828"), HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = host.ACTION_CARD_POP_GUTTER
	label.offset_right = -host.ACTION_CARD_POP_GUTTER
	label.add_theme_color_override("font_outline_color", Color("#fff4ce"))
	label.add_theme_constant_override("outline_size", 10)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(label)
	return root


func _stamina_gauge_tip_label_position() -> Vector2:
	if (
		host.detail_regen_circle != null
		and is_instance_valid(host.detail_regen_circle)
		and host.detail_header_body != null
		and is_instance_valid(host.detail_header_body)
	):
		var circle_rect: Rect2 = host.detail_regen_circle.get_global_rect()
		var body_rect: Rect2 = host.detail_header_body.get_global_rect()
		var label_width: float = host.ONBOARDING_STAMINA_TIP_LABEL_WIDTH
		var gap := 16.0
		var local_x := circle_rect.position.x - body_rect.position.x - label_width - gap
		var local_y := circle_rect.position.y - body_rect.position.y - 52.0
		return Vector2(local_x, local_y)
	return Vector2(620, 520)


func _add_stamina_cost_tip(parent: Control, fade_in := false) -> void:
	host.stamina_gauge_tip_root = null
	if not host._skill_detail_shows_tutorial_tips():
		return
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 64
	root.add_to_group("stamina_cost_tip_notes")
	parent.add_child(root)
	host.stamina_gauge_tip_root = root

	var label: Label = host._label("This is your\nfight stamina.", host.ONBOARDING_STAMINA_TIP_FONT_SIZE, Color("#4b3828"), HORIZONTAL_ALIGNMENT_LEFT)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.position = _stamina_gauge_tip_label_position()
	label.size = Vector2(host.ONBOARDING_STAMINA_TIP_LABEL_WIDTH, 120)
	label.add_theme_constant_override("line_spacing", -4)
	label.add_theme_color_override("font_outline_color", Color("#fff4ce"))
	label.add_theme_constant_override("outline_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 2
	root.add_child(label)
	if fade_in:
		root.modulate = Color(1, 1, 1, 0)
		var tween: Tween = host.create_tween()
		tween.tween_property(root, "modulate:a", 1.0, host.TUTORIAL_TIP_FADE_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _fade_tip_control(control: Control, preserve_layout := false, collapse_layout := false) -> void:
	if control == null or not is_instance_valid(control):
		return
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if collapse_layout:
		control.clip_contents = true
	var tween: Tween = host.create_tween()
	if collapse_layout:
		tween.set_parallel(true)
	tween.tween_property(control, "modulate:a", 0.0, host.TUTORIAL_TIP_FADE_OUT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if collapse_layout:
		tween.tween_property(control, "custom_minimum_size:y", 0.0, host.TUTORIAL_TIP_FADE_OUT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.set_parallel(false)
	if not preserve_layout:
		tween.tween_callback(host._queue_free_instance_id.bind(control.get_instance_id()))


func _fade_tip_group(group_name: String, preserve_layout := false, collapse_layout := false) -> bool:
	var had_tip := false
	for node in host.get_tree().get_nodes_in_group(group_name):
		had_tip = true
		_fade_tip_control(node as Control, preserve_layout, collapse_layout)
	return had_tip


func _apply_onboarding_fight_header_visibility() -> void:
	var runtime = host._onboarding_runtime()
	if not runtime._onboarding_fight_header_sequence_active():
		if host.detail_header_left_block != null and is_instance_valid(host.detail_header_left_block):
			host.detail_header_left_block.modulate = Color.WHITE
		if host.detail_regen_circle != null and is_instance_valid(host.detail_regen_circle):
			host.detail_regen_circle.modulate = Color.WHITE
			host.detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP
		if host.detail_regen_circle_fade_group != null and is_instance_valid(host.detail_regen_circle_fade_group):
			host.detail_regen_circle_fade_group.modulate = Color.WHITE
		if host.detail_regen_circle_host != null and is_instance_valid(host.detail_regen_circle_host):
			host.detail_regen_circle_host.modulate = Color.WHITE
		_apply_tutorial_starter_intro_header_visibility()
		return
	var summary_visible: bool = runtime.onboarding_fight_summary_revealed
	var stamina_visible: bool = runtime.onboarding_fight_stamina_revealed
	if host.detail_header_left_block != null and is_instance_valid(host.detail_header_left_block):
		host.detail_header_left_block.modulate = Color(1, 1, 1, 1.0 if summary_visible else 0.0)
	var regen_fade_target := _detail_regen_circle_fade_target()
	if regen_fade_target != null:
		regen_fade_target.modulate = Color(1, 1, 1, 1.0 if stamina_visible else 0.0)
	if host.detail_regen_circle != null and is_instance_valid(host.detail_regen_circle):
		host.detail_regen_circle.modulate = Color.WHITE
		host.detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_STOP if stamina_visible else Control.MOUSE_FILTER_IGNORE
	_apply_tutorial_starter_intro_header_visibility()


func _apply_tutorial_starter_intro_header_visibility() -> void:
	var intro_active: bool = host._onboarding_runtime()._tutorial_starter_only_detail_active(host.selected_skill_id)
	if host.detail_header_left_block != null and is_instance_valid(host.detail_header_left_block):
		host.detail_header_left_block.visible = not intro_active
	if host.detail_xp_label != null and is_instance_valid(host.detail_xp_label):
		host.detail_xp_label.visible = not intro_active
	if host.detail_xp_bar != null and is_instance_valid(host.detail_xp_bar):
		host.detail_xp_bar.visible = not intro_active
	if not intro_active:
		return
	var regen_fade_target := _detail_regen_circle_fade_target()
	if regen_fade_target != null:
		regen_fade_target.modulate = Color(1, 1, 1, 0.0)
	if host.detail_regen_circle_host != null and is_instance_valid(host.detail_regen_circle_host):
		host.detail_regen_circle_host.modulate = Color(1, 1, 1, 0.0)
	if host.detail_regen_circle != null and is_instance_valid(host.detail_regen_circle):
		host.detail_regen_circle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_tip_group("stamina_cost_tip_notes")
	if host.stamina_gauge_tip_root != null and is_instance_valid(host.stamina_gauge_tip_root):
		host.stamina_gauge_tip_root.queue_free()
	host.stamina_gauge_tip_root = null


func _detail_regen_circle_fade_target() -> CanvasItem:
	if host.detail_regen_circle_fade_group != null and is_instance_valid(host.detail_regen_circle_fade_group):
		return host.detail_regen_circle_fade_group
	return host.detail_regen_circle


func _fade_onboarding_header_control(control: CanvasItem, target_alpha: float, duration: float):
	if control == null or not is_instance_valid(control):
		return
	var control_id := control.get_instance_id()
	var tween: Tween = host.create_tween()
	tween.tween_method(
		host._set_canvas_item_alpha_safe.bind(control_id),
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
	if host._resolve_detail_lazy_stack() != null:
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
	var stack: VBoxContainer = host._resolve_detail_lazy_stack()
	if stack == null:
		return
	var content_width: float = host._skill_content_width()
	var actions_width: float = content_width
	var note := _bottom_tutorial_tip_note(
		content_width,
		"Your action will continue to run automatically.",
		"onboarding_auto_run_tip_notes"
	)
	var entry: Control = host._detail_eager_add_tutorial_note_after_action(host.TUTORIAL_STARTER_ACTION_ID, note, content_width, actions_width)
	onboarding_auto_run_message_root = entry if entry != null else note
	onboarding_auto_run_message_root.modulate = Color(1, 1, 1, 0)
	await _fade_onboarding_header_control(onboarding_auto_run_message_root, 1.0, host.ACTIVITY_START_TIP_FADE_SECONDS)


func _onboarding_fight_action_stats_should_hide() -> bool:
	return (
		host._onboarding_runtime()._onboarding_fight_header_sequence_active()
		and not host._onboarding_runtime().onboarding_fight_action_stats_revealed
	)


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
	return host._valid_control_ref(card.get(key, null))


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
	host._sync_action_stat_box_input_enabled(card, not should_hide_stats)
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
				host._sync_action_stat_box_input_enabled(card, true)
			var mastery_bar := _valid_card_control(card, "mastery")
			if mastery_bar != null:
				mastery_bar.modulate = Color.WHITE
		host._remove_onboarding_mastery_tip()
		host._remove_onboarding_medal_tip()
		host._remove_onboarding_swipe_overlay_tip()
		host._remove_onboarding_level_up_tip()
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
	if host.onboarding_mastery_tip_root != null and is_instance_valid(host.onboarding_mastery_tip_root) and not host.onboarding_mastery_tip_dismissed:
		var mastery_alpha := 0.0 if _onboarding_fight_action_stats_should_hide() else 1.0
		if runtime.onboarding_fight_action_stats_revealed:
			mastery_alpha = 1.0
		host.onboarding_mastery_tip_root.modulate = Color(1, 1, 1, mastery_alpha)


func _fade_onboarding_fight_action_stats_in(token: int):
	var runtime = host._onboarding_runtime()
	if runtime.onboarding_fight_action_stats_revealed or runtime.onboarding_fight_action_stats_fade_running:
		return
	var mastery_tip: Control = host._ensure_onboarding_mastery_tip_note()
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
				host._sync_action_stat_box_input_enabled(card, false)
	if mastery_tip != null and is_instance_valid(mastery_tip):
		mastery_tip.modulate.a = 0.0
		host._sync_onboarding_mastery_tip_position()
	runtime.onboarding_fight_action_stats_fade_running = true
	var tween: Tween = host.create_tween()
	tween.set_parallel(true)
	for target in targets:
		if target == null or not is_instance_valid(target):
			continue
		tween.tween_method(
			host._set_canvas_item_alpha_safe.bind(target.get_instance_id()),
			target.modulate.a,
			1.0,
			host.ONBOARDING_FIGHT_ACTION_STATS_FADE_SECONDS
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if mastery_tip != null and is_instance_valid(mastery_tip):
		tween.tween_method(
			host._set_canvas_item_alpha_safe.bind(mastery_tip.get_instance_id()),
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
				host._sync_action_stat_box_input_enabled(card, true)
	host.save_game()
	runtime.call_deferred("_maybe_trigger_onboarding_swipe_tip_at_zero_stamina", host.TUTORIAL_STARTER_SKILL_ID)
