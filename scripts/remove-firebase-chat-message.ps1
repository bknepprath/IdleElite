param(
    [Parameter(Mandatory = $true)][string]$MessageId,
    [Parameter(Mandatory = $true)][string]$ModeratorIdToken,
    [Parameter(Mandatory = $true)][string]$Reason
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

function ConvertFrom-Base64UrlJson {
    param([Parameter(Mandatory = $true)][string]$Base64Url)

    $padded = $Base64Url.Replace('-', '+').Replace('_', '/')
    while ($padded.Length % 4 -ne 0) {
        $padded += "="
    }
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($padded)) | ConvertFrom-Json
}

$cleanMessageId = $MessageId.Trim()
$cleanToken = $ModeratorIdToken.Trim()
$cleanReason = $Reason.Trim()

Assert-True ($cleanMessageId -match '^[A-Za-z0-9_-]{8,64}$') "MessageId must be a Firebase-safe chat message id."
Assert-True ($cleanToken.Split('.').Count -eq 3) "ModeratorIdToken must be a Firebase Auth ID token."
Assert-True ($cleanReason.Length -gt 0 -and $cleanReason.Length -le 160) "Reason must be 1..160 characters."
Assert-True (Test-Path -LiteralPath $configPath) "Missing firebase-leaderboard-config.json."

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$databaseUrl = ([string]$config.database_url).Trim().TrimEnd("/")
Assert-True ($databaseUrl -cmatch $firebaseDatabaseUrlPattern) "Invalid database_url in firebase-leaderboard-config.json."

$payload = ConvertFrom-Base64UrlJson -Base64Url $cleanToken.Split('.')[1]
$moderatorUid = [string]$payload.user_id
if ([string]::IsNullOrWhiteSpace($moderatorUid)) {
    $moderatorUid = [string]$payload.sub
}
Assert-True (-not [string]::IsNullOrWhiteSpace($moderatorUid)) "Could not read moderator uid from token payload."

$auth = [uri]::EscapeDataString($cleanToken)
$messageUrl = "$databaseUrl/global_chat/v1/messages/$cleanMessageId.json?auth=$auth"
$message = Invoke-RestMethod -Method Get -Uri $messageUrl
Assert-True ($null -ne $message) "Chat message '$cleanMessageId' was not found."
Assert-True (-not [bool]$message.deleted) "Chat message '$cleanMessageId' is already deleted."

$message.deleted = $true
$message | Add-Member -NotePropertyName deleted_at -NotePropertyValue @{ ".sv" = "timestamp" } -Force
$message | Add-Member -NotePropertyName deleted_by -NotePropertyValue $moderatorUid -Force

$logId = "mod_{0}_{1}" -f ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()), ([Guid]::NewGuid().ToString("N").Substring(0, 12))
$updates = [ordered]@{
    "messages/$cleanMessageId" = $message
    "moderation_logs/$logId" = [ordered]@{
        message_id = $cleanMessageId
        moderator_id = $moderatorUid
        reason = $cleanReason
        created_at = @{ ".sv" = "timestamp" }
        created_at_unix = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    }
}

$updateUrl = "$databaseUrl/global_chat/v1.json?print=silent&auth=$auth"
$body = $updates | ConvertTo-Json -Depth 12
Invoke-RestMethod -Method Patch -Uri $updateUrl -ContentType "application/json" -Body $body | Out-Null
Write-Output "firebase-chat-message-removed id=$cleanMessageId log=$logId"
