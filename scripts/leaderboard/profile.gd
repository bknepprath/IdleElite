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


static func metadata_for_save(display_name: String, raw_name_key: String, claimed: bool, verified: bool, guest_prefix: String, display_max_chars: int, key_max_chars: int) -> Dictionary:
	var safe_display_name := sanitize_display_name(display_name, display_max_chars)
	var safe_name_key := sanitize_name_key(raw_name_key, key_max_chars)
	if is_default_display_name(safe_display_name, display_max_chars) or is_guest_display_name(safe_display_name, guest_prefix, display_max_chars):
		return {"name_key": "", "profile_claimed": false, "name_claim_verified": false}
	if claimed and safe_name_key.is_empty():
		safe_name_key = name_key(safe_display_name, display_max_chars, key_max_chars)
	if not claimed or not verified or safe_name_key.is_empty():
		return {"name_key": "", "profile_claimed": false, "name_claim_verified": false}
	return {"name_key": safe_name_key, "profile_claimed": true, "name_claim_verified": true}


static func restored_metadata(data: Dictionary, current_display_name: String, current_name_key: String, current_avatar_index: int, current_player_id: String, make_guest: Callable, guest_prefix: String, display_max_chars: int, key_max_chars: int, avatar_count: int) -> Dictionary:
	var display_name := sanitize_display_name(str(data.get("leaderboard_display_name", current_display_name)), display_max_chars)
	var safe_name_key := sanitize_name_key(str(data.get("leaderboard_name_key", current_name_key)), key_max_chars)
	var claimed := bool(data.get("leaderboard_profile_claimed", false))
	var verified := bool(data.get("leaderboard_name_claim_verified", false))
	if is_default_display_name(display_name, display_max_chars):
		display_name = str(make_guest.call())
		claimed = false
		verified = false
		safe_name_key = ""
	if is_guest_display_name(display_name, guest_prefix, display_max_chars):
		claimed = false
		verified = false
		safe_name_key = ""
	if claimed and safe_name_key.is_empty():
		safe_name_key = name_key(display_name, display_max_chars, key_max_chars)
	if claimed and not verified:
		claimed = false
		safe_name_key = ""
	return {
		"display_name": display_name,
		"name_key": safe_name_key,
		"profile_claimed": claimed,
		"name_claim_verified": verified,
		"avatar_index": valid_avatar_index(int(data.get("leaderboard_avatar_index", current_avatar_index)), avatar_count),
		"player_id": sanitize_player_id(str(data.get("leaderboard_player_id", current_player_id)))
	}


static func refresh_token_for_save(refresh_token: String) -> String:
	return refresh_token.strip_edges()


static func auth_provider_for_save(provider: String) -> String:
	return "google" if provider == "google" else "anonymous"
