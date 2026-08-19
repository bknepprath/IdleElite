extends RefCounted

const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")

const HUB_BUILD_SECONDS := 15.0
const HUB_OFFLINE_SECONDS_PER_GARDEN_LEVEL := 60 * 60
const HUB_MODULE_MAX_LEVEL := 4
const HUB_TROPHY_SUCCESS_BONUS_BY_TIER := [0.0, 0.01, 0.02, 0.03, 0.05]
const HUB_MODULE_DEFS := {
	"barn": {
		"name": "Barn",
		"sheet": "res://assets/content/hub/hub-barn-tiers.png",
		"cell_count": 5,
		"position": Vector2(235, 550),
		"size": Vector2(280, 280),
		"visual_size": Vector2(280, 280),
		"visual_sizes": [Vector2(280, 280), Vector2(280, 280), Vector2(325, 325), Vector2(360, 360), Vector2(390, 390)],
		"visual_anchor": Vector2(0, 103),
		"cell_bottom_offsets": [Vector2(-2.5, 196), Vector2(0, 180), Vector2(0, 183), Vector2(0, 195), Vector2(0, 211)],
		"bubble_offset": Vector2(260, -380),
		"currency": "softwood",
		"cost_currencies": ["softwood", "softwood", "hardwood", "hardwood"],
		"costs": [60, 360, 90, 260],
		"unlock_levels": [3, 12, 28, 52],
		"bonus": "Makes low success rate activities more reliable."
	},
	"garden": {
		"name": "Garden",
		"sheet": "res://assets/content/hub/hub-garden-tiers.png",
		"cell_count": 5,
		"position": Vector2(280, 830),
		"size": Vector2(280, 280),
		"visual_size": Vector2(280, 280),
		"visual_anchor": Vector2(0, 97),
		"cell_bottom_offsets": [Vector2(-1, 192), Vector2(0, 176), Vector2(0, 182), Vector2(-1, 186), Vector2(-1.5, 201)],
		"bubble_offset": Vector2(260, -380),
		"currency": "mixed",
		"cost_currencies": ["softwood", "softwood", "hardwood", "hardwood"],
		"costs": [45, 280, 80, 220],
		"fish_costs": [15, 125, 600, 2800],
		"unlock_levels": [7, 19, 39, 65],
		"bonus": "+1 hour offline progress cap per level."
	},
	"pond": {
		"name": "Fish Pond",
		"sheet": "res://assets/content/hub/hub-fish-pond-tiers.png",
		"cell_count": 5,
		"position": Vector2(790, 920),
		"size": Vector2(280, 280),
		"visual_size": Vector2(280, 280),
		"visual_sizes": [Vector2(640, 640), Vector2(410, 410), Vector2(425, 425), Vector2(440, 440), Vector2(460, 460)],
		"visual_anchor": Vector2(0, 89),
		"cell_bottom_offsets": [Vector2(6.5, -10), Vector2(-0.5, 127), Vector2(0.5, 141), Vector2(-1, 169), Vector2(0, 200)],
		"visible_bounds": [
			Rect2(Vector2(173, 140), Vector2(179, 106)),
			Rect2(Vector2(55, 152), Vector2(401, 231)),
			Rect2(Vector2(69, 132), Vector2(375, 265)),
			Rect2(Vector2(69, 105), Vector2(372, 320)),
			Rect2(Vector2(19, 38), Vector2(474, 418))
		],
		"bubble_offset": Vector2(-630, -380),
		"currency": "fish",
		"costs": [8, 320, 1400, 12000],
		"unlock_levels": [5, 15, 33, 58],
		"bonus": "Improves stamina regen speed across all skills."
	},
	"mission": {
		"name": "Mission Sign",
		"sheet": "res://assets/content/hub/hub-mission-sign-tiers.png",
		"cell_count": 5,
		"position": Vector2(260, 1175),
		"size": Vector2(280, 280),
		"visual_size": Vector2(280, 280),
		"visual_anchor": Vector2(0, 97),
		"cell_bottom_offsets": [Vector2(1, 176), Vector2(0, 179), Vector2(1, 185), Vector2(-0.5, 195), Vector2(-0.5, 202)],
		"bubble_offset": Vector2(260, -380),
		"currency": "softwood",
		"cost_currencies": ["softwood", "softwood", "hardwood", "hardwood"],
		"costs": [35, 250, 70, 190],
		"unlock_levels": [10, 24, 45, 62],
		"bonus": "Prepares boosted task missions for a later update."
	}
}
const HUB_MODULE_ORDER := ["barn", "garden", "pond", "mission"]
const HUB_POSITION_ORDER := ["barn", "garden", "pond", "mission", "trophy"]
const HUB_BARN_FAILURE_GAP_FACTORS := [0.0, 0.10, 0.22, 0.38, 0.58]
const HUB_POND_REGEN_BONUS_BY_LEVEL := [0.0, 0.01, 0.03, 0.06, 0.10]
const HUB_MISSION_SLOT_COUNT_BY_LEVEL := [0, 1, 2, 3, 4]
const HUB_MISSION_STAMINA_REDUCTION_BY_LEVEL := [0.0, 0.30, 0.35, 0.42, 0.50]
const HUB_MISSION_XP_BONUS_BY_LEVEL := [0.0, 0.10, 0.14, 0.18, 0.25]
const HUB_MISSION_TIME_REDUCTION_BY_LEVEL := [0.0, 0.10, 0.14, 0.18, 0.25]
const HUB_MISSION_COOLDOWN_SECONDS_BY_LEVEL := [0, 300, 240, 180, 120]
const HUB_MISSION_REP_MIN_BY_LEVEL := [0, 50, 45, 40, 35]
const HUB_MISSION_REP_MAX_BY_LEVEL := [0, 150, 135, 120, 110]

