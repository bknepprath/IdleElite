extends RefCounted

const AudioDirector = preload("res://scripts/audio/audio_director.gd")

const STAMINA_GAUGE_PARENT_BUTTON_SUPPRESS_MSEC := 650

var host
var depressed_buttons := {}
var nav_pop_tweens := {}
var bottom_nav_transition_button_id := 0
var bottom_nav_transition_release_queued := false


func _init(host_ref = null) -> void:
	host = host_ref


static func event_kind(event: InputEvent) -> String:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		return "press" if event.pressed else "release"
	if event is InputEventScreenTouch:
		return "press" if (event as InputEventScreenTouch).pressed else "release"
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		return "drag"
	return ""


static func active(button: Button, prefix: String) -> bool:
	return button != null and is_instance_valid(button) and bool(button.get_meta(_meta_key(prefix, "active"), false))


static func begin(button: Button, prefix: String, press_position: Vector2) -> void:
	button.set_meta(_meta_key(prefix, "active"), true)
	button.set_meta(_meta_key(prefix, "position"), press_position)
	button.set_meta(_meta_key(prefix, "dragged"), false)


static func update_drag(button: Button, prefix: String, event_position: Vector2, release_slop: float) -> void:
	if not active(button, prefix):
		return
	var press_position := _meta_vector2(button, _meta_key(prefix, "position"), event_position)
	if event_position.distance_to(press_position) > release_slop:
		button.set_meta(_meta_key(prefix, "dragged"), true)


static func finish(button: Button, prefix: String, event_position: Vector2, release_slop: float, hit_grow := -1.0, extra_fields := []) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	var active_key := _meta_key(prefix, "active")
	var position_key := _meta_key(prefix, "position")
	var dragged_key := _meta_key(prefix, "dragged")
	var was_active := bool(button.get_meta(active_key, false))
	var was_dragged := bool(button.get_meta(dragged_key, false))
	var press_position := _meta_vector2(button, position_key, event_position)
	clear(button, prefix, extra_fields)
	if not was_active or was_dragged:
		return false
	if event_position.distance_to(press_position) > release_slop:
		return false
	return hit_grow < 0.0 or button.get_global_rect().grow(hit_grow).has_point(event_position)


static func clear(button: Button, prefix: String, extra_fields := []) -> void:
	if button == null or not is_instance_valid(button):
		return
	for field in ["active", "position", "dragged"]:
		var key := _meta_key(prefix, field)
		if button.has_meta(key):
			button.remove_meta(key)
	for field in extra_fields:
		var key := _meta_key(prefix, str(field))
		if button.has_meta(key):
			button.remove_meta(key)


static func _meta_key(prefix: String, field: String) -> String:
	return "%s_press_%s" % [prefix, field]


static func _meta_vector2(button: Button, key: String, fallback: Vector2) -> Vector2:
	var raw_value = button.get_meta(key, fallback)
	if raw_value is Vector2:
		return raw_value
	return fallback


func attach_button_depress_animation(button: BaseButton, depressed_scale := 0.965, play_sfx := true) -> void:
	if button == null:
		return
	button.set_meta("depress_animation_scale", depressed_scale)
	if button.has_meta("depress_animation_attached"):
		return
	button.set_meta("depress_animation_attached", true)
	if play_sfx:
		attach_default_button_sfx(button)
	var button_id := button.get_instance_id()
	var resize_callable := _sync_button_pivot_offset_bound.bind(button_id)
	if not button.resized.is_connected(resize_callable):
		button.resized.connect(resize_callable)
	var button_down_callable := _animate_button_depress_bound.bind(button_id, depressed_scale)
	if not button.button_down.is_connected(button_down_callable):
		button.button_down.connect(button_down_callable)
	var button_up_callable := _animate_button_release_bound.bind(button_id)
	if not button.button_up.is_connected(button_up_callable):
		button.button_up.connect(button_up_callable)


