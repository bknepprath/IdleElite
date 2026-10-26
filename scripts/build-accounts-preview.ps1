param([switch]$Release)
$ErrorActionPreference = 'Stop'
$stage = 'H:\Codex\Scratch\IdleElite\desktop-build'
$output = 'H:\Codex\Projects\IdleElite\outputs\accounts-preview'
$source = Split-Path -Parent $PSScriptRoot
$env:TEMP = 'H:\Codex\Scratch\IdleElite\temp'
$env:TMP = $env:TEMP
$env:GODOT_BIN = (Get-Command godot).Source
$env:GODOT_RUN_TIMEOUT_SECONDS = '900'
$projectPath = Join-Path $stage 'project.godot'
$original = [IO.File]::ReadAllText($projectPath)
$preview = $original.Replace('[application]', "[application]`nconfig/web_accounts=true")
[IO.File]::WriteAllText($projectPath, $preview)
$beforeImports = @(git -C $source status --porcelain=v1 -- '*.import')
git -C $source status --short | Set-Content (Join-Path $output 'status-before-import.txt')
try {
    & (Join-Path $stage 'run-godot-safe.ps1') --headless --path $stage --import *> (Join-Path $output 'import.log')
    if ($LASTEXITCODE -ne 0 -or (Select-String (Join-Path $output 'import.log') -Pattern 'SCRIPT ERROR:|Parse Error:')) { throw 'Account preview import failed' }
    $exportMode = if ($Release) { '--export-release' } else { '--export-debug' }
    & (Join-Path $stage 'run-godot-safe.ps1') --headless --path $stage $exportMode Web (Join-Path $output 'web\index.html') *> (Join-Path $output 'export.log')
    if ($LASTEXITCODE -ne 0) { throw 'Account preview export failed' }
} finally {
    [IO.File]::WriteAllText($projectPath, $original)
    git -C $source status --porcelain=v1 | Set-Content (Join-Path $output 'status-after-import.txt')
    $afterImports = @(git -C $source status --porcelain=v1 -- '*.import')
    if (($beforeImports -join "`n") -cne ($afterImports -join "`n")) { throw 'Source imports changed unexpectedly' }
    Get-Process -Name '*godot*' -ErrorAction SilentlyContinue | Select-Object Id,ProcessName
}
Write-Output 'accounts-preview-export-ok'
Set-Content (Join-Path $output 'build-kind.txt') $(if ($Release) { 'release' } else { 'debug' })
