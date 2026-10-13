$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'lib/godot-processes.ps1')
$output = & (Join-Path $projectRoot 'run-godot-safe.ps1') --path $projectRoot --script res://scripts/tests/activity_completion_save.gd --audio-driver Dummy 2>&1
$runExit = $LASTEXITCODE
$output | Out-Host
Assert-NoHeadlessGodotProcesses 'activity completion persistence'
Assert-NoUnexpectedGodotErrors $output 'activity completion persistence'
Assert-True ($runExit -eq 0 -and ($output | Out-String).Contains('activity-completion-save-ok')) 'Activity completion persistence test failed.'
