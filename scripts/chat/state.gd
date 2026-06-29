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
