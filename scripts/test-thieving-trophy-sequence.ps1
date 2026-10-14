param([switch]$VisibleGame, [switch]$AllActivities)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib/godot-processes.ps1")
$names = @("IDLE_ELITE_TEST_USER_DATA_DIR", "IDLE_ELITE_DISABLE_SAVE_WRITES", "IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "GODOT_RUN_TIMEOUT_SECONDS", "IDLE_ELITE_TEST_ALL_THIEVING_ACTIVITIES")
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process") }
try {
    $env:IDLE_ELITE_TEST_ALL_THIEVING_ACTIVITIES = if ($AllActivities) { "1" } else { "0" }
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot (".codex-tmp/detail-refresh-test-" + [guid]::NewGuid().ToString("N"))
    $env:IDLE_ELITE_DISABLE_SAVE_WRITES = "1"
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = "1"
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    $captureLog = Join-Path $projectRoot ".codex-tmp/thieving-trophy-sequence.log"
    $runArgs = @("--path", $projectRoot, "--script", "res://scripts/tests/thieving_trophy_sequence.gd", "--audio-driver", "Dummy", "--log-file", $captureLog)
    if ($VisibleGame) { $runArgs += "--visible-game" }
    & (Join-Path $projectRoot "run-godot-safe.ps1") @runArgs
    $testExit = $LASTEXITCODE
    $output = @(Get-Content -LiteralPath $captureLog)
    $output | Out-Host
    Assert-NoHeadlessGodotProcesses "detail refresh stability"
    Assert-NoUnexpectedGodotErrors $output "detail refresh stability"
    if ($testExit -ne 0 -or -not ($output | Out-String).Contains("thieving-trophy-sequence failures=[]")) { throw "Detail refresh stability failed ($testExit)." }
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], "Process") }
}

