$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib/godot-processes.ps1")
$names = @("IDLE_ELITE_TEST_USER_DATA_DIR", "IDLE_ELITE_DISABLE_SAVE_WRITES", "IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "GODOT_RUN_TIMEOUT_SECONDS")
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process") }
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot (".codex-tmp/title-spacing-test-" + [guid]::NewGuid().ToString("N"))
    $env:IDLE_ELITE_DISABLE_SAVE_WRITES = "1"
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = "1"
    $env:GODOT_RUN_TIMEOUT_SECONDS = "300"
    $log = Join-Path $projectRoot ".codex-tmp/activity-title-spacing-game.log"
    & (Join-Path $projectRoot "run-godot-safe.ps1") --path $projectRoot --script res://scripts/tests/activity_title_spacing.gd --audio-driver Dummy --visible-game --log-file $log
    $testExit = $LASTEXITCODE
    $output = Get-Content -LiteralPath $log
    $output | Out-Host
    Assert-NoHeadlessGodotProcesses "title-spacing"
    Assert-NoUnexpectedGodotErrors $output "title-spacing"
    if ($testExit -ne 0 -or -not ($output | Out-String).Contains("failures=[]")) { throw "Title spacing audit failed (exit $testExit)." }
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], "Process") }
}
