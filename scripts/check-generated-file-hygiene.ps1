$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$gitignorePath = Join-Path $projectRoot ".gitignore"
$hygieneDocPath = Join-Path $projectRoot "docs\generated-file-hygiene.md"
$assetAuditPath = Join-Path $projectRoot "docs\asset-file-structure-audit.md"

Assert-True (Test-Path -LiteralPath $gitignorePath) "Missing .gitignore."
Assert-True (Test-Path -LiteralPath $hygieneDocPath) "Missing docs\generated-file-hygiene.md."
Assert-True (Test-Path -LiteralPath $assetAuditPath) "Missing docs\asset-file-structure-audit.md."

$gitignore = Get-Content -LiteralPath $gitignorePath -Raw
$hygieneDoc = Get-Content -LiteralPath $hygieneDocPath -Raw
$assetAudit = Get-Content -LiteralPath $assetAuditPath -Raw

foreach ($requiredIgnore in @(
    ".godot/",
    ".firebase/",
    ".codex-tools/",
    ".codex-tmp/",
    "export/",
    "builds/",
    "release/",
    "output/",
    "test-results/",
    "android/build/.gradle/",
    "android/build/build/",
    "android/build/assetPack*/",
    "android/build/libs/debug/",
    "android/build/libs/release/",
    "firebase-leaderboard-config.json",
    "docs/loading-flex-preview.html",
    "assets/loading/blue-guy-flex-loading-spritesheet*.png",
    "!assets/loading/blue-guy-flex-loading-spritesheet.png"
)) {
    Assert-True ($gitignore.Contains($requiredIgnore)) ".gitignore is missing generated-file rule: $requiredIgnore"
}

Assert-True ($gitignore -notmatch '(?m)^\*\.import$') ".gitignore must not ignore every .import file; runtime import metadata can be required."
Assert-True ($gitignore -notmatch '(?m)^\*\.uid$') ".gitignore must not ignore every .uid file; tracked Godot/addon metadata can be required."

foreach ($requiredDocTerm in @(
    ".import",
    ".uid",
    "source/provenance archive",
    "output/",
    "test-results/",
    ".godot/",
    "firebase-leaderboard-config.json",
    "check-runtime-asset-paths.ps1"
)) {
    Assert-True ($hygieneDoc.Contains($requiredDocTerm)) "Generated-file hygiene doc is missing required term: $requiredDocTerm"
}

Assert-True ($hygieneDoc -match 'Do not add a broad `\*\.import` ignore rule') "Generated-file hygiene doc should forbid broad .import ignores."
Assert-True ($hygieneDoc -match 'Do not add a broad `\*\.uid` ignore rule') "Generated-file hygiene doc should forbid broad .uid ignores."
Assert-True ($hygieneDoc -match 'Keep the source/provenance archive outside the project') "Generated-file hygiene doc should keep the art-source archive outside the project."

Assert-True ($assetAudit -match 'Godot `\.import` metadata is no longer tracked under `docs/art-source/asset-sources/\*\*`') "Asset audit should preserve the docs-side .import cleanup decision."
Assert-True ($assetAudit -match 'Existing dirty/untracked files include navigation-control imports, Blue Guy loading files/imports, UI script UIDs, `output/`, and `test-results/`') "Asset audit should name current generated-file noise so future agents do not stage it casually."

Assert-True (-not (Test-Path -LiteralPath (Join-Path $projectRoot "docs\art-source"))) "docs/art-source should stay outside the runtime repository."

$trackedOutputFiles = @(git -C $projectRoot ls-files -- output test-results)
Assert-True ($trackedOutputFiles.Count -eq 0) "output/ and test-results/ should not contain tracked files."

Write-Output "generated-file-hygiene-ok"
