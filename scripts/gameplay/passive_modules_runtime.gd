extends RefCounted

const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")
const WOODCUTTING_LOG_MODULE_ID := "stack-logs-1"
const WOODCUTTING_LOG_MODULE_UNLOCK_LEVEL := 2
const WOODCUTTING_FIREPIT_MODULE_ID := "woodcutting-firepit"
const WOODCUTTING_FIREPIT_UNLOCK_LEVEL := 2
const FIREPIT_SCRAPWOOD_PER_SECOND := 1.0 / 30.0
const FIREPIT_MINIMUM_START_SCRAPWOOD := 0.2
const FIREPIT_HEAT_TIER_SECONDS := 60.0
const FIREPIT_MAX_HEAT_TIER := 15
const FIREPIT_STAMINA_REGEN_PER_TIER := 0.04
const FIREPIT_WOODCUTTING_XP_PER_SCRAPWOOD := 2
const FIREPIT_START_SCRAPWOOD_COST := 1.0
const FIREPIT_REGEN_DECAY_SECONDS_PER_PERCENT := 5.0
const PLANK_BUILD_XP_MULT := 0.05
const PASSIVE_TIME_START := 240
const PASSIVE_TIME_MAX := 30
const PASSIVE_YIELD_START := 2
const PASSIVE_YIELD_MAX := 18
const PASSIVE_CAPACITY_START := 20
const PASSIVE_CAPACITY_MAX := 1000
const MAX_OFFLINE_SECONDS := 8 * 60 * 60

var host


func _init(host_node) -> void:
	host = host_node


func is_passive_action(action: Dictionary) -> bool:
	return str(action.get("kind", "activity")) == "passive_item_collect"


func is_firepit_module(module_id: String) -> bool:
	return module_id in [WOODCUTTING_FIREPIT_MODULE_ID, "firepit"]


func save_state_normalizer_limits() -> Dictionary:
	return {
		"passive_capacity_max": PASSIVE_CAPACITY_MAX,
		"passive_time_start": PASSIVE_TIME_START,
		"passive_time_max": PASSIVE_TIME_MAX,
		"passive_yield_start": PASSIVE_YIELD_START,
		"passive_yield_max": PASSIVE_YIELD_MAX,
		"passive_capacity_start": PASSIVE_CAPACITY_START,
		"firepit_max_cooling_bonus": FIREPIT_STAMINA_REGEN_PER_TIER * float(FIREPIT_MAX_HEAT_TIER)
	}


func normalized_passive_modules(loaded_modules: Variant, now: int) -> Dictionary:
	return SaveStateNormalizers.normalized_passive_modules(loaded_modules, Callable(self, "is_firepit_module"), now, save_state_normalizer_limits())


func restore_from_save(data: Dictionary, preserve_existing := false) -> void:
	var loaded_passive_modules = normalized_passive_modules(data.get("passive_modules", {}), host._unix_now())
	if typeof(loaded_passive_modules) != TYPE_DICTIONARY:
		return
	for raw_module_id in loaded_passive_modules.keys():
		var module_id := str(raw_module_id)
		if preserve_existing and host.passive_modules.has(module_id):
			continue
		host.passive_modules[module_id] = loaded_passive_modules.get(raw_module_id, {}) as Dictionary


func for_save() -> Dictionary:
	return normalized_passive_modules(host.passive_modules, host._unix_now())


func firepit_state_from_save(loaded_module: Dictionary, now: int) -> Dictionary:
	return SaveStateNormalizers.firepit_state(loaded_module, now, save_state_normalizer_limits())


func passive_module_state_from_save(loaded_module: Dictionary, now: int) -> Dictionary:
	return SaveStateNormalizers.passive_module_state(loaded_module, now, save_state_normalizer_limits())


func firepit_state(now: int) -> Dictionary:
	return ensure_firepit_state(now)


