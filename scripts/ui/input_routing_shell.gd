extends RefCounted

const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")

var host
var modal_background_input_block_until_msec := 0
var activity_lock_input_active := false
var active_activity_lock_rig: Control
var fishing_detail_swipe_press_active := false
var fishing_detail_swipe_press_position := Vector2.ZERO
var fishing_detail_swipe_press_touch_index := -1


func _init(host_ref) -> void:
	host = host_ref


func _global_event_position(local_position: Vector2, event_global_position: Vector2, source: Control = null) -> Vector2:
	if source != null and is_instance_valid(source):
		var source_local_rect := Rect2(Vector2.ZERO, source.size)
		if event_global_position.distance_squared_to(local_position) <= 0.25 and source_local_rect.has_point(local_position):
			return source.get_global_position() + local_position
	if event_global_position != Vector2.ZERO:
		return event_global_position
	if source != null and is_instance_valid(source):
		return source.get_global_position() + local_position
	return local_position


func _is_primary_press_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _passive_button_event_position(event: InputEvent, source: Control) -> Vector2:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return _global_event_position(mouse_event.position, mouse_event.global_position, source)
	if event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		return _global_event_position(motion_event.position, motion_event.global_position, source)
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return _global_event_position(touch_event.position, touch_event.position, source)
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		return _global_event_position(drag_event.position, drag_event.position, source)
	return Vector2.ZERO


func _activity_input_position_candidates(event_position: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	_add_unique_event_position(positions, event_position)
	var window_size := Vector2.ZERO
	if DisplayServer.get_name() != "headless":
		window_size = Vector2(DisplayServer.window_get_size())
	if window_size.x > 1.0 and window_size.y > 1.0:
		_add_unique_event_position(positions, event_position * (host.BASE_CANVAS.x / window_size.x))
		_add_unique_event_position(positions, event_position * (host.BASE_CANVAS.y / window_size.y))
		_add_unique_event_position(positions, Vector2(event_position.x * host.BASE_CANVAS.x / window_size.x, event_position.y * host.BASE_CANVAS.y / window_size.y))
	if host.is_inside_tree():
		var visible_size: Vector2 = host.get_viewport_rect().size
		if visible_size.x > 1.0 and visible_size.y > 1.0:
			_add_unique_event_position(positions, event_position * (host.BASE_CANVAS.x / visible_size.x))
			_add_unique_event_position(positions, event_position * (host.BASE_CANVAS.y / visible_size.y))
	return positions


func _action_card_event_positions(event: InputEvent, source: Control) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if source == null:
		return positions
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var source_local_rect := Rect2(Vector2.ZERO, source.size)
		var mouse_position_is_local := source_local_rect.has_point(mouse_event.position)
		if mouse_position_is_local:
			_add_unique_event_position(positions, mouse_event.global_position)
			_add_unique_event_position(positions, source.get_global_position() + mouse_event.position)
		else:
			for event_position in _activity_input_position_candidates(mouse_event.global_position):
				_add_unique_event_position(positions, event_position)
			for event_position in _activity_input_position_candidates(mouse_event.position):
				_add_unique_event_position(positions, event_position)
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		var source_local_rect := Rect2(Vector2.ZERO, source.size)
		var touch_position_is_local := source_local_rect.has_point(touch_event.position)
		if touch_position_is_local:
			_add_unique_event_position(positions, source.get_global_position() + touch_event.position)
		else:
			for event_position in _activity_input_position_candidates(touch_event.position):
				_add_unique_event_position(positions, event_position)
	return positions


func _add_unique_event_position(positions: Array[Vector2], event_position: Vector2) -> void:
	for existing in positions:
		if existing.distance_to(event_position) <= 0.5:
			return
	positions.append(event_position)


func _first_position_in_rect(positions: Array[Vector2], rect: Rect2) -> Variant:
	for event_position in positions:
		if rect.has_point(event_position):
			return event_position
	return null


func _first_event_position(positions: Array[Vector2]) -> Vector2:
	return positions[0] if not positions.is_empty() else Vector2.ZERO


func _event_positions_close_to_press(positions: Array[Vector2]) -> bool:
	return _event_positions_within_press_slop(positions, host.ACTION_CARD_TAP_RELEASE_SLOP)


func _event_positions_within_press_slop(positions: Array[Vector2], slop: float) -> bool:
	for event_position in positions:
		if event_position.distance_to(host._skill_detail_surface().action_card_press_position) <= slop:
			return true
	return false


func _event_points_inside_bottom_interactive_ui(event: InputEvent, source: Control = null, nav_only := false) -> bool:
	var positions: Array[Vector2] = []
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		_add_unique_event_position(positions, _global_event_position(mouse_event.position, mouse_event.global_position, source))
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_add_unique_event_position(positions, _global_event_position(motion_event.position, motion_event.global_position, source))
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		_add_unique_event_position(positions, _global_event_position(touch_event.position, touch_event.position, source))
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_add_unique_event_position(positions, _global_event_position(drag_event.position, drag_event.position, source))
	for event_position in positions:
		if nav_only:
			if host._navigation_shell()._position_inside_bottom_nav(event_position):
				return true
		elif _position_inside_bottom_interactive_ui(event_position):
			return true
	return false


func _position_inside_bottom_interactive_ui(event_position: Vector2) -> bool:
	for raw_control in [host._navigation_shell().module_sort_menu, host._navigation_shell().module_utility_row, host._profile_chat_overlay_surface().chat_strip_control(), host._navigation_shell().nav_bar]:
		var control := raw_control as Control
		if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
			continue
		var control_rect := control.get_global_rect().grow(4.0)
		for candidate in _activity_input_position_candidates(event_position):
			if control_rect.has_point(candidate):
				return true
	return false


func _position_inside_detail_actions_viewport(event_position: Vector2, viewport_outset := 2.0) -> bool:
	var viewport_control: Control = null
	if host.current_screen == "skill":
		viewport_control = host._skill_detail_surface().detail_actions_scroll
	elif host.current_screen == "pinned" or host.current_screen == "queue":
		viewport_control = host.content_scroll
	elif host.current_screen == "menu":
		return _position_inside_skill_menu_active_drawer(event_position)
	if viewport_control == null or not is_instance_valid(viewport_control):
		return false
	if not viewport_control.is_visible_in_tree():
		return false
	var viewport_rect := viewport_control.get_global_rect().grow(viewport_outset)
	for candidate in _activity_input_position_candidates(event_position):
		if viewport_rect.has_point(candidate):
			return true
	if host.current_screen == "queue":
		for candidate in _activity_input_position_candidates(event_position):
			if _queue_page_activity_card_contains_position(candidate):
				return true
	return false


func _queue_page_activity_card_contains_position(event_position: Vector2) -> bool:
	host._skill_detail_surface()._prune_invalid_action_cards()
	for raw_key in host.action_card_keys:
		var key := str(raw_key)
		if not key.begins_with("queue_page:") or not host.action_cards.has(key):
			continue
		var card := host.action_cards.get(key, {}) as Dictionary
		if card.is_empty():
			continue
		var module_key: String = host._skill_swipe_activity_surface()._activity_queue_module_key_for_card(card)
		if module_key.is_empty() or not host._activity_queue_runtime().is_activity_queued(module_key):
			continue
		var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		if pop.get_global_rect().grow(2.0).has_point(event_position):
			return true
	return false


func _position_inside_skill_menu_active_drawer(event_position: Vector2) -> bool:
	for raw_drawer in host._navigation_shell().skill_menu_active_drawers.values():
		if typeof(raw_drawer) != TYPE_DICTIONARY:
			continue
		var drawer := raw_drawer as Dictionary
		var slot := drawer.get("slot") as Control
		if slot == null or not is_instance_valid(slot) or not slot.is_visible_in_tree():
			continue
		var drawer_rect := slot.get_global_rect().grow(2.0)
		for candidate in _activity_input_position_candidates(event_position):
			if drawer_rect.has_point(candidate):
				return true
	return false


func _positions_inside_detail_actions_viewport(positions: Array[Vector2], viewport_outset := 2.0) -> bool:
	for event_position in positions:
		if _position_inside_detail_actions_viewport(event_position, viewport_outset):
			return true
	return false


func _event_points_inside_detail_actions_viewport(event: InputEvent, source: Control = null, viewport_outset := 2.0) -> bool:
	var positions: Array[Vector2] = []
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		_add_unique_event_position(positions, _global_event_position(mouse_event.position, mouse_event.global_position, source))
	elif event is InputEventMouseMotion:
		var motion_event := event as InputEventMouseMotion
		_add_unique_event_position(positions, _global_event_position(motion_event.position, motion_event.global_position, source))
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		_add_unique_event_position(positions, _global_event_position(touch_event.position, touch_event.position, source))
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		_add_unique_event_position(positions, _global_event_position(drag_event.position, drag_event.position, source))
	return _positions_inside_detail_actions_viewport(positions, viewport_outset)


static func event_is_outside_panel_press(event: InputEvent, panel: Control) -> bool:
	if panel == null or not is_instance_valid(panel):
		return false
	var panel_rect := panel.get_global_rect()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		return not panel_rect.has_point(event.global_position)
	if event is InputEventScreenTouch and event.pressed:
		return not panel_rect.has_point(event.position)
	return false


func input(event: InputEvent) -> void:
	if host._material_collection_surface().route_berry_mode_leave_button_input(event):
		host.get_viewport().set_input_as_handled()
		return
	var fishing_input_trace: bool = host._fishing_ui_surface()._fishing_input_trace_enabled()
	var fishing_input_total_started_usec: int = Time.get_ticks_usec() if fishing_input_trace else 0
	if _route_input_fishing_preflight(event, fishing_input_trace, fishing_input_total_started_usec):
		return
	var press_started_on_button := _input_primary_press_started_on_button(event)
	if _route_input_top_level_controls(event, press_started_on_button):
		return
	if _route_input_modal_controls(event):
		return
	if _route_input_screen_controls(event):
		return
	_route_input_activity_surface(event, press_started_on_button)


func _update_fishing_detail_primary_pointer_down(event: InputEvent) -> void:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		host._fishing_ui_surface().fishing_detail_primary_pointer_down = false
		return
	var event_position := _fishing_detail_event_position(event)
	if _is_primary_press_event(event):
		host._fishing_ui_surface().fishing_detail_primary_pointer_down = (
			event_position != Vector2.INF
			and _position_inside_detail_actions_viewport(event_position)
			and not _position_inside_bottom_interactive_ui(event_position)
		)
	elif host.button_press_runtime._input_event_releases_primary_pointer(event):
		host._fishing_ui_surface().fishing_detail_primary_pointer_down = false


func _fishing_detail_scroll_container_should_own_event(event: InputEvent) -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		return false
	if not host._skill_detail_surface().detail_actions_scroll.is_visible_in_tree():
		return false
	if not (event is InputEventMouseMotion or event is InputEventScreenDrag or event is InputEventMouseButton or event is InputEventScreenTouch):
		return false
	var event_position := _fishing_detail_event_position(event)
	if event_position == Vector2.INF or not _position_inside_detail_actions_viewport(event_position):
		return false
	if _position_inside_bottom_interactive_ui(event_position):
		return false
	if host._navigation_shell().page_switch_press_active or host.module_ui_runtime.pin_press_active() or host._action_stop_hold().active():
		return false
	if host._fishing_ui_surface().has_active_fishing_button_press():
		return false
	if host._skill_swipe_activity_surface().skill_swipe_tracking and host._skill_swipe_activity_surface().skill_swipe_horizontal:
		return false
	if host._skill_swipe_activity_surface().skill_swipe_tracking and not host._skill_swipe_activity_surface().skill_swipe_horizontal:
		return false
	if host._skill_detail_surface().detail_actions_scroll.drag_scrolling:
		return true
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		return host._skill_detail_surface().detail_actions_scroll.drag_tracking and host._skill_detail_surface().detail_actions_scroll.drag_touch_index == drag_event.index
	if event is InputEventMouseMotion:
		return host._skill_detail_surface().detail_actions_scroll.drag_tracking and host._skill_detail_surface().detail_actions_scroll.drag_touch_index < 0
	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		return not touch_event.pressed and host._skill_detail_surface().detail_actions_scroll.drag_tracking and host._skill_detail_surface().detail_actions_scroll.drag_touch_index == touch_event.index
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and not mouse_event.pressed
			and host._skill_detail_surface().detail_actions_scroll.drag_tracking
			and host._skill_detail_surface().detail_actions_scroll.drag_touch_index < 0
		)
	return false


