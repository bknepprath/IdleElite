param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\tutorial-swipe-navigation"
$testScript = Join-Path $testDir "tutorial_swipe_navigation_test.gd"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

New-Item -ItemType Directory -Path $testDir -Force | Out-Null

@'
extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("tutorial-swipe-navigation-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	scene.get("activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	scene._onboarding_runtime().tutorial_active = true
	scene._onboarding_runtime().tutorial_step = 1
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", scene.TUTORIAL_STARTER_SKILL_ID)
	var target_skill := _first_non_starter_skill(scene)
	if target_skill.is_empty():
		_fail("no non-starter skill found")
		return
	scene.call("_navigation_shell").call("_select_skill_with_initial_scroll", target_skill, false, -1, false)
	await process_frame
	if str(scene.get("selected_skill_id")) != target_skill:
		_fail("tutorial should not block skill navigation; selected=%s target=%s" % [str(scene.get("selected_skill_id")), target_skill])
		return
	var visible := scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", target_skill) as Array
	if visible.is_empty():
		_fail("target skill should have visible modules")
		return
	print("tutorial-swipe-navigation-ok target=%s visible=%d" % [target_skill, visible.size()])
	quit(0)

func _first_non_starter_skill(scene: Node) -> String:
	for raw_def in scene.skill_defs:
		var skill_id := str((raw_def as Dictionary).get("id", ""))
		if not skill_id.is_empty() and skill_id != scene.TUTORIAL_STARTER_SKILL_ID:
			return skill_id
	return ""

func _fail(message: String) -> void:
	push_error(message)
	print("tutorial-swipe-navigation-failed: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

$output = & $runner --path $projectRoot --script "res://.codex-tmp/tutorial-swipe-navigation/tutorial_swipe_navigation_test.gd" 2>&1
$output | Write-Output
Assert-True (($output | Out-String) -match "tutorial-swipe-navigation-ok") "Tutorial swipe navigation test did not report success."
