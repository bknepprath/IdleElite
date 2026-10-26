$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\thieving-heist-click-flow"
$testScript = Join-Path $testDir "thieving_heist_click_flow.gd"

# run-godot-safe.ps1 gives every headless run its own user data folder, so this
# test never sees the real desktop save and must not copy, restore or delete it.

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const BOOT_TIMEOUT_FRAMES := 720
const TARGET_HEIST_ID := "complimentary_spoon"

var failed := false


func _init() -> void:
	call_deferred("_run")


func _mouse_button_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	return event


func _run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	# A headless window is 64 x 64 and the layout that follows from it puts the
	# heist button under the bottom bar. Lay the game out as a phone does.
	root.content_scale_size = Vector2i(1080, 1920)
	root.size = Vector2i(1080, 1920)
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return

	# These used to live on main.gd; each now belongs to the runtime or surface named here.
	scene.call("_save_runtime").call("_clear_pending_save_restore_work")
	scene.call("_save_runtime").call("_init_state")
	# Level 8 arrives all at once here; without this the automatic lock openings
	# for every activity below it run their ceremonies under the click.
	scene.set("auto_unlock_lockpads_enabled", false)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "thieving")
	# This run has its own empty profile, so the game starts in the tutorial, which
	# takes every tap that is not on its starter activity. Finish it the way the
	# other tests do.
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.module_ui_runtime.reset()
	var skills := scene.get("skills") as Dictionary
	var thieving := (skills.get("thieving", {}) as Dictionary).duplicate(true)
	thieving["xp"] = SkillState.xp_for_level(8)
	thieving["level"] = 8
	skills["thieving"] = thieving
	scene.set("skills", skills)
	SkillState.recalculate_level(scene, "thieving")
	scene.thieving_state.ensure_all_trophy_state()
	scene.call("_hub_runtime").sync_trophy_level_from_thieving()
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _frame in range(40):
		await process_frame
	scene.call("_skill_detail_surface").call("_detail_lazy_mount_thieving_heists_sync", true)
	for _frame in range(10):
		await process_frame

	var card_key := "thieving_heist:%s" % TARGET_HEIST_ID
	var cards := scene.get("action_cards") as Dictionary
	if not cards.has(card_key):
		_fail("rendered heist action card was not registered")
		return
	var card := cards.get(card_key, {}) as Dictionary
	var button := card.get("button") as Button
	if button == null or not is_instance_valid(button):
		_fail("rendered heist card has no button")
		return
	if button.disabled:
		_fail("rendered heist STEAL button is disabled")
		return
	var click_point := button.get_global_rect().get_center()
	# The list scrolls under the bottom bars, which take any tap on them. Bring the
	# button clear of them first, as a player does.
	var routing = scene.call("_input_routing_shell")
	var actions_scroll = scene.call("_skill_detail_surface").detail_actions_scroll
	for _attempt in range(16):
		if not bool(routing.call("_position_inside_bottom_interactive_ui", click_point)):
			break
		actions_scroll.scroll_vertical += 120
		actions_scroll.drag_scroll_position = float(actions_scroll.scroll_vertical)
		for _frame in range(4):
			await process_frame
		click_point = button.get_global_rect().get_center()
	for _frame in range(20):
		await process_frame
	if not is_instance_valid(button):
		_fail("heist card was rebuilt while the list was scrolled")
		return
	click_point = button.get_global_rect().get_center()
	if bool(routing.call("_position_inside_bottom_interactive_ui", click_point)):
		_fail("heist STEAL button could not be scrolled clear of the bottom bars: %s" % str(click_point))
		return
	if not bool(routing.call("_position_inside_detail_actions_viewport", click_point)):
		_fail("heist STEAL click point is outside the activity viewport: %s" % str(click_point))
		return

	var xp_before := int(((scene.get("skills") as Dictionary).get("thieving", {}) as Dictionary).get("xp", 0))
	scene.call("_skill_swipe_activity_surface").call("_clear_skill_swipe_button_suppression")
	scene.call("_input", _mouse_button_event(click_point, true))
	for _frame in range(4):
		await process_frame
	scene.call("_input", _mouse_button_event(click_point, false))
	for _frame in range(45):
		scene.call("_update_ui", 0.016, false)
		await process_frame

	var trophy_state := (scene.thieving_state.trophies.get(TARGET_HEIST_ID, {}) as Dictionary)
	var xp_after := int(((scene.get("skills") as Dictionary).get("thieving", {}) as Dictionary).get("xp", 0))
	var cooldown_remaining := int(scene.thieving_state.heist_cooldown_remaining(TARGET_HEIST_ID, int(scene.call("_unix_now"))))
	var interacted := bool(trophy_state.get("stolen", false)) or cooldown_remaining > 0 or xp_after > xp_before
	if not interacted:
		_fail("STEAL click did not change trophy state, cooldown, or XP. result=%s xp_before=%s xp_after=%s trophy=%s" % [
			str(scene.get("last_result")),
			str(xp_before),
			str(xp_after),
			str(trophy_state)
		])
		return
	print("thieving-heist-click-flow-ok")
	quit(0)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		var queue = scene.get("boot_detail_render_queue")
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and (queue == null or (queue is Array and (queue as Array).is_empty()))
		):
			return true
		await process_frame
	return false


func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error(message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $before = Get-HeadlessGodotProcesses
    $output = & $runner --path $projectRoot --script $testScript 2>&1
    $exitCode = $LASTEXITCODE
    $output | ForEach-Object { Write-Output $_ }
    Assert-NoUnexpectedGodotErrors -Output $output -Context "Thieving heist click flow test"
    Assert-True ($exitCode -eq 0) "Thieving heist click flow test exited with code $exitCode."
    Assert-True (($output -join "`n") -match "thieving-heist-click-flow-ok") "Thieving heist click flow test did not report success."
    $after = Get-HeadlessGodotProcesses
    $beforeIds = @($before | ForEach-Object { $_.ProcessId })
    $leftovers = @($after | Where-Object { $beforeIds -notcontains $_.ProcessId })
    $testLeftovers = @($leftovers | Where-Object { $_.CommandLine -match 'thieving_heist_click_flow\.gd' })
    $leftoverIds = (@($testLeftovers | ForEach-Object { [string]$_.ProcessId }) -join ', ')
    Assert-True ($testLeftovers.Count -eq 0) "Headless Godot process left behind after Thieving heist click flow test: $leftoverIds"
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
}
