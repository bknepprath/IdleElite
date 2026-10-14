# Regression test: the first swipe of a session (after the neighbour pages were rebuilt) must
# land. Tutorial tip notes built inside the off-screen neighbour pages used to raise a blocking
# tip that swallowed the swipe's release, leaving the page parked and then snapping it back.
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\skill-swipe-first-swipe"
$testScript = Join-Path $testDir "skill_swipe_first_swipe_test.gd"
New-Item -ItemType Directory -Force -Path $testDir | Out-Null

@'
extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(1080, 1920)
	root.size = Vector2i(1080, 1920)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "20")
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for _i in range(900):
		if bool(scene.get("startup_initialized")) and bool(scene.get("save_restore_complete")):
			break
		await process_frame
	# Tutorial finished, first activity running, tips not yet seen: neighbour pages carry tip notes.
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_action_runtime").call("_start_action", "fight", "push-ups", false, false)
	var adjacent = scene.call("_skill_swipe_activity_surface").call("_adjacent_pages")
	var tutorial = scene.call("_tutorial_overlay_surface")
	for attempt in range(3):
		scene.set("selected_skill_id", "build")
		scene.set("current_screen", "skill")
		await scene.call("_navigation_shell").call("_render_screen")
		await _frames(240)
		if bool(tutorial.get("blocking_tip_active")) and attempt == 0:
			print("skill-swipe-first-swipe blocking tip group=%s" % str(tutorial.get("blocking_tip_group")))
		# Neighbour pages going stale (progress while idle) makes the next swipe build them again.
		adjacent.call("discard_all")
		var start_y := 900.0 if attempt != 1 else 1250.0
		await _touch_swipe(Vector2(900, start_y), Vector2(260, start_y), 30)
		await _frames(90)
		var landed := str(scene.get("selected_skill_id"))
		print("skill-swipe-first-swipe attempt=%s landed=%s" % [attempt + 1, landed])
		if landed != "woodcutting":
			failures.append("swipe %s from Building landed on %s instead of Woodcutting" % [attempt + 1, landed])
	if failures.is_empty():
		print("skill-swipe-first-swipe-ok")
	scene.queue_free()
	await _frames(2)
	if failures.is_empty():
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


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


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

$previousUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = if ($previousUserData) { $previousUserData } else { Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-first-swipe-" + [guid]::NewGuid().ToString("N")) }
    $output = & $runner --headless --path $projectRoot --script "res://.codex-tmp/skill-swipe-first-swipe/skill_swipe_first_swipe_test.gd" 2>&1
    $output | ForEach-Object { Write-Host $_ }
    Assert-True (($output | Out-String) -match "skill-swipe-first-swipe-ok") "The first swipe after the neighbour pages rebuild must land on the next skill."
} finally {
    if ($null -eq $previousUserData) {
        Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousUserData
    }
}
