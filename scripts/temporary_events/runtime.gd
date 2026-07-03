extends RefCounted

const ActivityDataNormalizers = preload("res://scripts/activity_data/normalizers.gd")
const TemporaryEventState = preload("res://scripts/temporary_events/state.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")

const TEMPORARY_EVENT_SCHEDULER_CHECK_SECONDS := 5.0
const TEMPORARY_EVENT_INITIAL_ROLL_DELAY_SECONDS := 120
const TEMPORARY_EVENT_ROLL_INTERVAL_SECONDS := 900
const TEMPORARY_EVENT_MAX_ACTIVE := 1
const TEMPORARY_EVENT_MIN_LEVEL_OFFSET := 1
const TEMPORARY_EVENT_MAX_LEVEL_OFFSET := 10
const TEMPORARY_EVENT_XP_RATE_MULTIPLIER := 12.0
const TEMPORARY_EVENT_STAMINA_MULTIPLIER := 5.0
const TEMPORARY_EVENT_BASE_SECONDS := 8.0
const TEMPORARY_EVENT_SECONDS_PER_LEVEL := 0.08
const TEMPORARY_EVENT_REFERENCE_SECONDS_MULTIPLIER := 3.0
const TEMPORARY_EVENT_BASE_SUCCESS := 30.0
const TEMPORARY_EVENT_LOG_REWARD_MAT_TIERS := ["scrapwood", "softwood", "hardwood"]

var host
var event_module_defs: Array = []
var temporary_event_active := {}
var temporary_event_cooldowns := {}
var temporary_event_next_roll_unix := 0
var temporary_event_scheduler_elapsed := 0.0


func _init(host_ref) -> void:
	host = host_ref


func _load_event_module_definitions(data: Dictionary) -> void:
	event_module_defs.clear()
	var loaded_events = data.get("event_modules", [])
	if typeof(loaded_events) != TYPE_ARRAY:
		return
	var definition_order := 0
	for raw_event in loaded_events:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event_def := ActivityDataNormalizers.event_module_for_load(raw_event as Dictionary, definition_order)
		if event_def.is_empty():
			continue
		event_module_defs.append(event_def)
		definition_order += 1
	event_module_defs.sort_custom(Callable(self, "_event_module_sort_less"))


func _event_module_sort_less(left: Variant, right: Variant) -> bool:
	if typeof(left) != TYPE_DICTIONARY:
		return false
	if typeof(right) != TYPE_DICTIONARY:
		return true
	var left_event := left as Dictionary
	var right_event := right as Dictionary
	var left_page := str(left_event.get("page", ""))
	var right_page := str(right_event.get("page", ""))
	if left_page != right_page:
		return left_page < right_page
	var left_sort = host._activity_data_catalog().activity_action_display_sort_level(left_event)
	var right_sort = host._activity_data_catalog().activity_action_display_sort_level(right_event)
	if left_sort != right_sort:
		return left_sort < right_sort
	return int(left_event.get("definition_order", 0)) < int(right_event.get("definition_order", 0))


func _activate_all_temporary_events_for_art_review_test() -> void:
	temporary_event_active.clear()
	temporary_event_cooldowns.clear()
	var now = host._unix_now()
	for raw_event in event_module_defs:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event_def := raw_event as Dictionary
		var event_id := str(event_def.get("id", ""))
		var page := str(event_def.get("page", ""))
		if event_id.is_empty() or page.is_empty() or not host.actions_by_skill.has(page):
			continue
		if not _temporary_event_page_level_eligible(event_def):
			continue
		var entry := _temporary_event_spawn_entry(event_def, now, now + int(event_def.get("definition_order", 0)))
		entry["expires_unix"] = now + 30 * 24 * 60 * 60
		temporary_event_active[event_id] = entry
	temporary_event_next_roll_unix = now + 30 * 24 * 60 * 60


func _event_module_def(event_id: String) -> Dictionary:
	if event_id.is_empty():
		return {}
	for raw_event in event_module_defs:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event_def := raw_event as Dictionary
		if str(event_def.get("id", "")) == event_id:
			return event_def
	return {}


func _temporary_event_definition_level(event_def: Dictionary) -> int:
	var event_meta := event_def.get("event", {}) as Dictionary
	var fallback_level := int(event_def.get("target_level", event_def.get("sort_unlock", event_def.get("unlock", 1))))
	return clampi(int(event_meta.get("target_level", fallback_level)), 1, 99)


