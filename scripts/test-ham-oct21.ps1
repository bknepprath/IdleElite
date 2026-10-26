param([switch]$VisibleGame)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$names = @('IDLE_ELITE_TEST_USER_DATA_DIR','IDLE_ELITE_DISABLE_SAVE_WRITES','IDLE_ELITE_DISABLE_ONLINE_REQUESTS','GODOT_RUN_TIMEOUT_SECONDS')
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name,'Process') }
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot ('.codex-tmp/ham-oct21-user-' + [guid]::NewGuid().ToString('N'))
    $env:IDLE_ELITE_DISABLE_SAVE_WRITES = '1'
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = '1'
    $env:GODOT_RUN_TIMEOUT_SECONDS = '320'
    $runner = Join-Path $projectRoot 'run-godot-safe.ps1'
    $output = & $runner --path $projectRoot --script res://scripts/tests/ham_oct21_regressions.gd --audio-driver Dummy 2>&1
    $testExit = $LASTEXITCODE
    $output | Out-Host
    Assert-NoHeadlessGodotProcesses 'Ham October 21 regressions'
    Assert-NoUnexpectedGodotErrors $output 'Ham October 21 regressions'
    if ($testExit -ne 0 -or ($output | Out-String) -notmatch 'ham-oct21-regressions recovery_cases=40 failures=\[\]') { throw 'Ham October 21 regression check failed.' }
    if ($VisibleGame) {
        $captureLog = Join-Path $projectRoot '.codex-tmp/ham-oct21-visible.log'
        & $runner --visible-game --path $projectRoot --script res://scripts/tests/ham_oct21_capture.gd --audio-driver Dummy --log-file $captureLog
        $testExit = $LASTEXITCODE
        $output = Get-Content -LiteralPath $captureLog
        $output | Out-Host
        Assert-NoHeadlessGodotProcesses 'Ham October 21 visible capture'
        Assert-NoUnexpectedGodotErrors $output 'Ham October 21 visible capture'
        if ($testExit -ne 0 -or ($output | Out-String) -notmatch 'ham-oct21-capture failures=\[\]') { throw 'Ham October 21 game capture failed.' }
    }
    Write-Output 'ham-oct21-ok'
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name,$previous[$name],'Process') }
}
