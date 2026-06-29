class_name MedalBuffs


static func contributions(playable_actions: Array, target_index: int, effect: String, mastery_level: Callable, max_level: int) -> Array:
	var results := []
	if target_index < 0:
		return results
	for i in range(playable_actions.size()):
		if i == target_index:
			continue
		var source_action := playable_actions[i] as Dictionary
		var source_action_id := str(source_action.get("id", ""))
		if source_action_id.is_empty():
			continue
		var medal_tier := clampi(int(mastery_level.call(source_action_id)), 0, max_level)
		if medal_tier <= 0:
			continue
		var distance := target_index - i
		var per_tier := per_tier(distance, effect)
		if per_tier <= 0.0:
			continue
		results.append({
			"source_id": source_action_id,
			"source_name": str(source_action.get("name", source_action_id.capitalize())),
			"level": medal_tier,
			"distance": distance,
			"per_tier": per_tier,
			"amount": per_tier * float(medal_tier)
		})
	return results


static func per_tier(distance: int, effect: String) -> float:
	if distance > 0:
		if effect == "stamina" or effect == "time":
			if distance == 1:
				return 0.02
			if distance == 2:
				return 0.01
			if distance == 3:
				return 0.005
		return 0.0
	if distance < 0:
		if effect != "stamina" and effect != "accuracy":
			return 0.0
		var prior_distance := -distance
		if prior_distance >= 1 and prior_distance <= 10:
			var prior_percent := float(11 - prior_distance) * 0.1
			return prior_percent if effect == "accuracy" else prior_percent * 0.01
	return 0.0
