class_name SkillState

const SKILL_XP_CURVE_BASE := 22.0
const SKILL_XP_CURVE_EXPONENT := 2.08
const SKILL_XP_STRETCH_START_LEVEL := 10
const SKILL_XP_STRETCH_TARGET_LEVEL := 99
const SKILL_XP_STRETCH_TARGET_MULTIPLIER := 4.0
const SKILL_XP_STRETCH_POWER := 2.0
const BASE_MAX_STAMINA := 30
const STAMINA_REGEN_SECONDS := 12.0


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


static func stamina_int(stamina: Dictionary, skill_id: String, max_stamina: Callable) -> int:
	return clampi(int(floor(stamina_value(stamina, skill_id, max_stamina))), 0, int(max_stamina.call(skill_id)))


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


static func skill_level_for_xp(xp_total: int) -> int:
	var level := 1
	while level < 99 and xp_total >= xp_for_level(level + 1):
		level += 1
	return level


static func _skill_ids(skill_defs: Array) -> Array:
	var ids := []
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if not skill_id.is_empty():
			ids.append(skill_id)
	return ids
