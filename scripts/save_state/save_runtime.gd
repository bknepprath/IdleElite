extends RefCounted

const SaveStateNormalizers = preload("res://scripts/save_state/normalizers.gd")
const AdBonus = preload("res://scripts/monetization/ad_bonus.gd")
const LeaderboardProfile = preload("res://scripts/leaderboard/profile.gd")
const LeaderboardState = preload("res://scripts/leaderboard/state.gd")
const ProfileChatOverlaySurface = preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const SkillDetailSurface = preload("res://scripts/ui/skill_detail_surface.gd")
const HubRuntime = preload("res://scripts/gameplay/hub_runtime.gd")
const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")
const AchievementState = preload("res://scripts/achievements/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")
const FishingState = preload("res://scripts/fishing/state.gd")
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")
const GameFormatting = preload("res://scripts/core/formatting.gd")
const ActionRuntime = preload("res://scripts/gameplay/action_runtime.gd")

const SAVE_PATH := "user://idle_elite_save.json"
const SAVE_TEMP_PATH := "user://idle_elite_save.tmp.json"
const SAVE_BACKUP_PATH := "user://idle_elite_save.backup.json"
const SAVE_BACKUP_2_PATH := "user://idle_elite_save.backup-2.json"
const SAVE_BACKUP_3_PATH := "user://idle_elite_save.backup-3.json"
const SAVE_RECOVERY_SNAPSHOT_PATH := "user://idle_elite_save.recovery.json"
const SAVE_JOURNAL_PATH := "user://idle_elite_save.journal.json"
const SAVE_JOURNAL_TEMP_PATH := "user://idle_elite_save.journal.tmp.json"
const SAVE_JOURNAL_MAX_EVENTS := 32
const SAVE_ENVELOPE_VERSION := 1
const SAVE_SCHEMA_VERSION := 2
const SAVE_PROFILE_DISPLAY_NAME_MAX_CHARS := 16
const SAVE_PROFILE_NAME_KEY_MAX_CHARS := 16
const SAVE_PROFILE_GUEST_NAME_PREFIX := "guest"
const TRUSTED_DESTRUCTIVE_REPAIR_MARKER := "idle-elite:destructive-save-repair:v1"
const TRUSTED_DESTRUCTIVE_REPAIR_KEY := "save_destructive_repair_authorization"
const AUTOSAVE_INTERVAL_SECONDS := 15.0
const SAVE_RECOVERY_BLOCK_MESSAGE := "Save recovery required.\nYour save files are preserved.\nDo not reinstall or clear app data.\nContact support."
const SAVE_STORAGE_BLOCK_MESSAGE := "Save storage could not be initialized.\nRestart the game before playing."

var host
var last_save_unix_time := 0
var last_save_monotonic_msec := -1
var save_dirty := false
var save_dirty_reason := ""
var allow_next_save_progress_regression := false
var next_save_identity_transition_source_uid := ""
var next_save_identity_transition_target_uid := ""
var next_save_vetted_progress_repair_source := {}
var next_save_vetted_progress_repair_payload := {}
var next_save_vetted_identity_repair_source := {}
var next_save_vetted_identity_repair_payload := {}
var next_save_vetted_identity_repair_requires_exact_claim := false
var save_reset_generation := 0
var save_repair_generation := 0
var save_revision := 0
var save_writes_blocked := false
var save_writes_blocked_reason := ""
var pending_post_load_saved_at := -1
var pending_save_restore_data := {}
var pending_save_has_achievement_toast_seen_ids := false
var achievement_toast_seen_ids := {}
var save_repaired_this_boot := false
var boot_post_load_simulation_scheduled := false


static func read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


static func write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var write_error := file.get_error()
	file.close()
	return write_error == OK


static func write_bytes(path: String, bytes: PackedByteArray) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.flush()
	var write_error := file.get_error()
	file.close()
	return write_error == OK


static func read_bytes_result(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"data": PackedByteArray(), "error": "open_failed"}
	var bytes := file.get_buffer(file.get_length())
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		return {"data": PackedByteArray(), "error": "read_failed"}
	return {"data": bytes, "error": ""}


static func load_dictionary(path: String) -> Dictionary:
	return load_dictionary_result(path).get("data", {}) as Dictionary


static func load_dictionary_result(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"data": {}, "error": "open_failed"}
	var raw := file.get_buffer(file.get_length()).get_string_from_utf8()
	var read_error := file.get_error()
	file.close()
	if read_error != OK:
		return {"data": {}, "error": "read_failed"}
	var json := JSON.new()
	if json.parse(raw) != OK:
		return {"data": {}, "error": "invalid_json", "raw": raw}
	var save_payload: Variant = json.data
	if typeof(save_payload) != TYPE_DICTIONARY:
		return {"data": {}, "error": "invalid_root", "raw": raw}
	var parsed := save_payload as Dictionary
	var enveloped := parsed.has("save_envelope_version")
	if enveloped:
		if typeof(parsed.get("save_envelope_version")) not in [TYPE_INT, TYPE_FLOAT] or int(parsed.get("save_envelope_version", 0)) != SAVE_ENVELOPE_VERSION:
			return {"data": {}, "error": "unsupported_envelope", "raw": raw}
		var payload_text_value = parsed.get("payload_json", null)
		var checksum_value = parsed.get("checksum", null)
		if typeof(payload_text_value) != TYPE_STRING or typeof(checksum_value) != TYPE_STRING:
			return {"data": {}, "error": "invalid_envelope", "raw": raw}
		var payload_text := str(payload_text_value)
		if payload_text.is_empty() or str(checksum_value) != payload_text.sha256_text():
			return {"data": {}, "error": "checksum_failed", "raw": raw}
		var payload_json := JSON.new()
		if payload_json.parse(payload_text) != OK or typeof(payload_json.data) != TYPE_DICTIONARY:
			return {"data": {}, "error": "invalid_envelope_payload", "raw": raw}
		parsed = payload_json.data as Dictionary
	var schema_value = parsed.get("save_schema_version", 0)
	if typeof(schema_value) not in [TYPE_INT, TYPE_FLOAT]:
		return {"data": {}, "error": "invalid_schema", "raw": raw}
	var schema_version := int(schema_value)
	if schema_version < 0:
		return {"data": {}, "error": "invalid_schema", "raw": raw}
	if schema_version > SAVE_SCHEMA_VERSION:
		return {
			"data": {},
			"error": "future_schema",
			"schema_version": schema_version,
			"raw": raw,
		}
	var semantic_error := _payload_semantic_error(parsed, schema_version)
	if not semantic_error.is_empty():
		return {"data": {}, "error": semantic_error, "schema_version": schema_version, "raw": raw}
	return {
		"data": parsed,
		"error": "",
		"schema_version": schema_version,
		"raw": raw,
		"enveloped": enveloped,
	}


static func _payload_semantic_error(payload: Dictionary, schema_version: int) -> String:
	var skills_value = payload.get("skills", null)
	if typeof(skills_value) != TYPE_DICTIONARY:
		return "missing_skills"
	var skills := skills_value as Dictionary
	# Schema-zero fixtures and historical desktop saves may legitimately contain an
	# empty skills dictionary. Every save emitted by schema v1 or later contains at
	# least one skill, so an empty current save is an incomplete write.
	if schema_version >= 1 and skills.is_empty():
		return "empty_skills"
	for raw_skill_id in skills.keys():
		if str(raw_skill_id).strip_edges().is_empty():
			return "invalid_skill_id"
		var skill_value = skills.get(raw_skill_id, null)
		if typeof(skill_value) != TYPE_DICTIONARY:
			return "invalid_skill_state"
		var skill_state := skill_value as Dictionary
		if not skill_state.has("xp") or typeof(skill_state.get("xp")) not in [TYPE_INT, TYPE_FLOAT] or float(skill_state.get("xp", 0)) < 0.0:
			return "invalid_skill_xp"
	if schema_version >= 1:
		# Schema v1 and later are always emitted as complete gameplay payloads. A
		# fragment that happens to contain one valid skill is an interrupted/truncated
		# write, not a save that can safely be filled from current defaults.
		for required_dictionary in ["mastery", "stamina", "stamina_bank", "mats"]:
			if typeof(payload.get(required_dictionary, null)) != TYPE_DICTIONARY:
				return "missing_%s" % required_dictionary
		for required_number in ["save_reset_generation", "saved_at"]:
			if typeof(payload.get(required_number, null)) not in [TYPE_INT, TYPE_FLOAT]:
				return "missing_%s" % required_number
		if typeof(payload.get("selected_skill_id", null)) != TYPE_STRING:
			return "missing_selected_skill_id"
	# Identity metadata can be repaired independently. Rejecting the whole payload
	# here would make intact gameplay unavailable because of a damaged profile.
	return ""


static func encoded_payload(payload: Dictionary) -> String:
	var payload_text := JSON.stringify(payload)
	# Keep a complete flat copy for rollback builds whose loader predates the
	# envelope. Current builds ignore this compatibility copy and verify the
	# checksummed payload_json before returning any save data.
	var encoded := payload.duplicate(true)
	encoded["save_envelope_version"] = SAVE_ENVELOPE_VERSION
	encoded["checksum"] = payload_text.sha256_text()
	encoded["payload_json"] = payload_text
	return JSON.stringify(encoded)


static func save_journal_events() -> Array:
	if not FileAccess.file_exists(SAVE_JOURNAL_PATH):
		return []
	var journal_json := JSON.new()
	if journal_json.parse(read_text(SAVE_JOURNAL_PATH)) != OK or typeof(journal_json.data) != TYPE_ARRAY:
		return []
	return (journal_json.data as Array).duplicate(true)


static func append_save_journal_event(event_name: String, details := {}) -> void:
	var events := save_journal_events()
	var event := {
		"at": int(Time.get_unix_time_from_system()),
		"event": event_name.strip_edges().substr(0, 48),
	}
	if typeof(details) == TYPE_DICTIONARY:
		var source := details as Dictionary
		# This whitelist intentionally excludes payload contents, profile values,
		# tokens, display names, and arbitrary error bodies.
		for key in ["source", "result", "schema", "revision", "migration_from", "migration_to", "trigger", "stage", "rotation"]:
			if not source.has(key):
				continue
			var value = source.get(key)
			if key in ["schema", "revision", "migration_from", "migration_to"]:
				event[key] = int(value)
			else:
				var clean_value := str(value).strip_edges().substr(0, 96)
				if key == "source":
					clean_value = clean_value.get_file()
				event[key] = clean_value
	events.append(event)
	while events.size() > SAVE_JOURNAL_MAX_EVENTS:
		events.pop_front()
	if not write_text(SAVE_JOURNAL_TEMP_PATH, JSON.stringify(events)):
		return
	_replace_with_staged_file(SAVE_JOURNAL_TEMP_PATH, SAVE_JOURNAL_PATH)


static func _remove_file_if_present(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return true
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK


static func _replace_with_staged_file(staging_path: String, destination_path: String) -> bool:
	if not FileAccess.file_exists(staging_path):
		return false
	if not _remove_file_if_present(destination_path):
		return false
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(staging_path),
		ProjectSettings.globalize_path(destination_path)
	) == OK


static func copy_valid_save(source_path: String, destination_path: String, staging_path := "") -> bool:
	if not FileAccess.file_exists(source_path):
		return true
	var source_result := load_dictionary_result(source_path)
	if not str(source_result.get("error", "")).is_empty():
		return false
	var source_text := str(source_result.get("raw", ""))
	if source_text.is_empty():
		return false
	var copy_staging_path := staging_path
	if copy_staging_path.is_empty():
		copy_staging_path = destination_path + ".copying"
	if not write_text(copy_staging_path, source_text):
		return false
	var staged_result := load_dictionary_result(copy_staging_path)
	if not str(staged_result.get("error", "")).is_empty() or str(staged_result.get("raw", "")) != source_text:
		return false
	if not _replace_with_staged_file(copy_staging_path, destination_path):
		return false
	var destination_result := load_dictionary_result(destination_path)
	return (
		str(destination_result.get("error", "")).is_empty()
		and str(destination_result.get("raw", "")) == source_text
	)


static func rotate_valid_save(source_path: String, destination_path: String) -> bool:
	if not FileAccess.file_exists(source_path):
		return true
	var source_result := load_dictionary_result(source_path)
	if not str(source_result.get("error", "")).is_empty():
		append_save_journal_event("backup_rotation", {"source": source_path, "result": "source_invalid", "rotation": destination_path.get_file()})
		return true
	var copied := copy_valid_save(source_path, destination_path, destination_path + ".rotating")
	append_save_journal_event("backup_rotation", {"source": source_path, "result": "ok" if copied else "failed", "rotation": destination_path.get_file()})
	return copied


