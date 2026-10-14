$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$names = @('IDLE_ELITE_TEST_USER_DATA_DIR', 'IDLE_ELITE_DISABLE_SAVE_WRITES', 'IDLE_ELITE_DISABLE_ONLINE_REQUESTS', 'GODOT_RUN_TIMEOUT_SECONDS')
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot ('.codex-tmp/screen-performance-' + [guid]::NewGuid().ToString('N'))
    $env:IDLE_ELITE_DISABLE_SAVE_WRITES = '1'
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = '1'
    $env:GODOT_RUN_TIMEOUT_SECONDS = '180'
    $output = & (Join-Path $projectRoot 'run-godot-safe.ps1') --path $projectRoot --script res://scripts/tests/screen_performance.gd --audio-driver Dummy 2>&1
    $runExit = $LASTEXITCODE
    $output | Out-Host
    Assert-NoHeadlessGodotProcesses 'screen performance'
    Assert-NoUnexpectedGodotErrors $output 'screen performance'
    if ($runExit -ne 0 -or -not ($output | Out-String).Contains('screen-performance-audit-ok')) { throw 'Screen performance audit failed.' }
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
