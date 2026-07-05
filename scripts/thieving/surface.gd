extends Node

const ButtonPressState = preload("res://scripts/ui/button_press_state.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const RewardFeedbackSurface = preload("res://scripts/ui/reward_feedback_surface.gd")
const ThievingState = preload("res://scripts/thieving/state.gd")

const THIEVING_HEIST_CARD_HEIGHT := 880.0
const THIEVING_HEIST_BACKGROUND_SHEET := ThievingState.HEIST_BACKGROUND_SHEET
const THIEVING_HEIST_TROPHY_SHEET := ThievingState.HEIST_TROPHY_SHEET
const THIEVING_HEIST_JAIL_BARS_TEXTURE := ThievingState.HEIST_JAIL_BARS_TEXTURE
const THIEVING_HEIST_BACKGROUND_CELL := ThievingState.HEIST_BACKGROUND_CELL
const THIEVING_HEIST_TROPHY_CELL := ThievingState.HEIST_TROPHY_CELL
const THIEVING_HEIST_HORIZONTAL_BLEED := 0.0
const THIEVING_HEIST_UI_SAFE_INSET := 228.0
const THIEVING_HEIST_LEVEL_SUCCESS_BONUS := ThievingState.HEIST_LEVEL_SUCCESS_BONUS
const THIEVING_HEIST_MAX_SUCCESS := ThievingState.HEIST_MAX_SUCCESS
const THIEVING_ACTION_JAIL_BASE_SECONDS := ThievingState.ACTION_JAIL_BASE_SECONDS
const THIEVING_ACTION_JAIL_SECONDS_PER_UNLOCK_LEVEL := ThievingState.ACTION_JAIL_SECONDS_PER_UNLOCK_LEVEL
const THIEVING_ACTION_JAIL_MIN_SECONDS := ThievingState.ACTION_JAIL_MIN_SECONDS

var host: Node

var THIEVING_JAIL_SECONDS_BY_LEVEL:
	get: return host.THIEVING_JAIL_SECONDS_BY_LEVEL
var MODULE_TITLE_OVER_PIN_Z_INDEX: int:
	get: return host.MODULE_TITLE_OVER_PIN_Z_INDEX
var COLOR_INK:
	get: return host.COLOR_INK
var COLOR_GOLD:
	get: return host.COLOR_GOLD
var PASSIVE_BUTTON_TAP_RELEASE_SLOP: float:
	get: return host.PASSIVE_BUTTON_TAP_RELEASE_SLOP
var BOTTOM_NAV_HEIGHT: float:
	get: return NavigationShell.BOTTOM_NAV_HEIGHT
var REWARD_FLOAT_Z: int:
	get: return RewardFeedbackSurface.REWARD_FLOAT_Z
var TAU: float:
	get: return PI * 2.0

var detail_action_card_nodes:
	get: return host._skill_detail_surface().detail_action_card_nodes
var action_cards:
	get: return host.action_cards
var activity_unlock_heist_preview_after_ceremony_id:
	get: return host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id
	set(value): host._activity_unlock_ceremony_surface().heist_preview_after_ceremony_id = value
var thieving_heist_feather_shader: Shader
var current_screen:
	get: return host.current_screen
var selected_skill_id:
	get: return host.selected_skill_id
var skill_swipe_tracking:
	get: return host._skill_swipe_activity_surface().skill_swipe_tracking
var thieving_trophies:
	get: return host.thieving_state.trophies
var skills:
	get: return host.skills
var pending_thieving_trophy_reward_float:
	get: return host.thieving_state.pending_trophy_reward_float
	set(value): host.thieving_state.pending_trophy_reward_float = value
var detail_actions_scroll:
	get: return host._skill_detail_surface().detail_actions_scroll
var content_scroll:
	get: return host.content_scroll
var hub_tab:
	get: return host._navigation_shell().hub_tab
var detail_rendered_action_ids:
	get: return host._skill_detail_surface().detail_rendered_action_ids
var running_skill_id:
	get: return host.running_skill_id
var running_action_id:
	get: return host.running_action_id
var thieving_action_jail_material: ShaderMaterial

func setup(next_host: Node) -> void:
	host = next_host


func card_height() -> float:
	return THIEVING_HEIST_CARD_HEIGHT


func warmup_texture_paths() -> Array:
	return [
		THIEVING_HEIST_BACKGROUND_SHEET,
		THIEVING_HEIST_TROPHY_SHEET,
		THIEVING_HEIST_JAIL_BARS_TEXTURE,
	]


func clear_visual_caches() -> void:
	thieving_heist_feather_shader = null
	thieving_action_jail_material = null

func _missing_host_call(method: String, args: Array = []):
	return host.callv(method, args)
func _build_thieving_heist_card(heist: Dictionary, content_width: float, preview_only := false, card_key_override := "") -> Control:
	var heist_id := str(heist.get("id", ""))
	var card_root := Control.new()
	card_root.custom_minimum_size = Vector2(0, THIEVING_HEIST_CARD_HEIGHT)
	card_root.custom_minimum_size.x = content_width
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false
	detail_action_card_nodes["heist:%s" % heist_id] = card_root

	var pop_card := Control.new()
	pop_card.anchor_left = 0.0
	pop_card.anchor_right = 1.0
	pop_card.anchor_top = 0.0
	pop_card.anchor_bottom = 1.0
	pop_card.offset_left = -THIEVING_HEIST_HORIZONTAL_BLEED
	pop_card.offset_right = THIEVING_HEIST_HORIZONTAL_BLEED
	pop_card.offset_top = 0.0
	pop_card.offset_bottom = 0.0
	pop_card.clip_contents = false
	card_root.add_child(pop_card)

	var bg := TextureRect.new()
	bg.texture = host.visual_texture_cache._spritesheet_or_visual_fallback(THIEVING_HEIST_BACKGROUND_SHEET, int(heist.get("cell", 0)), THIEVING_HEIST_BACKGROUND_CELL)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	pop_card.add_child(bg)

	var shade := Panel.new()
	shade.add_theme_stylebox_override("panel", ActivityCardStyles.cached_shade(0.28))
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = 175
	pop_card.add_child(shade)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", int(THIEVING_HEIST_UI_SAFE_INSET))
	margin.add_theme_constant_override("margin_right", int(THIEVING_HEIST_UI_SAFE_INSET))
	margin.add_theme_constant_override("margin_top", 118)
	margin.add_theme_constant_override("margin_bottom", 118)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.z_index = 210
	pop_card.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	margin.add_child(row)

	var info_column := VBoxContainer.new()
	info_column.custom_minimum_size = Vector2(360, 0)
	info_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	info_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_column.alignment = BoxContainer.ALIGNMENT_CENTER
	info_column.add_theme_constant_override("separation", 30)
	info_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info_column)

	var chance_label := _label("", 68, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	chance_label.add_theme_color_override("font_outline_color", COLOR_INK)
	chance_label.add_theme_constant_override("outline_size", 28)
	chance_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chance_label.custom_minimum_size = Vector2(0, 170)
	info_column.add_child(chance_label)

	var punishment_label := _label("Punishment\n%s jail" % GameFormatting.duration(float(heist.get("cooldown_seconds", 0))), 52, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	punishment_label.add_theme_color_override("font_outline_color", COLOR_INK)
	punishment_label.add_theme_constant_override("outline_size", 22)
	punishment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	punishment_label.custom_minimum_size = Vector2(0, 170)
	info_column.add_child(punishment_label)

	var trophy_panel := Control.new()
	trophy_panel.custom_minimum_size = Vector2(560, 640)
	trophy_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	trophy_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trophy_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(trophy_panel)

	var trophy := TextureRect.new()
	trophy.texture = host.visual_texture_cache._spritesheet_or_visual_fallback(THIEVING_HEIST_TROPHY_SHEET, int(heist.get("cell", 0)), THIEVING_HEIST_TROPHY_CELL)
	trophy.set_anchors_preset(Control.PRESET_FULL_RECT)
	trophy.offset_left = -190
	trophy.offset_right = 190
	trophy.offset_top = -120
	trophy.offset_bottom = 120
	trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trophy.z_index = 1
	trophy_panel.add_child(trophy)

	var state: Dictionary = host.thieving_state.ensure_trophy_state(heist_id)
	var stolen := bool(state.get("stolen", false))
	var cooldown_remaining: int = host.thieving_state.heist_cooldown_remaining(heist_id, _unix_now())
	var can_steal: bool = not stolen and cooldown_remaining <= 0

	var button := _menu_button("STOLEN" if stolen else ("JAILED" if cooldown_remaining > 0 else "STEAL"))
	button.custom_minimum_size = Vector2(360, 430)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 86)
	button.disabled = not can_steal
	button.pressed.connect(_attempt_thieving_heist.bind(heist_id))
	button.gui_input.connect(_on_thieving_heist_button_input.bind(heist_id, button))
	row.add_child(button)

	pop_card.add_child(_thieving_heist_feather_band(true))
	pop_card.add_child(_thieving_heist_feather_band(false))

	var card := {
		"root": card_root,
		"pop": pop_card,
		"button": button,
		"art_panel": trophy_panel,
		"progress": trophy_panel,
		"mastery": null,
		"heist": heist,
		"heist_id": heist_id,
		"trophy": trophy,
		"chance_label": chance_label,
		"jail_overlay": null,
		"jail_label": null,
		"last_stolen": stolen,
		"last_cooldown": cooldown_remaining
	}
	card["preview_only"] = preview_only
	if not preview_only:
		card["module_action_zones"] = _add_module_action_zones(pop_card, ModuleUiRuntime.thieving_heist(heist_id))
		var card_key := card_key_override if not card_key_override.is_empty() else _thieving_heist_card_key(heist_id)
		_register_action_card(card_key, card)
		_stage_thieving_heist_preview_if_pending(card)

	if not preview_only:
		if stolen:
			_add_thieving_heist_completed_stamp(pop_card)
		elif cooldown_remaining > 0:
			_add_thieving_heist_jail_overlay(card, cooldown_remaining)
	_update_thieving_heist_card(card, 0.0, true)
	return card_root



func _on_thieving_heist_button_input(event: InputEvent, heist_id: String, source: Button) -> void:
	if source == null or not is_instance_valid(source) or source.disabled:
		return
	var event_position: Vector2 = host._input_routing_shell()._passive_button_event_position(event, source)
	var event_kind := ButtonPressState.event_kind(event)
	if event_kind == "press":
		if _position_inside_bottom_interactive_ui(event_position) or not _position_inside_detail_actions_viewport(event_position):
			return
		ButtonPressState.begin(source, "thieving_heist", event_position)
		host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
		get_viewport().set_input_as_handled()
		return
	if event_kind == "drag":
		if ButtonPressState.active(source, "thieving_heist") or skill_swipe_tracking:
			ButtonPressState.update_drag(source, "thieving_heist", event_position, -1.0)
			host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
			get_viewport().set_input_as_handled()
		return
	if event_kind == "release":
		var was_active := ButtonPressState.active(source, "thieving_heist")
		if skill_swipe_tracking:
			host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
		var valid_tap := ButtonPressState.finish(source, "thieving_heist", event_position, PASSIVE_BUTTON_TAP_RELEASE_SLOP)
		if (
			was_active
			and valid_tap
			and _position_inside_detail_actions_viewport(event_position)
			and not _skill_swipe_suppresses_button_action()
		):
			_attempt_thieving_heist(heist_id)
		get_viewport().set_input_as_handled()



func _route_thieving_heist_button_global_input(event: InputEvent) -> bool:
	if current_screen != "skill" and current_screen != "pinned":
		return false
	if current_screen == "skill" and selected_skill_id != "thieving":
		return false
	var event_position := Vector2.ZERO
	var is_press := false
	var is_release := false
	var is_motion := false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_event := event as InputEventMouseButton
		event_position = mouse_event.global_position
		is_press = mouse_event.pressed
		is_release = not mouse_event.pressed
	elif event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_motion = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		event_position = touch_event.position
		is_press = touch_event.pressed
		is_release = not touch_event.pressed
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		is_motion = true
	else:
		return false
	var hit := _thieving_heist_button_hit(event_position, is_press)
	if hit.is_empty() and (is_release or is_motion):
		hit = _active_thieving_heist_button_hit()
	if hit.is_empty():
		return false
	var source := hit.get("button", null) as Button
	var heist_id := str(hit.get("heist_id", ""))
	if source == null or not is_instance_valid(source) or heist_id.is_empty():
		return false
	if is_press:
		if not _position_inside_detail_actions_viewport(event_position):
			return false
		ButtonPressState.begin(source, "thieving_heist", event_position)
		host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
		return true
	if is_motion:
		if ButtonPressState.active(source, "thieving_heist") or skill_swipe_tracking:
			ButtonPressState.update_drag(source, "thieving_heist", event_position, -1.0)
			host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
			return true
		return false
	if is_release:
		var was_active := ButtonPressState.active(source, "thieving_heist")
		if skill_swipe_tracking:
			host._skill_swipe_activity_surface()._route_skill_swipe_button_input(event, source)
		var valid_tap := ButtonPressState.finish(source, "thieving_heist", event_position, PASSIVE_BUTTON_TAP_RELEASE_SLOP)
		if (
			was_active
			and valid_tap
			and _position_inside_detail_actions_viewport(event_position)
			and not _skill_swipe_suppresses_button_action()
		):
			_attempt_thieving_heist(heist_id)
		return true
	return true



func _thieving_heist_button_hit(event_position: Vector2, require_contains_point := true) -> Dictionary:
	for hit in _thieving_heist_button_hit_candidates():
		var button := hit.get("button", null) as Button
		if button == null or not is_instance_valid(button) or button.disabled:
			continue
		if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
			continue
		if not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		if require_contains_point and not button.get_global_rect().has_point(event_position):
			continue
		return hit
	return {}



func _active_thieving_heist_button_hit() -> Dictionary:
	for hit in _thieving_heist_button_hit_candidates():
		var button := hit.get("button", null) as Button
		if ButtonPressState.active(button, "thieving_heist"):
			return hit
	return {}



func _thieving_heist_button_hit_candidates() -> Array:
	var hits: Array = []
	for raw_card in action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card := raw_card as Dictionary
		var heist_id := str(card.get("heist_id", ""))
		if heist_id.is_empty():
			continue
		var button := card.get("button", null) as Button
		if button != null:
			hits.append({"heist_id": heist_id, "button": button})
	return hits



func _thieving_heist_card_key(heist_id: String) -> String:
	return "thieving_heist:%s" % heist_id



func _stage_thieving_heist_preview_if_pending(card: Dictionary) -> void:
	var heist_id := str(card.get("heist_id", ""))
	if heist_id.is_empty() or heist_id != activity_unlock_heist_preview_after_ceremony_id:
		return
	var root := _valid_control_ref(card.get("root"))
	var pop := _valid_control_ref(card.get("pop"))
	if root == null or pop == null or root.is_queued_for_deletion() or pop.is_queued_for_deletion():
		return
	var target_height := maxf(float(root.custom_minimum_size.y), THIEVING_HEIST_CARD_HEIGHT)
	card["thieving_heist_reveal_target_height"] = target_height
	card["thieving_heist_reveal_original_root_clip"] = root.clip_contents
	card["thieving_heist_reveal_original_pop_anchor_bottom"] = pop.anchor_bottom
	card["thieving_heist_reveal_original_pop_offset_bottom"] = pop.offset_bottom
	_set_canvas_item_visible_if_changed(root, true)
	_set_canvas_item_modulate_if_changed(root, Color.WHITE)
	root.clip_contents = true
	var collapsed_size := root.custom_minimum_size
	collapsed_size.y = 0.0
	root.custom_minimum_size = collapsed_size
	pop.anchor_top = 0.0
	pop.anchor_bottom = 0.0
	pop.offset_top = 42.0
	pop.offset_bottom = target_height + 42.0
	_set_canvas_item_modulate_if_changed(pop, Color(1, 1, 1, 0))
	call_deferred("_play_thieving_heist_preview_fade_in", heist_id)



func _play_thieving_heist_preview_fade_in(heist_id: String) -> void:
	if heist_id.is_empty() or heist_id != activity_unlock_heist_preview_after_ceremony_id:
		return
	var key := _thieving_heist_card_key(heist_id)
	if not action_cards.has(key):
		activity_unlock_heist_preview_after_ceremony_id = ""
		return
	var card := action_cards[key] as Dictionary
	var root := _valid_control_ref(card.get("root"))
	var pop := _valid_control_ref(card.get("pop"))
	if root == null or pop == null or root.is_queued_for_deletion() or pop.is_queued_for_deletion():
		activity_unlock_heist_preview_after_ceremony_id = ""
		return
	host._app_lifecycle_runtime()._kill_card_tween(card, "preview_fade_tween")
	var target_height := maxf(float(card.get("thieving_heist_reveal_target_height", THIEVING_HEIST_CARD_HEIGHT)), THIEVING_HEIST_CARD_HEIGHT)
	_hold_skill_detail_layout_refresh(1.10)
	var tween := create_tween()
	card["preview_fade_tween"] = tween
	tween.set_parallel(true)
	tween.tween_property(root, "custom_minimum_size:y", target_height, 0.62).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(pop, "modulate:a", 1.0, 0.36).set_delay(0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var pop_id := pop.get_instance_id()
	tween.tween_method(
		_set_thieving_heist_reveal_pop_offset_safe.bind(pop_id, target_height),
		0.0,
		1.0,
		0.54
	).set_delay(0.18).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_thieving_heist_preview_fade_in.bind(heist_id, root.get_instance_id(), pop_id, target_height))



func _set_thieving_heist_reveal_pop_offset(progress: float, pop: Control, target_height: float) -> void:
	if pop == null or not is_instance_valid(pop) or pop.is_queued_for_deletion():
		return
	var offset_y := lerpf(42.0, 0.0, clampf(progress, 0.0, 1.0))
	pop.offset_top = offset_y
	pop.offset_bottom = target_height + offset_y



func _set_thieving_heist_reveal_pop_offset_safe(progress: float, pop_id: int, target_height: float) -> void:
	var pop := _valid_control_ref(instance_from_id(pop_id))
	if pop == null or pop.is_queued_for_deletion():
		return
	_set_thieving_heist_reveal_pop_offset(progress, pop, target_height)



func _finish_thieving_heist_preview_fade_in(heist_id: String, root_id: int, pop_id: int, target_height: float) -> void:
	var key := _thieving_heist_card_key(heist_id)
	var card := action_cards.get(key, {}) as Dictionary
	var cb_root := _valid_control_ref(instance_from_id(root_id))
	var cb_pop := _valid_control_ref(instance_from_id(pop_id))
	if cb_root != null and not cb_root.is_queued_for_deletion():
		var final_size := cb_root.custom_minimum_size
		final_size.y = target_height
		cb_root.custom_minimum_size = final_size
		cb_root.clip_contents = bool(card.get("thieving_heist_reveal_original_root_clip", false))
		_set_canvas_item_modulate_if_changed(cb_root, Color.WHITE)
	if cb_pop != null and not cb_pop.is_queued_for_deletion():
		cb_pop.anchor_top = 0.0
		cb_pop.anchor_bottom = float(card.get("thieving_heist_reveal_original_pop_anchor_bottom", 1.0))
		cb_pop.offset_top = 0.0
		cb_pop.offset_bottom = float(card.get("thieving_heist_reveal_original_pop_offset_bottom", 0.0))
		_set_canvas_item_modulate_if_changed(cb_pop, Color.WHITE)
	if not card.is_empty():
		card.erase("thieving_heist_reveal_target_height")
		card.erase("thieving_heist_reveal_original_root_clip")
		card.erase("thieving_heist_reveal_original_pop_anchor_bottom")
		card.erase("thieving_heist_reveal_original_pop_offset_bottom")
		card.erase("preview_fade_tween")
	activity_unlock_heist_preview_after_ceremony_id = ""
	_release_detail_unlock_extra_scroll_space()



func _thieving_heist_feather_shader() -> Shader:
	if thieving_heist_feather_shader != null:
		return thieving_heist_feather_shader
	thieving_heist_feather_shader = Shader.new()
	thieving_heist_feather_shader.code = """
shader_type canvas_item;
uniform bool top_fade = true;

void fragment() {
	float alpha = top_fade ? (1.0 - UV.y) : UV.y;
	COLOR.a *= smoothstep(0.0, 1.0, alpha);
}
"""
	return thieving_heist_feather_shader



func _thieving_heist_feather_band(top: bool) -> ColorRect:
	var band := ColorRect.new()
	band.color = _theme_paper_color()
	band.anchor_left = 0.0
	band.anchor_right = 1.0
	band.anchor_top = 0.0 if top else 1.0
	band.anchor_bottom = 0.0 if top else 1.0
	band.offset_left = 0.0
	band.offset_right = 0.0
	band.offset_top = 0.0 if top else -170.0
	band.offset_bottom = 170.0 if top else 0.0
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.z_index = 205
	var shader_material := ShaderMaterial.new()
	shader_material.shader = _thieving_heist_feather_shader()
	shader_material.set_shader_parameter("top_fade", top)
	band.material = shader_material
	return band



func _add_thieving_heist_completed_stamp(parent: Control) -> void:
	var stamp := _label("STOLEN", 68, COLOR_GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	stamp.add_theme_color_override("font_outline_color", COLOR_INK)
	stamp.add_theme_constant_override("outline_size", 26)
	stamp.anchor_left = 1.0
	stamp.anchor_right = 1.0
	stamp.anchor_top = 0.0
	stamp.anchor_bottom = 0.0
	stamp.offset_left = -420
	stamp.offset_right = -60
	stamp.offset_top = 38
	stamp.offset_bottom = 132
	stamp.rotation_degrees = 4.0
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.z_index = 260
	parent.add_child(stamp)



func _add_thieving_heist_jail_overlay(card: Dictionary, cooldown_remaining: int) -> void:
	var pop := _valid_control_ref(card.get("pop"))
	var root := _valid_control_ref(card.get("root"))
	if pop == null or root == null:
		return
	var heist_id := str(card.get("heist_id", ""))
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.clip_contents = false
	overlay.z_index = 280
	overlay.gui_input.connect(_on_thieving_heist_jail_overlay_input.bind(heist_id))
	root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.045, 0.04, 0.36)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shade)

	var bars_shake_body := Control.new()
	bars_shake_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars_shake_body.offset_left = -54.0
	bars_shake_body.offset_right = 54.0
	bars_shake_body.offset_top = -28.0
	bars_shake_body.offset_bottom = 28.0
	bars_shake_body.clip_contents = false
	bars_shake_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_shake_body.z_index = 2
	overlay.add_child(bars_shake_body)

	var bars := TextureRect.new()
	bars.texture = host.visual_texture_cache._texture_or_visual_fallback(THIEVING_HEIST_JAIL_BARS_TEXTURE)
	bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bars.stretch_mode = TextureRect.STRETCH_SCALE
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_shake_body.add_child(bars)

	var timer := _label(_thieving_heist_jail_text(cooldown_remaining), 86, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	timer.add_theme_color_override("font_outline_color", Color.BLACK)
	timer.add_theme_constant_override("outline_size", 34)
	timer.add_theme_constant_override("line_spacing", -8)
	timer.anchor_left = 0.0
	timer.anchor_right = 1.0
	timer.anchor_top = 0.5
	timer.anchor_bottom = 0.5
	timer.offset_left = 0
	timer.offset_right = 0
	timer.offset_top = -105
	timer.offset_bottom = 105
	timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer.z_index = 6
	overlay.add_child(timer)
	card["jail_overlay"] = overlay
	card["jail_label"] = timer
	card["jail_bars_shake_body"] = bars_shake_body



func _on_thieving_heist_jail_overlay_input(event: InputEvent, heist_id: String) -> void:
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return
	else:
		return
	var key := _thieving_heist_card_key(heist_id)
	var card := action_cards.get(key, {}) as Dictionary
	if event is InputEventMouseButton:
		var mouse_event_id := int(event.get_instance_id())
		if int(card.get("last_jail_mouse_event_id", 0)) == mouse_event_id:
			get_viewport().set_input_as_handled()
			return
		card["last_jail_mouse_event_id"] = mouse_event_id
	var shake_body := _valid_control_ref(card.get("jail_bars_shake_body"))
	if shake_body != null:
		_play_padlock_click_shake(shake_body)
	var remaining: int = host.thieving_state.heist_cooldown_remaining(heist_id, _unix_now())
	if remaining > 0:
		_reduce_thieving_heist_jail_timer(heist_id, card)
		var updated_remaining: int = host.thieving_state.heist_cooldown_remaining(heist_id, _unix_now())
		host._reward_feedback_surface()._set_result("Still jailed: %s." % _format_countdown(updated_remaining))
	get_viewport().set_input_as_handled()



func _reduce_thieving_heist_jail_timer(heist_id: String, card: Dictionary) -> void:
	if card.is_empty():
		return
	var state: Dictionary = host.thieving_state.ensure_trophy_state(heist_id)
	var cooldown_until := maxi(0, int(state.get("cooldown_until_unix", 0)))
	if cooldown_until <= 0:
		return
	state["cooldown_until_unix"] = maxi(_unix_now(), cooldown_until - 1)
	thieving_trophies[heist_id] = state
	_float_thieving_jail_timer_reduction(card)
	_update_thieving_heist_card(card, 0.0, true)
	if host.thieving_state.heist_cooldown_remaining(heist_id, _unix_now()) <= 0:
		save_game()



func _float_thieving_jail_timer_reduction(card: Dictionary) -> void:
	var timer := _state_object_ref(card.get("jail_label")) as Label
	var overlay := _valid_control_ref(card.get("jail_overlay"))
	if timer == null or overlay == null:
		return
	if not overlay.is_inside_tree() or not timer.is_inside_tree():
		return
	var reward_size := Vector2(210, 92)
	var holder := Control.new()
	holder.size = reward_size
	holder.z_index = 320
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(holder)

	var shadow := _label("-1s", 58, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = reward_size
	shadow.position = Vector2(5, 6)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.modulate = Color(1, 1, 1, 0.58)
	holder.add_child(shadow)

	var label := _label("-1s", 58, Color("#7dff8e"), HORIZONTAL_ALIGNMENT_CENTER)
	label.size = reward_size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_outline_color", COLOR_INK)
	label.add_theme_constant_override("outline_size", 16)
	holder.add_child(label)

	var timer_rect := timer.get_global_rect()
	var overlay_origin := overlay.global_position
	var origin := timer_rect.position - overlay_origin + Vector2(
		randf_range(timer_rect.size.x * 0.34, timer_rect.size.x * 0.66),
		randf_range(-18.0, 18.0)
	)
	origin += Vector2(randf_range(-150.0, 150.0), randf_range(-36.0, 10.0))
	holder.position = origin - reward_size * 0.5
	holder.rotation = randf_range(-0.22, 0.22)
	holder.scale = Vector2.ONE * randf_range(0.74, 0.92)
	holder.modulate = Color(1, 1, 1, 0)

	var rise := Vector2(randf_range(-76.0, 76.0), randf_range(-172.0, -108.0))
	var end_rotation := holder.rotation + randf_range(-0.16, 0.16)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + rise, randf_range(0.82, 1.12)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "rotation", end_rotation, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE * randf_range(1.02, 1.18), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.08)
	tween.tween_property(holder, "modulate:a", 0.0, 0.48).set_delay(randf_range(0.34, 0.52))
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(holder.get_instance_id()))



