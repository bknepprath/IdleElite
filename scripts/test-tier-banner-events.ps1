param([switch]$Capture)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib\godot-processes.ps1')
$testDirectory = Join-Path $projectRoot '.codex-tmp\tier-banner-events'
New-Item -ItemType Directory -Path $testDirectory -Force | Out-Null
$previousEnvironment = @{}
$testEnvironment = @{
    GODOT_MAX_PROCESSES = '4'
    GODOT_RUN_TIMEOUT_SECONDS = '180'
    IDLE_ELITE_TEST_USER_DATA_DIR = (Join-Path $testDirectory 'user-data')
    IDLE_ELITE_DISABLE_SAVE_WRITES = '1'
    IDLE_ELITE_DISABLE_ONLINE_REQUESTS = '1'
}
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)
foreach ($key in $testEnvironment.Keys) {
    $previousEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
    [Environment]::SetEnvironmentVariable($key, $testEnvironment[$key], 'Process')
}
try {
    $runner = Join-Path $projectRoot 'run-godot-safe.ps1'
    $mode = if ($Capture) { '--visible-game' } else { '--headless' }
    $logPath = Join-Path $testDirectory ('runtime-' + [guid]::NewGuid().ToString('N') + '.log')
    $output = & $runner $mode --path $projectRoot --audio-driver Dummy --log-file $logPath --script res://scripts/tests/tier_banner_events.gd 2>&1
    $exitCode = $LASTEXITCODE
    if ($Capture -and (Test-Path -LiteralPath $logPath)) {
        $output = @($output) + @(Get-Content -LiteralPath $logPath)
    }
    $output | Out-Host
    Assert-True ($exitCode -eq 0) "Tier-banner event validation failed with exit code $exitCode"
    Assert-NoUnexpectedGodotErrors $output 'tier-banner event validation'
    Assert-True (($output -join "`n") -match 'tier-banner-events-ok failures=\[\]') 'Tier-banner event validation did not pass'
}
finally {
    foreach ($key in $testEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($key, $previousEnvironment[$key], 'Process')
    }
    $remaining = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    Assert-True ($remaining.Count -eq 0) 'New headless Godot processes remain after tier-banner event validation'
}
