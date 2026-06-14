$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\skill-first-swipe-visual"
$testScript = Join-Path $testDir "skill_first_swipe_visual_test.gd"

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

function Assert-NoUnexpectedGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Output) {
        return
    }

    foreach ($line in @($Output)) {
        $text = [string]$line
        if ($text -notmatch '^(ERROR|SCRIPT ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match '^ERROR: \d+ RID allocations of type .+ were leaked at exit\.$' -or
            $text -match '^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}

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

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 90
const FINALIZE_WAIT_FRAMES := 360
const POST_SETTLE_VISIBILITY_FRAMES := 150
const TEST_FRAME_SECONDS := 1.0 / 120.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("skill-first-swipe-visual-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
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

	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_max_skills_state")
	scene.call("_god_mode_unlock_actions_state")
	scene.call("_sync_passive_module_unlocks", int(scene.call("_unix_now")))
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	Engine.max_fps = 0

	await _select_skill_from_menu(scene, "build")
	await _run_real_input_swipe(scene)
	var normal_first_visible := await _wait_for_first_uncovered_woodcutting_frame(scene)
	_expect(not normal_first_visible.is_empty(), "Normal first Woodcutting swipe never reached an uncovered frame: %s" % _state_summary(scene))
	if not normal_first_visible.is_empty():
		_expect(int(normal_first_visible.get("visible_modules", 0)) >= 1, "Normal first uncovered Woodcutting frame is blank: %s %s" % [str(normal_first_visible), _state_summary(scene)])
		_expect(float(normal_first_visible.get("visible_module_area", 0.0)) > 100000.0, "Normal first uncovered Woodcutting module area is too small: %s %s" % [str(normal_first_visible), _state_summary(scene)])
		_expect(float(normal_first_visible.get("min_module_alpha", 0.0)) >= 0.98, "Normal first uncovered Woodcutting modules should already be opaque: %s %s" % [str(normal_first_visible), _state_summary(scene)])
	var normal_settled_frame := await _wait_for_woodcutting_settled(scene)
	_expect(normal_settled_frame >= 0, "Normal first Woodcutting swipe did not settle: %s" % _state_summary(scene))

	await _select_skill_from_menu(scene, "build")
	await _scroll_current_detail_to_bottom(scene)
	await _force_idle_preview_prewarm(scene)
	await _run_real_input_swipe(scene)
	var first_visible := await _wait_for_first_uncovered_woodcutting_frame(scene)
	_expect(not first_visible.is_empty(), "Woodcutting never reached an uncovered first-swipe frame: %s" % _state_summary(scene))
	if not first_visible.is_empty():
		_expect(int(first_visible.get("visible_modules", 0)) >= 1, "First uncovered Woodcutting frame is blank: %s %s" % [str(first_visible), _state_summary(scene)])
		_expect(float(first_visible.get("visible_module_area", 0.0)) > 100000.0, "First uncovered Woodcutting module area is too small: %s %s" % [str(first_visible), _state_summary(scene)])
		_expect(float(first_visible.get("min_module_alpha", 0.0)) >= 0.98, "First uncovered Woodcutting modules should already be opaque: %s %s" % [str(first_visible), _state_summary(scene)])
	var settled_frame := await _wait_for_woodcutting_settled(scene)
	_expect(settled_frame >= 0, "Woodcutting did not settle after real input swipe: %s" % _state_summary(scene))

	await _wait_test_frame()
	await _wait_test_frame()
	var stats := _visible_layout_stats(scene)
	print("skill-first-swipe-visible-path stats=%s %s" % [str(stats), _state_summary(scene)])
	_expect(float(stats.get("scroll_area", 0.0)) > 100000.0, "Woodcutting scroll viewport has collapsed: %s %s" % [str(stats), _state_summary(scene)])
	_expect(int(stats.get("visible_modules", 0)) >= 1, "Woodcutting has no module rect visible after first swipe: %s %s" % [str(stats), _state_summary(scene)])
	_expect(float(stats.get("visible_module_area", 0.0)) > 100000.0, "Woodcutting visible module area is too small after first swipe: %s %s" % [str(stats), _state_summary(scene)])
	_expect(float(stats.get("min_module_alpha", 0.0)) >= 0.98, "Woodcutting modules are still fading after first swipe: %s %s" % [str(stats), _state_summary(scene)])
	_expect(not bool(stats.get("opaque_cover", false)), "Woodcutting is still hidden by an opaque swipe cover: %s %s" % [str(stats), _state_summary(scene)])
	var late_stats := await _watch_woodcutting_visibility(scene, POST_SETTLE_VISIBILITY_FRAMES)
	_expect(not bool(late_stats.get("lost_visibility", false)), "Woodcutting modules disappeared after the swipe settled: %s %s" % [str(late_stats), _state_summary(scene)])
	if failures.is_empty():
		print("skill-first-swipe-visual-ok settled_frame=%s stats=%s late_stats=%s" % [str(settled_frame), str(stats), str(late_stats)])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _select_skill_from_menu(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "menu")
	var render = scene.call("_render_screen", false, -1, false)
	if render != null:
		await render
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
	scene.call("_select_skill", skill_id)
	for _i in range(SETTLE_FRAMES * 2):
		await _wait_test_frame()
		if str(scene.get("current_screen")) == "skill" and str(scene.get("selected_skill_id")) == skill_id and _visible_real_module_count(scene) > 0:
			return


func _force_idle_preview_prewarm(scene: Node) -> void:
	var next_token := int(scene.get("skill_swipe_preview_prewarm_token")) + 1
	scene.set("skill_swipe_preview_prewarm_token", next_token)
	scene.set("skill_swipe_preview_prewarm_pending", true)
	var prewarm_result = scene.call("_prewarm_skill_swipe_neighbor_previews", "build", next_token)
	if prewarm_result != null:
		await prewarm_result
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		if _preview_page_count(scene) > 0 and not bool(scene.get("skill_swipe_preview_prewarm_pending")):
			return
	_expect(_preview_page_count(scene) > 0, "Live-style idle prewarm did not cache Woodcutting preview: %s" % _state_summary(scene))


func _scroll_current_detail_to_bottom(scene: Node) -> void:
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null:
		_fail("Build page has no detail scroll before first-swipe visual test")
		return
	var max_scroll: int = int(scroll.call("get_max_scroll_vertical")) if scroll.has_method("get_max_scroll_vertical") else 0
	var target := maxi(0, max_scroll - 12)
	scroll.set("drag_scroll_position", float(target))
	scroll.set("scroll_vertical", target)
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		var clamped := int(scroll.get("scroll_vertical"))
		if clamped >= mini(target, maxi(0, int(scroll.call("get_max_scroll_vertical")) - 12)):
			return


func _clear_swipe_preview_cache(scene: Node) -> void:
	scene.set("skill_swipe_preview_prewarm_token", int(scene.get("skill_swipe_preview_prewarm_token")) + 1)
	scene.set("skill_swipe_preview_prewarm_pending", false)
	scene.call("_clear_skill_swipe_preview")
	scene.call("_discard_skill_detail_cache_entry", scene.call("_skill_detail_cache_key", "woodcutting"))
	await _wait_test_frame()
	scene.set("skill_swipe_preview_prewarm_token", int(scene.get("skill_swipe_preview_prewarm_token")) + 1)
	scene.set("skill_swipe_preview_prewarm_pending", false)
	scene.call("_clear_skill_swipe_preview")
	_expect(_preview_page_count(scene) == 0, "Cold swipe test started with cached preview pages: %s" % _state_summary(scene))


func _run_real_input_swipe(scene: Node) -> void:
	var start := Vector2(1780.0, 1560.0)
	var end := Vector2(260.0, 1560.0)
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.position = start
	touch_down.pressed = true
	scene.call("_input", touch_down)
	await _wait_test_frame()
	for step in range(28):
		var t := float(step + 1) / 28.0
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = start.lerp(end, t)
		drag.relative = drag.position - start.lerp(end, float(step) / 28.0)
		drag.velocity = Vector2(-2400.0, 0.0)
		scene.call("_input", drag)
		await _wait_test_frame()
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.position = end
	touch_up.pressed = false
	scene.call("_input", touch_up)


func _wait_for_first_uncovered_woodcutting_frame(scene: Node) -> Dictionary:
	for frame in range(FINALIZE_WAIT_FRAMES):
		await _wait_test_frame()
		if str(scene.get("selected_skill_id")) != "woodcutting":
			continue
		if bool(scene.get("skill_swipe_animating")) or bool(scene.get("skill_swipe_tracking")):
			continue
		var stats := _visible_layout_stats(scene)
		if not bool(stats.get("opaque_cover", false)):
			stats["frame"] = frame
			return stats
	return {}


func _wait_for_woodcutting_settled(scene: Node) -> int:
	for frame in range(FINALIZE_WAIT_FRAMES):
		await _wait_test_frame()
		if str(scene.get("selected_skill_id")) != "woodcutting":
			continue
		if bool(scene.get("skill_swipe_animating")) or bool(scene.get("skill_swipe_tracking")) or bool(scene.get("skill_swipe_pending_full_finalize")):
			continue
		var cover := _valid_control(scene.get("skill_swipe_handoff_cover"))
		if cover != null and cover.visible and cover.modulate.a > 0.08:
			continue
		if _visible_real_module_count(scene) > 0:
			return frame
	return -1


func _watch_woodcutting_visibility(scene: Node, frames: int) -> Dictionary:
	var min_visible := 999999
	var min_area := INF
	var worst_stats := {}
	for frame in range(frames):
		await _wait_test_frame()
		if str(scene.get("selected_skill_id")) != "woodcutting":
			continue
		if bool(scene.get("skill_swipe_animating")) or bool(scene.get("skill_swipe_tracking")):
			continue
		var stats := _visible_layout_stats(scene)
		if bool(stats.get("opaque_cover", false)):
			continue
		var visible := int(stats.get("visible_modules", 0))
		var area := float(stats.get("visible_module_area", 0.0))
		if visible < min_visible or area < min_area:
			min_visible = mini(min_visible, visible)
			min_area = minf(min_area, area)
			worst_stats = stats.duplicate()
			worst_stats["frame"] = frame
		if visible <= 0 or area <= 100000.0:
			stats["frame"] = frame
			stats["lost_visibility"] = true
			return stats
	if worst_stats.is_empty():
		worst_stats = _visible_layout_stats(scene)
	worst_stats["lost_visibility"] = false
	worst_stats["min_visible_modules"] = min_visible
	worst_stats["min_visible_module_area"] = min_area
	return worst_stats


func _visible_layout_stats(scene: Node) -> Dictionary:
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	var scroll_rect := Rect2()
	if scroll != null:
		scroll_rect = scroll.get_global_rect()
	var visible_modules := 0
	var visible_module_area := 0.0
	var largest_module_area := 0.0
	var min_module_alpha := 1.0
	if scroll != null and scroll.get_child_count() > 0:
		var stack := _valid_control(scroll.get_child(0))
		if stack != null:
			for raw_child in stack.get_children():
				var child := _valid_control(raw_child)
				if child == null or child.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
					continue
				if not _has_real_content(child):
					continue
				var intersection := child.get_global_rect().intersection(scroll_rect)
				var area := maxf(0.0, intersection.size.x) * maxf(0.0, intersection.size.y)
				if area <= 1.0:
					continue
				visible_modules += 1
				visible_module_area += area
				largest_module_area = maxf(largest_module_area, area)
				min_module_alpha = minf(min_module_alpha, _effective_canvas_alpha(child))
	var cover := _valid_control(scene.get("skill_swipe_handoff_cover"))
	var opaque_cover := cover != null and cover.visible and cover.modulate.a > 0.08
	return {
		"scroll_rect": scroll_rect,
		"scroll_area": maxf(0.0, scroll_rect.size.x) * maxf(0.0, scroll_rect.size.y),
		"visible_modules": visible_modules,
		"visible_module_area": visible_module_area,
		"largest_module_area": largest_module_area,
		"min_module_alpha": 0.0 if visible_modules <= 0 else min_module_alpha,
		"opaque_cover": opaque_cover,
		"cover_alpha": 0.0 if cover == null else cover.modulate.a
	}


func _visible_real_module_count(scene: Node) -> int:
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null or not scroll.visible or not scroll.is_visible_in_tree() or scroll.get_child_count() <= 0:
		return 0
	var stack := _valid_control(scroll.get_child(0))
	if stack == null or not stack.visible or not stack.is_visible_in_tree():
		return 0
	var count := 0
	var viewport_rect := scroll.get_global_rect()
	for raw_child in stack.get_children():
		var child := _valid_control(raw_child)
		if child == null or child.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		if _control_intersects_viewport(child, viewport_rect) and _has_real_content(child):
			count += 1
	return count


func _control_intersects_viewport(control: Control, viewport_rect: Rect2) -> bool:
	if not control.visible or not control.is_visible_in_tree() or control.modulate.a <= 0.01:
		return false
	var rect := control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	return rect.intersects(viewport_rect)


func _effective_canvas_alpha(control: Control) -> float:
	var alpha := 1.0
	var node := control as CanvasItem
	while node != null and is_instance_valid(node):
		alpha *= node.modulate.a
		var parent := node.get_parent()
		node = parent as CanvasItem
	return alpha


func _has_real_content(control: Control) -> bool:
	if bool(control.get_meta("detail_lazy_placeholder", false)):
		return false
	if not control.visible or not control.is_visible_in_tree() or control.modulate.a <= 0.01:
		return false
	if bool(control.get_meta("detail_stack_entry_wrapper", false)):
		for raw_child in control.get_children():
			var child := _valid_control(raw_child)
			if child != null and not bool(child.get_meta("detail_lazy_placeholder", false)) and child.visible and child.modulate.a > 0.01:
				return true
		return false
	return maxf(control.size.y, control.custom_minimum_size.y) > 1.0


func _preview_page_count(scene: Node) -> int:
	var pages := scene.get("skill_swipe_preview_pages") as Dictionary
	return 0 if pages == null else pages.size()


func _state_summary(scene: Node) -> String:
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	var page := _valid_control(scene.get("skill_swipe_page"))
	var cover := _valid_control(scene.get("skill_swipe_handoff_cover"))
	return "screen=%s selected=%s pending=%s anim=%s tracking=%s preview_pages=%s real_visible=%s page=%s page_visible=%s scroll=%s scroll_visible=%s cover=%s cover_alpha=%.3f" % [
		str(scene.get("current_screen")),
		str(scene.get("selected_skill_id")),
		str(scene.get("skill_swipe_pending_full_finalize")),
		str(scene.get("skill_swipe_animating")),
		str(scene.get("skill_swipe_tracking")),
		str(_preview_page_count(scene)),
		str(_visible_real_module_count(scene)),
		str(page != null),
		str(page != null and page.visible and page.is_visible_in_tree()),
		str(scroll != null),
		str(scroll != null and scroll.visible and scroll.is_visible_in_tree()),
		str(cover != null and cover.visible),
		0.0 if cover == null else cover.modulate.a
	]


func _valid_control(value: Variant) -> Control:
	if value == null:
		return null
	if not is_instance_valid(value):
		return null
	return value as Control


func _wait_test_frame() -> void:
	await process_frame
	await create_timer(TEST_FRAME_SECONDS, true, false, true).timeout


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	push_error("skill-first-swipe-visual-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "skill-first-swipe-visual-ok") "Skill first-swipe visible-path test did not report success."
    Assert-NoUnexpectedGodotErrors $output "skill first-swipe visual test"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the skill first-swipe visual test."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