static func quarantine_invalid_save(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var result := load_dictionary_result(path)
	if str(result.get("error", "")).is_empty():
		return false
	if not result.has("raw"):
		# Open/read failures cannot be copied safely. Leave the original in place so
		# boot recovery will remain fail-closed.
		append_save_journal_event("quarantine", {"source": path, "result": "unavailable"})
		return false
	var raw := str(result.get("raw", ""))
	var bytes_result := read_bytes_result(path)
	if not str(bytes_result.get("error", "")).is_empty():
		append_save_journal_event("quarantine", {"source": path, "result": "unavailable"})
		return false
	var source_bytes := bytes_result.get("data", PackedByteArray()) as PackedByteArray
	var base_path := path.trim_suffix(".json")
	var quarantine_path := "%s.corrupt-%s.json" % [base_path, raw.sha256_text().left(16)]
	if FileAccess.file_exists(quarantine_path):
		var existing_matches := FileAccess.get_file_as_bytes(quarantine_path) == source_bytes
		append_save_journal_event("quarantine", {"source": path, "result": "preserved" if existing_matches else "collision"})
		return existing_matches
	var preserved := (
		write_bytes(quarantine_path, source_bytes)
		and FileAccess.file_exists(quarantine_path)
		and FileAccess.get_file_as_bytes(quarantine_path) == source_bytes
	)
	append_save_journal_event("quarantine", {"source": path, "result": "preserved" if preserved else "failed"})
	return preserved


static func write_payload_atomically(
	payload: Dictionary,
	save_path: String,
	temp_path: String,
	backup_path: String,
	backup_2_path := "",
	backup_3_path := ""
) -> bool:
	var resolved_backup_2_path := backup_2_path if not backup_2_path.is_empty() else backup_path + ".2"
	var resolved_backup_3_path := backup_3_path if not backup_3_path.is_empty() else backup_path + ".3"
	var payload_text := encoded_payload(payload)
	var revision := maxi(0, int(payload.get("save_revision", 0)))
	if not write_text(temp_path, payload_text):
		append_save_journal_event("write_result", {"source": save_path, "result": "failed", "stage": "temp_write", "revision": revision})
		return false
	var temp_result := load_dictionary_result(temp_path)
	if not str(temp_result.get("error", "")).is_empty() or str(temp_result.get("raw", "")) != payload_text:
		append_save_journal_event("write_result", {"source": save_path, "result": "failed", "stage": "temp_verify", "revision": revision})
		return false
	if FileAccess.file_exists(save_path):
		var existing_result := load_dictionary_result(save_path)
		if not str(existing_result.get("error", "")).is_empty():
			quarantine_invalid_save(save_path)
			append_save_journal_event("write_result", {"source": save_path, "result": "blocked", "stage": "primary_verify", "revision": revision})
			return false
		if not rotate_valid_save(resolved_backup_2_path, resolved_backup_3_path):
			append_save_journal_event("write_result", {"source": save_path, "result": "failed", "stage": "backup_3", "revision": revision})
			return false
		if not rotate_valid_save(backup_path, resolved_backup_2_path):
			append_save_journal_event("write_result", {"source": save_path, "result": "failed", "stage": "backup_2", "revision": revision})
			return false
		if not copy_valid_save(save_path, backup_path, backup_path + ".rotating"):
			append_save_journal_event("write_result", {"source": save_path, "result": "failed", "stage": "backup_1", "revision": revision})
			return false
	if FileAccess.file_exists(save_path):
		if not _remove_file_if_present(save_path):
			append_save_journal_event("write_result", {"source": save_path, "result": "failed", "stage": "primary_remove", "revision": revision})
			return false
	if not _replace_with_staged_file(temp_path, save_path):
		if FileAccess.file_exists(backup_path):
			copy_valid_save(backup_path, save_path, save_path + ".restoring")
		append_save_journal_event("write_result", {"source": save_path, "result": "failed", "stage": "primary_promote", "revision": revision})
		return false
	var final_result := load_dictionary_result(save_path)
	if not str(final_result.get("error", "")).is_empty() or str(final_result.get("raw", "")) != payload_text:
		quarantine_invalid_save(save_path)
		if FileAccess.file_exists(backup_path):
			copy_valid_save(backup_path, save_path, save_path + ".restoring")
		append_save_journal_event("write_result", {"source": save_path, "result": "failed", "stage": "primary_verify", "revision": revision})
		return false
	append_save_journal_event("write_result", {"source": save_path, "result": "ok", "stage": "complete", "revision": revision, "schema": int(payload.get("save_schema_version", 0))})
	return true


static func best_dictionary_from_paths(paths: Array, skill_defs: Array, action_id_aliases := {}) -> Dictionary:
	return best_dictionary_result_from_paths(paths, skill_defs, action_id_aliases).get("data", {}) as Dictionary


static func best_dictionary_result_from_paths(paths: Array, skill_defs: Array, action_id_aliases := {}) -> Dictionary:
	var best_save := {}
	var best_path := ""
	for path in paths:
		if not FileAccess.file_exists(path):
			continue
		var candidate_save := load_dictionary(path)
		if candidate_save.is_empty():
			continue
		if should_replace_best_save(best_save, candidate_save, skill_defs, action_id_aliases):
			best_save = candidate_save
			best_path = str(path)
	return {"data": best_save, "path": best_path}


static func should_replace_best_save(best_save: Dictionary, candidate: Dictionary, skill_defs: Array, action_id_aliases := {}) -> bool:
	if candidate.is_empty():
		return false
	if best_save.is_empty():
		return true
	var candidate_reset_generation := SaveStateNormalizers.save_reset_generation(candidate)
	var best_reset_generation := SaveStateNormalizers.save_reset_generation(best_save)
	if candidate_reset_generation != best_reset_generation:
		return candidate_reset_generation > best_reset_generation
	var best_comparison := SaveStateNormalizers.payload_with_canonical_action_keys(best_save, action_id_aliases)
	var candidate_comparison := SaveStateNormalizers.payload_with_canonical_action_keys(candidate, action_id_aliases)
	var candidate_identity_regresses := SaveStateNormalizers.payload_regresses_identity(best_comparison, candidate_comparison)
	var best_identity_regresses := SaveStateNormalizers.payload_regresses_identity(candidate_comparison, best_comparison)
	var stable_account_boundary := SaveStateNormalizers.payloads_share_stable_account_boundary(best_comparison, candidate_comparison)
	var candidate_repair_generation := SaveStateNormalizers.save_repair_generation(candidate_comparison)
	var best_repair_generation := SaveStateNormalizers.save_repair_generation(best_comparison)
	var candidate_repairs_incomplete_claim := _candidate_repairs_incomplete_claimed_identity(best_comparison, candidate_comparison)
	var candidate_is_vetted_identity_repair := (
		stable_account_boundary
		and candidate_repair_generation > best_repair_generation
		and SaveStateNormalizers.vetted_identity_repair_is_safe(best_comparison, candidate_comparison)
	)
	var best_is_vetted_identity_repair := (
		stable_account_boundary
		and best_repair_generation > candidate_repair_generation
		and SaveStateNormalizers.vetted_identity_repair_is_safe(candidate_comparison, best_comparison)
	)
	if (
		SaveStateNormalizers.claimed_name_boundary_changes(best_comparison, candidate_comparison)
		and not candidate_is_vetted_identity_repair
	):
		# A repair generation is never authority to rename a claimed profile. Keep the
		# caller's path ordering until an explicit identity transition is persisted.
		return false
	# A newer repair generation may cross an identity guard only when it is exactly
	# the constrained normalization accepted by vetted_identity_repair_is_safe().
	# A complete identity from an older backup is grafted onto the selected gameplay
	# payload separately; it must never make the entire older payload win here.
	if candidate_is_vetted_identity_repair:
		return true
	if best_is_vetted_identity_repair:
		return false
	if candidate_identity_regresses != best_identity_regresses and not candidate_repairs_incomplete_claim:
		return not candidate_identity_regresses
	if candidate_identity_regresses and best_identity_regresses:
		# Never use recency to cross an established account boundary. The caller's
		# path order remains the deterministic authority for conflicting identities.
		return false
	if stable_account_boundary and candidate_repair_generation != best_repair_generation:
		return candidate_repair_generation > best_repair_generation
	var candidate_progress_regresses := SaveStateNormalizers.payload_regresses_game_progress(best_comparison, candidate_comparison, skill_defs)
	var best_progress_regresses := SaveStateNormalizers.payload_regresses_game_progress(candidate_comparison, best_comparison, skill_defs)
	if candidate_progress_regresses != best_progress_regresses:
		return not candidate_progress_regresses
	var candidate_revision := maxi(0, int(candidate.get("save_revision", 0)))
	var best_revision := maxi(0, int(best_save.get("save_revision", 0)))
	if candidate_revision != best_revision and (candidate_revision > 0 or best_revision > 0):
		return candidate_revision > best_revision
	var candidate_xp := SaveStateNormalizers.total_skill_xp_evidence(candidate, skill_defs)
	var best_xp := SaveStateNormalizers.total_skill_xp_evidence(best_save, skill_defs)
	if candidate_xp != best_xp:
		return candidate_xp > best_xp
	var candidate_progress := SaveStateNormalizers.progress_evidence_score(candidate, skill_defs)
	var best_progress := SaveStateNormalizers.progress_evidence_score(best_save, skill_defs)
	if candidate_progress != best_progress:
		return candidate_progress > best_progress
	return int(candidate.get("saved_at", 0)) > int(best_save.get("saved_at", 0))


static func _candidate_repairs_incomplete_claimed_identity(existing_payload: Dictionary, candidate_payload: Dictionary) -> bool:
	if not SaveStateNormalizers.payload_has_recoverable_identity_inconsistency(existing_payload):
		return false
	if SaveStateNormalizers.payload_has_recoverable_identity_inconsistency(candidate_payload):
		return false
	if not bool(candidate_payload.get("leaderboard_profile_claimed", false)) or not bool(candidate_payload.get("leaderboard_name_claim_verified", false)):
		return false
	if not SaveStateNormalizers.payloads_share_stable_account_boundary(existing_payload, candidate_payload):
		return false
	var candidate_display_name := str(candidate_payload.get("leaderboard_display_name", "")).strip_edges()
	var candidate_name_key := str(candidate_payload.get("leaderboard_name_key", "")).strip_edges()
	if LeaderboardProfile.is_default_display_name(candidate_display_name, SAVE_PROFILE_DISPLAY_NAME_MAX_CHARS) or LeaderboardProfile.is_guest_display_name(candidate_display_name, SAVE_PROFILE_GUEST_NAME_PREFIX, SAVE_PROFILE_DISPLAY_NAME_MAX_CHARS):
		return false
	if LeaderboardProfile.sanitize_display_name(candidate_display_name, SAVE_PROFILE_DISPLAY_NAME_MAX_CHARS) != candidate_display_name:
		return false
	if LeaderboardProfile.sanitize_name_key(candidate_name_key, SAVE_PROFILE_NAME_KEY_MAX_CHARS) != candidate_name_key:
		return false
	if LeaderboardProfile.make_name_key(candidate_display_name, SAVE_PROFILE_DISPLAY_NAME_MAX_CHARS, SAVE_PROFILE_NAME_KEY_MAX_CHARS) != candidate_name_key:
		return false
	for key in ["leaderboard_display_name", "leaderboard_name_key"]:
		var existing_value := str(existing_payload.get(key, "")).strip_edges()
		if key == "leaderboard_display_name" and (
			LeaderboardProfile.is_default_display_name(existing_value, SAVE_PROFILE_DISPLAY_NAME_MAX_CHARS)
			or LeaderboardProfile.is_guest_display_name(existing_value, SAVE_PROFILE_GUEST_NAME_PREFIX, SAVE_PROFILE_DISPLAY_NAME_MAX_CHARS)
		):
			continue
		if not existing_value.is_empty() and str(candidate_payload.get(key, "")).strip_edges() != existing_value:
			return false
	# The candidate supplies only these validated claim fields. Its older token,
	# provider, recovery markers, gameplay, and revision never enter the repaired
	# payload, so legacy v1 candidates may safely omit newer identity metadata.
	return true


static func payload_with_recovered_claimed_identity(existing_payload: Dictionary, candidate_payload: Dictionary) -> Dictionary:
	if not _candidate_repairs_incomplete_claimed_identity(existing_payload, candidate_payload):
		return existing_payload
	var repaired := existing_payload.duplicate(true)
	# Copy only the server-validated claim boundary. Gameplay, save revision, repair
	# generation, currencies, credentials, and every other local field remain from
	# the selected primary so username recovery can never roll progress back. Force
	# one canonical server check before online writes resume.
	for key in ["leaderboard_display_name", "leaderboard_name_key", "leaderboard_profile_claimed", "leaderboard_name_claim_verified"]:
		repaired[key] = candidate_payload.get(key)
	repaired["leaderboard_auth_recovery_required"] = true
	if str(repaired.get("leaderboard_auth_recovery_reason", "")).strip_edges().is_empty():
		repaired["leaderboard_auth_recovery_reason"] = "Recovered saved username needs server verification."
	return repaired


func _init(host_ref) -> void:
	host = host_ref


func _init_state() -> void:
	SkillState.invalidate_stat_caches(host)
	host._app_lifecycle_runtime().clear_lazy_overlay_registry()
	host.skills.clear()
	host.mastery.clear()
	host.stamina.clear()
	host.stamina_bank.clear()
	host.honey_stamina_seconds_remaining = 0.0
	host.canceled_action_progress_by_key.clear()
	host._action_runtime().auto_eat_fish_after_spend_due_msec_by_skill.clear()
	host.material_runtime.legacy_softwood_amount = 0
	host.material_runtime.wallet.clear()
	host.auto_unlock_lockpads_enabled = false
	host._navigation_shell()._restore_nav_symbol_seen_ids({})
	host.offline_progress_cap_notifications_enabled = false
	host.module_ui_runtime.reset()
	host._navigation_shell().module_utility_collapsed = false
	host.god_mode_enabled = false
	host.god_mode_save_tainted = false
	host.fishing_runtime.reset()
	host._fishing_ui_surface()._clear_fishing_tool_circle_menu()
	host.passive_modules.clear()
	host.convergence_modules.clear()
	host._temporary_event_runtime().reset()
	host.thieving_state.reset()
	host._hub_runtime().hub_modules.clear()
	host._hub_runtime().hub_selected_module_id = "pond"
	host._hub_surface().hub_module_positions.clear()
	host._hub_surface().hub_decor_layout.clear()
	host._hub_runtime().hub_missions.clear()
	host._hub_runtime().hub_mission_cooldown_until_unix = 0
	host._hub_surface().hub_tutorial_tip_seen = false
	host._hub_surface().hub_tutorial_host = null
	host._hub_surface().hub_tutorial_tip_root = null
	host._hub_surface().hub_tutorial_info_button = null
	host._hub_surface()._kill_hub_tutorial_tip_tween()
	host.manual_activity_unlocks.clear()
	host.manual_activity_requirement_unlocks.clear()
	host._activity_unlock_runtime()._invalidate_manual_activity_unlock_trust()
	host.plank_boost_enabled = false
	host.activity_crit_seen = false
	host.activity_mega_crit_seen = false
	achievement_toast_seen_ids.clear()
	host._onboarding_runtime().activity_start_tip_seen = false
	host._action_runtime().reset_activity_counts()
	host._onboarding_runtime().onboarding_starter_action_completion_count = 0
	host._onboarding_runtime().onboarding_first_module_center_release_pending = false
	host._onboarding_runtime().onboarding_first_module_center_released = false
	host._onboarding_runtime().onboarding_header_reveal_after_progress = false
	host._onboarding_runtime().onboarding_swipe_tip_eligible = true
	host._onboarding_runtime().onboarding_swipe_navigation_unlocked = true
	host._onboarding_runtime().onboarding_swipe_tip_sequence_running = false
	host._onboarding_runtime().skill_swipe_tip_seen = true
	host._onboarding_runtime().onboarding_explore_tip_seen = true
	host._onboarding_runtime().onboarding_tutorial_complete = true
	host._onboarding_runtime().onboarding_explore_tip_sequence_running = false
	host._onboarding_runtime().stamina_gauge_tip_seen = true
	host._onboarding_runtime().lock_click_tip_seen = false
	host._onboarding_runtime().passive_module_tip_seen = false
	host._onboarding_runtime().silver_opportunity_tip_seen = false
	host._onboarding_runtime().silver_opportunity_tip_action_key = ""
	host.stamina_gauge_pre_tip_hold_seconds = 0.0
	host.show_stamina_decimal = false
	host.offline_progress_cap_notifications_enabled = false
	host.stamina_gauge_tip_root = null
	host._onboarding_runtime().onboarding_fight_summary_revealed = true
	host._onboarding_runtime().onboarding_fight_auto_run_message_shown = true
	host._onboarding_runtime().onboarding_fight_stamina_revealed = true
	host._onboarding_runtime().onboarding_fight_action_stats_revealed = true
	host._onboarding_runtime().onboarding_fight_action_stats_fade_running = false
	host._onboarding_runtime().onboarding_header_sequence_running = false
	host._onboarding_runtime().onboarding_auto_run_sequence_running = false
	host._onboarding_runtime().onboarding_stamina_tip_sequence_running = false
	host._onboarding_runtime().onboarding_header_sequence_started_msec = 0
	host._onboarding_runtime().onboarding_stamina_tip_sequence_started_msec = 0
	host._tutorial_overlay_surface().reset_onboarding_tip_state()
	host._onboarding_runtime().tutorial_gate_latch_only_until_swipe = false
	host._activity_unlock_runtime().set_pending_readiness_pages({})
	var unlock_ceremony = host._activity_unlock_ceremony_surface()
	unlock_ceremony.ceremony_count = 0
	unlock_ceremony.ceremony_action_key = ""
	unlock_ceremony.preview_after_ceremony_id = ""
	unlock_ceremony.heist_preview_after_ceremony_id = ""
	unlock_ceremony.center_scroll_target = -1
	unlock_ceremony.detail_refresh_done = false
	unlock_ceremony.clear_preview_reveal_guards()
	host._onboarding_runtime()._cancel_onboarding_header_sequence()
	host._tutorial_overlay_surface()._dismiss_activity_start_highlight(true)
	var leaderboard_state = host.leaderboard_state
	leaderboard_state.reset_submission_metadata()
	host.leaderboard_profile.reset(host.PROFILE_GUEST_NAME_PREFIX)
	leaderboard_state.rows_by_category.clear()
	leaderboard_state.fetch_unix_by_category.clear()
	leaderboard_state.fetch_retry_unix_by_category.clear()
	leaderboard_state.status_message = ""
	host._online_runtime().reset_cloud_save_state()
	host._online_runtime().reset_leaderboard_runtime_state()
	host._online_runtime().reset_chat_runtime_state()
	host.last_passive_process_unix = host._unix_now()
	host._ad_bonus_runtime().seconds_remaining = 0.0
	for def in host.skill_defs:
		var skill_id = str(def["id"])
		host.skills[skill_id] = {"xp": 0, "level": 1}
		host.stamina[skill_id] = float(host.BASE_MAX_STAMINA)
		host.stamina_bank[skill_id] = 0.0
	SkillState.invalidate_stat_caches(host)


func reset_data(feedback_button: Button = null) -> void:
	if save_writes_blocked:
		host.last_result = "Hard reset blocked while save recovery is required."
		return
	host.save_restore_complete = false
	cancel_next_identity_transition_save()
	_clear_pending_save_restore_work()
	host._navigation_shell().reset_navigation_render_state()
	host._skill_swipe_activity_surface()._apply_skill_swipe_drag_offset(0.0)
	host._navigation_shell().screen_render_in_progress = false
	host._navigation_shell().screen_render_target_key = ""
	host._navigation_shell().pending_screen_render_request.clear()
	host._navigation_shell().pending_skill_detail_refresh_request.clear()
	host._settings_surface()._clear_reset_data_buttons_for_rebuild()
	_init_state()
	host._navigation_shell()._reset_page_control_refs()
	host.running_skill_id = ""
	host.running_action_id = ""
	host.action_progress = 0.0
	host.canceled_action_progress_by_key.clear()
	host.selected_skill_id = host.TUTORIAL_STARTER_SKILL_ID
	if host.settings_overlay != null:
		host._app_lifecycle_runtime().set_canvas_item_visible_if_changed(host.settings_overlay, false)
		host._profile_chat_overlay_surface()._hide_profile_overlay()
	host._achievement_overlay_surface().hide_overlay_without_sfx()
	host._achievement_overlay_surface().hide_offline_summary_immediate()
	if host._profile_chat_overlay_surface().chat_overlay_visible():
		host._profile_chat_overlay_surface()._close_chat_overlay(false)
	host._boot_warmup_runtime().prepare_selected_skill_for_render(false)
	host.last_result = "Data wiped."
	save_reset_generation = maxi(save_reset_generation + 1, int(round(Time.get_unix_time_from_system() * 1000.0)))
	allow_next_save_progress_regression = true
	host.save_restore_complete = true
	host._onboarding_runtime()._start_tutorial()
	host._update_ui(0.0, true)
	var feedback_button_id := feedback_button.get_instance_id() if feedback_button != null and is_instance_valid(feedback_button) else 0
	host._settings_surface().call_deferred("_play_reset_data_wiped_feedback_by_id", feedback_button_id)



func _mark_save_dirty(reason = "") -> void:
	save_dirty = true
	if not reason.is_empty():
		save_dirty_reason = reason


func allow_next_identity_transition_save(source_uid: String, target_uid: String) -> bool:
	# This capability is reserved for a completed, user-initiated account switch.
	# Refresh, anonymous signup, and background auth must never call it. Exact UID
	# anchors prevent it from authorizing any different in-memory transition.
	cancel_next_identity_transition_save()
	var clean_source_uid := LeaderboardProfile.sanitize_player_id(source_uid)
	var clean_target_uid := LeaderboardProfile.sanitize_player_id(target_uid)
	if clean_source_uid.is_empty() or clean_target_uid.is_empty():
		return false
	next_save_identity_transition_source_uid = clean_source_uid
	next_save_identity_transition_target_uid = clean_target_uid
	return true


func cancel_next_identity_transition_save() -> void:
	next_save_identity_transition_source_uid = ""
	next_save_identity_transition_target_uid = ""


func _consume_next_identity_transition_save() -> Dictionary:
	var capability := {}
	if not next_save_identity_transition_source_uid.is_empty() and not next_save_identity_transition_target_uid.is_empty():
		capability = {
			"source_uid": next_save_identity_transition_source_uid,
			"target_uid": next_save_identity_transition_target_uid,
		}
	cancel_next_identity_transition_save()
	return capability


func _allow_next_vetted_progress_repair_save(source_payload: Dictionary, repaired_payload: Dictionary) -> void:
	next_save_vetted_progress_repair_source = source_payload.duplicate(true)
	next_save_vetted_progress_repair_payload = repaired_payload.duplicate(true)


func _allow_next_vetted_identity_repair_save(
	source_payload: Dictionary,
	repaired_payload: Dictionary,
	require_exact_claim := false
) -> void:
	next_save_vetted_identity_repair_source = source_payload.duplicate(true)
	next_save_vetted_identity_repair_payload = repaired_payload.duplicate(true)
	next_save_vetted_identity_repair_requires_exact_claim = require_exact_claim


func _clear_vetted_save_repair_capabilities() -> void:
	next_save_vetted_progress_repair_source = {}
	next_save_vetted_progress_repair_payload = {}
	next_save_vetted_identity_repair_source = {}
	next_save_vetted_identity_repair_payload = {}
	next_save_vetted_identity_repair_requires_exact_claim = false



func save_game() -> bool:
	# Identity-transition authority is one-shot. Consume it before every exit path,
	# including storage failures, so a later unrelated save cannot inherit it.
	var identity_transition_capability := _consume_next_identity_transition_save()
	if OS.get_environment("IDLE_ELITE_DISABLE_SAVE_WRITES") == "1":
		save_dirty = false
		save_dirty_reason = ""
		return false
	if save_writes_blocked:
		save_dirty = true
		save_dirty_reason = save_writes_blocked_reason
		host.last_result = "Save protected: %s" % save_writes_blocked_reason
		return false
	if not host.save_restore_complete:
		save_dirty = true
		save_dirty_reason = "save restore is incomplete"
		return false
	var now = host._unix_now()
	var payload = _save_payload(now)
	payload["save_revision"] = maxi(save_revision, _highest_local_save_revision()) + 1
	append_save_journal_event("save_requested", {
		"trigger": save_dirty_reason if not save_dirty_reason.is_empty() else "direct",
		"revision": int(payload.get("save_revision", 0)),
		"schema": SAVE_SCHEMA_VERSION,
	})
	if not _save_payload_can_replace_existing_save(payload, identity_transition_capability):
		save_dirty = true
		save_dirty_reason = "progress regression blocked"
		host.last_result = "Save protected: progress regression blocked."
		push_warning(
			"Idle Elite blocked a save that would reduce progress at %s" % ProjectSettings.globalize_path(SAVE_PATH)
		)
		return false
	if allow_next_save_progress_regression:
		allow_next_save_progress_regression = false
	if not _write_save_payload_atomically(payload):
		save_dirty = true
		save_dirty_reason = "save file write failed"
		host.last_result = "Save failed."
		push_warning(
			"Idle Elite save failed at %s" % ProjectSettings.globalize_path(SAVE_PATH)
		)
		return false
	save_revision = int(payload.get("save_revision", save_revision + 1))
	_sync_web_userfs_after_save()
	if host._online_runtime()._cloud_save_account_ready():
		host._online_runtime().mark_cloud_save_dirty()
		host._online_runtime().upload_cloud_save()
	save_dirty = false
	save_dirty_reason = ""
	allow_next_save_progress_regression = false
	_clear_vetted_save_repair_capabilities()
	return true



func _write_save_payload_atomically(payload: Dictionary) -> bool:
	if not write_payload_atomically(
		payload,
		SAVE_PATH,
		SAVE_TEMP_PATH,
		SAVE_BACKUP_PATH,
		SAVE_BACKUP_2_PATH,
		SAVE_BACKUP_3_PATH
	):
		return false
	last_save_unix_time = int(payload.get("saved_at", host._unix_now()))
	last_save_monotonic_msec = Time.get_ticks_msec()
	if FileAccess.file_exists(SAVE_RECOVERY_SNAPSHOT_PATH) and not _remove_file_if_present(SAVE_RECOVERY_SNAPSHOT_PATH):
		append_save_journal_event("recovery_snapshot", {"source": SAVE_RECOVERY_SNAPSHOT_PATH, "result": "cleanup_failed"})
	return true



func _save_payload_can_replace_existing_save(next_payload: Dictionary, identity_transition_capability := {}) -> bool:
	if allow_next_save_progress_regression:
		return true
	var action_id_aliases = host.FISHING_ACTION_ID_ALIASES
	var existing = best_dictionary_from_paths(_local_save_paths(), host.skill_defs, action_id_aliases)
	var existing_comparison := SaveStateNormalizers.payload_with_canonical_action_keys(existing, action_id_aliases)
	var next_comparison := SaveStateNormalizers.payload_with_canonical_action_keys(next_payload, action_id_aliases)
	var existing_reset_generation := _save_reset_generation(existing)
	var next_reset_generation := _save_reset_generation(next_payload)
	if next_reset_generation > existing_reset_generation:
		return true
	if next_reset_generation < existing_reset_generation:
		return false
	if (
		SaveStateNormalizers.payloads_share_stable_account_boundary(existing_comparison, next_comparison)
		and SaveStateNormalizers.save_repair_generation(next_payload) < SaveStateNormalizers.save_repair_generation(existing)
	):
		return false
	if SaveStateNormalizers.payload_regresses_identity(existing_comparison, next_comparison):
		var exact_identity_transition := _identity_transition_capability_matches(
			existing_comparison,
			next_comparison,
			identity_transition_capability
		)
		var vetted_normalization := (
			not next_save_vetted_identity_repair_requires_exact_claim
			and SaveStateNormalizers.vetted_identity_repair_is_safe(existing, next_payload)
		)
		var vetted_claim_recovery := (
			next_save_vetted_identity_repair_requires_exact_claim
			and _identity_repair_matches_expected_claim(next_payload, next_save_vetted_identity_repair_payload)
			and _vetted_claimed_identity_recovery_is_safe(existing, next_payload, next_save_vetted_identity_repair_payload)
		)
		var vetted_identity_repair := (
			not next_save_vetted_identity_repair_source.is_empty()
			and not next_save_vetted_identity_repair_payload.is_empty()
			and existing == next_save_vetted_identity_repair_source
			and (vetted_normalization or vetted_claim_recovery)
		)
		if not exact_identity_transition and not vetted_identity_repair:
			return false
	if not SaveStateNormalizers.payload_regresses_game_progress(existing_comparison, next_comparison, host.skill_defs):
		return true
	if next_save_vetted_progress_repair_source.is_empty() or next_save_vetted_progress_repair_payload.is_empty():
		return false
	return not SaveStateNormalizers.payload_regresses_outside_vetted_progress_repair(
		existing,
		next_payload,
		next_save_vetted_progress_repair_source,
		next_save_vetted_progress_repair_payload,
		host.skill_defs
	)


static func _identity_repair_matches_expected_claim(next_payload: Dictionary, expected_payload: Dictionary) -> bool:
	for key in ["leaderboard_display_name", "leaderboard_name_key", "leaderboard_profile_claimed", "leaderboard_name_claim_verified"]:
		if next_payload.get(key, null) != expected_payload.get(key, null):
			return false
	return true


static func _vetted_claimed_identity_recovery_is_safe(existing_payload: Dictionary, next_payload: Dictionary, expected_payload: Dictionary) -> bool:
	var expected_repair := payload_with_recovered_claimed_identity(existing_payload, expected_payload)
	if expected_repair == existing_payload or not bool(expected_repair.get("leaderboard_auth_recovery_required", false)):
		return false
	if not _identity_repair_matches_expected_claim(next_payload, expected_repair):
		return false
	# The backup authorizes only the claimed name fields. The selected primary's
	# UID, credentials, provider, and recovery/transfer anchors must still survive.
	return not SaveStateNormalizers.payload_regresses_identity(expected_repair, next_payload)


static func _identity_transition_capability_matches(existing_payload: Dictionary, next_payload: Dictionary, capability: Variant) -> bool:
	if typeof(capability) != TYPE_DICTIONARY:
		return false
	var source := capability as Dictionary
	var expected_source_uid := LeaderboardProfile.sanitize_player_id(str(source.get("source_uid", "")))
	var expected_target_uid := LeaderboardProfile.sanitize_player_id(str(source.get("target_uid", "")))
	if expected_source_uid.is_empty() or expected_target_uid.is_empty():
		return false
	var existing_uid := LeaderboardProfile.sanitize_player_id(str(existing_payload.get("leaderboard_player_id", "")))
	var existing_bound_uid := LeaderboardProfile.sanitize_player_id(str(existing_payload.get("leaderboard_auth_bound_uid", "")))
	var next_uid := LeaderboardProfile.sanitize_player_id(str(next_payload.get("leaderboard_player_id", "")))
	var next_bound_uid := LeaderboardProfile.sanitize_player_id(str(next_payload.get("leaderboard_auth_bound_uid", "")))
	var next_provider := str(next_payload.get("leaderboard_auth_provider", "")).strip_edges()
	return (
		existing_uid == expected_source_uid
		and (existing_bound_uid.is_empty() or existing_bound_uid == expected_source_uid)
		and next_uid == expected_target_uid
		and next_bound_uid == expected_target_uid
		and next_provider == "google"
	)


func _highest_local_save_revision() -> int:
	var highest := 0
	for path in _local_save_paths():
		if not FileAccess.file_exists(path):
			continue
		var result := load_dictionary_result(path)
		if not str(result.get("error", "")).is_empty():
			continue
		var data := result.get("data", {}) as Dictionary
		highest = maxi(highest, int(data.get("save_revision", 0)))
	return highest



func _save_payload_regresses_progress(existing_payload: Dictionary, next_payload: Dictionary) -> bool:
	return SaveStateNormalizers.payload_regresses_progress(existing_payload, next_payload, host.skill_defs)



func _save_reset_generation(data: Dictionary) -> int:
	return SaveStateNormalizers.save_reset_generation(data)



func _save_total_skill_xp_evidence(data: Dictionary) -> int:
	return SaveStateNormalizers.total_skill_xp_evidence(data, host.skill_defs)



func _sync_web_userfs_after_save() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.force_fs_sync()


func _running_action_id_for_save() -> String:
	if host.running_skill_id.is_empty() or host.running_action_id.is_empty():
		return ""
	var action: Dictionary = host._action_data(host.running_skill_id, host.running_action_id)
	if action.is_empty():
		return ""
	return str(action.get("id", ModuleUiRuntime.canonical_action_id(host.running_skill_id, host.running_action_id, host.FISHING_ACTION_ID_ALIASES)))


func _event_running_action_id_for_save() -> String:
	var temporary_events = host._temporary_event_runtime()
	if temporary_events.event_running_skill_id.is_empty() or temporary_events.event_running_action_id.is_empty():
		return ""
	var action: Dictionary = host._action_data(temporary_events.event_running_skill_id, temporary_events.event_running_action_id)
	if action.is_empty() or not host._is_event_action(action):
		return ""
	return str(action.get("id", temporary_events.event_running_action_id))


func _selected_skill_id_for_save() -> String:
	if SkillState.has_skill_id(host.skill_defs, host.selected_skill_id):
		return host.selected_skill_id
	return _default_skill_id_for_save()


func _running_skill_id_for_save() -> String:
	var action_id := _running_action_id_for_save()
	if action_id.is_empty() or not SkillState.has_skill_id(host.skill_defs, host.running_skill_id):
		return ""
	return host.running_skill_id


func _event_running_skill_id_for_save() -> String:
	var temporary_events = host._temporary_event_runtime()
	var action_id := _event_running_action_id_for_save()
	if action_id.is_empty() or not SkillState.has_skill_id(host.skill_defs, temporary_events.event_running_skill_id):
		return ""
	return temporary_events.event_running_skill_id


func _default_skill_id_for_save() -> String:
	if SkillState.has_skill_id(host.skill_defs, "fight"):
		return "fight"
	if not host.skill_defs.is_empty():
		return str((host.skill_defs[0] as Dictionary).get("id", ""))
	return ""


func _action_progress_for_save() -> float:
	return _normalized_action_progress(host.action_progress)


func _event_action_progress_for_save() -> float:
	return _normalized_action_progress(host._temporary_event_runtime().event_action_progress)


func _normalized_action_progress(value: Variant) -> float:
	return clampf(float(value), 0.0, 0.999)


func _action_key_for_save(key: String) -> String:
	return _canonical_action_key(key)


func _canonical_action_key(key: String) -> String:
	var separator := key.find(":")
	if separator < 0:
		return ""
	var skill_id := key.substr(0, separator)
	var action_id := key.substr(separator + 1)
	if skill_id.is_empty() or action_id.is_empty():
		return ""
	var action: Dictionary = host._action_data(skill_id, action_id)
	if action.is_empty() or host._passive_modules_runtime().is_passive_action(action):
		return ""
	return host._action_key(skill_id, str(action.get("id", action_id)))



func _save_payload(now: int) -> Dictionary:
	var payload := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"save_reset_generation": save_reset_generation,
		"save_repair_generation": save_repair_generation,
		"save_revision": save_revision,
		"skills": SkillState.skills_for_save(host.skill_defs, host.skills),
		"mastery": MasteryState.for_save(host.mastery, Callable(self, "_canonical_action_key"), host.MASTERY_MAX_LEVEL),
		"stamina": SkillState.stamina_for_save(host.skill_defs, host.stamina, Callable(SkillState, "host_max_stamina").bind(host)),
		"stamina_bank": SkillState.stamina_bank_for_save(host.skill_defs, host.stamina, host.stamina_bank, Callable(SkillState, "host_max_stamina").bind(host)),
		"honey_stamina_seconds_remaining": clampf(host.honey_stamina_seconds_remaining, 0.0, SkillState.HONEY_STAMINA_SECONDS_PER_CONSUMPTION),
		"blue_guy_health": host._fighting_runtime().blue_guy_health_value(),
		"blue_guy_health_bank": host._fighting_runtime().blue_guy_health_bank_for_save(),
		"mats": host.material_runtime.save_wallet(),
		"log_currency": maxi(0, host.material_runtime.legacy_softwood_amount),
		"auto_eat_fish_enabled": not host.fishing_runtime.auto_eat_fish_enabled_by_skill_for_save(host).is_empty(),
		"auto_eat_fish_enabled_by_skill": host.fishing_runtime.auto_eat_fish_enabled_by_skill_for_save(host),
		"passive_modules": host._passive_modules_runtime().for_save(),
		"convergence_modules": host._convergence_runtime()._convergence_modules_for_save(),
		"built_modules": BuildableModules.normalized_for_save(host.built_modules, Callable(host, "_action_data"), Callable(host, "_action_key")),
		"completed_bosses": host._fighting_runtime().completed_bosses_for_save(),
		"temporary_events": host._temporary_event_runtime()._temporary_events_for_save(),
		"thieving_trophies": host.thieving_state.trophies_for_save(),
		"thieving_action_jails": host.thieving_state.action_jails_for_save(now, func(skill_id: String, action_id: String) -> String: return ModuleUiRuntime.canonical_action_id(skill_id, action_id, host.FISHING_ACTION_ID_ALIASES), Callable(host, "_action_data")),
		"hub_modules": host._hub_runtime().modules_for_save(),
		"hub_selected_module_id": host._hub_runtime().selected_module_id_for_save(),
		"hub_module_positions": host._hub_surface()._hub_module_positions_for_save(),
		"hub_decor_layout": host._hub_surface()._normalized_hub_decor_layout(host._hub_surface().hub_decor_layout),
		"hub_missions": host._hub_runtime().missions_for_save(),
		"hub_mission_cooldown_until_unix": maxi(0, host._hub_runtime().hub_mission_cooldown_until_unix),
		"hub_tutorial_tip_seen": host._hub_surface().hub_tutorial_tip_seen,
		"manual_activity_unlocks": host._activity_unlock_runtime()._manual_activity_unlocks_for_save(),
		"manual_activity_requirement_unlocks": host._activity_unlock_runtime()._manual_activity_requirement_unlocks_for_save(),
		"berry_prep": host.material_runtime.berry_prep_for_save(Callable(host, "_action_data")),
		"plank_boost_enabled": bool(host.plank_boost_enabled),
		"activity_crit_seen": host.activity_crit_seen,
		"activity_mega_crit_seen": host.activity_mega_crit_seen,
		"achievement_toast_seen_ids": AchievementState.normalized_seen_ids(achievement_toast_seen_ids),
		"ad_bonus_seconds_remaining": clampf(host._ad_bonus_runtime().seconds_remaining, 0.0, float(AdBonus.AD_BONUS_MAX_SECONDS)),
		"shop_rate_prompt_dismissed": host._shop_surface().rate_prompt_dismissed_for_save(),
		"selected_skill_id": _selected_skill_id_for_save(),
		"running_skill_id": _running_skill_id_for_save(),
		"running_action_id": _running_action_id_for_save(),
		"action_progress": _action_progress_for_save(),
		"event_running_skill_id": _event_running_skill_id_for_save(),
		"event_running_action_id": _event_running_action_id_for_save(),
		"event_action_progress": _event_action_progress_for_save(),
		"activity_queue": host._activity_queue_runtime()._activity_queue_for_save(),
		"module_ui_pinned_order": host.module_ui_runtime.pinned_order_for_save(Callable(host._skill_detail_surface(), "_module_ui_key_allows_pin_or_collapse")),
		"module_ui_pin_color_paths": host.module_ui_runtime.pin_color_paths_for_save(ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, Callable(host._skill_detail_surface(), "_module_ui_key_allows_pin_or_collapse")),
		"module_ui_collapsed": host.module_ui_runtime.collapsed_for_save(Callable(host._skill_detail_surface(), "_module_ui_key_allows_pin_or_collapse")),
		"module_ui_collapse_save_version": ModuleUiRuntime.COLLAPSE_SAVE_VERSION,
		"module_ui_sort_mode": host.module_ui_runtime.sort_mode_for_save(),
		"module_ui_combo_first": host.module_ui_runtime.combo_first,
		"module_ui_collection_first": host.module_ui_runtime.collection_first,
		"audio_settings_version": host.AudioDirector.AUDIO_SETTINGS_VERSION,
		"music_volume": clampf(host._audio_director().music_volume, 0.0, 1.0),
		"sfx_volume": clampf(host._audio_director().sfx_volume, 0.0, 1.0),
		"music_muted": host._audio_director().music_muted,
		"sfx_muted": host._audio_director().sfx_muted,
		"show_stamina_decimal": host.show_stamina_decimal,
		"offline_progress_cap_notifications_enabled": host.offline_progress_cap_notifications_enabled,
		"dark_mode_enabled": host.dark_mode_enabled,
		"offline_progress_enabled": host.offline_progress_enabled,
		"auto_unlock_lockpads_enabled": host.auto_unlock_lockpads_enabled,
		"nav_symbol_seen_ids": host._navigation_shell()._nav_symbol_seen_ids_for_save(),
		"god_mode_enabled": host.god_mode_enabled and host._test_state_runtime()._god_mode_available(),
		"god_mode_save_tainted": host.god_mode_save_tainted,
		"activity_start_tip_seen": host._onboarding_runtime().activity_start_tip_seen,
		"activity_start_count": maxi(0, host._action_runtime().activity_start_count),
		"activity_completion_count": maxi(0, host._action_runtime().activity_completion_count),
		"guaranteed_success_action_completions": clampi(host._action_runtime().guaranteed_success_action_completions, 0, ActionRuntime.GUARANTEED_SUCCESS_ACTION_COMPLETIONS),
		"onboarding_starter_action_completion_count": maxi(0, host._onboarding_runtime().onboarding_starter_action_completion_count),
		"onboarding_first_module_center_released": host._onboarding_runtime().onboarding_first_module_center_released,
		"onboarding_header_reveal_after_progress": host._onboarding_runtime().onboarding_header_reveal_after_progress,
		"onboarding_swipe_tip_eligible": host._onboarding_runtime().onboarding_swipe_tip_eligible,
		"onboarding_swipe_navigation_unlocked": host._onboarding_runtime().onboarding_swipe_navigation_unlocked,
		"skill_swipe_tip_seen": host._onboarding_runtime().skill_swipe_tip_seen,
		"onboarding_explore_tip_seen": host._onboarding_runtime().onboarding_explore_tip_seen,
		"onboarding_tutorial_complete": host._onboarding_runtime().onboarding_tutorial_complete,
		"tutorial_active": host._onboarding_runtime().tutorial_active,
		"tutorial_step": host._onboarding_runtime().tutorial_step,
		"tutorial_gate_latch_only_until_swipe": false,
		"stamina_gauge_tip_seen": host._onboarding_runtime().stamina_gauge_tip_seen,
		"onboarding_fight_summary_revealed": host._onboarding_runtime().onboarding_fight_summary_revealed,
		"onboarding_fight_auto_run_message_shown": host._onboarding_runtime().onboarding_fight_auto_run_message_shown,
		"onboarding_fight_stamina_revealed": host._onboarding_runtime().onboarding_fight_stamina_revealed,
		"onboarding_fight_action_stats_revealed": host._onboarding_runtime().onboarding_fight_action_stats_revealed,
		"onboarding_medal_tip_shown": host._tutorial_overlay_surface().onboarding_medal_tip_shown,
		"lock_click_tip_seen": host._onboarding_runtime().lock_click_tip_seen,
		"passive_module_tip_seen": host._onboarding_runtime().passive_module_tip_seen,
		"silver_opportunity_tip_seen": host._onboarding_runtime().silver_opportunity_tip_seen,
		"silver_opportunity_tip_action_key": _action_key_for_save(host._onboarding_runtime().silver_opportunity_tip_action_key),
		"detail_pull_recent_tip_texts": SaveStateNormalizers.normalized_recent_tip_texts(host._skill_detail_surface().detail_pull_recent_tip_texts, SkillDetailSurface.DETAIL_PULL_TIP_TEXTS),
		"stamina_gauge_pre_tip_hold_seconds": clampf(host.stamina_gauge_pre_tip_hold_seconds, 0.0, host.STAMINA_TIP_DISCOVERY_HOLD_SECONDS),
		"music_start_chance_unlocked": host._audio_director().music_start_chance_unlocked,
		"flow_heat": clampf(host._audio_director().flow_heat, 0.0, 36.0),
		"flow_active_action_seconds": maxf(0.0, host._audio_director().flow_active_action_seconds),
		"leaderboard_last_submitted_score": maxi(0, int(host.leaderboard_state.last_submitted_score)),
		"leaderboard_last_submitted_total_xp": maxi(0, int(host.leaderboard_state.last_submitted_total_xp)),
		"leaderboard_last_submitted_scores_by_category": host.leaderboard_state.last_submitted_scores_for_save(),
		"leaderboard_last_submit_unix": maxi(0, int(host.leaderboard_state.last_submit_unix)),
		"leaderboard_repair_publish_version": clampi(int(host.leaderboard_state.repair_publish_version), 0, LeaderboardState.REPAIR_PUBLISH_VERSION),
		"leaderboard_display_name": LeaderboardProfile.display_name_for_save(host, host.PROFILE_DISPLAY_NAME_MAX_CHARS),
		"leaderboard_name_key": LeaderboardProfile.name_key_for_save(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS),
		"leaderboard_avatar_index": LeaderboardProfile.avatar_index_for_save(host, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT),
		"leaderboard_profile_claimed": LeaderboardProfile.profile_claimed_for_save(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS),
		"leaderboard_name_claim_verified": LeaderboardProfile.name_claim_verified_for_save(host, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS),
		"leaderboard_player_id": LeaderboardProfile.player_id_for_save(host),
		"leaderboard_auth_provider": LeaderboardProfile.auth_provider_for_save_host(host),
		"leaderboard_auth_refresh_token": LeaderboardProfile.auth_refresh_token_for_save(host),
		"leaderboard_auth_retry_after_unix": maxi(0, int(host._online_runtime().leaderboard_auth_retry_after_unix)),
		"leaderboard_fetch_retry_unix_by_category": host.leaderboard_state.fetch_retry_unix_by_category_for_save(),
		# Chat rows are not saved; the realtime stream is reopened only while the skills chat strip is visible.
		"last_result": host.last_result,
		"saved_at": now
	}
	var online_runtime = host._online_runtime()
	if online_runtime.has_method("auth_identity_metadata_for_save"):
		var auth_identity_metadata = online_runtime.call("auth_identity_metadata_for_save")
		if typeof(auth_identity_metadata) == TYPE_DICTIONARY:
			payload.merge(auth_identity_metadata as Dictionary, true)
	payload.merge(online_runtime.chat_metadata_for_save(now), true)
	payload.merge(host.fishing_runtime.save_payload(
		FishingState.FISHING_NET_HAUL_THRESHOLD,
		FishingState.FISHING_BOAT_HAUL_THRESHOLD,
		Callable(host.fishing_runtime, "tool_is_unlocked"),
		Callable(host.fishing_runtime, "area_metadata_loaded"),
		Callable(host.fishing_runtime, "location_id_valid").bind(FishingState.FISHING_LOCATION_DEFS)
	), true)
	return payload



