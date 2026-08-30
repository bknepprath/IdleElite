class_name SkillState

const GameFormatting = preload("res://scripts/core/formatting.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const NavigationShell = preload("res://scripts/ui/navigation_shell.gd")
const SKILL_XP_CURVE_BASE := 22.0
const SKILL_XP_CURVE_EXPONENT := 2.08
const SKILL_XP_STRETCH_START_LEVEL := 10
const SKILL_XP_STRETCH_TARGET_LEVEL := 99
const SKILL_XP_STRETCH_TARGET_MULTIPLIER := 4.0
const SKILL_XP_STRETCH_POWER := 2.0
const BASE_MAX_STAMINA := 30
const STAMINA_REGEN_SECONDS := 12.0
const HONEY_STAMINA_REGEN_MULT := 2.0
const HONEY_STAMINA_SECONDS_PER_CONSUMPTION := 10.0
const SKILL_SHORT_CODES := {
	"fight": "FGT",
	"thieving": "THV",
	"build": "BLD",
	"woodcutting": "WOD",
	"fishing": "FSH"
}

static var max_stamina_cache_valid := false
static var cached_max_stamina := BASE_MAX_STAMINA
static var cached_max_stamina_by_skill := {}


static func skill_level(skills: Dictionary, skill_id: String) -> int:
	return int(skills.get(skill_id, {}).get("level", 1))


static func host_skill_level(host, skill_id: String) -> int:
	return skill_level(host.skills, skill_id)


static func global_level(skills: Dictionary) -> int:
	var total := 0
	for skill_id in skills.keys():
		total += skill_level(skills, str(skill_id))
	return total


static func max_stamina(host, skill_id: String = "") -> int:
	if not max_stamina_cache_valid:
		cached_max_stamina = BASE_MAX_STAMINA + int(floor(float(global_level(host.skills)) / 10.0)) + int(round(AchievementState.global_reward_bonus(host, "max_stamina")))
		cached_max_stamina_by_skill.clear()
		max_stamina_cache_valid = true
	if skill_id.is_empty():
		return cached_max_stamina
	if cached_max_stamina_by_skill.has(skill_id):
		return int(cached_max_stamina_by_skill[skill_id])
	var skill_max := cached_max_stamina + AchievementState.skill_medal_max_stamina_bonus(host, skill_id)
	cached_max_stamina_by_skill[skill_id] = skill_max
	return skill_max


static func host_max_stamina(skill_id: String, host) -> int:
	return max_stamina(host, skill_id)


static func invalidate_stat_caches(host) -> void:
	host._action_runtime().invalidate_stat_cache()
	invalidate_max_stamina_cache()
	host.activity_medal_buff_total_cache.clear()
	host.reward_bonus_cache.clear()


static func invalidate_max_stamina_cache() -> void:
	max_stamina_cache_valid = false
	cached_max_stamina_by_skill.clear()


static func skill_name(skill_defs: Array, skill_id: String) -> String:
	for skill_def in skill_defs:
		if str((skill_def as Dictionary).get("id", "")) == skill_id:
			return str((skill_def as Dictionary).get("name", ""))
	return skill_id.capitalize()


static func skill_short_code(skill_defs: Array, skill_id: String) -> String:
	if SKILL_SHORT_CODES.has(skill_id):
		return str(SKILL_SHORT_CODES[skill_id])
	var skill_display_name := skill_name(skill_defs, skill_id).strip_edges()
	if skill_display_name.is_empty():
		return "XP"
	return skill_display_name.substr(0, mini(3, skill_display_name.length())).to_upper()


static func skill_detail_title_font_size(skill_id: String, default_size: int, woodcutting_size: int) -> int:
	if skill_id == "woodcutting":
		return woodcutting_size
	return default_size


static func skills_for_save(skill_defs: Array, skills: Dictionary) -> Dictionary:
	var normalized := {}
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if skill_id.is_empty():
			continue
		var skill_state = skills.get(skill_id, {})
		var xp := 0
		if typeof(skill_state) == TYPE_DICTIONARY:
			xp = maxi(0, int((skill_state as Dictionary).get("xp", 0)))
		normalized[skill_id] = {
			"xp": xp,
			"level": skill_level_for_xp(xp)
		}
	return normalized


static func has_skill_id(skill_defs: Array, skill_id: String) -> bool:
	if skill_id.is_empty():
		return false
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		if str(skill_def.get("id", "")) == skill_id:
			return true
	return false


static func stamina_for_save(skill_defs: Array, stamina: Dictionary, max_stamina: Callable) -> Dictionary:
	var normalized := {}
	for skill_id in _skill_ids(skill_defs):
		normalized[skill_id] = stamina_value(stamina, skill_id, max_stamina)
	return normalized


static func stamina_bank_for_save(skill_defs: Array, stamina: Dictionary, stamina_bank: Dictionary, max_stamina: Callable) -> Dictionary:
	var normalized := {}
	for skill_id in _skill_ids(skill_defs):
		if stamina_value(stamina, skill_id, max_stamina) >= float(max_stamina.call(skill_id)) - 0.0001:
			normalized[skill_id] = 0.0
		else:
			normalized[skill_id] = clampf(float(stamina_bank.get(skill_id, 0.0)), 0.0, STAMINA_REGEN_SECONDS)
	return normalized


static func stamina_value(stamina: Dictionary, skill_id: String, max_stamina: Callable) -> float:
	var maximum := int(max_stamina.call(skill_id))
	return clampf(float(stamina.get(skill_id, maximum)), 0.0, float(maximum))


static func host_stamina_value(skill_id: String, host) -> float:
	return stamina_value(host.stamina, skill_id, Callable(SkillState, "host_max_stamina").bind(host))


static func stamina_int(stamina: Dictionary, skill_id: String, max_stamina: Callable) -> int:
	return clampi(int(floor(stamina_value(stamina, skill_id, max_stamina))), 0, int(max_stamina.call(skill_id)))


static func host_stamina_int(skill_id: String, host) -> int:
	return stamina_int(host.stamina, skill_id, Callable(SkillState, "host_max_stamina").bind(host))


static func stamina_fraction(stamina: Dictionary, skill_id: String, max_stamina: Callable) -> float:
	var value := stamina_value(stamina, skill_id, max_stamina)
	if value >= float(max_stamina.call(skill_id)) - 0.0001:
		return 1.0
	return clampf(value - floorf(value), 0.0, 1.0)


static func stamina_regen_fraction(stamina: Dictionary, stamina_bank: Dictionary, skill_id: String, max_stamina: Callable) -> float:
	if stamina_value(stamina, skill_id, max_stamina) >= float(max_stamina.call(skill_id)) - 0.0001:
		return 1.0
	return clampf(float(stamina_bank.get(skill_id, 0.0)) / STAMINA_REGEN_SECONDS, 0.0, 1.0)


static func sync_stamina_bank(stamina: Dictionary, stamina_bank: Dictionary, skill_id: String, max_stamina: Callable) -> void:
	if stamina_value(stamina, skill_id, max_stamina) >= float(max_stamina.call(skill_id)) - 0.0001:
		stamina[skill_id] = float(max_stamina.call(skill_id))
		stamina_bank[skill_id] = 0.0
		return
	stamina_bank[skill_id] = clampf(float(stamina_bank.get(skill_id, 0.0)), 0.0, STAMINA_REGEN_SECONDS)


static func host_sync_stamina_bank(skill_id: String, host) -> void:
	sync_stamina_bank(host.stamina, host.stamina_bank, skill_id, Callable(SkillState, "host_max_stamina").bind(host))


static func stamina_regen_needs_honey(skill_defs: Array, stamina: Dictionary, max_stamina: Callable, excluded_skill_id := "") -> bool:
	for raw_def in skill_defs:
		var skill_id := str((raw_def as Dictionary).get("id", ""))
		if skill_id.is_empty() or skill_id == excluded_skill_id:
			continue
		if stamina_value(stamina, skill_id, max_stamina) < float(max_stamina.call(skill_id)) - 0.0001:
			return true
	return false


static func honey_adjusted_stamina_regen_seconds(seconds: float, skill_defs: Array, stamina: Dictionary, max_stamina: Callable, excluded_skill_id: String, honey_seconds_remaining: float, honey_available: Callable, consume_honey: Callable) -> Dictionary:
	if seconds <= 0.0 or not stamina_regen_needs_honey(skill_defs, stamina, max_stamina, excluded_skill_id):
		return {"seconds": seconds, "honey_seconds_remaining": honey_seconds_remaining}
	var remaining_seconds := seconds
	var boosted_seconds := 0.0
	while remaining_seconds > 0.0001:
		if honey_seconds_remaining <= 0.0001:
			if not bool(honey_available.call()) or not bool(consume_honey.call()):
				break
			honey_seconds_remaining = HONEY_STAMINA_SECONDS_PER_CONSUMPTION
		var consumed_seconds := minf(remaining_seconds, honey_seconds_remaining)
		honey_seconds_remaining = maxf(0.0, honey_seconds_remaining - consumed_seconds)
		boosted_seconds += consumed_seconds
		remaining_seconds -= consumed_seconds
	return {
		"seconds": boosted_seconds * HONEY_STAMINA_REGEN_MULT + remaining_seconds,
		"honey_seconds_remaining": honey_seconds_remaining
	}


static func spend_action_stamina(stamina: Dictionary, stamina_bank: Dictionary, skill_id: String, stamina_cost: float, max_stamina: Callable) -> bool:
	if skill_id.is_empty() or stamina_cost <= 0.0:
		return true
	if stamina_value(stamina, skill_id, max_stamina) + 0.0001 < stamina_cost:
		return false
	stamina[skill_id] = maxf(0.0, stamina_value(stamina, skill_id, max_stamina) - stamina_cost)
	sync_stamina_bank(stamina, stamina_bank, skill_id, max_stamina)
	return true


static func restore_action_stamina(stamina: Dictionary, stamina_bank: Dictionary, skill_id: String, amount: float, max_stamina: Callable) -> float:
	if skill_id.is_empty() or amount <= 0.0 or not stamina.has(skill_id):
		return 0.0
	var before := stamina_value(stamina, skill_id, max_stamina)
	var restored := minf(float(max_stamina.call(skill_id)), before + amount)
	stamina[skill_id] = restored
	sync_stamina_bank(stamina, stamina_bank, skill_id, max_stamina)
	return maxf(0.0, restored - before)


static func honey_stamina_regen_multiplier(player_has_stamina_honey: bool) -> float:
	return HONEY_STAMINA_REGEN_MULT if player_has_stamina_honey else 1.0


static func xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	var base_xp := SKILL_XP_CURVE_BASE * pow(float(level - 1), SKILL_XP_CURVE_EXPONENT)
	return int(round(base_xp * xp_curve_stretch_for_level(level)))


static func xp_curve_stretch_for_level(level: int) -> float:
	if level <= SKILL_XP_STRETCH_START_LEVEL:
		return 1.0
	var stretch_range := maxi(1, SKILL_XP_STRETCH_TARGET_LEVEL - SKILL_XP_STRETCH_START_LEVEL)
	var progress := clampf(float(level - SKILL_XP_STRETCH_START_LEVEL) / float(stretch_range), 0.0, 1.0)
	return 1.0 + (SKILL_XP_STRETCH_TARGET_MULTIPLIER - 1.0) * pow(progress, SKILL_XP_STRETCH_POWER)


static func xp_progress(skills: Dictionary, skill_id: String, level: int) -> Dictionary:
	var xp_total := int(skills.get(skill_id, {}).get("xp", 0))
	var start := xp_for_level(level)
	var end := xp_for_level(level + 1)
	var current := maxi(0, xp_total)
	var needed := maxi(1, end)
	var level_current := clampi(xp_total - start, 0, end - start)
	var level_needed := maxi(1, end - start)
	return {"current": current, "needed": needed, "pct": clampf(float(level_current) / float(level_needed) * 100.0, 0.0, 100.0)}


static func level_xp_text(skills: Dictionary, skill_id: String, level: int) -> String:
	var xp := xp_progress(skills, skill_id, level)
	if level >= 99:
		return "Lv %s · %s XP" % [
			level,
			GameFormatting.compact_number(float(xp["current"]))
		]
	return "Lv %s · %s/%s" % [
		level,
		GameFormatting.compact_number(float(xp["current"])),
		GameFormatting.compact_number(float(xp["needed"]))
	]


static func skill_level_for_xp(xp_total: int) -> int:
	var level := 1
	while level < 99 and xp_total >= xp_for_level(level + 1):
		level += 1
	return level


static func recalculate_level(host, skill_id: String, apply_unlocks := true) -> void:
	var xp_total := int(host.skills[skill_id]["xp"])
	var old_level := int(host.skills[skill_id].get("level", 1))
	var level := skill_level_for_xp(xp_total)
	host.skills[skill_id]["level"] = level
	if level > old_level and apply_unlocks:
		invalidate_stat_caches(host)
		var ready_by_skill: Dictionary = host._activity_unlock_runtime()._ready_actions_for_level_gain(skill_id, old_level, level)
		host._activity_unlock_runtime()._queue_activity_unlock_readiness(skill_id, old_level, level, ready_by_skill)
		if host.startup_initialized:
			host._navigation_shell()._refresh_hero_nav_unlock_state()
			if skill_id == "build" and old_level < NavigationShell.HUB_UNLOCK_BUILD_LEVEL and level >= NavigationShell.HUB_UNLOCK_BUILD_LEVEL:
				host._navigation_shell()._sync_hub_nav_button(false)
			host._reward_feedback_surface()._show_visible_skill_level_up_float(skill_id)
			host._audio_director()._play_level_up_sfx()


static func _skill_ids(skill_defs: Array) -> Array:
	var ids := []
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if not skill_id.is_empty():
			ids.append(skill_id)
	return ids
