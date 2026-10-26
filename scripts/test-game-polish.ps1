param([switch]$VisibleGame)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib/godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$names = @("IDLE_ELITE_TEST_USER_DATA_DIR", "IDLE_ELITE_DISABLE_SAVE_WRITES", "IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "GODOT_RUN_TIMEOUT_SECONDS")
$previous = @{}
foreach ($name in $names) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, "Process") }

try {
    $env:IDLE_ELITE_DISABLE_SAVE_WRITES = "1"
    $env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = "1"
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    foreach ($test in @(
        @{ Script = "ham_feedback"; Marker = "ham-feedback failures=[]" },
        @{ Script = "first_session_input"; Marker = "INPUT_TEST failures=[]" },
        @{ Script = "polish_capture"; Marker = "polish-ui failures=[]" }
    )) {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot (".codex-tmp/polish-test-" + [guid]::NewGuid().ToString("N"))
        $runArgs = @("--path", $projectRoot, "--script", "res://scripts/tests/$($test.Script).gd", "--audio-driver", "Dummy")
        $visibleCapture = $VisibleGame -and $test.Script -eq "polish_capture"
        $captureLog = Join-Path $projectRoot (".codex-tmp/polish-capture-" + [guid]::NewGuid().ToString("N") + ".log")
        if ($visibleCapture) { $runArgs += @("--visible-game", "--log-file", $captureLog) }
        $output = & $runner @runArgs 2>&1
        $testExit = $LASTEXITCODE
        if ($visibleCapture -and (Test-Path -LiteralPath $captureLog)) { $output = @(Get-Content -LiteralPath $captureLog) }
        $output | Out-Host
        Assert-NoHeadlessGodotProcesses $test.Script
        Assert-NoUnexpectedGodotErrors $output $test.Script
        if ($testExit -ne 0 -or -not ($output | Out-String).Contains($test.Marker)) {
            throw "$($test.Script) did not finish successfully (exit $testExit)."
        }
    }
    Write-Output "game-polish-ok"
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $previous[$name], "Process") }
}
