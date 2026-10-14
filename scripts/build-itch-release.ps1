# Builds the itch.io web zip from the committed HEAD.
#
# The game's large textures import as high-quality VRAM formats for Android (ASTC) and
# desktop (BPTC). A web export would carry both copies (~450 MB index.pck), over itch's
# 200 MB single-file limit. This script exports from a throwaway git worktree whose large
# textures are switched to lossy WebP (~50 MB pck), so the real project's imports and the
# Android build are never touched.
#
#   .\scripts\build-itch-release.ps1              -> builds\itch\idle-elite-itch-web-v<ver>-code<code>.zip
#   .\scripts\build-itch-release.ps1 -Upload      -> also uploads with Butler (see package-itch-web.ps1)
param(
    [switch] $Upload,
    [double] $LossyQuality = 0.82
)
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$itchBuildDir = Join-Path $projectRoot "builds\itch"
$worktree = Join-Path (Split-Path -Parent $projectRoot) ("idle-elite-itch-build-" + [guid]::NewGuid().ToString("N").Substring(0, 8))

$dirty = @(git -C $projectRoot status --porcelain --untracked-files=no)
Assert-True ($dirty.Count -eq 0) "Commit your changes first: the itch build is exported from HEAD."

# Same validations the itch packager runs, against the real project.
& (Join-Path $projectRoot "scripts\update-firebase-leaderboard-rules.ps1") -Check
& (Join-Path $projectRoot "scripts\check-leaderboard-cost-safety.ps1")
& (Join-Path $projectRoot "scripts\test-save-hardening.ps1")
& (Join-Path $projectRoot "scripts\test-save-lifecycle-guard.ps1")
& (Join-Path $projectRoot "scripts\check-runtime-asset-paths.ps1")

$ErrorActionPreference = "Continue"
git -C $projectRoot worktree add --detach $worktree HEAD 2>&1 | Out-Null
$ErrorActionPreference = "Stop"
Assert-True ($LASTEXITCODE -eq 0) "Could not create the temporary build worktree."
try {
    # Reuse the import cache so only the switched textures are re-imported.
    $godotCache = Join-Path $projectRoot ".godot"
    if (Test-Path -LiteralPath $godotCache) {
        Copy-Item -LiteralPath $godotCache -Destination (Join-Path $worktree ".godot") -Recurse -Force
    }
    $firebaseConfig = Join-Path $projectRoot "firebase-leaderboard-config.json"
    if (Test-Path -LiteralPath $firebaseConfig) {
        Copy-Item -LiteralPath $firebaseConfig -Destination $worktree -Force
    }

    # Only image imports: audio .import files use the same compress/mode key for a different setting.
    $converted = 0
    Get-ChildItem -LiteralPath (Join-Path $worktree "assets") -Recurse -File -Include "*.png.import", "*.jpg.import", "*.jpeg.import", "*.webp.import" | ForEach-Object {
        $text = [IO.File]::ReadAllText($_.FullName)
        if ($text -match '(?m)^compress/mode=2\r?$') {
            $text = [regex]::Replace($text, '(?m)^compress/mode=2(\r?)$', 'compress/mode=1$1')
            $text = [regex]::Replace($text, '(?m)^compress/lossy_quality=[^\r\n]*', "compress/lossy_quality=$LossyQuality")
            [IO.File]::WriteAllText($_.FullName, $text, (New-Object Text.UTF8Encoding($false)))
            # A copied .md5 cache can leave the old VRAM remap valid even after
            # changing compression. Missing generated destinations force Godot
            # to rebuild this texture and rewrite the remap for the web export.
            $cacheRoot = [IO.Path]::GetFullPath((Join-Path $worktree '.godot/imported')) + [IO.Path]::DirectorySeparatorChar
            $cachedTextures = [regex]::Matches($text, 'res://\.godot/imported/[^"\r\n]+\.ctex') | ForEach-Object { $_.Value } | Select-Object -Unique
            foreach ($cachedTexture in $cachedTextures) {
                $cachedPath = [IO.Path]::GetFullPath((Join-Path $worktree $cachedTexture.Substring(6)))
                Assert-True ($cachedPath.StartsWith($cacheRoot, [StringComparison]::OrdinalIgnoreCase)) 'Generated texture must remain inside the temporary import cache.'
                if (Test-Path -LiteralPath $cachedPath -PathType Leaf) {
                    Remove-Item -LiteralPath $cachedPath -Force
                }
            }
            $converted++
        }
    }
    Write-Output "Switched $converted large textures to lossy WebP for the web export."

    $previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
    $env:GODOT_RUN_TIMEOUT_SECONDS = "2400"
    try {
        & (Join-Path $worktree "run-godot-safe.ps1") --headless --path $worktree --import
    } finally {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }

    $packageArgs = @{ SkipValidation = $true }
    if ($Upload) { $packageArgs["Upload"] = $true }
    & (Join-Path $worktree "scripts\package-itch-web.ps1") @packageArgs

    New-Item -ItemType Directory -Force -Path $itchBuildDir | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $worktree "builds\itch") -Filter "*.zip" | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $itchBuildDir -Force
        Write-Output "Itch zip: $(Join-Path $itchBuildDir $_.Name)"
    }
} finally {
    $ErrorActionPreference = "Continue"
    git -C $projectRoot worktree remove --force $worktree 2>&1 | Out-Null
}
Write-Output "itch-release-build-ok"
