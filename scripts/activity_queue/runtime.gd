extends RefCounted

const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")

var host
var activity_queue: Array = []
var activity_queue_running := false
var activity_queue_index := -1
var activity_queue_attempt_key := ""


func _init(host_ref) -> void:
	host = host_ref


func get_activity_queue() -> Array:
	activity_queue = _activity_queue_unlocked_only(_normalized_queue(activity_queue))
	return activity_queue.duplicate()


func set_activity_queue(entries) -> void:
	activity_queue = _activity_queue_unlocked_only(_normalized_queue(entries))
	host._mark_save_dirty("activity queue changed")
	host.save_game()
	host._skill_swipe_activity_surface()._refresh_activity_queue_visuals()


func add_activity_to_queue(entry) -> bool:
	var key: String = ModuleUiRuntime.normalize(entry)
	if key.is_empty() or not _activity_queue_key_is_queueable(key):
		return false
	if activity_queue.has(key):
		return false
	activity_queue.append(key)
	activity_queue = _activity_queue_unlocked_only(_normalized_queue(activity_queue))
	host._mark_save_dirty("activity queued")
	host.save_game()
	host._skill_swipe_activity_surface()._refresh_activity_queue_visuals()
	return true


func remove_activity_from_queue(entry) -> bool:
	var key: String = ModuleUiRuntime.normalize(entry)
	if key.is_empty() or not activity_queue.has(key):
		return false
	var removed_index: int = activity_queue.find(key)
	activity_queue.erase(key)
	if activity_queue_running:
		if removed_index < activity_queue_index:
			activity_queue_index -= 1
		elif removed_index == activity_queue_index:
			activity_queue_attempt_key = ""
	host._mark_save_dirty("activity dequeued")
	host.save_game()
	host._skill_swipe_activity_surface()._refresh_activity_queue_visuals()
	return true


func is_activity_queued(entry) -> bool:
	var key: String = ModuleUiRuntime.normalize(entry)
	return not key.is_empty() and activity_queue.has(key)


func get_queue_index(entry) -> int:
	var key: String = ModuleUiRuntime.normalize(entry)
	if key.is_empty():
		return -1
	return activity_queue.find(key)


func _activity_queue_active_shelf_skill_id() -> String:
	if activity_queue_running and not host.running_skill_id.is_empty() and not host.running_action_id.is_empty():
		return host.running_skill_id
	return ""


func clear_activity_queue() -> void:
	if activity_queue.is_empty():
		return
	activity_queue.clear()
	_stop_activity_queue_runtime(false)
	host._mark_save_dirty("activity queue cleared")
	host.save_game()
	host._skill_swipe_activity_surface()._refresh_activity_queue_visuals()


func _activity_queue_for_save() -> Array:
	return _activity_queue_unlocked_only(_normalized_queue(activity_queue))


func _restore_activity_queue_from_save(data: Dictionary) -> void:
	activity_queue = _activity_queue_unlocked_only(_normalized_queue(data.get("activity_queue", [])))
	activity_queue_running = false
	activity_queue_index = -1
	activity_queue_attempt_key = ""
	host.queue_selection_mode = false


func _normalized_queue(value: Variant) -> Array:
	var queue: Array = []
	if typeof(value) != TYPE_ARRAY:
		return queue
	var seen := {}
	for raw_key in value:
		var key := ModuleUiRuntime.normalize(raw_key)
		if key.is_empty() or seen.has(key):
			continue
		seen[key] = true
		queue.append(key)
	return queue


func _next_index(current_index: int, queue_size: int) -> int:
	if queue_size <= 0:
		return -1
	return (current_index + 1) % queue_size


func _activity_queue_unlocked_only(keys: Array) -> Array:
	var filtered: Array = []
	for raw_key in keys:
		var key: String = ModuleUiRuntime.normalize(raw_key)
		if not key.is_empty() and _activity_queue_key_is_queueable(key):
			filtered.append(key)
	return filtered


