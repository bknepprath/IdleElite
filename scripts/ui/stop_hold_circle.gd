extends Control


const ACTION_STOP_HOLD_ARM_DELAY_SECONDS := 0.16
const ACTION_STOP_HOLD_SECONDS := 0.45
const ACTION_STOP_HOLD_UNLOAD_SECONDS := 0.18
const ACTION_STOP_HOLD_RING_SIZE := Vector2(190, 190)
const ThemeStyles = preload("res://scripts/ui/theme_styles.gd")

var progress := 0.0
var unload_progress := 0.0
var unloading := false
var show_question := false
var theme_color := Color("#3aa0ff")
var host
var action_stop_hold_kind := ""
var action_stop_hold_active := false
var action_stop_hold_armed := false
var action_stop_hold_unloading := false
var action_stop_hold_skill_id := ""
var action_stop_hold_action_id := ""
var action_stop_hold_stat_kind := ""
var action_stop_hold_card_key := ""
var action_stop_hold_elapsed := 0.0
var action_stop_hold_unload_elapsed := 0.0
var action_stop_hold_pointer_id := -1
var action_stop_hold_position := Vector2.ZERO
var action_stop_hold_start_position := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = ACTION_STOP_HOLD_RING_SIZE
	visible = false


func setup(host_ref) -> void:
	host = host_ref


func active() -> bool:
	return action_stop_hold_active or action_stop_hold_unloading


func begin_action(skill_id: String, action_id: String, pointer_position: Vector2, pointer_id: int) -> void:
	begin_info(skill_id, action_id, "", host._action_key(skill_id, action_id), pointer_position, pointer_id)
	action_stop_hold_kind = "action"


func begin_info(skill_id: String, action_id: String, stat_kind: String, card_key: String, pointer_position: Vector2, pointer_id: int) -> void:
	action_stop_hold_kind = "info"
	action_stop_hold_active = true
	action_stop_hold_armed = false
	action_stop_hold_unloading = false
	action_stop_hold_skill_id = skill_id
	action_stop_hold_action_id = action_id
	action_stop_hold_stat_kind = stat_kind
	action_stop_hold_card_key = card_key
	action_stop_hold_elapsed = 0.0
	action_stop_hold_unload_elapsed = 0.0
	action_stop_hold_pointer_id = pointer_id
	action_stop_hold_start_position = pointer_position
	host._skill_detail_surface().action_card_press_key = ""
	host._skill_detail_surface().action_card_press_stat_kind = ""
	host._skill_detail_surface().action_card_press_dragged = false
	_update_position(pointer_position)
	hide_ring()


func route_input(event: InputEvent) -> bool:
	if not action_stop_hold_active and not action_stop_hold_unloading:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and action_stop_hold_pointer_id >= 0:
		return true
	if event is InputEventMouseMotion and action_stop_hold_pointer_id >= 0:
		return true
	if event is InputEventScreenTouch and action_stop_hold_pointer_id < 0:
		return true
	if event is InputEventScreenDrag and action_stop_hold_pointer_id < 0:
		return true
	if event is InputEventMouseMotion and action_stop_hold_active and action_stop_hold_pointer_id < 0:
		var event_position := (event as InputEventMouseMotion).global_position
		if _motion_is_scroll_drag(event_position):
			cancel_action()
			return false
		if not action_stop_hold_armed:
			return _handoff_to_swipe_if_needed(event_position)
		if _cancel_if_pointer_left_start_circle(event_position):
			return true
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and action_stop_hold_pointer_id < 0:
		if not event.pressed and action_stop_hold_active:
			if action_stop_hold_kind == "action" and not action_stop_hold_armed:
				_finish_pending_click(event.global_position)
			cancel_action()
		return true
	if event is InputEventScreenDrag and action_stop_hold_active and event.index == action_stop_hold_pointer_id:
		var event_position := (event as InputEventScreenDrag).position
		if _motion_is_scroll_drag(event_position):
			cancel_action()
			return false
		if not action_stop_hold_armed:
			return _handoff_to_swipe_if_needed(event_position)
		if _cancel_if_pointer_left_start_circle(event_position):
			return true
		return true
	if event is InputEventScreenTouch and event.index == action_stop_hold_pointer_id:
		if not event.pressed and action_stop_hold_active:
			if action_stop_hold_kind == "action" and not action_stop_hold_armed:
				_finish_pending_click(event.position)
			cancel_action()
		return true
	return action_stop_hold_unloading


