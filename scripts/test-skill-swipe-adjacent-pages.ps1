$ErrorActionPreference = "Stop"
# Regression for adjacent skill pages: the neighbour page is a real, mounted
# page beside the current one while dragging, a committed swipe lands on that
# same page instance (no re-render, no cream cover) and its scroll does not move
# after the settle. Also checks that nothing of a neighbour is on screen at rest.
$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\skill-swipe-adjacent-pages"
$testScript = Join-Path $testDir "skill_swipe_adjacent_pages.gd"
$testUserDataDir = Join-Path $testDir "user-data"

function Restore-EnvironmentValue {
    param([string]$Name, [AllowNull()][string]$Value)
    if ($null -eq $Value) {
        Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
    } else {
        Set-Item -LiteralPath "Env:$Name" -Value $Value
    }
}

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
New-Item -ItemType Directory -Path $testUserDataDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousTestUserDataDir = $env:IDLE_ELITE_TEST_USER_DATA_DIR
$previousDisableSaveWrites = $env:IDLE_ELITE_DISABLE_SAVE_WRITES
$env:GODOT_RUN_TIMEOUT_SECONDS = "300"
$env:IDLE_ELITE_TEST_USER_DATA_DIR = $testUserDataDir
$env:IDLE_ELITE_DISABLE_SAVE_WRITES = "1"
$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const READY_TIMEOUT_MSEC := 6000
const POST_SETTLE_WATCH_MSEC := 1600

