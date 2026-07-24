$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$captureRoot = Join-Path $projectRoot ".codex-tmp\fighting-diamond-real"

$captures = @(
    @{ Monster = "chicken"; File = "fight-chickens-lv99-auto-real-card-active-runtime-scale-final-1080x1920.png"; Y = 590 },
    @{ Monster = "goblin"; File = "fight-goblins-lv99-auto-real-card-active-runtime-scale-final-1080x1920.png"; Y = 590 },
    @{ Monster = "rouse"; File = "fight-r-o-u-s-es-lv99-rouses-crash-real-card-active-runtime-behavior-final-1080x1920.png"; Y = 400 },
    @{ Monster = "werewolf"; File = "fight-werewolves-lv99-auto-real-card-active-runtime-scale-final-wolf-1080x1920.png"; Y = 590 },
    @{ Monster = "werewolf-transform"; File = "fight-werewolves-lv99-werewolf-transform-real-card-active-runtime-scale-final-1080x1920.png"; Y = 590 },
    @{ Monster = "cave-troll"; File = "fight-cave-trolls-lv99-cave-troll-slam-real-card-active-runtime-behavior-final-v2-1080x1920.png"; Y = 400 },
    @{ Monster = "vampire"; File = "fight-vampires-lv99-vampire-flank-cross-real-card-active-runtime-behavior-final-1080x1920.png"; Y = 400 },
    @{ Monster = "dragon"; File = "fight-dragons-lv99-breath-strike-real-card-active-runtime-behavior-final-1080x1920.png"; Y = 980 }
)

foreach ($capture in $captures) {
    $sourcePath = Join-Path $captureRoot $capture.File
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing real-game capture: $sourcePath"
    }

    $source = [System.Drawing.Bitmap]::FromFile($sourcePath)
    try {
        if ($source.Width -ne 1080 -or $source.Height -ne 1920) {
            throw "Unexpected dimensions for ${sourcePath}: $($source.Width)x$($source.Height)"
        }

        $cropRect = [System.Drawing.Rectangle]::new(80, [int]$capture.Y, 920, 640)
        $crop = $source.Clone($cropRect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $outputPath = Join-Path $PSScriptRoot ("{0}-arena-proof.png" -f $capture.Monster)
            $crop.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            $hash = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
            Write-Output ("{0}|{1}|{2}" -f $capture.Monster, $outputPath, $hash)
        } finally {
            $crop.Dispose()
        }
    } finally {
        $source.Dispose()
    }
}
