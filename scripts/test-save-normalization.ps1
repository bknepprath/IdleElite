$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\save-normalization"
$testScript = Join-Path $testDir "save_normalization_test.gd"


Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    @'
extends SceneTree

const MasteryState := preload("res://scripts/progression/mastery_state.gd")

const MainScript := preload("res://scripts/main.gd")
const AchievementState := preload("res://scripts/achievements/state.gd")
const AudioDirector := preload("res://scripts/audio/audio_director.gd")
const ModuleUiRuntime := preload("res://scripts/module_ui/runtime.gd")
const SaveRuntime := preload("res://scripts/save_state/save_runtime.gd")
const SaveStateNormalizers := preload("res://scripts/save_state/normalizers.gd")
const SkillState := preload("res://scripts/progression/skill_state.gd")
const FishingState := preload("res://scripts/fishing/state.gd")
const LeaderboardProfile := preload("res://scripts/leaderboard/profile.gd")
const LeaderboardPresentation := preload("res://scripts/leaderboard/presentation.gd")
const ChatState := preload("res://scripts/online/chat_state.gd")
const ProfileChatOverlaySurface := preload("res://scripts/ui/profile_chat_overlay_surface.gd")
const ActionArtUi := preload("res://scripts/ui/action_art_ui.gd")
const ActionRuntime := preload("res://scripts/gameplay/action_runtime.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := MainScript.new()
	game.get("activity_data_catalog").call("load_action_data", game)

	_check_mastery_restore(game)
	_check_mastery_save(game)
	_check_skills_save(game)
	_check_stamina_save(game)
	_check_fishing_location_save(game)
	_check_fishing_location_restore(game)
	_check_equipped_fishing_tool_save_restore(game)
	_check_fishing_rod_collection_save_restore(game)
	_check_fishing_numeric_state_save(game)
	_check_fishing_net_collection_save_restore(game)
	_check_thieving_jail_save(game)
	_check_thieving_jail_restore(game)
	_check_thieving_trophy_save_restore(game)
	_check_convergence_module_save_restore(game)
	_check_temporary_event_save_restore(game)
	_check_temporary_event_scheduler(game)
	_check_temporary_event_page_insertion(game)
	_check_temporary_event_complete_despawn(game)
	_check_temporary_event_tap_awards_rewards_before_despawn(game)
	_check_combo_xp_reward_map(game)
	_check_hub_module_save_restore(game)
	_check_hub_module_position_save_restore(game)
	_check_hub_decor_layout_save_restore(game)
	_check_hub_mission_save_restore(game)
	_check_leaderboard_scores_save(game)
	_check_leaderboard_profile_auth_save_restore(game)
	_check_leaderboard_fetch_retry_save_restore(game)
	_check_chat_metadata_save_restore(game)
	_check_resource_and_audio_settings_save(game)
	_check_audio_settings_restore(game)
	_check_god_mode_save(game)
	_check_test_profile_save_repair(game)
	_check_hard_reset_pending_restore_cancel(game)
	_check_active_skill_identity_save(game)
	_check_running_action_save(game)
	_check_action_progress_save_restore(game)
	_check_historical_activity_aliases(game)
	_check_action_key_save(game)
	_check_manual_activity_unlock_save_restore(game)
	_check_fishing_method_unlock_routing(game)
	_check_module_ui_preferences_save_restore(game)
	_check_auto_eat_fish_per_skill_save_restore(game)
	_check_auto_unlock_lockpads(game)
	_check_achievement_toast_seen_ids_save_restore(game)
	_check_scalar_progression_metadata_save(game)
	_check_offline_progress_trust(game)
	_check_load_save_dictionary_rejects_corrupt_files(game)
	_check_best_save_dictionary_prefers_progress(game)
	_check_save_payload_progress_regression_guard(game)
	_check_save_payload(game)
	_check_passive_module_save(game)
	_check_passive_module_restore(game)

	game.free()
	_finish()


func _save_payload_value(game: Node, key: String) -> Variant:
	var payload := _save_payload(game, int(game.call("_unix_now")))
	return payload.get(key)


func _save_payload(game: Node, now: int) -> Dictionary:
	return game.call("_save_runtime").call("_save_payload", now) as Dictionary


func _fishing_location_valid_callable(game: Node) -> Callable:
	return Callable(game.fishing_runtime, "location_id_valid").bind(FishingState.FISHING_LOCATION_DEFS)


func _fishing_state_save_payload(game: Node) -> Dictionary:
	return game.fishing_runtime.save_payload(
		FishingState.FISHING_NET_HAUL_THRESHOLD,
		FishingState.FISHING_BOAT_HAUL_THRESHOLD,
		Callable(game.fishing_runtime, "tool_is_unlocked"),
		Callable(game.fishing_runtime, "area_metadata_loaded"),
		_fishing_location_valid_callable(game)
	)


func _save_runtime(game: Node) -> Object:
	return game.call("_save_runtime") as Object


func _action_runtime(game: Node) -> Object:
	return game.call("_action_runtime") as Object


func _check_mastery_restore(game: Node) -> void:
	game.set("mastery", MasteryState.restored_from_save({
		"fishing:dip-a-tidepool-minnow": {"xp": 12},
		"fishing:shallows": {"xp": 31},
		"woodcutting:stack-logs-1": {"xp": 99},
		"fight:not-a-real-action": {"xp": 77},
		"malformed-key": {"xp": 66},
		"fight:push-ups": "bad-entry",
	}, Callable(_save_runtime(game), "_canonical_action_key"), game.MASTERY_MAX_LEVEL))
	var restored := game.get("mastery") as Dictionary
	_expect(restored.has("fishing:shallows"), "Mastery restore should canonicalize fishing action aliases.")
	_expect(_entry_xp(restored, "fishing:shallows") == 31, "Mastery restore should keep the highest XP for duplicate canonical keys.")
	_expect(not restored.has("woodcutting:stack-logs-1"), "Mastery restore should drop passive action keys.")
	_expect(not restored.has("fight:not-a-real-action"), "Mastery restore should drop unknown action keys.")
	_expect(not restored.has("malformed-key"), "Mastery restore should drop malformed action keys.")
	_expect(not restored.has("fight:push-ups"), "Mastery restore should drop malformed mastery entries.")


func _check_mastery_save(game: Node) -> void:
	game.set("mastery", {
		"fishing:dip-a-tidepool-minnow": {"xp": 18},
		"fishing:shallows": {"xp": 42},
		"woodcutting:stack-logs-1": {"xp": 99},
		"fight:not-a-real-action": {"xp": 77},
		"malformed-key": {"xp": 66},
	})
	var saved := MasteryState.for_save(game.mastery, Callable(_save_runtime(game), "_canonical_action_key"), game.MASTERY_MAX_LEVEL)
	_expect(saved.has("fishing:shallows"), "Mastery save should canonicalize fishing action aliases.")
	_expect(_entry_xp(saved, "fishing:shallows") == 42, "Mastery save should keep the highest XP for duplicate canonical keys.")
	_expect(not saved.has("woodcutting:stack-logs-1"), "Mastery save should drop passive action keys.")
	_expect(not saved.has("fight:not-a-real-action"), "Mastery save should drop unknown action keys.")
	_expect(not saved.has("malformed-key"), "Mastery save should drop malformed action keys.")


func _check_skills_save(game: Node) -> void:
	var level_10_xp := SkillState.xp_for_level(10)
	game.set("skills", {
		"fight": {"xp": level_10_xp, "level": 1},
		"thieving": {"xp": -50, "level": 99},
		"build": "bad-state",
		"not-a-real-skill": {"xp": 9999, "level": 99},
	})
	var saved := SkillState.skills_for_save(game.skill_defs, game.skills)
	_expect(saved.has("fight") and saved.has("thieving") and saved.has("build"), "Skill save should include known skill ids.")
	_expect(not saved.has("not-a-real-skill"), "Skill save should drop unknown skill ids.")
	var fight := saved.get("fight", {}) as Dictionary
	var thieving := saved.get("thieving", {}) as Dictionary
	var build := saved.get("build", {}) as Dictionary
	_expect(int(fight.get("xp", -1)) == level_10_xp, "Skill save should preserve known skill XP.")
	_expect(int(fight.get("level", -1)) == 10, "Skill save should derive levels from XP.")
	_expect(int(thieving.get("xp", -1)) == 0, "Skill save should clamp negative XP.")
	_expect(int(thieving.get("level", -1)) == 1, "Skill save should derive clamped negative XP as level 1.")
	_expect(int(build.get("xp", -1)) == 0 and int(build.get("level", -1)) == 1, "Skill save should replace malformed skill state with defaults.")


func _check_stamina_save(game: Node) -> void:
	_prime_core_skill_state(game)
	game.set("stamina", {
		"fight": 999.0,
		"thieving": -4.0,
		"build": 12.5,
		"woodcutting": 30.0,
		"not-a-real-skill": 14.0,
	})
	game.set("stamina_bank", {
		"fight": 999.0,
		"thieving": 6.0,
		"build": 999.0,
		"woodcutting": 5.0,
		"not-a-real-skill": 12.0,
	})
	var saved_stamina := SkillState.stamina_for_save(game.skill_defs, game.stamina, Callable(SkillState, "host_max_stamina").bind(game))
	var saved_bank := SkillState.stamina_bank_for_save(game.skill_defs, game.stamina, game.stamina_bank, Callable(SkillState, "host_max_stamina").bind(game))
	_expect(saved_stamina.has("fight") and saved_stamina.has("thieving") and saved_stamina.has("build"), "Stamina save should include known skills.")
	_expect(not saved_stamina.has("not-a-real-skill"), "Stamina save should drop unknown skill ids.")
	_expect(float(saved_stamina.get("fight", -1.0)) == 30.0, "Stamina save should clamp values above max stamina.")
	_expect(float(saved_stamina.get("thieving", -1.0)) == 0.0, "Stamina save should clamp negative stamina.")
	_expect(float(saved_stamina.get("build", -1.0)) == 12.5, "Stamina save should preserve fractional stamina.")
	_expect(float(saved_bank.get("fight", -1.0)) == 0.0, "Stamina bank save should reset full-stamina banks.")
	_expect(float(saved_bank.get("build", -1.0)) == 12.0, "Stamina bank save should preserve clamped regen-bank progress independently from fractional stamina.")
	_expect(not saved_bank.has("not-a-real-skill"), "Stamina bank save should drop unknown skill ids.")


func _check_fishing_location_save(game: Node) -> void:
	game.fishing_runtime.selected_locations = {
		"beach": "rocky",
		"pier": "missing-location",
		"lake": "ghost",
		"unknown-area": "shallows",
	}
	var saved := _fishing_state_save_payload(game).get("selected_fishing_locations", {}) as Dictionary
	_expect(saved.size() == 1, "Fishing location save should only keep valid area/location selections.")
	_expect(str(saved.get("beach", "")) == "rocky", "Fishing location save should preserve the valid beach selection.")


func _check_fishing_location_restore(game: Node) -> void:
	game.fishing_runtime.selected_locations = {"beach": "rocky"}
	game.fishing_runtime.restore_selected_locations("bad-entry", Callable(game.fishing_runtime, "area_metadata_loaded"), _fishing_location_valid_callable(game))
	var restored := game.fishing_runtime.selected_locations as Dictionary
	_expect(restored.is_empty(), "Fishing location restore should clear malformed saved selections.")
	game.fishing_runtime.restore_selected_locations({
		"beach": "rocky",
		"pier": "missing-location",
		"lake": "ghost",
		"unknown-area": "shallows",
	}, Callable(game.fishing_runtime, "area_metadata_loaded"), _fishing_location_valid_callable(game))
	restored = game.fishing_runtime.selected_locations as Dictionary
	_expect(restored.size() == 1, "Fishing location restore should only keep valid area/location selections.")
	_expect(str(restored.get("beach", "")) == "rocky", "Fishing location restore should preserve the valid beach selection.")


func _check_equipped_fishing_tool_save_restore(game: Node) -> void:
	game.fishing_runtime.rod_collected = true
	game.fishing_runtime.reinforced_rod_collected = true
	game.fishing_runtime.star_rod_collected = false
	game.fishing_runtime.equipped_tool_id = "line"
	_expect(str(_fishing_state_save_payload(game).get("equipped_fishing_tool_id", "")) == "reinforced_rod", "Equipped fishing tool save should collapse stale rod ids to the highest collected rod.")
	var payload := _save_payload(game, int(game.call("_unix_now")))
	_expect(str(payload.get("equipped_fishing_tool_id", "")) == "reinforced_rod", "Save payload should serialize normalized equipped fishing tool ids.")

	game.fishing_runtime.equipped_tool_id = "not-a-real-tool"
	_expect(str(_fishing_state_save_payload(game).get("equipped_fishing_tool_id", "")) == "hands", "Equipped fishing tool save should fall back to hands for invalid tool ids.")

	game.fishing_runtime.rod_collected = false
	game.fishing_runtime.reinforced_rod_collected = false
	game.fishing_runtime.star_rod_collected = false
	game.fishing_runtime.equipped_tool_id = "hands"
	game.call("_restore_fishing_state_from_save", {"selected_skill_id": "fishing", "equipped_fishing_tool_id": "star_rod"})
	_expect(str(game.fishing_runtime.equipped_tool_id) == "star_rod", "Fishing tool restore should still accept legacy equipped-tool unlocks.")
	_expect(_truthy(game.fishing_runtime.rod_collected) and _truthy(game.fishing_runtime.reinforced_rod_collected) and _truthy(game.fishing_runtime.star_rod_collected), "Legacy star rod restore should still reconcile collected rod state.")


func _check_fishing_rod_collection_save_restore(game: Node) -> void:
	game.fishing_runtime.rod_collected = false
	game.fishing_runtime.reinforced_rod_collected = false
	game.fishing_runtime.star_rod_collected = true
	var state_payload := _fishing_state_save_payload(game)
	_expect(_truthy(state_payload.get("fishing_rod_collected", false)), "Fishing rod save should infer base rod from star rod collection.")
	_expect(_truthy(state_payload.get("fishing_reinforced_rod_collected", false)), "Fishing rod save should infer reinforced rod from star rod collection.")
	var payload := _save_payload(game, int(game.call("_unix_now")))
	_expect(_truthy(payload.get("fishing_rod_collected", false)), "Save payload should not write star rod without base rod collection.")
	_expect(_truthy(payload.get("fishing_reinforced_rod_collected", false)), "Save payload should not write star rod without reinforced rod collection.")
	_expect(_truthy(payload.get("fishing_star_rod_collected", false)), "Save payload should preserve star rod collection.")

	game.fishing_runtime.rod_collected = false
	game.fishing_runtime.reinforced_rod_collected = false
	game.fishing_runtime.star_rod_collected = false
	game.call("_restore_fishing_state_from_save", {
		"selected_skill_id": "fishing",
		"fishing_star_rod_collected": true,
	})
	_expect(_truthy(game.fishing_runtime.rod_collected) and _truthy(game.fishing_runtime.reinforced_rod_collected) and _truthy(game.fishing_runtime.star_rod_collected), "Fishing rod restore should repair legacy saves where star rod is missing earlier rod flags.")

	game.fishing_runtime.rod_collected = false
	game.fishing_runtime.reinforced_rod_collected = true
	game.fishing_runtime.star_rod_collected = false
	game.fishing_runtime.reconcile_rod_collection()
	_expect(_truthy(game.fishing_runtime.rod_collected) and _truthy(game.fishing_runtime.reinforced_rod_collected) and not _truthy(game.fishing_runtime.star_rod_collected), "Fishing rod reconciliation should infer base rod from reinforced rod without granting star rod.")


func _check_fishing_numeric_state_save(game: Node) -> void:
	game.fishing_runtime.fish_currency = -10.0
	_expect(float(_save_payload_value(game, "fish_currency")) == 0.0, "Fishing currency save should clamp negative values.")
	game.fishing_runtime.net_stored_fish = 999
	_expect(int(_save_payload_value(game, "fishing_net_stored_fish")) == 9, "Fishing net stored-fish save should cap below the haul threshold.")
	game.fishing_runtime.net_successes = -2
	_expect(int(_save_payload_value(game, "fishing_net_successes")) == 0, "Fishing net successes save should clamp negative counts.")
	game.fishing_runtime.net_stored_xp = -3
	_expect(int(_save_payload_value(game, "fishing_net_stored_xp")) == 0, "Fishing net stored XP save should clamp negative values.")
	game.fishing_runtime.net_stored_mastery = -4.0
	_expect(float(_save_payload_value(game, "fishing_net_stored_mastery")) == 0.0, "Fishing net stored mastery save should clamp negative values.")
	game.fishing_runtime.boat_stored_fish = 999
	_expect(int(_save_payload_value(game, "fishing_boat_stored_fish")) == 199, "Fishing boat stored-fish save should cap below the haul threshold.")
	game.fishing_runtime.boat_successes = -5
	_expect(int(_save_payload_value(game, "fishing_boat_successes")) == 0, "Fishing boat successes save should clamp negative counts.")
	game.fishing_runtime.boat_stored_xp = -6
	_expect(int(_save_payload_value(game, "fishing_boat_stored_xp")) == 0, "Fishing boat stored XP save should clamp negative values.")
	game.fishing_runtime.boat_stored_mastery = -7.0
	_expect(float(_save_payload_value(game, "fishing_boat_stored_mastery")) == 0.0, "Fishing boat stored mastery save should clamp negative values.")


func _check_fishing_net_collection_save_restore(game: Node) -> void:
	game.fishing_runtime.net_collected = true
	var payload := _save_payload(game, int(game.call("_unix_now")))
	_expect(_truthy(payload.get("fishing_net_collect_completed", false)), "Fishing net save should keep the canonical collection-completed field.")
	_expect(not payload.has("fishing_net_collected"), "Fishing net save should not write the legacy collection field.")

	game.fishing_runtime.net_collected = false
	game.call("_restore_fishing_state_from_save", {"selected_skill_id": "fishing", "fishing_net_collected": true})
	_expect(_truthy(game.fishing_runtime.net_collected), "Fishing net restore should still accept the legacy collection field.")


func _check_thieving_jail_save(game: Node) -> void:
	var now := int(game.call("_unix_now"))
	var thieving_state: Object = game.get("thieving_state") as Object
	var penny_action := game.call("_action_data", "thieving", "borrow-cookie-permanently") as Dictionary
	_expect(int(game.call("_thieving_surface").call("_thieving_action_jail_seconds", penny_action, 1)) == 7, "Level 1 thieving jail seconds should use base time plus level-one module scaling.")
	_expect(int(game.call("_thieving_surface").call("_thieving_action_jail_seconds", penny_action, 2)) == 6, "Level 1 thieving jail seconds should shrink with one overlevel.")
	_expect(int(game.call("_thieving_surface").call("_thieving_action_jail_seconds", penny_action, 3)) == 0, "Level 1 thieving jail seconds should become no jail once below the minimum punishable timer.")
	var cookie_action := game.call("_action_data", "thieving", "sneak-past-tip-jar") as Dictionary
	_expect(int(game.call("_thieving_surface").call("_thieving_action_jail_seconds", cookie_action, 2)) == 9, "Thieving jail seconds should start at base time plus module unlock level times two.")
	_expect(int(game.call("_thieving_surface").call("_thieving_action_jail_seconds", cookie_action, 4)) == 7, "Thieving jail seconds should shrink as current level rises above the action unlock level.")
	_expect(int(game.call("_thieving_surface").call("_thieving_action_jail_seconds", cookie_action, 5)) == 6, "Thieving jail seconds should keep the minimum punishable jail timer.")
	_expect(int(game.call("_thieving_surface").call("_thieving_action_jail_seconds", cookie_action, 6)) == 0, "Thieving jail seconds below the minimum punishable timer should become no jail.")
	thieving_state.action_jails = {
		"sneak-past-tip-jar": {"cooldown_until_unix": now + 60, "resume_when_free": true},
		"pocket-a-penny-nobody-wanted": {"cooldown_until_unix": now + 60, "resume_when_free": true, "show_bars": false},
		"not-a-real-action": {"cooldown_until_unix": now + 60, "resume_when_free": true},
		"sneak-past-tip-jar-eye-contact": "bad-entry",
	}
	var saved := thieving_state.call("action_jails_for_save", now, func(skill_id: String, action_id: String) -> String: return ModuleUiRuntime.canonical_action_id(skill_id, action_id, game.get("FISHING_ACTION_ID_ALIASES")), Callable(game, "_action_data")) as Dictionary
	_expect(saved.size() == 1, "Thieving jail save should only keep active valid punishable jail entries.")
	_expect(saved.has("sneak-past-tip-jar"), "Thieving jail save should preserve the valid active jail.")
	var jail := saved.get("sneak-past-tip-jar", {}) as Dictionary
	_expect(_truthy(jail.get("resume_when_free", false)), "Thieving jail save should preserve the resume flag.")
	_expect(not jail.has("show_bars"), "Thieving jail save should not write no-bars jail state.")


func _check_thieving_jail_restore(game: Node) -> void:
	var now := int(game.call("_unix_now"))
	var thieving_state: Object = game.get("thieving_state") as Object
	thieving_state.action_jails = {"sneak-past-tip-jar": {"cooldown_until_unix": now + 60, "resume_when_free": true}}
	thieving_state.call("restore_action_jails", "bad-entry", now, func(skill_id: String, action_id: String) -> String: return ModuleUiRuntime.canonical_action_id(skill_id, action_id, game.get("FISHING_ACTION_ID_ALIASES")), Callable(game, "_action_data"))
	var restored: Dictionary = thieving_state.action_jails
	_expect(restored.is_empty(), "Thieving jail restore should clear malformed saved jail data.")
	thieving_state.call("restore_action_jails", {
		"sneak-past-tip-jar": {"cooldown_until_unix": now + 60, "resume_when_free": true},
		"pocket-a-penny-nobody-wanted": now + 120,
		"sneak-past-tip-jar-eye-contact": {"cooldown_until_unix": now + 60, "resume_when_free": true, "show_bars": false},
		"not-a-real-action": {"cooldown_until_unix": now + 60, "resume_when_free": true},
	}, now, func(skill_id: String, action_id: String) -> String: return ModuleUiRuntime.canonical_action_id(skill_id, action_id, game.get("FISHING_ACTION_ID_ALIASES")), Callable(game, "_action_data"))
	restored = thieving_state.action_jails
	_expect(restored.size() == 2, "Thieving jail restore should keep active valid dictionary and legacy scalar entries.")
	_expect(restored.has("sneak-past-tip-jar"), "Thieving jail restore should preserve valid dictionary entries.")
	_expect(restored.has("borrow-cookie-permanently"), "Thieving jail restore should preserve legacy scalar cooldown entries.")
	_expect(not restored.has("sneak-past-tip-jar-eye-contact"), "Thieving jail restore should drop saved no-bars entries as no jail punishment.")
	var dictionary_jail := restored.get("sneak-past-tip-jar", {}) as Dictionary
	var legacy_jail := restored.get("borrow-cookie-permanently", {}) as Dictionary
	_expect(_truthy(dictionary_jail.get("resume_when_free", false)), "Thieving jail restore should preserve dictionary resume flags.")
	_expect(not dictionary_jail.has("show_bars"), "Thieving jail restore should not preserve dictionary no-bars state.")
	_expect(not legacy_jail.has("show_bars"), "Thieving jail restore should not add no-bars state to legacy scalar entries.")
	_expect(not _truthy(legacy_jail.get("resume_when_free", true)), "Thieving jail restore should default legacy scalar resume flags to false.")


func _check_thieving_trophy_save_restore(game: Node) -> void:
	var thieving_state: Object = game.get("thieving_state") as Object
	game.call("_save_runtime").call("_restore_thieving_trophies_from_save", {"thieving_trophies": "bad-entry"})
	var restored := thieving_state.get("trophies") as Dictionary
	_expect(restored.is_empty(), "Thieving trophy restore should clear malformed saved trophy data.")
	game.call("_save_runtime").call("_restore_thieving_trophies_from_save", {
		"thieving_trophies": {
			"complimentary_spoon": {"stolen": true, "cooldown_until_unix_msec": 1234},
			"crown_jewel_replica_replica": true,
			"not-a-real-heist": {"stolen": true, "cooldown_until_unix": 99},
		}
	})
	restored = thieving_state.get("trophies") as Dictionary
	_expect(restored.size() == 2, "Thieving trophy restore should keep known trophy ids only.")
	_expect(restored.has("complimentary_spoon"), "Thieving trophy restore should preserve valid dictionary entries.")
	_expect(restored.has("crown_jewel_replica_replica"), "Thieving trophy restore should preserve valid legacy boolean entries.")
	var spoon := restored.get("complimentary_spoon", {}) as Dictionary
	var crown := restored.get("crown_jewel_replica_replica", {}) as Dictionary
	_expect(_truthy(spoon.get("stolen", false)), "Thieving trophy restore should preserve stolen state.")
	_expect(int(spoon.get("cooldown_until_unix", 0)) == 1234, "Thieving trophy restore should preserve legacy millisecond cooldown field.")
	_expect(_truthy(crown.get("stolen", false)), "Thieving trophy restore should preserve legacy boolean stolen state.")

	thieving_state.set("trophies", {
		"complimentary_spoon": {"stolen": true, "cooldown_until_unix": 44},
		"crown_jewel_replica_replica": true,
		"not-a-real-heist": {"stolen": true, "cooldown_until_unix": 99},
	})
	var saved := thieving_state.call("trophies_for_save") as Dictionary
	_expect(saved.size() == 1, "Thieving trophy save should only keep valid dictionary trophy entries.")
	_expect(saved.has("complimentary_spoon"), "Thieving trophy save should preserve valid trophy entries.")
	var saved_spoon := saved.get("complimentary_spoon", {}) as Dictionary
	_expect(_truthy(saved_spoon.get("stolen", false)), "Thieving trophy save should preserve stolen state.")
	_expect(int(saved_spoon.get("cooldown_until_unix", 0)) == 44, "Thieving trophy save should preserve cooldown state.")


func _check_convergence_module_save_restore(game: Node) -> void:
	_install_test_convergence_action(game)
	var convergence_runtime: Object = game.call("_convergence_runtime") as Object
	var raw_modules := {
		"test-convergence-shrine": {"built": true, "building": true, "build_started_unix": -7, "completions": -3},
		"not-a-real-convergence": {"built": true, "building": true, "build_started_unix": 99, "completions": 8},
		"bad-entry": "bad-state",
	}
	game.set("convergence_modules", raw_modules)
	var saved := convergence_runtime.call("_convergence_modules_for_save") as Dictionary
	_expect(saved.size() == 1, "Convergence module save should only keep valid convergence module entries.")
	_expect(saved.has("test-convergence-shrine"), "Convergence module save should preserve valid module ids.")
	var saved_state := saved.get("test-convergence-shrine", {}) as Dictionary
	_expect(_truthy(saved_state.get("built", false)), "Convergence module save should preserve built state.")
	_expect(_truthy(saved_state.get("building", false)), "Convergence module save should preserve building state.")
	_expect(int(saved_state.get("build_started_unix", -1)) == 0, "Convergence module save should clamp negative build timestamps.")
	_expect(int(saved_state.get("completions", -1)) == 0, "Convergence module save should clamp negative completion counts.")

	game.set("convergence_modules", {"test-convergence-shrine": {"built": true, "building": false}})
	convergence_runtime.call("_restore_convergence_modules_from_save", {"convergence_modules": "bad-entry"})
	var restored := game.get("convergence_modules") as Dictionary
	_expect(restored.is_empty(), "Convergence module restore should clear malformed saved module data.")
	convergence_runtime.call("_restore_convergence_modules_from_save", {"convergence_modules": raw_modules})
	restored = game.get("convergence_modules") as Dictionary
	_expect(restored.size() == 1, "Convergence module restore should only keep valid convergence module entries.")
	var restored_state := restored.get("test-convergence-shrine", {}) as Dictionary
	_expect(int(restored_state.get("build_started_unix", -1)) == 0, "Convergence module restore should clamp negative build timestamps.")
	_expect(int(restored_state.get("completions", -1)) == 0, "Convergence module restore should clamp negative completion counts.")


func _check_temporary_event_save_restore(game: Node) -> void:
	var runtime = game.call("_temporary_event_runtime")
	_prime_core_skill_state(game)
	var high_level_xp := SkillState.xp_for_level(80)
	var high_skills_by_id := game.get("skills") as Dictionary
	for raw_skill_id in high_skills_by_id.keys():
		var skill_id := str(raw_skill_id)
		var skill_state := high_skills_by_id.get(skill_id, {}) as Dictionary
		skill_state["xp"] = high_level_xp
		skill_state["level"] = 80
		high_skills_by_id[skill_id] = skill_state
	game.set("skills", high_skills_by_id)
	var raw_events := {
		"ambush-log-wagon": {
			"id": "ambush-log-wagon",
			"page": "fake-page",
			"spawned_unix": -25,
			"expires_unix": 10,
			"completed": true,
			"completed_unix": -9
		},
		"not-a-real-event": {
			"id": "not-a-real-event",
			"spawned_unix": 1,
			"expires_unix": 2
		},
		"bad-entry": "bad-state",
	}
	game.call("_temporary_event_runtime").set("temporary_event_active", raw_events)
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {
		"ambush-log-wagon": 99,
		"not-a-real-event": 123,
		"suspicious-picnic-basket": -20,
	})
	game.call("_temporary_event_runtime").set("temporary_event_next_roll_unix", -50)
	var saved := runtime.call("_temporary_events_for_save") as Dictionary
	var saved_active := saved.get("active", {}) as Dictionary
	var saved_cooldowns := saved.get("cooldowns", {}) as Dictionary
	_expect(saved_active.size() == 1 and saved_active.has("ambush-log-wagon"), "Temporary event save should keep only known active event ids.")
	var saved_wagon := saved_active.get("ambush-log-wagon", {}) as Dictionary
	_expect(str(saved_wagon.get("page", "")) == "fight", "Temporary event save should derive page from the event definition.")
	_expect(int(saved_wagon.get("spawn_level", -1)) == 25, "Temporary event save should default legacy entries to the event definition level, found %s." % int(saved_wagon.get("spawn_level", -1)))
	_expect(int(saved_wagon.get("spawned_unix", -1)) == 0, "Temporary event save should clamp negative spawn timestamps.")
	_expect(int(saved_wagon.get("expires_unix", -1)) == 10, "Temporary event save should preserve expiry timestamps after spawn.")
	_expect(_truthy(saved_wagon.get("completed", false)), "Temporary event save should preserve completion state.")
	_expect(int(saved_wagon.get("completed_unix", -1)) == 0, "Temporary event save should clamp negative completion timestamps.")
	_expect(saved_cooldowns.size() == 2 and saved_cooldowns.has("ambush-log-wagon") and saved_cooldowns.has("suspicious-picnic-basket"), "Temporary event save should keep only known cooldown ids.")
	_expect(int(saved_cooldowns.get("suspicious-picnic-basket", -1)) == 0, "Temporary event save should clamp negative cooldown timestamps.")
	_expect(int(saved.get("next_roll_unix", -1)) == 0, "Temporary event save should clamp negative next-roll timestamps.")

	game.call("_temporary_event_runtime").set("temporary_event_active", {"ambush-log-wagon": {"id": "ambush-log-wagon"}})
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {"ambush-log-wagon": 77})
	game.call("_temporary_event_runtime").set("temporary_event_next_roll_unix", 88)
	runtime.call("_restore_temporary_events_from_save", "bad-entry")
	_expect((game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary).is_empty(), "Temporary event restore should clear malformed active state.")
	_expect((game.call("_temporary_event_runtime").get("temporary_event_cooldowns") as Dictionary).is_empty(), "Temporary event restore should clear malformed cooldown state.")
	_expect(int(game.call("_temporary_event_runtime").get("temporary_event_next_roll_unix")) == 0, "Temporary event restore should clear malformed next-roll state.")
	runtime.call("_restore_temporary_events_from_save", {
		"active": raw_events,
		"cooldowns": {
			"ambush-log-wagon": 99,
			"not-a-real-event": 123,
			"suspicious-picnic-basket": -20,
		},
		"next_roll_unix": 44
	})
	var restored_active := game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary
	var restored_cooldowns := game.call("_temporary_event_runtime").get("temporary_event_cooldowns") as Dictionary
	_expect(restored_active.size() == 1 and restored_active.has("ambush-log-wagon"), "Temporary event restore should keep known active event ids.")
	var restored_wagon := restored_active.get("ambush-log-wagon", {}) as Dictionary
	_expect(int(restored_wagon.get("spawn_level", -1)) == 25, "Temporary event restore should default legacy active entries to the event definition level, found %s." % int(restored_wagon.get("spawn_level", -1)))
	_expect(restored_cooldowns.size() == 2 and restored_cooldowns.has("ambush-log-wagon") and restored_cooldowns.has("suspicious-picnic-basket"), "Temporary event restore should keep known cooldown ids.")
	_expect(int(game.call("_temporary_event_runtime").get("temporary_event_next_roll_unix")) == 44, "Temporary event restore should preserve next-roll timestamps.")

	_prime_core_skill_state(game)
	runtime.call("_restore_temporary_events_from_save", {
		"active": {
			"ambush-log-wagon": {
				"id": "ambush-log-wagon",
				"spawned_unix": 10,
				"expires_unix": 999
			}
		}
	})
	_expect((game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary).is_empty(), "Temporary event restore should drop active events below the owning skill's minimum event level.")


