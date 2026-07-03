extends RefCounted

var host
var manual_activity_unlocks := {}
var manual_activity_requirement_unlocks := {}
var manual_activity_unlocks_trust_checked := false
var manual_activity_unlocks_trusted := true


func _init(host_ref) -> void:
	host = host_ref


func _is_action_unlocked(skill_id: String, action: Dictionary) -> bool:
	if host._is_event_action(action):
		var event_action_id := str(action.get("id", ""))
		return not event_action_id.is_empty() and host._temporary_event_runtime()._temporary_event_is_active(event_action_id)
	if not host._fighting_runtime().action_boss_requirements_met(action):
		return false
	var requirements := _action_unlock_requirements(skill_id, action)
	if _action_requirements_max_level(requirements) <= 1:
		return _action_requirements_met_from_requirements(requirements)
	var action_id := str(action.get("id", ""))
	if action_id.is_empty():
		return false
	if host._is_passive_action(action):
		return _manual_activity_unlock_flag_is_trusted(skill_id, action_id) and _can_unlock_action(skill_id, action)
	return _manual_activity_unlock_flag_is_trusted(skill_id, action_id) and _can_unlock_action(skill_id, action)


func _manual_activity_unlock_flag_is_trusted(skill_id: String, action_id: String) -> bool:
	if not bool(manual_activity_unlocks.get(host._action_key(skill_id, action_id), false)):
		return false
	return _manual_activity_unlocks_are_trusted()


func _manual_activity_unlocks_are_trusted() -> bool:
	if manual_activity_unlocks_trust_checked:
		return manual_activity_unlocks_trusted
	manual_activity_unlocks_trust_checked = true
	manual_activity_unlocks_trusted = not _manual_activity_unlocks_have_bulk_corruption()
	return manual_activity_unlocks_trusted


func _invalidate_manual_activity_unlock_trust() -> void:
	manual_activity_unlocks_trust_checked = false
	manual_activity_unlocks_trusted = true


func _manual_activity_unlocks_have_bulk_corruption() -> bool:
	var manual_count := 0
	var impossible_count := 0
	for raw_key in manual_activity_unlocks.keys():
		if not bool(manual_activity_unlocks.get(raw_key, false)):
			continue
		manual_count += 1
		var action_ref: Dictionary = host._save_runtime()._action_ref_from_key(_canonical_manual_activity_unlock_key(str(raw_key)))
		if action_ref.is_empty():
			continue
		var skill_id := str(action_ref.get("skill_id", ""))
		var action := action_ref.get("action", {}) as Dictionary
		if not _action_requirements_met(skill_id, action):
			impossible_count += 1
	if manual_count < 50:
		return false
	return impossible_count >= maxi(12, int(float(manual_count) * 0.45))


