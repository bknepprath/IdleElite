param(
    [Parameter(Mandatory = $true)][string]$ProjectId,
    [Parameter(Mandatory = $true)][string]$AuthExportPath,
    [string]$RtdbBackupPath,
    [Alias("PlayerWritesPaused")][switch]$ConfirmWritesPaused,
    [switch]$Apply
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

function Get-IdentifierFingerprint {
    param([AllowEmptyString()][string]$Value)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        $hex = [System.BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace("-", "").ToLowerInvariant()
        return "sha256:$($hex.Substring(0, 12))"
    } finally {
        $sha256.Dispose()
    }
}

function Test-JsonNumber {
    param($Value)

    return (
        $Value -is [byte] -or $Value -is [sbyte] -or
        $Value -is [int16] -or $Value -is [uint16] -or
        $Value -is [int32] -or $Value -is [uint32] -or
        $Value -is [int64] -or $Value -is [uint64] -or
        $Value -is [single] -or $Value -is [double] -or $Value -is [decimal]
    )
}

function Test-JsonIntegerInRange {
    param(
        $Value,
        [long]$Minimum,
        [long]$Maximum
    )

    if (-not (Test-JsonNumber -Value $Value)) {
        return $false
    }
    $numericValue = [double]$Value
    return (
        -not [double]::IsNaN($numericValue) -and
        -not [double]::IsInfinity($numericValue) -and
        [Math]::Truncate($numericValue) -eq $numericValue -and
        $numericValue -ge $Minimum -and
        $numericValue -le $Maximum
    )
}

function Get-ClientNameKey {
    param([AllowEmptyString()][string]$DisplayName)

    # Conservative PowerShell equivalent of LeaderboardProfile.make_name_key.
    # .NET counts UTF-16 units, so a non-BMP name near the limit is rejected
    # instead of risking a key that the Godot client would derive differently.
    $clean = $DisplayName.Trim()
    $clean = $clean.Replace("`n", " ").Replace("`r", " ").Replace("`t", " ")
    while ($clean.Contains("  ")) {
        $clean = $clean.Replace("  ", " ")
    }
    if ($clean.Length -gt 16) {
        $clean = $clean.Substring(0, 16).Trim()
    }
    $clean = $clean.ToLowerInvariant()
    $builder = [System.Text.StringBuilder]::new()
    $lastWasSeparator = $false
    foreach ($character in $clean.ToCharArray()) {
        $code = [int][char]$character
        $isDigit = $code -ge 48 -and $code -le 57
        $isLower = $code -ge 97 -and $code -le 122
        if ($isDigit -or $isLower) {
            [void]$builder.Append($character)
            $lastWasSeparator = $false
        } elseif (($code -eq 32 -or $code -eq 45 -or $code -eq 95) -and $builder.Length -gt 0 -and -not $lastWasSeparator) {
            [void]$builder.Append('_')
            $lastWasSeparator = $true
        }
    }
    $key = $builder.ToString().TrimEnd('_')
    if ($key -notmatch '^[a-z0-9_]{1,16}$') {
        return ""
    }
    return $key
}

function Test-ClaimMatchesPlan {
    param(
        $Claim,
        [Parameter(Mandatory = $true)]$Expected
    )

    if ($null -eq $Claim) {
        return $false
    }
    $avatarValue = $Claim.avatar_index
    return (
        [string]$Claim.uid -ceq [string]$Expected.uid -and
        [string]$Claim.name -ceq [string]$Expected.display_name -and
        [string]$Claim.name_key -ceq [string]$Expected.name_key -and
        (Get-ClientNameKey -DisplayName ([string]$Claim.name)) -ceq [string]$Expected.name_key -and
        (Test-JsonIntegerInRange -Value $avatarValue -Minimum 0 -Maximum 19) -and
        [int]$avatarValue -eq [int]$Expected.avatar_index
    )
}

function Test-CanonicalProfileMatchesPlan {
    param(
        $Profile,
        [Parameter(Mandatory = $true)]$Expected
    )

    if ($null -eq $Profile) {
        return $false
    }
    $requiredFields = @('uid', 'display_name', 'name_key', 'avatar_index', 'profile_claimed', 'name_claim_verified', 'auth_provider', 'updated_at', 'updated_at_unix')
    $propertyNames = @($Profile.PSObject.Properties | ForEach-Object { [string]$_.Name })
    if ($propertyNames.Count -ne $requiredFields.Count) {
        return $false
    }
    foreach ($field in $requiredFields) {
        if (-not ($propertyNames -ccontains $field)) {
            return $false
        }
    }
    $avatarValue = $Profile.avatar_index
    $updatedAt = $Profile.updated_at
    $updatedAtUnix = $Profile.updated_at_unix
    return (
        [string]$Profile.uid -ceq [string]$Expected.uid -and
        [string]$Profile.display_name -ceq [string]$Expected.display_name -and
        [string]$Profile.name_key -ceq [string]$Expected.name_key -and
        (Get-ClientNameKey -DisplayName ([string]$Profile.display_name)) -ceq [string]$Expected.name_key -and
        (Test-JsonIntegerInRange -Value $avatarValue -Minimum 0 -Maximum 19) -and
        [int]$avatarValue -eq [int]$Expected.avatar_index -and
        $Profile.profile_claimed -is [bool] -and $Profile.profile_claimed -eq $true -and
        $Profile.name_claim_verified -is [bool] -and $Profile.name_claim_verified -eq $true -and
        ([string]$Profile.auth_provider -ceq 'anonymous' -or [string]$Profile.auth_provider -ceq 'google') -and
        (Test-JsonIntegerInRange -Value $updatedAt -Minimum 1 -Maximum ([long]::MaxValue)) -and
        (Test-JsonIntegerInRange -Value $updatedAtUnix -Minimum 1 -Maximum ([long]::MaxValue))
    )
}

$cleanProjectId = $ProjectId.Trim()
Assert-True ($cleanProjectId -match '^[a-z][a-z0-9-]{4,29}$') "ProjectId should be the Firebase project id, for example idle-elite."
if ($Apply) {
    Assert-True ([bool]$ConfirmWritesPaused) "Apply requires -ConfirmWritesPaused after player profile writes have actually been paused for the reconciliation window."
    Assert-True ([string]::IsNullOrWhiteSpace($RtdbBackupPath)) "Apply must read Firebase directly and cannot use -RtdbBackupPath."
}

Assert-True (Test-Path -LiteralPath $AuthExportPath -PathType Leaf) "AuthExportPath must point to a Firebase Auth JSON export."
$authExport = Get-Content -LiteralPath $AuthExportPath -Raw | ConvertFrom-Json
Assert-True ($null -ne $authExport -and $null -ne $authExport.PSObject.Properties['users'] -and $authExport.users -is [System.Array]) "AuthExportPath must contain a JSON object with a users array."
$authByUid = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
$disabledAuthByUid = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
$invalidAuthUserCount = 0
foreach ($authUser in @($authExport.users)) {
    if ($null -eq $authUser -or $null -eq $authUser.PSObject.Properties['localId'] -or $authUser.localId -isnot [string]) {
        $invalidAuthUserCount += 1
        continue
    }
    $authUid = [string]$authUser.localId
    $disabledProperty = $authUser.PSObject.Properties['disabled']
    $disabledMalformed = $null -ne $disabledProperty -and $disabledProperty.Value -isnot [bool]
    if (
        [string]::IsNullOrWhiteSpace($authUid) -or
        $authUid.Length -gt 128 -or
        $disabledMalformed -or
        $authByUid.ContainsKey($authUid) -or
        $disabledAuthByUid.ContainsKey($authUid)
    ) {
        $invalidAuthUserCount += 1
        continue
    }
    if ($null -ne $disabledProperty -and [bool]$disabledProperty.Value) {
        $disabledAuthByUid[$authUid] = $authUser
    } else {
        $authByUid[$authUid] = $authUser
    }
}
if ($invalidAuthUserCount -gt 0) {
    Write-Output ("firebase-profile-backfill-refused malformed_or_duplicate_auth_users={0}" -f $invalidAuthUserCount)
    throw "The Firebase Auth export contains malformed, overlong, or duplicate user records. No writes were attempted."
}

function Read-FirebasePath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$SafeLabel
    )

    $raw = & firebase database:get $Path --project $cleanProjectId
    if ($LASTEXITCODE -ne 0) {
        throw "firebase database:get failed for $SafeLabel"
    }
    if ([string]::IsNullOrWhiteSpace($raw) -or $raw.Trim() -eq "null") {
        return $null
    }
    return $raw | ConvertFrom-Json
}

