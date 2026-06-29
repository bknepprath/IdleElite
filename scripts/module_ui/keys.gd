class_name ModuleUiKeys

const PREFIX_ACTION := "action:"
const PREFIX_THIEVING_HEIST := "thieving_heist:"
const PREFIX_FISHING_AREA := "fishing_area:"
const PREFIX_FISHING_OFFER := "fishing_offer:"
const PREFIX_HUB := "hub:"
const VALID_PREFIXES := [
	PREFIX_ACTION,
	PREFIX_THIEVING_HEIST,
	PREFIX_FISHING_AREA,
	PREFIX_FISHING_OFFER,
	PREFIX_HUB,
]


static func normalize(value: Variant) -> String:
	var key := str(value).strip_edges()
	if key.is_empty():
		return ""
	for prefix in VALID_PREFIXES:
		if key.begins_with(prefix) and key.length() > prefix.length():
			return key
	return ""


static func action(skill_id: String, action_id: String, aliases := {}) -> String:
	var id := canonical_action_id(skill_id, action_id, aliases)
	if skill_id.is_empty() or id.is_empty():
		return ""
	return "%s%s:%s" % [PREFIX_ACTION, skill_id, id]


static func action_for_record(skill_id: String, action_record: Dictionary, aliases := {}) -> String:
	return action(skill_id, str(action_record.get("id", "")), aliases)


static func thieving_heist(heist_id: String) -> String:
	return _prefix(PREFIX_THIEVING_HEIST, heist_id)


static func fishing_area(area_key: String) -> String:
	return _prefix(PREFIX_FISHING_AREA, area_key)


static func fishing_offer(offer_id: String) -> String:
	return _prefix(PREFIX_FISHING_OFFER, offer_id)


static func hub(module_id: String) -> String:
	return _prefix(PREFIX_HUB, module_id)


static func belongs_to_skill(module_key: String, skill_id: String) -> bool:
	var key := normalize(module_key)
	if key.is_empty() or skill_id.is_empty():
		return false
	if key.begins_with(PREFIX_ACTION):
		return key.begins_with("%s%s:" % [PREFIX_ACTION, skill_id])
	if key.begins_with(PREFIX_THIEVING_HEIST):
		return skill_id == "thieving"
	if key.begins_with(PREFIX_FISHING_AREA) or key.begins_with(PREFIX_FISHING_OFFER):
		return skill_id == "fishing"
	return false


static func lazy_track_id(module_key: String, skill_id: String) -> String:
	var key := normalize(module_key)
	if key.is_empty() or skill_id.is_empty() or not belongs_to_skill(key, skill_id):
		return ""
	if key.begins_with(PREFIX_ACTION):
		var action_key := key.substr(PREFIX_ACTION.length())
		var parts := action_key.split(":", false, 2)
		if parts.size() >= 2:
			return str(parts[1])
	if key.begins_with(PREFIX_THIEVING_HEIST) and skill_id == "thieving":
		return "heist:%s" % key.substr(PREFIX_THIEVING_HEIST.length())
	if key.begins_with(PREFIX_FISHING_AREA) and skill_id == "fishing":
		return key.substr(PREFIX_FISHING_AREA.length())
	if key.begins_with(PREFIX_FISHING_OFFER) and skill_id == "fishing":
		return "offer:%s" % key.substr(PREFIX_FISHING_OFFER.length())
	return ""


static func normalized_order(value: Variant) -> Array:
	var order: Array = []
	if typeof(value) != TYPE_ARRAY:
		return order
	var seen := {}
	for raw_key in value:
		var key := normalize(raw_key)
		if key.is_empty() or seen.has(key):
			continue
		seen[key] = true
		order.append(key)
	return order


static func normalized_flags(value: Variant) -> Dictionary:
	var flags := {}
	if typeof(value) != TYPE_DICTIONARY:
		return flags
	var source := value as Dictionary
	for raw_key in source.keys():
		var key := normalize(raw_key)
		if key.is_empty() or not bool(source.get(raw_key, false)):
			continue
		flags[key] = true
	return flags


static func normalized_paths(value: Variant, valid_paths: Array) -> Dictionary:
	var paths := {}
	if typeof(value) != TYPE_DICTIONARY:
		return paths
	var source := value as Dictionary
	for raw_key in source.keys():
		var key := normalize(raw_key)
		var path := str(source.get(raw_key, ""))
		if key.is_empty() or not valid_paths.has(path):
			continue
		paths[key] = path
	return paths


static func canonical_action_id(skill_id: String, action_id: String, aliases := {}) -> String:
	if skill_id == "fishing" and aliases.has(action_id):
		return str(aliases[action_id])
	return action_id


static func _prefix(prefix: String, id: String) -> String:
	return "" if id.is_empty() else "%s%s" % [prefix, id]
