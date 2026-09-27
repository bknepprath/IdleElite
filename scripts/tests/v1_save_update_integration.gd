extends SceneTree

const SaveRuntime := preload("res://scripts/save_state/save_runtime.gd")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const LEGACY_FIGHT_XP := 1000000
const LEGACY_MASTERY_XP := 2468

var failures: Array[String] = []


class InterruptedSaveRuntime:
	extends "res://scripts/save_state/save_runtime.gd"

	func _load_game_secondary_restore() -> void:

		pass


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_save_family()
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "600")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	var fixture := _v1_fixture()
	_expect(SaveRuntime.write_text(SaveRuntime.SAVE_PATH, JSON.stringify(fixture)), "The flat v1 update fixture must be writable.")
	if not failures.is_empty():
		_finish(null)
		return

	var game := MAIN_SCENE.instantiate()
	root.add_child(game)
	var deadline := Time.get_ticks_msec() + 90000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(game.get("save_restore_complete")):
			var persisted_result := SaveRuntime.load_dictionary_result(SaveRuntime.SAVE_PATH)
			var persisted := persisted_result.get("data", {}) as Dictionary
			if (
				str(persisted_result.get("error", "")).is_empty()
				and bool(persisted_result.get("enveloped", false))
				and int(persisted.get("save_schema_version", 0)) == SaveRuntime.SAVE_SCHEMA_VERSION
				and int(persisted.get("save_revision", 0)) > 0
			):
				break

	_check_live_secondary_restore(game)
	_check_resaved_payload()
	if bool(game.get("save_restore_complete")):
		_check_cloud_restore(game)
		_check_reset_and_auth_persistence(game)
		_check_interrupted_cloud_restore(game)
	_finish(game)


func _check_cloud_restore(game: Node) -> void:
	var runtime = game.call("_save_runtime")
	var online = game.call("_online_runtime")
	var remote: Dictionary = runtime._save_payload(game.call("_unix_now"))
	var mastery: Dictionary = remote["mastery"]
	mastery["fishing:anchor-the-tiny-boat-dock"] = mastery["fishing:anchor-tiny-boat-dock"]
	mastery.erase("fishing:anchor-tiny-boat-dock")
	remote["save_revision"] = int(remote["save_revision"]) + 1
	_expect(not online._cloud_save_payload_conflicts_with_local(remote), "Renamed mastery keys must not create a false cloud conflict.")
	_expect(online._cloud_save_payload_should_replace_local(remote), "Equivalent aliased cloud progress must remain eligible for revision comparison.")
	remote["skills"]["fight"]["xp"] += 100
	remote["leaderboard_display_name"] = "RemoteOther"
	remote["leaderboard_name_key"] = "remoteother"
	remote["leaderboard_player_id"] = "remote-other-uid"
	online.cloud_save_remote_revision = 73
	online.cloud_save_remote_etag = "test-etag"
	online.cloud_save_last_remote_record = {"revision": 73}
	online.leaderboard_auth_id_token = "local-id-token"
	online.leaderboard_auth_expires_unix = 123456
	_expect(online._restore_cloud_save_payload(remote), "A complete cloud restore must persist successfully.")
	_expect(online.cloud_save_remote_revision == 73 and online.cloud_save_remote_etag == "test-etag", "Restoring gameplay must preserve cloud concurrency metadata.")
	_expect(online.cloud_save_last_remote_record == {"revision": 73}, "Restoring gameplay must preserve the cloud record needed for archival.")
	_expect(online.leaderboard_auth_id_token == "local-id-token" and online.leaderboard_auth_expires_unix == 123456, "Restoring gameplay must preserve the current auth session.")
	var persisted := SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	_expect(persisted["leaderboard_player_id"] == "uid-v1-keeper" and persisted["leaderboard_name_key"] == "v1keeper", "Cloud gameplay must not replace the device identity or claimed username.")
	_expect(int(persisted["skills"]["fight"]["xp"]) >= LEGACY_FIGHT_XP + 100, "Restored cloud XP must reach disk.")

	var staging := ProjectSettings.globalize_path(SaveRuntime.SAVE_RECOVERY_SNAPSHOT_PATH + ".staging")
	_expect(DirAccess.make_dir_absolute(staging) == OK, "Snapshot failure fixture must be created.")
	var before: Dictionary = runtime._save_payload(game.call("_unix_now"))
	_expect(not online._restore_cloud_save_payload(remote), "Cloud restore must fail if the prior device state cannot be protected.")
	_expect(runtime._save_payload(game.call("_unix_now"))["skills"] == before["skills"], "Snapshot failure must leave live progress untouched.")
	_expect(DirAccess.remove_absolute(staging) == OK, "Snapshot failure fixture must be removed.")
	var temp_path := ProjectSettings.globalize_path(SaveRuntime.SAVE_TEMP_PATH)
	_expect(DirAccess.make_dir_absolute(temp_path) == OK, "Save failure fixture must be created.")
	_expect(not online._restore_cloud_save_payload(remote), "Cloud restore must not report success when the final save fails.")
	_expect(FileAccess.file_exists(SaveRuntime.SAVE_RECOVERY_SNAPSHOT_PATH), "Failed cloud persistence must retain the pre-restore recovery copy.")
	_expect(DirAccess.remove_absolute(temp_path) == OK, "Save failure fixture must be removed.")
	_expect(game.call("save_game"), "Cloud persistence must be retryable after storage recovers.")


