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


static func attempt_build(host, skill_id: String, action: Dictionary) -> bool:
	if not is_buildable(action):
		return false
	var module_key := key(skill_id, action, Callable(host, "_action_key"))
	if module_key.is_empty():
		return false
	if is_built(host.built_modules, skill_id, action, Callable(host, "_action_key")):
		return true
	var need_text := "Need %s to %s %s." % [
		cost_text(action, Callable(host.material_runtime, "amount_text_for_host").bind(host), Callable(host.material_runtime, "display_name")),
		label(action).to_lower(),
		str(action.get("name", "module"))
	]
	if not can_pay(action, Callable(host.material_runtime, "amount")):
		host._set_result(need_text)
		return false
	if not spend(action, Callable(host.material_runtime, "amount"), Callable(host.material_runtime, "spend_amount")):
		host._set_result(need_text)
		return false
	var reward_xp := xp_reward(action)
	if reward_xp > 0 and host.skills.has("build"):
		host.skills["build"]["xp"] = int(host.skills["build"].get("xp", 0)) + reward_xp
		host._recalculate_level("build")
	host.built_modules[module_key] = true
	host._set_result("%s built: +%s Building XP." % [str(action.get("name", "Module")), reward_xp])
	host._mark_save_dirty("module built")
	host.save_game()
	var refresh_scroll: int = host.detail_actions_scroll.scroll_vertical if host.detail_actions_scroll != null else -1
	if host._skill_detail_surface()._play_buildable_module_built_animation(skill_id, action, refresh_scroll):
		return true
	host._render_screen(false, refresh_scroll)
	host._update_ui(0.0, true)
	return true


static func action_from_key(module_key: String, action_lookup: Callable) -> Dictionary:
	var parts := module_key.split(":", false, 1)
	if parts.size() != 2:
		return {}
	var action = action_lookup.call(str(parts[0]), str(parts[1]))
	return action as Dictionary if typeof(action) == TYPE_DICTIONARY else {}
