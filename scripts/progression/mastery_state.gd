class_name MasteryState


static func for_save(mastery: Dictionary, canonical_key: Callable, max_level: int, xp_for_level: Callable) -> Dictionary:
	return _normalized_entries(mastery, canonical_key, max_level, xp_for_level)


static func restored_from_save(loaded_mastery: Variant, canonical_key: Callable, max_level: int, xp_for_level: Callable) -> Dictionary:
	return _normalized_entries(loaded_mastery, canonical_key, max_level, xp_for_level)


static func _normalized_entries(raw_mastery: Variant, canonical_key: Callable, max_level: int, xp_for_level: Callable) -> Dictionary:
	var normalized := {}
	if typeof(raw_mastery) != TYPE_DICTIONARY:
		return normalized
	var source := raw_mastery as Dictionary
	for raw_key in source.keys():
		var key := str(canonical_key.call(str(raw_key)))
		if key.is_empty():
			continue
		var entry = source.get(raw_key, {})
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var xp := maxi(0, int((entry as Dictionary).get("xp", 0)))
		var existing = normalized.get(key, null)
		if typeof(existing) == TYPE_DICTIONARY:
			xp = maxi(xp, int((existing as Dictionary).get("xp", 0)))
		normalized[key] = _entry_for_xp(xp, max_level, xp_for_level)
	return normalized


static func _entry_for_xp(xp: int, max_level: int, xp_for_level: Callable) -> Dictionary:
	var xp_total := float(maxi(0, xp))
	var level := 0
	while level < max_level and xp_total >= float(xp_for_level.call(level + 1)):
		level += 1
	return {
		"xp": minf(xp_total, float(xp_for_level.call(max_level))),
		"level": level
	}
