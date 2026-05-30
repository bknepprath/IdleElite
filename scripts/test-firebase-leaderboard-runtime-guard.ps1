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
	_expect(game._leaderboard_database_url_allowed("https://idle-elite-default-rtdb.firebaseio.com"), "US Realtime Database URL should be accepted.")
	_expect(game._leaderboard_database_url_allowed("https://idle-elite-default-rtdb.europe-west1.firebasedatabase.app"), "Regional Realtime Database URL should be accepted.")
	_expect(not game._leaderboard_database_url_allowed("http://idle-elite-default-rtdb.firebaseio.com"), "HTTP database URL should be rejected.")
	_expect(not game._leaderboard_database_url_allowed("https://idle-elite.example.com"), "Non-Firebase host should be rejected.")
	_expect(not game._leaderboard_database_url_allowed("https://idle-elite-default-rtdb.firebaseio.com.evil.example"), "Firebase-looking suffix on another host should be rejected.")
	_expect(not game._leaderboard_database_url_allowed("https://your-project-id-default-rtdb.firebaseio.com"), "Placeholder database URL should be rejected.")
	_expect(not game._leaderboard_database_url_allowed("https://idle_elite-default-rtdb.firebaseio.com"), "Unsafe database host characters should be rejected.")
	_expect(game._leaderboard_firebase_host_label_allowed("europe-west1"), "Firebase region label should be accepted.")
	_expect(not game._leaderboard_firebase_host_label_allowed("-europe-west1"), "Leading hyphen should be rejected.")
	_expect(not game._leaderboard_firebase_host_label_allowed("europe-west1-"), "Trailing hyphen should be rejected.")
	game.leaderboard_config_loaded = true
	game.leaderboard_config_database_url = "https://idle-elite-default-rtdb.firebaseio.com/"
	_expect(game._leaderboard_firebase_base_url() == "https://idle-elite-default-rtdb.firebaseio.com", "Runtime base URL getter should trim valid Firebase URLs.")
	game.leaderboard_config_database_url = "https://idle-elite.example.com"
	_expect(game._leaderboard_firebase_base_url() == "", "Runtime base URL getter should fail closed for malformed hosts.")
	game.leaderboard_config_database_url = "https://your-project-id-default-rtdb.firebaseio.com"
	_expect(game._leaderboard_firebase_base_url() == "", "Runtime base URL getter should fail closed for placeholder hosts.")
	game.leaderboard_config_web_api_key = "AIzaSyValidationOnlyNotARealFirebaseKey123456"
	_expect(game._leaderboard_firebase_api_key() == "AIzaSyValidationOnlyNotARealFirebaseKey123456", "Runtime API key getter should accept plausible Firebase keys.")
	game.leaderboard_config_web_api_key = "too-short"
	_expect(game._leaderboard_firebase_api_key() == "", "Runtime API key getter should reject short keys.")
	game.leaderboard_config_web_api_key = "AIzaSy Validation Only Key"
	_expect(game._leaderboard_firebase_api_key() == "", "Runtime API key getter should reject whitespace-damaged keys.")
	game.leaderboard_config_database_url = ""
	game.leaderboard_config_web_api_key = ""
	game.leaderboard_auth_in_flight = false
	game.leaderboard_fetch_in_flight = false
	game.leaderboard_submit_in_flight = false
	game.current_screen = "leaderboard"
	game._leaderboard_fetch_category(game.LEADERBOARD_CATEGORY_TOTAL_LEVEL)
	_expect_leaderboard_requests_idle(game, "fetch with absent config")
	game._leaderboard_submit_scores()
	_expect_leaderboard_requests_idle(game, "submit with absent config")
	game._process_leaderboard_sync(31.0)
	_expect_leaderboard_requests_idle(game, "sync with absent config")
	_expect(game.leaderboard_status_message == "Firebase URL and Web API key are not configured yet.", "Absent config should produce the fail-closed leaderboard status.")
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
