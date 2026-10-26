$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot 'run-godot-safe.ps1'
. (Join-Path $PSScriptRoot 'lib\godot-processes.ps1')
$previousAction = $env:IDLE_ELITE_FISHING_TEST_ACTION
$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = '100'
    foreach ($action in @('practice-pool', 'fight-a-shark')) {
        $env:IDLE_ELITE_FISHING_TEST_ACTION = $action
        $output = & $runner --headless --path $projectRoot --script res://scripts/tests/fishing_opportunity_input.gd 2>&1
        $exitCode = $LASTEXITCODE
        $text = $output -join "`n"
        $remaining = @(Get-HeadlessGodotProcesses | Where-Object { $_.CommandLine -like '*res://scripts/tests/fishing_opportunity_input.gd*' })
        if ($remaining.Count -gt 0) {
            throw 'Fishing input validation left a matching headless process running.'
        }
        if ($exitCode -ne 0 -or $text -notmatch 'FISHING_OPPORTUNITY_INPUT failures=\[\]') {
            $output | Select-Object -Last 35 | Out-Host
            throw "Fishing opportunity input failed: $action"
        }
        # The engine's leak report at exit is known shutdown noise, as in the other tests.
        try {
            Assert-NoUnexpectedGodotErrors $output "fishing opportunity input ($action)"
        } catch {
            $output | Select-Object -Last 35 | Out-Host
            throw
        }
        Write-Output "Fishing opportunity input passed: $action"
    }
}
finally {
    $env:IDLE_ELITE_FISHING_TEST_ACTION = $previousAction
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
}