$claims = $null
$profiles = $null
if ([string]::IsNullOrWhiteSpace($RtdbBackupPath)) {
    $firebaseCommand = Get-Command firebase -ErrorAction SilentlyContinue
    Assert-True ($null -ne $firebaseCommand) "Firebase CLI was not found. Install it or use -RtdbBackupPath for a read-only offline audit."
    $claims = Read-FirebasePath -Path "/leaderboards/v1/name_claims" -SafeLabel "name-claims root"
    $profiles = Read-FirebasePath -Path "/leaderboards/v1/profiles_by_uid" -SafeLabel "canonical-profiles root"
} else {
    Assert-True (Test-Path -LiteralPath $RtdbBackupPath -PathType Leaf) "RtdbBackupPath must point to a Firebase RTDB JSON backup."
    $rtdbBackup = Get-Content -LiteralPath $RtdbBackupPath -Raw | ConvertFrom-Json
    Assert-True ($null -ne $rtdbBackup -and $rtdbBackup -is [pscustomobject]) "RtdbBackupPath must contain a JSON object."
    $leaderboardsProperty = $rtdbBackup.PSObject.Properties['leaderboards']
    if ($null -ne $leaderboardsProperty -and $null -ne $leaderboardsProperty.Value) {
        $v1Property = $leaderboardsProperty.Value.PSObject.Properties['v1']
        if ($null -ne $v1Property -and $null -ne $v1Property.Value) {
            $claimsProperty = $v1Property.Value.PSObject.Properties['name_claims']
            $profilesProperty = $v1Property.Value.PSObject.Properties['profiles_by_uid']
            if ($null -ne $claimsProperty) {
                $claims = $claimsProperty.Value
            }
            if ($null -ne $profilesProperty) {
                $profiles = $profilesProperty.Value
            }
        }
    }
}

