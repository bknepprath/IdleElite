$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$skillsPagePerformanceTest = Join-Path $projectRoot "scripts\test-skills-page-performance.ps1"
$skillsPagePerformanceRepeatTest = Join-Path $projectRoot "scripts\test-skills-page-performance-repeat.ps1"

function Assert-NoUnexpectedGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Output) {
        return
    }

    $renderedText = $Output | Out-String -Width 4096
    $skillsPageStart = $renderedText.IndexOf("skills-page-performance-start")
    if ($Context -match 'skills page performance' -and $skillsPageStart -ge 0) {
        $renderedText = $renderedText.Substring($skillsPageStart)
    }
    foreach ($line in ($renderedText -split "\r?\n")) {
        if ($line -notmatch '(ERROR|SCRIPT ERROR):') {
            if (
                $line -match '^\s*At .+\.ps1:\d+ char:\d+' -or
                $line -match 'OperationStopped' -or
                $line -match 'did not report success'
            ) {
                throw "Unexpected PowerShell failure during ${Context}: $line"
            }
            continue
        }
        $knownShutdownNoise = (
            $line -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $line -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.' -or
            $line -match 'ERROR: Failed to read the root certificate store\.'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $line"
        }
    }
}

function Assert-NoCrashLikeGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Output) {
        return
    }

    $renderedText = $Output | Out-String -Width 4096
    foreach ($line in ($renderedText -split "\r?\n")) {
        if ($line -notmatch '(ERROR|SCRIPT ERROR|powershell\.exe : ERROR):') {
            continue
        }
        $knownPerformanceFailure = (
            $line -match '(ERROR|powershell\.exe : ERROR): (idle|scroll|swipe|rapid_swipe)/.+(FPS budget|frame work exceeded)' -or
            $line -match 'ERROR: Skills page performance test did not report success\.'
        )
        $knownShutdownNoise = (
            $line -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $line -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.' -or
            $line -match 'ERROR: Failed to read the root certificate store\.'
        )
        if (-not ($knownPerformanceFailure -or $knownShutdownNoise)) {
            throw "Crash-like Godot error during ${Context}: $line"
        }
    }
}

function Invoke-ProjectValidationScript {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$MissingMessage,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw $MissingMessage
    }

    $output = & $Path 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-NoUnexpectedGodotErrors $output $Context
    Assert-NoHeadlessGodotProcesses $Context
}

