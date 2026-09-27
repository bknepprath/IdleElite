$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fishing-net-offer-click"
$testScript = Join-Path $testDir "fishing_net_offer_click.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    $testScript = Join-Path $projectRoot "scripts\tests\fishing_native_controls.gd"

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "FISHING_NATIVE_CONTROLS failures=\[\]") "Fishing net offer click test did not report success."
}
finally {
    $headless = @()
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $headless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
        if ($headless.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after fishing net offer validation."
    }
}
