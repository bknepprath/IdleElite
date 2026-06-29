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


static func time_text(row_data: Dictionary) -> String:
	var created := maxi(0, int(row_data.get("created_at_unix", 0)))
	if created <= 0:
		return ""
	var timestamp := central_datetime_from_unix_time(created)
	return "%02d:%02d" % [int(timestamp.get("hour", 0)), int(timestamp.get("minute", 0))]


static func central_datetime_from_unix_time(unix_time: int) -> Dictionary:
	var offset_seconds := -5 * 60 * 60 if central_daylight_time_active(unix_time) else -6 * 60 * 60
	return Time.get_datetime_dict_from_unix_time(unix_time + offset_seconds)


static func central_daylight_time_active(unix_time: int) -> bool:
	var utc := Time.get_datetime_dict_from_unix_time(unix_time)
	var year := int(utc.get("year", 1970))
	var dst_start_utc := central_dst_transition_utc(year, 3, 2, 2, -6)
	var dst_end_utc := central_dst_transition_utc(year, 11, 1, 2, -5)
	return unix_time >= dst_start_utc and unix_time < dst_end_utc


static func central_dst_transition_utc(year: int, month: int, sunday_ordinal: int, local_hour: int, offset_hours_before_transition: int) -> int:
	var day := nth_sunday_day_of_month(year, month, sunday_ordinal)
	var local_unix := Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": day,
		"hour": local_hour,
		"minute": 0,
		"second": 0
	})
	return int(local_unix) - offset_hours_before_transition * 60 * 60


static func nth_sunday_day_of_month(year: int, month: int, sunday_ordinal: int) -> int:
	var first_day_unix := Time.get_unix_time_from_datetime_dict({
		"year": year,
		"month": month,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	})
	var first_day := Time.get_datetime_dict_from_unix_time(first_day_unix)
	var first_weekday := int(first_day.get("weekday", 0))
	var first_sunday := 1 if first_weekday == 0 else 8 - first_weekday
	return first_sunday + (maxi(1, sunday_ordinal) - 1) * 7