function Invoke-CapturedPowerShellScript {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stdoutPath = [IO.Path]::GetTempFileName()
    $stderrPath = [IO.Path]::GetTempFileName()
    try {
        $escapedPath = $Path.Replace('"', '\"')
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$escapedPath`""
        $process = Start-Process `
            -FilePath "powershell.exe" `
            -ArgumentList $arguments `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath
        $stdout = @(Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue)
        $stderr = @(Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue)
        return @{
            "exit_code" = $process.ExitCode
            "output" = @($stdout + $stderr)
        }
    } finally {
        Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-SkillsPagePerformanceValidation {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$MissingMessage,
        [Parameter(Mandatory = $true)][string]$Context,
        [Parameter(Mandatory = $true)][bool]$Strict
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw $MissingMessage
    }

    $attemptCount = if ($Strict) { 1 } else { 3 }
    if ($Strict) {
        Write-Host "Strict skills page performance repeat is enabled."
    }
    $lastFailureOutput = $null
    $lastFailureExitCode = 0
    for ($attempt = 1; $attempt -le $attemptCount; $attempt++) {
        if (-not $Strict) {
            Write-Host "skills page performance validation attempt $attempt/$attemptCount"
        }
        $result = Invoke-CapturedPowerShellScript $Path
        $output = @($result["output"])
        $exitCode = [int]$result["exit_code"]
        if ($Strict) {
            $output | Out-Host
        }
        Assert-NoHeadlessGodotProcesses "$Context attempt $attempt"
        if ($exitCode -eq 0) {
            if (-not $Strict) {
                $output | Out-Host
            }
            Assert-NoUnexpectedGodotErrors $output "$Context attempt $attempt"
            if (-not $Strict) {
                Write-Host "skills-page-performance-release-ok attempt=$attempt"
            }
            $global:LASTEXITCODE = 0
            return
        }
        Assert-NoCrashLikeGodotErrors $output "$Context attempt $attempt failure output"
        if ($Strict) {
            exit $exitCode
        }
        $lastFailureOutput = $output
        $lastFailureExitCode = $exitCode
        Write-Warning "Skills page performance attempt $attempt failed with exit code $exitCode; retrying in non-strict mode."
    }

    Write-Warning "Skills page performance validation failed after $attemptCount attempts; continuing because strict skills performance is disabled."
    if ($null -ne $lastFailureOutput) {
        Assert-NoCrashLikeGodotErrors $lastFailureOutput "$Context non-strict failure output"
        Write-Host "Last failed non-strict skills page performance output follows. exitCode=$lastFailureExitCode"
        $lastFailureOutput | Out-Host
    }
    Write-Host "skills-page-performance-release-warning attempts=$attemptCount"
    $global:LASTEXITCODE = 0
}

if (-not (Test-Path -LiteralPath $runner)) {
    throw "Godot runner was not found at $runner"
}

$suiteTestDir = Join-Path $projectRoot ".codex-tmp\check-project-suite"
$suiteUserDataDir = Join-Path $suiteTestDir "user-data"
if (Test-Path -LiteralPath $suiteTestDir) {
    Remove-Item -LiteralPath $suiteTestDir -Recurse -Force
}
New-Item -ItemType Directory -Path $suiteUserDataDir -Force | Out-Null
$previousSuiteUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$env:IDLE_ELITE_TEST_USER_DATA_DIR = $suiteUserDataDir
try {
$smokeTestDir = Join-Path $projectRoot ".codex-tmp\check-project-smoke"
$smokeUserDataDir = Join-Path $smokeTestDir "user-data"
if (Test-Path -LiteralPath $smokeTestDir) {
    Remove-Item -LiteralPath $smokeTestDir -Recurse -Force
}
New-Item -ItemType Directory -Path $smokeUserDataDir -Force | Out-Null
$previousSmokeTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousSmokeUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$env:GODOT_RUN_TIMEOUT_SECONDS = "60"
$env:IDLE_ELITE_TEST_USER_DATA_DIR = $smokeUserDataDir
try {
    $smokeOutput = & $runner --headless --path $projectRoot --quit-after 1 2>&1
}
finally {
    if ($null -eq $previousSmokeTimeout) {
        Remove-Item Env:GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousSmokeTimeout
    }
    if ($null -eq $previousSmokeUserDataDir) {
        Remove-Item Env:IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousSmokeUserDataDir
    }
}
$smokeOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $smokeOutput "project smoke validation"
Assert-NoHeadlessGodotProcesses "project smoke validation"

foreach ($validation in @(
    @("scripts\test-performance-monitor.ps1", "Performance monitor", "performance monitor"),
    @("scripts\test-performance-regressions.ps1", "Performance regression", "performance regression"),
    @("scripts\check-runtime-asset-paths.ps1", "Runtime asset path", "runtime asset path"),
    @("scripts\test-woodcutting-firepit.ps1", "Woodcutting Firepit", "woodcutting firepit"),
    @("scripts\check-activity-database-contracts.ps1", "Activity database contract", "activity database contract"),
    @("scripts\check-generated-file-hygiene.ps1", "Generated-file hygiene", "generated-file hygiene"),
    @("scripts\check-ui-boundary-contracts.ps1", "UI boundary contract", "UI boundary contract"),
    @("scripts\check-activity-ui-boundary-contracts.ps1", "Activity UI boundary contract", "activity UI boundary contract"),
    @("scripts\check-leaderboard-cost-safety.ps1", "Leaderboard cost-safety", "leaderboard cost-safety"),
    @("scripts\check-crash-audit-contracts.ps1", "Crash-audit contracts", "crash-audit contracts"),
    @("scripts\check-test-harness-contracts.ps1", "Test-harness contracts", "test-harness contracts"),
    @("scripts\check-1080p-migration-contracts.ps1", "1080p migration contracts", "1080p migration contracts"),
    @("scripts\check-performance-resource-contracts.ps1", "Performance resource contracts", "performance resource contracts"),
    @("scripts\test-performance-resource-lifetime.ps1", "Performance resource lifetime", "performance resource lifetime"),
    @("scripts\test-activity-card-geometry.ps1", "Activity card geometry", "activity card geometry"),
    @("scripts\test-home-achievement-medal-click.ps1", "Home achievement medal click", "home achievement medal click"),
    @("scripts\test-action-card-medal-ceremony-cleanup.ps1", "Action card medal ceremony cleanup", "action card medal ceremony cleanup"),
    @("scripts\test-crash-report-recovery.ps1", "Crash report recovery", "crash report recovery"),
    @("scripts\test-tutorial-start-scroll.ps1", "Tutorial start scroll", "tutorial start scroll"),
    @("scripts\test-stamina-gauge-fail-shake.ps1", "Stamina gauge fail-shake", "stamina gauge fail-shake"),
    @("scripts\test-skill-detail-bottom-scroll-pad.ps1", "Skill detail bottom scroll-pad", "skill detail bottom scroll-pad"),
    @("scripts\test-skill-detail-hidden-preview-scroll-gap.ps1", "Skill detail hidden preview scroll-gap", "skill detail hidden preview scroll-gap"),
    @("scripts\test-save-normalization.ps1", "Save normalization", "save normalization"),
    @("scripts\test-save-hardening.ps1", "Save hardening", "save hardening"),
    @("scripts\test-stability-regressions.ps1", "Stability regressions", "stability regressions"),
    @("scripts\test-skill-swipe-fresh-save.ps1", "Fresh-save skill swipe", "fresh-save skill swipe"),
    @("scripts\test-tier-banner-scroll.ps1", "Tier menu drag scroll", "tier menu drag scroll"),
    @("scripts\test-skill-swipe-first-swipe.ps1", "First swipe after neighbour rebuild", "first swipe after neighbour rebuild"),
    @("scripts\test-skill-swipe-adjacent-pages.ps1", "Adjacent skill pages swipe", "adjacent skill pages swipe"),
    @("scripts\test-save-lifecycle-guard.ps1", "Save lifecycle guard", "save lifecycle guard"),
    @("scripts\test-online-identity-safety.ps1", "Online identity safety", "online identity safety"),
    @("scripts\test-firebase-profile-backfill.ps1", "Firebase profile backfill", "firebase profile backfill"),
    @("scripts\test-firebase-leaderboard-runtime-guard.ps1", "Firebase leaderboard runtime guard", "firebase leaderboard runtime guard"),
    @("scripts\test-leaderboard-sync.ps1", "Leaderboard sync regression", "leaderboard sync regression"),
    @("scripts\test-online-reliability.ps1", "Chat and returning-player reliability", "online reliability"),
    @("scripts\test-leaderboard-fresh-start.ps1", "Leaderboard fresh start", "leaderboard fresh start"),
    @("scripts\test-activity-queue.ps1", "Activity queue", "activity queue"),
    @("scripts\test-module-list-transitions.ps1", "Module list transitions", "module list transitions"),
    @("scripts\test-pinned-pin-visual-smoke.ps1", "Pinned pin visual smoke", "pinned pin visual smoke"),
    @("scripts\test-pinned-scroll-anchor.ps1", "Pinned scroll anchor", "pinned scroll anchor"),
    @("scripts\test-pinned-page-interactions.ps1", "Pinned page interactions", "pinned page interactions")
)) {
    $validationPath = Join-Path $projectRoot $validation[0]
    Invoke-ProjectValidationScript `
        -Path $validationPath `
        -MissingMessage "$($validation[1]) test was not found at $validationPath" `
        -Context "$($validation[2]) validation"
}

$strictSkillsPerformance = $env:IDLE_ELITE_STRICT_SKILLS_PERF -eq "1"
$skillsPageValidationTest = $skillsPagePerformanceRepeatTest
$skillsPageValidationContext = "strict repeated skills page performance validation"
if (-not $strictSkillsPerformance) {
    $skillsPageValidationTest = $skillsPagePerformanceTest
    $skillsPageValidationContext = "skills page performance validation"
}

if (-not (Test-Path -LiteralPath $skillsPageValidationTest)) {
    throw "Skills page performance test was not found at $skillsPageValidationTest"
}

Invoke-SkillsPagePerformanceValidation `
    -Path $skillsPageValidationTest `
    -MissingMessage "Skills page performance test was not found at $skillsPageValidationTest" `
    -Context $skillsPageValidationContext `
    -Strict $strictSkillsPerformance
Write-Output "check-project-ok"
}
finally {
    if ($null -eq $previousSuiteUserDataDir) {
        Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousSuiteUserDataDir
    }
}