func ensure_firepit_state(now: int) -> Dictionary:
	if not host.passive_modules.has(WOODCUTTING_FIREPIT_MODULE_ID) or typeof(host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID]) != TYPE_DICTIONARY:
		host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = {
			"active": false,
			"igniting": false,
			"last_update": now,
			"started_unix": 0,
			"burned_scrapwood": 0.0,
			"cooling_bonus": 0.0,
			"cooling_started_unix": 0,
			"shutdown_reason": ""
		}
	var state := host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] as Dictionary
	state["active"] = bool(state.get("active", false))
	state["igniting"] = bool(state.get("igniting", false)) and not bool(state.get("active", false))
	var last_update := int(state.get("last_update", now))
	if last_update <= 0 or last_update > now + 60:
		last_update = now
	state["last_update"] = last_update
	state["started_unix"] = maxi(0, int(state.get("started_unix", 0)))
	state["burned_scrapwood"] = maxf(0.0, float(state.get("burned_scrapwood", 0.0)))
	state["cooling_bonus"] = clampf(float(state.get("cooling_bonus", 0.0)), 0.0, FIREPIT_STAMINA_REGEN_PER_TIER * float(FIREPIT_MAX_HEAT_TIER))
	state["cooling_started_unix"] = maxi(0, int(state.get("cooling_started_unix", 0)))
	if not bool(state.get("active", false)) and float(state.get("cooling_bonus", 0.0)) > 0.0:
		var decayed_bonus := firepit_decayed_cooling_bonus_from_state(state, now)
		state["cooling_bonus"] = decayed_bonus
		if decayed_bonus <= 0.0001:
			state["cooling_bonus"] = 0.0
			state["cooling_started_unix"] = 0
		else:
			state["cooling_started_unix"] = now
	state["shutdown_reason"] = str(state.get("shutdown_reason", ""))
	host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
	return state


func firepit_active(now: int) -> bool:
	return bool(firepit_state(now).get("active", false)) and is_passive_module_unlocked(WOODCUTTING_FIREPIT_MODULE_ID)


func firepit_heat_seconds(now: int) -> float:
	if not firepit_active(now):
		return 0.0
	var state := firepit_state(now)
	var started_unix := int(state.get("started_unix", 0))
	if started_unix <= 0:
		return 0.0
	return maxf(0.0, float(now - started_unix))


func firepit_heat_tier(now: int) -> int:
	if not firepit_active(now):
		return 0
	var tier := int(floor(firepit_heat_seconds(now) / FIREPIT_HEAT_TIER_SECONDS)) + 1
	return clampi(tier, 1, FIREPIT_MAX_HEAT_TIER)


func firepit_active_regen_bonus(now: int) -> float:
	return float(firepit_heat_tier(now)) * FIREPIT_STAMINA_REGEN_PER_TIER


func firepit_shutdown_regen_bonus_from_state(state: Dictionary, now: int) -> float:
	if bool(state.get("active", false)):
		var started_unix := int(state.get("started_unix", 0))
		if started_unix <= 0:
			return FIREPIT_STAMINA_REGEN_PER_TIER
		var heat_seconds := maxf(0.0, float(now - started_unix))
		var tier := clampi(int(floor(heat_seconds / FIREPIT_HEAT_TIER_SECONDS)) + 1, 1, FIREPIT_MAX_HEAT_TIER)
		return float(tier) * FIREPIT_STAMINA_REGEN_PER_TIER
	return firepit_decayed_cooling_bonus_from_state(state, now)


func firepit_decayed_cooling_bonus_from_state(state: Dictionary, now: int) -> float:
	var cooling_bonus := clampf(float(state.get("cooling_bonus", 0.0)), 0.0, FIREPIT_STAMINA_REGEN_PER_TIER * float(FIREPIT_MAX_HEAT_TIER))
	if cooling_bonus <= 0.0:
		return 0.0
	var cooling_started_unix := maxi(0, int(state.get("cooling_started_unix", 0)))
	if cooling_started_unix <= 0:
		return cooling_bonus
	var decay_per_second := 0.01 / maxf(0.001, FIREPIT_REGEN_DECAY_SECONDS_PER_PERCENT)
	var elapsed := maxf(0.0, float(now - cooling_started_unix))
	return maxf(0.0, cooling_bonus - elapsed * decay_per_second)


