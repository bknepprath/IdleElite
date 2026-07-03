class_name ActivityDataCatalog
extends RefCounted

const ACTIVITY_DATABASE_PATH := "res://docs/activity-database.json"
const ActivityDataNormalizers = preload("res://scripts/activity_data/normalizers.gd")

var skill_defs := []
var actions_by_skill := {}
var actions_by_key := {}
var convergence_action_ids := []


func load_action_data(host) -> bool:
	actions_by_skill.clear()
	actions_by_key.clear()
	host.fishing_area_definitions.clear()
	host._temporary_event_runtime().event_module_defs.clear()
	skill_defs.clear()
	if load_activity_database(host):
		rebuild_action_lookup(host)
		return true
	push_error("Failed to load required activity database: %s" % ACTIVITY_DATABASE_PATH)
	return false


func rebuild_action_lookup(host) -> void:
	actions_by_key.clear()
	convergence_action_ids.clear()
	for raw_skill_id in actions_by_skill.keys():
		var skill_id := str(raw_skill_id)
		for raw_action in actions_by_skill.get(skill_id, []):
			if typeof(raw_action) != TYPE_DICTIONARY:
				continue
			var action := raw_action as Dictionary
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			actions_by_key[host._action_key(skill_id, action_id)] = action
			if host._convergence_runtime()._is_convergence_action(action):
				convergence_action_ids.append(action_id)
	host.convergence_state_dirty = true


func load_activity_database(host) -> bool:
	if not FileAccess.file_exists(ACTIVITY_DATABASE_PATH):
		return false
	var file := FileAccess.open(ACTIVITY_DATABASE_PATH, FileAccess.READ)
	if file == null:
		return false
	var activity_database = JSON.parse_string(file.get_as_text())
	if typeof(activity_database) != TYPE_DICTIONARY:
		return false
	var loaded_skills = activity_database.get("skills", [])
	if typeof(loaded_skills) != TYPE_ARRAY or loaded_skills.is_empty():
		return false
	for raw_skill in loaded_skills:
		if typeof(raw_skill) != TYPE_DICTIONARY:
			continue
		var skill := raw_skill as Dictionary
		var skill_id := str(skill.get("id", ""))
		if skill_id.is_empty():
			continue
		skill_defs.append({
			"id": skill_id,
			"name": str(skill.get("name", skill_id.capitalize())),
			"verb": str(skill.get("verb", "Training"))
		})
		var loaded_actions = skill.get("actions", [])
		var actions := []
		if typeof(loaded_actions) == TYPE_ARRAY:
			for raw_action in loaded_actions:
				if typeof(raw_action) != TYPE_DICTIONARY:
					continue
				var action := raw_action as Dictionary
				var action_data := ActivityDataNormalizers.action_for_load(action, skill_id, actions.size(), host._action_runtime()._action_mat_reward_defs(action))
				actions.append(action_data)
		sort_activity_actions_for_page(skill_id, actions)
		actions_by_skill[skill_id] = actions
		if skill_id == "fishing":
			host.fishing_runtime.load_area_definitions_from_skill(host, skill, actions)
	host._temporary_event_runtime()._load_event_module_definitions(activity_database)
	return not skill_defs.is_empty()


func sort_activity_actions_for_page(skill_id: String, actions: Array) -> void:
	if skill_id == "fishing" or actions.size() <= 1:
		return
	actions.sort_custom(func(left, right): return activity_action_display_sort_less(left, right))


func activity_action_display_sort_less(left: Variant, right: Variant) -> bool:
	if typeof(left) != TYPE_DICTIONARY:
		return false
	if typeof(right) != TYPE_DICTIONARY:
		return true
	var left_action := left as Dictionary
	var right_action := right as Dictionary
	var left_sort := activity_action_display_sort_level(left_action)
	var right_sort := activity_action_display_sort_level(right_action)
	if left_sort != right_sort:
		return left_sort < right_sort
	var left_unlock := int(left_action.get("unlock", 1))
	var right_unlock := int(right_action.get("unlock", 1))
	if left_unlock != right_unlock:
		return left_unlock < right_unlock
	var left_order := int(left_action.get("database_order", 0))
	var right_order := int(right_action.get("database_order", 0))
	if left_order != right_order:
		return left_order < right_order
	return str(left_action.get("id", "")) < str(right_action.get("id", ""))


func activity_action_display_sort_level(action: Dictionary) -> int:
	return maxi(1, int(action.get("sort_unlock", action.get("unlock", 1))))
