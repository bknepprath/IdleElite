param([switch]$VisibleGame)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib/godot-processes.ps1")
$names = @("IDLE_ELITE_TEST_USER_DATA_DIR", "IDLE_ELITE_DISABLE_SAVE_WRITES", "IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "GODOT_RUN_TIMEOUT_SECONDS")
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process") }
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot (".codex-tmp/chat-send-input-test-" + [guid]::NewGuid().ToString("N"))
    $env:IDLE_ELITE_DISABLE_SAVE_WRITES = "1"
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = "1"
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    $captureLog = Join-Path $projectRoot ".codex-tmp/chat-send-input.log"
    $runArgs = @("--path", $projectRoot, "--script", "res://scripts/tests/chat_send_input.gd", "--audio-driver", "Dummy", "--log-file", $captureLog)
    if ($VisibleGame) { $runArgs += "--visible-game" }
    & (Join-Path $projectRoot "run-godot-safe.ps1") @runArgs
    $testExit = $LASTEXITCODE
    $output = @(Get-Content -LiteralPath $captureLog)
    $output | Out-Host
    Assert-NoHeadlessGodotProcesses "chat send input"
    Assert-NoUnexpectedGodotErrors $output "chat send input"
    if ($testExit -ne 0 -or -not ($output | Out-String).Contains("chat-send-input failures=[]")) { throw "Chat send input failed ($testExit)." }
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], "Process") }
}
