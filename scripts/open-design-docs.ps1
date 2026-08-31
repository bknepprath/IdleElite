$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$docsDir = Join-Path $projectRoot "docs"
$page = "fishing-rework-brainstorm.html"

if ($args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($args[0])) {
    $page = $args[0]
}

$docsRoot = [IO.Path]::GetFullPath($docsDir) + [IO.Path]::DirectorySeparatorChar
$target = [IO.Path]::GetFullPath((Join-Path $docsDir $page))
if (-not $target.StartsWith($docsRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "Doc must be inside $docsDir" }
if (-not (Test-Path -LiteralPath $target)) {
    throw "Doc not found: $target"
}

Start-Process -FilePath $target
Write-Output "Opened $target in your default browser."
