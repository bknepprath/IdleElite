param([switch]$VisibleGame, [switch]$TierOnly)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$names = @('GODOT_BIN','GODOT_RUN_TIMEOUT_SECONDS','IDLE_ELITE_TEST_USER_DATA_DIR','IDLE_ELITE_NOTES_WISDOM_ONLY','IDLE_ELITE_NOTES_TIER_ONLY')
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    if (-not $env:GODOT_BIN) { $env:GODOT_BIN = (Get-Command godot -ErrorAction Stop).Source }
    $env:GODOT_RUN_TIMEOUT_SECONDS = '200'
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot '.codex-tmp/brian-notes-test-user'
    $env:IDLE_ELITE_NOTES_WISDOM_ONLY = ''
    $env:IDLE_ELITE_NOTES_TIER_ONLY = if ($TierOnly) { '1' } else { '0' }
    $arguments = @('--path', $projectRoot, '--script', 'res://scripts/tests/brian_notes_oct22.gd', '--audio-driver', 'Dummy')
    if ($VisibleGame) { $arguments = @('--visible-game') + $arguments }
    $logPath = Join-Path $projectRoot '.codex-tmp/brian-notes-oct22.log'
    $arguments += @('--log-file', $logPath)
    & (Join-Path $projectRoot 'run-godot-safe.ps1') @arguments
    $testExit = $LASTEXITCODE
    $output = Get-Content -LiteralPath $logPath
    $output | Select-Object -Last 12 | Out-Host
    Assert-NoHeadlessGodotProcesses 'Brian notes October 22'
    Assert-NoUnexpectedGodotErrors $output 'Brian notes October 22'
    if ($testExit -ne 0 -or ($output | Out-String) -notmatch 'brian-notes-oct22 failures=\[\]') { throw 'Brian notes regression failed.' }
    Write-Output 'brian-notes-oct22-ok'
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
