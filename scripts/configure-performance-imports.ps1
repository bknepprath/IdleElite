param([switch] $Check)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing

$runtimeSourceAllowlist = @(
    "assets/content/fight/enemies/cave-trolls/cave-trolls-pound-source.png",
    "assets/content/fight/enemies/giants/giants-states-source.png",
    "assets/content/fight/enemies/vampires/vampires-cape-summon-source.png"
)
$explicitlyExcluded = @(
    "assets/content/ui/berry-mode-borders-source.png",
    "assets/content/ui/profile-avatar-game-objects-spritesheet.png",
    "assets/content/ui/profile-avatar-blue-guy-spritesheet.png",
    "assets/content/thieving/heists/thieving-trophy-heist-backgrounds-wide.png"
)

function Normalize-ProjectPath {
    param([string] $Path)
    return $Path.Replace('\', '/')
}

function Test-RuntimeTextureCandidate {
    param([string] $RelativePath)

    $normalized = Normalize-ProjectPath $RelativePath
    if (-not ($normalized.StartsWith("assets/content/") -or $normalized.StartsWith("assets/loading/"))) {
        return $false
    }
    if ($explicitlyExcluded -contains $normalized) {
        return $false
    }
    if ($normalized -match '(?i)/(drafts|source|source-originals|walk-debug)/' -or $normalized -match '(?i)-preview\.(png|jpg|jpeg|webp)$' -or $normalized -match '(?i)-master\.(png|jpg|jpeg|webp)$') {
        return $runtimeSourceAllowlist -contains $normalized
    }
    if ($normalized -match '(?i)-source\.(png|jpg|jpeg|webp)$') {
        return $runtimeSourceAllowlist -contains $normalized
    }
    return $true
}

function Set-ImportValue {
    param(
        [string] $Text,
        [string] $Key,
        [string] $Value
    )

    $pattern = '(?m)^' + [regex]::Escape($Key) + '=.*$'
    if ($Text -notmatch $pattern) {
        throw "Missing import setting: $Key"
    }
    return [regex]::Replace($Text, $pattern, "$Key=$Value")
}

$updatedTextureImports = 0
$disabledUiMipmaps = 0
$violations = [System.Collections.Generic.List[string]]::new()
$textureImports = Get-ChildItem -LiteralPath (Join-Path $projectRoot "assets") -Recurse -File -Filter "*.png.import"
foreach ($importFile in $textureImports) {
    $relativeImport = Normalize-ProjectPath $importFile.FullName.Substring($projectRoot.Length + 1)
    $relativeImage = $relativeImport.Substring(0, $relativeImport.Length - ".import".Length)
    if (-not (Test-RuntimeTextureCandidate $relativeImage)) {
        continue
    }

    $imagePath = Join-Path $projectRoot $relativeImage
    if (-not (Test-Path -LiteralPath $imagePath -PathType Leaf)) {
        continue
    }
    $image = [System.Drawing.Image]::FromFile($imagePath)
    try {
        $width = $image.Width
        $height = $image.Height
    } finally {
        $image.Dispose()
    }

    $text = Get-Content -Raw -LiteralPath $importFile.FullName
    $sizeLimit = 0
    if ($text -match '(?m)^process/size_limit=(\d+)$') {
        $sizeLimit = [int]$Matches[1]
    }
    $scale = 1.0
    if ($sizeLimit -gt 0 -and [Math]::Max($width, $height) -gt $sizeLimit) {
        $scale = $sizeLimit / [double][Math]::Max($width, $height)
    }
    $effectivePixels = [Math]::Round($width * $height * $scale * $scale)
    if ($effectivePixels -lt 262144) {
        continue
    }

    $next = Set-ImportValue -Text $text -Key "compress/mode" -Value "2"
    $next = Set-ImportValue -Text $next -Key "compress/high_quality" -Value "true"
    $next = $next -replace '"vram_texture": false', '"vram_texture": true'
    $isUiTexture = $relativeImage -match '(?i)^assets/content/(ui|icons)/' -or $relativeImage -match '(?i)^assets/loading/'
    if ($isUiTexture) {
        $next = Set-ImportValue -Text $next -Key "mipmaps/generate" -Value "false"
        $disabledUiMipmaps++
    }
    if ($next -ne $text) {
        if ($Check) {
            $violations.Add($relativeImport)
        } else {
            Set-Content -LiteralPath $importFile.FullName -Value $next -NoNewline -Encoding UTF8
            $updatedTextureImports++
        }
    }
}

$updatedMusicImports = 0
foreach ($importFile in Get-ChildItem -LiteralPath (Join-Path $projectRoot "assets/music") -File -Filter "*.ogg.import") {
    $text = Get-Content -Raw -LiteralPath $importFile.FullName
    $next = Set-ImportValue -Text $text -Key "loop" -Value "true"
    if ($next -ne $text) {
        if ($Check) {
            $relativeImport = Normalize-ProjectPath $importFile.FullName.Substring($projectRoot.Length + 1)
            $violations.Add($relativeImport)
        } else {
            Set-Content -LiteralPath $importFile.FullName -Value $next -NoNewline -Encoding UTF8
            $updatedMusicImports++
        }
    }
}

if ($Check) {
    if ($violations.Count -gt 0) {
        throw "Performance import settings are stale: $($violations -join ', ')"
    }
    Write-Output "performance-import-contracts-ok"
    exit 0
}

Write-Output "VRAM-compressed texture imports updated: $updatedTextureImports"
Write-Output "UI/loading mipmap imports disabled: $disabledUiMipmaps"
Write-Output "Streaming music loop imports updated: $updatedMusicImports"
