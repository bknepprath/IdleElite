extends SceneTree

const SaveRuntime := preload("res://scripts/save_state/save_runtime.gd")
const MAIN_SCENE := preload("res://scenes/main.tscn")
const LEGACY_FIGHT_XP := 1000000
const LEGACY_MASTERY_XP := 2468

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_cleanup_save_family()
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "600")
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
	_finish(game)


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
