param(
    [Parameter(Mandatory = $true)][string]$AuthExportPath,
    [Parameter(Mandatory = $true)][string]$RtdbBackupPath,
    [switch]$ConfirmAnonymousCleanupDisabled,
    [switch]$ConfirmSnapshotsMatchConfiguredProject,
    [switch]$ConfirmPlayerWritesPausedDuringFinalReconciliation,
    [switch]$ConfirmBackfillAppliedAndReconciled,
    [switch]$ConfirmCanonicalRulesDeployed,
    [switch]$ConfirmGoogleProviderEnabled,
    [switch]$ConfirmGoogleOAuthAudienceReady,
    [switch]$ConfirmPlaySigningSha1Registered,
    [switch]$ConfirmUploadSha1Registered,
    [switch]$ConfirmSupportTransferProcedureReady,
    [string]$FreezeRulesPath,
    [string]$OutputPath
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot "firebase-leaderboard-config.json"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$rulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $projectRoot "release\firebase-migration-readiness.json"
}

function Assert-Condition {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-TextSha256 {
    param([Parameter(Mandatory = $true)][string]$Value)

    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
        return ([System.BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    }
    finally {
        $sha256.Dispose()
    }
}

function Assert-SensitiveInputIsUntracked {
    param([Parameter(Mandatory = $true)][string]$Path)

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $projectRootWithSeparator = [System.IO.Path]::GetFullPath($projectRoot) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $fullPath.StartsWith($projectRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
        return
    }
    $releaseRootWithSeparator = [System.IO.Path]::GetFullPath((Join-Path $projectRoot "release")) + [System.IO.Path]::DirectorySeparatorChar
    Assert-Condition ($fullPath.StartsWith($releaseRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) "Sensitive Firebase exports inside the workspace must stay under the ignored release directory."
}

foreach ($confirmation in @(
    @{ Value = [bool]$ConfirmAnonymousCleanupDisabled; Name = "ConfirmAnonymousCleanupDisabled" },
    @{ Value = [bool]$ConfirmSnapshotsMatchConfiguredProject; Name = "ConfirmSnapshotsMatchConfiguredProject" },
    @{ Value = [bool]$ConfirmPlayerWritesPausedDuringFinalReconciliation; Name = "ConfirmPlayerWritesPausedDuringFinalReconciliation" },
    @{ Value = [bool]$ConfirmBackfillAppliedAndReconciled; Name = "ConfirmBackfillAppliedAndReconciled" },
    @{ Value = [bool]$ConfirmCanonicalRulesDeployed; Name = "ConfirmCanonicalRulesDeployed" },
    @{ Value = [bool]$ConfirmGoogleProviderEnabled; Name = "ConfirmGoogleProviderEnabled" },
    @{ Value = [bool]$ConfirmGoogleOAuthAudienceReady; Name = "ConfirmGoogleOAuthAudienceReady" },
    @{ Value = [bool]$ConfirmPlaySigningSha1Registered; Name = "ConfirmPlaySigningSha1Registered" },
    @{ Value = [bool]$ConfirmUploadSha1Registered; Name = "ConfirmUploadSha1Registered" },
    @{ Value = [bool]$ConfirmSupportTransferProcedureReady; Name = "ConfirmSupportTransferProcedureReady" }
)) {
    Assert-Condition ([bool]$confirmation.Value) "Refusing to create release evidence without -$($confirmation.Name)."
}

Assert-Condition (Test-Path -LiteralPath $configPath -PathType Leaf) "firebase-leaderboard-config.json is required."
Assert-Condition (Test-Path -LiteralPath $exportPresetsPath -PathType Leaf) "export_presets.cfg is required."
Assert-Condition (Test-Path -LiteralPath $rulesPath -PathType Leaf) "firebase-realtime-database.rules.json is required."
Assert-Condition (Test-Path -LiteralPath $AuthExportPath -PathType Leaf) "AuthExportPath must point to the current Firebase Auth JSON export."
Assert-Condition (Test-Path -LiteralPath $RtdbBackupPath -PathType Leaf) "RtdbBackupPath must point to the current RTDB JSON backup."
Assert-SensitiveInputIsUntracked $AuthExportPath
Assert-SensitiveInputIsUntracked $RtdbBackupPath

$releaseRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot "release"))
$resolvedFreezeRulesPath = if ([string]::IsNullOrWhiteSpace($FreezeRulesPath)) {
    Join-Path $releaseRoot "firebase-migration-freeze\firebase-realtime-database.rules.json"
} elseif (-not [System.IO.Path]::IsPathRooted($FreezeRulesPath)) {
    [System.IO.Path]::GetFullPath((Join-Path $projectRoot $FreezeRulesPath))
} else {
    [System.IO.Path]::GetFullPath($FreezeRulesPath)
}
Assert-Condition ($resolvedFreezeRulesPath.StartsWith($releaseRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) "The migration freeze rules must stay inside the ignored release directory."
Assert-Condition (Test-Path -LiteralPath $resolvedFreezeRulesPath -PathType Leaf) "Generate the ignored migration freeze rules before creating release evidence."
$FreezeRulesPath = $resolvedFreezeRulesPath
$resolvedOutputPath = [System.IO.Path]::GetFullPath($OutputPath)
Assert-Condition ($resolvedOutputPath.StartsWith($releaseRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) "The readiness receipt must stay inside the ignored release directory."
$OutputPath = $resolvedOutputPath

$authFile = Get-Item -LiteralPath $AuthExportPath
$rtdbFile = Get-Item -LiteralPath $RtdbBackupPath
Assert-Condition ($authFile.FullName -cne $rtdbFile.FullName) "The Auth export and RTDB backup must be different files."
Assert-Condition ($authFile.Length -gt 2) "The Firebase Auth export is empty."
Assert-Condition ($rtdbFile.Length -gt 2) "The RTDB backup is empty."
Assert-Condition ($authFile.LastWriteTimeUtc -ge [DateTime]::UtcNow.AddHours(-24)) "The Firebase Auth export is older than 24 hours. Create a fresh export."
Assert-Condition ($rtdbFile.LastWriteTimeUtc -ge [DateTime]::UtcNow.AddHours(-24)) "The RTDB backup is older than 24 hours. Create a fresh backup."

$authExport = Get-Content -LiteralPath $authFile.FullName -Raw | ConvertFrom-Json
Assert-Condition ($null -ne $authExport.PSObject.Properties['users'] -and $authExport.users -is [System.Array]) "The Firebase Auth export must contain a users array."
$rtdbBackup = Get-Content -LiteralPath $rtdbFile.FullName -Raw | ConvertFrom-Json
Assert-Condition ($null -ne $rtdbBackup -and $rtdbBackup -is [pscustomobject]) "The RTDB backup must contain a JSON object, not null or a scalar value."

$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
$databaseUrl = ([string]$config.database_url).Trim().TrimEnd("/").ToLowerInvariant()
$webApiKey = ([string]$config.web_api_key).Trim()
$googleWebClientId = ([string]$config.google_web_client_id).Trim().ToLowerInvariant()
Assert-Condition (-not [string]::IsNullOrWhiteSpace($databaseUrl)) "firebase-leaderboard-config.json is missing database_url."
Assert-Condition ($webApiKey.Length -ge 20 -and $webApiKey -notmatch '\s') "firebase-leaderboard-config.json has an invalid web_api_key."
Assert-Condition ($googleWebClientId -match '^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$') "firebase-leaderboard-config.json has an invalid google_web_client_id."

$exportPresets = Get-Content -LiteralPath $exportPresetsPath -Raw
Assert-Condition ($exportPresets -match '(?m)^version/name="([^"]+)"$') "export_presets.cfg is missing version/name."
$versionName = $Matches[1]
Assert-Condition ($exportPresets -match '(?m)^version/code=(\d+)$') "export_presets.cfg is missing version/code."
$versionCode = [int]$Matches[1]

$receipt = [ordered]@{
    receipt_schema_version = 1
    release = [ordered]@{
        version_name = $versionName
        version_code = $versionCode
    }
    firebase_target_sha256 = Get-TextSha256 $databaseUrl
    firebase_web_api_key_sha256 = Get-TextSha256 $webApiKey
    google_web_client_sha256 = Get-TextSha256 $googleWebClientId
    firebase_rules_sha256 = (Get-FileHash -LiteralPath $rulesPath -Algorithm SHA256).Hash.ToLowerInvariant()
    verified_at_utc = [DateTimeOffset]::UtcNow.ToString("o")
    evidence = [ordered]@{
        anonymous_cleanup_disabled = $true
        snapshots_match_configured_project = $true
        player_writes_paused_during_final_reconciliation = $true
        auth_export_sha256 = (Get-FileHash -LiteralPath $authFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        auth_export_size_bytes = [long]$authFile.Length
        rtdb_backup_sha256 = (Get-FileHash -LiteralPath $rtdbFile.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        rtdb_backup_size_bytes = [long]$rtdbFile.Length
        migration_freeze_rules_sha256 = (Get-FileHash -LiteralPath $FreezeRulesPath -Algorithm SHA256).Hash.ToLowerInvariant()
        backfill_applied_and_reconciled = $true
        canonical_rules_deployed = $true
        google_provider_enabled = $true
        google_oauth_audience_ready = $true
        play_signing_sha1_registered = $true
        upload_sha1_registered = $true
        support_transfer_procedure_ready = $true
    }
}

$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

& (Join-Path $PSScriptRoot "check-firebase-migration-readiness.ps1") -ReceiptPath $OutputPath -ConfigPath $configPath -ExportPresetsPath $exportPresetsPath -FreezeRulesPath $FreezeRulesPath
Write-Output "firebase-migration-readiness-receipt-written=$OutputPath"
