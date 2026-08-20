extends Control

const ActivityLockRig = preload("res://scripts/ui/activity_lock_rig.gd")

signal chain_moved(kind: String, intensity: float)
signal padlock_clicked
signal padlock_hovered

var rigs: Array[ActivityLockRig] = []
var active_rig: ActivityLockRig
var shared_chain_rig: ActivityLockRig
var unlock_drop_active := false
var unlock_drop_tween: Tween
var uses_requirement_levels := false
var uses_requirement_themes := false
var ready_pulse_tween: Tween
var ready_pulse_active := false
var last_clicked_requirement_index := -1
var shared_drag_active := false
var shared_motion_source: ActivityLockRig


func setup(
	link_texture: Texture2D,
	padlock_texture: Texture2D,
	padlock_pulse_texture: Texture2D,
	unlock_level: int,
	font: Font,
	fallback_font: Font,
	padlock_hit_image: Image = null,
	padlock_tint_mask_texture: Texture2D = null,
	theme_color: Color = Color("#ffd238"),
	padlock_body_texture: Texture2D = null,
	padlock_shackle_closed_texture: Texture2D = null,
	padlock_shackle_open_texture: Texture2D = null,
	requirements: Array = []
) -> void:
	_clear_rigs()
	var lock_requirements := _normalized_requirements(requirements, unlock_level, theme_color)
	uses_requirement_levels = not requirements.is_empty()
	uses_requirement_themes = not requirements.is_empty()
	var use_shared_chain := lock_requirements.size() > 1
	if use_shared_chain:
		shared_chain_rig = _create_rig(
			link_texture,
			padlock_texture,
			padlock_pulse_texture,
			unlock_level,
			font,
			fallback_font,
			padlock_hit_image,
			padlock_tint_mask_texture,
			theme_color,
			padlock_body_texture,
			padlock_shackle_closed_texture,
			padlock_shackle_open_texture,
			-1,
			false,
			true
		)
		shared_chain_rig.set_padlock_visible(false)
	for requirement in lock_requirements:
		_add_rig(
			link_texture,
			padlock_texture,
			padlock_pulse_texture,
			int(requirement.get("level", unlock_level)),
			font,
			fallback_font,
			padlock_hit_image,
			padlock_tint_mask_texture,
			requirement.get("theme_color", theme_color) as Color,
			padlock_body_texture,
			padlock_shackle_closed_texture,
			padlock_shackle_open_texture,
			use_shared_chain
		)
	_layout_base()
	set_process(use_shared_chain)


func set_unlock_level(next_level: int) -> void:
	if uses_requirement_levels:
		return
	for rig in rigs:
		rig.set_unlock_level(next_level)


func set_theme_color(next_theme_color: Color) -> void:
	if uses_requirement_themes:
		return
	for rig in rigs:
		rig.set_theme_color(next_theme_color)


func set_lock_state(next_state: String) -> void:
	for rig in rigs:
		rig.set_lock_state(next_state)
	unlock_drop_active = next_state == ActivityLockRig.LOCK_STATE_DROPPING
	_set_ready_pulse(next_state == ActivityLockRig.LOCK_STATE_READY_OPEN)
	_update_shared_chain_path()


func set_requirement_states(requirement_states: Array) -> void:
	var all_ready := not requirement_states.is_empty()
	for index in range(rigs.size()):
		var met := false
		var dismissed := false
		if index < requirement_states.size() and typeof(requirement_states[index]) == TYPE_DICTIONARY:
			var state := requirement_states[index] as Dictionary
			met = bool(state.get("met", false))
			dismissed = bool(state.get("dismissed", false))
		if rigs[index].lock_state == ActivityLockRig.LOCK_STATE_DROPPING:
			continue
		if dismissed:
			rigs[index].set_lock_state(ActivityLockRig.LOCK_STATE_GONE)
		else:
			rigs[index].set_lock_state(ActivityLockRig.LOCK_STATE_READY_OPEN if met else ActivityLockRig.LOCK_STATE_CLOSED)
			all_ready = all_ready and met
	unlock_drop_active = false
	_set_ready_pulse(all_ready)
	_update_shared_chain_path()


func consume_unlock_click() -> void:
	for rig in rigs:
		rig.consume_unlock_click()


func pulse_requirement_states(requirement_states: Array) -> void:
	for index in range(mini(requirement_states.size(), rigs.size())):
		var raw_state = requirement_states[index]
		if typeof(raw_state) != TYPE_DICTIONARY:
			continue
		var state := raw_state as Dictionary
		if bool(state.get("met", false)):
			continue
		rigs[index].unlock_impulse()