func _autosave_if_needed() -> void:
	if save_dirty or _autosave_has_live_state_changes():
		host.save_game()



func _autosave_has_live_state_changes() -> bool:
	if not host.startup_initialized:
		return false
	if not host.running_skill_id.is_empty():
		return true
	if not host.thieving_state.action_jails.is_empty():
		return true
	if host._ad_bonus_runtime().seconds_remaining > 0.0:
		return true
	for raw_module_id in HubRuntime.HUB_MODULE_ORDER:
		if host._hub_surface()._hub_module_building(str(raw_module_id)):
			return true
	for raw_module_id in host.convergence_modules.keys():
		if host._convergence_runtime()._convergence_is_building(str(raw_module_id)):
			return true
	for raw_skill_id in host.skills.keys():
		var skill_id = str(raw_skill_id)
		if SkillState.host_stamina_value(skill_id, host) < float(SkillState.max_stamina(host, skill_id)) - 0.0001:
			return true
	if not host._fighting_runtime().blue_guy_health_full():
		return true
	if host.offline_progress_enabled:
		for raw_action in host.actions_by_skill.get("woodcutting", []):
			var action = raw_action as Dictionary
			if not host._passive_modules_runtime().is_passive_action(action):
				continue
			var module_id = str(action.get("id", host._passive_modules_runtime().WOODCUTTING_LOG_MODULE_ID))
			if host._passive_modules_runtime().is_passive_module_unlocked(module_id):
				return true
	return false



