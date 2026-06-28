class_name MobileScrollContainer
extends ScrollContainer

signal user_scroll_direction(direction: int)
signal pull_offset_changed(offset_y: float)

const DRAG_DEADZONE := 18.0
const FLICK_SAMPLE_SECONDS := 0.14
const FLICK_MIN_VELOCITY := 90.0
const FLICK_MAX_VELOCITY := 4200.0
const INERTIA_DECAY := 5.4
const PULL_RESISTANCE_MAX := 210.0
const PULL_SNAP_SECONDS := 0.34
const WHEEL_STEP := 220.0
const WHEEL_MAX_IMMEDIATE_DELTA := 36.0
const WHEEL_VELOCITY_SCALE := 12.0
const WHEEL_MAX_VELOCITY := 7200.0

var drag_tracking := false
var drag_scrolling := false
var drag_start := Vector2.ZERO
var drag_last := Vector2.ZERO
var drag_touch_index := -1
var drag_scroll_position := 0.0
var drag_velocity_samples := []
var velocity := 0.0
var pull_resistance_enabled := false
var pull_raw_offset := 0.0
var pull_offset := 0.0
var pull_anchor_position_y := 0.0
var pull_anchor_position_valid := false
var child_click_suppressed := false
var input_locked_by_activity_lock := false
var max_scroll_override := -1
var content_scroll_enabled := true
var scroll_tween: Tween
var pull_tween: Tween
var drag_last_apply_frame := -1
var drag_pending_position := Vector2.ZERO
var drag_pending_valid := false
var modal_block_cache_frame := -1
var modal_block_cache_value := false
var max_scroll_cache_frame := -1
var max_scroll_cache_value := 0

func _ready() -> void:
	set_process(false)
	scroll_deadzone = int(DRAG_DEADZONE)

