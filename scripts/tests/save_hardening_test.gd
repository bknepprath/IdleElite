extends SceneTree

const SaveRuntime := preload("res://scripts/save_state/save_runtime.gd")
const SaveStateNormalizers := preload("res://scripts/save_state/normalizers.gd")
const LeaderboardProfile := preload("res://scripts/leaderboard/profile.gd")
const BuildableModules := preload("res://scripts/gameplay/buildable_modules.gd")

var failures: Array[String] = []


class SaveHostStub:
	extends RefCounted
	var skill_defs: Array = []
	var save_restore_complete := false
	var FISHING_ACTION_ID_ALIASES := {
		"build:add-roof-to-something-roofless": "roof-the-roofless",
		"fishing:anchor-the-tiny-boat-dock": "anchor-tiny-boat-dock",
		"fight:duel-leaning-fence-post": "duel-fence-post",
	}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_global_save_family()
	_check_flat_v1_compatibility()
	_check_envelope_and_checksum()
	_check_code38_rollback_decoder()
	_check_verified_backup_rotation()
	_check_semantic_and_future_rejection()
	_check_quarantine_preserves_originals()
	_check_fail_closed_boot_selection()
	_check_recovery_candidate_snapshotted()
	_check_identity_regression_and_candidate_selection()
	_check_boot_grafts_identity_without_rolling_back_gameplay()
	_check_identity_transition_capability_is_scoped()
	_check_canonical_aliases_do_not_regress()
	_check_cyclic_fishing_counters_may_reset()
	_check_consumable_spend_may_decrease()
	_check_requirement_unlock_supersession()
	_check_inconsistent_identity_loads_gameplay_for_recovery()
	_check_untrusted_identity_hints_survive()
	_check_vetted_repair_capabilities_are_scoped()
	_check_journal_is_bounded_and_redacted()
	_cleanup_global_save_family()
	if failures.is_empty():
		print("save-hardening-test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _check_flat_v1_compatibility() -> void:
	var path := "user://save-hardening-flat-v1.json"
	var flat_v1 := {
		"save_schema_version": 1,
		"save_reset_generation": 17,
		"skills": {
			"fight": {"xp": 1234, "level": 9},
			"fishing": {"xp": 77, "level": 3},
		},
		"mastery": {},
		"stamina": {"fight": 10.0, "fishing": 10.0},
		"stamina_bank": {"fight": 0.0, "fishing": 0.0},
		"mats": {"softwood": 48, "iron": 12},
		"selected_skill_id": "fight",
		"leaderboard_display_name": "StablePlayer",
		"leaderboard_name_key": "stableplayer",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
		"leaderboard_player_id": "uid-stable",
		"leaderboard_auth_provider": "anonymous",
		"leaderboard_auth_refresh_token": "refresh-stable",
		"saved_at": 100,
	}
	_expect(SaveRuntime.write_text(path, JSON.stringify(flat_v1)), "Flat v1 fixture should be writable.")
	var loaded := SaveRuntime.load_dictionary(path)
	_expect(int(((loaded.get("skills", {}) as Dictionary).get("fight", {}) as Dictionary).get("xp", 0)) == 1234, "Flat v1 skill XP must load unchanged.")
	var loaded_mats := loaded.get("mats", {}) as Dictionary
	_expect(int(loaded_mats.get("softwood", 0)) == 48 and int(loaded_mats.get("iron", 0)) == 12, "Flat v1 nested material values must load unchanged.")
	_expect(str(loaded.get("leaderboard_auth_refresh_token", "")) == "refresh-stable", "Flat v1 auth metadata must load unchanged.")
	var runtime := SaveRuntime.new(null)
	var migrated := runtime.call("_migrate_save_to_current_schema", loaded) as Dictionary
	_expect(int(migrated.get("save_schema_version", 0)) == SaveRuntime.SAVE_SCHEMA_VERSION, "Flat v1 should migrate explicitly to the current schema.")
	_expect(int(migrated.get("save_revision", -1)) == 0, "Flat v1 migration should initialize revision zero.")
	_expect(str(migrated.get("leaderboard_display_name", "")) == "StablePlayer", "Migration must preserve profile values.")
	var expected_migration := loaded.duplicate(true)
	expected_migration["save_schema_version"] = SaveRuntime.SAVE_SCHEMA_VERSION
	expected_migration["save_revision"] = 0
	_expect(migrated == expected_migration, "Flat v1 migration must preserve every gameplay and identity value except the new schema metadata.")
	_expect(not loaded.has("save_revision") and int(loaded.get("save_schema_version", 0)) == 1, "Migration must not mutate the decoded v1 dictionary.")
	_remove(path)


func _check_envelope_and_checksum() -> void:
	var path := "user://save-hardening-envelope.json"
	var payload := _payload(1, 100)
	_expect(SaveRuntime.write_text(path, SaveRuntime.encoded_payload(payload)), "Envelope fixture should be writable.")
	var loaded_result := SaveRuntime.load_dictionary_result(path)
	_expect(str(loaded_result.get("error", "")).is_empty(), "A valid envelope should decode.")
	_expect(bool(loaded_result.get("enveloped", false)), "A valid envelope should report that it was unwrapped.")
	_expect(int((loaded_result.get("data", {}) as Dictionary).get("save_revision", 0)) == 1, "Envelope decoding must return the inner payload.")
	var outer_json := JSON.new()
	_expect(outer_json.parse(SaveRuntime.read_text(path)) == OK, "Envelope fixture should parse as JSON.")
	if typeof(outer_json.data) == TYPE_DICTIONARY:
		var outer := outer_json.data as Dictionary
		outer["payload_json"] = str(outer.get("payload_json", "")) + " "
		SaveRuntime.write_text(path, JSON.stringify(outer))
		_expect(str(SaveRuntime.load_dictionary_result(path).get("error", "")) == "checksum_failed", "Tampered envelope payload must fail checksum validation.")
	_remove(path)


func _check_identity_transition_capability_is_scoped() -> void:
	var runtime := SaveRuntime.new(null)
	var source_uid := "uid-source-123"
	var target_uid := "uid-target-456"
	_expect(runtime.allow_next_identity_transition_save(source_uid, target_uid), "A valid identity transition capability should be created.")
	var capability := runtime.call("_consume_next_identity_transition_save") as Dictionary
	_expect(SaveRuntime._identity_transition_capability_matches(
		{"leaderboard_player_id": source_uid, "leaderboard_auth_bound_uid": source_uid},
		{"leaderboard_player_id": target_uid, "leaderboard_auth_bound_uid": target_uid, "leaderboard_auth_provider": "google"},
		capability
	), "An identity transition capability must match its exact source and target UIDs.")
	_expect(not SaveRuntime._identity_transition_capability_matches(
		{"leaderboard_player_id": "uid-other-789"},
		{"leaderboard_player_id": target_uid, "leaderboard_auth_bound_uid": target_uid, "leaderboard_auth_provider": "google"},
		capability
	), "An identity transition capability must reject a different source UID.")
	_expect(not SaveRuntime._identity_transition_capability_matches(
		{"leaderboard_player_id": source_uid},
		{"leaderboard_player_id": "uid-other-789", "leaderboard_auth_bound_uid": "uid-other-789", "leaderboard_auth_provider": "google"},
		capability
	), "An identity transition capability must reject a different target UID.")
	_expect(not SaveRuntime._identity_transition_capability_matches(
		{"leaderboard_player_id": source_uid},
		{"leaderboard_player_id": target_uid, "leaderboard_auth_bound_uid": target_uid, "leaderboard_auth_provider": "anonymous"},
		capability
	), "An identity transition capability must reject a non-Google target binding.")
	_expect((runtime.call("_consume_next_identity_transition_save") as Dictionary).is_empty(), "An identity transition capability must be consumed after one attempt.")
	_expect(runtime.allow_next_identity_transition_save(target_uid, target_uid), "A completed same-UID recovery transition should be authorizable.")
	_expect(not runtime.allow_next_identity_transition_save("", target_uid), "An invalid identity transition request must be rejected.")
	_expect((runtime.call("_consume_next_identity_transition_save") as Dictionary).is_empty(), "Rejecting an invalid transition must clear any older capability.")


func _check_code38_rollback_decoder() -> void:
	var path := "user://save-hardening-code38-rollback.json"
	var payload := _payload(39, 7654321)
	payload["leaderboard_display_name"] = "RollbackKeeper"
	payload["leaderboard_name_key"] = "rollbackkeeper"
	payload["leaderboard_profile_claimed"] = true
	payload["leaderboard_name_claim_verified"] = true
	payload["leaderboard_player_id"] = "uid-rollback-keeper"
	payload["leaderboard_auth_provider"] = "anonymous"
	payload["leaderboard_auth_refresh_token"] = "refresh-rollback-keeper"
	payload["mastery"] = {
		"fight": {"power-strike": 14},
		"build": {"carpentry": 7},
	}
	payload["manual_activity_unlocks"] = {
		"build:roof-the-roofless": true,
		"fight:duel-fence-post": true,
	}
	payload["built_modules"] = {
		"build:roof-the-roofless": true,
	}
	_expect(SaveRuntime.write_text(path, SaveRuntime.encoded_payload(payload)), "Rollback-compatible envelope fixture should be writable.")

	# Frozen copy of production code38's decoder: it parses the complete outer
	# dictionary and knows nothing about save envelopes.
	var code38_payload := _code38_load_dictionary(path)
	_expect(str(code38_payload.get("leaderboard_display_name", "")) == "RollbackKeeper", "The pre-migration reader must see the exact username in a migrated save.")
	_expect(str(code38_payload.get("leaderboard_name_key", "")) == "rollbackkeeper", "The pre-migration reader must see the exact claimed-name key in a migrated save.")
	_expect(str(code38_payload.get("leaderboard_player_id", "")) == "uid-rollback-keeper", "The pre-migration reader must see the exact player UID in a migrated save.")
	_expect(_json_values_equal(code38_payload.get("skills", {}), payload["skills"]), "The pre-migration reader must see every skill value in a migrated save.")
	_expect(_json_values_equal(code38_payload.get("mastery", {}), payload["mastery"]), "The pre-migration reader must see every mastery value in a migrated save.")
	_expect(code38_payload.get("manual_activity_unlocks", {}) == payload["manual_activity_unlocks"], "The pre-migration reader must see every activity unlock in a migrated save.")
	_expect(code38_payload.get("built_modules", {}) == payload["built_modules"], "The pre-migration reader must see every built-module unlock in a migrated save.")

	var current_result := SaveRuntime.load_dictionary_result(path)
	_expect(str(current_result.get("error", "")).is_empty(), "The current decoder must accept the rollback-compatible envelope.")
	_expect(bool(current_result.get("enveloped", false)), "The current decoder must verify the inner envelope payload.")
	_expect(_json_values_equal(current_result.get("data", {}), payload), "The current decoder must round-trip the exact inner payload.")

	var outer_json := JSON.new()
	if outer_json.parse(SaveRuntime.read_text(path)) == OK and typeof(outer_json.data) == TYPE_DICTIONARY:
		var outer := outer_json.data as Dictionary
		outer["leaderboard_display_name"] = "UntrustedOuterCopy"
		outer["leaderboard_player_id"] = "uid-untrusted-outer"
		outer["skills"] = {"fight": {"xp": 0, "level": 1}}
		SaveRuntime.write_text(path, JSON.stringify(outer))
		var preferred_result := SaveRuntime.load_dictionary_result(path)
		_expect(_json_values_equal(preferred_result.get("data", {}), payload), "The current decoder must prefer the verified inner payload over the compatibility copy.")
	else:
		_expect(false, "The rollback-compatible envelope should remain parseable for the inner-payload preference test.")
	_remove(path)


func _code38_load_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var raw := file.get_buffer(file.get_length()).get_string_from_utf8()
	file.close()
	var save_json := JSON.new()
	if save_json.parse(raw) != OK or typeof(save_json.data) != TYPE_DICTIONARY:
		return {}
	return save_json.data as Dictionary


func _json_values_equal(left: Variant, right: Variant) -> bool:
	var left_type := typeof(left)
	var right_type := typeof(right)
	if left_type in [TYPE_INT, TYPE_FLOAT] and right_type in [TYPE_INT, TYPE_FLOAT]:
		# Godot's JSON decoder represents JSON numbers as floats. Integer and float
		# Variants with the same JSON value are therefore equivalent on disk.
		return float(left) == float(right)
	if left_type != right_type:
		return false
	if left_type == TYPE_DICTIONARY:
		var left_dictionary := left as Dictionary
		var right_dictionary := right as Dictionary
		if left_dictionary.size() != right_dictionary.size():
			return false
		for key in left_dictionary.keys():
			if not right_dictionary.has(key) or not _json_values_equal(left_dictionary.get(key), right_dictionary.get(key)):
				return false
		return true
	if left_type == TYPE_ARRAY:
		var left_array := left as Array
		var right_array := right as Array
		if left_array.size() != right_array.size():
			return false
		for index in range(left_array.size()):
			if not _json_values_equal(left_array[index], right_array[index]):
				return false
		return true
	return left == right


func _check_verified_backup_rotation() -> void:
	var primary := "user://save-hardening-rotation.json"
	var temp := "user://save-hardening-rotation.tmp.json"
	var backup_1 := "user://save-hardening-rotation.backup.json"
	var backup_2 := "user://save-hardening-rotation.backup-2.json"
	var backup_3 := "user://save-hardening-rotation.backup-3.json"
	var paths := [primary, temp, backup_1, backup_2, backup_3]
	for path in paths:
		_remove(path)
	for revision in range(1, 5):
		_expect(
			SaveRuntime.write_payload_atomically(_payload(revision, revision * 100), primary, temp, backup_1, backup_2, backup_3),
			"Atomic write %s should succeed." % revision
		)
	_expect(_revision_at(primary) == 4, "Primary should contain the fourth revision.")
	_expect(_revision_at(backup_1) == 3, "First backup should contain the third revision.")
	_expect(_revision_at(backup_2) == 2, "Second backup should contain the second revision.")
	_expect(_revision_at(backup_3) == 1, "Third backup should contain the first revision.")
	for path in [primary, backup_1, backup_2, backup_3]:
		_expect(str(SaveRuntime.load_dictionary_result(path).get("error", "")).is_empty(), "%s must be a verified save." % path)
	for path in paths:
		_remove(path)


func _check_semantic_and_future_rejection() -> void:
	var incomplete_path := "user://save-hardening-incomplete.json"
	var partial_path := "user://save-hardening-partial-v1.json"
	var partial_current_path := "user://save-hardening-partial-current.json"
	var future_path := "user://save-hardening-future.json"
	SaveRuntime.write_text(incomplete_path, JSON.stringify({"save_schema_version": 1, "skills": {}}))
	SaveRuntime.write_text(partial_path, JSON.stringify({
		"save_schema_version": 1,
		"skills": {"fight": {"xp": 1, "level": 1}},
	}))
	SaveRuntime.write_text(partial_current_path, SaveRuntime.encoded_payload({
		"save_schema_version": SaveRuntime.SAVE_SCHEMA_VERSION,
		"skills": {"fight": {"xp": 1, "level": 1}},
	}))
	SaveRuntime.write_text(future_path, JSON.stringify({
		"save_schema_version": SaveRuntime.SAVE_SCHEMA_VERSION + 1,
		"skills": {"fight": {"xp": 1, "level": 1}},
	}))
	_expect(str(SaveRuntime.load_dictionary_result(incomplete_path).get("error", "")) == "empty_skills", "A semantically incomplete v1 save must be rejected.")
	_expect(str(SaveRuntime.load_dictionary_result(partial_path).get("error", "")) == "missing_mastery", "A one-field v1 fragment must not be default-filled into a valid current save.")
	_expect(str(SaveRuntime.load_dictionary_result(partial_current_path).get("error", "")) == "missing_mastery", "A checksummed current-schema fragment must not be default-filled into a valid save.")
	_expect(str(SaveRuntime.load_dictionary_result(future_path).get("error", "")) == "future_schema", "A future-schema save must be rejected.")
	_remove(incomplete_path)
	_remove(partial_path)
	_remove(partial_current_path)
	_remove(future_path)


func _check_quarantine_preserves_originals() -> void:
	var corrupt_path := "user://save-hardening-corrupt.json"
	var corrupt_raw := "{not-json"
	SaveRuntime.write_text(corrupt_path, corrupt_raw)
	_expect(SaveRuntime.quarantine_invalid_save(corrupt_path), "Invalid JSON should be quarantined.")
	var quarantine_path := corrupt_path.trim_suffix(".json") + ".corrupt-%s.json" % corrupt_raw.sha256_text().left(16)
	_expect(FileAccess.file_exists(corrupt_path) and SaveRuntime.read_text(corrupt_path) == corrupt_raw, "Quarantine must preserve the invalid original.")
	_expect(FileAccess.file_exists(quarantine_path) and SaveRuntime.read_text(quarantine_path) == corrupt_raw, "Quarantine must preserve exact invalid bytes.")
	_remove(corrupt_path)
	_remove(quarantine_path)

	var empty_path := "user://save-hardening-empty.json"
	SaveRuntime.write_text(empty_path, "")
	_expect(SaveRuntime.quarantine_invalid_save(empty_path), "A zero-byte save should be quarantined.")
	var empty_quarantine := empty_path.trim_suffix(".json") + ".corrupt-%s.json" % "".sha256_text().left(16)
	_expect(FileAccess.file_exists(empty_path), "Zero-byte quarantine must preserve the original.")
	_expect(FileAccess.file_exists(empty_quarantine) and FileAccess.get_file_as_bytes(empty_quarantine).is_empty(), "Zero-byte quarantine must create a verified zero-byte copy.")
	_remove(empty_path)
	_remove(empty_quarantine)


func _check_fail_closed_boot_selection() -> void:
	_cleanup_global_save_family()
	SaveRuntime.write_text(SaveRuntime.SAVE_PATH, "{broken")
	var runtime := SaveRuntime.new(SaveHostStub.new())
	var boot_result := runtime.call("_boot_save_dictionary") as Dictionary
	_expect(not str(boot_result.get("error", "")).is_empty(), "Existing unreadable save files must return a recovery error.")
	_expect((boot_result.get("data", {}) as Dictionary).is_empty(), "Unreadable save files must not become a blank valid payload.")
	_expect(FileAccess.file_exists(SaveRuntime.SAVE_PATH), "Fail-closed selection must preserve the unreadable primary.")
	runtime.save_writes_blocked = true
	_expect(runtime.boot_recovery_blocks_reveal(), "Incomplete recovery must keep the normal game UI covered.")
	_expect(runtime.boot_recovery_status_text().contains("save files are preserved"), "The recovery state must tell players their files were preserved.")
	_expect(runtime.boot_recovery_status_text().contains("Do not reinstall or clear app data") and runtime.boot_recovery_status_text().contains("Contact support"), "The blocked recovery screen must give actionable data-preservation instructions.")
	runtime.save_writes_blocked = false
	runtime.pending_save_restore_data = _payload(1, 100)
	_expect(not runtime.boot_storage_failure_blocks_restore(), "A valid pending payload must be allowed to enter its secondary restore under the splash.")
	_expect(runtime.boot_recovery_blocks_reveal(), "A still-pending secondary restore must keep the normal UI covered until completion.")
	runtime.pending_save_restore_data = {}
	runtime.host.save_restore_complete = true
	_expect(not runtime.boot_recovery_blocks_reveal(), "A completed restore may reveal normal play.")
	_cleanup_global_save_family()


func _check_recovery_candidate_snapshotted() -> void:
	_cleanup_global_save_family()
	SaveRuntime.write_text(SaveRuntime.SAVE_TEMP_PATH, SaveRuntime.encoded_payload(_payload(9, 900)))
	var runtime := SaveRuntime.new(SaveHostStub.new())
	var boot_result := runtime.call("_boot_save_dictionary") as Dictionary
	_expect(bool(boot_result.get("recovered", false)), "A valid interrupted-write temp should be selected for recovery.")
	_expect(_revision_at(SaveRuntime.SAVE_RECOVERY_SNAPSHOT_PATH) == 9, "The selected temp candidate must be snapshotted before any later write can reuse the temp path.")
	_cleanup_global_save_family()


func _check_identity_regression_and_candidate_selection() -> void:
	var established := _payload(5, 100)
	established.merge({
		"leaderboard_display_name": "StablePlayer",
		"leaderboard_name_key": "stableplayer",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
		"leaderboard_player_id": "uid-stable",
		"leaderboard_auth_provider": "google",
		"leaderboard_auth_refresh_token": "refresh-stable",
		"leaderboard_auth_bound_uid": "uid-stable",
		"leaderboard_auth_recovery_required": false,
	}, true)
	var wiped := established.duplicate(true)
	wiped["save_revision"] = 6
	wiped["skills"] = {"fight": {"xp": 1000, "level": 10}}
	wiped["leaderboard_display_name"] = "Guest 1234"
	wiped["leaderboard_name_key"] = ""
	wiped["leaderboard_profile_claimed"] = false
	wiped["leaderboard_name_claim_verified"] = false
	wiped["leaderboard_auth_refresh_token"] = ""
	wiped["leaderboard_auth_bound_uid"] = ""
	_expect(SaveStateNormalizers.payload_regresses_identity(established, wiped), "Dropping a claimed authenticated identity must be a regression.")
	_expect(not SaveRuntime.should_replace_best_save(established, wiped, [{"id": "fight"}]), "A newer higher-XP candidate must not replace an established identity with a guest profile.")
	var changed_uid := established.duplicate(true)
	changed_uid["save_revision"] = 7
	changed_uid["leaderboard_player_id"] = "uid-replacement"
	changed_uid["leaderboard_auth_bound_uid"] = "uid-replacement"
	_expect(SaveStateNormalizers.payload_regresses_identity(established, changed_uid), "Changing an established bound UID must be a regression.")
	_expect(not SaveRuntime.should_replace_best_save(established, changed_uid, [{"id": "fight"}]), "Recency must not cross an established account boundary.")
	var downgraded_provider := established.duplicate(true)
	downgraded_provider["leaderboard_auth_provider"] = "anonymous"
	_expect(SaveStateNormalizers.payload_regresses_identity(established, downgraded_provider), "A Google identity must not silently downgrade to anonymous auth.")
	var renamed := established.duplicate(true)
	renamed["leaderboard_display_name"] = "DifferentPlayer"
	renamed["leaderboard_name_key"] = "differentplayer"
	_expect(SaveStateNormalizers.payload_regresses_identity(established, renamed), "A claimed profile's exact display name and reservation key must not change in a routine save.")
	renamed["save_repair_generation"] = 999
	_expect(not SaveRuntime.should_replace_best_save(established, renamed, [{"id": "fight"}]), "Repair generation must not authorize a claimed profile rename.")
	var incomplete_claim := established.duplicate(true)
	incomplete_claim["save_revision"] = 8
	incomplete_claim["skills"] = {"fight": {"xp": 1000, "level": 10}}
	incomplete_claim["leaderboard_display_name"] = ""
	incomplete_claim["leaderboard_name_key"] = ""
	_expect(SaveStateNormalizers.payload_has_recoverable_identity_inconsistency(incomplete_claim), "A claimed profile with missing name fields must be recognized as incomplete.")
	_expect(not SaveRuntime.should_replace_best_save(incomplete_claim, established, [{"id": "fight"}]), "An older identity backup must not replace a newer incomplete primary's gameplay payload.")
	var recovered_claim := SaveRuntime.payload_with_recovered_claimed_identity(incomplete_claim, established)
	_expect(str(recovered_claim.get("leaderboard_display_name", "")) == "StablePlayer" and str(recovered_claim.get("leaderboard_name_key", "")) == "stableplayer", "A complete same-UID backup must restore the verified claimed name fields.")
	_expect(int(((recovered_claim.get("skills", {}) as Dictionary).get("fight", {}) as Dictionary).get("xp", 0)) == 1000 and int(recovered_claim.get("save_revision", 0)) == 8, "Identity recovery must preserve the newer primary's gameplay and revision.")
	_expect(str(recovered_claim.get("leaderboard_auth_refresh_token", "")) == "refresh-stable" and str(recovered_claim.get("leaderboard_auth_provider", "")) == "google", "Identity recovery must retain the selected primary's auth credentials and provider.")
	_expect(bool(recovered_claim.get("leaderboard_auth_recovery_required", false)), "A recovered local claim must be verified against the canonical server record before online writes resume.")
	var flat_v1_claim := established.duplicate(true)
	flat_v1_claim["save_schema_version"] = 1
	flat_v1_claim.erase("save_repair_generation")
	flat_v1_claim.erase("save_revision")
	flat_v1_claim.erase("leaderboard_auth_bound_uid")
	flat_v1_claim.erase("leaderboard_auth_recovery_required")
	flat_v1_claim["leaderboard_auth_provider"] = "anonymous"
	flat_v1_claim["leaderboard_auth_refresh_token"] = "refresh-stale-v1"
	_expect(not SaveRuntime.should_replace_best_save(incomplete_claim, flat_v1_claim, [{"id": "fight"}]), "A flat v1 identity backup must not replace the newer gameplay payload.")
	var flat_v1_recovered_claim := SaveRuntime.payload_with_recovered_claimed_identity(incomplete_claim, flat_v1_claim)
	_expect(str(flat_v1_recovered_claim.get("leaderboard_display_name", "")) == "StablePlayer" and int(((flat_v1_recovered_claim.get("skills", {}) as Dictionary).get("fight", {}) as Dictionary).get("xp", 0)) == 1000, "A complete same-UID flat v1 backup must restore only identity even though it predates the explicit bound UID.")
	_expect(str(flat_v1_recovered_claim.get("leaderboard_auth_refresh_token", "")) == "refresh-stable" and str(flat_v1_recovered_claim.get("leaderboard_auth_provider", "")) == "google", "A stale flat-v1 backup credential/provider must not replace the selected primary's current auth state.")
	var guest_named_incomplete_claim := incomplete_claim.duplicate(true)
	guest_named_incomplete_claim["leaderboard_display_name"] = "guest1234"
	var guest_recovered_claim := SaveRuntime.payload_with_recovered_claimed_identity(guest_named_incomplete_claim, established)
	_expect(str(guest_recovered_claim.get("leaderboard_display_name", "")) == "StablePlayer", "A generated guest display value must not block a complete same-UID claimed backup from restoring the real username.")
	_expect(not SaveRuntime.should_replace_best_save(established, incomplete_claim, [{"id": "fight"}]), "An incomplete claimed candidate must never replace a complete same-UID identity.")
	_expect(SaveRuntime.payload_with_recovered_claimed_identity(established, incomplete_claim) == established, "An incomplete candidate must not modify a complete primary identity.")
	var trust_mismatch_primary := established.duplicate(true)
	trust_mismatch_primary["save_revision"] = 10
	trust_mismatch_primary["saved_at"] = 10
	trust_mismatch_primary["skills"] = {"fight": {"xp": 2000, "level": 12}}
	trust_mismatch_primary["leaderboard_name_claim_verified"] = false
	_expect(SaveStateNormalizers.payload_has_recoverable_identity_inconsistency(trust_mismatch_primary), "A one-sided claimed/verified mismatch must be recognized as recoverable.")
	_expect(not SaveRuntime.should_replace_best_save(trust_mismatch_primary, established, [{"id": "fight"}]), "An older complete identity backup must not replace newer gameplay when only one trust flag is damaged.")
	var repaired_trust_mismatch := SaveRuntime.payload_with_recovered_claimed_identity(trust_mismatch_primary, established)
	_expect(bool(repaired_trust_mismatch.get("leaderboard_name_claim_verified", false)), "The same-UID backup must repair the missing trust flag.")
	_expect(int(((repaired_trust_mismatch.get("skills", {}) as Dictionary).get("fight", {}) as Dictionary).get("xp", 0)) == 2000 and int(repaired_trust_mismatch.get("save_revision", 0)) == 10, "Trust-flag recovery must retain the newer primary's gameplay and revision.")
	var higher_generation_credential_wipe := established.duplicate(true)
	higher_generation_credential_wipe["save_revision"] = 9
	higher_generation_credential_wipe["save_repair_generation"] = 999
	higher_generation_credential_wipe["leaderboard_auth_provider"] = "anonymous"
	higher_generation_credential_wipe["leaderboard_auth_refresh_token"] = ""
	_expect(not SaveRuntime.should_replace_best_save(established, higher_generation_credential_wipe, [{"id": "fight"}]), "Repair generation must not outrank a same-UID save when it loses Google credentials.")
	var fresh_placeholder := _payload(1, 0)
	fresh_placeholder.merge({
		"leaderboard_player_id": "paaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		"leaderboard_auth_provider": "anonymous",
		"leaderboard_auth_refresh_token": "",
		"leaderboard_auth_bound_uid": "",
		"leaderboard_profile_claimed": false,
	}, true)
	var first_signup := fresh_placeholder.duplicate(true)
	first_signup["leaderboard_player_id"] = "firebase-first-uid"
	first_signup["leaderboard_auth_refresh_token"] = "first-refresh-token"
	first_signup["leaderboard_auth_bound_uid"] = "firebase-first-uid"
	_expect(not SaveStateNormalizers.payload_regresses_identity(fresh_placeholder, first_signup), "The first anonymous signup may bind a local placeholder to its first Firebase UID.")


func _check_boot_grafts_identity_without_rolling_back_gameplay() -> void:
	_cleanup_global_save_family()
	var complete_backup := _payload(7, 100)
	complete_backup.merge({
		"leaderboard_display_name": "StablePlayer",
		"leaderboard_name_key": "stableplayer",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
		"leaderboard_player_id": "uid-stable",
		"leaderboard_auth_provider": "google",
		"leaderboard_auth_refresh_token": "refresh-stable",
		"leaderboard_auth_bound_uid": "uid-stable",
		"leaderboard_auth_recovery_required": false,
	}, true)
	var flat_v1_backup := complete_backup.duplicate(true)
	flat_v1_backup["save_schema_version"] = 1
	flat_v1_backup.erase("save_repair_generation")
	flat_v1_backup.erase("save_revision")
	flat_v1_backup.erase("leaderboard_auth_bound_uid")
	flat_v1_backup.erase("leaderboard_auth_recovery_required")
	flat_v1_backup["leaderboard_auth_provider"] = "anonymous"
	flat_v1_backup["leaderboard_auth_refresh_token"] = "refresh-stale-v1"
	var incomplete_primary := complete_backup.duplicate(true)
	incomplete_primary["save_revision"] = 8
	incomplete_primary["saved_at"] = 8
	incomplete_primary["skills"] = {"fight": {"xp": 1000, "level": 10}}
	incomplete_primary["leaderboard_display_name"] = ""
	incomplete_primary["leaderboard_name_key"] = ""
	_expect(SaveRuntime.write_text(SaveRuntime.SAVE_PATH, SaveRuntime.encoded_payload(incomplete_primary)), "Incomplete primary identity fixture should be writable.")
	_expect(SaveRuntime.write_text(SaveRuntime.SAVE_BACKUP_PATH, JSON.stringify(flat_v1_backup)), "Complete flat-v1 backup identity fixture should be writable.")
	var host := SaveHostStub.new()
	host.skill_defs = [{"id": "fight"}]
	var runtime := SaveRuntime.new(host)
	var boot_result := runtime.call("_boot_save_dictionary") as Dictionary
	var boot_payload := boot_result.get("data", {}) as Dictionary
	_expect(bool(boot_result.get("recovered", false)), "Boot must mark a same-UID identity graft for persistence after the full restore.")
	_expect(str(boot_payload.get("leaderboard_display_name", "")) == "StablePlayer" and str(boot_payload.get("leaderboard_name_key", "")) == "stableplayer", "Boot must recover the verified username from the complete same-UID backup.")
	_expect(int(((boot_payload.get("skills", {}) as Dictionary).get("fight", {}) as Dictionary).get("xp", 0)) == 1000 and int(boot_payload.get("save_revision", 0)) == 8, "Boot identity recovery must preserve the primary's newer gameplay and revision.")
	_expect(str(boot_payload.get("leaderboard_auth_refresh_token", "")) == "refresh-stable" and str(boot_payload.get("leaderboard_auth_provider", "")) == "google", "Boot identity recovery must not replace auth credentials from the selected primary.")
	_expect(bool(boot_payload.get("leaderboard_auth_recovery_required", false)), "Boot identity recovery must require canonical server verification before online writes.")
	_expect(not (boot_result.get("identity_repair_source", {}) as Dictionary).is_empty() and not (boot_result.get("identity_repair_payload", {}) as Dictionary).is_empty(), "Boot must retain exact one-shot identity repair anchors for the post-restore save.")
	var identity_repair_source := boot_result.get("identity_repair_source", {}) as Dictionary
	var identity_repair_payload := boot_result.get("identity_repair_payload", {}) as Dictionary
	runtime.call("_allow_next_vetted_identity_repair_save", identity_repair_source, identity_repair_payload, true)
	var next_save := boot_payload.duplicate(true)
	next_save["save_revision"] = 9
	next_save["saved_at"] = 9
	_expect(runtime.call("_save_payload_can_replace_existing_save", next_save), "The exact identity-only graft must be writable after full restore.")
	var unexpected_name := next_save.duplicate(true)
	unexpected_name["leaderboard_display_name"] = "DifferentPlayer"
	unexpected_name["leaderboard_name_key"] = "differentplayer"
	_expect(not runtime.call("_save_payload_can_replace_existing_save", unexpected_name), "The one-shot identity repair capability must not authorize any name other than the vetted backup claim.")
	_cleanup_global_save_family()


func _check_canonical_aliases_do_not_regress() -> void:
	var aliases := {
		"build:add-roof-to-something-roofless": "roof-the-roofless",
		"fishing:anchor-the-tiny-boat-dock": "anchor-tiny-boat-dock",
		"fight:duel-leaning-fence-post": "duel-fence-post",
	}
	var legacy := _payload(4, 500)
	legacy["mastery"] = {"fishing:anchor-the-tiny-boat-dock": {"xp": 80, "level": 2}}
	legacy["manual_activity_unlocks"] = {"build:add-roof-to-something-roofless": true}
	legacy["manual_activity_requirement_unlocks"] = {"build:add-roof-to-something-roofless:build:4": true}
	legacy["built_modules"] = {"fight:duel-leaning-fence-post": true}
	var canonical := legacy.duplicate(true)
	canonical["save_revision"] = 5
	canonical["mastery"] = {"fishing:anchor-tiny-boat-dock": {"xp": 80, "level": 2}}
	canonical["manual_activity_unlocks"] = {"build:roof-the-roofless": true}
	canonical["manual_activity_requirement_unlocks"] = {"build:roof-the-roofless:build:4": true}
	canonical["built_modules"] = {"fight:duel-fence-post": true}
	var legacy_comparison := SaveStateNormalizers.payload_with_canonical_action_keys(legacy, aliases)
	var canonical_comparison := SaveStateNormalizers.payload_with_canonical_action_keys(canonical, aliases)
	_expect(not SaveStateNormalizers.payload_regresses_game_progress(legacy_comparison, canonical_comparison, [{"id": "fight"}]), "Canonicalizing historical action IDs must not look like lost mastery, unlocks, or buildables.")
	_expect(SaveRuntime.should_replace_best_save(legacy, canonical, [{"id": "fight"}], aliases), "A canonicalized newer save should outrank its alias-keyed v1 source.")
	var action_lookup := func(_skill_id: String, action_id: String) -> Dictionary:
		if action_id in ["duel-leaning-fence-post", "duel-fence-post"]:
			return {"id": "duel-fence-post", "build": {"cost": {"softwood": 1}}}
		return {}
	var action_key := func(skill_id: String, action_id: String) -> String: return "%s:%s" % [skill_id, action_id]
	var restored_buildables := BuildableModules.restored_from_save(legacy.get("built_modules", {}), action_lookup, action_key)
	_expect(bool(restored_buildables.get("fight:duel-fence-post", false)), "Buildable restore must move a historical alias onto the canonical module key.")
	_expect(not restored_buildables.has("fight:duel-leaning-fence-post"), "Buildable restore must not leave the inaccessible historical key behind.")


func _check_cyclic_fishing_counters_may_reset() -> void:
	var before_haul := _payload(4, 500)
	before_haul["fishing_net_successes"] = 8
	before_haul["fishing_boat_successes"] = 3
	var after_haul := before_haul.duplicate(true)
	after_haul["save_revision"] = 5
	after_haul["fishing_net_successes"] = 0
	after_haul["fishing_boat_successes"] = 0
	_expect(not SaveStateNormalizers.payload_regresses_game_progress(before_haul, after_haul, [{"id": "fight"}]), "Fishing batch counters must be allowed to reset after a haul or tool switch.")


func _check_consumable_spend_may_decrease() -> void:
	var before_spend := _payload(4, 500)
	before_spend["log_currency"] = 20.0
	before_spend["fish_currency"] = 8.0
	var after_spend := before_spend.duplicate(true)
	after_spend["save_revision"] = 5
	after_spend["log_currency"] = 0.0
	after_spend["fish_currency"] = 0.0
	_expect(not SaveStateNormalizers.payload_regresses_game_progress(before_spend, after_spend, [{"id": "fight"}]), "Legitimate consumable spending must not be mistaken for save corruption.")


func _check_requirement_unlock_supersession() -> void:
	var partial := _payload(6, 500)
	partial["manual_activity_requirement_unlocks"] = {
		"fight:dragon:build:20": true,
		"fight:dragon:fishing:30": true,
	}
	var complete := partial.duplicate(true)
	complete["save_revision"] = 7
	complete["manual_activity_requirement_unlocks"] = {}
	complete["manual_activity_unlocks"] = {"fight:dragon": true}
	_expect(not SaveStateNormalizers.payload_regresses_game_progress(partial, complete, [{"id": "fight"}]), "A full activity unlock must supersede and clear its requirement unlock keys.")
	var lost_partial := partial.duplicate(true)
	lost_partial["manual_activity_requirement_unlocks"] = {}
	_expect(SaveStateNormalizers.payload_regresses_game_progress(partial, lost_partial, [{"id": "fight"}]), "Partial requirement unlocks must remain protected when no full unlock supersedes them.")


func _check_inconsistent_identity_loads_gameplay_for_recovery() -> void:
	var inconsistent := _payload(0, 4321)
	inconsistent["save_schema_version"] = 1
	inconsistent["leaderboard_display_name"] = "DamagedPlayer"
	inconsistent["leaderboard_name_key"] = "damagedplayer"
	inconsistent["leaderboard_profile_claimed"] = true
	inconsistent["leaderboard_name_claim_verified"] = true
	inconsistent["leaderboard_player_id"] = ""
	var path := "user://save-hardening-inconsistent-identity.json"
	_expect(SaveRuntime.write_text(path, JSON.stringify(inconsistent)), "Inconsistent identity fixture should be writable.")
	var load_result := SaveRuntime.load_dictionary_result(path)
	_expect(str(load_result.get("error", "")).is_empty(), "Identity damage must not make intact gameplay unreadable.")
	var runtime := SaveRuntime.new(null)
	var migrated := runtime.call("_migrate_save_to_current_schema", load_result.get("data", {}) as Dictionary) as Dictionary
	_expect(int((((migrated.get("skills", {}) as Dictionary).get("fight", {}) as Dictionary).get("xp", 0))) == 4321, "Identity recovery migration must preserve gameplay XP.")
	_expect(bool(migrated.get("leaderboard_auth_recovery_required", false)), "Inconsistent saved identity must enter recovery instead of blank initialization.")
	var restored_metadata := LeaderboardProfile.restored_metadata({
		"leaderboard_display_name": "DamagedPlayer",
		"leaderboard_name_key": "damagedplayer",
		"leaderboard_profile_claimed": false,
		"leaderboard_name_claim_verified": true,
		"leaderboard_player_id": "uid-stable",
	}, "guest0000", "", 0, "paaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "guest", 16, 16, 20)
	_expect(not bool(restored_metadata.get("profile_claimed", true)) and not bool(restored_metadata.get("name_claim_verified", true)), "Profile restore must normalize verified-without-claimed metadata into an untrusted recovery state.")
	_expect(str(restored_metadata.get("name_key", "")) == "damagedplayer", "An untrusted but matching saved name key must remain available as a recovery hint.")
	_remove(path)


func _check_untrusted_identity_hints_survive() -> void:
	var hinted := _payload(2, 321)
	hinted.merge({
		"leaderboard_display_name": "RememberMe",
		"leaderboard_name_key": "rememberme",
		"leaderboard_profile_claimed": false,
		"leaderboard_name_claim_verified": false,
		"leaderboard_player_id": "uid-remember-me",
		"leaderboard_auth_refresh_token": "refresh-remember-me",
	}, true)
	_expect(SaveStateNormalizers.payload_has_recoverable_identity_inconsistency(hinted), "A lost-trust name/key pair must enter account recovery rather than becoming a guest.")
	var runtime := SaveRuntime.new(null)
	var migrated := runtime.call("_migrate_save_to_current_schema", hinted) as Dictionary
	_expect(bool(migrated.get("leaderboard_auth_recovery_required", false)), "Migration must persist a recovery flag for untrusted name/key hints.")
	var restored := LeaderboardProfile.restored_metadata(hinted, "guest0000", "", 0, "paaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", "guest", 16, 16, 20)
	_expect(str(restored.get("display_name", "")) == "RememberMe" and str(restored.get("name_key", "")) == "rememberme", "Profile restore must retain matching untrusted name/key hints exactly.")
	_expect(not bool(restored.get("profile_claimed", true)) and not bool(restored.get("name_claim_verified", true)), "Retained hints must not regain claim authority before recovery.")
	var saved := LeaderboardProfile.metadata_for_save("RememberMe", "rememberme", false, false, "guest", 16, 16)
	_expect(str(saved.get("name_key", "")) == "rememberme", "A subsequent save must not wipe an untrusted recovery name key.")


func _check_vetted_repair_capabilities_are_scoped() -> void:
	_cleanup_global_save_family()
	var established := _payload(10, 900)
	established.merge({
		"save_reset_generation": 3,
		"save_repair_generation": 4,
		"leaderboard_display_name": "StablePlayer",
		"leaderboard_name_key": "stableplayer",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
		"leaderboard_player_id": "uid-stable",
		"leaderboard_auth_provider": "google",
		"leaderboard_auth_refresh_token": "refresh-stable",
		"leaderboard_auth_bound_uid": "uid-stable",
		"leaderboard_auth_recovery_required": false,
		"thieving_trophies": {"vault": {"stolen": true}},
		"completed_bosses": {"dragon": true},
	}, true)
	_expect(SaveRuntime.write_payload_atomically(established, SaveRuntime.SAVE_PATH, SaveRuntime.SAVE_TEMP_PATH, SaveRuntime.SAVE_BACKUP_PATH, SaveRuntime.SAVE_BACKUP_2_PATH, SaveRuntime.SAVE_BACKUP_3_PATH), "Repair guard fixture should be writable.")
	var persisted_established := SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	var runtime := SaveRuntime.new(SaveHostStub.new())
	runtime.host.skill_defs = [{"id": "fight"}]
	var repaired := persisted_established.duplicate(true)
	repaired["save_revision"] = 11
	repaired["thieving_trophies"] = {"vault": {"stolen": false}}
	var stale_generation := persisted_established.duplicate(true)
	stale_generation["save_reset_generation"] = 2
	_expect(not runtime.call("_save_payload_can_replace_existing_save", stale_generation), "A save from an older reset generation must never replace the current generation.")
	var stale_repair_generation := persisted_established.duplicate(true)
	stale_repair_generation["save_repair_generation"] = 3
	_expect(not runtime.call("_save_payload_can_replace_existing_save", stale_repair_generation), "A save from before an accepted repair must never replace the repaired generation.")
	_expect(not runtime.call("_save_payload_can_replace_existing_save", repaired), "A progress-reducing repair must require its one-shot capability.")
	runtime.call("_allow_next_vetted_progress_repair_save", persisted_established, repaired)
	_expect(runtime.call("_save_payload_can_replace_existing_save", repaired), "The exact vetted progress repair should be saveable.")
	var unrelated_loss := repaired.duplicate(true)
	unrelated_loss["completed_bosses"] = {}
	_expect(not runtime.call("_save_payload_can_replace_existing_save", unrelated_loss), "A vetted repair must not authorize unrelated progress loss.")
	var authoritative_repair := repaired.duplicate(true)
	authoritative_repair["save_repair_generation"] = 5
	_expect(not SaveRuntime.should_replace_best_save(authoritative_repair, persisted_established, [{"id": "fight"}]), "A pre-repair backup must not undo a completed vetted repair on the next boot.")
	_expect(SaveRuntime.should_replace_best_save(persisted_established, authoritative_repair, [{"id": "fight"}]), "The newer vetted repair generation must outrank its pre-repair source even when corruption looked like more progress.")
	var unbound_source := _payload(30, 900)
	var unbound_repair := _payload(31, 100)
	unbound_repair["save_repair_generation"] = 99
	_expect(not SaveRuntime.should_replace_best_save(unbound_source, unbound_repair, [{"id": "fight"}]), "Repair generation must not outrank stronger progress without a shared stable account UID.")
	_cleanup_global_save_family()

	var inconsistent := established.duplicate(true)
	inconsistent["save_revision"] = 20
	inconsistent["leaderboard_profile_claimed"] = false
	inconsistent["leaderboard_name_claim_verified"] = true
	_expect(SaveRuntime.write_payload_atomically(inconsistent, SaveRuntime.SAVE_PATH, SaveRuntime.SAVE_TEMP_PATH, SaveRuntime.SAVE_BACKUP_PATH, SaveRuntime.SAVE_BACKUP_2_PATH, SaveRuntime.SAVE_BACKUP_3_PATH), "Identity repair fixture should be writable.")
	var persisted_inconsistent := SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	var identity_runtime := SaveRuntime.new(SaveHostStub.new())
	identity_runtime.host.skill_defs = [{"id": "fight"}]
	var identity_repaired := persisted_inconsistent.duplicate(true)
	identity_repaired["save_revision"] = 21
	identity_repaired["save_repair_generation"] = int(persisted_inconsistent.get("save_repair_generation", 0)) + 1
	identity_repaired["leaderboard_name_claim_verified"] = false
	identity_repaired["leaderboard_auth_recovery_required"] = true
	identity_repaired["leaderboard_auth_recovery_reason"] = "Saved online identity needs recovery."
	_expect(not identity_runtime.call("_save_payload_can_replace_existing_save", identity_repaired), "Identity normalization must require its one-shot capability.")
	# Production records the repair capability before profile restore normalizes the
	# inconsistent trust flags. The expected pre-restore payload therefore still
	# contains the damaged flags while the eventual save contains the safe result.
	identity_runtime.call("_allow_next_vetted_identity_repair_save", persisted_inconsistent, persisted_inconsistent)
	_expect(identity_runtime.call("_save_payload_can_replace_existing_save", identity_repaired), "A vetted post-restore identity normalization should preserve gameplay and stable account anchors even when its pre-restore expectation still has damaged trust flags.")
	_expect(SaveRuntime.should_replace_best_save(persisted_inconsistent, identity_repaired, [{"id": "fight"}]), "A newer vetted identity normalization must outrank its inconsistent same-UID source during recovery selection.")
	_expect(not SaveRuntime.should_replace_best_save(identity_repaired, persisted_inconsistent, [{"id": "fight"}]), "A stale inconsistent backup must not replace its persisted same-UID identity normalization on the next boot.")
	var unsafe_identity_repair := identity_repaired.duplicate(true)
	unsafe_identity_repair["leaderboard_player_id"] = "uid-replacement"
	unsafe_identity_repair["leaderboard_auth_bound_uid"] = "uid-replacement"
	_expect(not identity_runtime.call("_save_payload_can_replace_existing_save", unsafe_identity_repair), "Identity repair must not authorize changing the established account UID.")
	_cleanup_global_save_family()


func _check_journal_is_bounded_and_redacted() -> void:
	_remove(SaveRuntime.SAVE_JOURNAL_PATH)
	_remove(SaveRuntime.SAVE_JOURNAL_TEMP_PATH)
	for index in range(SaveRuntime.SAVE_JOURNAL_MAX_EVENTS + 8):
		SaveRuntime.append_save_journal_event("test_event", {
			"source": "user://nested/save-%s.json" % index,
			"result": "ok",
			"revision": index,
			"leaderboard_auth_refresh_token": "must-never-appear",
			"payload": {"secret": true},
		})
	var events := SaveRuntime.save_journal_events()
	_expect(events.size() == SaveRuntime.SAVE_JOURNAL_MAX_EVENTS, "The save journal must retain only its fixed event limit.")
	var rendered := JSON.stringify(events)
	_expect(not rendered.contains("must-never-appear") and not rendered.contains("secret"), "The save journal must exclude tokens and payload contents.")
	if not events.is_empty():
		_expect(str((events.back() as Dictionary).get("source", "")) == "save-%s.json" % (SaveRuntime.SAVE_JOURNAL_MAX_EVENTS + 7), "Journal sources must be reduced to filenames.")
	_remove(SaveRuntime.SAVE_JOURNAL_PATH)
	_remove(SaveRuntime.SAVE_JOURNAL_TEMP_PATH)


func _payload(revision: int, xp: int) -> Dictionary:
	return {
		"save_schema_version": SaveRuntime.SAVE_SCHEMA_VERSION,
		"save_reset_generation": 0,
		"save_repair_generation": 0,
		"save_revision": revision,
		"skills": {"fight": {"xp": xp, "level": 1}},
		"mastery": {},
		"stamina": {"fight": 10.0},
		"stamina_bank": {"fight": 0.0},
		"mats": {},
		"selected_skill_id": "fight",
		"saved_at": revision,
	}


func _revision_at(path: String) -> int:
	return int(SaveRuntime.load_dictionary(path).get("save_revision", -1))


func _cleanup_global_save_family() -> void:
	for path in [
		SaveRuntime.SAVE_PATH,
		SaveRuntime.SAVE_TEMP_PATH,
		SaveRuntime.SAVE_BACKUP_PATH,
		SaveRuntime.SAVE_BACKUP_2_PATH,
		SaveRuntime.SAVE_BACKUP_3_PATH,
		SaveRuntime.SAVE_RECOVERY_SNAPSHOT_PATH,
		SaveRuntime.SAVE_RECOVERY_SNAPSHOT_PATH + ".staging",
	]:
		_remove(path)
	var user_dir := DirAccess.open("user://")
	if user_dir == null:
		return
	for filename in user_dir.get_files():
		if filename.begins_with("idle_elite_save") and filename.contains(".corrupt-"):
			_remove("user://" + filename)


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
