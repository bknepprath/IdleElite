param([switch]$VisibleGame)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$names = @('GODOT_BIN', 'GODOT_RUN_TIMEOUT_SECONDS', 'IDLE_ELITE_TEST_USER_DATA_DIR', 'IDLE_ELITE_ART_AUDIT_OUTPUT')
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    if (-not $env:GODOT_BIN) { $env:GODOT_BIN = (Get-Command godot -ErrorAction Stop).Source }
    $env:GODOT_RUN_TIMEOUT_SECONDS = '210'
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot '.codex-tmp/soft-guidance-user'
    $env:IDLE_ELITE_ART_AUDIT_OUTPUT = 'res://outputs/verification/soft-guidance-oct24'
    $log = Join-Path $projectRoot '.codex-tmp/soft-guidance.log'
    $arguments = @('--path', $projectRoot, '--script', 'res://scripts/tests/soft_interaction_guidance.gd', '--audio-driver', 'Dummy', '--log-file', $log)
    if ($VisibleGame) { $arguments = @('--visible-game') + $arguments }
    & (Join-Path $projectRoot 'run-godot-safe.ps1') @arguments | Out-Null
    $output = Get-Content -LiteralPath $log
    $errors = $output | Where-Object { $_ -match '(SCRIPT ERROR:|ERROR:)' -and $_ -notmatch 'Failed to read the root certificate store' }
    if ($LASTEXITCODE -ne 0 -or $errors -or ($output -join "`n") -notmatch 'SOFT_INTERACTION_GUIDANCE failures=\[\]') { throw 'Soft interaction guidance validation failed' }
    'soft-interaction-guidance-ok'
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
