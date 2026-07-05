extends RefCounted

const GameFormatting = preload("res://scripts/core/formatting.gd")
const LOG_CURRENCY_ICON_TEXTURE := "res://assets/content/icons/resources/log-currency.png"
const SCRAPWOOD_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/scrapwood.png"
const SOFTWOOD_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/softwood.png"
const HARDWOOD_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/hardwood.png"
const HONEY_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/honey.png"
const BERRIES_MAT_ICON_TEXTURE := "res://assets/content/icons/resources/berries.png"
const MAT_COLLECTION_STONE_BACKGROUND_TEXTURE := "res://assets/content/ui/mats/mat-bg-stone.png"
const MAT_COLLECTION_WOOD_BACKGROUND_TEXTURE := "res://assets/content/ui/mats/mat-bg-wood.png"
const BUILD_REQUIRED_PLANK_PIECE_TEXTURES := [
	"res://assets/content/ui/build-required-wide-plank.png"
]
const PLANK_ICON_TEXTURE := "res://assets/content/icons/resources/plank.png"
const UPGRADE_ARROW_ICON_TEXTURE := "res://assets/content/icons/upgrades/upgrade-arrow.png"
const WOODCUTTING_LOG_COLLECTION_MAT_IDS := ["scrapwood", "softwood", "hardwood"]

const MAT_COLLECTION_DEFS := {
	"scrapwood": {
		"name": "Scrapwood",
		"icon": SCRAPWOOD_MAT_ICON_TEXTURE,
		"background": MAT_COLLECTION_WOOD_BACKGROUND_TEXTURE,
		"color": Color("#bd8f54"),
		"amount_digits": 1
	},
	"softwood": {
		"name": "Softwood",
		"icon": SOFTWOOD_MAT_ICON_TEXTURE,
		"background": MAT_COLLECTION_WOOD_BACKGROUND_TEXTURE,
		"color": Color("#74b85e"),
		"amount_digits": 0
	},
	"hardwood": {
		"name": "Hardwood",
		"icon": HARDWOOD_MAT_ICON_TEXTURE,
		"background": MAT_COLLECTION_WOOD_BACKGROUND_TEXTURE,
		"color": Color("#7c4728"),
		"amount_digits": 0
	},
	"honey": {
		"name": "Honey",
		"icon": HONEY_MAT_ICON_TEXTURE,
		"background": MAT_COLLECTION_WOOD_BACKGROUND_TEXTURE,
		"color": Color("#f2a814"),
		"amount_digits": 0
	},
	"berries": {
		"name": "Berries",
		"icon": BERRIES_MAT_ICON_TEXTURE,
		"background": MAT_COLLECTION_WOOD_BACKGROUND_TEXTURE,
		"color": Color("#d8456b"),
		"amount_digits": 0
	}
}

var wallet := {}
var legacy_softwood_amount := 0
var berry_prep := {}


func normalize_id(mat_id: String) -> String:
	var normalized := mat_id.strip_edges().to_lower()
	if normalized == "logs" or normalized == "log":
		return "softwood"
	return normalized


func has_definition(mat_id: String) -> bool:
	return MAT_COLLECTION_DEFS.has(normalize_id(mat_id))


func definition(mat_id: String) -> Dictionary:
	return MAT_COLLECTION_DEFS.get(normalize_id(mat_id), {}) as Dictionary


func display_name(mat_id: String) -> String:
	var def := definition(mat_id)
	return str(def.get("name", mat_id.capitalize()))


func icon_path(mat_id: String) -> String:
	var def := definition(mat_id)
	return str(def.get("icon", LOG_CURRENCY_ICON_TEXTURE))


func background_path(mat_id: String) -> String:
	var def := definition(mat_id)
	return str(def.get("background", MAT_COLLECTION_STONE_BACKGROUND_TEXTURE))


func color(mat_id: String) -> Color:
	var def := definition(mat_id)
	return def.get("color", Color("#b98245")) as Color


func rounded_amount(mat_id: String, amount: float) -> float:
	if normalize_id(mat_id) == "scrapwood":
		return floor(maxf(0.0, amount) * 10.0 + 0.5) / 10.0
	return maxf(0.0, amount)


