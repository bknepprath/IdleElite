# One-time leaderboard switch-on, run after 0.6.0 is live on Play and itch.
#
#   Preview (read-only):  .\scripts\switch-on-firebase-leaderboard-rules.ps1 -ProjectId idle-elite
#   Do it:                .\scripts\switch-on-firebase-leaderboard-rules.ps1 -ProjectId idle-elite -Apply
#
# -Apply deploys the authenticated rules (scores need a login, can't go down, capped levels),
# then removes score rows and name claims that don't belong to a signed-in player (0.5.3 and
# older entries), so everyone starts fresh and can re-claim their name.
# Player progress is untouched: it lives in each player's save, and 0.6.0 re-posts every score
# the first time it runs. A full backup of /leaderboards/v1 is written under release\ first.
param(
    [Parameter(Mandatory = $true)][string]$ProjectId,
    [switch]$Apply
)
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
. (Join-Path $PSScriptRoot "lib\leaderboard-switch-on.ps1")
$deployScript = Join-Path $PSScriptRoot "deploy-firebase-leaderboard-rules.ps1"
$evidenceDir = Join-Path $projectRoot "release\leaderboard-switch-on"
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

Assert-True ($null -ne (Get-Command firebase -ErrorAction SilentlyContinue)) "Firebase CLI was not found."

function Save-LeaderboardSnapshot {
    param([string]$Label)
    $stamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $path = Join-Path $evidenceDir "leaderboards-v1-$Label-$stamp.json"
    & firebase database:get /leaderboards/v1 --project $ProjectId --output $path
    Assert-True ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $path)) "Could not read /leaderboards/v1 from $ProjectId."
    return $path
}

function Get-SnapshotPlan {
    param([string]$SnapshotPath)
    $snapshot = Get-Content -LiteralPath $SnapshotPath -Raw | ConvertFrom-Json
    Assert-True ($null -ne $snapshot) "Snapshot $SnapshotPath is empty."
    return Get-StaleLeaderboardScorePaths -LeaderboardsV1 $snapshot
}

# Validates the committed rules and cost-safety checks without deploying.
& $deployScript -ProjectId $ProjectId -CheckOnly

$previewSnapshot = Save-LeaderboardSnapshot "preview"
$previewPlan = Get-SnapshotPlan $previewSnapshot
Write-Output "Backup: $previewSnapshot"
Write-Output "Signed-in score rows kept: $($previewPlan.Kept)"
Write-Output "Legacy score rows and name claims to remove: $($previewPlan.Stale.Count)"

if (-not $Apply) {
    Write-Output "Preview only. Re-run with -Apply to deploy the rules and remove the legacy rows."
    return
}

& $deployScript -ProjectId $ProjectId

# Snapshot again after the deploy: from here on legacy clients can no longer write, so this set is final.
$finalSnapshot = Save-LeaderboardSnapshot "after-rules"
$plan = Get-SnapshotPlan $finalSnapshot
if ($plan.Stale.Count -gt 0) {
    $updatePath = Join-Path $evidenceDir ("remove-legacy-rows-" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".json")
    New-StaleLeaderboardDeleteUpdate -StalePaths $plan.Stale | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $updatePath -Encoding UTF8
    & firebase database:update /leaderboards/v1 $updatePath --project $ProjectId --force
    Assert-True ($LASTEXITCODE -eq 0) "Removing legacy score rows failed. The rules are deployed; re-run with -Apply to retry the cleanup."
}
Write-Output "Rules deployed. Kept $($plan.Kept) signed-in score rows and $($plan.KeptClaims) name claims; removed $($plan.Stale.Count) legacy entries."
Write-Output "leaderboard-switch-on-ok"