func _trusted_offline_seconds(saved_at_unix_time: int, now_unix_time: int) -> int:
	var wall_elapsed = now_unix_time - saved_at_unix_time
	if wall_elapsed <= 0:
		return 0
	return int(clamp(wall_elapsed, 0, host._hub_surface()._hub_offline_cap_seconds()))



func _apply_offline_progress(saved_at_unix_time: int) -> int:
	var now = host._unix_now()
	last_save_unix_time = now
	var offline = _trusted_offline_seconds(saved_at_unix_time, now)
	if offline <= 0:
		return 0
	if not host.offline_progress_enabled:
		host._ad_bonus_runtime().seconds_remaining = maxf(0.0, host._ad_bonus_runtime().seconds_remaining - float(offline))
		return 0
	var active_result = host._action_runtime()._apply_offline_active_action(float(offline))
	if not bool(active_result.get("handled", false)):
		host._action_runtime()._apply_stamina_regen_seconds(float(offline), false)
		host._fighting_runtime().apply_blue_guy_health_regen_seconds(float(offline))
	host._ad_bonus_runtime().seconds_remaining = maxf(0.0, host._ad_bonus_runtime().seconds_remaining - float(offline))
	_set_offline_result_text(float(offline), active_result)
	host._achievement_overlay_surface()._maybe_show_offline_summary(float(offline), active_result)
	return offline