func _thieving_action_jail_remaining(action_id: String) -> int:
	if action_id.is_empty() or not host.thieving_state.action_jails.has(action_id):
		return 0
	var state := host.thieving_state.action_jails.get(action_id, {}) as Dictionary
	return maxi(0, int(state.get("cooldown_until_unix", 0)) - _unix_now())



func _thieving_action_is_jailed(action_id: String) -> bool:
	return _thieving_action_jail_remaining(action_id) > 0



func _thieving_action_jail_seconds(action: Dictionary, skill_level := -1) -> int:
	if action.is_empty():
		return 0
	var level := skill_level
	if level < 0:
		level = _skill_level("thieving")
	var unlock_level := maxi(1, int(action.get("unlock", 1)))
	var base_seconds := THIEVING_ACTION_JAIL_BASE_SECONDS + unlock_level * THIEVING_ACTION_JAIL_SECONDS_PER_UNLOCK_LEVEL
	var level_reduction := maxi(0, level - unlock_level)
	var jail_seconds := base_seconds - level_reduction
	return jail_seconds if jail_seconds >= THIEVING_ACTION_JAIL_MIN_SECONDS else 0



func _jail_thieving_action(action_id: String, resume_when_free := true, jail_seconds := -1) -> void:
	if action_id.is_empty():
		return
	if jail_seconds < 0:
		jail_seconds = _thieving_action_jail_seconds(_action_data("thieving", action_id))
	if jail_seconds <= 0:
		if host.thieving_state.action_jails.has(action_id):
			_clear_thieving_action_jail(action_id, false)
		return
	host.thieving_state.action_jails[action_id] = {
		"cooldown_until_unix": _unix_now() + jail_seconds,
		"resume_when_free": resume_when_free
	}
	for card in _thieving_action_cards_for_action(action_id):
		_sync_thieving_action_jail_overlay(card, action_id)
	_update_ui(0.0, true)
	save_game()



