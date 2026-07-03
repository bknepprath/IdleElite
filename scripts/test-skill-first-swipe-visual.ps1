$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\skill-first-swipe-visual"
$testScript = Join-Path $testDir "skill_first_swipe_visual_test.gd"
$capturePath = Join-Path $projectRoot ".codex-tmp\skill-first-swipe-visual-thieving.png"

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
        if ($text -notmatch '(ERROR|SCRIPT ERROR|powershell\.exe : ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
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
$previousCapture = $env:IDLE_ELITE_SWIPE_VISUAL_CAPTURE
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"
$env:IDLE_ELITE_SWIPE_VISUAL_CAPTURE = $capturePath

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

	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.call("_passive_modules_runtime").sync_passive_module_unlocks(int(scene.call("_unix_now")))
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	Engine.max_fps = 0

	await _select_skill_from_menu(scene, "build")
	await _run_direct_swipe(scene)
	var normal_first_visible := await _wait_for_first_uncovered_woodcutting_frame(scene)
	_expect(not normal_first_visible.is_empty(), "Normal first Woodcutting swipe never reached an uncovered frame: %s" % _state_summary(scene))
	if not normal_first_visible.is_empty():
		_expect(int(normal_first_visible.get("visible_modules", 0)) >= 1, "Normal first uncovered Woodcutting frame is blank: %s %s" % [str(normal_first_visible), _state_summary(scene)])
		_expect(float(normal_first_visible.get("visible_module_area", 0.0)) > 100000.0, "Normal first uncovered Woodcutting module area is too small: %s %s" % [str(normal_first_visible), _state_summary(scene)])
		_expect(float(normal_first_visible.get("min_module_alpha", 0.0)) >= 0.98, "Normal first uncovered Woodcutting modules should already be opaque: %s %s" % [str(normal_first_visible), _state_summary(scene)])
		_expect(int(normal_first_visible.get("freshly_mounted_modules", 0)) == 0, "Normal first uncovered Woodcutting frame exposed freshly mounted modules: %s %s" % [str(normal_first_visible), _state_summary(scene)])
		_expect_no_preview_content(normal_first_visible, "Normal first uncovered Woodcutting frame", scene)
	var normal_settled_frame := await _wait_for_woodcutting_settled(scene)
	_expect(normal_settled_frame >= 0, "Normal first Woodcutting swipe did not settle: %s" % _state_summary(scene))

	await _select_skill_from_menu(scene, "fight")
	await _run_real_input_swipe(scene)
	var thieving_first_visible := await _wait_for_first_uncovered_skill_frame(scene, "thieving")
	_expect(not thieving_first_visible.is_empty(), "Thieving never reached an uncovered swipe frame: %s" % _state_summary(scene))
	if not thieving_first_visible.is_empty():
		_expect(int(thieving_first_visible.get("visible_modules", 0)) >= 1, "First uncovered Thieving frame is blank: %s %s" % [str(thieving_first_visible), _state_summary(scene)])
		_expect(float(thieving_first_visible.get("visible_module_area", 0.0)) > 100000.0, "First uncovered Thieving module area is too small: %s %s" % [str(thieving_first_visible), _state_summary(scene)])
		_expect(int(thieving_first_visible.get("visible_action_stat_boxes", 0)) >= 2, "First uncovered Thieving action card is missing visible stat boxes: %s %s" % [str(thieving_first_visible), _state_summary(scene)])
		_expect(int(thieving_first_visible.get("freshly_mounted_modules", 0)) == 0, "First uncovered Thieving frame exposed freshly mounted modules: %s %s" % [str(thieving_first_visible), _state_summary(scene)])
		_expect_no_preview_content(thieving_first_visible, "First uncovered Thieving frame", scene)
		_capture_viewport_png()
	var thieving_settled_frame := await _wait_for_skill_settled(scene, "thieving")
	_expect(thieving_settled_frame >= 0, "Thieving did not settle after real input swipe: %s" % _state_summary(scene))
	var thieving_late_stats := await _watch_skill_visibility(scene, "thieving", POST_SETTLE_VISIBILITY_FRAMES)
	_expect(not bool(thieving_late_stats.get("lost_visibility", false)), "Thieving modules disappeared after the swipe settled: %s %s" % [str(thieving_late_stats), _state_summary(scene)])

	await _assert_first_uncovered_swipe_target(scene, "thieving", "build")

	await _select_skill_from_menu(scene, "woodcutting")
	await _run_real_input_swipe(scene)
	var fishing_first_visible := await _wait_for_first_uncovered_skill_frame(scene, "fishing")
	_expect(not fishing_first_visible.is_empty(), "Fishing never reached an uncovered swipe frame: %s" % _state_summary(scene))
	if not fishing_first_visible.is_empty():
		_expect(int(fishing_first_visible.get("visible_modules", 0)) >= 1, "First uncovered Fishing frame is blank: %s %s" % [str(fishing_first_visible), _state_summary(scene)])
		_expect(float(fishing_first_visible.get("visible_module_area", 0.0)) > 100000.0, "First uncovered Fishing module area is too small: %s %s" % [str(fishing_first_visible), _state_summary(scene)])
		_expect(int(fishing_first_visible.get("visible_fishing_method_tiles", 0)) >= 1, "First uncovered Fishing area is missing visible method tiles: %s %s" % [str(fishing_first_visible), _state_summary(scene)])
		_expect(int(fishing_first_visible.get("freshly_mounted_modules", 0)) == 0, "First uncovered Fishing frame exposed freshly mounted modules: %s %s" % [str(fishing_first_visible), _state_summary(scene)])
		_expect_no_preview_content(fishing_first_visible, "First uncovered Fishing frame", scene)
	var fishing_settled_frame := await _wait_for_skill_settled(scene, "fishing")
	_expect(fishing_settled_frame >= 0, "Fishing did not settle after real input swipe: %s" % _state_summary(scene))
	var fishing_late_stats := await _watch_skill_visibility(scene, "fishing", POST_SETTLE_VISIBILITY_FRAMES)
	_expect(not bool(fishing_late_stats.get("lost_visibility", false)), "Fishing modules disappeared after the swipe settled: %s %s" % [str(fishing_late_stats), _state_summary(scene)])

	await _assert_first_uncovered_reverse_swipe_target(scene, "thieving", "fight")

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
		_expect(int(first_visible.get("freshly_mounted_modules", 0)) == 0, "First uncovered Woodcutting frame exposed freshly mounted modules: %s %s" % [str(first_visible), _state_summary(scene)])
		_expect_no_preview_content(first_visible, "First uncovered Woodcutting frame", scene)
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
	_expect(int(stats.get("freshly_mounted_modules", 0)) == 0, "Woodcutting uncovered freshly mounted modules: %s %s" % [str(stats), _state_summary(scene)])
	_expect_no_preview_content(stats, "Woodcutting settled frame", scene)
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


func _assert_first_uncovered_swipe_target(scene: Node, source_skill_id: String, target_skill_id: String) -> void:
	await _select_skill_from_menu(scene, source_skill_id)
	await _run_real_input_swipe(scene)
	await _assert_first_uncovered_target_after_swipe(scene, source_skill_id, target_skill_id)


func _assert_first_uncovered_reverse_swipe_target(scene: Node, source_skill_id: String, target_skill_id: String) -> void:
	await _select_skill_from_menu(scene, source_skill_id)
	await _run_real_input_swipe_reverse(scene)
	await _assert_first_uncovered_target_after_swipe(scene, source_skill_id, target_skill_id)


func _assert_first_uncovered_target_after_swipe(scene: Node, source_skill_id: String, target_skill_id: String) -> void:
	var first_visible := await _wait_for_first_uncovered_skill_frame(scene, target_skill_id)
	_expect(not first_visible.is_empty(), "%s never reached an uncovered swipe frame from %s: %s" % [target_skill_id, source_skill_id, _state_summary(scene)])
	if not first_visible.is_empty():
		_expect(int(first_visible.get("visible_modules", 0)) >= 1, "First uncovered %s frame is blank: %s %s" % [target_skill_id, str(first_visible), _state_summary(scene)])
		_expect(float(first_visible.get("visible_module_area", 0.0)) > 100000.0, "First uncovered %s module area is too small: %s %s" % [target_skill_id, str(first_visible), _state_summary(scene)])
		_expect(int(first_visible.get("freshly_mounted_modules", 0)) == 0, "First uncovered %s frame exposed freshly mounted modules: %s %s" % [target_skill_id, str(first_visible), _state_summary(scene)])
		_expect_no_preview_content(first_visible, "First uncovered %s frame" % target_skill_id, scene)
	var settled_frame := await _wait_for_skill_settled(scene, target_skill_id)
	_expect(settled_frame >= 0, "%s did not settle after real input swipe from %s: %s" % [target_skill_id, source_skill_id, _state_summary(scene)])
	var late_stats := await _watch_skill_visibility(scene, target_skill_id, POST_SETTLE_VISIBILITY_FRAMES)
	_expect(not bool(late_stats.get("lost_visibility", false)), "%s modules disappeared after swipe from %s settled: %s %s" % [target_skill_id, source_skill_id, str(late_stats), _state_summary(scene)])


func _expect_no_preview_content(stats: Dictionary, context: String, scene: Node) -> void:
	_expect(int(stats.get("visible_light_preview_cards", 0)) == 0, "%s exposed light preview card nodes: %s %s" % [context, str(stats), _state_summary(scene)])
	_expect(int(stats.get("visible_preview_placeholders", 0)) == 0, "%s exposed preview placeholders: %s %s" % [context, str(stats), _state_summary(scene)])
	_expect(int(stats.get("registered_preview_cards", 0)) == 0, "%s left preview/proxy cards registered: %s %s" % [context, str(stats), _state_summary(scene)])


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
	var preview_surface = scene.call("_skill_swipe_activity_surface")
	var next_token := int(preview_surface.get("preview_prewarm_token")) + 1
	preview_surface.set("preview_prewarm_token", next_token)
	preview_surface.set("preview_prewarm_pending", true)
	var prewarm_result = scene.call("_prewarm_skill_swipe_neighbor_previews", "build", next_token)
	if prewarm_result != null:
		await prewarm_result
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		if _preview_page_count(scene) > 0 and not bool(preview_surface.get("preview_prewarm_pending")):
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
	var preview_surface = scene.call("_skill_swipe_activity_surface")
	preview_surface.set("preview_prewarm_token", int(preview_surface.get("preview_prewarm_token")) + 1)
	preview_surface.set("preview_prewarm_pending", false)
	preview_surface.call("_clear_skill_swipe_preview")
	await _wait_test_frame()
	preview_surface.set("preview_prewarm_token", int(preview_surface.get("preview_prewarm_token")) + 1)
	preview_surface.set("preview_prewarm_pending", false)
	preview_surface.call("_clear_skill_swipe_preview")
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


func _run_real_input_swipe_reverse(scene: Node) -> void:
	var start := Vector2(260.0, 1560.0)
	var end := Vector2(1780.0, 1560.0)
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
		drag.velocity = Vector2(2400.0, 0.0)
		scene.call("_input", drag)
		await _wait_test_frame()
	var touch_up := InputEventScreenTouch.new()
	touch_up.index = 0
	touch_up.position = end
	touch_up.pressed = false
	scene.call("_input", touch_up)


func _run_direct_swipe(scene: Node, reverse := false) -> void:
	var start := Vector2(900.0, 520.0)
	var end := start + (Vector2(640.0, 0.0) if reverse else Vector2(-640.0, 0.0))
	scene.call("_begin_skill_swipe_tracking", start, -1)
	for step in range(24):
		var t := float(step + 1) / 24.0
		scene.call("_update_skill_swipe_feedback", start.lerp(end, t))
		await _wait_test_frame()
	scene.call("_finish_skill_swipe", end)


func _wait_for_first_uncovered_woodcutting_frame(scene: Node) -> Dictionary:
	return await _wait_for_first_uncovered_skill_frame(scene, "woodcutting")


func _wait_for_first_uncovered_skill_frame(scene: Node, skill_id: String) -> Dictionary:
	for frame in range(FINALIZE_WAIT_FRAMES):
		await _wait_test_frame()
		if str(scene.get("selected_skill_id")) != skill_id:
			continue
		if bool(scene.get("skill_swipe_animating")) or bool(scene.get("skill_swipe_tracking")):
			continue
		var stats := _visible_layout_stats(scene)
		if not bool(stats.get("opaque_cover", false)):
			stats["frame"] = frame
			return stats
	return {}


func _wait_for_woodcutting_settled(scene: Node) -> int:
	return await _wait_for_skill_settled(scene, "woodcutting")


func _wait_for_skill_settled(scene: Node, skill_id: String) -> int:
	for frame in range(FINALIZE_WAIT_FRAMES):
		await _wait_test_frame()
		if str(scene.get("selected_skill_id")) != skill_id:
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
	return await _watch_skill_visibility(scene, "woodcutting", frames)


func _watch_skill_visibility(scene: Node, skill_id: String, frames: int) -> Dictionary:
	var min_visible := 999999
	var min_area := INF
	var worst_stats := {}
	for frame in range(frames):
		await _wait_test_frame()
		if str(scene.get("selected_skill_id")) != skill_id:
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
		if int(stats.get("visible_light_preview_cards", 0)) > 0 or int(stats.get("visible_preview_placeholders", 0)) > 0 or int(stats.get("registered_preview_cards", 0)) > 0:
			stats["frame"] = frame
			stats["lost_visibility"] = true
			stats["preview_content"] = true
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
	var action_stat_boxes := 0
	var visible_action_stat_boxes := 0
	var fishing_method_tiles := 0
	var visible_fishing_method_tiles := 0
	var freshly_mounted_modules := 0
	var visible_light_preview_cards := 0
	var visible_preview_placeholders := 0
	if scroll != null and scroll.get_child_count() > 0:
		var stack := _valid_control(scroll.get_child(0))
		if stack != null:
			for raw_child in stack.get_children():
				var child := _valid_control(raw_child)
				if child == null or child.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
					continue
				if _control_intersects_viewport(child, scroll_rect):
					visible_light_preview_cards += _control_tree_meta_count(child, "skill_swipe_light_preview_card")
					visible_preview_placeholders += _control_tree_meta_count(child, "skill_swipe_preview_placeholder")
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
				var stat_counts := _action_stat_box_counts(child, scroll_rect)
				action_stat_boxes += int(stat_counts.get("total", 0))
				visible_action_stat_boxes += int(stat_counts.get("visible", 0))
				var tile_counts := _marked_control_counts(child, scroll_rect, "fishing_area_method_ready_marker")
				fishing_method_tiles += int(tile_counts.get("total", 0))
				visible_fishing_method_tiles += int(tile_counts.get("visible", 0))
				if not _lazy_mount_frames_settled(child):
					freshly_mounted_modules += 1
	var cover := _valid_control(scene.get("skill_swipe_handoff_cover"))
	var opaque_cover := cover != null and cover.visible and cover.modulate.a > 0.08
	return {
		"scroll_rect": scroll_rect,
		"scroll_area": maxf(0.0, scroll_rect.size.x) * maxf(0.0, scroll_rect.size.y),
		"visible_modules": visible_modules,
		"visible_module_area": visible_module_area,
		"largest_module_area": largest_module_area,
		"min_module_alpha": 0.0 if visible_modules <= 0 else min_module_alpha,
		"action_stat_boxes": action_stat_boxes,
		"visible_action_stat_boxes": visible_action_stat_boxes,
		"fishing_method_tiles": fishing_method_tiles,
		"visible_fishing_method_tiles": visible_fishing_method_tiles,
		"freshly_mounted_modules": freshly_mounted_modules,
		"visible_light_preview_cards": visible_light_preview_cards,
		"visible_preview_placeholders": visible_preview_placeholders,
		"registered_preview_cards": _registered_preview_card_count(scene),
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


func _action_stat_box_counts(control: Control, viewport_rect: Rect2) -> Dictionary:
	var counts := {"total": 0, "visible": 0}
	_collect_action_stat_box_counts(control, viewport_rect, counts)
	return counts


func _marked_control_counts(control: Control, viewport_rect: Rect2, marker_name: String) -> Dictionary:
	var counts := {"total": 0, "visible": 0}
	_collect_marked_control_counts(control, viewport_rect, marker_name, counts)
	return counts


func _lazy_mount_frames_settled(control: Control) -> bool:
	return _lazy_mount_frames_settled_recursive(control, Engine.get_process_frames())


func _lazy_mount_frames_settled_recursive(control: Control, current_process_frame: int) -> bool:
	if control == null or not is_instance_valid(control):
		return true
	if control.has_meta("detail_lazy_mounted_process_frame"):
		var mounted_process_frame := int(control.get_meta("detail_lazy_mounted_process_frame"))
		if current_process_frame - mounted_process_frame < 2:
			return false
	for raw_child in control.get_children():
		var child := _valid_control(raw_child)
		if child != null and not _lazy_mount_frames_settled_recursive(child, current_process_frame):
			return false
	return true


func _registered_preview_card_count(scene: Node) -> int:
	var cards := scene.get("action_cards") as Dictionary
	if cards == null:
		return 0
	var count := 0
	for raw_card in cards.values():
		var card := raw_card as Dictionary
		if card.is_empty():
			continue
		if bool(card.get("preview_only", false)) or bool(card.get("swipe_proxy", false)):
			count += 1
	return count


func _control_tree_meta_count(control: Control, meta_name: String) -> int:
	if control == null or not is_instance_valid(control):
		return 0
	var count := 1 if bool(control.get_meta(meta_name, false)) else 0
	for raw_child in control.get_children():
		var child := _valid_control(raw_child)
		if child != null:
			count += _control_tree_meta_count(child, meta_name)
	return count


func _capture_viewport_png() -> void:
	var path := OS.get_environment("IDLE_ELITE_SWIPE_VISUAL_CAPTURE")
	if path.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		print("skill-first-swipe-visual-capture skipped=headless path=%s" % path)
		return
	var texture := root.get_texture()
	if texture == null:
		print("skill-first-swipe-visual-capture skipped=no-texture path=%s display=%s" % [path, DisplayServer.get_name()])
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("skill-first-swipe-visual-capture skipped=empty-image path=%s display=%s" % [path, DisplayServer.get_name()])
		return
	var result := image.save_png(path)
	if result == OK:
		print("skill-first-swipe-visual-capture path=%s size=%sx%s" % [path, image.get_width(), image.get_height()])
	else:
		_fail("failed to save Thieving swipe capture: %s err=%s" % [path, str(result)])


func _collect_action_stat_box_counts(control: Control, viewport_rect: Rect2, counts: Dictionary) -> void:
	if control == null or not is_instance_valid(control):
		return
	if bool(control.get_meta("action_stat_box", false)):
		counts["total"] = int(counts.get("total", 0)) + 1
		if _control_intersects_viewport(control, viewport_rect):
			counts["visible"] = int(counts.get("visible", 0)) + 1
	for raw_child in control.get_children():
		var child := _valid_control(raw_child)
		if child != null:
			_collect_action_stat_box_counts(child, viewport_rect, counts)


func _collect_marked_control_counts(control: Control, viewport_rect: Rect2, marker_name: String, counts: Dictionary) -> void:
	if control == null or not is_instance_valid(control):
		return
	if bool(control.get_meta(marker_name, false)):
		counts["total"] = int(counts.get("total", 0)) + 1
		if _control_intersects_viewport(control, viewport_rect):
			counts["visible"] = int(counts.get("visible", 0)) + 1
	for raw_child in control.get_children():
		var child := _valid_control(raw_child)
		if child != null:
			_collect_marked_control_counts(child, viewport_rect, marker_name, counts)


func _preview_page_count(scene: Node) -> int:
	var pages := scene.call("_skill_swipe_activity_surface").get("preview_pages") as Dictionary
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
    if ($null -eq $previousCapture) {
        Remove-Item Env:\IDLE_ELITE_SWIPE_VISUAL_CAPTURE -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_SWIPE_VISUAL_CAPTURE = $previousCapture
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
