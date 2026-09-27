$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$skillsPagePerformanceTest = Join-Path $projectRoot "scripts\test-skills-page-performance.ps1"
$skillsPagePerformanceRepeatTest = Join-Path $projectRoot "scripts\test-skills-page-performance-repeat.ps1"

function Assert-NoUnexpectedGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context,
        [switch]$AllowPerformanceFailures
    )

    if ($null -eq $Output) {
        return
    }

    $renderedText = $Output | Out-String -Width 4096
    $skillsPageStart = $renderedText.IndexOf("skills-page-performance-start")
    if (-not $AllowPerformanceFailures -and $Context -match 'skills page performance' -and $skillsPageStart -ge 0) {
        $renderedText = $renderedText.Substring($skillsPageStart)
    }
    foreach ($line in ($renderedText -split "\r?\n")) {
        $text = [string]$line
        if ($text -notmatch '(ERROR|SCRIPT ERROR):') {
            if (-not $AllowPerformanceFailures -and (
                $text -match '^\s*At .+\.ps1:\d+ char:\d+' -or
                $text -match 'OperationStopped' -or
                $text -match 'did not report success'
            )) {
                throw "Unexpected PowerShell failure during ${Context}: $text"
            }
            continue
        }
        $knownPerformanceFailure = $AllowPerformanceFailures -and (
            $text -match '(ERROR|powershell\.exe : ERROR): (idle|scroll|swipe|rapid_swipe)/.+(FPS budget|frame work exceeded)' -or
            $text -match 'ERROR: Skills page performance test did not report success\.'
        )
        $knownShutdownNoise = (
			$text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
			$text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
		)
		$knownMachineCertificateNoise = $text -match '^ERROR: Failed to read the root certificate store\.$'
		if (-not ($knownPerformanceFailure -or $knownShutdownNoise -or $knownMachineCertificateNoise)) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}

function Invoke-ProjectValidationScript {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Validation script was not found for ${Context}: $Path"
    }

    $global:LASTEXITCODE = 0
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
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$Path`""
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
        Assert-NoUnexpectedGodotErrors $output "$Context attempt $attempt failure output" -AllowPerformanceFailures
        $lastFailureOutput = $output
        $lastFailureExitCode = $exitCode
        Write-Warning "Skills page performance attempt $attempt failed with exit code $exitCode; retrying in non-strict mode."
    }

    Write-Warning "Skills page performance validation failed after $attemptCount attempts; continuing because strict skills performance is disabled."
    if ($null -ne $lastFailureOutput) {
        Assert-NoUnexpectedGodotErrors $lastFailureOutput "$Context non-strict failure output" -AllowPerformanceFailures
        Write-Host "Last failed non-strict skills page performance output follows. exitCode=$lastFailureExitCode"
        $lastFailureOutput | Out-Host
    }
    Write-Host "skills-page-performance-release-warning attempts=$attemptCount"
    $global:LASTEXITCODE = 0
}

if (-not (Test-Path -LiteralPath $runner)) {
    throw "Godot runner was not found at $runner"
}

$previousSmokeTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "60"
try {
    $smokeOutput = & $runner --headless --path $projectRoot 2>&1
}
finally {
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousSmokeTimeout
}
$smokeOutput | Out-Host
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Assert-NoUnexpectedGodotErrors $smokeOutput "project smoke validation"
Assert-NoHeadlessGodotProcesses "project smoke validation"

$validationScripts = @(
    ,@("test-performance-monitor.ps1", "performance monitor validation")
    ,@("check-runtime-asset-paths.ps1", "runtime asset path validation")
    ,@("test-woodcutting-firepit.ps1", "woodcutting firepit validation")
    ,@("check-activity-database-contracts.ps1", "activity database contract validation")
    ,@("check-generated-file-hygiene.ps1", "generated-file hygiene validation")
    ,@("check-ui-boundary-contracts.ps1", "UI boundary contract validation")
    ,@("check-leaderboard-cost-safety.ps1", "leaderboard cost-safety validation")
    ,@("check-crash-audit-contracts.ps1", "crash-audit contracts validation")
    ,@("test-activity-card-geometry.ps1", "activity card geometry validation")
    ,@("test-home-achievement-medal-click.ps1", "home achievement medal click validation")
    ,@("test-action-card-medal-ceremony-cleanup.ps1", "action card medal ceremony cleanup validation")
    ,@("test-crash-report-recovery.ps1", "crash report recovery validation")
    ,@("test-tutorial-start-scroll.ps1", "tutorial start scroll validation")
    ,@("test-stamina-gauge-fail-shake.ps1", "stamina gauge fail-shake validation")
    ,@("test-skill-detail-bottom-scroll-pad.ps1", "skill detail bottom scroll pad validation")
    ,@("test-skill-detail-hidden-preview-scroll-gap.ps1", "skill detail hidden preview scroll-gap validation")
    ,@("test-tier-banner-scroll.ps1", "tier banner scroll validation")
    ,@("test-save-normalization.ps1", "save normalization validation")
    ,@("test-save-hardening.ps1", "save migration and hardening validation")
    ,@("test-save-lifecycle-guard.ps1", "save lifecycle guard validation")
    ,@("test-online-identity-safety.ps1", "online identity safety validation")
    ,@("test-activity-queue.ps1", "activity queue validation")
    ,@("test-module-list-transitions.ps1", "module list transitions validation")
    ,@("test-pinned-pin-visual-smoke.ps1", "pinned pin visual smoke validation")
    ,@("test-pinned-scroll-anchor.ps1", "pinned scroll anchor validation")
    ,@("test-pinned-page-interactions.ps1", "pinned page interactions validation")
)
foreach ($validation in $validationScripts) {
    Invoke-ProjectValidationScript (Join-Path $PSScriptRoot $validation[0]) $validation[1]
}

$strictSkillsPerformance = $env:IDLE_ELITE_STRICT_SKILLS_PERF -eq "1"
$skillsPageValidationTest = $skillsPagePerformanceRepeatTest
$skillsPageValidationContext = "strict repeated skills page performance validation"
if (-not $strictSkillsPerformance) {
    $skillsPageValidationTest = $skillsPagePerformanceTest
    $skillsPageValidationContext = "skills page performance validation"
}

Invoke-SkillsPagePerformanceValidation `
    -Path $skillsPageValidationTest `
    -MissingMessage "Skills page performance test was not found at $skillsPageValidationTest" `
    -Context $skillsPageValidationContext `
    -Strict $strictSkillsPerformance