func firepit_cooling_regen_bonus(now: int) -> float:
	var state := ensure_firepit_state(now)
	if bool(state.get("active", false)):
		return 0.0
	return firepit_decayed_cooling_bonus_from_state(state, now)


func set_firepit_cooling_from_bonus(state: Dictionary, now: int, bonus: float) -> Dictionary:
	var clamped_bonus := clampf(bonus, 0.0, FIREPIT_STAMINA_REGEN_PER_TIER * float(FIREPIT_MAX_HEAT_TIER))
	state["cooling_bonus"] = clamped_bonus
	state["cooling_started_unix"] = now if clamped_bonus > 0.0001 else 0
	return state


func firepit_restart_heat_offset_seconds(cooling_bonus: float) -> float:
	if cooling_bonus <= 0.0001:
		return 0.0
	var preserved_tier := clampi(int(ceil(cooling_bonus / FIREPIT_STAMINA_REGEN_PER_TIER)), 1, FIREPIT_MAX_HEAT_TIER)
	return float(preserved_tier - 1) * FIREPIT_HEAT_TIER_SECONDS


func firepit_comfort_text(heat_tier: int) -> String:
	if heat_tier >= FIREPIT_MAX_HEAT_TIER:
		return "Feels perfect"
	if heat_tier >= 12:
		return "Feels powerful"
	if heat_tier >= 8:
		return "Feels wonderful"
	if heat_tier >= 4:
		return "Feels steady"
	if heat_tier > 0:
		return "Feels good"
	return "Fire is out"


func firepit_stamina_regen_bonus(skill_id: String, now: int) -> float:
	if skill_id != "woodcutting":
		return 0.0
	if firepit_active(now):
		return firepit_active_regen_bonus(now)
	return firepit_cooling_regen_bonus(now)


func award_firepit_burn_xp(scrapwood_burned: int, animate := true) -> void:
	if scrapwood_burned <= 0 or not host.skills.has("woodcutting"):
		return
	var xp_reward := scrapwood_burned * FIREPIT_WOODCUTTING_XP_PER_SCRAPWOOD
	if xp_reward <= 0:
		return
	host.skills["woodcutting"]["xp"] = int(host.skills["woodcutting"].get("xp", 0)) + xp_reward
	SkillState.recalculate_level(host, "woodcutting")
	host._mark_save_dirty("firepit xp")
	if animate and (host.startup_initialized or host.action_cards.has(host._action_key("woodcutting", WOODCUTTING_FIREPIT_MODULE_ID))):
		host._passive_firepit_surface()._hold_firepit_next_scrapwood_ring_empty()
		host._passive_firepit_surface()._animate_firepit_scrapwood_to_fire(scrapwood_burned)


func toggle_plank_boost() -> void:
	host.plank_boost_enabled = not host.plank_boost_enabled
	host.save_game()
	host._update_ui(0.0, false)


func plank_bonus_applies(skill_id: String) -> bool:
	return skill_id == "build" and host.plank_boost_enabled and host.material_runtime.amount("softwood") >= 1.0


func firepit_seconds_available(scrapwood: float) -> float:
	if FIREPIT_SCRAPWOOD_PER_SECOND <= 0.0:
		return 0.0
	return maxf(0.0, scrapwood) / FIREPIT_SCRAPWOOD_PER_SECOND


func firepit_heat_bonus_progress_pct(now: int) -> float:
	var max_bonus := FIREPIT_STAMINA_REGEN_PER_TIER * float(FIREPIT_MAX_HEAT_TIER)
	if max_bonus <= 0.0:
		return 0.0
	if not firepit_active(now):
		return clampf(firepit_cooling_regen_bonus(now) / max_bonus * 100.0, 0.0, 100.0)
	var state := firepit_state(now)
	var started_unix := int(state.get("started_unix", 0))
	if started_unix <= 0:
		return 0.0
	var max_heat_seconds := FIREPIT_HEAT_TIER_SECONDS * float(FIREPIT_MAX_HEAT_TIER)
	if max_heat_seconds <= 0.0:
		return 0.0
	var live_heat_seconds := maxf(0.0, Time.get_unix_time_from_system() - float(started_unix))
	var smooth_heat_seconds := clampf(FIREPIT_HEAT_TIER_SECONDS + live_heat_seconds, FIREPIT_HEAT_TIER_SECONDS, max_heat_seconds)
	return clampf(smooth_heat_seconds / max_heat_seconds * 100.0, 0.0, 100.0)