func reset_unlock_drop_animation() -> void:
	unlock_drop_active = false
	unlock_drop_tween = null
	_set_ready_pulse(false)
	if shared_chain_rig != null and is_instance_valid(shared_chain_rig):
		shared_chain_rig.reset_unlock_drop_animation()
	for rig in rigs:
		rig.reset_unlock_drop_animation()


func play_unlock_drop_animation() -> void:
	unlock_drop_active = true
	unlock_drop_tween = null
	_set_ready_pulse(false)
	if shared_chain_rig != null and is_instance_valid(shared_chain_rig):
		shared_chain_rig.play_unlock_drop_animation()
		unlock_drop_tween = shared_chain_rig.unlock_drop_tween
	for rig in rigs:
		rig.play_unlock_drop_animation()
		if unlock_drop_tween == null:
			unlock_drop_tween = rig.unlock_drop_tween


func play_requirement_unlock_drop_animation(requirement_index: int) -> void:
	if requirement_index < 0 or requirement_index >= rigs.size():
		return
	unlock_drop_active = true
	unlock_drop_tween = null
	_set_ready_pulse(false)
	var rig := rigs[requirement_index]
	rig.play_unlock_drop_animation()
	unlock_drop_tween = rig.unlock_drop_tween


func set_requirement_lock_gone(requirement_index: int) -> void:
	if requirement_index < 0 or requirement_index >= rigs.size():
		return
	rigs[requirement_index].set_lock_state(ActivityLockRig.LOCK_STATE_GONE)
	unlock_drop_active = false


func get_last_clicked_requirement_index() -> int:
	return last_clicked_requirement_index


func handle_pointer_event(event: InputEvent) -> bool:
	if active_rig != null and is_instance_valid(active_rig):
		if not _rig_accepts_input(active_rig):
			active_rig = null
		else:
			var handled := active_rig.handle_pointer_event(event)
			if handled:
				_sync_cluster_motion_from(active_rig)
			if _input_released(event):
				active_rig = null
			return handled
	for index in range(rigs.size() - 1, -1, -1):
		var rig := rigs[index]
		if _rig_accepts_input(rig) and rig.handle_pointer_event(event):
			if _input_pressed(event):
				active_rig = rig
			_sync_cluster_motion_from(rig)
			return true
	return false


func pointer_over_lock_event(event: InputEvent) -> bool:
	for rig in rigs:
		if _rig_accepts_input(rig) and rig.pointer_over_lock_event(event):
			return true
	return false