func _temporary_event_minimum_level(event_def: Dictionary) -> int:
	var event_meta := event_def.get("event", {}) as Dictionary
	return maxi(1, int(event_meta.get("minimum_level", event_def.get("minimum_level", event_def.get("unlock", 1)))))


func _temporary_event_page_level_eligible(event_def: Dictionary) -> bool:
	var page := str(event_def.get("page", ""))
	if page.is_empty() or not host.actions_by_skill.has(page):
		return false
	return _temporary_event_highest_unlocked_page_level(page) >= _temporary_event_minimum_level(event_def)


func _temporary_event_highest_unlocked_page_level(page: String) -> int:
	if page.is_empty() or not host.actions_by_skill.has(page):
		return 0
	var page_level = host._skill_level(page) if host.skills.has(page) else 0
	var highest := 0
	for raw_action in host.actions_by_skill.get(page, []):
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var action := raw_action as Dictionary
		if action.is_empty() or host._is_event_action(action):
			continue
		if not host._is_action_unlocked(page, action):
			continue
		var display_level = host._activity_data_catalog().activity_action_display_sort_level(action)
		if page_level > 0 and display_level > page_level:
			continue
		highest = maxi(highest, display_level)
	if highest <= 0:
		return page_level
	return highest


func _temporary_event_spawn_level_bounds_for_page(page: String) -> Dictionary:
	var highest_level := _temporary_event_highest_unlocked_page_level(page)
	if highest_level <= 1:
		return {"highest": highest_level, "min": 1, "max": 1}
	var min_level := maxi(1, highest_level - TEMPORARY_EVENT_MAX_LEVEL_OFFSET)
	var max_level := maxi(min_level, highest_level - TEMPORARY_EVENT_MIN_LEVEL_OFFSET)
	return {"highest": highest_level, "min": min_level, "max": max_level}


func _temporary_event_spawn_level_for_page(page: String, event_id: String, roll_unix: int) -> int:
	var bounds := _temporary_event_spawn_level_bounds_for_page(page)
	var highest_level := int(bounds.get("highest", 0))
	var min_level := int(bounds.get("min", 1))
	var max_level := int(bounds.get("max", 1))
	if min_level >= max_level:
		return min_level
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(hash("%s:%s:%s:%s:%s" % [
		str(roll_unix),
		page,
		event_id,
		str(highest_level),
		str(host._global_level())
	])))
	return rng.randi_range(min_level, max_level)


func _temporary_event_spawn_level_from_entry(event_entry: Dictionary, event_def: Dictionary) -> int:
	var fallback_level := _temporary_event_definition_level(event_def)
	var raw_level := clampi(int(event_entry.get("spawn_level", event_entry.get("level", event_entry.get("target_level", fallback_level)))), 1, 99)
	if bool(event_entry.get("completed", false)):
		return raw_level
	var bounds := _temporary_event_spawn_level_bounds_for_page(str(event_def.get("page", "")))
	return clampi(raw_level, 1, int(bounds.get("max", raw_level)))


func _temporary_event_reference_action_for_level(page: String, spawn_level: int) -> Dictionary:
	if page.is_empty() or not host.actions_by_skill.has(page):
		return {}
	var best_below := {}
	var best_below_level := -1
	var best_above := {}
	var best_above_level := 999999
	for raw_action in host.actions_by_skill.get(page, []):
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var action := raw_action as Dictionary
		if action.is_empty() or host._is_event_action(action) or host._is_passive_action(action) or host._convergence_runtime()._is_convergence_action(action):
			continue
		var action_level = host._activity_data_catalog().activity_action_display_sort_level(action)
		if action_level <= spawn_level and action_level > best_below_level:
			best_below = action
			best_below_level = action_level
		elif action_level > spawn_level and action_level < best_above_level:
			best_above = action
			best_above_level = action_level
	return best_below if not best_below.is_empty() else best_above


func _temporary_event_reward_template(event_def: Dictionary) -> Dictionary:
	var rewards := {}
	var raw_rewards = event_def.get("xp_rewards", {})
	if typeof(raw_rewards) == TYPE_DICTIONARY:
		for raw_skill_id in (raw_rewards as Dictionary).keys():
			var reward_skill_id := str(raw_skill_id).strip_edges()
			var amount := maxi(0, int((raw_rewards as Dictionary).get(raw_skill_id, 0)))
			if not reward_skill_id.is_empty() and amount > 0:
				rewards[reward_skill_id] = amount
	var page := str(event_def.get("page", "")).strip_edges()
	if rewards.is_empty() and not page.is_empty():
		rewards[page] = maxi(1, int(event_def.get("xp", 1)))
	return rewards


