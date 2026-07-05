param(
    [switch]$Capture
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\pinned-scroll-anchor"
$testScript = Join-Path $testDir "pinned_scroll_anchor_smoke.gd"
$captureDir = Join-Path $testDir "captures"

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
if ($Capture) {
    New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
}

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCaptureDir = $env:IDLE_ELITE_PINNED_SCROLL_ANCHOR_DIR
$env:GODOT_RUN_TIMEOUT_SECONDS = "120"
if ($Capture) {
    $env:IDLE_ELITE_PINNED_SCROLL_ANCHOR_DIR = $captureDir
}
$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const PAGE_SWITCH_BOTTOM_CLEARANCE_MAX_GAP := 700.0
const ModuleUiRuntime = preload("res://scripts/module_ui/runtime.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("pinned-scroll-anchor-start")
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
	if not await _wait_for_boot_hidden(scene):
		_fail("boot splash did not hide before scroll-anchor capture")
		return
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	await _check_top_pin_does_not_render_pinned_shelf(scene)
	await _check_pin_unpin_preserves_mid_scroll(scene)
	await _check_multiple_pins_can_scroll_to_bottom_clearance(scene)

	if failures.is_empty():
		print("pinned-scroll-anchor-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			scene.get("startup_initialized") == true
			and scene.get("boot_detail_render_in_progress") != true
			and scene.get("boot_detail_scroll_locked") != true
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_for_boot_hidden(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		var overlay := scene.get("boot_warmup_overlay") as Control
		if scene.get("boot_warmup_active") != true and (overlay == null or not overlay.visible or overlay.modulate.a <= 0.01):
			return true
	return false


func _check_pin_unpin_preserves_mid_scroll(scene: Node) -> void:
	var skill_id := "build"
	var module_runtime := scene.get("module_ui_runtime") as Object
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	module_runtime.set("sort_mode", "level")
	module_runtime.set("pinned_order", [])
	module_runtime.set("collapsed", {})
	scene.set("module_ui_pending_pin_scroll_anchor", {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var module_key := _first_action_module_key(scene, skill_id)
	if module_key.is_empty():
		_record("could not find build action module for pin scroll-anchor smoke")
		return
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll):
		_record("missing detail scroll for pin scroll-anchor smoke")
		return
	var target_scroll := mini(950, scroll.get_max_scroll_vertical())
	scroll.set("drag_scroll_position", float(target_scroll))
	scroll.set("scroll_vertical", target_scroll)
	for _i in range(4):
		await process_frame
	if scroll.scroll_vertical <= 0:
		_record("could not establish mid-list scroll for pin scroll-anchor smoke")
		return
	var visible_pair := _visible_normal_module_pair(scene, scroll, skill_id)
	if visible_pair.is_empty():
		_record("could not find a visible normal source module before pin")
		return
	module_key = str(visible_pair.get("module_key", module_key))
	var source := visible_pair.get("control") as Control
	if source == null or not is_instance_valid(source):
		_record("could not find normal source module before pin")
		return
	await _capture("before-pin")
	var before_pin_y := source.get_global_rect().position.y
	var before_pin_x := source.get_global_rect().position.x
	var before_pin_scroll := scroll.scroll_vertical
	scene.call("_skill_detail_surface").call("_pin_module_ui_key", module_key, source.get_instance_id())
	for _i in range(36):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var pinned_scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if pinned_scroll == null or not is_instance_valid(pinned_scroll):
		_record("missing detail scroll after pin")
		return
	var pinned_source := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", pinned_scroll, module_key) as Control
	if pinned_source == null or not is_instance_valid(pinned_source):
		_record("could not find normal source module after pin")
		return
	await _capture("after-pin")
	var after_pin_x := pinned_source.get_global_rect().position.x
	var after_pin_y := pinned_source.get_global_rect().position.y
	if absf(after_pin_x - before_pin_x) > 3.0:
		_record("pin changed horizontal viewport position. before_x=%s after_x=%s before_scroll=%s after_scroll=%s anchor=%s" % [
			before_pin_x,
			after_pin_x,
			before_pin_scroll,
			pinned_scroll.scroll_vertical,
			str(scene.get("module_ui_pin_scroll_anchor_debug"))
		])
	if absf(after_pin_y - before_pin_y) > 5.0:
		_record("pin changed viewport position. before_y=%s after_y=%s before_scroll=%s after_scroll=%s anchor=%s" % [
			before_pin_y,
			after_pin_y,
			before_pin_scroll,
			pinned_scroll.scroll_vertical,
			str(scene.get("module_ui_pin_scroll_anchor_debug"))
		])
	var before_unpin_y := pinned_source.get_global_rect().position.y
	var before_unpin_x := pinned_source.get_global_rect().position.x
	var before_unpin_scroll := pinned_scroll.scroll_vertical
	scene.call("_skill_detail_surface").call("_unpin_module_ui_key", module_key, pinned_source.get_instance_id())
	for _i in range(44):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var unpinned_scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if unpinned_scroll == null or not is_instance_valid(unpinned_scroll):
		_record("missing detail scroll after unpin")
		return
	var unpinned_source := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", unpinned_scroll, module_key) as Control
	if unpinned_source == null or not is_instance_valid(unpinned_source):
		_record("could not find normal source module after unpin")
		return
	await _capture("after-unpin")
	var after_unpin_x := unpinned_source.get_global_rect().position.x
	var after_unpin_y := unpinned_source.get_global_rect().position.y
	if absf(after_unpin_x - before_unpin_x) > 3.0:
		_record("unpin changed horizontal viewport position. before_x=%s after_x=%s before_scroll=%s after_scroll=%s anchor=%s" % [
			before_unpin_x,
			after_unpin_x,
			before_unpin_scroll,
			unpinned_scroll.scroll_vertical,
			str(scene.get("module_ui_pin_scroll_anchor_debug"))
		])
	if absf(after_unpin_y - before_unpin_y) > 5.0 and unpinned_scroll.scroll_vertical > 0:
		_record("unpin changed viewport position. before_y=%s after_y=%s before_scroll=%s after_scroll=%s anchor=%s" % [
			before_unpin_y,
			after_unpin_y,
			before_unpin_scroll,
			unpinned_scroll.scroll_vertical,
			str(scene.get("module_ui_pin_scroll_anchor_debug"))
		])


func _check_top_pin_does_not_render_pinned_shelf(scene: Node) -> void:
	var skill_id := "build"
	var module_runtime := scene.get("module_ui_runtime") as Object
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	module_runtime.set("sort_mode", "level")
	module_runtime.set("pinned_order", [])
	module_runtime.set("collapsed", {})
	scene.set("module_ui_pending_pin_scroll_anchor", {})
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	var module_key := _first_action_module_key(scene, skill_id)
	if module_key.is_empty():
		_record("could not find build action module for top pin no-shelf smoke")
		return
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll):
		_record("missing detail scroll for top pin no-shelf smoke")
		return
	scroll.set("drag_scroll_position", 0.0)
	scroll.set("scroll_vertical", 0)
	for _i in range(3):
		await process_frame
	var source := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", scroll, module_key) as Control
	if source == null or not is_instance_valid(source):
		_record("could not find normal source module before top pin")
		return
	var before_y := source.get_global_rect().position.y
	scene.call("_skill_detail_surface").call("_pin_module_ui_key", module_key, source.get_instance_id())
	for _i in range(30):
		await process_frame
	await _capture("top-after-pin")
	var pinned_scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if pinned_scroll == null or not is_instance_valid(pinned_scroll):
		_record("missing detail scroll after top pin")
		return
	if pinned_scroll.scroll_vertical > 8:
		_record("top pin should not auto-scroll when pins only appear in the pin menu. scroll=%s anchor=%s" % [pinned_scroll.scroll_vertical, str(scene.get("module_ui_pin_scroll_anchor_debug"))])
	var shelf := _find_node_named(pinned_scroll, "PinnedModuleShelf") as Control
	if shelf != null and is_instance_valid(shelf) and shelf.is_visible_in_tree():
		_record("top pin rendered a pinned shelf on the skill page even though pins should only appear in the pin menu")
	var pinned_source := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", pinned_scroll, module_key) as Control
	if pinned_source == null or not is_instance_valid(pinned_source):
		_record("could not find normal source module after top pin")
	elif absf(pinned_source.get_global_rect().position.y - before_y) > 5.0:
		_record("top pin moved the source module on the skill page. before_y=%s after_y=%s" % [before_y, pinned_source.get_global_rect().position.y])
	module_runtime.set("pinned_order", [])
	scene.set("module_ui_pending_pin_scroll_anchor", {})
	var cleanup_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if cleanup_result != null:
		await cleanup_result
	for _i in range(4):
		await process_frame

func _check_multiple_pins_can_scroll_to_bottom_clearance(scene: Node) -> void:
	var skill_id := "build"
	var module_runtime := scene.get("module_ui_runtime") as Object
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	module_runtime.set("sort_mode", "level")
	module_runtime.set("collapsed", {})
	scene.set("module_ui_pending_pin_scroll_anchor", {})
	var pinned_keys: Array[String] = []
	for raw_action in scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", skill_id):
		var action := raw_action as Dictionary
		if action.is_empty() or scene.call("_passive_modules_runtime").is_passive_action(action) == true:
			continue
		var key := ModuleUiRuntime.action_for_record(skill_id, action)
		if not key.is_empty():
			pinned_keys.append(key)
		if pinned_keys.size() >= 4:
			break
	if pinned_keys.size() < 3:
		_record("bottom clearance smoke could not find enough build modules to pin")
		return
	module_runtime.set("pinned_order", pinned_keys)
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(10):
		await process_frame
	scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
	scene.call("_skill_detail_surface").call("_sync_detail_actions_scroll_limit")
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll):
		_record("bottom clearance smoke missing detail scroll")
		return
	var max_scroll := int(scroll.call("get_max_scroll_vertical"))
	if max_scroll <= 0:
		_record("bottom clearance smoke did not have scrollable content with pinned modules")
		return
	scroll.call("scroll_to_vertical", max_scroll, 0.0)
	scroll.set("drag_scroll_position", float(max_scroll))
	scroll.set("scroll_vertical", max_scroll)
	for _i in range(8):
		await process_frame
	await _capture("bottom-multiple-pins")
	var page_switch := _find_node_named(scroll, "PageSwitchModule") as Control
	if page_switch == null or not is_instance_valid(page_switch):
		_record("bottom clearance smoke could not find PageSwitchModule after scrolling to bottom")
		return
	var nav_shell := scene.call("_navigation_shell") as Object
	var nav_bar := nav_shell.get("nav_bar") as Control if nav_shell != null else null
	var chat_surface := scene.call("_profile_chat_overlay_surface") as Object
	var chat_strip := chat_surface.call("chat_strip_control") as Control if chat_surface != null else null
	var utility_row := scene.get("module_utility_row") as Control
	var visible_rect := root.get_visible_rect()
	var obscured_top := visible_rect.position.y + visible_rect.size.y
	for control in [nav_bar, chat_strip, utility_row]:
		if control != null and is_instance_valid(control) and control.visible:
			obscured_top = minf(obscured_top, control.get_global_rect().position.y)
	var page_rect := _visible_descendant_bounds(page_switch)
	if page_rect.size == Vector2.ZERO:
		page_rect = page_switch.get_global_rect()
	var page_bottom := page_rect.position.y + page_rect.size.y
	if page_bottom > obscured_top - 12.0:
		_record("bottom clearance smoke could not scroll page-switch controls above bottom UI. page_rect=%s scroll_rect=%s scroll_y=%s drag=%s obscured_top=%s max_scroll=%s nav=%s chat=%s utility=%s" % [
			page_rect,
			scroll.get_global_rect(),
			scroll.scroll_vertical,
			scroll.get("drag_scroll_position"),
			obscured_top,
			max_scroll,
			nav_bar.get_global_rect() if nav_bar != null and is_instance_valid(nav_bar) else Rect2(),
			chat_strip.get_global_rect() if chat_strip != null and is_instance_valid(chat_strip) else Rect2(),
			utility_row.get_global_rect() if utility_row != null and is_instance_valid(utility_row) else Rect2()
		])
	if page_bottom < obscured_top - PAGE_SWITCH_BOTTOM_CLEARANCE_MAX_GAP:
		_record("bottom clearance smoke left excessive dead space below page-switch controls. page_bottom=%s obscured_top=%s gap=%s max_scroll=%s" % [
			page_bottom,
			obscured_top,
			obscured_top - page_bottom,
			max_scroll
		])
	module_runtime.set("pinned_order", [])
	scene.set("module_ui_pending_pin_scroll_anchor", {})
	var cleanup_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if cleanup_result != null:
		await cleanup_result
	for _i in range(4):
		await process_frame


func _find_node_named(root_node: Node, target_name: String) -> Node:
	if root_node == null or not is_instance_valid(root_node):
		return null
	if root_node.name == target_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_node_named(child, target_name)
		if found != null:
			return found
	return null


func _visible_descendant_bounds(root_node: Node) -> Rect2:
	var merged := Rect2()
	var found := false
	var stack: Array[Node] = [root_node]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node == null or not is_instance_valid(node):
			continue
		if node is Control:
			var control := node as Control
			if control.visible and control.modulate.a > 0.01:
				var rect := control.get_global_rect()
				if rect.size.x > 1.0 and rect.size.y > 1.0:
					merged = rect if not found else merged.merge(rect)
					found = true
		for child_node in node.get_children():
			stack.append(child_node as Node)
	return merged if found else Rect2()


func _assert_no_exposed_anchor_jump_during_frames(scene: Node, module_key: String, expected_x: float, expected_y: float, frame_count: int, label: String) -> void:
	var observed_uncovered_anchor := false
	var observed_cover_anchor := false
	for frame_index in range(frame_count):
		await process_frame
		var scroll := scene.get("detail_actions_scroll") as ScrollContainer
		if scroll == null or not is_instance_valid(scroll):
			continue
		var source := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", scroll, module_key) as Control
		if source == null or not is_instance_valid(source):
			continue
		if scene.get("skill_detail_refresh_cover_active") == true:
			var cover := scene.get("skill_swipe_handoff_cover") as Control
			var covered_source := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", cover, module_key) as Control
			if covered_source == null or not is_instance_valid(covered_source):
				continue
			observed_cover_anchor = true
			var covered_x := covered_source.get_global_rect().position.x
			var covered_y := covered_source.get_global_rect().position.y
			if absf(covered_x - expected_x) > 3.0:
				_record("%s cover exposed a transient horizontal viewport jump on frame %s. expected_x=%s actual_x=%s scroll=%s drag=%s anchor=%s" % [
					label,
					frame_index,
					expected_x,
					covered_x,
					scroll.scroll_vertical,
					scroll.get("drag_scroll_position"),
					str(scene.get("module_ui_pin_scroll_anchor_debug"))
				])
				return
			if absf(covered_y - expected_y) > 5.0:
				_record("%s cover exposed a transient viewport jump on frame %s. expected_y=%s actual_y=%s scroll=%s drag=%s anchor=%s" % [
					label,
					frame_index,
					expected_y,
					covered_y,
					scroll.scroll_vertical,
					scroll.get("drag_scroll_position"),
					str(scene.get("module_ui_pin_scroll_anchor_debug"))
				])
				return
			continue
		observed_uncovered_anchor = true
		var source_x := source.get_global_rect().position.x
		var source_y := source.get_global_rect().position.y
		if absf(source_x - expected_x) > 3.0:
			_record("%s exposed a transient horizontal viewport jump on frame %s. expected_x=%s actual_x=%s scroll=%s drag=%s anchor=%s" % [
				label,
				frame_index,
				expected_x,
				source_x,
				scroll.scroll_vertical,
				scroll.get("drag_scroll_position"),
				str(scene.get("module_ui_pin_scroll_anchor_debug"))
			])
			return
		if absf(source_y - expected_y) > 5.0:
			_record("%s exposed a transient viewport jump on frame %s. expected_y=%s actual_y=%s scroll=%s drag=%s anchor=%s" % [
				label,
				frame_index,
				expected_y,
				source_y,
				scroll.scroll_vertical,
				scroll.get("drag_scroll_position"),
				str(scene.get("module_ui_pin_scroll_anchor_debug"))
			])
			return
	if not observed_uncovered_anchor:
		_record("%s refresh never exposed the source module after %s frames; the smoke cannot prove there was no visible jump" % [label, frame_count])
	if not observed_cover_anchor:
		_record("%s refresh never exposed the covered source module after %s frames; the smoke cannot prove the handoff cover stayed still" % [label, frame_count])


func _visible_normal_module_pair(scene: Node, scroll: ScrollContainer, skill_id: String) -> Dictionary:
	var viewport_rect := scroll.get_global_rect()
	var keys: Array[String] = []
	for raw_action in scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", skill_id):
		var action := raw_action as Dictionary
		if action.is_empty() or scene.call("_passive_modules_runtime").is_passive_action(action) == true:
			continue
		var key := ModuleUiRuntime.action_for_record(skill_id, action)
		if not key.is_empty():
			keys.append(key)
	for key in keys:
		if key == "action:build:stack-bricks":
			continue
		var control := scene.call("_skill_detail_surface").call("_find_normal_module_ui_control_for_scroll_anchor", scroll, key) as Control
		if control == null or not is_instance_valid(control):
			continue
		var rect := control.get_global_rect()
		if rect.position.y < 430.0 or rect.position.y > 1680.0:
			continue
		var overlap_top := maxf(rect.position.y, viewport_rect.position.y)
		var overlap_bottom := minf(rect.position.y + rect.size.y, viewport_rect.position.y + viewport_rect.size.y)
		if overlap_bottom - overlap_top >= minf(180.0, rect.size.y * 0.45):
			return {"module_key": key, "control": control}
	return {}


func _first_action_module_key(scene: Node, skill_id: String) -> String:
	for raw_action in scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", skill_id):
		var action := raw_action as Dictionary
		if action.is_empty() or scene.call("_passive_modules_runtime").is_passive_action(action) == true:
			continue
		var key := ModuleUiRuntime.action_for_record(skill_id, action)
		if not key.is_empty():
			return key
	return ""


func _capture(name: String) -> void:
	var capture_dir := OS.get_environment("IDLE_ELITE_PINNED_SCROLL_ANCHOR_DIR")
	if capture_dir.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		print("pinned-scroll-anchor-capture skipped=headless")
		return
	for _i in range(3):
		await process_frame
	var texture := root.get_texture()
	if texture == null:
		print("pinned-scroll-anchor-capture skipped=no-texture name=%s" % name)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("pinned-scroll-anchor-capture skipped=empty-image name=%s" % name)
		return
	var path := "%s/%s.png" % [capture_dir, name]
	var result := image.save_png(path)
	if result == OK:
		print("pinned-scroll-anchor-capture path=%s size=%sx%s" % [path, image.get_width(), image.get_height()])
	else:
		print("pinned-scroll-anchor-capture skipped=save-failed name=%s code=%s" % [name, result])


func _record(message: String) -> void:
	failures.append(message)


func _fail(message: String) -> void:
	push_error("pinned-scroll-anchor-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    if ($Capture) {
        $output = & $runner --visible-game --path $projectRoot --script $testScript 2>&1
    } else {
        $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    }
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    if (-not $Capture) {
        Assert-True (($output -join "`n") -match "pinned-scroll-anchor-ok") "Pinned scroll-anchor smoke did not report success."
    } else {
        Assert-True (Test-Path -LiteralPath (Join-Path $captureDir "before-pin.png")) "Pinned scroll-anchor before-pin capture was not created."
        Assert-True (Test-Path -LiteralPath (Join-Path $captureDir "top-after-pin.png")) "Pinned scroll-anchor top-after-pin capture was not created."
        Assert-True (Test-Path -LiteralPath (Join-Path $captureDir "after-pin.png")) "Pinned scroll-anchor after-pin capture was not created."
        Assert-True (Test-Path -LiteralPath (Join-Path $captureDir "after-unpin.png")) "Pinned scroll-anchor after-unpin capture was not created."
        Assert-True (Test-Path -LiteralPath (Join-Path $captureDir "bottom-multiple-pins.png")) "Pinned scroll-anchor bottom-multiple-pins capture was not created."
    }

    $newHeadless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A new headless Godot process is still running after pinned scroll-anchor smoke."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCaptureDir) {
        Remove-Item Env:\IDLE_ELITE_PINNED_SCROLL_ANCHOR_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_PINNED_SCROLL_ANCHOR_DIR = $previousCaptureDir
    }
    if (Test-Path -LiteralPath $testDir) {
        if ($Capture) {
            Remove-Item -LiteralPath $testScript -Force -ErrorAction SilentlyContinue
        } else {
            Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
