param(
    [Parameter(Mandatory = $true)][string]$ModeratorIdToken,
    [int]$Limit = 25
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot "firebase-leaderboard-config.json"
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

$cleanToken = $ModeratorIdToken.Trim()
$safeLimit = [Math]::Min([Math]::Max($Limit, 1), 25)
Assert-True (Test-Path -LiteralPath $configPath) "Missing firebase-leaderboard-config.json."

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$databaseUrl = ([string]$config.database_url).Trim().TrimEnd("/")
Assert-True ($databaseUrl -cmatch $firebaseDatabaseUrlPattern) "Invalid database_url in firebase-leaderboard-config.json."

$query = 'orderBy=%22created_at%22&limitToLast={0}&auth={1}' -f $safeLimit, ([uri]::EscapeDataString($cleanToken))
$url = "$databaseUrl/global_chat/v1/messages.json?$query"
$messages = Invoke-RestMethod -Method Get -Uri $url
if ($null -eq $messages) {
    Write-Output "firebase-chat-messages-empty"
    return
}

$rows = @()
$messages.PSObject.Properties | ForEach-Object {
    $value = $_.Value
    $rows += [pscustomobject]@{
        id = $_.Name
        created_at = [int64]$value.created_at
        name = [string]$value.name
        sender_id = [string]$value.sender_id
        deleted = [bool]$value.deleted
        text = [string]$value.text
    }
}

$rows | Sort-Object created_at | Format-Table -AutoSize
