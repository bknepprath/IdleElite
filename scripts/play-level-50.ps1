param([switch]$Resume)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$env:GODOT_BIN = (Get-Command godot -ErrorAction Stop).Source
$env:GODOT_RUN_TIMEOUT_SECONDS = '0'
$env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path $projectRoot '.codex-tmp/level-50-groves-oct25'
$env:IDLE_ELITE_RESUME_PLAYTEST = if ($Resume) { '1' } else { '0' }
& (Join-Path $projectRoot 'run-godot-safe.ps1') --visible-game --path $projectRoot --script res://scripts/dev/level_50_playtest.gd --audio-driver Dummy --log-file .codex-tmp/level-50-player.log
