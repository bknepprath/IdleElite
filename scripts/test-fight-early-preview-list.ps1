param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fight-early-preview-list"
$testScript = Join-Path $testDir "fight_early_preview_list_test.gd"

New-Item -ItemType Directory -Path $testDir -Force | Out-Null

@'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("fight-early-preview-list-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	scene.get("activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")

	var fight := (scene.skills.get("fight", {}) as Dictionary).duplicate(true)
	fight["level"] = 2
	fight["xp"] = SkillState.xp_for_level(2)
	scene.skills["fight"] = fight
	scene.call("_activity_unlock_runtime").call("_mark_action_manually_unlocked", "fight", scene.TUTORIAL_LEVEL_TWO_ACTION_ID)
	scene._onboarding_runtime().tutorial_active = false
	scene._onboarding_runtime().onboarding_tutorial_complete = false
	scene._onboarding_runtime().skill_swipe_tip_seen = false
	scene._onboarding_runtime().tutorial_gate_latch_only_until_swipe = true

	var visible_ids := []
	for raw_action in scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", "fight") as Array:
		visible_ids.append(str((raw_action as Dictionary).get("id", "")))
	_expect(visible_ids.has(scene.TUTORIAL_GATE_LATCH_ACTION_ID), "level 3 combo preview missing: %s" % str(visible_ids))
	_expect(visible_ids.has(scene.TUTORIAL_DEFERRED_AFTER_GATE_ACTION_ID), "level 4 fight preview missing: %s" % str(visible_ids))
	if failed:
		quit(1)
		return
	print("fight-early-preview-list-ok visible=%s" % str(visible_ids))
	quit(0)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error(message)
	print("fight-early-preview-list-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

$output = & $runner --path $projectRoot --script "res://.codex-tmp/fight-early-preview-list/fight_early_preview_list_test.gd" 2>&1
$output | Write-Output
Assert-True (($output | Out-String) -match "fight-early-preview-list-ok") "Fight early preview list test did not report success."