func firepit_next_scrapwood_progress_pct(state: Dictionary, now: int) -> float:
	if not firepit_active(now):
		return 0.0
	var burned := maxf(0.0, float(state.get("burned_scrapwood", 0.0)))
	var last_update := int(state.get("last_update", now))
	var live_elapsed := maxf(0.0, Time.get_unix_time_from_system() - float(last_update))
	burned += live_elapsed * FIREPIT_SCRAPWOOD_PER_SECOND
	var partial := fposmod(burned, 1.0)
	return clampf((1.0 - partial) * 100.0, 0.0, 100.0)


func passive_module_state(module_id: String, now: int) -> Dictionary:
	return ensure_passive_module_state(module_id, now)


func ensure_passive_module_state(module_id: String, now: int) -> Dictionary:
	if module_id.is_empty():
		module_id = WOODCUTTING_LOG_MODULE_ID
	if is_firepit_module(module_id):
		return ensure_firepit_state(now)
	if not host.passive_modules.has(module_id) or typeof(host.passive_modules[module_id]) != TYPE_DICTIONARY:
		host.passive_modules[module_id] = {
			"stored": 0,
			"time_seconds": PASSIVE_TIME_START,
			"yield": PASSIVE_YIELD_START,
			"capacity": PASSIVE_CAPACITY_START,
			"seeded": false,
			"last_update": now
		}
	var state := host.passive_modules[module_id] as Dictionary
	state["time_seconds"] = clampi(int(state.get("time_seconds", PASSIVE_TIME_START)), PASSIVE_TIME_MAX, PASSIVE_TIME_START)
	state["yield"] = clampi(int(state.get("yield", PASSIVE_YIELD_START)), PASSIVE_YIELD_START, PASSIVE_YIELD_MAX)
	state["capacity"] = clampi(int(state.get("capacity", PASSIVE_CAPACITY_START)), PASSIVE_CAPACITY_START, PASSIVE_CAPACITY_MAX)
	state["stored"] = clampi(int(state.get("stored", 0)), 0, int(state["capacity"]))
	state["seeded"] = bool(state.get("seeded", false))
	var last_update := int(state.get("last_update", now))
	if last_update <= 0 or last_update > now + 60:
		last_update = now
	state["last_update"] = last_update
	host.passive_modules[module_id] = state
	return state


func is_passive_module_unlocked(module_id: String) -> bool:
	var action: Dictionary = host._action_data("woodcutting", module_id)
	if action.is_empty():
		if is_firepit_module(module_id):
			return SkillState.host_skill_level(host, "woodcutting") >= WOODCUTTING_FIREPIT_UNLOCK_LEVEL
		return SkillState.host_skill_level(host, "woodcutting") >= WOODCUTTING_LOG_MODULE_UNLOCK_LEVEL
	return host._activity_unlock_runtime()._is_action_unlocked("woodcutting", action)


func sync_passive_module_unlocks(now: int) -> void:
	for action in host.actions_by_skill.get("woodcutting", []):
		var action_data := action as Dictionary
		if not is_passive_action(action_data):
			continue
		var module_id := str(action_data.get("id", WOODCUTTING_LOG_MODULE_ID))
		var state := ensure_passive_module_state(module_id, now)
		if is_firepit_module(module_id):
			if not is_passive_module_unlocked(module_id):
				state["active"] = false
				state["igniting"] = false
				state["last_update"] = now
				state["started_unix"] = 0
				state["burned_scrapwood"] = 0.0
				state["cooling_bonus"] = 0.0
				state["cooling_started_unix"] = 0
			host.passive_modules[module_id] = state
			continue
		if is_passive_module_unlocked(module_id):
			if not bool(state.get("seeded", false)):
				state["stored"] = mini(int(state.get("capacity", PASSIVE_CAPACITY_START)), int(state.get("stored", 0)) + 3)
				state["seeded"] = true
				state["last_update"] = now
		else:
			state["last_update"] = now
		host.passive_modules[module_id] = state


