param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backfillPath = Join-Path $PSScriptRoot "backfill-firebase-profiles-by-uid.ps1"
$testRoot = Join-Path $projectRoot ".codex-tmp\firebase-profile-backfill-test"
$authPath = Join-Path $testRoot "auth-export.json"
$cleanRtdbPath = Join-Path $testRoot "clean-rtdb.json"
$invalidRtdbPath = Join-Path $testRoot "invalid-rtdb.json"
$powerShellPath = (Get-Process -Id $PID).Path

function Assert-BackfillTest {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function New-CanonicalProfile {
    param(
        [Parameter(Mandatory = $true)][string]$Uid,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][string]$NameKey,
        [int]$AvatarIndex = 0
    )

    return [ordered]@{
        uid = $Uid
        display_name = $DisplayName
        name_key = $NameKey
        avatar_index = $AvatarIndex
        profile_claimed = $true
        name_claim_verified = $true
        auth_provider = "anonymous"
        updated_at = 1700000000000
        updated_at_unix = 1700000000
    }
}

function New-NameClaim {
    param(
        [Parameter(Mandatory = $true)][string]$Uid,
        [Parameter(Mandatory = $true)][string]$DisplayName,
        [Parameter(Mandatory = $true)][string]$NameKey,
        [int]$AvatarIndex = 0
    )

    return [ordered]@{
        uid = $Uid
        name = $DisplayName
        name_key = $NameKey
        avatar_index = $AvatarIndex
    }
}

function Write-JsonFixture {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)]$Value
    )

    $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $Path -Encoding UTF8
}

if (Test-Path -LiteralPath $testRoot) {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

try {
    $existingUid = "activeUid123"
    $newUid = "createUid456"
    $orphanUid = "orphanUid789"
    Write-JsonFixture -Path $authPath -Value ([ordered]@{
        users = @(
            [ordered]@{ localId = $existingUid },
            [ordered]@{ localId = $newUid; providerUserInfo = @([ordered]@{ providerId = "google.com" }) },
            [ordered]@{ localId = $orphanUid }
        )
    })

    Write-JsonFixture -Path $cleanRtdbPath -Value ([ordered]@{
        leaderboards = [ordered]@{
            v1 = [ordered]@{
                name_claims = [ordered]@{
                    alpha = New-NameClaim -Uid $existingUid -DisplayName "Alpha" -NameKey "alpha"
                    beta = New-NameClaim -Uid $newUid -DisplayName "Beta" -NameKey "beta" -AvatarIndex 1
                }
                profiles_by_uid = [ordered]@{
                    $existingUid = New-CanonicalProfile -Uid $existingUid -DisplayName "Alpha" -NameKey "alpha"
                }
            }
        }
    })

    $cleanOutput = @(& $powerShellPath -NoProfile -ExecutionPolicy Bypass -File $backfillPath -ProjectId "idle-elite" -AuthExportPath $authPath -RtdbBackupPath $cleanRtdbPath 2>&1)
    Assert-BackfillTest ($LASTEXITCODE -eq 0) "A clean offline profile snapshot should pass the backfill audit."
    Assert-BackfillTest (($cleanOutput -join "`n") -match 'create=1') "The clean fixture should plan exactly one missing canonical profile."
    Assert-BackfillTest (($cleanOutput -join "`n") -match 'auth_provider=google') "Google Auth users must retain their provider in planned profiles."

    $malformedProfile = New-CanonicalProfile -Uid $existingUid -DisplayName "Wrong Name" -NameKey "alpha"
    Write-JsonFixture -Path $invalidRtdbPath -Value ([ordered]@{
        leaderboards = [ordered]@{
            v1 = [ordered]@{
                name_claims = [ordered]@{
                    alpha = New-NameClaim -Uid $existingUid -DisplayName "Alpha" -NameKey "alpha"
                }
                profiles_by_uid = [ordered]@{
                    $existingUid = $malformedProfile
                    $orphanUid = New-CanonicalProfile -Uid $orphanUid -DisplayName "Orphan" -NameKey "orphan"
                }
            }
        }
    })

    $invalidOutput = @(& $powerShellPath -NoProfile -ExecutionPolicy Bypass -File $backfillPath -ProjectId "idle-elite" -AuthExportPath $authPath -RtdbBackupPath $invalidRtdbPath 2>&1)
    Assert-BackfillTest ($LASTEXITCODE -ne 0) "An orphan or malformed canonical profile must fail the backfill audit."
    $invalidText = $invalidOutput -join "`n"
    Assert-BackfillTest ($invalidText -match 'orphan_profiles=1') "The audit must report the orphan canonical profile."
    Assert-BackfillTest ($invalidText -match 'existing_conflicts=1') "The audit must report the malformed canonical profile."
    Assert-BackfillTest ($invalidText -notmatch [regex]::Escape($existingUid)) "Refusal output must not expose the malformed profile UID."
    Assert-BackfillTest ($invalidText -notmatch [regex]::Escape($orphanUid)) "Refusal output must not expose the orphan profile UID."

    Write-Output "firebase-profile-backfill-fixtures-ok"
    # The last fixture intentionally launches a child PowerShell process that
    # exits nonzero. Do not leak that expected native exit code to callers after
    # every assertion above has passed.
    $global:LASTEXITCODE = 0
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}
