$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing

function Resize-Png {
    param(
        [Parameter(Mandatory = $true)][string] $Source,
        [Parameter(Mandatory = $true)][string] $Destination,
        [Parameter(Mandatory = $true)][int] $Width,
        [Parameter(Mandatory = $true)][int] $Height
    )

    $sourcePath = Join-Path $projectRoot $Source
    $destinationPath = Join-Path $projectRoot $Destination
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Source texture not found: $sourcePath"
    }

    $sourceImage = [System.Drawing.Image]::FromFile($sourcePath)
    try {
        $bitmap = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $bitmap.SetResolution($sourceImage.HorizontalResolution, $sourceImage.VerticalResolution)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.DrawImage($sourceImage, 0, 0, $Width, $Height)
            } finally {
                $graphics.Dispose()
            }
            $destinationDirectory = Split-Path -Parent $destinationPath
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
            $bitmap.Save($destinationPath, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $bitmap.Dispose()
        }
    } finally {
        $sourceImage.Dispose()
    }

    [pscustomobject]@{
        source = $Source
        destination = $Destination
        width = $Width
        height = $Height
        bytes = (Get-Item -LiteralPath $destinationPath).Length
    }
}

$results = @(
    Resize-Png -Source "assets/content/ui/berry-mode-borders-source.png" -Destination "assets/content/ui/berry-mode-borders-1080p.png" -Width 1080 -Height 1920
    Resize-Png -Source "assets/content/thieving/heists/thieving-trophy-heist-backgrounds-wide.png" -Destination "assets/content/thieving/heists/thieving-trophy-heist-backgrounds-1080p.png" -Width 4320 -Height 619
    Resize-Png -Source "assets/content/ui/profile-avatar-game-objects-spritesheet.png" -Destination "assets/content/ui/profile-avatar-game-objects-spritesheet-1080p.png" -Width 1280 -Height 512
    Resize-Png -Source "assets/content/ui/profile-avatar-blue-guy-spritesheet.png" -Destination "assets/content/ui/profile-avatar-blue-guy-spritesheet-1080p.png" -Width 1280 -Height 512
)

$results | Format-Table destination,width,height,bytes -AutoSize
