$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$configPath = Join-Path $projectRoot "firebase-leaderboard-config.json"
$firebaseJsonPath = Join-Path $projectRoot "firebase.json"
$rulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"
$gitignorePath = Join-Path $projectRoot ".gitignore"
$firebaseDatabaseUrlPattern = '^https://([a-z0-9-]+\.firebaseio\.com|[a-z0-9-]+\.[a-z0-9-]+\.firebasedatabase\.app)$'

Assert-True (Test-Path -LiteralPath $firebaseJsonPath) "Missing firebase.json."
Assert-True (Test-Path -LiteralPath $rulesPath) "Missing firebase-realtime-database.rules.json."
Assert-True (Test-Path -LiteralPath $gitignorePath) "Missing .gitignore."

$firebaseJson = Get-Content -LiteralPath $firebaseJsonPath -Raw | ConvertFrom-Json
Assert-True ([string]$firebaseJson.database.rules -eq "firebase-realtime-database.rules.json") "firebase.json must point at the leaderboard Realtime Database rules file."

$gitignore = Get-Content -LiteralPath $gitignorePath -Raw
Assert-True ($gitignore -match '(?m)^firebase-leaderboard-config\.json$') "firebase-leaderboard-config.json must stay ignored by git."

& (Join-Path $projectRoot "scripts\update-firebase-leaderboard-rules.ps1") -Check
Write-Output "firebase-setup-state-rules-current"

if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Output "firebase-setup-state-config-absent"
    Write-Output "firebase-setup-next-step=publish-rules-then-write-local-config"
    exit 0
}

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$databaseUrl = ([string]$config.database_url).Trim().TrimEnd("/")
$webApiKey = ([string]$config.web_api_key).Trim()
$googleWebClientId = ([string]$config.google_web_client_id).Trim()

Assert-True ($databaseUrl -cmatch $firebaseDatabaseUrlPattern) "firebase-leaderboard-config.json has an invalid database_url."
Assert-True ($databaseUrl -notmatch 'your-project-id|YOUR-PROJECT|your_project') "firebase-leaderboard-config.json still contains a placeholder database_url."
Assert-True ($webApiKey.Length -ge 20) "firebase-leaderboard-config.json has an invalid web_api_key."
Assert-True ($webApiKey -ne "YOUR_FIREBASE_WEB_API_KEY") "firebase-leaderboard-config.json still contains a placeholder web_api_key."
Assert-True ($webApiKey -notmatch '\s') "firebase-leaderboard-config.json web_api_key must not contain whitespace."
if (-not [string]::IsNullOrWhiteSpace($googleWebClientId)) {
    Assert-True ($googleWebClientId -match '^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$') "firebase-leaderboard-config.json has an invalid google_web_client_id."
}

Write-Output "firebase-setup-state-config-ok"
Write-Output "firebase-setup-next-step=run-read-only-live-smoke"
