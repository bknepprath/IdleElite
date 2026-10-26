param([ValidateSet('runtime','desktop')][string]$Group = 'runtime')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$outputRoot = Join-Path $projectRoot '.codex-tmp/audit-2026-10-14'
New-Item -ItemType Directory -Force $outputRoot | Out-Null
$tests = if ($Group -eq 'runtime') { @(
    'check-runtime-asset-paths','check-activity-database-contracts','audit-activity-database',
    'check-ui-boundary-contracts','check-activity-ui-boundary-contracts','check-crash-audit-contracts',
    'check-test-harness-contracts','check-1080p-migration-contracts','check-performance-resource-contracts',
    'test-performance-monitor','test-performance-resource-lifetime','test-save-normalization',
    'test-save-hardening','test-stability-regressions','test-save-lifecycle-guard',
    'test-online-identity-safety','test-activity-queue','test-buildable-modules',
    'test-module-list-transitions','test-woodcutting-firepit','test-recovery-modules',
    'test-activity-card-geometry','test-activity-progress-turnover',
    'test-tutorial-start-scroll','test-skill-swipe-fresh-save','test-tier-banner-scroll',
    'test-skill-swipe-first-swipe','test-skill-swipe-adjacent-pages',
    'test-pinned-scroll-anchor','test-pinned-page-interactions',
    'test-stamina-gauge-fail-shake','test-home-achievement-medal-click',
    'test-action-card-medal-ceremony-cleanup','test-crash-report-recovery',
    'test-skills-page-performance'
) } else { @(
    'startup_ribbon','startup_returning','early_skill_links','desktop_opening','desktop_responsive',
    'desktop_focus_reveal','desktop_reveal_tips','desktop_corner_navigation',
    'project_resources','full_width_barriers','auto_unlock_desktop','build_panel_refresh'
) }
$results = @()
foreach ($test in $tests) {
    $stdout = Join-Path $outputRoot "$Group-$test.stdout.log"
    $stderr = Join-Path $outputRoot "$Group-$test.stderr.log"
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $outputRoot "users/$Group-$test"
    $env:GODOT_RUN_TIMEOUT_SECONDS = '300'
    $env:IDLE_ELITE_AUDIT_LABEL = "verified-$test"
    $arguments = if ($Group -eq 'runtime') {
        '-NoProfile -ExecutionPolicy Bypass -File "{0}"' -f (Join-Path $PSScriptRoot "$test.ps1")
    } else {
        '-NoProfile -ExecutionPolicy Bypass -File "{0}" --visible-game --path "{1}" --audio-driver Dummy --script res://scripts/tests/{2}.gd --log-file "{3}"' -f (Join-Path $projectRoot 'run-godot-safe.ps1'), $projectRoot, $test, (Join-Path $outputRoot "desktop-$test.godot.log")
    }
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $process = Start-Process powershell.exe -ArgumentList $arguments -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $null = $process.Handle
    if (-not $process.WaitForExit(360000)) {
        # The safe runner has its own 300-second limit. Unknown children must not
        # be killed or silently accepted by this reporting layer.
        throw "Audit child exceeded its safe-runner timeout: $test (PID $($process.Id))."
    }
    $process.Refresh()
    $logs = @(Get-Content $stdout,$stderr -ErrorAction SilentlyContinue)
    if ($Group -eq 'desktop') { $logs += @(Get-Content (Join-Path $outputRoot "desktop-$test.godot.log") -ErrorAction SilentlyContinue) }
    $errors = @($logs | Where-Object { $_ -match 'SCRIPT ERROR:|^ERROR:|failures=\["|"failures":\["' -and $_ -notmatch 'RID allocations|resources still in use|root certificate store' })
    Assert-NoHeadlessGodotProcesses $test
    if ($Group -eq 'desktop' -and @(Get-Process godot* -ErrorAction SilentlyContinue).Count -gt 0) { throw "Unattributed Godot remains after $test; stopping audit." }
    $result = [pscustomobject]@{test=$test;exit_code=$process.ExitCode;passed=($process.ExitCode -eq 0 -and $errors.Count -eq 0);seconds=[math]::Round($watch.Elapsed.TotalSeconds,2);errors=@($errors | Select-Object -First 8)}
    $results += $result
    $results | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $outputRoot "$Group-results.json")
    Write-Output ("AUDIT {0} {1} {2}s" -f $test,$result.passed,$result.seconds)
}
Write-Output ("AUDIT COMPLETE passed={0}/{1}" -f @($results | Where-Object passed).Count,$results.Count)
