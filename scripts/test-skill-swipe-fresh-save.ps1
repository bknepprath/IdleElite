# Regression test for the fresh-install swipe snap-back: with an early-game save
# and an activity running, a finger-speed swipe from Building must land on
# Woodcutting every time instead of bouncing back.
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\skill-swipe-fresh-save"
$testScript = Join-Path $testDir "skill_swipe_fresh_save_test.gd"
New-Item -ItemType Directory -Force -Path $testDir | Out-Null

@'
extends SceneTree

const ATTEMPTS := 5
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "20")
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for _i in range(900):
		if bool(scene.get("startup_initialized")) and bool(scene.get("save_restore_complete")):
			break
		await process_frame
	await _frames(60)
	# Fresh save that has only finished the tutorial, with Push-Ups running.
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_action_runtime").call("_start_action", "fight", "push-ups", false, false)
	print("skill-swipe-fresh-save setup running=%s:%s" % [str(scene.get("running_skill_id")), str(scene.get("running_action_id"))])
	var refresh_wanted_mid_drag := 0
	for attempt in range(ATTEMPTS):
		scene.set("selected_skill_id", "build")
		scene.set("current_screen", "skill")
		await scene.call("_navigation_shell").call("_render_screen")
		await _frames(45)
		var start_y := 700.0 if attempt % 2 == 0 else 1250.0
		var start := Vector2(900, start_y)
		var finish := Vector2(260, start_y)
		await _touch_swipe(start, finish, 30)
		await _frames(90)
		var landed := str(scene.get("selected_skill_id"))
		print("skill-swipe-fresh-save attempt=%s landed=%s screen=%s" % [attempt + 1, landed, str(scene.get("current_screen"))])
		if landed != "woodcutting":
			failures.append("attempt %s: swipe from Building landed on %s instead of woodcutting" % [attempt + 1, landed])
	# A plain tap on a skill switcher tile must still switch pages.
	scene.set("selected_skill_id", "build")
	await scene.call("_navigation_shell").call("_render_screen")
	await _frames(45)
	var tile := _page_switch_button_to(scene, "woodcutting")
	if tile == null:
		failures.append("Building page has no Woodcutting switcher tile to tap")
	else:
		var center := tile.get_global_rect().get_center()
		for pressed in [true, false]:
			var touch := InputEventScreenTouch.new()
			touch.index = 0
			touch.position = center
			touch.pressed = pressed
			root.push_input(touch, true)
			await _frames(4)
		await _frames(90)
		if str(scene.get("selected_skill_id")) != "woodcutting":
			failures.append("tapping the Woodcutting tile landed on %s" % str(scene.get("selected_skill_id")))
	print("skill-swipe-fresh-save refresh_wanted_mid_drag=%s" % refresh_wanted_mid_drag)
	if failures.is_empty():
		print("skill-swipe-fresh-save-ok")
	scene.queue_free()
	await _frames(2)
	if failures.is_empty():
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


# Real screen-touch events through the game's input routing, like a finger.
func _touch_swipe(start: Vector2, finish: Vector2, steps: int) -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = start
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var previous := start
	for step in range(1, steps + 1):
		var point := start.lerp(finish, float(step) / float(steps))
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = point
		drag.relative = point - previous
		drag.velocity = (point - previous) * 60.0
		root.push_input(drag, true)
		previous = point
		await process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = finish
	up.pressed = false
	root.push_input(up, true)


func _page_switch_button_to(node: Node, target_skill_id: String) -> Button:
	if node is Button and str(node.get_meta("page_switch_target_skill_id", "")) == target_skill_id and (node as Button).is_visible_in_tree():
		return node as Button
	for child in node.get_children():
		var found := _page_switch_button_to(child, target_skill_id)
		if found != null:
			return found
	return null


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

$previousUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-swipe-fresh-" + [guid]::NewGuid().ToString("N"))
    $output = & $runner --headless --path $projectRoot --script "res://.codex-tmp/skill-swipe-fresh-save/skill_swipe_fresh_save_test.gd" 2>&1
    $output | ForEach-Object { Write-Host $_ }
    Assert-True (($output | Out-String) -match "skill-swipe-fresh-save-ok") "Fresh-save swipe from Building did not land on Woodcutting every time."
} finally {
    if ($null -eq $previousUserData) {
        Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousUserData
    }
}
