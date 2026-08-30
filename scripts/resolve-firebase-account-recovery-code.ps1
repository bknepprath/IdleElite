param(
    [Parameter(Mandatory = $true)][string]$RecoveryCode,
    [Parameter(Mandatory = $true)][string]$AuthExportPath,
    [Parameter(Mandatory = $true)][string]$RtdbBackupPath
)

$ErrorActionPreference = "Stop"

function Assert-RecoveryCondition {
    param(
        [bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-RecoveryFingerprint {
    param([Parameter(Mandatory = $true)][string]$Value)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hex = [System.BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace("-", "").ToLowerInvariant()
        return $hex.Substring(0, 12)
    } finally {
        $sha256.Dispose()
    }
}

$cleanCode = $RecoveryCode.Trim()
Assert-RecoveryCondition ($cleanCode -match '^T-([a-f0-9]{12})\s+S-([a-f0-9]{12})$') "RecoveryCode must use the exact T-<12 hex> S-<12 hex> format shown in the game."
$targetFingerprint = [string]$Matches[1]
$sourceFingerprint = [string]$Matches[2]
Assert-RecoveryCondition ($targetFingerprint -cne $sourceFingerprint) "RecoveryCode target and source fingerprints must differ."

Assert-RecoveryCondition (Test-Path -LiteralPath $AuthExportPath -PathType Leaf) "AuthExportPath must point to a restricted Firebase Auth JSON export."
Assert-RecoveryCondition (Test-Path -LiteralPath $RtdbBackupPath -PathType Leaf) "RtdbBackupPath must point to a restricted Firebase RTDB JSON backup."
$authExport = Get-Content -LiteralPath $AuthExportPath -Raw | ConvertFrom-Json
$rtdbBackup = Get-Content -LiteralPath $RtdbBackupPath -Raw | ConvertFrom-Json
Assert-RecoveryCondition ($null -ne $authExport -and $null -ne $authExport.PSObject.Properties['users'] -and $authExport.users -is [System.Array]) "The Auth export must contain a users array."
Assert-RecoveryCondition ($null -ne $rtdbBackup) "The RTDB backup is empty or invalid."

$seenAuthUids = [System.Collections.Generic.Dictionary[string, bool]]::new([System.StringComparer]::Ordinal)
$targetMatches = @()
foreach ($authUser in @($authExport.users)) {
    $validObject = $null -ne $authUser -and $null -ne $authUser.PSObject.Properties['localId'] -and $authUser.localId -is [string]
    Assert-RecoveryCondition $validObject "The Auth export contains a malformed user record."
    $uid = [string]$authUser.localId
    $disabledProperty = $authUser.PSObject.Properties['disabled']
    Assert-RecoveryCondition (-not [string]::IsNullOrWhiteSpace($uid) -and $uid.Length -le 128) "The Auth export contains an invalid user identifier."
    Assert-RecoveryCondition ($null -eq $disabledProperty -or $disabledProperty.Value -is [bool]) "The Auth export contains a malformed disabled status."
    Assert-RecoveryCondition (-not $seenAuthUids.ContainsKey($uid)) "The Auth export contains a duplicate user identifier."
    $seenAuthUids[$uid] = $true
    if ($null -ne $disabledProperty -and [bool]$disabledProperty.Value) {
        continue
    }
    if ((Get-RecoveryFingerprint -Value $uid) -ceq $targetFingerprint) {
        $targetMatches += $uid
    }
}
Assert-RecoveryCondition ($targetMatches.Count -eq 1) "RecoveryCode target fingerprint did not resolve to exactly one active Auth user."
$targetUid = [string]$targetMatches[0]
Assert-RecoveryCondition ($targetUid -match '^[A-Za-z0-9_-]{8,48}$') "RecoveryCode target is not a client-compatible Firebase user."

$claims = $null
if ($null -ne $rtdbBackup.PSObject.Properties['leaderboards']) {
    $leaderboards = $rtdbBackup.leaderboards
    if ($null -ne $leaderboards -and $null -ne $leaderboards.PSObject.Properties['v1']) {
        $leaderboardsV1 = $leaderboards.v1
        if ($null -ne $leaderboardsV1 -and $null -ne $leaderboardsV1.PSObject.Properties['name_claims']) {
            $claims = $leaderboardsV1.name_claims
        }
    }
}
Assert-RecoveryCondition ($null -ne $claims) "The RTDB backup does not contain leaderboard name claims."

$sourceMatches = @()
$targetClaimCount = 0
foreach ($property in @($claims.PSObject.Properties)) {
    $claim = $property.Value
    if ($null -eq $claim -or $null -eq $claim.PSObject.Properties['uid']) {
        continue
    }
    $uid = [string]$claim.uid
    if ($uid -ceq $targetUid) {
        $targetClaimCount += 1
    }
    if ($uid -match '^[A-Za-z0-9_-]{8,48}$' -and (Get-RecoveryFingerprint -Value $uid) -ceq $sourceFingerprint) {
        $nameKey = [string]$property.Name
        $displayName = [string]$claim.name
        $claimNameKey = [string]$claim.name_key
        $avatarIndex = -1
        $avatarIsInteger = [int]::TryParse([string]$claim.avatar_index, [ref]$avatarIndex)
        Assert-RecoveryCondition (
            $nameKey -match '^[a-z0-9_]{1,16}$' -and
            $claimNameKey -ceq $nameKey -and
            -not [string]::IsNullOrWhiteSpace($displayName) -and
            $displayName.Length -le 16 -and
            $avatarIsInteger -and
            $avatarIndex -ge 0 -and
            $avatarIndex -le 19
        ) "The uniquely fingerprinted source claim is malformed and requires manual review."
        $sourceMatches += [pscustomobject]@{
            uid = $uid
            name_key = $nameKey
            display_name = $displayName
            avatar_index = $avatarIndex
        }
    }
}
Assert-RecoveryCondition ($sourceMatches.Count -eq 1) "RecoveryCode source fingerprint did not resolve to exactly one RTDB name claim."
Assert-RecoveryCondition ($targetClaimCount -eq 0) "The target Auth user already owns an RTDB name claim and requires manual support review."
$sourceMatch = $sourceMatches[0]
Assert-RecoveryCondition ([string]$sourceMatch.uid -cne $targetUid) "RecoveryCode resolved to the same target and source user."
Assert-RecoveryCondition (-not $seenAuthUids.ContainsKey([string]$sourceMatch.uid)) "The source identifier still exists in Firebase Auth and cannot use the deleted/authless transfer workflow."

$targetProfileExists = $false
$profiles = $leaderboardsV1.profiles_by_uid
if ($null -ne $profiles) {
    foreach ($property in @($profiles.PSObject.Properties)) {
        if ([string]$property.Name -ceq $targetUid) {
            $targetProfileExists = $true
            break
        }
    }
}
Assert-RecoveryCondition (-not $targetProfileExists) "The target Auth user already has a canonical profile and requires manual support review."

# This is the only output containing raw identifiers. It is emitted only after
# both restricted snapshots resolve uniquely and target conflicts are absent.
[pscustomobject]@{
    status = "unique-match"
    target_uid = $targetUid
    source_uid = [string]$sourceMatch.uid
    name_key = [string]$sourceMatch.name_key
    display_name = [string]$sourceMatch.display_name
    avatar_index = [int]$sourceMatch.avatar_index
}
