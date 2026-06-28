extends RefCounted


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
