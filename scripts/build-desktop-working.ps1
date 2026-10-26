param(
    [string]$BuildRoot = 'H:\Codex\Scratch\IdleElite\desktop-build',
    # The version this build carries. A build for itch.io has a lowercase i at the
    # end of its version, like 0.7.1i (Brian, 2026-10-18). It has to be given: the
    # project's own version is not taken, so that no build goes out under the
    # number of the one before it.
    [string]$Version = '',
    # Left empty: outputs\v<Version>.
    [string]$OutputRoot = '',
    [switch]$PrepareOnly
)
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
if ($Version -cnotmatch '^\d+\.\d+\.\d+i$') {
    throw "Give -Version as three numbers and a lowercase i, like 0.7.1i: an itch.io build's version ends in i. Got '$Version'."
}
$baseVersion = $Version.Substring(0, $Version.Length - 1)
if (-not $OutputRoot) { $OutputRoot = "H:\Codex\Projects\IdleElite\outputs\v$Version" }
$volume = Get-Volume -DriveLetter H
if ($volume.FileSystemLabel -ne 'Flareon 4TB' -or $volume.SizeRemaining -lt 12GB) {
    throw 'Expected Flareon 4TB with at least 12 GB available.'
}
New-Item -ItemType Directory -Force -Path $BuildRoot,$OutputRoot,(Join-Path $OutputRoot 'web'),(Join-Path $OutputRoot 'windows'),'H:\Codex\Scratch\IdleElite\temp' | Out-Null
$env:TEMP = 'H:\Codex\Scratch\IdleElite\temp'
$env:TMP = $env:TEMP
$env:TMPDIR = $env:TEMP
$env:IDLE_ELITE_BUILD_SOURCE = $sourceRoot
$env:IDLE_ELITE_BUILD_ROOT = $BuildRoot
$env:IDLE_ELITE_BUILD_OUTPUT = $OutputRoot
# One reusable build snapshot, including working changes. No commits or source imports are changed.
@'
import pathlib, os, subprocess, shutil, re, hashlib, json
source=pathlib.Path(os.environ['IDLE_ELITE_BUILD_SOURCE'])
dest=pathlib.Path(os.environ['IDLE_ELITE_BUILD_ROOT'])
files=subprocess.check_output(['git','-C',str(source),'ls-files','-co','--exclude-standard','-z']).decode().split('\0')
allowed=('assets/','addons/','scenes/','scripts/','shaders/','fonts/','data/','translations/')
root_files={'project.godot','export_presets.cfg','run-godot-safe.ps1','firebase-leaderboard-config.json','icon.svg','icon.svg.import','docs/activity-database.json'}
# git does not list an ignored file, and firebase-leaderboard-config.json is ignored.
# A build without it starts with no high scores, chat or name claim.
files+=[rel for rel in root_files if (source/rel).is_file()]
manifest={}
copied=0
for rel in sorted(set(files)):
    if not rel or not (rel.startswith(allowed) or rel in root_files): continue
    src=source/rel
    if not src.is_file(): continue
    target=dest/rel
    target.parent.mkdir(parents=True,exist_ok=True)
    if rel.endswith(('.png.import','.jpg.import','.jpeg.import','.webp.import')):
        text=src.read_text(encoding='utf-8-sig')
        text=re.sub(r'(?m)^compress/mode=2\s*$', 'compress/mode=1',text)
        text=re.sub(r'(?m)^compress/lossy_quality=[^\r\n]*','compress/lossy_quality=0.82',text)
        if not target.exists() or target.read_text(encoding='utf-8-sig') != text:
            target.write_text(text,encoding='utf-8');copied+=1
    elif not target.exists() or src.stat().st_size!=target.stat().st_size or abs(src.stat().st_mtime-target.stat().st_mtime)>1:
        shutil.copy2(src,target);copied+=1
    if rel.startswith(('scripts/','scenes/')) or rel in root_files:
        manifest[rel]=hashlib.sha256(src.read_bytes()).hexdigest()
