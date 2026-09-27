extends RefCounted

static func wait_for_startup(tree: SceneTree, scene: Node) -> bool:
	for _i in range(240):
		if bool(scene.get("startup_initialized")):
			return true
		await tree.process_frame
	return false

static func mouse_button_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	return event

static func truthy_approx(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return not is_zero_approx(float(value))
		TYPE_STRING:
			return not str(value).is_empty()
		_:
			return value != null

static func rendered_action_ids(scene: Node) -> Array:
	var ids := []
	var cards := scene.get("action_cards") as Dictionary
	if cards == null:
		return ids
	for raw_key in cards.keys():
		var key := str(raw_key)
		if key.begins_with("fight:"):
			ids.append(key.substr("fight:".length()))
	ids.sort()
	return ids

static func wait_for_boot_ready_strict(tree: SceneTree, timeout_frames: int, scene: Node) -> bool:
	for _frame in range(timeout_frames):
		await tree.process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			scene.get("startup_initialized") == true
			and scene.get("boot_detail_render_in_progress") != true
			and scene.get("boot_detail_scroll_locked") != true
			and (queue == null or queue.is_empty())
		):
			return true
	return false

static func wait_for_boot_hidden(tree: SceneTree, timeout_frames: int, scene: Node) -> bool:
	for _frame in range(timeout_frames):
		await tree.process_frame
		var overlay := scene.get("boot_warmup_overlay") as Control
		if scene.get("boot_warmup_active") != true and (overlay == null or not overlay.visible or overlay.modulate.a <= 0.01):
			return true
	return false

static func wait_for_regen_circle(tree: SceneTree, settle_frames: int, scene: Node, skill_id: String) -> Control:
	for _frame in range(settle_frames * 3):
		await tree.call("_wait_test_frame")
		if str(scene.get("current_screen")) != "skill" or str(scene.get("selected_skill_id")) != skill_id:
			continue
		var circle := scene._skill_detail_surface().detail_regen_circle as Control
		if circle != null and circle.is_inside_tree() and circle.visible:
			return circle
	return null

static func wait_for_boot_ready(tree: SceneTree, timeout_frames: int, scene: Node) -> bool:
	for _frame in range(timeout_frames):
		await tree.process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false

static func valid_control(value: Variant) -> Control:
	if value == null:
		return null
	if not is_instance_valid(value):
		return null
	return value as Control

static func valid_control_object(value) -> Control:
	if value == null or typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value as Control

static func wait_for_boot_ready_truthy(tree: SceneTree, timeout_frames: int, scene: Node) -> bool:
	for _frame in range(timeout_frames):
		await tree.process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			truthy(scene.get("startup_initialized"))
			and not truthy(scene.get("boot_detail_render_in_progress"))
			and not truthy(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false

static func truthy(value: Variant) -> bool:
	if value == null:
		return false
	if value is bool:
		return value
	if value is int or value is float:
		return value != 0
	if value is String:
		return not value.is_empty()
	return true

static func has_real_content(control: Control) -> bool:
	if truthy(control.get_meta("detail_lazy_placeholder", false)):
		return false
	if not control.visible or control.modulate.a <= 0.01:
		return false
	if truthy(control.get_meta("detail_stack_entry_wrapper", false)):
		for raw_child in control.get_children():
			var child := valid_control(raw_child)
			if child != null and not truthy(child.get_meta("detail_lazy_placeholder", false)) and child.visible and child.modulate.a > 0.01:
				return true
		return false
	return maxf(control.size.y, control.custom_minimum_size.y) > 1.0

static func placeholder_count(control: Control) -> int:
	var count := 0
	if truthy(control.get_meta("detail_lazy_placeholder", false)):
		count += 1
	for raw_child in control.get_children():
		var child := valid_control(raw_child)
		if child != null:
			count += placeholder_count(child)
	return count

static func control_intersects_viewport(control: Control, viewport_rect: Rect2) -> bool:
	if not control.visible or control.modulate.a <= 0.01:
		return false
	var rect := control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	return rect.intersects(viewport_rect)

static func average(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())

static func percentile(values: Array[int], pct: float) -> int:
	if values.is_empty():
		return 0
	var sorted := values.duplicate()
	sorted.sort()
	var index := clampi(int(floor(float(sorted.size() - 1) * pct)), 0, sorted.size() - 1)
	return int(sorted[index])