func process_action(delta: float) -> void:
	if not action_stop_hold_active and not action_stop_hold_unloading:
		return
	var card := host.action_cards.get(action_stop_hold_card_key, {}) as Dictionary
	if action_stop_hold_kind == "action":
		if host.running_skill_id != action_stop_hold_skill_id or host.running_action_id != action_stop_hold_action_id or host.running_action_id.is_empty():
			cancel_action()
			return
	elif card.is_empty() or host._action_data(action_stop_hold_skill_id, action_stop_hold_action_id).is_empty():
		cancel_action()
		return
	if action_stop_hold_unloading:
		action_stop_hold_unload_elapsed += delta
		var unload := clampf(action_stop_hold_unload_elapsed / ACTION_STOP_HOLD_UNLOAD_SECONDS, 0.0, 1.0)
		sync_ring(action_stop_hold_position, 1.0, unload, true)
		if unload >= 1.0:
			var skill_id := action_stop_hold_skill_id
			var action_id := action_stop_hold_action_id
			var stat_kind := action_stop_hold_stat_kind
			var card_key := action_stop_hold_card_key
			var hold_kind := action_stop_hold_kind
			hide_ring()
			if hold_kind == "action":
				host._skill_swipe_activity_surface()._release_action_card_3d_press(card_key)
			clear_state()
			if hold_kind == "action":
				host._action_runtime()._stop_running_action(skill_id, action_id)
			else:
				host._skill_detail_surface()._toggle_activity_stat_popup_for_card(card, skill_id, action_id, stat_kind)
		return
	if not action_stop_hold_armed:
		if action_stop_hold_pointer_id < 0 and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			cancel_action()
			return
		action_stop_hold_elapsed += delta
		if action_stop_hold_elapsed < ACTION_STOP_HOLD_ARM_DELAY_SECONDS:
			return
		action_stop_hold_armed = true
		action_stop_hold_elapsed = 0.0
		host._skill_swipe_activity_surface().skill_swipe_tracking = false
		host._skill_swipe_activity_surface().skill_swipe_horizontal = false
		host._skill_swipe_activity_surface().skill_swipe_touch_index = -1
		if action_stop_hold_kind == "action":
			host._skill_swipe_activity_surface()._press_action_card_3d(action_stop_hold_card_key)
			show_ring(ThemeStyles.skill_theme_color(action_stop_hold_skill_id, host.COLOR_BLUE), action_stop_hold_position)
		else:
			host._skill_swipe_activity_surface()._press_activity_stat_box(action_stop_hold_card_key, action_stop_hold_stat_kind)
			show_ring(ThemeStyles.skill_theme_color(action_stop_hold_skill_id, host.COLOR_BLUE), action_stop_hold_position, true)
		return
	action_stop_hold_elapsed += delta
	var progress_value := clampf(action_stop_hold_elapsed / ACTION_STOP_HOLD_SECONDS, 0.0, 1.0)
	sync_ring(action_stop_hold_position, progress_value, 0.0, false)
	if progress_value >= 1.0:
		action_stop_hold_active = false
		action_stop_hold_unloading = true
		action_stop_hold_unload_elapsed = 0.0
		sync_ring(action_stop_hold_position, 1.0, 0.0, true)


func cancel_action() -> void:
	var hold_kind := action_stop_hold_kind
	var card_key := action_stop_hold_card_key
	hide_ring()
	if hold_kind == "action":
		host._skill_swipe_activity_surface()._release_action_card_3d_press(card_key)
	clear_state()