var scene: Node
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("skill-swipe-adjacent-pages-start")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = Vector2i(1080, 1920)
	root.size = Vector2i(1080, 1920)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		quit(1)
		return
	scene = packed.instantiate()
	root.add_child(scene)
	if not await _wait_for_boot_ready():
		_fail("boot did not become ready")
		quit(1)
		return
	scene.call("_achievement_overlay_surface").call("_close_offline_summary_overlay")
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	var achievement_state = load("res://scripts/achievements/state.gd")
	achievement_state.mark_completed_seen_ids(achievement_state.milestones(scene, false), scene.call("_save_runtime").achievement_toast_seen_ids, [])
	scene.call("_achievement_toast_surface").achievement_toast_queue.clear()
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "build")
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result

	# build -> woodcutting -> fishing -> fight (wraps around) -> fishing (back).
	for step in [[1, "woodcutting"], [1, "fishing"], [1, "fight"], [-1, "fishing"]]:
		if not failures.is_empty():
			break
		await _swipe_and_check(int(step[0]), str(step[1]))
	if failures.is_empty():
		await _caught_settle_returns_to_rest()

	if failures.is_empty():
		print("skill-swipe-adjacent-pages-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _swipe_surface() -> Object:
	return scene.call("_skill_swipe_activity_surface")


func _adjacent() -> Object:
	return _swipe_surface().call("_adjacent_pages")


func _viewport_rect() -> Rect2:
	return scene.get_viewport().get_visible_rect()


func _wait_for_neighbours_ready(context: String) -> bool:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < READY_TIMEOUT_MSEC:
		await process_frame
		var adjacent := _adjacent()
		if bool(adjacent.call("page_ready", -1)) and bool(adjacent.call("page_ready", 1)) and not bool(_swipe_surface().get("skill_swipe_animating")):
			return true
	_fail("%s: neighbour pages never became ready: %s" % [context, str(_adjacent().call("debug_state"))])
	return false


func _mounted_hosts(page: Control) -> Array:
	var hosts := []
	for raw_key in (scene.get("action_cards") as Dictionary).keys():
		var card := (scene.get("action_cards") as Dictionary)[raw_key] as Dictionary
		var root_control := card.get("root") as Control
		if root_control == null or not is_instance_valid(root_control) or not page.is_ancestor_of(root_control):
			continue
		hosts.append(root_control)
	return hosts


func _visible_hosts(hosts: Array) -> Array:
	var visible := []
	var viewport := _viewport_rect()
	for raw_host in hosts:
		var control := raw_host as Control
		if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
			continue
		if control.get_global_rect().intersects(viewport):
			visible.append(control)
	return visible


func _shelf_background(page: Control) -> Control:
	return page.find_child("SkillDetailFullBleedShelfBackground", true, false) as Control


func _check_rest_edges(context: String) -> void:
	var viewport := _viewport_rect()
	for offset in [-1, 1]:
		var page := _adjacent().call("page_for_offset", offset) as Control
		if page == null:
			_fail("%s: missing neighbour page %d at rest" % [context, offset])
			continue
		if page.get_global_rect().intersects(viewport):
			_fail("%s: neighbour page %d visible at rest: %s" % [context, offset, str(page.get_global_rect())])
		var shelf := _shelf_background(page)
		if shelf != null and shelf.is_visible_in_tree() and shelf.get_global_rect().intersects(viewport):
			_fail("%s: neighbour shelf background %d visible at rest: %s" % [context, offset, str(shelf.get_global_rect())])


func _send_touch(position: Vector2, pressed: bool) -> void:
	# Same entry points the input router uses for a touch on the skill page.
	if pressed:
		_swipe_surface().call("_interrupt_skill_swipe_animation_for_input")
		_swipe_surface().call("_begin_skill_swipe_tracking", position, 0)
	else:
		_swipe_surface().call("_finish_skill_swipe", position)


func _send_drag(position: Vector2, _relative: Vector2) -> void:
	_swipe_surface().call("_update_skill_swipe_feedback", position)


func _swipe_and_check(offset: int, expected_skill: String) -> void:
	var from_skill := str(scene.get("selected_skill_id"))
	var context := "%s->%s" % [from_skill, expected_skill]
	if not await _wait_for_neighbours_ready(context):
		return
	_check_rest_edges(context)
	var frame := _swipe_surface().get("skill_swipe_frame") as Control
	print("skill-swipe-adjacent-pages-geometry viewport=%s frame=%s host_width=%.1f stride=%.1f" % [str(_viewport_rect()), str(frame.get_global_rect()), float(scene.call("_skill_column_host_width")), float(_adjacent().call("stride"))])
	var target_page := _adjacent().call("page_for_offset", offset) as Control
	var target_skill := str((_adjacent().call("debug_state") as Dictionary).get(offset, {}).get("skill_id", ""))
	if target_skill != expected_skill:
		_fail("%s: neighbour %d is %s" % [context, offset, target_skill])
		return
	var detail_scroll_before := _page_scroll_value(target_page)
	var hosts_before := _mounted_hosts(target_page)
	if hosts_before.is_empty():
		_fail("%s: neighbour page has no mounted cards before the drag" % context)
		return
	var host_ids := []
	for raw_host in hosts_before:
		host_ids.append((raw_host as Control).get_instance_id())

	# Finger moves opposite to the page offset: next page = drag left.
	var direction := -float(offset)
	var start := Vector2(540.0 - direction * 330.0, 1000.0)
	var mid := start + Vector2(direction * 420.0, 0.0)
	var finish := start + Vector2(direction * 700.0, 0.0)
	_send_touch(start, true)
	await process_frame
	var previous := start
	for step in range(1, 13):
		var point := start.lerp(mid, float(step) / 12.0)
		_send_drag(point, point - previous)
		previous = point
		await process_frame
	if str(scene.get("selected_skill_id")) != from_skill:
		_fail("%s: skill changed before release" % context)
	var target_rect := target_page.get_global_rect()
	if not target_rect.intersects(_viewport_rect()):
		_fail("%s: neighbour page not on screen mid-drag: %s" % [context, str(target_rect)])
	var visible_mid := _visible_hosts(_mounted_hosts(target_page))
	if visible_mid.is_empty():
		_fail("%s: no real neighbour cards visible mid-drag" % context)
	var drag_x := float(_swipe_surface().get("skill_swipe_drag_offset_x"))
	if absf(drag_x - direction * 420.0) > 40.0:
		_fail("%s: frame did not follow the finger mid-drag: drag_x=%.1f" % [context, drag_x])
	print("skill-swipe-adjacent-pages-mid-drag context=%s drag_x=%.1f neighbour_x=%.1f visible_cards=%d" % [context, drag_x, target_rect.position.x, visible_mid.size()])
	for step in range(1, 7):
		var point := mid.lerp(finish, float(step) / 6.0)
		_send_drag(point, point - previous)
		previous = point
		await process_frame
	_send_touch(finish, false)

	var settled_msec := -1
	var settled_scroll := -1
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 5000:
		await process_frame
		var cover := _swipe_surface().get("skill_swipe_handoff_cover") as Control
		if cover != null and is_instance_valid(cover) and cover.visible:
			_fail("%s: a handoff cover appeared during the swipe" % context)
			return
		if bool(_swipe_surface().get("skill_swipe_animating")) or str(scene.get("selected_skill_id")) != expected_skill:
			continue
		var current_page := _swipe_surface().get("skill_swipe_page") as Control
		if current_page != target_page:
			_fail("%s: landed on a different page instance (re-rendered)" % context)
			return
		var scroll_now := _page_scroll_value(target_page)
		if settled_msec < 0:
			settled_msec = Time.get_ticks_msec()
			settled_scroll = scroll_now
			if scroll_now != detail_scroll_before:
				_fail("%s: scroll changed on arrival: before=%d after=%d" % [context, detail_scroll_before, scroll_now])
				return
			continue
		if scroll_now != settled_scroll:
			_fail("%s: scroll moved after settle: %d -> %d" % [context, settled_scroll, scroll_now])
			return
		if Time.get_ticks_msec() - settled_msec >= POST_SETTLE_WATCH_MSEC:
			break
	if settled_msec < 0:
		_fail("%s: swipe never settled on %s (selected=%s)" % [context, expected_skill, str(scene.get("selected_skill_id"))])
		return
	if _swipe_surface().get("skill_swipe_page") != target_page:
		_fail("%s: page was re-rendered after settle" % context)
		return
	var hosts_after := _mounted_hosts(target_page)
	var ids_after := {}
	for raw_host in hosts_after:
		ids_after[(raw_host as Control).get_instance_id()] = true
	for raw_id in host_ids:
		if not ids_after.has(int(raw_id)):
			_fail("%s: card node %d was replaced after the swipe" % [context, int(raw_id)])
			return
	var frame_x := float(_swipe_surface().get("skill_swipe_drag_offset_x"))
	if absf(frame_x) > 0.5:
		_fail("%s: frame did not settle at rest: %.2f" % [context, frame_x])
	print("skill-swipe-adjacent-pages-landed context=%s page=%d cards=%d scroll=%d" % [context, target_page.get_instance_id(), hosts_after.size(), settled_scroll])


## A finger that catches the release settle and then scrolls vertically must not
## leave the strip parked between two pages.
func _caught_settle_returns_to_rest() -> void:
	var from_skill := str(scene.get("selected_skill_id"))
	if not await _wait_for_neighbours_ready("caught-settle"):
		return
	var start := Vector2(870.0, 1000.0)
	var finish := Vector2(170.0, 1000.0)
	_send_touch(start, true)
	await process_frame
	for step in range(1, 9):
		_send_drag(start.lerp(finish, float(step) / 8.0), Vector2.ZERO)
		await process_frame
	_send_touch(finish, false)
	await process_frame
	var caught := Vector2(540.0, 900.0)
	_send_touch(caught, true)
	var caught_x := float(_swipe_surface().get("skill_swipe_drag_offset_x"))
	for step in range(1, 7):
		_send_drag(caught + Vector2(0.0, 40.0 * float(step)), Vector2.ZERO)
		await process_frame
	_send_touch(caught + Vector2(0.0, 240.0), false)
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 2000:
		await process_frame
		if absf(float(_swipe_surface().get("skill_swipe_drag_offset_x"))) <= 0.5 and not bool(_swipe_surface().get("skill_swipe_animating")):
			print("skill-swipe-adjacent-pages-caught-settle from=%s landed=%s caught_x=%.1f" % [from_skill, str(scene.get("selected_skill_id")), caught_x])
			return
	_fail("caught settle left the strip parked at x=%.1f (caught at %.1f)" % [float(_swipe_surface().get("skill_swipe_drag_offset_x")), caught_x])


func _page_scroll_value(page: Control) -> int:
	var scroll := page.find_child("DetailActionsClip", true, false)
	if scroll == null or scroll.get_child_count() <= 0:
		return -1
	var container := scroll.get_child(0) as ScrollContainer
	if container == null:
		return -1
	return container.scroll_vertical


func _wait_for_boot_ready() -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and not bool(scene.call("_navigation_shell").get("screen_render_in_progress"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _fail(message: String) -> void:
	failures.append(message)
	push_error(message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    Push-Location $projectRoot
    try {
        $output = & $runner --path . --headless --script $testScript 2>&1
        $output | Write-Output
        if ($LASTEXITCODE -ne 0) {
            throw "Adjacent skill pages regression failed with exit code $LASTEXITCODE."
        }
        Assert-True (($output -join "`n") -match 'skill-swipe-adjacent-pages-ok') "Adjacent skill pages regression did not report success."
    }
    finally {
        Pop-Location
    }
}
finally {
    Restore-EnvironmentValue "GODOT_RUN_TIMEOUT_SECONDS" $previousTimeout
    Restore-EnvironmentValue "IDLE_ELITE_TEST_USER_DATA_DIR" $previousTestUserDataDir
    Restore-EnvironmentValue "IDLE_ELITE_DISABLE_SAVE_WRITES" $previousDisableSaveWrites
    $leftBehind = @()
    foreach ($process in @(Get-HeadlessGodotProcesses)) {
        if (-not $baselineHeadlessProcessIds.ContainsKey([int]$process.ProcessId)) {
            $leftBehind += $process
        }
    }
    if ($leftBehind.Count -gt 0) {
        $details = ($leftBehind | ForEach-Object { "PID=$($_.ProcessId) CMD=$($_.CommandLine)" }) -join "`n"
        throw "Headless Godot process left behind by adjacent skill pages test:`n$details"
    }
}