$existingByUid = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
if ($null -ne $profiles) {
    foreach ($property in $profiles.PSObject.Properties) {
        $existingByUid[[string]$property.Name] = $property.Value
    }
}

$claimsByUid = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
$invalidClaims = @()
foreach ($property in @(if ($null -eq $claims) { @() } else { $claims.PSObject.Properties })) {
    $nameKey = [string]$property.Name
    $claim = $property.Value
    $uid = [string]$claim.uid
    $displayName = [string]$claim.name
    $claimNameKey = [string]$claim.name_key
    $avatarValue = $claim.avatar_index
    $avatarIndex = -1
    if (Test-JsonIntegerInRange -Value $avatarValue -Minimum 0 -Maximum 19) {
        $avatarIndex = [int]$claim.avatar_index
    }
    $derivedNameKey = Get-ClientNameKey -DisplayName $displayName
    $valid = (
        $nameKey -match '^[a-z0-9_]{1,16}$' -and
        $uid -match '^[A-Za-z0-9_-]{8,48}$' -and
        $claimNameKey -ceq $nameKey -and
        $derivedNameKey -ceq $nameKey -and
        -not [string]::IsNullOrWhiteSpace($displayName) -and
        $displayName.Length -le 16 -and
        $avatarIndex -ge 0 -and
        $avatarIndex -le 19
    )
    if (-not $valid) {
        $invalidClaims += $nameKey
        continue
    }
    if (-not $claimsByUid.ContainsKey($uid)) {
        $claimsByUid[$uid] = @()
    }
    $claimsByUid[$uid] += [pscustomobject]@{
        uid = $uid
        display_name = $displayName
        name_key = $nameKey
        avatar_index = $avatarIndex
    }
}

$ambiguousUids = @($claimsByUid.Keys | Where-Object { @($claimsByUid[$_]).Count -ne 1 } | Sort-Object)
if ($invalidClaims.Count -gt 0 -or $ambiguousUids.Count -gt 0) {
    Write-Output ("firebase-profile-backfill-refused invalid_claims={0} ambiguous_uids={1}" -f $invalidClaims.Count, $ambiguousUids.Count)
    foreach ($uid in $ambiguousUids) {
        Write-Output ("ambiguous uid_fingerprint={0} claim_count={1}" -f (Get-IdentifierFingerprint -Value $uid), @($claimsByUid[$uid]).Count)
    }
    throw "Resolve invalid or duplicate claims before backfilling canonical profiles. No writes were attempted."
}