func _temporary_event_distribute_reward_total(event_def: Dictionary, target_total: int) -> Dictionary:
	var template := _temporary_event_reward_template(event_def)
	var page := str(event_def.get("page", "")).strip_edges()
	return host._distribute_xp_reward_map_to_total(template, page, target_total)


func _temporary_event_reward_map_for_level(event_def: Dictionary, spawn_level: int) -> Dictionary:
	var page := str(event_def.get("page", ""))
	var reference_action := _temporary_event_reference_action_for_level(page, spawn_level)
	var reference_rewards = host._base_xp_reward_map(reference_action, page) if not reference_action.is_empty() else {}
	var reference_total = host._reward_map_total(reference_rewards)
	if reference_total <= 0:
		reference_total = maxi(1, int(event_def.get("xp", 1)))
	var reference_seconds := maxf(0.1, float(reference_action.get("seconds", event_def.get("seconds", 1.0)))) if not reference_action.is_empty() else maxf(0.1, float(event_def.get("seconds", 1.0)))
	var event_seconds := _temporary_event_seconds_for_level(event_def, spawn_level)
	var target_total := maxi(1, int(round(float(reference_total) / reference_seconds * event_seconds * TEMPORARY_EVENT_XP_RATE_MULTIPLIER)))
	var xp_reward_cap := int(event_def.get("xp_reward_cap", 0))
	if xp_reward_cap > 0:
		target_total = mini(target_total, xp_reward_cap)
	return _temporary_event_distribute_reward_total(event_def, target_total)


func _temporary_event_resource_rewards_for_level(event_def: Dictionary, spawn_level: int) -> Dictionary:
	var rewards = event_def.get("resource_rewards", {})
	if typeof(rewards) != TYPE_DICTIONARY:
		return {}
	var resource_rewards := rewards as Dictionary
	var logs_min := maxi(0, int(resource_rewards.get("logs_min", 0)))
	var logs_max := maxi(logs_min, int(resource_rewards.get("logs_max", logs_min)))
	if logs_max <= 0:
		return {}
	var event_meta := event_def.get("event", {}) as Dictionary
	var minimum_level := maxi(1, int(event_meta.get("minimum_level", event_def.get("minimum_level", event_def.get("unlock", 1)))))
	var reward_scale := maxf(1.0, float(maxi(1, spawn_level)) / float(minimum_level))
	return {
		"logs_min": maxi(1, int(round(float(logs_min) * reward_scale))),
		"logs_max": maxi(1, int(round(float(logs_max) * reward_scale)))
	}


func _temporary_event_roll_log_reward(action: Dictionary) -> int:
	if not host._is_event_action(action):
		return 0
	var rewards = action.get("resource_rewards", {})
	if typeof(rewards) != TYPE_DICTIONARY:
		return 0
	var resource_rewards := rewards as Dictionary
	var logs_min := maxi(0, int(resource_rewards.get("logs_min", 0)))
	var logs_max := maxi(logs_min, int(resource_rewards.get("logs_max", logs_min)))
	if logs_max <= 0:
		return 0
	if logs_min >= logs_max:
		return logs_min
	return randi_range(logs_min, logs_max)


func _temporary_event_log_reward_mat_id() -> String:
	var best_mat_id := "scrapwood"
	var best_tier = TEMPORARY_EVENT_LOG_REWARD_MAT_TIERS.find(best_mat_id)
	for raw_action in host.actions_by_skill.get("woodcutting", []):
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var woodcutting_action := raw_action as Dictionary
		if not host._is_action_unlocked("woodcutting", woodcutting_action):
			continue
		for raw_reward in host._action_runtime()._action_mat_reward_defs(woodcutting_action):
			if typeof(raw_reward) != TYPE_DICTIONARY:
				continue
			var reward := raw_reward as Dictionary
			var mat_id = host.material_runtime.normalize_id(str(reward.get("id", "")))
			var tier = TEMPORARY_EVENT_LOG_REWARD_MAT_TIERS.find(mat_id)
			if tier > best_tier:
				best_tier = tier
				best_mat_id = mat_id
	return best_mat_id


