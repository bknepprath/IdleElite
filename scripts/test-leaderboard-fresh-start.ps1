param([switch]$StaticOnly)

# Leaderboard fresh start (0.6.0 leaderboard wipe): returning 0.5.3 players and
# preview testers with legacy identity state must sign in anonymously like new
# players, never block publishing on support recovery, and keep local progress.
# The game is never added to the SceneTree, so HTTPRequest cannot reach the
# network; every Firebase response is simulated by calling the completion
# handlers directly. The engine's 'Condition "!is_inside_tree()" is true' lines in
# the output are those refused requests and are expected.

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$runtimePath = Join-Path $projectRoot "scripts\online\online_runtime.gd"
$identitySafetyPath = Join-Path $projectRoot "scripts\online\identity_safety.gd"
$normalizersPath = Join-Path $projectRoot "scripts\save_state\normalizers.gd"
$testDir = Join-Path $projectRoot (".codex-tmp\leaderboard-fresh-start-{0}" -f [guid]::NewGuid().ToString("N"))
$testScript = Join-Path $testDir "leaderboard_fresh_start_test.gd"
$testUserDataDir = Join-Path $testDir "user-data"
$previousTestUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
$runtime = Get-Content -LiteralPath $runtimePath -Raw
$identitySafety = Get-Content -LiteralPath $identitySafetyPath -Raw
$normalizers = Get-Content -LiteralPath $normalizersPath -Raw

Assert-True ($identitySafety -match '(?m)^const LEADERBOARD_FRESH_START := true\r?$') "The leaderboard fresh-start switch must be a single named constant and enabled for the wipe release."
$restartAllowedBlock = [regex]::Match($runtime, '(?s)func _fresh_start_anonymous_restart_allowed\(\).*?(?=\r?\nfunc |\r?\n\r?\n\r?\n)').Value
Assert-True ($restartAllowedBlock.Length -gt 0) "The fresh-start anonymous restart eligibility must be one named function."
Assert-True ($restartAllowedBlock -notmatch 'OS\.get_name|has_feature') "The fresh-start anonymous restart must not depend on the platform (Android included)."
Assert-True ($restartAllowedBlock -match 'leaderboard_auth_provider == "google"') "A Google account must never be replaced by an anonymous restart."
$submitBlock = [regex]::Match($runtime, '(?s)func _leaderboard_submit_scores\(\).*?(?=\r?\nfunc )').Value
Assert-True ($submitBlock -match 'if not IdentitySafety\.LEADERBOARD_FRESH_START and \(leaderboard_name_transfer_required or leaderboard_legacy_username_recovery_required\)') "Legacy transfer state must never pause publishing in fresh-start mode."
$probeBlock = [regex]::Match($runtime, '(?s)func _on_fresh_start_claim_probe_completed\(.*?(?=\r?\nfunc )').Value
Assert-True ($probeBlock -match 'response_code == 401 or response_code == 403:[\s\S]*_fresh_start_release_unavailable_name\(\)' -and $runtime -match 'if not _start_fresh_start_claim_probe\(\):') "A name may be given up only after a claim-only probe is refused."
$releaseBlock = [regex]::Match($runtime, '(?s)func _fresh_start_release_unavailable_name\(\).*?(?=\r?\nfunc )').Value
Assert-True ($releaseBlock -match 'leaderboard_released_name_key = released_key' -and $releaseBlock -match 'if not _save_identity_state\(' -and $releaseBlock -match 'leaderboard_released_name_key = str\(previous_profile') "Dropping an unavailable name must persist the released key the save guard requires and restore the profile if the save fails."
Assert-True ($identitySafety -match 'func fresh_start_claimed_name_released' -and $normalizers -match 'IdentitySafety\.fresh_start_claimed_name_released\(existing_payload, next_payload\)') "The save guard may drop a claimed name only for the same UID's persisted released key."
Assert-True ($normalizers -match 'IdentitySafety\.fresh_start_legacy_identity_state\(existing_payload\)') "The save guard must let fresh start retire legacy-only recovery without blocking saves."
Assert-True ($normalizers -match '\(next_bound_uid\.is_empty\(\) or next_player_id != next_bound_uid or next_refresh_token\.is_empty\(\)\)') "The save guard must keep the credential check for non-legacy recovery."
Assert-True ($normalizers -match 'if existing_claimed and not next_claimed and not claimed_name_released:\s+return true' -and $normalizers -match 'next_player_id != existing_player_id') "Claimed-name and UID save checks must remain."