func process_passive_modules(now: int) -> void:
	if now == host.last_passive_process_unix:
		return
	host.last_passive_process_unix = now
	sync_passive_module_unlocks(now)
	apply_passive_module_production(now)
	apply_firepit_fuel(now)


func reset_passive_module_timestamps(now: int) -> void:
	for action in host.actions_by_skill.get("woodcutting", []):
		var action_data := action as Dictionary
		if not is_passive_action(action_data):
			continue
		var module_id := str(action_data.get("id", WOODCUTTING_LOG_MODULE_ID))
		var state := ensure_passive_module_state(module_id, now)
		state["last_update"] = now
		host.passive_modules[module_id] = state


func apply_passive_module_production(now: int) -> void:
	for action in host.actions_by_skill.get("woodcutting", []):
		var action_data := action as Dictionary
		if not is_passive_action(action_data):
			continue
		var module_id := str(action_data.get("id", WOODCUTTING_LOG_MODULE_ID))
		if is_firepit_module(module_id):
			continue
		var state := ensure_passive_module_state(module_id, now)
		if not is_passive_module_unlocked(module_id):
			state["last_update"] = now
			host.passive_modules[module_id] = state
			continue
		var capacity := int(state.get("capacity", PASSIVE_CAPACITY_START))
		var stored := clampi(int(state.get("stored", 0)), 0, capacity)
		if stored >= capacity:
			state["stored"] = capacity
			state["last_update"] = now
			host.passive_modules[module_id] = state
			continue
		var interval := maxi(PASSIVE_TIME_MAX, int(state.get("time_seconds", PASSIVE_TIME_START)))
		var last_update := int(state.get("last_update", now))
		var elapsed := maxi(0, mini(MAX_OFFLINE_SECONDS, now - last_update))
		if elapsed < interval:
			host.passive_modules[module_id] = state
			continue
		var cycles := int(floor(float(elapsed) / float(interval)))
		if cycles <= 0:
			host.passive_modules[module_id] = state
			continue
		var produced := cycles * maxi(1, int(state.get("yield", PASSIVE_YIELD_START)))
		var next_stored := mini(capacity, stored + produced)
		var gained := next_stored - stored
		state["stored"] = next_stored
		state["last_update"] = now if next_stored >= capacity else last_update + cycles * interval
		host.passive_modules[module_id] = state
		if gained > 0:
			host._passive_firepit_surface()._float_passive_production_feedback(module_id, gained)


func passive_production_progress_pct(module_id: String, state: Dictionary, unlocked: bool, now: int) -> float:
	if not unlocked or not is_passive_module_unlocked(module_id):
		return 0.0
	var capacity := maxi(1, int(state.get("capacity", PASSIVE_CAPACITY_START)))
	var stored := clampi(int(state.get("stored", 0)), 0, capacity)
	if stored >= capacity:
		return 100.0
	var interval := maxi(PASSIVE_TIME_MAX, int(state.get("time_seconds", PASSIVE_TIME_START)))
	var elapsed := maxf(0.0, float(now) - float(state.get("last_update", now)))
	return clampf(float(elapsed) / float(interval) * 100.0, 0.0, 99.0)


