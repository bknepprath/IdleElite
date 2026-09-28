param(
    # Ship-first rollout: build without the Firebase migration receipt. Use only when the
    # live rules still accept this build's writes and the rules switch happens after launch
    # (scripts\switch-on-firebase-leaderboard-rules.ps1). The receipt stays mandatory otherwise.
    [switch]$SkipFirebaseMigrationReceipt
)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$javaHome = "C:\Program Files\Android\Android Studio\jbr"
$stdoutLogPath = Join-Path $projectRoot "builds\android\last-release-build.stdout.log"
$stderrLogPath = Join-Path $projectRoot "builds\android\last-release-build.stderr.log"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$projectSettingsPath = Join-Path $projectRoot "project.godot"
$releaseTemplateAar = Join-Path $projectRoot "android\build\libs\release\godot-lib.template_release.aar"
$assetPackGradlePath = Join-Path $projectRoot "android\build\assetPackInstallTime\build.gradle"
$assetPackManifestPath = Join-Path $projectRoot "android\build\assetPackInstallTime\src\main\AndroidManifest.xml"
$firebaseConfigPath = Join-Path $projectRoot "firebase-leaderboard-config.json"
$firebaseMigrationReadinessCheck = Join-Path $projectRoot "scripts\check-firebase-migration-readiness.ps1"
$keystorePassword = $env:IDLE_ELITE_KEYSTORE_PASSWORD
function Set-TextWithRetry {
    param(
        [string] $Path,
        [string] $Value
    )

    $lastError = $null
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        try {
            [System.IO.File]::WriteAllText($Path, $Value, [System.Text.UTF8Encoding]::new($false))
            return
        } catch {
            $lastError = $_
            Start-Sleep -Milliseconds 500
        }
    }

    throw $lastError
}
if (-not (Test-Path -LiteralPath $runner)) {
    throw "Godot runner was not found at $runner"
}
if (-not (Test-Path -LiteralPath $androidSdk)) {
    throw "Android SDK not found at $androidSdk"
}
if (-not (Test-Path -LiteralPath $javaHome)) {
    throw "Java home not found at $javaHome"
}
if (-not (Test-Path -LiteralPath $exportPresetsPath)) {
    throw "Export presets file not found at $exportPresetsPath"
}
if (-not (Test-Path -LiteralPath $projectSettingsPath)) {
    throw "Godot project settings file not found at $projectSettingsPath"
}
foreach ($requiredTemplatePath in @($releaseTemplateAar, $assetPackGradlePath, $assetPackManifestPath)) {
    if (-not (Test-Path -LiteralPath $requiredTemplatePath)) {
        throw "Required Android build-template path not found: $requiredTemplatePath"
    }
}
if (-not (Test-Path -LiteralPath $firebaseConfigPath)) {
    throw "Android release blocked: firebase-leaderboard-config.json is required for account recovery and cloud save."
}
if (-not (Test-Path -LiteralPath $firebaseMigrationReadinessCheck)) {
    throw "Android release blocked: the Firebase migration readiness check is missing."
}
$firebaseConfig = Get-Content -LiteralPath $firebaseConfigPath -Raw | ConvertFrom-Json
$googleWebClientId = ([string]$firebaseConfig.google_web_client_id).Trim()
if ($googleWebClientId -notmatch '^[0-9]+-[a-z0-9]+\.apps\.googleusercontent\.com$') {
    throw "Android release blocked: firebase-leaderboard-config.json must contain a valid google_web_client_id."
}
if ($SkipFirebaseMigrationReceipt) {
    Write-Warning "Skipping the Firebase migration receipt check (ship-first rollout). Switch the rules on after launch."
} else {
    & $firebaseMigrationReadinessCheck
}
& (Join-Path $projectRoot "scripts\check-crash-audit-contracts.ps1")
& (Join-Path $projectRoot "scripts\check-firebase-leaderboard-preflight.ps1") -SkipGodotSafeValidation
$projectSettings = Get-Content -Raw -LiteralPath $projectSettingsPath
if ($projectSettings -notmatch '(?m)^window/size/viewport_width=1080\r?$' -or
    $projectSettings -notmatch '(?m)^window/size/viewport_height=1920\r?$') {
    throw 'Android release blocked: project.godot must use the native 1080 x 1920 viewport. The archived 2160 x 3840 project must never be released.'
}
if ($projectSettings -notmatch '(?m)^window/stretch/mode="viewport"\r?$') {
    throw 'Android release blocked: project.godot must keep window/stretch/mode="viewport" to prevent full-screen pixel tearing on physical phones.'
}
if ($projectSettings -notmatch '(?m)^renderer/rendering_method="gl_compatibility"\r?$' -or
    $projectSettings -notmatch '(?m)^renderer/rendering_method\.mobile="gl_compatibility"\r?$') {
    throw 'Android release blocked: the native 1080p Samsung build must keep both rendering methods on gl_compatibility to prevent Vulkan framebuffer corruption.'
}
if ([string]::IsNullOrWhiteSpace($keystorePassword)) {
    throw "Set IDLE_ELITE_KEYSTORE_PASSWORD before running this script."
}
$originalExportPresets = Get-Content -Raw -LiteralPath $exportPresetsPath
if ($originalExportPresets -notmatch '(?m)^version/name="([^"]+)"') {
    throw "Could not read Android version name from $exportPresetsPath"
}
$versionName = $Matches[1]
if ($originalExportPresets -notmatch '(?m)^version/code=(\d+)') {
    throw "Could not read Android version code from $exportPresetsPath"
}
$versionCode = $Matches[1]
$artifactBaseName = "idle-elite-release-v$versionName-code$versionCode"
$output = Join-Path $projectRoot "builds\android\$artifactBaseName.aab"
$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk
$env:JAVA_HOME = $javaHome
$outputDir = Split-Path -Parent $output
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
foreach ($logPath in @($stdoutLogPath, $stderrLogPath)) {
    if (Test-Path -LiteralPath $logPath) {
        Remove-Item -LiteralPath $logPath -Force
    }
}
if (Test-Path -LiteralPath $output) {
    Remove-Item -LiteralPath $output -Force
}