func amount(mat_id: String) -> float:
	var normalized := normalize_id(mat_id)
	if normalized == "softwood":
		return maxf(float(legacy_softwood_amount), float(wallet.get(normalized, 0.0)))
	return maxf(0.0, float(wallet.get(normalized, 0.0)))


func set_amount(mat_id: String, new_amount: float) -> void:
	var normalized := normalize_id(mat_id)
	if not has_definition(normalized):
		return
	var safe_amount := rounded_amount(normalized, new_amount)
	wallet[normalized] = safe_amount
	if normalized == "softwood":
		legacy_softwood_amount = int(floor(safe_amount + 0.0001))


func add_amount(mat_id: String, delta: float) -> float:
	var normalized := normalize_id(mat_id)
	if not has_definition(normalized):
		return 0.0
	var gained := rounded_amount(normalized, delta)
	set_amount(normalized, amount(normalized) + gained)
	return gained


func spend_amount(mat_id: String, cost: float) -> bool:
	var normalized := normalize_id(mat_id)
	var safe_cost := maxf(0.0, cost)
	if amount(normalized) + 0.0001 < safe_cost:
		return false
	set_amount(normalized, amount(normalized) - safe_cost)
	return true


func amount_text(mat_id: String, amount_override: float, compact_number: Callable, trim_zeroes: Callable) -> String:
	var normalized := normalize_id(mat_id)
	var value := amount(normalized) if amount_override < -0.0001 else maxf(0.0, amount_override)
	if normalized == "scrapwood":
		if value < 1000.0:
			return str(trim_zeroes.call("%.1f" % rounded_amount(normalized, value)))
		return str(compact_number.call(value, 3))
	return str(compact_number.call(floor(value + 0.0001), 3))


func amount_text_for_host(mat_id: String, amount_override: float = -1.0, host = null) -> String:
	return amount_text(mat_id, amount_override, Callable(GameFormatting, "compact_number"), Callable(GameFormatting, "trim_trailing_decimal_zeroes"))


func save_wallet() -> Dictionary:
	var saved := {}
	for raw_mat_id in MAT_COLLECTION_DEFS.keys():
		var mat_id := str(raw_mat_id)
		var current_amount := amount(mat_id)
		if current_amount > 0.0001:
			saved[mat_id] = current_amount
	return saved


func restore_wallet(data: Dictionary) -> void:
	wallet = {}
	var loaded = data.get("mats", {})
	if typeof(loaded) == TYPE_DICTIONARY:
		for raw_mat_id in (loaded as Dictionary).keys():
			var mat_id := normalize_id(str(raw_mat_id))
			if has_definition(mat_id):
				set_amount(mat_id, float((loaded as Dictionary).get(raw_mat_id, 0.0)))
	var legacy_logs := maxi(0, int(data.get("log_currency", legacy_softwood_amount)))
	if legacy_logs > 0 and amount("softwood") <= 0.0001:
		set_amount("softwood", float(legacy_logs))
	var softwood_amount := amount("softwood")
	legacy_softwood_amount = maxi(0, int(floor(softwood_amount + 0.0001))) if softwood_amount > 0.0001 else legacy_logs


func is_woodcutting_log_mat(mat_id: String) -> bool:
	return WOODCUTTING_LOG_COLLECTION_MAT_IDS.has(normalize_id(mat_id))


func buffed_log_collection_amount(mat_id: String, amount: float, multiplier: float) -> float:
	var safe_amount := maxf(0.0, amount)
	if safe_amount <= 0.0001 or not is_woodcutting_log_mat(mat_id):
		return safe_amount
	return safe_amount * multiplier


func woodcutting_log_collection_multiplier(woodcutting_level: int) -> float:
	return 1.0 + maxf(0.0, float(woodcutting_level)) / 100.0


func buffed_log_collection_amount_for_host(mat_id: String, amount: float, host) -> float:
	return buffed_log_collection_amount(mat_id, amount, woodcutting_log_collection_multiplier(SkillState.host_skill_level(host, "woodcutting")))