func _check_temporary_event_scheduler(game: Node) -> void:
	var runtime = game.call("_temporary_event_runtime")
	_prime_core_skill_state(game)
	game.call("_temporary_event_runtime").set("temporary_event_active", {})
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {})
	game.call("_temporary_event_runtime").set("temporary_event_next_roll_unix", 500)
	var low_level_changed: bool = runtime.call("_sync_temporary_event_scheduler", 500) == true
	_expect(low_level_changed, "Temporary event scheduler should advance due rolls even when no event is eligible.")
	_expect((game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary).is_empty(), "Temporary event scheduler should not spawn events before a page has an unlocked level above 1.")
	_expect(int(game.call("_temporary_event_runtime").get("temporary_event_next_roll_unix")) == 1400, "Temporary event scheduler should schedule the next roll after an ineligible due roll.")

	var suspicious_event := runtime.call("_event_module_def", "suspicious-picnic-basket") as Dictionary
	_expect(not suspicious_event.is_empty(), "Temporary event scheduler test should find the Suspicious Picnic Basket definition.")
	var level_two_xp := SkillState.xp_for_level(2)
	var low_thieving_skills := game.get("skills") as Dictionary
	var low_thieving := low_thieving_skills.get("thieving", {}) as Dictionary
	low_thieving["xp"] = level_two_xp
	low_thieving["level"] = 2
	low_thieving_skills["thieving"] = low_thieving
	game.set("skills", low_thieving_skills)
	_unlock_all_normal_actions_for_test(game, "thieving")
	_expect(runtime.call("_temporary_event_can_spawn", suspicious_event, 600) != true, "Suspicious Picnic Basket should not spawn before Thieving level 12.")
	var level_twelve_xp := SkillState.xp_for_level(12)
	low_thieving["xp"] = level_twelve_xp
	low_thieving["level"] = 12
	low_thieving_skills["thieving"] = low_thieving
	game.set("skills", low_thieving_skills)
	_expect(runtime.call("_temporary_event_can_spawn", suspicious_event, 600) == true, "Suspicious Picnic Basket should become eligible at Thieving level 12.")

	_prime_core_skill_state(game)
	var skills_by_id := game.get("skills") as Dictionary
	var high_level_xp := SkillState.xp_for_level(80)
	for raw_skill_id in skills_by_id.keys():
		var skill_id := str(raw_skill_id)
		var skill_state := skills_by_id.get(skill_id, {}) as Dictionary
		skill_state["xp"] = high_level_xp
		skill_state["level"] = 80
		skills_by_id[skill_id] = skill_state
	game.set("skills", skills_by_id)
	for raw_skill_def in game.get("skill_defs") as Array:
		var skill_def := raw_skill_def as Dictionary
		_unlock_all_normal_actions_for_test(game, str(skill_def.get("id", "")))
	game.call("_temporary_event_runtime").set("temporary_event_active", {})
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {})
	game.call("_temporary_event_runtime").set("temporary_event_next_roll_unix", 0)
	var initial_changed: bool = runtime.call("_sync_temporary_event_scheduler", 1000) == true
	_expect(initial_changed, "Temporary event scheduler should initialize an empty next-roll timestamp.")
	_expect((game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary).is_empty(), "Temporary event scheduler should delay the first roll instead of spawning immediately.")
	_expect(int(game.call("_temporary_event_runtime").get("temporary_event_next_roll_unix")) == 1120, "Temporary event scheduler should use the initial roll delay.")

	_save_runtime(game).set("save_dirty", false)
	var spawn_changed: bool = runtime.call("_sync_temporary_event_scheduler", 1120) == true
	var active := game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary
	_expect(spawn_changed, "Temporary event scheduler should report changed state when spawning an event.")
	_expect(active.size() == 1, "Temporary event scheduler should spawn one active event when eligible.")
	_expect(int(game.call("_temporary_event_runtime").get("temporary_event_next_roll_unix")) == 2020, "Temporary event scheduler should schedule the next periodic roll after spawning.")
	_expect(_save_runtime(game).get("save_dirty") == true, "Temporary event scheduler should mark spawned event state dirty for autosave.")
	var active_event_id := str(active.keys()[0])
	var active_entry := active.get(active_event_id, {}) as Dictionary
	var active_def := runtime.call("_event_module_def", active_event_id) as Dictionary
	var active_meta := active_def.get("event", {}) as Dictionary
	_expect(not active_def.is_empty(), "Temporary event scheduler should only spawn known event definitions.")
	_expect(str(active_entry.get("id", "")) == active_event_id, "Temporary event scheduler should write the active event id.")
	_expect(int(active_entry.get("spawned_unix", 0)) == 1120, "Temporary event scheduler should record spawn time.")
	_expect(int(active_entry.get("expires_unix", 0)) == 1120 + int(active_meta.get("active_duration_seconds", 0)), "Temporary event scheduler should record expiry from the event definition.")
	var page_highest := int(runtime.call("_temporary_event_highest_unlocked_page_level", str(active_def.get("page", ""))))
	var spawn_level := int(active_entry.get("spawn_level", 0))
	_expect(spawn_level >= maxi(1, page_highest - 10) and spawn_level <= page_highest - 1, "Temporary event scheduler should choose a spawn level one to ten below the highest unlocked page module.")
	_expect(runtime.call("_temporary_event_can_spawn", active_def, 1120) != true, "Temporary event scheduler should not consider an already active event eligible.")

	var expiry_unix := int(active_entry.get("expires_unix", 0))
	game.call("_temporary_event_runtime").set("temporary_event_next_roll_unix", expiry_unix + 99999)
	_save_runtime(game).set("save_dirty", false)
	var expiry_changed: bool = runtime.call("_sync_temporary_event_scheduler", expiry_unix + 1) == true
	var expired_active := game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary
	var cooldowns := game.call("_temporary_event_runtime").get("temporary_event_cooldowns") as Dictionary
	_expect(expiry_changed, "Temporary event scheduler should report changed state when expiring events.")
	_expect(expired_active.is_empty(), "Temporary event scheduler should remove expired active events.")
	_expect(cooldowns.has(active_event_id), "Temporary event scheduler should set a cooldown for expired events.")
	_expect(int(cooldowns.get(active_event_id, 0)) == expiry_unix + int(active_meta.get("respawn_cooldown_seconds", 0)), "Temporary event scheduler should start expiry cooldowns from the expiry timestamp.")

	game.call("_temporary_event_runtime").set("temporary_event_active", {})
	var elapsed_cooldowns := {}
	elapsed_cooldowns[active_event_id] = expiry_unix
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", elapsed_cooldowns)
	game.call("_temporary_event_runtime").set("temporary_event_next_roll_unix", expiry_unix + 99999)
	var prune_changed: bool = runtime.call("_sync_temporary_event_scheduler", expiry_unix + 1) == true
	_expect(prune_changed, "Temporary event scheduler should report changed state when pruning elapsed cooldowns.")
	_expect((game.call("_temporary_event_runtime").get("temporary_event_cooldowns") as Dictionary).is_empty(), "Temporary event scheduler should prune elapsed cooldowns.")


func _expected_temporary_event_total_for_projection(game: Node, page: String, event_action: Dictionary) -> int:
	var runtime = game.call("_temporary_event_runtime")
	var catalog = game.get("activity_data_catalog")
	var spawn_level := int(catalog.call("activity_action_display_sort_level", event_action))
	var reference_action := runtime.call("_temporary_event_reference_action_for_level", page, spawn_level) as Dictionary
	if reference_action.is_empty():
		return maxi(1, int(event_action.get("xp", 1)))
	var reference_rewards := _action_runtime(game).call("_base_xp_reward_map", reference_action, page) as Dictionary
	var reference_total := maxi(1, int(_action_runtime(game).call("_reward_map_total", reference_rewards)))
	var reference_seconds := maxf(0.1, float(reference_action.get("seconds", 1.0)))
	var event_seconds := maxf(0.1, float(event_action.get("seconds", reference_seconds)))
	var expected_total := maxi(1, int(round(float(reference_total) / reference_seconds * event_seconds * 12.0)))
	var xp_reward_cap := int(event_action.get("xp_reward_cap", 0))
	if xp_reward_cap > 0:
		expected_total = mini(expected_total, xp_reward_cap)
	return expected_total


func _check_temporary_event_xp_caps(game: Node) -> void:
	var runtime = game.call("_temporary_event_runtime")
	var event_defs := runtime.get("event_module_defs") as Array
	for raw_event_def in event_defs:
		var event_def := raw_event_def as Dictionary
		var event_id := str(event_def.get("id", ""))
		var page := str(event_def.get("page", ""))
		var xp_reward_cap := int(event_def.get("xp_reward_cap", 0))
		_expect(xp_reward_cap > 0, "Temporary event %s should define an XP cap." % event_id)
		var event_action := runtime.call("_temporary_event_action_for_entry", event_def, {
			"id": event_id,
			"page": page,
			"spawn_level": 98,
			"spawned_unix": 0,
			"expires_unix": 3600,
			"completed": false,
			"completed_unix": 0,
		}) as Dictionary
		var base_rewards := _action_runtime(game).call("_base_xp_reward_map", event_action, page) as Dictionary
		_expect(int(_action_runtime(game).call("_reward_map_total", base_rewards)) <= xp_reward_cap, "Temporary event %s base XP should stay under its cap." % event_id)
		var inflated_event := event_action.duplicate(true)
		var inflated_rewards := {}
		for raw_skill_id in base_rewards.keys():
			inflated_rewards[raw_skill_id] = maxi(xp_reward_cap * 2, int(base_rewards.get(raw_skill_id, 0)) * 10)
		if inflated_rewards.is_empty():
			inflated_rewards[page] = xp_reward_cap * 10
		inflated_event["xp_rewards"] = inflated_rewards
		inflated_event["event_stats_scaled"] = true
		var capped_rewards := _action_runtime(game).call("_effective_xp_reward_map", inflated_event, page) as Dictionary
		_expect(int(_action_runtime(game).call("_reward_map_total", capped_rewards)) == xp_reward_cap, "Temporary event %s effective XP should clamp boosted rewards to its cap." % event_id)


func _expected_temporary_event_stamina_for_projection(game: Node, page: String, event_action: Dictionary) -> int:
	var runtime = game.call("_temporary_event_runtime")
	var catalog = game.get("activity_data_catalog")
	var spawn_level := int(catalog.call("activity_action_display_sort_level", event_action))
	var reference_action := runtime.call("_temporary_event_reference_action_for_level", page, spawn_level) as Dictionary
	if reference_action.is_empty():
		return maxi(1, int(event_action.get("stamina", 1)))
	return maxi(1, int(round(float(reference_action.get("stamina", 1)) * 5.0)))


func _expected_temporary_event_seconds_for_projection(game: Node, page: String, event_action: Dictionary) -> float:
	var runtime = game.call("_temporary_event_runtime")
	var catalog = game.get("activity_data_catalog")
	var spawn_level := int(catalog.call("activity_action_display_sort_level", event_action))
	var reference_action := runtime.call("_temporary_event_reference_action_for_level", page, spawn_level) as Dictionary
	var fallback_seconds := float(event_action.get("seconds", 1.0))
	var reference_seconds := maxf(0.1, float(reference_action.get("seconds", fallback_seconds))) if not reference_action.is_empty() else maxf(0.1, fallback_seconds)
	return maxf(8.0, reference_seconds * 3.0) + maxf(0.0, float(spawn_level)) * 0.08


func _expected_temporary_event_log_range(event_action: Dictionary) -> Dictionary:
	var spawn_level := int(event_action.get("target_level", event_action.get("unlock", 1)))
	var active_event = event_action.get("active_event", {})
	if typeof(active_event) == TYPE_DICTIONARY:
		spawn_level = int((active_event as Dictionary).get("spawn_level", spawn_level))
	var event_meta := event_action.get("event", {}) as Dictionary
	var minimum_level := maxi(1, int(event_meta.get("minimum_level", event_action.get("minimum_level", event_action.get("unlock", 1)))))
	var scale := maxf(1.0, float(maxi(1, spawn_level)) / float(minimum_level))
	return {
		"logs_min": maxi(1, int(round(30.0 * scale))),
		"logs_max": maxi(1, int(round(50.0 * scale)))
	}


