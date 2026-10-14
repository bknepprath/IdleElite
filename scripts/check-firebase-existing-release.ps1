param(
    [Parameter(Mandatory = $true)][string]$BaselineAab,
    [string]$ProjectId = 'idle-elite'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$configPath = Join-Path $projectRoot 'firebase-leaderboard-config.json'
$rulesPath = Join-Path $projectRoot 'firebase-realtime-database.rules.json'
$presetPath = Join-Path $projectRoot 'export_presets.cfg'
$java = 'C:\Program Files\Android\Android Studio\jbr\bin\java.exe'
$bundletool = Join-Path $projectRoot '.codex-tools/bundletool-all-1.18.3.jar'
foreach ($required in @($BaselineAab, $configPath, $rulesPath, $presetPath, $java, $bundletool)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required release input missing: $required" }
}

# This workflow is for compatible updates, never an account-system migration.
# Read the shipped bundle itself so an old checkout cannot supply the baseline config.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $BaselineAab).Path)
try {
    $entries = @($zip.Entries | Where-Object { $_.FullName -match '(^|/)assets/firebase-leaderboard-config\.json$' })
    if ($entries.Count -ne 1) { throw 'Baseline bundle must contain exactly one Firebase configuration.' }
    $reader = [IO.StreamReader]::new($entries[0].Open())
    try { $baselineConfig = $reader.ReadToEnd() | ConvertFrom-Json }
    finally { $reader.Dispose() }
} finally { $zip.Dispose() }
$config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
foreach ($key in @('database_url', 'web_api_key', 'google_web_client_id')) {
    if ([string]::IsNullOrWhiteSpace([string]$config.$key) -or [string]$config.$key -cne [string]$baselineConfig.$key) {
        throw "Existing-release Firebase configuration differs from the shipped bundle ($key). Use the migration workflow."
    }
}
$manifest = (& $java -jar $bundletool dump manifest "--bundle=$BaselineAab" 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) { throw 'Could not inspect baseline bundle manifest.' }
if ($manifest -notmatch 'package="com\.idleelite\.game"' -or $manifest -notmatch 'android:versionCode="(\d+)"') {
    throw 'Baseline is not a production Idle Elite bundle.'
}
$baselineCode = [int]$Matches[1]
$presets = Get-Content -LiteralPath $presetPath -Raw
if ($presets -notmatch '(?m)^version/code=(\d+)\r?$') { throw 'Release version code is missing.' }
$releaseCode = [int]$Matches[1]
if ($releaseCode -le $baselineCode) { throw 'New release version code must exceed the shipped baseline.' }
if ($presets -notmatch '(?m)^version/name="([^"]+)"\r?$') { throw 'Release version name is missing.' }
$releaseName = $Matches[1]

if ([string]::IsNullOrWhiteSpace($ProjectId)) { throw 'Firebase project is missing.' }
$evidenceDir = Join-Path $projectRoot 'release/existing-release-readiness'
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null
$liveRulesPath = Join-Path $evidenceDir ("live-rules-code{0}-{1}.json" -f $releaseCode, [guid]::NewGuid().ToString('N'))
# A fresh authenticated GET is mandatory on every build. No rules or player records are written.
& firebase database:get /.settings/rules --project $ProjectId --instance (([uri]$config.database_url).Host.Split('.')[0]) --output $liveRulesPath
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $liveRulesPath)) { throw 'Cannot verify currently deployed Firebase rules.' }
$liveRules = Get-Content -LiteralPath $liveRulesPath -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 100 -Compress
$localRules = Get-Content -LiteralPath $rulesPath -Raw | ConvertFrom-Json | ConvertTo-Json -Depth 100 -Compress
if ($liveRules -cne $localRules) { throw 'Deployed Firebase rules differ from the release rules. Review compatibility before building.' }

$receipt = [ordered]@{
    verified_at_utc = [DateTimeOffset]::UtcNow.ToString('o')
    workflow = 'existing-account-system-update'
    version_name = $releaseName
    version_code = $releaseCode
    baseline_version_code = $baselineCode
    baseline_aab_sha256 = (Get-FileHash -LiteralPath $BaselineAab -Algorithm SHA256).Hash
    firebase_config_sha256 = (Get-FileHash -LiteralPath $configPath -Algorithm SHA256).Hash
    firebase_rules_sha256 = (Get-FileHash -LiteralPath $rulesPath -Algorithm SHA256).Hash
    live_rules_path = $liveRulesPath
    configuration_matches_shipped_bundle = $true
    deployed_rules_match = $true
}
$receipt | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $evidenceDir "code$releaseCode.json") -Encoding UTF8
Write-Output "firebase-existing-release-ok baseline=$baselineCode release=$releaseCode"
