param([switch]$VisibleGame)
$ErrorActionPreference='Stop'
$projectRoot=Split-Path -Parent $PSScriptRoot
$names=@('GODOT_BIN','GODOT_RUN_TIMEOUT_SECONDS','IDLE_ELITE_TEST_USER_DATA_DIR','IDLE_ELITE_ART_AUDIT_OUTPUT')
$previous=@{}
foreach($name in $names) { $previous[$name]=[Environment]::GetEnvironmentVariable($name,'Process') }
try {
 if(-not $env:GODOT_BIN) { $env:GODOT_BIN=(Get-Command godot -ErrorAction Stop).Source }
 $env:GODOT_RUN_TIMEOUT_SECONDS='300'
 $env:IDLE_ELITE_TEST_USER_DATA_DIR=Join-Path $projectRoot '.codex-tmp/fishing-entry-user'
 $env:IDLE_ELITE_ART_AUDIT_OUTPUT='res://outputs/verification/fishing-tool-entry-oct24'
 $log=Join-Path $projectRoot '.codex-tmp/fishing-tool-entry.log'
 $arguments=@('--path',$projectRoot,'--script','res://scripts/tests/fishing_tool_entry.gd','--audio-driver','Dummy','--log-file',$log)
 if($VisibleGame) { $arguments=@('--visible-game')+$arguments }
 & (Join-Path $projectRoot 'run-godot-safe.ps1') @arguments | Out-Null
 $output=Get-Content -LiteralPath $log
 $errors=$output | Where-Object { $_ -match '(SCRIPT ERROR:|ERROR:)' -and $_ -notmatch 'Failed to read the root certificate store' }
 if($LASTEXITCODE -ne 0 -or $errors -or ($output -join "`n") -notmatch 'FISHING_TOOL_ENTRY failures=\[\]') { throw 'Fishing tool entry validation failed' }
 'fishing-tool-entry-ok'
} finally {
 foreach($name in $names) { [Environment]::SetEnvironmentVariable($name,$previous[$name],'Process') }
}