func _set_offline_result_text(offline_seconds: float, active_result: Dictionary) -> void:
	if not bool(active_result.get("handled", false)):
		return
	var completions := int(active_result.get("completions", 0))
	var action_name := str(active_result.get("action_name", "activity"))
	if completions <= 0:
		host.last_result = "Away %s: %s waited for stamina." % [GameFormatting.duration(offline_seconds), action_name]
		return
	var parts := [
		"Away %s: %s x%s" % [GameFormatting.duration(offline_seconds), action_name, completions]
	]
	var xp_total := int(active_result.get("xp", 0))
	if xp_total > 0:
		parts.append("+%s XP" % xp_total)
	var mastery_total := float(active_result.get("mastery", 0.0))
	if mastery_total > 0.0:
		parts.append("+%s mastery" % GameFormatting.significant_digits(mastery_total))
	var fish_total := float(active_result.get("fish", 0.0))
	if fish_total > 0.0:
		parts.append("+%s food" % GameFormatting.compact_number(maxf(0.0, fish_total), 3))
	var logs_spent := int(active_result.get("logs_spent", 0))
	if logs_spent > 0:
		parts.append("%s Softwood spent" % logs_spent)
	if bool(active_result.get("convergence", false)):
		parts.append("all-skill shrine XP")
	else:
		parts.append("offline XP and mastery at %s%%" % int(round(ActionRuntime.OFFLINE_XP_MULT * 100.0)))
	host.last_result = ", ".join(parts) + "."



func load_game() -> void:
	host.loaded_save_this_boot = false
	host.save_restore_complete = false
	save_writes_blocked = false
	save_writes_blocked_reason = ""
	cancel_next_identity_transition_save()
	_clear_vetted_save_repair_capabilities()
	pending_save_restore_data = {}
	pending_save_has_achievement_toast_seen_ids = false
	var boot_save = _boot_save_dictionary()
	var boot_error := str(boot_save.get("error", ""))
	if not boot_error.is_empty():
		save_writes_blocked = true
		save_writes_blocked_reason = boot_error
		host.last_result = "Save recovery required. Existing save files were preserved."
		push_warning("Idle Elite blocked save writes: %s" % boot_error)
		return
	var save_data = boot_save.get("data", {}) as Dictionary
	if save_data.is_empty():
		_start_new_save_file()
		return
	var repair_source_payload := save_data.duplicate(true)
	var boot_identity_repair_source := boot_save.get("identity_repair_source", {}) as Dictionary
	var boot_identity_repair_payload := boot_save.get("identity_repair_payload", {}) as Dictionary
	var identity_needed_repair := SaveStateNormalizers.payload_has_recoverable_identity_inconsistency(save_data)
	var recovered_save = bool(boot_save.get("recovered", false))
	var loaded_schema_version := int(save_data.get("save_schema_version", 0))
	var migrated_save := _migrate_save_to_current_schema(save_data)
	if migrated_save.is_empty():
		append_save_journal_event("migration", {"result": "failed", "migration_from": loaded_schema_version, "migration_to": SAVE_SCHEMA_VERSION})
		save_writes_blocked = true
		save_writes_blocked_reason = "save migration failed"
		host.last_result = "Save recovery required. Existing save files were preserved."
		return
	save_data = migrated_save
	append_save_journal_event("migration", {
		"result": "unchanged" if loaded_schema_version == SAVE_SCHEMA_VERSION else "ok",
		"migration_from": loaded_schema_version,
		"migration_to": SAVE_SCHEMA_VERSION,
		"revision": int(save_data.get("save_revision", 0)),
	})
	var save_needed_repair = _repair_save_for_regular_play(save_data)
	var save_repair_reduces_progress := save_needed_repair and SaveStateNormalizers.payload_regresses_game_progress(repair_source_payload, save_data, host.skill_defs)
	var repair_has_stable_account_boundary := not SaveStateNormalizers.stable_account_uid(repair_source_payload).is_empty()
	if not boot_identity_repair_source.is_empty() and not boot_identity_repair_payload.is_empty():
		_allow_next_vetted_identity_repair_save(boot_identity_repair_source, boot_identity_repair_payload, true)
	elif identity_needed_repair:
		_allow_next_vetted_identity_repair_save(repair_source_payload, save_data)
	if save_repair_reduces_progress:
		_allow_next_vetted_progress_repair_save(repair_source_payload, save_data)
	save_repaired_this_boot = recovered_save or save_needed_repair or identity_needed_repair or loaded_schema_version < SAVE_SCHEMA_VERSION
	_load_game_core(save_data)
	if repair_has_stable_account_boundary and (save_repair_reduces_progress or identity_needed_repair):
		save_repair_generation = SaveStateNormalizers.save_repair_generation(save_data) + 1
	pending_save_has_achievement_toast_seen_ids = save_data.has("achievement_toast_seen_ids")
	pending_save_restore_data = save_data
	host.loaded_save_this_boot = true
	_restore_boot_render_save_fields(save_data)
	if not host._onboarding_runtime()._onboarding_path_active() and not host.running_skill_id.is_empty() and host.skills.has(host.running_skill_id) and not host._action_data(host.running_skill_id, host.running_action_id).is_empty():
		host.selected_skill_id = host.running_skill_id


func _clear_pending_save_restore_work() -> void:
	pending_save_restore_data = {}
	pending_save_has_achievement_toast_seen_ids = false
	pending_post_load_saved_at = -1
	boot_post_load_simulation_scheduled = false
	save_repaired_this_boot = false
	_clear_vetted_save_repair_capabilities()


func _load_game_secondary_restore() -> void:
	if pending_save_restore_data.is_empty():
		return
	var restored_save := pending_save_restore_data
	# Restore account identity before any subsystem that can initiate an online
	# request. Keep the pending payload until every restore step has completed so a
	# runtime error cannot turn a partial restore into a saveable state.
	host.leaderboard_state.restore_submission_metadata_from_save(restored_save)
	LeaderboardProfile.restore_profile_metadata_from_save(host, restored_save, host.PROFILE_GUEST_NAME_PREFIX, host.PROFILE_DISPLAY_NAME_MAX_CHARS, host.PROFILE_NAME_KEY_MAX_CHARS, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT)
	LeaderboardProfile.restore_auth_metadata_from_save(host, restored_save)
	var online_runtime = host._online_runtime()
	if online_runtime.has_method("restore_auth_identity_metadata_from_save"):
		online_runtime.call("restore_auth_identity_metadata_from_save", restored_save)
	achievement_toast_seen_ids = AchievementState.normalized_seen_ids(restored_save.get("achievement_toast_seen_ids", {}))
	if not pending_save_has_achievement_toast_seen_ids:
		AchievementState.mark_completed_seen_ids(AchievementState.milestones(host, false), achievement_toast_seen_ids, ["activity-crit", "activity-mega-crit"])
	pending_save_has_achievement_toast_seen_ids = false
	_restore_thieving_trophies_from_save(restored_save)
	_restore_activity_crit_metadata_from_save(restored_save)
	if not _save_needs_fishing_restore(restored_save):
		host.fishing_runtime.restore_auto_eat_fish_enabled_from_save(host, restored_save)
		host._restore_fishing_state_from_save(restored_save)
	host._passive_modules_runtime().restore_from_save(restored_save, true)
	if host.convergence_modules.is_empty():
		host._convergence_runtime()._restore_convergence_modules_from_save(restored_save)
	host._hub_runtime().restore_modules(restored_save.get("hub_modules", {}))
	host._hub_runtime().restore_selected_module_id(restored_save)
	host._hub_surface()._restore_hub_module_positions(restored_save.get("hub_module_positions", {}))
	host._hub_surface()._restore_hub_decor_layout(restored_save.get("hub_decor_layout", []))
	host._hub_runtime().restore_missions(restored_save.get("hub_missions", []))
	host._hub_runtime().restore_mission_cooldown(restored_save)
	_restore_boot_visible_tip_flags_from_save(restored_save)
	host.plank_boost_enabled = SaveStateNormalizers.bool_value(restored_save, "plank_boost_enabled")
	host._ad_bonus_runtime().restore_seconds_from_save(restored_save)
	host._action_runtime().activity_start_count = SaveStateNormalizers.nonnegative_int(restored_save, "activity_start_count")
	host._action_runtime().activity_completion_count = SaveStateNormalizers.nonnegative_int(restored_save, "activity_completion_count")
	host._action_runtime().guaranteed_success_action_completions = SaveStateNormalizers.clamped_int(restored_save, "guaranteed_success_action_completions", 0, ActionRuntime.GUARANTEED_SUCCESS_ACTION_COMPLETIONS, host._action_runtime().activity_completion_count)
	_restore_onboarding_progression_from_save(restored_save)
	_restore_tip_metadata_from_save(restored_save)
	host.stamina_gauge_pre_tip_hold_seconds = SaveStateNormalizers.clamped_float(restored_save, "stamina_gauge_pre_tip_hold_seconds", 0.0, host.STAMINA_TIP_DISCOVERY_HOLD_SECONDS)
	host._audio_director().restore_music_flow_state(restored_save)
	host.leaderboard_state.restore_fetch_metadata_from_save(restored_save)
	online_runtime.restore_chat_metadata_from_save(restored_save)
	_apply_legacy_clock_guard_leaderboard_forgiveness(restored_save)
	host._navigation_shell()._refresh_shop_nav_unlock_state()
	pending_save_restore_data = {}
	pending_save_has_achievement_toast_seen_ids = false
	host.save_restore_complete = true
	if save_repaired_this_boot:
		save_repaired_this_boot = false
		host.last_result = "Save repaired. Progress will save normally."
		save_game()


func _schedule_boot_post_load_simulation() -> void:
	if boot_post_load_simulation_scheduled or pending_post_load_saved_at < 0:
		return
	boot_post_load_simulation_scheduled = true
	call_deferred("_apply_boot_post_load_simulation_after_cards")


func _save_needs_fishing_restore(data: Dictionary) -> bool:
	var selected := str(data.get("selected_skill_id", host.selected_skill_id))
	var running := str(data.get("running_skill_id", ""))
	return selected == "fishing" or running == "fishing"


