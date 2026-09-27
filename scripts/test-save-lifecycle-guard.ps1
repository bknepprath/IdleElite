$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\save-lifecycle-guard"
$testScript = Join-Path $testDir "save_lifecycle_guard_test.gd"
$testUserData = Join-Path ([System.IO.Path]::GetTempPath()) ("idle-elite-save-lifecycle-" + $PID)
$previousTestUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserData
    @'
extends SceneTree

const AppLifecycleRuntime = preload("res://scripts/app/lifecycle_runtime.gd")

class FakeHost:
	extends RefCounted
	var save_restore_complete := false
	var save_writes_blocked := false
	var save_result := true
	var save_calls := 0

	func _save_runtime():
		return self

	func save_game() -> bool:
		save_calls += 1
		return save_result


var failures: Array[String] = []


func _init() -> void:
	var host := FakeHost.new()
	var lifecycle := AppLifecycleRuntime.new(host)

	host.save_restore_complete = false
	_expect(not lifecycle._runtime_save_is_safe(), "Core-loaded or rendered state must not make saving safe before full restore.")
	_expect(lifecycle._persist_for_lifecycle() == 0, "Lifecycle persistence should defer while restore is incomplete.")
	_expect(host.save_calls == 0, "Deferred lifecycle persistence must not write a partial save.")
	host.save_writes_blocked = true
	_expect(lifecycle._persist_for_lifecycle() == -1, "Blocked storage must report save failure instead of a clean deferred shutdown.")
	_expect(not lifecycle.last_lifecycle_save_was_deferred and host.save_calls == 0, "Blocked storage must not be mislabeled as deferred or attempt a write.")
	host.save_writes_blocked = false

	host.save_restore_complete = true
	_expect(lifecycle._runtime_save_is_safe(), "Full restore completion should enable lifecycle saving.")
	_expect(lifecycle._persist_for_lifecycle() == 1, "A successful lifecycle save should report success.")
	_expect(host.save_calls == 1, "The first safe lifecycle event should save once.")
	_expect(lifecycle._persist_for_lifecycle() == 1, "A paired focus/pause event should reuse the first successful result.")
	_expect(host.save_calls == 1, "Paired focus/pause events must not rotate backups twice.")

	lifecycle.last_lifecycle_save_monotonic_msec = Time.get_ticks_msec() - AppLifecycleRuntime.LIFECYCLE_SAVE_DEBOUNCE_MSEC - 1
	host.save_result = false
	_expect(lifecycle._persist_for_lifecycle() == -1, "A failed safe save should report failure.")
	_expect(host.save_calls == 2, "A later lifecycle event should make one new save attempt.")
	host.save_result = true
	_expect(lifecycle._persist_for_lifecycle() == 1, "A paired lifecycle notification should retry after a failed save.")
	_expect(host.save_calls == 3, "Failed lifecycle saves must not be debounced.")
	_expect(lifecycle._persist_for_lifecycle() == 1, "A successful retry should then debounce the paired notification.")
	_expect(host.save_calls == 3, "A successful retry should rotate backups only once.")

	if failures.is_empty():
		print("save-lifecycle-guard-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $baselineHeadlessProcessIds = @{}
    foreach ($process in @(Get-HeadlessGodotProcesses)) {
        $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
    }
    & $runner --headless --path $projectRoot --script $testScript
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

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
        throw "A headless Godot process is still running after the save lifecycle guard test."
    }
} finally {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousTestUserData
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $testUserData) {
        Remove-Item -LiteralPath $testUserData -Recurse -Force
    }
}