if ($StaticOnly) {
    Write-Output "leaderboard-fresh-start-static-ok"
    return
}

$baselineHeadlessProcessIds = @(Get-HeadlessGodotProcesses | ForEach-Object ProcessId)
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserDataDir
    @'
extends SceneTree

const SaveRuntime = preload("res://scripts/save_state/save_runtime.gd")
const LeaderboardState = preload("res://scripts/leaderboard/state.gd")
const IdentitySafety = preload("res://scripts/online/identity_safety.gd")

const LEGACY_UID := "p0123456789abcdef0123456789abcdef"
const SKILL_XP := {"fight": 1234567, "fishing": 234567, "build": 345678, "woodcutting": 456789, "thieving": 567890}
const FAKE_DATABASE_URL := "https://fresh-start-offline-test-default-rtdb.firebaseio.com"
const FAKE_API_KEY := "AIzaSyFreshStartOfflineTestOnlyKey0000000"

var failures: Array[String] = []


func _init() -> void:
	_expect(IdentitySafety.LEADERBOARD_FRESH_START, "Fresh start must be enabled.")
	_scenario_legacy_authless_claim_reclaimed()
	_scenario_preview_tester_flags_and_name_taken()
	_scenario_deleted_anonymous_login()
	_scenario_genuine_recovery_kept()
	if failures.is_empty():
		print("leaderboard-fresh-start-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


# 0.5.3 web-style save: authless p+32 id with a claimed, verified name.
func _scenario_legacy_authless_claim_reclaimed() -> void:
	var game = _boot_with_save(_fixture({}))
	var online = game._online_runtime()
	_expect_no_legacy_flags(online, "legacy authless after load")
	_expect_skills_unchanged(game, "legacy authless after load")
	_expect(not online.legacy_authless_google_transition_required(), "A legacy authless save must not be pushed to Google.")
	_expect(not online.deleted_auth_google_transition_required(), "A legacy authless save is not a deleted Google account.")
	_expect(online.call("_anonymous_sign_up_mode") == "fresh_start_anonymous_restart", "A legacy authless save must request an anonymous sign-in.")
	online.submit_leaderboard_scores()
	_expect(game.leaderboard_state.status_message.find("paused") < 0, "Publishing must not be paused for a legacy save: %s" % game.leaderboard_state.status_message)
	_expect(game.leaderboard_state.status_message.begins_with("Online login failed to start."), "Publishing must start the anonymous login (offline in this test): %s" % game.leaderboard_state.status_message)
	_expect(not online.leaderboard_auth_recovery_required, "Starting the login must not enter account recovery.")
	online.leaderboard_auth_retry_after_unix = 0
	_simulate_anonymous_sign_up(online, "fresh_start_anonymous_restart", "freshAnonUidLegacy0001")
	_expect(game.leaderboard_profile.player_id == "freshAnonUidLegacy0001", "The new anonymous UID must become the leaderboard player id.")
	_expect(online.leaderboard_auth_bound_uid == "freshAnonUidLegacy0001" and online.leaderboard_auth_provider == "anonymous", "The new UID must be bound as an anonymous login.")
	_expect(online.leaderboard_auth_last_transition_outcome == "fresh_start_new_identity", "The transition must be recorded as a fresh-start identity.")
	_expect(game.leaderboard_profile.display_name == "LegacyHero" and game.leaderboard_profile.profile_claimed, "The saved display name must be kept for the reclaim.")
	_expect_no_legacy_flags(online, "legacy authless after sign-in")
	_expect_skills_unchanged(game, "legacy authless after sign-in")
	var persisted := SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	_expect(str(persisted.get("leaderboard_player_id", "")) == "freshAnonUidLegacy0001", "The adopted UID must be saved.")
	_expect_persisted_skills(persisted, "legacy authless after sign-in")
	_expect_no_persisted_legacy_flags(persisted, "legacy authless after sign-in")
	_expect(game.leaderboard_state.repair_publish_due(), "The first publish under the new UID must republish every category.")
	_expect(game.leaderboard_state.last_submitted_scores_by_category.is_empty(), "Old submission checkpoints must not suppress categories under the new UID.")
	online.submit_leaderboard_scores()
	_expect(game.leaderboard_state.status_message.begins_with("Checking your leaderboard name"), "Publishing must first confirm the name claim for the new UID: %s" % game.leaderboard_state.status_message)
	online.profile_recovery_fetch_in_flight = false
	online.call("_on_profile_recovery_fetch_completed", HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), "null".to_utf8_buffer())
	_expect(online.leaderboard_fresh_start_name_reclaim_pending, "A missing canonical profile must re-claim the saved name.")
	online.profile_reference_update_in_flight = true
	online.profile_reference_update_stage = "canonical"
	online.call("_on_profile_reference_update_completed", HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), PackedByteArray())
	_expect(online.leaderboard_fresh_start_profile_confirmed_uid == "freshAnonUidLegacy0001", "A successful reclaim must confirm the new UID.")
	_expect(game.leaderboard_state.status_message.begins_with("Leaderboard write failed"), "A successful reclaim must immediately start the republish (offline here): %s" % game.leaderboard_state.status_message)
	_expect(game.leaderboard_profile.display_name == "LegacyHero" and game.leaderboard_profile.profile_claimed, "A reclaimed name must stay claimed.")
	_expect(game.save_game(), "Saves must keep working after the fresh start.")
	_expect_persisted_skills(SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH), "legacy authless after republish")
	_shutdown(game)


