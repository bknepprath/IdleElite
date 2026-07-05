$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\mission-ceremony"
$testScript = Join-Path $testDir "mission_completion_ceremony_test.gd"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
if (Test-Path -LiteralPath $testDir) { Remove-Item -LiteralPath $testDir -Recurse -Force }
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree

var test_failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("mission-completion-ceremony-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var packed := load("res://scenes/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	scene.call("_activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	var hub_runtime := scene.call("_hub_runtime") as Object
	hub_runtime.set("hub_missions", [{
		"skill_id": "fight",
		"action_id": "kick-mud-off-boot",
		"target": 1,
		"remaining": 1,
		"assigned_unix": int(scene.call("_unix_now"))
	}])
	var action := scene.call("_action_data", "fight", "kick-mud-off-boot") as Dictionary
	_expect(not action.is_empty(), "mission action should load")
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1080.0, 1080.0) as Dictionary
	var card := built.get("card", {}) as Dictionary
	scene.call("_register_action_card", scene.call("_action_key", "fight", "kick-mud-off-boot"), card)
	var hub_surface := scene.call("_hub_surface") as Object
	hub_surface.call("_sync_hub_mission_badge", card, "fight", action, true)
	var recorded := bool(hub_runtime.call("record_mission_action_completion", "fight", "kick-mud-off-boot"))
	_expect(recorded, "mission completion should be recorded")
	_expect((hub_runtime.get("hub_missions") as Array).is_empty(), "completed one-count mission should be removed")
	_expect(str(scene.last_hub_mission_completion_ceremony_text) == "MISSION ICON POP", "mission completion should trigger icon-pop ceremony, not player-facing text")
	var badge := card.get("mission_badge") as Control
	_expect(badge != null, "mission completion should use the module mission badge")
	_expect(badge == null or (badge.anchor_left == 1.0 and badge.anchor_top == 0.0), "mission pop should stay at the module badge anchor")
	scene.queue_free()
	if test_failed:
		quit(1)
		return
	print("mission-completion-ceremony-ok")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	test_failed = true
	push_error(message)
	print("mission-completion-ceremony-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script "res://.codex-tmp/mission-ceremony/mission_completion_ceremony_test.gd" 2>&1
    $output | Write-Output
    Assert-True (($output | Out-String) -match "mission-completion-ceremony-ok") "Mission completion ceremony test did not report success."
}
finally {
    if ($null -eq $previousTimeout) { Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue } else { $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        throw "Headless Godot process left behind after mission completion ceremony test."
    }
}
