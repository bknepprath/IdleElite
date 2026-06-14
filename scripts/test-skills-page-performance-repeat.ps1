$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$skillsPagePerformanceTest = Join-Path $projectRoot "scripts\test-skills-page-performance.ps1"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

function Assert-NoHeadlessGodotProcesses {
    param([Parameter(Mandatory = $true)][string]$Context)

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after $Context."
    }
}

function Assert-NoUnexpectedGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Output) {
        return
    }

    foreach ($line in @($Output)) {
        $text = [string]$line
        if ($text -notmatch '^(ERROR|SCRIPT ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match '^ERROR: \d+ RID allocations of type .+ were leaked at exit\.$' -or
            $text -match '^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}

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