func _input_pressed(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _input_released(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed
	if event is InputEventScreenTouch:
		return not (event as InputEventScreenTouch).pressed
	return false


func _set_ready_pulse(active: bool) -> void:
	if ready_pulse_active == active:
		return
	ready_pulse_active = active
	if ready_pulse_tween != null and ready_pulse_tween.is_valid():
		ready_pulse_tween.kill()
	ready_pulse_tween = null
	modulate = Color.WHITE
	if not active:
		return
	ready_pulse_tween = create_tween()
	ready_pulse_tween.set_loops()
	ready_pulse_tween.tween_property(self, "modulate", Color(1.10, 1.10, 1.10, 1.0), 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ready_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.58).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_base()


func _process(_delta: float) -> void:
	if shared_chain_rig == null or not is_instance_valid(shared_chain_rig):
		return
	var source := _motion_source_rig()
	if source != null:
		_sync_cluster_motion_from(source)
	else:
		_update_shared_chain_path()


func _layout_base() -> void:
	if size.x <= 1.0 or size.y <= 1.0:
		return
	if shared_chain_rig != null and is_instance_valid(shared_chain_rig):
		shared_chain_rig.size = size
		shared_chain_rig.scale = Vector2.ONE
		shared_chain_rig.position = Vector2.ZERO
		shared_chain_rig.pivot_offset = shared_chain_rig.size * 0.5
		shared_chain_rig.set_base_lock_x_shift(0.0)
	var count := clampi(rigs.size(), 1, 5)
	for index in range(rigs.size()):
		var rig := rigs[index]
		var layout := _layout_for_count(index, count)
		var center := Vector2(float(layout.get("x", 0.5)) * size.x, float(layout.get("y", 0.5)) * size.y)
		var layout_scale := float(layout.get("scale", 1.0))
		rig.size = size
		rig.scale = Vector2.ONE * layout_scale
		rig.pivot_offset = rig.size * 0.5
		rig.position = center - rig.pivot_offset
		rig._layout_base()
	if shared_chain_rig != null and is_instance_valid(shared_chain_rig):
		_update_shared_chain_path()
		_sync_cluster_motion_from(_motion_source_rig())


func _normalized_requirements(requirements: Array, fallback_level: int, fallback_color: Color) -> Array:
	var normalized := []
	for raw_requirement in requirements:
		if normalized.size() >= 5:
			break
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		normalized.append({
			"level": maxi(1, int(requirement.get("level", fallback_level))),
			"theme_color": requirement.get("theme_color", fallback_color) as Color
		})
	if normalized.is_empty():
		normalized.append({
			"level": maxi(1, fallback_level),
			"theme_color": fallback_color
		})
	return normalized


func _layout_for_count(index: int, count: int) -> Dictionary:
	match count:
		1:
			return {"x": 0.5, "y": 0.5, "scale": 1.0}
		2:
			var half_spacing := clampf((ActivityLockRig.PADLOCK_SIZE.x * 0.78) / (maxf(size.x, 1.0) * 2.0), 0.19, 0.24)
			var xs := [0.5 - half_spacing, 0.5 + half_spacing]
			return {"x": xs[index], "y": 0.50, "scale": 1.0}
		3:
			var points := [
				{"x": 0.20, "y": 0.58},
				{"x": 0.50, "y": 0.42},
				{"x": 0.80, "y": 0.58},
			]
			var point: Dictionary = points[index]
			point["scale"] = 0.78
			return point
		4:
			var points := [
				{"x": 0.30, "y": 0.38},
				{"x": 0.70, "y": 0.38},
				{"x": 0.30, "y": 0.68},
				{"x": 0.70, "y": 0.68},
			]
			var point: Dictionary = points[index]
			point["scale"] = 0.62
			return point
		_:
			var points := [
				{"x": 0.22, "y": 0.36},
				{"x": 0.50, "y": 0.34},
				{"x": 0.78, "y": 0.36},
				{"x": 0.34, "y": 0.68},
				{"x": 0.66, "y": 0.68},
			]
			var point: Dictionary = points[index]
			point["scale"] = 0.52
			return point


func _update_shared_chain_path() -> void:
	if shared_chain_rig == null or not is_instance_valid(shared_chain_rig):
		return
	var anchor_pairs := []
	for rig in rigs:
		if rig == null or not is_instance_valid(rig):
			continue
		var left_anchor := _cluster_closed_chain_anchor_for_rig(rig, -1)
		var right_anchor := _cluster_closed_chain_anchor_for_rig(rig, 1)
		var motion_offset := _cluster_chain_motion_offset_for_rig(rig)
		left_anchor += motion_offset
		right_anchor += motion_offset
		anchor_pairs.append({
			"left": left_anchor,
			"right": right_anchor,
			"center_x": (left_anchor.x + right_anchor.x) * 0.5
		})
	anchor_pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("center_x", 0.0)) < float(b.get("center_x", 0.0))
	)
	if anchor_pairs.is_empty():
		shared_chain_rig.set_custom_chain_path([])
		return
	var path := []
	var first_pair := anchor_pairs[0] as Dictionary
	var last_pair := anchor_pairs[anchor_pairs.size() - 1] as Dictionary
	var left_outer := Vector2(ActivityLockRig.LINK_SIZE.x * ActivityLockRig.CHAIN_EDGE_ANCHOR_INSET_RATIO, size.y * 0.28)
	var right_outer := Vector2(size.x - ActivityLockRig.LINK_SIZE.x * ActivityLockRig.CHAIN_EDGE_ANCHOR_INSET_RATIO, size.y * 0.28)
	_append_chain_curve(path, left_outer, first_pair.get("left", left_outer) as Vector2, 4, size.y * 0.105)
	for index in range(anchor_pairs.size()):
		var pair := anchor_pairs[index] as Dictionary
		var left_anchor := pair.get("left", Vector2.ZERO) as Vector2
		var right_anchor := pair.get("right", Vector2.ZERO) as Vector2
		_append_chain_curve(path, left_anchor, right_anchor, 2, size.y * 0.012)
		if index < anchor_pairs.size() - 1:
			var next_pair := anchor_pairs[index + 1] as Dictionary
			_append_chain_curve(path, right_anchor, next_pair.get("left", right_anchor) as Vector2, 3, size.y * 0.092)
	_append_chain_curve(path, last_pair.get("right", right_outer) as Vector2, right_outer, 4, size.y * 0.105)
	shared_chain_rig.set_custom_chain_path(path, _combo_chain_render_count(anchor_pairs.size()))


