class_name ThievingState


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
