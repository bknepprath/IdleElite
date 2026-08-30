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
	if save_repair_generation(next_payload) < save_repair_generation(existing_payload):
		return true
	if payload_regresses_identity(existing_payload, next_payload):
		return true
	return payload_regresses_game_progress(existing_payload, next_payload, skill_defs)


static func payload_regresses_game_progress(existing_payload: Dictionary, next_payload: Dictionary, skill_defs: Array) -> bool:
	if _skill_xp_regresses(existing_payload, next_payload, skill_defs):
		return true
	for key in [
		"activity_start_count",
		"activity_completion_count",
		"onboarding_starter_action_completion_count",
		"guaranteed_success_action_completions",
	]:
		if int(next_payload.get(key, 0)) < int(existing_payload.get(key, 0)):
			return true
	for key in [
		"manual_activity_unlocks",
		"built_modules",
		"completed_bosses",
		"achievement_toast_seen_ids",
		"nav_symbol_seen_ids",
	]:
		if _true_dictionary_regresses(existing_payload.get(key, {}), next_payload.get(key, {})):
			return true
	if _activity_requirement_unlocks_regress(existing_payload, next_payload):
		return true
	for key in [
		"fishing_net_collect_completed",
		"fishing_rod_collected",
		"fishing_reinforced_rod_collected",
		"fishing_star_rod_collected",
		"fishing_boat_built",
		"fishing_mirror_collected",
		"onboarding_tutorial_complete",
	]:
		if bool(existing_payload.get(key, false)) and not bool(next_payload.get(key, false)):
			return true
	if _nested_number_regresses(existing_payload.get("mastery", {}), next_payload.get("mastery", {}), ["xp", "level"]):
		return true
	if _nested_number_regresses(existing_payload.get("hub_modules", {}), next_payload.get("hub_modules", {}), ["level"]):
		return true
	if _nested_number_regresses(existing_payload.get("convergence_modules", {}), next_payload.get("convergence_modules", {}), ["completions"]):
		return true
	if _thieving_trophies_regress(existing_payload.get("thieving_trophies", {}), next_payload.get("thieving_trophies", {})):
		return true
	# The aggregate evidence score is useful only for choosing between otherwise
	# equivalent recovery candidates. It includes consumable currencies and other
	# values that legitimately decrease during play, so it must never reject a save.
	return false


static func payload_with_canonical_action_keys(payload: Dictionary, action_id_aliases := {}) -> Dictionary:
	if payload.is_empty() or typeof(action_id_aliases) != TYPE_DICTIONARY or (action_id_aliases as Dictionary).is_empty():
		return payload
	var normalized := payload.duplicate(true)
	for field in ["manual_activity_unlocks", "built_modules"]:
		normalized[field] = _canonical_true_action_dictionary(payload.get(field, {}), action_id_aliases)
	normalized["manual_activity_requirement_unlocks"] = _canonical_requirement_unlock_dictionary(
		payload.get("manual_activity_requirement_unlocks", {}),
		action_id_aliases
	)
	normalized["mastery"] = _canonical_mastery_dictionary(payload.get("mastery", {}), action_id_aliases)
	return normalized


