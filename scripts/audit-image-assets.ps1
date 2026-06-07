param(
    [string]$Root = "assets",
    [int]$WarnPixels = 1048576,
    [int]$WarnBytes = 1048576
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$assetRoot = Resolve-Path (Join-Path $projectRoot $Root)

$rows = Get-ChildItem -LiteralPath $assetRoot -Recurse -File -Filter *.png | ForEach-Object {
    $image = $null
    try {
        $image = [System.Drawing.Image]::FromFile($_.FullName)
        $pixels = [int64]$image.Width * [int64]$image.Height
        $rawMb = [math]::Round(($pixels * 4) / 1MB, 2)
        $importPath = "$($_.FullName).import"
        $mode = ""
        if (Test-Path -LiteralPath $importPath) {
            $match = Select-String -LiteralPath $importPath -Pattern '^compress/mode=(\d+)' | Select-Object -First 1
            if ($match) {
                $mode = $match.Matches[0].Groups[1].Value
            }
        }
        [pscustomobject]@{
            RawMB = $rawMb
            FileMB = [math]::Round($_.Length / 1MB, 2)
            Width = $image.Width
            Height = $image.Height
            ImportMode = $mode
            SuspectSource = [bool]($_.Name -match '(?i)(source|contact-sheet|draft|chromakey|approved-anchors|preview)')
            Path = $_.FullName.Substring($projectRoot.Length + 1)
        }
    } finally {
        if ($image -ne $null) {
            $image.Dispose()
        }
    }
}

$totalFiles = @($rows).Count
$totalFileMb = [math]::Round((Get-ChildItem -LiteralPath $assetRoot -Recurse -File -Filter *.png | Measure-Object Length -Sum).Sum / 1MB, 2)
$totalRawMb = [math]::Round((@($rows) | Measure-Object RawMB -Sum).Sum, 2)

Write-Host "PNG files: $totalFiles"
Write-Host "PNG disk size: $totalFileMb MB"
Write-Host "Estimated raw RGBA texture memory: $totalRawMb MB"
Write-Host ""

Write-Host "Largest estimated runtime textures:"
$rows | Sort-Object RawMB -Descending | Select-Object -First 30 | Format-Table -AutoSize

Write-Host ""
Write-Host "Likely source/draft art still under $Root/:"
$rows | Where-Object SuspectSource | Sort-Object FileMB -Descending | Select-Object -First 40 | Format-Table -AutoSize

Write-Host ""
Write-Host "Warnings:"
$rows |
    Where-Object { ($_.Width * $_.Height) -ge $WarnPixels -or ($_.FileMB * 1MB) -ge $WarnBytes -or $_.SuspectSource } |
    Sort-Object RawMB -Descending |
    Select-Object RawMB,FileMB,Width,Height,ImportMode,SuspectSource,Path |
    Format-Table -AutoSize