var host
var hub_modules := {}
var hub_selected_module_id := "pond"
var hub_missions := []
var hub_mission_cooldown_until_unix := 0


func _init(host_node) -> void:
	host = host_node


func ensure_module_state(module_id: String) -> Dictionary:
	if not hub_modules.has(module_id) or typeof(hub_modules[module_id]) != TYPE_DICTIONARY:
		hub_modules[module_id] = {"level": 0, "building": false, "build_started_unix_msec": 0}
	var state := hub_modules[module_id] as Dictionary
	state["level"] = clampi(int(state.get("level", 0)), 0, HUB_MODULE_MAX_LEVEL)
	state["building"] = bool(state.get("building", false))
	state["build_started_unix_msec"] = maxi(0, int(state.get("build_started_unix_msec", state.get("build_started_msec", 0))))
	hub_modules[module_id] = state
	return state


func sync_trophy_level_from_thieving() -> void:
	var tier := best_trophy_tier()
	if tier > 0:
		var state := ensure_module_state("trophy")
		if int(state.get("level", 0)) < tier:
			state["level"] = tier
			state["building"] = false
			state["build_started_unix_msec"] = 0
			hub_modules["trophy"] = state
	if hub_selected_module_id == "trophy":
		host._hub_surface().hub_detail_open = true


func module_level(module_id: String) -> int:
	if module_id == "trophy":
		return maxi(int(ensure_module_state(module_id).get("level", 0)), best_trophy_tier())
	return int(ensure_module_state(module_id).get("level", 0))


func module_building(module_id: String) -> bool:
	return bool(ensure_module_state(module_id).get("building", false))


func module_build_progress(module_id: String) -> float:
	var state := ensure_module_state(module_id)
	if not bool(state.get("building", false)):
		return 0.0
	var started := int(state.get("build_started_unix_msec", 0))
	if started <= 0:
		return 0.0
	var elapsed := float(int(round(Time.get_unix_time_from_system() * 1000.0)) - started) / 1000.0
	return clampf(elapsed / HUB_BUILD_SECONDS, 0.0, 1.0)


func module_build_remaining_seconds(module_id: String) -> int:
	var state := ensure_module_state(module_id)
	if not bool(state.get("building", false)):
		return 0
	var started := int(state.get("build_started_unix_msec", 0))
	if started <= 0:
		return ceili(HUB_BUILD_SECONDS)
	var elapsed := float(int(round(Time.get_unix_time_from_system() * 1000.0)) - started) / 1000.0
	return maxi(0, ceili(HUB_BUILD_SECONDS - elapsed))


