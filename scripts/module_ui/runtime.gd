class_name ModuleUiRuntime
extends RefCounted

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
const SORT_LEVEL := "level"
const SORT_LEVEL_REVERSE := "level_reverse"
const COLLAPSE_SAVE_VERSION := 3

var pinned_order: Array = []
var pin_color_paths := {}
var collapsed := {}
var sort_mode := SORT_LEVEL
var combo_first := false
var collection_first := false
var pin_preview_tokens := {}


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


static func normalized_sort_mode(value: Variant) -> String:
	var mode := str(value)
	match mode:
		SORT_LEVEL, SORT_LEVEL_REVERSE:
			return mode
		_:
			return SORT_LEVEL


func reset() -> void:
	pinned_order.clear()
	pin_color_paths.clear()
	collapsed.clear()
	sort_mode = SORT_LEVEL
	combo_first = false
	collection_first = false
	pin_preview_tokens.clear()


func set_sort_mode(next_mode: String) -> bool:
	var normalized := normalized_sort_mode(next_mode)
	if sort_mode == normalized:
		return false
	sort_mode = normalized
	return true


func toggle_level_sort() -> bool:
	return set_sort_mode(SORT_LEVEL if sort_mode == SORT_LEVEL_REVERSE else SORT_LEVEL_REVERSE)


func toggle_sort_priority(priority_kind: String) -> bool:
	match priority_kind:
		"combo":
			combo_first = not combo_first
		"collection":
			collection_first = not collection_first
		_:
			return false
	return true


func sort_detail_entries(entries: Array, skill_id: String, level_sort_value: Callable, combo_module: Callable, collection_module: Callable) -> Array:
	if entries.size() > 1:
		entries.sort_custom(func(left, right): return _detail_entry_sort_less(left, right, skill_id, level_sort_value, combo_module, collection_module))
	return entries


func sort_fishing_lazy_plan(plan: Array, skill_id: String, stack_separation: float, level_sort_value: Callable, combo_module: Callable, collection_module: Callable) -> Array:
	if plan.size() > 1:
		plan.sort_custom(func(left, right):
			return _detail_entry_sort_less(
				_lazy_entry_detail_sort_proxy(left as Dictionary),
				_lazy_entry_detail_sort_proxy(right as Dictionary),
				skill_id,
				level_sort_value,
				combo_module,
				collection_module
			)
		)
	var y := 0.0
	for raw_entry in plan:
		var entry := raw_entry as Dictionary
		entry["y"] = y
		y += float(entry.get("height", 0.0)) + stack_separation
	return plan


func is_collapsed(module_key: String, allow_key: Callable) -> bool:
	var key := normalize(module_key)
	return _allowed(key, allow_key) and bool(collapsed.get(key, false))


func is_pinned(module_key: String, allow_key: Callable) -> bool:
	var key := normalize(module_key)
	return _allowed(key, allow_key) and pinned_order.has(key)


func pinned_order_for_save(allow_key: Callable) -> Array:
	return pinned_order_unlocked_only(normalized_order(pinned_order), allow_key)


func pin_color_paths_for_save(valid_paths: Array, allow_key: Callable) -> Dictionary:
	return pin_color_paths_unlocked_only(normalized_paths(pin_color_paths, valid_paths), valid_paths, allow_key)


func random_pin_texture_path(valid_paths: Array, fallback_path: String) -> String:
	if valid_paths.is_empty():
		return fallback_path
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return str(valid_paths[rng.randi_range(0, valid_paths.size() - 1)])


func pin_texture_path_for_key(module_key: String, valid_paths: Array, fallback_path: String) -> String:
	var key := normalize(module_key)
	var path := str(pin_color_paths.get(key, ""))
	if not path.is_empty() and valid_paths.has(path):
		return path
	return fallback_path


