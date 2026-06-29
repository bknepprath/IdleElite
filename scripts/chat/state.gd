class_name ChatState


static func retry_unix_for_save(retry_unix: int, now_unix: int, retry_interval_seconds: int) -> int:
	return mini(maxi(0, int(retry_unix)), now_unix + retry_interval_seconds)


static func next_connect_unix_for_save(retry_unix: int, next_connect_unix: int, now_unix: int, retry_interval_seconds: int) -> int:
	var saved_retry_unix := retry_unix_for_save(retry_unix, now_unix, retry_interval_seconds)
	return mini(maxi(saved_retry_unix, int(next_connect_unix)), now_unix + retry_interval_seconds)


static func restored_retry_metadata(data: Dictionary, now_unix: int, retry_interval_seconds: int) -> Dictionary:
	var max_retry_unix := now_unix + retry_interval_seconds
	var retry_unix := mini(maxi(0, int(data.get("chat_stream_retry_unix", data.get("chat_fetch_retry_unix", 0)))), max_retry_unix)
	return {
		"retry_unix": retry_unix,
		"next_connect_unix": mini(maxi(retry_unix, int(data.get("chat_stream_next_connect_unix", 0))), max_retry_unix)
	}


static func normalized_message_id(raw_message_id: Variant) -> String:
	var message_id := str(raw_message_id).strip_edges()
	return message_id.substr(0, 64) if message_id.length() > 64 else message_id


static func sanitize_message(raw_text: String, max_chars: int, censored_words: Array) -> String:
	var clean := raw_text.strip_edges()
	clean = clean.replace("\n", " ").replace("\r", " ").replace("\t", " ")
	while clean.contains("  "):
		clean = clean.replace("  ", " ")
	clean = censored_message(clean, censored_words)
	if clean.length() > max_chars:
		clean = clean.substr(0, max_chars).strip_edges()
	return clean


static func censored_message(raw_text: String, censored_words: Array) -> String:
	var output := ""
	var token := ""
	for i in range(raw_text.length()):
		var ch := raw_text.substr(i, 1)
		if is_word_char(ch):
			token += ch
		else:
			output += censored_token(token, censored_words)
			token = ""
			output += ch
	output += censored_token(token, censored_words)
	return output


static func censored_token(token: String, censored_words: Array) -> String:
	if token.is_empty():
		return ""
	if censored_words.has(token.to_lower()):
		var mask := ""
		for _i in range(token.length()):
			mask += "*"
		return mask
	return token


static func is_word_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code := ch.unicode_at(0)
	return (
		(code >= 48 and code <= 57)
		or (code >= 65 and code <= 90)
		or (code >= 97 and code <= 122)
	)


static func make_message_id(now_unix: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var alphabet := "0123456789abcdef"
	var suffix := ""
	for _i in range(12):
		suffix += alphabet.substr(rng.randi_range(0, alphabet.length() - 1), 1)
	return "m%s_%s" % [now_unix, suffix]