func _fishing_detail_scroll_event_bypasses_global_input(event: InputEvent) -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if host._skill_detail_surface().detail_actions_scroll == null or not is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
		return false
	if not host._skill_detail_surface().detail_actions_scroll.is_visible_in_tree():
		return false
	var event_position := _fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return false
	if _position_inside_bottom_interactive_ui(event_position):
		return false
	if not _position_inside_detail_actions_viewport(event_position):
		return false
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		return mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN or mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP
	if event is InputEventMouseMotion:
		return host._skill_detail_surface().detail_actions_scroll.drag_tracking and host._skill_detail_surface().detail_actions_scroll.drag_touch_index < 0
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		return host._skill_detail_surface().detail_actions_scroll.drag_tracking and host._skill_detail_surface().detail_actions_scroll.drag_touch_index == drag_event.index
	return false


func _fishing_detail_primary_press_skips_global_button_scan(event: InputEvent) -> bool:
	var trace_enabled: bool = host._fishing_ui_surface()._fishing_input_trace_enabled()
	var step_usec := Time.get_ticks_usec() if trace_enabled else 0
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	var event_position := Vector2.INF
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			return false
		event_position = mouse_event.global_position
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			return false
		event_position = touch_event.position
	else:
		return false
	if event_position == Vector2.INF:
		return false
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_position", step_usec, event)
	step_usec = Time.get_ticks_usec() if trace_enabled else 0
	if _position_inside_bottom_interactive_ui(event_position):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_bottom_ui_true", step_usec, event)
		return false
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_bottom_ui_false", step_usec, event)
	step_usec = Time.get_ticks_usec() if trace_enabled else 0
	if _page_switch_button_control_at_position(event_position) != null:
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_page_switch_true", step_usec, event)
		return false
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_page_switch_false", step_usec, event)
	step_usec = Time.get_ticks_usec() if trace_enabled else 0
	var inside_detail := _position_inside_detail_actions_viewport(event_position)
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_skip_scan_detail_viewport", step_usec, event)
	return inside_detail


func _fishing_detail_primary_press_started_on_fast_button(event: InputEvent) -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if not _is_primary_press_event(event):
		return false
	var event_position := _fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return false
	if _position_inside_bottom_interactive_ui(event_position):
		return true
	return _page_switch_button_control_at_position(event_position) != null


func _fishing_detail_primary_press_should_defer_tap_scan(event: InputEvent) -> bool:
	var trace_enabled: bool = host._fishing_ui_surface()._fishing_input_trace_enabled()
	var step_usec := Time.get_ticks_usec() if trace_enabled else 0
	if not _fishing_detail_primary_press_skips_global_button_scan(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_defer_skip_scan_false", step_usec, event)
		return false
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_defer_skip_scan_true", step_usec, event)
	step_usec = Time.get_ticks_usec() if trace_enabled else 0
	if fishing_detail_swipe_press_active:
		return false
	if host.queue_selection_mode:
		return false
	if host._navigation_shell().page_switch_press_active or host.module_ui_runtime.pin_press_active() or host._action_stop_hold().active():
		return false
	if host._fishing_ui_surface().has_active_fishing_button_press():
		return false
	if host._skill_swipe_activity_surface().skill_swipe_tracking or host._skill_swipe_activity_surface().skill_swipe_animating:
		return false
	var event_position := _fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return false
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_defer_remaining_guards", step_usec, event)
	return true


func _fishing_detail_input_context_active() -> bool:
	if host.current_screen == "skill":
		return host.selected_skill_id == "fishing"
	return host.current_screen == "pinned" or host.current_screen == "queue"


func _begin_fishing_detail_deferred_swipe_if_press(event: InputEvent) -> void:
	var press_position := Vector2.INF
	var touch_index := -1
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT or not mouse_event.pressed:
			if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
				_clear_fishing_detail_deferred_swipe()
			return
		press_position = mouse_event.global_position
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if not touch_event.pressed:
			if fishing_detail_swipe_press_touch_index < 0 or touch_event.index == fishing_detail_swipe_press_touch_index:
				_clear_fishing_detail_deferred_swipe()
			return
		press_position = touch_event.position
		touch_index = touch_event.index
	else:
		return
	fishing_detail_swipe_press_active = true
	fishing_detail_swipe_press_position = press_position
	fishing_detail_swipe_press_touch_index = touch_index
	host._skill_swipe_activity_surface().skill_swipe_tracking = false
	host._skill_swipe_activity_surface().skill_swipe_horizontal = false
	host._skill_swipe_activity_surface().skill_swipe_touch_index = -1


func _route_fishing_detail_deferred_swipe_input(event: InputEvent) -> bool:
	if not fishing_detail_swipe_press_active:
		return false
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		_clear_fishing_detail_deferred_swipe()
		return false
	var event_position := Vector2.INF
	var is_motion := false
	var is_release := false
	if event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		is_motion = true
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		event_position = (event as InputEventMouseButton).global_position
		is_release = not (event as InputEventMouseButton).pressed
	elif event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if fishing_detail_swipe_press_touch_index >= 0 and drag_event.index != fishing_detail_swipe_press_touch_index:
			return false
		event_position = drag_event.position
		is_motion = true
	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if fishing_detail_swipe_press_touch_index >= 0 and touch_event.index != fishing_detail_swipe_press_touch_index:
			return false
		event_position = touch_event.position
		is_release = not touch_event.pressed
	if is_release:
		var press_position := fishing_detail_swipe_press_position
		var touch_index := fishing_detail_swipe_press_touch_index
		_clear_fishing_detail_deferred_swipe()
		if (
			event_position != Vector2.INF
			and event_position.distance_to(press_position) <= host.PASSIVE_BUTTON_TAP_RELEASE_SLOP
			and _position_inside_detail_actions_viewport(event_position)
			and not _position_inside_bottom_interactive_ui(event_position)
			and not host._skill_swipe_activity_surface()._skill_swipe_suppresses_button_action()
		):
			return _route_fishing_detail_deferred_tap_release(event_position, touch_index)
		return false
	if not is_motion or event_position == Vector2.INF:
		return false
	var drag_offset := event_position - fishing_detail_swipe_press_position
	if (
		absf(drag_offset.y) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	):
		return _try_handoff_fishing_deferred_vertical_scroll(event, event_position)
	if not (
		absf(drag_offset.x) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.x) > absf(drag_offset.y) * 1.15
	):
		return false
	var start_position := fishing_detail_swipe_press_position
	var touch_index := fishing_detail_swipe_press_touch_index
	_clear_fishing_detail_deferred_swipe()
	host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(start_position, touch_index)
	if host._skill_swipe_activity_surface().skill_swipe_tracking:
		host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event_position)
	return true


