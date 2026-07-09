param(
    [double]$MaxFrameMsec = 50,
    [int]$MinMounted = 2,
    [int]$MinSampleCount = 800,
    [int]$MinScrollDelta = 400,
    [int]$MaxFirstScrollFrame = 8
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fishing-drag-spike"
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

$env:IDLE_ELITE_FISHING_DRAG_SPIKE_RESULT = $resultPath
$env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserDataDir

try {
    $output = & $runner --path $projectRoot --script "res://scripts/tests/fishing_drag_spike.gd" 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    Assert-True (Test-Path -LiteralPath $resultPath) "Fishing drag spike test did not write a result file."
    $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
    Assert-True ($result.status -eq "ok") "Fishing drag spike test status was $($result.status)."
    Assert-True ([int]$result.mounted -ge $MinMounted) "Fishing drag spike mounted too few modules: $($result.mounted), expected at least $MinMounted."
    Assert-True ([int]$result.sample_count -ge $MinSampleCount) "Fishing drag spike sampled too few frames: $($result.sample_count), expected at least $MinSampleCount."
    Assert-True ([double]$result.max_ms -le $MaxFrameMsec) "Fishing drag spike max frame $($result.max_ms)ms exceeded ${MaxFrameMsec}ms."
    Assert-True ([int]$result.over_50 -eq 0) "Fishing drag spike recorded $($result.over_50) frames over 50ms."

    foreach ($probeName in @("cold-touch-up", "cold-mouse-tile-up", "touch-up", "touch-down", "mouse-up", "touch-tile-up", "mouse-tile-up")) {
        $delta = [int]$result.probe_scroll_deltas.$probeName
        Assert-True ($delta -ge $MinScrollDelta) "Fishing drag spike probe $probeName barely scrolled: $delta px, expected at least $MinScrollDelta px."
    }

    foreach ($probeName in @("cold-touch-up", "cold-mouse-tile-up", "touch-tile-up", "mouse-tile-up")) {
        $firstScrollFrame = [int]$result.probe_first_scroll_frames.$probeName
        Assert-True ($firstScrollFrame -gt 0) "Fishing drag spike probe $probeName never started scrolling."
        Assert-True ($firstScrollFrame -le $MaxFirstScrollFrame) "Fishing drag spike probe $probeName started scrolling on frame $firstScrollFrame, expected frame $MaxFirstScrollFrame or sooner."
    }

    "fishing-drag-spike-ok mounted=$($result.mounted) samples=$($result.sample_count) max_ms=$($result.max_ms) p95_ms=$($result.p95_ms) over50=$($result.over_50) tile_first_scroll_touch=$($result.probe_first_scroll_frames.'touch-tile-up') tile_first_scroll_mouse=$($result.probe_first_scroll_frames.'mouse-tile-up') result=$resultPath"
}
finally {
    Remove-Item Env:IDLE_ELITE_FISHING_DRAG_SPIKE_RESULT -ErrorAction SilentlyContinue
    Remove-Item Env:IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    $headless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after fishing drag spike validation."
    }
}
