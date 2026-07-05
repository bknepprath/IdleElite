extends RefCounted

const ACTIVITY_DATABASE_PATH := "res://docs/activity-database.json"

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
	host._convergence_runtime().convergence_state_dirty = true


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
				var action_data := _action_for_load(action, skill_id, actions.size(), host._action_runtime()._action_mat_reward_defs(action))
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


static func _action_for_load(source: Dictionary, owner_skill_id: String, database_order: int, mat_rewards: Array = []) -> Dictionary:
	var action_id := str(source.get("id", ""))
	if action_id.is_empty():
		action_id = _slug(str(source.get("name", "Action")))
	var unlock_level := int(source.get("unlock", 1))
	var xp_value := int(source.get("xp", source.get("rewards", {}).get("xp", 1)))
	var action_data := {
		"id": action_id,
		"name": str(source.get("name", action_id.capitalize())),
		"unlock": unlock_level,
		"tier": int(source.get("tier", 1)),
		"seconds": float(source.get("seconds", 1.0)),
		"xp": xp_value,
		"stamina": int(source.get("stamina", source.get("costs", {}).get("stamina", 1))),
		"success": float(source.get("success", 90.0)),
		"art": _res_path(str(source.get("art", ""))),
		"bg": _res_path(str(source.get("background", source.get("bg", ""))))
	}
	var art_animation := _action_art_animation_for_load(source.get("art_animation", {}))
	if not art_animation.is_empty():
		action_data["art_animation"] = art_animation
	var requirements := _action_requirements_for_load(source, owner_skill_id, unlock_level)
	action_data["requirements"] = requirements
	action_data["sort_unlock"] = int(source.get("sort_unlock", _max_requirement_level(requirements, unlock_level)))
	action_data["database_order"] = database_order
	action_data["xp_rewards"] = _action_xp_rewards_for_load(source, owner_skill_id, xp_value)
	var build := _build_contract_for_load(source.get("build", {}))
	if not build.is_empty():
		action_data["build"] = build
	var recovery := _recovery_contract_for_load(source.get("recovery", {}))
	if not recovery.is_empty():
		action_data["recovery"] = recovery
	var combat := _combat_contract_for_load(source.get("combat", {}))
	if not combat.is_empty():
		action_data["combat"] = combat
	var boss := _boss_contract_for_load(source.get("boss", {}))
	if not boss.is_empty():
		action_data["boss"] = boss
	action_data["requires_bosses"] = _string_array_for_load(source.get("requires_bosses", []))
	action_data["blocks_after"] = bool(source.get("blocks_after", false))
	if not mat_rewards.is_empty():
		action_data["mat_rewards"] = mat_rewards
	action_data["combo_tags"] = _string_array_for_load(source.get("combo_tags", []))
	action_data["display_tags"] = _string_array_for_load(source.get("display_tags", source.get("tags", [])))
	var event_metadata := _event_metadata_for_load(source.get("event", {}))
	if not event_metadata.is_empty():
		action_data["event"] = event_metadata
	var kind := str(source.get("kind", source.get("type", "activity")))
	action_data["kind"] = kind
	if owner_skill_id == "fishing":
		action_data["area"] = str(source.get("area", ""))
	if kind == "passive_item_collect":
		action_data["passive"] = source.get("passive", {})
		action_data["stamina"] = 0
		action_data["success"] = 100.0
	return action_data


static func _build_contract_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var cost := {}
	var raw_cost = source.get("cost", {})
	if typeof(raw_cost) == TYPE_DICTIONARY:
		for raw_mat_id in (raw_cost as Dictionary).keys():
			var mat_id := str(raw_mat_id).strip_edges()
			var amount := maxf(0.0, float((raw_cost as Dictionary).get(raw_mat_id, 0.0)))
			if not mat_id.is_empty() and amount > 0.0:
				cost[mat_id] = amount
	if cost.is_empty():
		return {}
	return {
		"cost": cost,
		"xp": maxi(0, int(source.get("xp", 0))),
		"label": str(source.get("label", "Build")).strip_edges()
	}


