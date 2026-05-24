$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$javaHome = "C:\Program Files\Android\Android Studio\jbr"
$output = Join-Path $projectRoot "builds\android\idle-elite-release.aab"
$stdoutLogPath = Join-Path $projectRoot "builds\android\last-release-build.stdout.log"
$stderrLogPath = Join-Path $projectRoot "builds\android\last-release-build.stderr.log"

if (-not (Test-Path -LiteralPath $runner)) {
    throw "Godot runner was not found at $runner"
}
if (-not (Test-Path -LiteralPath $androidSdk)) {
    throw "Android SDK not found at $androidSdk"
}
if (-not (Test-Path -LiteralPath $javaHome)) {
    throw "Java home not found at $javaHome"
}

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
    & $runner @arguments > $stdoutLogPath 2> $stderrLogPath
    $godotExitCode = $LASTEXITCODE
} finally {
    $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
}

if ($godotExitCode -ne 0) {
    if ($godotExitCode -eq 124 -and (Test-Path -LiteralPath $output)) {
        Write-Warning "Godot export timed out after producing an AAB. Continuing with the generated artifact."
    } else {
        throw "Godot export failed with exit code $godotExitCode. See $stdoutLogPath and $stderrLogPath"
    }
}

if (-not (Test-Path -LiteralPath $output)) {
    throw "Release AAB was not created at $output"
}

$artifact = Get-Item -LiteralPath $output
Write-Output "Release AAB created: $($artifact.FullName)"
Write-Output "Size: $($artifact.Length) bytes"
Write-Output "Build stdout log: $stdoutLogPath"
Write-Output "Build stderr log: $stderrLogPath"
$artifact