func assign_random_pin_texture_path(module_key: String, valid_paths: Array, fallback_path: String) -> String:
	var key := normalize(module_key)
	if key.is_empty():
		return ""
	var texture_path := random_pin_texture_path(valid_paths, fallback_path)
	pin_color_paths[key] = texture_path
	return texture_path


func clear_pin_texture_path(module_key: String) -> void:
	var key := normalize(module_key)
	if not key.is_empty():
		pin_color_paths.erase(key)


func apply_pin_badge_texture(badge: TextureButton, module_key: String, valid_paths: Array, fallback_path: String, texture_for_path: Callable) -> void:
	if badge == null or not is_instance_valid(badge):
		return
	var texture_path := pin_texture_path_for_key(module_key, valid_paths, fallback_path)
	var texture: Texture2D = texture_for_path.call(texture_path) if texture_for_path.is_valid() else null
	badge.texture_normal = texture
	badge.texture_pressed = badge.texture_normal
	badge.texture_hover = badge.texture_normal
	badge.texture_disabled = badge.texture_normal
	badge.texture_focused = badge.texture_normal
	badge.set_meta("module_pin_texture_path", texture_path)


func collapsed_for_save(allow_key: Callable) -> Dictionary:
	return collapsed_unlocked_only(normalized_flags(collapsed), allow_key)


func sort_mode_for_save() -> String:
	return normalized_sort_mode(sort_mode)


func restore_from_save(data: Dictionary, valid_paths: Array, fallback_path: String, allow_key: Callable) -> bool:
	pinned_order = pinned_order_unlocked_only(normalized_order(data.get("module_ui_pinned_order", [])), allow_key)
	pin_color_paths = pin_color_paths_unlocked_only(normalized_paths(data.get("module_ui_pin_color_paths", {}), valid_paths), valid_paths, allow_key)
	for raw_key in pinned_order:
		var key := normalize(raw_key)
		if not key.is_empty() and not pin_color_paths.has(key):
			assign_random_pin_texture_path(key, valid_paths, fallback_path)
	pin_preview_tokens.clear()
	var collapse_save_version := int(data.get("module_ui_collapse_save_version", 0))
	var loaded_collapsed := normalized_flags(data.get("module_ui_collapsed", {}))
	collapsed = collapsed_unlocked_only(loaded_collapsed, allow_key) if collapse_save_version >= COLLAPSE_SAVE_VERSION else {}
	sort_mode = normalized_sort_mode(data.get("module_ui_sort_mode", SORT_LEVEL))
	combo_first = bool(data.get("module_ui_combo_first", false))
	collection_first = bool(data.get("module_ui_collection_first", false))
	return collapse_save_version < COLLAPSE_SAVE_VERSION and not loaded_collapsed.is_empty()


func pinned_order_unlocked_only(keys: Array, allow_key: Callable) -> Array:
	var filtered: Array = []
	for raw_key in keys:
		var key := normalize(raw_key)
		if _allowed(key, allow_key):
			filtered.append(key)
	return filtered


func pin_color_paths_unlocked_only(source: Dictionary, valid_paths: Array, allow_key: Callable) -> Dictionary:
	var filtered := {}
	for raw_key in source.keys():
		var key := normalize(raw_key)
		var path := str(source.get(raw_key, ""))
		if _allowed(key, allow_key) and valid_paths.has(path):
			filtered[key] = path
	return filtered


func collapsed_unlocked_only(source: Dictionary, allow_key: Callable) -> Dictionary:
	var filtered := {}
	for raw_key in source.keys():
		var key := normalize(raw_key)
		if _allowed(key, allow_key) and bool(source.get(raw_key, false)):
			filtered[key] = true
	return filtered


