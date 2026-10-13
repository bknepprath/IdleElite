$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
& node (Join-Path $PSScriptRoot 'tests/leaderboard_rule_leaves.test.cjs')
Assert-True ($LASTEXITCODE -eq 0) 'Leaderboard numeric rule regressions did not pass.'
$baseline = @(Get-HeadlessGodotProcesses | ForEach-Object ProcessId)
$oldUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$oldTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot '.codex-tmp/online-reliability-user-data'
    $env:GODOT_RUN_TIMEOUT_SECONDS = '60'
    $output = & (Join-Path $projectRoot 'run-godot-safe.ps1') --headless --path $projectRoot --script res://scripts/tests/online_reliability_test.gd --audio-driver Dummy --quit-after 120 2>&1
    $output | ForEach-Object { Write-Output $_ }
    Assert-NoUnexpectedGodotErrors -Output $output -Context 'online reliability'
    Assert-True (($output | Out-String) -match 'online-reliability-ok') 'Online reliability regressions did not pass.'
} finally {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $oldUserData
    $env:GODOT_RUN_TIMEOUT_SECONDS = $oldTimeout
    $remaining = @(Get-HeadlessGodotProcesses | Where-Object { $baseline -notcontains $_.ProcessId })
    Assert-True ($remaining.Count -eq 0) 'Online reliability test left an agent-owned headless process running.'
}

