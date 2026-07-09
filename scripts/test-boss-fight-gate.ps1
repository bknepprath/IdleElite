$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\boss-fight\tests"
$testScript = Join-Path $testDir "boss_fight_gate_test.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const RoosterPunchOutStageClass = preload("res://scripts/ui/rooster_punch_out_stage.gd")

var test_failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("boss-fight-gate-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	scene.get("activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	scene.startup_initialized = true
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 9
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(9))
	scene.skills["fight"] = fight
	var boss_action := scene.call("_action_data", "fight", "face-the-rooster") as Dictionary
	_expect(not boss_action.is_empty(), "Rooster boss action should load")
	var fighting_runtime = scene.call("_fighting_runtime")
	_expect(fighting_runtime.call("is_boss_fight_action", boss_action), "Rooster action should be a boss fight")
	_expect(str((boss_action.get("boss", {}) as Dictionary).get("id", "")) == "rooster", "Boss id should normalize")
	var blocked_action := scene.call("_action_data", "fight", "outmuscle-angry-wheelbarrow") as Dictionary
	_expect(not blocked_action.is_empty(), "blocked post-boss action should load")
	_expect(not scene.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", blocked_action), "post-boss action should remain locked before Rooster is cleared")
	_expect(str(scene.call("_missing_action_requirements_text", "fight", blocked_action)).contains("Rooster cleared"), "missing requirements should mention Rooster clear")
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", boss_action, 1080.0, 1080.0) as Dictionary
	var root_control := built.get("card_root") as Control
	_expect(root_control != null and str(root_control.get_meta("boss_stage", "")) == "rooster_punch_out", "Rooster boss should use the Punch-Out stage shell")
	var card := built.get("card", {}) as Dictionary
	var boss_label := card.get("boss_label") as Label
	_expect(boss_label == null, "Rooster Punch-Out boss should not use a boss info chip")
	var rooster_stage: Control = _rooster_stage(card.get("pop") as Control) as Control
	_expect(rooster_stage != null, "Rooster boss card should render the Punch-Out stage")
	_expect(rooster_stage.mouse_filter == Control.MOUSE_FILTER_IGNORE, "inactive Rooster stage should let card taps start the boss")
	var inactive_hp := float(rooster_stage.get("rooster_hp"))
	var inactive_stamina := float(rooster_stage.get("player_stamina"))
	rooster_stage.call("_process", 2.0)
	_expect(is_equal_approx(float(rooster_stage.get("rooster_hp")), inactive_hp), "inactive Rooster stage should not fight on its own")
	_expect(is_equal_approx(float(rooster_stage.get("player_stamina")), inactive_stamina), "inactive Rooster stage should not damage stamina")
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "face-the-rooster", "boss gate test unlock")
	scene.stamina["fight"] = 5.0
	scene.call("_sync_stamina_bank", "fight")
	var boss_key := str(scene.call("_action_key", "fight", "face-the-rooster"))
	scene.call("_register_action_card", boss_key, card)
	scene.call("_fighting_runtime").call("sync_rooster_punch_out_stage_active", card, "fight", "face-the-rooster", false)
	var started := bool(scene.call("_action_runtime").call("_start_action_from_card_tap", "fight", "face-the-rooster", boss_key))
	_expect(started, "Rooster boss should start from the card tap")
	_expect(scene.running_skill_id == "fight" and scene.running_action_id == "face-the-rooster", "Rooster card tap should start the boss fight")
	_expect(rooster_stage.mouse_filter == Control.MOUSE_FILTER_STOP, "running Rooster stage should own punch taps")
	var xp_before_timer := int((scene.skills["fight"] as Dictionary).get("xp", 0))
	scene.call("_action_runtime").call("_process_action", 4.0)
	_expect(int((scene.skills["fight"] as Dictionary).get("xp", 0)) == xp_before_timer, "Rooster boss should not grant normal timed activity XP")
	_expect(not bool(scene.completed_bosses.get("rooster", false)), "Rooster should not clear from the normal activity timer")
	rooster_stage.emit_signal("boss_defeated")
	_expect(bool(scene.completed_bosses.get("rooster", false)), "Rooster should be saved as completed after KO")
	_expect(str(scene.last_result).contains("Rooster cleared"), "completion result should mention the boss clear")
	_expect(int((scene.skills["fight"] as Dictionary).get("xp", 0)) > xp_before_timer, "Rooster KO should grant one XP reward")
	_expect((scene.call("_pending_activity_readiness_action_ids", "fight") as Array).has("outmuscle-angry-wheelbarrow"), "post-boss action lockpad should be queued after Rooster is cleared")
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "outmuscle-angry-wheelbarrow", "boss gate test unlock")
	_expect(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", blocked_action), "post-boss action should unlock after Rooster is cleared")
	var payload := scene.call("_save_runtime").call("_save_payload", int(scene.call("_unix_now"))) as Dictionary
	_expect(bool((payload.get("completed_bosses", {}) as Dictionary).get("rooster", false)), "completed boss should save")
	scene.queue_free()
	if test_failed:
		quit(1)
		return
	print("boss-fight-gate-ok")
	quit(0)


func _rooster_stage(root_control: Control):
	if root_control == null:
		return null
	for child in root_control.get_children():
		if child is RoosterPunchOutStageClass:
			return child as RoosterPunchOutStageClass
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	test_failed = true
	push_error(message)
	print("boss-fight-gate-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script "res://.codex-tmp/boss-fight/tests/boss_fight_gate_test.gd" 2>&1
    $output | Write-Output
    Assert-True (($output | Out-String) -match "boss-fight-gate-ok") "Boss fight gate test did not report success."
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        throw "Headless Godot process left behind after boss fight gate test."
    }
}
