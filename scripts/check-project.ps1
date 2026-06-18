$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$performanceTest = Join-Path $projectRoot "scripts\test-performance-monitor.ps1"
$performanceRegressionTest = Join-Path $projectRoot "scripts\test-performance-regressions.ps1"
$runtimeAssetPathTest = Join-Path $projectRoot "scripts\check-runtime-asset-paths.ps1"
$activityDatabaseContractTest = Join-Path $projectRoot "scripts\check-activity-database-contracts.ps1"
$uiBoundaryContractTest = Join-Path $projectRoot "scripts\check-ui-boundary-contracts.ps1"
$activityUiBoundaryContractTest = Join-Path $projectRoot "scripts\check-activity-ui-boundary-contracts.ps1"
$leaderboardCostSafetyTest = Join-Path $projectRoot "scripts\check-leaderboard-cost-safety.ps1"
$activityCardGeometryTest = Join-Path $projectRoot "scripts\test-activity-card-geometry.ps1"
$tutorialStartScrollTest = Join-Path $projectRoot "scripts\test-tutorial-start-scroll.ps1"
$staminaGaugeFailShakeTest = Join-Path $projectRoot "scripts\test-stamina-gauge-fail-shake.ps1"
$skillDetailBottomScrollPadTest = Join-Path $projectRoot "scripts\test-skill-detail-bottom-scroll-pad.ps1"
$skillDetailHiddenPreviewScrollGapTest = Join-Path $projectRoot "scripts\test-skill-detail-hidden-preview-scroll-gap.ps1"
$saveNormalizationTest = Join-Path $projectRoot "scripts\test-save-normalization.ps1"
$skillsPagePerformanceTest = Join-Path $projectRoot "scripts\test-skills-page-performance.ps1"
$skillsPagePerformanceRepeatTest = Join-Path $projectRoot "scripts\test-skills-page-performance-repeat.ps1"

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

if (-not (Test-Path -LiteralPath $activityDatabaseContractTest)) {
    throw "Activity database contract test was not found at $activityDatabaseContractTest"
}

$activityDatabaseContractOutput = & $activityDatabaseContractTest 2>&1
$activityDatabaseContractOutput | Out-Host
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

if ($strictSkillsPerformance) {
    Write-Host "Strict skills page performance repeat is enabled."
}

$skillsPageOutput = & $skillsPageValidationTest 2>&1
$skillsPageOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $skillsPageOutput $skillsPageValidationContext
Assert-NoHeadlessGodotProcesses $skillsPageValidationContext
