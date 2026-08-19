$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$exportPresetsPath = Join-Path $projectRoot "export_presets.cfg"
$projectSettingsPath = Join-Path $projectRoot "project.godot"
$buildGradlePath = Join-Path $projectRoot "android\build\build.gradle"
$debugTemplateAar = Join-Path $projectRoot "android\build\libs\debug\godot-lib.template_debug.aar"
$assetPackGradlePath = Join-Path $projectRoot "android\build\assetPackInstallTime\build.gradle"
$assetPackManifestPath = Join-Path $projectRoot "android\build\assetPackInstallTime\src\main\AndroidManifest.xml"
$androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$javaHome = "C:\Program Files\Android\Android Studio\jbr"
$output = Join-Path $projectRoot "builds\android\idle-elite-preview-debug.aab"
$stdoutLogPath = Join-Path $projectRoot "builds\android\last-preview-build.stdout.log"
$stderrLogPath = Join-Path $projectRoot "builds\android\last-preview-build.stderr.log"
$presetName = "Android Release"

foreach ($path in @($runner, $exportPresetsPath, $projectSettingsPath, $buildGradlePath, $debugTemplateAar, $assetPackGradlePath, $assetPackManifestPath, $androidSdk, $javaHome)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required path not found: $path"
    }
}

$projectSettings = Get-Content -Raw -LiteralPath $projectSettingsPath
if ($projectSettings -notmatch '(?m)^window/stretch/mode="viewport"\r?$') {
    throw 'Android preview blocked: project.godot must keep window/stretch/mode="viewport" to prevent full-screen pixel tearing on physical phones.'
}

$originalExportPresets = Get-Content -Raw -LiteralPath $exportPresetsPath
$originalBuildGradle = Get-Content -Raw -LiteralPath $buildGradlePath
$patchedExportPresets = $originalExportPresets `
    -replace '(?m)^package/unique_name="com\.idleelite\.game"\r?$', 'package/unique_name="com.idleelite.game.preview"'
$patchedBuildGradle = $originalBuildGradle -replace 'applicationId getExportPackageName\(\)', 'applicationId "com.idleelite.game.preview"'

if ($patchedExportPresets -eq $originalExportPresets) {
    throw "Could not patch the Android preview package metadata."
}
if ($patchedBuildGradle -eq $originalBuildGradle) {
    throw "Could not patch the Android preview applicationId."
}

$env:ANDROID_HOME = $androidSdk
$env:ANDROID_SDK_ROOT = $androidSdk
$env:JAVA_HOME = $javaHome
$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "1200"
$outputDir = Split-Path -Parent $output
New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
foreach ($artifactPath in @($output, $stdoutLogPath, $stderrLogPath)) {
    if (Test-Path -LiteralPath $artifactPath) {
        Remove-Item -LiteralPath $artifactPath -Force
    }
}

$pushedLocation = $false
try {
    Set-Content -LiteralPath $exportPresetsPath -Value $patchedExportPresets -NoNewline
    Set-Content -LiteralPath $buildGradlePath -Value $patchedBuildGradle -NoNewline
    Push-Location $projectRoot
    $pushedLocation = $true
    & $runner --path . --export-debug $presetName $output > $stdoutLogPath 2> $stderrLogPath
    $godotExitCode = $LASTEXITCODE
} finally {
    if ($pushedLocation) {
        Pop-Location
    }
    Set-Content -LiteralPath $buildGradlePath -Value $originalBuildGradle -NoNewline
    Set-Content -LiteralPath $exportPresetsPath -Value $originalExportPresets -NoNewline
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
}

if ($godotExitCode -ne 0) {
    throw "Godot preview export failed with exit code $godotExitCode. See $stdoutLogPath and $stderrLogPath"
}
if (-not (Test-Path -LiteralPath $output)) {
    throw "Android preview AAB was not created at $output"
}

$headless = @(Get-HeadlessGodotProcesses)
if ($headless.Count -gt 0) {
    $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
    throw "A headless Godot process is still running after the Android preview export."
}

$artifact = Get-Item -LiteralPath $output
Write-Output "Android preview AAB created: $($artifact.FullName)"
Write-Output "Size: $($artifact.Length) bytes"
Write-Output "Build stdout log: $stdoutLogPath"
Write-Output "Build stderr log: $stderrLogPath"
$artifact
