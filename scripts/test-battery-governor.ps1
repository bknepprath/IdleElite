$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\battery-governor"
$testScript = Join-Path $testDir "battery_governor_test.gd"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
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
        if ($text -notmatch '(ERROR|SCRIPT ERROR|powershell\.exe : ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
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
	OS.set_environment("IDLE_ELITE_FORCE_MOBILE_BATTERY_GOVERNOR", "1")

	var previous_fps := Engine.max_fps
	var previous_low_processor := OS.low_processor_usage_mode
	var previous_sleep_usec := OS.low_processor_usage_mode_sleep_usec
	var game := MainScript.new()

	game.call("_configure_performance_mode")
	_expect(Engine.max_fps == 60, "Expected active mobile frame cap to be 60, got %s." % str(Engine.max_fps))
	_expect(not OS.low_processor_usage_mode, "Expected active governor state to disable low processor mode.")

	game.set("battery_governor_last_activity_msec", Time.get_ticks_msec() - 100000)
	game.call("_process_battery_governor")
	_expect(Engine.max_fps == 30, "Expected idle mobile frame cap to be 30, got %s." % str(Engine.max_fps))
	_expect(OS.low_processor_usage_mode, "Expected idle governor state to enable low processor mode.")
	_expect(OS.low_processor_usage_mode_sleep_usec == 8000, "Expected idle governor sleep usec to be 8000.")

	game.call("_record_battery_governor_activity")
	_expect(Engine.max_fps == 60, "Expected governor activity to restore 60 FPS, got %s." % str(Engine.max_fps))
	_expect(not OS.low_processor_usage_mode, "Expected governor activity to disable low processor mode.")

	game.set("current_screen", "skill")
	game.set("skill_swipe_tracking", true)
	game.set("battery_governor_last_activity_msec", Time.get_ticks_msec() - 100000)
	game.call("_process_battery_governor")
	_expect(Engine.max_fps == 60, "Expected swipe work to keep active 60 FPS, got %s." % str(Engine.max_fps))
	_expect(not OS.low_processor_usage_mode, "Expected swipe work to keep low processor mode disabled.")

	game.set("skill_swipe_tracking", false)
	game.set("battery_governor_last_activity_msec", Time.get_ticks_msec() - 100000)
	game.call("_process_battery_governor")
	_expect(Engine.max_fps == 30, "Expected governor to return to idle after swipe work ended.")

	OS.set_environment("IDLE_ELITE_FORCE_MOBILE_BATTERY_GOVERNOR", "0")
	Engine.max_fps = previous_fps
	OS.low_processor_usage_mode = previous_low_processor
	OS.low_processor_usage_mode_sleep_usec = previous_sleep_usec
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("battery-governor-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $beforeHeadless = @(Get-HeadlessGodotProcesses)
    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "battery-governor-ok") "Battery governor test did not report success."
    Assert-NoUnexpectedGodotErrors $output "battery governor test"

    $afterHeadless = @(Get-HeadlessGodotProcesses)
    $beforeIds = @($beforeHeadless | ForEach-Object { $_.ProcessId })
    $newHeadless = @($afterHeadless | Where-Object { $beforeIds -notcontains $_.ProcessId })
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the battery governor test."
    }
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
