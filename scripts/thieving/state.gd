class_name ThievingState
extends RefCounted

const HEIST_BACKGROUND_SHEET := "res://assets/content/thieving/heists/thieving-trophy-heist-backgrounds-wide.png"
const HEIST_TROPHY_SHEET := "res://assets/content/thieving/trophies/thieving-trophy-sheet.png"
const HEIST_JAIL_BARS_TEXTURE := "res://assets/content/thieving/heists/thieving-jail-bars-overlay.png"
const HEIST_BACKGROUND_CELL := Vector2(1536, 880)
const HEIST_TROPHY_CELL := Vector2(256, 256)
const HEIST_LEVEL_SUCCESS_BONUS := 0.75
const HEIST_MAX_SUCCESS := 95.0
const ACTION_JAIL_BASE_SECONDS := 5
const ACTION_JAIL_SECONDS_PER_UNLOCK_LEVEL := 2
const ACTION_JAIL_MIN_SECONDS := 6
const HEIST_DEFS := [
	{
		"id": "complimentary_spoon",
		"name": "Case The Cafe Display",
		"trophy": "The Complimentary Spoon",
		"unlock": 8,
		"tier": 1,
		"cell": 0,
		"xp": 250,
		"success": 88.0,
		"cooldown_seconds": 60,
		"success_text": "Acquired: The Complimentary Spoon.",
		"failure_text": "Jailed for spoon hesitation."
	},
	{
		"id": "crown_jewel_replica_replica",
		"name": "Lift The Replica's Replica",
		"trophy": "The Crown Jewel Replica Replica",
		"unlock": 20,
		"tier": 2,
		"cell": 1,
		"xp": 1000,
		"success": 68.0,
		"cooldown_seconds": 15 * 60,
		"success_text": "Acquired: The Crown Jewel Replica Replica.",
		"failure_text": "Jailed for fake jewel confusion."
	},
	{
		"id": "bad_decisions_idol",
		"name": "Dodge The Temple Refund Policy",
		"trophy": "The Idol Of Slightly Bad Decisions",
		"unlock": 32,
		"tier": 3,
		"cell": 2,
		"xp": 3000,
		"success": 48.0,
		"cooldown_seconds": 60 * 60,
		"success_text": "Acquired: The Idol Of Slightly Bad Decisions.",
		"failure_text": "Jailed under museum-temple policy."
	},
	{
		"id": "borrowed_empire_crown",
		"name": "Empty The Imperial Exhibit",
		"trophy": "The Crown Of Borrowed Empire",
		"unlock": 65,
		"tier": 4,
		"cell": 3,
		"xp": 12000,
		"success": 32.0,
		"cooldown_seconds": 3 * 60 * 60,
		"success_text": "Acquired: The Crown Of Borrowed Empire.",
		"failure_text": "Jailed for diplomatic crown nonsense."
	}
]

var host
var trophies := {}
var action_jails := {}
var pending_trophy_reward_float := {}
var last_action_jail_process_unix := 0


func _init(host_ref = null) -> void:
	host = host_ref


func reset() -> void:
	trophies.clear()
	action_jails.clear()
	pending_trophy_reward_float.clear()
	last_action_jail_process_unix = 0


func visible_heists_for_render() -> Array:
	var visible_heists := []
	var pending_heist_id := ""
	var pending_key := str(pending_trophy_reward_float.get("key", "")) if not pending_trophy_reward_float.is_empty() else ""
	if pending_key.begins_with("thieving_heist:"):
		pending_heist_id = pending_key.substr("thieving_heist:".length())
	for i in range(HEIST_DEFS.size()):
		var heist := HEIST_DEFS[i] as Dictionary
		var heist_id := str(heist.get("id", ""))
		if _skill_level() < int(heist.get("unlock", 1)):
			continue
		if i > 0 and not trophy_stolen(str((HEIST_DEFS[i - 1] as Dictionary).get("id", ""))):
			continue
		if trophy_stolen(heist_id) and heist_id != pending_heist_id:
			continue
		visible_heists.append(heist)
	return visible_heists


func heist_preceding_action(heist: Dictionary) -> Dictionary:
	var heist_unlock := int(heist.get("unlock", 1))
	var best_action := {}
	var best_unlock := -1
	if host == null:
		return best_action
	for raw_action in host.actions_by_skill.get("thieving", []):
		var action := raw_action as Dictionary
		if action.is_empty():
			continue
		var action_unlock := int(action.get("unlock", 1))
		if action_unlock >= heist_unlock:
			continue
		if action_unlock >= best_unlock:
			best_action = action
			best_unlock = action_unlock
	return best_action


func heist_revealed_by_action_unlock(skill_id: String, action: Dictionary) -> String:
	if skill_id != "thieving" or action.is_empty():
		return ""
	var action_id := str(action.get("id", ""))
	if action_id.is_empty():
		return ""
	for i in range(HEIST_DEFS.size()):
		var heist := HEIST_DEFS[i] as Dictionary
		var heist_id := str(heist.get("id", ""))
		if heist_id.is_empty() or trophy_stolen(heist_id):
			continue
		if _skill_level() < int(heist.get("unlock", 1)):
			continue
		if i > 0 and not trophy_stolen(str((HEIST_DEFS[i - 1] as Dictionary).get("id", ""))):
			continue
		var preceding_action := heist_preceding_action(heist)
		if str(preceding_action.get("id", "")) == action_id:
			return heist_id
	return ""


