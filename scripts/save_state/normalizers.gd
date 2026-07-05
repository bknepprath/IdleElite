static func restored_tip_metadata(data: Dictionary, valid_detail_tips: Array, action_key_for_save: Callable) -> Dictionary:
	return {
		"lock_click_tip_seen": bool(data.get("lock_click_tip_seen", false)),
		"passive_module_tip_seen": bool(data.get("passive_module_tip_seen", false)),
		"silver_opportunity_tip_seen": bool(data.get("silver_opportunity_tip_seen", false)),
		"silver_opportunity_tip_action_key": str(action_key_for_save.call(str(data.get("silver_opportunity_tip_action_key", "")))),
		"detail_pull_recent_tip_texts": normalized_recent_tip_texts(data.get("detail_pull_recent_tip_texts", []), valid_detail_tips)
	}


static func normalized_recent_tip_texts(value: Variant, valid_detail_tips: Array) -> Array:
	var normalized: Array = []
	if typeof(value) != TYPE_ARRAY:
		return normalized
	var valid_tips := {}
	for raw_tip in valid_detail_tips:
		valid_tips[str(raw_tip)] = true
	for raw_tip in value:
		var tip := str(raw_tip).strip_edges()
		if tip.is_empty() or not valid_tips.has(tip):
			continue
		normalized.erase(tip)
		normalized.append(tip)
		while normalized.size() > 3:
			normalized.pop_front()
	return normalized


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


static func payload_regresses_progress(existing_payload: Dictionary, next_payload: Dictionary, skill_defs: Array) -> bool:
	if existing_payload.is_empty():
		return false
	var existing_reset_generation := save_reset_generation(existing_payload)
	var next_reset_generation := save_reset_generation(next_payload)
	if next_reset_generation > existing_reset_generation:
		return false
	if next_reset_generation < existing_reset_generation:
		return true
	var existing_progress := progress_evidence_score(existing_payload, skill_defs)
	if existing_progress <= 0:
		return false
	return progress_evidence_score(next_payload, skill_defs) < existing_progress


static func save_reset_generation(data: Dictionary) -> int:
	return maxi(0, int(data.get("save_reset_generation", 0)))


static func total_skill_xp_evidence(data: Dictionary, skill_defs: Array) -> int:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return 0
	var total_xp := 0
	var source := loaded_skills as Dictionary
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if skill_id.is_empty() or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state := skill_state as Dictionary
		total_xp += maxi(0, int(state.get("xp", 0)))
	return total_xp


static func progress_evidence_score(data: Dictionary, skill_defs: Array) -> int:
	return total_skill_xp_evidence(data, skill_defs) * 100000 + non_xp_progress_evidence(data)


static func non_xp_progress_evidence(data: Dictionary) -> int:
	var evidence := 0
	evidence += _positive_number_evidence(data, [
		"log_currency",
		"fish_currency",
		"activity_start_count",
		"activity_completion_count",
		"onboarding_starter_action_completion_count"
	])
	evidence += _dictionary_true_evidence(data.get("manual_activity_unlocks", {}))
	evidence += _dictionary_true_evidence(data.get("manual_activity_requirement_unlocks", {}))
	evidence += _dictionary_true_evidence(data.get("built_modules", {}))
	evidence += _dictionary_true_evidence(data.get("completed_bosses", {}))
	evidence += _mastery_evidence(data.get("mastery", {}))
	evidence += _hub_module_evidence(data.get("hub_modules", {}))
	evidence += _thieving_trophy_evidence(data.get("thieving_trophies", {}))
	if bool(data.get("onboarding_tutorial_complete", false)):
		evidence += 1
	return evidence


static func _positive_number_evidence(data: Dictionary, keys: Array) -> int:
	var evidence := 0
	for key in keys:
		if float(data.get(str(key), 0.0)) > 0.0:
			evidence += 1
	return evidence


static func _dictionary_true_evidence(value: Variant) -> int:
	if typeof(value) != TYPE_DICTIONARY:
		return 0
	var evidence := 0
	for raw_key in (value as Dictionary).keys():
		if bool((value as Dictionary).get(raw_key, false)):
			evidence += 1
	return evidence


