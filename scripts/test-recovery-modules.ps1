$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\recovery-modules\tests"
$testScript = Join-Path $testDir "recovery_modules_test.gd"

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

const RecoveryModules = preload("res://scripts/gameplay/recovery_modules.gd")
const ActivityCardDepth = preload("res://scripts/ui/activity_card_depth.gd")
const ActivityCardStyles = preload("res://scripts/ui/activity_card_styles.gd")
const ActivityProgressRail = preload("res://scripts/ui/activity_progress_rail.gd")

var test_failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("recovery-modules-start")
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
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 7
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(7))
	scene.skills["fight"] = fight
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "wrap-hands", "recovery module test unlock")
	scene.stamina["fight"] = 1.0
	SkillState.host_sync_stamina_bank("fight", scene)
	var action := scene.call("_action_data", "fight", "wrap-hands") as Dictionary
	_expect(not action.is_empty(), "recovery action should load")
	_expect(RecoveryModules.has_recovery(action), "Wrap Hands should have a recovery contract")
	_expect(float(action.get("stamina", 0)) == -3.0, "recovery action should show negative stamina")
	_expect(float(action.get("seconds", 0.0)) >= 8.5, "recovery action should be slow for its stamina value")
	_expect(int(action.get("xp", 0)) == 1, "recovery action should be very low XP")
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1080.0, 1080.0) as Dictionary
	var card := built.get("card", {}) as Dictionary
	var recovery_root := built.get("card_root") as Control
	var normal_action := scene.call("_action_data", "fight", "push-ups") as Dictionary
	var normal_built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", normal_action, 1080.0, 1080.0) as Dictionary
	var normal_root := normal_built.get("card_root") as Control
	_expect(recovery_root != null and normal_root != null and is_equal_approx(recovery_root.custom_minimum_size.y - ActivityCardStyles.RECOVERY_ACTIVITY_CARD_DEPTH_OFFSET.y, normal_root.custom_minimum_size.y - ActivityCardStyles.NORMAL_ACTIVITY_CARD_DEPTH_OFFSET.y), "recovery cards should keep the same front-face height as normal activity cards")
	var depth := card.get("depth") as ActivityCardDepth
	_expect(depth != null and depth.depth_offset.is_equal_approx(ActivityCardStyles.RECOVERY_ACTIVITY_CARD_DEPTH_OFFSET), "recovery cards should expose the same front-face height as normal activity cards")
	var pop := card.get("pop") as Control
	_expect(pop != null and (pop.get_meta("activity_card_press_offset", Vector2.ZERO) as Vector2).is_equal_approx(ActivityCardStyles.NORMAL_ACTIVITY_CARD_PRESS_OFFSET), "recovery cards should press straight down without breaking their depth outline")
	if depth != null:
		var outline_points := depth.call("_wide_u_back_outline_points", Rect2(Vector2.ZERO, Vector2(1080.0, 720.0)), 12.0) as PackedVector2Array
		_expect(outline_points.size() > 60 and outline_points[0].is_equal_approx(outline_points[outline_points.size() - 1]), "recovery depth outline should be one closed stroke")
		_expect(outline_points.has(Vector2(1074.0, 576.0)) and outline_points.has(Vector2(1008.0, 642.0)), "recovery depth outline should round its outer bottom corners")
	var stamina_label := card.get("stamina") as Label
	_expect(stamina_label != null, "recovery card should render a stamina stat chip")
	_expect(stamina_label == null or stamina_label.text == "+3", "recovery card should display the stamina refund as +3")
	var stamina_box := (card.get("stat_boxes", {}) as Dictionary).get("stamina") as Control
	_expect(stamina_box != null and bool(stamina_box.get_meta("normal_activity_stat_box", false)), "recovery cards should use normal activity stat chips")
	_expect(card.get("mastery_ring") as Control != null, "recovery cards should use the normal action-art mastery ring")
	var progress := card.get("progress") as ActivityProgressRail
	_expect(progress != null and progress.bottom_radius >= 64.0 and progress.offset_top < -100.0 and progress.bottom_shape == "wide_u", "recovery card should use the wide U recovery progress rail shape")
	if progress != null:
		var rail_probe := ActivityProgressRail.new()
		rail_probe.size = Vector2(1080.0, 142.0)
		rail_probe.edge_inset = ActivityCardStyles.ACTION_CARD_STROKE_WIDTH
		rail_probe.wide_u_bottom_rise = progress.wide_u_bottom_rise
		rail_probe.wide_u_shoulder_ratio = progress.wide_u_shoulder_ratio
		var outer_start := rail_probe.call("_wide_u_progress_point", 0.0, 100.0) as Vector2
		var inner_start := rail_probe.call("_wide_u_progress_point", 0.0, 88.0) as Vector2
		_expect(outer_start.is_equal_approx(inner_start) and is_zero_approx(outer_start.x), "recovery rail should meet the module edges without pill caps")
		var corner_bounds := rail_probe.call("_wide_u_progress_band_bounds", 0.0, 100.0) as Vector2
		var shoulder_bounds := rail_probe.call("_wide_u_progress_band_bounds", ActivityCardStyles.RECOVERY_WIDE_U_SHOULDER_RATIO, 100.0) as Vector2
		var center_bounds := rail_probe.call("_wide_u_progress_band_bounds", 0.5, 100.0) as Vector2
		_expect(is_equal_approx(corner_bounds.x, shoulder_bounds.x), "recovery rail top should stay flat through its outer corners")
		_expect(corner_bounds.y < shoulder_bounds.y, "recovery rail should round only its lower outer corners")
		_expect(center_bounds.x > shoulder_bounds.x and center_bounds.y > shoulder_bounds.y, "recovery rail should dip through the center after its straight shoulder")
		rail_probe.free()
	var recovery_label := card.get("recovery_label") as Label
	_expect(recovery_label == null, "recovery card should not show the extra recovery face-plate message")
	var starting_xp := int((scene.skills["fight"] as Dictionary).get("xp", 0))
	scene.call("_action_runtime").set("guaranteed_success_action_completions", 0)
	var started := bool(scene.call("_action_runtime").call("_start_action", "fight", "wrap-hands", true, false))
	_expect(started, "recovery action should start normally")
	for _step in range(12):
		scene.call("_action_runtime").call("_process_action", 1.0)
	_expect(int((scene.skills["fight"] as Dictionary).get("xp", 0)) == starting_xp + 1, "recovery action should grant its tiny XP reward")
	_expect(absf(float(SkillState.host_stamina_value("fight", scene)) - 4.0) < 0.001, "recovery action should restore 3 Fighting stamina")
	_expect(str(scene.last_result).contains("Fighting stamina"), "recovery result should mention the restored stamina")
	var recovery_counts := {}
	for raw_skill_def in scene.skill_defs:
		var recovery_skill_id := str((raw_skill_def as Dictionary).get("id", ""))
		var recovery_count := 0
		for raw_loaded_action in scene.actions_by_skill.get(recovery_skill_id, []):
			if RecoveryModules.has_recovery(raw_loaded_action as Dictionary):
				recovery_count += 1
		recovery_counts[recovery_skill_id] = recovery_count
	_expect(int(recovery_counts.get("fight", 0)) == 5, "Fighting should have five recovery modules")
	_expect(int(recovery_counts.get("thieving", 0)) == 5, "Thieving should have five recovery modules")
	_expect(int(recovery_counts.get("build", 0)) == 5, "Building should have five recovery modules")
	_expect(int(recovery_counts.get("woodcutting", 0)) == 5, "Woodcutting should have five recovery modules")
	_expect(int(recovery_counts.get("fishing", 0)) == 0, "Fishing should not have recovery modules")
	scene.stamina["fight"] = 10.0
	scene.stamina["thieving"] = 10.0
	scene.stamina["build"] = 0.5
	scene.stamina["woodcutting"] = 10.0
	scene.stamina["fishing"] = 10.0
	var lowest_action := scene.call("_action_data", "thieving", "lay-low-until-morning") as Dictionary
	var lowest_result := RecoveryModules.apply("thieving", lowest_action, scene.skill_defs, scene.stamina, func(skill_id: String) -> float: return SkillState.host_stamina_value(skill_id, scene), func(skill_id: String) -> int: return SkillState.max_stamina(scene, skill_id), func(skill_id: String, amount: float) -> float: return SkillState.restore_action_stamina(scene.stamina, scene.stamina_bank, skill_id, amount, func(max_skill_id: String) -> int: return SkillState.max_stamina(scene, max_skill_id)))
	_expect(str(lowest_result.get("skill_id", "")) == "build", "lowest-target recovery should restore the lowest stamina skill")
	_expect(float(lowest_result.get("amount", 0.0)) > 0.0, "lowest-target recovery should restore stamina")
	scene.queue_free()
	if test_failed:
		quit(1)
		return
	print("recovery-modules-ok")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	test_failed = true
	push_error(message)
	print("recovery-modules-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script "res://.codex-tmp/recovery-modules/tests/recovery_modules_test.gd" 2>&1
    $output | Write-Output
    Assert-True (($output | Out-String) -match "recovery-modules-ok") "Recovery modules test did not report success."
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
        throw "Headless Godot process left behind after recovery module test."
    }
}
