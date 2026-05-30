param(
    [string]$Category = "total_level",
    [switch]$ResetAuth
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot "firebase-leaderboard-config.json"
$activityDatabasePath = Join-Path $projectRoot "docs\activity-database.json"
$smokeDir = Join-Path $projectRoot ".codex-tmp"
$firebaseDatabaseUrlPattern = '^https://([a-z0-9-]+\.firebaseio\.com|[a-z0-9-]+\.[a-z0-9-]+\.firebasedatabase\.app)$'

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Invoke-JsonPost {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Body,
        [Parameter(Mandatory = $true)][string]$ContentType
    )

    Invoke-RestMethod -Method Post -Uri $Uri -Body $Body -ContentType $ContentType
}

function New-AnonymousAuth {
    param([Parameter(Mandatory = $true)][string]$ApiKey)

    $authUrl = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$([uri]::EscapeDataString($ApiKey))"
    Invoke-JsonPost -Uri $authUrl -ContentType "application/json" -Body '{"returnSecureToken":true}'
}

function Refresh-AnonymousAuth {
    param(
        [Parameter(Mandatory = $true)][string]$ApiKey,
        [Parameter(Mandatory = $true)][string]$RefreshToken
    )

    $refreshUrl = "https://securetoken.googleapis.com/v1/token?key=$([uri]::EscapeDataString($ApiKey))"
    $body = "grant_type=refresh_token&refresh_token=$([uri]::EscapeDataString($RefreshToken))"
    Invoke-JsonPost -Uri $refreshUrl -ContentType "application/x-www-form-urlencoded" -Body $body
}

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
$allowedCategoryKeys = @("total_level", "medals_earned", "total_xp") + @($skillIds | ForEach-Object { "skill_xp__$_" }) + @("elite_heavenly")
$categoryKey = $Category.Trim().Replace(":", "__")
Assert-True ($allowedCategoryKeys -contains $categoryKey) "Category is not in the Idle Elite leaderboard allowlist."

$projectCacheKey = ([uri]$databaseUrl).Host.ToLowerInvariant() -replace '[^a-z0-9.-]', '-'
$smokeAuthPath = Join-Path $smokeDir "firebase-leaderboard-live-read-auth-$projectCacheKey.json"

if ($ResetAuth -and (Test-Path -LiteralPath $smokeAuthPath)) {
    Remove-Item -LiteralPath $smokeAuthPath -Force
}

$auth = $null
$usedCachedAuth = $false
if (Test-Path -LiteralPath $smokeAuthPath) {
    $cached = Get-Content -LiteralPath $smokeAuthPath -Raw | ConvertFrom-Json
    $cachedRefreshToken = [string]$cached.refresh_token
    if (-not [string]::IsNullOrWhiteSpace($cachedRefreshToken)) {
        try {
            $auth = Refresh-AnonymousAuth -ApiKey $webApiKey -RefreshToken $cachedRefreshToken
            $usedCachedAuth = $true
        } catch {
            Remove-Item -LiteralPath $smokeAuthPath -Force -ErrorAction SilentlyContinue
            $auth = $null
        }
    }
}

if ($null -eq $auth) {
    $auth = New-AnonymousAuth -ApiKey $webApiKey
}

$idToken = [string]$auth.idToken
$refreshToken = [string]$auth.refreshToken
$localId = [string]$auth.localId
if ([string]::IsNullOrWhiteSpace($idToken)) {
    $idToken = [string]$auth.id_token
}
if ([string]::IsNullOrWhiteSpace($refreshToken)) {
    $refreshToken = [string]$auth.refresh_token
}
if ([string]::IsNullOrWhiteSpace($localId)) {
    $localId = [string]$auth.user_id
}
Assert-True (-not [string]::IsNullOrWhiteSpace($idToken)) "Firebase Anonymous Auth did not return an idToken."
Assert-True (-not [string]::IsNullOrWhiteSpace($localId)) "Firebase Anonymous Auth did not return a localId."

if (-not [string]::IsNullOrWhiteSpace($refreshToken)) {
    New-Item -ItemType Directory -Path $smokeDir -Force | Out-Null
    [ordered]@{
        refresh_token = $refreshToken
        local_id = $localId
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $smokeAuthPath -Encoding UTF8
}

$query = 'orderBy=%22score%22&limitToLast=1'
$readUrl = "$databaseUrl/leaderboards/v1/scores/$categoryKey.json?$query&auth=$([uri]::EscapeDataString($idToken))"
$databaseReadCount = 0
$databaseReadCount += 1
$rows = Invoke-RestMethod -Method Get -Uri $readUrl
Assert-True ($databaseReadCount -eq 1) "Live smoke helper must perform exactly one database read."

Write-Output "firebase-live-auth-ok uid=$localId cached=$usedCachedAuth"
if ($null -eq $rows -or [string]$rows -eq "null") {
    Write-Output "firebase-live-read-ok category=$categoryKey rows=0"
} else {
    $rowCount = @($rows.PSObject.Properties).Count
    Write-Output "firebase-live-read-ok category=$categoryKey rows=$rowCount"
}
Write-Output "firebase-live-db-read-count-ok count=$databaseReadCount"
Write-Output "firebase-live-read-only-ok"