func _legacy_clock_guard_was_saved(data: Dictionary) -> bool:
	return bool(data.get("offline_clock_guard_tainted", false)) or int(data.get("offline_clock_guard_last_rejected_unix", 0)) > 0


func _apply_legacy_clock_guard_leaderboard_forgiveness(data: Dictionary) -> void:
	if not _legacy_clock_guard_was_saved(data):
		return
	host.leaderboard_state.last_submitted_score = 0
	host.leaderboard_state.last_submitted_total_xp = 0
	host.leaderboard_state.last_submitted_scores_by_category.clear()
	host.leaderboard_state.last_submit_unix = 0
	var leaderboard_state = host.leaderboard_state
	leaderboard_state.fetch_retry_unix_by_category.clear()
	host._online_runtime().leaderboard_auth_retry_after_unix = 0
	host._online_runtime().clear_chat_clock_guard_metadata()
	var old_result := str(host.last_result)
	if old_result.to_lower().find("clock") >= 0:
		host.last_result = ""
	leaderboard_state.status_message = ""
	_mark_save_dirty("legacy clock guard forgiven")


func _apply_boot_post_load_simulation_after_cards() -> void:
	var wait_started_msec := Time.get_ticks_msec()
	while (
		host.is_inside_tree()
		and pending_post_load_saved_at >= 0
		and (host.boot_detail_render_in_progress or host.boot_detail_scroll_locked or not host.boot_detail_render_queue.is_empty())
	):
		if Time.get_ticks_msec() - wait_started_msec >= 5000:
			break
		await host.get_tree().process_frame
	if not host.is_inside_tree():
		return
	boot_post_load_simulation_scheduled = false
	_apply_post_load_simulation()


func _apply_post_load_simulation() -> void:
	if pending_post_load_saved_at < 0:
		return
	var saved_at := pending_post_load_saved_at
	pending_post_load_saved_at = -1
	var offline_seconds := _apply_offline_progress(saved_at)
	var now: int = host._unix_now()
	host._passive_modules_runtime().sync_passive_module_unlocks(now)
	if host.offline_progress_enabled:
		host._passive_modules_runtime().apply_passive_module_production(now)
	else:
		host._passive_modules_runtime().reset_passive_module_timestamps(now)
	host.last_passive_process_unix = now
	host.thieving_state.ensure_all_trophy_state()
	host._hub_runtime().sync_trophy_level_from_thieving()
	host._hub_surface()._validate_hub_module_positions()
	host._hub_runtime().sync_missions()
	host._hub_runtime().sync_trophy_level_from_thieving()
	if not host._audio_director().music_start_chance_unlocked and host._audio_director()._saved_music_groove_floor() >= host._audio_director().MUSIC_BASE_ACTION_THRESHOLD:
		host._audio_director().music_start_chance_unlocked = true
	host._audio_director()._maybe_start_music_cycle_on_launch()
	SkillState.invalidate_stat_caches(host)
	host._update_ui(0.0, true)
	if offline_seconds > 0:
		host.save_game()



func _boot_save_dictionary() -> Dictionary:
	var any_save_file_exists := false
	var local_save_candidates: Array[Dictionary] = []
	for path in _local_save_paths():
		if not FileAccess.file_exists(path):
			continue
		any_save_file_exists = true
		var result := load_dictionary_result(path)
		var error := str(result.get("error", ""))
		var data := result.get("data", {}) as Dictionary
		append_save_journal_event("load_candidate", {
			"source": path,
			"result": "ok" if error.is_empty() else error,
			"schema": int(result.get("schema_version", 0)),
			"revision": int(data.get("save_revision", 0)),
		})
		if error in ["future_schema", "unsupported_envelope"]:
			return {"data": {}, "error": "a newer app version is required"}
		if not error.is_empty():
			quarantine_invalid_save(path)
		elif not data.is_empty():
			local_save_candidates.append({"path": path, "data": data})
	var recovery_result := _recovery_save_result()
	var recovery_data := recovery_result.get("data", {}) as Dictionary
	var recovery_path := str(recovery_result.get("path", ""))
	var selected_data := {}
	var selected_path := ""
	var selected_recovered := false
	var primary_error := ""
	if FileAccess.file_exists(SAVE_PATH):
		var primary_result := load_dictionary_result(SAVE_PATH)
		var save_data := primary_result.get("data", {}) as Dictionary
		primary_error = str(primary_result.get("error", ""))
		if should_replace_best_save(save_data, recovery_data, host.skill_defs, host.FISHING_ACTION_ID_ALIASES):
			selected_data = recovery_data
			selected_path = recovery_path
			selected_recovered = true
		if not save_data.is_empty():
			if selected_data.is_empty():
				selected_data = save_data
				selected_path = SAVE_PATH
	if selected_data.is_empty() and not recovery_data.is_empty():
		selected_data = recovery_data
		selected_path = recovery_path
		selected_recovered = true

	# A valid but brand-new/current blank save must not hide a progressed save from
	# the former desktop project directory during an in-place application update.
	var legacy_save = _legacy_desktop_save_for_recovery(selected_data)
	if not legacy_save.is_empty():
		var legacy_identity_repair_source := legacy_save.duplicate(true)
		var legacy_identity_recovery := _recover_claimed_identity_from_local_candidates(legacy_save, local_save_candidates)
		legacy_save = legacy_identity_recovery.get("data", legacy_save) as Dictionary
		var legacy_identity_recovered := bool(legacy_identity_recovery.get("recovered", false))
		if not _preserve_payload_as_recovery_snapshot(legacy_save):
			return {"data": {}, "error": "the legacy recovery save could not be snapshotted"}
		if FileAccess.file_exists(SAVE_PATH):
			var legacy_primary_result := load_dictionary_result(SAVE_PATH)
			if not str(legacy_primary_result.get("error", "")).is_empty():
				if not quarantine_invalid_save(SAVE_PATH) or not _remove_file_if_present(SAVE_PATH):
					return {"data": {}, "error": "the invalid primary save could not be isolated"}
		append_save_journal_event("load_selected", {"source": "legacy_desktop", "result": "recovered", "schema": int(legacy_save.get("save_schema_version", 0)), "revision": int(legacy_save.get("save_revision", 0))})
		var legacy_boot_result := {"data": legacy_save, "recovered": true}
		if legacy_identity_recovered:
			legacy_boot_result["identity_repair_source"] = legacy_identity_repair_source
			legacy_boot_result["identity_repair_payload"] = legacy_save.duplicate(true)
		return legacy_boot_result
	if not selected_data.is_empty():
		var selected_identity_repair_source := selected_data.duplicate(true)
		var identity_recovery := _recover_claimed_identity_from_local_candidates(selected_data, local_save_candidates)
		selected_data = identity_recovery.get("data", selected_data) as Dictionary
		var identity_recovered := bool(identity_recovery.get("recovered", false))
		if identity_recovered:
			append_save_journal_event("identity_recovery", {
				"source": str(identity_recovery.get("source", "")),
				"result": "grafted",
				"revision": int(selected_data.get("save_revision", 0)),
			})
		if selected_recovered:
			if not _preserve_recovery_candidate(selected_path):
				return {"data": {}, "error": "the recovery save could not be snapshotted"}
			if not primary_error.is_empty():
				if not quarantine_invalid_save(SAVE_PATH):
					return {"data": {}, "error": "the primary save could not be quarantined"}
				if not _remove_file_if_present(SAVE_PATH):
					return {"data": {}, "error": "the quarantined primary save could not be isolated"}
		append_save_journal_event("load_selected", {
			"source": selected_path,
			"result": "identity_recovered" if identity_recovered else ("recovered" if selected_recovered else "primary"),
			"schema": int(selected_data.get("save_schema_version", 0)),
			"revision": int(selected_data.get("save_revision", 0)),
		})
		var boot_result := {"data": selected_data, "recovered": selected_recovered or identity_recovered}
		if identity_recovered:
			boot_result["identity_repair_source"] = selected_identity_repair_source
			boot_result["identity_repair_payload"] = selected_data.duplicate(true)
		return boot_result
	if any_save_file_exists:
		return {"data": {}, "error": "all local save copies are unreadable or incomplete"}
	return {"data": {}, "recovered": false}



func _recover_claimed_identity_from_local_candidates(selected_data: Dictionary, candidates: Array[Dictionary]) -> Dictionary:
	for candidate_entry in candidates:
		var candidate_data := candidate_entry.get("data", {}) as Dictionary
		var repaired := payload_with_recovered_claimed_identity(selected_data, candidate_data)
		if repaired != selected_data:
			return {
				"data": repaired,
				"recovered": true,
				"source": str(candidate_entry.get("path", "")),
			}
	return {"data": selected_data, "recovered": false, "source": ""}



func _start_new_save_file() -> void:
	if _any_local_save_file_exists():
		save_writes_blocked = true
		save_writes_blocked_reason = "existing save files require recovery"
		host.last_result = "Save recovery required. Existing save files were preserved."
		return
	save_reset_generation = 0
	save_repair_generation = 0
	save_revision = 0
	host.selected_skill_id = host.TUTORIAL_STARTER_SKILL_ID
	host.current_screen = "skill"
	host._onboarding_runtime().prepare_tutorial_state()
	var now: int = host._unix_now()
	var payload := _save_payload(now)
	payload["save_revision"] = 1
	append_save_journal_event("save_requested", {"trigger": "new_install", "revision": 1, "schema": SAVE_SCHEMA_VERSION})
	if not _write_save_payload_atomically(payload):
		save_writes_blocked = true
		save_writes_blocked_reason = "initial save write failed"
		host.last_result = "Save failed. Existing recovery files were preserved."
		return
	save_revision = 1
	save_dirty = false
	save_dirty_reason = ""
	_sync_web_userfs_after_save()
	host.save_restore_complete = true



func _recovery_save_dictionary() -> Dictionary:
	var best_save := _recovery_save_result().get("data", {}) as Dictionary
	if not best_save.is_empty():
		push_warning("Idle Elite recovered save progress from backup storage.")
	return best_save


func _recovery_save_result() -> Dictionary:
	return best_dictionary_result_from_paths(
		[SAVE_TEMP_PATH, SAVE_BACKUP_PATH, SAVE_BACKUP_2_PATH, SAVE_BACKUP_3_PATH, SAVE_RECOVERY_SNAPSHOT_PATH],
		host.skill_defs,
		host.FISHING_ACTION_ID_ALIASES
	)


func _preserve_recovery_candidate(source_path: String) -> bool:
	if source_path.is_empty():
		return false
	if source_path == SAVE_RECOVERY_SNAPSHOT_PATH:
		return str(load_dictionary_result(source_path).get("error", "")).is_empty()
	var preserved := copy_valid_save(source_path, SAVE_RECOVERY_SNAPSHOT_PATH, SAVE_RECOVERY_SNAPSHOT_PATH + ".staging")
	append_save_journal_event("recovery_snapshot", {"source": source_path, "result": "preserved" if preserved else "failed"})
	return preserved


func _preserve_payload_as_recovery_snapshot(payload: Dictionary) -> bool:
	var encoded := encoded_payload(payload)
	var staging_path := SAVE_RECOVERY_SNAPSHOT_PATH + ".staging"
	if not write_text(staging_path, encoded):
		return false
	var result := load_dictionary_result(staging_path)
	if not str(result.get("error", "")).is_empty() or str(result.get("raw", "")) != encoded:
		return false
	var preserved := _replace_with_staged_file(staging_path, SAVE_RECOVERY_SNAPSHOT_PATH)
	append_save_journal_event("recovery_snapshot", {"source": "legacy_desktop", "result": "preserved" if preserved else "failed"})
	return preserved


func _local_save_paths() -> Array:
	return [SAVE_PATH, SAVE_TEMP_PATH, SAVE_BACKUP_PATH, SAVE_BACKUP_2_PATH, SAVE_BACKUP_3_PATH, SAVE_RECOVERY_SNAPSHOT_PATH]


func _any_local_save_file_exists() -> bool:
	for path in _local_save_paths():
		if FileAccess.file_exists(path):
			return true
	return false


func boot_storage_failure_blocks_restore() -> bool:
	return save_writes_blocked


func boot_recovery_blocks_reveal() -> bool:
	return save_writes_blocked or not bool(host.save_restore_complete)


func boot_recovery_status_text() -> String:
	if _any_local_save_file_exists():
		return SAVE_RECOVERY_BLOCK_MESSAGE
	return SAVE_STORAGE_BLOCK_MESSAGE


