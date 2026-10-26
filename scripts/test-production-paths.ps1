param([switch]$VisibleGame)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$priorUser=$env:IDLE_ELITE_TEST_USER_DATA_DIR
$priorTimeout=$env:GODOT_RUN_TIMEOUT_SECONDS
try {
 $env:IDLE_ELITE_TEST_USER_DATA_DIR=Join-Path $projectRoot '.codex-tmp/production-test-user'
 $env:GODOT_RUN_TIMEOUT_SECONDS='300'
 foreach($testName in @('production_paths','medal_strategy_oct24')) {
  $log=Join-Path $projectRoot ('.codex-tmp/'+$testName+'-regression.log')
  & (Join-Path $projectRoot 'run-godot-safe.ps1') --headless --path $projectRoot --script ('res://scripts/tests/'+$testName+'.gd') --audio-driver Dummy --log-file $log | Out-Null
  if($LASTEXITCODE -ne 0) { throw "$testName failed" }
  $errors=Get-Content -LiteralPath $log | Where-Object { $_ -match '(SCRIPT ERROR:|ERROR:)' -and $_ -notmatch 'Failed to read the root certificate store' }
  if($errors) { throw ($errors -join [Environment]::NewLine) }
 }
 if($VisibleGame) {
  & (Join-Path $projectRoot 'run-godot-safe.ps1') --visible-game --path $projectRoot --script res://scripts/tests/production_capture.gd --audio-driver Dummy --log-file (Join-Path $projectRoot '.codex-tmp/production-visible.log') | Out-Null
  if($LASTEXITCODE -ne 0) { throw 'Production UI capture failed' }
 }
 'production-paths-ok'
} finally {
 $env:IDLE_ELITE_TEST_USER_DATA_DIR=$priorUser
 $env:GODOT_RUN_TIMEOUT_SECONDS=$priorTimeout
}
