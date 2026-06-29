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