func apply_firepit_fuel(now: int) -> void:
	var state := ensure_firepit_state(now)
	if not bool(state.get("active", false)):
		state["last_update"] = now
		host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
		return
	if not is_passive_module_unlocked(WOODCUTTING_FIREPIT_MODULE_ID):
		var locked_bonus := firepit_shutdown_regen_bonus_from_state(state, now)
		state["active"] = false
		state["igniting"] = false
		state["last_update"] = now
		state["started_unix"] = 0
		state["burned_scrapwood"] = 0.0
		state = set_firepit_cooling_from_bonus(state, now, locked_bonus)
		state["shutdown_reason"] = "locked"
		host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
		SkillState.invalidate_stat_caches(host)
		return
	var last_update := int(state.get("last_update", now))
	var elapsed := maxi(0, mini(MAX_OFFLINE_SECONDS, now - last_update))
	if elapsed <= 0:
		host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
		return
	var requested_fuel := float(elapsed) * FIREPIT_SCRAPWOOD_PER_SECOND
	var available_fuel: float = host.material_runtime.amount("scrapwood")
	if available_fuel <= 0.0001:
		var empty_bonus := firepit_shutdown_regen_bonus_from_state(state, now)
		state["active"] = false
		state["igniting"] = false
		state["last_update"] = now
		state["started_unix"] = 0
		state["burned_scrapwood"] = 0.0
		state = set_firepit_cooling_from_bonus(state, now, empty_bonus)
		state["shutdown_reason"] = "no_fuel"
		host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
		SkillState.invalidate_stat_caches(host)
		host._mark_save_dirty("firepit empty")
		return
	var burned := minf(available_fuel, requested_fuel)
	if burned > 0.0001:
		var previous_whole_scrapwood_burned := int(floor(maxf(0.0, float(state.get("burned_scrapwood", 0.0)))))
		host.material_runtime.set_amount("scrapwood", available_fuel - burned)
		state["burned_scrapwood"] = maxf(0.0, float(state.get("burned_scrapwood", 0.0))) + burned
		var whole_scrapwood_burned := int(floor(maxf(0.0, float(state.get("burned_scrapwood", 0.0)))))
		var newly_burned_whole_scrapwood := maxi(0, whole_scrapwood_burned - previous_whole_scrapwood_burned)
		if newly_burned_whole_scrapwood > 0:
			award_firepit_burn_xp(newly_burned_whole_scrapwood)
	if burned + 0.0001 < requested_fuel:
		var out_of_fuel_bonus := firepit_shutdown_regen_bonus_from_state(state, now)
		state["active"] = false
		state["igniting"] = false
		state["started_unix"] = 0
		state["burned_scrapwood"] = 0.0
		state = set_firepit_cooling_from_bonus(state, now, out_of_fuel_bonus)
		state["shutdown_reason"] = "no_fuel"
		SkillState.invalidate_stat_caches(host)
		host._mark_save_dirty("firepit empty")
	else:
		state["shutdown_reason"] = ""
	state["last_update"] = now
	host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state


func toggle_firepit_pressed(module_id: String, now: int) -> void:
	host._skill_swipe_activity_surface()._cancel_skill_swipe_feedback(false)
	host._passive_firepit_surface()._clear_passive_button_press()
	if not is_firepit_module(module_id) or not is_passive_module_unlocked(module_id):
		return
	apply_firepit_fuel(now)
	if firepit_active(now):
		host.last_result = "Hold the firepit to put the fire out."
	else:
		begin_firepit_ignition(now)


func start_firepit(now: int) -> bool:
	if host.material_runtime.amount("scrapwood") < FIREPIT_MINIMUM_START_SCRAPWOOD:
		host.last_result = "Need Scrapwood to start the fire."
		return false
	var state := ensure_firepit_state(now)
	var restart_heat_offset := firepit_restart_heat_offset_seconds(float(state.get("cooling_bonus", 0.0)))
	state["active"] = true
	state["igniting"] = false
	state["started_unix"] = now - int(restart_heat_offset)
	state["last_update"] = now
	state["burned_scrapwood"] = 0.0
	state["cooling_bonus"] = 0.0
	state["cooling_started_unix"] = 0
	state["shutdown_reason"] = ""
	host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
	host.last_result = "Firepit lit. Warm Momentum started at +4% Woodcutting stamina regen."
	SkillState.invalidate_stat_caches(host)
	host._audio_director()._play_firepit_toggle_sfx(true)
	host._mark_save_dirty("firepit lit")
	host.save_game()
	host._update_ui(0.0, false)
	return true