func complete_ready_builds() -> Array:
	var completed := []
	for module_id in HUB_MODULE_ORDER:
		var id := str(module_id)
		var state := ensure_module_state(id)
		if not bool(state.get("building", false)) or module_build_progress(id) < 1.0:
			continue
		state["building"] = false
		state["build_started_unix_msec"] = 0
		state["level"] = mini(HUB_MODULE_MAX_LEVEL, int(state.get("level", 0)) + 1)
		hub_modules[id] = state
		completed.append(id)
	return completed


func sync_missions() -> bool:
	var level := mission_level()
	var changed := false
	if level <= 0:
		if not hub_missions.is_empty() or hub_mission_cooldown_until_unix > 0:
			hub_missions.clear()
			hub_mission_cooldown_until_unix = 0
			changed = true
		return changed
	var cleaned := []
	for raw_mission in hub_missions:
		if typeof(raw_mission) != TYPE_DICTIONARY:
			changed = true
			continue
		var mission := normalized_mission(raw_mission as Dictionary)
		if mission.is_empty():
			changed = true
			continue
		cleaned.append(mission)
	if cleaned.size() != hub_missions.size():
		changed = true
	hub_missions = cleaned
	var slots := mission_slot_count()
	while hub_missions.size() > slots:
		hub_missions.pop_back()
		changed = true
	if hub_missions.size() >= slots or hub_mission_cooldown_until_unix > host._unix_now():
		return changed
	while hub_missions.size() < slots:
		var mission := roll_mission()
		if mission.is_empty():
			break
		hub_missions.append(mission)
		hub_mission_cooldown_until_unix = 0
		changed = true
	return changed


func normalized_mission(mission: Dictionary) -> Dictionary:
	var skill_id := str(mission.get("skill_id", ""))
	var action_id := str(mission.get("action_id", ""))
	var action: Dictionary = host._action_data(skill_id, action_id)
	if skill_id.is_empty() or action_id.is_empty() or action.is_empty():
		return {}
	if not host._activity_unlock_runtime()._is_action_unlocked(skill_id, action) or host._passive_modules_runtime().is_passive_action(action):
		return {}
	var target := maxi(1, int(mission.get("target", mission.get("count", 1))))
	var remaining := clampi(int(mission.get("remaining", target)), 1, target)
	return {
		"skill_id": skill_id,
		"action_id": ModuleUiRuntime.canonical_action_id(skill_id, action_id, host.FISHING_ACTION_ID_ALIASES),
		"target": target,
		"remaining": remaining,
		"assigned_unix": maxi(0, int(mission.get("assigned_unix", host._unix_now())))
	}


func roll_mission() -> Dictionary:
	var existing_keys := {}
	for raw_mission in hub_missions:
		var mission := raw_mission as Dictionary
		existing_keys[host._action_key(str(mission.get("skill_id", "")), str(mission.get("action_id", "")))] = true
	var choices := mission_eligible_actions(existing_keys)
	if choices.is_empty():
		return {}
	var choice := choices[randi_range(0, choices.size() - 1)] as Dictionary
	var target := randi_range(mission_rep_min(), mission_rep_max())
	return {
		"skill_id": str(choice.get("skill_id", "")),
		"action_id": str(choice.get("action_id", "")),
		"target": target,
		"remaining": target,
		"assigned_unix": host._unix_now(),
		"level": mission_level()
	}


func mission_eligible_actions(existing_keys: Dictionary) -> Array:
	var choices := []
	for raw_def in host.skill_defs:
		var skill_id := str((raw_def as Dictionary).get("id", ""))
		if skill_id.is_empty() or host._fishing_rework_active_for_skill(skill_id):
			continue
		for raw_action in host.actions_by_skill.get(skill_id, []):
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty() or host._passive_modules_runtime().is_passive_action(action):
				continue
			if existing_keys.has(host._action_key(skill_id, action_id)):
				continue
			if host._activity_unlock_runtime()._is_action_unlocked(skill_id, action):
				choices.append({"skill_id": skill_id, "action_id": action_id})
	return choices


func mission_level() -> int:
	if not host._navigation_shell()._hub_unlocked():
		return 0
	return clampi(module_level("mission"), 0, HUB_MODULE_MAX_LEVEL)