func _activity_queue_key_is_queueable(module_key: String) -> bool:
	var key: String = ModuleUiRuntime.normalize(module_key)
	if key.is_empty():
		return false
	if key.begins_with("action:"):
		var action_parts: PackedStringArray = key.substr("action:".length()).split(":", false, 2)
		if action_parts.size() < 2:
			return false
		var skill_id: String = str(action_parts[0])
		var action: Dictionary = host._action_data(skill_id, str(action_parts[1]))
		return (
			not action.is_empty()
			and host._activity_unlock_runtime()._is_action_unlocked(skill_id, action)
			and not host._passive_modules_runtime().is_passive_action(action)
			and not host._is_event_action(action)
		)
	if key.begins_with("fishing_area:"):
		return host._skill_detail_surface()._module_ui_fishing_area_is_unlocked(key)
	return false


func _start_activity_queue_from_key(module_key: String) -> bool:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.is_empty():
		return false
	var queue := get_activity_queue()
	var start_index := queue.find(normalized_key)
	if start_index < 0:
		return false
	activity_queue_running = true
	activity_queue_index = start_index
	activity_queue_attempt_key = ""
	return _advance_activity_queue_to_runnable()


func _stop_activity_queue_runtime(clear_running_action := false) -> void:
	activity_queue_running = false
	activity_queue_index = -1
	activity_queue_attempt_key = ""
	if clear_running_action:
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
		host._action_runtime()._reset_action_opportunity_state()


func _process_activity_queue_runtime() -> void:
	if not activity_queue_running:
		return
	var queue := get_activity_queue()
	if queue.is_empty() or activity_queue_index < 0:
		_stop_activity_queue_runtime()
		return
	if activity_queue_index >= queue.size():
		activity_queue_index = 0
	if host.running_skill_id.is_empty() or host.running_action_id.is_empty():
		_advance_activity_queue_to_runnable()
		return
	var active_key := _activity_queue_key_for_running_action(host.running_skill_id, host.running_action_id)
	if active_key.is_empty() or active_key != activity_queue_attempt_key:
		_stop_activity_queue_runtime()
		return
	var action: Dictionary = host._action_data(host.running_skill_id, host.running_action_id)
	if action.is_empty() or not host._activity_unlock_runtime()._is_action_unlocked(host.running_skill_id, action):
		activity_queue_index = _next_index(activity_queue_index, queue.size())
		_advance_activity_queue_to_runnable()
		return
	if host._fishing_rework_active_for_skill(host.running_skill_id) and not host._is_event_action(action):
		return
	if _activity_queue_should_advance_for_action(host.running_skill_id, action):
		activity_queue_index = _next_index(activity_queue_index, queue.size())
		_advance_activity_queue_to_runnable()


func _advance_activity_queue_to_runnable() -> bool:
	var queue := get_activity_queue()
	if queue.is_empty() or activity_queue_index < 0:
		_stop_activity_queue_runtime(true)
		host._reward_feedback_surface()._set_result("Queue finished.")
		host._update_ui(0.0, true)
		return false
	activity_queue_index = activity_queue_index % queue.size()
	var attempts_remaining := queue.size()
	while attempts_remaining > 0:
		var module_key: String = ModuleUiRuntime.normalize(queue[activity_queue_index])
		var target := _activity_queue_target_for_key(module_key)
		if target.is_empty():
			activity_queue_index = _next_index(activity_queue_index, queue.size())
			attempts_remaining -= 1
			continue
		var skill_id := str(target.get("skill_id", ""))
		var action_id := str(target.get("action_id", ""))
		var action: Dictionary = host._action_data(skill_id, action_id)
		if action.is_empty() or host._passive_modules_runtime().is_passive_action(action) or not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
			activity_queue_index = _next_index(activity_queue_index, queue.size())
			attempts_remaining -= 1
			continue
		if skill_id == "thieving" and host._thieving_surface()._thieving_action_is_jailed(action_id):
			activity_queue_index = _next_index(activity_queue_index, queue.size())
			attempts_remaining -= 1
			continue
		var fishing_rework_attempt: bool = host._fishing_rework_active_for_skill(skill_id) and not host._is_event_action(action)
		if not fishing_rework_attempt and _activity_queue_should_advance_for_action(skill_id, action):
			activity_queue_index = _next_index(activity_queue_index, queue.size())
			attempts_remaining -= 1
			continue
		activity_queue_attempt_key = module_key
		if host._action_runtime()._start_action(skill_id, action_id, true, false, true):
			host._reward_feedback_surface()._set_result("Queue: %s started." % str(action.get("name", "Activity")))
			host._update_ui(0.0, true)
			return true
		activity_queue_index = _next_index(activity_queue_index, queue.size())
		attempts_remaining -= 1
	_stop_activity_queue_runtime(true)
	host._reward_feedback_surface()._set_result("Queue finished.")
	host._update_ui(0.0, true)
	return false