func berry_prep_target_key(skill_id: String, action_id: String, action_lookup: Callable, action_key: Callable) -> String:
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	var action = action_lookup.call(skill_id, action_id)
	if typeof(action) != TYPE_DICTIONARY or (action as Dictionary).is_empty():
		return ""
	return str(action_key.call(skill_id, str((action as Dictionary).get("id", action_id))))


func berry_prep_for_save(action_lookup: Callable) -> Dictionary:
	var targets := {}
	for raw_key in (berry_prep.get("targets", {}) as Dictionary).keys():
		var key := str(raw_key)
		if _berry_prep_action_exists_for_key(key, action_lookup):
			targets[key] = true
	if targets.is_empty():
		return {}
	return {"targets": targets}


func restore_berry_prep(value: Variant, action_lookup: Callable, action_key: Callable) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		berry_prep = {}
		return
	var targets := {}
	var raw_targets: Variant = (value as Dictionary).get("targets", {})
	if typeof(raw_targets) == TYPE_DICTIONARY:
		for raw_key in (raw_targets as Dictionary).keys():
			var normalized := _normalized_berry_prep_key(str(raw_key), action_lookup, action_key)
			if not normalized.is_empty():
				targets[normalized] = true
	else:
		var legacy_key := _normalized_berry_prep_key(str((value as Dictionary).get("target_key", "")), action_lookup, action_key)
		if not legacy_key.is_empty():
			targets[legacy_key] = true
	berry_prep = {} if targets.is_empty() else {"targets": targets}


func berry_prep_matches(skill_id: String, action_id: String, action_lookup: Callable, action_key: Callable) -> bool:
	var key := berry_prep_target_key(skill_id, action_id, action_lookup, action_key)
	return not key.is_empty() and bool((berry_prep.get("targets", {}) as Dictionary).get(key, false))


func toggle_berry_prep_target(skill_id: String, action_id: String, action_lookup: Callable, action_key: Callable) -> bool:
	var target_key := berry_prep_target_key(skill_id, action_id, action_lookup, action_key)
	if target_key.is_empty():
		return false
	if not berry_prep.has("targets") or typeof(berry_prep.get("targets")) != TYPE_DICTIONARY:
		berry_prep["targets"] = {}
	var targets := berry_prep["targets"] as Dictionary
	if bool(targets.get(target_key, false)):
		targets.erase(target_key)
		return false
	targets[target_key] = true
	return true


func consume_berry_prep_bonus(skill_id: String, action_id: String, reward_map: Dictionary, action_lookup: Callable, action_key: Callable) -> Dictionary:
	if not berry_prep_matches(skill_id, action_id, action_lookup, action_key):
		return {}
	if amount("berries") < 1.0 or not spend_amount("berries", 1.0):
		return {}
	var bonus_xp := maxi(1, int(ceil(float(_reward_map_total(reward_map)))))
	reward_map[skill_id] = maxi(0, int(reward_map.get(skill_id, 0))) + bonus_xp
	return {
		"bonus_xp": bonus_xp,
		"mat_id": "berries"
	}


func berry_prep_result_text(result: Dictionary) -> String:
	var bonus_xp := maxi(0, int(result.get("bonus_xp", 0)))
	if bonus_xp <= 0:
		return ""
	return "Berry used 1 Berries for +%s XP and doubled loot." % bonus_xp


func _normalized_berry_prep_key(key: String, action_lookup: Callable, action_key: Callable) -> String:
	var parts := key.split(":", false, 1)
	if parts.size() != 2:
		return ""
	return berry_prep_target_key(str(parts[0]), str(parts[1]), action_lookup, action_key)


func _berry_prep_action_exists_for_key(key: String, action_lookup: Callable) -> bool:
	var parts := key.split(":", false, 1)
	if parts.size() != 2:
		return false
	var action = action_lookup.call(str(parts[0]), str(parts[1]))
	return typeof(action) == TYPE_DICTIONARY and not (action as Dictionary).is_empty()


func _reward_map_total(reward_map: Dictionary) -> int:
	var total := 0
	for raw_value in reward_map.values():
		total += maxi(0, int(raw_value))
	return total
