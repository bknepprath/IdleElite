$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\crash-report-recovery"
$testScript = Join-Path $testDir "crash_report_recovery_test.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    @'
extends SceneTree

const CrashReportRuntime := preload("res://scripts/diagnostics/crash_report_runtime.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("crash-report-recovery-start")
	var game := Node.new()
	_check_silent_json_parser_handles_malformed_external_text(game)
	_check_malformed_report_falls_back_to_raw_text(game)
	_check_java_exception_report_is_compacted(game)
	_check_unclean_session_report_is_summarized(game)
	_check_save_failure_report_is_classified(game)
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
			"loaded_save_this_boot": true,
			"save_restore_complete": false,
			"save_restore_pending": true,
			"save_writes_blocked": true,
			"save_writes_blocked_reason": "existing save files require recovery",
			"save_dirty": true,
			"save_dirty_reason": "save restore is incomplete",
			"auth_diagnostics": {
				"provider": "anonymous",
				"refresh_token_present": true,
				"bound_uid_present": true,
				"bound_uid_fingerprint": "0123456789ab",
				"recovery_required": false,
				"last_error_class": "transient",
				"last_uid_transition_outcome": "refresh_same_identity",
				"events": [
					{
						"at_unix": 139,
						"event": "auth_applied",
						"detail": "refresh same identity",
						"provider": "anonymous",
						"refresh_token_present": true,
						"bound_uid_present": true,
						"bound_uid_fingerprint": "0123456789ab",
						"recovery_required": false,
						"refresh_token": "secret-auth-token"
					}
				]
			},
			"save_journal": [
				{
					"at": 138,
					"event": "load_selected",
					"result": "recovered",
					"source": "idle_elite_save.backup.json",
					"revision": 42,
					"payload": "secret-save-payload"
				}
			],
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
	_expect(text.find("save: loaded=true restored=false pending=true writes_blocked=true blocked_reason=existing save files require recovery dirty=true reason=save restore is incomplete") >= 0, "Unclean session report should include save-restore, write-block, and dirty-state context.")
	_expect(text.find("auth: provider=anonymous token=true bound=true uid=0123456789ab recovery=false error=transient transition=refresh_same_identity") >= 0, "Unclean session report should include redacted authentication context.")
	_expect(text.find("save_events:\n- at=138 event=load_selected result=recovered source=idle_elite_save.backup.json revision=42") >= 0, "Unclean session report should include the bounded save event timeline.")
	_expect(text.find("auth_events:\n- at_unix=139 event=auth_applied detail=refresh same identity provider=anonymous refresh_token_present=true bound_uid_present=true recovery_required=false bound_uid_fingerprint=0123456789ab") >= 0, "Unclean session report should include the bounded authentication event timeline.")
	_expect(text.find("secret-auth-token") < 0 and text.find("secret-save-payload") < 0, "Support event timelines must exclude unapproved secret fields.")
	_expect(text.find("verdict: pause before relaunch; clean lifecycle exit") >= 0, "Unclean session report should summarize lifecycle verdicts.")
	var tail := CrashReportRuntime._tail_events([1, 2, 3, 4], 2) as Array
	_expect(tail == [3, 4], "Diagnostic event tails should remain bounded to the newest events.")
	var bounded_reason := CrashReportRuntime._bounded_support_text("recovery\n" + "x".repeat(200), 24)
	_expect(bounded_reason.length() == 24 and bounded_reason.find("\n") < 0, "Save-write block reasons should be single-line and bounded in support output.")
	var live_save_context := CrashReportRuntime.save_support_context({
		"pending_save_restore_data": {},
		"save_writes_blocked": true,
		"save_writes_blocked_reason": "recovery\n" + "x".repeat(200),
		"save_dirty": false,
		"save_dirty_reason": "",
	})
	_expect(bool(live_save_context.get("save_writes_blocked", false)), "Live support context should record that save writes are blocked.")
	_expect(str(live_save_context.get("save_writes_blocked_reason", "")).length() == 120 and str(live_save_context.get("save_writes_blocked_reason", "")).find("\n") < 0, "Live support context should bound and sanitize the write-block reason.")
	_expect(not bool(live_save_context.get("save_restore_pending", true)) and not bool(live_save_context.get("save_dirty", true)), "Live support context should preserve an unrecoverable boot's pending and dirty signals.")


func _check_save_failure_report_is_classified(game: Node) -> void:
	var metadata := CrashReportRuntime.previous_session_report_metadata("save_failed", "stop")
	_expect(str(metadata.get("kind", "")) == "save_persistence_failure", "A failed lifecycle save should be classified as a persistence failure.")
	_expect(str(metadata.get("reason", "")) == "local_save_write_failed", "A failed lifecycle save should have a save-specific reason.")
	_expect(str(metadata.get("message", "")).find("could not persist the local save") >= 0, "A failed lifecycle save should have an accurate support message.")
	_expect(str(metadata.get("message", "")).find("native crash") < 0, "A failed lifecycle save must not be mislabeled as a native crash.")
	var report := {
		"kind": metadata.get("kind", ""),
		"reason": metadata.get("reason", ""),
		"timestamp_unix": 200,
		"previous_session": {
			"status": "save_failed",
			"timestamp_unix": 190,
			"os": "Android",
			"save_restore_complete": true,
			"save_dirty": true,
			"save_dirty_reason": "primary promote failed"
		}
	}
	var text := CrashReportRuntime.clipboard_text(JSON.stringify(report))
	_expect(text.find("type: save_persistence_failure") >= 0, "Persistence-failure clipboard reports should retain their classification.")
	_expect(text.find("prev_status: save_failed") >= 0, "Persistence-failure clipboard reports should include previous-session state.")


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
	_expect(CrashReportRuntime.session_marker_requires_report("save_failed", true), "A failed save must produce a support report even after a normal Android pause.")
	_expect(not CrashReportRuntime.session_marker_requires_report("clean_save_deferred", false), "An intentionally deferred pre-restore save should remain a clean lifecycle marker.")


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
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
