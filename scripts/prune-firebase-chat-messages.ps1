param(
    [Parameter(Mandatory = $true)][string]$ProjectId,
    [int]$Keep = 50,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

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
$safeKeep = [Math]::Min([Math]::Max($Keep, 1), 500)
Assert-True ($cleanProjectId -match '^[a-z][a-z0-9-]{4,29}$') "ProjectId should be the Firebase project id, for example idle-elite."

$firebaseCommand = Get-Command firebase -ErrorAction SilentlyContinue
Assert-True ($null -ne $firebaseCommand) "Firebase CLI was not found. Install it or prune from the Firebase console."

$raw = & firebase database:get /global_chat/v1/messages --project $cleanProjectId
if ($LASTEXITCODE -ne 0) {
    throw "firebase database:get failed."
}
if ([string]::IsNullOrWhiteSpace($raw) -or $raw.Trim() -eq "null") {
    Write-Output "firebase-chat-prune-empty"
    return
}

$messages = $raw | ConvertFrom-Json
$rows = @()
$messages.PSObject.Properties | ForEach-Object {
    $id = [string]$_.Name
    Assert-True ($id -match '^[A-Za-z0-9_-]{8,64}$') "Unexpected message id '$id'."
    $value = $_.Value
    $createdAt = 0L
    if ($null -ne $value.created_at) {
        $createdAt = [int64]$value.created_at
    }
    $rows += [pscustomobject]@{
        id = $id
        created_at = $createdAt
    }
}

$ordered = @($rows | Sort-Object created_at, id)
if ($ordered.Count -le $safeKeep) {
    Write-Output ("firebase-chat-prune-none count={0} keep={1}" -f $ordered.Count, $safeKeep)
    return
}

$removeCount = $ordered.Count - $safeKeep
$toRemove = @($ordered | Select-Object -First $removeCount)
Write-Output ("firebase-chat-prune-plan total={0} keep={1} remove={2}" -f $ordered.Count, $safeKeep, $toRemove.Count)

foreach ($row in $toRemove) {
    $path = "/global_chat/v1/messages/$($row.id)"
    if ($DryRun) {
        Write-Output "dry-run remove $path"
        continue
    }
    & firebase database:remove $path --project $cleanProjectId --force | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "firebase database:remove failed for $path"
    }
    Write-Output "removed $path"
}