func _temporary_event_seconds_for_level(event_def: Dictionary, spawn_level: int) -> float:
	var page := str(event_def.get("page", ""))
	var reference_action := _temporary_event_reference_action_for_level(page, spawn_level)
	var reference_seconds := maxf(0.1, float(reference_action.get("seconds", event_def.get("seconds", 1.0)))) if not reference_action.is_empty() else maxf(0.1, float(event_def.get("seconds", 1.0)))
	var base_seconds := maxf(TEMPORARY_EVENT_BASE_SECONDS, reference_seconds * TEMPORARY_EVENT_REFERENCE_SECONDS_MULTIPLIER)
	return maxf(0.1, base_seconds + maxf(0.0, float(spawn_level)) * TEMPORARY_EVENT_SECONDS_PER_LEVEL)


func _temporary_event_stamina_for_level(event_def: Dictionary, spawn_level: int) -> int:
	var page := str(event_def.get("page", ""))
	if page == "fishing":
		return 0
	var reference_action := _temporary_event_reference_action_for_level(page, spawn_level)
	var reference_stamina := int(reference_action.get("stamina", event_def.get("stamina", 1))) if not reference_action.is_empty() else int(event_def.get("stamina", 1))
	return maxi(1, int(round(float(reference_stamina) * TEMPORARY_EVENT_STAMINA_MULTIPLIER)))


func _temporary_event_scaled_reward_amount(action: Dictionary, base_amount: int) -> int:
	if not host._is_event_action(action):
		return maxi(1, base_amount)
	if bool(action.get("event_stats_scaled", false)):
		return maxi(1, base_amount)
	var active_event := action.get("active_event", {}) as Dictionary
	var spawn_level := _temporary_event_spawn_level_from_entry(active_event, action)
	var definition_level := _temporary_event_definition_level(action)
	if definition_level <= 0 or spawn_level == definition_level:
		return maxi(1, base_amount)
	var scaled := float(maxi(1, base_amount)) * float(spawn_level) / float(definition_level)
	return maxi(1, int(round(scaled)))


func _temporary_event_action_for_entry(event_def: Dictionary, event_entry: Dictionary) -> Dictionary:
	var event_action := event_def.duplicate(true)
	var spawn_level := _temporary_event_spawn_level_from_entry(event_entry, event_def)
	var active_entry := event_entry.duplicate(true)
	active_entry["spawn_level"] = spawn_level
	event_action["unlock"] = spawn_level
	event_action["sort_unlock"] = spawn_level
	event_action["target_level"] = spawn_level
	event_action["requirements"] = [{"skill": str(event_def.get("page", "")), "level": spawn_level}]
	event_action["active_event"] = active_entry
	var reward_map := _temporary_event_reward_map_for_level(event_def, spawn_level)
	var page := str(event_def.get("page", ""))
	event_action["xp_rewards"] = reward_map
	event_action["xp"] = maxi(1, int(reward_map.get(page, host._reward_map_total(reward_map))))
	event_action["resource_rewards"] = _temporary_event_resource_rewards_for_level(event_def, spawn_level)
	event_action["seconds"] = _temporary_event_seconds_for_level(event_def, spawn_level)
	event_action["stamina"] = _temporary_event_stamina_for_level(event_def, spawn_level)
	event_action["success"] = TEMPORARY_EVENT_BASE_SUCCESS
	event_action["event_stats_scaled"] = true
	var event_meta := event_action.get("event", {}) as Dictionary
	event_meta["spawn_level"] = spawn_level
	event_meta["reward_rate_multiplier"] = TEMPORARY_EVENT_XP_RATE_MULTIPLIER
	if int(event_def.get("xp_reward_cap", 0)) > 0:
		event_meta["xp_reward_cap"] = int(event_def.get("xp_reward_cap", 0))
	event_meta["stamina_multiplier"] = TEMPORARY_EVENT_STAMINA_MULTIPLIER
	event_meta["base_seconds"] = TEMPORARY_EVENT_BASE_SECONDS
	event_meta["seconds_per_level"] = TEMPORARY_EVENT_SECONDS_PER_LEVEL
	event_meta["base_success"] = TEMPORARY_EVENT_BASE_SUCCESS
	event_action["event"] = event_meta
	return event_action