$escapedKeystorePassword = $keystorePassword.Replace("\", "\\").Replace('"', '\"').Replace('$', '$$')
$patchedExportPresets = $originalExportPresets -replace '(?m)^keystore/release_password="[^"\r\n]*"', "keystore/release_password=`"$escapedKeystorePassword`""
if ($patchedExportPresets -eq $originalExportPresets) {
    throw "Could not inject release keystore password into $exportPresetsPath"
}

$arguments = @(
    "--headless",
    "--path",
    $projectRoot,
    "--export-release",
    "Android Release",
    $output
)
$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "1200"
try {
    Set-TextWithRetry -Path $exportPresetsPath -Value $patchedExportPresets
    & $runner @arguments > $stdoutLogPath 2> $stderrLogPath
    $godotExitCode = $LASTEXITCODE
} finally {
    Set-TextWithRetry -Path $exportPresetsPath -Value $originalExportPresets
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
}
if ($godotExitCode -ne 0) {
    throw "Godot export failed with exit code $godotExitCode. See $stdoutLogPath and $stderrLogPath"
}
if (-not (Test-Path -LiteralPath $output)) {
    throw "Release AAB was not created at $output"
}

& (Join-Path $projectRoot "scripts\check-android-backup-artifact.ps1") -AabPath $output

$artifact = Get-Item -LiteralPath $output
Write-Output "Release AAB created: $($artifact.FullName)"
Write-Output "Size: $($artifact.Length) bytes"
Write-Output "Build stdout log: $stdoutLogPath"
Write-Output "Build stderr log: $stderrLogPath"
$artifact