func _check_temporary_event_page_insertion(game: Node) -> void:
	var runtime = game.call("_temporary_event_runtime")
	_prime_core_skill_state(game)
	var low_level_xp := SkillState.xp_for_level(12)
	var low_skills_by_id := game.get("skills") as Dictionary
	for raw_skill_id in low_skills_by_id.keys():
		var low_skill_id := str(raw_skill_id)
		var low_skill_state := low_skills_by_id.get(low_skill_id, {}) as Dictionary
		low_skill_state["xp"] = low_level_xp
		low_skill_state["level"] = 12
		low_skills_by_id[low_skill_id] = low_skill_state
	game.set("skills", low_skills_by_id)
	_unlock_all_normal_actions_for_test(game, "thieving")
	var low_now := int(game.call("_unix_now"))
	game.call("_temporary_event_runtime").set("temporary_event_active", {
		"suspicious-picnic-basket": {
			"id": "suspicious-picnic-basket",
			"page": "thieving",
			"spawn_level": 73,
			"spawned_unix": low_now,
			"expires_unix": low_now + 3600,
			"completed": false,
			"completed_unix": 0
		}
	})
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {})
	var repaired_event := game.call("_action_data", "thieving", "suspicious-picnic-basket") as Dictionary
	_expect(not repaired_event.is_empty(), "Active temporary events with over-high saved levels should resolve through action data lookup.")
	_expect(game.call("_activity_unlock_runtime").call("_is_action_unlocked", "thieving", repaired_event) == true, "Active temporary events with repaired levels should never appear locked.")
	_expect(int(runtime.call("_temporary_event_highest_unlocked_page_level", "thieving")) == 12, "Temporary event page-level scan should ignore manually unlocked actions above the current page level.")
	var catalog = game.get("activity_data_catalog")
	_expect(int(catalog.call("activity_action_display_sort_level", repaired_event)) == 11, "Temporary event active projection should cap over-high saved levels below the current highest unlocked page module.")
	var repaired_rewards := _action_runtime(game).call("_base_xp_reward_map", repaired_event, "thieving") as Dictionary
	_expect(repaired_rewards.has("thieving") and repaired_rewards.has("fishing"), "Temporary event reward splits should preserve their event template skills.")
	_expect(int(_action_runtime(game).call("_reward_map_total", repaired_rewards)) == _expected_temporary_event_total_for_projection(game, "thieving", repaired_event), "Temporary event rewards should scale to roughly 12x the repaired spawn-level module XP rate.")
	_expect(int(repaired_event.get("stamina", -1)) == _expected_temporary_event_stamina_for_projection(game, "thieving", repaired_event), "Temporary event stamina should scale to 5x the repaired spawn-level module stamina.")
	_expect(absf(float(repaired_event.get("seconds", -1.0)) - _expected_temporary_event_seconds_for_projection(game, "thieving", repaired_event)) <= 0.001, "Temporary event seconds should use a higher base duration plus spawn-level scaling.")
	_expect(absf(float(repaired_event.get("success", -1.0)) - 30.0) <= 0.001, "Temporary events should start from a low 30% base completion rate.")
	_expect(float(MasteryState.reward_for_action(game, "thieving", "suspicious-picnic-basket", repaired_event)) == 0.0, "Temporary events should not grant mastery rewards.")

	_prime_core_skill_state(game)
	var level_one_skills := game.get("skills") as Dictionary
	var level_one_fight := level_one_skills.get("fight", {}) as Dictionary
	level_one_fight["xp"] = 0
	level_one_fight["level"] = 1
	level_one_skills["fight"] = level_one_fight
	game.set("skills", level_one_skills)
	_unlock_all_normal_actions_for_test(game, "fight")
	var forced_low_event_now := int(game.call("_unix_now"))
	game.call("_temporary_event_runtime").set("temporary_event_active", {
		"ambush-log-wagon": {
			"id": "ambush-log-wagon",
			"page": "fight",
			"spawn_level": 25,
			"spawned_unix": forced_low_event_now,
			"expires_unix": forced_low_event_now + 3600,
			"completed": false,
			"completed_unix": 0
		}
	})
	_expect((runtime.call("_active_event_actions_for_skill", "fight") as Array).is_empty(), "Forced active temporary events should not render before the owning skill reaches level 12.")
	_expect((game.call("_action_data", "fight", "ambush-log-wagon") as Dictionary).is_empty(), "Forced active temporary events should not resolve as action data before the owning skill reaches level 12.")
	_expect(_entry_index_for_action_id(game.call("_skill_detail_surface").call("_visible_detail_entries_for_skill", "fight") as Array, "ambush-log-wagon") < 0, "Forced active temporary events should not appear in low-level skill detail entries.")

	_prime_core_skill_state(game)
	var high_level_xp := SkillState.xp_for_level(80)
	var skills_by_id := game.get("skills") as Dictionary
	for raw_skill_id in skills_by_id.keys():
		var skill_id := str(raw_skill_id)
		var skill_state := skills_by_id.get(skill_id, {}) as Dictionary
		skill_state["xp"] = high_level_xp
		skill_state["level"] = 80
		skills_by_id[skill_id] = skill_state
	game.set("skills", skills_by_id)
	_unlock_all_normal_actions_for_test(game, "fight")
	_unlock_all_normal_actions_for_test(game, "fishing")
	var now := int(game.call("_unix_now"))
	game.call("_temporary_event_runtime").set("temporary_event_active", {
		"ambush-log-wagon": {
			"id": "ambush-log-wagon",
			"page": "fight",
			"spawn_level": 20,
			"spawned_unix": now,
			"expires_unix": now + 3600,
			"completed": false,
			"completed_unix": 0
		},
		"washed-up-locked-crate": {
			"id": "washed-up-locked-crate",
			"page": "fishing",
			"spawn_level": 72,
			"spawned_unix": now,
			"expires_unix": now + 3600,
			"completed": false,
			"completed_unix": 0
		}
	})
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {})

	var fight_event := game.call("_action_data", "fight", "ambush-log-wagon") as Dictionary
	_expect(not fight_event.is_empty(), "Active temporary events should resolve through action data lookup.")
	_expect(str(fight_event.get("name", "")) == "Ambush Log Wagon", "Covered wagon event should use the Ambush Log Wagon display name.")
	_expect(game.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", fight_event) == true, "Active eligible temporary events should be playable without permanent manual unlocks.")
	_expect(int(catalog.call("activity_action_display_sort_level", fight_event)) == 20, "Active temporary events should use their saved spawn level for page insertion.")
	var scaled_rewards := _action_runtime(game).call("_base_xp_reward_map", fight_event, "fight") as Dictionary
	_expect(scaled_rewards.has("fight") and scaled_rewards.has("thieving"), "Active temporary event reward splits should preserve their event template skills.")
	_expect(int(_action_runtime(game).call("_reward_map_total", scaled_rewards)) == _expected_temporary_event_total_for_projection(game, "fight", fight_event), "Active temporary event rewards should scale to roughly 12x the spawned-level module XP rate.")
	var expected_fight_event_stamina := _expected_temporary_event_stamina_for_projection(game, "fight", fight_event)
	_expect(int(fight_event.get("stamina", -1)) == expected_fight_event_stamina, "Active temporary event stamina should scale to 5x the spawned-level module stamina, found %s expected %s." % [int(fight_event.get("stamina", -1)), expected_fight_event_stamina])
	_expect(absf(float(fight_event.get("seconds", -1.0)) - _expected_temporary_event_seconds_for_projection(game, "fight", fight_event)) <= 0.001, "Active temporary event seconds should use a higher base duration plus spawn-level scaling.")
	var log_range := fight_event.get("resource_rewards", {}) as Dictionary
	var expected_log_range := _expected_temporary_event_log_range(fight_event)
	_expect(int(log_range.get("logs_min", -1)) == int(expected_log_range.get("logs_min", -2)) and int(log_range.get("logs_max", -1)) == int(expected_log_range.get("logs_max", -2)), "Ambush Log Wagon log rewards should scale from the 30-50 base range by spawn level.")
	_expect(absf(float(fight_event.get("success", -1.0)) - 30.0) <= 0.001, "Active temporary events should start from a 30% base completion rate.")
	_expect(float(MasteryState.reward_for_action(game, "fight", "ambush-log-wagon", fight_event)) == 0.0, "Active temporary events should not grant mastery rewards.")
	var fight_medal_actions := AchievementState.playable_actions_for_medal_buffs_including_event(game, "fight", fight_event)
	var fight_event_medal_index := -1
	for i in range(fight_medal_actions.size()):
		var medal_action := fight_medal_actions[i] as Dictionary
		if str(medal_action.get("id", "")) == "ambush-log-wagon":
			fight_event_medal_index = i
			break
	_expect(fight_event_medal_index >= 0 and fight_event_medal_index < fight_medal_actions.size() - 1, "Active temporary events should be inserted among normal modules for medal-neighbor bonuses.")
	if fight_event_medal_index >= 0 and fight_event_medal_index < fight_medal_actions.size() - 1:
		var medal_source := fight_medal_actions[fight_event_medal_index + 1] as Dictionary
		var medal_source_id := str(medal_source.get("id", ""))
		var mastery_state := game.get("mastery") as Dictionary
		mastery_state[str(game.call("_action_key", "fight", medal_source_id))] = {"xp": MasteryState.xp_for_level(1), "level": 1}
		game.set("mastery", mastery_state)
		SkillState.invalidate_stat_caches(game)
		_expect(AchievementState.activity_medal_accuracy_bonus(game, "fight", fight_event) > 0.0, "Temporary event completion rate should include surrounding medal accuracy bonuses.")
		_expect(float(game.call("_action_runtime").call("_success_chance", "fight", fight_event)) > 30.0, "Temporary event success chance should rise above the 30% base when surrounding medal bonuses apply.")
	var fight_entries := game.call("_skill_detail_surface").call("_visible_detail_entries_for_skill", "fight") as Array
	var fight_event_index := _entry_index_for_action_id(fight_entries, "ambush-log-wagon")
	_expect(fight_event_index >= 0, "Active temporary events should appear in the owning page detail entries.")
	if fight_event_index > 0:
		var previous_action := (fight_entries[fight_event_index - 1] as Dictionary).get("action", {}) as Dictionary
		_expect(int(catalog.call("activity_action_display_sort_level", previous_action)) <= 20, "Temporary event insertion should keep lower-level actions before the event.")
	if fight_event_index >= 0 and fight_event_index < fight_entries.size() - 1:
		var next_action := (fight_entries[fight_event_index + 1] as Dictionary).get("action", {}) as Dictionary
		if not next_action.is_empty():
			_expect(int(catalog.call("activity_action_display_sort_level", next_action)) >= 20, "Temporary event insertion should keep higher-level actions after the event.")

	var fishing_signature := game.call("_fishing_ui_surface").call("_fishing_detail_render_signature") as Array
	_expect(fishing_signature.has("washed-up-locked-crate"), "Fishing detail signature should include active temporary events.")
	var fishing_event := game.call("_action_data", "fishing", "washed-up-locked-crate") as Dictionary
	var fishing_event_rewards := _action_runtime(game).call("_base_xp_reward_map", fishing_event, "fishing") as Dictionary
	var fishing_event_total := int(_action_runtime(game).call("_reward_map_total", fishing_event_rewards))
	_expect(fishing_event_total >= 3500 and fishing_event_total <= 4200, "Washed-Up Locked Crate base XP should stay in the 4k range when spawned at high level.")
	_check_temporary_event_xp_caps(game)
	var fishing_plan := game.call("_fishing_ui_surface").call("_build_fishing_detail_lazy_plan", "fishing") as Array
	var fishing_event_index := _plan_index_for_track_id(fishing_plan, "washed-up-locked-crate")
	_expect(fishing_event_index >= 0, "Fishing lazy plan should include an active temporary event card.")

	game.call("_temporary_event_runtime").set("temporary_event_active", {
		"ambush-log-wagon": {
			"id": "ambush-log-wagon",
			"page": "fight",
			"spawned_unix": now - 7200,
			"expires_unix": now - 1,
			"completed": false,
			"completed_unix": 0
		}
	})
	_expect((runtime.call("_active_event_actions_for_skill", "fight") as Array).is_empty(), "Expired temporary events should not be exposed as active page actions.")


func _check_temporary_event_complete_despawn(game: Node) -> void:
	var runtime = game.call("_temporary_event_runtime")
	_prime_core_skill_state(game)
	var now := int(game.call("_unix_now"))
	game.call("_temporary_event_runtime").set("temporary_event_active", {
		"ambush-log-wagon": {
			"id": "ambush-log-wagon",
			"page": "fight",
			"spawned_unix": now,
			"expires_unix": now + 3600,
			"completed": false,
			"completed_unix": 0
		}
	})
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {})
	_save_runtime(game).set("save_dirty", false)
	var event_def := runtime.call("_event_module_def", "ambush-log-wagon") as Dictionary
	var event_meta := event_def.get("event", {}) as Dictionary
	var changed: bool = runtime.call("_complete_temporary_event_action_state", "ambush-log-wagon", now + 12) == true
	var active := game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary
	var cooldowns := game.call("_temporary_event_runtime").get("temporary_event_cooldowns") as Dictionary
	_expect(changed, "Temporary event completion should report changed state.")
	_expect(active.is_empty(), "Temporary event completion should remove the active event.")
	_expect(cooldowns.has("ambush-log-wagon"), "Temporary event completion should set a respawn cooldown.")
	_expect(int(cooldowns.get("ambush-log-wagon", 0)) == now + 12 + int(event_meta.get("respawn_cooldown_seconds", 0)), "Temporary event completion cooldown should start from completion time.")
	_expect(_save_runtime(game).get("save_dirty") == true, "Temporary event completion should mark save state dirty.")
	_expect((game.call("_action_data", "fight", "ambush-log-wagon") as Dictionary).is_empty(), "Completed temporary events should no longer resolve as active action data.")


func _check_temporary_event_tap_awards_rewards_before_despawn(game: Node) -> void:
	var runtime = game.call("_temporary_event_runtime")
	_prime_core_skill_state(game)
	var now := int(game.call("_unix_now"))
	var skills := game.get("skills") as Dictionary
	var fight_state := skills.get("fight", {}) as Dictionary
	fight_state["xp"] = SkillState.xp_for_level(80)
	skills["fight"] = fight_state
	game.set("skills", skills)
	SkillState.recalculate_level(game, "fight")
	var stamina_state := game.get("stamina") as Dictionary
	stamina_state["fight"] = float(SkillState.max_stamina(game, "fight"))
	game.set("stamina", stamina_state)
	game.set("current_screen", "home")
	game.set("selected_skill_id", "fight")
	game.call("_temporary_event_runtime").set("temporary_event_active", {
		"ambush-log-wagon": {
			"id": "ambush-log-wagon",
			"page": "fight",
			"spawn_level": 20,
			"spawned_unix": now,
			"expires_unix": now + 3600,
			"completed": false
		}
	})
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {})
	_save_runtime(game).set("save_dirty", false)
	var event_action := game.call("_action_data", "fight", "ambush-log-wagon") as Dictionary
	_expect(not event_action.is_empty(), "Temporary event tap test should resolve the active event action.")
	event_action["success"] = 100.0
	var reward_map := _action_runtime(game).call("_completion_xp_reward_map", event_action, "fight", false, false, false, false) as Dictionary
	var expected_fight_xp := int(reward_map.get("fight", 0))
	var expected_thieving_xp := int(reward_map.get("thieving", 0))
	_expect(str(runtime.call("_temporary_event_log_reward_mat_id")) == "scrapwood", "Covered wagon should treat Scrapwood as the base log material before higher log tiers are unlocked.")
	var action_runtime: Object = game.call("_action_runtime")
	var badge_icons := ActionArtUi.resource_icon_paths(event_action, Callable(action_runtime, "_action_mat_reward_defs"), Callable(game.material_runtime, "icon_path"), Callable(runtime, "_temporary_event_log_reward_mat_id")) as Array
	_expect(not badge_icons.is_empty() and str(badge_icons[0]) == str(game.material_runtime.icon_path("scrapwood")), "Covered wagon art badge should show the Scrapwood icon when Scrapwood is the awarded log material.")
	skills = game.get("skills") as Dictionary
	var woodcutting_state := skills.get("woodcutting", {}) as Dictionary
	woodcutting_state["xp"] = SkillState.xp_for_level(80)
	skills["woodcutting"] = woodcutting_state
	game.set("skills", skills)
	SkillState.recalculate_level(game, "woodcutting")
	game.call("_activity_unlock_runtime").call("_mark_action_manually_unlocked", "woodcutting", "chop-knotty-maple")
	_expect(str(runtime.call("_temporary_event_log_reward_mat_id")) == "hardwood", "Covered wagon should choose Hardwood once a Hardwood-yielding woodcutting action is unlocked.")
	badge_icons = ActionArtUi.resource_icon_paths(event_action, Callable(action_runtime, "_action_mat_reward_defs"), Callable(game.material_runtime, "icon_path"), Callable(runtime, "_temporary_event_log_reward_mat_id")) as Array
	_expect(not badge_icons.is_empty() and str(badge_icons[0]) == str(game.material_runtime.icon_path("hardwood")), "Covered wagon art badge should show the Hardwood icon when Hardwood is the awarded log material.")
	var log_range := event_action.get("resource_rewards", {}) as Dictionary
	var expected_log_min := int(log_range.get("logs_min", 0))
	var expected_log_max := int(log_range.get("logs_max", expected_log_min))
	var expected_log_multiplier: float = game.material_runtime.woodcutting_log_collection_multiplier(int(SkillState.host_skill_level(game, "woodcutting")))
	var expected_log_min_buffed := float(expected_log_min) * expected_log_multiplier
	var expected_log_max_buffed := float(expected_log_max) * expected_log_multiplier
	skills = game.get("skills") as Dictionary
	fight_state = skills.get("fight", {}) as Dictionary
	var thieving_state := skills.get("thieving", {}) as Dictionary
	var fight_xp_before := int(fight_state.get("xp", 0))
	var thieving_xp_before := int(thieving_state.get("xp", 0))
	var stamina_before := float((game.get("stamina") as Dictionary).get("fight", 0.0))
	var softwood_before: float = game.material_runtime.amount("softwood")
	var hardwood_before: float = game.material_runtime.amount("hardwood")
	game.set("running_skill_id", "fight")
	game.set("running_action_id", "ambush-log-wagon")
	game.set("action_progress", 1.0)
	var cost := float(game.call("_action_runtime").call("_effective_stamina", "fight", event_action))
	var spent := SkillState.spend_action_stamina(game.stamina, game.stamina_bank, "fight", cost, Callable(SkillState, "host_max_stamina").bind(game))
	_expect(spent, "Temporary event completion test should be able to charge stamina.")
	runtime.call(
		"_complete_temporary_event_action_attempt",
		"fight",
		"ambush-log-wagon",
		event_action,
		game.call("_action_key", "fight", "ambush-log-wagon"),
		cost,
		{},
		true
	)
	var active := game.call("_temporary_event_runtime").get("temporary_event_active") as Dictionary
	var cooldowns := game.call("_temporary_event_runtime").get("temporary_event_cooldowns") as Dictionary
	skills = game.get("skills") as Dictionary
	fight_state = skills.get("fight", {}) as Dictionary
	thieving_state = skills.get("thieving", {}) as Dictionary
	var softwood_after: float = game.material_runtime.amount("softwood")
	var hardwood_after: float = game.material_runtime.amount("hardwood")
	var hardwood_delta := hardwood_after - hardwood_before
	_expect(active.is_empty(), "Successful temporary event completion should despawn the event.")
	_expect(cooldowns.has("ambush-log-wagon"), "Successful temporary event completion should set a respawn cooldown.")
	_expect(int(fight_state.get("xp", 0)) - fight_xp_before == expected_fight_xp, "Successful temporary event completion should grant owner-skill XP before despawning.")
	_expect(int(thieving_state.get("xp", 0)) - thieving_xp_before == expected_thieving_xp, "Successful temporary event completion should grant secondary event XP before despawning.")
	_expect(absf(softwood_after - softwood_before) <= 0.0001, "Covered wagon should not award Softwood once Hardwood logs are unlocked.")
	_expect(hardwood_delta >= expected_log_min_buffed - 0.0001 and hardwood_delta <= expected_log_max_buffed + 0.0001, "Covered wagon should award buffed Hardwood within its scaled log reward range, delta=%s expected=%s-%s multiplier=%s." % [hardwood_delta, expected_log_min_buffed, expected_log_max_buffed, expected_log_multiplier])
	_expect(float((game.get("stamina") as Dictionary).get("fight", 0.0)) < stamina_before, "Successful temporary event completion should charge stamina.")
	_expect(str(game.get("running_skill_id")).is_empty(), "Successful temporary event completion should clear the running skill.")
	_expect(str(game.get("running_action_id")).is_empty(), "Successful temporary event completion should clear the running action.")
	_expect(str(game.get("last_result")).begins_with("Event complete:"), "Successful temporary event completion should show event completion feedback text.")
	_expect(str(game.get("last_result")).contains("Hardwood"), "Successful covered wagon feedback should name the awarded highest unlocked log material.")


func _check_combo_xp_reward_map(game: Node) -> void:
	_prime_core_skill_state(game)
	var combo_action := game.call("_action_data", "fishing", "fight-a-shark") as Dictionary
	_expect(not combo_action.is_empty(), "Combo XP test should resolve the fight-a-shark action.")
	var reward_map := _action_runtime(game).call("_completion_xp_reward_map", combo_action, "fishing", false, false, false, false) as Dictionary
	_expect(reward_map.has("fishing") and reward_map.has("fight"), "Combo XP reward map should include both owner and secondary rewarded skills.")
	var level_2_xp := SkillState.xp_for_level(2)
	var skills_state := game.get("skills") as Dictionary
	for reward_skill_id in ["fishing", "fight"]:
		var amount := int(reward_map.get(reward_skill_id, 0))
		_expect(amount > 0, "Combo XP reward amount should be positive for %s." % reward_skill_id)
		var skill_entry := skills_state.get(reward_skill_id, {}) as Dictionary
		skill_entry["xp"] = maxi(0, level_2_xp - amount + 1)
		skill_entry["level"] = SkillState.skill_level_for_xp(int(skill_entry["xp"]))
		skills_state[reward_skill_id] = skill_entry
	game.set("skills", skills_state)
	var old_levels := _action_runtime(game).call("_skill_levels_for_reward_map", "fishing", reward_map) as Dictionary
	var old_xp := {}
	for reward_skill_id in ["fishing", "fight"]:
		var skill_entry := (game.get("skills") as Dictionary).get(reward_skill_id, {}) as Dictionary
		old_xp[reward_skill_id] = int(skill_entry.get("xp", 0))
	var affected := _action_runtime(game).call("_apply_xp_reward_map", "fishing", reward_map) as Array
	var updated_skills := game.get("skills") as Dictionary
	for reward_skill_id in ["fishing", "fight"]:
		_expect(affected.has(reward_skill_id), "Combo XP application should report %s as affected." % reward_skill_id)
		var updated_entry := updated_skills.get(reward_skill_id, {}) as Dictionary
		var expected_xp := int(old_xp.get(reward_skill_id, 0)) + int(reward_map.get(reward_skill_id, 0))
		_expect(int(updated_entry.get("xp", -1)) == expected_xp, "Combo XP application should add XP to %s." % reward_skill_id)
		SkillState.recalculate_level(game, reward_skill_id)
		_expect(int(SkillState.host_skill_level(game, reward_skill_id)) > int(old_levels.get(reward_skill_id, 1)), "Combo XP application should level %s when its reward crosses a threshold." % reward_skill_id)
	_expect(_action_runtime(game).call("_any_reward_skill_leveled_up", affected, old_levels) == true, "Combo XP application should report a level-up when any rewarded skill crosses a threshold.")
	var invalid_affected := _action_runtime(game).call("_apply_xp_reward_map", "fishing", {"not-a-real-skill": 999, "fishing": 1}) as Array
	_expect(not invalid_affected.has("not-a-real-skill") and invalid_affected.has("fishing"), "Combo XP application should ignore unknown reward skills but keep valid ones.")


func _check_hub_module_save_restore(game: Node) -> void:
	var hub_runtime: Object = game.call("_hub_runtime")
	var raw_modules := {
		"barn": {"level": 99, "building": true, "build_started_msec": 1234},
		"pond": {"level": -4, "building": false, "build_started_unix_msec": -55},
		"trophy": {"level": 4, "building": true, "build_started_unix_msec": 999},
		"not-a-real-module": {"level": 4, "building": true, "build_started_unix_msec": 999},
		"garden": "bad-state",
	}
	hub_runtime.set("hub_modules", raw_modules)
	var saved := hub_runtime.call("modules_for_save") as Dictionary
	_expect(saved.size() == 2, "Hub module save should only keep known module definitions with dictionary state.")
	_expect(saved.has("barn") and saved.has("pond"), "Hub module save should preserve valid module ids.")
	_expect(not saved.has("trophy"), "Hub module save should not persist derived trophy state.")
	var barn := saved.get("barn", {}) as Dictionary
	var pond := saved.get("pond", {}) as Dictionary
	_expect(int(barn.get("level", -1)) == 4, "Hub module save should clamp levels to the max module level.")
	_expect(_truthy(barn.get("building", false)), "Hub module save should preserve building state.")
	_expect(int(barn.get("build_started_unix_msec", 0)) == 1234, "Hub module save should accept legacy build_started_msec.")
	_expect(int(pond.get("level", -1)) == 0, "Hub module save should clamp negative levels.")
	_expect(int(pond.get("build_started_unix_msec", -1)) == 0, "Hub module save should clamp negative build timestamps.")

	hub_runtime.set("hub_modules", {"barn": {"level": 1, "building": false}})
	hub_runtime.call("restore_modules", "bad-entry")
	var restored := hub_runtime.get("hub_modules") as Dictionary
	_expect(restored.is_empty(), "Hub module restore should clear malformed saved module data.")
	hub_runtime.call("restore_modules", raw_modules)
	restored = hub_runtime.get("hub_modules") as Dictionary
	_expect(restored.size() == 2, "Hub module restore should only keep known module definitions with dictionary state.")
	_expect(restored.has("barn") and restored.has("pond"), "Hub module restore should preserve valid module ids.")
	var restored_barn := restored.get("barn", {}) as Dictionary
	_expect(int(restored_barn.get("level", -1)) == 4, "Hub module restore should clamp levels to the max module level.")
	_expect(int(restored_barn.get("build_started_unix_msec", 0)) == 1234, "Hub module restore should accept legacy build_started_msec.")


func _check_hub_module_position_save_restore(game: Node) -> void:
	var hub_surface: Object = game.call("_hub_surface")
	hub_surface.set("hub_module_positions", {
		"barn": Vector2(-100, -100),
		"trophy": Vector2(99999, 99999),
		"not-a-real-module": Vector2(500, 500),
	})
	var saved := hub_surface.call("_hub_module_positions_for_save") as Dictionary
	_expect(saved.size() == 2, "Hub position save should only keep storable module ids.")
	_expect(saved.has("barn") and saved.has("trophy"), "Hub position save should preserve valid stored module ids.")
	var barn := saved.get("barn", {}) as Dictionary
	var trophy := saved.get("trophy", {}) as Dictionary
	_expect(float(barn.get("x", 0.0)) == 160.0 and float(barn.get("y", 0.0)) == 180.0, "Hub position save should clamp low coordinates.")
	_expect(float(trophy.get("x", 0.0)) == 2000.0, "Hub position save should clamp high x coordinates.")

	hub_surface.set("hub_module_positions", {"barn": Vector2(300, 300)})
	hub_surface.call("_restore_hub_module_positions", "bad-entry")
	var restored := hub_surface.get("hub_module_positions") as Dictionary
	_expect(restored.is_empty(), "Hub position restore should clear malformed saved position data.")
	hub_surface.call("_restore_hub_module_positions", {
		"barn": {"x": -100, "y": -100},
		"mission": {"x": 500, "y": 600},
		"trophy": {"x": 99999, "y": 99999},
		"not-a-real-module": {"x": 500, "y": 500},
	})
	restored = hub_surface.get("hub_module_positions") as Dictionary
	_expect(restored.size() == 3, "Hub position restore should only keep storable module ids.")
	_expect(restored.has("barn") and restored.has("mission") and restored.has("trophy"), "Hub position restore should preserve valid saved module ids.")
	var restored_barn := restored.get("barn", Vector2.ZERO) as Vector2
	var restored_mission := restored.get("mission", Vector2.ZERO) as Vector2
	_expect(restored_barn == Vector2(160, 180), "Hub position restore should clamp low coordinates.")
	_expect(restored_mission == Vector2(500, 600), "Hub position restore should preserve in-bounds coordinates.")


func _check_hub_decor_layout_save_restore(game: Node) -> void:
	var hub_surface: Object = game.call("_hub_surface")
	game.leaderboard_profile.player_id = "testdecorplayer"
	var raw_layout := [
		{"type": "tree", "index": 99, "x": -100, "y": -100, "w": 10, "h": 10},
		{"type": "decor", "index": 99, "x": 500, "y": 500, "w": 999, "h": 999},
		{"type": "bad-type", "index": 4, "x": 20, "y": 20, "w": 100, "h": 100},
		"bad-entry",
	]
	hub_surface.set("hub_decor_layout", raw_layout)
	var saved := hub_surface.call("_normalized_hub_decor_layout", hub_surface.get("hub_decor_layout")) as Array
	_expect(saved.size() == 2, "Hub decor save should only keep valid decor entry types.")
	var tree := saved[0] as Dictionary
	var decor := saved[1] as Dictionary
	_expect(str(tree.get("type", "")) == "tree", "Hub decor save should preserve tree entries.")
	_expect(int(tree.get("index", -1)) == 5, "Hub decor save should clamp tree sprite indexes.")
	_expect(float(tree.get("w", 0.0)) == 80.0 and float(tree.get("h", 0.0)) == 80.0, "Hub decor save should clamp tiny decor sizes.")
	_expect(float(tree.get("x", 0.0)) >= 46.0 and float(tree.get("y", 0.0)) >= 80.0, "Hub decor save should clamp tree positions into the field.")
	_expect(str(decor.get("type", "")) == "decor", "Hub decor save should preserve decor entries.")
	_expect(int(decor.get("index", -1)) == 15, "Hub decor save should clamp decor sprite indexes.")
	_expect(float(decor.get("w", 0.0)) == 460.0 and float(decor.get("h", 0.0)) == 460.0, "Hub decor save should clamp oversized decor sizes.")

	hub_surface.set("hub_decor_layout", [{"type": "tree", "index": 1, "x": 100, "y": 100, "w": 120, "h": 120}])
	hub_surface.call("_restore_hub_decor_layout", "bad-entry")
	var restored := hub_surface.get("hub_decor_layout") as Array
	_expect(restored.is_empty(), "Hub decor restore should clear malformed saved decor data.")
	hub_surface.call("_restore_hub_decor_layout", raw_layout)
	restored = hub_surface.get("hub_decor_layout") as Array
	_expect(restored.size() == 2, "Hub decor restore should only keep valid decor entry types.")
	tree = restored[0] as Dictionary
	_expect(int(tree.get("index", -1)) == 5, "Hub decor restore should clamp tree sprite indexes.")
	_expect(float(tree.get("x", 0.0)) >= 46.0 and float(tree.get("y", 0.0)) >= 80.0, "Hub decor restore should clamp tree positions into the field.")