func _active_event_actions_for_skill(skill_id: String) -> Array:
	var active_actions := []
	if skill_id.is_empty() or temporary_event_active.is_empty():
		return active_actions
	var now = host._unix_now()
	for raw_event_id in temporary_event_active.keys():
		var event_id := str(raw_event_id)
		var entry = temporary_event_active.get(raw_event_id, {})
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var event_entry := entry as Dictionary
		if bool(event_entry.get("completed", false)):
			continue
		var expires_unix := int(event_entry.get("expires_unix", 0))
		if expires_unix > 0 and expires_unix <= now:
			continue
		var event_def := _event_module_def(event_id)
		if event_def.is_empty() or str(event_def.get("page", "")) != skill_id:
			continue
		if not _temporary_event_page_level_eligible(event_def):
			continue
		var event_action := _temporary_event_action_for_entry(event_def, event_entry)
		event_action["database_order"] = 100000 + int(event_def.get("definition_order", 0))
		active_actions.append(event_action)
	if active_actions.size() > 1:
		active_actions.sort_custom(func(left, right): return host._activity_data_catalog().activity_action_display_sort_less(left, right))
	return active_actions


func _active_event_action_data(skill_id: String, action_id: String) -> Dictionary:
	if skill_id.is_empty() or action_id.is_empty():
		return {}
	for raw_action in _active_event_actions_for_skill(skill_id):
		var action := raw_action as Dictionary
		if str(action.get("id", "")) == action_id:
			return action
	return {}


func _process_temporary_event_scheduler(delta: float) -> void:
	if event_module_defs.is_empty():
		return
	temporary_event_scheduler_elapsed += maxf(0.0, delta)
	if temporary_event_scheduler_elapsed < TEMPORARY_EVENT_SCHEDULER_CHECK_SECONDS:
		return
	temporary_event_scheduler_elapsed = 0.0
	_sync_temporary_event_scheduler(host._unix_now())


func _sync_temporary_event_scheduler(now_unix: int = -1) -> bool:
	if event_module_defs.is_empty():
		return false
	var now = host._unix_now() if now_unix < 0 else maxi(0, now_unix)
	var changed := false
	changed = _expire_temporary_events(now) or changed
	changed = _prune_temporary_event_cooldowns(now) or changed
	if temporary_event_next_roll_unix <= 0:
		temporary_event_next_roll_unix = now + TEMPORARY_EVENT_INITIAL_ROLL_DELAY_SECONDS
		changed = true
	elif now >= temporary_event_next_roll_unix and _temporary_event_active_count() < TEMPORARY_EVENT_MAX_ACTIVE:
		var roll_unix = temporary_event_next_roll_unix
		changed = _try_spawn_temporary_event(now, roll_unix) or changed
		temporary_event_next_roll_unix = now + TEMPORARY_EVENT_ROLL_INTERVAL_SECONDS
		changed = true
	if changed:
		_mark_temporary_event_state_changed("temporary event scheduler")
	return changed


func _mark_temporary_event_state_changed(reason: String) -> void:
	host._mark_save_dirty(reason)
	host.ui_static_refresh_elapsed = host.UI_STATIC_REFRESH_INTERVAL_SECONDS


func _temporary_event_active_count() -> int:
	var count := 0
	for raw_event_id in temporary_event_active.keys():
		var event_id := str(raw_event_id)
		if _event_module_def(event_id).is_empty():
			continue
		var entry = temporary_event_active.get(raw_event_id, {})
		if typeof(entry) == TYPE_DICTIONARY and not bool((entry as Dictionary).get("completed", false)):
			count += 1
	return count


func _expire_temporary_events(now_unix: int) -> bool:
	var changed := false
	for raw_event_id in temporary_event_active.keys():
		var event_id := str(raw_event_id)
		var entry = temporary_event_active.get(raw_event_id, {})
		if typeof(entry) != TYPE_DICTIONARY or _event_module_def(event_id).is_empty():
			temporary_event_active.erase(raw_event_id)
			changed = true
			continue
		var event_entry := entry as Dictionary
		var completed := bool(event_entry.get("completed", false))
		var expires_unix := int(event_entry.get("expires_unix", 0))
		if not completed and expires_unix > now_unix:
			continue
		var cooldown_until := _temporary_event_cooldown_until(event_id, event_entry, now_unix)
		if cooldown_until > 0:
			temporary_event_cooldowns[event_id] = maxi(int(temporary_event_cooldowns.get(event_id, 0)), cooldown_until)
		temporary_event_active.erase(raw_event_id)
		changed = true
	return changed


func _temporary_event_cooldown_until(event_id: String, event_entry: Dictionary, now_unix: int) -> int:
	var event_def := _event_module_def(event_id)
	if event_def.is_empty():
		return 0
	var event_meta := event_def.get("event", {}) as Dictionary
	var cooldown_seconds := maxi(1, int(event_meta.get("respawn_cooldown_seconds", 21600)))
	var base_unix := now_unix
	if bool(event_entry.get("completed", false)):
		var completed_unix := int(event_entry.get("completed_unix", 0))
		base_unix = completed_unix if completed_unix > 0 else now_unix
	else:
		var expires_unix := int(event_entry.get("expires_unix", 0))
		base_unix = expires_unix if expires_unix > 0 else now_unix
	return maxi(0, base_unix + cooldown_seconds)


