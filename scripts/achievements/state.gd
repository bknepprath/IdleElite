class_name AchievementState


static func normalized_seen_ids(value: Variant) -> Dictionary:
	var seen_ids := {}
	if typeof(value) != TYPE_DICTIONARY:
		return seen_ids
	var source := value as Dictionary
	for raw_id in source.keys():
		var id := str(raw_id)
		if id.is_empty() or not bool(source.get(raw_id, false)):
			continue
		seen_ids[id] = true
	return seen_ids


static func visible_milestones(milestones: Array, hide_completed: bool) -> Array:
	var chain_order := []
	var chains := {}
	for raw_achievement in milestones:
		if typeof(raw_achievement) != TYPE_DICTIONARY:
			continue
		var achievement := raw_achievement as Dictionary
		if not should_show_in_bonus_log(achievement):
			continue
		var chain_key := str(achievement.get("chain_key", achievement.get("id", "")))
		if chain_key.is_empty():
			continue
		if not chains.has(chain_key):
			chains[chain_key] = []
			chain_order.append(chain_key)
		(chains[chain_key] as Array).append(achievement)
	var visible_achievements := []
	for chain_key in chain_order:
		var chain: Array = chains[chain_key]
		var next_achievement := {}
		for achievement in chain:
			if bool(achievement.get("completed", false)):
				if not hide_completed:
					visible_achievements.append(achievement)
				continue
			if next_achievement.is_empty():
				next_achievement = achievement
		if not next_achievement.is_empty():
			visible_achievements.append(next_achievement)
	return visible_achievements


static func should_show_in_bonus_log(achievement: Dictionary) -> bool:
	return (
		not bool(achievement.get("log_only", false))
		and not str(achievement.get("reward_stat", "")).is_empty()
	)
