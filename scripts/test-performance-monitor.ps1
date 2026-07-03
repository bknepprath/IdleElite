$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\performance-monitor"
$testScript = Join-Path $testDir "performance_monitor_test.gd"

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

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    @'
extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var monitor_script = load("res://scripts/app/perf_monitor.gd")
	_expect(monitor_script != null, "Performance monitor script should load.")
	if monitor_script == null:
		_finish()
		return

	var monitor = monitor_script.new()
	root.add_child(monitor)
	monitor.set_process(false)
	monitor.set_overlay_visible(true)
	await process_frame

	for i in range(60):
		monitor.record_frame(1.0 / 60.0)
	for i in range(5):
		monitor.record_frame(0.050)

	var report: Dictionary = monitor.current_report()
	_expect(monitor.has_overlay(), "Overlay nodes should be created when enabled.")
	_expect(monitor.is_overlay_visible(), "Overlay should report visible after being enabled.")
	_expect(int(report.get("sample_frames", 0)) == 65, "Report should include every sampled frame.")
	_expect(int(report.get("jank_frames", 0)) == 5, "Report should count frames slower than the jank threshold.")
	_expect(float(report.get("measured_fps", 0.0)) > 0.0, "Report should calculate measured FPS.")
	_expect(float(report.get("max_ms", 0.0)) >= 50.0, "Report should expose max frame time in milliseconds.")
	_expect(str(monitor.report_text()).contains("PERF REPORT"), "Overlay text should include a screenshot-friendly heading.")
	_expect(str(monitor.report_text()).contains("FPS"), "Overlay text should include FPS.")

	monitor.set_overlay_visible(false)
	_expect(not monitor.is_overlay_visible(), "Overlay should report hidden after being disabled.")
	monitor.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("performance-monitor-ok")
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
    Assert-True (($output -join "`n") -match "performance-monitor-ok") "Performance monitor test did not report success."
    Assert-NoUnexpectedGodotErrors $output "performance monitor test"

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
        throw "A new headless Godot process is still running after the performance monitor test."
    }
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
