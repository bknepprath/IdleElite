$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\save-normalization"
$testScript = Join-Path $testDir "save_normalization_test.gd"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

function Assert-NoUnexpectedGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Output) {
        return
    }

    foreach ($line in @($Output)) {
        $text = [string]$line
        if ($text -notmatch '^(ERROR|SCRIPT ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match '^ERROR: \d+ RID allocations of type .+ were leaked at exit\.$' -or
            $text -match '^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    @'
extends SceneTree

const MainScript := preload("res://scripts/main.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := MainScript.new()
	game.call("_load_action_data")

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
	_check_hub_module_save_restore(game)
	_check_hub_module_position_save_restore(game)
	_check_hub_decor_layout_save_restore(game)
	_check_hub_mission_save_restore(game)
	_check_leaderboard_scores_save(game)
	_check_leaderboard_profile_auth_save_restore(game)
	_check_leaderboard_fetch_retry_save_restore(game)
	_check_chat_metadata_save_restore(game)
	_check_resource_and_audio_settings_save(game)
	_check_god_mode_save(game)
	_check_active_skill_identity_save(game)
	_check_running_action_save(game)
	_check_action_progress_save_restore(game)
	_check_action_key_save(game)
	_check_achievement_toast_seen_ids_save_restore(game)
	_check_scalar_progression_metadata_save(game)
	_check_save_payload(game)
	_check_passive_module_save(game)
	_check_passive_module_restore(game)

	game.free()
	_finish()


func _check_mastery_restore(game: Node) -> void:
	game.call("_restore_mastery_from_save", {
		"fishing:dip-a-tidepool-minnow": {"xp": 12},
		"fishing:beach-shallows": {"xp": 31},
		"woodcutting:stack-logs-1": {"xp": 99},
		"fight:not-a-real-action": {"xp": 77},
		"malformed-key": {"xp": 66},
		"fight:shove-wobbly-hay-bale": "bad-entry",
	})
	var restored := game.get("mastery") as Dictionary
	_expect(restored.has("fishing:beach-shallows"), "Mastery restore should canonicalize fishing action aliases.")
	_expect(_entry_xp(restored, "fishing:beach-shallows") == 31, "Mastery restore should keep the highest XP for duplicate canonical keys.")
	_expect(not restored.has("woodcutting:stack-logs-1"), "Mastery restore should drop passive action keys.")
	_expect(not restored.has("fight:not-a-real-action"), "Mastery restore should drop unknown action keys.")
	_expect(not restored.has("malformed-key"), "Mastery restore should drop malformed action keys.")
	_expect(not restored.has("fight:shove-wobbly-hay-bale"), "Mastery restore should drop malformed mastery entries.")


func _check_mastery_save(game: Node) -> void:
	game.set("mastery", {
		"fishing:dip-a-tidepool-minnow": {"xp": 18},
		"fishing:beach-shallows": {"xp": 42},
		"woodcutting:stack-logs-1": {"xp": 99},
		"fight:not-a-real-action": {"xp": 77},
		"malformed-key": {"xp": 66},
	})
	var saved := game.call("_mastery_for_save") as Dictionary
	_expect(saved.has("fishing:beach-shallows"), "Mastery save should canonicalize fishing action aliases.")
	_expect(_entry_xp(saved, "fishing:beach-shallows") == 42, "Mastery save should keep the highest XP for duplicate canonical keys.")
	_expect(not saved.has("woodcutting:stack-logs-1"), "Mastery save should drop passive action keys.")
	_expect(not saved.has("fight:not-a-real-action"), "Mastery save should drop unknown action keys.")
	_expect(not saved.has("malformed-key"), "Mastery save should drop malformed action keys.")


func _check_skills_save(game: Node) -> void:
	var level_10_xp := int(game.call("_xp_for_level", 10))
	game.set("skills", {
		"fight": {"xp": level_10_xp, "level": 1},
		"thieving": {"xp": -50, "level": 99},
		"build": "bad-state",
		"not-a-real-skill": {"xp": 9999, "level": 99},
	})
	var saved := game.call("_skills_for_save") as Dictionary
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
	var saved_stamina := game.call("_stamina_for_save") as Dictionary
	var saved_bank := game.call("_stamina_bank_for_save") as Dictionary
	_expect(saved_stamina.has("fight") and saved_stamina.has("thieving") and saved_stamina.has("build"), "Stamina save should include known skills.")
	_expect(not saved_stamina.has("not-a-real-skill"), "Stamina save should drop unknown skill ids.")
	_expect(float(saved_stamina.get("fight", -1.0)) == 30.0, "Stamina save should clamp values above max stamina.")
	_expect(float(saved_stamina.get("thieving", -1.0)) == 0.0, "Stamina save should clamp negative stamina.")
	_expect(float(saved_stamina.get("build", -1.0)) == 12.5, "Stamina save should preserve fractional stamina.")
	_expect(float(saved_bank.get("fight", -1.0)) == 0.0, "Stamina bank save should reset full-stamina banks.")
	_expect(float(saved_bank.get("build", -1.0)) == 6.0, "Stamina bank save should derive fractional progress from stamina.")
	_expect(not saved_bank.has("not-a-real-skill"), "Stamina bank save should drop unknown skill ids.")


func _check_fishing_location_save(game: Node) -> void:
	game.set("selected_fishing_locations", {
		"beach": "rocky",
		"pier": "missing-location",
		"lake": "ghost",
		"unknown-area": "shallows",
	})
	var saved := game.call("_selected_fishing_locations_for_save") as Dictionary
	_expect(saved.size() == 1, "Fishing location save should only keep valid area/location selections.")
	_expect(str(saved.get("beach", "")) == "rocky", "Fishing location save should preserve the valid beach selection.")


func _check_fishing_location_restore(game: Node) -> void:
	game.set("selected_fishing_locations", {"beach": "rocky"})
	game.call("_restore_selected_fishing_locations_from_save", "bad-entry")
	var restored := game.get("selected_fishing_locations") as Dictionary
	_expect(restored.is_empty(), "Fishing location restore should clear malformed saved selections.")
	game.call("_restore_selected_fishing_locations_from_save", {
		"beach": "rocky",
		"pier": "missing-location",
		"lake": "ghost",
		"unknown-area": "shallows",
	})
	restored = game.get("selected_fishing_locations") as Dictionary
	_expect(restored.size() == 1, "Fishing location restore should only keep valid area/location selections.")
	_expect(str(restored.get("beach", "")) == "rocky", "Fishing location restore should preserve the valid beach selection.")


func _check_equipped_fishing_tool_save_restore(game: Node) -> void:
	game.set("fishing_rod_collected", true)
	game.set("fishing_reinforced_rod_collected", true)
	game.set("fishing_star_rod_collected", false)
	game.set("equipped_fishing_tool_id", "line")
	_expect(str(game.call("_equipped_fishing_tool_id_for_save")) == "reinforced_rod", "Equipped fishing tool save should collapse stale rod ids to the highest collected rod.")
	var payload := game.call("_save_payload", int(game.call("_unix_now"))) as Dictionary
	_expect(str(payload.get("equipped_fishing_tool_id", "")) == "reinforced_rod", "Save payload should serialize normalized equipped fishing tool ids.")

	game.set("equipped_fishing_tool_id", "not-a-real-tool")
	_expect(str(game.call("_equipped_fishing_tool_id_for_save")) == "hands", "Equipped fishing tool save should fall back to hands for invalid tool ids.")

	game.set("fishing_rod_collected", false)
	game.set("fishing_reinforced_rod_collected", false)
	game.set("fishing_star_rod_collected", false)
	game.set("equipped_fishing_tool_id", "hands")
	game.call("_restore_fishing_state_from_save", {"selected_skill_id": "fishing", "equipped_fishing_tool_id": "star_rod"})
	_expect(str(game.get("equipped_fishing_tool_id")) == "star_rod", "Fishing tool restore should still accept legacy equipped-tool unlocks.")
	_expect(bool(game.get("fishing_rod_collected")) and bool(game.get("fishing_reinforced_rod_collected")) and bool(game.get("fishing_star_rod_collected")), "Legacy star rod restore should still reconcile collected rod state.")


func _check_fishing_rod_collection_save_restore(game: Node) -> void:
	game.set("fishing_rod_collected", false)
	game.set("fishing_reinforced_rod_collected", false)
	game.set("fishing_star_rod_collected", true)
	_expect(bool(game.call("_fishing_rod_collected_for_save")), "Fishing rod save should infer base rod from star rod collection.")
	_expect(bool(game.call("_fishing_reinforced_rod_collected_for_save")), "Fishing rod save should infer reinforced rod from star rod collection.")
	var payload := game.call("_save_payload", int(game.call("_unix_now"))) as Dictionary
	_expect(bool(payload.get("fishing_rod_collected", false)), "Save payload should not write star rod without base rod collection.")
	_expect(bool(payload.get("fishing_reinforced_rod_collected", false)), "Save payload should not write star rod without reinforced rod collection.")
	_expect(bool(payload.get("fishing_star_rod_collected", false)), "Save payload should preserve star rod collection.")

	game.set("fishing_rod_collected", false)
	game.set("fishing_reinforced_rod_collected", false)
	game.set("fishing_star_rod_collected", false)
	game.call("_restore_fishing_state_from_save", {
		"selected_skill_id": "fishing",
		"fishing_star_rod_collected": true,
	})
	_expect(bool(game.get("fishing_rod_collected")) and bool(game.get("fishing_reinforced_rod_collected")) and bool(game.get("fishing_star_rod_collected")), "Fishing rod restore should repair legacy saves where star rod is missing earlier rod flags.")

	game.set("fishing_rod_collected", false)
	game.set("fishing_reinforced_rod_collected", true)
	game.set("fishing_star_rod_collected", false)
	game.call("_reconcile_fishing_rod_collection_state")
	_expect(bool(game.get("fishing_rod_collected")) and bool(game.get("fishing_reinforced_rod_collected")) and not bool(game.get("fishing_star_rod_collected")), "Fishing rod reconciliation should infer base rod from reinforced rod without granting star rod.")


func _check_fishing_numeric_state_save(game: Node) -> void:
	game.set("fish_currency", -10.0)
	_expect(float(game.call("_fish_currency_for_save")) == 0.0, "Fishing currency save should clamp negative values.")
	game.set("fishing_net_stored_fish", 999)
	_expect(int(game.call("_fishing_net_stored_fish_for_save")) == 9, "Fishing net stored-fish save should cap below the haul threshold.")
	game.set("fishing_net_successes", -2)
	_expect(int(game.call("_fishing_net_successes_for_save")) == 0, "Fishing net successes save should clamp negative counts.")
	game.set("fishing_net_stored_xp", -3)
	_expect(int(game.call("_fishing_net_stored_xp_for_save")) == 0, "Fishing net stored XP save should clamp negative values.")
	game.set("fishing_net_stored_mastery", -4.0)
	_expect(float(game.call("_fishing_net_stored_mastery_for_save")) == 0.0, "Fishing net stored mastery save should clamp negative values.")
	game.set("fishing_boat_stored_fish", 999)
	_expect(int(game.call("_fishing_boat_stored_fish_for_save")) == 199, "Fishing boat stored-fish save should cap below the haul threshold.")
	game.set("fishing_boat_successes", -5)
	_expect(int(game.call("_fishing_boat_successes_for_save")) == 0, "Fishing boat successes save should clamp negative counts.")
	game.set("fishing_boat_stored_xp", -6)
	_expect(int(game.call("_fishing_boat_stored_xp_for_save")) == 0, "Fishing boat stored XP save should clamp negative values.")
	game.set("fishing_boat_stored_mastery", -7.0)
	_expect(float(game.call("_fishing_boat_stored_mastery_for_save")) == 0.0, "Fishing boat stored mastery save should clamp negative values.")


func _check_fishing_net_collection_save_restore(game: Node) -> void:
	game.set("fishing_net_collected", true)
	var payload := game.call("_save_payload", int(game.call("_unix_now"))) as Dictionary
	_expect(bool(payload.get("fishing_net_collect_completed", false)), "Fishing net save should keep the canonical collection-completed field.")
	_expect(not payload.has("fishing_net_collected"), "Fishing net save should not write the legacy collection field.")

	game.set("fishing_net_collected", false)
	game.call("_restore_fishing_state_from_save", {"selected_skill_id": "fishing", "fishing_net_collected": true})
	_expect(bool(game.get("fishing_net_collected")), "Fishing net restore should still accept the legacy collection field.")


func _check_thieving_jail_save(game: Node) -> void:
	var now := int(game.call("_unix_now"))
	game.set("thieving_action_jails", {
		"borrow-a-cookie-permanently": {"cooldown_until_unix": now + 60, "resume_when_free": true},
		"pocket-a-penny-nobody-wanted": {"cooldown_until_unix": now - 1, "resume_when_free": true},
		"not-a-real-action": {"cooldown_until_unix": now + 60, "resume_when_free": true},
		"sneak-past-tip-jar-eye-contact": "bad-entry",
	})
	var saved := game.call("_thieving_action_jails_for_save", now) as Dictionary
	_expect(saved.size() == 1, "Thieving jail save should only keep active valid jail entries.")
	_expect(saved.has("borrow-a-cookie-permanently"), "Thieving jail save should preserve the valid active jail.")
	var jail := saved.get("borrow-a-cookie-permanently", {}) as Dictionary
	_expect(bool(jail.get("resume_when_free", false)), "Thieving jail save should preserve the resume flag.")


func _check_thieving_jail_restore(game: Node) -> void:
	var now := int(game.call("_unix_now"))
	game.set("thieving_action_jails", {"borrow-a-cookie-permanently": {"cooldown_until_unix": now + 60, "resume_when_free": true}})
	game.call("_restore_thieving_action_jails_from_save", "bad-entry")
	var restored := game.get("thieving_action_jails") as Dictionary
	_expect(restored.is_empty(), "Thieving jail restore should clear malformed saved jail data.")
	game.call("_restore_thieving_action_jails_from_save", {
		"borrow-a-cookie-permanently": {"cooldown_until_unix": now + 60, "resume_when_free": true},
		"pocket-a-penny-nobody-wanted": now + 120,
		"sneak-past-tip-jar-eye-contact": {"cooldown_until_unix": now - 1, "resume_when_free": true},
		"not-a-real-action": {"cooldown_until_unix": now + 60, "resume_when_free": true},
	})
	restored = game.get("thieving_action_jails") as Dictionary
	_expect(restored.size() == 2, "Thieving jail restore should keep active valid dictionary and legacy scalar entries.")
	_expect(restored.has("borrow-a-cookie-permanently"), "Thieving jail restore should preserve valid dictionary entries.")
	_expect(restored.has("pocket-a-penny-nobody-wanted"), "Thieving jail restore should preserve legacy scalar cooldown entries.")
	var dictionary_jail := restored.get("borrow-a-cookie-permanently", {}) as Dictionary
	var legacy_jail := restored.get("pocket-a-penny-nobody-wanted", {}) as Dictionary
	_expect(bool(dictionary_jail.get("resume_when_free", false)), "Thieving jail restore should preserve dictionary resume flags.")
	_expect(not bool(legacy_jail.get("resume_when_free", true)), "Thieving jail restore should default legacy scalar resume flags to false.")


func _check_thieving_trophy_save_restore(game: Node) -> void:
	game.call("_restore_thieving_trophies_from_save", {"thieving_trophies": "bad-entry"})
	var restored := game.get("thieving_trophies") as Dictionary
	_expect(restored.is_empty(), "Thieving trophy restore should clear malformed saved trophy data.")
	game.call("_restore_thieving_trophies_from_save", {
		"thieving_trophies": {
			"complimentary_spoon": {"stolen": true, "cooldown_until_unix_msec": 1234},
			"crown_jewel_replica_replica": true,
			"not-a-real-heist": {"stolen": true, "cooldown_until_unix": 99},
		}
	})
	restored = game.get("thieving_trophies") as Dictionary
	_expect(restored.size() == 2, "Thieving trophy restore should keep known trophy ids only.")
	_expect(restored.has("complimentary_spoon"), "Thieving trophy restore should preserve valid dictionary entries.")
	_expect(restored.has("crown_jewel_replica_replica"), "Thieving trophy restore should preserve valid legacy boolean entries.")
	var spoon := restored.get("complimentary_spoon", {}) as Dictionary
	var crown := restored.get("crown_jewel_replica_replica", {}) as Dictionary
	_expect(bool(spoon.get("stolen", false)), "Thieving trophy restore should preserve stolen state.")
	_expect(int(spoon.get("cooldown_until_unix", 0)) == 1234, "Thieving trophy restore should preserve legacy millisecond cooldown field.")
	_expect(bool(crown.get("stolen", false)), "Thieving trophy restore should preserve legacy boolean stolen state.")

	game.set("thieving_trophies", {
		"complimentary_spoon": {"stolen": true, "cooldown_until_unix": 44},
		"crown_jewel_replica_replica": true,
		"not-a-real-heist": {"stolen": true, "cooldown_until_unix": 99},
	})
	var saved := game.call("_thieving_trophies_for_save") as Dictionary
	_expect(saved.size() == 1, "Thieving trophy save should only keep valid dictionary trophy entries.")
	_expect(saved.has("complimentary_spoon"), "Thieving trophy save should preserve valid trophy entries.")
	var saved_spoon := saved.get("complimentary_spoon", {}) as Dictionary
	_expect(bool(saved_spoon.get("stolen", false)), "Thieving trophy save should preserve stolen state.")
	_expect(int(saved_spoon.get("cooldown_until_unix", 0)) == 44, "Thieving trophy save should preserve cooldown state.")


func _check_convergence_module_save_restore(game: Node) -> void:
	_install_test_convergence_action(game)
	var raw_modules := {
		"test-convergence-shrine": {"built": true, "building": true, "build_started_unix": -7, "completions": -3},
		"not-a-real-convergence": {"built": true, "building": true, "build_started_unix": 99, "completions": 8},
		"bad-entry": "bad-state",
	}
	game.set("convergence_modules", raw_modules)
	var saved := game.call("_convergence_modules_for_save") as Dictionary
	_expect(saved.size() == 1, "Convergence module save should only keep valid convergence module entries.")
	_expect(saved.has("test-convergence-shrine"), "Convergence module save should preserve valid module ids.")
	var saved_state := saved.get("test-convergence-shrine", {}) as Dictionary
	_expect(bool(saved_state.get("built", false)), "Convergence module save should preserve built state.")
	_expect(bool(saved_state.get("building", false)), "Convergence module save should preserve building state.")
	_expect(int(saved_state.get("build_started_unix", -1)) == 0, "Convergence module save should clamp negative build timestamps.")
	_expect(int(saved_state.get("completions", -1)) == 0, "Convergence module save should clamp negative completion counts.")

	game.set("convergence_modules", {"test-convergence-shrine": {"built": true, "building": false}})
	game.call("_restore_convergence_modules_from_save", {"convergence_modules": "bad-entry"})
	var restored := game.get("convergence_modules") as Dictionary
	_expect(restored.is_empty(), "Convergence module restore should clear malformed saved module data.")
	game.call("_restore_convergence_modules_from_save", {"convergence_modules": raw_modules})
	restored = game.get("convergence_modules") as Dictionary
	_expect(restored.size() == 1, "Convergence module restore should only keep valid convergence module entries.")
	var restored_state := restored.get("test-convergence-shrine", {}) as Dictionary
	_expect(int(restored_state.get("build_started_unix", -1)) == 0, "Convergence module restore should clamp negative build timestamps.")
	_expect(int(restored_state.get("completions", -1)) == 0, "Convergence module restore should clamp negative completion counts.")


func _check_hub_module_save_restore(game: Node) -> void:
	var raw_modules := {
		"barn": {"level": 99, "building": true, "build_started_msec": 1234},
		"pond": {"level": -4, "building": false, "build_started_unix_msec": -55},
		"trophy": {"level": 4, "building": true, "build_started_unix_msec": 999},
		"not-a-real-module": {"level": 4, "building": true, "build_started_unix_msec": 999},
		"garden": "bad-state",
	}
	game.set("hub_modules", raw_modules)
	var saved := game.call("_hub_modules_for_save") as Dictionary
	_expect(saved.size() == 2, "Hub module save should only keep known module definitions with dictionary state.")
	_expect(saved.has("barn") and saved.has("pond"), "Hub module save should preserve valid module ids.")
	_expect(not saved.has("trophy"), "Hub module save should not persist derived trophy state.")
	var barn := saved.get("barn", {}) as Dictionary
	var pond := saved.get("pond", {}) as Dictionary
	_expect(int(barn.get("level", -1)) == 4, "Hub module save should clamp levels to the max module level.")
	_expect(bool(barn.get("building", false)), "Hub module save should preserve building state.")
	_expect(int(barn.get("build_started_unix_msec", 0)) == 1234, "Hub module save should accept legacy build_started_msec.")
	_expect(int(pond.get("level", -1)) == 0, "Hub module save should clamp negative levels.")
	_expect(int(pond.get("build_started_unix_msec", -1)) == 0, "Hub module save should clamp negative build timestamps.")

	game.set("hub_modules", {"barn": {"level": 1, "building": false}})
	game.call("_restore_hub_modules_from_save", "bad-entry")
	var restored := game.get("hub_modules") as Dictionary
	_expect(restored.is_empty(), "Hub module restore should clear malformed saved module data.")
	game.call("_restore_hub_modules_from_save", raw_modules)
	restored = game.get("hub_modules") as Dictionary
	_expect(restored.size() == 2, "Hub module restore should only keep known module definitions with dictionary state.")
	_expect(restored.has("barn") and restored.has("pond"), "Hub module restore should preserve valid module ids.")
	var restored_barn := restored.get("barn", {}) as Dictionary
	_expect(int(restored_barn.get("level", -1)) == 4, "Hub module restore should clamp levels to the max module level.")
	_expect(int(restored_barn.get("build_started_unix_msec", 0)) == 1234, "Hub module restore should accept legacy build_started_msec.")


func _check_hub_module_position_save_restore(game: Node) -> void:
	game.set("hub_module_positions", {
		"barn": Vector2(-100, -100),
		"trophy": Vector2(99999, 99999),
		"not-a-real-module": Vector2(500, 500),
	})
	var saved := game.call("_hub_module_positions_for_save") as Dictionary
	_expect(saved.size() == 2, "Hub position save should only keep storable module ids.")
	_expect(saved.has("barn") and saved.has("trophy"), "Hub position save should preserve valid stored module ids.")
	var barn := saved.get("barn", {}) as Dictionary
	var trophy := saved.get("trophy", {}) as Dictionary
	_expect(float(barn.get("x", 0.0)) == 160.0 and float(barn.get("y", 0.0)) == 180.0, "Hub position save should clamp low coordinates.")
	_expect(float(trophy.get("x", 0.0)) == 2000.0, "Hub position save should clamp high x coordinates.")

	game.set("hub_module_positions", {"barn": Vector2(300, 300)})
	game.call("_restore_hub_module_positions", "bad-entry")
	var restored := game.get("hub_module_positions") as Dictionary
	_expect(restored.is_empty(), "Hub position restore should clear malformed saved position data.")
	game.call("_restore_hub_module_positions", {
		"barn": {"x": -100, "y": -100},
		"mission": {"x": 500, "y": 600},
		"trophy": {"x": 99999, "y": 99999},
		"not-a-real-module": {"x": 500, "y": 500},
	})
	restored = game.get("hub_module_positions") as Dictionary
	_expect(restored.size() == 3, "Hub position restore should only keep storable module ids.")
	_expect(restored.has("barn") and restored.has("mission") and restored.has("trophy"), "Hub position restore should preserve valid saved module ids.")
	var restored_barn := restored.get("barn", Vector2.ZERO) as Vector2
	var restored_mission := restored.get("mission", Vector2.ZERO) as Vector2
	_expect(restored_barn == Vector2(160, 180), "Hub position restore should clamp low coordinates.")
	_expect(restored_mission == Vector2(500, 600), "Hub position restore should preserve in-bounds coordinates.")


func _check_hub_decor_layout_save_restore(game: Node) -> void:
	game.set("leaderboard_player_id", "testdecorplayer")
	var raw_layout := [
		{"type": "tree", "index": 99, "x": -100, "y": -100, "w": 10, "h": 10},
		{"type": "decor", "index": 99, "x": 500, "y": 500, "w": 999, "h": 999},
		{"type": "bad-type", "index": 4, "x": 20, "y": 20, "w": 100, "h": 100},
		"bad-entry",
	]
	game.set("hub_decor_layout", raw_layout)
	var saved := game.call("_hub_decor_layout_for_save") as Array
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

	game.set("hub_decor_layout", [{"type": "tree", "index": 1, "x": 100, "y": 100, "w": 120, "h": 120}])
	game.call("_restore_hub_decor_layout", "bad-entry")
	var restored := game.get("hub_decor_layout") as Array
	_expect(restored.is_empty(), "Hub decor restore should clear malformed saved decor data.")
	game.call("_restore_hub_decor_layout", raw_layout)
	restored = game.get("hub_decor_layout") as Array
	_expect(restored.size() == 2, "Hub decor restore should only keep valid decor entry types.")
	tree = restored[0] as Dictionary
	_expect(int(tree.get("index", -1)) == 5, "Hub decor restore should clamp tree sprite indexes.")
	_expect(float(tree.get("x", 0.0)) >= 46.0 and float(tree.get("y", 0.0)) >= 80.0, "Hub decor restore should clamp tree positions into the field.")


func _check_hub_mission_save_restore(game: Node) -> void:
	game.set("skills", {
		"fight": {"xp": int(game.call("_xp_for_level", 10)), "level": 1},
		"woodcutting": {"xp": -99, "level": 99},
		"not-a-real-skill": {"xp": 9999, "level": 99},
	})
	var raw_missions := [
		{"skill_id": "fight", "action_id": "shove-wobbly-hay-bale", "target": 3, "remaining": 99, "assigned_unix": -5},
		{"skill_id": "fight", "action_id": "not-a-real-action", "target": 3, "remaining": 2},
		{"skill_id": "woodcutting", "action_id": "stack-logs-1", "target": 3, "remaining": 2},
		"bad-entry",
	]
	game.set("hub_missions", raw_missions)
	var saved := game.call("_hub_missions_for_save") as Array
	_expect(saved.size() == 1, "Hub mission save should only keep valid unlocked non-passive missions.")
	var saved_mission := saved[0] as Dictionary
	_expect(str(saved_mission.get("skill_id", "")) == "fight", "Hub mission save should preserve the mission skill.")
	_expect(str(saved_mission.get("action_id", "")) == "shove-wobbly-hay-bale", "Hub mission save should preserve the canonical mission action.")
	_expect(int(saved_mission.get("target", 0)) == 3, "Hub mission save should preserve the target count.")
	_expect(int(saved_mission.get("remaining", 0)) == 3, "Hub mission save should clamp remaining count to the target.")
	_expect(int(saved_mission.get("assigned_unix", -1)) == 0, "Hub mission save should clamp negative assignment timestamps.")

	game.set("hub_missions", [{"skill_id": "fight", "action_id": "shove-wobbly-hay-bale", "target": 1, "remaining": 1}])
	game.call("_restore_hub_missions_from_save", "bad-entry")
	var restored := game.get("hub_missions") as Array
	_expect(restored.is_empty(), "Hub mission restore should clear malformed saved mission data.")
	game.call("_restore_hub_missions_from_save", raw_missions)
	restored = game.get("hub_missions") as Array
	_expect(restored.size() == 1, "Hub mission restore should only keep valid unlocked non-passive missions.")
	var restored_mission := restored[0] as Dictionary
	_expect(str(restored_mission.get("action_id", "")) == "shove-wobbly-hay-bale", "Hub mission restore should preserve the canonical mission action.")
	_expect(int(restored_mission.get("remaining", 0)) == 3, "Hub mission restore should clamp remaining count to the target.")


func _check_leaderboard_scores_save(game: Node) -> void:
	game.set("leaderboard_last_submitted_scores_by_category", {
		"skill_xp:fight": 40,
		"unknown-category": 99,
		"total_level": 12,
		"medals_earned": -5,
	})
	var saved := game.call("_leaderboard_last_submitted_scores_for_save") as Dictionary
	_expect(int(saved.get("skill_xp:fight", 0)) == 40, "Leaderboard category save should preserve valid category scores.")
	_expect(int(saved.get("total_level", 0)) == 99, "Leaderboard category save should fold unknown categories into the canonical default category.")
	_expect(int(saved.get("medals_earned", -1)) == 0, "Leaderboard category save should clamp negative scores.")
	_expect(not saved.has("unknown-category"), "Leaderboard category save should not preserve unknown category keys.")
	game.call("_restore_leaderboard_submission_metadata_from_save", {
		"leaderboard_last_submitted_score": -10,
		"leaderboard_last_submitted_total_xp": -20,
		"leaderboard_last_submitted_scores_by_category": "bad-scores",
		"leaderboard_last_submit_unix": -30
	})
	_expect(int(game.get("leaderboard_last_submitted_score")) == 0, "Leaderboard submission restore should clamp negative last scores.")
	_expect(int(game.get("leaderboard_last_submitted_total_xp")) == 0, "Leaderboard submission restore should clamp negative total XP.")
	_expect((game.get("leaderboard_last_submitted_scores_by_category") as Dictionary).is_empty(), "Leaderboard submission restore should clear malformed category scores.")
	_expect(int(game.get("leaderboard_last_submit_unix")) == 0, "Leaderboard submission restore should clamp negative submit timestamps.")
	game.call("_restore_leaderboard_submission_metadata_from_save", {
		"leaderboard_last_submitted_score": 12,
		"leaderboard_last_submitted_scores_by_category": {
			"skill_xp:fight": 40,
			"unknown-category": 99,
			"total_level": 12,
			"medals_earned": -5
		},
		"leaderboard_last_submit_unix": 1234
	})
	var restored_scores := game.get("leaderboard_last_submitted_scores_by_category") as Dictionary
	_expect(int(game.get("leaderboard_last_submitted_total_xp")) == 12, "Leaderboard submission restore should default missing total XP from the restored last score.")
	_expect(int(restored_scores.get("skill_xp:fight", 0)) == 40, "Leaderboard submission restore should preserve valid category scores.")
	_expect(int(restored_scores.get("total_level", 0)) == 99, "Leaderboard submission restore should merge duplicate canonical category scores by max.")
	_expect(int(restored_scores.get("medals_earned", -1)) == 0, "Leaderboard submission restore should clamp negative category scores.")
	_expect(not restored_scores.has("unknown-category"), "Leaderboard submission restore should not preserve unknown category keys.")


func _check_leaderboard_profile_auth_save_restore(game: Node) -> void:
	game.set("leaderboard_last_submitted_score", -10)
	game.set("leaderboard_last_submitted_total_xp", -20)
	game.set("leaderboard_last_submit_unix", -30)
	game.set("leaderboard_display_name", "  A\nName\tThat Is Too Long For Profile  ")
	game.set("leaderboard_name_key", " Bad Key! ")
	game.set("leaderboard_profile_claimed", true)
	game.set("leaderboard_name_claim_verified", false)
	game.set("leaderboard_avatar_index", 999)
	game.set("leaderboard_player_id", " bad id! ")
	game.set("leaderboard_auth_refresh_token", "  refresh-token  ")
	game.set("leaderboard_auth_retry_after_unix", -40)
	_expect(int(game.call("_leaderboard_last_submitted_score_for_save")) == 0, "Leaderboard last score save should clamp negative values.")
	_expect(int(game.call("_leaderboard_last_submitted_total_xp_for_save")) == 0, "Leaderboard last total XP save should clamp negative values.")
	_expect(int(game.call("_leaderboard_last_submit_unix_for_save")) == 0, "Leaderboard submit timestamp save should clamp negative values.")
	_expect(str(game.call("_leaderboard_display_name_for_save")) == "A Name That Is T", "Leaderboard display-name save should sanitize and truncate names.")
	_expect(str(game.call("_leaderboard_name_key_for_save")).is_empty(), "Leaderboard name-key save should drop invalid keys.")
	_expect(not bool(game.call("_leaderboard_profile_claimed_for_save")), "Leaderboard profile save should clear unverified claims.")
	_expect(not bool(game.call("_leaderboard_name_claim_verified_for_save")), "Leaderboard profile save should clear unverified claim verification.")

	game.set("leaderboard_display_name", "Mira Stone")
	game.set("leaderboard_name_key", "")
	game.set("leaderboard_profile_claimed", true)
	game.set("leaderboard_name_claim_verified", true)
	_expect(str(game.call("_leaderboard_name_key_for_save")) == "mira_stone", "Leaderboard profile save should derive a missing verified claim key from the display name.")
	_expect(bool(game.call("_leaderboard_profile_claimed_for_save")), "Leaderboard profile save should preserve valid verified claims.")
	_expect(bool(game.call("_leaderboard_name_claim_verified_for_save")), "Leaderboard profile save should preserve valid claim verification.")

	game.set("leaderboard_display_name", "guest1234")
	game.set("leaderboard_name_key", "guest1234")
	game.set("leaderboard_profile_claimed", true)
	game.set("leaderboard_name_claim_verified", true)
	_expect(str(game.call("_leaderboard_name_key_for_save")).is_empty(), "Leaderboard profile save should not persist guest name keys.")
	_expect(not bool(game.call("_leaderboard_profile_claimed_for_save")), "Leaderboard profile save should clear guest profile claims.")
	_expect(not bool(game.call("_leaderboard_name_claim_verified_for_save")), "Leaderboard profile save should clear guest profile verification.")

	_expect(int(game.call("_leaderboard_avatar_index_for_save")) == 19, "Leaderboard avatar save should clamp to a valid avatar index.")
	_expect(str(game.call("_leaderboard_player_id_for_save")).is_empty(), "Leaderboard player-id save should drop invalid ids.")
	_expect(str(game.call("_leaderboard_auth_refresh_token_for_save")) == "refresh-token", "Leaderboard refresh-token save should strip whitespace.")
	_expect(int(game.call("_leaderboard_auth_retry_after_unix_for_save")) == 0, "Leaderboard auth retry save should clamp negative timestamps.")

	game.call("_restore_leaderboard_profile_metadata_from_save", {
		"leaderboard_display_name": "Mira Stone",
		"leaderboard_name_key": "",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
		"leaderboard_avatar_index": 999,
		"leaderboard_player_id": " bad id! ",
	})
	_expect(str(game.get("leaderboard_display_name")) == "Mira Stone", "Leaderboard profile restore should preserve valid display names.")
	_expect(str(game.get("leaderboard_name_key")) == "mira_stone", "Leaderboard profile restore should derive missing verified claim keys.")
	_expect(bool(game.get("leaderboard_profile_claimed")) and bool(game.get("leaderboard_name_claim_verified")), "Leaderboard profile restore should preserve valid verified claims.")
	_expect(int(game.get("leaderboard_avatar_index")) == 19, "Leaderboard profile restore should clamp avatar indexes.")
	var generated_player_id := str(game.get("leaderboard_player_id"))
	_expect(not generated_player_id.is_empty() and generated_player_id != " bad id! ", "Leaderboard profile restore should regenerate invalid player ids.")

	game.call("_restore_leaderboard_profile_metadata_from_save", {
		"leaderboard_display_name": "guest1234",
		"leaderboard_name_key": "guest1234",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
	})
	_expect(str(game.get("leaderboard_name_key")).is_empty(), "Leaderboard profile restore should clear guest name keys.")
	_expect(not bool(game.get("leaderboard_profile_claimed")) and not bool(game.get("leaderboard_name_claim_verified")), "Leaderboard profile restore should clear guest profile claims.")

	game.call("_restore_leaderboard_profile_metadata_from_save", {
		"leaderboard_display_name": "Mira Stone",
		"leaderboard_name_key": "mira_stone",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": false,
	})
	_expect(str(game.get("leaderboard_name_key")).is_empty(), "Leaderboard profile restore should clear unverified claim keys.")
	_expect(not bool(game.get("leaderboard_profile_claimed")), "Leaderboard profile restore should clear unverified profile claims.")
	game.call("_restore_leaderboard_profile_metadata_from_save", {
		"leaderboard_player_id": "player_1234",
	})
	_expect(str(game.get("leaderboard_player_id")) == "player_1234", "Leaderboard profile restore should preserve valid player ids.")

	game.set("leaderboard_auth_id_token", "stale-id-token")
	game.set("leaderboard_auth_refresh_token", "stale-refresh-token")
	game.set("leaderboard_auth_expires_unix", 999999)
	game.set("leaderboard_auth_retry_after_unix", 123)
	game.set("leaderboard_auth_provider", "stale-provider")
	game.call("_restore_leaderboard_auth_metadata_from_save", {
		"leaderboard_auth_refresh_token": "  refresh-token  ",
		"leaderboard_auth_retry_after_unix": -40,
	})
	_expect(str(game.get("leaderboard_auth_id_token")).is_empty(), "Leaderboard auth restore should clear volatile id tokens.")
	_expect(str(game.get("leaderboard_auth_refresh_token")) == "refresh-token", "Leaderboard auth restore should trim refresh tokens.")
	_expect(int(game.get("leaderboard_auth_expires_unix")) == 0, "Leaderboard auth restore should clear volatile token expiry.")
	_expect(int(game.get("leaderboard_auth_retry_after_unix")) == 0, "Leaderboard auth restore should clamp retry timestamps.")
	_expect(str(game.get("leaderboard_auth_provider")) == "anonymous", "Leaderboard auth restore should reset the ignored provider.")


func _check_leaderboard_fetch_retry_save_restore(game: Node) -> void:
	game.set("leaderboard_fetch_retry_unix_by_category", {
		"skill_xp:fight": 40,
		"unknown-category": 99,
		"total_level": 12,
		"medals_earned": -5,
	})
	var saved := game.call("_leaderboard_fetch_retry_unix_by_category_for_save") as Dictionary
	_expect(int(saved.get("skill_xp:fight", 0)) == 40, "Leaderboard fetch retry save should preserve valid category cooldowns.")
	_expect(int(saved.get("total_level", 0)) == 99, "Leaderboard fetch retry save should keep the highest cooldown for duplicate canonical categories.")
	_expect(int(saved.get("medals_earned", -1)) == 0, "Leaderboard fetch retry save should clamp negative retry timestamps.")
	_expect(not saved.has("unknown-category"), "Leaderboard fetch retry save should not preserve unknown category keys.")

	game.set("leaderboard_fetch_retry_unix_by_category", {"skill_xp:fight": 1})
	game.call("_restore_leaderboard_fetch_retry_unix_by_category_from_save", "bad-entry")
	var restored := game.get("leaderboard_fetch_retry_unix_by_category") as Dictionary
	_expect(restored.is_empty(), "Leaderboard fetch retry restore should clear malformed saved retry data.")
	game.call("_restore_leaderboard_fetch_retry_unix_by_category_from_save", {
		"skill_xp:fight": 40,
		"unknown-category": 99,
		"total_level": 12,
		"medals_earned": -5,
	})
	restored = game.get("leaderboard_fetch_retry_unix_by_category") as Dictionary
	_expect(int(restored.get("skill_xp:fight", 0)) == 40, "Leaderboard fetch retry restore should preserve valid category cooldowns.")
	_expect(int(restored.get("total_level", 0)) == 99, "Leaderboard fetch retry restore should keep the highest cooldown for duplicate canonical categories.")
	_expect(int(restored.get("medals_earned", -1)) == 0, "Leaderboard fetch retry restore should clamp negative retry timestamps.")
	_expect(not restored.has("unknown-category"), "Leaderboard fetch retry restore should not preserve unknown category keys.")
	game.set("leaderboard_fetch_unix_by_category", {"skill_xp:fight": 1234})
	game.call("_restore_leaderboard_fetch_metadata_from_save", {
		"leaderboard_fetch_retry_unix_by_category": {
			"skill_xp:fight": 40,
			"unknown-category": 99
		}
	})
	_expect((game.get("leaderboard_fetch_unix_by_category") as Dictionary).is_empty(), "Leaderboard fetch metadata restore should clear unsaved successful fetch timestamps.")
	restored = game.get("leaderboard_fetch_retry_unix_by_category") as Dictionary
	_expect(int(restored.get("skill_xp:fight", 0)) == 40, "Leaderboard fetch metadata restore should preserve retry cooldowns.")
	_expect(int(restored.get("total_level", 0)) == 99, "Leaderboard fetch metadata restore should canonicalize retry cooldown categories.")


func _check_chat_metadata_save_restore(game: Node) -> void:
	var now := int(game.call("_unix_now"))
	var long_id := "  abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij-extra  "
	game.set("chat_last_send_unix", -10)
	game.set("chat_stream_retry_unix", now + 9999)
	game.set("chat_stream_next_connect_unix", -5)
	game.set("chat_last_opened_created_at", -20)
	game.set("chat_last_opened_message_id", long_id)
	_expect(int(game.call("_chat_last_send_unix_for_save")) == 0, "Chat last-send save should clamp negative timestamps.")
	_expect(int(game.call("_chat_stream_retry_unix_for_save", now)) == now + 30, "Chat retry save should cap future retry timestamps.")
	_expect(int(game.call("_chat_stream_next_connect_unix_for_save", now)) == now + 30, "Chat next-connect save should stay at least the retry timestamp and cap future timestamps.")
	_expect(int(game.call("_chat_last_opened_created_at_for_save")) == 0, "Chat opened cursor save should clamp negative timestamps.")
	var saved_id := str(game.call("_chat_last_opened_message_id_for_save"))
	_expect(saved_id.length() == 64, "Chat opened message id save should truncate long ids.")
	_expect(saved_id.begins_with("abcdefghij"), "Chat opened message id save should strip surrounding whitespace.")

	game.set("chat_last_send_unix", 12)
	game.call("_restore_chat_last_send_unix_from_save", {"chat_last_send_unix": -10})
	_expect(int(game.get("chat_last_send_unix")) == 0, "Chat last-send restore should clamp negative timestamps.")
	game.call("_restore_chat_last_send_unix_from_save", {"chat_last_send_unix": now})
	_expect(int(game.get("chat_last_send_unix")) == now, "Chat last-send restore should preserve nonnegative timestamps.")

	game.set("chat_stream_retry_unix", 0)
	game.set("chat_stream_next_connect_unix", 0)
	game.call("_restore_chat_stream_retry_metadata_from_save", {
		"chat_stream_retry_unix": now + 9999,
		"chat_stream_next_connect_unix": -5,
	})
	_expect(int(game.get("chat_stream_retry_unix")) == now + 30, "Chat retry restore should cap future retry timestamps.")
	_expect(int(game.get("chat_stream_next_connect_unix")) == now + 30, "Chat next-connect restore should stay at least the restored retry timestamp.")

	game.set("chat_stream_retry_unix", 0)
	game.set("chat_stream_next_connect_unix", 0)
	game.call("_restore_chat_stream_retry_metadata_from_save", {
		"chat_fetch_retry_unix": now + 10,
		"chat_stream_next_connect_unix": now + 5,
	})
	_expect(int(game.get("chat_stream_retry_unix")) == now + 10, "Chat retry restore should accept legacy fetch retry timestamps.")
	_expect(int(game.get("chat_stream_next_connect_unix")) == now + 10, "Chat next-connect restore should not precede legacy retry timestamps.")

	game.set("chat_last_opened_created_at", 12)
	game.set("chat_last_opened_message_id", "old")
	game.call("_restore_chat_opened_cursor_from_save", {
		"chat_last_opened_created_at": -20,
		"chat_last_opened_message_id": long_id,
	})
	_expect(int(game.get("chat_last_opened_created_at")) == 0, "Chat opened cursor restore should clamp negative timestamps.")
	var restored_id := str(game.get("chat_last_opened_message_id"))
	_expect(restored_id.length() == 64, "Chat opened message id restore should truncate long ids.")
	_expect(restored_id.begins_with("abcdefghij"), "Chat opened message id restore should strip surrounding whitespace.")


func _check_resource_and_audio_settings_save(game: Node) -> void:
	game.set("log_currency", -20)
	_expect(int(game.call("_log_currency_for_save")) == 0, "Log currency save should clamp negative values.")
	game.set("music_volume", 1.5)
	_expect(float(game.call("_music_volume_for_save")) == 1.0, "Music volume save should cap values above one.")
	game.set("music_volume", -0.25)
	_expect(float(game.call("_music_volume_for_save")) == 0.0, "Music volume save should clamp negative values.")
	game.set("sfx_volume", 1.25)
	_expect(float(game.call("_sfx_volume_for_save")) == 1.0, "SFX volume save should cap values above one.")
	game.set("sfx_volume", -0.5)
	_expect(float(game.call("_sfx_volume_for_save")) == 0.0, "SFX volume save should clamp negative values.")


func _check_god_mode_save(game: Node) -> void:
	game.set("god_mode_enabled", true)
	_expect(not bool(game.call("_god_mode_enabled_for_save")), "God mode enabled save should be gated by availability.")


func _check_active_skill_identity_save(game: Node) -> void:
	game.set("selected_skill_id", "woodcutting")
	_expect(str(game.call("_selected_skill_id_for_save")) == "woodcutting", "Selected skill save should preserve known skill ids.")
	game.set("selected_skill_id", "not-a-real-skill")
	_expect(str(game.call("_selected_skill_id_for_save")) == "fight", "Selected skill save should replace unknown skill ids with the default skill.")

	game.set("running_skill_id", "fishing")
	game.set("running_action_id", "dip-a-tidepool-minnow")
	_expect(str(game.call("_running_skill_id_for_save")) == "fishing", "Running skill save should preserve a known skill with a valid canonical action.")
	game.set("running_skill_id", "fishing")
	game.set("running_action_id", "not-a-real-action")
	_expect(str(game.call("_running_skill_id_for_save")).is_empty(), "Running skill save should clear a skill with no valid running action.")
	game.set("running_skill_id", "not-a-real-skill")
	game.set("running_action_id", "shove-wobbly-hay-bale")
	_expect(str(game.call("_running_skill_id_for_save")).is_empty(), "Running skill save should clear unknown skill ids.")


func _check_running_action_save(game: Node) -> void:
	game.set("running_skill_id", "fishing")
	game.set("running_action_id", "dip-a-tidepool-minnow")
	_expect(str(game.call("_running_action_id_for_save")) == "beach-shallows", "Running action save should canonicalize fishing aliases.")
	game.set("running_skill_id", "fight")
	game.set("running_action_id", "not-a-real-action")
	_expect(str(game.call("_running_action_id_for_save")).is_empty(), "Running action save should drop unknown actions.")


func _check_action_progress_save_restore(game: Node) -> void:
	game.set("action_progress", 1.5)
	_expect(float(game.call("_action_progress_for_save")) == 0.999, "Action progress save should cap progress below completion.")
	game.set("action_progress", -0.25)
	_expect(float(game.call("_action_progress_for_save")) == 0.0, "Action progress save should clamp negative progress.")

	_prime_core_skill_state(game)
	game.call("_load_game_core", {
		"selected_skill_id": "fight",
		"running_skill_id": "fight",
		"running_action_id": "shove-wobbly-hay-bale",
		"action_progress": 1.5,
		"skills": {},
		"stamina": {},
		"stamina_bank": {},
		"saved_at": int(game.call("_unix_now")),
	})
	_expect(float(game.get("action_progress")) == 0.999, "Action progress restore should cap progress below completion.")

	_prime_core_skill_state(game)
	game.call("_load_game_core", {
		"selected_skill_id": "fight",
		"running_skill_id": "fight",
		"running_action_id": "shove-wobbly-hay-bale",
		"action_progress": -0.25,
		"skills": {},
		"stamina": {},
		"stamina_bank": {},
		"saved_at": int(game.call("_unix_now")),
	})
	_expect(float(game.get("action_progress")) == 0.0, "Action progress restore should clamp negative progress.")


func _check_action_key_save(game: Node) -> void:
	_expect(str(game.call("_action_key_for_save", "fishing:dip-a-tidepool-minnow")) == "fishing:beach-shallows", "Action-key save should canonicalize fishing aliases.")
	_expect(str(game.call("_action_key_for_save", "woodcutting:stack-logs-1")).is_empty(), "Action-key save should drop passive action keys.")
	_expect(str(game.call("_action_key_for_save", "malformed-key")).is_empty(), "Action-key save should drop malformed keys.")
	_expect(str(game.call("_action_key_for_save", "fight:not-a-real-action")).is_empty(), "Action-key save should drop unknown action keys.")
	game.call("_restore_tip_metadata_from_save", {
		"lock_click_tip_seen": true,
		"passive_module_tip_seen": true,
		"silver_opportunity_tip_seen": true,
		"silver_opportunity_tip_action_key": "fishing:dip-a-tidepool-minnow"
	})
	_expect(bool(game.get("lock_click_tip_seen")), "Tip metadata restore should preserve lock-click tip state.")
	_expect(bool(game.get("passive_module_tip_seen")), "Tip metadata restore should preserve passive-module tip state.")
	_expect(bool(game.get("silver_opportunity_tip_seen")), "Tip metadata restore should preserve silver-opportunity tip state.")
	_expect(str(game.get("silver_opportunity_tip_action_key")) == "fishing:beach-shallows", "Tip metadata restore should canonicalize silver-opportunity action keys.")
	game.call("_restore_tip_metadata_from_save", {"silver_opportunity_tip_action_key": "malformed-key"})
	_expect(str(game.get("silver_opportunity_tip_action_key")).is_empty(), "Tip metadata restore should clear malformed silver-opportunity action keys.")


func _check_achievement_toast_seen_ids_save_restore(game: Node) -> void:
	game.call("_restore_activity_crit_metadata_from_save", {
		"activity_crit_seen": false,
		"activity_mega_crit_seen": true
	})
	_expect(bool(game.get("activity_crit_seen")), "Activity crit restore should mark crit seen when mega crit has been seen.")
	_expect(bool(game.get("activity_mega_crit_seen")), "Activity crit restore should preserve mega crit state.")
	game.call("_restore_activity_crit_metadata_from_save", {
		"activity_crit_seen": false,
		"activity_mega_crit_seen": false
	})
	_expect(not bool(game.get("activity_crit_seen")), "Activity crit restore should preserve unseen crit state.")
	_expect(not bool(game.get("activity_mega_crit_seen")), "Activity crit restore should preserve unseen mega crit state.")
	game.call("_restore_boot_visible_tip_flags_from_save", {
		"activity_start_tip_seen": true,
		"hub_tutorial_tip_seen": true
	})
	_expect(bool(game.get("activity_start_tip_seen")), "Boot-visible tip restore should preserve activity-start tip state.")
	_expect(bool(game.get("hub_tutorial_tip_seen")), "Boot-visible tip restore should preserve hub tutorial tip state.")
	game.call("_restore_boot_visible_tip_flags_from_save", {})
	_expect(not bool(game.get("activity_start_tip_seen")), "Boot-visible tip restore should default missing activity-start tip state to false.")
	_expect(not bool(game.get("hub_tutorial_tip_seen")), "Boot-visible tip restore should default missing hub tutorial tip state to false.")

	game.set("achievement_toast_seen_ids", {
		"total-level-25": true,
		"activity-crit": false,
		"": true,
		123: true,
	})
	var saved := game.call("_achievement_toast_seen_ids_for_save") as Dictionary
	_expect(saved.size() == 2, "Achievement toast save should only keep truthy non-empty ids.")
	_expect(bool(saved.get("total-level-25", false)), "Achievement toast save should preserve truthy string ids.")
	_expect(bool(saved.get("123", false)), "Achievement toast save should stringify non-string ids for compatibility.")
	_expect(not saved.has("activity-crit"), "Achievement toast save should drop false entries.")
	_expect(not saved.has(""), "Achievement toast save should drop empty ids.")

	game.set("achievement_toast_seen_ids", {"total-level-25": true})
	game.call("_restore_achievement_toast_seen_ids", {"achievement_toast_seen_ids": "bad-entry"})
	var restored := game.get("achievement_toast_seen_ids") as Dictionary
	_expect(restored.is_empty(), "Achievement toast restore should clear malformed saved seen-id data.")
	game.call("_restore_achievement_toast_seen_ids", {
		"achievement_toast_seen_ids": {
			"total-level-25": true,
			"activity-crit": false,
			"": true,
			123: true,
		}
	})
	restored = game.get("achievement_toast_seen_ids") as Dictionary
	_expect(restored.size() == 2, "Achievement toast restore should only keep truthy non-empty ids.")
	_expect(bool(restored.get("total-level-25", false)) and bool(restored.get("123", false)), "Achievement toast restore should preserve compatible truthy ids.")


func _check_scalar_progression_metadata_save(game: Node) -> void:
	game.set("hub_selected_module_id", "barn")
	_expect(str(game.call("_hub_selected_module_id_for_save")) == "barn", "Hub selected-module save should preserve persisted hub modules.")
	game.set("hub_selected_module_id", "trophy")
	_expect(str(game.call("_hub_selected_module_id_for_save")) == "pond", "Hub selected-module save should mirror restore behavior for derived selections.")
	game.set("hub_selected_module_id", "barn")
	game.call("_restore_hub_selected_module_id_from_save", {"hub_selected_module_id": "not-a-module"})
	_expect(str(game.get("hub_selected_module_id")) == "pond", "Hub selected-module restore should replace unknown modules with the pond.")
	game.call("_restore_hub_selected_module_id_from_save", {"hub_selected_module_id": "barn"})
	_expect(str(game.get("hub_selected_module_id")) == "barn", "Hub selected-module restore should preserve persisted hub modules.")
	game.set("hub_mission_cooldown_until_unix", -12)
	_expect(int(game.call("_hub_mission_cooldown_until_unix_for_save")) == 0, "Hub mission cooldown save should clamp negative timestamps.")
	game.call("_restore_hub_mission_cooldown_until_unix_from_save", {"hub_mission_cooldown_until_unix": -12})
	_expect(int(game.get("hub_mission_cooldown_until_unix")) == 0, "Hub mission cooldown restore should clamp negative timestamps.")
	game.call("_restore_hub_mission_cooldown_until_unix_from_save", {"hub_mission_cooldown_until_unix": 1234})
	_expect(int(game.get("hub_mission_cooldown_until_unix")) == 1234, "Hub mission cooldown restore should preserve nonnegative timestamps.")
	game.set("plank_boost_enabled", true)
	_expect(bool(game.call("_plank_boost_enabled_for_save")), "Plank boost save should preserve enabled state.")
	game.call("_restore_plank_boost_enabled_from_save", {"plank_boost_enabled": true})
	_expect(bool(game.get("plank_boost_enabled")), "Plank boost restore should preserve enabled state.")
	game.call("_restore_plank_boost_enabled_from_save", {})
	_expect(not bool(game.get("plank_boost_enabled")), "Plank boost restore should default missing state to disabled.")
	game.set("ad_bonus_seconds_remaining", 999999.0)
	_expect(float(game.call("_ad_bonus_seconds_remaining_for_save")) == 21600.0, "Ad bonus save should cap remaining seconds.")
	game.call("_restore_ad_bonus_seconds_remaining_from_save", {"ad_bonus_seconds_remaining": -5.0})
	_expect(float(game.get("ad_bonus_seconds_remaining")) == 0.0, "Ad bonus restore should clamp negative remaining seconds.")
	game.call("_restore_ad_bonus_seconds_remaining_from_save", {"ad_bonus_seconds_remaining": 999999.0})
	_expect(float(game.get("ad_bonus_seconds_remaining")) == 21600.0, "Ad bonus restore should cap remaining seconds.")
	game.call("_restore_ad_bonus_seconds_remaining_from_save", {"ad_bonus_seconds_remaining": 42.5})
	_expect(float(game.get("ad_bonus_seconds_remaining")) == 42.5, "Ad bonus restore should preserve valid remaining seconds.")
	game.set("activity_start_count", -3)
	_expect(int(game.call("_activity_start_count_for_save")) == 0, "Activity start-count save should clamp negative counts.")
	game.set("activity_completion_count", -4)
	_expect(int(game.call("_activity_completion_count_for_save")) == 0, "Activity completion-count save should clamp negative counts.")
	game.set("guaranteed_success_action_completions", 999)
	_expect(int(game.call("_guaranteed_success_action_completions_for_save")) == 7, "Guaranteed-success save should cap completion counts.")
	game.call("_restore_activity_progress_counts_from_save", {
		"activity_start_count": -3,
		"activity_completion_count": -4,
		"guaranteed_success_action_completions": 999
	})
	_expect(int(game.get("activity_start_count")) == 0, "Activity progress restore should clamp negative start counts.")
	_expect(int(game.get("activity_completion_count")) == 0, "Activity progress restore should clamp negative completion counts.")
	_expect(int(game.get("guaranteed_success_action_completions")) == 7, "Activity progress restore should cap guaranteed-success completions.")
	game.call("_restore_activity_progress_counts_from_save", {
		"activity_start_count": 4,
		"activity_completion_count": 5
	})
	_expect(int(game.get("activity_start_count")) == 4, "Activity progress restore should preserve valid start counts.")
	_expect(int(game.get("activity_completion_count")) == 5, "Activity progress restore should preserve valid completion counts.")
	_expect(int(game.get("guaranteed_success_action_completions")) == 5, "Activity progress restore should default missing guaranteed-success completions from restored completion count.")
	game.call("_restore_guaranteed_success_action_completions_from_save", {}, 6)
	_expect(int(game.get("guaranteed_success_action_completions")) == 6, "Guaranteed-success restore should use the supplied fallback completion count.")
	game.set("onboarding_starter_action_completion_count", -5)
	_expect(int(game.call("_onboarding_starter_action_completion_count_for_save")) == 0, "Onboarding starter-count save should clamp negative counts.")
	game.call("_restore_onboarding_progression_from_save", {"onboarding_fight_auto_run_message_shown": true})
	_expect(int(game.get("onboarding_starter_action_completion_count")) == 1, "Onboarding restore should backfill starter completions from the auto-run message.")
	game.call("_restore_onboarding_progression_from_save", {"onboarding_starter_action_completion_count": 2})
	_expect(bool(game.get("onboarding_header_reveal_after_progress")), "Onboarding restore should keep the legacy header reveal backfill.")
	game.call("_restore_onboarding_progression_from_save", {"skill_swipe_tip_seen": true})
	_expect(bool(game.get("onboarding_swipe_tip_eligible")) and bool(game.get("onboarding_swipe_navigation_unlocked")), "Onboarding restore should keep swipe unlocks implied by seen swipe tips.")
	_expect(bool(game.get("onboarding_fight_summary_revealed")) and bool(game.get("onboarding_fight_action_stats_revealed")), "Onboarding restore should keep fight reveal state implied by seen swipe tips.")
	game.set("skill_swipe_tip_seen", false)
	game.set("onboarding_swipe_tip_eligible", false)
	game.set("onboarding_swipe_navigation_unlocked", false)
	game.set("stamina_gauge_tip_seen", true)
	game.set("onboarding_fight_summary_revealed", false)
	game.set("onboarding_fight_auto_run_message_shown", false)
	game.set("onboarding_fight_stamina_revealed", false)
	game.set("onboarding_fight_action_stats_revealed", false)
	game.call("_apply_onboarding_restored_completion_implications")
	_expect(bool(game.get("onboarding_fight_summary_revealed")) and bool(game.get("onboarding_fight_action_stats_revealed")), "Onboarding completion implications should reveal fight tutorial state from restored stamina tips.")
	_expect(not bool(game.get("onboarding_swipe_navigation_unlocked")), "Onboarding completion implications should not unlock swipe navigation from stamina tips alone.")
	game.call("_restore_onboarding_progression_from_save", {"onboarding_medal_tip_shown": true})
	_expect(bool(game.get("onboarding_mastery_tip_dismissed")), "Onboarding restore should keep medal tips dismissing the mastery tip.")
	game.set("stamina_gauge_pre_tip_hold_seconds", 99.0)
	_expect(float(game.call("_stamina_gauge_pre_tip_hold_seconds_for_save")) == 4.0, "Stamina tip hold save should cap discovery hold seconds.")
	game.call("_restore_stamina_gauge_pre_tip_hold_seconds_from_save", {"stamina_gauge_pre_tip_hold_seconds": -5.0})
	_expect(float(game.get("stamina_gauge_pre_tip_hold_seconds")) == 0.0, "Stamina tip hold restore should clamp negative seconds.")
	game.call("_restore_stamina_gauge_pre_tip_hold_seconds_from_save", {"stamina_gauge_pre_tip_hold_seconds": 99.0})
	_expect(float(game.get("stamina_gauge_pre_tip_hold_seconds")) == 4.0, "Stamina tip hold restore should cap discovery hold seconds.")
	game.set("flow_heat", 99.0)
	_expect(float(game.call("_flow_heat_for_save")) == 36.0, "Music flow heat save should cap heat.")
	game.set("flow_active_action_seconds", -8.0)
	_expect(float(game.call("_flow_active_action_seconds_for_save")) == 0.0, "Music flow active seconds save should clamp negative seconds.")
	game.set("flow_actions_taken", 12)
	game.call("_restore_music_flow_state_from_save", {
		"music_start_chance_unlocked": true,
		"flow_heat": 99.0,
		"flow_active_action_seconds": -8.0
	})
	_expect(int(game.get("flow_actions_taken")) == 0, "Music flow restore should reset unsaved action streak count.")
	_expect(bool(game.get("music_start_chance_unlocked")), "Music flow restore should preserve start chance unlock state.")
	_expect(float(game.get("flow_heat")) == 36.0, "Music flow restore should cap heat.")
	_expect(float(game.get("flow_active_action_seconds")) == 0.0, "Music flow restore should clamp negative active seconds.")
	game.set("flow_heat", 7.5)
	game.set("flow_active_action_seconds", 3.25)
	game.call("_restore_music_flow_state_from_save", {})
	_expect(float(game.get("flow_heat")) == 7.5, "Music flow restore should keep existing heat when save data omits it.")
	_expect(float(game.get("flow_active_action_seconds")) == 3.25, "Music flow restore should keep existing active seconds when save data omits them.")


func _check_save_payload(game: Node) -> void:
	var now := int(game.call("_unix_now"))
	game.set("mastery", {
		"fishing:dip-a-tidepool-minnow": {"xp": 18},
		"fishing:beach-shallows": {"xp": 42},
		"fight:not-a-real-action": {"xp": 77},
	})
	game.set("selected_fishing_locations", {
		"beach": "rocky",
		"pier": "missing-location",
	})
	game.set("passive_modules", {
		"existing-module": {"stored": 9999, "time_seconds": 2, "yield": 99, "capacity": 9999, "seeded": true, "last_update": 1234},
		"": {"stored": 1},
		"bad-module": "bad-state",
	})
	game.set("thieving_action_jails", {
		"borrow-a-cookie-permanently": {"cooldown_until_unix": now + 60, "resume_when_free": true},
		"not-a-real-action": {"cooldown_until_unix": now + 60, "resume_when_free": true},
	})
	game.set("thieving_trophies", {
		"complimentary_spoon": {"stolen": true, "cooldown_until_unix": 44},
		"not-a-real-heist": {"stolen": true, "cooldown_until_unix": 99},
	})
	_install_test_convergence_action(game)
	game.set("convergence_modules", {
		"test-convergence-shrine": {"built": true, "building": true, "build_started_unix": -7, "completions": -3},
		"not-a-real-convergence": {"built": true, "building": true, "build_started_unix": 99, "completions": 8},
		"bad-entry": "bad-state",
	})
	game.set("hub_modules", {
		"barn": {"level": 99, "building": true, "build_started_msec": 1234},
		"pond": {"level": -4, "building": false, "build_started_unix_msec": -55},
		"trophy": {"level": 4, "building": true, "build_started_unix_msec": 999},
		"not-a-real-module": {"level": 4, "building": true, "build_started_unix_msec": 999},
		"garden": "bad-state",
	})
	game.set("hub_module_positions", {
		"barn": Vector2(-100, -100),
		"trophy": Vector2(99999, 99999),
		"not-a-real-module": Vector2(500, 500),
	})
	game.set("leaderboard_player_id", "testdecorplayer")
	game.set("hub_decor_layout", [
		{"type": "tree", "index": 99, "x": -100, "y": -100, "w": 10, "h": 10},
		{"type": "decor", "index": 99, "x": 500, "y": 500, "w": 999, "h": 999},
		{"type": "bad-type", "index": 4, "x": 20, "y": 20, "w": 100, "h": 100},
		"bad-entry",
	])
	game.set("skills", {
		"fight": {"xp": int(game.call("_xp_for_level", 10)), "level": 1},
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
	game.set("hub_missions", [
		{"skill_id": "fight", "action_id": "shove-wobbly-hay-bale", "target": 3, "remaining": 99, "assigned_unix": -5},
		{"skill_id": "fight", "action_id": "not-a-real-action", "target": 3, "remaining": 2},
		{"skill_id": "woodcutting", "action_id": "stack-logs-1", "target": 3, "remaining": 2},
		"bad-entry",
	])
	game.set("leaderboard_last_submitted_scores_by_category", {
		"skill_xp:fight": 40,
		"unknown-category": 99,
	})
	game.set("leaderboard_last_submitted_score", -10)
	game.set("leaderboard_last_submitted_total_xp", -20)
	game.set("leaderboard_last_submit_unix", -30)
	game.set("leaderboard_display_name", "  A\nName\tThat Is Too Long For Profile  ")
	game.set("leaderboard_name_key", " Bad Key! ")
	game.set("leaderboard_profile_claimed", true)
	game.set("leaderboard_name_claim_verified", false)
	game.set("leaderboard_avatar_index", 999)
	game.set("leaderboard_player_id", " bad id! ")
	game.set("leaderboard_auth_refresh_token", "  refresh-token  ")
	game.set("leaderboard_auth_retry_after_unix", -40)
	game.set("leaderboard_fetch_retry_unix_by_category", {
		"skill_xp:fight": 40,
		"unknown-category": 99,
		"total_level": 12,
		"medals_earned": -5,
	})
	game.set("chat_last_send_unix", -10)
	game.set("chat_stream_retry_unix", now + 9999)
	game.set("chat_stream_next_connect_unix", -5)
	game.set("chat_last_opened_created_at", -20)
	game.set("chat_last_opened_message_id", "  abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij-extra  ")
	game.set("selected_skill_id", "not-a-real-skill")
	game.set("running_skill_id", "fishing")
	game.set("running_action_id", "dip-a-tidepool-minnow")
	game.set("action_progress", 1.5)
	game.set("silver_opportunity_tip_action_key", "fishing:dip-a-tidepool-minnow")
	game.set("leaderboard_auth_provider", "unused-provider")
	game.set("achievement_toast_seen_ids", {
		"total-level-25": true,
		"activity-crit": false,
		"": true,
	})
	game.set("log_currency", -20)
	game.set("music_volume", 1.5)
	game.set("sfx_volume", -0.5)
	game.set("god_mode_enabled", true)
	game.set("god_mode_save_tainted", true)
	game.set("equipped_fishing_tool_id", "not-a-real-tool")
	game.set("fish_currency", -10.0)
	game.set("fishing_net_stored_fish", 999)
	game.set("fishing_net_successes", -2)
	game.set("fishing_net_stored_xp", -3)
	game.set("fishing_net_stored_mastery", -4.0)
	game.set("fishing_net_collected", true)
	game.set("fishing_boat_stored_fish", 999)
	game.set("fishing_boat_successes", -5)
	game.set("fishing_boat_stored_xp", -6)
	game.set("fishing_boat_stored_mastery", -7.0)
	game.set("fishing_rod_collected", false)
	game.set("fishing_reinforced_rod_collected", false)
	game.set("fishing_star_rod_collected", true)
	game.set("hub_selected_module_id", "trophy")
	game.set("hub_mission_cooldown_until_unix", -12)
	game.set("plank_boost_enabled", true)
	game.set("ad_bonus_seconds_remaining", 999999.0)
	game.set("activity_start_count", -3)
	game.set("activity_completion_count", -4)
	game.set("guaranteed_success_action_completions", 999)
	game.set("onboarding_starter_action_completion_count", -5)
	game.set("stamina_gauge_pre_tip_hold_seconds", 99.0)
	game.set("flow_heat", 99.0)
	game.set("flow_active_action_seconds", -8.0)

	var payload := game.call("_save_payload", now) as Dictionary
	var payload_mastery := payload.get("mastery", {}) as Dictionary
	_expect(payload_mastery.has("fishing:beach-shallows"), "Save payload should include canonical mastery keys.")
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
	var payload_fight_max := float(game.call("_max_stamina", "fight"))
	_expect(payload_stamina.has("fight") and payload_stamina.has("build") and not payload_stamina.has("not-a-real-skill"), "Save payload should include only known stamina skill ids.")
	_expect(float(payload_stamina.get("fight", -1.0)) == payload_fight_max, "Save payload should clamp stamina above the max.")
	_expect(float(payload_stamina.get("thieving", -1.0)) == 0.0, "Save payload should clamp negative stamina.")
	_expect(float(payload_stamina.get("build", -1.0)) == 12.5, "Save payload should preserve fractional stamina.")
	_expect(float(payload_stamina_bank.get("fight", -1.0)) == 0.0, "Save payload should reset full-stamina banks.")
	_expect(float(payload_stamina_bank.get("build", -1.0)) == 6.0, "Save payload should derive stamina bank progress from fractional stamina.")
	_expect(not payload_stamina_bank.has("not-a-real-skill"), "Save payload should include only known stamina bank skill ids.")
	var payload_locations := payload.get("selected_fishing_locations", {}) as Dictionary
	_expect(payload_locations.size() == 1 and str(payload_locations.get("beach", "")) == "rocky", "Save payload should include only valid fishing selections.")
	_expect(int(payload.get("log_currency", -1)) == 0, "Save payload should clamp log currency.")
	_expect(float(payload.get("music_volume", -1.0)) == 1.0, "Save payload should cap music volume.")
	_expect(float(payload.get("sfx_volume", -1.0)) == 0.0, "Save payload should clamp SFX volume.")
	_expect(not payload.has("is_muted"), "Save payload should not include obsolete global mute state.")
	_expect(not bool(payload.get("god_mode_enabled", true)), "Save payload should gate god mode enabled by availability.")
	_expect(bool(payload.get("god_mode_save_tainted", false)), "Save payload should preserve god mode taint state.")
	_expect(str(payload.get("equipped_fishing_tool_id", "")) == "hands", "Save payload should normalize invalid equipped fishing tool ids.")
	_expect(float(payload.get("fish_currency", -1.0)) == 0.0, "Save payload should clamp fishing currency.")
	_expect(int(payload.get("fishing_net_stored_fish", -1)) == 9, "Save payload should cap fishing net stored fish.")
	_expect(int(payload.get("fishing_net_successes", -1)) == 0, "Save payload should clamp fishing net successes.")
	_expect(int(payload.get("fishing_net_stored_xp", -1)) == 0, "Save payload should clamp fishing net stored XP.")
	_expect(float(payload.get("fishing_net_stored_mastery", -1.0)) == 0.0, "Save payload should clamp fishing net stored mastery.")
	_expect(bool(payload.get("fishing_net_collect_completed", false)), "Save payload should keep canonical fishing net collection state.")
	_expect(not payload.has("fishing_net_collected"), "Save payload should not include legacy fishing net collection state.")
	_expect(int(payload.get("fishing_boat_stored_fish", -1)) == 199, "Save payload should cap fishing boat stored fish.")
	_expect(int(payload.get("fishing_boat_successes", -1)) == 0, "Save payload should clamp fishing boat successes.")
	_expect(int(payload.get("fishing_boat_stored_xp", -1)) == 0, "Save payload should clamp fishing boat stored XP.")
	_expect(float(payload.get("fishing_boat_stored_mastery", -1.0)) == 0.0, "Save payload should clamp fishing boat stored mastery.")
	_expect(bool(payload.get("fishing_rod_collected", false)) and bool(payload.get("fishing_reinforced_rod_collected", false)) and bool(payload.get("fishing_star_rod_collected", false)), "Save payload should normalize fishing rod collection hierarchy.")
	var payload_passive := payload.get("passive_modules", {}) as Dictionary
	_expect(payload_passive.size() == 1 and payload_passive.has("existing-module"), "Save payload should include only valid passive module entries.")
	var payload_passive_state := payload_passive.get("existing-module", {}) as Dictionary
	_expect(int(payload_passive_state.get("stored", -1)) == 1000, "Save payload should clamp passive stored values.")
	_expect(int(payload_passive_state.get("time_seconds", -1)) == 30, "Save payload should clamp passive time values.")
	_expect(int(payload_passive_state.get("yield", -1)) == 18, "Save payload should clamp passive yield values.")
	_expect(int(payload_passive_state.get("capacity", -1)) == 1000, "Save payload should clamp passive capacity values.")
	var payload_jails := payload.get("thieving_action_jails", {}) as Dictionary
	_expect(payload_jails.size() == 1 and payload_jails.has("borrow-a-cookie-permanently"), "Save payload should include only valid active thieving jails.")
	var payload_trophies := payload.get("thieving_trophies", {}) as Dictionary
	_expect(payload_trophies.size() == 1 and payload_trophies.has("complimentary_spoon"), "Save payload should include only valid thieving trophy entries.")
	var payload_convergence := payload.get("convergence_modules", {}) as Dictionary
	_expect(payload_convergence.size() == 1 and payload_convergence.has("test-convergence-shrine"), "Save payload should include only valid convergence module entries.")
	var payload_convergence_state := payload_convergence.get("test-convergence-shrine", {}) as Dictionary
	_expect(int(payload_convergence_state.get("build_started_unix", -1)) == 0, "Save payload should clamp convergence build timestamps.")
	_expect(int(payload_convergence_state.get("completions", -1)) == 0, "Save payload should clamp convergence completion counts.")
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
	_expect(str(payload_mission.get("action_id", "")) == "shove-wobbly-hay-bale", "Save payload should preserve canonical hub mission actions.")
	_expect(int(payload_mission.get("remaining", 0)) == 3, "Save payload should clamp hub mission remaining counts.")
	var payload_scores := payload.get("leaderboard_last_submitted_scores_by_category", {}) as Dictionary
	_expect(payload_scores.has("skill_xp:fight") and payload_scores.has("total_level") and not payload_scores.has("unknown-category"), "Save payload should include only canonical leaderboard category score keys.")
	_expect(int(payload.get("leaderboard_last_submitted_score", -1)) == 0, "Save payload should clamp leaderboard last score.")
	_expect(int(payload.get("leaderboard_last_submitted_total_xp", -1)) == 0, "Save payload should clamp leaderboard last total XP.")
	_expect(int(payload.get("leaderboard_last_submit_unix", -1)) == 0, "Save payload should clamp leaderboard last submit timestamps.")
	_expect(str(payload.get("leaderboard_display_name", "")) == "A Name That Is T", "Save payload should sanitize leaderboard display names.")
	_expect(str(payload.get("leaderboard_name_key", "bad")).is_empty(), "Save payload should sanitize leaderboard name keys.")
	_expect(not bool(payload.get("leaderboard_profile_claimed", true)), "Save payload should clear invalid leaderboard profile claims.")
	_expect(not bool(payload.get("leaderboard_name_claim_verified", true)), "Save payload should clear invalid leaderboard profile verification.")
	_expect(int(payload.get("leaderboard_avatar_index", -1)) == 19, "Save payload should clamp leaderboard avatar indexes.")
	_expect(str(payload.get("leaderboard_player_id", "bad")).is_empty(), "Save payload should sanitize leaderboard player ids.")
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
	_expect(str(payload.get("running_action_id", "")) == "beach-shallows", "Save payload should canonicalize the running action id.")
	_expect(float(payload.get("action_progress", -1.0)) == 0.999, "Save payload should cap action progress below completion.")
	_expect(str(payload.get("silver_opportunity_tip_action_key", "")) == "fishing:beach-shallows", "Save payload should canonicalize saved action-key fields.")
	var payload_seen := payload.get("achievement_toast_seen_ids", {}) as Dictionary
	_expect(payload_seen.size() == 1 and bool(payload_seen.get("total-level-25", false)), "Save payload should include only normalized achievement toast seen ids.")
	_expect(str(payload.get("hub_selected_module_id", "")) == "pond", "Save payload should mirror restore behavior for derived hub selections.")
	_expect(int(payload.get("hub_mission_cooldown_until_unix", -1)) == 0, "Save payload should clamp hub mission cooldown timestamps.")
	_expect(bool(payload.get("plank_boost_enabled", false)), "Save payload should preserve plank boost enabled state.")
	_expect(float(payload.get("ad_bonus_seconds_remaining", 0.0)) == 21600.0, "Save payload should cap ad bonus seconds.")
	_expect(int(payload.get("activity_start_count", -1)) == 0, "Save payload should clamp activity start counts.")
	_expect(int(payload.get("activity_completion_count", -1)) == 0, "Save payload should clamp activity completion counts.")
	_expect(int(payload.get("guaranteed_success_action_completions", -1)) == 7, "Save payload should cap guaranteed-success completions.")
	_expect(int(payload.get("onboarding_starter_action_completion_count", -1)) == 0, "Save payload should clamp onboarding starter completions.")
	_expect(float(payload.get("stamina_gauge_pre_tip_hold_seconds", 0.0)) == 4.0, "Save payload should cap stamina tip hold seconds.")
	_expect(float(payload.get("flow_heat", 0.0)) == 36.0, "Save payload should cap music flow heat.")
	_expect(float(payload.get("flow_active_action_seconds", -1.0)) == 0.0, "Save payload should clamp music flow active seconds.")
	_expect(not payload.has("leaderboard_auth_provider"), "Save payload should not include ignored leaderboard auth provider state.")
	_expect(int(payload.get("saved_at", 0)) == now, "Save payload should use the supplied timestamp.")


func _check_passive_module_save(game: Node) -> void:
	game.set("passive_modules", {
		"existing-module": {"stored": 9999, "time_seconds": 2, "yield": 99, "capacity": 9999, "seeded": true, "last_update": 1234},
		"": {"stored": 1},
		"bad-module": "bad-state",
	})
	var saved := game.call("_passive_modules_for_save") as Dictionary
	_expect(saved.size() == 1, "Passive module save should only keep named dictionary module entries.")
	_expect(saved.has("existing-module"), "Passive module save should preserve valid module ids.")
	var existing := saved.get("existing-module", {}) as Dictionary
	_expect(int(existing.get("stored", -1)) == 1000, "Passive module save should clamp stored values.")
	_expect(int(existing.get("time_seconds", -1)) == 30, "Passive module save should clamp time values.")
	_expect(int(existing.get("yield", -1)) == 18, "Passive module save should clamp yield values.")
	_expect(int(existing.get("capacity", -1)) == 1000, "Passive module save should clamp capacity values.")
	_expect(bool(existing.get("seeded", false)), "Passive module save should preserve seeded state.")
	_expect(int(existing.get("last_update", 0)) == 1234, "Passive module save should preserve module update timestamps.")


func _check_passive_module_restore(game: Node) -> void:
	game.set("passive_modules", {})
	game.call("_restore_passive_modules_from_save", {
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
	_expect(bool(existing.get("seeded", false)), "Passive restore should preserve seeded module state.")
	_expect(int(existing.get("last_update", 0)) == 1234, "Passive restore should preserve module update timestamp.")

	game.set("passive_modules", {
		"existing-module": {"stored": 99, "time_seconds": 99, "yield": 99, "capacity": 99, "seeded": false, "last_update": 99},
	})
	game.call("_restore_passive_modules_from_save", {
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


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("save-normalization-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "save-normalization-ok") "Save normalization test did not report success."
    Assert-NoUnexpectedGodotErrors $output "save normalization test"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the save normalization test."
    }
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
