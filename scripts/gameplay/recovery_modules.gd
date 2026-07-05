static func contract(action: Dictionary) -> Dictionary:
	if typeof(action.get("recovery", {})) != TYPE_DICTIONARY:
		return {}
	return action.get("recovery", {}) as Dictionary


static func has_recovery(action: Dictionary) -> bool:
	return not contract(action).is_empty()


static func target_skill_id(owner_skill_id: String, action: Dictionary, skill_defs: Array, stamina: Dictionary, stamina_value: Callable, max_stamina: Callable) -> String:
	var recovery := contract(action)
	var target := str(recovery.get("target", "self")).strip_edges()
	if target == "self" or target.is_empty():
		return owner_skill_id
	if target == "lowest":
		return lowest_stamina_skill(owner_skill_id, skill_defs, stamina_value, max_stamina)
	return target if stamina.has(target) else owner_skill_id


static func recovery_target_is_full(owner_skill_id: String, action: Dictionary, skill_defs: Array, stamina: Dictionary, stamina_value: Callable, max_stamina: Callable) -> bool:
	if not has_recovery(action):
		return false
	var skill_id := target_skill_id(owner_skill_id, action, skill_defs, stamina, stamina_value, max_stamina)
	return not skill_id.is_empty() and float(stamina_value.call(skill_id)) + 0.0001 >= float(max_stamina.call(skill_id))


static func apply(owner_skill_id: String, action: Dictionary, skill_defs: Array, stamina: Dictionary, stamina_value: Callable, max_stamina: Callable, restore_stamina: Callable) -> Dictionary:
	var recovery := contract(action)
	if recovery.is_empty():
		return {}
	var skill_id := target_skill_id(owner_skill_id, action, skill_defs, stamina, stamina_value, max_stamina)
	var restored := float(restore_stamina.call(skill_id, maxf(0.0, float(recovery.get("stamina", 0.0)))))
	if restored <= 0.0001:
		return {}
	return {
		"skill_id": skill_id,
		"amount": restored
	}


static func result_text(result: Dictionary, skill_name: Callable, stamina_amount_text: Callable) -> String:
	if result.is_empty():
		return ""
	return "+%s %s stamina." % [
		str(stamina_amount_text.call(float(result.get("amount", 0.0)))),
		str(skill_name.call(str(result.get("skill_id", ""))))
	]


static func lowest_stamina_skill(owner_skill_id: String, skill_defs: Array, stamina_value: Callable, max_stamina: Callable) -> String:
	var lowest_skill_id := owner_skill_id
	var lowest_fraction := 2.0
	for raw_def in skill_defs:
		var skill_id := str((raw_def as Dictionary).get("id", ""))
		if skill_id.is_empty():
			continue
		var max_value := maxf(1.0, float(max_stamina.call(skill_id)))
		var fraction := float(stamina_value.call(skill_id)) / max_value
		if fraction < lowest_fraction:
			lowest_fraction = fraction
			lowest_skill_id = skill_id
	return lowest_skill_id