func _check_hub_mission_save_restore(game: Node) -> void:
	var hub_runtime: Object = game.call("_hub_runtime")
	game.set("skills", {
		"fight": {"xp": SkillState.xp_for_level(10), "level": 1},
		"woodcutting": {"xp": -99, "level": 99},
		"not-a-real-skill": {"xp": 9999, "level": 99},
	})
	var raw_missions := [
		{"skill_id": "fight", "action_id": "push-ups", "target": 3, "remaining": 99, "assigned_unix": -5},
		{"skill_id": "fight", "action_id": "not-a-real-action", "target": 3, "remaining": 2},
		{"skill_id": "woodcutting", "action_id": "stack-logs-1", "target": 3, "remaining": 2},
		"bad-entry",
	]
	hub_runtime.set("hub_missions", raw_missions)
	var saved := hub_runtime.call("missions_for_save") as Array
	_expect(saved.size() == 1, "Hub mission save should only keep valid unlocked non-passive missions.")
	var saved_mission := saved[0] as Dictionary
	_expect(str(saved_mission.get("skill_id", "")) == "fight", "Hub mission save should preserve the mission skill.")
	_expect(str(saved_mission.get("action_id", "")) == "push-ups", "Hub mission save should preserve the canonical mission action.")
	_expect(int(saved_mission.get("target", 0)) == 3, "Hub mission save should preserve the target count.")
	_expect(int(saved_mission.get("remaining", 0)) == 3, "Hub mission save should clamp remaining count to the target.")
	_expect(int(saved_mission.get("assigned_unix", -1)) == 0, "Hub mission save should clamp negative assignment timestamps.")

	hub_runtime.set("hub_missions", [{"skill_id": "fight", "action_id": "push-ups", "target": 1, "remaining": 1}])
	hub_runtime.call("restore_missions", "bad-entry")
	var restored := hub_runtime.get("hub_missions") as Array
	_expect(restored.is_empty(), "Hub mission restore should clear malformed saved mission data.")
	hub_runtime.call("restore_missions", raw_missions)
	restored = hub_runtime.get("hub_missions") as Array
	_expect(restored.size() == 1, "Hub mission restore should only keep valid unlocked non-passive missions.")
	var restored_mission := restored[0] as Dictionary
	_expect(str(restored_mission.get("action_id", "")) == "push-ups", "Hub mission restore should preserve the canonical mission action.")
	_expect(int(restored_mission.get("remaining", 0)) == 3, "Hub mission restore should clamp remaining count to the target.")


func _check_leaderboard_scores_save(game: Node) -> void:
	var leaderboard_state = game.get("leaderboard_state")
	game.leaderboard_state.last_submitted_scores_by_category = {
		"skill_xp:fight": 40,
		"unknown-category": 99,
		"total_level": 12,
		"medals_earned": -5,
	}
	var saved := leaderboard_state.call("last_submitted_scores_for_save") as Dictionary
	_expect(int(saved.get("skill_xp:fight", 0)) == 40, "Leaderboard category save should preserve valid category scores.")
	_expect(int(saved.get("total_level", 0)) == 99, "Leaderboard category save should fold unknown categories into the canonical default category.")
	_expect(int(saved.get("medals_earned", -1)) == 0, "Leaderboard category save should clamp negative scores.")
	_expect(not saved.has("unknown-category"), "Leaderboard category save should not preserve unknown category keys.")
	leaderboard_state.call("restore_submission_metadata_from_save", {
		"leaderboard_last_submitted_score": -10,
		"leaderboard_last_submitted_total_xp": -20,
		"leaderboard_last_submitted_scores_by_category": "bad-scores",
		"leaderboard_last_submit_unix": -30
	})
	_expect(int(game.leaderboard_state.last_submitted_score) == 0, "Leaderboard submission restore should clamp negative last scores.")
	_expect(int(game.leaderboard_state.last_submitted_total_xp) == 0, "Leaderboard submission restore should clamp negative total XP.")
	_expect((game.leaderboard_state.last_submitted_scores_by_category as Dictionary).is_empty(), "Leaderboard submission restore should clear malformed category scores.")
	_expect(int(game.leaderboard_state.last_submit_unix) == 0, "Leaderboard submission restore should clamp negative submit timestamps.")
	leaderboard_state.call("restore_submission_metadata_from_save", {
		"leaderboard_last_submitted_score": 12,
		"leaderboard_last_submitted_scores_by_category": {
			"skill_xp:fight": 40,
			"unknown-category": 99,
			"total_level": 12,
			"medals_earned": -5
		},
		"leaderboard_last_submit_unix": 1234
	})
	var restored_scores := game.leaderboard_state.last_submitted_scores_by_category as Dictionary
	_expect(int(game.leaderboard_state.last_submitted_total_xp) == 12, "Leaderboard submission restore should default missing total XP from the restored last score.")
	_expect(int(restored_scores.get("skill_xp:fight", 0)) == 40, "Leaderboard submission restore should preserve valid category scores.")
	_expect(int(restored_scores.get("total_level", 0)) == 99, "Leaderboard submission restore should merge duplicate canonical category scores by max.")
	_expect(int(restored_scores.get("medals_earned", -1)) == 0, "Leaderboard submission restore should clamp negative category scores.")
	_expect(not restored_scores.has("unknown-category"), "Leaderboard submission restore should not preserve unknown category keys.")
	game.leaderboard_state.last_submitted_scores_by_category = {
		"total_level": 1200,
	}
	saved = leaderboard_state.call("last_submitted_scores_for_save") as Dictionary
	_expect(int(saved.get("total_level", -1)) == 0, "Leaderboard category save should reset legacy XP-shaped Total Level scores.")
	leaderboard_state.call("restore_submission_metadata_from_save", {
		"leaderboard_last_submitted_scores_by_category": {
			"total_level": 1200,
		},
	})
	restored_scores = game.leaderboard_state.last_submitted_scores_by_category as Dictionary
	_expect(int(restored_scores.get("total_level", -1)) == 0, "Leaderboard submission restore should reset legacy XP-shaped Total Level scores.")


func _check_leaderboard_profile_auth_save_restore(game: Node) -> void:
	game.leaderboard_state.last_submitted_score = -10
	game.leaderboard_state.last_submitted_total_xp = -20
	game.leaderboard_state.last_submit_unix = -30
	game.leaderboard_profile.display_name = "  A\nName\tThat Is Too Long For Profile  "
	game.leaderboard_profile.name_key = " Bad Key! "
	game.leaderboard_profile.profile_claimed = true
	game.leaderboard_profile.name_claim_verified = false
	game.leaderboard_profile.avatar_index = 999
	game.leaderboard_profile.player_id = " bad id! "
	game.call("_online_runtime").leaderboard_auth_refresh_token = "  refresh-token  "
	game.call("_online_runtime").leaderboard_auth_retry_after_unix = -40
	_expect(int(_save_payload_value(game, "leaderboard_last_submitted_score")) == 0, "Leaderboard last score save should clamp negative values.")
	_expect(int(_save_payload_value(game, "leaderboard_last_submitted_total_xp")) == 0, "Leaderboard last total XP save should clamp negative values.")
	_expect(int(_save_payload_value(game, "leaderboard_last_submit_unix")) == 0, "Leaderboard submit timestamp save should clamp negative values.")
	_expect(str(_save_payload_value(game, "leaderboard_display_name")) == "A Name That Is T", "Leaderboard display-name save should sanitize and truncate names.")
	_expect(str(_save_payload_value(game, "leaderboard_name_key")).is_empty(), "Leaderboard name-key save should drop invalid keys.")
	_expect(not _truthy(_save_payload_value(game, "leaderboard_profile_claimed")), "Leaderboard profile save should clear unverified claims.")
	_expect(not _truthy(_save_payload_value(game, "leaderboard_name_claim_verified")), "Leaderboard profile save should clear unverified claim verification.")

	game.leaderboard_profile.display_name = "Mira Stone"
	game.leaderboard_profile.name_key = ""
	game.leaderboard_profile.profile_claimed = true
	game.leaderboard_profile.name_claim_verified = true
	_expect(str(_save_payload_value(game, "leaderboard_name_key")) == "mira_stone", "Leaderboard profile save should derive a missing verified claim key from the display name.")
	_expect(_truthy(_save_payload_value(game, "leaderboard_profile_claimed")), "Leaderboard profile save should preserve valid verified claims.")
	_expect(_truthy(_save_payload_value(game, "leaderboard_name_claim_verified")), "Leaderboard profile save should preserve valid claim verification.")

	game.leaderboard_profile.display_name = "guest1234"
	game.leaderboard_profile.name_key = "guest1234"
	game.leaderboard_profile.profile_claimed = true
	game.leaderboard_profile.name_claim_verified = true
	_expect(str(_save_payload_value(game, "leaderboard_name_key")).is_empty(), "Leaderboard profile save should not persist guest name keys.")
	_expect(not _truthy(_save_payload_value(game, "leaderboard_profile_claimed")), "Leaderboard profile save should clear guest profile claims.")
	_expect(not _truthy(_save_payload_value(game, "leaderboard_name_claim_verified")), "Leaderboard profile save should clear guest profile verification.")

	_expect(int(_save_payload_value(game, "leaderboard_avatar_index")) == 19, "Leaderboard avatar save should clamp to a valid avatar index.")
	_expect(str(_save_payload_value(game, "leaderboard_player_id")).is_empty(), "Leaderboard player-id save should drop invalid ids.")
	_expect(str(_save_payload_value(game, "leaderboard_auth_refresh_token")) == "refresh-token", "Leaderboard refresh-token save should strip whitespace.")
	_expect(int(_save_payload_value(game, "leaderboard_auth_retry_after_unix")) == 0, "Leaderboard auth retry save should clamp negative timestamps.")

	LeaderboardProfile.restore_profile_metadata_from_save(game, {
		"leaderboard_display_name": "Mira Stone",
		"leaderboard_name_key": "",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
		"leaderboard_avatar_index": 999,
		"leaderboard_player_id": " bad id! ",
	}, game.PROFILE_GUEST_NAME_PREFIX, game.PROFILE_DISPLAY_NAME_MAX_CHARS, game.PROFILE_NAME_KEY_MAX_CHARS, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT)
	_expect(str(game.leaderboard_profile.display_name) == "Mira Stone", "Leaderboard profile restore should preserve valid display names.")
	_expect(str(game.leaderboard_profile.name_key) == "mira_stone", "Leaderboard profile restore should derive missing verified claim keys.")
	_expect(_truthy(game.leaderboard_profile.profile_claimed) and _truthy(game.leaderboard_profile.name_claim_verified), "Leaderboard profile restore should preserve valid verified claims.")
	_expect(int(game.leaderboard_profile.avatar_index) == 19, "Leaderboard profile restore should clamp avatar indexes.")
	var generated_player_id := str(game.leaderboard_profile.player_id)
	_expect(not generated_player_id.is_empty() and generated_player_id != " bad id! ", "Leaderboard profile restore should regenerate invalid player ids.")

	LeaderboardProfile.restore_profile_metadata_from_save(game, {
		"leaderboard_display_name": "guest1234",
		"leaderboard_name_key": "guest1234",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
	}, game.PROFILE_GUEST_NAME_PREFIX, game.PROFILE_DISPLAY_NAME_MAX_CHARS, game.PROFILE_NAME_KEY_MAX_CHARS, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT)
	_expect(str(game.leaderboard_profile.name_key).is_empty(), "Leaderboard profile restore should clear guest name keys.")
	_expect(not _truthy(game.leaderboard_profile.profile_claimed) and not _truthy(game.leaderboard_profile.name_claim_verified), "Leaderboard profile restore should clear guest profile claims.")

	LeaderboardProfile.restore_profile_metadata_from_save(game, {
		"leaderboard_display_name": "Mira Stone",
		"leaderboard_name_key": "mira_stone",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": false,
	}, game.PROFILE_GUEST_NAME_PREFIX, game.PROFILE_DISPLAY_NAME_MAX_CHARS, game.PROFILE_NAME_KEY_MAX_CHARS, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT)
	_expect(str(game.leaderboard_profile.name_key).is_empty(), "Leaderboard profile restore should clear unverified claim keys.")
	_expect(not _truthy(game.leaderboard_profile.profile_claimed), "Leaderboard profile restore should clear unverified profile claims.")
	LeaderboardProfile.restore_profile_metadata_from_save(game, {
		"leaderboard_player_id": "player_1234",
	}, game.PROFILE_GUEST_NAME_PREFIX, game.PROFILE_DISPLAY_NAME_MAX_CHARS, game.PROFILE_NAME_KEY_MAX_CHARS, ProfileChatOverlaySurface.PROFILE_AVATAR_COUNT)
	_expect(str(game.leaderboard_profile.player_id) == "player_1234", "Leaderboard profile restore should preserve valid player ids.")

	game.call("_online_runtime").leaderboard_auth_id_token = "stale-id-token"
	game.call("_online_runtime").leaderboard_auth_refresh_token = "stale-refresh-token"
	game.call("_online_runtime").leaderboard_auth_expires_unix = 999999
	game.call("_online_runtime").leaderboard_auth_retry_after_unix = 123
	game.call("_online_runtime").leaderboard_auth_provider = "stale-provider"
	LeaderboardProfile.restore_auth_metadata_from_save(game, {
		"leaderboard_auth_refresh_token": "  refresh-token  ",
		"leaderboard_auth_retry_after_unix": -40,
		"leaderboard_auth_provider": "google",
	})
	_expect(str(game.call("_online_runtime").leaderboard_auth_id_token).is_empty(), "Leaderboard auth restore should clear volatile id tokens.")
	_expect(str(game.call("_online_runtime").leaderboard_auth_refresh_token) == "refresh-token", "Leaderboard auth restore should trim refresh tokens.")
	_expect(int(game.call("_online_runtime").leaderboard_auth_expires_unix) == 0, "Leaderboard auth restore should clear volatile token expiry.")
	_expect(int(game.call("_online_runtime").leaderboard_auth_retry_after_unix) == 0, "Leaderboard auth restore should clamp retry timestamps.")
	_expect(str(game.call("_online_runtime").leaderboard_auth_provider) == "google", "Leaderboard auth restore should preserve Google account providers.")
	LeaderboardProfile.restore_auth_metadata_from_save(game, {
		"leaderboard_auth_provider": "stale-provider",
	})
	_expect(str(game.call("_online_runtime").leaderboard_auth_provider) == "anonymous", "Leaderboard auth restore should normalize unknown providers.")


func _check_leaderboard_fetch_retry_save_restore(game: Node) -> void:
	var leaderboard_state = game.get("leaderboard_state")
	leaderboard_state.set("fetch_retry_unix_by_category", {
		"skill_xp:fight": 40,
		"unknown-category": 99,
		"total_level": 12,
		"medals_earned": -5,
	})
	var saved := leaderboard_state.call("fetch_retry_unix_by_category_for_save") as Dictionary
	_expect(int(saved.get("skill_xp:fight", 0)) == 40, "Leaderboard fetch retry save should preserve valid category cooldowns.")
	_expect(int(saved.get("total_level", 0)) == 99, "Leaderboard fetch retry save should keep the highest cooldown for duplicate canonical categories.")
	_expect(int(saved.get("medals_earned", -1)) == 0, "Leaderboard fetch retry save should clamp negative retry timestamps.")
	_expect(not saved.has("unknown-category"), "Leaderboard fetch retry save should not preserve unknown category keys.")

	leaderboard_state.set("fetch_retry_unix_by_category", {"skill_xp:fight": 1})
	leaderboard_state.call("restore_fetch_retry_unix_by_category_from_save", "bad-entry")
	var restored := leaderboard_state.get("fetch_retry_unix_by_category") as Dictionary
	_expect(restored.is_empty(), "Leaderboard fetch retry restore should clear malformed saved retry data.")
	leaderboard_state.call("restore_fetch_retry_unix_by_category_from_save", {
		"skill_xp:fight": 40,
		"unknown-category": 99,
		"total_level": 12,
		"medals_earned": -5,
	})
	restored = leaderboard_state.get("fetch_retry_unix_by_category") as Dictionary
	_expect(int(restored.get("skill_xp:fight", 0)) == 40, "Leaderboard fetch retry restore should preserve valid category cooldowns.")
	_expect(int(restored.get("total_level", 0)) == 99, "Leaderboard fetch retry restore should keep the highest cooldown for duplicate canonical categories.")
	_expect(int(restored.get("medals_earned", -1)) == 0, "Leaderboard fetch retry restore should clamp negative retry timestamps.")
	_expect(not restored.has("unknown-category"), "Leaderboard fetch retry restore should not preserve unknown category keys.")
	leaderboard_state.set("fetch_unix_by_category", {"skill_xp:fight": 1234})
	leaderboard_state.call("restore_fetch_metadata_from_save", {
		"leaderboard_fetch_retry_unix_by_category": {
			"skill_xp:fight": 40,
			"unknown-category": 99
		}
	})
	_expect((leaderboard_state.get("fetch_unix_by_category") as Dictionary).is_empty(), "Leaderboard fetch metadata restore should clear unsaved successful fetch timestamps.")
	restored = leaderboard_state.get("fetch_retry_unix_by_category") as Dictionary
	_expect(int(restored.get("skill_xp:fight", 0)) == 40, "Leaderboard fetch metadata restore should preserve retry cooldowns.")
	_expect(int(restored.get("total_level", 0)) == 99, "Leaderboard fetch metadata restore should canonicalize retry cooldown categories.")


func _check_chat_metadata_save_restore(game: Node) -> void:
	var now := int(game.call("_unix_now"))
	var long_id := "  abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij-extra  "
	var chat_runtime = game.call("_online_runtime")
	chat_runtime.set("chat_last_send_unix", -10)
	chat_runtime.set("chat_stream_retry_unix", now + 9999)
	chat_runtime.set("chat_stream_next_connect_unix", -5)
	chat_runtime.set("chat_last_opened_created_at", -20)
	chat_runtime.set("chat_last_opened_message_id", long_id)
	_expect(int(_save_payload_value(game, "chat_last_send_unix")) == 0, "Chat last-send save should clamp negative timestamps.")
	_expect(int(_save_payload_value(game, "chat_stream_retry_unix")) == now + 30, "Chat retry save should cap future retry timestamps.")
	_expect(int(_save_payload_value(game, "chat_stream_next_connect_unix")) == now + 30, "Chat next-connect save should stay at least the retry timestamp and cap future timestamps.")
	_expect(int(_save_payload_value(game, "chat_last_opened_created_at")) == 0, "Chat opened cursor save should clamp negative timestamps.")
	var saved_id := str(_save_payload_value(game, "chat_last_opened_message_id"))
	_expect(saved_id.length() == 64, "Chat opened message id save should truncate long ids.")
	_expect(saved_id.begins_with("abcdefghij"), "Chat opened message id save should strip surrounding whitespace.")

	chat_runtime.set("chat_last_send_unix", 12)
	ChatState.restore_metadata_to_runtime(chat_runtime, {"chat_last_send_unix": -10}, now, game.CHAT_STREAM_RETRY_INTERVAL_SECONDS)
	_expect(int(chat_runtime.get("chat_last_send_unix")) == 0, "Chat last-send restore should clamp negative timestamps.")
	ChatState.restore_metadata_to_runtime(chat_runtime, {"chat_last_send_unix": now}, now, game.CHAT_STREAM_RETRY_INTERVAL_SECONDS)
	_expect(int(chat_runtime.get("chat_last_send_unix")) == now, "Chat last-send restore should preserve nonnegative timestamps.")

	chat_runtime.set("chat_stream_retry_unix", 0)
	chat_runtime.set("chat_stream_next_connect_unix", 0)
	ChatState.restore_metadata_to_runtime(chat_runtime, {
		"chat_stream_retry_unix": now + 9999,
		"chat_stream_next_connect_unix": -5,
	}, now, game.CHAT_STREAM_RETRY_INTERVAL_SECONDS)
	_expect(int(chat_runtime.get("chat_stream_retry_unix")) == now + 30, "Chat retry restore should cap future retry timestamps.")
	_expect(int(chat_runtime.get("chat_stream_next_connect_unix")) == now + 30, "Chat next-connect restore should stay at least the restored retry timestamp.")

	chat_runtime.set("chat_stream_retry_unix", 0)
	chat_runtime.set("chat_stream_next_connect_unix", 0)
	ChatState.restore_metadata_to_runtime(chat_runtime, {
		"chat_fetch_retry_unix": now + 10,
		"chat_stream_next_connect_unix": now + 5,
	}, now, game.CHAT_STREAM_RETRY_INTERVAL_SECONDS)
	_expect(int(chat_runtime.get("chat_stream_retry_unix")) == now + 10, "Chat retry restore should accept legacy fetch retry timestamps.")
	_expect(int(chat_runtime.get("chat_stream_next_connect_unix")) == now + 10, "Chat next-connect restore should not precede legacy retry timestamps.")

	chat_runtime.set("chat_last_opened_created_at", 12)
	chat_runtime.set("chat_last_opened_message_id", "old")
	ChatState.restore_metadata_to_runtime(chat_runtime, {
		"chat_last_opened_created_at": -20,
		"chat_last_opened_message_id": long_id,
	}, now, game.CHAT_STREAM_RETRY_INTERVAL_SECONDS)
	_expect(int(chat_runtime.get("chat_last_opened_created_at")) == 0, "Chat opened cursor restore should clamp negative timestamps.")
	var restored_id := str(chat_runtime.get("chat_last_opened_message_id"))
	_expect(restored_id.length() == 64, "Chat opened message id restore should truncate long ids.")
	_expect(restored_id.begins_with("abcdefghij"), "Chat opened message id restore should strip surrounding whitespace.")


func _check_resource_and_audio_settings_save(game: Node) -> void:
	game.material_runtime.legacy_softwood_amount = -20
	_expect(int(_save_payload_value(game, "log_currency")) == 0, "Log currency save should clamp negative values.")
	var audio := game.call("_audio_director") as AudioDirector
	audio.music_volume = 1.5
	_expect(float(_save_payload_value(game, "music_volume")) == 1.0, "Music volume save should cap values above one.")
	audio.music_volume = -0.25
	_expect(float(_save_payload_value(game, "music_volume")) == 0.0, "Music volume save should clamp negative values.")
	audio.sfx_volume = 1.25
	_expect(float(_save_payload_value(game, "sfx_volume")) == 1.0, "SFX volume save should cap values above one.")
	audio.sfx_volume = -0.5
	_expect(float(_save_payload_value(game, "sfx_volume")) == 0.0, "SFX volume save should clamp negative values.")
	game.set("auto_unlock_lockpads_enabled", true)
	var payload := _save_payload(game, int(game.call("_unix_now")))
	_expect(_truthy(payload.get("auto_unlock_lockpads_enabled", false)), "Auto-unlock lockpad setting should be saved when enabled.")
	game.set("show_stamina_decimal", true)
	payload = _save_payload(game, int(game.call("_unix_now")))
	_expect(_truthy(payload.get("show_stamina_decimal", false)), "Stamina decimal setting should be saved when enabled.")


func _check_audio_settings_restore(game: Node) -> void:
	var audio := game.call("_audio_director") as AudioDirector
	audio.music_volume = 0.82
	audio.sfx_volume = 0.70
	audio.apply_settings_from_save({
		"audio_settings_version": 1,
		"music_volume": 0.31,
		"sfx_volume": 0.44,
	})
	_expect(is_equal_approx(float(audio.music_volume), 0.31), "Audio restore should preserve old-version saved music slider values.")
	_expect(is_equal_approx(float(audio.sfx_volume), 0.44), "Audio restore should preserve old-version saved SFX slider values.")

	audio.apply_settings_from_save({})
	_expect(is_equal_approx(float(audio.music_volume), 0.55), "Audio restore should use the calmer default music level when no saved value exists.")
	_expect(is_equal_approx(float(audio.sfx_volume), 0.65), "Audio restore should use the default SFX level when no saved value exists.")

	audio.apply_settings_from_save({
		"music_volume": "loud",
		"sfx_volume": 2.0,
	})
	_expect(is_equal_approx(float(audio.music_volume), 0.55), "Audio restore should reject malformed music volume values.")
	_expect(is_equal_approx(float(audio.sfx_volume), 1.0), "Audio restore should clamp oversized SFX volume values.")

	_prime_core_skill_state(game)
	game.set("auto_unlock_lockpads_enabled", false)
	game.set("show_stamina_decimal", false)
	game.call("_save_runtime").call("_load_game_core", {
		"auto_unlock_lockpads_enabled": true,
		"show_stamina_decimal": true,
		"offline_clock_guard_tainted": true,
		"offline_clock_guard_last_rejected_unix": 123,
		"skills": {},
		"stamina": {},
		"stamina_bank": {},
		"saved_at": int(game.call("_unix_now")),
	})
	_expect(_truthy(game.get("auto_unlock_lockpads_enabled")), "Auto-unlock lockpad setting should restore when present.")
	_expect(_truthy(game.get("show_stamina_decimal")), "Stamina decimal setting should restore when present.")
	var migrated_payload := _save_payload(game, int(game.call("_unix_now")))
	_expect(not migrated_payload.has("offline_clock_guard_tainted"), "Old offline clock guard taint should be dropped when existing saves are written again.")
	_expect(not migrated_payload.has("offline_clock_guard_last_rejected_unix"), "Old offline clock guard rejection timestamps should be dropped when existing saves are written again.")

	game.leaderboard_state.last_submitted_score = 50
	game.leaderboard_state.last_submitted_total_xp = 5000
	game.leaderboard_state.last_submitted_scores_by_category = {"total_level": 50, "skill_xp__fight": 1000}
	game.leaderboard_state.last_submit_unix = int(game.call("_unix_now"))
	game.call("_online_runtime").leaderboard_auth_retry_after_unix = int(game.call("_unix_now")) + 999
	var chat_runtime = game.call("_online_runtime")
	chat_runtime.set("chat_last_send_unix", int(game.call("_unix_now")))
	chat_runtime.set("chat_stream_retry_unix", int(game.call("_unix_now")) + 999)
	chat_runtime.set("chat_stream_next_connect_unix", int(game.call("_unix_now")) + 999)
	game.set("last_result", "Offline progress paused: device clock changed too quickly.")
	game.call("_save_runtime").call("_apply_legacy_clock_guard_leaderboard_forgiveness", {
		"offline_clock_guard_tainted": true,
		"offline_clock_guard_last_rejected_unix": 123,
	})
	_expect(int(game.leaderboard_state.last_submitted_score) == 0, "Forgiven clock-guard saves should republish total leaderboard score.")
	_expect(int(game.leaderboard_state.last_submitted_total_xp) == 0, "Forgiven clock-guard saves should republish total XP compatibility score.")
	_expect((game.leaderboard_state.last_submitted_scores_by_category as Dictionary).is_empty(), "Forgiven clock-guard saves should republish every leaderboard category.")
	_expect(int(game.leaderboard_state.last_submit_unix) == 0, "Forgiven clock-guard saves should clear leaderboard submit cooldown.")
	_expect(int(game.call("_online_runtime").leaderboard_auth_retry_after_unix) == 0, "Forgiven clock-guard saves should clear leaderboard auth retry cooldown.")
	_expect(int(chat_runtime.get("chat_last_send_unix")) == 0, "Forgiven clock-guard saves should clear chat send cooldown.")
	_expect(int(chat_runtime.get("chat_stream_retry_unix")) == 0, "Forgiven clock-guard saves should clear chat stream retry cooldown.")
	_expect(str(game.get("last_result")).is_empty(), "Forgiven clock-guard saves should remove the old clock warning result text.")

	_prime_core_skill_state(game)
	game.set("auto_unlock_lockpads_enabled", true)
	game.set("show_stamina_decimal", true)
	game.call("_save_runtime").call("_load_game_core", {
		"skills": {},
		"stamina": {},
		"stamina_bank": {},
		"saved_at": int(game.call("_unix_now")),
	})
	_expect(not _truthy(game.get("auto_unlock_lockpads_enabled")), "Auto-unlock lockpad setting should default off for existing saves.")
	_expect(not _truthy(game.get("show_stamina_decimal")), "Stamina decimal setting should default off for new saves.")


