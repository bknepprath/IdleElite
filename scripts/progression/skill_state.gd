class_name SkillState


static func skills_for_save(skill_defs: Array, skills: Dictionary, level_for_xp: Callable) -> Dictionary:
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
			"level": int(level_for_xp.call(xp))
		}
	return normalized


static func stamina_for_save(skill_defs: Array, stamina_value: Callable) -> Dictionary:
	var normalized := {}
	for skill_id in _skill_ids(skill_defs):
		normalized[skill_id] = stamina_value.call(skill_id)
	return normalized


static func stamina_bank_for_save(skill_defs: Array, stamina_bank: Dictionary, stamina_value: Callable, max_stamina: Callable, regen_seconds: float) -> Dictionary:
	var normalized := {}
	for skill_id in _skill_ids(skill_defs):
		if float(stamina_value.call(skill_id)) >= float(max_stamina.call(skill_id)) - 0.0001:
			normalized[skill_id] = 0.0
		else:
			normalized[skill_id] = clampf(float(stamina_bank.get(skill_id, 0.0)), 0.0, regen_seconds)
	return normalized


static func _skill_ids(skill_defs: Array) -> Array:
	var ids := []
	for raw_def in skill_defs:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if not skill_id.is_empty():
			ids.append(skill_id)
	return ids
