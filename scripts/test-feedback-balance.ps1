param([switch]$VisibleGame)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib/godot-processes.ps1")
$names = @("IDLE_ELITE_TEST_USER_DATA_DIR", "IDLE_ELITE_DISABLE_SAVE_WRITES", "IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "GODOT_RUN_TIMEOUT_SECONDS")
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process") }
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot (".codex-tmp/feedback-test-" + [guid]::NewGuid().ToString("N"))
    $env:IDLE_ELITE_DISABLE_SAVE_WRITES = "1"
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = "1"
    $env:GODOT_RUN_TIMEOUT_SECONDS = "120"
    $runner = Join-Path $projectRoot "run-godot-safe.ps1"
    & $runner --path $projectRoot --script res://scripts/tests/feedback_balance.gd --audio-driver Dummy
    $testExit = $LASTEXITCODE
    Assert-NoHeadlessGodotProcesses "feedback balance"
    if ($testExit -ne 0) { throw "Feedback balance test failed ($testExit)." }
    if ($VisibleGame) {
        $startedAt = Get-Date
        & $runner --path $projectRoot --visible-game --script res://scripts/tests/feedback_capture.gd --audio-driver Dummy
        $testExit = $LASTEXITCODE
        Assert-NoHeadlessGodotProcesses "feedback capture"
        if ($testExit -ne 0) { throw "Feedback capture failed ($testExit)." }
        $resultPath = Join-Path $projectRoot ".codex-tmp/feedback-captures/result.json"
        if (-not (Test-Path -LiteralPath $resultPath) -or (Get-Item -LiteralPath $resultPath).LastWriteTime -lt $startedAt) { throw "Feedback capture did not write a fresh result." }
        $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        if (@($result.failures).Count -gt 0) { throw "Feedback capture failed: $($result.failures -join '; ')" }
        Write-Output "feedback-capture-ok"
    }
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], "Process") }
}