func _route_fishing_detail_deferred_tap_release(event_position: Vector2, touch_index := -1) -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if event_position == Vector2.INF:
		return false
	if _position_inside_bottom_interactive_ui(event_position) or not _position_inside_detail_actions_viewport(event_position):
		return false
	if _route_fishing_method_lock_tap_at_position(event_position):
		return true
	var offer_button: Button = host._fishing_ui_surface()._fishing_offer_button_hit(event_position, true)
	if offer_button != null:
		host._fishing_ui_surface()._activate_fishing_offer_button(str(offer_button.get_meta("fishing_offer_id", "")), offer_button)
		return true
	var method_hit: Dictionary = host._fishing_ui_surface()._fishing_method_button_hit(event_position, true)
	if not method_hit.is_empty():
		var method_card := method_hit.get("method_card", {}) as Dictionary
		if method_card.is_empty():
			return false
		var skill_id := str(method_card.get("skill_id", "fishing"))
		var action_id := str(method_card.get("action_id", ""))
		var owner_area_card := method_hit.get("owner_area_card", {}) as Dictionary
		var owner_pop := owner_area_card.get("pop", null) as Control
		var owner_area_pop_instance_id := owner_pop.get_instance_id() if owner_pop != null and is_instance_valid(owner_pop) else 0
		if owner_area_pop_instance_id == 0:
			owner_area_pop_instance_id = int(method_hit.get("owner_pop_instance_id", 0))
		if host.queue_selection_mode:
			if owner_area_card.is_empty():
				host._skill_swipe_activity_surface()._queue_selection_toggle_from_card(method_card)
			else:
				host._skill_swipe_activity_surface()._queue_selection_toggle_from_card(owner_area_card)
			return true
		if host.current_screen == "queue":
			var module_key: String = host._skill_swipe_activity_surface()._activity_queue_module_key_for_card(owner_area_card if not owner_area_card.is_empty() else method_card)
			if not module_key.is_empty():
				host._activity_queue_runtime()._start_activity_queue_from_key(module_key)
				return true
		host._fishing_ui_surface()._on_fishing_method_pressed(skill_id, action_id, str(method_card.get("fishing_area_key", "")), owner_area_pop_instance_id)
		return true
	return false


func _try_handoff_fishing_deferred_vertical_scroll(event: InputEvent, event_position: Vector2) -> bool:
	if not fishing_detail_swipe_press_active or event_position == Vector2.INF:
		return false
	var is_motion := event is InputEventMouseMotion
	if event is InputEventScreenDrag:
		var drag_event := event as InputEventScreenDrag
		if fishing_detail_swipe_press_touch_index >= 0 and drag_event.index != fishing_detail_swipe_press_touch_index:
			return false
		is_motion = true
	if not is_motion:
		return false
	var drag_offset := event_position - fishing_detail_swipe_press_position
	if not (
		absf(drag_offset.y) >= host.ACTION_CARD_SCROLL_DRAG_VISUAL_DEADZONE
		and absf(drag_offset.y) > absf(drag_offset.x) * 1.15
	):
		return false
	var scroll_press_position := fishing_detail_swipe_press_position
	var scroll_touch_index := fishing_detail_swipe_press_touch_index
	_clear_fishing_detail_deferred_swipe()
	host._fishing_ui_surface()._handoff_fishing_vertical_scroll(scroll_press_position, event_position, scroll_touch_index)
	return true


func _clear_fishing_detail_deferred_swipe() -> void:
	fishing_detail_swipe_press_active = false
	fishing_detail_swipe_press_position = Vector2.ZERO
	fishing_detail_swipe_press_touch_index = -1