func begin_firepit_ignition(now: int) -> bool:
	if host.material_runtime.amount("scrapwood") < FIREPIT_START_SCRAPWOOD_COST:
		host.last_result = "Need Scrapwood to start the fire."
		host._passive_firepit_surface()._float_firepit_need_scrapwood()
		return false
	var state := ensure_firepit_state(now)
	if bool(state.get("igniting", false)):
		return false
	var cooling_bonus := float(state.get("cooling_bonus", 0.0))
	state["active"] = false
	state["igniting"] = true
	state["started_unix"] = 0
	state["last_update"] = now
	state["burned_scrapwood"] = 0.0
	state = set_firepit_cooling_from_bonus(state, now, cooling_bonus)
	state["shutdown_reason"] = "igniting"
	host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
	host.last_result = "Feeding Scrapwood into the firepit..."
	host._mark_save_dirty("firepit ignition")
	host._update_ui(0.0, false)
	host._passive_firepit_surface().call_deferred("_launch_firepit_ignition_flyer")
	return true


func finish_firepit_ignition(now: int) -> void:
	var state := ensure_firepit_state(now)
	if not bool(state.get("igniting", false)) or bool(state.get("active", false)):
		return
	if host.material_runtime.amount("scrapwood") < FIREPIT_START_SCRAPWOOD_COST:
		state["active"] = false
		state["igniting"] = false
		state["started_unix"] = 0
		state["last_update"] = now
		state["burned_scrapwood"] = 0.0
		state["shutdown_reason"] = "no_fuel"
		host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
		host.last_result = "Need Scrapwood to start the fire."
		host._passive_firepit_surface()._float_firepit_need_scrapwood()
		host._update_ui(0.0, false)
		return
	host.material_runtime.set_amount("scrapwood", host.material_runtime.amount("scrapwood") - FIREPIT_START_SCRAPWOOD_COST)
	award_firepit_burn_xp(1, false)
	var restart_heat_offset := firepit_restart_heat_offset_seconds(float(state.get("cooling_bonus", 0.0)))
	state["active"] = true
	state["igniting"] = false
	state["started_unix"] = now - int(restart_heat_offset)
	state["last_update"] = now
	state["burned_scrapwood"] = 0.0
	state["cooling_bonus"] = 0.0
	state["cooling_started_unix"] = 0
	state["shutdown_reason"] = ""
	host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
	host.last_result = "Firepit lit. Warm Momentum started at +4% Woodcutting stamina regen."
	SkillState.invalidate_stat_caches(host)
	host._audio_director()._play_firepit_toggle_sfx(true)
	host._passive_firepit_surface()._float_firepit_xp_reward_from_fire(0)
	host._mark_save_dirty("firepit lit")
	host.save_game()
	host._update_ui(0.0, false)


func extinguish_firepit(now: int) -> void:
	var state := ensure_firepit_state(now)
	var cooling_bonus := firepit_shutdown_regen_bonus_from_state(state, now)
	state["active"] = false
	state["last_update"] = now
	state["started_unix"] = 0
	state["burned_scrapwood"] = 0.0
	state = set_firepit_cooling_from_bonus(state, now, cooling_bonus)
	state["shutdown_reason"] = "manual"
	host.passive_modules[WOODCUTTING_FIREPIT_MODULE_ID] = state
	host.last_result = "Firepit stopped. Warm Momentum streak reset."
	SkillState.invalidate_stat_caches(host)
	host._audio_director()._play_firepit_toggle_sfx(false)
	host._mark_save_dirty("firepit stopped")
	host.save_game()
	host._update_ui(0.0, false)


func collect_passive_module(module_id: String, now: int) -> void:
	if not is_passive_module_unlocked(module_id):
		return
	var state := passive_module_state(module_id, now)
	var stored := maxi(0, int(state.get("stored", 0)))
	if stored <= 0:
		return
	var visible_logs_before := int(floor(host.material_runtime.amount("softwood") + 0.0001))
	var collected_amount: float = host.material_runtime.buffed_log_collection_amount_for_host("softwood", float(stored), host)
	host.material_runtime.add_amount("softwood", collected_amount)
	var visible_logs_gained := maxi(1, int(floor(host.material_runtime.amount("softwood") + 0.0001)) - visible_logs_before)
	state["stored"] = 0
	host.passive_modules[module_id] = state
	host._passive_firepit_surface()._float_log_currency_feedback(module_id, visible_logs_gained)
	host.save_game()
	host._update_ui(0.0, false)


