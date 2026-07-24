$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$jsonPath = Join-Path $projectRoot "docs\activity-database.json"
$auditScriptPath = Join-Path $projectRoot "scripts\audit-activity-database.ps1"
$contractDocPath = Join-Path $projectRoot "docs\activity-database-contract.md"
$catalogPath = Join-Path $projectRoot "scripts\activity_data\catalog.gd"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$docsHtmlPath = Join-Path $projectRoot "docs\activity-database.html"
$docsScriptPath = Join-Path $projectRoot "docs\activity-docs.js"

foreach ($path in @($jsonPath, $auditScriptPath, $contractDocPath, $catalogPath, $exportPresetsPath, $docsHtmlPath, $docsScriptPath)) {
    Assert-True (Test-Path -LiteralPath $path) "Missing activity database contract file: $path"
}

$jsonRaw = Get-Content -LiteralPath $jsonPath -Raw
$contractDoc = Get-Content -LiteralPath $contractDocPath -Raw
$catalog = Get-Content -LiteralPath $catalogPath -Raw
$exportPresets = Get-Content -LiteralPath $exportPresetsPath -Raw
$docsHtml = Get-Content -LiteralPath $docsHtmlPath -Raw
$docsScript = Get-Content -LiteralPath $docsScriptPath -Raw

Assert-True ($contractDoc -match 'docs/activity-database\.json.*source of truth') "Contract doc must state that JSON is the source of truth."
Assert-True ($contractDoc -match '\.\\scripts\\audit-activity-database\.ps1') "Contract doc must include the audit command."
Assert-True ($catalog -match 'const ACTIVITY_DATABASE_PATH := "res://docs/activity-database\.json"') "Runtime catalog must load the source activity database JSON."
Assert-True ($catalog -match 'push_error\("Failed to load required activity database: %s" % ACTIVITY_DATABASE_PATH\)') "Runtime catalog should report the catalog-owned database path."
Assert-True ($exportPresets -match 'include_filter="[^"]*docs/activity-database\.json') "Android export must include docs/activity-database.json."
try {
    $null = $jsonRaw | ConvertFrom-Json
} catch {
    throw "docs/activity-database.json must be valid JSON. $($_.Exception.Message)"
}
Assert-True ($docsHtml -match '<script src="activity-docs\.js"></script>') "Activity database HTML must load the docs fetch script."
Assert-True ($docsHtml -notmatch 'IDLE_ELITE_ACTIVITY_DATABASE') "Activity database HTML must not embed a second activity database."
Assert-True ($docsScript -match 'const databasePath = "activity-database\.json"') "Activity docs must use the relative JSON database path."
Assert-True ($docsScript -match 'fetch\(databasePath\)') "Activity docs must fetch the source JSON over HTTP."

Write-Output "activity-database-contracts-ok"
