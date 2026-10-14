$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$previousUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$previousOnline = $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS
$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot ('.codex-tmp/stability-test-' + [guid]::NewGuid().ToString('N'))
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = '1'
    $env:GODOT_RUN_TIMEOUT_SECONDS = '140'
    $output = & (Join-Path $projectRoot 'run-godot-safe.ps1') --path $projectRoot --script res://scripts/tests/stability_regressions.gd --audio-driver Dummy 2>&1
    $runExit = $LASTEXITCODE
    $output | Out-Host
    Assert-NoUnexpectedGodotErrors $output 'stability regressions'
    Assert-NoHeadlessGodotProcesses 'stability regressions'
    Assert-True ($runExit -eq 0 -and ($output | Out-String).Contains('stability-regressions: PASS')) 'Stability regressions failed.'
} finally {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousUserData
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = $previousOnline
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
}