func attach_default_button_sfx(button: BaseButton) -> void:
	if button == null or button.has_meta("default_button_sfx_attached"):
		return
	button.set_meta("default_button_sfx_attached", true)
	var sfx_callable := _play_default_button_sfx_for_button_bound.bind(button.get_instance_id())
	if not button.button_down.is_connected(sfx_callable):
		button.button_down.connect(sfx_callable)


func _sync_button_pivot_offset_bound(button_id: int) -> void:
	var button := _valid_base_button_ref(instance_from_id(button_id))
	if button != null:
		button.pivot_offset = button.size * 0.5


func _animate_button_depress_bound(button_id: int, depressed_scale: float) -> void:
	var button := _valid_base_button_ref(instance_from_id(button_id))
	if button != null:
		animate_button_depress(button, depressed_scale)


func _animate_button_release_bound(button_id: int) -> void:
	var button := _valid_base_button_ref(instance_from_id(button_id))
	if button != null:
		animate_button_release(button)


func _play_default_button_sfx_for_button_bound(button_id: int) -> void:
	var button := _valid_base_button_ref(instance_from_id(button_id))
	if button != null:
		play_default_button_sfx_for_button(button)


func _pop_nav_button(button: Button) -> void:
	if button == null or not is_instance_valid(button):
		return
	if bool(button.get_meta("bottom_nav_transition_hold", false)):
		return
	kill_button_depress_tween(button)
	var key := button.get_instance_id()
	clear_nav_pop_tween(key)
	button.scale = Vector2.ONE
	button.pivot_offset = button.size * 0.5
	var tween: Tween = host.create_tween()
	nav_pop_tweens[key] = tween
	tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_nav_button_pop.bind(key))


func _finish_nav_button_pop(key: int) -> void:
	nav_pop_tweens.erase(key)


func _pop_nav_button_bound(button_id: int) -> void:
	var button := _valid_button_ref(instance_from_id(button_id))
	if button == null:
		return
	_pop_nav_button(button)


func clear_nav_pop_tween(button_id: int) -> void:
	if not nav_pop_tweens.has(button_id):
		return
	host._app_lifecycle_runtime()._kill_tween_value(nav_pop_tweens[button_id])
	nav_pop_tweens.erase(button_id)


func clear_all_nav_pop_tweens() -> void:
	for tween in nav_pop_tweens.values():
		host._app_lifecycle_runtime()._kill_tween_value(tween)
	nav_pop_tweens.clear()


func hold_bottom_nav_transition_button(button: Button) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if bottom_nav_transition_button_id != 0 and bottom_nav_transition_button_id != button.get_instance_id():
		release_bottom_nav_transition_button()
	var button_id := button.get_instance_id()
	bottom_nav_transition_button_id = button_id
	button.set_meta("bottom_nav_transition_hold", true)
	clear_nav_pop_tween(button_id)
	animate_button_depress(button, float(button.get_meta("depress_animation_scale", 0.92)))


func bottom_nav_transition_active() -> bool:
	return bottom_nav_transition_button_id != 0


func bottom_nav_transition_visual_active(visual_blocker: Callable) -> bool:
	return bottom_nav_transition_active() and visual_blocker.is_valid() and bool(visual_blocker.call())


func release_bottom_nav_transition_button() -> void:
	if bottom_nav_transition_button_id == 0:
		return
	var button := _valid_base_button_ref(instance_from_id(bottom_nav_transition_button_id))
	bottom_nav_transition_button_id = 0
	bottom_nav_transition_release_queued = false
	if button == null:
		return
	if button.has_meta("bottom_nav_transition_hold"):
		button.remove_meta("bottom_nav_transition_hold")
	animate_button_release(button)


func _release_bottom_nav_transition_button() -> void:
	release_bottom_nav_transition_button()


func _schedule_bottom_nav_transition_button_idle_release() -> void:
	if bottom_nav_transition_release_queued:
		return
	bottom_nav_transition_release_queued = true
	call_deferred("_release_bottom_nav_transition_button_when_idle")