static func _canonical_true_action_dictionary(value: Variant, action_id_aliases: Dictionary) -> Dictionary:
	var normalized := {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized
	for raw_key in (value as Dictionary).keys():
		if not bool((value as Dictionary).get(raw_key, false)):
			continue
		var key := _canonical_qualified_action_key(str(raw_key), action_id_aliases)
		if not key.is_empty():
			normalized[key] = true
	return normalized


static func _canonical_requirement_unlock_dictionary(value: Variant, action_id_aliases: Dictionary) -> Dictionary:
	var normalized := {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized
	for raw_key in (value as Dictionary).keys():
		if not bool((value as Dictionary).get(raw_key, false)):
			continue
		var parts := str(raw_key).split(":", false, 4)
		if parts.size() < 4:
			continue
		var action_key := _canonical_qualified_action_key("%s:%s" % [parts[0], parts[1]], action_id_aliases)
		if action_key.is_empty():
			continue
		normalized["%s:%s:%s" % [action_key, parts[2], parts[3]]] = true
	return normalized


static func _canonical_mastery_dictionary(value: Variant, action_id_aliases: Dictionary) -> Dictionary:
	var normalized := {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized
	for raw_key in (value as Dictionary).keys():
		var key := _canonical_qualified_action_key(str(raw_key), action_id_aliases)
		var raw_state = (value as Dictionary).get(raw_key, {})
		if key.is_empty() or typeof(raw_state) != TYPE_DICTIONARY:
			continue
		var state := (raw_state as Dictionary).duplicate(true)
		var existing = normalized.get(key, null)
		if typeof(existing) == TYPE_DICTIONARY:
			state["xp"] = maxf(float(state.get("xp", 0.0)), float((existing as Dictionary).get("xp", 0.0)))
			state["level"] = maxi(int(state.get("level", 0)), int((existing as Dictionary).get("level", 0)))
		normalized[key] = state
	return normalized


static func _canonical_qualified_action_key(key: String, action_id_aliases: Dictionary) -> String:
	var separator := key.find(":")
	if separator <= 0 or separator >= key.length() - 1:
		return ""
	var skill_id := key.substr(0, separator)
	var action_id := key.substr(separator + 1)
	var qualified_id := "%s:%s" % [skill_id, action_id]
	if action_id_aliases.has(qualified_id):
		action_id = str(action_id_aliases.get(qualified_id, action_id))
	elif action_id_aliases.has(action_id):
		action_id = str(action_id_aliases.get(action_id, action_id))
	if action_id.is_empty():
		return ""
	return "%s:%s" % [skill_id, action_id]


static func payload_regresses_skill_xp(existing_payload: Dictionary, next_payload: Dictionary, skill_defs: Array) -> bool:
	return _skill_xp_regresses(existing_payload, next_payload, skill_defs)


static func payload_regresses_outside_vetted_progress_repair(
	existing_payload: Dictionary,
	next_payload: Dictionary,
	repair_source_payload: Dictionary,
	repaired_payload: Dictionary,
	skill_defs: Array
) -> bool:
	if repair_source_payload.is_empty() or repaired_payload.is_empty() or existing_payload != repair_source_payload:
		return true
	var vetted_baseline := existing_payload.duplicate(true)
	var repair_changed_progress := false
	for key in ["skills", "manual_activity_unlocks", "manual_activity_requirement_unlocks", "thieving_trophies"]:
		var source_has_key := repair_source_payload.has(key)
		var repaired_has_key := repaired_payload.has(key)
		var source_value = repair_source_payload.get(key, null)
		var repaired_value = repaired_payload.get(key, null)
		if source_has_key == repaired_has_key and source_value == repaired_value:
			continue
		repair_changed_progress = true
		if repaired_has_key:
			vetted_baseline[key] = repaired_value
		else:
			vetted_baseline.erase(key)
	if not repair_changed_progress:
		return true
	return payload_regresses_game_progress(vetted_baseline, next_payload, skill_defs)


static func _activity_requirement_unlocks_regress(existing_payload: Dictionary, next_payload: Dictionary) -> bool:
	var existing_value = existing_payload.get("manual_activity_requirement_unlocks", {})
	if typeof(existing_value) != TYPE_DICTIONARY:
		return false
	var next_requirements = next_payload.get("manual_activity_requirement_unlocks", {})
	if typeof(next_requirements) != TYPE_DICTIONARY:
		next_requirements = {}
	var next_full_unlocks = next_payload.get("manual_activity_unlocks", {})
	if typeof(next_full_unlocks) != TYPE_DICTIONARY:
		next_full_unlocks = {}
	for raw_key in (existing_value as Dictionary).keys():
		if not bool((existing_value as Dictionary).get(raw_key, false)):
			continue
		var requirement_key := str(raw_key)
		if bool((next_requirements as Dictionary).get(requirement_key, false)):
			continue
		var parts := requirement_key.split(":", false, 4)
		if parts.size() >= 2:
			var full_unlock_key := "%s:%s" % [parts[0], parts[1]]
			if bool((next_full_unlocks as Dictionary).get(full_unlock_key, false)):
				continue
		return true
	return false


static func _skill_xp_regresses(existing_payload: Dictionary, next_payload: Dictionary, skill_defs: Array) -> bool:
	var existing_skills = existing_payload.get("skills", {})
	var next_skills = next_payload.get("skills", {})
	if typeof(existing_skills) != TYPE_DICTIONARY or typeof(next_skills) != TYPE_DICTIONARY:
		return typeof(existing_skills) == TYPE_DICTIONARY and typeof(next_skills) != TYPE_DICTIONARY
	for raw_def in skill_defs:
		var skill_id := str((raw_def as Dictionary).get("id", ""))
		var existing_state = (existing_skills as Dictionary).get(skill_id, {})
		if typeof(existing_state) != TYPE_DICTIONARY:
			continue
		var next_state = (next_skills as Dictionary).get(skill_id, {})
		if typeof(next_state) != TYPE_DICTIONARY:
			return true
		if int((next_state as Dictionary).get("xp", 0)) < int((existing_state as Dictionary).get("xp", 0)):
			return true
	return false


static func _true_dictionary_regresses(existing_value: Variant, next_value: Variant) -> bool:
	if typeof(existing_value) != TYPE_DICTIONARY:
		return false
	if typeof(next_value) != TYPE_DICTIONARY:
		return not (existing_value as Dictionary).is_empty()
	for raw_key in (existing_value as Dictionary).keys():
		if bool((existing_value as Dictionary).get(raw_key, false)) and not bool((next_value as Dictionary).get(raw_key, false)):
			return true
	return false


static func _nested_number_regresses(existing_value: Variant, next_value: Variant, fields: Array) -> bool:
	if typeof(existing_value) != TYPE_DICTIONARY:
		return false
	if typeof(next_value) != TYPE_DICTIONARY:
		return not (existing_value as Dictionary).is_empty()
	for raw_key in (existing_value as Dictionary).keys():
		var existing_state = (existing_value as Dictionary).get(raw_key, {})
		if typeof(existing_state) != TYPE_DICTIONARY:
			continue
		var next_state = (next_value as Dictionary).get(raw_key, {})
		if typeof(next_state) != TYPE_DICTIONARY:
			return true
		for raw_field in fields:
			var field := str(raw_field)
			if float((next_state as Dictionary).get(field, 0.0)) < float((existing_state as Dictionary).get(field, 0.0)):
				return true
	return false


static func _thieving_trophies_regress(existing_value: Variant, next_value: Variant) -> bool:
	if typeof(existing_value) != TYPE_DICTIONARY:
		return false
	if typeof(next_value) != TYPE_DICTIONARY:
		return not (existing_value as Dictionary).is_empty()
	for raw_key in (existing_value as Dictionary).keys():
		var existing_state = (existing_value as Dictionary).get(raw_key, false)
		var was_stolen := false
		if typeof(existing_state) == TYPE_DICTIONARY:
			was_stolen = bool((existing_state as Dictionary).get("stolen", false))
		else:
			was_stolen = bool(existing_state)
		if not was_stolen:
			continue
		var next_state = (next_value as Dictionary).get(raw_key, false)
		var is_stolen := false
		if typeof(next_state) == TYPE_DICTIONARY:
			is_stolen = bool((next_state as Dictionary).get("stolen", false))
		else:
			is_stolen = bool(next_state)
		if not is_stolen:
			return true
	return false


static func payload_regresses_identity(existing_payload: Dictionary, next_payload: Dictionary) -> bool:
	if existing_payload.is_empty():
		return false
	var existing_claimed := bool(existing_payload.get("leaderboard_profile_claimed", false))
	var existing_verified := bool(existing_payload.get("leaderboard_name_claim_verified", false))
	var next_claimed := bool(next_payload.get("leaderboard_profile_claimed", false))
	var next_verified := bool(next_payload.get("leaderboard_name_claim_verified", false))
	if existing_claimed and not next_claimed:
		return true
	if existing_verified and not next_verified:
		return true
	if existing_claimed or existing_verified:
		for required_key in ["leaderboard_display_name", "leaderboard_name_key"]:
			var existing_value := str(existing_payload.get(required_key, "")).strip_edges()
			var next_value := str(next_payload.get(required_key, "")).strip_edges()
			if existing_value.is_empty() or next_value != existing_value:
				return true

	var existing_bound_uid := str(existing_payload.get("leaderboard_auth_bound_uid", "")).strip_edges()
	var next_bound_uid := str(next_payload.get("leaderboard_auth_bound_uid", "")).strip_edges()
	if not existing_bound_uid.is_empty() and next_bound_uid != existing_bound_uid:
		return true

	var existing_provider := str(existing_payload.get("leaderboard_auth_provider", "")).strip_edges()
	var next_provider := str(next_payload.get("leaderboard_auth_provider", "")).strip_edges()
	if not existing_provider.is_empty() and next_provider.is_empty():
		return true
	if existing_provider == "google" and next_provider != "google":
		return true
	var existing_refresh_token := str(existing_payload.get("leaderboard_auth_refresh_token", "")).strip_edges()
	var next_refresh_token := str(next_payload.get("leaderboard_auth_refresh_token", "")).strip_edges()
	if not existing_refresh_token.is_empty() and next_refresh_token.is_empty():
		return true

	var existing_player_id := str(existing_payload.get("leaderboard_player_id", "")).strip_edges()
	var next_player_id := str(next_payload.get("leaderboard_player_id", "")).strip_edges()
	var existing_has_bound_identity := (
		existing_claimed
		or not existing_bound_uid.is_empty()
		or not existing_refresh_token.is_empty()
		or existing_provider == "google"
		or (not existing_player_id.is_empty() and not _player_id_is_local_placeholder(existing_player_id))
	)
	if existing_has_bound_identity and not existing_player_id.is_empty() and next_player_id != existing_player_id:
		return true

	if existing_payload.has("leaderboard_auth_recovery_required") and not next_payload.has("leaderboard_auth_recovery_required"):
		return true
	var existing_recovery_required := bool(existing_payload.get("leaderboard_auth_recovery_required", false))
	var next_recovery_required := bool(next_payload.get("leaderboard_auth_recovery_required", false))
	if existing_recovery_required and not next_recovery_required:
		# Recovery may clear the flag only after the runtime is demonstrably bound
		# back to the preserved UID with a usable credential.
		if next_bound_uid.is_empty() or next_player_id != next_bound_uid or next_refresh_token.is_empty():
			return true
	var existing_name_transfer_required := bool(existing_payload.get("leaderboard_name_transfer_required", false))
	var next_name_transfer_required := bool(next_payload.get("leaderboard_name_transfer_required", false))
	if existing_name_transfer_required and not next_name_transfer_required:
		return true
	var existing_legacy_username_recovery_required := bool(existing_payload.get("leaderboard_legacy_username_recovery_required", false))
	var next_legacy_username_recovery_required := bool(next_payload.get("leaderboard_legacy_username_recovery_required", false))
	if existing_legacy_username_recovery_required and not next_legacy_username_recovery_required:
		return true
	var existing_deleted_auth_transition_pending := bool(existing_payload.get("leaderboard_deleted_auth_transition_pending", false))
	var next_deleted_auth_transition_pending := bool(next_payload.get("leaderboard_deleted_auth_transition_pending", false))
	if existing_deleted_auth_transition_pending and not next_deleted_auth_transition_pending:
		return true
	var existing_definitive_failure_code := str(existing_payload.get("leaderboard_auth_definitive_failure_code", "")).strip_edges()
	var next_definitive_failure_code := str(next_payload.get("leaderboard_auth_definitive_failure_code", "")).strip_edges()
	if existing_deleted_auth_transition_pending and (
		existing_definitive_failure_code.is_empty()
		or next_definitive_failure_code != existing_definitive_failure_code
	):
		return true
	var existing_legacy_old_uid := str(existing_payload.get("leaderboard_legacy_authless_old_uid", "")).strip_edges()
	var next_legacy_old_uid := str(next_payload.get("leaderboard_legacy_authless_old_uid", "")).strip_edges()
	if not existing_legacy_old_uid.is_empty() and next_legacy_old_uid != existing_legacy_old_uid:
		return true
	for hint_key in ["leaderboard_legacy_name_hint_display", "leaderboard_legacy_name_hint_key"]:
		var existing_hint := str(existing_payload.get(hint_key, "")).strip_edges()
		if not existing_hint.is_empty() and str(next_payload.get(hint_key, "")).strip_edges() != existing_hint:
			return true
	return false


static func payload_has_recoverable_identity_inconsistency(payload: Dictionary) -> bool:
	var claimed := bool(payload.get("leaderboard_profile_claimed", false))
	var verified := bool(payload.get("leaderboard_name_claim_verified", false))
	if claimed != verified:
		return true
	if not claimed:
		# Older clients could retain a real profile name/key while losing both trust
		# flags. Keep that metadata as an untrusted recovery hint instead of treating
		# it as a guest profile and erasing it on the next save.
		return not str(payload.get("leaderboard_name_key", "")).strip_edges().is_empty()
	for required_key in ["leaderboard_display_name", "leaderboard_name_key", "leaderboard_player_id"]:
		if str(payload.get(required_key, "")).strip_edges().is_empty():
			return true
	return false


static func vetted_identity_repair_is_safe(existing_payload: Dictionary, next_payload: Dictionary) -> bool:
	if not payload_has_recoverable_identity_inconsistency(existing_payload):
		return false
	if not bool(next_payload.get("leaderboard_auth_recovery_required", false)):
		return false
	for stable_key in [
		"leaderboard_player_id",
		"leaderboard_auth_bound_uid",
		"leaderboard_auth_refresh_token",
		"leaderboard_auth_provider",
		"leaderboard_display_name",
	]:
		var existing_value := str(existing_payload.get(stable_key, "")).strip_edges()
		if not existing_value.is_empty() and str(next_payload.get(stable_key, "")).strip_edges() != existing_value:
			return false
	var existing_name_key := str(existing_payload.get("leaderboard_name_key", "")).strip_edges()
	var next_name_key := str(next_payload.get("leaderboard_name_key", "")).strip_edges()
	if not existing_name_key.is_empty() and next_name_key != existing_name_key:
		var next_claimed := bool(next_payload.get("leaderboard_profile_claimed", false))
		var next_verified := bool(next_payload.get("leaderboard_name_claim_verified", false))
		if not next_name_key.is_empty() or next_claimed or next_verified:
			return false
	if bool(next_payload.get("leaderboard_profile_claimed", false)) and not bool(existing_payload.get("leaderboard_profile_claimed", false)):
		return false
	if bool(next_payload.get("leaderboard_name_claim_verified", false)) and not bool(existing_payload.get("leaderboard_name_claim_verified", false)):
		return false
	return true


static func claimed_name_boundary_changes(existing_payload: Dictionary, next_payload: Dictionary) -> bool:
	if not (
		bool(existing_payload.get("leaderboard_profile_claimed", false))
		or bool(existing_payload.get("leaderboard_name_claim_verified", false))
	):
		return false
	for key in ["leaderboard_display_name", "leaderboard_name_key"]:
		if str(existing_payload.get(key, "")).strip_edges() != str(next_payload.get(key, "")).strip_edges():
			return true
	return false


static func stable_account_uid(payload: Dictionary) -> String:
	var player_id := str(payload.get("leaderboard_player_id", "")).strip_edges()
	var bound_uid := str(payload.get("leaderboard_auth_bound_uid", "")).strip_edges()
	if not bound_uid.is_empty():
		if not player_id.is_empty() and player_id != bound_uid:
			return ""
		return bound_uid
	if player_id.is_empty() or _player_id_is_local_placeholder(player_id):
		return ""
	var provider := str(payload.get("leaderboard_auth_provider", "")).strip_edges()
	var has_account_evidence := (
		bool(payload.get("leaderboard_profile_claimed", false))
		or bool(payload.get("leaderboard_name_claim_verified", false))
		or provider == "google"
		or not str(payload.get("leaderboard_auth_refresh_token", "")).strip_edges().is_empty()
	)
	return player_id if has_account_evidence else ""


static func payloads_share_stable_account_boundary(first_payload: Dictionary, second_payload: Dictionary) -> bool:
	var first_uid := stable_account_uid(first_payload)
	return not first_uid.is_empty() and first_uid == stable_account_uid(second_payload)


static func _player_id_is_local_placeholder(player_id: String) -> bool:
	var clean := player_id.strip_edges()
	if clean.length() != 33 or not clean.begins_with("p"):
		return false
	for index in range(1, clean.length()):
		var code := clean.unicode_at(index)
		if not ((code >= 48 and code <= 57) or (code >= 97 and code <= 102)):
			return false
	return true


static func save_reset_generation(data: Dictionary) -> int:
	return maxi(0, int(data.get("save_reset_generation", 0)))


static func save_repair_generation(data: Dictionary) -> int:
	return maxi(0, int(data.get("save_repair_generation", 0)))


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
	evidence += _dictionary_true_evidence(data.get("manual_activity_unlocks", {})) * 100
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
