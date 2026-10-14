$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$previousUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$previousOnline = $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS
$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot ('.codex-tmp/stability-soak-user-' + [guid]::NewGuid().ToString('N'))
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = '1'
    $env:GODOT_RUN_TIMEOUT_SECONDS = '1950'
    $output = & (Join-Path $projectRoot 'run-godot-safe.ps1') --path $projectRoot --script res://scripts/tests/stability_soak.gd --audio-driver Dummy 2>&1
    $runExit = $LASTEXITCODE
    $output | Set-Content -LiteralPath (Join-Path $projectRoot '.codex-tmp/stability-soak.log')
    $output | Out-Host
    Assert-NoUnexpectedGodotErrors $output '30-minute stability profile'
    Assert-NoHeadlessGodotProcesses '30-minute stability profile'
    Assert-True ($runExit -eq 0 -and ($output | Out-String).Contains('stability-soak: PASS (1800 seconds;')) '30-minute stability profile did not complete.'
} finally {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousUserData
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = $previousOnline
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
}
