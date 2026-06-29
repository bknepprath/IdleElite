class_name MaterialDefs


static func normalize_id(mat_id: String) -> String:
	var normalized := mat_id.strip_edges().to_lower()
	if normalized == "logs" or normalized == "log":
		return "softwood"
	return normalized


static func definition(mat_id: String, defs: Dictionary) -> Dictionary:
	return defs.get(normalize_id(mat_id), {}) as Dictionary


static func display_name(mat_id: String, defs: Dictionary) -> String:
	var def := definition(mat_id, defs)
	return str(def.get("name", mat_id.capitalize()))


static func icon_path(mat_id: String, defs: Dictionary, fallback_path: String) -> String:
	var def := definition(mat_id, defs)
	return str(def.get("icon", fallback_path))


static func background_path(mat_id: String, defs: Dictionary, fallback_path: String) -> String:
	var def := definition(mat_id, defs)
	return str(def.get("background", fallback_path))


static func color(mat_id: String, defs: Dictionary, fallback: Color) -> Color:
	var def := definition(mat_id, defs)
	return def.get("color", fallback) as Color


static func rounded_amount(mat_id: String, amount: float) -> float:
	if normalize_id(mat_id) == "scrapwood":
		return floor(maxf(0.0, amount) * 10.0 + 0.5) / 10.0
	return maxf(0.0, amount)
