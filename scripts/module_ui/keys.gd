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


static func canonical_action_id(skill_id: String, action_id: String, aliases := {}) -> String:
	if skill_id == "fishing" and aliases.has(action_id):
		return str(aliases[action_id])
	return action_id


static func _prefix(prefix: String, id: String) -> String:
	return "" if id.is_empty() else "%s%s" % [prefix, id]
