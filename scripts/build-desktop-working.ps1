param(
    [string]$BuildRoot = 'H:\Codex\Scratch\IdleElite\desktop-build',
    [string]$OutputRoot = 'H:\Codex\Projects\IdleElite\outputs\v0.7.0',
    [switch]$PrepareOnly
)
$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
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
& $runner --headless --path $BuildRoot --export-release Web (Join-Path $OutputRoot 'web\index.html') *>> $log
if ($LASTEXITCODE -ne 0) { throw "Web export failed. See $log" }
& $runner --headless --path $BuildRoot --export-release 'Windows Desktop' (Join-Path $OutputRoot 'windows\Idle Elite.exe') *>> $log
if ($LASTEXITCODE -ne 0) { throw "Windows export failed. See $log" }
Compress-Archive -Path (Join-Path $OutputRoot 'web\*') -DestinationPath (Join-Path $OutputRoot 'idle-elite-v0.7.0-itch-web.zip') -Force
Compress-Archive -Path (Join-Path $OutputRoot 'windows\*') -DestinationPath (Join-Path $OutputRoot 'idle-elite-v0.7.0-windows.zip') -Force
Get-ChildItem -LiteralPath $OutputRoot -Filter '*.zip' | ForEach-Object { Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256 }
Write-Output 'desktop-working-build-ok'