func _cancel_thieving_action_jail_resumes_for_started_action(skill_id: String, action_id: String) -> void:
	if host.thieving_state.action_jails.is_empty():
		return
	var changed := false
	for raw_jailed_action_id in host.thieving_state.action_jails.keys():
		var jailed_action_id := str(raw_jailed_action_id)
		var state := host.thieving_state.action_jails.get(jailed_action_id, {}) as Dictionary
		if skill_id == "thieving" and action_id == jailed_action_id:
			continue
		if bool(state.get("resume_when_free", false)):
			state["resume_when_free"] = false
			host.thieving_state.action_jails[jailed_action_id] = state
			changed = true
	if changed:
		save_game()



func _clear_thieving_action_jail(action_id: String, resume_if_free := true) -> void:
	if action_id.is_empty() or not host.thieving_state.action_jails.has(action_id):
		return
	var state := host.thieving_state.action_jails.get(action_id, {}) as Dictionary
	var should_resume := resume_if_free and bool(state.get("resume_when_free", false))
	host.thieving_state.action_jails.erase(action_id)
	for card in _thieving_action_cards_for_action(action_id):
		_release_thieving_action_jail_overlay(card)
		card["jail_overlay"] = null
		card["jail_label"] = null
		card["jail_bars_shake_body"] = null
		card["jail_bars"] = null
		_set_thieving_action_card_jailed_visual(card, false)
	if should_resume and running_skill_id.is_empty() and running_action_id.is_empty():
		host._action_runtime()._start_action("thieving", action_id, false)
	save_game()