static func _mastery_evidence(value: Variant) -> int:
	if typeof(value) != TYPE_DICTIONARY:
		return 0
	var evidence := 0
	for raw_state in (value as Dictionary).values():
		if typeof(raw_state) == TYPE_DICTIONARY and float((raw_state as Dictionary).get("xp", 0.0)) > 0.0:
			evidence += 1
	return evidence


static func _hub_module_evidence(value: Variant) -> int:
	if typeof(value) != TYPE_DICTIONARY:
		return 0
	var evidence := 0
	for raw_state in (value as Dictionary).values():
		if typeof(raw_state) != TYPE_DICTIONARY:
			continue
		var state := raw_state as Dictionary
		if int(state.get("level", 0)) > 0 or bool(state.get("building", false)):
			evidence += 1
	return evidence


static func _thieving_trophy_evidence(value: Variant) -> int:
	if typeof(value) != TYPE_DICTIONARY:
		return 0
	var evidence := 0
	for raw_state in (value as Dictionary).values():
		if typeof(raw_state) == TYPE_DICTIONARY and bool((raw_state as Dictionary).get("stolen", false)):
			evidence += 1
		elif typeof(raw_state) == TYPE_BOOL and bool(raw_state):
			evidence += 1
	return evidence


static func has_known_skill_progress(data: Dictionary, skill_defs: Array) -> bool:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return false
	var source := loaded_skills as Dictionary
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if skill_id.is_empty() or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state := skill_state as Dictionary
		if int(state.get("level", 1)) > 1 or int(state.get("xp", 0)) > 0:
			return true
	return false


static func has_progress_beyond_onboarding(data: Dictionary, skill_defs: Array, tutorial_starter_skill_id: String) -> bool:
	if has_non_tutorial_skill_progress(data, skill_defs, tutorial_starter_skill_id):
		return true
	return manual_activity_unlock_count(data) >= 2


static func has_non_tutorial_skill_progress(data: Dictionary, skill_defs: Array, tutorial_starter_skill_id: String) -> bool:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return false
	var source := loaded_skills as Dictionary
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if skill_id.is_empty() or skill_id == tutorial_starter_skill_id or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state := skill_state as Dictionary
		if int(state.get("level", 1)) > 1 or int(state.get("xp", 0)) > 0:
			return true
	return false


static func manual_activity_unlock_count(data: Dictionary) -> int:
	var raw_manual = data.get("manual_activity_unlocks", {})
	if typeof(raw_manual) != TYPE_DICTIONARY:
		return 0
	var manual := raw_manual as Dictionary
	var count := 0
	for raw_key in manual.keys():
		if bool(manual.get(raw_key, false)):
			count += 1
	return count


static func mark_onboarding_complete(data: Dictionary) -> void:
	data["onboarding_tutorial_complete"] = true
	data["onboarding_explore_tip_seen"] = true
	data["skill_swipe_tip_seen"] = true
	data["stamina_gauge_tip_seen"] = true
	data["onboarding_swipe_tip_eligible"] = true
	data["onboarding_swipe_navigation_unlocked"] = true
	data["tutorial_active"] = false
	data["tutorial_step"] = 4
	data["tutorial_gate_latch_only_until_swipe"] = false
	data["onboarding_fight_summary_revealed"] = true
	data["onboarding_fight_auto_run_message_shown"] = true
	data["onboarding_fight_stamina_revealed"] = true
	data["onboarding_fight_action_stats_revealed"] = true
	data["onboarding_header_reveal_after_progress"] = false


static func valid_dictionary_key(raw_key: Variant, valid_defs: Dictionary, fallback: String) -> String:
	var key := str(raw_key)
	return key if valid_defs.has(key) else fallback


static func nonnegative_int(data: Dictionary, key: String, fallback: Variant = 0) -> int:
	return maxi(0, int(data.get(key, fallback)))


static func bool_value(data: Dictionary, key: String, fallback := false) -> bool:
	return bool(data.get(key, fallback))


static func clamped_float(data: Dictionary, key: String, minimum: float, maximum: float, fallback: Variant = 0.0) -> float:
	return clampf(float(data.get(key, fallback)), minimum, maximum)


static func clamped_int(data: Dictionary, key: String, minimum: int, maximum: int, fallback: Variant = 0) -> int:
	return clampi(int(data.get(key, fallback)), minimum, maximum)