func _release_bottom_nav_transition_button_when_idle() -> void:
	await host.get_tree().process_frame
	bottom_nav_transition_release_queued = false
	if bottom_nav_transition_button_id == 0:
		return
	if bottom_nav_transition_visual_active(Callable(host._navigation_shell(), "_bottom_nav_transition_visual_active")):
		_schedule_bottom_nav_transition_button_idle_release()
		return
	release_bottom_nav_transition_button()


func play_default_button_sfx() -> void:
	var director: AudioDirector = host._audio_director()
	var now := Time.get_ticks_msec()
	if now - director.last_default_button_sfx_msec < AudioDirector.DEFAULT_BUTTON_SFX_DEBOUNCE_MSEC:
		return
	director.last_default_button_sfx_msec = now
	director._ensure_click_player()
	director._play_click_sfx()


func play_default_button_sfx_for_button(button: BaseButton) -> void:
	if is_dead_reset_confirm_press(button):
		button.set_meta("suppress_current_press_animation", true)
		return
	if _button_has_active_stamina_gauge_parent_suppression(button):
		button.set_meta("suppress_current_press_animation", true)
		return
	if button_sfx_is_active_action_tap(button):
		return
	play_default_button_sfx()


func _suppress_stamina_gauge_parent_button(source: Control) -> void:
	var button := _stamina_gauge_parent_button(source)
	if button == null:
		return
	button.set_meta("stamina_gauge_suppress_parent_until_msec", Time.get_ticks_msec() + STAMINA_GAUGE_PARENT_BUTTON_SUPPRESS_MSEC)
	button.set_meta("suppress_current_press_animation", true)


func _stamina_gauge_parent_button(source: Control) -> BaseButton:
	var node := source as Node
	while node != null:
		if node is BaseButton:
			return node as BaseButton
		node = node.get_parent()
	return null


func _button_has_active_stamina_gauge_parent_suppression(button: BaseButton) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	var until_msec := int(button.get_meta("stamina_gauge_suppress_parent_until_msec", 0))
	if until_msec <= 0:
		return false
	if Time.get_ticks_msec() <= until_msec:
		return true
	button.remove_meta("stamina_gauge_suppress_parent_until_msec")
	return false


func button_sfx_is_active_action_tap(button: BaseButton) -> bool:
	if button == null:
		return false
	var skill_id := str(button.get_meta("action_button_skill_id", ""))
	var action_id := str(button.get_meta("action_button_action_id", ""))
	return not skill_id.is_empty() and not action_id.is_empty()


