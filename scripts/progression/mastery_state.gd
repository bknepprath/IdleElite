class_name MasteryState

const MEDAL_NAMES := [
	"Bronze",
	"Silver",
	"Gold",
	"Platinum",
	"Sapphire",
	"Emerald",
	"Ruby",
	"Diamond",
	"Demonic",
	"Heavenly",
	"Elite Bronze",
	"Elite Silver",
	"Elite Gold",
	"Elite Platinum",
	"Elite Sapphire",
	"Elite Emerald",
	"Elite Ruby",
	"Elite Diamond",
	"Elite Demonic",
	"Elite Heavenly"
]
const MEDAL_ACCENTS := [
	Color("#b77938"),
	Color("#a9adb7"),
	Color("#f4bf35"),
	Color("#a7d6e8"),
	Color("#3aa0ff"),
	Color("#35d86d"),
	Color("#e84d4d"),
	Color("#8fdcff"),
	Color("#9b54ff"),
	Color("#fff2a8"),
	Color("#c06d2c"),
	Color("#b8bec8"),
	Color("#ffd32f"),
	Color("#f1ebe0"),
	Color("#1f82ff"),
	Color("#22cc58"),
	Color("#ff2430"),
	Color("#aeeeff"),
	Color("#8a2cff"),
	Color("#fff0b8")
]
const GLOBAL_MEDAL_BUFFS := [
	{"level": 1, "stat": "max_stamina", "amount": 1.0},
	{"level": 2, "stat": "xp_mult", "amount": 0.02},
	{"level": 3, "stat": "speed_mult", "amount": 0.02},
	{"level": 4, "stat": "success_bonus", "amount": 1.0},
	{"level": 5, "stat": "max_stamina", "amount": 1.0},
	{"level": 6, "stat": "xp_mult", "amount": 0.03},
	{"level": 7, "stat": "speed_mult", "amount": 0.03},
	{"level": 8, "stat": "success_bonus", "amount": 1.0},
	{"level": 9, "stat": "max_stamina", "amount": 2.0},
	{"level": 10, "stat": "xp_mult", "amount": 0.05},
	{"level": 11, "stat": "max_stamina", "amount": 2.0},
	{"level": 12, "stat": "xp_mult", "amount": 0.05},
	{"level": 13, "stat": "speed_mult", "amount": 0.04},
	{"level": 14, "stat": "success_bonus", "amount": 1.0},
	{"level": 15, "stat": "max_stamina", "amount": 2.0},
	{"level": 16, "stat": "xp_mult", "amount": 0.05},
	{"level": 17, "stat": "speed_mult", "amount": 0.04},
	{"level": 18, "stat": "success_bonus", "amount": 1.0},
	{"level": 19, "stat": "max_stamina", "amount": 3.0},
	{"level": 20, "stat": "xp_mult", "amount": 0.08}
]


static func medal_name(level: int) -> String:
	if level <= 0:
		return "Unranked"
	return str(MEDAL_NAMES[clampi(level, 1, MEDAL_NAMES.size()) - 1])


static func xp_reward(_action: Dictionary) -> float:
	return 1.0


static func action_has_mastery(host, action: Dictionary) -> bool:
	if action.is_empty():
		return false
	return not host._is_event_action(action) and not host._passive_modules_runtime().is_passive_action(action) and not host._convergence_runtime()._is_convergence_action(action)


static func reward_for_action(host, skill_id: String, action_id: String, action: Dictionary) -> float:
	if not action_has_mastery(host, action):
		return 0.0
	if not host._onboarding_runtime()._onboarding_mastery_rewards_allowed(skill_id):
		return 0.0
	if is_maxed(host.mastery, host._action_key(skill_id, action_id), host.MASTERY_MAX_LEVEL):
		return 0.0
	return xp_reward(action)


static func add_host_xp(host, skill_id: String, action_id: String, amount: float) -> void:
	var key: String = host._action_key(skill_id, action_id)
	if amount <= 0.0 or is_maxed(host.mastery, key, host.MASTERY_MAX_LEVEL):
		return
	if not host._onboarding_runtime()._onboarding_mastery_rewards_allowed(skill_id):
		return
	_refresh_host_after_level_change(host, add_xp(host.mastery, key, amount, host.MASTERY_MAX_LEVEL))


static func recalculate_host(host, key: String) -> void:
	_refresh_host_after_level_change(host, recalculate_entry(host.mastery, key, host.MASTERY_MAX_LEVEL))