func _activity_queue_should_advance_for_action(skill_id: String, action: Dictionary) -> bool:
	if RecoveryModules.has_recovery(action):
		return RecoveryModules.recovery_target_is_full(skill_id, action, host.skill_defs, host.stamina, Callable(SkillState, "host_stamina_value").bind(host), Callable(SkillState, "host_max_stamina").bind(host))
	var cost: float = host._action_runtime()._effective_stamina(skill_id, action)
	return SkillState.host_stamina_value(skill_id, host) + 0.0001 < cost


func _activity_queue_target_for_key(module_key: String) -> Dictionary:
	var normalized_key: String = ModuleUiRuntime.normalize(module_key)
	if normalized_key.begins_with("action:"):
		var action_key: String = normalized_key.substr("action:".length())
		var parts: PackedStringArray = action_key.split(":", false, 2)
		if parts.size() < 2:
			return {}
		return {"skill_id": str(parts[0]), "action_id": str(parts[1])}
	if normalized_key.begins_with("fishing_area:"):
		var area_key: String = normalized_key.substr("fishing_area:".length())
		for raw_area_def in host._fishing_ui_surface().render_area_modules("fishing"):
			var area_def := raw_area_def as Dictionary
			if host.fishing_runtime.area_module_key("fishing", area_def) != area_key:
				continue
			var selected_id: String = _activity_queue_selected_fishing_action_for_area(area_def)
			if selected_id.is_empty():
				return {}
			return {"skill_id": "fishing", "action_id": selected_id}
	return {}


func _activity_queue_selected_fishing_action_for_area(area_def: Dictionary) -> String:
	var area_key: String = host.fishing_runtime.area_module_key("fishing", area_def)
	for raw_card in host.action_cards.values():
		if typeof(raw_card) != TYPE_DICTIONARY:
			continue
		var area_card := raw_card as Dictionary
		if not bool(area_card.get("is_fishing_area", false)):
			continue
		if str(area_card.get("area_key", "")) != area_key:
			continue
		var selected_id: String = str(area_card.get("selected_action_id", ""))
		if not selected_id.is_empty():
			return selected_id
	for raw_method_id in host._fishing_ui_surface().area_module_method_ids("fishing", area_def):
		var action_id: String = str(raw_method_id)
		var action: Dictionary = host._action_data("fishing", action_id)
		if not action.is_empty() and host._activity_unlock_runtime()._is_action_unlocked("fishing", action):
			return action_id
	return ""


func _activity_queue_key_for_running_action(skill_id: String, action_id: String) -> String:
	var action_key: String = ModuleUiRuntime.action(skill_id, action_id, host.FISHING_ACTION_ID_ALIASES)
	if activity_queue_attempt_key == action_key:
		return action_key
	if skill_id == "fishing":
		for raw_key in get_activity_queue():
			var module_key: String = ModuleUiRuntime.normalize(raw_key)
			if not module_key.begins_with("fishing_area:"):
				continue
			var target: Dictionary = _activity_queue_target_for_key(module_key)
			if str(target.get("skill_id", "")) == skill_id and str(target.get("action_id", "")) == action_id:
				return module_key
	return action_key if is_activity_queued(action_key) else ""