func _check_god_mode_save(game: Node) -> void:
	game.set("god_mode_enabled", true)
	_expect(_truthy(_save_payload_value(game, "god_mode_enabled")), "Debug saves should preserve enabled God Mode.")


func _check_test_profile_save_repair(game: Node) -> void:
	var save_runtime = game.call("_save_runtime")
	var tainted_save := {"god_mode_save_tainted": true, "god_mode_enabled": true}
	_expect(not _truthy(save_runtime.call("_repair_save_for_regular_play", tainted_save)), "Debug builds should not repair an explicit God Mode test save.")
	_expect(_truthy(tainted_save.get("god_mode_save_tainted", false)) and _truthy(tainted_save.get("god_mode_enabled", false)), "Debug builds should preserve test-only save markers.")
	var maxed_skills := {}
	var played_maxed_skills := {}
	var level_99_xp := SkillState.xp_for_level(99)
	for raw_def in (game.get("skill_defs") as Array):
		var skill_id := str((raw_def as Dictionary).get("id", ""))
		if skill_id.is_empty():
			continue
		maxed_skills[skill_id] = {"xp": level_99_xp, "level": 99}
		played_maxed_skills[skill_id] = {"xp": level_99_xp + 1234, "level": 99}
	var maxed_save := {
		"skills": maxed_skills,
		"activity_completion_count": 10,
		"manual_activity_unlocks": {
			"fight:kick-mud-off-boot": true,
			"build:stack-bricks": true,
		},
	}
	_expect(_truthy(save_runtime.call("_repair_save_for_regular_play", maxed_save)), "Regular builds should repair unmarked all-99 test saves with low play evidence.")
	var repaired_skills := maxed_save.get("skills", {}) as Dictionary
	for raw_skill_id in repaired_skills.keys():
		var repaired_skill := repaired_skills.get(raw_skill_id, {}) as Dictionary
		_expect(int(repaired_skill.get("level", 99)) < 99, "All-99 repair should lower suspicious maxed skill levels without discarding the save.")
		_expect(int(repaired_skill.get("xp", level_99_xp)) < level_99_xp, "All-99 repair should lower suspicious maxed skill XP without discarding the save.")
	_expect(not maxed_save.has("manual_activity_unlocks"), "All-99 repair should drop generated manual unlock maps.")
	_expect(save_runtime.call("_repair_save_for_regular_play", {
		"onboarding_tutorial_complete": true,
		"skills": played_maxed_skills,
		"activity_completion_count": 999999,
	}) != true, "Regular builds should leave high-evidence all-99 saves alone.")
	_expect(save_runtime.call("_repair_save_for_regular_play", {
		"god_mode_save_tainted": false,
		"god_mode_enabled": false,
	}) != true, "Regular builds should leave clean saves alone.")
	var impossible_trophy_save := {
		"skills": {
			"thieving": {"xp": SkillState.xp_for_level(2), "level": 2},
		},
		"thieving_trophies": {
			"complimentary_spoon": {"stolen": true, "cooldown_until_unix": 44},
			"crown_jewel_replica_replica": {"stolen": false, "cooldown_until_unix": 0},
		},
	}
	_expect(save_runtime.call("_repair_save_for_regular_play", impossible_trophy_save) == true, "Regular builds should repair heist trophies stolen before their Thieving unlock level.")
	var repaired_trophies := impossible_trophy_save.get("thieving_trophies", {}) as Dictionary
	var repaired_spoon := repaired_trophies.get("complimentary_spoon", {}) as Dictionary
	_expect(not _truthy(repaired_spoon.get("stolen", true)), "Impossible Thieving trophy repair should clear stolen state.")
	_expect(int(repaired_spoon.get("cooldown_until_unix", -1)) == 0, "Impossible Thieving trophy repair should clear cooldown state.")
	var valid_trophy_save := {
		"onboarding_tutorial_complete": true,
		"skills": {
			"thieving": {"xp": SkillState.xp_for_level(8), "level": 8},
		},
		"thieving_trophies": {
			"complimentary_spoon": {"stolen": true, "cooldown_until_unix": 0},
		},
	}
	_expect(save_runtime.call("_repair_save_for_regular_play", valid_trophy_save) != true, "Regular builds should keep trophies that match the saved Thieving level.")
	var mixed_tutorial_save := {
		"onboarding_tutorial_complete": false,
		"skills": {
			"fight": {"xp": SkillState.xp_for_level(4), "level": 4},
			"thieving": {"xp": SkillState.xp_for_level(3), "level": 3},
		},
		"manual_activity_unlocks": {
			"fight:kick-mud-off-boot": true,
			"fight:wrestle-stuck-gate-latch": true,
		},
	}
	_expect(save_runtime.call("_repair_save_for_regular_play", mixed_tutorial_save) == true, "Saves with real progress should not remain stuck in tutorial mode.")
	_expect(_truthy(mixed_tutorial_save.get("onboarding_tutorial_complete", false)), "Tutorial-progress mismatch repair should complete onboarding.")
	_expect(_truthy(mixed_tutorial_save.get("skill_swipe_tip_seen", false)), "Tutorial-progress mismatch repair should unlock skill navigation.")
	var latched_tutorial_save := {
		"onboarding_tutorial_complete": false,
		"tutorial_active": true,
		"tutorial_step": 1,
		"skills": {
			"fight": {"xp": SkillState.xp_for_level(2), "level": 2},
		},
		"manual_activity_unlocks": {
			"fight:kick-mud-off-boot": true,
		},
		"stamina_gauge_tip_seen": true,
		"onboarding_fight_action_stats_revealed": true,
	}
	_expect(save_runtime.call("_repair_save_for_regular_play", latched_tutorial_save) != true, "Level-two onboarding saves should no longer need obsolete latch repair.")
	_prime_core_skill_state(game)
	game.call("_onboarding_runtime").set("tutorial_gate_latch_only_until_swipe", false)
	game.call("_save_runtime").call("_load_game_core", latched_tutorial_save)
	save_runtime.call("_restore_onboarding_progression_from_save", latched_tutorial_save)
	var level_two_action := game.call("_action_data", "fight", "kick-mud-off-boot") as Dictionary
	var deferred_action := game.call("_action_data", "fight", "box-suspicious-feed-sack") as Dictionary
	_expect(_truthy(game.call("_onboarding_runtime").get("onboarding_tutorial_complete")), "Level-two onboarding restore should complete inline tutorial saves.")
	_expect(not _truthy(game.call("_onboarding_runtime").get("tutorial_gate_latch_only_until_swipe")), "Level-two onboarding restore should not keep the obsolete boxed swipe latch active.")
	_expect(game.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", level_two_action) == true, "Level-two onboarding latch restore should keep the level 2 fight module visible.")
	_expect(game.call("_onboarding_runtime").call("_tutorial_should_defer_action_until_skill_swipe", "fight", deferred_action) != true, "Level-two onboarding latch restore should not defer post-gate modules after completing the repaired tutorial save.")
	var legacy_save := {"skills": {"fight": {"xp": 40, "level": 2}}}
	var fresh_maxed_skills := {}
	for raw_def in (game.get("skill_defs") as Array):
		var skill_id := str((raw_def as Dictionary).get("id", ""))
		if skill_id.is_empty():
			continue
		fresh_maxed_skills[skill_id] = {"xp": level_99_xp, "level": 99}
	var fresh_maxed_save := {
		"skills": fresh_maxed_skills,
		"activity_completion_count": 10,
	}
	_expect(game.call("_save_runtime").call("_save_should_use_legacy_desktop_recovery", {}, legacy_save) == true, "Missing current desktop saves should recover known legacy desktop progress.")
	_expect(game.call("_save_runtime").call("_save_should_use_legacy_desktop_recovery", fresh_maxed_save, legacy_save) != true, "Suspicious current desktop saves should be repaired in place instead of recovering legacy desktop progress.")
	_expect(game.call("_save_runtime").call("_save_should_use_legacy_desktop_recovery", legacy_save, legacy_save) != true, "Clean current desktop saves should not be replaced by legacy saves.")
	_expect(game.call("_save_runtime").call("_save_should_use_legacy_desktop_recovery", {}, {"skills": fresh_maxed_skills}) != true, "Legacy all-99 saves should not be used for recovery.")
	var old_curve_legacy := {"skills": {"fight": {"xp": level_99_xp, "level": 7}}}
	game.call("_save_runtime").call("_normalize_legacy_desktop_skill_levels", old_curve_legacy)
	var normalized_fight := (old_curve_legacy.get("skills", {}) as Dictionary).get("fight", {}) as Dictionary
	_expect(int(normalized_fight.get("level", 0)) == 7, "Legacy desktop recovery should preserve the saved skill level.")
	_expect(int(normalized_fight.get("xp", -1)) == SkillState.xp_for_level(7), "Legacy desktop recovery should remap old XP to the current level curve.")


func _check_hard_reset_pending_restore_cancel(game: Node) -> void:
	var save_runtime = game.call("_save_runtime")
	save_runtime.set("pending_save_restore_data", {
		"thieving_trophies": {
			"complimentary_spoon": {"stolen": true, "cooldown_until_unix": 44},
		},
		"achievement_toast_seen_ids": {},
	})
	save_runtime.set("pending_save_has_achievement_toast_seen_ids", true)
	save_runtime.set("pending_post_load_saved_at", int(game.call("_unix_now")))
	save_runtime.set("boot_post_load_simulation_scheduled", true)
	save_runtime.set("save_repaired_this_boot", true)
	game.thieving_state.trophies = {}
	save_runtime.call("_clear_pending_save_restore_work")
	save_runtime.call("_load_game_secondary_restore")
	save_runtime.call("_apply_post_load_simulation")
	_expect((save_runtime.get("pending_save_restore_data") as Dictionary).is_empty(), "Hard reset should clear pending secondary save restore data.")
	_expect(int(save_runtime.get("pending_post_load_saved_at")) == -1, "Hard reset should clear pending post-load simulation timestamps.")
	_expect(save_runtime.get("boot_post_load_simulation_scheduled") != true, "Hard reset should cancel scheduled post-load simulation.")
	_expect(save_runtime.get("save_repaired_this_boot") != true, "Hard reset should clear stale save-repair autosave state.")
	var trophies := game.thieving_state.trophies as Dictionary
	_expect(trophies.is_empty(), "Hard reset should prevent delayed save restore from re-adding Thieving trophies.")


func _check_active_skill_identity_save(game: Node) -> void:
	var save_runtime = game.call("_save_runtime")
	game.set("selected_skill_id", "woodcutting")
	_expect(str(save_runtime.call("_selected_skill_id_for_save")) == "woodcutting", "Selected skill save should preserve known skill ids.")
	game.set("selected_skill_id", "not-a-real-skill")
	_expect(str(save_runtime.call("_selected_skill_id_for_save")) == "fight", "Selected skill save should replace unknown skill ids with the default skill.")

	game.set("running_skill_id", "fishing")
	game.set("running_action_id", "dip-a-tidepool-minnow")
	_expect(str(save_runtime.call("_running_skill_id_for_save")) == "fishing", "Running skill save should preserve a known skill with a valid canonical action.")
	game.set("running_skill_id", "fishing")
	game.set("running_action_id", "not-a-real-action")
	_expect(str(save_runtime.call("_running_skill_id_for_save")).is_empty(), "Running skill save should clear a skill with no valid running action.")
	game.set("running_skill_id", "not-a-real-skill")
	game.set("running_action_id", "push-ups")
	_expect(str(save_runtime.call("_running_skill_id_for_save")).is_empty(), "Running skill save should clear unknown skill ids.")


func _check_running_action_save(game: Node) -> void:
	var save_runtime = game.call("_save_runtime")
	game.set("running_skill_id", "fishing")
	game.set("running_action_id", "dip-a-tidepool-minnow")
	_expect(str(save_runtime.call("_running_action_id_for_save")) == "shallows", "Running action save should canonicalize fishing aliases.")
	game.set("running_skill_id", "fight")
	game.set("running_action_id", "not-a-real-action")
	_expect(str(save_runtime.call("_running_action_id_for_save")).is_empty(), "Running action save should drop unknown actions.")


func _check_action_progress_save_restore(game: Node) -> void:
	var save_runtime = game.call("_save_runtime")
	game.set("action_progress", 1.5)
	_expect(float(save_runtime.call("_action_progress_for_save")) == 0.999, "Action progress save should cap progress below completion.")
	game.set("action_progress", -0.25)
	_expect(float(save_runtime.call("_action_progress_for_save")) == 0.0, "Action progress save should clamp negative progress.")

	_prime_core_skill_state(game)
	game.call("_save_runtime").call("_load_game_core", {
		"selected_skill_id": "fight",
		"running_skill_id": "fight",
		"running_action_id": "push-ups",
		"action_progress": 1.5,
		"skills": {},
		"stamina": {},
		"stamina_bank": {},
		"saved_at": int(game.call("_unix_now")),
	})
	_expect(float(game.get("action_progress")) == 0.999, "Action progress restore should cap progress below completion.")

	_prime_core_skill_state(game)
	game.call("_save_runtime").call("_load_game_core", {
		"selected_skill_id": "fight",
		"running_skill_id": "fight",
		"running_action_id": "push-ups",
		"action_progress": -0.25,
		"skills": {},
		"stamina": {},
		"stamina_bank": {},
		"saved_at": int(game.call("_unix_now")),
	})
	_expect(float(game.get("action_progress")) == 0.0, "Action progress restore should clamp negative progress.")


func _check_action_key_save(game: Node) -> void:
	var save_runtime = game.call("_save_runtime")
	_expect(str(save_runtime.call("_action_key_for_save", "fishing:dip-a-tidepool-minnow")) == "fishing:shallows", "Action-key save should canonicalize fishing aliases.")
	_expect(str(save_runtime.call("_action_key_for_save", "woodcutting:stack-logs-1")).is_empty(), "Action-key save should drop passive action keys.")
	_expect(str(save_runtime.call("_action_key_for_save", "malformed-key")).is_empty(), "Action-key save should drop malformed keys.")
	_expect(str(save_runtime.call("_action_key_for_save", "fight:not-a-real-action")).is_empty(), "Action-key save should drop unknown action keys.")
	save_runtime.call("_restore_tip_metadata_from_save", {
		"lock_click_tip_seen": true,
		"passive_module_tip_seen": true,
		"silver_opportunity_tip_seen": true,
		"silver_opportunity_tip_action_key": "fishing:dip-a-tidepool-minnow"
	})
	var onboarding_runtime = game.call("_onboarding_runtime")
	_expect(_truthy(onboarding_runtime.get("lock_click_tip_seen")), "Tip metadata restore should preserve lock-click tip state.")
	_expect(_truthy(onboarding_runtime.get("passive_module_tip_seen")), "Tip metadata restore should preserve passive-module tip state.")
	_expect(_truthy(onboarding_runtime.get("silver_opportunity_tip_seen")), "Tip metadata restore should preserve silver-opportunity tip state.")
	_expect(str(onboarding_runtime.get("silver_opportunity_tip_action_key")) == "fishing:shallows", "Tip metadata restore should canonicalize silver-opportunity action keys.")
	save_runtime.call("_restore_tip_metadata_from_save", {"silver_opportunity_tip_action_key": "malformed-key"})
	_expect(str(onboarding_runtime.get("silver_opportunity_tip_action_key")).is_empty(), "Tip metadata restore should clear malformed silver-opportunity action keys.")


func _check_historical_activity_aliases(game: Node) -> void:
	var historical_aliases := [
		{"legacy": "thieving:pocket-a-penny-nobody-wanted", "canonical": "thieving:borrow-cookie-permanently"},
		{"legacy": "thieving:borrow-a-cookie-permanently", "canonical": "thieving:sneak-past-tip-jar"},
		{"legacy": "thieving:burgle-the-dream-of-a-sleeping-wizard", "canonical": "thieving:burgle-wizard-dream"},
		{"legacy": "build:construct-suspiciously-tall-silo", "canonical": "build:build-tall-silo"},
		{"legacy": "build:build-the-building-that-builds-you", "canonical": "build:build-builder-building"},
		{"legacy": "fishing:space-starlight", "canonical": "fishing:starlight"},
		{"legacy": "fishing:space-reflection", "canonical": "fishing:reflection"},
	]
	for alias_case in historical_aliases:
		var legacy_key := str(alias_case.get("legacy", ""))
		var canonical_key := str(alias_case.get("canonical", ""))
		var key_parts := legacy_key.split(":", false, 1)
		_expect(key_parts.size() == 2, "Historical alias test input must be a qualified action key: %s." % legacy_key)
		if key_parts.size() != 2:
			continue
		var skill_id := str(key_parts[0])
		var action_id := str(key_parts[1])
		var resolved_key := str(game.call("_action_key", skill_id, action_id))
		_expect(resolved_key == canonical_key, "Historical action key %s should canonicalize to %s, got %s." % [legacy_key, canonical_key, resolved_key])
		var action := game.call("_action_data", skill_id, action_id) as Dictionary
		_expect(not action.is_empty(), "Historical action key %s should resolve to real action data." % legacy_key)
		if not action.is_empty():
			_expect("%s:%s" % [skill_id, str(action.get("id", ""))] == canonical_key, "Historical action key %s should resolve to canonical action data %s." % [legacy_key, canonical_key])
	var level_one_key := str(game.call("_action_key", "thieving", "pocket-a-penny-nobody-wanted"))
	var level_two_key := str(game.call("_action_key", "thieving", "borrow-a-cookie-permanently"))
	_expect(level_one_key != level_two_key, "Historical level-1 and level-2 thieving IDs must remain distinct.")


func _check_manual_activity_unlock_save_restore(game: Node) -> void:
	var level_5_xp := SkillState.xp_for_level(5)
	var level_2_xp := SkillState.xp_for_level(2)
	_prime_core_skill_state(game)
	game.call("_save_runtime").call("_load_game_core", {
		"selected_skill_id": "fight",
		"running_skill_id": "",
		"running_action_id": "",
		"action_progress": 0.0,
		"skills": {
			"fight": {"xp": level_5_xp, "level": 5},
			"build": {"xp": level_2_xp, "level": 2},
		},
		"manual_activity_unlocks": {
			"fight:kick-mud-off-boot": true,
			"fight:wrestle-stuck-gate-latch": false,
			"fight:not-a-real-action": true,
			"malformed-key": true,
		},
		"stamina": {},
		"stamina_bank": {},
		"saved_at": int(game.call("_unix_now")),
	})
	var manual_unlocks := game.get("manual_activity_unlocks") as Dictionary
	_expect(_truthy(manual_unlocks.get("fight:kick-mud-off-boot", false)), "Manual activity unlock restore should preserve saved unlocked actions.")
	_expect(not manual_unlocks.has("fight:wrestle-stuck-gate-latch"), "Manual activity unlock restore should not preserve false unlock entries.")
	_expect(not manual_unlocks.has("fight:not-a-real-action"), "Manual activity unlock restore should drop unknown action ids.")
	var kicked_action := game.call("_action_data", "fight", "kick-mud-off-boot") as Dictionary
	var gate_action := game.call("_action_data", "fight", "wrestle-stuck-gate-latch") as Dictionary
	_expect(game.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", kicked_action) == true, "Saved manual activity unlocks should remain playable after migration.")
	_expect(game.call("_activity_unlock_runtime").call("_can_unlock_action", "fight", gate_action) == true, "Level-met unsaved actions should be ready to unlock after migration.")
	_expect(game.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", gate_action) != true, "Level-met unsaved actions should not silently become playable after migration.")
	var gate_lock_state := game.call("_activity_unlock_runtime").call("_action_lock_cluster_state", "fight", gate_action) as Dictionary
	_expect(_truthy(gate_lock_state.get("all_met", false)) and int(gate_lock_state.get("ready_count", 0)) == int(gate_lock_state.get("total", -1)), "Level-met unsaved actions should expose an all-ready lock cluster state after migration.")
	var saved_manual := game.call("_activity_unlock_runtime").call("_manual_activity_unlocks_for_save") as Dictionary
	_expect(saved_manual.size() == 1 and _truthy(saved_manual.get("fight:kick-mud-off-boot", false)), "Manual activity unlock save should serialize only canonical true unlocks.")

	_prime_core_skill_state(game)
	game.call("_save_runtime").call("_load_game_core", {
		"selected_skill_id": "fight",
		"running_skill_id": "",
		"running_action_id": "",
		"action_progress": 0.0,
		"skills": {
			"fight": {"xp": level_5_xp, "level": 5},
			"build": {"xp": level_2_xp, "level": 2},
		},
		"stamina": {},
		"stamina_bank": {},
		"saved_at": int(game.call("_unix_now")),
	})
	manual_unlocks = game.get("manual_activity_unlocks") as Dictionary
	_expect(_truthy(manual_unlocks.get("fight:kick-mud-off-boot", false)), "Legacy saves without a manual unlock map should keep old level-unlocked mono actions playable.")
	_expect(not _truthy(manual_unlocks.get("fight:wrestle-stuck-gate-latch", false)), "Legacy save migration should not silently grant combo actions without explicit manual unlock state.")


func _check_fishing_method_unlock_routing(game: Node) -> void:
	var method_card := {
		"is_fishing_method": true,
		"skill_id": "fishing",
		"action_id": "rocks",
	}
	_expect(game.call("_skill_detail_surface").call("_should_route_activity_unlock_to_fishing_method", method_card, "fishing", "rocks") == true, "Fishing method cards should use the small fishing padlock ceremony.")
	_expect(game.call("_skill_detail_surface").call("_should_route_activity_unlock_to_fishing_method", method_card, "fight", "kick-mud-off-boot") != true, "Non-fishing actions should not use the fishing padlock ceremony.")
	game.set("action_cards", {str(game.call("_action_key", "fishing", "rocks")): method_card})
	_expect(game.call("_skill_detail_surface").call("_should_route_activity_unlock_to_fishing_method", {}, "fishing", "rocks") == true, "Registered fishing methods should be recovered before generic unlock routing.")

	var skills := game.get("skills") as Dictionary
	var fishing := (skills.get("fishing", {}) as Dictionary).duplicate(true)
	fishing["level"] = 4
	fishing["xp"] = SkillState.xp_for_level(4)
	skills["fishing"] = fishing
	game.set("skills", skills)
	var manual_unlocks := game.get("manual_activity_unlocks") as Dictionary
	manual_unlocks.erase(str(game.call("_action_key", "fishing", "rocks")))
	game.set("manual_activity_unlocks", manual_unlocks)
	game.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	_expect(game.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fishing", "rocks", "fishing method unlock") == true, "Fishing method lock click persistence should accept level-ready Rocks.")
	manual_unlocks = game.get("manual_activity_unlocks") as Dictionary
	_expect(_truthy(manual_unlocks.get("fishing:rocks", false)), "Fishing method lock clicks should persist the unlock immediately before page/tool refresh can discard the ceremony node.")
	var rocks_action := game.call("_action_data", "fishing", "rocks") as Dictionary
	_expect(game.call("_activity_unlock_runtime").call("_is_action_unlocked", "fishing", rocks_action) == true, "Immediately persisted fishing method unlocks should render as unlocked on rebuilt fishing location tiles.")
	var live_panel := Panel.new()
	var live_button := Button.new()
	live_button.disabled = true
	live_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	live_panel.add_child(live_button)
	var live_lock := Control.new()
	live_lock.mouse_filter = Control.MOUSE_FILTER_STOP
	var live_padlock_hit := Control.new()
	live_padlock_hit.mouse_filter = Control.MOUSE_FILTER_STOP
	live_lock.set_meta("padlock_button", live_padlock_hit)
	live_lock.add_child(live_padlock_hit)
	live_panel.add_child(live_lock)
	var live_method_card := {
		"is_fishing_method": true,
		"skill_id": "fishing",
		"action_id": "rocks",
		"fishing_area_key": "fishing:area-beach",
		"method_button": live_button,
		"art_panel": live_panel,
		"lock_root": live_lock,
		"unlock_ready_pending": true,
		"unlock_ceremony_pending": true,
	}
	game.get("fishing_ui_surface")._sync_fishing_method_card_unlocked_live(live_method_card)
	_expect(not live_button.disabled and live_button.mouse_filter == Control.MOUSE_FILTER_IGNORE and live_panel.mouse_filter == Control.MOUSE_FILTER_STOP, "Live fishing method cards should become tappable immediately after their lock is accepted through the manual fishing hit route.")
	_expect(not _truthy(live_method_card.get("unlock_ready_pending", true)) and not _truthy(live_method_card.get("unlock_ceremony_pending", true)), "Live fishing method unlock sync should clear stale locked-card flags before a page rebuild.")
	_expect(live_lock.mouse_filter == Control.MOUSE_FILTER_IGNORE and live_padlock_hit.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Live fishing method unlock sync should stop the old padlock from stealing the next tap.")
	_expect(str(game.call("_onboarding_runtime").call("_tutorial_preview_after_manual_unlock", "fishing", "rocks")) == "dock-edge", "Unlocking Rocks should target Pier Dock Edge as the next fishing module preview.")
	_expect(str(game.fishing_runtime.global_teaser_location_key(game, "fishing", FishingState.FISHING_LOCATION_DEFS, FishingState.FISHING_TOOL_LOCATION_ACTIONS)) == "pier.dock-cup", "After Rocks is unlocked, the fishing teaser should move to the Pier Dock Edge location tile.")
	var render_area_ids := []
	for raw_area_def in game.call("_fishing_ui_surface").render_area_modules("fishing") as Array:
		var area_def := raw_area_def as Dictionary
		render_area_ids.append(str(area_def.get("id", "")))
	_expect(render_area_ids.has("pier"), "After Rocks is unlocked, the Pier area module should be included as the next locked fishing module.")


func _check_module_ui_preferences_save_restore(game: Node) -> void:
	_prime_core_skill_state(game)
	var skills := game.get("skills") as Dictionary
	skills["fight"] = {"xp": SkillState.xp_for_level(2), "level": 2}
	game.set("skills", skills)
	var unlocked_action := game.call("_action_data", "fight", "push-ups") as Dictionary
	var unlocked_key := str(ModuleUiRuntime.action_for_record("fight", unlocked_action, game.get("FISHING_ACTION_ID_ALIASES")))
	var locked_key := ""
	var actions_by_skill := game.get("actions_by_skill") as Dictionary
	for raw_action in actions_by_skill.get("fight", []) as Array:
		var action := raw_action as Dictionary
		if action.is_empty() or int(action.get("unlock", 1)) <= 2:
			continue
		locked_key = str(ModuleUiRuntime.action_for_record("fight", action, game.get("FISHING_ACTION_ID_ALIASES")))
		break
	_expect(not unlocked_key.is_empty(), "Module UI test needs an unlocked fight action key.")
	_expect(not locked_key.is_empty(), "Module UI test needs a locked fight action key.")
	var locked_heist_key := str(ModuleUiRuntime.thieving_heist("complimentary_spoon"))
	var unavailable_offer_key := str(ModuleUiRuntime.fishing_offer("net"))
	var locked_fishing_area_key := ""
	for raw_area_def in game.call("_fishing_ui_surface").render_area_modules("fishing") as Array:
		var area_def := raw_area_def as Dictionary
		var area_key := str(ModuleUiRuntime.fishing_area(game.get("fishing_runtime").area_module_key("fishing", area_def)))
		if not area_key.is_empty() and game.call("_skill_detail_surface").call("_module_ui_key_allows_pin_or_collapse", area_key) != true:
			locked_fishing_area_key = area_key
			break
	_expect(not locked_heist_key.is_empty(), "Module UI test needs a locked thieving heist key.")
	_expect(not unavailable_offer_key.is_empty(), "Module UI test needs an unavailable fishing offer key.")
	var locked_host := Control.new()
	var skill_detail_surface: Object = game.call("_skill_detail_surface")
	var locked_zones := skill_detail_surface.call("_add_module_action_zones", locked_host, locked_key) as Dictionary
	_expect(locked_zones.is_empty() and locked_host.get_child_count() == 0, "Locked modules should not receive pin or collapse action zones.")
	locked_host.free()
	var hub_key := ModuleUiRuntime.hub("trophy")
	var rejected_module_keys := [locked_key, hub_key, locked_heist_key, unavailable_offer_key]
	if not locked_fishing_area_key.is_empty():
		rejected_module_keys.append(locked_fishing_area_key)
	var hub_host := Control.new()
	var hub_zones := skill_detail_surface.call("_add_module_action_zones", hub_host, hub_key) as Dictionary
	_expect(hub_zones.is_empty() and hub_host.get_child_count() == 0, "Hub modules should not receive activity pin or collapse action zones.")
	hub_host.free()
	for rejected_key in rejected_module_keys:
		var rejected_host := Control.new()
		var rejected_zones := skill_detail_surface.call("_add_module_action_zones", rejected_host, rejected_key) as Dictionary
		_expect(rejected_zones.is_empty() and rejected_host.get_child_count() == 0, "Unavailable module key should not receive pin or collapse action zones: %s" % rejected_key)
		rejected_host.free()
	var module_ui_runtime: Object = game.get("module_ui_runtime")
	module_ui_runtime.set("pinned_order", [])
	module_ui_runtime.set("collapsed", {})
	var preview_tokens := {}
	for rejected_key in rejected_module_keys:
		preview_tokens[rejected_key] = 1
	module_ui_runtime.set("pin_preview_tokens", preview_tokens)
	for rejected_key in rejected_module_keys:
		game.call("_skill_detail_surface").call("_pin_module_ui_key", rejected_key, 0)
		game.call("_skill_detail_surface").call("_collapse_module_ui_key", rejected_key, 0)
		game.call("_skill_detail_surface").call("_unpin_module_ui_key", rejected_key, 0)
	_expect((module_ui_runtime.get("pinned_order") as Array).is_empty(), "Rejected module pin mutators should not change runtime pinned order.")
	_expect((module_ui_runtime.get("collapsed") as Dictionary).is_empty(), "Rejected module collapse mutators should not change runtime collapsed state.")
	var preview_tokens_after_rejected_mutators := module_ui_runtime.get("pin_preview_tokens") as Dictionary
	for rejected_key in rejected_module_keys:
		_expect(not preview_tokens_after_rejected_mutators.has(rejected_key), "Rejected module UI mutators should clear stale preview token without persisting state: %s" % rejected_key)
	var dirty_pinned_order := [unlocked_key, locked_key, hub_key, locked_heist_key, unavailable_offer_key, unlocked_key, "not-a-module-key"]
	var dirty_collapsed := {
		unlocked_key: true,
		locked_key: true,
		hub_key: true,
		locked_heist_key: true,
		unavailable_offer_key: true,
		"not-a-module-key": true,
	}
	if not locked_fishing_area_key.is_empty():
		dirty_pinned_order.insert(5, locked_fishing_area_key)
		dirty_collapsed[locked_fishing_area_key] = true
	module_ui_runtime.set("pinned_order", dirty_pinned_order)
	module_ui_runtime.set("collapsed", dirty_collapsed)
	module_ui_runtime.set("sort_mode", "level_reverse")
	var saved_order := module_ui_runtime.pinned_order_for_save(Callable(game.call("_skill_detail_surface"), "_module_ui_key_allows_pin_or_collapse")) as Array
	_expect(saved_order == [unlocked_key], "Module UI pin save should keep only unique unlocked module keys.")
	var saved_collapsed := module_ui_runtime.collapsed_for_save(Callable(game.call("_skill_detail_surface"), "_module_ui_key_allows_pin_or_collapse")) as Dictionary
	_expect(saved_collapsed.size() == 1 and _truthy(saved_collapsed.get(unlocked_key, false)), "Module UI collapse save should keep only intentional unlocked module flags.")
	_expect(str(module_ui_runtime.sort_mode_for_save()) == "level_reverse", "Module UI sort save should preserve valid sort mode.")
	var module_ui_payload := _save_payload(game, int(game.call("_unix_now")))
	_expect(int(module_ui_payload.get("module_ui_collapse_save_version", 0)) == ModuleUiRuntime.COLLAPSE_SAVE_VERSION, "Save payload should include the current module collapse save version.")
	_expect((module_ui_payload.get("module_ui_pinned_order", []) as Array) == [unlocked_key], "Save payload should serialize normalized pinned module order.")
	var payload_collapsed := module_ui_payload.get("module_ui_collapsed", {}) as Dictionary
	_expect(payload_collapsed.size() == 1 and _truthy(payload_collapsed.get(unlocked_key, false)), "Save payload should serialize normalized collapsed module flags.")
	_expect(str(module_ui_payload.get("module_ui_sort_mode", "")) == "level_reverse", "Save payload should serialize normalized module sort mode.")
	module_ui_runtime.set("pin_preview_tokens", {unlocked_key: 7})
	var restore_pinned_order := [locked_key, hub_key, locked_heist_key, unavailable_offer_key, unlocked_key, "bad"]
	var restore_collapsed := {locked_key: true, hub_key: true, locked_heist_key: true, unavailable_offer_key: true, unlocked_key: true, "bad": true}
	if not locked_fishing_area_key.is_empty():
		restore_pinned_order.insert(4, locked_fishing_area_key)
		restore_collapsed[locked_fishing_area_key] = true
	module_ui_runtime.restore_from_save({
		"module_ui_pinned_order": restore_pinned_order,
		"module_ui_collapsed": restore_collapsed,
		"module_ui_collapse_save_version": ModuleUiRuntime.COLLAPSE_SAVE_VERSION,
		"module_ui_sort_mode": "unknown-mode",
	}, ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE, Callable(game.call("_skill_detail_surface"), "_module_ui_key_allows_pin_or_collapse"))
	var restored_order := module_ui_runtime.get("pinned_order") as Array
	var restored_collapsed := module_ui_runtime.get("collapsed") as Dictionary
	_expect(restored_order == [unlocked_key], "Module UI pin restore should filter locked and malformed keys.")
	_expect(restored_collapsed.size() == 1 and _truthy(restored_collapsed.get(unlocked_key, false)), "Module UI collapse restore should filter locked and malformed keys.")
	_expect(str(module_ui_runtime.get("sort_mode")) == "level", "Module UI sort restore should fall back to default for invalid modes.")
	_expect((module_ui_runtime.get("pin_preview_tokens") as Dictionary).is_empty(), "Module UI restore should clear transient pin preview tokens.")
	module_ui_runtime.set("collapsed", {unlocked_key: true})
	module_ui_runtime.restore_from_save({
		"module_ui_collapsed": {unlocked_key: true},
		"module_ui_collapse_save_version": 0,
	}, ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE, Callable(game.call("_skill_detail_surface"), "_module_ui_key_allows_pin_or_collapse"))
	_expect((module_ui_runtime.get("collapsed") as Dictionary).is_empty(), "Legacy module collapse saves should migrate to expanded modules.")
	module_ui_runtime.set("collapsed", {unlocked_key: true})
	module_ui_runtime.restore_from_save({
		"module_ui_collapsed": {unlocked_key: true},
		"module_ui_collapse_save_version": "bad-version",
	}, ModuleUiRuntime.MODULE_PIN_COLOR_TEXTURES, ModuleUiRuntime.MODULE_PIN_ICON_TEXTURE, Callable(game.call("_skill_detail_surface"), "_module_ui_key_allows_pin_or_collapse"))
	_expect((module_ui_runtime.get("collapsed") as Dictionary).is_empty(), "Malformed module collapse save versions should migrate to expanded modules.")
	module_ui_runtime.set("pinned_order", [unlocked_key])
	module_ui_runtime.set("collapsed", {unlocked_key: true})
	module_ui_runtime.set("sort_mode", "level_reverse")
	module_ui_runtime.reset()
	(game.call("_navigation_shell") as Object).set("module_utility_collapsed", false)
	_expect((module_ui_runtime.get("pinned_order") as Array).is_empty(), "Hard reset should clear pinned module order.")
	_expect((module_ui_runtime.get("collapsed") as Dictionary).is_empty(), "Hard reset should expand collapsed modules.")
	_expect(str(module_ui_runtime.get("sort_mode")) == "level", "Hard reset should restore default module sorting.")


func _check_auto_unlock_lockpads(game: Node) -> void:
	var previous_startup := _truthy(game.get("startup_initialized"))
	var previous_screen := str(game.get("current_screen"))
	var previous_selected := str(game.get("selected_skill_id"))
	var previous_auto_unlock := _truthy(game.get("auto_unlock_lockpads_enabled"))
	game.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	_prime_core_skill_state(game)
	game.set("startup_initialized", true)
	game.set("current_screen", "home")
	game.set("selected_skill_id", "fight")
	game.set("auto_unlock_lockpads_enabled", true)
	game.set("manual_activity_unlocks", {})
	game.call("_activity_unlock_runtime").set("pending_activity_unlock_ceremony", {})
	var skills := game.get("skills") as Dictionary
	var fight := skills.get("fight", {}) as Dictionary
	fight["xp"] = SkillState.xp_for_level(2)
	fight["level"] = 2
	skills["fight"] = fight
	game.set("skills", skills)
	game.call("_activity_unlock_runtime").call("_queue_activity_unlock_readiness", "fight", 1, 2, {"fight": ["kick-mud-off-boot"]})
	var manual_unlocks := game.get("manual_activity_unlocks") as Dictionary
	_expect(manual_unlocks.get("fight:kick-mud-off-boot", false) == true, "Auto-unlock lockpads should immediately mark non-visible ready locks unlocked.")
	_expect((game.call("_activity_unlock_runtime").get("pending_activity_unlock_ceremony") as Dictionary).is_empty(), "Auto-unlock lockpads should not leave non-visible ready locks pending.")

	_prime_core_skill_state(game)
	game.set("startup_initialized", true)
	game.set("current_screen", "home")
	game.set("selected_skill_id", "fight")
	game.set("auto_unlock_lockpads_enabled", true)
	game.set("manual_activity_unlocks", {})
	game.set("manual_activity_requirement_unlocks", {})
	game.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	game.call("_activity_unlock_runtime").set("pending_activity_unlock_ceremony", {})
	skills = game.get("skills") as Dictionary
	var fishing := skills.get("fishing", {}) as Dictionary
	fishing["xp"] = SkillState.xp_for_level(4)
	fishing["level"] = 4
	skills["fishing"] = fishing
	game.set("skills", skills)
	game.call("_activity_unlock_runtime").call("_queue_activity_unlock_readiness", "fishing", 1, 4, {"fishing": ["rocks"]})
	manual_unlocks = game.get("manual_activity_unlocks") as Dictionary
	_expect(manual_unlocks.get("fishing:rocks", false) == true, "Auto-unlock lockpads should immediately mark non-visible ready fishing methods unlocked.")
	_expect((game.call("_activity_unlock_runtime").get("pending_activity_unlock_ceremony") as Dictionary).is_empty(), "Auto-unlock lockpads should not leave non-visible fishing methods pending.")

	_prime_core_skill_state(game)
	game.set("startup_initialized", true)
	game.set("current_screen", "skill")
	game.set("selected_skill_id", "fight")
	game.set("auto_unlock_lockpads_enabled", true)
	game.set("manual_activity_unlocks", {})
	game.set("manual_activity_requirement_unlocks", {})
	game.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	game.call("_activity_unlock_runtime").set("pending_activity_unlock_ceremony", {})
	skills = game.get("skills") as Dictionary
	fight = skills.get("fight", {}) as Dictionary
	fight["xp"] = SkillState.xp_for_level(2)
	fight["level"] = 2
	skills["fight"] = fight
	game.set("skills", skills)
	game.call("_activity_unlock_runtime").call("_run_startup_auto_unlock_lockpads")
	manual_unlocks = game.get("manual_activity_unlocks") as Dictionary
	_expect(manual_unlocks.get("fight:kick-mud-off-boot", false) == true, "Startup with auto-unlock on should not leave ready lockpads alive until the setting is toggled.")
	_expect((game.call("_activity_unlock_runtime").get("pending_activity_unlock_ceremony") as Dictionary).is_empty(), "Startup with auto-unlock on should drain retroactive ready lockpads.")

	_prime_core_skill_state(game)
	game.set("startup_initialized", true)
	game.set("current_screen", "home")
	game.set("selected_skill_id", "fight")
	game.set("auto_unlock_lockpads_enabled", true)
	game.set("manual_activity_unlocks", {})
	game.set("manual_activity_requirement_unlocks", {})
	game.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	game.call("_activity_unlock_runtime").set("pending_activity_unlock_ceremony", {})
	skills = game.get("skills") as Dictionary
	fishing = skills.get("fishing", {}) as Dictionary
	fishing["xp"] = SkillState.xp_for_level(4)
	fishing["level"] = 4
	skills["fishing"] = fishing
	game.set("skills", skills)
	game.call("_activity_unlock_runtime").call("_run_startup_auto_unlock_lockpads")
	manual_unlocks = game.get("manual_activity_unlocks") as Dictionary
	_expect(manual_unlocks.get("fishing:rocks", false) == true, "Startup with auto-unlock on should drain retroactive ready fishing method lockpads.")
	_expect((game.call("_activity_unlock_runtime").get("pending_activity_unlock_ceremony") as Dictionary).is_empty(), "Startup with auto-unlock on should not leave ready fishing method lockpads pending.")

	_prime_core_skill_state(game)
	game.set("startup_initialized", true)
	game.set("current_screen", "home")
	game.set("selected_skill_id", "fight")
	game.set("auto_unlock_lockpads_enabled", false)
	game.set("manual_activity_unlocks", {})
	game.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	game.call("_activity_unlock_runtime").set("pending_activity_unlock_ceremony", {
		"pages": {
			"fight": {
				"skill_id": "fight",
				"ready": ["kick-mud-off-boot", "wrestle-stuck-gate-latch"],
				"applied": true
			}
		}
	})
	skills = game.get("skills") as Dictionary
	fight = skills.get("fight", {}) as Dictionary
	fight["xp"] = SkillState.xp_for_level(3)
	fight["level"] = 3
	skills["fight"] = fight
	var build := skills.get("build", {}) as Dictionary
	build["xp"] = SkillState.xp_for_level(2)
	build["level"] = 2
	skills["build"] = build
	game.set("skills", skills)
	game.call("_settings_surface").call("toggle_auto_unlock_lockpads_enabled")
	manual_unlocks = game.get("manual_activity_unlocks") as Dictionary
	_expect(game.get("auto_unlock_lockpads_enabled") == true, "Auto-unlock lockpad toggle should enable the setting.")
	_expect(manual_unlocks.get("fight:kick-mud-off-boot", false) == true and manual_unlocks.get("fight:wrestle-stuck-gate-latch", false) == true, "Toggling auto-unlock on should clear all currently ready non-visible lockpads.")
	_expect((game.call("_activity_unlock_runtime").get("pending_activity_unlock_ceremony") as Dictionary).is_empty(), "Toggling auto-unlock on should drain the current ready lockpad queue.")

	_prime_core_skill_state(game)
	game.set("startup_initialized", true)
	game.set("current_screen", "home")
	game.set("selected_skill_id", "fight")
	game.set("auto_unlock_lockpads_enabled", false)
	game.set("manual_activity_unlocks", {})
	game.set("manual_activity_requirement_unlocks", {})
	game.call("_activity_unlock_runtime").call("_invalidate_manual_activity_unlock_trust")
	game.call("_activity_unlock_runtime").set("pending_activity_unlock_ceremony", {
		"pages": {
			"fishing": {
				"skill_id": "fishing",
				"ready": ["rocks"],
				"applied": true
			}
		}
	})
	skills = game.get("skills") as Dictionary
	fishing = skills.get("fishing", {}) as Dictionary
	fishing["xp"] = SkillState.xp_for_level(4)
	fishing["level"] = 4
	skills["fishing"] = fishing
	game.set("skills", skills)
	game.call("_settings_surface").call("toggle_auto_unlock_lockpads_enabled")
	manual_unlocks = game.get("manual_activity_unlocks") as Dictionary
	_expect(manual_unlocks.get("fishing:rocks", false) == true, "Toggling auto-unlock on should clear ready non-visible fishing method lockpads.")
	_expect((game.call("_activity_unlock_runtime").get("pending_activity_unlock_ceremony") as Dictionary).is_empty(), "Toggling auto-unlock on should drain pending fishing method lockpads.")
	game.set("startup_initialized", previous_startup)
	game.set("current_screen", previous_screen)
	game.set("selected_skill_id", previous_selected)
	game.set("auto_unlock_lockpads_enabled", previous_auto_unlock)


func _check_auto_eat_fish_per_skill_save_restore(game: Node) -> void:
	_prime_core_skill_state(game)
	var fishing_runtime: Object = game.get("fishing_runtime")
	fishing_runtime.set("auto_eat_fish_enabled_by_skill", {})
	fishing_runtime.call("set_auto_eat_fish_enabled_for_skill", game, "woodcutting", true)
	fishing_runtime.call("set_auto_eat_fish_enabled_for_skill", game, "fight", false)
	var saved := fishing_runtime.call("auto_eat_fish_enabled_by_skill_for_save", game) as Dictionary
	_expect(_truthy(saved.get("woodcutting", false)), "Auto-eat fish save should keep the enabled skill.")
	_expect(not saved.has("fight"), "Auto-eat fish save should omit disabled skills.")
	_expect(not saved.has("fishing"), "Auto-eat fish save should omit fishing.")

	fishing_runtime.call("restore_auto_eat_fish_enabled_from_save", game, {
		"auto_eat_fish_enabled_by_skill": {
			"fight": true,
			"woodcutting": false,
			"fishing": true,
		}
	})
	_expect(_truthy(fishing_runtime.call("auto_eat_fish_enabled_for_skill", game, "fight")), "Auto-eat fish restore should enable the saved skill.")
	_expect(not _truthy(fishing_runtime.call("auto_eat_fish_enabled_for_skill", game, "woodcutting")), "Auto-eat fish restore should keep saved disabled skills off.")
	_expect(not _truthy(fishing_runtime.call("auto_eat_fish_enabled_for_skill", game, "fishing")), "Auto-eat fish restore should not enable fishing.")

	fishing_runtime.call("restore_auto_eat_fish_enabled_from_save", game, {"auto_eat_fish_enabled": true})
	_expect(_truthy(fishing_runtime.call("auto_eat_fish_enabled_for_skill", game, "fight")), "Legacy auto-eat save should migrate fight to enabled.")
	_expect(_truthy(fishing_runtime.call("auto_eat_fish_enabled_for_skill", game, "woodcutting")), "Legacy auto-eat save should migrate woodcutting to enabled.")
	_expect(not _truthy(fishing_runtime.call("auto_eat_fish_enabled_for_skill", game, "fishing")), "Legacy auto-eat save should still leave fishing off.")


func _check_achievement_toast_seen_ids_save_restore(game: Node) -> void:
	var save_runtime: Object = game.call("_save_runtime")
	game.call("_save_runtime").call("_restore_activity_crit_metadata_from_save", {
		"activity_crit_seen": false,
		"activity_mega_crit_seen": true
	})
	_expect(_truthy(game.get("activity_crit_seen")), "Activity crit restore should mark crit seen when mega crit has been seen.")
	_expect(_truthy(game.get("activity_mega_crit_seen")), "Activity crit restore should preserve mega crit state.")
	game.call("_save_runtime").call("_restore_activity_crit_metadata_from_save", {
		"activity_crit_seen": false,
		"activity_mega_crit_seen": false
	})
	_expect(not _truthy(game.get("activity_crit_seen")), "Activity crit restore should preserve unseen crit state.")
	_expect(not _truthy(game.get("activity_mega_crit_seen")), "Activity crit restore should preserve unseen mega crit state.")
	game.call("_save_runtime").call("_restore_boot_visible_tip_flags_from_save", {
		"activity_start_tip_seen": true,
		"hub_tutorial_tip_seen": true
	})
	_expect(_truthy(game.call("_onboarding_runtime").get("activity_start_tip_seen")), "Boot-visible tip restore should preserve activity-start tip state.")
	_expect(game.call("_hub_surface").get("hub_tutorial_tip_seen") == true, "Boot-visible tip restore should preserve hub tutorial tip state.")
	game.call("_save_runtime").call("_restore_boot_visible_tip_flags_from_save", {})
	_expect(not _truthy(game.call("_onboarding_runtime").get("activity_start_tip_seen")), "Boot-visible tip restore should default missing activity-start tip state to false.")
	_expect(game.call("_hub_surface").get("hub_tutorial_tip_seen") != true, "Boot-visible tip restore should default missing hub tutorial tip state to false.")

	save_runtime.set("achievement_toast_seen_ids", {
		"total-level-25": true,
		"activity-crit": false,
		"": true,
		123: true,
	})
	var saved := AchievementState.normalized_seen_ids(save_runtime.get("achievement_toast_seen_ids")) as Dictionary
	_expect(saved.size() == 2, "Achievement toast save should only keep truthy non-empty ids.")
	_expect(saved.get("total-level-25", false) == true, "Achievement toast save should preserve truthy string ids.")
	_expect(saved.get("123", false) == true, "Achievement toast save should stringify non-string ids for compatibility.")
	_expect(not saved.has("activity-crit"), "Achievement toast save should drop false entries.")
	_expect(not saved.has(""), "Achievement toast save should drop empty ids.")

	save_runtime.set("achievement_toast_seen_ids", {"total-level-25": true})
	save_runtime.set("achievement_toast_seen_ids", AchievementState.normalized_seen_ids("bad-entry"))
	var restored := save_runtime.get("achievement_toast_seen_ids") as Dictionary
	_expect(restored.is_empty(), "Achievement toast restore should clear malformed saved seen-id data.")
	save_runtime.set("achievement_toast_seen_ids", AchievementState.normalized_seen_ids({
		"total-level-25": true,
		"activity-crit": false,
		"": true,
		123: true,
	}))
	restored = save_runtime.get("achievement_toast_seen_ids") as Dictionary
	_expect(restored.size() == 2, "Achievement toast restore should only keep truthy non-empty ids.")
	_expect(restored.get("total-level-25", false) == true and restored.get("123", false) == true, "Achievement toast restore should preserve compatible truthy ids.")


func _check_scalar_progression_metadata_save(game: Node) -> void:
	var hub_runtime: Object = game.call("_hub_runtime")
	var ad_bonus_runtime: Object = game.call("_ad_bonus_runtime")
	var save_runtime: Object = game.call("_save_runtime")
	hub_runtime.set("hub_selected_module_id", "barn")
	_expect(str(hub_runtime.call("selected_module_id_for_save")) == "barn", "Hub selected-module save should preserve persisted hub modules.")
	hub_runtime.set("hub_selected_module_id", "trophy")
	_expect(str(hub_runtime.call("selected_module_id_for_save")) == "pond", "Hub selected-module save should mirror restore behavior for derived selections.")
	hub_runtime.set("hub_selected_module_id", "barn")
	hub_runtime.call("restore_selected_module_id", {"hub_selected_module_id": "not-a-module"})
	_expect(str(hub_runtime.get("hub_selected_module_id")) == "pond", "Hub selected-module restore should replace unknown modules with the pond.")
	hub_runtime.call("restore_selected_module_id", {"hub_selected_module_id": "barn"})
	_expect(str(hub_runtime.get("hub_selected_module_id")) == "barn", "Hub selected-module restore should preserve persisted hub modules.")
	hub_runtime.set("hub_mission_cooldown_until_unix", -12)
	_expect(int(_save_payload_value(game, "hub_mission_cooldown_until_unix")) == 0, "Hub mission cooldown save should clamp negative timestamps.")
	hub_runtime.call("restore_mission_cooldown", {"hub_mission_cooldown_until_unix": -12})
	_expect(int(hub_runtime.get("hub_mission_cooldown_until_unix")) == 0, "Hub mission cooldown restore should clamp negative timestamps.")
	hub_runtime.call("restore_mission_cooldown", {"hub_mission_cooldown_until_unix": 1234})
	_expect(int(hub_runtime.get("hub_mission_cooldown_until_unix")) == 1234, "Hub mission cooldown restore should preserve nonnegative timestamps.")
	game.set("plank_boost_enabled", true)
	_expect(_save_payload_value(game, "plank_boost_enabled") == true, "Plank boost save should preserve enabled state.")
	game.set("plank_boost_enabled", SaveStateNormalizers.bool_value({"plank_boost_enabled": true}, "plank_boost_enabled"))
	_expect(game.get("plank_boost_enabled") == true, "Plank boost restore should preserve enabled state.")
	game.set("plank_boost_enabled", SaveStateNormalizers.bool_value({}, "plank_boost_enabled"))
	_expect(game.get("plank_boost_enabled") != true, "Plank boost restore should default missing state to disabled.")
	ad_bonus_runtime.set("seconds_remaining", 999999.0)
	_expect(float(_save_payload_value(game, "ad_bonus_seconds_remaining")) == 21600.0, "Ad bonus save should cap remaining seconds.")
	ad_bonus_runtime.call("restore_seconds_from_save", {"ad_bonus_seconds_remaining": -5.0})
	_expect(float(ad_bonus_runtime.get("seconds_remaining")) == 0.0, "Ad bonus restore should clamp negative remaining seconds.")
	ad_bonus_runtime.call("restore_seconds_from_save", {"ad_bonus_seconds_remaining": 999999.0})
	_expect(float(ad_bonus_runtime.get("seconds_remaining")) == 21600.0, "Ad bonus restore should cap remaining seconds.")
	ad_bonus_runtime.call("restore_seconds_from_save", {"ad_bonus_seconds_remaining": 42.5})
	_expect(float(ad_bonus_runtime.get("seconds_remaining")) == 42.5, "Ad bonus restore should preserve valid remaining seconds.")
	_action_runtime(game).set("activity_start_count", -3)
	_expect(int(_save_payload_value(game, "activity_start_count")) == 0, "Activity start-count save should clamp negative counts.")
	_action_runtime(game).set("activity_completion_count", -4)
	_expect(int(_save_payload_value(game, "activity_completion_count")) == 0, "Activity completion-count save should clamp negative counts.")
	_action_runtime(game).set("guaranteed_success_action_completions", 999)
	_expect(int(_save_payload_value(game, "guaranteed_success_action_completions")) == 7, "Guaranteed-success save should cap completion counts.")
	var restored_activity_progress := {
		"activity_start_count": -3,
		"activity_completion_count": -4,
		"guaranteed_success_action_completions": 999
	}
	_action_runtime(game).set("activity_start_count", SaveStateNormalizers.nonnegative_int(restored_activity_progress, "activity_start_count"))
	_action_runtime(game).set("activity_completion_count", SaveStateNormalizers.nonnegative_int(restored_activity_progress, "activity_completion_count"))
	_action_runtime(game).set("guaranteed_success_action_completions", SaveStateNormalizers.clamped_int(restored_activity_progress, "guaranteed_success_action_completions", 0, ActionRuntime.GUARANTEED_SUCCESS_ACTION_COMPLETIONS, _action_runtime(game).get("activity_completion_count")))
	_expect(int(_action_runtime(game).get("activity_start_count")) == 0, "Activity progress restore should clamp negative start counts.")
	_expect(int(_action_runtime(game).get("activity_completion_count")) == 0, "Activity progress restore should clamp negative completion counts.")
	_expect(int(_action_runtime(game).get("guaranteed_success_action_completions")) == 7, "Activity progress restore should cap guaranteed-success completions.")
	restored_activity_progress = {
		"activity_start_count": 4,
		"activity_completion_count": 5
	}
	_action_runtime(game).set("activity_start_count", SaveStateNormalizers.nonnegative_int(restored_activity_progress, "activity_start_count"))
	_action_runtime(game).set("activity_completion_count", SaveStateNormalizers.nonnegative_int(restored_activity_progress, "activity_completion_count"))
	_action_runtime(game).set("guaranteed_success_action_completions", SaveStateNormalizers.clamped_int(restored_activity_progress, "guaranteed_success_action_completions", 0, ActionRuntime.GUARANTEED_SUCCESS_ACTION_COMPLETIONS, _action_runtime(game).get("activity_completion_count")))
	_expect(int(_action_runtime(game).get("activity_start_count")) == 4, "Activity progress restore should preserve valid start counts.")
	_expect(int(_action_runtime(game).get("activity_completion_count")) == 5, "Activity progress restore should preserve valid completion counts.")
	_expect(int(_action_runtime(game).get("guaranteed_success_action_completions")) == 5, "Activity progress restore should default missing guaranteed-success completions from restored completion count.")
	_action_runtime(game).set("guaranteed_success_action_completions", SaveStateNormalizers.clamped_int({}, "guaranteed_success_action_completions", 0, ActionRuntime.GUARANTEED_SUCCESS_ACTION_COMPLETIONS, 6))
	_expect(int(_action_runtime(game).get("guaranteed_success_action_completions")) == 6, "Guaranteed-success restore should use the supplied fallback completion count.")
	game.call("_onboarding_runtime").set("onboarding_starter_action_completion_count", -5)
	_expect(int(_save_payload_value(game, "onboarding_starter_action_completion_count")) == 0, "Onboarding starter-count save should clamp negative counts.")
	save_runtime.call("_restore_onboarding_progression_from_save", {"onboarding_fight_auto_run_message_shown": true})
	_expect(int(game.call("_onboarding_runtime").get("onboarding_starter_action_completion_count")) == 1, "Onboarding restore should backfill starter completions from the auto-run message.")
	save_runtime.call("_restore_onboarding_progression_from_save", {"onboarding_starter_action_completion_count": 2})
	_expect(_truthy(game.call("_onboarding_runtime").get("onboarding_fight_summary_revealed")), "Onboarding restore should reveal the fight summary instead of preserving the obsolete header reveal backfill.")
	save_runtime.call("_restore_onboarding_progression_from_save", {"skill_swipe_tip_seen": true})
	_expect(_truthy(game.call("_onboarding_runtime").get("onboarding_swipe_tip_eligible")) and _truthy(game.call("_onboarding_runtime").get("onboarding_swipe_navigation_unlocked")), "Onboarding restore should keep swipe unlocks implied by seen swipe tips.")
	_expect(_truthy(game.call("_onboarding_runtime").get("onboarding_fight_summary_revealed")) and _truthy(game.call("_onboarding_runtime").get("onboarding_fight_action_stats_revealed")), "Onboarding restore should keep fight reveal state implied by seen swipe tips.")
	game.call("_onboarding_runtime").set("skill_swipe_tip_seen", false)
	game.call("_onboarding_runtime").set("onboarding_swipe_tip_eligible", false)
	game.call("_onboarding_runtime").set("onboarding_swipe_navigation_unlocked", false)
	game.call("_onboarding_runtime").set("stamina_gauge_tip_seen", true)
	game.call("_onboarding_runtime").set("onboarding_fight_summary_revealed", false)
	game.call("_onboarding_runtime").set("onboarding_fight_auto_run_message_shown", false)
	game.call("_onboarding_runtime").set("onboarding_fight_stamina_revealed", false)
	game.call("_onboarding_runtime").set("onboarding_fight_action_stats_revealed", false)
	save_runtime.call("_apply_onboarding_restored_completion_implications")
	_expect(_truthy(game.call("_onboarding_runtime").get("onboarding_fight_summary_revealed")) and _truthy(game.call("_onboarding_runtime").get("onboarding_fight_action_stats_revealed")), "Onboarding completion implications should reveal fight tutorial state from restored stamina tips.")
	_expect(_truthy(game.call("_onboarding_runtime").get("onboarding_swipe_navigation_unlocked")), "Onboarding completion implications should unlock swipe navigation when stamina-tip progress is restored.")
	var low_fight_stamina := game.get("stamina") as Dictionary
	low_fight_stamina["fight"] = 4.0
	game.set("stamina", low_fight_stamina)
	save_runtime.call("_restore_onboarding_progression_from_save", {
		"stamina_gauge_tip_seen": true,
		"onboarding_fight_action_stats_revealed": true
	})
	_expect(_truthy(game.call("_onboarding_runtime").get("onboarding_swipe_tip_eligible")) and _truthy(game.call("_onboarding_runtime").get("onboarding_swipe_navigation_unlocked")), "Onboarding restore should unlock swipe navigation at the same low-stamina threshold as live tutorial play.")
	save_runtime.call("_restore_onboarding_progression_from_save", {"onboarding_medal_tip_shown": true})
	_expect(game.call("_tutorial_overlay_surface").onboarding_mastery_tip_dismissed == true, "Onboarding restore should keep medal tips dismissing the mastery tip.")
	game.set("stamina_gauge_pre_tip_hold_seconds", 99.0)
	_expect(float(_save_payload_value(game, "stamina_gauge_pre_tip_hold_seconds")) == 4.0, "Stamina tip hold save should cap discovery hold seconds.")
	game.set("stamina_gauge_pre_tip_hold_seconds", SaveStateNormalizers.clamped_float({"stamina_gauge_pre_tip_hold_seconds": -5.0}, "stamina_gauge_pre_tip_hold_seconds", 0.0, MainScript.STAMINA_TIP_DISCOVERY_HOLD_SECONDS))
	_expect(float(game.get("stamina_gauge_pre_tip_hold_seconds")) == 0.0, "Stamina tip hold restore should clamp negative seconds.")
	game.set("stamina_gauge_pre_tip_hold_seconds", SaveStateNormalizers.clamped_float({"stamina_gauge_pre_tip_hold_seconds": 99.0}, "stamina_gauge_pre_tip_hold_seconds", 0.0, MainScript.STAMINA_TIP_DISCOVERY_HOLD_SECONDS))
	_expect(float(game.get("stamina_gauge_pre_tip_hold_seconds")) == 4.0, "Stamina tip hold restore should cap discovery hold seconds.")
	var audio := game.call("_audio_director") as AudioDirector
	audio.flow_heat = 99.0
	_expect(float(_save_payload_value(game, "flow_heat")) == 36.0, "Music flow heat save should cap heat.")
	audio.flow_active_action_seconds = -8.0
	_expect(float(_save_payload_value(game, "flow_active_action_seconds")) == 0.0, "Music flow active seconds save should clamp negative seconds.")
	audio.flow_actions_taken = 12
	audio.restore_music_flow_state({
		"music_start_chance_unlocked": true,
		"flow_heat": 99.0,
		"flow_active_action_seconds": -8.0
	})
	_expect(int(audio.flow_actions_taken) == 0, "Music flow restore should reset unsaved action streak count.")
	_expect(_truthy(audio.music_start_chance_unlocked), "Music flow restore should preserve start chance unlock state.")
	_expect(float(audio.flow_heat) == 36.0, "Music flow restore should cap heat.")
	_expect(float(audio.flow_active_action_seconds) == 0.0, "Music flow restore should clamp negative active seconds.")
	audio.flow_heat = 7.5
	audio.flow_active_action_seconds = 3.25
	audio.restore_music_flow_state({})
	_expect(float(audio.flow_heat) == 7.5, "Music flow restore should keep existing heat when save data omits it.")
	_expect(float(audio.flow_active_action_seconds) == 3.25, "Music flow restore should keep existing active seconds when save data omits them.")


func _check_offline_progress_trust(game: Node) -> void:
	var save_runtime = game.call("_save_runtime")
	var now := int(game.call("_unix_now"))
	game.set("last_save_monotonic_msec", 0)
	var trusted := int(save_runtime.call("_trusted_offline_seconds", now - 60, now))
	_expect(trusted == 60, "Offline progress should trust short offline windows.")

	game.set("last_save_monotonic_msec", 0)
	game.set("god_mode_save_tainted", false)
	trusted = int(save_runtime.call("_trusted_offline_seconds", now - 60 * 60, now))
	var expected := mini(60 * 60, int(game.call("_hub_surface").call("_hub_offline_cap_seconds")))
	_expect(trusted == expected, "Offline progress should trust large offline windows up to the normal cap.")
	var leaderboard_state = game.get("leaderboard_state")
	_expect(str(LeaderboardPresentation.submit_status_title(false, true, true, true, false, 0, leaderboard_state.submit_ready())) != "Clock check", "Saves should not show a leaderboard clock-check status.")
	_expect(str(LeaderboardPresentation.submit_status_detail(false, true, true, 0, false, true, false, "", 0, leaderboard_state.queued_score(), leaderboard_state.has_pending_category_score(), leaderboard_state.submit_ready())).find("Hard Reset") < 0, "Saves should not tell players to hard reset for clock reasons.")


func _check_load_save_dictionary_rejects_corrupt_files(game: Node) -> void:
	var corrupt_path := "user://codex-corrupt-save-normalization.json"
	var file := FileAccess.open(corrupt_path, FileAccess.WRITE)
	_expect(file != null, "Corrupt save parser smoke should be able to create a temp user save file.")
	if file != null:
		file.store_string("{not-valid-json")
		file.close()
	_expect(SaveRuntime.load_dictionary(corrupt_path).is_empty(), "Save loader should return an empty dictionary for invalid JSON.")

	file = FileAccess.open(corrupt_path, FileAccess.WRITE)
	if file != null:
		file.store_string("[1, 2, 3]")
		file.close()
	_expect(SaveRuntime.load_dictionary(corrupt_path).is_empty(), "Save loader should return an empty dictionary for non-dictionary JSON.")

	file = FileAccess.open(corrupt_path, FileAccess.WRITE)
	if file != null:
		file.store_string("{\"skills\":{},\"saved_at\":123}")
		file.close()
	var valid := SaveRuntime.load_dictionary(corrupt_path)
	_expect(int(valid.get("saved_at", 0)) == 123, "Save loader should still return valid dictionary JSON from user storage.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(corrupt_path))


func _check_best_save_dictionary_prefers_progress(game: Node) -> void:
	var reset_path := "user://codex-reset-save-normalization.json"
	var marked_reset_path := "user://codex-marked-reset-save-normalization.json"
	var backup_path := "user://codex-backup-save-normalization.json"
	var temp_path := "user://codex-temp-save-normalization.json"
	_write_temp_save(reset_path, {
		"skills": {
			"fight": {"xp": 0, "level": 1},
			"thieving": {"xp": 0, "level": 1},
		},
		"saved_at": 100,
	})
	_write_temp_save(backup_path, {
		"skills": {
			"fight": {"xp": 2500, "level": 12},
			"thieving": {"xp": 400, "level": 5},
		},
		"saved_at": 90,
	})
	_write_temp_save(temp_path, {
		"skills": {
			"fight": {"xp": 1200, "level": 9},
			"thieving": {"xp": 100, "level": 2},
		},
		"saved_at": 110,
	})
	var best := SaveRuntime.best_dictionary_from_paths([reset_path, temp_path, backup_path], game.skill_defs)
	var best_skills := best.get("skills", {}) as Dictionary
	var best_fight := best_skills.get("fight", {}) as Dictionary
	_expect(int(best_fight.get("xp", 0)) == 2500, "Save recovery should prefer the highest-progress candidate over an unmarked lower-progress save.")
	_write_temp_save(backup_path, {
		"skills": {
			"fight": {"xp": 0, "level": 1},
			"thieving": {"xp": 0, "level": 1},
		},
		"manual_activity_unlocks": {"fight:poke-the-training-dummy": true},
		"built_modules": {"build:cozy-firepit": true},
		"activity_completion_count": 4,
		"saved_at": 80,
	})
	best = SaveRuntime.best_dictionary_from_paths([reset_path, backup_path], game.skill_defs)
	_expect(int(best.get("activity_completion_count", 0)) == 4, "Save recovery should prefer non-XP progress over a newer empty save.")
	_write_temp_save(marked_reset_path, {
		"save_reset_generation": 500,
		"skills": {
			"fight": {"xp": 0, "level": 1},
			"thieving": {"xp": 0, "level": 1},
		},
		"saved_at": 120,
	})
	best = SaveRuntime.best_dictionary_from_paths([marked_reset_path, temp_path, backup_path], game.skill_defs)
	best_skills = best.get("skills", {}) as Dictionary
	best_fight = best_skills.get("fight", {}) as Dictionary
	_expect(int(best.get("save_reset_generation", 0)) == 500 and int(best_fight.get("xp", -1)) == 0, "Save recovery should honor a marked hard-reset save over older high-progress backups.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(reset_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(marked_reset_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))


func _check_save_payload_progress_regression_guard(game: Node) -> void:
	var save_runtime = game.call("_save_runtime")
	var existing_progress := {
		"skills": {
			"fight": {"xp": 2500, "level": 12},
			"thieving": {"xp": 400, "level": 5},
		},
		"saved_at": 200,
	}
	var reset_payload := {
		"skills": {
			"fight": {"xp": 0, "level": 1},
			"thieving": {"xp": 0, "level": 1},
		},
		"saved_at": 300,
	}
	var marked_reset_payload := reset_payload.duplicate(true)
	marked_reset_payload["save_reset_generation"] = 700
	var post_reset_existing := marked_reset_payload.duplicate(true)
	var equal_payload := {
		"skills": {
			"fight": {"xp": 2500, "level": 12},
			"thieving": {"xp": 400, "level": 5},
		},
		"saved_at": 301,
	}
	var improved_payload := {
		"skills": {
			"fight": {"xp": 2600, "level": 12},
			"thieving": {"xp": 400, "level": 5},
		},
		"saved_at": 302,
	}
	var stale_payload := improved_payload.duplicate(true)
	stale_payload["save_reset_generation"] = 0
	var non_xp_progress := reset_payload.duplicate(true)
	non_xp_progress["manual_activity_unlocks"] = {"fight:poke-the-training-dummy": true}
	non_xp_progress["built_modules"] = {"build:cozy-firepit": true}
	non_xp_progress["activity_completion_count"] = 4
	_expect(_truthy(save_runtime.call("_save_payload_regresses_progress", existing_progress, reset_payload)), "Autosave guard should detect a lower-progress reset payload.")
	_expect(_truthy(save_runtime.call("_save_payload_regresses_progress", non_xp_progress, reset_payload)), "Autosave guard should detect reset payloads that would erase non-XP progress.")
	_expect(not _truthy(save_runtime.call("_save_payload_regresses_progress", existing_progress, marked_reset_payload)), "Autosave guard should allow marked hard-reset payloads.")
	_expect(_truthy(save_runtime.call("_save_payload_regresses_progress", post_reset_existing, stale_payload)), "Autosave guard should reject stale pre-reset payloads after a marked hard reset.")
	_expect(not _truthy(save_runtime.call("_save_payload_regresses_progress", existing_progress, equal_payload)), "Autosave guard should allow equal-progress save refreshes.")
	_expect(not _truthy(save_runtime.call("_save_payload_regresses_progress", existing_progress, improved_payload)), "Autosave guard should allow improved progress.")
	_expect(not _truthy(save_runtime.call("_save_payload_regresses_progress", {}, reset_payload)), "Autosave guard should allow first saves with no existing evidence.")
	_expect(not _truthy(save_runtime.call("_save_payload_regresses_progress", {"skills": {}}, reset_payload)), "Autosave guard should allow saves when existing data has no progress evidence.")


func _check_save_payload(game: Node) -> void:
	var now := int(game.call("_unix_now"))
	var hub_runtime: Object = game.call("_hub_runtime")
	var hub_surface: Object = game.call("_hub_surface")
	var ad_bonus_runtime: Object = game.call("_ad_bonus_runtime")
	var save_runtime: Object = game.call("_save_runtime")
	game.set("mastery", {
		"fishing:dip-a-tidepool-minnow": {"xp": 18},
		"fishing:shallows": {"xp": 42},
		"fight:not-a-real-action": {"xp": 77},
	})
	game.fishing_runtime.selected_locations = {
		"beach": "rocky",
		"pier": "missing-location",
	}
	game.set("passive_modules", {
		"existing-module": {"stored": 9999, "time_seconds": 2, "yield": 99, "capacity": 9999, "seeded": true, "last_update": 1234},
		"": {"stored": 1},
		"bad-module": "bad-state",
	})
	game.thieving_state.action_jails = {
		"sneak-past-tip-jar": {"cooldown_until_unix": now + 60, "resume_when_free": true},
		"not-a-real-action": {"cooldown_until_unix": now + 60, "resume_when_free": true},
	}
	game.thieving_state.trophies = {
		"complimentary_spoon": {"stolen": true, "cooldown_until_unix": 44},
		"not-a-real-heist": {"stolen": true, "cooldown_until_unix": 99},
	}
	_install_test_convergence_action(game)
	game.set("convergence_modules", {
		"test-convergence-shrine": {"built": true, "building": true, "build_started_unix": -7, "completions": -3},
		"not-a-real-convergence": {"built": true, "building": true, "build_started_unix": 99, "completions": 8},
		"bad-entry": "bad-state",
	})
	game.call("_temporary_event_runtime").set("temporary_event_active", {
		"ambush-log-wagon": {"id": "ambush-log-wagon", "spawned_unix": -25, "expires_unix": 10, "completed": true},
		"not-a-real-event": {"id": "not-a-real-event", "spawned_unix": 1, "expires_unix": 2},
	})
	game.call("_temporary_event_runtime").set("temporary_event_cooldowns", {
		"ambush-log-wagon": 99,
		"not-a-real-event": 123,
	})
	game.call("_temporary_event_runtime").set("temporary_event_next_roll_unix", -50)
	hub_runtime.set("hub_modules", {
		"barn": {"level": 99, "building": true, "build_started_msec": 1234},
		"pond": {"level": -4, "building": false, "build_started_unix_msec": -55},
		"trophy": {"level": 4, "building": true, "build_started_unix_msec": 999},
		"not-a-real-module": {"level": 4, "building": true, "build_started_unix_msec": 999},
		"garden": "bad-state",
	})
	hub_surface.set("hub_module_positions", {
		"barn": Vector2(-100, -100),
		"trophy": Vector2(99999, 99999),
		"not-a-real-module": Vector2(500, 500),
	})
	game.leaderboard_profile.player_id = "testdecorplayer"
	hub_surface.set("hub_decor_layout", [
		{"type": "tree", "index": 99, "x": -100, "y": -100, "w": 10, "h": 10},
		{"type": "decor", "index": 99, "x": 500, "y": 500, "w": 999, "h": 999},
		{"type": "bad-type", "index": 4, "x": 20, "y": 20, "w": 100, "h": 100},
		"bad-entry",
	])
	game.set("skills", {
		"fight": {"xp": SkillState.xp_for_level(10), "level": 1},
		"woodcutting": {"xp": -99, "level": 99},
		"not-a-real-skill": {"xp": 9999, "level": 99},
	})
	game.set("stamina", {
		"fight": 999.0,
		"thieving": -4.0,
		"build": 12.5,
		"woodcutting": 30.0,
		"not-a-real-skill": 14.0,
	})
	game.set("stamina_bank", {
		"fight": 999.0,
		"thieving": 6.0,
		"build": 999.0,
		"woodcutting": 5.0,
		"not-a-real-skill": 12.0,
	})
	hub_runtime.set("hub_missions", [
		{"skill_id": "fight", "action_id": "push-ups", "target": 3, "remaining": 99, "assigned_unix": -5},
		{"skill_id": "fight", "action_id": "not-a-real-action", "target": 3, "remaining": 2},
		{"skill_id": "woodcutting", "action_id": "stack-logs-1", "target": 3, "remaining": 2},
		"bad-entry",
	])
	game.leaderboard_state.last_submitted_scores_by_category = {
		"skill_xp:fight": 40,
		"unknown-category": 99,
	}
	game.leaderboard_state.last_submitted_score = -10
	game.leaderboard_state.last_submitted_total_xp = -20
	game.leaderboard_state.last_submit_unix = -30
	game.leaderboard_profile.display_name = "  A\nName\tThat Is Too Long For Profile  "
	game.leaderboard_profile.name_key = " Bad Key! "
	game.leaderboard_profile.profile_claimed = true
	game.leaderboard_profile.name_claim_verified = false
	game.leaderboard_profile.avatar_index = 999
	game.leaderboard_profile.player_id = " bad id! "
	game.call("_online_runtime").leaderboard_auth_refresh_token = "  refresh-token  "
	game.call("_online_runtime").leaderboard_auth_retry_after_unix = -40
	(game.get("leaderboard_state") as RefCounted).set("fetch_retry_unix_by_category", {
		"skill_xp:fight": 40,
		"unknown-category": 99,
		"total_level": 12,
		"medals_earned": -5,
	})
	var chat_runtime = game.call("_online_runtime")
	chat_runtime.set("chat_last_send_unix", -10)
	chat_runtime.set("chat_stream_retry_unix", now + 9999)
	chat_runtime.set("chat_stream_next_connect_unix", -5)
	chat_runtime.set("chat_last_opened_created_at", -20)
	chat_runtime.set("chat_last_opened_message_id", "  abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij-extra  ")
	game.set("selected_skill_id", "not-a-real-skill")
	game.set("running_skill_id", "fishing")
	game.set("running_action_id", "dip-a-tidepool-minnow")
	game.set("action_progress", 1.5)
	game.call("_onboarding_runtime").set("silver_opportunity_tip_action_key", "fishing:dip-a-tidepool-minnow")
	game.call("_online_runtime").leaderboard_auth_provider = "google"
	save_runtime.set("achievement_toast_seen_ids", {
		"total-level-25": true,
		"activity-crit": false,
		"": true,
	})
	game.material_runtime.legacy_softwood_amount = -20
	var audio := game.call("_audio_director") as AudioDirector
	audio.music_volume = 1.5
	audio.sfx_volume = -0.5
	game.set("god_mode_enabled", true)
	game.set("god_mode_save_tainted", true)
	game.fishing_runtime.equipped_tool_id = "not-a-real-tool"
	game.fishing_runtime.fish_currency = -10.0
	game.fishing_runtime.net_stored_fish = 999
	game.fishing_runtime.net_successes = -2
	game.fishing_runtime.net_stored_xp = -3
	game.fishing_runtime.net_stored_mastery = -4.0
	game.fishing_runtime.net_collected = true
	game.fishing_runtime.boat_stored_fish = 999
	game.fishing_runtime.boat_successes = -5
	game.fishing_runtime.boat_stored_xp = -6
	game.fishing_runtime.boat_stored_mastery = -7.0
	game.fishing_runtime.rod_collected = false
	game.fishing_runtime.reinforced_rod_collected = false
	game.fishing_runtime.star_rod_collected = true
	hub_runtime.set("hub_selected_module_id", "trophy")
	hub_runtime.set("hub_mission_cooldown_until_unix", -12)
	game.set("plank_boost_enabled", true)
	ad_bonus_runtime.set("seconds_remaining", 999999.0)
	_action_runtime(game).set("activity_start_count", -3)
	_action_runtime(game).set("activity_completion_count", -4)
	_action_runtime(game).set("guaranteed_success_action_completions", 999)
	game.call("_onboarding_runtime").set("onboarding_starter_action_completion_count", -5)
	game.set("stamina_gauge_pre_tip_hold_seconds", 99.0)
	audio.flow_heat = 99.0
	audio.flow_active_action_seconds = -8.0

	var payload := _save_payload(game, now)
	_expect(int(payload.get("save_reset_generation", -1)) == int(_save_runtime(game).get("save_reset_generation")), "Save payload should include the current hard-reset generation.")
	var payload_mastery := payload.get("mastery", {}) as Dictionary
	_expect(payload_mastery.has("fishing:shallows"), "Save payload should include canonical mastery keys.")
	_expect(not payload_mastery.has("fishing:dip-a-tidepool-minnow"), "Save payload should not include alias mastery keys.")
	_expect(not payload_mastery.has("fight:not-a-real-action"), "Save payload should not include unknown mastery keys.")
	var payload_skills := payload.get("skills", {}) as Dictionary
	var payload_fight_skill := payload_skills.get("fight", {}) as Dictionary
	var payload_woodcutting_skill := payload_skills.get("woodcutting", {}) as Dictionary
	_expect(payload_skills.has("fight") and payload_skills.has("woodcutting") and not payload_skills.has("not-a-real-skill"), "Save payload should include only known skill ids.")
	_expect(int(payload_fight_skill.get("level", -1)) == 10, "Save payload should derive skill levels from XP.")
	_expect(int(payload_woodcutting_skill.get("xp", -1)) == 0 and int(payload_woodcutting_skill.get("level", -1)) == 1, "Save payload should clamp negative skill XP and derive level 1.")
	var payload_stamina := payload.get("stamina", {}) as Dictionary
	var payload_stamina_bank := payload.get("stamina_bank", {}) as Dictionary
	var payload_fight_max := float(SkillState.max_stamina(game, "fight"))
	_expect(payload_stamina.has("fight") and payload_stamina.has("build") and not payload_stamina.has("not-a-real-skill"), "Save payload should include only known stamina skill ids.")
	_expect(float(payload_stamina.get("fight", -1.0)) == payload_fight_max, "Save payload should clamp stamina above the max.")
	_expect(float(payload_stamina.get("thieving", -1.0)) == 0.0, "Save payload should clamp negative stamina.")
	_expect(float(payload_stamina.get("build", -1.0)) == 12.5, "Save payload should preserve fractional stamina.")
	_expect(float(payload_stamina_bank.get("fight", -1.0)) == 0.0, "Save payload should reset full-stamina banks.")
	_expect(float(payload_stamina_bank.get("build", -1.0)) == 12.0, "Save payload should preserve clamped regen-bank progress independently from fractional stamina.")
	_expect(not payload_stamina_bank.has("not-a-real-skill"), "Save payload should include only known stamina bank skill ids.")
	var payload_locations := payload.get("selected_fishing_locations", {}) as Dictionary
	_expect(payload_locations.size() == 1 and str(payload_locations.get("beach", "")) == "rocky", "Save payload should include only valid fishing selections.")
	_expect(int(payload.get("log_currency", -1)) == 0, "Save payload should clamp log currency.")
	_expect(float(payload.get("music_volume", -1.0)) == 1.0, "Save payload should cap music volume.")
	_expect(float(payload.get("sfx_volume", -1.0)) == 0.0, "Save payload should clamp SFX volume.")
	_expect(not payload.has("is_muted"), "Save payload should not include obsolete global mute state.")
	_expect(_truthy(payload.get("god_mode_enabled", false)), "Debug save payload should preserve enabled God Mode.")
	_expect(_truthy(payload.get("god_mode_save_tainted", false)), "Save payload should preserve god mode taint state.")
	_expect(not payload.has("offline_clock_guard_tainted"), "Save payload should stop preserving obsolete offline clock guard taint state.")
	_expect(not payload.has("offline_clock_guard_last_rejected_unix"), "Save payload should stop preserving obsolete offline clock guard rejection timestamps.")
	_expect(not payload.has("saved_at_monotonic_msec"), "Save payload should stop preserving monotonic timing for obsolete same-session clock checks.")
	_expect(str(payload.get("equipped_fishing_tool_id", "")) == "hands", "Save payload should normalize invalid equipped fishing tool ids.")
	_expect(float(payload.get("fish_currency", -1.0)) == 0.0, "Save payload should clamp fishing currency.")
	_expect(int(payload.get("fishing_net_stored_fish", -1)) == 9, "Save payload should cap fishing net stored fish.")
	_expect(int(payload.get("fishing_net_successes", -1)) == 0, "Save payload should clamp fishing net successes.")
	_expect(int(payload.get("fishing_net_stored_xp", -1)) == 0, "Save payload should clamp fishing net stored XP.")
	_expect(float(payload.get("fishing_net_stored_mastery", -1.0)) == 0.0, "Save payload should clamp fishing net stored mastery.")
	_expect(_truthy(payload.get("fishing_net_collect_completed", false)), "Save payload should keep canonical fishing net collection state.")
	_expect(not payload.has("fishing_net_collected"), "Save payload should not include legacy fishing net collection state.")
	_expect(int(payload.get("fishing_boat_stored_fish", -1)) == 199, "Save payload should cap fishing boat stored fish.")
	_expect(int(payload.get("fishing_boat_successes", -1)) == 0, "Save payload should clamp fishing boat successes.")
	_expect(int(payload.get("fishing_boat_stored_xp", -1)) == 0, "Save payload should clamp fishing boat stored XP.")
	_expect(float(payload.get("fishing_boat_stored_mastery", -1.0)) == 0.0, "Save payload should clamp fishing boat stored mastery.")
	_expect(_truthy(payload.get("fishing_rod_collected", false)) and _truthy(payload.get("fishing_reinforced_rod_collected", false)) and _truthy(payload.get("fishing_star_rod_collected", false)), "Save payload should normalize fishing rod collection hierarchy.")
	var payload_passive := payload.get("passive_modules", {}) as Dictionary
	_expect(payload_passive.size() == 1 and payload_passive.has("existing-module"), "Save payload should include only valid passive module entries.")
	var payload_passive_state := payload_passive.get("existing-module", {}) as Dictionary
	_expect(int(payload_passive_state.get("stored", -1)) == 1000, "Save payload should clamp passive stored values.")
	_expect(int(payload_passive_state.get("time_seconds", -1)) == 30, "Save payload should clamp passive time values.")
	_expect(int(payload_passive_state.get("yield", -1)) == 18, "Save payload should clamp passive yield values.")
	_expect(int(payload_passive_state.get("capacity", -1)) == 1000, "Save payload should clamp passive capacity values.")
	var payload_jails := payload.get("thieving_action_jails", {}) as Dictionary
	_expect(payload_jails.size() == 1 and payload_jails.has("sneak-past-tip-jar"), "Save payload should include only valid active thieving jails.")
	var payload_trophies := payload.get("thieving_trophies", {}) as Dictionary
	_expect(payload_trophies.size() == 1 and payload_trophies.has("complimentary_spoon"), "Save payload should include only valid thieving trophy entries.")
	var payload_convergence := payload.get("convergence_modules", {}) as Dictionary
	_expect(payload_convergence.size() == 1 and payload_convergence.has("test-convergence-shrine"), "Save payload should include only valid convergence module entries.")
	var payload_convergence_state := payload_convergence.get("test-convergence-shrine", {}) as Dictionary
	_expect(int(payload_convergence_state.get("build_started_unix", -1)) == 0, "Save payload should clamp convergence build timestamps.")
	_expect(int(payload_convergence_state.get("completions", -1)) == 0, "Save payload should clamp convergence completion counts.")
	var payload_events := payload.get("temporary_events", {}) as Dictionary
	var payload_active_events := payload_events.get("active", {}) as Dictionary
	var payload_event_cooldowns := payload_events.get("cooldowns", {}) as Dictionary
	_expect(payload_active_events.size() == 1 and payload_active_events.has("ambush-log-wagon"), "Save payload should include only valid active temporary events.")
	_expect(payload_event_cooldowns.size() == 1 and payload_event_cooldowns.has("ambush-log-wagon"), "Save payload should include only valid temporary event cooldowns.")
	_expect(int(payload_events.get("next_roll_unix", -1)) == 0, "Save payload should clamp temporary event next-roll timestamps.")
	var payload_hub_modules := payload.get("hub_modules", {}) as Dictionary
	_expect(payload_hub_modules.size() == 2 and payload_hub_modules.has("barn") and payload_hub_modules.has("pond"), "Save payload should include only valid hub module entries.")
	_expect(not payload_hub_modules.has("trophy"), "Save payload should not include derived trophy hub state.")
	var payload_barn := payload_hub_modules.get("barn", {}) as Dictionary
	_expect(int(payload_barn.get("level", -1)) == 4, "Save payload should clamp hub module levels.")
	_expect(int(payload_barn.get("build_started_unix_msec", 0)) == 1234, "Save payload should preserve legacy hub build timestamps through the canonical field.")
	var payload_positions := payload.get("hub_module_positions", {}) as Dictionary
	_expect(payload_positions.size() == 2 and payload_positions.has("barn") and payload_positions.has("trophy"), "Save payload should include only storable hub module positions.")
	var payload_barn_position := payload_positions.get("barn", {}) as Dictionary
	_expect(float(payload_barn_position.get("x", 0.0)) == 160.0 and float(payload_barn_position.get("y", 0.0)) == 180.0, "Save payload should clamp hub module positions.")
	var payload_decor := payload.get("hub_decor_layout", []) as Array
	_expect(payload_decor.size() == 2, "Save payload should include only valid hub decor entries.")
	var payload_tree := payload_decor[0] as Dictionary
	_expect(int(payload_tree.get("index", -1)) == 5, "Save payload should clamp hub tree decor indexes.")
	_expect(float(payload_tree.get("w", 0.0)) == 80.0 and float(payload_tree.get("h", 0.0)) == 80.0, "Save payload should clamp hub decor sizes.")
	var payload_missions := payload.get("hub_missions", []) as Array
	_expect(payload_missions.size() == 1, "Save payload should include only valid hub missions.")
	var payload_mission := payload_missions[0] as Dictionary
	_expect(str(payload_mission.get("action_id", "")) == "push-ups", "Save payload should preserve canonical hub mission actions.")
	_expect(int(payload_mission.get("remaining", 0)) == 3, "Save payload should clamp hub mission remaining counts.")
	var payload_scores := payload.get("leaderboard_last_submitted_scores_by_category", {}) as Dictionary
	_expect(payload_scores.has("skill_xp:fight") and payload_scores.has("total_level") and not payload_scores.has("unknown-category"), "Save payload should include only canonical leaderboard category score keys.")
	_expect(int(payload.get("leaderboard_last_submitted_score", -1)) == 0, "Save payload should clamp leaderboard last score.")
	_expect(int(payload.get("leaderboard_last_submitted_total_xp", -1)) == 0, "Save payload should clamp leaderboard last total XP.")
	_expect(int(payload.get("leaderboard_last_submit_unix", -1)) == 0, "Save payload should clamp leaderboard last submit timestamps.")
	_expect(str(payload.get("leaderboard_display_name", "")) == "A Name That Is T", "Save payload should sanitize leaderboard display names.")
	_expect(str(payload.get("leaderboard_name_key", "bad")).is_empty(), "Save payload should sanitize leaderboard name keys.")
	_expect(not _truthy(payload.get("leaderboard_profile_claimed", true)), "Save payload should clear invalid leaderboard profile claims.")
	_expect(not _truthy(payload.get("leaderboard_name_claim_verified", true)), "Save payload should clear invalid leaderboard profile verification.")
	_expect(int(payload.get("leaderboard_avatar_index", -1)) == 19, "Save payload should clamp leaderboard avatar indexes.")
	_expect(str(payload.get("leaderboard_player_id", "bad")).is_empty(), "Save payload should sanitize leaderboard player ids.")
	_expect(str(payload.get("leaderboard_auth_provider", "")) == "google", "Save payload should preserve sanitized leaderboard auth providers.")
	_expect(str(payload.get("leaderboard_auth_refresh_token", "")) == "refresh-token", "Save payload should trim leaderboard refresh tokens.")
	_expect(int(payload.get("leaderboard_auth_retry_after_unix", -1)) == 0, "Save payload should clamp leaderboard auth retry timestamps.")
	var payload_fetch_retry := payload.get("leaderboard_fetch_retry_unix_by_category", {}) as Dictionary
	_expect(payload_fetch_retry.has("skill_xp:fight") and payload_fetch_retry.has("total_level") and not payload_fetch_retry.has("unknown-category"), "Save payload should include only canonical leaderboard fetch retry categories.")
	_expect(int(payload_fetch_retry.get("total_level", 0)) == 99, "Save payload should keep the highest leaderboard fetch retry timestamp for duplicate canonical categories.")
	_expect(int(payload_fetch_retry.get("medals_earned", -1)) == 0, "Save payload should clamp leaderboard fetch retry timestamps.")
	_expect(int(payload.get("chat_last_send_unix", -1)) == 0, "Save payload should clamp chat last-send timestamps.")
	_expect(int(payload.get("chat_stream_retry_unix", 0)) == now + 30, "Save payload should cap chat retry timestamps.")
	_expect(int(payload.get("chat_stream_next_connect_unix", 0)) == now + 30, "Save payload should cap chat next-connect timestamps.")
	_expect(int(payload.get("chat_last_opened_created_at", -1)) == 0, "Save payload should clamp chat opened cursor timestamps.")
	_expect(str(payload.get("chat_last_opened_message_id", "")).length() == 64, "Save payload should truncate chat opened message ids.")
	_expect(str(payload.get("selected_skill_id", "")) == "fight", "Save payload should replace unknown selected skill ids with the default skill.")
	_expect(str(payload.get("running_skill_id", "")) == "fishing", "Save payload should preserve valid running skill ids.")
	_expect(str(payload.get("running_action_id", "")) == "shallows", "Save payload should canonicalize the running action id.")
	_expect(float(payload.get("action_progress", -1.0)) == 0.999, "Save payload should cap action progress below completion.")
	_expect(str(payload.get("silver_opportunity_tip_action_key", "")) == "fishing:shallows", "Save payload should canonicalize saved action-key fields.")
	var payload_seen := payload.get("achievement_toast_seen_ids", {}) as Dictionary
	_expect(payload_seen.size() == 1 and _truthy(payload_seen.get("total-level-25", false)), "Save payload should include only normalized achievement toast seen ids.")
	_expect(str(payload.get("hub_selected_module_id", "")) == "pond", "Save payload should mirror restore behavior for derived hub selections.")
	_expect(int(payload.get("hub_mission_cooldown_until_unix", -1)) == 0, "Save payload should clamp hub mission cooldown timestamps.")
	_expect(_truthy(payload.get("plank_boost_enabled", false)), "Save payload should preserve plank boost enabled state.")
	_expect(float(payload.get("ad_bonus_seconds_remaining", 0.0)) == 21600.0, "Save payload should cap ad bonus seconds.")
	_expect(int(payload.get("activity_start_count", -1)) == 0, "Save payload should clamp activity start counts.")
	_expect(int(payload.get("activity_completion_count", -1)) == 0, "Save payload should clamp activity completion counts.")
	_expect(int(payload.get("guaranteed_success_action_completions", -1)) == 7, "Save payload should cap guaranteed-success completions.")
	_expect(int(payload.get("onboarding_starter_action_completion_count", -1)) == 0, "Save payload should clamp onboarding starter completions.")
	_expect(float(payload.get("stamina_gauge_pre_tip_hold_seconds", 0.0)) == 4.0, "Save payload should cap stamina tip hold seconds.")
	_expect(float(payload.get("flow_heat", 0.0)) == 36.0, "Save payload should cap music flow heat.")
	_expect(float(payload.get("flow_active_action_seconds", -1.0)) == 0.0, "Save payload should clamp music flow active seconds.")
	_expect(int(payload.get("saved_at", 0)) == now, "Save payload should use the supplied timestamp.")


func _check_passive_module_save(game: Node) -> void:
	game.set("passive_modules", {
		"existing-module": {"stored": 9999, "time_seconds": 2, "yield": 99, "capacity": 9999, "seeded": true, "last_update": 1234},
		"": {"stored": 1},
		"bad-module": "bad-state",
	})
	var passive_modules_runtime = game.call("_passive_modules_runtime")
	var saved := passive_modules_runtime.for_save() as Dictionary
	_expect(saved.size() == 1, "Passive module save should only keep named dictionary module entries.")
	_expect(saved.has("existing-module"), "Passive module save should preserve valid module ids.")
	var existing := saved.get("existing-module", {}) as Dictionary
	_expect(int(existing.get("stored", -1)) == 1000, "Passive module save should clamp stored values.")
	_expect(int(existing.get("time_seconds", -1)) == 30, "Passive module save should clamp time values.")
	_expect(int(existing.get("yield", -1)) == 18, "Passive module save should clamp yield values.")
	_expect(int(existing.get("capacity", -1)) == 1000, "Passive module save should clamp capacity values.")
	_expect(_truthy(existing.get("seeded", false)), "Passive module save should preserve seeded state.")
	_expect(int(existing.get("last_update", 0)) == 1234, "Passive module save should preserve module update timestamps.")


func _check_passive_module_restore(game: Node) -> void:
	game.set("passive_modules", {})
	game.call("_passive_modules_runtime").restore_from_save({
		"passive_modules": {
			"existing-module": {"stored": 7, "time_seconds": 20, "yield": 2, "capacity": 8, "seeded": true, "last_update": 1234},
			"bad-module": "bad-entry",
		}
	})
	var restored := game.get("passive_modules") as Dictionary
	_expect(restored.has("existing-module"), "Passive restore should load valid passive module entries.")
	_expect(not restored.has("bad-module"), "Passive restore should skip malformed passive module entries.")
	var existing := restored.get("existing-module", {}) as Dictionary
	_expect(int(existing.get("stored", -1)) == 7, "Passive restore should preserve stored module value.")
	_expect(_truthy(existing.get("seeded", false)), "Passive restore should preserve seeded module state.")
	_expect(int(existing.get("last_update", 0)) == 1234, "Passive restore should preserve module update timestamp.")

	game.set("passive_modules", {
		"existing-module": {"stored": 99, "time_seconds": 99, "yield": 99, "capacity": 99, "seeded": false, "last_update": 99},
	})
	game.call("_passive_modules_runtime").restore_from_save({
		"passive_modules": {
			"existing-module": {"stored": 1, "time_seconds": 1, "yield": 1, "capacity": 1, "seeded": true, "last_update": 1},
			"new-module": {"stored": 3, "time_seconds": 20, "yield": 2, "capacity": 8, "seeded": true, "last_update": 4321},
		}
	}, true)
	restored = game.get("passive_modules") as Dictionary
	existing = restored.get("existing-module", {}) as Dictionary
	var new_module := restored.get("new-module", {}) as Dictionary
	_expect(int(existing.get("stored", 0)) == 99, "Passive secondary restore should preserve existing module state.")
	_expect(int(new_module.get("stored", 0)) == 3, "Passive secondary restore should add missing module state.")
	_expect(int(new_module.get("last_update", 0)) == 4321, "Passive secondary restore should use the shared module normalizer.")


func _entry_xp(source: Dictionary, key: String) -> int:
	var entry := source.get(key, {}) as Dictionary
	return int(round(float(entry.get("xp", 0))))


func _install_test_convergence_action(game: Node) -> void:
	var actions_by_key := game.get("actions_by_key") as Dictionary
	actions_by_key["build:test-convergence-shrine"] = {
		"id": "test-convergence-shrine",
		"name": "Test Convergence Shrine",
		"kind": "convergence_module",
		"unlock": 1,
	}
	game.set("actions_by_key", actions_by_key)


func _unlock_all_normal_actions_for_test(game: Node, skill_id: String) -> void:
	var manual := game.get("manual_activity_unlocks") as Dictionary
	var actions_by_skill := game.get("actions_by_skill") as Dictionary
	for raw_action in actions_by_skill.get(skill_id, []) as Array:
		var action := raw_action as Dictionary
		if str(action.get("kind", "activity")) != "activity":
			continue
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		manual[str(game.call("_action_key", skill_id, action_id))] = true
	game.set("manual_activity_unlocks", manual)


func _entry_index_for_action_id(entries: Array, action_id: String) -> int:
	for i in range(entries.size()):
		var entry := entries[i] as Dictionary
		if str(entry.get("kind", "")) != "action":
			continue
		var action := entry.get("action", {}) as Dictionary
		if str(action.get("id", "")) == action_id:
			return i
	return -1


func _plan_index_for_track_id(plan: Array, track_id: String) -> int:
	for i in range(plan.size()):
		var item := plan[i] as Dictionary
		if str(item.get("track_id", "")) == track_id:
			return i
	return -1


func _prime_core_skill_state(game: Node) -> void:
	var skills_by_id := {}
	var stamina_by_id := {}
	var stamina_bank_by_id := {}
	for raw_def in game.get("skill_defs") as Array:
		var skill_def := raw_def as Dictionary
		var skill_id := str(skill_def.get("id", ""))
		if skill_id.is_empty():
			continue
		skills_by_id[skill_id] = {"xp": 0, "level": 1}
		stamina_by_id[skill_id] = 10.0
		stamina_bank_by_id[skill_id] = 0.0
	game.set("skills", skills_by_id)
	game.set("stamina", stamina_by_id)
	game.set("stamina_bank", stamina_bank_by_id)
	game.set("passive_modules", {})
	game.set("convergence_modules", {})


func _write_temp_save(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "Save recovery test should be able to create temp save file %s." % path)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _truthy(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return not is_zero_approx(float(value))
		TYPE_STRING:
			return not str(value).is_empty()
		_:
			return value != null


func _finish() -> void:
	if failures.is_empty():
		print("save-normalization-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $previousDisableSaveWrites = $env:IDLE_ELITE_DISABLE_SAVE_WRITES
    $env:IDLE_ELITE_DISABLE_SAVE_WRITES = "1"
    $beforeHeadless = @(Get-HeadlessGodotProcesses)
    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "save-normalization-ok") "Save normalization test did not report success."
    Assert-NoUnexpectedGodotErrors $output "save normalization test"

    $afterHeadless = @(Get-HeadlessGodotProcesses)
    $beforeIds = @($beforeHeadless | ForEach-Object { $_.ProcessId })
    $newHeadless = @($afterHeadless | Where-Object { $beforeIds -notcontains $_.ProcessId })
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the save normalization test."
    }
} finally {
    if ($null -eq $previousDisableSaveWrites) {
        Remove-Item Env:\IDLE_ELITE_DISABLE_SAVE_WRITES -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_DISABLE_SAVE_WRITES = $previousDisableSaveWrites
    }
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