func _route_input_fishing_preflight(event: InputEvent, fishing_input_trace: bool, fishing_input_total_started_usec: int) -> bool:
	var fishing_input_step_started_usec: int = fishing_input_total_started_usec
	var perf_runtime = host._performance_runtime()
	if perf_runtime._input_event_wakes_battery_governor(event):
		perf_runtime._record_battery_governor_activity()
	host._audio_director().note_player_input(event)
	host._fishing_ui_surface()._trace_fishing_input_duration("input_note_player", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	if host._fishing_ui_surface()._route_fishing_wallet_unhandled_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("input_fishing_wallet_early", fishing_input_step_started_usec, event)
		host.get_viewport().set_input_as_handled()
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("input_fishing_wallet_early", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	_update_fishing_detail_primary_pointer_down(event)
	host._fishing_ui_surface()._trace_fishing_input_duration("input_primary_pointer_down", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	host._fishing_ui_surface()._maybe_end_fishing_scroll_mode_for_new_press(event)
	host._fishing_ui_surface()._trace_fishing_input_duration("input_maybe_end_scroll_mode", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	if (
		(activity_lock_input_active or (host.current_screen == "skill" and host.selected_skill_id == "fishing"))
		and _route_activity_lock_input(event)
	):
		host._fishing_ui_surface()._trace_fishing_input_duration("input_activity_lock_early", fishing_input_step_started_usec, event)
		host.get_viewport().set_input_as_handled()
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("input_activity_lock_early", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	if host._skill_detail_surface()._route_detail_jump_arrow_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("input_detail_jump_arrow_early", fishing_input_step_started_usec, event)
		host.get_viewport().set_input_as_handled()
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("input_detail_jump_arrow_early", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	if _route_active_fishing_control_drag_handoff(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("input_active_fishing_control_early", fishing_input_step_started_usec, event)
		host.get_viewport().set_input_as_handled()
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("input_active_fishing_control_early", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	if _route_fishing_detail_deferred_swipe_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("input_deferred_swipe_early", fishing_input_step_started_usec, event)
		host.get_viewport().set_input_as_handled()
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("input_deferred_swipe_early", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	if _fishing_detail_scroll_container_should_own_event(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("input_scroll_container_should_own_true", fishing_input_step_started_usec, event)
		host._fishing_ui_surface()._trace_fishing_input_duration("input_total_scroll_container_return", fishing_input_total_started_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("input_scroll_container_should_own_false", fishing_input_step_started_usec, event)
	fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
	if _fishing_detail_primary_press_should_defer_tap_scan(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("input_defer_tap_check_true", fishing_input_step_started_usec, event)
		fishing_input_step_started_usec = Time.get_ticks_usec() if fishing_input_trace else 0
		_begin_fishing_detail_deferred_swipe_if_press(event)
		host._fishing_ui_surface()._trace_fishing_input_duration("input_defer_swipe_begin", fishing_input_step_started_usec, event)
		host.get_viewport().set_input_as_handled()
		host._fishing_ui_surface()._trace_fishing_input_duration("input_total_defer_return", fishing_input_total_started_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("input_defer_tap_check_false", fishing_input_step_started_usec, event)
	return false


func _input_primary_press_started_on_button(event: InputEvent) -> bool:
	var press_started_on_button := false
	if _is_primary_press_event(event):
		press_started_on_button = _fishing_detail_primary_press_started_on_fast_button(event)
		if not press_started_on_button and not _fishing_detail_primary_press_skips_global_button_scan(event):
			var button_scan_started_usec: int = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
			press_started_on_button = host.button_press_runtime._primary_press_started_on_button(event)
			host._fishing_ui_surface()._trace_fishing_input_duration("primary_button_scan", button_scan_started_usec, event)
	return press_started_on_button


func _route_input_top_level_controls(event: InputEvent, press_started_on_button: bool) -> bool:
	if host.button_press_runtime._input_event_releases_primary_pointer(event):
		if host._fishing_ui_surface().has_active_fishing_method_press() and host._fishing_ui_surface()._route_fishing_method_button_global_input(event):
			host.get_viewport().set_input_as_handled()
			return true
		host.button_press_runtime.release_all_depressed_buttons()
		host._skill_swipe_activity_surface().release_all_depressed_activity_shell_buttons()
	elif event is InputEventMouseMotion or event is InputEventScreenDrag:
		host.button_press_runtime.release_depressed_buttons_if_pointer_left(event)
		host._skill_swipe_activity_surface().release_depressed_activity_shell_buttons_if_pointer_left(event)
	host._action_stop_hold().cancel_if_scroll_drag_event(event)
	if _modal_blocks_background_input():
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback()
		host._action_stop_hold().cancel_action()
		host.get_viewport().set_input_as_handled()
		return true
	if _route_page_switch_button_global_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if _fishing_detail_scroll_container_should_own_event(event):
		return true
	if _fishing_detail_scroll_event_bypasses_global_input(event):
		if not press_started_on_button:
			_begin_fishing_detail_deferred_swipe_if_press(event)
		return true
	if host._navigation_shell()._route_pinned_shelf_action_card_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if _route_system_back_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._boot_warmup_runtime().active:
		host.get_viewport().set_input_as_handled()
		return true
	if host._achievement_toast_surface()._route_achievement_toast_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	var fishing_deferred_started_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if _route_fishing_detail_deferred_swipe_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_deferred_swipe", fishing_deferred_started_usec, event)
		host.get_viewport().set_input_as_handled()
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_deferred_swipe", fishing_deferred_started_usec, event)
	var fishing_route_started_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if _route_fishing_detail_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_detail_route", fishing_route_started_usec, event)
		host.get_viewport().set_input_as_handled()
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_detail_route", fishing_route_started_usec, event)
	if _fishing_detail_should_skip_generic_input(event):
		if not press_started_on_button:
			_begin_fishing_detail_deferred_swipe_if_press(event)
		return true
	if host._skill_detail_surface()._route_direct_module_action_zone_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if not _modal_blocks_background_input() and not _any_modal_overlay_visible():
		if host._navigation_shell()._route_module_utility_button_global_input(event):
			host.get_viewport().set_input_as_handled()
			return true
		if host._profile_chat_overlay_surface()._route_chat_strip_input(event):
			host.get_viewport().set_input_as_handled()
			return true
		if host._navigation_shell()._route_bottom_nav_button_global_input(event):
			host.get_viewport().set_input_as_handled()
			return true
	return false


func _route_input_modal_controls(event: InputEvent) -> bool:
	host._settings_surface()._disarm_reset_data_confirmation_on_outside_press(event)
	if host._settings_surface()._route_onboarding_settings_nav_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._tutorial_overlay_surface()._route_tutorial_panel_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._settings_surface()._route_audio_slider_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._profile_chat_overlay_surface()._route_chat_overlay_key_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if _modal_blocks_background_input():
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback()
		host._action_stop_hold().cancel_action()
		host.get_viewport().set_input_as_handled()
		return true
	if host._achievement_overlay_surface()._route_achievement_medal_press(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._achievement_overlay_surface()._route_achievement_medal_popover_dismiss(event):
		host.get_viewport().set_input_as_handled()
		return true
	if _any_modal_overlay_visible():
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback()
		host._action_stop_hold().cancel_action()
		return true
	return false


func _route_input_screen_controls(event: InputEvent) -> bool:
	if _route_page_switch_button_global_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	host._hub_surface()._maybe_dismiss_hub_tutorial_tip_for_input(event)
	if host._action_runtime()._is_stamina_gauge_release_event(event):
		host._action_runtime()._finish_stamina_gauge_click_or_hold()
		host.get_viewport().set_input_as_handled()
		return true
	if host._skill_detail_surface()._route_detail_jump_arrow_input(event):
		if host._navigation_shell()._route_pinned_shelf_action_card_input(event):
			host.get_viewport().set_input_as_handled()
			return true
		host.get_viewport().set_input_as_handled()
		return true
	if host._profile_chat_overlay_surface()._route_chat_strip_input(event):
		if host._navigation_shell()._route_pinned_shelf_action_card_input(event):
			host.get_viewport().set_input_as_handled()
			return true
		host.get_viewport().set_input_as_handled()
		return true
	if host._hub_surface()._route_hub_hotspot_hold_input(event):
		if host._navigation_shell()._route_pinned_shelf_action_card_input(event):
			host.get_viewport().set_input_as_handled()
			return true
		host.get_viewport().set_input_as_handled()
		return true
	if (host.current_screen != "skill" and host.current_screen != "pinned" and host.current_screen != "queue" and host.current_screen != "menu") or _any_modal_overlay_visible():
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback()
		host._action_stop_hold().cancel_action()
		return true
	return false


func _route_input_activity_surface(event: InputEvent, press_started_on_button: bool) -> bool:
	if _release_active_activity_lock_input(event):
		if host._navigation_shell()._route_pinned_shelf_action_card_input(event):
			host.get_viewport().set_input_as_handled()
			return true
		host.get_viewport().set_input_as_handled()
		return true
	if host._skill_detail_surface()._route_module_action_zone_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._thieving_surface()._route_thieving_heist_button_global_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if _route_active_skill_swipe_input(event):
		return true
	if host._navigation_shell()._event_points_inside_bottom_nav(event):
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
		host._fishing_ui_surface()._clear_active_fishing_method_button_press()
		host._skill_detail_surface().action_card_press_key = ""
		return true
	if _event_points_inside_bottom_interactive_ui(event):
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
		host._fishing_ui_surface()._clear_active_fishing_method_button_press()
		host._skill_detail_surface().action_card_press_key = ""
		return true
	if host._action_stop_hold().route_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if _route_fishing_method_lock_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if _route_activity_lock_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._skill_detail_surface()._route_detail_back_button_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._fishing_ui_surface()._route_fishing_active_tool_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	host._skill_detail_surface()._hide_skill_header_info_on_outside_press(event)
	host._passive_firepit_surface()._schedule_passive_info_click_away_dismiss(event)
	if host._passive_firepit_surface()._route_passive_module_button_input_by_position(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._skill_detail_surface()._route_collapsed_module_expand_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	if host._passive_firepit_surface()._route_passive_button_global_input(event):
		host.get_viewport().set_input_as_handled()
		return true
	host._skill_detail_surface()._update_action_card_press_drag_state(event)
	if _route_action_card_release(event):
		host.get_viewport().set_input_as_handled()
		return true
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			host.action_card_press_consumed = false
			if _route_action_card_press(event.global_position):
				host.get_viewport().set_input_as_handled()
				return true
			if host.current_screen == "skill" and not press_started_on_button:
				host._skill_swipe_activity_surface()._interrupt_skill_swipe_animation_for_input()
				if host.skills_page != null and Rect2(host.skills_page.global_position, host.skills_page.size).has_point(event.global_position):
					host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(event.global_position, -1)
		elif host._skill_swipe_activity_surface().skill_swipe_tracking:
			host._skill_swipe_activity_surface()._finish_skill_swipe(event.global_position)
		return true
	if event is InputEventMouseMotion and host._skill_swipe_activity_surface().skill_swipe_tracking:
		host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event.global_position)
		return true
	if event is InputEventScreenTouch:
		if event.pressed:
			host.action_card_press_consumed = false
			if _route_action_card_press(event.position, event.index):
				host.get_viewport().set_input_as_handled()
				return true
			if host.current_screen == "skill" and not press_started_on_button:
				host._skill_swipe_activity_surface()._interrupt_skill_swipe_animation_for_input()
				host._skill_swipe_activity_surface()._begin_skill_swipe_tracking(event.position, event.index)
		elif host._skill_swipe_activity_surface().skill_swipe_tracking and event.index == host._skill_swipe_activity_surface().skill_swipe_touch_index:
			host._skill_swipe_activity_surface()._finish_skill_swipe(event.position)
		return true
	if event is InputEventScreenDrag and host._skill_swipe_activity_surface().skill_swipe_tracking and event.index == host._skill_swipe_activity_surface().skill_swipe_touch_index:
		host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event.position)
		return true
	return false


func _route_active_skill_swipe_input(event: InputEvent) -> bool:
	if not host._skill_swipe_activity_surface().skill_swipe_tracking:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		host._skill_swipe_activity_surface()._finish_skill_swipe(event.global_position)
		return true
	if event is InputEventMouseMotion:
		host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event.global_position)
		return true
	if event is InputEventScreenTouch and not event.pressed and event.index == host._skill_swipe_activity_surface().skill_swipe_touch_index:
		host._skill_swipe_activity_surface()._finish_skill_swipe(event.position)
		return true
	if event is InputEventScreenDrag and event.index == host._skill_swipe_activity_surface().skill_swipe_touch_index:
		host._skill_swipe_activity_surface()._update_skill_swipe_feedback(event.position)
		return true
	return false


func _route_system_back_input(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed and not event.echo and event.is_action("ui_cancel"):
		_handle_system_back_request()
		return true
	return false


func _handle_system_back_request() -> void:
	if host._boot_warmup_runtime().active:
		return
	if host._onboarding_runtime().tutorial_active:
		host._onboarding_runtime()._complete_tutorial_target_intro()
		return
	if host._profile_chat_overlay_surface().chat_overlay_visible():
		host._profile_chat_overlay_surface()._close_chat_overlay()
		return
	if host._achievement_overlay_surface().offline_summary_visible():
		host._achievement_overlay_surface()._close_offline_summary_overlay()
		return
	if host._achievement_overlay_surface().is_overlay_visible():
		host._achievement_overlay_surface()._close_achievements_overlay()
		return
	if host._profile_chat_overlay_surface()._profile_overlay_visible():
		host._profile_chat_overlay_surface()._save_profile_and_close()
		return
	if host.settings_overlay != null and host.settings_overlay.visible:
		host._settings_surface()._close_settings()
		return
	if host.current_screen == "settings":
		host._settings_surface()._return_from_settings_page()
		return
	if host.current_screen == "skill":
		host._navigation_shell()._show_skills()
		return
	if host.current_screen != "menu":
		host._navigation_shell()._show_skills()


func _any_modal_overlay_visible() -> bool:
	if host._profile_chat_overlay_surface().chat_overlay_visible():
		return true
	if host.settings_overlay != null and host.settings_overlay.visible:
		return true
	if host._profile_chat_overlay_surface()._profile_overlay_visible():
		return true
	if host._achievement_overlay_surface().is_overlay_visible():
		return true
	if host._achievement_overlay_surface().offline_summary_visible():
		return true
	return false


func _modal_blocks_background_input() -> bool:
	return Time.get_ticks_msec() < modal_background_input_block_until_msec


func _block_background_input_briefly(duration_msec := 180) -> void:
	modal_background_input_block_until_msec = maxi(modal_background_input_block_until_msec, Time.get_ticks_msec() + duration_msec)


func _route_fishing_method_lock_input(event: InputEvent) -> bool:
	if host.current_screen == "skill" and host.selected_skill_id != "fishing":
		return false
	if host.current_screen != "skill" and host.current_screen != "pinned":
		return false
	var event_position = Vector2.ZERO
	var is_press = false
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		event_position = mouse_event.global_position
		is_press = mouse_event.pressed
	elif event is InputEventScreenTouch:
		var touch_event = event as InputEventScreenTouch
		event_position = touch_event.position
		is_press = touch_event.pressed
	else:
		return false
	if not is_press:
		return false
	if not _event_points_inside_detail_actions_viewport(event):
		return false
	return _route_fishing_method_lock_tap_at_position(event_position)


func _route_fishing_method_lock_tap_at_position(event_position: Vector2) -> bool:
	var method_cards: Array = []
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var card = raw_card as Dictionary
		if bool(card.get("is_fishing_method", false)):
			method_cards.append(card)
		if bool(card.get("is_fishing_area", false)):
			for raw_method_card in (card.get("method_slots", {}) as Dictionary).values():
				if typeof(raw_method_card) == TYPE_DICTIONARY:
					method_cards.append(raw_method_card as Dictionary)
	for raw_method_card in method_cards:
		var card = raw_method_card as Dictionary
		if card.is_empty() or not bool(card.get("is_fishing_method", false)):
			continue
		var action_id = str(card.get("action_id", ""))
		var skill_id = str(card.get("skill_id", "fishing"))
		var action = host._action_data(skill_id, action_id)
		var locked_method = action.is_empty() or not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action) or bool(card.get("unlock_ready_pending", false))
		if not locked_method:
			continue
		var lock_root = host._app_lifecycle_runtime().valid_control_ref(card.get("lock_root"))
		var hit_control = lock_root
		if hit_control == null:
			hit_control = host._app_lifecycle_runtime().valid_control_ref(card.get("art_panel"))
		if hit_control == null:
			continue
		if not hit_control.visible or not hit_control.is_visible_in_tree():
			continue
		var hit_rect = hit_control.get_global_rect().grow(28.0)
		var padlock_hit_area = host._app_lifecycle_runtime().valid_control_ref(lock_root.get_meta("padlock_button")) if lock_root != null else null
		if padlock_hit_area != null and padlock_hit_area.is_visible_in_tree():
			hit_rect = padlock_hit_area.get_global_rect().grow(32.0)
		if not hit_rect.has_point(event_position):
			continue
		host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
		host._skill_detail_surface().action_card_press_key = ""
		host._skill_detail_surface().action_card_press_stat_kind = ""
		host._skill_detail_surface().action_card_press_dragged = false
		var shake_body = host._app_lifecycle_runtime().valid_control_ref(lock_root.get_meta("padlock_shake_body")) if lock_root != null else null
		host._fishing_ui_surface()._on_fishing_method_lock_pressed(skill_id, action_id, shake_body)
		return true
	return false


func _route_activity_lock_input(event: InputEvent) -> bool:
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	if _release_active_activity_lock_input(event):
		return true
	if activity_lock_input_active:
		if active_activity_lock_rig == null or not is_instance_valid(active_activity_lock_rig):
			active_activity_lock_rig = null
			activity_lock_input_active = false
			_set_activity_lock_page_scrolling_disabled(false)
			return false
		if active_activity_lock_rig.has_method("handle_pointer_event") and bool(active_activity_lock_rig.call("handle_pointer_event", event)):
			_set_activity_lock_page_scrolling_disabled(true)
			host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
			return true
	if host._skill_detail_surface()._event_points_inside_detail_jump_arrow(event):
		return false
	if _event_points_inside_bottom_interactive_ui(event):
		return false
	if host.current_screen != "skill":
		return false
	var event_position: Vector2 = _passive_button_event_position(event, null)
	if _page_switch_button_control_at_position(event_position) != null:
		return false
	if not _event_points_inside_detail_actions_viewport(event):
		return false
	event_position = _fishing_detail_event_position(event)
	for raw_card in host.action_cards.values():
		var card := raw_card as Dictionary
		var overlay := card.get("lock_overlay", {}) as Dictionary
		if overlay.is_empty():
			continue
		var overlay_root: Control = host._app_lifecycle_runtime().valid_control_ref(overlay.get("root"))
		var rig: Control = host._app_lifecycle_runtime().valid_control_ref(overlay.get("group"))
		if overlay_root == null or rig == null or not overlay_root.visible or not rig.visible:
			continue
		if not overlay_root.is_visible_in_tree() or not rig.is_visible_in_tree():
			continue
		if event_position != Vector2.INF and not overlay_root.get_global_rect().grow(12.0).has_point(event_position):
			continue
		if not rig.has_method("pointer_over_lock_event") or not rig.has_method("handle_pointer_event"):
			continue
		if not bool(rig.call("pointer_over_lock_event", event)) and not activity_lock_input_active:
			continue
		if bool(rig.call("handle_pointer_event", event)):
			activity_lock_input_active = not _activity_lock_input_released(event)
			active_activity_lock_rig = rig if activity_lock_input_active else null
			_set_activity_lock_page_scrolling_disabled(activity_lock_input_active)
			host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
			return true
	return false


func _release_active_activity_lock_input(event: InputEvent) -> bool:
	if not activity_lock_input_active or not _activity_lock_input_released(event):
		return false
	if active_activity_lock_rig != null and is_instance_valid(active_activity_lock_rig) and active_activity_lock_rig.has_method("handle_pointer_event"):
		active_activity_lock_rig.call("handle_pointer_event", event)
	active_activity_lock_rig = null
	activity_lock_input_active = false
	_set_activity_lock_page_scrolling_disabled(false)
	return true


func _clear_activity_lock_input_state() -> void:
	active_activity_lock_rig = null
	activity_lock_input_active = false
	_set_activity_lock_page_scrolling_disabled(false)


func _activity_lock_input_released(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		return not event.pressed
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


func _set_activity_lock_page_scrolling_disabled(disabled: bool) -> void:
	if host._skill_detail_surface().detail_actions_scroll != null:
		host._skill_detail_surface().detail_actions_scroll.set_input_locked_by_activity_lock(disabled)
	if disabled:
		host._skill_swipe_activity_surface().skill_swipe_tracking = false
		host._skill_swipe_activity_surface().skill_swipe_horizontal = false
		host._skill_swipe_activity_surface().skill_swipe_touch_index = -1


func _route_action_card_press(press_position: Vector2, pointer_id := -1) -> bool:
	if host._navigation_shell()._position_inside_bottom_nav(press_position):
		return false
	if not _position_inside_detail_actions_viewport(press_position):
		return false
	var press_positions: Array[Vector2] = []
	press_positions.append(press_position)
	for routed_position in press_positions:
		var match = _action_card_at_position(routed_position)
		if match.is_empty():
			continue
		var card = match["card"] as Dictionary
		var skill_id = str(match["skill_id"])
		var action_id = str(match["action_id"])
		var action = host._action_data(skill_id, action_id)
		if _activity_card_is_locked_or_covered(skill_id, action, card):
			host._action_stop_hold().cancel_action()
			return false
		if skill_id == "thieving" and host._thieving_surface()._thieving_action_is_jailed(action_id):
			host._thieving_surface()._reduce_thieving_action_jail_from_card(action_id, card)
			host.action_card_press_consumed = true
			host._action_stop_hold().cancel_action()
			host._skill_swipe_activity_surface().skill_swipe_tracking = false
			host._skill_swipe_activity_surface().skill_swipe_horizontal = false
			host._skill_swipe_activity_surface().skill_swipe_touch_index = -1
			return true
		if host.queue_selection_mode:
			if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
				host._skill_detail_surface().detail_actions_scroll.prepare_child_tap()
			host._skill_detail_surface().action_card_press_key = str(card.get("card_key", host._action_key(skill_id, action_id)))
			host._skill_detail_surface().action_card_press_position = routed_position
			host._skill_detail_surface().action_card_press_stat_kind = ""
			host._skill_detail_surface().action_card_press_dragged = false
			host._skill_swipe_activity_surface()._queue_action_card_3d_press(host._skill_detail_surface().action_card_press_key)
			return true
		if host.running_skill_id == skill_id and host.running_action_id == action_id:
			var card_key = str(card.get("card_key", host._action_key(skill_id, action_id)))
			var pinned_duplicate_body_press = host.current_screen == "pinned" or card_key.begins_with("pinned_shelf:")
			if pinned_duplicate_body_press:
				host._action_stop_hold().begin_action(skill_id, action_id, routed_position, pointer_id)
				return true
			if host._action_runtime()._try_action_opportunity_click(skill_id, action_id, routed_position):
				host.action_card_press_consumed = true
				host._action_stop_hold().cancel_action()
				host._skill_swipe_activity_surface().skill_swipe_tracking = false
				host._skill_swipe_activity_surface().skill_swipe_horizontal = false
				host._skill_swipe_activity_surface().skill_swipe_touch_index = -1
				return true
		var stat_kind = host._skill_detail_surface()._activity_stat_kind_at_position(card, routed_position)
		if stat_kind.is_empty() and host._skill_swipe_activity_surface()._action_card_medal_hit_at_position(card, routed_position):
			stat_kind = host.ACTION_CARD_MEDAL_PRESS_KIND
		if stat_kind.is_empty() and (host.queue_selection_mode or host.current_screen == "queue"):
			if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
				host._skill_detail_surface().detail_actions_scroll.prepare_child_tap()
			host._skill_detail_surface().action_card_press_key = str(card.get("card_key", host._action_key(skill_id, action_id)))
			host._skill_detail_surface().action_card_press_position = routed_position
			host._skill_detail_surface().action_card_press_stat_kind = stat_kind
			host._skill_detail_surface().action_card_press_dragged = false
			host._skill_swipe_activity_surface()._queue_action_card_3d_press(host._skill_detail_surface().action_card_press_key)
			return true
		if stat_kind.is_empty() and host.running_skill_id == skill_id and host.running_action_id == action_id:
			if host._action_runtime()._miss_action_opportunity_click(skill_id, action_id, routed_position):
				host.action_card_press_consumed = true
				host._action_stop_hold().cancel_action()
				host._skill_swipe_activity_surface().skill_swipe_tracking = false
				host._skill_swipe_activity_surface().skill_swipe_horizontal = false
				host._skill_swipe_activity_surface().skill_swipe_touch_index = -1
				return true
			host._action_stop_hold().begin_action(skill_id, action_id, routed_position, pointer_id)
			return true
		if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
			host._skill_detail_surface().detail_actions_scroll.prepare_child_tap()
		host._skill_detail_surface().action_card_press_key = str(card.get("card_key", host._action_key(skill_id, action_id)))
		host._skill_detail_surface().action_card_press_position = routed_position
		host._skill_detail_surface().action_card_press_stat_kind = stat_kind
		host._skill_detail_surface().action_card_press_dragged = false
		if stat_kind.is_empty():
			host._skill_swipe_activity_surface()._queue_action_card_3d_press(host._skill_detail_surface().action_card_press_key)
		return true
	return false


func _route_fishing_detail_input(event: InputEvent) -> bool:
	if not _fishing_detail_input_context_active():
		return false
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	var event_position = _fishing_detail_event_position(event)
	if (host.current_screen == "pinned" or host.current_screen == "queue") and not _pinned_fishing_detail_event_relevant(event_position):
		return false
	if event_position != Vector2.INF and _position_inside_bottom_interactive_ui(event_position):
		if host.module_ui_runtime.pin_press_active() and host.module_ui_runtime.module_pin_press_event_belongs_to_active_press(event):
			return host.module_ui_runtime.update_pending_module_pin_press(event, host.PASSIVE_BUTTON_TAP_RELEASE_SLOP, host._skill_swipe_activity_surface().skill_swipe_tracking, Callable(host._skill_detail_surface(), "_commit_module_pin_tap"))
		return false
	if host._navigation_shell().page_switch_press_active:
		return false
	var page_switch_button: Button = null
	var can_target_page_switch = event is InputEventMouseButton or event is InputEventScreenTouch
	if event_position != Vector2.INF and can_target_page_switch:
		page_switch_button = _page_switch_button_control_at_position(event_position)
	if page_switch_button != null and page_switch_button.get_global_rect().has_point(event_position):
		return false
	if host._skill_swipe_activity_surface().skill_swipe_tracking and host._skill_swipe_activity_surface().skill_swipe_horizontal:
		return false
	var active_control_drag_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if _route_active_fishing_control_drag_handoff(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_active_control_drag", active_control_drag_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_active_control_drag", active_control_drag_usec, event)
	var deferred_handoff_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if _try_handoff_fishing_deferred_vertical_scroll(event, event_position):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_deferred_handoff", deferred_handoff_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_deferred_handoff", deferred_handoff_usec, event)
	if _fishing_detail_plain_scroll_motion_can_skip_global_hit_tests(event, event_position):
		return false
	if host._fishing_ui_surface().fishing_scroll_mouse_pick_suspended:
		return false
	var route_step_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if host._skill_detail_surface()._route_fishing_area_pin_corner_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_pin_corner", route_step_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_pin_corner", route_step_usec, event)
	route_step_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if _route_fishing_area_queue_selection_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_queue", route_step_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_queue", route_step_usec, event)
	route_step_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if host._fishing_ui_surface()._route_fishing_offer_button_global_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_offer", route_step_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_offer", route_step_usec, event)
	route_step_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if host._fishing_ui_surface()._route_fishing_location_image_priority_press(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_location_priority", route_step_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_location_priority", route_step_usec, event)
	route_step_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if host._fishing_ui_surface()._route_fishing_method_button_global_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_method", route_step_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_method", route_step_usec, event)
	if page_switch_button != null:
		return false
	if host.current_screen == "pinned" or host.current_screen == "queue":
		var action_hit = host._skill_detail_surface()._module_action_circle_at_direct_position(event_position)
		if not action_hit.is_empty() and ModuleUiRuntime.belongs_to_skill(str(action_hit.get("module_key", "")), "fishing"):
			if host._skill_detail_surface()._route_module_action_zone_input(event):
				return true
	route_step_usec = Time.get_ticks_usec() if host._fishing_ui_surface()._fishing_input_trace_enabled() else 0
	if host._fishing_ui_surface()._route_fishing_active_tool_input(event):
		host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_active_tool", route_step_usec, event)
		return true
	host._fishing_ui_surface()._trace_fishing_input_duration("fishing_route_active_tool", route_step_usec, event)
	return false


func _fishing_area_card_at_position(event_position: Vector2) -> Dictionary:
	if not _position_inside_detail_actions_viewport(event_position):
		return {}
	host._skill_detail_surface()._prune_invalid_action_cards()
	if not host._skill_detail_surface()._module_action_circle_at_direct_position(event_position).is_empty():
		return {}
	var keys: Array = host.action_card_keys.duplicate()
	keys.reverse()
	for raw_key in keys:
		var key := str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card := host.action_cards[key] as Dictionary
		if not bool(card.get("is_fishing_area", false)):
			continue
		var pop: Control = host._app_lifecycle_runtime().valid_control_ref(card.get("pop", null))
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree():
			continue
		if not pop.get_global_rect().has_point(event_position):
			continue
		if not host._skill_detail_surface()._module_action_zone_kind_at_position(pop, event_position).is_empty():
			continue
		if host._fishing_ui_surface()._fishing_active_tool_hit_at_position(card, event_position):
			continue
		return card
	return {}


func _route_fishing_area_queue_selection_input(event: InputEvent) -> bool:
	if not host.queue_selection_mode:
		return false
	if host.current_screen != "skill" and host.current_screen != "pinned" and host.current_screen != "queue":
		return false
	if host.current_screen == "skill" and host.selected_skill_id != "fishing":
		return false
	var event_position := Vector2.INF
	var is_press := false
	var is_motion := false
	var is_release := false
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
	if is_press:
		if _position_inside_bottom_interactive_ui(event_position) or not _position_inside_detail_actions_viewport(event_position):
			return false
		var area_card := _fishing_area_card_at_position(event_position)
		if area_card.is_empty():
			return false
		var card_key := str(area_card.get("card_key", ""))
		if card_key.is_empty():
			card_key = ModuleUiRuntime.fishing_area(host.fishing_runtime.area_module_key(str(area_card.get("skill_id", "fishing")), area_card.get("area_def", {}) as Dictionary))
		if card_key.is_empty() or not host.action_cards.has(card_key):
			return false
		if host._skill_detail_surface().detail_actions_scroll != null and is_instance_valid(host._skill_detail_surface().detail_actions_scroll):
			host._skill_detail_surface().detail_actions_scroll.prepare_child_tap()
		host._skill_detail_surface().action_card_press_key = card_key
		host._skill_detail_surface().action_card_press_position = event_position
		host._skill_detail_surface().action_card_press_stat_kind = ""
		host._skill_detail_surface().action_card_press_dragged = false
		host._skill_swipe_activity_surface()._queue_action_card_3d_press(host._skill_detail_surface().action_card_press_key)
		return true
	if host._skill_detail_surface().action_card_press_key.is_empty():
		return false
	var pressed_card = host.action_cards.get(host._skill_detail_surface().action_card_press_key, {})
	if typeof(pressed_card) != TYPE_DICTIONARY or not bool((pressed_card as Dictionary).get("is_fishing_area", false)):
		return false
	if is_motion:
		host._skill_detail_surface()._update_action_card_press_drag_state(event)
		return true
	if is_release:
		return _route_action_card_release(event)
	return false


func _route_active_fishing_control_drag_handoff(event: InputEvent) -> bool:
	if not (event is InputEventMouseMotion or event is InputEventScreenDrag):
		return false
	if host._fishing_ui_surface().has_active_fishing_method_press():
		return host._fishing_ui_surface()._route_fishing_method_button_global_input(event)
	if host._fishing_ui_surface().has_active_fishing_offer_press():
		return host._fishing_ui_surface()._route_fishing_offer_button_global_input(event)
	return false


func _fishing_detail_plain_scroll_motion_can_skip_global_hit_tests(event: InputEvent, event_position: Vector2) -> bool:
	if not (event is InputEventMouseMotion or event is InputEventScreenDrag):
		return false
	if event_position == Vector2.INF:
		return false
	if not _position_inside_detail_actions_viewport(event_position) or _position_inside_bottom_interactive_ui(event_position):
		return false
	if host._navigation_shell().page_switch_press_active or host.module_ui_runtime.pin_press_active() or host._action_stop_hold().active():
		return false
	if host._fishing_ui_surface().has_active_fishing_button_press():
		return false
	if host._skill_swipe_activity_surface().skill_swipe_tracking:
		return false
	return true


func _pinned_fishing_detail_event_relevant(event_position: Vector2) -> bool:
	if host.module_ui_runtime.pin_press_active():
		return ModuleUiRuntime.belongs_to_skill(host.module_ui_runtime.pin_press_module_key(), "fishing")
	if not host._fishing_ui_surface()._active_fishing_method_button_hit().is_empty() or host._fishing_ui_surface()._active_fishing_offer_button() != null:
		return true
	if event_position == Vector2.INF:
		return false
	if not host._skill_detail_surface()._fishing_area_pin_corner_hit(event_position).is_empty():
		return true
	var action_hit = host._skill_detail_surface()._module_action_circle_at_direct_position(event_position)
	if not action_hit.is_empty() and ModuleUiRuntime.belongs_to_skill(str(action_hit.get("module_key", "")), "fishing"):
		return true
	if not host._fishing_ui_surface()._fishing_method_button_hit(event_position, true).is_empty():
		return true
	if host._fishing_ui_surface()._fishing_offer_button_hit(event_position, true) != null:
		return true
	return false


func _fishing_detail_event_position(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).global_position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).global_position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2.INF


func _fishing_detail_should_skip_generic_input(event: InputEvent) -> bool:
	if host.current_screen != "skill" or host.selected_skill_id != "fishing":
		return false
	if host._skill_swipe_activity_surface().skill_swipe_tracking:
		return false
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	var event_position = _fishing_detail_event_position(event)
	if event_position == Vector2.INF:
		return false
	if _position_inside_bottom_interactive_ui(event_position):
		return false
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if _page_switch_button_control_at_position(event_position) != null:
			return false
	if not _position_inside_detail_actions_viewport(event_position):
		return false
	return true


func _activity_card_is_locked_or_covered(skill_id: String, action: Dictionary, card: Dictionary) -> bool:
	if skill_id.is_empty() or action.is_empty() or card.is_empty():
		return true
	if host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
		return false
	return (
		bool(card.get("locked_preview_hidden", false))
		or bool(card.get("unlock_ready_pending", false))
		or bool(card.get("unlock_ceremony_pending", false))
		or bool(card.get("unlock_ceremony_active", false))
		or not (card.get("lock_overlay", {}) as Dictionary).is_empty()
	)


func _action_card_at_position(event_position: Vector2) -> Dictionary:
	if not _position_inside_detail_actions_viewport(event_position):
		return {}
	host._skill_detail_surface()._prune_invalid_action_cards()
	var action_circle_hit = host._skill_detail_surface()._module_action_circle_at_position(event_position)
	var keys = host.action_card_keys.duplicate()
	keys.reverse()
	for raw_key in keys:
		var key = str(raw_key)
		if not host.action_cards.has(key):
			continue
		var card = host.action_cards[key] as Dictionary
		var raw_pop = card.get("pop", null)
		var pop = host._app_lifecycle_runtime().valid_control_ref(raw_pop)
		if raw_pop != null and pop == null:
			host._skill_detail_surface()._discard_action_card_key(str(key))
			continue
		if pop == null or not pop.is_inside_tree() or not pop.is_visible_in_tree() or not pop.get_global_rect().has_point(event_position):
			continue
		var skill_id = str(card.get("skill_id", ""))
		var action_id = str(card.get("action_id", ""))
		if skill_id.is_empty() or action_id.is_empty():
			continue
		var action = host._action_data(skill_id, action_id)
		if action.is_empty():
			continue
		if (
			not action_circle_hit.is_empty()
			and _module_action_hit_belongs_to_card(action_circle_hit, card)
			and not host._is_event_action(action)
		):
			continue
		if host._passive_modules_runtime().is_passive_action(action):
			continue
		if bool(card.get("unlock_ceremony_active", false)) or bool(card.get("unlock_ceremony_pending", false)):
			continue
		return {
			"card": card,
			"skill_id": skill_id,
			"action_id": action_id
		}
	return {}


func _module_action_hit_belongs_to_card(hit: Dictionary, card: Dictionary) -> bool:
	if hit.is_empty() or card.is_empty():
		return false
	var hit_card = hit.get("card", {})
	if typeof(hit_card) == TYPE_DICTIONARY and not (hit_card as Dictionary).is_empty():
		return str((hit_card as Dictionary).get("card_key", "")) == str(card.get("card_key", ""))
	var hit_host = host._app_lifecycle_runtime().valid_control_ref(hit.get("host"))
	var card_pop = host._app_lifecycle_runtime().valid_control_ref(card.get("pop"))
	return hit_host != null and card_pop != null and hit_host == card_pop


func _route_action_card_release(event: InputEvent) -> bool:
	if host._skill_detail_surface().action_card_press_key.is_empty():
		return false
	var release_position = Vector2.ZERO
	var released = false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		release_position = event.global_position
		released = true
	elif event is InputEventScreenTouch and not event.pressed:
		release_position = event.position
		released = true
	if not released:
		return false
	var release_positions = _activity_input_position_candidates(release_position)
	var key = host._skill_detail_surface().action_card_press_key
	var stat_kind = host._skill_detail_surface().action_card_press_stat_kind
	var dragged = host._skill_detail_surface().action_card_press_dragged
	host._skill_detail_surface().action_card_press_key = ""
	host._skill_detail_surface().action_card_press_stat_kind = ""
	host._skill_detail_surface().action_card_press_dragged = false
	host._skill_swipe_activity_surface()._release_action_card_3d_press(key)
	if host._navigation_shell()._position_inside_bottom_nav(release_position):
		return false
	if not _position_inside_detail_actions_viewport(release_position):
		return false
	if not host.action_cards.has(key):
		return false
	var card = host.action_cards[key] as Dictionary
	var raw_pop = card.get("pop", null)
	var pop = host._app_lifecycle_runtime().valid_control_ref(raw_pop)
	if raw_pop != null and pop == null:
		host._skill_detail_surface()._discard_action_card_key(key)
		return false
	if pop != null and (not pop.is_inside_tree() or not pop.is_visible_in_tree()):
		return false
	if pop != null and _first_position_in_rect(release_positions, pop.get_global_rect()) == null:
		var root = host._app_lifecycle_runtime().valid_control_ref(card.get("root"))
		if root == null or _first_position_in_rect(release_positions, root.get_global_rect()) == null:
			return false
	elif pop == null:
		return false
	var close_to_press = _event_positions_close_to_press(release_positions)
	if not stat_kind.is_empty():
		close_to_press = host._skill_detail_surface()._event_positions_inside_activity_stat_box(card, stat_kind, release_positions)
	if dragged or not close_to_press:
		return false
	if host._skill_swipe_activity_surface()._skill_swipe_suppresses_button_action():
		if stat_kind.is_empty():
			return false
		host._skill_swipe_activity_surface()._clear_skill_swipe_button_suppression()
	if host.queue_selection_mode and stat_kind.is_empty():
		return host._skill_swipe_activity_surface()._queue_selection_toggle_from_card(card)
	var skill_id = str(card.get("skill_id", ""))
	var action_id = str(card.get("action_id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return false
	var action = host._action_data(skill_id, action_id)
	var unlocked = not action.is_empty() and host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
	if stat_kind == host.ACTION_CARD_MEDAL_PRESS_KIND:
		host._skill_swipe_activity_surface()._play_action_card_medal_tap_ceremony(card)
	elif not stat_kind.is_empty():
		host._skill_detail_surface()._toggle_activity_stat_popup_for_card(card, skill_id, action_id, stat_kind)
	elif unlocked:
		if host.current_screen == "queue":
			var module_key = host._skill_swipe_activity_surface()._activity_queue_module_key_for_card(card)
			if not module_key.is_empty():
				host._activity_queue_runtime()._start_activity_queue_from_key(module_key)
		else:
			host._action_runtime()._start_action_from_card_tap(skill_id, action_id, key)
	host._skill_swipe_activity_surface().skill_swipe_tracking = false
	return true


func _route_page_switch_button_global_input(event: InputEvent) -> bool:
	if host.current_screen != "skill":
		return false
	if not (
		event is InputEventMouseButton
		or event is InputEventMouseMotion
		or event is InputEventScreenTouch
		or event is InputEventScreenDrag
	):
		return false
	var event_position = _passive_button_event_position(event, null)
	var is_press = (
		(event is InputEventMouseButton and (event as InputEventMouseButton).pressed)
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	)
	var is_release = (
		(event is InputEventMouseButton and not (event as InputEventMouseButton).pressed)
		or (event is InputEventScreenTouch and not (event as InputEventScreenTouch).pressed)
	)
	var navigation_shell = host._navigation_shell()
	if _position_inside_bottom_interactive_ui(event_position):
		if navigation_shell.page_switch_press_active and is_release:
			var active_bottom_button = navigation_shell._active_page_switch_button()
			if active_bottom_button != null:
				navigation_shell._clear_page_switch_button_press_state(active_bottom_button)
				navigation_shell._release_page_switch_button_shell(active_bottom_button)
			navigation_shell._clear_page_switch_press_state()
		return false
	navigation_shell._recover_stale_page_switch_input_lock()
	if navigation_shell._page_switch_input_locked() and not navigation_shell.page_switch_press_active:
		var locked_button = _page_switch_button_at_position(event_position) if is_press else navigation_shell._active_page_switch_button()
		return locked_button != null or navigation_shell._page_switch_scroll_cover_active()
	if navigation_shell.page_switch_press_active and (event is InputEventMouseMotion or event is InputEventScreenDrag):
		if event_position.distance_to(navigation_shell.page_switch_press_position) > host.PASSIVE_BUTTON_TAP_RELEASE_SLOP:
			navigation_shell.page_switch_press_dragged = true
		var active_motion_button = navigation_shell._active_page_switch_button()
		if active_motion_button != null:
			navigation_shell._on_page_switch_button_gui_input(event, navigation_shell.page_switch_press_target_skill_id, active_motion_button)
		return true
	if navigation_shell.page_switch_press_active and is_release:
		var target_skill_id = navigation_shell.page_switch_press_target_skill_id
		var valid_tap = (
			not navigation_shell.page_switch_press_dragged
			and event_position.distance_to(navigation_shell.page_switch_press_position) <= host.PASSIVE_BUTTON_TAP_RELEASE_SLOP
			and not target_skill_id.is_empty()
		)
		var active_release_button = navigation_shell._active_page_switch_button()
		if active_release_button != null:
			navigation_shell._clear_page_switch_button_press_state(active_release_button, valid_tap)
			if not valid_tap:
				navigation_shell._release_page_switch_button_shell(active_release_button)
			navigation_shell._suppress_page_switch_pressed_signal(active_release_button)
		navigation_shell._clear_page_switch_press_state()
		if valid_tap:
			host._navigation_shell()._select_skill_from_page_switch(target_skill_id, active_release_button)
		return true
	var button = _page_switch_button_at_position(event_position) if is_press else navigation_shell._active_page_switch_button()
	if button == null:
		return false
	var target_skill_id = str(button.get_meta("page_switch_target_skill_id", ""))
	if target_skill_id.is_empty():
		return false
	if is_press:
		navigation_shell.page_switch_press_active = true
		navigation_shell.page_switch_press_target_skill_id = target_skill_id
		navigation_shell.page_switch_press_position = event_position
		navigation_shell.page_switch_press_dragged = false
	navigation_shell._on_page_switch_button_gui_input(event, target_skill_id, button)
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	host._skill_detail_surface().action_card_press_key = ""
	return true


func _page_switch_button_at_position(event_position: Vector2) -> Button:
	if not _action_card_at_position(event_position).is_empty():
		return null
	return _page_switch_button_control_at_position(event_position)


func _page_switch_button_control_at_position(event_position: Vector2) -> Button:
	var tree = host.get_tree()
	if tree == null or event_position == Vector2.INF:
		return null
	var positions = _activity_input_position_candidates(event_position)
	for raw_node in tree.get_nodes_in_group("page_switch_buttons"):
		var button = raw_node as Button
		if button == null or not is_instance_valid(button) or button.disabled:
			continue
		if not host._navigation_shell()._page_switch_button_belongs_to_current_page(button):
			continue
		if not button.is_inside_tree() or not button.is_visible_in_tree():
			continue
		if _first_position_in_rect(positions, button.get_global_rect().grow(24.0)) != null:
			return button
	return null
