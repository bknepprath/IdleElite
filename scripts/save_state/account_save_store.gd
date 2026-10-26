extends RefCounted

# A recoverable transaction separates account saves from the active save and its
# backups. The normal save guards are never relaxed for automatic cloud sync.
const ROOT := "user://accounts"
const PENDING := ROOT + "/pending.json"

static func slot(payload: Dictionary) -> String:
	if str(payload.get("leaderboard_auth_provider", "")) != "google":
		return ROOT + "/guest.json"
	return ROOT + "/" + str(payload.get("leaderboard_auth_bound_uid", "")).sha256_text() + ".json"

static func stash(api: Script, payload: Dictionary) -> bool:
	if DirAccess.make_dir_recursive_absolute(ROOT) != OK:
		return false
	return api.write_payload_atomically(payload, slot(payload), slot(payload) + ".tmp", slot(payload) + ".backup")

static func stage(api: Script, current: Dictionary, target: Dictionary) -> bool:
	if FileAccess.file_exists(PENDING) or not api._payload_semantic_error(target, int(target.get("save_schema_version", 0))).is_empty():
		return false
	if not stash(api, current):
		return false
	var transaction := ROOT + "/switch-%s-%s" % [Time.get_ticks_usec(), randi()]
	if DirAccess.make_dir_recursive_absolute(transaction) != OK:
		return false
	var target_path := transaction + "/target.json"
	var encoded: String = api.encoded_payload(target)
	if not api.write_text(target_path, encoded) or api.load_dictionary(target_path).is_empty() or FileAccess.get_file_as_string(target_path) != encoded:
		return false
	# Commit intent before touching any active files. Restart resumes this exact
	# verified target, never a mix of one account's primary and another's backups.
	if not api.write_text(PENDING + ".tmp", JSON.stringify({"directory": transaction})):
		return false
	if not api._replace_with_staged_file(PENDING + ".tmp", PENDING):
		return false
	return recover(api)

static func recover(api: Script) -> bool:
	if not FileAccess.file_exists(PENDING):
		return true
	var marker = JSON.parse_string(FileAccess.get_file_as_string(PENDING))
	if not marker is Dictionary:
		return false
	var directory := str(marker.get("directory", ""))
	if not directory.begins_with(ROOT + "/switch-") or directory.contains("..") or directory.trim_prefix(ROOT + "/").contains("/") or directory.contains("\\"):
		return false
	var target_path := directory + "/target.json"
	var target: Dictionary = api.load_dictionary(target_path)
	if target.is_empty():
		return false
	var paths := [api.SAVE_PATH, api.SAVE_TEMP_PATH, api.SAVE_BACKUP_PATH, api.SAVE_BACKUP_2_PATH, api.SAVE_BACKUP_3_PATH, api.SAVE_RECOVERY_SNAPSHOT_PATH]
	# Copy every old file and verify bytes before moving any of them.
	for path in paths:
		if not FileAccess.file_exists(path):
			continue
		var archived := directory + "/" + str(path).get_file()
		if not FileAccess.file_exists(archived):
			if DirAccess.copy_absolute(path, archived) != OK or FileAccess.get_sha256(path) != FileAccess.get_sha256(archived):
				return false
	# Once archived, remove active copies. Re-running this step after interruption
	# is safe: target.json and all previous files remain in the transaction folder.
	for path in paths:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) != OK:
			return false
	if not api.copy_valid_save(target_path, api.SAVE_PATH, api.SAVE_TEMP_PATH):
		return false
	return DirAccess.remove_absolute(PENDING) == OK
