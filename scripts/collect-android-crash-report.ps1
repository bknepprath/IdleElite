param(
    [string]$PackageName = "com.idleelite.game",
    [string]$OutputRoot = "",
    [string]$Serial = "",
    [int]$LogLines = 20000,
    [int]$LiveSeconds = 0,
    [switch]$BugReport
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $OutputRoot = Join-Path $projectRoot "builds\android\crash-reports"
}

$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path -LiteralPath $adb)) {
    throw "adb not found at $adb"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$outputDir = Join-Path $OutputRoot $timestamp
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$serialArgs = @()
if (-not [string]::IsNullOrWhiteSpace($Serial)) {
    $serialArgs = @("-s", $Serial)
}

function Invoke-AdbCapture {
    param(
        [Parameter(Mandatory = $true)][string[]]$AdbArgs,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    try {
        & $adb @serialArgs @AdbArgs 2>&1 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    } catch {
        $_ | Out-String | Set-Content -LiteralPath $OutputPath -Encoding UTF8
    }
}

function Invoke-AdbNoThrow {
    param([Parameter(Mandatory = $true)][string[]]$AdbArgs)

    try {
        & $adb @serialArgs @AdbArgs
    } catch {
        Write-Warning $_
    }
}

Invoke-AdbCapture -AdbArgs @("devices", "-l") -OutputPath (Join-Path $outputDir "adb-devices.txt")
Invoke-AdbCapture -AdbArgs @("shell", "getprop") -OutputPath (Join-Path $outputDir "device-getprop.txt")
Invoke-AdbCapture -AdbArgs @("shell", "dumpsys", "package", $PackageName) -OutputPath (Join-Path $outputDir "package.txt")
Invoke-AdbCapture -AdbArgs @("shell", "pidof", $PackageName) -OutputPath (Join-Path $outputDir "pidof.txt")
Invoke-AdbCapture -AdbArgs @("shell", "dumpsys", "meminfo", $PackageName) -OutputPath (Join-Path $outputDir "meminfo.txt")
Invoke-AdbCapture -AdbArgs @("shell", "dumpsys", "battery") -OutputPath (Join-Path $outputDir "battery.txt")
Invoke-AdbCapture -AdbArgs @("shell", "dumpsys", "thermalservice") -OutputPath (Join-Path $outputDir "thermalservice.txt")
Invoke-AdbCapture -AdbArgs @("shell", "dumpsys", "cpuinfo") -OutputPath (Join-Path $outputDir "cpuinfo.txt")
Invoke-AdbCapture -AdbArgs @("logcat", "-b", "main", "-b", "system", "-b", "crash", "-d", "-v", "threadtime", "-t", "$LogLines") -OutputPath (Join-Path $outputDir "logcat-tail.txt")
Invoke-AdbCapture -AdbArgs @("shell", "dumpsys", "dropbox", "--print", "data_app_crash", "data_app_native_crash", "system_app_crash") -OutputPath (Join-Path $outputDir "dropbox-crashes.txt")

Invoke-AdbCapture -AdbArgs @("shell", "run-as", $PackageName, "cat", "files/pending-crash-report.json") -OutputPath (Join-Path $outputDir "pending-crash-report-run-as.txt")

if ($LiveSeconds -gt 0) {
    $liveLog = Join-Path $outputDir "logcat-live.txt"
    $liveErr = Join-Path $outputDir "logcat-live.stderr.txt"
    $args = @()
    $args += $serialArgs
    $args += @("logcat", "-v", "threadtime")
    $process = Start-Process -FilePath $adb -ArgumentList $args -RedirectStandardOutput $liveLog -RedirectStandardError $liveErr -WindowStyle Hidden -PassThru
    Start-Sleep -Seconds $LiveSeconds
    if (-not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
}

if ($BugReport) {
    $bugReportZip = Join-Path $outputDir "bugreport.zip"
    Invoke-AdbNoThrow -AdbArgs @("bugreport", $bugReportZip) | Out-File -LiteralPath (Join-Path $outputDir "bugreport.txt") -Encoding UTF8
}

Compress-Archive -Path (Join-Path $outputDir "*") -DestinationPath (Join-Path $OutputRoot "$timestamp.zip") -Force
Write-Output "Crash report bundle: $(Join-Path $OutputRoot "$timestamp.zip")"