func _gui_input(event: InputEvent) -> void:
	if not content_scroll_enabled:
		if event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_WHEEL_DOWN or event.button_index == MOUSE_BUTTON_WHEEL_UP):
			_set_scroll_vertical_float(0.0)
			accept_event()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			user_scroll_direction.emit(1)
			_apply_wheel_step(1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			user_scroll_direction.emit(-1)
			_apply_wheel_step(-1)
			accept_event()

func set_pull_resistance_enabled(enabled: bool) -> void:
	pull_resistance_enabled = enabled
	if not enabled:
		_set_pull_raw_offset(0.0)
		_cancel_pull_tween()

func set_input_locked_by_activity_lock(locked: bool) -> void:
	input_locked_by_activity_lock = locked
	if locked:
		drag_tracking = false
		drag_scrolling = false
		drag_touch_index = -1
		velocity = 0.0
		child_click_suppressed = false
		_clear_pending_drag_motion()
		_cancel_scroll_tween()
		_cancel_pull_tween()

func set_max_scroll_override(next_max_scroll: int) -> void:
	max_scroll_override = next_max_scroll
	max_scroll_cache_frame = -1
	_clamp_to_current_content_height()

func set_scroll_enabled_by_content(enabled: bool) -> void:
	content_scroll_enabled = enabled
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER if enabled else ScrollContainer.SCROLL_MODE_DISABLED
	if not enabled:
		drag_tracking = false
		drag_scrolling = false
		drag_touch_index = -1
		velocity = 0.0
		_cancel_scroll_tween()
		_cancel_pull_tween()
		_set_pull_raw_offset(0.0)
		_set_scroll_vertical_float(0.0)

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if not content_scroll_enabled:
		drag_tracking = false
		drag_scrolling = false
		drag_touch_index = -1
		velocity = 0.0
		child_click_suppressed = false
		_clear_pending_drag_motion()
		_set_pull_raw_offset(0.0)
		_set_scroll_vertical_float(0.0)
		return
	if input_locked_by_activity_lock or _modal_blocks_this_scroll():
		drag_tracking = false
		drag_scrolling = false
		velocity = 0.0
		_clear_pending_drag_motion()
		_cancel_scroll_tween()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _contains_global_point(event.global_position):
				_cancel_scroll_tween()
				_cancel_pull_tween()
				drag_tracking = true
				drag_scrolling = false
				drag_start = event.global_position
				drag_last = event.global_position
				drag_touch_index = -1
				drag_scroll_position = float(scroll_vertical)
				_reset_drag_velocity_samples(event.global_position)
				_clear_pending_drag_motion()
				velocity = 0.0
		elif drag_tracking:
			if drag_scrolling:
				_apply_pending_drag_motion()
				child_click_suppressed = true
				_apply_release_velocity(event.global_position)
				get_viewport().set_input_as_handled()
			drag_tracking = false
			drag_scrolling = false
			drag_touch_index = -1
			_clear_pending_drag_motion()
			_snap_pull_offset()
			if child_click_suppressed:
				call_deferred("_clear_child_click_suppression")
		elif child_click_suppressed:
			call_deferred("_clear_child_click_suppression")
		return
	if event is InputEventMouseMotion and drag_tracking:
		var distance: float = event.global_position.distance_to(drag_start)
		var drag_offset: Vector2 = event.global_position - drag_start
		if distance >= DRAG_DEADZONE and absf(drag_offset.y) > absf(drag_offset.x) * 1.15:
			drag_scrolling = true
		if drag_scrolling:
			child_click_suppressed = true
			_apply_or_queue_drag_motion(event.global_position)
			get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed:
			if _contains_global_point(event.position):
				_cancel_scroll_tween()
				_cancel_pull_tween()
				drag_tracking = true
				drag_scrolling = false
				drag_start = event.position
				drag_last = event.position
				drag_touch_index = event.index
				drag_scroll_position = float(scroll_vertical)
				_reset_drag_velocity_samples(event.position)
				_clear_pending_drag_motion()
				velocity = 0.0
		elif drag_tracking and event.index == drag_touch_index:
			if drag_scrolling:
				_apply_pending_drag_motion()
				child_click_suppressed = true
				_apply_release_velocity(event.position)
				get_viewport().set_input_as_handled()
			drag_tracking = false
			drag_scrolling = false
			drag_touch_index = -1
			_clear_pending_drag_motion()
			_snap_pull_offset()
			if child_click_suppressed:
				call_deferred("_clear_child_click_suppression")
		elif child_click_suppressed:
			call_deferred("_clear_child_click_suppression")
		return
	if event is InputEventScreenDrag and drag_tracking and event.index == drag_touch_index:
		var distance: float = event.position.distance_to(drag_start)
		var drag_offset: Vector2 = event.position - drag_start
		if distance >= DRAG_DEADZONE and absf(drag_offset.y) > absf(drag_offset.x) * 1.15:
			drag_scrolling = true
		if drag_scrolling:
			child_click_suppressed = true
			_apply_or_queue_drag_motion(event.position)
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and _contains_global_point(event.global_position):
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			user_scroll_direction.emit(1)
			_apply_wheel_step(1)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			user_scroll_direction.emit(-1)
			_apply_wheel_step(-1)
			get_viewport().set_input_as_handled()
			return

func _process(delta: float) -> void:
	if not content_scroll_enabled:
		drag_tracking = false
		drag_scrolling = false
		drag_touch_index = -1
		velocity = 0.0
		child_click_suppressed = false
		_clear_pending_drag_motion()
		_set_pull_raw_offset(0.0)
		_set_scroll_vertical_float(0.0)
		set_process(false)
		return
	if input_locked_by_activity_lock or _modal_blocks_this_scroll():
		velocity = 0.0
		_clear_pending_drag_motion()
		set_process(false)
		return
	_clamp_to_current_content_height()
	if drag_tracking and drag_scrolling and drag_pending_valid:
		_apply_pending_drag_motion()
	if drag_tracking or absf(pull_offset) > 0.0 or absf(velocity) < 4.0:
		if not drag_tracking and absf(pull_offset) <= 0.0 and absf(velocity) < 4.0:
			velocity = 0.0
			set_process(false)
		return
	var old_scroll := drag_scroll_position
	_set_scroll_vertical_float(drag_scroll_position + velocity * delta)
	_emit_user_scroll_direction_from_delta(drag_scroll_position - old_scroll)
	velocity = lerpf(velocity, 0.0, 1.0 - exp(-INERTIA_DECAY * delta))
	if absf(velocity) < 4.0:
		velocity = 0.0
		set_process(false)

func _clamp_to_current_content_height() -> void:
	var max_scroll := get_max_scroll_vertical()
	if drag_tracking and absf(pull_raw_offset) > 0.0:
		_pin_scroll_to_active_pull_edge(max_scroll)
		return
	if scroll_vertical <= max_scroll and drag_scroll_position <= float(max_scroll):
		drag_scroll_position = clampf(float(scroll_vertical), 0.0, float(max_scroll))
		return
	velocity = 0.0
	_set_scroll_vertical_float(float(max_scroll))

func _apply_wheel_step(direction: int) -> void:
	if not content_scroll_enabled:
		_set_scroll_vertical_float(0.0)
		return
	_apply_wheel_scroll_delta(float(direction) * WHEEL_STEP)


func _apply_wheel_scroll_delta(scroll_delta: float) -> void:
	if absf(scroll_delta) <= 0.01:
		return
	_cancel_scroll_tween()
	_cancel_pull_tween()
	_set_pull_raw_offset(0.0)
	var immediate_delta := clampf(scroll_delta, -WHEEL_MAX_IMMEDIATE_DELTA, WHEEL_MAX_IMMEDIATE_DELTA)
	var old_scroll := drag_scroll_position
	_set_scroll_vertical_float(float(scroll_vertical) + immediate_delta)
	_emit_user_scroll_direction_from_delta(drag_scroll_position - old_scroll)
	var residual_delta := scroll_delta - immediate_delta
	if absf(residual_delta) <= 0.01:
		velocity = 0.0
		return
	velocity = clampf(velocity + residual_delta * WHEEL_VELOCITY_SCALE, -WHEEL_MAX_VELOCITY, WHEEL_MAX_VELOCITY)
	if absf(velocity) >= 4.0:
		set_process(true)


func apply_direct_wheel_delta(delta_y: float) -> void:
	if not content_scroll_enabled:
		_set_scroll_vertical_float(0.0)
		return
	if absf(delta_y) <= 0.01:
		return
	var scroll_delta := clampf(delta_y, -420.0, 420.0)
	_apply_wheel_scroll_delta(scroll_delta)

func _apply_drag_delta(delta_y: float) -> void:
	if pull_resistance_enabled:
		if absf(pull_raw_offset) > 0.0:
			var next_pull_raw_offset := pull_raw_offset + delta_y
			if pull_raw_offset > 0.0 and next_pull_raw_offset < 0.0:
				next_pull_raw_offset = 0.0
			elif pull_raw_offset < 0.0 and next_pull_raw_offset > 0.0:
				next_pull_raw_offset = 0.0
			if absf(next_pull_raw_offset) > 0.0:
				_pin_scroll_to_active_pull_edge()
			_set_pull_raw_offset(next_pull_raw_offset)
			velocity = 0.0
			return
		var max_scroll := float(get_max_scroll_vertical())
		var requested_scroll := drag_scroll_position - delta_y
		if requested_scroll < 0.0:
			_set_scroll_vertical_float(0.0)
			_set_pull_raw_offset(-requested_scroll)
			velocity = 0.0
			return
		if requested_scroll > max_scroll:
			_set_scroll_vertical_float(max_scroll)
			_set_pull_raw_offset(max_scroll - requested_scroll)
			velocity = 0.0
			return
	var old_scroll := drag_scroll_position
	_set_scroll_vertical_float(drag_scroll_position - delta_y)
	_emit_user_scroll_direction_from_delta(drag_scroll_position - old_scroll)
	velocity = -delta_y * 60.0


func handoff_drag_scroll(press_position: Vector2, current_position: Vector2, touch_index := -1) -> void:
	if not is_visible_in_tree() or not content_scroll_enabled:
		return
	if input_locked_by_activity_lock or _modal_blocks_this_scroll():
		return
	if not _contains_global_point(press_position) and not _contains_global_point(current_position):
		return
	_cancel_scroll_tween()
	_cancel_pull_tween()
	drag_tracking = true
	drag_scrolling = true
	drag_start = press_position
	drag_last = press_position
	drag_touch_index = touch_index
	drag_scroll_position = float(scroll_vertical)
	_reset_drag_velocity_samples(press_position)
	velocity = 0.0
	child_click_suppressed = true
	_clear_pending_drag_motion()
	_apply_drag_motion_position(current_position)
	get_viewport().set_input_as_handled()


func _apply_or_queue_drag_motion(pointer_position: Vector2) -> void:
	var current_frame := Engine.get_process_frames()
	if drag_last_apply_frame == current_frame:
		drag_pending_position = pointer_position
		drag_pending_valid = true
		set_process(true)
		return
	_apply_drag_motion_position(pointer_position)


func _apply_pending_drag_motion() -> void:
	if not drag_pending_valid:
		return
	var pending_position := drag_pending_position
	drag_pending_valid = false
	_apply_drag_motion_position(pending_position)


func _apply_drag_motion_position(pointer_position: Vector2) -> void:
	drag_last_apply_frame = Engine.get_process_frames()
	var delta_y: float = pointer_position.y - drag_last.y
	_apply_drag_delta(delta_y)
	drag_last = pointer_position
	_record_drag_velocity_sample(pointer_position)


func _clear_pending_drag_motion() -> void:
	drag_pending_valid = false
	drag_pending_position = Vector2.ZERO
	drag_last_apply_frame = -1


func _set_scroll_vertical_float(next_value: float) -> void:
	if not content_scroll_enabled:
		drag_scroll_position = 0.0
		scroll_vertical = 0
		for child in get_children():
			if child is Control:
				var control := child as Control
				control.position.y = 0.0
		return
	drag_scroll_position = clampf(next_value, 0.0, float(get_max_scroll_vertical()))
	scroll_vertical = int(round(drag_scroll_position))

func _pin_scroll_to_active_pull_edge(max_scroll := -1) -> void:
	if max_scroll < 0:
		max_scroll = get_max_scroll_vertical()
	var boundary := 0.0 if pull_raw_offset > 0.0 else float(max_scroll)
	drag_scroll_position = boundary
	scroll_vertical = int(round(boundary))

func _contains_global_point(point: Vector2) -> bool:
	return Rect2(global_position, size).has_point(point)

func _reset_drag_velocity_samples(pointer_position: Vector2) -> void:
	drag_velocity_samples.clear()
	_record_drag_velocity_sample(pointer_position)

func _record_drag_velocity_sample(pointer_position: Vector2) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	drag_velocity_samples.append({"position": pointer_position, "time": now})
	while drag_velocity_samples.size() > 2 and now - float(drag_velocity_samples[0]["time"]) > FLICK_SAMPLE_SECONDS:
		drag_velocity_samples.pop_front()

func _apply_release_velocity(pointer_position: Vector2) -> void:
	if absf(pull_raw_offset) > 0.0 or drag_velocity_samples.is_empty():
		velocity = 0.0
		return
	_record_drag_velocity_sample(pointer_position)
	var newest: Dictionary = drag_velocity_samples[drag_velocity_samples.size() - 1]
	var oldest: Dictionary = drag_velocity_samples[0]
	var elapsed := float(newest["time"]) - float(oldest["time"])
	if elapsed <= 0.0:
		return
	var delta_y := (newest["position"] as Vector2).y - (oldest["position"] as Vector2).y
	var release_velocity := clampf(-delta_y / elapsed, -FLICK_MAX_VELOCITY, FLICK_MAX_VELOCITY)
	velocity = release_velocity if absf(release_velocity) >= FLICK_MIN_VELOCITY else 0.0
	if absf(velocity) >= 4.0:
		set_process(true)

func _modal_blocks_this_scroll() -> bool:
	var current_frame := Engine.get_process_frames()
	if modal_block_cache_frame == current_frame:
		return modal_block_cache_value
	modal_block_cache_frame = current_frame
	modal_block_cache_value = false
	var tree := get_tree()
	if tree == null:
		return false
	for node in tree.get_nodes_in_group("modal_overlay"):
		var modal := node as Control
		if modal != null and modal.visible and modal.is_visible_in_tree() and not _is_descendant_of(modal):
			modal_block_cache_value = true
			return true
	return false

func _is_descendant_of(node: Node) -> bool:
	var current: Node = self
	while current != null:
		if current == node:
			return true
		current = current.get_parent()
	return false

func get_max_scroll_vertical() -> int:
	if not content_scroll_enabled:
		return 0
	var current_frame := Engine.get_process_frames()
	if max_scroll_cache_frame == current_frame:
		return max_scroll_cache_value
	var scroll_bar := get_v_scroll_bar()
	var natural_max := 0
	if scroll_bar != null:
		natural_max = maxi(0, int(ceil(scroll_bar.max_value - scroll_bar.page)))
	else:
		var max_scroll: float = 0.0
		for child in get_children():
			if child is Control:
				var control := child as Control
				if not control.visible or control.is_queued_for_deletion():
					continue
				max_scroll = maxf(max_scroll, control.position.y + control.size.y)
		natural_max = maxi(0, int(ceil(max_scroll - size.y)))
	if max_scroll_override >= 0:
		max_scroll_cache_value = mini(natural_max, max_scroll_override)
	else:
		max_scroll_cache_value = natural_max
	max_scroll_cache_frame = current_frame
	return max_scroll_cache_value

func scroll_to_vertical(target: int, duration := 0.26, transition := Tween.TRANS_CUBIC, ease_type := Tween.EASE_OUT) -> void:
	_cancel_scroll_tween()
	velocity = 0.0
	if not content_scroll_enabled:
		_set_scroll_vertical_float(0.0)
		return
	var clamped_target := clampi(target, 0, get_max_scroll_vertical())
	if duration <= 0.0:
		drag_scroll_position = float(clamped_target)
		scroll_vertical = clamped_target
		return
	scroll_tween = create_tween()
	scroll_tween.tween_method(_set_scroll_vertical_float, float(scroll_vertical), float(clamped_target), duration).set_trans(transition).set_ease(ease_type)
	scroll_tween.finished.connect(_finish_scroll_to_vertical.bind(clamped_target))

func _finish_scroll_to_vertical(clamped_target: int) -> void:
	_set_scroll_vertical_float(float(clamped_target))
	scroll_tween = null

func is_child_click_suppressed() -> bool:
	return child_click_suppressed or drag_scrolling or absf(velocity) >= 4.0

func prepare_child_tap() -> void:
	child_click_suppressed = false
	drag_scrolling = false
	velocity = 0.0
	_cancel_scroll_tween()

func _clear_child_click_suppression() -> void:
	child_click_suppressed = false

func _cancel_scroll_tween() -> void:
	if scroll_tween != null and scroll_tween.is_valid():
		scroll_tween.kill()
		drag_scroll_position = float(scroll_vertical)
	scroll_tween = null

func _emit_user_scroll_direction_from_delta(delta: float) -> void:
	if absf(delta) < 0.5:
		return
	user_scroll_direction.emit(1 if delta > 0.0 else -1)

func _set_pull_raw_offset(next_raw_offset: float) -> void:
	_capture_pull_anchor_position()
	pull_raw_offset = next_raw_offset
	var direction := signf(pull_raw_offset)
	pull_offset = direction * PULL_RESISTANCE_MAX * (1.0 - exp(-absf(pull_raw_offset) / PULL_RESISTANCE_MAX))
	position.y = pull_anchor_position_y + pull_offset
	pull_offset_changed.emit(pull_offset)
	if absf(pull_offset) <= 0.0 and pull_tween == null:
		pull_anchor_position_valid = false

func _snap_pull_offset() -> void:
	if not pull_resistance_enabled and absf(pull_offset) <= 0.0:
		pull_raw_offset = 0.0
		pull_offset = 0.0
		pull_anchor_position_valid = false
		return
	if absf(pull_offset) <= 0.0:
		_set_pull_raw_offset(0.0)
		return
	_cancel_pull_tween()
	velocity = 0.0
	_capture_pull_anchor_position()
	pull_raw_offset = 0.0
	pull_offset_changed.emit(0.0)
	pull_tween = create_tween()
	pull_tween.tween_property(self, "position:y", pull_anchor_position_y, PULL_SNAP_SECONDS).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	pull_tween.finished.connect(_finish_pull_snap)

func _finish_pull_snap() -> void:
	pull_offset = 0.0
	pull_raw_offset = 0.0
	position.y = pull_anchor_position_y
	pull_anchor_position_valid = false
	pull_tween = null

func _cancel_pull_tween() -> void:
	if pull_tween != null and pull_tween.is_valid():
		pull_tween.kill()
		_capture_pull_anchor_position()
		pull_offset = position.y - pull_anchor_position_y
		var pull_pct := clampf(absf(pull_offset) / PULL_RESISTANCE_MAX, 0.0, 0.98)
		pull_raw_offset = signf(pull_offset) * -PULL_RESISTANCE_MAX * log(1.0 - pull_pct)
	pull_tween = null

func _capture_pull_anchor_position() -> void:
	if pull_anchor_position_valid:
		return
	pull_anchor_position_y = position.y - pull_offset
	pull_anchor_position_valid = true