# 0.6.0 preview tester: Android forced legacy recovery and persisted it.
func _scenario_preview_tester_flags_and_name_taken() -> void:
	var game = _boot_with_save(_fixture({
		"leaderboard_auth_recovery_required": true,
		"leaderboard_auth_recovery_reason": "The previous online login is missing.",
		"leaderboard_name_transfer_required": true,
		"leaderboard_legacy_username_recovery_required": false,
		"leaderboard_legacy_authless_old_uid": LEGACY_UID,
		"leaderboard_legacy_name_hint_display": "LegacyHero",
		"leaderboard_legacy_name_hint_key": "legacyhero",
	}))
	var online = game._online_runtime()
	_expect_no_legacy_flags(online, "preview tester after load")
	_expect_skills_unchanged(game, "preview tester after load")
	_expect(game.save_game(), "Clearing persisted legacy flags must not block saves.")
	var persisted := SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	_expect_no_persisted_legacy_flags(persisted, "preview tester after load")
	_expect(persisted.has("leaderboard_name_transfer_required") and persisted.has("leaderboard_legacy_authless_old_uid"), "Legacy save keys must stay in the save format.")
	_expect(online.call("_anonymous_sign_up_mode") == "fresh_start_anonymous_restart", "A preview tester must request an anonymous sign-in.")
	online.call("_claim_leaderboard_name", "Another Name")
	_expect(online.leaderboard_name_claim_in_flight, "Claiming a new name must not be blocked by legacy state.")
	online.leaderboard_name_claim_in_flight = false
	online.leaderboard_name_claim_pending_name = ""
	online.leaderboard_name_claim_pending_key = ""
	online.leaderboard_auth_retry_after_unix = 0
	_simulate_anonymous_sign_up(online, "fresh_start_anonymous_restart", "freshAnonUidPreview0002")
	_expect(game.leaderboard_profile.player_id == "freshAnonUidPreview0002", "Preview testers must adopt the new anonymous UID.")
	_expect_no_legacy_flags(online, "preview tester after sign-in")
	online.profile_recovery_fetch_in_flight = false
	online.call("_on_profile_recovery_fetch_completed", HTTPRequest.RESULT_SUCCESS, 401, PackedStringArray(), "{\"error\":\"Permission denied\"}".to_utf8_buffer())
	_expect(online.leaderboard_fresh_start_name_reclaim_pending, "A denied canonical read must re-claim the saved name.")
	online.profile_reference_update_in_flight = true
	online.profile_reference_update_stage = "canonical"
	online.call("_on_profile_reference_update_completed", HTTPRequest.RESULT_SUCCESS, 401, PackedStringArray(), PackedByteArray())
	_expect(game.leaderboard_profile.profile_claimed, "A refused claim + profile write alone must not drop the name before the claim-only probe.")
	# Probe says the claim is ours (only the profile write was refused): keep the name.
	online.profile_reference_update_in_flight = true
	online.profile_reference_update_stage = "fresh_start_claim_probe"
	online.call("_on_profile_reference_update_completed", HTTPRequest.RESULT_SUCCESS, 204, PackedStringArray(), PackedByteArray())
	_expect(game.leaderboard_profile.profile_claimed and game.leaderboard_profile.display_name == "LegacyHero", "A claim that still belongs to this UID must be kept.")
	# Probe says someone else holds the claim: fall back to a guest name.
	online.profile_reference_update_in_flight = true
	online.profile_reference_update_stage = "fresh_start_claim_probe"
	online.call("_on_profile_reference_update_completed", HTTPRequest.RESULT_SUCCESS, 401, PackedStringArray(), PackedByteArray())
	_expect(not game.leaderboard_profile.profile_claimed and game.leaderboard_profile.name_key.is_empty(), "A name held by someone else must fall back to the guest-name path.")
	_expect(game.leaderboard_profile.display_name.begins_with(game.PROFILE_GUEST_NAME_PREFIX), "The fallback must use a guest display name.")
	_expect(game.leaderboard_state.status_message.find("taken") >= 0, "The player must be told the name is taken: %s" % game.leaderboard_state.status_message)
	_expect(game.leaderboard_state.status_message.find("paused") < 0, "Publishing must not be paused after a taken name.")
	_expect_no_legacy_flags(online, "preview tester after name taken")
	persisted = SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	_expect(not bool(persisted.get("leaderboard_profile_claimed", true)), "The guest fallback must be saved.")
	_expect_persisted_skills(persisted, "preview tester after name taken")
	_expect(game.save_game(), "Saves must keep working after the guest fallback.")
	_expect_skills_unchanged(game, "preview tester after name taken")
	_shutdown(game)
	# Older backups still hold the claimed name; a reboot must keep the released save.
	game = _boot_from_disk()
	online = game._online_runtime()
	_expect(game.leaderboard_profile.player_id == "freshAnonUidPreview0002", "A reboot after the guest fallback must keep the new UID.")
	_expect(not game.leaderboard_profile.profile_claimed, "A reboot must not restore the released name from an older backup.")
	_expect_skills_unchanged(game, "preview tester after reboot")
	_expect_no_legacy_flags(online, "preview tester after reboot")
	online.leaderboard_name_claim_pending_name = "Second Hero"
	online.leaderboard_name_claim_pending_key = "second_hero"
	online.call("_on_leaderboard_name_claim_completed", HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), PackedByteArray())
	_expect(game.leaderboard_profile.profile_claimed and game.leaderboard_profile.display_name == "Second Hero", "The player must be able to claim another name after the fallback.")
	_expect(game.save_game(), "Saves must keep working after claiming a new name.")
	persisted = SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH)
	_expect(str(persisted.get("leaderboard_display_name", "")) == "Second Hero" and bool(persisted.get("leaderboard_profile_claimed", false)), "The new claimed name must be saved.")
	_expect(game.leaderboard_state.repair_publish_due(), "The new name must republish every category.")
	_shutdown(game)
	game = _boot_from_disk()
	_expect(game.leaderboard_profile.display_name == "Second Hero" and game.leaderboard_profile.profile_claimed, "A reboot must keep the newly claimed name.")
	_expect_skills_unchanged(game, "preview tester after new name reboot")
	_shutdown(game)