func key_allows_pin_or_collapse(module_key: String, action_allowed: Callable, heist_allowed: Callable, fishing_area_allowed: Callable) -> bool:
	var key := normalize(module_key)
	if key.is_empty():
		return false
	if key.begins_with(PREFIX_ACTION):
		var action_parts := key.substr(PREFIX_ACTION.length()).split(":", false, 2)
		return action_parts.size() >= 2 and action_allowed.is_valid() and bool(action_allowed.call(str(action_parts[0]), str(action_parts[1])))
	if key.begins_with(PREFIX_THIEVING_HEIST):
		return heist_allowed.is_valid() and bool(heist_allowed.call(key.substr(PREFIX_THIEVING_HEIST.length())))
	if key.begins_with(PREFIX_FISHING_AREA):
		return fishing_area_allowed.is_valid() and bool(fishing_area_allowed.call(key))
	return false


static func _prefix(prefix: String, id: String) -> String:
	return "" if id.is_empty() else "%s%s" % [prefix, id]


func _detail_entry_priority_bucket(entry: Dictionary, skill_id: String, combo_module: Callable, collection_module: Callable) -> int:
	var action := entry.get("action", {}) as Dictionary
	if combo_first and not action.is_empty() and bool(combo_module.call(skill_id, action)):
		return 0
	if collection_first and not action.is_empty() and bool(collection_module.call(skill_id, action)):
		return 1 if combo_first else 0
	return 2 if combo_first or collection_first else 0


func _detail_entry_tiebreaker(entry: Dictionary) -> String:
	match str(entry.get("kind", "action")):
		"thieving_heist":
			var heist := entry.get("heist", {}) as Dictionary
			return "%09d:heist:%s" % [int(heist.get("database_order", heist.get("unlock", 0))), str(heist.get("id", ""))]
		"fishing_area":
			var area_def := entry.get("area_def", {}) as Dictionary
			return "%09d:%s" % [int(area_def.get("module_index", area_def.get("unlock", 0))), str(area_def.get("id", ""))]
		"fishing_offer":
			return str(entry.get("offer_id", ""))
	var action := entry.get("action", {}) as Dictionary
	return "%09d:%s" % [int(action.get("database_order", action.get("unlock", 0))), str(action.get("id", ""))]


func _detail_entry_sort_less(left: Variant, right: Variant, skill_id: String, level_sort_value: Callable, combo_module: Callable, collection_module: Callable) -> bool:
	if typeof(left) != TYPE_DICTIONARY:
		return false
	if typeof(right) != TYPE_DICTIONARY:
		return true
	var left_entry := left as Dictionary
	var right_entry := right as Dictionary
	var left_bucket := _detail_entry_priority_bucket(left_entry, skill_id, combo_module, collection_module)
	var right_bucket := _detail_entry_priority_bucket(right_entry, skill_id, combo_module, collection_module)
	if left_bucket != right_bucket:
		return left_bucket < right_bucket
	var left_level := int(level_sort_value.call(left_entry, skill_id))
	var right_level := int(level_sort_value.call(right_entry, skill_id))
	if left_level != right_level:
		return left_level > right_level if sort_mode == SORT_LEVEL_REVERSE else left_level < right_level
	var left_tiebreaker := _detail_entry_tiebreaker(left_entry)
	var right_tiebreaker := _detail_entry_tiebreaker(right_entry)
	return left_tiebreaker > right_tiebreaker if sort_mode == SORT_LEVEL_REVERSE else left_tiebreaker < right_tiebreaker


func _lazy_entry_detail_sort_proxy(lazy_entry: Dictionary) -> Dictionary:
	match str(lazy_entry.get("kind", "")):
		"fishing_area":
			return {"kind": "fishing_area", "area_def": lazy_entry.get("area_def", {})}
		"fishing_offer":
			return {"kind": "fishing_offer", "offer_id": str(lazy_entry.get("offer_id", ""))}
		"heist":
			return {"kind": "thieving_heist", "heist": (lazy_entry.get("entry", {}) as Dictionary).get("heist", {})}
		_:
			return (lazy_entry.get("entry", {}) as Dictionary).duplicate()


func _allowed(key: String, allow_key: Callable) -> bool:
	return not key.is_empty() and allow_key.is_valid() and bool(allow_key.call(key))