static func _recovery_contract_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var amount := maxf(0.0, float(source.get("stamina", source.get("amount", 0.0))))
	if amount <= 0.0:
		return {}
	var target := str(source.get("target", "self")).strip_edges()
	if target.is_empty():
		target = "self"
	return {
		"target": target,
		"stamina": amount,
		"label": str(source.get("label", "Recover")).strip_edges()
	}


static func _combat_contract_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var enemy_id := str(source.get("enemy_id", source.get("enemy", ""))).strip_edges()
	var arena_shape := str(source.get("arena_shape", "")).strip_edges().to_lower()
	if enemy_id.is_empty() and arena_shape.is_empty():
		return {}
	var combat := {
		"enemy_id": enemy_id,
		"arena_shape": arena_shape,
		"enemy_kind": str(source.get("enemy_kind", "swarm")).strip_edges(),
		"art_ref": str(source.get("art_ref", "")).strip_edges()
	}
	for numeric_key in ["speed", "health", "spawn_rhythm", "contact_damage", "reward_xp"]:
		if source.has(numeric_key):
			combat[numeric_key] = maxf(0.0, float(source.get(numeric_key, 0.0)))
	return combat


static func _boss_contract_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var boss_id := str(source.get("id", "")).strip_edges()
	if boss_id.is_empty():
		return {}
	var boss_name := str(source.get("name", boss_id.capitalize())).strip_edges()
	var boss := {
		"id": boss_id,
		"name": boss_name,
		"hp": maxi(1, int(source.get("hp", 100)))
	}
	var requires := []
	var raw_requires = source.get("requires", [])
	if typeof(raw_requires) == TYPE_ARRAY:
		for raw_requirement in raw_requires:
			if typeof(raw_requirement) != TYPE_DICTIONARY:
				continue
			var requirement := raw_requirement as Dictionary
			var requirement_skill := str(requirement.get("skill", requirement.get("skill_id", ""))).strip_edges()
			if not requirement_skill.is_empty():
				requires.append({
					"skill": requirement_skill,
					"level": maxi(1, int(requirement.get("level", 1)))
				})
	if not requires.is_empty():
		boss["requires"] = requires
	return boss


static func _action_requirements_for_load(action: Dictionary, owner_skill_id: String, legacy_unlock: int) -> Array:
	var normalized := []
	var raw_requirements = action.get("requirements", [])
	if typeof(raw_requirements) == TYPE_ARRAY:
		for raw_requirement in raw_requirements:
			if typeof(raw_requirement) != TYPE_DICTIONARY:
				continue
			var requirement := raw_requirement as Dictionary
			var requirement_skill := str(requirement.get("skill", requirement.get("skill_id", owner_skill_id))).strip_edges()
			if requirement_skill.is_empty():
				requirement_skill = owner_skill_id
			var requirement_level := maxi(1, int(requirement.get("level", requirement.get("unlock", legacy_unlock))))
			normalized.append({
				"skill": requirement_skill,
				"level": requirement_level
			})
	if normalized.is_empty():
		normalized.append({
			"skill": owner_skill_id,
			"level": maxi(1, legacy_unlock)
		})
	return normalized


static func _action_xp_rewards_for_load(action: Dictionary, owner_skill_id: String, primary_xp: int) -> Dictionary:
	var normalized := {}
	var raw_rewards = action.get("xp_rewards", action.get("xp_by_skill", {}))
	if typeof(raw_rewards) == TYPE_DICTIONARY:
		var rewards := raw_rewards as Dictionary
		for raw_skill_id in rewards.keys():
			var skill_id := str(raw_skill_id).strip_edges()
			if skill_id.is_empty():
				continue
			var amount := maxi(0, int(rewards.get(raw_skill_id, 0)))
			if amount > 0:
				normalized[skill_id] = amount
	elif typeof(raw_rewards) == TYPE_ARRAY:
		for raw_reward in raw_rewards:
			if typeof(raw_reward) != TYPE_DICTIONARY:
				continue
			var reward := raw_reward as Dictionary
			var skill_id := str(reward.get("skill", reward.get("skill_id", owner_skill_id))).strip_edges()
			if skill_id.is_empty():
				continue
			var amount := maxi(0, int(reward.get("xp", reward.get("amount", 0))))
			if amount > 0:
				normalized[skill_id] = amount
	if normalized.is_empty():
		normalized[owner_skill_id] = maxi(1, primary_xp)
	return normalized