func mission_slot_count() -> int:
	return int(HUB_MISSION_SLOT_COUNT_BY_LEVEL[mission_level()])


func mission_max_slot_count() -> int:
	var max_slots := 0
	for raw_count in HUB_MISSION_SLOT_COUNT_BY_LEVEL:
		max_slots = maxi(max_slots, int(raw_count))
	return max_slots


func mission_required_level_for_slot(slot_index: int) -> int:
	for level in range(HUB_MISSION_SLOT_COUNT_BY_LEVEL.size()):
		if int(HUB_MISSION_SLOT_COUNT_BY_LEVEL[level]) > slot_index:
			return level
	return HUB_MISSION_SLOT_COUNT_BY_LEVEL.size() - 1


func mission_stamina_reduction() -> float:
	return float(HUB_MISSION_STAMINA_REDUCTION_BY_LEVEL[mission_level()])


func mission_xp_bonus() -> float:
	return float(HUB_MISSION_XP_BONUS_BY_LEVEL[mission_level()])


func mission_time_reduction() -> float:
	return float(HUB_MISSION_TIME_REDUCTION_BY_LEVEL[mission_level()])


func mission_cooldown_seconds() -> int:
	return int(HUB_MISSION_COOLDOWN_SECONDS_BY_LEVEL[mission_level()])


func mission_rep_min() -> int:
	return int(HUB_MISSION_REP_MIN_BY_LEVEL[mission_level()])


func mission_rep_max() -> int:
	return int(HUB_MISSION_REP_MAX_BY_LEVEL[mission_level()])


func mission_for_action(skill_id: String, action_id: String) -> Dictionary:
	var key: String = host._action_key(skill_id, action_id)
	for raw_mission in hub_missions:
		var mission := raw_mission as Dictionary
		if host._action_key(str(mission.get("skill_id", "")), str(mission.get("action_id", ""))) == key:
			return mission
	return {}


func mission_bonus_applies(skill_id: String, action: Dictionary) -> bool:
	return mission_level() > 0 and not mission_for_action(skill_id, str(action.get("id", ""))).is_empty()


func record_mission_action_completion(skill_id: String, action_id: String) -> bool:
	var key: String = host._action_key(skill_id, action_id)
	for i in range(hub_missions.size()):
		var mission := hub_missions[i] as Dictionary
		if host._action_key(str(mission.get("skill_id", "")), str(mission.get("action_id", ""))) != key:
			continue
		var remaining := maxi(0, int(mission.get("remaining", 0)) - 1)
		if remaining <= 0:
			hub_missions.remove_at(i)
			hub_mission_cooldown_until_unix = host._unix_now() + mission_cooldown_seconds()
			host._hub_surface()._show_hub_mission_completion_ceremony(skill_id, action_id)
		else:
			mission["remaining"] = remaining
			hub_missions[i] = mission
		return true
	return false


func next_trophy_def() -> Dictionary:
	for raw_heist in host.thieving_state.HEIST_DEFS:
		var heist := raw_heist as Dictionary
		var heist_id := str(heist.get("id", ""))
		if not heist_id.is_empty() and not host.thieving_state.trophy_stolen(heist_id):
			return heist
	return {}


func best_trophy_tier() -> int:
	var trophy_def := best_trophy_def()
	return 0 if trophy_def.is_empty() else int(trophy_def.get("tier", 0))


func best_trophy_def() -> Dictionary:
	var best_def := {}
	var best_tier := 0
	for def in host.thieving_state.HEIST_DEFS:
		var trophy_id := str((def as Dictionary).get("id", ""))
		var state = host.thieving_state.trophies.get(trophy_id, {})
		var stolen := bool((state as Dictionary).get("stolen", false)) if typeof(state) == TYPE_DICTIONARY else bool(state)
		var tier := int((def as Dictionary).get("tier", 0))
		if stolen and tier >= best_tier:
			best_def = def as Dictionary
			best_tier = tier
	return best_def


func trophy_success_bonus() -> float:
	var tier := clampi(best_trophy_tier(), 0, HUB_TROPHY_SUCCESS_BONUS_BY_TIER.size() - 1)
	return float(HUB_TROPHY_SUCCESS_BONUS_BY_TIER[tier])


