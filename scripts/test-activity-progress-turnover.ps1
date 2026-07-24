$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "scripts\run-godot-test.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\activity-progress-turnover"
$testScript = "res://scripts/tests/activity_progress_turnover.gd"

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}


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