func _repair_runtime_manual_activity_unlock_trust() -> void:
	if _manual_activity_unlocks_are_trusted():
		return
	var repaired := {}
	for raw_key in manual_activity_unlocks.keys():
		if not bool(manual_activity_unlocks.get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_unlock_key(str(raw_key))
		if key.is_empty():
			continue
		var action_ref: Dictionary = host._save_runtime()._action_ref_from_key(key)
		if action_ref.is_empty():
			continue
		var skill_id := str(action_ref.get("skill_id", ""))
		var action := action_ref.get("action", {}) as Dictionary
		if _action_requirements_met(skill_id, action):
			repaired[key] = true
	manual_activity_unlocks = repaired
	manual_activity_unlocks_trust_checked = true
	manual_activity_unlocks_trusted = true


func _action_unlock_requirements(owner_skill_id: String, action: Dictionary) -> Array:
	var normalized := []
	var raw_requirements = action.get("requirements", [])
	if typeof(raw_requirements) == TYPE_ARRAY:
		for raw_requirement in raw_requirements:
			if typeof(raw_requirement) != TYPE_DICTIONARY:
				continue
			var requirement := raw_requirement as Dictionary
			var requirement_skill := str(requirement.get("skill", requirement.get("skill_id", owner_skill_id))).strip_edges()
			if requirement_skill.is_empty():
				requirement_skill = owner_skill_id
			normalized.append({
				"skill": requirement_skill,
				"level": maxi(1, int(requirement.get("level", requirement.get("unlock", action.get("unlock", 1)))))
			})
	if normalized.is_empty():
		normalized.append({
			"skill": owner_skill_id,
			"level": maxi(1, int(action.get("unlock", 1)))
		})
	return normalized


func _requirement_met(requirement: Dictionary) -> bool:
	var skill_id := str(requirement.get("skill", ""))
	if skill_id.is_empty():
		return false
	return host._skill_level(skill_id) >= int(requirement.get("level", 1))


func _action_requirement_states(owner_skill_id: String, action: Dictionary) -> Array:
	var states := []
	for raw_requirement in _action_unlock_requirements(owner_skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		var requirement_skill := str(requirement.get("skill", ""))
		var required_level := maxi(1, int(requirement.get("level", 1)))
		var current_level = host._skill_level(requirement_skill) if not requirement_skill.is_empty() else 0
		var requirement_index := states.size()
		states.append({
			"skill": requirement_skill,
			"level": required_level,
			"current_level": current_level,
			"met": current_level >= required_level,
			"dismissed": _action_requirement_manually_unlocked(owner_skill_id, action, requirement_index)
		})
	return states


func _action_requirements_met(owner_skill_id: String, action: Dictionary) -> bool:
	return _action_requirements_met_from_requirements(_action_unlock_requirements(owner_skill_id, action))


func _action_requirements_met_from_requirements(requirements: Array) -> bool:
	if requirements.is_empty():
		return true
	for raw_requirement in requirements:
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			return false
		if not _requirement_met(raw_requirement as Dictionary):
			return false
	return true


func _action_requirements_max_level(requirements: Array) -> int:
	var max_level := 1
	for raw_requirement in requirements:
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		max_level = maxi(max_level, int((raw_requirement as Dictionary).get("level", 1)))
	return max_level


func _action_lock_cluster_state(owner_skill_id: String, action: Dictionary) -> Dictionary:
	var states := _action_requirement_states(owner_skill_id, action)
	var ready_count := 0
	var unmet := []
	for raw_state in states:
		if typeof(raw_state) != TYPE_DICTIONARY:
			continue
		var state := raw_state as Dictionary
		if bool(state.get("met", false)):
			ready_count += 1
		else:
			unmet.append(state)
	return {
		"requirements": states,
		"unmet": unmet,
		"ready_count": ready_count,
		"total": states.size(),
		"all_met": unmet.is_empty(),
		"max_level": _action_requirements_max_level(states)
	}


func _can_unlock_action(skill_id: String, action: Dictionary) -> bool:
	return _action_requirements_met(skill_id, action) and host._fighting_runtime().action_boss_requirements_met(action)


func _mark_action_manually_unlocked(skill_id: String, action_id: String) -> void:
	var key := _canonical_manual_activity_unlock_key(host._action_key(skill_id, action_id))
	if not key.is_empty():
		_repair_runtime_manual_activity_unlock_trust()
		manual_activity_unlocks[key] = true
		_clear_activity_requirement_manual_unlocks(skill_id, action_id)
		manual_activity_unlocks_trust_checked = true
		manual_activity_unlocks_trusted = true


func _queue_manual_activity_unlock_for_ceremony(card: Dictionary, skill_id: String, action_id: String) -> void:
	if card.is_empty() or skill_id.is_empty() or action_id.is_empty():
		return
	card["manual_unlock_pending_skill_id"] = skill_id
	card["manual_unlock_pending_action_id"] = action_id


func _finalize_manual_activity_unlock(skill_id: String, action_id: String, save_reason := "activity unlock") -> bool:
	if skill_id.is_empty() or action_id.is_empty():
		return false
	_mark_action_manually_unlocked(skill_id, action_id)
	if host.current_screen == "skill" and host._fishing_rework_active_for_skill(skill_id) and host.selected_skill_id == skill_id:
		host._queue_fishing_unlock_visible_mount(action_id)
		host._ensure_detail_lazy_entry_mounted(action_id)
		var next_fishing_preview_id: String = host._fishing_preview_after_manual_unlock(action_id)
		if not next_fishing_preview_id.is_empty():
			host._ensure_detail_lazy_entry_mounted(next_fishing_preview_id)
	host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
	host._mark_save_dirty(save_reason)
	return true


func _finalize_manual_activity_unlock_for_card(card: Dictionary, save_reason := "activity unlock") -> bool:
	if card.is_empty():
		return false
	var skill_id := str(card.get("manual_unlock_pending_skill_id", ""))
	var action_id := str(card.get("manual_unlock_pending_action_id", ""))
	card.erase("manual_unlock_pending_skill_id")
	card.erase("manual_unlock_pending_action_id")
	return _finalize_manual_activity_unlock(skill_id, action_id, save_reason)


func _clear_activity_requirement_manual_unlocks(skill_id: String, action_id: String) -> void:
	if skill_id.is_empty() or action_id.is_empty() or manual_activity_requirement_unlocks.is_empty():
		return
	var prefix := "%s:%s:" % [skill_id, action_id]
	for raw_key in manual_activity_requirement_unlocks.keys():
		var key := str(raw_key)
		if key.begins_with(prefix):
			manual_activity_requirement_unlocks.erase(raw_key)


func _restore_manual_activity_unlocks(loaded_manual_unlocks: Variant) -> void:
	manual_activity_unlocks.clear()
	_invalidate_manual_activity_unlock_trust()
	if typeof(loaded_manual_unlocks) != TYPE_DICTIONARY:
		return
	for raw_key in (loaded_manual_unlocks as Dictionary).keys():
		if not bool((loaded_manual_unlocks as Dictionary).get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_unlock_key(str(raw_key))
		if not key.is_empty():
			manual_activity_unlocks[key] = true
	_invalidate_manual_activity_unlock_trust()


func _manual_activity_unlocks_for_save() -> Dictionary:
	if not _manual_activity_unlocks_are_trusted():
		return {}
	var normalized := {}
	for raw_key in manual_activity_unlocks.keys():
		if not bool(manual_activity_unlocks.get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_unlock_key(str(raw_key))
		if not key.is_empty():
			normalized[key] = true
	return normalized


func _manual_activity_requirement_unlocks_for_save() -> Dictionary:
	var normalized := {}
	for raw_key in manual_activity_requirement_unlocks.keys():
		if not bool(manual_activity_requirement_unlocks.get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_requirement_unlock_key(str(raw_key))
		if not key.is_empty():
			normalized[key] = true
	return normalized


func _restore_manual_activity_requirement_unlocks(loaded_requirement_unlocks: Variant) -> void:
	manual_activity_requirement_unlocks.clear()
	if typeof(loaded_requirement_unlocks) != TYPE_DICTIONARY:
		return
	for raw_key in (loaded_requirement_unlocks as Dictionary).keys():
		if not bool((loaded_requirement_unlocks as Dictionary).get(raw_key, false)):
			continue
		var key := _canonical_manual_activity_requirement_unlock_key(str(raw_key))
		if not key.is_empty():
			manual_activity_requirement_unlocks[key] = true


func _mark_activity_requirement_manually_unlocked(skill_id: String, action: Dictionary, requirement_index: int) -> bool:
	var key := _action_requirement_unlock_key(skill_id, action, requirement_index)
	if key.is_empty():
		return false
	manual_activity_requirement_unlocks[key] = true
	return true


func _action_requirement_manually_unlocked(skill_id: String, action: Dictionary, requirement_index: int) -> bool:
	var key := _action_requirement_unlock_key(skill_id, action, requirement_index)
	return not key.is_empty() and bool(manual_activity_requirement_unlocks.get(key, false))


func _action_requirement_unlock_key(skill_id: String, action: Dictionary, requirement_index: int) -> String:
	if skill_id.is_empty() or action.is_empty() or requirement_index < 0:
		return ""
	var action_id := str(action.get("id", ""))
	if action_id.is_empty():
		return ""
	var requirements := _action_unlock_requirements(skill_id, action)
	if requirement_index >= requirements.size():
		return ""
	var requirement := requirements[requirement_index] as Dictionary
	var requirement_skill := str(requirement.get("skill", skill_id))
	var requirement_level := maxi(1, int(requirement.get("level", action.get("unlock", 1))))
	if requirement_skill.is_empty():
		return ""
	return "%s:%s:%s:%s" % [skill_id, action_id, requirement_skill, requirement_level]


func _canonical_manual_activity_requirement_unlock_key(key: String) -> String:
	var parts := key.split(":", false, 4)
	if parts.size() < 4:
		return ""
	var skill_id := str(parts[0])
	var action_id := str(parts[1])
	var requirement_skill := str(parts[2])
	var requirement_level := maxi(1, int(parts[3]))
	if skill_id.is_empty() or action_id.is_empty() or requirement_skill.is_empty():
		return ""
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return ""
	for index in range(_action_unlock_requirements(skill_id, action).size()):
		var requirement := (_action_unlock_requirements(skill_id, action)[index]) as Dictionary
		if str(requirement.get("skill", skill_id)) == requirement_skill and int(requirement.get("level", 1)) == requirement_level:
			return _action_requirement_unlock_key(skill_id, action, index)
	return ""


func _canonical_manual_activity_unlock_key(key: String) -> String:
	var separator := key.find(":")
	if separator < 0:
		return ""
	var skill_id := key.substr(0, separator)
	var action_id := key.substr(separator + 1)
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	var action = host._action_data(skill_id, action_id)
	if action.is_empty():
		return ""
	return host._action_key(skill_id, str(action.get("id", action_id)))
