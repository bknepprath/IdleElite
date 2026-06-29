class_name FirebaseCloudSave


static func account_ready(auth_ready: bool, auth_provider: String) -> bool:
	return auth_ready and auth_provider == "google"


static func status_text(
	firebase_enabled: bool,
	auth_provider: String,
	profile_claim_valid: bool,
	google_auth_status_message: String,
	upload_in_flight: bool,
	fetch_in_flight: bool,
	cloud_status_message: String
) -> String:
	if not firebase_enabled:
		return "Cloud save is offline until Firebase is configured."
	if auth_provider != "google":
		if not profile_claim_valid:
			return "Save a username before connecting Google."
		if google_auth_status_message.is_empty():
			return "Connect Google to back up progress to your account."
		return google_auth_status_message
	if upload_in_flight:
		return "Uploading cloud save..."
	if fetch_in_flight:
		return "Checking cloud save..."
	if not cloud_status_message.is_empty():
		return cloud_status_message
	return "Google connected. Progress saves to your account automatically."


static func summary(payload: Dictionary, total_skill_xp: int, total_level: int) -> Dictionary:
	return {
		"save_schema_version": int(payload.get("save_schema_version", 0)),
		"saved_at": maxi(0, int(payload.get("saved_at", 0))),
		"total_skill_xp": total_skill_xp,
		"total_level": total_level
	}


static func payload_json(payload: Dictionary, max_chars: int) -> String:
	var text := JSON.stringify(payload)
	if text.length() > max_chars:
		return ""
	return text


static func record(
	payload: Dictionary,
	now: int,
	uid: String,
	server_timestamp: Dictionary,
	total_skill_xp: int,
	total_level: int,
	schema_version: int,
	max_payload_chars: int
) -> Dictionary:
	return {
		"uid": uid,
		"updated_at": server_timestamp,
		"updated_at_unix": now,
		"save_schema_version": int(payload.get("save_schema_version", schema_version)),
		"saved_at": maxi(0, int(payload.get("saved_at", now))),
		"total_skill_xp": total_skill_xp,
		"total_level": total_level,
		"payload_json": payload_json(payload, max_payload_chars)
	}
