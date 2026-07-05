class_name BuildableModules

const MATERIAL_BUILD_XP := {
	"scrapwood": 20,
	"softwood": 40,
	"hardwood": 80
}


static func key(skill_id: String, action: Dictionary, action_key: Callable) -> String:
	var action_id := str(action.get("id", ""))
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	return str(action_key.call(skill_id, action_id))


static func is_buildable(action: Dictionary) -> bool:
	return typeof(action.get("build", {})) == TYPE_DICTIONARY and not (action.get("build", {}) as Dictionary).is_empty()


static func is_built(built_modules: Dictionary, skill_id: String, action: Dictionary, action_key: Callable) -> bool:
	if not is_buildable(action):
		return true
	var module_key := key(skill_id, action, action_key)
	return not module_key.is_empty() and bool(built_modules.get(module_key, false))


static func normalized_for_save(built_modules: Dictionary, action_lookup: Callable) -> Dictionary:
	var normalized := {}
	for raw_key in built_modules.keys():
		var module_key := str(raw_key)
		if not bool(built_modules.get(raw_key, false)):
			continue
		var action := action_from_key(module_key, action_lookup)
		if action.is_empty() or not is_buildable(action):
			continue
		normalized[module_key] = true
	return normalized


static func restored_from_save(value: Variant, action_lookup: Callable) -> Dictionary:
	var restored := {}
	if typeof(value) != TYPE_DICTIONARY:
		return restored
	for raw_key in (value as Dictionary).keys():
		var module_key := str(raw_key)
		if not bool((value as Dictionary).get(raw_key, false)):
			continue
		var action := action_from_key(module_key, action_lookup)
		if action.is_empty() or not is_buildable(action):
			continue
		restored[module_key] = true
	return restored


static func cost(action: Dictionary) -> Dictionary:
	if not is_buildable(action):
		return {}
	var build := action.get("build", {}) as Dictionary
	return build.get("cost", {}) as Dictionary


static func label(action: Dictionary) -> String:
	if not is_buildable(action):
		return "Build"
	var text := str((action.get("build", {}) as Dictionary).get("label", "Build")).strip_edges()
	return "Build" if text.is_empty() else text


static func xp_reward(action: Dictionary) -> int:
	if not is_buildable(action):
		return 0
	var total := 0
	for raw_mat_id in cost(action).keys():
		var mat_id := str(raw_mat_id)
		total += int(round(float(cost(action).get(raw_mat_id, 0.0)) * float(MATERIAL_BUILD_XP.get(mat_id, 40))))
	return maxi(0, total)


static func cost_text(action: Dictionary, mat_amount_text: Callable, mat_name: Callable) -> String:
	var parts := []
	var build_cost := cost(action)
	for raw_mat_id in build_cost.keys():
		var mat_id := str(raw_mat_id)
		var amount := float(build_cost.get(raw_mat_id, 0.0))
		if amount > 0.0:
			parts.append("%s %s" % [str(mat_amount_text.call(mat_id, amount)), str(mat_name.call(mat_id))])
	return ", ".join(parts)


static func can_pay(action: Dictionary, mat_amount: Callable) -> bool:
	var build_cost := cost(action)
	for raw_mat_id in build_cost.keys():
		var mat_id := str(raw_mat_id)
		var amount := float(build_cost.get(raw_mat_id, 0.0))
		if amount > 0.0 and float(mat_amount.call(mat_id)) + 0.0001 < amount:
			return false
	return true


static func spend(action: Dictionary, mat_amount: Callable, spend_mat_amount: Callable) -> bool:
	if not can_pay(action, mat_amount):
		return false
	var build_cost := cost(action)
	for raw_mat_id in build_cost.keys():
		var mat_id := str(raw_mat_id)
		var amount := float(build_cost.get(raw_mat_id, 0.0))
		if amount > 0.0 and not bool(spend_mat_amount.call(mat_id, amount)):
			return false
	return true


static func action_from_key(module_key: String, action_lookup: Callable) -> Dictionary:
	var parts := module_key.split(":", false, 1)
	if parts.size() != 2:
		return {}
	var action = action_lookup.call(str(parts[0]), str(parts[1]))
	return action as Dictionary if typeof(action) == TYPE_DICTIONARY else {}