func _cluster_closed_chain_anchor_for_rig(rig: ActivityLockRig, side: int) -> Vector2:
	var base_lock_position := rig.get("base_lock_position") as Vector2
	var local_anchor := base_lock_position + Vector2(
		ActivityLockRig.PADLOCK_SIZE.x * 0.5 + float(side) * ActivityLockRig.PADLOCK_SIZE.x * 0.34,
		ActivityLockRig.PADLOCK_SIZE.y * 0.34
	)
	return rig.position + local_anchor * rig.scale


func _cluster_chain_motion_offset_for_rig(rig: ActivityLockRig) -> Vector2:
	if str(rig.lock_state) == ActivityLockRig.LOCK_STATE_DROPPING or str(rig.lock_state) == ActivityLockRig.LOCK_STATE_GONE:
		return Vector2.ZERO
	if rig.dragging_lock:
		return rig.lock_offset * rig.scale
	if rig.click_shake_remaining > 0.0:
		return rig.lock_offset * rig.scale * 0.72
	if not shared_drag_active:
		return Vector2.ZERO
	return rig.lock_offset * rig.scale


func _combo_chain_render_count(anchor_count: int) -> int:
	match anchor_count:
		1:
			return ActivityLockRig.LINKS_PER_SIDE * 2
		2:
			return 12
		3:
			return 15
		4:
			return 18
		_:
			return 20


func _append_chain_curve(points: Array, start: Vector2, end: Vector2, point_count: int, sag: float) -> void:
	var count := maxi(2, point_count)
	for i in range(count):
		if i == 0 and not points.is_empty():
			continue
		var t := float(i) / float(count - 1)
		var point := start.lerp(end, t)
		point.y += sin(t * PI) * sag
		points.append(point)


func _add_rig(
	link_texture: Texture2D,
	padlock_texture: Texture2D,
	padlock_pulse_texture: Texture2D,
	unlock_level: int,
	font: Font,
	fallback_font: Font,
	padlock_hit_image: Image,
	padlock_tint_mask_texture: Texture2D,
	theme_color: Color,
	padlock_body_texture: Texture2D,
	padlock_shackle_closed_texture: Texture2D,
	padlock_shackle_open_texture: Texture2D,
	hide_chain := false
) -> ActivityLockRig:
	var rig := _create_rig(
		link_texture,
		padlock_texture,
		padlock_pulse_texture,
		unlock_level,
		font,
		fallback_font,
		padlock_hit_image,
		padlock_tint_mask_texture,
		theme_color,
		padlock_body_texture,
		padlock_shackle_closed_texture,
		padlock_shackle_open_texture,
		rigs.size(),
		true,
		not hide_chain
	)
	if hide_chain:
		rig.set_chain_visible(false)
	rigs.append(rig)
	return rig


func _create_rig(
	link_texture: Texture2D,
	padlock_texture: Texture2D,
	padlock_pulse_texture: Texture2D,
	unlock_level: int,
	font: Font,
	fallback_font: Font,
	padlock_hit_image: Image,
	padlock_tint_mask_texture: Texture2D,
	theme_color: Color,
	padlock_body_texture: Texture2D,
	padlock_shackle_closed_texture: Texture2D,
	padlock_shackle_open_texture: Texture2D,
	requirement_index: int,
	allow_padlock_events := true,
	show_chain := true
) -> ActivityLockRig:
	var rig := ActivityLockRig.new()
	rig.setup(
		link_texture,
		padlock_texture,
		padlock_pulse_texture,
		unlock_level,
		font,
		fallback_font,
		padlock_hit_image,
		padlock_tint_mask_texture,
		theme_color,
		padlock_body_texture,
		padlock_shackle_closed_texture,
		padlock_shackle_open_texture
	)
	rig.set_anchors_preset(Control.PRESET_TOP_LEFT)
	rig.clip_contents = false
	rig.visible = true
	rig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rig.set_chain_visible(show_chain)
	rig.chain_moved.connect(_on_rig_chain_moved)
	rig.padlock_clicked.connect(_on_rig_padlock_clicked.bind(allow_padlock_events, requirement_index))
	rig.padlock_hovered.connect(_on_rig_padlock_hovered.bind(allow_padlock_events))
	add_child(rig)
	return rig


func _on_rig_chain_moved(kind: String, intensity: float) -> void:
	chain_moved.emit(kind, intensity)


func _on_rig_padlock_clicked(allow_padlock_events: bool, requirement_index: int) -> void:
	if not allow_padlock_events:
		return
	last_clicked_requirement_index = requirement_index
	padlock_clicked.emit()


func _on_rig_padlock_hovered(allow_padlock_events: bool) -> void:
	if not allow_padlock_events:
		return
	padlock_hovered.emit()


