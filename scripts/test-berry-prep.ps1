$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\berry-prep\tests"
$testScript = Join-Path $testDir "berry_prep_test.gd"

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

var test_failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("berry-prep-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	scene.call("_activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	var woodcutting := scene.skills["woodcutting"] as Dictionary
	woodcutting["level"] = 13
	woodcutting["xp"] = maxi(int(woodcutting.get("xp", 0)), SkillState.xp_for_level(13))
	scene.skills["woodcutting"] = woodcutting
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "woodcutting", "prune-orchard-row", "berry mode test unlock")
	var starter_action := scene.call("_action_data", "woodcutting", "gather-fallen-branches") as Dictionary
	_expect(not starter_action.is_empty(), "Gather Fallen Branches should load")
	for raw_reward in scene.call("_action_runtime").call("_action_mat_reward_defs", starter_action) as Array:
		var reward := raw_reward as Dictionary
		_expect(str(reward.get("id", "")) != "berries", "Gather Fallen Branches should not drop Berries")
	var action := scene.call("_action_data", "woodcutting", "prune-orchard-row") as Dictionary
	_expect(not action.is_empty(), "Prune Orchard Row should load")
	var has_berries := false
	for raw_reward in scene.call("_action_runtime").call("_action_mat_reward_defs", action) as Array:
		var reward := raw_reward as Dictionary
		if str(reward.get("id", "")) == "berries":
			has_berries = true
			reward["chance"] = 1.0
	_expect(has_berries, "Prune Orchard Row should be able to drop Berries")
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "woodcutting", action, 1080.0, 1080.0) as Dictionary
	var card := built.get("card", {}) as Dictionary
	var collection := card.get("mat_collection", {}) as Dictionary
	var modules := collection.get("modules", {}) as Dictionary
	var berry_module := modules.get("berries") as Control
	_expect(berry_module != null, "Berries reward should create a material module")
	var berry_button := _first_berry_button(berry_module)
	_expect(berry_button != null, "Berries material module should expose a prep button")
	var hint := instance_from_id(int(berry_button.get_meta("berry_prep_hint_label_id", 0))) as Label
	_expect(hint != null and str(hint.text).is_empty(), "Berries module should not put mode instructions on the face plate")
	scene.material_runtime.set_amount("berries", 2.0)
	var material_surface: Object = scene.call("_material_collection_surface")
	berry_button.pressed.emit()
	_expect(bool(material_surface.get("berry_mode_enabled")), "Berries button should enable berry mode")
	berry_button.pressed.emit()
	_expect(not bool(material_surface.get("berry_mode_enabled")), "Berries button should toggle berry mode off")
	berry_button.pressed.emit()
	_expect(bool(material_surface.get("berry_mode_enabled")), "Berries button should toggle berry mode back on")
	var overlay := material_surface.get("berry_mode_overlay") as Control
	_expect(overlay != null, "Berry mode should create a selection overlay")
	_expect(_find_named_control(overlay, "BerryModeTopInputBlocker") != null, "Berry mode should block top UI buttons")
	_expect(_find_named_control(overlay, "BerryModeBottomInputBlocker") != null, "Berry mode should block bottom UI buttons")
	var leave_button := _find_named_control(overlay, "BerryModeLeaveButton") as Button
	_expect(leave_button != null and leave_button.text == "LEAVE MODE", "Berry mode should show a leave button")
	material_surface.call("toggle_berry_prep_for_action", "woodcutting", "prune-orchard-row")
	_expect(scene.material_runtime.berry_prep_matches("woodcutting", "prune-orchard-row", Callable(scene, "_action_data"), Callable(scene, "_action_key")), "Berry mode should save the chosen target")
	var rebuilt := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "woodcutting", action, 1080.0, 1080.0) as Dictionary
	var rebuilt_card := rebuilt.get("card", {}) as Dictionary
	var rebuilt_modules := ((rebuilt_card.get("mat_collection", {}) as Dictionary).get("modules", {}) as Dictionary)
	var rebuilt_berry_button := _first_berry_button(rebuilt_modules.get("berries") as Control)
	var rebuilt_hint := instance_from_id(int(rebuilt_berry_button.get_meta("berry_prep_hint_label_id", 0))) as Label
	_expect(rebuilt_hint != null and str(rebuilt_hint.text).is_empty(), "Berries module should not put mode instructions on the face plate")
	var payload := scene.call("_save_runtime").call("_save_payload", int(scene.call("_unix_now"))) as Dictionary
	var saved_targets := (payload.get("berry_prep", {}) as Dictionary).get("targets", {}) as Dictionary
	_expect(bool(saved_targets.get("woodcutting:prune-orchard-row", false)), "Berry mode should save normalized action keys")
	action["success"] = 100
	scene.stamina["woodcutting"] = 5.0
	scene.call("_sync_stamina_bank", "woodcutting")
	var starting_xp := int((scene.skills["woodcutting"] as Dictionary).get("xp", 0))
	var started := bool(scene.call("_action_runtime").call("_start_action", "woodcutting", "prune-orchard-row", true, false))
	_expect(started, "prepped action should still start normally")
	scene.call("_action_runtime").call("_process_action", 3.0)
	var ending_xp := int((scene.skills["woodcutting"] as Dictionary).get("xp", 0))
	_expect(ending_xp == starting_xp + 28, "Berry mode should double XP")
	_expect(scene.material_runtime.berry_prep_matches("woodcutting", "prune-orchard-row", Callable(scene, "_action_data"), Callable(scene, "_action_key")), "Berry mode should stay enabled after consumption")
	var berries_left: float = scene.material_runtime.amount("berries")
	_expect(berries_left >= 1.0 and berries_left <= 3.0, "Berry mode should spend one Berries and then apply doubled loot")
	_expect(str(scene.last_result).contains("Berry used 1 Berries"), "completion result should mention Berry consumption")
	await process_frame
	var leave_position := leave_button.get_global_rect().get_center()
	_send_primary_click(scene, leave_position)
	_expect(not bool(material_surface.get("berry_mode_enabled")), "Leave button should disable Berry mode")
	scene.queue_free()
	if test_failed:
		quit(1)
		return
	print("berry-prep-ok")
	quit(0)


func _first_berry_button(root_control: Control) -> Button:
	for child in root_control.get_children():
		var button := child as Button
		if button != null and button.is_in_group("berry_prep_buttons"):
			return button
	return null


func _find_named_control(root_control: Control, control_name: String) -> Control:
	if root_control == null:
		return null
	if root_control.name == control_name:
		return root_control
	for child in root_control.get_children():
		var control := child as Control
		var found := _find_named_control(control, control_name)
		if found != null:
			return found
	return null


func _send_primary_click(scene: Node, global_position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = global_position
	press.global_position = global_position
	scene.call("_input", press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = global_position
	release.global_position = global_position
	scene.call("_input", release)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	test_failed = true
	push_error(message)
	print("berry-prep-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script "res://.codex-tmp/berry-prep/tests/berry_prep_test.gd" 2>&1
    $output | Write-Output
    Assert-True (($output | Out-String) -match "berry-prep-ok") "Berry Prep test did not report success."
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
        throw "Headless Godot process left behind after Berry Prep test."
    }
}