func heist_def(heist_id: String) -> Dictionary:
	for raw_heist in HEIST_DEFS:
		var heist := raw_heist as Dictionary
		if str(heist.get("id", "")) == heist_id:
			return heist
	return {}


func ensure_trophy_state(heist_id: String) -> Dictionary:
	if heist_id.is_empty():
		return {}
	if not trophies.has(heist_id) or typeof(trophies[heist_id]) != TYPE_DICTIONARY:
		trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
	var state := trophies[heist_id] as Dictionary
	if not state.has("stolen"):
		state["stolen"] = false
	if not state.has("cooldown_until_unix"):
		state["cooldown_until_unix"] = int(state.get("cooldown_until", 0))
	trophies[heist_id] = state
	return state


func ensure_all_trophy_state() -> void:
	for raw_heist in HEIST_DEFS:
		var heist := raw_heist as Dictionary
		ensure_trophy_state(str(heist.get("id", "")))


func trophy_stolen(heist_id: String) -> bool:
	return bool(ensure_trophy_state(heist_id).get("stolen", false))


func heist_cooldown_remaining(heist_id: String, now: int) -> int:
	var state := ensure_trophy_state(heist_id)
	return maxi(0, int(state.get("cooldown_until_unix", 0)) - now)


func best_trophy_tier(max_level: int) -> int:
	var best := 0
	for raw_heist in HEIST_DEFS:
		var heist := raw_heist as Dictionary
		if trophy_stolen(str(heist.get("id", ""))):
			best = maxi(best, int(heist.get("tier", 0)))
	return clampi(best, 0, max_level)


func action_jails_for_save(now: int, canonical_action_id: Callable, action_data: Callable) -> Dictionary:
	return normalized_action_jails(action_jails, now, canonical_action_id, action_data)


func trophies_for_save() -> Dictionary:
	return normalized_trophies(trophies, Callable(self, "heist_def"))


func restore_action_jails(loaded_jails: Variant, now: int, canonical_action_id: Callable, action_data: Callable) -> void:
	action_jails = normalized_action_jails(loaded_jails, now, canonical_action_id, action_data, true)


func restore_trophies(loaded_trophies: Variant, accept_legacy_bool := true) -> void:
	trophies = normalized_trophies(loaded_trophies, Callable(self, "heist_def"), accept_legacy_bool)


func _skill_level() -> int:
	return host._skill_level("thieving") if host != null else 1


static func normalized_trophies(loaded_trophies: Variant, heist_def: Callable, accept_legacy_bool := false) -> Dictionary:
	var normalized := {}
	if typeof(loaded_trophies) != TYPE_DICTIONARY:
		return normalized
	var source := loaded_trophies as Dictionary
	for raw_trophy_id in source.keys():
		var trophy_id := str(raw_trophy_id)
		var trophy_def := heist_def.call(trophy_id) as Dictionary
		if trophy_def.is_empty():
			continue
		var raw_trophy_state = source.get(raw_trophy_id, {})
		if typeof(raw_trophy_state) == TYPE_DICTIONARY:
			var state := raw_trophy_state as Dictionary
			normalized[trophy_id] = {
				"stolen": bool(state.get("stolen", false)),
				"cooldown_until_unix": maxi(0, int(state.get("cooldown_until_unix", state.get("cooldown_until_unix_msec", 0))))
			}
		elif accept_legacy_bool and typeof(raw_trophy_state) == TYPE_BOOL:
			normalized[trophy_id] = {"stolen": bool(raw_trophy_state), "cooldown_until_unix": 0}
	return normalized


static func normalized_action_jails(
	loaded_jails: Variant,
	now: int,
	canonical_action_id: Callable,
	action_data: Callable,
	accept_legacy_scalar := false
) -> Dictionary:
	var normalized := {}
	if typeof(loaded_jails) != TYPE_DICTIONARY:
		return normalized
	var source := loaded_jails as Dictionary
	for raw_action_id in source.keys():
		var action_id := str(canonical_action_id.call("thieving", str(raw_action_id)))
		var action := action_data.call("thieving", action_id) as Dictionary
		if action_id.is_empty() or action.is_empty():
			continue
		var raw_state = source.get(raw_action_id, {})
		var cooldown_until := 0
		var resume_when_free := false
		if typeof(raw_state) == TYPE_DICTIONARY:
			var state := raw_state as Dictionary
			if state.has("show_bars") and not bool(state.get("show_bars", true)):
				continue
			cooldown_until = maxi(0, int(state.get("cooldown_until_unix", 0)))
			resume_when_free = bool(state.get("resume_when_free", false))
		elif accept_legacy_scalar:
			cooldown_until = maxi(0, int(raw_state))
		else:
			continue
		if cooldown_until <= now:
			continue
		normalized[action_id] = {
			"cooldown_until_unix": cooldown_until,
			"resume_when_free": resume_when_free
		}
	return normalized