$legacyAuthlessPattern = '^p[a-f0-9]{32}$'
$legacyAuthlessByUid = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
$missingAuthByUid = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
$disabledReferencedByUid = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
$legacyCanonicalConflictsByUid = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
foreach ($uid in @($claimsByUid.Keys)) {
    if ($authByUid.ContainsKey($uid)) {
        continue
    }
    if ($disabledAuthByUid.ContainsKey($uid)) {
        $disabledReferencedByUid[$uid] = $true
        continue
    }
    if ($uid -cmatch $legacyAuthlessPattern) {
        $legacyAuthlessByUid[$uid] = $true
    } else {
        $missingAuthByUid[$uid] = $true
    }
}
foreach ($uid in @($existingByUid.Keys)) {
    if ($authByUid.ContainsKey($uid)) {
        continue
    }
    if ($disabledAuthByUid.ContainsKey($uid)) {
        $disabledReferencedByUid[$uid] = $true
        continue
    }
    if ($uid -cmatch $legacyAuthlessPattern) {
        $legacyCanonicalConflictsByUid[$uid] = $true
    } else {
        $missingAuthByUid[$uid] = $true
    }
}

Write-Output ("firebase-profile-backfill-auth-plan active_auth_users={0} disabled_auth_users={1} claims={2} existing={3} legacy_authless={4} missing_auth={5} disabled_referenced={6} legacy_canonical_conflicts={7} writes_paused={8} reconciliation={9} apply={10}" -f $authByUid.Count, $disabledAuthByUid.Count, $claimsByUid.Count, $existingByUid.Count, $legacyAuthlessByUid.Count, $missingAuthByUid.Count, $disabledReferencedByUid.Count, $legacyCanonicalConflictsByUid.Count, [bool]$ConfirmWritesPaused, $(if ($ConfirmWritesPaused) { 'authoritative-paused-window' } else { 'exploratory-writes-not-confirmed' }), [bool]$Apply)
foreach ($uid in @($legacyAuthlessByUid.Keys | Sort-Object)) {
    Write-Output ("legacy-authless uid_fingerprint={0} canonical=skipped action=google-transition-with-admin-ticket" -f (Get-IdentifierFingerprint -Value $uid))
}
if ($missingAuthByUid.Count -gt 0 -or $disabledReferencedByUid.Count -gt 0 -or $legacyCanonicalConflictsByUid.Count -gt 0) {
    Write-Output ("firebase-profile-backfill-refused missing_auth_uids={0} disabled_referenced_uids={1} legacy_canonical_conflicts={2}" -f $missingAuthByUid.Count, $disabledReferencedByUid.Count, $legacyCanonicalConflictsByUid.Count)
    foreach ($uid in @($missingAuthByUid.Keys | Sort-Object)) {
        Write-Output ("missing-auth uid_fingerprint={0} canonical=refused" -f (Get-IdentifierFingerprint -Value $uid))
    }
    foreach ($uid in @($disabledReferencedByUid.Keys | Sort-Object)) {
        Write-Output ("disabled-auth uid_fingerprint={0} canonical=refused" -f (Get-IdentifierFingerprint -Value $uid))
    }
    foreach ($uid in @($legacyCanonicalConflictsByUid.Keys | Sort-Object)) {
        Write-Output ("legacy-authless-cleanup-conflict uid_fingerprint={0}" -f (Get-IdentifierFingerprint -Value $uid))
    }
    throw "Every non-placeholder canonical or claimed UID must be an active Firebase Auth user, and legacy authless canonical profiles must be removed after review. No writes were attempted."
}

