# Regression test: dragging the skill page with a finger that starts on an open tier menu
# must scroll the page and leave the menu open. A plain tap still toggles it.
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\tier-banner-scroll"
$testScript = Join-Path $testDir "tier_banner_scroll_test.gd"
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
	scene.call("_test_state_runtime").call("_apply_art_review_test_unlock_all_state")
	scene.set("selected_skill_id", "thieving")
	scene.set("current_screen", "skill")
	await scene.call("_navigation_shell").call("_render_screen")
	await _frames(60)
	var detail = scene.call("_skill_detail_surface")
	var plaque := await _scroll_to_hit(scene, detail, "tier_banner_plaque_hit")
	if plaque == null:
		_finish(["no tier banner found on the Thieving page"])
		return
	await _touch_tap(plaque.get_global_rect().get_center())
	await _frames(20)
	if str(detail.get("expanded_tier_banner_key")).is_empty():
		failures.append("tapping the tier banner did not open its menu")
	var panel := _find_hit(scene, "tier_banner_panel_hit")
	if panel == null:
		_finish(failures + ["open tier menu has no panel hit area"])
		return
	var scroll = detail.get("detail_actions_scroll")
	var scroll_before := int(scroll.scroll_vertical) if scroll != null else 0
	var start := _visible_point(panel.get_global_rect())
	await _touch_drag(start, start + Vector2(0, 420), 24)
	await _frames(30)
	var scroll_after := int(scroll.scroll_vertical) if scroll != null else 0
	print("tier-banner-scroll dragged scroll=%s->%s expanded=%s" % [scroll_before, scroll_after, str(detail.get("expanded_tier_banner_key"))])
	if scroll_after == scroll_before:
		failures.append("dragging from the tier menu did not scroll the page")
	if str(detail.get("expanded_tier_banner_key")).is_empty():
		failures.append("dragging the page from the open tier menu closed the menu on release")
	await _frames(120)
	panel = _find_hit(scene, "tier_banner_panel_hit")
	if panel != null and scroll != null:
		# Bring the open menu back on screen before the plain tap.
		scroll.scroll_vertical = int(scroll.scroll_vertical + (panel.get_global_rect().position.y - 560.0))
		scroll.set("drag_scroll_position", float(scroll.scroll_vertical))
		await _frames(30)
		await _touch_tap(_visible_point(panel.get_global_rect()))
		await _frames(20)
		if not str(detail.get("expanded_tier_banner_key")).is_empty():
			failures.append("a plain tap on the open tier menu no longer closes it")
	# A sideways swipe that starts on a tier banner must change skill pages.
	await _frames(60)
	plaque = await _scroll_to_hit(scene, detail, "tier_banner_plaque_hit")
	if plaque == null:
		failures.append("tier banner disappeared before the swipe check")
	else:
		var swipe_start := _visible_point(plaque.get_global_rect())
		swipe_start.x = 900.0
		await _touch_drag(swipe_start, Vector2(240.0, swipe_start.y), 24)
		await _frames(90)
		print("tier-banner-scroll swipe landed=%s expanded=%s" % [str(scene.get("selected_skill_id")), str(detail.get("expanded_tier_banner_key"))])
		if str(scene.get("selected_skill_id")) == "thieving":
			failures.append("a sideways swipe that starts on a tier banner did not change pages")
	_finish(failures)


func _finish(found: Array) -> void:
	if found.is_empty():
		print("tier-banner-scroll-ok")
		quit(0)
		return
	for failure in found:
		push_error(failure)
	quit(1)


func _scroll_to_hit(scene: Node, detail, meta_key: String) -> Control:
	var scroll = detail.get("detail_actions_scroll")
	for step in range(80):
		var hit := _find_hit(scene, meta_key)
		if hit != null:
			var rect := hit.get_global_rect()
			if rect.position.y > 450.0 and rect.end.y < 1500.0:
				return hit
			if scroll != null:
				scroll.scroll_vertical = int(scroll.scroll_vertical + (rect.position.y - 700.0))
				scroll.set("drag_scroll_position", float(scroll.scroll_vertical))
		elif scroll != null:
			scroll.scroll_vertical = int(scroll.scroll_vertical) + 400
			scroll.set("drag_scroll_position", float(scroll.scroll_vertical))
		await _frames(12)
	return _find_hit(scene, meta_key)


# A point inside the rect that is on screen above the bottom button row and chat strip.
func _visible_point(rect: Rect2) -> Vector2:
	var top := maxf(rect.position.y + 40.0, 480.0)
	var bottom := minf(rect.end.y - 40.0, 1150.0)
	return Vector2(rect.get_center().x, clampf((top + bottom) * 0.5, top, maxf(top, bottom)))


func _find_hit(node: Node, meta_key: String) -> Control:
	if node is Control and bool(node.get_meta(meta_key, false)) and (node as Control).is_visible_in_tree() and (node as Control).get_global_rect().position.x >= 0.0 and (node as Control).get_global_rect().position.x < 540.0:
		return node as Control
	for child in node.get_children():
		var found := _find_hit(child, meta_key)
		if found != null:
			return found
	return null


func _touch_tap(position: Vector2) -> void:
	for pressed in [true, false]:
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = position
		touch.pressed = pressed
		Input.parse_input_event(touch)
		_mouse_button(position, pressed)
		await _frames(3)


func _touch_drag(start: Vector2, finish: Vector2, steps: int) -> void:
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = start
	down.pressed = true
	Input.parse_input_event(down)
	_mouse_button(start, true)
	await process_frame
	var previous := start
	for step in range(1, steps + 1):
		var point := start.lerp(finish, float(step) / float(steps))
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = point
		drag.relative = point - previous
		drag.velocity = (point - previous) * 60.0
		Input.parse_input_event(drag)
		_mouse_motion(point, point - previous)
		previous = point
		await process_frame
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = finish
	up.pressed = false
	Input.parse_input_event(up)
	_mouse_button(finish, false)
	await process_frame


# A phone delivers each touch as a touch event plus an emulated mouse event; send both.
func _mouse_button(position: Vector2, pressed: bool) -> void:
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = position
	mouse.global_position = position
	mouse.pressed = pressed
	mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	Input.parse_input_event(mouse)


func _mouse_motion(position: Vector2, relative: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	motion.relative = relative
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)


func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

$previousUserData = $env:IDLE_ELITE_TEST_USER_DATA_DIR
try {
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = if ($previousUserData) { $previousUserData } else { Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-tier-banner-" + [guid]::NewGuid().ToString("N")) }
    $output = & $runner --headless --path $projectRoot --script "res://.codex-tmp/tier-banner-scroll/tier_banner_scroll_test.gd" 2>&1
    $output | ForEach-Object { Write-Host $_ }
    Assert-True (($output | Out-String) -match "tier-banner-scroll-ok") "Dragging the page from an open tier menu must scroll without closing it."
} finally {
    if ($null -eq $previousUserData) {
        Remove-Item Env:\IDLE_ELITE_TEST_USER_DATA_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TEST_USER_DATA_DIR = $previousUserData
    }
}
