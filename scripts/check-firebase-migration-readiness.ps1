param(
    [string]$ReceiptPath,
    [string]$ConfigPath,
    [string]$ExportPresetsPath,
    [string]$FreezeRulesPath,
    [int]$MaximumAgeHours = 24
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$rulesPath = Join-Path $projectRoot "firebase-realtime-database.rules.json"
if ([string]::IsNullOrWhiteSpace($ReceiptPath)) {
    $ReceiptPath = Join-Path $projectRoot "release\firebase-migration-readiness.json"
}
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $projectRoot "firebase-leaderboard-config.json"
}
if ([string]::IsNullOrWhiteSpace($ExportPresetsPath)) {
    $ExportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
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

function Assert-FreezeEquivalent {
    param(
        $Source,
        $Frozen,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if ($Source -is [pscustomobject]) {
        Assert-Condition ($Frozen -is [pscustomobject]) "Android release blocked: migration freeze rules changed the JSON type at $Path."
        $sourceNames = @($Source.PSObject.Properties | ForEach-Object { [string]$_.Name } | Sort-Object)
        $frozenNames = @($Frozen.PSObject.Properties | ForEach-Object { [string]$_.Name } | Sort-Object)
        Assert-Condition (($sourceNames -join "`n") -ceq ($frozenNames -join "`n")) "Android release blocked: migration freeze rules changed property names at $Path."
        foreach ($property in $Source.PSObject.Properties) {
            $name = [string]$property.Name
            $frozenValue = $Frozen.PSObject.Properties[$name].Value
            if ($name -ceq ".write") {
                $script:validatedFreezeWriteRuleCount += 1
                Assert-Condition ($frozenValue -is [bool] -and $frozenValue -eq $false) "Android release blocked: migration freeze rules contain a non-false write at $Path/.write."
            } else {
                Assert-FreezeEquivalent -Source $property.Value -Frozen $frozenValue -Path "$Path/$name"
            }
        }
        return
    }
    if ($Source -is [System.Array]) {
        Assert-Condition ($Frozen -is [System.Array]) "Android release blocked: migration freeze rules changed an array at $Path."
        Assert-Condition ($Source.Count -eq $Frozen.Count) "Android release blocked: migration freeze rules changed array length at $Path."
        for ($index = 0; $index -lt $Source.Count; $index++) {
            Assert-FreezeEquivalent -Source $Source[$index] -Frozen $Frozen[$index] -Path "$Path[$index]"
        }
        return
    }

    $sourceJson = ConvertTo-Json -InputObject $Source -Compress
    $frozenJson = ConvertTo-Json -InputObject $Frozen -Compress
    Assert-Condition ($sourceJson -ceq $frozenJson) "Android release blocked: migration freeze rules changed a non-write value at $Path."
}

$releaseRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot "release"))
$resolvedReceiptPath = [System.IO.Path]::GetFullPath($ReceiptPath)
Assert-Condition ($resolvedReceiptPath.StartsWith($releaseRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) "Android release blocked: the Firebase migration receipt must stay inside the ignored release directory."
$ReceiptPath = $resolvedReceiptPath
if ([string]::IsNullOrWhiteSpace($FreezeRulesPath)) {
    $FreezeRulesPath = Join-Path $releaseRoot "firebase-migration-freeze\firebase-realtime-database.rules.json"
}
$FreezeRulesPath = [System.IO.Path]::GetFullPath($FreezeRulesPath)
Assert-Condition ($FreezeRulesPath.StartsWith($releaseRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) "Android release blocked: migration freeze rules must stay inside the ignored release directory."

Assert-Condition (Test-Path -LiteralPath $ReceiptPath -PathType Leaf) "Android release blocked: create the ignored Firebase migration readiness receipt first."
Assert-Condition (Test-Path -LiteralPath $ConfigPath -PathType Leaf) "Android release blocked: firebase-leaderboard-config.json is missing."
Assert-Condition (Test-Path -LiteralPath $ExportPresetsPath -PathType Leaf) "Android release blocked: export_presets.cfg is missing."
Assert-Condition (Test-Path -LiteralPath $rulesPath -PathType Leaf) "Android release blocked: Firebase rules are missing."
Assert-Condition (Test-Path -LiteralPath $FreezeRulesPath -PathType Leaf) "Android release blocked: generate the ignored migration freeze rules first."
Assert-Condition ($MaximumAgeHours -ge 1 -and $MaximumAgeHours -le 168) "MaximumAgeHours must be between 1 and 168."

$receipt = Get-Content -LiteralPath $ReceiptPath -Raw | ConvertFrom-Json
$config = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
$exportPresets = Get-Content -LiteralPath $ExportPresetsPath -Raw
$sourceRules = Get-Content -LiteralPath $rulesPath -Raw | ConvertFrom-Json
$freezeRules = Get-Content -LiteralPath $FreezeRulesPath -Raw | ConvertFrom-Json
$script:validatedFreezeWriteRuleCount = 0
Assert-FreezeEquivalent -Source $sourceRules -Frozen $freezeRules -Path '$'
Assert-Condition ($script:validatedFreezeWriteRuleCount -gt 0) "Android release blocked: migration freeze rules did not disable any writes."
$temporaryFirebaseConfigPath = Join-Path (Split-Path -Parent $FreezeRulesPath) "firebase.json"
Assert-Condition (Test-Path -LiteralPath $temporaryFirebaseConfigPath -PathType Leaf) "Android release blocked: the migration freeze temporary firebase.json is missing."
$temporaryFirebaseConfig = Get-Content -LiteralPath $temporaryFirebaseConfigPath -Raw | ConvertFrom-Json
Assert-Condition ([string]$temporaryFirebaseConfig.database.rules -ceq (Split-Path -Leaf $FreezeRulesPath)) "Android release blocked: the migration freeze firebase.json does not target the freeze rules."
Assert-Condition ($temporaryFirebaseConfig.PSObject.Properties.Count -eq 1) "Android release blocked: the migration freeze firebase.json must remain database-only."

Assert-Condition ($exportPresets -match '(?m)^version/name="([^"]+)"$') "Android release blocked: version/name is missing from export_presets.cfg."
$versionName = $Matches[1]
Assert-Condition ($exportPresets -match '(?m)^version/code=(\d+)$') "Android release blocked: version/code is missing from export_presets.cfg."
$versionCode = [int]$Matches[1]

$databaseUrl = ([string]$config.database_url).Trim().TrimEnd("/").ToLowerInvariant()
$webApiKey = ([string]$config.web_api_key).Trim()
$googleWebClientId = ([string]$config.google_web_client_id).Trim().ToLowerInvariant()
Assert-Condition (-not [string]::IsNullOrWhiteSpace($databaseUrl)) "Android release blocked: Firebase database_url is missing."
Assert-Condition (-not [string]::IsNullOrWhiteSpace($webApiKey)) "Android release blocked: Firebase web_api_key is missing."
Assert-Condition (-not [string]::IsNullOrWhiteSpace($googleWebClientId)) "Android release blocked: google_web_client_id is missing."

Assert-Condition ([int]$receipt.receipt_schema_version -eq 1) "Android release blocked: the Firebase migration readiness receipt schema is unsupported."
Assert-Condition ([string]$receipt.release.version_name -ceq $versionName) "Android release blocked: the Firebase migration receipt is for a different version name."
Assert-Condition ([int]$receipt.release.version_code -eq $versionCode) "Android release blocked: the Firebase migration receipt is for a different version code."
Assert-Condition ([string]$receipt.firebase_target_sha256 -ceq (Get-TextSha256 $databaseUrl)) "Android release blocked: the Firebase migration receipt targets a different database."
Assert-Condition ([string]$receipt.firebase_web_api_key_sha256 -ceq (Get-TextSha256 $webApiKey)) "Android release blocked: the Firebase migration receipt targets a different Firebase API key."
Assert-Condition ([string]$receipt.google_web_client_sha256 -ceq (Get-TextSha256 $googleWebClientId)) "Android release blocked: the Firebase migration receipt targets a different Google web client."
Assert-Condition ([string]$receipt.firebase_rules_sha256 -ceq (Get-FileHash -LiteralPath $rulesPath -Algorithm SHA256).Hash.ToLowerInvariant()) "Android release blocked: Firebase rules changed after the migration receipt was created. Reconcile and redeploy them before rebuilding."
Assert-Condition ([string]$receipt.evidence.migration_freeze_rules_sha256 -ceq (Get-FileHash -LiteralPath $FreezeRulesPath -Algorithm SHA256).Hash.ToLowerInvariant()) "Android release blocked: migration freeze rules changed after the readiness receipt was created. Regenerate and verify the migration evidence."

[DateTimeOffset]$verifiedAt = [DateTimeOffset]::MinValue
Assert-Condition ([DateTimeOffset]::TryParse([string]$receipt.verified_at_utc, [ref]$verifiedAt)) "Android release blocked: the Firebase migration receipt has an invalid verification time."
$now = [DateTimeOffset]::UtcNow
Assert-Condition ($verifiedAt -le $now.AddMinutes(5)) "Android release blocked: the Firebase migration receipt verification time is in the future."
Assert-Condition ($verifiedAt -ge $now.AddHours(-$MaximumAgeHours)) "Android release blocked: the Firebase migration readiness receipt is stale. Regenerate fresh Auth and RTDB evidence."

$evidence = $receipt.evidence
foreach ($requiredConfirmation in @(
    "anonymous_cleanup_disabled",
    "snapshots_match_configured_project",
    "player_writes_paused_during_final_reconciliation",
    "backfill_applied_and_reconciled",
    "canonical_rules_deployed",
    "google_provider_enabled",
    "google_oauth_audience_ready",
    "play_signing_sha1_registered",
    "upload_sha1_registered",
    "support_transfer_procedure_ready"
)) {
    $confirmationValue = $evidence.$requiredConfirmation
    Assert-Condition ($confirmationValue -is [bool] -and $confirmationValue -eq $true) "Android release blocked: Firebase migration evidence is incomplete ($requiredConfirmation)."
}

foreach ($hashField in @("auth_export_sha256", "rtdb_backup_sha256", "migration_freeze_rules_sha256")) {
    Assert-Condition ([string]$evidence.$hashField -cmatch '^[a-f0-9]{64}$') "Android release blocked: Firebase migration evidence has an invalid $hashField."
}
Assert-Condition ([long]$evidence.auth_export_size_bytes -gt 2) "Android release blocked: the Firebase Auth export evidence is empty."
Assert-Condition ([long]$evidence.rtdb_backup_size_bytes -gt 2) "Android release blocked: the RTDB backup evidence is empty."

Write-Output "firebase-migration-readiness-ok version=$versionName code=$versionCode freeze_writes_disabled=$($script:validatedFreezeWriteRuleCount) verified_at=$($verifiedAt.ToUniversalTime().ToString('o'))"
