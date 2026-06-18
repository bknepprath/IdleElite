$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $projectRoot "docs\activity-database.json"
$jsPath = Join-Path $projectRoot "docs\activity-database-data.js"
$syncScriptPath = Join-Path $projectRoot "scripts\sync-activity-database-js.py"
$auditScriptPath = Join-Path $projectRoot "scripts\audit-activity-database.ps1"
$contractDocPath = Join-Path $projectRoot "docs\activity-database-contract.md"
$mainPath = Join-Path $projectRoot "scripts\main.gd"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

foreach ($path in @($jsonPath, $jsPath, $syncScriptPath, $auditScriptPath, $contractDocPath, $mainPath, $exportPresetsPath)) {
    Assert-True (Test-Path -LiteralPath $path) "Missing activity database contract file: $path"
}

$jsonRaw = Get-Content -LiteralPath $jsonPath -Raw
$jsRaw = Get-Content -LiteralPath $jsPath -Raw
$syncScript = Get-Content -LiteralPath $syncScriptPath -Raw
$contractDoc = Get-Content -LiteralPath $contractDocPath -Raw
$main = Get-Content -LiteralPath $mainPath -Raw
$exportPresets = Get-Content -LiteralPath $exportPresetsPath -Raw

Assert-True ($jsRaw.StartsWith("// Generated from activity-database.json for file:// HTML previews.")) "Generated activity database JS must keep its source warning header."
Assert-True ($syncScript -match 'JSON_PATH = ROOT / "docs" / "activity-database\.json"') "Sync script must read docs/activity-database.json."
Assert-True ($syncScript -match 'JS_PATH = ROOT / "docs" / "activity-database-data\.js"') "Sync script must write docs/activity-database-data.js."
Assert-True ($contractDoc -match 'docs/activity-database\.json.*source of truth') "Contract doc must state that JSON is the source of truth."
Assert-True ($contractDoc -match 'python scripts\\sync-activity-database-js\.py') "Contract doc must include the sync command."
Assert-True ($contractDoc -match '\.\\scripts\\audit-activity-database\.ps1') "Contract doc must include the audit command."
Assert-True ($main -match 'const ACTIVITY_DATABASE_PATH := "res://docs/activity-database\.json"') "Runtime must load the source activity database JSON."
Assert-True ($exportPresets -match 'include_filter="[^"]*docs/activity-database\.json') "Android export must include docs/activity-database.json."

$prefix = "globalThis.IDLE_ELITE_ACTIVITY_DATABASE = "
$payloadStart = $jsRaw.IndexOf($prefix)
Assert-True ($payloadStart -ge 0) "Generated activity database JS must assign globalThis.IDLE_ELITE_ACTIVITY_DATABASE."
$jsPayload = $jsRaw.Substring($payloadStart + $prefix.Length).Trim()
if ($jsPayload.EndsWith(";")) {
    $jsPayload = $jsPayload.Substring(0, $jsPayload.Length - 1)
}

$jsonObject = $jsonRaw | ConvertFrom-Json
$jsObject = $jsPayload | ConvertFrom-Json
$jsonCanonical = $jsonObject | ConvertTo-Json -Depth 100
$jsCanonical = $jsObject | ConvertTo-Json -Depth 100
Assert-True ($jsonCanonical -eq $jsCanonical) "docs/activity-database-data.js must match docs/activity-database.json. Run python scripts\sync-activity-database-js.py."

Write-Output "activity-database-contracts-ok"
