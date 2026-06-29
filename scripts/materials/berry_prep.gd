class_name BerryPrep


static func target_key(skill_id: String, action_id: String, action_lookup: Callable, action_key: Callable) -> String:
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	var action = action_lookup.call(skill_id, action_id)
	if typeof(action) != TYPE_DICTIONARY or (action as Dictionary).is_empty():
		return ""
	return str(action_key.call(skill_id, str((action as Dictionary).get("id", action_id))))


static func save_state(state: Dictionary, action_lookup: Callable) -> Dictionary:
	var key := str(state.get("target_key", ""))
	if key.is_empty() or not action_exists_for_key(key, action_lookup):
		return {}
	return {"target_key": key}


static func restored_state(value: Variant, action_lookup: Callable, action_key: Callable) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var key := str((value as Dictionary).get("target_key", ""))
	var parts := key.split(":", false, 1)
	if parts.size() != 2:
		return {}
	var normalized_key := target_key(str(parts[0]), str(parts[1]), action_lookup, action_key)
	if normalized_key.is_empty():
		return {}
	return {"target_key": normalized_key}


static func matches(state: Dictionary, skill_id: String, action_id: String, action_lookup: Callable, action_key: Callable) -> bool:
	var key := target_key(skill_id, action_id, action_lookup, action_key)
	return not key.is_empty() and str(state.get("target_key", "")) == key


static func consume_bonus(state: Dictionary, skill_id: String, action_id: String, reward_map: Dictionary, xp_multiplier: float, action_lookup: Callable, action_key: Callable) -> Dictionary:
	if not matches(state, skill_id, action_id, action_lookup, action_key):
		return {}
	var base_total := reward_map_total(reward_map)
	var bonus_xp := maxi(1, int(ceil(float(base_total) * xp_multiplier)))
	reward_map[skill_id] = maxi(0, int(reward_map.get(skill_id, 0))) + bonus_xp
	state.clear()
	return {
		"bonus_xp": bonus_xp,
		"mat_id": "berries"
	}


static func result_text(result: Dictionary) -> String:
	var bonus_xp := maxi(0, int(result.get("bonus_xp", 0)))
	if bonus_xp <= 0:
		return ""
	return "Berry Prep used 1 Berries for +%s XP." % bonus_xp


static func action_exists_for_key(key: String, action_lookup: Callable) -> bool:
	var parts := key.split(":", false, 1)
	if parts.size() != 2:
		return false
	var action = action_lookup.call(str(parts[0]), str(parts[1]))
	return typeof(action) == TYPE_DICTIONARY and not (action as Dictionary).is_empty()


static func reward_map_total(reward_map: Dictionary) -> int:
	var total := 0
	for raw_value in reward_map.values():
		total += maxi(0, int(raw_value))
	return total
