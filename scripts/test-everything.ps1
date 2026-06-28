param(
    [ValidateSet("smoke", "full", "release")]
    [string]$Mode = "full",

    [string[]]$Aspect = @(),

    [switch]$IncludeExternal,

    [switch]$IncludeRelease,

    [switch]$List,

    [int]$TimeoutSeconds = 900
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$resultsRoot = Join-Path $projectRoot "test-results"
$runId = Get-Date -Format "yyyyMMdd-HHmmss"
$runRoot = Join-Path $resultsRoot "test-everything-$runId"

function New-TestCase {
    param(
        [Parameter(Mandatory = $true)][string]$Aspect,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Script,
        [string[]]$Modes = @("full"),
        [int]$Timeout = $TimeoutSeconds,
        [switch]$External,
        [switch]$Release,
        [switch]$DelegatesFailureOutput,
        [string[]]$Arguments = @()
    )

    [pscustomobject]@{
        Aspect = $Aspect
        Name = $Name
        Script = $Script
        Modes = $Modes
        Timeout = $Timeout
        External = [bool]$External
        Release = [bool]$Release
        DelegatesFailureOutput = [bool]$DelegatesFailureOutput
        Arguments = @($Arguments)
    }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

function Assert-NoHeadlessGodotProcesses {
    param([Parameter(Mandatory = $true)][string]$Context)

    $headless = @()
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $headless = @(Get-HeadlessGodotProcesses)
        if ($headless.Count -eq 0) {
            return
        }
        Start-Sleep -Milliseconds 500
    }

    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after $Context."
    }
}

function Convert-ToSlug {
    param([Parameter(Mandatory = $true)][string]$Text)

    $slug = $Text.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $slug.Trim("-")
}

function Assert-NoFailureOutput {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context,
        [Parameter(Mandatory = $true)][string]$StdoutPath,
        [Parameter(Mandatory = $true)][string]$StderrPath
    )

    if ($null -eq $Output) {
        return
    }

    foreach ($line in @($Output)) {
        $text = [string]$line
        if ($text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.') {
            continue
        }
        if ($text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.') {
            continue
        }
        if (
            $text -match '^(SCRIPT ERROR|ERROR|powershell\.exe : ERROR):' -or
            $text -match 'did not report success' -or
            $text -match '^\s*At .+\.ps1:\d+ char:\d+' -or
            $text -match 'OperationStopped'
        ) {
            throw "$Context reported failure output: $text Logs: $StdoutPath $StderrPath"
        }
    }
}