func upgrade_passive_module(module_id: String, stat_type: String, now: int) -> bool:
	if not is_passive_module_unlocked(module_id):
		return false
	if passive_upgrade_maxed(module_id, stat_type, now):
		return false
	var cost := passive_upgrade_cost(module_id, stat_type, now)
	if host.material_runtime.amount("softwood") < float(cost):
		return false
	var state := passive_module_state(module_id, now)
	var old_value := passive_upgrade_value(module_id, stat_type, now)
	host.material_runtime.spend_amount("softwood", float(cost))
	if stat_type == "time":
		state["time_seconds"] = passive_next_upgrade_value(module_id, stat_type, now)
	elif stat_type == "yield":
		state["yield"] = passive_next_upgrade_value(module_id, stat_type, now)
	elif stat_type == "capacity":
		state["capacity"] = passive_next_upgrade_value(module_id, stat_type, now)
		state["stored"] = mini(int(state.get("stored", 0)), int(state.get("capacity", PASSIVE_CAPACITY_START)))
	var new_value := int(state.get("time_seconds", PASSIVE_TIME_START)) if stat_type == "time" else (int(state.get("yield", PASSIVE_YIELD_START)) if stat_type == "yield" else int(state.get("capacity", PASSIVE_CAPACITY_START)))
	host.passive_modules[module_id] = state
	host._audio_director()._play_passive_upgrade_sfx()
	host._passive_firepit_surface()._pop_passive_upgrade_button(module_id, stat_type)
	host._passive_firepit_surface()._float_passive_upgrade_feedback(module_id, stat_type, cost, old_value, new_value)
	host.save_game()
	host._update_ui(0.0, false)
	return true


func passive_upgrade_value(module_id: String, stat_type: String, now: int) -> int:
	var state := passive_module_state(module_id, now)
	if stat_type == "time":
		return int(state.get("time_seconds", PASSIVE_TIME_START))
	if stat_type == "yield":
		return int(state.get("yield", PASSIVE_YIELD_START))
	return int(state.get("capacity", PASSIVE_CAPACITY_START))


func passive_upgrade_maxed(module_id: String, stat_type: String, now: int) -> bool:
	var value := passive_upgrade_value(module_id, stat_type, now)
	if stat_type == "time":
		return value <= PASSIVE_TIME_MAX
	if stat_type == "yield":
		return value >= PASSIVE_YIELD_MAX
	return value >= PASSIVE_CAPACITY_MAX


func passive_next_upgrade_value(module_id: String, stat_type: String, now: int) -> int:
	var value := passive_upgrade_value(module_id, stat_type, now)
	if stat_type == "time":
		return maxi(PASSIVE_TIME_MAX, value - 5)
	if stat_type == "yield":
		return mini(PASSIVE_YIELD_MAX, value + 1)
	if value < 80:
		return mini(80, value + 10)
	if value < 200:
		return mini(200, value + 20)
	return mini(PASSIVE_CAPACITY_MAX, value + 50)


func passive_upgrade_step_index(module_id: String, stat_type: String, now: int) -> int:
	var value := passive_upgrade_value(module_id, stat_type, now)
	if stat_type == "time":
		return int(round(float(PASSIVE_TIME_START - value) / 5.0))
	if stat_type == "yield":
		return value - PASSIVE_YIELD_START
	if value < 80:
		return int(round(float(value - PASSIVE_CAPACITY_START) / 10.0))
	if value < 200:
		return 6 + int(round(float(value - 80) / 20.0))
	return 12 + int(round(float(value - 200) / 50.0))


func passive_upgrade_cost(module_id: String, stat_type: String, now: int) -> int:
	if passive_upgrade_maxed(module_id, stat_type, now):
		return 0
	var step_index := passive_upgrade_step_index(module_id, stat_type, now)
	if step_index < 2:
		return 1
	if step_index < 4:
		return 2
	if step_index < 6:
		return 3
	return int(floor(4.0 + pow(float(step_index - 5), 1.58) * 2.75))
