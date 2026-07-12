$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\activity-progress-turnover"
$testScript = Join-Path $testDir "activity_progress_turnover.gd"

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

@'
extends SceneTree

func _init() -> void:
	var script = load("res://scripts/ui/skill_swipe_activity_surface.gd")
	var surface = script.new(null)
	var failed := false
	failed = failed or not is_equal_approx(surface._action_progress_turnover_value(0.0, 25.0, 82.0, 60.0, 3.0), 82.0)
	failed = failed or not is_equal_approx(surface._action_progress_turnover_value(0.21, 25.0, 82.0, 60.0, 3.0), 0.0)
	failed = failed or not is_equal_approx(surface._action_progress_turnover_value(0.40, 25.0, 82.0, 60.0, 3.0), 22.0)
	var near_handoff: float = float(surface._action_progress_turnover_value(0.3999, 25.0, 82.0, 60.0, 3.0))
	failed = failed or absf((22.0 - near_handoff) / 0.0001 - 60.0) >= 1.0
	if failed:
		push_error("activity progress turnover continuity failed")
		quit(1)
		return
	print("activity-progress-turnover-ok")
	quit()
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "15"
try {
    $output = & $runner --path $projectRoot --headless --script $testScript 2>&1
    if ($LASTEXITCODE -ne 0 -or ($output -join "`n") -notmatch "activity-progress-turnover-ok") {
        throw "Activity progress turnover test failed.`n$($output -join "`n")"
    }
    $output
}
finally {
	$env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    foreach ($process in @(Get-HeadlessGodotProcesses)) {
        if (-not $baselineHeadlessProcessIds.ContainsKey([int]$process.ProcessId)) {
            Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
        }
    }
}
