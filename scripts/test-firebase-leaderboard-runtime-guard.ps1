$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\firebase-runtime-guard"
$testScript = Join-Path $testDir "leaderboard_runtime_guard_test.gd"

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

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    @'
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var main_script = load("res://scripts/main.gd")
	var game = main_script.new()
	var online = game._online_runtime()
	_expect(online.call("_leaderboard_database_url_allowed", "https://idle-elite-default-rtdb.firebaseio.com"), "US Realtime Database URL should be accepted.")
	_expect(online.call("_leaderboard_database_url_allowed", "https://idle-elite-default-rtdb.europe-west1.firebasedatabase.app"), "Regional Realtime Database URL should be accepted.")
	_expect(not online.call("_leaderboard_database_url_allowed", "http://idle-elite-default-rtdb.firebaseio.com"), "HTTP database URL should be rejected.")
	_expect(not online.call("_leaderboard_database_url_allowed", "https://idle-elite.example.com"), "Non-Firebase host should be rejected.")
	_expect(not online.call("_leaderboard_database_url_allowed", "https://idle-elite-default-rtdb.firebaseio.com.evil.example"), "Firebase-looking suffix on another host should be rejected.")
	_expect(not online.call("_leaderboard_database_url_allowed", "https://your-project-id-default-rtdb.firebaseio.com"), "Placeholder database URL should be rejected.")
	_expect(not online.call("_leaderboard_database_url_allowed", "https://idle_elite-default-rtdb.firebaseio.com"), "Unsafe database host characters should be rejected.")
	_expect(online.call("_leaderboard_firebase_host_label_allowed", "europe-west1"), "Firebase region label should be accepted.")
	_expect(not online.call("_leaderboard_firebase_host_label_allowed", "-europe-west1"), "Leading hyphen should be rejected.")
	_expect(not online.call("_leaderboard_firebase_host_label_allowed", "europe-west1-"), "Trailing hyphen should be rejected.")
	game.leaderboard_config_loaded = true
	game.leaderboard_config_database_url = "https://idle-elite-default-rtdb.firebaseio.com/"
	_expect(online.call("_leaderboard_firebase_base_url") == "https://idle-elite-default-rtdb.firebaseio.com", "Runtime base URL getter should trim valid Firebase URLs.")
	game.leaderboard_config_database_url = "https://idle-elite.example.com"
	_expect(online.call("_leaderboard_firebase_base_url") == "", "Runtime base URL getter should fail closed for malformed hosts.")
	game.leaderboard_config_database_url = "https://your-project-id-default-rtdb.firebaseio.com"
	_expect(online.call("_leaderboard_firebase_base_url") == "", "Runtime base URL getter should fail closed for placeholder hosts.")
	game.leaderboard_config_web_api_key = "AIzaSyValidationOnlyNotARealFirebaseKey123456"
	_expect(online.call("_leaderboard_firebase_api_key") == "AIzaSyValidationOnlyNotARealFirebaseKey123456", "Runtime API key getter should accept plausible Firebase keys.")
	game.leaderboard_config_web_api_key = "too-short"
	_expect(online.call("_leaderboard_firebase_api_key") == "", "Runtime API key getter should reject short keys.")
	game.leaderboard_config_web_api_key = "AIzaSy Validation Only Key"
	_expect(online.call("_leaderboard_firebase_api_key") == "", "Runtime API key getter should reject whitespace-damaged keys.")
	game.leaderboard_config_database_url = ""
	game.leaderboard_config_web_api_key = ""
	game.leaderboard_auth_in_flight = false
	game.leaderboard_fetch_in_flight = false
	game.leaderboard_submit_in_flight = false
	game.cloud_save_fetch_in_flight = false
	game.cloud_save_upload_in_flight = false
	game.current_screen = "leaderboard"
	online.fetch_leaderboard_category(game.LEADERBOARD_CATEGORY_TOTAL_LEVEL)
	_expect_leaderboard_requests_idle(game, "fetch with absent config")
	online.submit_leaderboard_scores()
	_expect_leaderboard_requests_idle(game, "submit with absent config")
	online.fetch_cloud_save()
	_expect_leaderboard_requests_idle(game, "cloud fetch with absent config")
	online.call("_upload_cloud_save", true)
	_expect_leaderboard_requests_idle(game, "cloud upload with absent config")
	online.call("_process_leaderboard_sync", 31.0)
	_expect_leaderboard_requests_idle(game, "sync with absent config")
	_expect(game.leaderboard_status_message == "Online services are not connected yet.", "Absent config should produce the fail-closed leaderboard status.")
	_expect(online.call("_cloud_save_status_text") == "Cloud save is offline until Firebase is configured.", "Cloud-save status should clearly explain absent Firebase config.")
	game.leaderboard_config_loaded = true
	game.leaderboard_config_database_url = "https://idle-elite-default-rtdb.firebaseio.com/"
	game.leaderboard_config_web_api_key = "AIzaSyValidationOnlyNotARealFirebaseKey123456"
	game.google_auth_web_client_id = ""
	game.leaderboard_display_name = "guest1234"
	game.leaderboard_name_key = ""
	game.leaderboard_profile_claimed = false
	game.leaderboard_name_claim_verified = false
	online.call("_start_google_account_sign_in")
	_expect(game.google_auth_status_message == "Save a username before connecting Google.", "Google sign-in should require a claimed username first.")
	game.leaderboard_display_name = "Validation Player"
	game.leaderboard_name_key = "validation_player"
	game.leaderboard_profile_claimed = true
	game.leaderboard_name_claim_verified = true
	online.call("_start_google_account_sign_in")
	_expect(game.google_auth_status_message == "Google sign-in needs google_web_client_id in firebase-leaderboard-config.json.", "Google sign-in without a client id should explain the missing config key.")
	game.google_auth_web_client_id = "1234567890-validationonly.apps.googleusercontent.com"
	online.call("_start_google_account_sign_in")
	_expect(game.google_auth_status_message == "Google sign-in is not available in this build yet.", "Non-Android Google sign-in should explain that this build has no native Google auth.")
	online.call("_on_google_sign_in_failed", "")
	_expect(game.google_auth_status_message == "Google sign-in was cancelled.", "Empty Google failure should read as a cancellation.")
	online.call("_on_google_sign_in_failed", "androidx.credentials.exceptions.GetCredentialCancellationException: activity is canceled by the user")
	_expect(game.google_auth_status_message == "Google sign-in was cancelled.", "Native cancellation text should be player-friendly.")
	online.call("_on_google_sign_in_failed", "No credentials available")
	_expect(game.google_auth_status_message == "No Google account was selected. Try Connect Google again.", "Missing credential text should tell the player what to do next.")
	online.call("_on_google_sign_in_failed", "Network timeout")
	_expect(game.google_auth_status_message == "Google sign-in needs an internet connection. Try again in a moment.", "Network Google failure should be actionable.")
	online.call("_on_google_sign_in_failed", "provider exploded")
	_expect(game.google_auth_status_message == "Google sign-in failed: provider exploded", "Unknown Google failure should preserve useful details.")
	game.free()
	if failures.is_empty():
		print("firebase-runtime-guard-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _expect_leaderboard_requests_idle(game: Node, context: String) -> void:
	_expect(not game.leaderboard_auth_in_flight, "%s should not start Firebase Auth." % context)
	_expect(not game.leaderboard_fetch_in_flight, "%s should not start a leaderboard read." % context)
	_expect(not game.leaderboard_submit_in_flight, "%s should not start a leaderboard write." % context)
	_expect(not game.cloud_save_fetch_in_flight, "%s should not start a cloud save read." % context)
	_expect(not game.cloud_save_upload_in_flight, "%s should not start a cloud save write." % context)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    & $runner --headless --path $projectRoot --script $testScript
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the runtime guard test."
    }
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