func _migrate_save_to_current_schema(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	var schema_version := int(migrated.get("save_schema_version", 0))
	if schema_version < 0 or schema_version > SAVE_SCHEMA_VERSION:
		return {}
	while schema_version < SAVE_SCHEMA_VERSION:
		match schema_version:
			0:
				# Pre-versioned flat saves already use the v1 field layout.
				schema_version = 1
			1:
				# v2 adds storage metadata only; gameplay and profile values remain
				# byte-for-byte equivalent after JSON decoding.
				if not migrated.has("save_revision"):
					migrated["save_revision"] = 0
				schema_version = 2
			_:
				return {}
		migrated["save_schema_version"] = schema_version
	if SaveStateNormalizers.payload_has_recoverable_identity_inconsistency(migrated):
		migrated["leaderboard_auth_recovery_required"] = true
		if str(migrated.get("leaderboard_auth_recovery_reason", "")).strip_edges().is_empty():
			migrated["leaderboard_auth_recovery_reason"] = "Saved online identity needs recovery."
	return migrated



func _legacy_desktop_save_for_recovery(current_data: Dictionary) -> Dictionary:
	for path in _legacy_desktop_save_paths():
		if not FileAccess.file_exists(path):
			continue
		var legacy_data = load_dictionary(path)
		if _save_should_use_legacy_desktop_recovery(current_data, legacy_data):
			return _prepare_legacy_desktop_save_for_recovery(legacy_data)
	return {}



func _legacy_desktop_save_paths() -> Array:
	if OS.has_feature("web"):
		return []
	var user_dir = ProjectSettings.globalize_path("user://")
	while user_dir.ends_with("/") or user_dir.ends_with("\\"):
		user_dir = user_dir.substr(0, user_dir.length() - 1)
	if user_dir.is_empty():
		return []
	var app_userdata_dir = user_dir.get_base_dir()
	if app_userdata_dir.is_empty() or app_userdata_dir == user_dir:
		return []
	return [
		app_userdata_dir.path_join("Idle Elite").path_join("idle_elite_save.json"),
		app_userdata_dir.path_join("Idle Slop").path_join("idle_elite_save.json"),
	]



func _save_should_use_legacy_desktop_recovery(current_data: Dictionary, legacy_data: Dictionary) -> bool:
	if legacy_data.is_empty() or not SaveStateNormalizers.has_known_skill_progress(legacy_data, host.skill_defs):
		return false
	if SaveStateNormalizers.has_known_skill_progress(current_data, host.skill_defs):
		return false
	var current_uid := SaveStateNormalizers.stable_account_uid(current_data)
	var legacy_uid := SaveStateNormalizers.stable_account_uid(legacy_data)
	# An established blank account may be new gameplay, but it is still an account
	# boundary. Only import a legacy candidate into it when the UID proves ownership.
	if not current_uid.is_empty() and legacy_uid != current_uid:
		return false
	return true



func _prepare_legacy_desktop_save_for_recovery(data: Dictionary) -> Dictionary:
	var prepared = data.duplicate(true)
	_normalize_legacy_desktop_skill_levels(prepared)
	return prepared



func _normalize_legacy_desktop_skill_levels(data: Dictionary) -> void:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return
	var source = loaded_skills as Dictionary
	for raw_def in host.skill_defs:
		var skill_def = raw_def as Dictionary
		var skill_id = str(skill_def.get("id", ""))
		if skill_id.is_empty() or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state = skill_state as Dictionary
		var saved_level = clampi(int(state.get("level", 1)), 1, host.GOD_MODE_TARGET_LEVEL)
		var saved_xp = state.get("xp", null)
		if typeof(saved_xp) not in [TYPE_INT, TYPE_FLOAT] or float(saved_xp) < 0.0:
			state["xp"] = SkillState.xp_for_level(saved_level)
		else:
			# XP is the authoritative accumulated-progress value. Replacing a valid
			# legacy value with the floor for its cached level loses within-level XP.
			state["xp"] = maxi(0, int(saved_xp))
		state["level"] = saved_level
		source[skill_id] = state
	data["skills"] = source



func _repair_save_for_regular_play(data: Dictionary) -> bool:
	var repaired = _repair_onboarding_progress_mismatch(data)
	var test_save := bool(data.get("god_mode_save_tainted", false)) or bool(data.get("god_mode_enabled", false))
	if test_save and host._test_state_runtime()._god_mode_available():
		return repaired
	if test_save:
		data["god_mode_enabled"] = false
		data["god_mode_save_tainted"] = false
		repaired = true
	if str(data.get(TRUSTED_DESTRUCTIVE_REPAIR_KEY, "")) != TRUSTED_DESTRUCTIVE_REPAIR_MARKER:
		return repaired
	# Destructive historical heuristics are support-authorized only. Requirement
	# thresholds, XP curves, and offline progression have all changed over time, so
	# none of these shapes proves corruption in an ordinary player save.
	data.erase(TRUSTED_DESTRUCTIVE_REPAIR_KEY)
	repaired = true
	if _repair_manual_activity_unlock_corruption(data):
		repaired = true
	if _repair_impossible_thieving_trophies(data):
		repaired = true
	if _save_has_unmarked_maxed_skills(data):
		_repair_maxed_skill_progression(data)
		data.erase("manual_activity_unlocks")
		data.erase("manual_activity_requirement_unlocks")
	return repaired



func _repair_impossible_thieving_trophies(data: Dictionary) -> bool:
	var loaded_trophies = data.get("thieving_trophies", {})
	if typeof(loaded_trophies) != TYPE_DICTIONARY:
		return false
	var trophies = loaded_trophies as Dictionary
	var thieving_level = _saved_skill_level_for_repair(data, "thieving")
	var repaired = false
	for raw_heist in host.thieving_state.HEIST_DEFS:
		var heist = raw_heist as Dictionary
		var heist_id = str(heist.get("id", ""))
		if heist_id.is_empty() or not trophies.has(heist_id):
			continue
		var raw_state = trophies.get(heist_id, {})
		var stolen = false
		if typeof(raw_state) == TYPE_DICTIONARY:
			stolen = bool((raw_state as Dictionary).get("stolen", false))
		elif typeof(raw_state) == TYPE_BOOL:
			stolen = bool(raw_state)
		if not stolen or thieving_level >= int(heist.get("unlock", 1)):
			continue
		if typeof(raw_state) == TYPE_DICTIONARY:
			var state = (raw_state as Dictionary).duplicate(true)
			state["stolen"] = false
			state["cooldown_until_unix"] = 0
			trophies[heist_id] = state
		else:
			trophies[heist_id] = {"stolen": false, "cooldown_until_unix": 0}
		repaired = true
	if repaired:
		data["thieving_trophies"] = trophies
	return repaired



func _saved_skill_level_for_repair(data: Dictionary, skill_id: String) -> int:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return 1
	var skill_state = (loaded_skills as Dictionary).get(skill_id, {})
	if typeof(skill_state) != TYPE_DICTIONARY:
		return 1
	var state = skill_state as Dictionary
	if state.has("xp"):
		return SkillState.skill_level_for_xp(maxi(0, int(state.get("xp", 0))))
	return clampi(int(state.get("level", 1)), 1, host.GOD_MODE_TARGET_LEVEL)



func _repair_onboarding_progress_mismatch(data: Dictionary) -> bool:
	if bool(data.get("onboarding_tutorial_complete", false)):
		return false
	if not SaveStateNormalizers.has_progress_beyond_onboarding(data, host.skill_defs, host.TUTORIAL_STARTER_SKILL_ID):
		return false
	SaveStateNormalizers.mark_onboarding_complete(data)
	return true



func _repair_manual_activity_unlock_corruption(data: Dictionary) -> bool:
	var raw_manual = data.get("manual_activity_unlocks", {})
	if typeof(raw_manual) != TYPE_DICTIONARY:
		return false
	var manual = raw_manual as Dictionary
	if manual.is_empty():
		return false
	var valid = {}
	var impossible_count = 0
	var manual_count = 0
	for raw_key in manual.keys():
		if not bool(manual.get(raw_key, false)):
			continue
		var key = host._activity_unlock_runtime()._canonical_manual_activity_unlock_key(str(raw_key))
		if key.is_empty():
			continue
		manual_count += 1
		var action_ref = _action_ref_from_key(key)
		if action_ref.is_empty():
			valid[key] = true
			continue
		var skill_id = str(action_ref.get("skill_id", ""))
		var action = action_ref.get("action", {}) as Dictionary
		if _save_action_requirements_met(data, skill_id, action):
			valid[key] = true
		else:
			impossible_count += 1
	if manual_count <= 0:
		return false
	var bulk_corruption = manual_count >= 50 and impossible_count >= maxi(12, int(float(manual_count) * 0.45))
	if bulk_corruption:
		data["manual_activity_unlocks"] = {}
		return true
	if impossible_count <= 0:
		return false
	data["manual_activity_unlocks"] = valid
	return true



func _action_ref_from_key(key: String) -> Dictionary:
	var parts = key.split(":", false, 2)
	if parts.size() < 2:
		return {}
	var skill_id = str(parts[0])
	var action_id = str(parts[1])
	if skill_id.is_empty() or action_id.is_empty():
		return {}
	for raw_action in host.actions_by_skill.get(skill_id, []):
		var action = raw_action as Dictionary
		if str(action.get("id", "")) == action_id:
			return {
				"skill_id": skill_id,
				"action": action
			}
	return {}



func _save_action_requirements_met(data: Dictionary, skill_id: String, action: Dictionary) -> bool:
	if action.is_empty():
		return false
	for raw_requirement in host._activity_unlock_runtime()._action_unlock_requirements(skill_id, action):
		if typeof(raw_requirement) != TYPE_DICTIONARY:
			return false
		var requirement = raw_requirement as Dictionary
		var requirement_skill = str(requirement.get("skill", skill_id))
		if _save_skill_level(data, requirement_skill) < int(requirement.get("level", 1)):
			return false
	return true



func _save_skill_level(data: Dictionary, skill_id: String) -> int:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return 1
	var skill_state = (loaded_skills as Dictionary).get(skill_id, {})
	if typeof(skill_state) != TYPE_DICTIONARY:
		return 1
	var state = skill_state as Dictionary
	var xp = maxi(0, int(state.get("xp", 0)))
	return maxi(1, maxi(int(state.get("level", 1)), SkillState.skill_level_for_xp(xp)))



func _repair_maxed_skill_progression(data: Dictionary) -> void:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return
	var source = loaded_skills as Dictionary
	var target_xp = SkillState.xp_for_level(host.GOD_MODE_TARGET_LEVEL)
	for raw_def in host.skill_defs:
		var skill_def = raw_def as Dictionary
		var skill_id = str(skill_def.get("id", ""))
		if skill_id.is_empty() or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state = skill_state as Dictionary
		var xp = maxi(0, int(state.get("xp", 0)))
		var level = maxi(int(state.get("level", 0)), SkillState.skill_level_for_xp(xp))
		if level < host.GOD_MODE_TARGET_LEVEL and xp < target_xp:
			continue
		var repaired_xp = _estimated_repaired_skill_xp(data, skill_id)
		state["xp"] = repaired_xp
		state["level"] = SkillState.skill_level_for_xp(repaired_xp)
		source[skill_id] = state
	data["skills"] = source



func _estimated_repaired_skill_xp(data: Dictionary, skill_id: String) -> int:
	var evidence_xp = 0
	var mastery_data = data.get("mastery", {})
	if typeof(mastery_data) == TYPE_DICTIONARY:
		var mastery_source = mastery_data as Dictionary
		for raw_key in mastery_source.keys():
			var key = str(raw_key)
			if not key.begins_with("%s:" % skill_id):
				continue
			var entry = mastery_source.get(raw_key, {})
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var mastery_entry = entry as Dictionary
			if int(mastery_entry.get("level", 0)) >= host.MASTERY_MAX_LEVEL:
				continue
			evidence_xp += maxi(0, int(mastery_entry.get("xp", 0)))
	if skill_id == host.TUTORIAL_STARTER_SKILL_ID:
		evidence_xp = maxi(evidence_xp, _save_activity_completion_evidence(data))
	return clampi(evidence_xp, 0, SkillState.xp_for_level(20))



func _save_has_unmarked_maxed_skills(data: Dictionary) -> bool:
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) != TYPE_DICTIONARY:
		return false
	var source = loaded_skills as Dictionary
	var target_xp = SkillState.xp_for_level(host.GOD_MODE_TARGET_LEVEL)
	var known_skill_count = 0
	var maxed_skill_count = 0
	var exact_god_mode_xp_count = 0
	for raw_def in host.skill_defs:
		var skill_def = raw_def as Dictionary
		var skill_id = str(skill_def.get("id", ""))
		if skill_id.is_empty() or not source.has(skill_id):
			continue
		var skill_state = source.get(skill_id, {})
		if typeof(skill_state) != TYPE_DICTIONARY:
			continue
		var state = skill_state as Dictionary
		var xp = maxi(0, int(state.get("xp", 0)))
		var level = maxi(int(state.get("level", 0)), SkillState.skill_level_for_xp(xp))
		known_skill_count += 1
		if level >= host.GOD_MODE_TARGET_LEVEL or xp >= target_xp:
			maxed_skill_count += 1
		if xp == target_xp:
			exact_god_mode_xp_count += 1
	if known_skill_count < 3 or maxed_skill_count < known_skill_count:
		return false
	if exact_god_mode_xp_count >= known_skill_count:
		return true
	return _save_activity_completion_evidence(data) < host.UNMARKED_MAXED_SAVE_COMPLETION_LIMIT



func _save_activity_completion_evidence(data: Dictionary) -> int:
	return maxi(
		maxi(0, int(data.get("activity_completion_count", 0))),
		maxi(0, int(data.get("onboarding_starter_action_completion_count", 0)))
	)



func _restore_thieving_trophies_from_save(data: Dictionary) -> void:
	host.thieving_state.restore_trophies(data.get("thieving_trophies", {}), true)



func _restore_activity_crit_metadata_from_save(data: Dictionary) -> void:
	host.activity_crit_seen = bool(data.get("activity_crit_seen", false))
	host.activity_mega_crit_seen = bool(data.get("activity_mega_crit_seen", false))
	if host.activity_mega_crit_seen:
		host.activity_crit_seen = true



func _restore_boot_visible_tip_flags_from_save(data: Dictionary) -> void:
	host._onboarding_runtime().activity_start_tip_seen = bool(data.get("activity_start_tip_seen", false))
	host._hub_surface().hub_tutorial_tip_seen = bool(data.get("hub_tutorial_tip_seen", false))



func _restore_boot_render_save_fields(data: Dictionary) -> void:
	SaveStateNormalizers.mark_onboarding_complete(data)
	_restore_thieving_trophies_from_save(data)
	_restore_boot_visible_tip_flags_from_save(data)
	host._onboarding_runtime().skill_swipe_tip_seen = bool(data.get("skill_swipe_tip_seen", false))
	host._onboarding_runtime().onboarding_explore_tip_seen = bool(data.get("onboarding_explore_tip_seen", false))
	host._onboarding_runtime().onboarding_tutorial_complete = bool(data.get("onboarding_tutorial_complete", false))
	host._onboarding_runtime().stamina_gauge_tip_seen = bool(data.get("stamina_gauge_tip_seen", false))
	host._onboarding_runtime().onboarding_fight_summary_revealed = bool(data.get("onboarding_fight_summary_revealed", false))
	host._onboarding_runtime().onboarding_fight_auto_run_message_shown = bool(data.get("onboarding_fight_auto_run_message_shown", false))
	host._onboarding_runtime().onboarding_fight_stamina_revealed = bool(data.get("onboarding_fight_stamina_revealed", false))
	host._onboarding_runtime().onboarding_fight_action_stats_revealed = bool(data.get("onboarding_fight_action_stats_revealed", false))
	_restore_tutorial_state_from_save(data)
	_apply_onboarding_restored_completion_implications()
	_restore_tutorial_gate_latch_from_save(data)
	_restore_tip_metadata_from_save(data)



func _restore_tip_metadata_from_save(data: Dictionary) -> void:
	var tip_metadata := SaveStateNormalizers.restored_tip_metadata(data, SkillDetailSurface.DETAIL_PULL_TIP_TEXTS, Callable(self, "_action_key_for_save"))
	host._onboarding_runtime().lock_click_tip_seen = bool(tip_metadata.get("lock_click_tip_seen", false))
	host._onboarding_runtime().passive_module_tip_seen = bool(tip_metadata.get("passive_module_tip_seen", false))
	host._onboarding_runtime().silver_opportunity_tip_seen = bool(tip_metadata.get("silver_opportunity_tip_seen", false))
	host._onboarding_runtime().silver_opportunity_tip_action_key = str(tip_metadata.get("silver_opportunity_tip_action_key", ""))
	host._skill_detail_surface().detail_pull_recent_tip_texts = tip_metadata.get("detail_pull_recent_tip_texts", []) as Array



