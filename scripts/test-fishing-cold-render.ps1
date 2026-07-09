param(
    [double]$MaxRenderMsec = 120,
    [double]$MaxWarmFrameMsec = 50,
    [int]$MaxImmediateMounted = 6,
    [int]$MaxWarmFrames = 180
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fishing-cold-render-probe"
$resultPath = Join-Path $testDir "result.json"
$testUserDataDir = Join-Path $testDir "user-data"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

$env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserDataDir

try {
    $output = & $runner --path $projectRoot --script "res://scripts/tests/fishing_cold_render_probe.gd" 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    Assert-True (Test-Path -LiteralPath $resultPath) "Fishing cold render probe did not write a result file."
    $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
    Assert-True ($result.status -eq "ok") "Fishing cold render probe status was $($result.status)."
    Assert-True ([double]$result.render_msec -le $MaxRenderMsec) "Fishing cold render took $($result.render_msec)ms, expected at most ${MaxRenderMsec}ms."
    Assert-True ([int]$result.immediate_mounted -le $MaxImmediateMounted) "Fishing cold render mounted $($result.immediate_mounted) modules immediately, expected at most $MaxImmediateMounted."
    Assert-True ([int]$result.warmed_mounted -eq [int]$result.plan) "Fishing warm mount should reach every module without player scroll: $($result.warmed_mounted) / $($result.plan)."
    Assert-True ([int]$result.warm_frames -le $MaxWarmFrames) "Fishing warm mount took $($result.warm_frames) frames, expected at most $MaxWarmFrames."
    Assert-True ([double]$result.max_warm_frame_msec -le $MaxWarmFrameMsec) "Fishing warm mount frame took $($result.max_warm_frame_msec)ms, expected at most ${MaxWarmFrameMsec}ms."
    Assert-True ([int]$result.warm_over_50 -eq 0) "Fishing warm mount had $($result.warm_over_50) frame(s) over 50ms."
    Assert-True (-not [bool]$result.visible_placeholders) "Fishing cold render left visible lazy placeholders in the viewport."
    Assert-True (-not [bool]$result.warmed_visible_placeholders) "Fishing warm mount left visible lazy placeholders in the viewport."

    "fishing-cold-render-ok render_ms=$($result.render_msec) immediate=$($result.immediate_mounted) warmed=$($result.warmed_mounted)/$($result.plan) warm_frames=$($result.warm_frames) max_warm_ms=$($result.max_warm_frame_msec) result=$resultPath"
}
finally {
    Remove-Item Env:IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    $headless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($headless.Count -gt 0) {
        $headless | Select-Object ProcessId,ParentProcessId,CommandLine | Format-List | Out-Host
        throw "Headless Godot process remained after fishing cold render probe."
    }
}
