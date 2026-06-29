class_name FishingState


static func normalized_selected_locations(loaded_locations: Variant, canonical_area_id: Callable, area_loaded: Callable, location_valid: Callable) -> Dictionary:
	var normalized := {}
	if typeof(loaded_locations) != TYPE_DICTIONARY:
		return normalized
	var source := loaded_locations as Dictionary
	for raw_area_id in source.keys():
		var area_id := str(canonical_area_id.call(str(raw_area_id)))
		if area_id.is_empty() or not bool(area_loaded.call(area_id)):
			continue
		var location_id := str(source.get(raw_area_id, ""))
		if location_id.is_empty():
			continue
		if bool(location_valid.call(area_id, location_id)):
			normalized[area_id] = location_id
	return normalized


static func equipped_tool_id_for_save(tool_id: String, rod_collected: bool, reinforced_collected: bool, star_collected: bool, is_rod: Callable, is_unlocked: Callable) -> String:
	if bool(is_rod.call(tool_id)):
		if star_collected:
			return "star_rod"
		if reinforced_collected:
			return "reinforced_rod"
		if rod_collected:
			return "line"
		return "hands"
	if bool(is_unlocked.call(tool_id)):
		return tool_id
	return "hands"


static func rod_collected_for_save(rod_collected: bool, reinforced_collected: bool, star_collected: bool) -> bool:
	return rod_collected or reinforced_collected or star_collected


static func reinforced_rod_collected_for_save(reinforced_collected: bool, star_collected: bool) -> bool:
	return reinforced_collected or star_collected


static func star_rod_collected_for_save(star_collected: bool) -> bool:
	return star_collected


static func reconciled_rod_collection(rod_collected: bool, reinforced_collected: bool, star_collected: bool) -> Dictionary:
	if star_collected:
		reinforced_collected = true
		rod_collected = true
	elif reinforced_collected:
		rod_collected = true
	return {
		"rod": rod_collected,
		"reinforced": reinforced_collected,
		"star": star_collected
	}