func _onboarding_restored_completion_seen() -> bool:
	return (
		host._onboarding_runtime().activity_start_tip_seen
		or host._onboarding_runtime().stamina_gauge_tip_seen
		or host._onboarding_runtime().skill_swipe_tip_seen
		or host._onboarding_runtime().onboarding_explore_tip_seen
		or host._onboarding_runtime().onboarding_tutorial_complete
	)



func _apply_onboarding_restored_completion_implications() -> void:
	if _onboarding_restored_completion_seen():
		host._onboarding_runtime().onboarding_fight_summary_revealed = true
		host._onboarding_runtime().onboarding_fight_auto_run_message_shown = true
		host._onboarding_runtime().onboarding_fight_stamina_revealed = true
		host._onboarding_runtime().onboarding_fight_action_stats_revealed = true
	if host._onboarding_runtime().onboarding_tutorial_complete or host._onboarding_runtime().skill_swipe_tip_seen:
		host._onboarding_runtime().onboarding_swipe_tip_eligible = true
		host._onboarding_runtime().onboarding_swipe_navigation_unlocked = true



func _restore_tutorial_state_from_save(data: Dictionary) -> void:
	if host._onboarding_runtime().onboarding_tutorial_complete:
		host._onboarding_runtime().tutorial_active = false
		host._onboarding_runtime().tutorial_step = 4
		return
	if data.has("tutorial_active"):
		host._onboarding_runtime().tutorial_active = bool(data.get("tutorial_active", false))
		if host._onboarding_runtime().tutorial_active and _onboarding_restored_completion_seen():
			host._onboarding_runtime().tutorial_active = false
	else:
		host._onboarding_runtime().tutorial_active = not _onboarding_restored_completion_seen()
	if host._onboarding_runtime().tutorial_active:
		host._onboarding_runtime().tutorial_step = clampi(int(data.get("tutorial_step", 1)), 1, 4)
		host.selected_skill_id = host.TUTORIAL_STARTER_SKILL_ID
		host.current_screen = "skill"
		host._onboarding_runtime().onboarding_fight_summary_revealed = false
		host._onboarding_runtime().onboarding_fight_auto_run_message_shown = false
		host._onboarding_runtime().onboarding_fight_stamina_revealed = false
		host._onboarding_runtime().onboarding_fight_action_stats_revealed = false
	else:
		host._onboarding_runtime().tutorial_step = clampi(int(data.get("tutorial_step", 0)), 0, 4)



func _restore_tutorial_gate_latch_from_save(data: Dictionary) -> void:
	host._onboarding_runtime().tutorial_gate_latch_only_until_swipe = false



func _restore_onboarding_progression_from_save(data: Dictionary) -> void:
	SaveStateNormalizers.mark_onboarding_complete(data)
	host._onboarding_runtime().onboarding_starter_action_completion_count = maxi(0, int(data.get("onboarding_starter_action_completion_count", 0)))
	host._onboarding_runtime().onboarding_first_module_center_released = bool(data.get(
		"onboarding_first_module_center_released",
		host._onboarding_runtime().onboarding_starter_action_completion_count > 0 or int((host.skills.get(host.TUTORIAL_STARTER_SKILL_ID, {}) as Dictionary).get("xp", 0)) >= host._activity_unlock_runtime().LOCKED_ACTIVITY_PREVIEW_XP_THRESHOLD
	))
	if host._onboarding_runtime().onboarding_first_module_center_released:
		host._onboarding_runtime().onboarding_first_module_center_release_pending = false
	host._onboarding_runtime().onboarding_header_reveal_after_progress = bool(data.get("onboarding_header_reveal_after_progress", false))
	host._onboarding_runtime().onboarding_swipe_tip_eligible = bool(data.get("onboarding_swipe_tip_eligible", false))
	host._onboarding_runtime().onboarding_swipe_navigation_unlocked = bool(data.get("onboarding_swipe_navigation_unlocked", false))
	host._onboarding_runtime().skill_swipe_tip_seen = bool(data.get("skill_swipe_tip_seen", false))
	host._onboarding_runtime().onboarding_explore_tip_seen = bool(data.get("onboarding_explore_tip_seen", false))
	host._onboarding_runtime().onboarding_tutorial_complete = bool(data.get("onboarding_tutorial_complete", false))
	host._onboarding_runtime().stamina_gauge_tip_seen = bool(data.get("stamina_gauge_tip_seen", false))
	host._onboarding_runtime().onboarding_fight_summary_revealed = bool(data.get("onboarding_fight_summary_revealed", false))
	var saved_auto_run_message_shown = bool(data.get("onboarding_fight_auto_run_message_shown", false))
	host._onboarding_runtime().onboarding_fight_auto_run_message_shown = saved_auto_run_message_shown
	host._onboarding_runtime().onboarding_fight_stamina_revealed = bool(data.get("onboarding_fight_stamina_revealed", false))
	host._onboarding_runtime().onboarding_fight_action_stats_revealed = bool(data.get("onboarding_fight_action_stats_revealed", false))
	_restore_tutorial_state_from_save(data)
	host._tutorial_overlay_surface().restore_onboarding_tip_flags(data)
	if host._onboarding_runtime().onboarding_starter_action_completion_count == 0 and saved_auto_run_message_shown:
		host._onboarding_runtime().onboarding_starter_action_completion_count = 1
	if (
		not host._onboarding_runtime().onboarding_header_reveal_after_progress
		and not host._onboarding_runtime().onboarding_fight_summary_revealed
		and host._onboarding_runtime().onboarding_starter_action_completion_count >= 2
	):
		host._onboarding_runtime().onboarding_header_reveal_after_progress = true
	var completion_seen = _onboarding_restored_completion_seen()
	_apply_onboarding_restored_completion_implications()
	if not completion_seen:
		if host._onboarding_runtime().onboarding_fight_action_stats_revealed:
			host._onboarding_runtime().onboarding_fight_auto_run_message_shown = true
			host._onboarding_runtime().onboarding_fight_stamina_revealed = true
		elif host._onboarding_runtime().onboarding_fight_stamina_revealed:
			host._onboarding_runtime().onboarding_fight_auto_run_message_shown = true
	if not (host._onboarding_runtime().onboarding_tutorial_complete or host._onboarding_runtime().skill_swipe_tip_seen):
		if host._onboarding_runtime().onboarding_swipe_navigation_unlocked:
			host._onboarding_runtime().onboarding_swipe_tip_eligible = true
		elif (
			host._onboarding_runtime().stamina_gauge_tip_seen
			and host._onboarding_runtime().onboarding_fight_action_stats_revealed
			and host._onboarding_runtime()._onboarding_fight_stamina_depleted()
		):
			host._onboarding_runtime().onboarding_swipe_tip_eligible = true
			host._onboarding_runtime().onboarding_swipe_navigation_unlocked = true
	_restore_tutorial_gate_latch_from_save(data)



func _load_game_core(data: Dictionary) -> void:
	save_reset_generation = _save_reset_generation(data)
	save_repair_generation = SaveStateNormalizers.save_repair_generation(data)
	save_revision = maxi(0, int(data.get("save_revision", 0)))
	host.selected_skill_id = str(data.get("selected_skill_id", host.selected_skill_id))
	host.running_skill_id = str(data.get("running_skill_id", ""))
	host.running_action_id = ModuleUiRuntime.canonical_action_id(host.running_skill_id, str(data.get("running_action_id", "")), host.FISHING_ACTION_ID_ALIASES)
	host.action_progress = _normalized_action_progress(data.get("action_progress", 0.0))
	var temporary_events = host._temporary_event_runtime()
	temporary_events.event_running_skill_id = str(data.get("event_running_skill_id", ""))
	temporary_events.event_running_action_id = str(data.get("event_running_action_id", ""))
	temporary_events.event_action_progress = _normalized_action_progress(data.get("event_action_progress", 0.0))
	var loaded_skills = data.get("skills", {})
	if typeof(loaded_skills) == TYPE_DICTIONARY:
		for skill_id in loaded_skills.keys():
			if host.skills.has(skill_id) and typeof(loaded_skills[skill_id]) == TYPE_DICTIONARY:
				host.skills[skill_id]["xp"] = int(loaded_skills[skill_id].get("xp", 0))
	var has_manual_activity_unlocks = data.has("manual_activity_unlocks")
	host._activity_unlock_runtime()._restore_manual_activity_unlocks(data.get("manual_activity_unlocks", {}))
	host._activity_unlock_runtime()._restore_manual_activity_requirement_unlocks(data.get("manual_activity_requirement_unlocks", {}))
	host.built_modules = BuildableModules.restored_from_save(data.get("built_modules", {}), Callable(host, "_action_data"), Callable(host, "_action_key"))
	host._temporary_event_runtime()._restore_temporary_events_from_save(data.get("temporary_events", {}))
	var restored_running_action = host._action_data(host.running_skill_id, host.running_action_id)
	if not restored_running_action.is_empty() and BuildableModules.is_buildable(restored_running_action) and not BuildableModules.is_built(host.built_modules, host.running_skill_id, restored_running_action, Callable(host, "_action_key")):
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
	if not restored_running_action.is_empty() and host._is_event_action(restored_running_action):
		if temporary_events.event_running_skill_id.is_empty():
			temporary_events.event_running_skill_id = host.running_skill_id
			temporary_events.event_running_action_id = host.running_action_id
			temporary_events.event_action_progress = host.action_progress
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
	if not temporary_events.event_running_skill_id.is_empty():
		temporary_events.event_running_action_id = str(host._action_data(temporary_events.event_running_skill_id, temporary_events.event_running_action_id).get("id", temporary_events.event_running_action_id))
		if temporary_events.event_running_action_id.is_empty() or not host._is_event_action(host._action_data(temporary_events.event_running_skill_id, temporary_events.event_running_action_id)):
			temporary_events.event_running_skill_id = ""
			temporary_events.event_running_action_id = ""
			temporary_events.event_action_progress = 0.0
	host.thieving_state.restore_action_jails(data.get("thieving_action_jails", {}), host._unix_now(), func(skill_id: String, action_id: String) -> String: return ModuleUiRuntime.canonical_action_id(skill_id, action_id, host.FISHING_ACTION_ID_ALIASES), Callable(host, "_action_data"))
	if host.running_skill_id == "thieving" and host._thieving_surface()._thieving_action_is_jailed(host.running_action_id):
		host.running_skill_id = ""
		host.running_action_id = ""
		host.action_progress = 0.0
	host.mastery = MasteryState.restored_from_save(data.get("mastery", {}), Callable(self, "_canonical_action_key"), host.MASTERY_MAX_LEVEL)
	for skill_id in host.skills.keys():
		SkillState.recalculate_level(host, str(skill_id), false)
	if not has_manual_activity_unlocks:
		host._activity_unlock_runtime().sync_legacy_manual_activity_unlocks_from_levels()
	var loaded_stamina = data.get("stamina", {})
	if typeof(loaded_stamina) == TYPE_DICTIONARY:
		for skill_id in loaded_stamina.keys():
			if host.stamina.has(skill_id):
				host.stamina[skill_id] = clampf(float(loaded_stamina[skill_id]), 0.0, float(SkillState.max_stamina(host, str(skill_id))))
	var loaded_bank = data.get("stamina_bank", {})
	if typeof(loaded_bank) == TYPE_DICTIONARY:
		for skill_id in loaded_bank.keys():
			if host.stamina_bank.has(skill_id):
				host.stamina_bank[skill_id] = float(loaded_bank[skill_id])
				SkillState.host_sync_stamina_bank(str(skill_id), host)
	host.honey_stamina_seconds_remaining = clampf(
		float(data.get("honey_stamina_seconds_remaining", 0.0)),
		0.0,
		SkillState.HONEY_STAMINA_SECONDS_PER_CONSUMPTION
	)
	host._fighting_runtime().restore_blue_guy_health_from_save(data)
	host.material_runtime.legacy_softwood_amount = maxi(0, int(data.get("log_currency", host.material_runtime.legacy_softwood_amount)))
	host.material_runtime.restore_wallet(data)
	if _save_needs_fishing_restore(data):
		host._restore_fishing_state_from_save(data)
	host.offline_progress_enabled = bool(data.get("offline_progress_enabled", true))
	host.auto_unlock_lockpads_enabled = bool(data.get("auto_unlock_lockpads_enabled", false))
	host._navigation_shell()._restore_nav_symbol_seen_ids(data.get("nav_symbol_seen_ids", {}))
	if host.module_ui_runtime.restore_from_save(
		data,
		ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES,
		ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE,
		Callable(host._skill_detail_surface(), "_module_ui_key_allows_pin_or_collapse")
	):
		host._mark_save_dirty("module collapse migration")
	host._activity_queue_runtime()._restore_activity_queue_from_save(data)
	host._fighting_runtime().restore_completed_bosses_from_save(data.get("completed_bosses", {}))
	host.material_runtime.restore_berry_prep(data.get("berry_prep", {}), Callable(host, "_action_data"), Callable(host, "_action_key"))
	host._shop_surface().restore_rate_prompt_from_save(data)
	host.god_mode_enabled = bool(data.get("god_mode_enabled", false)) and host._test_state_runtime()._god_mode_available()
	host.god_mode_save_tainted = bool(data.get("god_mode_save_tainted", false))
	host._action_runtime().guaranteed_success_action_completions = SaveStateNormalizers.clamped_int(data, "guaranteed_success_action_completions", 0, ActionRuntime.GUARANTEED_SUCCESS_ACTION_COMPLETIONS, data.get("activity_completion_count", 0))
	host._audio_director().apply_settings_from_save(data)
	host._audio_director().music_muted = bool(data.get("music_muted", false))
	host._audio_director().sfx_muted = bool(data.get("sfx_muted", false))
	host.show_stamina_decimal = bool(data.get("show_stamina_decimal", false))
	host.offline_progress_cap_notifications_enabled = bool(data.get(
		"offline_progress_cap_notifications_enabled",
		data.get("notifications_enabled", false)
	))
	host.dark_mode_enabled = bool(data.get("dark_mode_enabled", false))
	host.last_result = str(data.get("last_result", host.last_result))
	host._audio_director()._apply_audio_bus_volumes()
	host._settings_surface().apply_dark_mode_visual()
	pending_post_load_saved_at = int(data.get("saved_at", host._unix_now()))
	last_save_unix_time = pending_post_load_saved_at
	last_save_monotonic_msec = -1
	host._passive_modules_runtime().restore_from_save(data)
	if host.selected_skill_id == "build" or host.running_skill_id == "build":
		host._convergence_runtime()._restore_convergence_modules_from_save(data)
