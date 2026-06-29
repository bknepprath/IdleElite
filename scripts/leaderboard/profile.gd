class_name LeaderboardProfile


static func valid_avatar_index(index: int, avatar_count: int) -> int:
	if avatar_count <= 0:
		return 0
	return clampi(index, 0, avatar_count - 1)


static func sanitize_display_name(raw_name: String, max_chars: int) -> String:
	var clean := raw_name.strip_edges()
	clean = clean.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	while clean.contains("  "):
		clean = clean.replace("  ", " ")
	if clean.length() > max_chars:
		clean = clean.substr(0, max_chars).strip_edges()
	return clean


static func name_key(display_name: String, display_max_chars: int, key_max_chars: int) -> String:
	var clean := sanitize_display_name(display_name, display_max_chars).to_lower()
	var key := ""
	var last_was_separator := false
	for i in range(clean.length()):
		var code := clean.unicode_at(i)
		var is_digit := code >= 48 and code <= 57
		var is_lower := code >= 97 and code <= 122
		if is_digit or is_lower:
			key += char(code)
			last_was_separator = false
		elif code == 32 or code == 45 or code == 95:
			if not key.is_empty() and not last_was_separator:
				key += "_"
				last_was_separator = true
	while key.ends_with("_"):
		key = key.substr(0, key.length() - 1)
	if key.length() > key_max_chars:
		key = key.substr(0, key_max_chars)
		while key.ends_with("_"):
			key = key.substr(0, key.length() - 1)
	return sanitize_name_key(key, key_max_chars)


static func sanitize_name_key(raw_key: String, max_chars: int) -> String:
	var clean := raw_key.strip_edges().to_lower()
	if clean.length() <= 0 or clean.length() > max_chars:
		return ""
	for i in range(clean.length()):
		var code := clean.unicode_at(i)
		var is_digit := code >= 48 and code <= 57
		var is_lower := code >= 97 and code <= 122
		var is_underscore := code == 95
		if not (is_digit or is_lower or is_underscore):
			return ""
	return clean


static func is_default_display_name(display_name: String, max_chars: int) -> bool:
	var clean := sanitize_display_name(display_name, max_chars)
	return clean.is_empty() or clean == "You"


static func is_guest_display_name(display_name: String, prefix: String, max_chars: int) -> bool:
	var clean := sanitize_display_name(display_name, max_chars)
	if clean.is_empty() or clean == "You":
		return true
	if not clean.begins_with(prefix):
		return false
	if clean.length() != prefix.length() + 4:
		return false
	for i in range(prefix.length(), clean.length()):
		var code := clean.unicode_at(i)
		if code < 48 or code > 57:
			return false
	return true


static func make_guest_display_name(prefix: String) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%s%04d" % [prefix, rng.randi_range(0, 9999)]


static func make_player_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var alphabet := "0123456789abcdef"
	var token := ""
	for _i in range(32):
		token += alphabet.substr(rng.randi_range(0, alphabet.length() - 1), 1)
	return "p%s" % token


static func sanitize_player_id(raw_id: String) -> String:
	var clean := raw_id.strip_edges()
	if clean.length() < 8 or clean.length() > 48:
		return ""
	for i in range(clean.length()):
		var code := clean.unicode_at(i)
		var is_digit := code >= 48 and code <= 57
		var is_lower := code >= 97 and code <= 122
		var is_upper := code >= 65 and code <= 90
		var is_dash := code == 45
		var is_underscore := code == 95
		if not (is_digit or is_lower or is_upper or is_dash or is_underscore):
			return ""
	return clean