func _motion_source_rig() -> ActivityLockRig:
	if _rig_can_share_motion(active_rig) and active_rig.dragging_lock:
		return active_rig
	for rig in rigs:
		if not _rig_can_share_motion(rig):
			continue
		if rig.dragging_lock:
			return rig
	if _shared_motion_source_can_settle():
		return shared_motion_source
	return null


func _sync_cluster_motion_from(source: ActivityLockRig) -> void:
	var settling_from_drag := shared_drag_active and source == shared_motion_source and _shared_motion_source_can_settle()
	if not _rig_can_share_motion(source) or (not source.dragging_lock and not settling_from_drag):
		_reset_shared_drag_motion(source)
		return
	if shared_chain_rig == null or not is_instance_valid(shared_chain_rig):
		return
	shared_drag_active = true
	shared_motion_source = source
	shared_chain_rig.sync_shared_motion(Vector2.ZERO, Vector2.ZERO, 0.0)
	for rig in rigs:
		if rig == source or not is_instance_valid(rig):
			continue
		if rig.dragging_lock or rig.pressing_lock:
			continue
		if not _rig_can_share_motion(rig):
			continue
		var carried_offset := _chain_carried_lock_offset(source, rig)
		rig.sync_shared_motion(carried_offset, source.lock_velocity * _chain_carried_velocity_ratio(source, rig), source.lock_rotation * 0.42)
	_update_shared_chain_path()


func _reset_shared_drag_motion(except_rig: ActivityLockRig = null) -> void:
	shared_drag_active = false
	shared_motion_source = null
	if shared_chain_rig != null and is_instance_valid(shared_chain_rig):
		shared_chain_rig.sync_shared_motion(Vector2.ZERO, Vector2.ZERO, 0.0)
	for rig in rigs:
		if rig == except_rig or not is_instance_valid(rig):
			continue
		if rig.dragging_lock or rig.pressing_lock:
			continue
		rig.sync_shared_motion(Vector2.ZERO, Vector2.ZERO, 0.0)
	_update_shared_chain_path()


func _shared_motion_source_can_settle() -> bool:
	if shared_motion_source == null or not is_instance_valid(shared_motion_source):
		return false
	if not _rig_can_share_motion(shared_motion_source):
		return false
	return shared_motion_source.physics_active or shared_motion_source.lock_offset.length() > 0.375 or shared_motion_source.lock_velocity.length() > 2.0


func _chain_carried_lock_offset(source: ActivityLockRig, target: ActivityLockRig) -> Vector2:
	var influence := _chain_carried_influence(source, target)
	var offset := source.lock_offset * influence
	offset.y += absf(source.lock_offset.x) * 0.035 * signf(source.lock_offset.y + 0.001)
	return offset


func _chain_carried_velocity_ratio(source: ActivityLockRig, target: ActivityLockRig) -> float:
	return _chain_carried_influence(source, target) * 0.62


func _chain_carried_influence(source: ActivityLockRig, target: ActivityLockRig) -> float:
	var source_center := _cluster_closed_chain_anchor_for_rig(source, -1).lerp(_cluster_closed_chain_anchor_for_rig(source, 1), 0.5)
	var target_center := _cluster_closed_chain_anchor_for_rig(target, -1).lerp(_cluster_closed_chain_anchor_for_rig(target, 1), 0.5)
	var distance_ratio := clampf(source_center.distance_to(target_center) / maxf(size.x, 1.0), 0.0, 1.0)
	return clampf(0.82 - distance_ratio * 0.72, 0.34, 0.64)


func _rig_can_share_motion(rig: ActivityLockRig) -> bool:
	if rig == null or not is_instance_valid(rig):
		return false
	if rig.unlock_drop_active or str(rig.lock_state) == ActivityLockRig.LOCK_STATE_DROPPING or str(rig.lock_state) == ActivityLockRig.LOCK_STATE_GONE:
		return false
	return true


func _rig_accepts_input(rig: ActivityLockRig) -> bool:
	if rig == null or not is_instance_valid(rig) or not rig.visible:
		return false
	if str(rig.lock_state) == ActivityLockRig.LOCK_STATE_DROPPING or str(rig.lock_state) == ActivityLockRig.LOCK_STATE_GONE:
		return false
	return true


func _clear_rigs() -> void:
	for child in get_children():
		child.queue_free()
	rigs.clear()
	active_rig = null
	shared_chain_rig = null
	shared_motion_source = null
	unlock_drop_active = false
	unlock_drop_tween = null
	_set_ready_pulse(false)
	set_process(false)