pathlib.Path(os.environ['IDLE_ELITE_BUILD_OUTPUT'],'source-manifest.json').write_text(json.dumps(manifest,indent=2))
print(f'Updated {copied} files in the reusable desktop snapshot.')
'@ | python -
if ($LASTEXITCODE -ne 0) { throw 'Snapshot preparation failed.' }
if ($PrepareOnly) { return }
# A build does not write over an earlier one's zips.
$webZip = Join-Path $OutputRoot "idle-elite-v${Version}-itch-web.zip"
$windowsZip = Join-Path $OutputRoot "idle-elite-v${Version}-windows.zip"
foreach ($zip in @($webZip, $windowsZip)) {
    if (Test-Path -LiteralPath $zip) { throw "$zip is there already. Give a new -OutputRoot." }
}
# The build's own copy of the project is given the version; the working tree's
# project.godot is not touched. The number stays a plain one (the Windows export
# makes its file version from it), and the i is a setting of its own, which the
# game puts after the number wherever it shows its version.
$buildProject = Join-Path $BuildRoot 'project.godot'
$projectText = [System.IO.File]::ReadAllText($buildProject)
$newline = if ($projectText.Contains("`r`n")) { "`r`n" } else { "`n" }
$projectText = [regex]::Replace($projectText, '(?m)^config/version_suffix="[^"]*"\r?\n', '')
$stampedText = [regex]::Replace($projectText, '(?m)^config/version="[^"]*"', ('config/version="' + $baseVersion + '"' + $newline + 'config/version_suffix="i"'))
[System.IO.File]::WriteAllText($buildProject, $stampedText, (New-Object System.Text.UTF8Encoding($false)))
$stampedLines = @(Select-String -LiteralPath $buildProject -Pattern '^config/version(_suffix)?="' | ForEach-Object { $_.Line })
if ($stampedLines.Count -ne 2 -or $stampedLines[0] -cne ('config/version="' + $baseVersion + '"') -or $stampedLines[1] -cne 'config/version_suffix="i"') {
    throw "The version could not be written into the build's copy of project.godot: $($stampedLines -join ' | ')"
}
Set-Content -LiteralPath (Join-Path $OutputRoot 'build-version.txt') -Value $Version
$beforeStatus = @(git -C $sourceRoot status --short)
$beforeImports = @(git -C $sourceRoot status --porcelain=v1 -- '*.import')
$beforeStatus | Set-Content -LiteralPath (Join-Path $OutputRoot 'source-status-before-import.txt')
$env:GODOT_RUN_TIMEOUT_SECONDS = '1800' 
$runner = Join-Path $BuildRoot 'run-godot-safe.ps1'
$log = Join-Path $OutputRoot 'build.log'
& $runner --headless --path $BuildRoot --import *> $log
if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|Parse Error:')) { throw "Import failed. See $log" }
$afterImports = @(git -C $sourceRoot status --porcelain=v1 -- '*.import')
git -C $sourceRoot status --porcelain=v1 | Set-Content -LiteralPath (Join-Path $OutputRoot 'source-status-after-import.txt')
if (($beforeImports -join "`n") -cne ($afterImports -join "`n")) { throw 'Source import status changed during isolated build import; inspect before proceeding.' }
# Only the itch browser package redirects Watch ad to the website.
$itchProject = $stampedText.Replace('[application]', "[application]`nconfig/itch_browser=true")
[System.IO.File]::WriteAllText($buildProject, $itchProject, (New-Object System.Text.UTF8Encoding($false)))
try {
    & $runner --headless --path $BuildRoot --export-release Web (Join-Path $OutputRoot 'web\index.html') *>> $log
} finally {
    [System.IO.File]::WriteAllText($buildProject, $stampedText, (New-Object System.Text.UTF8Encoding($false)))
}
if ($LASTEXITCODE -ne 0) { throw "Web export failed. See $log" }
& $runner --headless --path $BuildRoot --export-release 'Windows Desktop' (Join-Path $OutputRoot 'windows\Idle Elite.exe') *>> $log
if ($LASTEXITCODE -ne 0) { throw "Windows export failed. See $log" }
# The packs must carry the online settings file (by name; its contents are not read here).
foreach ($pack in @((Join-Path $OutputRoot 'web\index.pck'), (Join-Path $OutputRoot 'windows\Idle Elite.pck'))) {
    $env:IDLE_ELITE_BUILD_PACK = $pack
    $found = "import os,sys`nsys.stdout.write(str(open(os.environ['IDLE_ELITE_BUILD_PACK'],'rb').read().count(b'firebase-leaderboard-config.json')))" | python -
    if ($LASTEXITCODE -ne 0 -or [int]$found -lt 1) { throw "The online settings file is not in $pack; this build would have no high scores or chat." }
}
Compress-Archive -Path (Join-Path $OutputRoot 'web\*') -DestinationPath $webZip
Compress-Archive -Path (Join-Path $OutputRoot 'windows\*') -DestinationPath $windowsZip
Get-ChildItem -LiteralPath $OutputRoot -Filter '*.zip' | ForEach-Object { Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256 }
Write-Output 'desktop-working-build-ok'
