class_name TipState


static func restored_metadata(data: Dictionary, valid_detail_tips: Array, action_key_for_save: Callable) -> Dictionary:
	return {
		"lock_click_tip_seen": bool(data.get("lock_click_tip_seen", false)),
		"passive_module_tip_seen": bool(data.get("passive_module_tip_seen", false)),
		"silver_opportunity_tip_seen": bool(data.get("silver_opportunity_tip_seen", false)),
		"silver_opportunity_tip_action_key": str(action_key_for_save.call(str(data.get("silver_opportunity_tip_action_key", "")))),
		"detail_pull_recent_tip_texts": normalized_recent_tip_texts(data.get("detail_pull_recent_tip_texts", []), valid_detail_tips)
	}


static func normalized_recent_tip_texts(value: Variant, valid_detail_tips: Array) -> Array:
	var normalized: Array = []
	if typeof(value) != TYPE_ARRAY:
		return normalized
	var valid_tips := {}
	for raw_tip in valid_detail_tips:
		valid_tips[str(raw_tip)] = true
	for raw_tip in value:
		var tip := str(raw_tip).strip_edges()
		if tip.is_empty() or not valid_tips.has(tip):
			continue
		normalized.erase(tip)
		normalized.append(tip)
		while normalized.size() > 3:
			normalized.pop_front()
	return normalized