func _check_reset_and_auth_persistence(game: Node) -> void:
	var runtime = game.call("_save_runtime")
	var online = game.call("_online_runtime")
	var response := {"localId": "uid-v1-keeper", "idToken": "test-id-token", "refreshToken": "test-refresh-token", "expiresIn": 3600}
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	_expect(not online._apply_firebase_auth_response(response, "anonymous", "refresh"), "Authentication must not report success before credentials are durable.")
	_expect(not online._leaderboard_auth_ready() and online.auth_identity_save_pending, "Unsaved credentials must not authorize username claims or other online writes.")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "0")
	_expect(online._apply_firebase_auth_response(response, "anonymous", "refresh"), "The same identity must become usable once its local save succeeds.")
	_expect(online._leaderboard_auth_ready() and not online.auth_identity_save_pending, "Durable identity persistence must release the online gate.")
	var authenticated := SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	_expect(authenticated.get("leaderboard_player_id") == "uid-v1-keeper" and authenticated.get("leaderboard_auth_refresh_token") == "test-refresh-token", "The accepted account must survive restart with its matching refresh credential.")
	runtime.reset_data()
	_expect(game.call("save_game"), "An explicit hard reset must be saveable with its new generation.")
	game.skills["fight"]["xp"] = 500
	game.leaderboard_profile.player_id = "post-reset-uid"
	online.leaderboard_auth_bound_uid = "post-reset-uid"
	online.leaderboard_auth_refresh_token = "post-reset-refresh"
	_expect(game.call("save_game"), "Progress and account binding earned after a reset must be saveable.")
	var regressed: Dictionary = runtime._save_payload(game.call("_unix_now"))
	regressed["skills"]["fight"]["xp"] = 0
	_expect(not runtime._save_payload_can_replace_existing_save(regressed), "A reset must not leave later same-session XP regression authorized.")
	var identity_loss := SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	identity_loss["leaderboard_player_id"] = "another-uid"
	_expect(not runtime._save_payload_can_replace_existing_save(identity_loss), "A reset must not leave later same-session identity replacement authorized.")


func _check_interrupted_cloud_restore(game: Node) -> void:
	var runtime = InterruptedSaveRuntime.new(game)
	var remote: Dictionary = game.call("_save_runtime")._save_payload(game.call("_unix_now"))
	var original := SaveRuntime.read_text(SaveRuntime.SAVE_PATH)
	game.set("save_runtime", runtime)
	_expect(not game.call("_online_runtime")._restore_cloud_save_payload(remote), "An interrupted secondary restore must not report cloud success.")
	_expect(not bool(game.get("save_restore_complete")), "An interrupted cloud restore must leave saving disabled.")
	_expect(not game.call("save_game"), "Autosave must refuse a partially restored game.")
	_expect(SaveRuntime.read_text(SaveRuntime.SAVE_PATH) == original, "Interrupted restoration must preserve the primary save byte for byte.")


func _v1_fixture() -> Dictionary:
	var skills := {}
	var stamina := {}
	var stamina_bank := {}
	for skill_id in ["fight", "fishing", "build", "woodcutting", "thieving"]:
		skills[skill_id] = {"xp": LEGACY_FIGHT_XP, "level": 1}
		stamina[skill_id] = 17.0
		stamina_bank[skill_id] = 3.0
	return {
		"save_schema_version": 1,
		"save_reset_generation": 0,
		"skills": skills,
		"mastery": {
			"fishing:anchor-the-tiny-boat-dock": {"xp": LEGACY_MASTERY_XP, "level": 1},
		},
		"stamina": stamina,
		"stamina_bank": stamina_bank,
		"mats": {"softwood": 321.0, "hardwood": 45.0},
		"selected_skill_id": "fight",
		"running_skill_id": "",
		"running_action_id": "",
		"action_progress": 0.0,
		"manual_activity_unlocks": {
			"build:add-roof-to-something-roofless": true,
		},
		"manual_activity_requirement_unlocks": {
			"build:add-roof-to-something-roofless:build:14": true,
		},
		"built_modules": {
			"fight:duel-leaning-fence-post": true,
		},
		"onboarding_tutorial_complete": true,
		"leaderboard_display_name": "V1Keeper",
		"leaderboard_name_key": "v1keeper",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
		"leaderboard_player_id": "uid-v1-keeper",
		"leaderboard_auth_provider": "",
		"leaderboard_auth_refresh_token": "",
		"saved_at": int(Time.get_unix_time_from_system()),
	}