func module_wood_currency_for_level(module_id: String, level: int) -> String:
	if not HUB_MODULE_DEFS.has(module_id):
		return "softwood"
	var def := HUB_MODULE_DEFS[module_id] as Dictionary
	var cost_currencies := def.get("cost_currencies", []) as Array
	if level >= 0 and level < cost_currencies.size():
		var tier_currency: String = host.material_runtime.normalize_id(str(cost_currencies[level]))
		if host.MAT_COLLECTION_DEFS.has(tier_currency):
			return tier_currency
	var base_currency := str(def.get("currency", "softwood"))
	if base_currency == "mixed":
		return "softwood"
	var normalized_currency: String = host.material_runtime.normalize_id(base_currency)
	return normalized_currency if host.MAT_COLLECTION_DEFS.has(normalized_currency) else "softwood"


func can_afford_module(module_id: String) -> bool:
	if not module_next_level_unlocked(module_id):
		return false
	var level := module_level(module_id)
	if level >= HUB_MODULE_MAX_LEVEL:
		return false
	var cost := int((HUB_MODULE_DEFS[module_id] as Dictionary).get("costs", [])[level])
	if module_id == "pond":
		return host.fishing_runtime.fish_currency >= float(cost)
	var wood_currency := module_wood_currency_for_level(module_id, level)
	if module_id == "garden":
		var fish_costs := (HUB_MODULE_DEFS[module_id] as Dictionary).get("fish_costs", []) as Array
		return host.material_runtime.amount(wood_currency) >= float(cost) and host.fishing_runtime.fish_currency >= float(int(fish_costs[level]))
	return host.material_runtime.amount(wood_currency) >= float(cost)


func module_next_unlock_level(module_id: String) -> int:
	if not HUB_MODULE_DEFS.has(module_id):
		return 999999
	var level := module_level(module_id)
	if level >= HUB_MODULE_MAX_LEVEL:
		return 999999
	var unlocks := (HUB_MODULE_DEFS[module_id] as Dictionary).get("unlock_levels", []) as Array
	return int(unlocks[level]) if level >= 0 and level < unlocks.size() else 0


func module_next_level_unlocked(module_id: String) -> bool:
	return SkillState.host_skill_level(host, "build") >= module_next_unlock_level(module_id)


func upgrade_module(module_id: String) -> Dictionary:
	if not HUB_MODULE_DEFS.has(module_id):
		return {}
	var state := ensure_module_state(module_id)
	if bool(state.get("building", false)) or int(state.get("level", 0)) >= HUB_MODULE_MAX_LEVEL:
		return {}
	if not module_next_level_unlocked(module_id) or not can_afford_module(module_id):
		return {"blocked": true}
	var level := int(state.get("level", 0))
	var cost := int((HUB_MODULE_DEFS[module_id] as Dictionary).get("costs", [])[level])
	var wood_currency := module_wood_currency_for_level(module_id, level)
	var spent_logs := 0
	var spent_fish := 0
	if module_id == "pond":
		host.fishing_runtime.fish_currency = maxf(0.0, host.fishing_runtime.fish_currency - float(cost))
		spent_fish = cost
	elif module_id == "garden":
		var fish_cost := int((HUB_MODULE_DEFS[module_id] as Dictionary).get("fish_costs", [])[level])
		host.material_runtime.spend_amount(wood_currency, float(cost))
		host.fishing_runtime.fish_currency = maxf(0.0, host.fishing_runtime.fish_currency - float(fish_cost))
		spent_logs = cost
		spent_fish = fish_cost
	else:
		host.material_runtime.spend_amount(wood_currency, float(cost))
		spent_logs = cost
	state["building"] = true
	state["build_started_unix_msec"] = int(round(Time.get_unix_time_from_system() * 1000.0))
	hub_modules[module_id] = state
	return {"spent_logs": spent_logs, "spent_fish": spent_fish}


func barn_failure_factor() -> float:
	var level := clampi(module_level("barn"), 0, HUB_MODULE_MAX_LEVEL)
	return float(HUB_BARN_FAILURE_GAP_FACTORS[level])