func _prune_temporary_event_cooldowns(now_unix: int) -> bool:
	var changed := false
	for raw_event_id in temporary_event_cooldowns.keys():
		var event_id := str(raw_event_id)
		var cooldown_until := int(temporary_event_cooldowns.get(raw_event_id, 0))
		if _event_module_def(event_id).is_empty() or cooldown_until <= now_unix:
			temporary_event_cooldowns.erase(raw_event_id)
			changed = true
	return changed


func _try_spawn_temporary_event(now_unix: int, roll_unix: int) -> bool:
	var candidates := _eligible_temporary_events(now_unix)
	if candidates.is_empty():
		return false
	var event_def := _choose_weighted_temporary_event(candidates, roll_unix)
	if event_def.is_empty():
		return false
	var event_id := str(event_def.get("id", ""))
	if event_id.is_empty():
		return false
	temporary_event_active[event_id] = _temporary_event_spawn_entry(event_def, now_unix, roll_unix)
	host._temporary_event_surface()._animate_temporary_event_entry_if_visible(event_def, event_id)
	return true


func _eligible_temporary_events(now_unix: int) -> Array:
	var candidates := []
	for raw_event in event_module_defs:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event_def := raw_event as Dictionary
		if _temporary_event_can_spawn(event_def, now_unix):
			candidates.append(event_def)
	return candidates


func _temporary_event_can_spawn(event_def: Dictionary, now_unix: int) -> bool:
	var event_id := str(event_def.get("id", ""))
	var page := str(event_def.get("page", ""))
	if event_id.is_empty() or page.is_empty() or not host.actions_by_skill.has(page):
		return false
	if _temporary_event_is_active(event_id):
		return false
	if int(temporary_event_cooldowns.get(event_id, 0)) > now_unix:
		return false
	return _temporary_event_page_level_eligible(event_def)


func _temporary_event_is_active(event_id: String) -> bool:
	if event_id.is_empty() or not temporary_event_active.has(event_id):
		return false
	var entry = temporary_event_active.get(event_id, {})
	return typeof(entry) == TYPE_DICTIONARY and not bool((entry as Dictionary).get("completed", false))


func _choose_weighted_temporary_event(candidates: Array, roll_unix: int) -> Dictionary:
	var total_weight := 0.0
	for raw_event in candidates:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event_def := raw_event as Dictionary
		var event_meta := event_def.get("event", {}) as Dictionary
		total_weight += maxf(0.0, float(event_meta.get("spawn_weight", 1.0)))
	if total_weight <= 0.0:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(hash("%s:%s:%s:%s" % [
		str(roll_unix),
		str(host._global_level()),
		str(temporary_event_active.size()),
		str(temporary_event_cooldowns.size())
	])))
	var roll := rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for raw_event in candidates:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event_def := raw_event as Dictionary
		var event_meta := event_def.get("event", {}) as Dictionary
		var weight := maxf(0.0, float(event_meta.get("spawn_weight", 1.0)))
		if weight <= 0.0:
			continue
		cursor += weight
		if roll <= cursor:
			return event_def
	var fallback = candidates.back()
	return fallback as Dictionary


func _temporary_event_spawn_entry(event_def: Dictionary, now_unix: int, roll_unix: int) -> Dictionary:
	var event_meta := event_def.get("event", {}) as Dictionary
	var duration_seconds := maxi(1, int(event_meta.get("active_duration_seconds", 3600)))
	var event_id := str(event_def.get("id", ""))
	var page := str(event_def.get("page", ""))
	return {
		"id": event_id,
		"page": page,
		"spawn_level": _temporary_event_spawn_level_for_page(page, event_id, roll_unix),
		"spawned_unix": now_unix,
		"expires_unix": now_unix + duration_seconds,
		"completed": false,
		"completed_unix": 0
	}


func reset() -> void:
	temporary_event_active.clear()
	temporary_event_cooldowns.clear()
	temporary_event_next_roll_unix = 0
	temporary_event_scheduler_elapsed = 0.0


