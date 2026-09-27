param(
    [Parameter(Mandatory = $true)][string]$DatabaseUrl,
    [Parameter(Mandatory = $true)][string]$WebApiKey,
    [Parameter(Mandatory = $true)][string]$GoogleWebClientId,
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$configPath = if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    Join-Path $projectRoot "firebase-leaderboard-config.json"
} else {
    $OutputPath
}

$cleanUrl = $DatabaseUrl.Trim().TrimEnd("/")
$cleanKey = $WebApiKey.Trim()
$cleanGoogleWebClientId = $GoogleWebClientId.Trim()
$firebaseDatabaseUrlPattern = '^https://([a-z0-9-]+\.firebaseio\.com|[a-z0-9-]+\.[a-z0-9-]+\.firebasedatabase\.app)$'

Assert-True ($cleanUrl -cmatch $firebaseDatabaseUrlPattern) "DatabaseUrl must be a lowercase Firebase Realtime Database URL like https://your-project-id-default-rtdb.firebaseio.com or https://your-project-id-default-rtdb.europe-west1.firebasedatabase.app"
Assert-True ($cleanUrl -notmatch 'your-project-id|YOUR-PROJECT') "DatabaseUrl still looks like a placeholder."
Assert-True ($cleanKey.Length -ge 20) "WebApiKey looks too short."
Assert-True ($cleanKey -ne "YOUR_FIREBASE_WEB_API_KEY") "WebApiKey is still the placeholder."
Assert-True ($cleanKey -notmatch '\s') "WebApiKey must not contain whitespace."
Assert-True (-not [string]::IsNullOrWhiteSpace($cleanGoogleWebClientId)) "GoogleWebClientId is required for account recovery and cloud save."
Assert-True ($cleanGoogleWebClientId -match '^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$') "GoogleWebClientId must look like an OAuth web client id ending in .apps.googleusercontent.com."

$config = [ordered]@{
    database_url = $cleanUrl
    web_api_key = $cleanKey
    google_web_client_id = $cleanGoogleWebClientId
}

$configDir = Split-Path -Parent $configPath
if (-not [string]::IsNullOrWhiteSpace($configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
Set-Content -LiteralPath $configPath -Value (($config | ConvertTo-Json -Depth 4) + "`n") -NoNewline -Encoding UTF8
Write-Output "firebase-leaderboard-config-written"