static func _string_array_for_load(value: Variant) -> Array:
	var normalized := []
	if typeof(value) == TYPE_ARRAY:
		for raw_item in value:
			var normalized_item := str(raw_item).strip_edges()
			if not normalized_item.is_empty() and not normalized.has(normalized_item):
				normalized.append(normalized_item)
	elif typeof(value) == TYPE_STRING:
		var normalized_item := str(value).strip_edges()
		if not normalized_item.is_empty():
			normalized.append(normalized_item)
	return normalized


static func _action_art_animation_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var atlas_path := _res_path(str(source.get("atlas", "")))
	var frame_count := maxi(1, int(source.get("frame_count", 1)))
	var cell_width := maxi(1, int(source.get("cell_width", 256)))
	var cell_height := maxi(1, int(source.get("cell_height", 256)))
	var sequence := []
	if typeof(source.get("sequence", [])) == TYPE_ARRAY:
		for raw_index in source.get("sequence", []):
			sequence.append(clampi(int(raw_index), 0, frame_count - 1))
	if sequence.is_empty():
		for frame_index in range(frame_count):
			sequence.append(frame_index)
	var durations := []
	if typeof(source.get("durations", [])) == TYPE_ARRAY:
		for raw_duration in source.get("durations", []):
			durations.append(maxf(0.016, float(raw_duration)))
	while durations.size() < sequence.size():
		durations.append(0.1)
	if atlas_path.is_empty():
		return {}
	return {
		"atlas": atlas_path,
		"frame_count": frame_count,
		"cell_width": cell_width,
		"cell_height": cell_height,
		"sequence": sequence,
		"durations": durations,
		"sync": str(source.get("sync", "")),
		"effects": _action_art_animation_effects_for_load(source.get("effects", {}))
	}


static func _action_art_animation_effects_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var effect_name := str(source.get("name", "")).strip_edges()
	if effect_name.is_empty():
		return {}
	var colors := []
	if typeof(source.get("colors", [])) == TYPE_ARRAY:
		for raw_color in source.get("colors", []):
			var color_text := str(raw_color).strip_edges()
			if not color_text.is_empty():
				colors.append(color_text)
	var scenario_palettes := []
	if typeof(source.get("scenario_palettes", [])) == TYPE_ARRAY:
		for raw_palette in source.get("scenario_palettes", []):
			var palette := []
			if typeof(raw_palette) == TYPE_ARRAY:
				for raw_color in raw_palette:
					var color_text := str(raw_color).strip_edges()
					if not color_text.is_empty():
						palette.append(color_text)
			if not palette.is_empty():
				scenario_palettes.append(palette)
	return {
		"name": effect_name,
		"splash": bool(source.get("splash", source.get("brush", false))),
		"random_scenario": bool(source.get("random_scenario", false)),
		"cycle_seconds": maxf(0.25, float(source.get("cycle_seconds", 1.15))),
		"paint_seconds": maxf(0.08, float(source.get("paint_seconds", 0.70))),
		"hold_seconds": maxf(0.08, float(source.get("hold_seconds", 0.55))),
		"colors": colors,
		"scenario_palettes": scenario_palettes
	}


static func _event_metadata_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var normalized := {}
	var source := value as Dictionary
	for raw_key in source.keys():
		var key := str(raw_key).strip_edges()
		if not key.is_empty():
			normalized[key] = source.get(raw_key)
	return normalized


static func _max_requirement_level(requirements: Array, fallback_level: int) -> int:
	var max_level := maxi(1, fallback_level)
	for raw_requirement in requirements:
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		max_level = maxi(max_level, int(requirement.get("level", 1)))
	return max_level


static func _res_path(path: String) -> String:
	if path.is_empty() or path.begins_with("res://"):
		return path
	return "res://%s" % path


static func _slug(text: String) -> String:
	return text.to_lower().replace("'", "").replace(",", "").replace(" ", "-")
