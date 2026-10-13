$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$baseline = @(Get-HeadlessGodotProcesses | ForEach-Object ProcessId)
$oldUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$oldTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot '.codex-tmp/leaderboard-sync-user-data'
    $env:GODOT_RUN_TIMEOUT_SECONDS = '60'
    $output = & (Join-Path $projectRoot 'run-godot-safe.ps1') --headless --path $projectRoot --script res://scripts/tests/leaderboard_sync_test.gd --audio-driver Dummy --quit-after 120 2>&1
    $output | ForEach-Object { Write-Output $_ }
    Assert-NoUnexpectedGodotErrors -Output $output -Context 'leaderboard sync'
    Assert-True (($output | Out-String) -match 'leaderboard-sync-ok') 'Leaderboard sync regressions did not pass.'
} finally {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $oldUserData
    $env:GODOT_RUN_TIMEOUT_SECONDS = $oldTimeout
    $remaining = @(Get-HeadlessGodotProcesses | Where-Object { $baseline -notcontains $_.ProcessId })
    Assert-True ($remaining.Count -eq 0) 'Leaderboard sync test left an agent-owned headless process running.'
}