func _start_temporary_event_action(skill_id: String, action_id: String, action: Dictionary, select_page := true) -> bool:
	host._audio_director()._unlock_audio_for_gameplay()
	host._audio_director()._play_activity_tap_sfx()
	if host.event_running_skill_id == skill_id and host.event_running_action_id == action_id:
		host._set_result("Event already underway: %s." % str(action.get("name", "Event")))
		host._pop_activity_button(host._action_key(skill_id, action_id))
		return false
	var action_key = host._action_key(skill_id, action_id)
	var stamina_cost = host._action_runtime()._effective_stamina(skill_id, action)
	if not host._auto_eat_fish_for_action(skill_id, stamina_cost, host.detail_regen_circle, true):
		host._set_result(_event_needs_stamina_text(skill_id, action))
		host._reward_feedback_surface()._float_event_need_stamina_feedback(action_key, stamina_cost)
		return false
	if select_page:
		host.selected_skill_id = skill_id
	host.event_running_skill_id = skill_id
	host.event_running_action_id = action_id
	host.event_action_progress = 0.0
	if host._audio_director().music_cycle_active:
		host._audio_director()._record_music_flow_start()
	host._pop_activity_button(action_key)
	host._material_collection_surface()._sync_visible_mat_collection_for_action(skill_id, action_id, true)
	host._set_result("Event started: %s." % str(action.get("name", "Event")))
	host._onboarding_runtime()._record_activity_start_for_tips()
	host._fade_out_onboarding_explore_tip()
	host._onboarding_runtime()._tutorial_on_action_started()
	return true


func _stop_temporary_event_action_with_feedback(skill_id: String, action_id: String, result_text: String, popup_text: String, color: Color) -> void:
	var action_key: String = host._action_key(skill_id, action_id)
	host._set_result(result_text)
	if not popup_text.is_empty():
		host._reward_feedback_surface()._float_action_card_warning_feedback(action_key, popup_text, color)
	_clear_running_temporary_event_action(skill_id, action_id)
	host._update_ui(0.0, false)


func _event_needs_stamina_text(skill_id: String, action: Dictionary) -> String:
	var cost: float = host._action_runtime()._effective_stamina(skill_id, action)
	var current_stamina: float = host._stamina_value(skill_id)
	return "%s needs %s stamina. You have %s." % [
		str(action.get("name", "Event")),
		GameFormatting.stamina_cost_detail(cost),
		GameFormatting.stamina_cost_detail(current_stamina)
	]


func _clear_running_temporary_event_action(skill_id: String, action_id: String) -> void:
	if host.event_running_skill_id == skill_id and host.event_running_action_id == action_id:
		host.event_running_skill_id = ""
		host.event_running_action_id = ""
		host.event_action_progress = 0.0
	if host.running_skill_id == skill_id and host.running_action_id == action_id:
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
		host.tired_activity_zero_float_action_key = ""
		host._action_runtime()._reset_action_opportunity_state()


