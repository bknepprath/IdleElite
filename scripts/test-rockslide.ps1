param([switch]$VisibleGame)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$names=@('GODOT_BIN','GODOT_RUN_TIMEOUT_SECONDS','IDLE_ELITE_TEST_USER_DATA_DIR','IDLE_ELITE_ART_AUDIT_OUTPUT')
$previous=@{}
foreach($name in $names) { $previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process') }
try {
 if(-not $env:GODOT_BIN) { $env:GODOT_BIN=(Get-Command godot -ErrorAction Stop).Source }
 $env:GODOT_RUN_TIMEOUT_SECONDS='180'
 $env:IDLE_ELITE_TEST_USER_DATA_DIR=Join-Path $projectRoot '.codex-tmp/rockslide-test-user'
 $env:IDLE_ELITE_ART_AUDIT_OUTPUT='res://outputs/verification/rockslide-oct24'
 $tests=@('rockslide_gameplay')
 if($VisibleGame) { $tests+= 'rockslide_capture' }
 foreach($test in $tests) {
  $log=Join-Path $projectRoot ('.codex-tmp/'+$test+'.log')
  $arguments=@('--path',$projectRoot,'--script',('res://scripts/tests/'+$test+'.gd'),'--audio-driver','Dummy','--log-file',$log)
  if($test -eq 'rockslide_capture') { $arguments=@('--visible-game')+$arguments }
  & (Join-Path $projectRoot 'run-godot-safe.ps1') @arguments | Out-Null
  $output=Get-Content -LiteralPath $log
  $errors=$output | Where-Object { $_ -match '(SCRIPT ERROR:|ERROR:)' -and $_ -notmatch 'Failed to read the root certificate store' }
  if($LASTEXITCODE -ne 0 -or $errors -or ($output -join "`n") -notmatch 'ROCKSLIDE_(GAMEPLAY|CAPTURE) failures=\[\]') { throw "$test failed" }
 }
 'rockslide-ok'
} finally {
 foreach($name in $names) { [Environment]::SetEnvironmentVariable($name,$previous[$name],'Process') }
}
