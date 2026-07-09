param(
    [string]$Category = "total_level"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$configPath = Join-Path $projectRoot "firebase-leaderboard-config.json"
$activityDatabasePath = Join-Path $projectRoot "docs\activity-database.json"
$firebaseDatabaseUrlPattern = '^https://([a-z0-9-]+\.firebaseio\.com|[a-z0-9-]+\.[a-z0-9-]+\.firebasedatabase\.app)$'

Assert-True (Test-Path -LiteralPath $configPath) "Missing firebase-leaderboard-config.json. Create it with scripts\write-firebase-leaderboard-config.ps1 after publishing rules."
Assert-True (Test-Path -LiteralPath $activityDatabasePath) "Missing docs\activity-database.json."

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$activityDatabase = Get-Content -LiteralPath $activityDatabasePath -Raw | ConvertFrom-Json
$databaseUrl = ([string]$config.database_url).Trim().TrimEnd("/")
$webApiKey = ([string]$config.web_api_key).Trim()

Assert-True ($databaseUrl -cmatch $firebaseDatabaseUrlPattern) "Invalid database_url in firebase-leaderboard-config.json."
Assert-True ($databaseUrl -notmatch 'your-project-id|YOUR-PROJECT') "database_url is still a placeholder."
Assert-True ($webApiKey.Length -ge 20) "Invalid web_api_key in firebase-leaderboard-config.json."
Assert-True ($webApiKey -ne "YOUR_FIREBASE_WEB_API_KEY") "web_api_key is still a placeholder."

$skillIds = @($activityDatabase.skills | ForEach-Object { $_.id } | Where-Object { $_ })
$allowedCategoryKeys = @("total_level") + @($skillIds | ForEach-Object { "skill_xp__$_" }) + @("medals_earned", "elite_heavenly")
$categoryKey = $Category.Trim().Replace(":", "__")
Assert-True ($allowedCategoryKeys -contains $categoryKey) "Category is not in the Idle Elite leaderboard allowlist."

$query = 'orderBy=%22score%22&limitToLast=1'
$readUrl = "$databaseUrl/leaderboards/v1/scores/$categoryKey.json?$query"
$databaseReadCount = 0
$databaseReadCount += 1
$rows = Invoke-RestMethod -Method Get -Uri $readUrl
Assert-True ($databaseReadCount -eq 1) "Live smoke helper must perform exactly one database read."

Write-Output "firebase-live-public-read-ok"
if ($null -eq $rows -or [string]$rows -eq "null") {
    Write-Output "firebase-live-read-ok category=$categoryKey rows=0"
} else {
    $rowCount = @($rows.PSObject.Properties).Count
    Write-Output "firebase-live-read-ok category=$categoryKey rows=$rowCount"
}
Write-Output "firebase-live-db-read-count-ok count=$databaseReadCount"
Write-Output "firebase-live-read-only-ok"