# An anonymous Firebase login that was deleted server-side.
func _scenario_deleted_anonymous_login() -> void:
	var game = _boot_with_save(_fixture({
		"leaderboard_player_id": "anonDeletedUid000003",
		"leaderboard_auth_bound_uid": "anonDeletedUid000003",
		"leaderboard_auth_provider": "anonymous",
		"leaderboard_auth_refresh_token": "dead-refresh-token",
	}))
	var online = game._online_runtime()
	_expect_no_legacy_flags(online, "deleted anonymous after load")
	online.leaderboard_auth_mode = "refresh"
	online.call("_on_leaderboard_auth_completed", HTTPRequest.RESULT_SUCCESS, 400, PackedStringArray(), "{\"error\":{\"message\":\"USER_NOT_FOUND\"}}".to_utf8_buffer())
	_expect(not online.leaderboard_auth_recovery_required, "A deleted anonymous login must not require support or Google recovery.")
	_expect(online.leaderboard_fresh_start_restart_source_uid == "anonDeletedUid000003", "A deleted anonymous login must restart from its own UID.")
	_expect(online.call("_anonymous_sign_up_mode") == "fresh_start_anonymous_restart", "A deleted anonymous login must request an anonymous sign-in.")
	online.leaderboard_auth_retry_after_unix = 0
	_simulate_anonymous_sign_up(online, "fresh_start_anonymous_restart", "freshAnonUidDeleted0003")
	_expect(game.leaderboard_profile.player_id == "freshAnonUidDeleted0003" and online.leaderboard_auth_refresh_token == "refresh-freshAnonUidDeleted0003", "The deleted login must be replaced by the new anonymous login.")
	_expect(online.leaderboard_fresh_start_restart_source_uid.is_empty(), "The restart marker must clear once applied.")
	_expect_no_legacy_flags(online, "deleted anonymous after sign-in")
	_expect_persisted_skills(SaveRuntime.load_dictionary(SaveRuntime.SAVE_PATH), "deleted anonymous after sign-in")
	_shutdown(game)


