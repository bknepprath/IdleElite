$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$docsDir = Join-Path $projectRoot "docs"
$page = "fishing-rework-brainstorm.html"

if ($args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($args[0])) {
    $page = $args[0]
}

$target = Join-Path $docsDir $page
if (-not (Test-Path -LiteralPath $target)) {
    throw "Doc not found: $target"
}

Start-Process -FilePath $target
Write-Output "Opened $target in your default browser."
