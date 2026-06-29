class_name AudioSettings


static func saved_volume(data: Dictionary, key: String, fallback: float) -> float:
	if not data.has(key):
		return clampf(fallback, 0.0, 1.0)
	var raw_value: Variant = data.get(key, fallback)
	if typeof(raw_value) != TYPE_FLOAT and typeof(raw_value) != TYPE_INT:
		return clampf(fallback, 0.0, 1.0)
	return clampf(float(raw_value), 0.0, 1.0)