func _process_thieving_action_jails() -> void:
	if host.thieving_state.action_jails.is_empty():
		return
	var now := _unix_now()
	if now == host.thieving_state.last_action_jail_process_unix:
		return
	host.thieving_state.last_action_jail_process_unix = now
	var expired: Array[String] = []
	for raw_action_id in host.thieving_state.action_jails.keys():
		var action_id := str(raw_action_id)
		if _thieving_action_jail_remaining(action_id) <= 0:
			expired.append(action_id)
	for action_id in expired:
		_clear_thieving_action_jail(action_id, true)



func _thieving_action_cards_for_action(action_id: String) -> Array:
	var cards := []
	if action_id.is_empty():
		return cards
	for raw_key in action_cards.keys():
		var key := str(raw_key)
		var card := action_cards.get(key, {}) as Dictionary
		if card.is_empty():
			continue
		if str(card.get("skill_id", "")) != "thieving" or str(card.get("action_id", "")) != action_id:
			continue
		var pop := _valid_control_ref(card.get("pop"))
		if pop == null or not pop.is_inside_tree():
			continue
		cards.append(card)
	return cards



func _sync_thieving_action_jail_overlay(card: Dictionary, action_id: String) -> void:
	if card.is_empty() or action_id.is_empty():
		return
	var remaining := _thieving_action_jail_remaining(action_id)
	var overlay := card.get("jail_overlay") as Control
	if remaining <= 0:
		_release_thieving_action_jail_overlay(card)
		card["jail_overlay"] = null
		card["jail_label"] = null
		card["jail_bars_shake_body"] = null
		card["jail_bars"] = null
		_set_thieving_action_card_jailed_visual(card, false)
		return
	_set_thieving_action_card_jailed_visual(card, true)
	if overlay == null or not is_instance_valid(overlay):
		_add_thieving_action_jail_overlay(card, action_id, remaining)
		return
	overlay.visible = true
	var jail_label := card.get("jail_label") as Label
	if jail_label != null and is_instance_valid(jail_label):
		_set_label_text_if_changed(jail_label, _thieving_heist_jail_text(remaining))



