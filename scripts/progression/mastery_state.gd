class_name MasteryState


static func xp_for_level(level: int) -> int:
	if level <= 0:
		return 0
	return int(round(18.0 * pow(float(level), 2.05)))


static func level(mastery: Dictionary, key: String) -> int:
	return int(mastery.get(key, {}).get("level", 0))


static func is_maxed(mastery: Dictionary, key: String, max_level: int) -> bool:
	return level(mastery, key) >= max_level


static func progress_pct(mastery: Dictionary, key: String, max_level: int) -> float:
	var current_level := level(mastery, key)
	if current_level >= max_level:
		return 100.0
	var xp_total := float(mastery.get(key, {}).get("xp", 0))
	var start := xp_for_level(current_level)
	var end := xp_for_level(current_level + 1)
	var needed := maxi(1, end - start)
	return clampf(float(xp_total - start) / float(needed) * 100.0, 0.0, 100.0)


static func would_reward_level_up(mastery: Dictionary, key: String, amount: float, max_level: int) -> bool:
	if amount <= 0.0:
		return false
	var current_level := level(mastery, key)
	if current_level >= max_level:
		return false
	var xp_total := float(mastery.get(key, {}).get("xp", 0))
	return xp_total + amount >= float(xp_for_level(current_level + 1))


static func add_xp(mastery: Dictionary, key: String, amount: float, max_level: int) -> Dictionary:
	if amount <= 0.0 or is_maxed(mastery, key, max_level):
		return {"level_changed": false}
	if not mastery.has(key):
		mastery[key] = {"xp": 0, "level": 0}
	mastery[key]["xp"] = float(mastery[key].get("xp", 0)) + amount
	return recalculate_entry(mastery, key, max_level)


static func recalculate_entry(mastery: Dictionary, key: String, max_level: int) -> Dictionary:
	if not mastery.has(key):
		return {"level_changed": false}
	var old_level := level(mastery, key)
	var entry := _entry_for_xp(float(mastery[key].get("xp", 0)), max_level, false)
	mastery[key]["level"] = entry["level"]
	mastery[key]["xp"] = entry["xp"]
	return {
		"level_changed": int(entry["level"]) != old_level,
		"old_level": old_level,
		"level": int(entry["level"]),
		"xp": float(entry["xp"])
	}


static func for_save(mastery: Dictionary, canonical_key: Callable, max_level: int) -> Dictionary:
	return _normalized_entries(mastery, canonical_key, max_level)


static func restored_from_save(loaded_mastery: Variant, canonical_key: Callable, max_level: int) -> Dictionary:
	return _normalized_entries(loaded_mastery, canonical_key, max_level)


static func _normalized_entries(raw_mastery: Variant, canonical_key: Callable, max_level: int) -> Dictionary:
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
		normalized[key] = _entry_for_xp(float(xp), max_level, true)
	return normalized


static func _entry_for_xp(xp: float, max_level: int, clamp_to_zero: bool) -> Dictionary:
	var xp_total := maxf(0.0, xp) if clamp_to_zero else xp
	var current_level := 0
	while current_level < max_level and xp_total >= float(xp_for_level(current_level + 1)):
		current_level += 1
	return {
		"xp": minf(xp_total, float(xp_for_level(max_level))),
		"level": current_level
	}
