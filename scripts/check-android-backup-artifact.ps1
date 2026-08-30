param(
    [Parameter(Mandatory = $true)][string] $AabPath
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$bundletool = Join-Path $projectRoot ".codex-tools\bundletool-all-1.18.3.jar"
$java = Join-Path "C:\Program Files\Android\Android Studio\jbr\bin" "java.exe"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"

foreach ($path in @($AabPath, $bundletool, $java, $exportPresetsPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required file not found: $path" }
}

$exportPresets = Get-Content -LiteralPath $exportPresetsPath -Raw
if ($exportPresets -notmatch '(?m)^package/unique_name="([^"]+)"$') {
    throw "Could not read the Android package name from export_presets.cfg."
}
$expectedPackage = $Matches[1]
if ($exportPresets -notmatch '(?m)^version/code=(\d+)$') {
    throw "Could not read the Android version code from export_presets.cfg."
}
$expectedVersionCode = $Matches[1]
if ($exportPresets -notmatch '(?m)^version/name="([^"]+)"$') {
    throw "Could not read the Android version name from export_presets.cfg."
}
$expectedVersionName = $Matches[1]
if ($exportPresets -notmatch '(?m)^gradle_build/target_sdk="(\d+)"$') {
    throw "Could not read the Android target SDK from export_presets.cfg."
}
$expectedTargetSdk = $Matches[1]

$validationOutput = & $java -jar $bundletool validate --bundle=$AabPath 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Bundletool validation failed with exit code $LASTEXITCODE.`n$($validationOutput -join [Environment]::NewLine)"
}

$manifestOutput = & $java -jar $bundletool dump manifest --bundle=$AabPath --module=base 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Dumping the merged release manifest failed with exit code $LASTEXITCODE."
}
$manifestText = $manifestOutput | Out-String -Width 4096
if ($manifestText -notmatch ('<manifest\s+[^>]*android:versionCode="' + [regex]::Escape($expectedVersionCode) + '"')) {
    throw "Merged release manifest versionCode does not match export_presets.cfg."
}
if ($manifestText -notmatch ('<manifest\s+[^>]*android:versionName="' + [regex]::Escape($expectedVersionName) + '"')) {
    throw "Merged release manifest versionName does not match export_presets.cfg."
}
if ($manifestText -notmatch ('<manifest\s+[^>]*package="' + [regex]::Escape($expectedPackage) + '"')) {
    throw "Merged release manifest package does not match export_presets.cfg."
}
if ($manifestText -notmatch '<uses-sdk\s+[^>]*android:minSdkVersion="24"') {
    throw "Merged release manifest must keep minSdkVersion 24."
}
if ($manifestText -notmatch ('<uses-sdk\s+[^>]*android:targetSdkVersion="' + [regex]::Escape($expectedTargetSdk) + '"')) {
    throw "Merged release manifest targetSdkVersion does not match export_presets.cfg."
}
if ($manifestText -notmatch '<application\s+[^>]*android:allowBackup="true"') {
    throw "Merged release manifest must enable Android backup."
}
if ($manifestText -notmatch 'android:fullBackupContent="@xml/backup_rules"') {
    throw "Merged release manifest is missing the legacy backup-rules reference."
}
if ($manifestText -notmatch 'android:dataExtractionRules="@xml/data_extraction_rules"') {
    throw "Merged release manifest is missing the Android 12+ data-extraction-rules reference."
}
if ($manifestText -notmatch 'android:name="org\.godotengine\.plugin\.v2\.IdleEliteGoogleAuth"') {
    throw "Merged release manifest is missing the Google account recovery plugin registration."
}
if ($manifestText -notmatch 'android:value="com\.godot\.game\.IdleEliteGoogleAuth"') {
    throw "Merged release manifest has the wrong Google account recovery plugin class."
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $AabPath))
try {
    $entryNames = @($archive.Entries | ForEach-Object { $_.FullName })
    foreach ($entryName in @("base/res/xml/backup_rules.xml", "base/res/xml/data_extraction_rules.xml")) {
        if ($entryNames -notcontains $entryName) {
            throw "Release bundle is missing packaged resource $entryName."
        }
    }
} finally {
    $archive.Dispose()
}

Write-Output "android-release-artifact-ok package=$expectedPackage version=$expectedVersionName code=$expectedVersionCode targetSdk=$expectedTargetSdk"
