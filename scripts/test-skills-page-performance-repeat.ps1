$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$skillsPagePerformanceTest = Join-Path $projectRoot "scripts\test-skills-page-performance.ps1"


Assert-True (Test-Path -LiteralPath $skillsPagePerformanceTest) "Missing scripts\test-skills-page-performance.ps1."

$repeatCount = 3
if (-not [string]::IsNullOrWhiteSpace($env:IDLE_ELITE_SKILLS_PERF_REPEAT_COUNT)) {
    $repeatCount = [int]$env:IDLE_ELITE_SKILLS_PERF_REPEAT_COUNT
}
$repeatCount = [Math]::Max(1, $repeatCount)

for ($run = 1; $run -le $repeatCount; $run++) {
    Write-Host "skills-page-performance-repeat run=$run/$repeatCount"
    $output = & $skillsPagePerformanceTest 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    # The focused test already asserts its success marker internally; it writes
    # Godot output to the host, so the wrapper may not capture that line here.
    Assert-NoUnexpectedGodotErrors -Output $output -Context "skills page performance repeat run $run"
    Assert-NoHeadlessGodotProcesses "skills page performance repeat run $run"
}

Write-Host "skills-page-performance-repeat-ok runs=$repeatCount"
