param(
    [string]$PackageName = "com.idleelite.game.preview",
    [string]$Serial = "",
    [ValidateRange(1, 100)][int]$Samples = 1,
    [ValidateRange(0, 300)][int]$IntervalSeconds = 5,
    [ValidateRange(0, 300)][int]$SettleSeconds = 20,
    [string]$OutputDirectory = "",
    [string]$MeminfoFile = "",
    [switch]$ColdLaunch
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$previewPackage = "com.idleelite.game.preview"

function ConvertFrom-AndroidMeminfo {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$MeasuredPackage,
        [Parameter(Mandatory = $true)][int]$SampleNumber
    )

    $valuesKb = @{}
    foreach ($line in $Lines) {
        $match = [regex]::Match($line, '^\s*(Java Heap|Native Heap|Graphics|Private Other|TOTAL PSS):\s+([\d,]+)')
        if (-not $match.Success) {
            continue
        }
        $valuesKb[$match.Groups[1].Value] = [int64]($match.Groups[2].Value -replace ',', '')
    }

    if (-not $valuesKb.ContainsKey("TOTAL PSS")) {
        throw "Android meminfo did not contain an App Summary TOTAL PSS value."
    }

    function Convert-KbToMb {
        param([int64]$Kilobytes)
        return [math]::Round($Kilobytes / 1024.0, 1)
    }

    return [pscustomobject]@{
        timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
        package = $MeasuredPackage
        sample = $SampleNumber
        total_pss_mb = Convert-KbToMb ([int64]$valuesKb["TOTAL PSS"])
        graphics_mb = Convert-KbToMb ([int64]$valuesKb["Graphics"])
        native_heap_mb = Convert-KbToMb ([int64]$valuesKb["Native Heap"])
        java_heap_mb = Convert-KbToMb ([int64]$valuesKb["Java Heap"])
        private_other_mb = Convert-KbToMb ([int64]$valuesKb["Private Other"])
    }
}

if (-not [string]::IsNullOrWhiteSpace($MeminfoFile)) {
    if (-not (Test-Path -LiteralPath $MeminfoFile -PathType Leaf)) {
        throw "Meminfo file not found: $MeminfoFile"
    }
    ConvertFrom-AndroidMeminfo -Lines (Get-Content -LiteralPath $MeminfoFile) -MeasuredPackage $PackageName -SampleNumber 1
    exit 0
}

if ($PackageName -ne $previewPackage) {
    throw "Memory measurement is restricted to the preview package $previewPackage."
}

$adb = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path -LiteralPath $adb -PathType Leaf)) {
    throw "adb not found at $adb"
}

$serialArgs = @()
if (-not [string]::IsNullOrWhiteSpace($Serial)) {
    $serialArgs = @("-s", $Serial)
}

$deviceLines = @(& $adb devices | Select-String "\sdevice$")
if (-not [string]::IsNullOrWhiteSpace($Serial)) {
    $deviceLines = @($deviceLines | Where-Object { $_.Line -match "^$([regex]::Escape($Serial))\s" })
}
if ($deviceLines.Count -ne 1) {
    throw "Expected exactly one authorized Android device, found $($deviceLines.Count)."
}

if ($ColdLaunch) {
    & $adb @serialArgs shell am force-stop $PackageName | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not stop $PackageName before cold launch."
    }
    & $adb @serialArgs shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Could not launch $PackageName."
    }
    if ($SettleSeconds -gt 0) {
        Start-Sleep -Seconds $SettleSeconds
    }
}

if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $OutputDirectory = (Resolve-Path -LiteralPath $OutputDirectory).Path
}

$results = @()
for ($sampleNumber = 1; $sampleNumber -le $Samples; $sampleNumber++) {
    $pidText = (& $adb @serialArgs shell pidof $PackageName 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($pidText)) {
        throw "$PackageName is not running."
    }

    $meminfoLines = @(& $adb @serialArgs shell dumpsys meminfo $PackageName 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Could not read Android meminfo for $PackageName."
    }
    $result = ConvertFrom-AndroidMeminfo -Lines $meminfoLines -MeasuredPackage $PackageName -SampleNumber $sampleNumber
    $results += $result

    if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
        $rawPath = Join-Path $OutputDirectory ("meminfo-{0:D3}.txt" -f $sampleNumber)
        $meminfoLines | Set-Content -LiteralPath $rawPath -Encoding UTF8
    }

    if ($sampleNumber -lt $Samples -and $IntervalSeconds -gt 0) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

if (-not [string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $results | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory "memory-samples.json") -Encoding UTF8
}

$results | Format-Table sample,total_pss_mb,graphics_mb,native_heap_mb,java_heap_mb,private_other_mb -AutoSize