func _check_live_secondary_restore(game: Node) -> void:
	_expect(bool(game.get("save_restore_complete")), "The production boot must finish its secondary restore for a flat v1 save.")
	var skills := game.get("skills") as Dictionary
	var fight_state := skills.get("fight", {}) as Dictionary
	_expect(int(fight_state.get("xp", 0)) >= LEGACY_FIGHT_XP, "The live v1 restore must retain accumulated skill XP.")
	var profile = game.get("leaderboard_profile")
	_expect(str(profile.display_name) == "V1Keeper", "The live secondary restore must retain the player's display name.")
	_expect(str(profile.name_key) == "v1keeper", "The live secondary restore must retain the player's exact name key.")
	_expect(bool(profile.profile_claimed) and bool(profile.name_claim_verified), "The live secondary restore must retain verified claim flags.")
	_expect(str(profile.player_id) == "uid-v1-keeper", "The live secondary restore must retain the player UID.")
	var mastery := game.get("mastery") as Dictionary
	_expect(int((mastery.get("fishing:anchor-tiny-boat-dock", {}) as Dictionary).get("xp", 0)) == LEGACY_MASTERY_XP, "The live restore must move legacy mastery onto its canonical action key.")
	var manual_unlocks := game.get("manual_activity_unlocks") as Dictionary
	_expect(bool(manual_unlocks.get("build:roof-the-roofless", false)), "The live restore must retain a legacy manual unlock under its canonical key.")
	var built_modules := game.get("built_modules") as Dictionary
	_expect(bool(built_modules.get("fight:duel-fence-post", false)), "The live restore must retain a built module under its canonical key.")


func _check_resaved_payload() -> void:
	var persisted_result := SaveRuntime.load_dictionary_result(SaveRuntime.SAVE_PATH)
	var persisted := persisted_result.get("data", {}) as Dictionary
	_expect(str(persisted_result.get("error", "")).is_empty(), "The migrated primary save must decode after production resave.")
	_expect(bool(persisted_result.get("enveloped", false)), "The migrated primary save must use the current checksum envelope.")
	_expect(int(persisted.get("save_schema_version", 0)) == SaveRuntime.SAVE_SCHEMA_VERSION, "The production resave must advance v1 to the current schema.")
	_expect(int(persisted.get("save_revision", 0)) > 0, "The production resave must assign a current revision.")
	_expect(int(((persisted.get("skills", {}) as Dictionary).get("fight", {}) as Dictionary).get("xp", 0)) >= LEGACY_FIGHT_XP, "The resaved payload must retain v1 skill XP.")
	_expect(str(persisted.get("leaderboard_display_name", "")) == "V1Keeper", "The resaved payload must retain the player's display name.")
	_expect(str(persisted.get("leaderboard_name_key", "")) == "v1keeper", "The resaved payload must retain the player's exact name key.")
	_expect(str(persisted.get("leaderboard_player_id", "")) == "uid-v1-keeper", "The resaved payload must retain the player UID.")
	_expect(bool((persisted.get("manual_activity_unlocks", {}) as Dictionary).get("build:roof-the-roofless", false)), "The resaved payload must retain the canonical manual unlock.")
	_expect(bool((persisted.get("built_modules", {}) as Dictionary).get("fight:duel-fence-post", false)), "The resaved payload must retain the canonical built module.")
	_expect(int(((persisted.get("mastery", {}) as Dictionary).get("fishing:anchor-tiny-boat-dock", {}) as Dictionary).get("xp", 0)) == LEGACY_MASTERY_XP, "The resaved payload must retain canonical mastery XP.")
	_expect(not (persisted.get("mastery", {}) as Dictionary).has("fishing:anchor-the-tiny-boat-dock"), "The resaved payload must not retain the obsolete mastery alias.")
	var backup_result := SaveRuntime.load_dictionary_result(SaveRuntime.SAVE_BACKUP_PATH)
	_expect(str(backup_result.get("error", "")).is_empty() and int(backup_result.get("schema_version", -1)) == 1, "The original flat v1 primary must remain available in the first verified backup after migration.")


func _cleanup_save_family() -> void:
	for path in [
		SaveRuntime.SAVE_PATH,
		SaveRuntime.SAVE_TEMP_PATH,
		SaveRuntime.SAVE_BACKUP_PATH,
		SaveRuntime.SAVE_BACKUP_2_PATH,
		SaveRuntime.SAVE_BACKUP_3_PATH,
		SaveRuntime.SAVE_RECOVERY_SNAPSHOT_PATH,
		SaveRuntime.SAVE_JOURNAL_PATH,
		SaveRuntime.SAVE_JOURNAL_TEMP_PATH,
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(game: Node) -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()
	_cleanup_save_family()
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if failures.is_empty():
		print("v1-save-update-integration: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
