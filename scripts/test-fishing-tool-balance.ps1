param([switch]$VisibleGame, [switch]$HelpOnly, [switch]$ModuleOnly, [switch]$AnimationOnly)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$names = @('GODOT_BIN','GODOT_RUN_TIMEOUT_SECONDS','IDLE_ELITE_TEST_USER_DATA_DIR','IDLE_ELITE_NOTES_WISDOM_ONLY','IDLE_ELITE_NOTES_TIER_ONLY','IDLE_ELITE_FISHING_HELP_ONLY','IDLE_ELITE_FISHING_MODULE_ONLY','IDLE_ELITE_FISHING_ANIMATION_ONLY')
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    if (-not $env:GODOT_BIN) { $env:GODOT_BIN = (Get-Command godot -ErrorAction Stop).Source }
    $env:GODOT_RUN_TIMEOUT_SECONDS = '320'
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot '.codex-tmp/fishing-tool-balance-user'
    $env:IDLE_ELITE_NOTES_WISDOM_ONLY = ''
    $env:IDLE_ELITE_NOTES_TIER_ONLY = '0'
    $env:IDLE_ELITE_FISHING_HELP_ONLY = if ($HelpOnly) { '1' } else { '0' }
    $env:IDLE_ELITE_FISHING_ANIMATION_ONLY = if ($AnimationOnly) { '1' } else { '0' }
    $env:IDLE_ELITE_FISHING_MODULE_ONLY = if ($ModuleOnly) { '1' } else { '0' }
    $arguments = @('--path', $projectRoot, '--script', 'res://scripts/tests/fishing_tool_balance.gd', '--audio-driver', 'Dummy')
    if ($VisibleGame) { $arguments = @('--visible-game') + $arguments }
    $logPath = Join-Path $projectRoot $(if ($AnimationOnly) { '.codex-tmp/fishing-active-animation.log' } elseif ($ModuleOnly) { '.codex-tmp/fishing-module-tools.log' } elseif ($HelpOnly) { '.codex-tmp/fishing-tool-help.log' } else { '.codex-tmp/fishing-tool-balance.log' })
    $arguments += @('--log-file', $logPath)
    & (Join-Path $projectRoot 'run-godot-safe.ps1') @arguments
    $testExit = $LASTEXITCODE
    $output = Get-Content -LiteralPath $logPath
    $output | Select-Object -Last 12 | Out-Host
    Assert-NoHeadlessGodotProcesses 'Fishing tool balance'
    Assert-NoUnexpectedGodotErrors $output 'Fishing tool balance'
    if ($testExit -ne 0 -or ($output | Out-String) -notmatch 'fishing-tool-balance failures=\[\]') { throw 'Fishing tool balance regression failed.' }
    Write-Output 'fishing-tool-balance-ok'
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
