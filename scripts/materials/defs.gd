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


static func amount(mat_id: String, wallet: Dictionary, softwood_legacy_amount: int) -> float:
	var normalized := normalize_id(mat_id)
	if normalized == "softwood":
		return maxf(float(softwood_legacy_amount), float(wallet.get(normalized, 0.0)))
	return maxf(0.0, float(wallet.get(normalized, 0.0)))


static func set_amount(wallet: Dictionary, defs: Dictionary, mat_id: String, new_amount: float) -> Dictionary:
	var normalized := normalize_id(mat_id)
	if not defs.has(normalized):
		return {}
	var safe_amount := rounded_amount(normalized, new_amount)
	wallet[normalized] = safe_amount
	return {
		"id": normalized,
		"amount": safe_amount,
		"legacy_softwood_amount": int(floor(safe_amount + 0.0001)) if normalized == "softwood" else -1
	}


static func add_amount(wallet: Dictionary, defs: Dictionary, mat_id: String, delta: float, softwood_legacy_amount: int) -> Dictionary:
	var normalized := normalize_id(mat_id)
	if not defs.has(normalized):
		return {}
	var gained := rounded_amount(normalized, delta)
	var result := set_amount(wallet, defs, normalized, amount(normalized, wallet, softwood_legacy_amount) + gained)
	result["gained"] = gained
	return result


static func spend_amount(wallet: Dictionary, defs: Dictionary, mat_id: String, cost: float, softwood_legacy_amount: int) -> Dictionary:
	var normalized := normalize_id(mat_id)
	var safe_cost := maxf(0.0, cost)
	if amount(normalized, wallet, softwood_legacy_amount) + 0.0001 < safe_cost:
		return {}
	var result := set_amount(wallet, defs, normalized, amount(normalized, wallet, softwood_legacy_amount) - safe_cost)
	result["spent"] = true
	return result


static func save_wallet(wallet: Dictionary, defs: Dictionary, softwood_legacy_amount: int) -> Dictionary:
	var saved := {}
	for raw_mat_id in defs.keys():
		var mat_id := str(raw_mat_id)
		var current_amount := amount(mat_id, wallet, softwood_legacy_amount)
		if current_amount > 0.0001:
			saved[mat_id] = current_amount
	return saved


static func restored_wallet(data: Dictionary, defs: Dictionary, current_softwood_legacy_amount: int) -> Dictionary:
	var wallet := {}
	var loaded = data.get("mats", {})
	if typeof(loaded) == TYPE_DICTIONARY:
		for raw_mat_id in (loaded as Dictionary).keys():
			var mat_id := normalize_id(str(raw_mat_id))
			if not defs.has(mat_id):
				continue
			set_amount(wallet, defs, mat_id, float((loaded as Dictionary).get(raw_mat_id, 0.0)))
	var legacy_logs := maxi(0, int(data.get("log_currency", current_softwood_legacy_amount)))
	if legacy_logs > 0 and amount("softwood", wallet, 0) <= 0.0001:
		set_amount(wallet, defs, "softwood", float(legacy_logs))
	var softwood_amount := amount("softwood", wallet, 0)
	return {
		"wallet": wallet,
		"legacy_softwood_amount": maxi(0, int(floor(softwood_amount + 0.0001))) if softwood_amount > 0.0001 else legacy_logs
	}
