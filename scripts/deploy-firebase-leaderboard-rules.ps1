param(
    [Parameter(Mandatory = $true)][string]$ProjectId,
    [switch]$CheckOnly
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$firebaseJsonPath = Join-Path $projectRoot "firebase.json"
$rulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$cleanProjectId = $ProjectId.Trim()
Assert-True ($cleanProjectId -match '^[a-z][a-z0-9-]{4,29}$') "ProjectId should be the Firebase project id, for example idle-elite-leaderboard."
Assert-True (Test-Path -LiteralPath $firebaseJsonPath) "Missing firebase.json."
Assert-True (Test-Path -LiteralPath $rulesPath) "Missing firebase-realtime-database.rules.json."

$firebaseConfig = Get-Content -LiteralPath $firebaseJsonPath -Raw | ConvertFrom-Json
Assert-True ([string]$firebaseConfig.database.rules -eq "firebase-realtime-database.rules.json") "firebase.json must deploy the generated leaderboard rules file."

& (Join-Path $projectRoot "scripts\update-firebase-leaderboard-rules.ps1") -Check
& (Join-Path $projectRoot "scripts\check-leaderboard-cost-safety.ps1")

if ($CheckOnly) {
    Write-Output "firebase-leaderboard-rules-deploy-check-ok"
    return
}

$firebaseCommand = Get-Command firebase -ErrorAction SilentlyContinue
Assert-True ($null -ne $firebaseCommand) "Firebase CLI was not found. Install it or publish rules from the Firebase console."

Push-Location $projectRoot
try {
    & firebase deploy --only database --project $cleanProjectId
} finally {
    Pop-Location
}
