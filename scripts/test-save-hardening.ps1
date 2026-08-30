$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testUserData = Join-Path ([System.IO.Path]::GetTempPath()) ("idle-elite-save-hardening-" + $PID)
$previousTestUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserData
    $output = & $runner --path $projectRoot --script "res://scripts/tests/save_hardening_test.gd" 2>&1
    $output | ForEach-Object { Write-Host $_ }
    $renderedOutput = $output | Out-String -Width 4096
    if ($LASTEXITCODE -ne 0) {
        throw "Save hardening test exited with code $LASTEXITCODE."
    }
    if ($renderedOutput -match "SCRIPT ERROR:") {
        throw "Save hardening test reported a Godot script error."
    }
    if ($renderedOutput -notmatch "save-hardening-test: PASS") {
        throw "Save hardening test did not report success."
    }

    $previousHeadlessSmoke = $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE
    $previousHeadlessSmokeSeconds = $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS
    try {
        $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE = "1"
        $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS = "600"
        $integrationOutput = & $runner --path $projectRoot --script "res://scripts/tests/v1_save_update_integration.gd" 2>&1
        $integrationOutput | ForEach-Object { Write-Host $_ }
        $renderedIntegrationOutput = $integrationOutput | Out-String -Width 4096
        if ($LASTEXITCODE -ne 0) {
            throw "V1 save update integration test exited with code $LASTEXITCODE."
        }
        if ($renderedIntegrationOutput -match "SCRIPT ERROR:") {
            throw "V1 save update integration test reported a Godot script error."
        }
        if ($renderedIntegrationOutput -notmatch "v1-save-update-integration: PASS") {
            throw "V1 save update integration test did not report success."
        }
    }
    finally {
        $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE = $previousHeadlessSmoke
        $env:IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS = $previousHeadlessSmokeSeconds
    }
}
finally {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousTestUserData
    if (Test-Path -LiteralPath $testUserData) {
        Remove-Item -LiteralPath $testUserData -Recurse -Force
    }
}