static func xp_for_level(level: int) -> int:
	if level <= 0:
		return 0
	if level <= 3:
		return _legacy_xp_for_level(level)
	var total := _legacy_xp_for_level(3)
	for medal_level in range(4, level + 1):
		var old_gap := _legacy_xp_for_level(medal_level) - _legacy_xp_for_level(medal_level - 1)
		var gap_multiplier := 1.0 + 0.08 * float(medal_level - 3)
		var elite_entry_jump := 0
		if medal_level > 10:
			gap_multiplier = (1.65 + 0.12 * float(medal_level - 11)) * pow(float(medal_level) / 11.0, 0.12)
			elite_entry_jump = 900 if medal_level == 11 else 0
		total += int(round(float(old_gap) * gap_multiplier)) + elite_entry_jump
	return total


static func _legacy_xp_for_level(level: int) -> int:
	return int(round(18.0 * pow(float(level), 2.05)))


static func level(mastery: Dictionary, key: String) -> int:
	return int(mastery.get(key, {}).get("level", 0))


static func is_maxed(mastery: Dictionary, key: String, max_level: int) -> bool:
	return level(mastery, key) >= max_level


static func progress_pct(mastery: Dictionary, key: String, max_level: int) -> float:
	var current_level := level(mastery, key)
	if current_level >= max_level:
		return 100.0
	var xp_total := float(mastery.get(key, {}).get("xp", 0))
	var start := xp_for_level(current_level)
	var end := xp_for_level(current_level + 1)
	var needed := maxi(1, end - start)
	return clampf(float(xp_total - start) / float(needed) * 100.0, 0.0, 100.0)


static func would_reward_level_up(mastery: Dictionary, key: String, amount: float, max_level: int) -> bool:
	if amount <= 0.0:
		return false
	var current_level := level(mastery, key)
	if current_level >= max_level:
		return false
	var xp_total := float(mastery.get(key, {}).get("xp", 0))
	return xp_total + amount >= float(xp_for_level(current_level + 1))


static func add_xp(mastery: Dictionary, key: String, amount: float, max_level: int) -> Dictionary:
	if amount <= 0.0 or is_maxed(mastery, key, max_level):
		return {"level_changed": false}
	if not mastery.has(key):
		mastery[key] = {"xp": 0, "level": 0}
	mastery[key]["xp"] = float(mastery[key].get("xp", 0)) + amount
	return recalculate_entry(mastery, key, max_level)


static func recalculate_entry(mastery: Dictionary, key: String, max_level: int) -> Dictionary:
	if not mastery.has(key):
		return {"level_changed": false}
	var old_level := level(mastery, key)
	var entry := _entry_for_xp(float(mastery[key].get("xp", 0)), max_level, false)
	mastery[key]["level"] = entry["level"]
	mastery[key]["xp"] = entry["xp"]
	return {
		"level_changed": int(entry["level"]) != old_level,
		"old_level": old_level,
		"level": int(entry["level"]),
		"xp": float(entry["xp"])
	}


static func for_save(mastery: Dictionary, canonical_key: Callable, max_level: int) -> Dictionary:
	return _normalized_entries(mastery, canonical_key, max_level)


static func restored_from_save(loaded_mastery: Variant, canonical_key: Callable, max_level: int) -> Dictionary:
	return _normalized_entries(loaded_mastery, canonical_key, max_level)


static func _normalized_entries(raw_mastery: Variant, canonical_key: Callable, max_level: int) -> Dictionary:
	var normalized := {}
	if typeof(raw_mastery) != TYPE_DICTIONARY:
		return normalized
	var source := raw_mastery as Dictionary
	for raw_key in source.keys():
		var key := str(canonical_key.call(str(raw_key)))
		if key.is_empty():
			continue
		var entry = source.get(raw_key, {})
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var xp := maxi(0, int((entry as Dictionary).get("xp", 0)))
		var existing = normalized.get(key, null)
		if typeof(existing) == TYPE_DICTIONARY:
			xp = maxi(xp, int((existing as Dictionary).get("xp", 0)))
		normalized[key] = _entry_for_xp(float(xp), max_level, true)
	return normalized


static func _entry_for_xp(xp: float, max_level: int, clamp_to_zero: bool) -> Dictionary:
	var xp_total := maxf(0.0, xp) if clamp_to_zero else xp
	var current_level := 0
	while current_level < max_level and xp_total >= float(xp_for_level(current_level + 1)):
		current_level += 1
	return {
		"xp": minf(xp_total, float(xp_for_level(max_level))),
		"level": current_level
	}


static func _refresh_host_after_level_change(host, result: Dictionary) -> void:
	if bool(result.get("level_changed", false)):
		SkillState.invalidate_stat_caches(host)
		host.ui_static_refresh_elapsed = host.UI_STATIC_REFRESH_INTERVAL_SECONDS
		host._navigation_shell()._refresh_shop_nav_unlock_state()