func animate_button_depress(button: BaseButton, depressed_scale: float) -> void:
	if button == null or not is_instance_valid(button) or button.disabled:
		return
	if is_dead_reset_confirm_press(button):
		button.set_meta("suppress_current_press_animation", true)
		return
	kill_button_depress_tween(button)
	depressed_buttons[button.get_instance_id()] = button
	button.pivot_offset = button.size * 0.5
	var tween: Tween = host.create_tween()
	button.set_meta("depress_tween", tween)
	tween.tween_property(button, "scale", Vector2(depressed_scale, depressed_scale), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func animate_button_release(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	if bool(button.get_meta("bottom_nav_transition_hold", false)):
		force_button_unpressed(button)
		kill_button_depress_tween(button)
		depressed_buttons[button.get_instance_id()] = button
		button.pivot_offset = button.size * 0.5
		var hold_scale := float(button.get_meta("depress_animation_scale", 0.92))
		var tween: Tween = host.create_tween()
		button.set_meta("depress_tween", tween)
		tween.tween_property(button, "scale", Vector2(hold_scale, hold_scale), 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		return
	depressed_buttons.erase(button.get_instance_id())
	force_button_unpressed(button)
	if bool(button.get_meta("suppress_current_press_animation", false)):
		button.remove_meta("suppress_current_press_animation")
		button.scale = Vector2.ONE
		button.pivot_offset = button.size * 0.5
		return
	kill_button_depress_tween(button)
	var tween: Tween = host.create_tween()
	button.set_meta("depress_tween", tween)
	var release_trans := Tween.TRANS_QUAD if bool(button.get_meta("depress_release_no_overshoot", false)) else Tween.TRANS_BACK
	tween.tween_property(button, "scale", Vector2.ONE, 0.105).set_trans(release_trans).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_finish_button_release_tween.bind(button.get_instance_id()))


func _finish_button_release_tween(button_id: int) -> void:
	var button := _valid_base_button_ref(instance_from_id(button_id))
	if button != null and button.has_meta("depress_tween"):
		button.remove_meta("depress_tween")


func is_dead_reset_confirm_press(button: BaseButton) -> bool:
	return host._settings_surface()._is_dead_reset_confirm_press(button)


func kill_button_depress_tween(button: BaseButton) -> void:
	host._app_lifecycle_runtime()._kill_meta_tween(button, "depress_tween")


func force_button_unpressed(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	if button.toggle_mode:
		return
	if button.has_method("set_pressed_no_signal"):
		button.call("set_pressed_no_signal", false)
	else:
		button.button_pressed = false


func release_depressed_buttons_if_pointer_left(event: InputEvent) -> void:
	if depressed_buttons.is_empty():
		return
	var event_position := Vector2.ZERO
	var has_event_position := false
	if event is InputEventMouseMotion:
		event_position = (event as InputEventMouseMotion).global_position
		has_event_position = true
	elif event is InputEventScreenDrag:
		event_position = (event as InputEventScreenDrag).position
		has_event_position = true
	if not has_event_position:
		return
	for raw_button in depressed_buttons.values().duplicate():
		var button := raw_button as BaseButton
		if button == null or not is_instance_valid(button):
			continue
		if bool(button.get_meta("bottom_nav_transition_hold", false)):
			force_button_unpressed(button)
			continue
		if pointer_inside_button_release_rect(event_position, button):
			continue
		animate_button_release(button)


func pointer_inside_button_release_rect(event_position: Vector2, button: Control) -> bool:
	if button == null or not is_instance_valid(button) or not button.is_visible_in_tree():
		return false
	var rect := button.get_global_rect().grow(42.0)
	for candidate in host._input_routing_shell()._activity_input_position_candidates(event_position):
		if rect.has_point(candidate):
			return true
	return false


func release_all_depressed_buttons() -> void:
	if depressed_buttons.is_empty():
		return
	var buttons := depressed_buttons.values()
	depressed_buttons.clear()
	for raw_button in buttons:
		var button := raw_button as BaseButton
		if button == null or not is_instance_valid(button):
			continue
		if bool(button.get_meta("bottom_nav_transition_hold", false)):
			depressed_buttons[button.get_instance_id()] = button
			force_button_unpressed(button)
			continue
		force_button_unpressed(button)
		kill_button_depress_tween(button)
		button.scale = Vector2.ONE
		button.pivot_offset = button.size * 0.5


func _input_event_releases_primary_pointer(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		return not event.pressed
	if event is InputEventScreenTouch:
		return not event.pressed
	return false


func _primary_press_started_on_button(event: InputEvent) -> bool:
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
	return _button_at_global_position(host, event_position) != null


func _button_at_global_position(node: Node, event_position: Vector2) -> BaseButton:
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
		return null
	var control := node as Control
	if control != null:
		if not control.is_inside_tree() or not control.is_visible_in_tree():
			return null
		if control.clip_contents and not control.get_global_rect().grow(2.0).has_point(event_position):
			return null
	var children := node.get_children()
	for index in range(children.size() - 1, -1, -1):
		var child_button := _button_at_global_position(children[index] as Node, event_position)
		if child_button != null:
			return child_button
	var button := node as BaseButton
	if button == null:
		return null
	if button.disabled or button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return null
	if not button.get_global_rect().grow(2.0).has_point(event_position):
		return null
	return button


func _valid_base_button_ref(value) -> BaseButton:
	if host != null and host.has_method("_valid_base_button_ref"):
		return host._app_lifecycle_runtime().valid_base_button_ref(value)
	if value == null or typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value as BaseButton


func _valid_button_ref(value) -> Button:
	if host != null and host.has_method("_valid_button_ref"):
		return host._app_lifecycle_runtime().valid_button_ref(value)
	if value == null or typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value as Button
