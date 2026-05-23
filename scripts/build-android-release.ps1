$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$godotConsole = Join-Path $env:TEMP "godot-console-run\Godot_v4.5.1-stable_win64_console.exe"
$androidSdk = Join-Path $env:LOCALAPPDATA "Android\Sdk"
$javaHome = "C:\Program Files\Android\Android Studio\jbr"
$output = Join-Path $projectRoot "builds\android\idle-elite-release.aab"
$stdoutLogPath = Join-Path $projectRoot "builds\android\last-release-build.stdout.log"
$stderrLogPath = Join-Path $projectRoot "builds\android\last-release-build.stderr.log"

if (-not (Test-Path -LiteralPath $godotConsole)) {
    throw "Godot console executable not found at $godotConsole"
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
    "`"$projectRoot`"",
    "--export-release",
    "`"Android Release`"",
    "`"$output`""
) -join " "
$process = Start-Process -FilePath $godotConsole -ArgumentList $arguments -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutLogPath -RedirectStandardError $stderrLogPath
if (-not $process.WaitForExit(1200000)) {
    if (Test-Path -LiteralPath $output) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    } else {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw "Godot export did not finish before timeout and no release AAB was created."
    }
} else {
    $process.Refresh()
    if ($null -ne $process.ExitCode -and $process.ExitCode -ne 0) {
        throw "Godot export failed with exit code $($process.ExitCode). See $stdoutLogPath and $stderrLogPath"
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
