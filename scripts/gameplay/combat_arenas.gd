class_name CombatArenas


static func uses_diamond_arena(action: Dictionary) -> bool:
	var combat: Variant = action.get("combat", {})
	if typeof(combat) != TYPE_DICTIONARY:
		return false
	return str((combat as Dictionary).get("arena_shape", "")).to_lower() == "diamond"
