class_name ActivityDataNormalizers


static func action_for_load(source: Dictionary, owner_skill_id: String, database_order: int, mat_rewards: Array = []) -> Dictionary:
	var action_id := str(source.get("id", ""))
	if action_id.is_empty():
		action_id = slug(str(source.get("name", "Action")))
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
		"art": res_path(str(source.get("art", ""))),
		"bg": res_path(str(source.get("background", source.get("bg", ""))))
	}
	var art_animation := action_art_animation_for_load(source.get("art_animation", {}))
	if not art_animation.is_empty():
		action_data["art_animation"] = art_animation
	var requirements := action_requirements_for_load(source, owner_skill_id, unlock_level)
	action_data["requirements"] = requirements
	action_data["sort_unlock"] = int(source.get("sort_unlock", max_requirement_level(requirements, unlock_level)))
	action_data["database_order"] = database_order
	action_data["xp_rewards"] = action_xp_rewards_for_load(source, owner_skill_id, xp_value)
	if not mat_rewards.is_empty():
		action_data["mat_rewards"] = mat_rewards
	action_data["combo_tags"] = string_array_for_load(source.get("combo_tags", []))
	action_data["display_tags"] = string_array_for_load(source.get("display_tags", source.get("tags", [])))
	var event_metadata := event_metadata_for_load(source.get("event", {}))
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


static func event_module_for_load(source: Dictionary, definition_order: int) -> Dictionary:
	var page := str(source.get("page", source.get("skill", source.get("skill_id", "")))).strip_edges()
	if page.is_empty():
		return {}
	var event_id := str(source.get("id", "")).strip_edges()
	if event_id.is_empty():
		event_id = slug(str(source.get("name", "Event Module")))
	var target_level := maxi(1, int(source.get("target_level", source.get("sort_unlock", source.get("unlock", 1)))))
	var unlock_level := maxi(1, int(source.get("unlock", target_level)))
	var xp_value := maxi(1, int(source.get("xp", source.get("rewards", {}).get("xp", 1))))
	var requirements := action_requirements_for_load(source, page, unlock_level)
	var event_def := {
		"id": event_id,
		"page": page,
		"name": str(source.get("name", event_id.capitalize())),
		"kind": "event_activity",
		"unlock": unlock_level,
		"sort_unlock": maxi(1, int(source.get("sort_unlock", target_level))),
		"target_level": target_level,
		"tier": int(source.get("tier", target_level)),
		"seconds": float(source.get("seconds", 1.0)),
		"xp": xp_value,
		"stamina": int(source.get("stamina", source.get("costs", {}).get("stamina", 1))),
		"success": float(source.get("success", 90.0)),
		"art": res_path(str(source.get("art", ""))),
		"bg": res_path(str(source.get("background", source.get("bg", "")))),
		"requirements": requirements,
		"xp_rewards": action_xp_rewards_for_load(source, page, xp_value),
		"resource_rewards": event_resource_rewards_for_load(source),
		"combo_tags": string_array_for_load(source.get("combo_tags", ["event"])),
		"display_tags": string_array_for_load(source.get("display_tags", ["Event"])),
		"definition_order": definition_order
	}
	if source.has("area"):
		event_def["area"] = str(source.get("area", ""))
	var xp_reward_cap := int(source.get("xp_reward_cap", 0))
	if xp_reward_cap > 0:
		event_def["xp_reward_cap"] = xp_reward_cap
	var event_metadata := event_metadata_for_load(source.get("event", {}))
	event_metadata["target_level"] = target_level
	event_metadata["minimum_level"] = maxi(1, int(source.get("minimum_level", event_metadata.get("minimum_level", target_level))))
	event_metadata["spawn_weight"] = maxf(0.0, float(source.get("spawn_weight", event_metadata.get("spawn_weight", 1.0))))
	event_metadata["active_duration_seconds"] = maxi(1, int(source.get("active_duration_seconds", event_metadata.get("active_duration_seconds", 3600))))
	event_metadata["respawn_cooldown_seconds"] = maxi(1, int(source.get("respawn_cooldown_seconds", event_metadata.get("respawn_cooldown_seconds", 21600))))
	event_metadata["definition_order"] = definition_order
	event_def["event"] = event_metadata
	return event_def


static func action_requirements_for_load(action: Dictionary, owner_skill_id: String, legacy_unlock: int) -> Array:
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


static func event_resource_rewards_for_load(action: Dictionary) -> Dictionary:
	var normalized := {}
	var raw_rewards = action.get("resource_rewards", action.get("resource_reward", {}))
	if typeof(raw_rewards) != TYPE_DICTIONARY:
		return normalized
	var rewards := raw_rewards as Dictionary
	var logs_min := maxi(0, int(rewards.get("logs_min", rewards.get("log_min", rewards.get("logs", 0)))))
	var logs_max := maxi(logs_min, int(rewards.get("logs_max", rewards.get("log_max", logs_min))))
	if logs_max > 0:
		normalized["logs_min"] = logs_min
		normalized["logs_max"] = logs_max
	return normalized


static func action_xp_rewards_for_load(action: Dictionary, owner_skill_id: String, primary_xp: int) -> Dictionary:
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


static func string_array_for_load(value: Variant) -> Array:
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


static func action_art_animation_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var atlas_path := res_path(str(source.get("atlas", "")))
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
		"effects": action_art_animation_effects_for_load(source.get("effects", {}))
	}


static func action_art_animation_effects_for_load(value: Variant) -> Dictionary:
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


static func event_metadata_for_load(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var normalized := {}
	var source := value as Dictionary
	for raw_key in source.keys():
		var key := str(raw_key).strip_edges()
		if not key.is_empty():
			normalized[key] = source.get(raw_key)
	return normalized


static func max_requirement_level(requirements: Array, fallback_level: int) -> int:
	var max_level := maxi(1, fallback_level)
	for raw_requirement in requirements:
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			continue
		var requirement := raw_requirement as Dictionary
		max_level = maxi(max_level, int(requirement.get("level", 1)))
	return max_level


static func res_path(path: String) -> String:
	if path.is_empty() or path.begins_with("res://"):
		return path
	return "res://%s" % path


static func slug(text: String) -> String:
	return text.to_lower().replace("'", "").replace(",", "").replace(" ", "-")