$orphanProfileUids = @()
$conflictingProfileUids = @()
foreach ($uid in @($existingByUid.Keys | Sort-Object)) {
    if (-not $claimsByUid.ContainsKey($uid) -or @($claimsByUid[$uid]).Count -ne 1) {
        $orphanProfileUids += $uid
        continue
    }
    $expectedClaim = @($claimsByUid[$uid])[0]
    if (-not (Test-CanonicalProfileMatchesPlan -Profile $existingByUid[$uid] -Expected $expectedClaim)) {
        $conflictingProfileUids += $uid
    }
}
if ($orphanProfileUids.Count -gt 0 -or $conflictingProfileUids.Count -gt 0) {
    Write-Output ("firebase-profile-backfill-refused orphan_profiles={0} existing_conflicts={1}" -f $orphanProfileUids.Count, $conflictingProfileUids.Count)
    foreach ($uid in @($orphanProfileUids | Sort-Object)) {
        Write-Output ("canonical-orphan uid_fingerprint={0}" -f (Get-IdentifierFingerprint -Value $uid))
    }
    foreach ($uid in @($conflictingProfileUids | Sort-Object)) {
        Write-Output ("canonical-conflict uid_fingerprint={0}" -f (Get-IdentifierFingerprint -Value $uid))
    }
    throw "Every existing canonical profile must have exactly one matching validated name claim. No writes were attempted."
}

$nowMsec = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$nowUnix = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$createRecords = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
foreach ($uid in @($claimsByUid.Keys | Sort-Object)) {
    $claim = @($claimsByUid[$uid])[0]
    if ($legacyAuthlessByUid.ContainsKey($uid)) {
        continue
    }
    if ($existingByUid.ContainsKey($uid)) {
        continue
    }
    $providerIds = @($authByUid[$uid].providerUserInfo | ForEach-Object { [string]$_.providerId })
    $authProvider = if ($providerIds -ccontains 'google.com') { 'google' } else { 'anonymous' }
    $createRecords[$uid] = [ordered]@{
        uid = $uid
        display_name = $claim.display_name
        name_key = $claim.name_key
        avatar_index = $claim.avatar_index
        profile_claimed = $true
        name_claim_verified = $true
        auth_provider = $authProvider
        updated_at = $nowMsec
        updated_at_unix = $nowUnix
    }
}

Write-Output ("firebase-profile-backfill-plan active_auth_users={0} claims={1} existing={2} create={3} legacy_authless_skipped={4} writes_paused={5} reconciliation={6} apply={7}" -f $authByUid.Count, $claimsByUid.Count, $existingByUid.Count, $createRecords.Count, $legacyAuthlessByUid.Count, [bool]$ConfirmWritesPaused, $(if ($ConfirmWritesPaused) { 'authoritative-paused-window' } else { 'exploratory-writes-not-confirmed' }), [bool]$Apply)
if (-not $Apply) {
    foreach ($uid in @($legacyAuthlessByUid.Keys | Sort-Object)) {
        Write-Output ("dry-run skip legacy-authless uid_fingerprint={0}" -f (Get-IdentifierFingerprint -Value $uid))
    }
    foreach ($uid in @($createRecords.Keys | Sort-Object)) {
        Write-Output ("dry-run create uid_fingerprint={0} auth_provider={1}" -f (Get-IdentifierFingerprint -Value $uid), $createRecords[$uid].auth_provider)
    }
    return
}

foreach ($uid in @($createRecords.Keys | Sort-Object)) {
    $fingerprint = Get-IdentifierFingerprint -Value $uid
    $plannedRecord = $createRecords[$uid]
    $claimPath = "/leaderboards/v1/name_claims/$($plannedRecord.name_key)"
    $currentClaim = Read-FirebasePath -Path $claimPath -SafeLabel "name claim for uid_fingerprint=$fingerprint"
    if (-not (Test-ClaimMatchesPlan -Claim $currentClaim -Expected $plannedRecord)) {
        throw "Refusing a stale plan because the source claim changed after reconciliation for uid_fingerprint=$fingerprint."
    }
    $path = "/leaderboards/v1/profiles_by_uid/$uid"
    $current = Read-FirebasePath -Path $path -SafeLabel "canonical profile for uid_fingerprint=$fingerprint"
    if ($null -ne $current) {
        throw "Refusing to overwrite a profile created after reconciliation for uid_fingerprint=$fingerprint."
    }
    $json = $plannedRecord | ConvertTo-Json -Compress
    & firebase database:set $path --project $cleanProjectId --data $json --force | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "firebase database:set failed for uid_fingerprint=$fingerprint"
    }
    Write-Output "created canonical-profile uid_fingerprint=$fingerprint"
}

Write-Output ("firebase-profile-backfill-applied count={0}" -f $createRecords.Count)