func _add_thieving_action_jail_overlay(card: Dictionary, action_id: String, cooldown_remaining: int) -> void:
	var pop := card.get("pop") as Control
	if pop == null or not is_instance_valid(pop):
		return
	var existing := card.get("jail_overlay") as Control
	if existing != null and is_instance_valid(existing):
		existing.queue_free()
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.clip_contents = true
	overlay.z_index = MODULE_TITLE_OVER_PIN_Z_INDEX + 240
	overlay.gui_input.connect(_on_thieving_action_jail_overlay_input.bind(action_id, str(card.get("card_key", _action_key("thieving", action_id)))))
	overlay.modulate = Color(1, 1, 1, 0)
	pop.add_child(overlay)

	var shade := Panel.new()
	shade.add_theme_stylebox_override("panel", _thieving_action_jail_shade_style())
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = 1
	overlay.add_child(shade)

	var bars_shake_body := Control.new()
	bars_shake_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars_shake_body.offset_left = 0.0
	bars_shake_body.offset_right = 0.0
	bars_shake_body.offset_top = 0.0
	bars_shake_body.offset_bottom = 0.0
	bars_shake_body.clip_contents = false
	bars_shake_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_shake_body.z_index = 2
	bars_shake_body.position = Vector2(0, -220)
	bars_shake_body.scale = Vector2.ONE
	bars_shake_body.pivot_offset = Vector2.ZERO
	overlay.add_child(bars_shake_body)

	var bars := TextureRect.new()
	bars.texture = host.visual_texture_cache._texture_or_visual_fallback(THIEVING_HEIST_JAIL_BARS_TEXTURE)
	bars.set_anchors_preset(Control.PRESET_FULL_RECT)
	bars.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bars.stretch_mode = TextureRect.STRETCH_SCALE
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_shake_body.add_child(bars)

	var timer := _label(_thieving_heist_jail_text(cooldown_remaining), 86, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	timer.add_theme_color_override("font_outline_color", Color.BLACK)
	timer.add_theme_constant_override("outline_size", 34)
	timer.add_theme_constant_override("line_spacing", -8)
	timer.anchor_left = 0.0
	timer.anchor_right = 1.0
	timer.anchor_top = 0.5
	timer.anchor_bottom = 0.5
	timer.offset_left = 0
	timer.offset_right = 0
	timer.offset_top = -105
	timer.offset_bottom = 105
	timer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer.z_index = 6
	timer.modulate = Color(1, 1, 1, 0)
	timer.scale = Vector2(0.86, 0.86)
	overlay.add_child(timer)
	card["jail_overlay"] = overlay
	card["jail_label"] = timer
	card["jail_bars_shake_body"] = bars_shake_body
	card["jail_bars"] = bars
	_play_thieving_action_jail_appear(card)



func _on_thieving_action_jail_overlay_input(event: InputEvent, action_id: String, card_key := "") -> void:
	if event is InputEventMouseButton:
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return
	else:
		return
	var key := card_key if not card_key.is_empty() else _action_key("thieving", action_id)
	var card := action_cards.get(key, {}) as Dictionary
	if event is InputEventMouseButton:
		var mouse_event_id := int(event.get_instance_id())
		if int(card.get("last_jail_mouse_event_id", 0)) == mouse_event_id:
			get_viewport().set_input_as_handled()
			return
		card["last_jail_mouse_event_id"] = mouse_event_id
	_reduce_thieving_action_jail_from_card(action_id, card)
	get_viewport().set_input_as_handled()



func _reduce_thieving_action_jail_from_card(action_id: String, card: Dictionary) -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec - int(card.get("last_jail_tap_msec", 0)) < 80:
		return
	card["last_jail_tap_msec"] = now_msec
	var shake_body := card.get("jail_bars_shake_body") as Control
	if shake_body != null and is_instance_valid(shake_body):
		_play_padlock_click_shake(shake_body)
	if _thieving_action_jail_remaining(action_id) <= 0:
		return
	_reduce_thieving_action_jail_timer(action_id, card)
	var updated_remaining := _thieving_action_jail_remaining(action_id)
	if updated_remaining > 0:
		host._reward_feedback_surface()._set_result("Still jailed: %s." % _format_countdown(updated_remaining))



func _reduce_thieving_action_jail_timer(action_id: String, card: Dictionary) -> void:
	if action_id.is_empty() or not host.thieving_state.action_jails.has(action_id):
		return
	var state := host.thieving_state.action_jails.get(action_id, {}) as Dictionary
	var cooldown_until := maxi(0, int(state.get("cooldown_until_unix", 0)))
	if cooldown_until <= 0:
		return
	state["cooldown_until_unix"] = maxi(_unix_now(), cooldown_until - 1)
	host.thieving_state.action_jails[action_id] = state
	_float_thieving_jail_timer_reduction(card)
	for duplicate_card in _thieving_action_cards_for_action(action_id):
		_sync_thieving_action_jail_overlay(duplicate_card, action_id)
	if _thieving_action_jail_remaining(action_id) <= 0:
		_clear_thieving_action_jail(action_id, true)
	else:
		save_game()



func _release_thieving_action_jail_overlay(card: Dictionary) -> void:
	var overlay := card.get("jail_overlay") as Control
	if overlay == null or not is_instance_valid(overlay):
		return
	if bool(overlay.get_meta("jail_releasing", false)):
		return
	overlay.set_meta("jail_releasing", true)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bars := card.get("jail_bars_shake_body") as Control
	var timer := card.get("jail_label") as Control
	host._app_lifecycle_runtime()._kill_card_tween(card, "jail_appear_tween")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 0.0, 0.28).set_delay(0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if bars != null and is_instance_valid(bars):
		tween.tween_property(bars, "position:y", -220.0, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if timer != null and is_instance_valid(timer):
		tween.tween_property(timer, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(timer, "scale", Vector2(0.78, 0.78), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(overlay.get_instance_id()))



func _set_thieving_action_card_jailed_visual(card: Dictionary, jailed: bool) -> void:
	if jailed:
		return
	var pop := card.get("pop") as Node
	if pop == null or not is_instance_valid(pop):
		return
	_set_thieving_action_card_grayscale_subtree(pop, false)



func _set_thieving_action_card_grayscale_subtree(node: Node, grayscale: bool) -> void:
	if node == null or not is_instance_valid(node):
		return
	if node is CanvasItem:
		var item := node as CanvasItem
		if grayscale:
			if not item.has_meta("thieving_jail_original_material"):
				item.set_meta("thieving_jail_original_material", item.material)
			item.material = _thieving_action_jail_material()
		elif item.has_meta("thieving_jail_original_material"):
			item.material = item.get_meta("thieving_jail_original_material") as Material
			item.remove_meta("thieving_jail_original_material")
	for child in node.get_children():
		_set_thieving_action_card_grayscale_subtree(child, grayscale)



func _play_thieving_action_jail_appear(card: Dictionary) -> void:
	var overlay := card.get("jail_overlay") as Control
	var bars := card.get("jail_bars_shake_body") as Control
	var timer := card.get("jail_label") as Control
	if overlay == null or bars == null or timer == null:
		return
	if not is_instance_valid(overlay) or not is_instance_valid(bars) or not is_instance_valid(timer):
		return
	host._app_lifecycle_runtime()._kill_card_tween(card, "jail_appear_tween")
	var jail_overlay_id := overlay.get_instance_id()
	var jail_bars_id := bars.get_instance_id()
	var jail_timer_id := timer.get_instance_id()
	var tween := create_tween()
	card["jail_appear_tween"] = tween
	tween.set_parallel(true)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(bars, "position:y", 0.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(timer, "modulate:a", 1.0, 0.16).set_delay(0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(timer, "scale", Vector2.ONE, 0.20).set_delay(0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_thieving_action_jail_appear.bind(str(card.get("card_key", "")), jail_overlay_id, jail_bars_id, jail_timer_id))



func _finish_thieving_action_jail_appear(card_key: String, jail_overlay_id: int, jail_bars_id: int, jail_timer_id: int) -> void:
	var cb_overlay := _valid_control_ref(instance_from_id(jail_overlay_id))
	var cb_bars := _valid_control_ref(instance_from_id(jail_bars_id))
	var cb_timer := _valid_control_ref(instance_from_id(jail_timer_id))
	if cb_overlay != null:
		cb_overlay.modulate.a = 1.0
	if cb_bars != null:
		cb_bars.position.y = 0.0
		cb_bars.scale = Vector2.ONE
	if cb_timer != null:
		cb_timer.modulate.a = 1.0
		cb_timer.scale = Vector2.ONE
	var card := action_cards.get(card_key, {}) as Dictionary
	if not card.is_empty():
		card.erase("jail_appear_tween")



func _thieving_heist_jail_text(cooldown_remaining: int) -> String:
	return "JAILED\n%s" % _format_countdown(cooldown_remaining)



func _update_thieving_heist_card(card: Dictionary, _delta: float, _instant: bool) -> void:
	var heist := card.get("heist", {}) as Dictionary
	var heist_id := str(card.get("heist_id", ""))
	var state: Dictionary = host.thieving_state.ensure_trophy_state(heist_id)
	var stolen := bool(state.get("stolen", false))
	var cooldown_remaining: int = host.thieving_state.heist_cooldown_remaining(heist_id, _unix_now())
	var button := card.get("button") as Button
	if button != null and is_instance_valid(button):
		_set_button_text_if_changed(button, "STOLEN" if stolen else ("JAILED" if cooldown_remaining > 0 else "STEAL"))
		_set_base_button_disabled_if_changed(button, stolen or cooldown_remaining > 0)
	var chance_label := card.get("chance_label") as Label
	if chance_label != null and is_instance_valid(chance_label):
		_set_label_text_if_changed(chance_label, "%s%% chance\nof success" % int(round(_thieving_heist_success_chance(heist))))
	var jail_label := card.get("jail_label") as Label
	if jail_label != null and is_instance_valid(jail_label):
		_set_label_text_if_changed(jail_label, _thieving_heist_jail_text(cooldown_remaining))
	var jail_overlay := card.get("jail_overlay") as Control
	if jail_overlay != null and is_instance_valid(jail_overlay):
		_set_canvas_item_visible_if_changed(jail_overlay, cooldown_remaining > 0 and not stolen)
	card["last_stolen"] = stolen
	card["last_cooldown"] = cooldown_remaining



func _thieving_heist_success_chance(heist: Dictionary) -> float:
	var base_success := float(heist.get("success", 0.0))
	var unlock_level := int(heist.get("unlock", 1))
	var level_bonus := maxf(0.0, float(_skill_level("thieving") - unlock_level) * THIEVING_HEIST_LEVEL_SUCCESS_BONUS)
	return clampf(base_success + level_bonus, 5.0, THIEVING_HEIST_MAX_SUCCESS)



func _attempt_thieving_heist(heist_id: String) -> void:
	host._settings_surface()._disarm_reset_data_confirmation()
	if _skill_swipe_suppresses_button_action():
		return
	var active_scroll: Control = detail_actions_scroll if current_screen == "skill" else (_valid_control_ref(content_scroll) as MobileScrollContainer if current_screen == "pinned" else null)
	if active_scroll != null and active_scroll.is_child_click_suppressed():
		return
	var heist: Dictionary = host.thieving_state.heist_def(heist_id)
	if heist.is_empty():
		return
	if _skill_level("thieving") < int(heist.get("unlock", 1)):
		return
	var state: Dictionary = host.thieving_state.ensure_trophy_state(heist_id)
	if bool(state.get("stolen", false)) or host.thieving_state.heist_cooldown_remaining(heist_id, _unix_now()) > 0:
		return
	host._audio_director()._unlock_audio_for_gameplay()
	var key := _thieving_heist_card_key(heist_id)
	host._skill_swipe_activity_surface()._pop_activity_button(key)
	var success := randf() * 100.0 <= _thieving_heist_success_chance(heist)
	if success:
		state["stolen"] = true
		state["cooldown_until_unix"] = 0
		thieving_trophies[heist_id] = state
		var xp_reward := int(heist.get("xp", 1))
		skills["thieving"]["xp"] = int(skills.get("thieving", {}).get("xp", 0)) + xp_reward
		var old_level := _skill_level("thieving")
		_recalculate_level("thieving")
		host._hub_runtime().sync_trophy_level_from_thieving()
		host._reward_feedback_surface()._set_result("%s +%s XP." % [str(heist.get("success_text", "Trophy stolen.")), xp_reward])
		pending_thieving_trophy_reward_float = {"key": key, "xp": xp_reward}
		host._audio_director()._play_activity_success_sound(1, false, false, false, false, 0)
		host._audio_director()._record_music_flow_action(true, 1, false, _skill_level("thieving") > old_level, _skill_level("thieving") > old_level, 0.0)
	else:
		var cooldown_until := _unix_now() + int(heist.get("cooldown_seconds", 60))
		state["cooldown_until_unix"] = cooldown_until
		thieving_trophies[heist_id] = state
		var failure_xp := maxi(1, int(round(float(heist.get("xp", 1)) * 0.20)))
		skills["thieving"]["xp"] = int(skills.get("thieving", {}).get("xp", 0)) + failure_xp
		_recalculate_level("thieving")
		host._action_runtime().reset_activity_completion_streak()
		host._action_runtime().reset_consecutive_activity_crits()
		host._reward_feedback_surface()._set_result("%s +%s XP. Try again in %s." % [str(heist.get("failure_text", "Heist failed.")), failure_xp, GameFormatting.duration(float(heist.get("cooldown_seconds", 60)))])
		host._reward_feedback_surface()._play_action_feedback(key, false, failure_xp, 0.0)
		host._audio_director()._play_failure_sfx()
		host._audio_director()._record_music_flow_action(false, 0, false, false, false, 0.0)
	host._onboarding_runtime()._record_activity_start_for_tips()
	host._onboarding_runtime()._record_activity_completion_for_tips("thieving", heist_id)
	save_game()
	if not pending_thieving_trophy_reward_float.is_empty():
		_update_ui(0.0, true)
		call_deferred("_play_pending_thieving_trophy_reward_float")
	else:
		var thieving_refresh_scroll: int = detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1
		_render_screen(false, thieving_refresh_scroll)
		_update_ui(0.0, true)



func _play_pending_thieving_trophy_reward_float() -> void:
	if pending_thieving_trophy_reward_float.is_empty():
		return
	if bool(pending_thieving_trophy_reward_float.get("playing", false)):
		return
	pending_thieving_trophy_reward_float["playing"] = true
	var reward: Dictionary = pending_thieving_trophy_reward_float.duplicate()
	await get_tree().process_frame
	await get_tree().create_timer(0.18).timeout
	if pending_thieving_trophy_reward_float.is_empty():
		return
	_play_thieving_trophy_hub_float(str(reward.get("key", "")), int(reward.get("xp", 0)))



func _play_thieving_trophy_hub_float(action_key: String, xp_amount: int) -> void:
	if not action_cards.has(action_key):
		pending_thieving_trophy_reward_float.clear()
		return
	var card := action_cards[action_key] as Dictionary
	var trophy := _state_object_ref(card.get("trophy")) as TextureRect
	var anchor := _valid_control_ref(card.get("art_panel"))
	if trophy == null or anchor == null or not anchor.is_inside_tree():
		pending_thieving_trophy_reward_float.clear()
		return
	if trophy.texture == null:
		pending_thieving_trophy_reward_float.clear()
		return
	var source_rect := trophy.get_global_rect()
	if source_rect.size.x <= 1.0 or source_rect.size.y <= 1.0:
		source_rect = anchor.get_global_rect()
	var to_local: Transform2D = host.get_global_transform_with_canvas().affine_inverse()
	var start_center: Vector2 = to_local * source_rect.get_center()
	var target_center := Vector2(_current_canvas_size().x * 0.5, _current_canvas_size().y - BOTTOM_NAV_HEIGHT * 0.52)
	if hub_tab != null and is_instance_valid(hub_tab) and hub_tab.is_inside_tree():
		target_center = to_local * hub_tab.get_global_rect().get_center()
	var holder_size := Vector2(maxf(360.0, source_rect.size.x), maxf(330.0, source_rect.size.y))
	var holder := Control.new()
	holder.size = holder_size
	holder.position = start_center - holder_size * 0.5
	holder.pivot_offset = holder_size * 0.5
	holder.scale = Vector2(0.86, 0.86)
	holder.rotation = -0.08
	holder.modulate = Color(1, 1, 1, 0)
	holder.z_index = REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._fishing_ui_surface()._fishing_collection_canvas().add_child(holder)
	_float_thieving_heist_xp_reward(start_center, xp_amount)

	var glow := Panel.new()
	glow.anchor_left = 0.5
	glow.anchor_right = 0.5
	glow.anchor_top = 0.5
	glow.anchor_bottom = 0.5
	glow.offset_left = -holder_size.x * 0.42
	glow.offset_right = holder_size.x * 0.42
	glow.offset_top = -holder_size.y * 0.36
	glow.offset_bottom = holder_size.y * 0.36
	glow.add_theme_stylebox_override("panel", _thieving_trophy_soft_glow_style())
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 0
	holder.add_child(glow)

	var old_parent := trophy.get_parent()
	if old_parent != null:
		old_parent.remove_child(trophy)
	holder.add_child(trophy)
	trophy.anchor_left = 0.0
	trophy.anchor_right = 1.0
	trophy.anchor_top = 0.0
	trophy.anchor_bottom = 1.0
	trophy.offset_left = 34
	trophy.offset_right = -34
	trophy.offset_top = 72
	trophy.offset_bottom = -6
	trophy.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	trophy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trophy.z_index = 3
	card["trophy"] = null

	var float_center: Vector2 = start_center + Vector2(randf_range(-50.0, 50.0), -250.0)
	var control_1: Vector2 = float_center + Vector2(randf_range(-220.0, 220.0), -260.0)
	var control_2 := target_center + Vector2(randf_range(-160.0, 160.0), -430.0)
	var tween := create_tween()
	var holder_id := holder.get_instance_id()
	tween.set_parallel(true)
	tween.tween_property(holder, "modulate:a", 1.0, 0.16)
	tween.tween_property(glow, "modulate:a", 0.0, 1.30).set_delay(0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		_apply_thieving_trophy_float_frame.bind(holder_id, start_center, float_center),
		0.0,
		1.0,
		0.72
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_interval(0.22)
	tween.chain()
	tween.tween_method(
		_apply_thieving_trophy_flight_frame.bind(holder_id, float_center, control_1, control_2, target_center),
		0.0,
		1.0,
		1.48
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.chain()
	tween.tween_interval(0.20)
	tween.chain().tween_callback(_finish_thieving_trophy_flight.bind(holder_id, action_key))



func _apply_thieving_trophy_float_frame(progress: float, holder_id: int, start_center: Vector2, float_center: Vector2) -> void:
	var trophy_holder := _valid_control_ref(instance_from_id(holder_id))
	if trophy_holder == null:
		return
	var p := clampf(progress, 0.0, 1.0)
	var center := start_center.lerp(float_center, 1.0 - pow(1.0 - p, 2.2))
	trophy_holder.position = center + Vector2(sin(p * TAU * 1.6) * 18.0, 0) - trophy_holder.size * 0.5
	trophy_holder.rotation = lerpf(-0.08, 0.08, sin(p * PI))
	trophy_holder.scale = Vector2.ONE * lerpf(0.86, 1.28, sin(p * PI * 0.5))



func _apply_thieving_trophy_flight_frame(progress: float, holder_id: int, float_center: Vector2, control_1: Vector2, control_2: Vector2, target_center: Vector2) -> void:
	var trophy_holder := _valid_control_ref(instance_from_id(holder_id))
	if trophy_holder == null:
		return
	var p := clampf(progress, 0.0, 1.0)
	var q := 1.0 - p
	var center := q * q * q * float_center + 3.0 * q * q * p * control_1 + 3.0 * q * p * p * control_2 + p * p * p * target_center
	var bob := Vector2(sin(p * TAU * 3.0) * 34.0 * (1.0 - p), cos(p * TAU * 2.0) * 20.0 * (1.0 - p))
	trophy_holder.position = center + bob - trophy_holder.size * 0.5
	trophy_holder.rotation = sin(p * TAU * 2.4) * 0.16 * (1.0 - p) - 0.08 * (1.0 - p)
	var zoom := lerpf(1.28, 0.22, pow(p, 2.2))
	trophy_holder.scale = Vector2(zoom, zoom)
	trophy_holder.modulate.a = 1.0 if p < 0.86 else lerpf(1.0, 0.0, (p - 0.86) / 0.14)



func _finish_thieving_trophy_flight(holder_id: int, action_key: String) -> void:
	var trophy_holder := _valid_control_ref(instance_from_id(holder_id))
	if trophy_holder != null:
		trophy_holder.queue_free()
		host.button_press_runtime._pop_nav_button(hub_tab)
		_fade_completed_thieving_heist_card(action_key)



func _thieving_trophy_soft_glow_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.91, 0.42, 0.20)
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_left = 999
	style.corner_radius_bottom_right = 999
	style.shadow_color = Color(1.0, 0.84, 0.26, 0.46)
	style.shadow_size = 34
	style.shadow_offset = Vector2.ZERO
	return style



func _float_thieving_heist_xp_reward(start_center: Vector2, xp_amount: int) -> void:
	if xp_amount <= 0:
		return
	var reward_size := Vector2(460, 132)
	var canvas_size := _current_canvas_size()
	var reward_center := start_center + Vector2(360.0 + randf_range(-18.0, 26.0), -110.0 + randf_range(-18.0, 16.0))
	reward_center.x = clampf(reward_center.x, reward_size.x * 0.5 + 24.0, canvas_size.x - reward_size.x * 0.5 - 24.0)
	reward_center.y = minf(reward_center.y, canvas_size.y - host._reward_feedback_surface()._reward_float_reserved_bottom() - reward_size.y * 0.5 - 24.0)
	var holder := Control.new()
	holder.size = reward_size
	holder.position = reward_center - reward_size * 0.5
	holder.pivot_offset = reward_size * 0.5
	holder.rotation = randf_range(-0.08, 0.08)
	holder.scale = Vector2(0.76, 0.76)
	holder.modulate = Color(1, 1, 1, 0)
	holder.z_index = REWARD_FLOAT_Z
	holder.z_as_relative = false
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host._fishing_ui_surface()._fishing_collection_canvas().add_child(holder)

	var shadow := _label("+%s XP!" % xp_amount, 82, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER)
	shadow.size = reward_size
	shadow.position = Vector2(6, 7)
	shadow.modulate = Color(1, 1, 1, 0.56)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shadow)

	var label := _label("+%s XP!" % xp_amount, 82, Color("#2ff06d"), HORIZONTAL_ALIGNMENT_CENTER)
	label.size = reward_size
	label.add_theme_color_override("font_outline_color", COLOR_INK)
	label.add_theme_constant_override("outline_size", 22)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(holder, "position", holder.position + Vector2(randf_range(18.0, 58.0), -250.0), 1.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "rotation", holder.rotation + randf_range(-0.06, 0.06), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "modulate:a", 1.0, 0.10)
	tween.tween_property(holder, "modulate:a", 0.0, 0.56).set_delay(0.66).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(host._app_lifecycle_runtime()._queue_free_instance_id.bind(holder.get_instance_id()))



func _fade_completed_thieving_heist_card(action_key: String) -> void:
	var card := action_cards.get(action_key, {}) as Dictionary
	var root := _valid_control_ref(card.get("root"))
	if root == null or not root.is_inside_tree():
		_refresh_skill_detail_after_thieving_heist_fade(-1)
		return
	var heist_fade_restore_scroll: int = detail_actions_scroll.scroll_vertical if detail_actions_scroll != null else -1
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.clip_contents = true
	_hold_skill_detail_layout_refresh(1.25)
	var start_height := maxf(root.custom_minimum_size.y, root.size.y)
	var tween := create_tween()
	tween.tween_interval(0.18)
	tween.tween_property(root, "modulate:a", 0.0, 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.12)
	tween.tween_property(root, "custom_minimum_size:y", 0.0, 0.48).from(start_height).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.08)
	tween.chain().tween_callback(_remove_thieving_heist_card_from_detail.bind(action_key, heist_fade_restore_scroll))



func _cleanup_stale_thieving_heist_cards() -> void:
	if current_screen != "skill" or selected_skill_id != "thieving":
		return
	var pending_key := str(pending_thieving_trophy_reward_float.get("key", "")) if not pending_thieving_trophy_reward_float.is_empty() else ""
	var removed := false
	for raw_key in action_cards.keys():
		var action_key := str(raw_key)
		if not action_key.begins_with("thieving_heist:") or action_key == pending_key:
			continue
		var heist_id := action_key.substr("thieving_heist:".length())
		if not host.thieving_state.trophy_stolen(heist_id):
			continue
		_remove_thieving_heist_card_from_detail(action_key, -1, false)
		removed = true
	if removed:
		call_deferred("_clamp_detail_actions_scroll_to_content_deferred")



func _remove_thieving_heist_card_from_detail(action_key: String, restore_scroll: int, update_after := true) -> void:
	if action_key.is_empty():
		return
	if str(pending_thieving_trophy_reward_float.get("key", "")) == action_key:
		pending_thieving_trophy_reward_float.clear()
	var card := action_cards.get(action_key, {}) as Dictionary
	var root := _valid_control_ref(card.get("root"))
	var rendered_id := "heist:%s" % action_key.substr("thieving_heist:".length())
	detail_action_card_nodes.erase(rendered_id)
	detail_rendered_action_ids.erase(rendered_id)
	_discard_action_card_key(action_key)
	if root != null:
		root.visible = false
		root.custom_minimum_size = Vector2(root.custom_minimum_size.x, 0.0)
		root.queue_free()
	if detail_actions_scroll != null and restore_scroll >= 0:
		var clamped_scroll := clampi(restore_scroll, 0, detail_actions_scroll.get_max_scroll_vertical())
		detail_actions_scroll.drag_scroll_position = float(clamped_scroll)
		detail_actions_scroll.scroll_vertical = clamped_scroll
	call_deferred("_clamp_detail_actions_scroll_to_content_deferred")
	if update_after:
		_update_ui(0.0, true)



func _refresh_skill_detail_after_thieving_heist_fade(restore_scroll: int) -> void:
	pending_thieving_trophy_reward_float.clear()
	if current_screen != "skill" or selected_skill_id != "thieving":
		return
	_set_detail_unlock_scroll_spacer_height(0.0)
	var action_key := ""
	for raw_key in action_cards.keys():
		if str(raw_key).begins_with("thieving_heist:"):
			var card := action_cards.get(raw_key, {}) as Dictionary
			var root := _valid_control_ref(card.get("root"))
			if root != null and root.custom_minimum_size.y <= 1.0:
				action_key = str(raw_key)
				break
	if not action_key.is_empty():
		_remove_thieving_heist_card_from_detail(action_key, restore_scroll, false)
	_update_ui(0.0, true)



func _thieving_action_jail_material() -> ShaderMaterial:
	if thieving_action_jail_material != null:
		return thieving_action_jail_material
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec4 color = texture(TEXTURE, UV) * COLOR;
	float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	color.rgb = mix(vec3(gray), vec3(0.46, 0.46, 0.44), 0.38) * 0.78;
	COLOR = color;
}
"""
	thieving_action_jail_material = ShaderMaterial.new()
	thieving_action_jail_material.shader = shader
	return thieving_action_jail_material



func _thieving_action_jail_shade_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.28, 0.27, 0.58)
	style.set_corner_radius_all(66)
	return style



func _label(text: String, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	return host._label(text, font_size, color, align)

func _menu_button(text: String) -> Button:
	return host._menu_button(text)

func _add_module_action_zones(parent: Control, module_key: String) -> Dictionary:
	return host._skill_detail_surface()._add_module_action_zones(parent, module_key)

func _register_action_card(card_key: String, card: Dictionary) -> void:
	host._skill_detail_surface()._register_action_card(card_key, card)

func _theme_paper_color() -> Color:
	return host._theme_paper_color()

func _valid_control_ref(value) -> Control:
	return host._app_lifecycle_runtime().valid_control_ref(value)

func _state_object_ref(value):
	return host._app_lifecycle_runtime().state_object_ref(value)

func _set_canvas_item_visible_if_changed(item: CanvasItem, visible: bool) -> void:
	host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(item, visible)

func _set_canvas_item_modulate_if_changed(item: CanvasItem, color: Color) -> void:
	host._app_lifecycle_runtime().set_canvas_item_modulate_if_changed(item, color)

func _hold_skill_detail_layout_refresh(seconds: float) -> void:
	host._skill_detail_surface()._hold_skill_detail_layout_refresh(seconds)

func _release_detail_unlock_extra_scroll_space() -> void:
	host._release_detail_unlock_extra_scroll_space()

func _position_inside_bottom_interactive_ui(point: Vector2) -> bool:
	return host._input_routing_shell()._position_inside_bottom_interactive_ui(point)

func _position_inside_detail_actions_viewport(point: Vector2) -> bool:
	return host._input_routing_shell()._position_inside_detail_actions_viewport(point)

func _skill_swipe_suppresses_button_action() -> bool:
	return host._skill_swipe_activity_surface()._skill_swipe_suppresses_button_action()

func _skill_level(skill_id: String) -> int:
	return SkillState.host_skill_level(host, skill_id)

func _recalculate_level(skill_id: String) -> void:
	SkillState.recalculate_level(host, skill_id)


func _unix_now() -> int:
	return host._unix_now()

func save_game() -> void:
	host.save_game()

func _update_ui(delta: float, instant: bool) -> void:
	host._update_ui(delta, instant)

func _render_screen(transition: bool, restore_scroll := -1) -> void:
	host._navigation_shell()._render_screen(transition, restore_scroll)

func _discard_action_card_key(action_key: String) -> void:
	host._skill_detail_surface()._discard_action_card_key(action_key)

func _clamp_detail_actions_scroll_to_content_deferred() -> void:
	host._clamp_detail_actions_scroll_to_content_deferred()

func _set_detail_unlock_scroll_spacer_height(height: float) -> void:
	host._set_detail_unlock_scroll_spacer_height(height)

func _current_canvas_size() -> Vector2:
	return host._current_canvas_size()

func _action_data(skill_id: String, action_id: String) -> Dictionary:
	return host._action_data(skill_id, action_id)

func _action_key(skill_id: String, action_id: String) -> String:
	return host._action_key(skill_id, action_id)

func _action_card_key(skill_id: String, action_id: String, visual_card_key := "") -> String:
	return host._action_card_key(skill_id, action_id, visual_card_key)

func _valid_texture_progress_ref(value) -> TextureProgressBar:
	var control: Control = host._app_lifecycle_runtime().valid_control_ref(value)
	if control == null:
		return null
	return control as TextureProgressBar

func _dim_action_card(card: Dictionary, dimmed: bool) -> void:
	host._dim_action_card(card, dimmed)

func _started_action_matches(skill_id: String, action_id: String) -> bool:
	return host._started_action_matches(skill_id, action_id)

func _play_padlock_click_shake(target: Control) -> void:
	host._fishing_ui_surface()._play_padlock_click_shake(target)

func _format_countdown(seconds: int) -> String:
	return GameFormatting.countdown(seconds)

func _set_label_text_if_changed(label: Label, text: String) -> void:
	host._app_lifecycle_runtime().set_label_text_if_changed(label, text)

func _set_button_text_if_changed(button: Button, text: String) -> void:
	host._app_lifecycle_runtime().set_button_text_if_changed(button, text)

func _set_base_button_disabled_if_changed(button: BaseButton, disabled: bool) -> void:
	host._app_lifecycle_runtime().set_base_button_disabled_if_changed(button, disabled)
