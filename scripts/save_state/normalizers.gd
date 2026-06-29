class_name SaveStateNormalizers


static func normalized_passive_modules(loaded_modules: Variant, is_firepit_module: Callable, now_unix: int, limits: Dictionary) -> Dictionary:
	var normalized := {}
	if typeof(loaded_modules) != TYPE_DICTIONARY:
		return normalized
	var source := loaded_modules as Dictionary
	for raw_module_id in source.keys():
		var module_id := str(raw_module_id)
		var loaded_module = source.get(raw_module_id, {})
		if module_id.is_empty() or typeof(loaded_module) != TYPE_DICTIONARY:
			continue
		normalized[module_id] = firepit_state(loaded_module as Dictionary, now_unix, limits) if bool(is_firepit_module.call(module_id)) else passive_module_state(loaded_module as Dictionary, now_unix, limits)
	return normalized


static func firepit_state(loaded_module: Dictionary, now_unix: int, limits: Dictionary) -> Dictionary:
	return {
		"active": bool(loaded_module.get("active", false)),
		"igniting": false,
		"last_update": int(loaded_module.get("last_update", now_unix)),
		"started_unix": maxi(0, int(loaded_module.get("started_unix", 0))),
		"burned_scrapwood": maxf(0.0, float(loaded_module.get("burned_scrapwood", 0.0))),
		"cooling_bonus": clampf(float(loaded_module.get("cooling_bonus", 0.0)), 0.0, float(limits.get("firepit_max_cooling_bonus", 0.0))),
		"cooling_started_unix": maxi(0, int(loaded_module.get("cooling_started_unix", 0))),
		"shutdown_reason": str(loaded_module.get("shutdown_reason", ""))
	}


static func passive_module_state(loaded_module: Dictionary, now_unix: int, limits: Dictionary) -> Dictionary:
	return {
		"stored": clampi(int(loaded_module.get("stored", 0)), 0, int(limits.get("passive_capacity_max", 0))),
		"time_seconds": clampi(int(loaded_module.get("time_seconds", int(limits.get("passive_time_start", 0)))), int(limits.get("passive_time_max", 0)), int(limits.get("passive_time_start", 0))),
		"yield": clampi(int(loaded_module.get("yield", int(limits.get("passive_yield_start", 0)))), int(limits.get("passive_yield_start", 0)), int(limits.get("passive_yield_max", 0))),
		"capacity": clampi(int(loaded_module.get("capacity", int(limits.get("passive_capacity_start", 0)))), int(limits.get("passive_capacity_start", 0)), int(limits.get("passive_capacity_max", 0))),
		"seeded": bool(loaded_module.get("seeded", false)),
		"last_update": int(loaded_module.get("last_update", now_unix))
	}


static func normalized_leaderboard_category_values(loaded_values: Variant, valid_category_id: Callable) -> Dictionary:
	var normalized := {}
	if typeof(loaded_values) != TYPE_DICTIONARY:
		return normalized
	var source := loaded_values as Dictionary
	for raw_category_id in source.keys():
		var category_id := str(valid_category_id.call(str(raw_category_id)))
		var amount := maxi(0, int(source.get(raw_category_id, 0)))
		var existing := int(normalized.get(category_id, 0))
		normalized[category_id] = maxi(existing, amount)
	return normalized


static func normalized_convergence_modules(loaded_modules: Variant, action_data: Callable, is_convergence_action: Callable) -> Dictionary:
	var normalized := {}
	if typeof(loaded_modules) != TYPE_DICTIONARY:
		return normalized
	var source := loaded_modules as Dictionary
	for raw_module_id in source.keys():
		var module_id := str(raw_module_id)
		var action := action_data.call("build", module_id) as Dictionary
		if action.is_empty() or not bool(is_convergence_action.call(action)):
			continue
		var loaded_state = source.get(raw_module_id, {})
		if typeof(loaded_state) != TYPE_DICTIONARY:
			continue
		normalized[module_id] = convergence_module_state(loaded_state as Dictionary)
	return normalized


static func convergence_module_state(loaded_state: Dictionary) -> Dictionary:
	return {
		"built": bool(loaded_state.get("built", false)),
		"building": bool(loaded_state.get("building", false)),
		"build_started_unix": maxi(0, int(loaded_state.get("build_started_unix", 0))),
		"completions": maxi(0, int(loaded_state.get("completions", 0)))
	}


static func normalized_hub_modules(loaded_modules: Variant, module_defs: Dictionary, max_level: int) -> Dictionary:
	var normalized := {}
	if typeof(loaded_modules) != TYPE_DICTIONARY:
		return normalized
	var source := loaded_modules as Dictionary
	for raw_module_id in source.keys():
		var module_id := str(raw_module_id)
		var loaded_state = source.get(raw_module_id, {})
		if not module_defs.has(module_id) or typeof(loaded_state) != TYPE_DICTIONARY:
			continue
		normalized[module_id] = hub_module_state(loaded_state as Dictionary, max_level)
	return normalized


static func hub_module_state(loaded_state: Dictionary, max_level: int) -> Dictionary:
	return {
		"level": clampi(int(loaded_state.get("level", 0)), 0, max_level),
		"building": bool(loaded_state.get("building", false)),
		"build_started_unix_msec": maxi(0, int(loaded_state.get("build_started_unix_msec", loaded_state.get("build_started_msec", 0))))
	}


static func normalized_hub_missions(loaded_missions: Variant, normalize_mission: Callable) -> Array:
	var normalized := []
	if typeof(loaded_missions) != TYPE_ARRAY:
		return normalized
	for raw_mission in (loaded_missions as Array):
		if typeof(raw_mission) != TYPE_DICTIONARY:
			continue
		var mission := normalize_mission.call(raw_mission as Dictionary) as Dictionary
		if not mission.is_empty():
			normalized.append(mission)
	return normalized
