class_name TemporaryEventState


static func save_payload(active_events: Dictionary, cooldowns: Dictionary, next_roll_unix: int) -> Dictionary:
	return {
		"active": active_events,
		"cooldowns": cooldowns,
		"next_roll_unix": maxi(0, next_roll_unix)
	}


static func restored_state(value: Variant, event_def: Callable, page_level_eligible: Callable, spawn_level_from_entry: Callable) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {
			"active": {},
			"cooldowns": {},
			"next_roll_unix": 0
		}
	var temporary_events_save := value as Dictionary
	return {
		"active": normalized_active(temporary_events_save.get("active", {}), event_def, page_level_eligible, spawn_level_from_entry),
		"cooldowns": normalized_cooldowns(temporary_events_save.get("cooldowns", {}), event_def),
		"next_roll_unix": maxi(0, int(temporary_events_save.get("next_roll_unix", temporary_events_save.get("next_roll", 0))))
	}


static func normalized_active(value: Variant, event_def: Callable, page_level_eligible: Callable, spawn_level_from_entry: Callable) -> Dictionary:
	var normalized := {}
	if typeof(value) == TYPE_ARRAY:
		for raw_entry in (value as Array):
			var entry := active_entry_from_save("", raw_entry, event_def, page_level_eligible, spawn_level_from_entry)
			if not entry.is_empty():
				normalized[str(entry.get("id", ""))] = entry
		return normalized
	if typeof(value) != TYPE_DICTIONARY:
		return normalized
	for raw_event_id in (value as Dictionary).keys():
		var event_id := str(raw_event_id)
		var entry := active_entry_from_save(event_id, (value as Dictionary).get(raw_event_id, {}), event_def, page_level_eligible, spawn_level_from_entry)
		if not entry.is_empty():
			normalized[str(entry.get("id", ""))] = entry
	return normalized


static func active_entry_from_save(event_id_hint: String, value: Variant, event_def: Callable, page_level_eligible: Callable, spawn_level_from_entry: Callable) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var source := value as Dictionary
	var event_id := str(source.get("id", event_id_hint)).strip_edges()
	var definition := event_def.call(event_id) as Dictionary
	if definition.is_empty():
		return {}
	if not bool(source.get("completed", source.get("completion_state", false))) and not bool(page_level_eligible.call(definition)):
		return {}
	var event_meta := definition.get("event", {}) as Dictionary
	var spawned_unix := maxi(0, int(source.get("spawned_unix", source.get("spawn_time", 0))))
	var default_duration := maxi(1, int(event_meta.get("active_duration_seconds", 3600)))
	var expires_unix := maxi(spawned_unix, int(source.get("expires_unix", source.get("expiry_time", spawned_unix + default_duration))))
	var completed := bool(source.get("completed", source.get("completion_state", false)))
	var spawn_level := int(spawn_level_from_entry.call(source, definition))
	return {
		"id": event_id,
		"page": str(definition.get("page", "")),
		"spawn_level": spawn_level,
		"spawned_unix": spawned_unix,
		"expires_unix": expires_unix,
		"completed": completed,
		"completed_unix": maxi(0, int(source.get("completed_unix", 0)))
	}


static func normalized_cooldowns(value: Variant, event_def: Callable) -> Dictionary:
	var normalized := {}
	if typeof(value) != TYPE_DICTIONARY:
		return normalized
	for raw_event_id in (value as Dictionary).keys():
		var event_id := str(raw_event_id).strip_edges()
		var definition := event_def.call(event_id) as Dictionary
		if definition.is_empty():
			continue
		normalized[event_id] = maxi(0, int((value as Dictionary).get(raw_event_id, 0)))
	return normalized
