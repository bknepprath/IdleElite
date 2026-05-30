param(
    [Parameter(Mandatory = $true)][string]$DatabaseUrl,
    [Parameter(Mandatory = $true)][string]$WebApiKey,
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    Join-Path $projectRoot "firebase-leaderboard-config.json"
} else {
    $OutputPath
}

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

$cleanUrl = $DatabaseUrl.Trim().TrimEnd("/")
$cleanKey = $WebApiKey.Trim()
$firebaseDatabaseUrlPattern = '^https://([a-z0-9-]+\.firebaseio\.com|[a-z0-9-]+\.[a-z0-9-]+\.firebasedatabase\.app)$'

Assert-True ($cleanUrl -cmatch $firebaseDatabaseUrlPattern) "DatabaseUrl must be a lowercase Firebase Realtime Database URL like https://your-project-id-default-rtdb.firebaseio.com or https://your-project-id-default-rtdb.europe-west1.firebasedatabase.app"
Assert-True ($cleanUrl -notmatch 'your-project-id|YOUR-PROJECT') "DatabaseUrl still looks like a placeholder."
Assert-True ($cleanKey.Length -ge 20) "WebApiKey looks too short."
Assert-True ($cleanKey -ne "YOUR_FIREBASE_WEB_API_KEY") "WebApiKey is still the placeholder."
Assert-True ($cleanKey -notmatch '\s') "WebApiKey must not contain whitespace."

$config = [ordered]@{
    database_url = $cleanUrl
    web_api_key = $cleanKey
}

$configDir = Split-Path -Parent $configPath
if (-not [string]::IsNullOrWhiteSpace($configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
Set-Content -LiteralPath $configPath -Value (($config | ConvertTo-Json -Depth 4) + "`n") -NoNewline -Encoding UTF8
Write-Output "firebase-leaderboard-config-written"
