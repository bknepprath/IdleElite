param(
    [switch] $SkipExport,
    [switch] $SkipValidation,
    [switch] $SkipWebTouchScrollValidation,
    [switch] $Upload,
    [string] $ButlerTarget = $env:ITCH_BUTLER_TARGET
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$webBuildDir = Join-Path $projectRoot "builds\web"
$itchBuildDir = Join-Path $projectRoot "builds\itch"
$latestZipPath = Join-Path $itchBuildDir "idle-elite-itch-web-latest.zip"
$webTouchScrollTest = Join-Path $projectRoot "scripts\test-fishing-web-touch-scroll.ps1"

function Get-RelativeZipEntryNames {
    param([Parameter(Mandatory = $true)][string] $ZipPath)

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
    try {
        @($archive.Entries | ForEach-Object { $_.FullName })
    } finally {
        $archive.Dispose()
    }
}

Assert-True (Test-Path -LiteralPath $runner) "Godot safe runner was not found at $runner"
Assert-True (Test-Path -LiteralPath $exportPresetsPath) "Export presets file was not found at $exportPresetsPath"

$exportPresets = Get-Content -Raw -LiteralPath $exportPresetsPath
if ($exportPresets -notmatch '(?m)^version/name="([^"]+)"') {
    throw "Could not read version/name from $exportPresetsPath"
}
$versionName = $Matches[1]
if ($exportPresets -notmatch '(?m)^version/code=(\d+)') {
    throw "Could not read version/code from $exportPresetsPath"
}
$versionCode = $Matches[1]

New-Item -ItemType Directory -Path $itchBuildDir -Force | Out-Null

if (-not $SkipValidation) {
    & (Join-Path $projectRoot "scripts\update-firebase-leaderboard-rules.ps1") -Check
    & (Join-Path $projectRoot "scripts\check-leaderboard-cost-safety.ps1")
    & (Join-Path $projectRoot "scripts\check-runtime-asset-paths.ps1")
}

if (-not $SkipExport) {
    if (Test-Path -LiteralPath $webBuildDir) {
        Remove-Item -LiteralPath $webBuildDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $webBuildDir -Force | Out-Null

    $previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
    $env:GODOT_RUN_TIMEOUT_SECONDS = "1200"
    try {
        & $runner --path $projectRoot --export-release Web (Join-Path $webBuildDir "index.html")
        if ($LASTEXITCODE -ne 0) {
            throw "Godot Web export failed with exit code $LASTEXITCODE"
        }
    } finally {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
}

$requiredFiles = @(
    "index.html",
    "index.js",
    "index.pck",
    "index.wasm"
)
foreach ($fileName in $requiredFiles) {
    Assert-True (Test-Path -LiteralPath (Join-Path $webBuildDir $fileName)) "Web export is missing $fileName in $webBuildDir"
}
$pck = Get-Item -LiteralPath (Join-Path $webBuildDir "index.pck")
Assert-True ($pck.Length -le 200000000) ("Web index.pck is {0:N2} MB ({1:N2} MiB), exceeding itch.io's 200 MB single-file limit." -f ($pck.Length / 1000000), ($pck.Length / 1MB))

if (-not $SkipValidation -and -not $SkipWebTouchScrollValidation) {
    Assert-True (Test-Path -LiteralPath $webTouchScrollTest) "Fishing web touch scroll test was not found at $webTouchScrollTest"
    & $webTouchScrollTest
    if ($LASTEXITCODE -ne 0) {
        throw "Fishing web touch scroll validation failed with exit code $LASTEXITCODE"
    }
}

$versionedZipPath = Join-Path $itchBuildDir "idle-elite-itch-web-v$versionName-code$versionCode.zip"
foreach ($zipPath in @($versionedZipPath, $latestZipPath)) {
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
}

Compress-Archive -Path (Join-Path $webBuildDir "*") -DestinationPath $versionedZipPath -Force
Copy-Item -LiteralPath $versionedZipPath -Destination $latestZipPath -Force

$entries = Get-RelativeZipEntryNames -ZipPath $latestZipPath
Assert-True ($entries -contains "index.html") "Itch zip must contain index.html at the zip root."
Assert-True (-not ($entries -contains "web/index.html" -or $entries -contains "builds/web/index.html")) "Itch zip must not contain a nested builds/web folder."

$hash = Get-FileHash -Algorithm SHA256 -LiteralPath $latestZipPath
Write-Output "itch-web-package-ok"
Write-Output "Versioned zip: $versionedZipPath"
Write-Output "Latest zip: $latestZipPath"
Write-Output "SHA256: $($hash.Hash)"

if ($Upload) {
    Assert-True (-not [string]::IsNullOrWhiteSpace($ButlerTarget)) "Set -ButlerTarget or ITCH_BUTLER_TARGET, for example user-name/game-name:web"
    $butlerCommand = Get-Command butler -ErrorAction SilentlyContinue
    Assert-True ($null -ne $butlerCommand) "Butler CLI was not found. Install Butler or run this script without -Upload."
    & butler push $latestZipPath $ButlerTarget --userversion "v$versionName-code$versionCode"
    if ($LASTEXITCODE -ne 0) {
        throw "Butler upload failed with exit code $LASTEXITCODE"
    }
    Write-Output "itch-web-upload-ok target=$ButlerTarget"
}

Get-Item -LiteralPath $latestZipPath
