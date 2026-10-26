$ErrorActionPreference = 'Stop'
$prototypeRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $prototypeRoot
$env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $prototypeRoot '.codex-tmp/progression-prototype/player'
$env:IDLE_ELITE_DISABLE_ONLINE_REQUESTS = '1'
$env:IDLE_ELITE_DISABLE_SAVE_WRITES = '1'
$env:GODOT_RUN_TIMEOUT_SECONDS = '0'
New-Item -ItemType Directory -Force -Path (Join-Path $prototypeRoot '.codex-tmp/progression-prototype') | Out-Null
& (Join-Path $prototypeRoot 'run-godot-safe.ps1') --visible-game --path $prototypeRoot --script res://scripts/dev/progression_playtest.gd --log-file .codex-tmp/progression-prototype/player.log
exit $LASTEXITCODE