function Invoke-TestCase {
    param(
        [Parameter(Mandatory = $true)]$TestCase,
        [Parameter(Mandatory = $true)][int]$Index,
        [Parameter(Mandatory = $true)][int]$Total
    )

    $scriptPath = Join-Path $projectRoot $TestCase.Script
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        throw "Missing $($TestCase.Name) script at $($TestCase.Script)."
    }

    $slug = Convert-ToSlug "$($Index)-$($TestCase.Aspect)-$($TestCase.Name)"
    $stdoutPath = Join-Path $runRoot "$slug.stdout.log"
    $stderrPath = Join-Path $runRoot "$slug.stderr.log"
    $elapsed = [Diagnostics.Stopwatch]::StartNew()

    Write-Host ""
    Write-Host "[$Index/$Total] $($TestCase.Aspect): $($TestCase.Name)"
    Write-Host "script=$($TestCase.Script) timeout=$($TestCase.Timeout)s"

    $scriptArguments = @($TestCase.Arguments)
    $arguments = @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        "`"$scriptPath`""
    ) + $scriptArguments
    $arguments = $arguments -join " "

    $previousTestUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $runRoot ("user-data\" + $slug)
    try {
        $process = Start-Process `
            -FilePath "powershell.exe" `
            -ArgumentList $arguments `
            -NoNewWindow `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath
    } finally {
        if ($null -eq $previousTestUserDataDir) {
            Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
        } else {
            $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousTestUserDataDir
        }
    }

    $finished = $process.WaitForExit([int]$TestCase.Timeout * 1000)
    if (-not $finished) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        Assert-NoHeadlessGodotProcesses "$($TestCase.Name) timeout"
        throw "$($TestCase.Name) timed out after $($TestCase.Timeout) seconds. Logs: $stdoutPath $stderrPath"
    }

    $elapsed.Stop()
    $process.Refresh()
    $exitCode = if ($null -eq $process.ExitCode) { 0 } else { [int]$process.ExitCode }
    $stdout = @(Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue)
    $stderr = @(Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue)
    $combined = @($stdout + $stderr)

    if ($combined.Count -gt 0) {
        $combined | Select-Object -Last 40 | ForEach-Object { Write-Host $_ }
    }

    Assert-NoHeadlessGodotProcesses $TestCase.Name

    if ($exitCode -ne 0) {
        throw "$($TestCase.Name) failed with exit code $exitCode after $([math]::Round($elapsed.Elapsed.TotalSeconds, 1))s. Logs: $stdoutPath $stderrPath"
    }
    if (-not $TestCase.DelegatesFailureOutput) {
        Assert-NoFailureOutput `
            -Output $combined `
            -Context $TestCase.Name `
            -StdoutPath $stdoutPath `
            -StderrPath $stderrPath
    }

    Write-Host "ok elapsed=$([math]::Round($elapsed.Elapsed.TotalSeconds, 1))s"
}

$tests = @(
    New-TestCase "core" "release gate" "scripts\check-project.ps1" @("smoke", "full", "release") 2400 -DelegatesFailureOutput

    New-TestCase "data" "activity database audit" "scripts\audit-activity-database.ps1" @("full", "release") 120
    New-TestCase "assets" "image asset audit" "scripts\audit-image-assets.ps1" @("full", "release") 180

    New-TestCase "firebase" "leaderboard config validation" "scripts\test-firebase-leaderboard-config-validation.ps1" @("full", "release") 120
    New-TestCase "firebase" "leaderboard runtime guard" "scripts\test-firebase-leaderboard-runtime-guard.ps1" @("full", "release") 180
    New-TestCase "firebase" "leaderboard preflight" "scripts\check-firebase-leaderboard-preflight.ps1" @("release") 180 -Arguments @("-SkipGodotSafeValidation")
    New-TestCase "firebase" "leaderboard setup state" "scripts\check-firebase-leaderboard-setup-state.ps1" @("release") 180
    New-TestCase "firebase" "leaderboard live read" "scripts\test-firebase-leaderboard-live-read.ps1" @("release") 180 -External

    New-TestCase "gameplay" "first five minutes simulation" "scripts\simulate-first-five-minutes.ps1" @("full", "release") 900
    New-TestCase "gameplay" "hard reset tutorial flow" "scripts\test-hard-reset-tutorial-flow.ps1" @("full", "release") 600
    New-TestCase "gameplay" "tutorial visible flow" "scripts\test-tutorial-visible-flow.ps1" @("full", "release") 600
    New-TestCase "gameplay" "honey stamina regen" "scripts\test-honey-stamina-regen.ps1" @("full", "release") 360
    New-TestCase "gameplay" "battery governor" "scripts\test-battery-governor.ps1" @("full", "release") 240

    New-TestCase "fishing" "fishing click flow" "scripts\test-fishing-click-flow.ps1" @("full", "release") 900
    New-TestCase "fishing" "fishing net offer click" "scripts\test-fishing-net-offer-click.ps1" @("full", "release") 600
    New-TestCase "fishing" "fishing drag spike" "scripts\test-fishing-drag-spike.ps1" @("full", "release") 240

    New-TestCase "thieving" "thieving heist click flow" "scripts\test-thieving-heist-click-flow.ps1" @("full", "release") 600

    New-TestCase "ui" "button census clicks" "scripts\test-button-census-clicks.ps1" @("full", "release") 420
    New-TestCase "ui" "page switch cover visual" "scripts\test-page-switch-cover-visual.ps1" @("full", "release") 600
    New-TestCase "ui" "stamina gauge offpage smooth" "scripts\test-stamina-gauge-offpage-smooth.ps1" @("full", "release") 360
    New-TestCase "ui" "skill first swipe build" "scripts\test-skill-first-swipe-build.ps1" @("full", "release") 600
    New-TestCase "ui" "skill first swipe visual" "scripts\test-skill-first-swipe-visual.ps1" @("full", "release") 600
    New-TestCase "ui" "unlock combo visual smoke" "scripts\test-unlock-combo-visual-smoke.ps1" @("full", "release") 600

    New-TestCase "performance" "strict skills page performance repeat" "scripts\test-skills-page-performance-repeat.ps1" @("release") 1200

    New-TestCase "release" "release app bundle" "scripts\test-release-aab.ps1" @("release") 2400 -Release
)

$selectedTests = @(
    $tests | Where-Object {
        ($_.Modes -contains $Mode) -and
        ($Aspect.Count -eq 0 -or ($Aspect -contains $_.Aspect)) -and
        (-not $_.External -or $IncludeExternal) -and
        (-not $_.Release -or $IncludeRelease -or $Mode -eq "release")
    }
)

if ($List) {
    $selectedTests |
        Select-Object Aspect, Name, Script, Timeout, External, Release |
        Format-Table -AutoSize
    exit 0
}

if ($selectedTests.Count -eq 0) {
    throw "No tests selected. Check -Mode, -Aspect, -IncludeExternal, and -IncludeRelease."
}

New-Item -ItemType Directory -Path $runRoot -Force | Out-Null

Write-Host "Idle Elite whole-game validation"
Write-Host "mode=$Mode aspects=$(if ($Aspect.Count -eq 0) { 'all' } else { $Aspect -join ',' }) external=$IncludeExternal release=$IncludeRelease"
Write-Host "logs=$runRoot"
Write-Host "selected=$($selectedTests.Count)"

$overall = [Diagnostics.Stopwatch]::StartNew()
$failures = New-Object System.Collections.Generic.List[string]

for ($index = 0; $index -lt $selectedTests.Count; $index++) {
    $testCase = $selectedTests[$index]
    try {
        Invoke-TestCase $testCase ($index + 1) $selectedTests.Count
    } catch {
        $failures.Add($_.Exception.Message)
        Write-Error $_.Exception.Message
        break
    }
}

$overall.Stop()

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "test-everything-failed elapsed=$([math]::Round($overall.Elapsed.TotalMinutes, 1))m"
    $failures | ForEach-Object { Write-Host "failure: $_" }
    exit 1
}

Write-Host ""
Write-Host "test-everything-ok elapsed=$([math]::Round($overall.Elapsed.TotalMinutes, 1))m logs=$runRoot"