func clear_state() -> void:
	action_stop_hold_kind = ""
	action_stop_hold_active = false
	action_stop_hold_armed = false
	action_stop_hold_unloading = false
	action_stop_hold_skill_id = ""
	action_stop_hold_action_id = ""
	action_stop_hold_stat_kind = ""
	action_stop_hold_card_key = ""
	action_stop_hold_elapsed = 0.0
	action_stop_hold_unload_elapsed = 0.0
	action_stop_hold_pointer_id = -1
	action_stop_hold_start_position = Vector2.ZERO


func cancel_if_scroll_drag_event(event: InputEvent) -> bool:
	if not action_stop_hold_active:
		return false
	var event_position := Vector2.INF
	if event is InputEventMouseMotion:
		if action_stop_hold_pointer_id >= 0:
			return false
		event_position = (event as InputEventMouseMotion).global_position
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if drag_event.index != action_stop_hold_pointer_id:
			return false
		event_position = drag_event.position
	else:
		return false
	if event_position == Vector2.INF or not _motion_is_scroll_drag(event_position):
		return false
	cancel_action()
	return true


func show_ring(color: Color, ring_position: Vector2, question := false) -> void:
	theme_color = color
	show_question = question
	size = ACTION_STOP_HOLD_RING_SIZE
	_update_position(ring_position)
	if modulate != Color.WHITE:
		modulate = Color.WHITE
	visible = true
	set_progress(0.0, 0.0, false)


func sync_ring(ring_position: Vector2, next_progress: float, next_unload: float, is_unloading: bool) -> void:
	if is_queued_for_deletion():
		return
	_update_position(ring_position)
	set_progress(next_progress, next_unload, is_unloading)


func hide_ring() -> void:
	if not is_queued_for_deletion():
		visible = false
		show_question = false
		set_progress(0.0, 0.0, false)

func set_progress(next_progress: float, next_unload := 0.0, is_unloading := false) -> void:
	progress = clampf(next_progress, 0.0, 1.0)
	unload_progress = clampf(next_unload, 0.0, 1.0)
	unloading = is_unloading
	queue_redraw()


func _update_position(pointer_position: Vector2) -> void:
	action_stop_hold_position = pointer_position
	position = pointer_position - ACTION_STOP_HOLD_RING_SIZE * 0.5


func _handoff_to_swipe_if_needed(pointer_position: Vector2) -> bool:
	if pointer_position.distance_to(action_stop_hold_start_position) < host.SKILL_SWIPE_FEEDBACK_DEADZONE:
		return true
	var start_position := action_stop_hold_start_position
	var pointer_id := action_stop_hold_pointer_id
	cancel_action()
	host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(start_position, pointer_id)
	host._skill_swipe_activity_surface()._update_skill_swipe_feedback(pointer_position)
	return true


func _cancel_if_pointer_left_start_circle(pointer_position: Vector2) -> bool:
	if _pointer_inside_start_circle(pointer_position):
		return false
	cancel_action()
	return true


func _pointer_inside_start_circle(pointer_position: Vector2) -> bool:
	var radius := minf(ACTION_STOP_HOLD_RING_SIZE.x, ACTION_STOP_HOLD_RING_SIZE.y) * 0.5
	return pointer_position.distance_to(action_stop_hold_start_position) <= radius


func _finish_pending_click(release_position: Vector2) -> void:
	if release_position.distance_to(action_stop_hold_start_position) > host.ACTION_CARD_TAP_RELEASE_SLOP:
		return
	host._action_runtime()._miss_action_opportunity_click(action_stop_hold_skill_id, action_stop_hold_action_id, release_position)


func _motion_is_scroll_drag(event_position: Vector2) -> bool:
	var drag_offset := event_position - action_stop_hold_start_position
	return (
		absf(drag_offset.y) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	)

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.39
	var width := maxf(10.0, radius * 0.24)
	var fill := theme_color
	fill.a = (0.96 if not unloading else 0.78) * modulate.a
	var visible_progress := clampf(progress - unload_progress, 0.0, 1.0)
	if visible_progress > 0.001:
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * visible_progress, 40, fill, width, true)
	if show_question:
		fill.a *= 1.0 - unload_progress
		draw_string(ThemeDB.fallback_font, Vector2(center.x - radius, center.y + 36.0), "?", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 112, fill)