func _complete_temporary_event_action_attempt(skill_id: String, action_id: String, action: Dictionary, reward_key: String, cost: float, bonus_snapshot_before: Dictionary, clear_running_action_on_success := true) -> void:
	if skill_id.is_empty() or action_id.is_empty() or action.is_empty():
		return
	var completed_achievements_before = AchievementState.completed_ids(AchievementState.milestones(host, false))
	var old_reward_skill_levels = host._skill_levels_for_reward_map(skill_id, host._base_xp_reward_map(action, skill_id))
	var success = host._action_runtime()._roll_action_success(skill_id, action)
	if success:
		var xp_reward_map = host._completion_xp_reward_map(action, skill_id, false, false, false, false)
		old_reward_skill_levels = host._skill_levels_for_reward_map(skill_id, xp_reward_map)
		var affected_reward_skill_ids = host._apply_xp_reward_map(skill_id, xp_reward_map)
		for raw_reward_skill_id in affected_reward_skill_ids:
			host._recalculate_level(str(raw_reward_skill_id))
		var any_reward_skill_level_up = host._any_reward_skill_leveled_up(affected_reward_skill_ids, old_reward_skill_levels)
		host._passive_modules_runtime().sync_passive_module_unlocks(host._unix_now())
		var log_reward := _temporary_event_roll_log_reward(action)
		var log_reward_mat_id := _temporary_event_log_reward_mat_id()
		var log_reward_amount = host.material_runtime.buffed_log_collection_amount_for_host(log_reward_mat_id, float(log_reward), host)
		if log_reward > 0:
			host.material_runtime.add_amount(log_reward_mat_id, log_reward_amount)
		var xp_reward = host._reward_map_total(xp_reward_map)
		host.last_result = "Event complete: %s" % host._xp_reward_result_sentence(xp_reward_map, skill_id, str(action.get("name", "Event")))
		if log_reward > 0:
			host.last_result += " +%s %s." % [host.material_runtime.amount_text_for_host(log_reward_mat_id, log_reward_amount, host), host.material_runtime.display_name(log_reward_mat_id)]
		host._reward_feedback_surface()._play_action_feedback(reward_key, true, xp_reward, 0.0, false, false, xp_reward_map)
		for achievement in AchievementState.newly_completed(AchievementState.milestones(host, false), completed_achievements_before):
			host._achievement_toast_surface().show_unlocked(achievement)
		host._audio_director()._play_activity_success_sound(1, false, false, false, false, 0)
		host._audio_director()._record_music_flow_action(true, 1, false, false, any_reward_skill_level_up, cost)
		_complete_temporary_event_action_state(action_id, host._unix_now())
		if clear_running_action_on_success:
			_clear_running_temporary_event_action(skill_id, action_id)
		host._onboarding_runtime()._record_activity_completion_for_tips(skill_id, action_id)
		host._temporary_event_surface()._play_temporary_event_completion_exit(skill_id, action_id, xp_reward)
	else:
		host.consecutive_activity_crit_count = 0
		host._reset_activity_completion_streak()
		host.last_result = "Event failed: %s will try again." % str(action.get("name", "Event"))
		host._reward_feedback_surface()._play_action_feedback(reward_key, false, 0, 0.0)
		for achievement in AchievementState.newly_completed(AchievementState.milestones(host, false), completed_achievements_before):
			host._achievement_toast_surface().show_unlocked(achievement)
		host._audio_director()._play_failure_sfx()
		host._audio_director()._record_music_flow_action(false, 0, false, false, false, cost)
		host._onboarding_runtime()._record_activity_completion_for_tips(skill_id, action_id)
		host._update_ui(0.0, false)
	host._emphasize_visible_bonus_changes_deferred(bonus_snapshot_before)


func _complete_temporary_event_action_state(event_id: String, completed_unix: int) -> bool:
	if event_id.is_empty() or not temporary_event_active.has(event_id):
		return false
	var entry = temporary_event_active.get(event_id, {})
	if typeof(entry) != TYPE_DICTIONARY:
		temporary_event_active.erase(event_id)
		_mark_temporary_event_state_changed("temporary event complete")
		return true
	var event_entry := (entry as Dictionary).duplicate(true)
	event_entry["completed"] = true
	event_entry["completed_unix"] = maxi(0, completed_unix)
	var cooldown_until := _temporary_event_cooldown_until(event_id, event_entry, completed_unix)
	if cooldown_until > 0:
		temporary_event_cooldowns[event_id] = maxi(int(temporary_event_cooldowns.get(event_id, 0)), cooldown_until)
	temporary_event_active.erase(event_id)
	_mark_temporary_event_state_changed("temporary event complete")
	return true


func _temporary_events_for_save() -> Dictionary:
	return TemporaryEventState.save_payload(_temporary_event_active_for_save(), _temporary_event_cooldowns_for_save(), temporary_event_next_roll_unix)


func _restore_temporary_events_from_save(value: Variant) -> void:
	var restored := TemporaryEventState.restored_state(value, Callable(self, "_event_module_def"), Callable(self, "_temporary_event_page_level_eligible"), Callable(self, "_temporary_event_spawn_level_from_entry"))
	temporary_event_active = restored.get("active", {}) as Dictionary
	temporary_event_cooldowns = restored.get("cooldowns", {}) as Dictionary
	temporary_event_next_roll_unix = maxi(0, int(restored.get("next_roll_unix", 0)))


func _temporary_event_active_for_save() -> Dictionary:
	return _normalized_temporary_event_active(temporary_event_active)


func _temporary_event_cooldowns_for_save() -> Dictionary:
	return _normalized_temporary_event_cooldowns(temporary_event_cooldowns)


func _normalized_temporary_event_active(value: Variant) -> Dictionary:
	return TemporaryEventState.normalized_active(value, Callable(self, "_event_module_def"), Callable(self, "_temporary_event_page_level_eligible"), Callable(self, "_temporary_event_spawn_level_from_entry"))


func _normalized_temporary_event_cooldowns(value: Variant) -> Dictionary:
	return TemporaryEventState.normalized_cooldowns(value, Callable(self, "_event_module_def"))
