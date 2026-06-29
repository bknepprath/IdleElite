class_name BossGates


static func is_boss_fight(action: Dictionary) -> bool:
	return str(action.get("kind", "")) == "boss_fight" and typeof(action.get("boss", {})) == TYPE_DICTIONARY and not (action.get("boss", {}) as Dictionary).is_empty()


static func boss_id(action: Dictionary) -> String:
	if not is_boss_fight(action):
		return ""
	return str((action.get("boss", {}) as Dictionary).get("id", "")).strip_edges()


static func boss_name(action: Dictionary) -> String:
	if not is_boss_fight(action):
		return ""
	return str((action.get("boss", {}) as Dictionary).get("name", str(action.get("name", "Boss")))).strip_edges()


static func is_completed(completed_bosses: Dictionary, action: Dictionary) -> bool:
	var id := boss_id(action)
	return not id.is_empty() and bool(completed_bosses.get(id, false))


static func completed_for_save(completed_bosses: Dictionary) -> Dictionary:
	var saved := {}
	for raw_id in completed_bosses.keys():
		var id := str(raw_id)
		if not id.is_empty() and bool(completed_bosses.get(raw_id, false)):
			saved[id] = true
	return saved


static func restored_from_save(value: Variant) -> Dictionary:
	var restored := {}
	if typeof(value) != TYPE_DICTIONARY:
		return restored
	for raw_id in (value as Dictionary).keys():
		var id := str(raw_id).strip_edges()
		if not id.is_empty() and bool((value as Dictionary).get(raw_id, false)):
			restored[id] = true
	return restored


static func requirements_met(completed_bosses: Dictionary, action: Dictionary) -> bool:
	return missing_requirements(completed_bosses, action).is_empty()


static func missing_requirements(completed_bosses: Dictionary, action: Dictionary) -> Array:
	var missing := []
	var raw_requirements = action.get("requires_bosses", [])
	if typeof(raw_requirements) != TYPE_ARRAY:
		return missing
	for raw_id in raw_requirements as Array:
		var id := str(raw_id).strip_edges()
		if not id.is_empty() and not bool(completed_bosses.get(id, false)):
			missing.append(id)
	return missing
