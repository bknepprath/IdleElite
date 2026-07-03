$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fighting-diamond"
$testScript = Join-Path $testDir "fighting_diamond_arena_test.gd"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

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

const DiamondArenaFrameClass = preload("res://scripts/ui/diamond_arena_frame.gd")

var test_failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("fighting-diamond-arena-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	scene.call("_activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 5
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(5))
	scene.skills["fight"] = fight
	var action := scene.call("_action_data", "fight", "chicken-sparring-pit") as Dictionary
	_expect(not action.is_empty(), "Fight Chickens should load")
	var fighting_runtime = scene.call("_fighting_runtime")
	_expect(fighting_runtime.action_uses_blue_guy_chicken_brawl_stage(action), "Fight Chickens should still use the chicken brawl stage")
	_expect(fighting_runtime.action_uses_diamond_combat_arena(action), "Fight Chickens should opt into the diamond combat arena")
	var combat := action.get("combat", {}) as Dictionary
	_expect(str(combat.get("enemy_id", "")) == "chicken-swarm", "combat enemy id should be normalized from data")
	_expect(float(combat.get("contact_damage", 0.0)) == 8.0, "combat contact damage should be preserved")
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1080.0, 1080.0) as Dictionary
	var root_control := built.get("card_root") as Control
	_expect(root_control != null and str(root_control.get_meta("combat_arena_shape", "")) == "diamond", "card root should mark diamond combat arena shape")
	_expect(root_control.custom_minimum_size.y > scene.call("_activity_card_root_height") * 1.4, "diamond combat arena should stay larger than a normal card")
	_expect(root_control.custom_minimum_size.y < scene.call("_activity_card_root_height") * 1.7, "diamond combat arena should not be double-height")
	var card := built.get("card", {}) as Dictionary
	scene.call("_set_activity_card_expanded", card, root_control, false, true)
	_expect(root_control.custom_minimum_size.y > scene.call("_activity_card_root_height") * 1.4, "diamond combat arena should not shrink to normal card height after stat sync")
	var pop := card.get("pop") as Control
	_expect(_has_diamond_frame(pop), "diamond combat arena should attach a DiamondArenaFrame overlay")
	var stage := card.get("blue_guy_chicken_stage") as Control
	_expect(stage != null and str(stage.get("arena_shape")) == "diamond", "chicken brawl gameplay should render inside the diamond arena")
	stage.size = Vector2(1080.0, 1080.0)
	_check_diamond_chicken_steering(stage)
	stage.set("diamond_stats_tucked", false)
	var open_rect := stage.call("_diamond_stats_plate_draw_rect", 1.0) as Rect2
	_expect(bool(stage.call("_toggle_diamond_stats_if_tapped", open_rect.get_center())), "diamond stat plate should tuck when tapped")
	_expect(bool(stage.get("diamond_stats_tucked")), "diamond stat plate should be tucked after tap")
	var tucked_rect := stage.call("_diamond_stats_plate_draw_rect", 1.0) as Rect2
	_expect(bool(stage.call("_toggle_diamond_stats_if_tapped", tucked_rect.get_center())), "diamond stat tab should reopen when tapped")
	_expect(not bool(stage.get("diamond_stats_tucked")), "diamond stat plate should reopen after second tap")
	scene.queue_free()
	if test_failed:
		quit(1)
		return
	print("fighting-diamond-arena-ok")
	quit(0)


func _has_diamond_frame(root_control: Control) -> bool:
	if root_control == null:
		return false
	for child in root_control.get_children():
		if child is DiamondArenaFrameClass:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _check_diamond_chicken_steering(stage: Control) -> void:
	stage.set("active", true)
	stage.set("hero_pos", Vector2(0.5, 0.55))
	var samples := [
		Vector2(0.04, 0.30),
		Vector2(0.96, 0.38),
		Vector2(0.22, 0.08),
		Vector2(0.78, 0.92),
	]
	for i in range(samples.size()):
		var chicken := {
			"id": i + 1,
			"pos": samples[i],
			"hp": 30.0,
			"max_hp": 30.0,
			"attack_cd": 9.0,
			"lunge_timer": 0.0,
			"uppercut_knock_timer": 0.0,
			"hit_flash": 0.0,
			"uppercut_pop": 0.0,
			"dead_timer": 0.0,
			"damage_done": false,
			"speed": 0.45,
			"variant": "white",
			"damage": 1.0
		}
		var before: float = samples[i].distance_to(Vector2(0.5, 0.55))
		stage.call("_step_chicken", chicken, 0.6)
		var after: float = (chicken.get("pos", samples[i]) as Vector2).distance_to(Vector2(0.5, 0.55))
		_expect(after < before, "diamond chicken steering should move sample %d toward blue guy" % i)


func _fail(message: String) -> void:
	test_failed = true
	push_error(message)
	print("fighting-diamond-arena-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script "res://.codex-tmp/fighting-diamond/fighting_diamond_arena_test.gd" 2>&1
    $output | Write-Output
    Assert-True (($output | Out-String) -match "fighting-diamond-arena-ok") "Fighting diamond arena test did not report success."
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
        throw "Headless Godot process left behind after fighting diamond arena test."
    }
}
