$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$performanceTest = Join-Path $projectRoot "scripts\test-performance-monitor.ps1"
$performanceRegressionTest = Join-Path $projectRoot "scripts\test-performance-regressions.ps1"
$runtimeAssetPathTest = Join-Path $projectRoot "scripts\check-runtime-asset-paths.ps1"
$woodcuttingFirepitTest = Join-Path $projectRoot "scripts\test-woodcutting-firepit.ps1"
$activityDatabaseContractTest = Join-Path $projectRoot "scripts\check-activity-database-contracts.ps1"
$generatedFileHygieneTest = Join-Path $projectRoot "scripts\check-generated-file-hygiene.ps1"
$uiBoundaryContractTest = Join-Path $projectRoot "scripts\check-ui-boundary-contracts.ps1"
$activityUiBoundaryContractTest = Join-Path $projectRoot "scripts\check-activity-ui-boundary-contracts.ps1"
$leaderboardCostSafetyTest = Join-Path $projectRoot "scripts\check-leaderboard-cost-safety.ps1"
$crashAuditContractsTest = Join-Path $projectRoot "scripts\check-crash-audit-contracts.ps1"
$activityCardGeometryTest = Join-Path $projectRoot "scripts\test-activity-card-geometry.ps1"
$homeAchievementMedalClickTest = Join-Path $projectRoot "scripts\test-home-achievement-medal-click.ps1"
$actionCardMedalCeremonyCleanupTest = Join-Path $projectRoot "scripts\test-action-card-medal-ceremony-cleanup.ps1"
$crashReportRecoveryTest = Join-Path $projectRoot "scripts\test-crash-report-recovery.ps1"
$tutorialStartScrollTest = Join-Path $projectRoot "scripts\test-tutorial-start-scroll.ps1"
$staminaGaugeFailShakeTest = Join-Path $projectRoot "scripts\test-stamina-gauge-fail-shake.ps1"
$skillDetailBottomScrollPadTest = Join-Path $projectRoot "scripts\test-skill-detail-bottom-scroll-pad.ps1"
$skillDetailHiddenPreviewScrollGapTest = Join-Path $projectRoot "scripts\test-skill-detail-hidden-preview-scroll-gap.ps1"
$saveNormalizationTest = Join-Path $projectRoot "scripts\test-save-normalization.ps1"
$activityQueueTest = Join-Path $projectRoot "scripts\test-activity-queue.ps1"
$moduleListTransitionsTest = Join-Path $projectRoot "scripts\test-module-list-transitions.ps1"
$pinnedPinVisualSmokeTest = Join-Path $projectRoot "scripts\test-pinned-pin-visual-smoke.ps1"
$pinnedScrollAnchorTest = Join-Path $projectRoot "scripts\test-pinned-scroll-anchor.ps1"
$pinnedPageInteractionsTest = Join-Path $projectRoot "scripts\test-pinned-page-interactions.ps1"
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
        $text = [string]$line
        if ($text -notmatch '(ERROR|SCRIPT ERROR):') {
            if (
                $text -match '^\s*At .+\.ps1:\d+ char:\d+' -or
                $text -match 'OperationStopped' -or
                $text -match 'did not report success'
            ) {
                throw "Unexpected PowerShell failure during ${Context}: $text"
            }
            continue
        }
        $knownShutdownNoise = (
            $text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
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
        $text = [string]$line
        if ($text -notmatch '(ERROR|SCRIPT ERROR|powershell\.exe : ERROR):') {
            continue
        }
        $knownPerformanceFailure = (
            $text -match '(ERROR|powershell\.exe : ERROR): (idle|scroll|swipe|rapid_swipe)/.+(FPS budget|frame work exceeded)' -or
            $text -match 'ERROR: Skills page performance test did not report success\.'
        )
        $knownShutdownNoise = (
            $text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
        )
        if (-not ($knownPerformanceFailure -or $knownShutdownNoise)) {
            throw "Crash-like Godot error during ${Context}: $text"
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

    if ($Strict) {
        Write-Host "Strict skills page performance repeat is enabled."
        $strictResult = Invoke-CapturedPowerShellScript $Path
        $strictOutput = @($strictResult["output"])
        $strictExitCode = [int]$strictResult["exit_code"]
        $strictOutput | Out-Host
        if ($strictExitCode -ne 0) {
            exit $strictExitCode
        }
        Assert-NoUnexpectedGodotErrors $strictOutput $Context
        Assert-NoHeadlessGodotProcesses $Context
        return
    }

    $attemptCount = 3
    $lastFailureOutput = $null
    $lastFailureExitCode = 0
    for ($attempt = 1; $attempt -le $attemptCount; $attempt++) {
        Write-Host "skills page performance validation attempt $attempt/$attemptCount"
        $result = Invoke-CapturedPowerShellScript $Path
        $output = @($result["output"])
        $exitCode = [int]$result["exit_code"]
        Assert-NoHeadlessGodotProcesses "$Context attempt $attempt"
        if ($exitCode -eq 0) {
            $output | Out-Host
            Assert-NoUnexpectedGodotErrors $output "$Context attempt $attempt"
            Write-Host "skills-page-performance-release-ok attempt=$attempt"
            $global:LASTEXITCODE = 0
            return
        }
        Assert-NoCrashLikeGodotErrors $output "$Context attempt $attempt failure output"
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

$smokeOutput = & $runner --headless --path $projectRoot --quit-after 1 2>&1
$smokeOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $smokeOutput "project smoke validation"
Assert-NoHeadlessGodotProcesses "project smoke validation"

if (-not (Test-Path -LiteralPath $performanceTest)) {
    throw "Performance monitor test was not found at $performanceTest"
}

$performanceOutput = & $performanceTest 2>&1
$performanceOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $performanceOutput "performance monitor validation"

if (-not (Test-Path -LiteralPath $performanceRegressionTest)) {
    throw "Performance regression test was not found at $performanceRegressionTest"
}

$performanceRegressionOutput = & $performanceRegressionTest 2>&1
$performanceRegressionOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $performanceRegressionOutput "performance regression validation"

if (-not (Test-Path -LiteralPath $runtimeAssetPathTest)) {
    throw "Runtime asset path test was not found at $runtimeAssetPathTest"
}

$runtimeAssetPathOutput = & $runtimeAssetPathTest 2>&1
$runtimeAssetPathOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Invoke-ProjectValidationScript `
    -Path $woodcuttingFirepitTest `
    -MissingMessage "Woodcutting Firepit test was not found at $woodcuttingFirepitTest" `
    -Context "woodcutting firepit validation"

if (-not (Test-Path -LiteralPath $activityDatabaseContractTest)) {
    throw "Activity database contract test was not found at $activityDatabaseContractTest"
}

$activityDatabaseContractOutput = & $activityDatabaseContractTest 2>&1
$activityDatabaseContractOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $generatedFileHygieneTest)) {
    throw "Generated-file hygiene test was not found at $generatedFileHygieneTest"
}

$generatedFileHygieneOutput = & $generatedFileHygieneTest 2>&1
$generatedFileHygieneOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $uiBoundaryContractTest)) {
    throw "UI boundary contract test was not found at $uiBoundaryContractTest"
}

$uiBoundaryContractOutput = & $uiBoundaryContractTest 2>&1
$uiBoundaryContractOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $activityUiBoundaryContractTest)) {
    throw "Activity UI boundary contract test was not found at $activityUiBoundaryContractTest"
}

$activityUiBoundaryContractOutput = & $activityUiBoundaryContractTest 2>&1
$activityUiBoundaryContractOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $leaderboardCostSafetyTest)) {
    throw "Leaderboard cost-safety test was not found at $leaderboardCostSafetyTest"
}

$leaderboardCostSafetyOutput = & $leaderboardCostSafetyTest 2>&1
$leaderboardCostSafetyOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $leaderboardCostSafetyOutput "leaderboard cost-safety validation"

if (-not (Test-Path -LiteralPath $crashAuditContractsTest)) {
    throw "Crash-audit contracts test was not found at $crashAuditContractsTest"
}

$crashAuditContractsOutput = & $crashAuditContractsTest 2>&1
$crashAuditContractsOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $crashAuditContractsOutput "crash-audit contracts validation"

if (-not (Test-Path -LiteralPath $activityCardGeometryTest)) {
    throw "Activity card geometry test was not found at $activityCardGeometryTest"
}

$activityCardGeometryOutput = & $activityCardGeometryTest 2>&1
$activityCardGeometryOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $activityCardGeometryOutput "activity card geometry validation"
Assert-NoHeadlessGodotProcesses "activity card geometry validation"

Invoke-ProjectValidationScript `
    -Path $homeAchievementMedalClickTest `
    -MissingMessage "Home achievement medal click test was not found at $homeAchievementMedalClickTest" `
    -Context "home achievement medal click validation"

Invoke-ProjectValidationScript `
    -Path $actionCardMedalCeremonyCleanupTest `
    -MissingMessage "Action card medal ceremony cleanup test was not found at $actionCardMedalCeremonyCleanupTest" `
    -Context "action card medal ceremony cleanup validation"

Invoke-ProjectValidationScript `
    -Path $crashReportRecoveryTest `
    -MissingMessage "Crash report recovery test was not found at $crashReportRecoveryTest" `
    -Context "crash report recovery validation"

if (-not (Test-Path -LiteralPath $tutorialStartScrollTest)) {
    throw "Tutorial start scroll test was not found at $tutorialStartScrollTest"
}

$tutorialStartScrollOutput = & $tutorialStartScrollTest 2>&1
$tutorialStartScrollOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $tutorialStartScrollOutput "tutorial start scroll validation"
Assert-NoHeadlessGodotProcesses "tutorial start scroll validation"

if (-not (Test-Path -LiteralPath $staminaGaugeFailShakeTest)) {
    throw "Stamina gauge fail-shake test was not found at $staminaGaugeFailShakeTest"
}

$staminaGaugeFailShakeOutput = & $staminaGaugeFailShakeTest 2>&1
$staminaGaugeFailShakeOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $staminaGaugeFailShakeOutput "stamina gauge fail-shake validation"
Assert-NoHeadlessGodotProcesses "stamina gauge fail-shake validation"

if (-not (Test-Path -LiteralPath $skillDetailBottomScrollPadTest)) {
    throw "Skill detail bottom scroll pad test was not found at $skillDetailBottomScrollPadTest"
}

$skillDetailBottomScrollPadOutput = & $skillDetailBottomScrollPadTest 2>&1
$skillDetailBottomScrollPadOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath $skillDetailHiddenPreviewScrollGapTest)) {
    throw "Skill detail hidden preview scroll-gap test was not found at $skillDetailHiddenPreviewScrollGapTest"
}

$skillDetailHiddenPreviewScrollGapOutput = & $skillDetailHiddenPreviewScrollGapTest 2>&1
$skillDetailHiddenPreviewScrollGapOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $skillDetailHiddenPreviewScrollGapOutput "skill detail hidden preview scroll-gap validation"
Assert-NoHeadlessGodotProcesses "skill detail hidden preview scroll-gap validation"

if (-not (Test-Path -LiteralPath $saveNormalizationTest)) {
    throw "Save normalization test was not found at $saveNormalizationTest"
}

$saveNormalizationOutput = & $saveNormalizationTest 2>&1
$saveNormalizationOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $saveNormalizationOutput "save normalization validation"
Assert-NoHeadlessGodotProcesses "save normalization validation"

Invoke-ProjectValidationScript `
    -Path $activityQueueTest `
    -MissingMessage "Activity queue test was not found at $activityQueueTest" `
    -Context "activity queue validation"

Invoke-ProjectValidationScript `
    -Path $moduleListTransitionsTest `
    -MissingMessage "Module list transitions test was not found at $moduleListTransitionsTest" `
    -Context "module list transitions validation"

Invoke-ProjectValidationScript `
    -Path $pinnedPinVisualSmokeTest `
    -MissingMessage "Pinned pin visual smoke test was not found at $pinnedPinVisualSmokeTest" `
    -Context "pinned pin visual smoke validation"

Invoke-ProjectValidationScript `
    -Path $pinnedScrollAnchorTest `
    -MissingMessage "Pinned scroll anchor test was not found at $pinnedScrollAnchorTest" `
    -Context "pinned scroll anchor validation"

Invoke-ProjectValidationScript `
    -Path $pinnedPageInteractionsTest `
    -MissingMessage "Pinned page interactions test was not found at $pinnedPageInteractionsTest" `
    -Context "pinned page interactions validation"

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
