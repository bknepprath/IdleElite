$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\crash-report-recovery"
$testUserDataDir = Join-Path $testDir "user-data"
$testScript = Join-Path $testDir "crash_report_recovery_test.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTestUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserDataDir
try {
    @'
extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const CrashReportRuntime := preload("res://scripts/diagnostics/crash_report_runtime.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("crash-report-recovery-start")
	var game := MainScript.new()
	_check_silent_json_parser_handles_malformed_external_text(game)
	_check_malformed_report_falls_back_to_raw_text(game)
	_check_java_exception_report_is_compacted(game)
	_check_unclean_session_report_is_summarized(game)
	_check_android_lifecycle_helpers(game)
	game.free()
	if failures.is_empty():
		print("crash-report-recovery-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_silent_json_parser_handles_malformed_external_text(game: Node) -> void:
	var crash_runtime := CrashReportRuntime.new(game)
	_expect(crash_runtime.call("_parse_json_silent", "{not-json") == null, "Silent JSON parser should return null for malformed external text.")
	_expect(crash_runtime.call("_parse_json_silent", "") == null, "Silent JSON parser should return null for empty external text.")
	var parsed_object = crash_runtime.call("_parse_json_silent", "{\"ok\":true}")
	_expect(typeof(parsed_object) == TYPE_DICTIONARY and bool((parsed_object as Dictionary).get("ok", false)), "Silent JSON parser should preserve valid JSON objects.")
	var parsed_array = crash_runtime.call("_parse_json_silent", "[1,2,3]")
	_expect(typeof(parsed_array) == TYPE_ARRAY and (parsed_array as Array).size() == 3, "Silent JSON parser should preserve valid JSON arrays.")


func _check_malformed_report_falls_back_to_raw_text(game: Node) -> void:
	var raw := "{not-json"
	_expect(CrashReportRuntime.clipboard_text(raw) == raw, "Malformed crash reports should be copied as raw text instead of throwing.")
	_expect(CrashReportRuntime.clipboard_text("[1,2,3]") == "[1,2,3]", "Non-dictionary crash reports should be copied as raw text.")


func _check_java_exception_report_is_compacted(game: Node) -> void:
	var report := {
		"kind": "java_exception",
		"timestamp_unix": 123,
		"version_name": "0.test",
		"version_code": 99,
		"device": "UnitDevice",
		"android_sdk": 35,
		"exception": "Boom",
		"thread": "main",
		"stack_trace": "line one\nline two\nline three\nline four",
		"android_diagnostic_events": [
			"2026-01-01T00:00:00.000 create version=0.test(99) device=UnitDevice",
			"2026-01-01T00:00:02.000 resume"
		]
	}
	var text := CrashReportRuntime.clipboard_text(JSON.stringify(report))
	_expect(text.find("Idle Elite crash report v2") >= 0, "Structured crash report should include the report header.")
	_expect(text.find("type: java_exception") >= 0, "Structured crash report should include the crash type.")
	_expect(text.find("build=0.test(99)") >= 0, "Structured crash report should include build metadata.")
	_expect(text.find("exception: Boom") >= 0, "Structured crash report should include exception summary.")
	_expect(text.find("- line three") >= 0 and text.find("line four") < 0, "Structured crash report should compact stack traces to the first three lines.")


func _check_unclean_session_report_is_summarized(game: Node) -> void:
	var report := {
		"kind": "unclean_previous_session",
		"reason": "previous_android_lifecycle:pause",
		"timestamp_unix": 200,
		"previous_session": {
			"status": "running",
			"timestamp_unix": 140,
			"os": "Android",
			"startup_initialized": true,
			"current_screen": "skill",
			"selected_skill_id": "fight",
			"running_skill_id": "fight",
			"running_action_id": "shove-wobbly-hay-bale",
			"action_progress": 0.5,
			"last_result": "testing"
		},
		"android_diagnostic_events": [
			"2026-01-01T00:00:00.000 create",
			"2026-01-01T00:00:01.000 pause",
			"2026-01-01T00:00:02.000 create"
		]
	}
	var text := CrashReportRuntime.clipboard_text(JSON.stringify(report))
	_expect(text.find("type: unclean_previous_session") >= 0, "Unclean session report should include the crash type.")
	_expect(text.find("prev_status: running startup=true os=Android") >= 0, "Unclean session report should summarize the previous marker.")
	_expect(text.find("screen: skill selected=fight") >= 0, "Unclean session report should include screen context.")
	_expect(text.find("verdict: pause before relaunch; clean lifecycle exit") >= 0, "Unclean session report should summarize lifecycle verdicts.")


func _check_android_lifecycle_helpers(game: Node) -> void:
	var clean_events := [
		"2026-01-01T00:00:00.000 create",
		"2026-01-01T00:00:01.000 stop",
		"2026-01-01T00:00:02.000 create"
	]
	var dirty_events := [
		"2026-01-01T00:00:00.000 create",
		"2026-01-01T00:00:01.000 resume",
		"2026-01-01T00:00:02.000 create"
	]
	_expect(CrashReportRuntime.previous_android_lifecycle_before_launch(clean_events) == "stop", "Lifecycle helper should find the previous lifecycle event before relaunch.")
	_expect(CrashReportRuntime.previous_android_lifecycle_was_clean(clean_events), "Lifecycle helper should treat stop as a clean pre-relaunch lifecycle.")
	_expect(not CrashReportRuntime.previous_android_lifecycle_was_clean(dirty_events), "Lifecycle helper should treat resume before relaunch as unclean.")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $baselineHeadlessProcessIds = @{}
    foreach ($process in @(Get-HeadlessGodotProcesses)) {
        $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
    }
    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "crash-report-recovery-ok") "Crash report recovery test did not report success."
    Assert-NoUnexpectedGodotErrors $output "crash report recovery test"

    $newHeadless = @()
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $newHeadless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
        if ($newHeadless.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A new headless Godot process is still running after the crash report recovery test."
    }
} finally {
    if ($null -eq $previousTestUserDataDir) {
        Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousTestUserDataDir
    }
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