func pond_regen_bonus() -> float:
	var level := clampi(module_level("pond"), 0, HUB_MODULE_MAX_LEVEL)
	return float(HUB_POND_REGEN_BONUS_BY_LEVEL[level])


func offline_cap_seconds() -> int:
	return host.MAX_OFFLINE_SECONDS + module_level("garden") * HUB_OFFLINE_SECONDS_PER_GARDEN_LEVEL


func modules_for_save() -> Dictionary:
	return normalized_modules(hub_modules)


func normalized_modules(loaded_modules: Variant) -> Dictionary:
	return SaveStateNormalizers.normalized_hub_modules(loaded_modules, HUB_MODULE_DEFS, HUB_MODULE_MAX_LEVEL)


func selected_module_id_for_save() -> String:
	return SaveStateNormalizers.valid_dictionary_key(hub_selected_module_id, HUB_MODULE_DEFS, "pond")


func restore_selected_module_id(data: Dictionary) -> void:
	hub_selected_module_id = SaveStateNormalizers.valid_dictionary_key(data.get("hub_selected_module_id", hub_selected_module_id), HUB_MODULE_DEFS, "pond")


func restore_mission_cooldown(data: Dictionary) -> void:
	hub_mission_cooldown_until_unix = SaveStateNormalizers.nonnegative_int(data, "hub_mission_cooldown_until_unix")


func restore_modules(loaded_modules: Variant) -> void:
	hub_modules = normalized_modules(loaded_modules)


func missions_for_save() -> Array:
	return normalized_missions(hub_missions)


func restore_missions(loaded_missions: Variant) -> void:
	hub_missions = normalized_missions(loaded_missions)


func normalized_missions(loaded_missions: Variant) -> Array:
	return SaveStateNormalizers.normalized_hub_missions(loaded_missions, Callable(self, "normalized_mission"))


func module_positions_for_save() -> Dictionary:
	var normalized := normalized_module_positions(host._hub_surface().hub_module_positions)
	var saved := {}
	for raw_module_id in HUB_POSITION_ORDER:
		var module_id := str(raw_module_id)
		if normalized.has(module_id):
			var module_position := normalized.get(module_id, host._hub_surface()._hub_default_module_center(module_id)) as Vector2
			saved[module_id] = {"x": module_position.x, "y": module_position.y}
	return saved


func restore_module_positions(raw_positions: Variant, pre_migration_layout := false) -> void:
	host._hub_surface().hub_module_positions = normalized_module_positions(raw_positions, pre_migration_layout)


func normalized_module_positions(raw_positions: Variant, pre_migration_layout := false) -> Dictionary:
	var normalized := {}
	if typeof(raw_positions) != TYPE_DICTIONARY:
		return normalized
	for raw_module_id in (raw_positions as Dictionary).keys():
		var module_id := str(raw_module_id)
		if not can_store_position(module_id):
			continue
		var fallback: Vector2 = host._hub_surface()._hub_default_module_center(module_id)
		var raw_position: Variant = (raw_positions as Dictionary).get(raw_module_id)
		var module_position: Vector2 = fallback
		if raw_position is Vector2:
			module_position = raw_position as Vector2
		elif typeof(raw_position) == TYPE_DICTIONARY:
			var raw_dict := raw_position as Dictionary
			module_position = Vector2(float(raw_dict.get("x", fallback.x)), float(raw_dict.get("y", fallback.y)))
		if pre_migration_layout:
			module_position *= 0.5
		normalized[module_id] = host._hub_surface()._clamp_hub_module_center(module_position)
	return normalized


func validate_module_positions() -> void:
	var clean := {}
	for raw_module_id in host._hub_surface().hub_module_positions.keys():
		var module_id := str(raw_module_id)
		var raw_position = host._hub_surface().hub_module_positions.get(raw_module_id)
		if can_store_position(module_id) and raw_position is Vector2:
			clean[module_id] = host._hub_surface()._clamp_hub_module_center(raw_position as Vector2)
	host._hub_surface().hub_module_positions = clean


func can_store_position(module_id: String) -> bool:
	return HUB_MODULE_DEFS.has(module_id) or module_id == "trophy"