# Genuine recovery (disabled accounts, Google accounts) is not legacy migration.
func _scenario_genuine_recovery_kept() -> void:
	var game = _boot_with_save(_fixture({
		"leaderboard_player_id": "anonDisabledUid00004",
		"leaderboard_auth_bound_uid": "anonDisabledUid00004",
		"leaderboard_auth_provider": "anonymous",
		"leaderboard_auth_refresh_token": "disabled-refresh-token",
	}))
	var online = game._online_runtime()
	online.leaderboard_auth_mode = "refresh"
	online.call("_on_leaderboard_auth_completed", HTTPRequest.RESULT_SUCCESS, 400, PackedStringArray(), "{\"error\":{\"message\":\"USER_DISABLED\"}}".to_utf8_buffer())
	_expect(online.leaderboard_auth_recovery_required and online.leaderboard_fresh_start_restart_source_uid.is_empty(), "A disabled account must stay blocked, not restart anonymously.")
	_shutdown(game)
	game = _boot_with_save(_fixture({
		"leaderboard_player_id": "googleUid00000000005",
		"leaderboard_auth_bound_uid": "googleUid00000000005",
		"leaderboard_auth_provider": "google",
		"leaderboard_auth_refresh_token": "google-refresh-token",
	}))
	online = game._online_runtime()
	online.leaderboard_auth_mode = "refresh"
	online.call("_on_leaderboard_auth_completed", HTTPRequest.RESULT_SUCCESS, 400, PackedStringArray(), "{\"error\":{\"message\":\"TOKEN_EXPIRED\"}}".to_utf8_buffer())
	_expect(online.leaderboard_auth_recovery_required, "A Google account must keep its Google recovery path.")
	_expect(game.leaderboard_profile.player_id == "googleUid00000000005", "Google recovery must preserve the UID.")
	_shutdown(game)


func _fixture(overrides: Dictionary) -> Dictionary:
	var skills := {}
	for skill_id in SKILL_XP.keys():
		skills[skill_id] = {"xp": int(SKILL_XP[skill_id]), "level": 1}
	var payload := {
		"save_schema_version": 2,
		"save_revision": 7,
		"save_reset_generation": 0,
		"skills": skills,
		"mastery": {},
		"stamina": {},
		"stamina_bank": {},
		"mats": {"softwood": 321.0},
		"selected_skill_id": "fight",
		"running_skill_id": "",
		"running_action_id": "",
		"action_progress": 0.0,
		"onboarding_tutorial_complete": true,
		"leaderboard_display_name": "LegacyHero",
		"leaderboard_name_key": "legacyhero",
		"leaderboard_profile_claimed": true,
		"leaderboard_name_claim_verified": true,
		"leaderboard_player_id": LEGACY_UID,
		"leaderboard_auth_provider": "",
		"leaderboard_auth_refresh_token": "",
		"leaderboard_last_submitted_scores_by_category": {"total_level": 50},
		"leaderboard_last_submit_unix": int(Time.get_unix_time_from_system()) - 60,
		"leaderboard_repair_publish_version": LeaderboardState.REPAIR_PUBLISH_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
	}
	for key in overrides.keys():
		payload[key] = overrides[key]
	return payload


