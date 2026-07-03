param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fight-modules"
$testScript = Join-Path $testDir "fight_modules_clickable_test.gd"

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

New-Item -ItemType Directory -Path $testDir -Force | Out-Null

@'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("fight-modules-clickable-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	scene.call("_activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	_unlock_fight(scene)
	var tested := 0
	var skipped_locked := 0
	var fight_actions := scene.call("_visible_actions_for_skill", "fight") as Array
	for raw_action in fight_actions:
		var action := raw_action as Dictionary
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		if not bool(scene.call("_is_action_unlocked", "fight", action)):
			skipped_locked += 1
			continue
		var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1080.0, 1080.0) as Dictionary
		var card := built.get("card", {}) as Dictionary
		var root_control := built.get("card_root") as Control
		_expect(root_control != null, "%s card root should build" % action_id)
		_expect(not card.is_empty(), "%s card dictionary should build" % action_id)
		var key := str(scene.call("_action_key", "fight", action_id))
		scene.call("_register_action_card", key, card)
		var was_built := BuildableModules.is_built(scene.built_modules, "fight", action, Callable(scene, "_action_key"))
		var started := bool(scene.call("_start_action_from_card_tap", "fight", action_id, key))
		var is_buildable := BuildableModules.is_buildable(action)
		var now_built := BuildableModules.is_built(scene.built_modules, "fight", action, Callable(scene, "_action_key"))
		var built_from_tap := is_buildable and not was_built and now_built
		_expect(started or built_from_tap, "%s should start or build from card tap" % action_id)
		if started:
			_expect(str(scene.get("running_skill_id")) == "fight", "%s should set running skill" % action_id)
			_expect(str(scene.get("running_action_id")) == action_id, "%s should set running action" % action_id)
		_reset_running_action(scene)
		tested += 1
	_expect(tested >= 6, "expected multiple visible unlocked fight modules to be tested")
	scene.queue_free()
	if failed:
		quit(1)
		return
	print("fight-modules-clickable-ok tested=%d skipped_locked=%d" % [tested, skipped_locked])
	quit(0)

func _unlock_fight(scene: Node) -> void:
	for raw_skill_id in (scene.skills as Dictionary).keys():
		var skill_id := str(raw_skill_id)
		var skill := scene.skills[raw_skill_id] as Dictionary
		skill["level"] = 30
		skill["xp"] = maxi(int(skill.get("xp", 0)), SkillState.xp_for_level(30))
		scene.skills[raw_skill_id] = skill
	scene.stamina["fight"] = 999.0
	scene.completed_bosses["rooster"] = true
	scene.completed_bosses["chicken"] = true
	scene.call("_sync_manual_activity_unlocks_from_levels")
	if scene.has_method("_sync_stamina_bank"):
		scene.call("_sync_stamina_bank", "fight")
	for mat_id in ["scrapwood", "softwood", "hardwood", "wood", "stone", "berries"]:
		scene.material_runtime.add_amount(mat_id, 999.0)

func _reset_running_action(scene: Node) -> void:
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("last_action_card_tap_key", "")
	scene.set("last_action_card_tap_msec", 0)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)

func _fail(message: String) -> void:
	failed = true
	push_error(message)
	print("fight-modules-clickable-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

$output = & $runner --path $projectRoot --script "res://.codex-tmp/fight-modules/fight_modules_clickable_test.gd" 2>&1
$output | Write-Output
Assert-True (($output | Out-String) -match "fight-modules-clickable-ok") "Fight modules clickable test did not report success."