func _boot_with_save(payload: Dictionary) -> Node:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://"))
	for path in [SaveRuntime.SAVE_PATH, SaveRuntime.SAVE_TEMP_PATH, SaveRuntime.SAVE_BACKUP_PATH, SaveRuntime.SAVE_BACKUP_2_PATH, SaveRuntime.SAVE_BACKUP_3_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	_expect(SaveRuntime.write_payload_atomically(payload, SaveRuntime.SAVE_PATH, SaveRuntime.SAVE_TEMP_PATH, SaveRuntime.SAVE_BACKUP_PATH, SaveRuntime.SAVE_BACKUP_2_PATH, SaveRuntime.SAVE_BACKUP_3_PATH), "Fixture save must be writable.")
	return _boot_from_disk()


func _boot_from_disk() -> Node:
	var game = load("res://scripts/main.gd").new()
	game.activity_data_catalog.load_action_data(game)
	game._save_runtime()._init_state()
	game._save_runtime().load_game()
	game._save_runtime()._load_game_secondary_restore()
	_expect(bool(game.save_restore_complete), "The fixture save must finish restoring.")
	var online = game._online_runtime()
	# Never in the SceneTree: HTTPRequest refuses to start, so nothing reaches Firebase.
	_expect(not game.is_inside_tree() and not online.is_inside_tree(), "The test game must stay outside the SceneTree so no network request can start.")
	online.leaderboard_config_loaded = true
	online.leaderboard_config_database_url = FAKE_DATABASE_URL
	online.leaderboard_config_web_api_key = FAKE_API_KEY
	online.ensure_leaderboard_http()
	return game


func _simulate_anonymous_sign_up(online, mode: String, new_uid: String) -> void:
	online.leaderboard_auth_in_flight = true
	online.leaderboard_auth_mode = mode
	var body := JSON.stringify({
		"idToken": "id-%s" % new_uid,
		"refreshToken": "refresh-%s" % new_uid,
		"localId": new_uid,
		"expiresIn": "3600"
	})
	online.call("_on_leaderboard_auth_completed", HTTPRequest.RESULT_SUCCESS, 200, PackedStringArray(), body.to_utf8_buffer())


func _expect_no_legacy_flags(online, context: String) -> void:
	_expect(not online.leaderboard_auth_recovery_required, "%s: auth recovery must not be required." % context)
	_expect(not online.leaderboard_name_transfer_required, "%s: name transfer must not be required." % context)
	_expect(not online.leaderboard_legacy_username_recovery_required, "%s: legacy username recovery must not be required." % context)
	_expect(not online.leaderboard_deleted_auth_transition_pending, "%s: no deleted-account transfer may be pending." % context)
	_expect(online.account_recovery_code() == "", "%s: no support recovery code may be shown." % context)


func _expect_no_persisted_legacy_flags(payload: Dictionary, context: String) -> void:
	for key in ["leaderboard_auth_recovery_required", "leaderboard_name_transfer_required", "leaderboard_legacy_username_recovery_required", "leaderboard_deleted_auth_transition_pending"]:
		_expect(not bool(payload.get(key, false)), "%s: saved %s must be false." % [context, key])


func _expect_skills_unchanged(game, context: String) -> void:
	for skill_id in SKILL_XP.keys():
		var state := (game.skills as Dictionary).get(skill_id, {}) as Dictionary
		_expect(int(state.get("xp", -1)) == int(SKILL_XP[skill_id]), "%s: local %s XP must be unchanged." % [context, skill_id])


func _expect_persisted_skills(payload: Dictionary, context: String) -> void:
	var skills := payload.get("skills", {}) as Dictionary
	for skill_id in SKILL_XP.keys():
		_expect(int((skills.get(skill_id, {}) as Dictionary).get("xp", -1)) == int(SKILL_XP[skill_id]), "%s: saved %s XP must be unchanged." % [context, skill_id])


func _shutdown(game) -> void:
	game.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | ForEach-Object { Write-Host $_ }
    $renderedOutput = $output | Out-String -Width 4096
    if ($LASTEXITCODE -ne 0) { throw "Leaderboard fresh-start test failed with exit code $LASTEXITCODE." }
    if ($renderedOutput -match "SCRIPT ERROR:") { throw "Leaderboard fresh-start test reported a Godot script error." }
    # The safe runner does not always propagate quit(1); require the success line.
    if ($renderedOutput -notmatch "leaderboard-fresh-start-ok") { throw "Leaderboard fresh-start test did not report success." }

    $headless = @()
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $headless = @(Get-HeadlessGodotProcesses | Where-Object { $baselineHeadlessProcessIds -notcontains $_.ProcessId })
        if ($headless.Count -eq 0) { break }
        Start-Sleep -Milliseconds 500
    }
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the leaderboard fresh-start test."
    }
    Write-Output "leaderboard-fresh-start-ok"
} finally {
    if ($null -eq $previousTestUserDataDir) {
        Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousTestUserDataDir
    }
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
