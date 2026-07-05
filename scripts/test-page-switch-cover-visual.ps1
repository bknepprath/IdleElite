$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\page-switch-cover-visual"
$testScript = Join-Path $testDir "page_switch_cover_visual_test.gd"
$captureDir = Join-Path $projectRoot ".codex-tmp\page-switch-cover-visual-captures"
$resultPath = Join-Path $captureDir "result.json"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-GodotProcesses {
    @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
}

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
Remove-Item -LiteralPath (Join-Path $captureDir "*.png") -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $resultPath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCaptureDir = $env:IDLE_ELITE_PAGE_SWITCH_VISUAL_DIR
$env:GODOT_RUN_TIMEOUT_SECONDS = "90"
$env:IDLE_ELITE_PAGE_SWITCH_VISUAL_DIR = $captureDir
$baselineProcessIds = @{}
foreach ($process in @(Get-GodotProcesses)) {
    $baselineProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 90
const TEST_FRAME_SECONDS := 1.0 / 120.0
const PAPER := Color("#f8f1e5")

var failures: Array[String] = []
var result := {}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(900, 1600))
	root.size = Vector2i(900, 1600)
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
		_fail("boot splash did not hide before visual capture")
		return

	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)

	await _select_skill(scene, "build")
	await _scroll_detail_to_bottom(scene)
	await _capture("before")

	var module := _find_node_by_name(scene, "PageSwitchModule") as Control
	if module == null or not module.is_visible_in_tree():
		_fail("PageSwitchModule is not visible after scrolling to bottom")
		return
	var buttons := _buttons_under(module)
	if buttons.size() < 2:
		_fail("PageSwitchModule did not expose both colored skill buttons")
		return
	var before_skill := str(scene.get("selected_skill_id"))
	var target_button := buttons[1] as Button
	_press_page_switch_button(scene, target_button)
	await process_frame
	var entering_cover := _skill_swipe_handoff_cover(scene)
	result["enter_cover_alpha"] = 0.0 if entering_cover == null or not is_instance_valid(entering_cover) else entering_cover.modulate.a
	result["enter_skill"] = str(scene.get("selected_skill_id"))
	var enter_cover_id := 0
	var enter_cover_started_msec := 0
	if entering_cover != null and is_instance_valid(entering_cover):
		enter_cover_id = entering_cover.get_instance_id()
		enter_cover_started_msec = int(entering_cover.get_meta("page_switch_scroll_cover_started_msec", 0))
	var held_pop := instance_from_id(int(target_button.get_meta("activity_button_pop_id", 0))) as Control
	var held_offset := Vector2.ZERO
	var activity_surface = scene.call("_skill_swipe_activity_surface")
	if held_pop != null and is_instance_valid(held_pop):
		held_offset = activity_surface.call("_activity_button_pop_depth_offset", held_pop) as Vector2
	result["held_offset_enter"] = str(held_offset)
	result["held_button_id_enter"] = int(scene.call("_navigation_shell").get("page_switch_transition_button_id"))
	_expect(held_offset.length() > 0.5, "page switch button should remain depressed while the cover fades in: %s" % str(held_offset))
	_expect(int(result.get("held_button_id_enter", 0)) == target_button.get_instance_id(), "page switch transition should remember the exiting button")
	for _spam in range(4):
		_press_page_switch_button(scene, target_button)
		await process_frame
	var spam_cover := _skill_swipe_handoff_cover(scene)
	var spam_cover_id := 0 if spam_cover == null or not is_instance_valid(spam_cover) else spam_cover.get_instance_id()
	var spam_cover_started_msec := 0 if spam_cover == null or not is_instance_valid(spam_cover) else int(spam_cover.get_meta("page_switch_scroll_cover_started_msec", 0))
	var spam_held_pop := instance_from_id(int(target_button.get_meta("activity_button_pop_id", 0))) as Control
	var spam_held_offset := Vector2.ZERO
	if spam_held_pop != null and is_instance_valid(spam_held_pop):
		spam_held_offset = activity_surface.call("_activity_button_pop_depth_offset", spam_held_pop) as Vector2
	result["spam_same_cover"] = spam_cover_id == enter_cover_id
	result["spam_same_started_msec"] = spam_cover_started_msec == enter_cover_started_msec
	result["spam_skill"] = str(scene.get("selected_skill_id"))
	result["held_offset_after_spam"] = str(spam_held_offset)
	_expect(bool(result.get("spam_same_cover", false)), "spamming the page switch button restarted the cover")
	_expect(bool(result.get("spam_same_started_msec", false)), "spamming the page switch button restarted the cover timer")
	_expect(str(result.get("spam_skill", "")) == before_skill, "selected skill changed before the first cover finished after spam")
	_expect(spam_held_offset.length() > 0.5, "page switch button should remain depressed after spam: %s" % str(spam_held_offset))
	_expect(float(result.get("enter_cover_alpha", 1.0)) < 0.95, "page switch cover should fade in instead of appearing fully opaque immediately: %s" % str(result.get("enter_cover_alpha", 1.0)))
	_expect(str(result.get("enter_skill", "")) == before_skill, "selected skill changed before the cream cover finished fading in")
	if not await _wait_for_cover_alpha(scene, 0.98):
		_fail("page switch cover did not finish fading in")
		return
	var cover_stats := await _capture("cover")
	var cover := _skill_swipe_handoff_cover(scene)
	result["before_skill"] = before_skill
	result["during_skill"] = str(scene.get("selected_skill_id"))
	result["cover_exists"] = cover != null and is_instance_valid(cover)
	result["cover_visible"] = cover != null and is_instance_valid(cover) and cover.visible
	result["cover_alpha"] = 0.0 if cover == null or not is_instance_valid(cover) else cover.modulate.a
	result["cover_cream_ratio"] = cover_stats.get("cream_ratio", 0.0)
	result["cover_average"] = cover_stats.get("average", "")
	var cover_rect_stats := _rect_cream_stats_from_viewport(cover.get_global_rect()) if cover != null and cover.visible else {"cream_ratio": 0.0, "average": ""}
	result["cover_rect_cream_ratio"] = cover_rect_stats.get("cream_ratio", 0.0)
	result["cover_offset_bottom"] = 0.0 if cover == null or not is_instance_valid(cover) else cover.offset_bottom
	var navigation_shell = scene.call("_navigation_shell")
	result["expected_cover_offset_bottom"] = navigation_shell.call("_global_chat_nav_cover_bottom_offset")
	var nav_bar := _valid_control(navigation_shell.get("nav_bar"))
	var nav_cover_stats := _rect_cream_stats_from_viewport(nav_bar.get_global_rect()) if nav_bar != null and nav_bar.visible else {"cream_ratio": 0.0, "average": ""}
	result["cover_nav_cream_ratio"] = nav_cover_stats.get("cream_ratio", 0.0)
	result["cover_nav_average"] = nav_cover_stats.get("average", "")
	var profile_chat = scene.call("_profile_chat_overlay_surface")
	var chat_strip := _valid_control(profile_chat.get("chat_strip") if profile_chat != null else null)
	var chat_cover_stats := _rect_cream_stats_from_viewport(chat_strip.get_global_rect()) if chat_strip != null and chat_strip.visible else {"cream_ratio": 0.0, "average": ""}
	result["cover_chat_cream_ratio"] = chat_cover_stats.get("cream_ratio", 0.0)
	result["cover_chat_average"] = chat_cover_stats.get("average", "")
	var utility_row := _valid_control(scene.get("module_utility_row"))
	var utility_cover_stats := _rect_cream_stats_from_viewport(utility_row.get_global_rect()) if utility_row != null and utility_row.visible else {"cream_ratio": 1.0, "average": ""}
	result["cover_utility_cream_ratio"] = utility_cover_stats.get("cream_ratio", 1.0)
	result["cover_utility_average"] = utility_cover_stats.get("average", "")
	_expect(bool(result.get("cover_exists", false)), "pressing page switch did not create a cover")
	_expect(bool(result.get("cover_visible", false)), "page switch cover exists but is not visible")
	_expect(float(result.get("cover_alpha", 0.0)) >= 0.92, "page switch cover alpha is not opaque: %s" % str(result.get("cover_alpha", 0.0)))
	_expect(absf(float(result.get("cover_offset_bottom", 0.0)) - float(result.get("expected_cover_offset_bottom", 0.0))) <= 0.5, "page switch cover bottom does not stop at chat/nav: expected=%s actual=%s" % [str(result.get("expected_cover_offset_bottom", 0.0)), str(result.get("cover_offset_bottom", 0.0))])
	_expect(float(result.get("cover_rect_cream_ratio", 0.0)) >= 0.96, "plain cover rect is not fully cream: %s" % str(result.get("cover_rect_cream_ratio", 0.0)))
	_expect(float(result.get("cover_nav_cream_ratio", 1.0)) < 0.90, "nav bar band should remain visible above the cream cover: %s" % str(result.get("cover_nav_cream_ratio", 1.0)))
	_expect(float(result.get("cover_chat_cream_ratio", 1.0)) < 0.90, "chat strip band should remain visible above the cream cover: %s" % str(result.get("cover_chat_cream_ratio", 1.0)))
	_expect(float(result.get("cover_utility_cream_ratio", 0.0)) >= 0.96, "module utility row band is not covered by cream: %s" % str(result.get("cover_utility_cream_ratio", 0.0)))

	for _i in range(96):
		await _wait_test_frame()
	var after_stats := await _capture("after")
	result["after_skill"] = str(scene.get("selected_skill_id"))
	result["after_cream_ratio"] = after_stats.get("cream_ratio", 0.0)
	var after_cover := _skill_swipe_handoff_cover(scene)
	result["after_cover_visible"] = after_cover != null and is_instance_valid(after_cover) and after_cover.visible
	result["after_page_switch_button_lock"] = int(scene.call("_navigation_shell").get("page_switch_transition_button_id"))
	_expect(str(result.get("after_skill", "")) != before_skill, "page switch did not change selected skill")
	_expect(not bool(result.get("after_cover_visible", false)), "page switch cover is still visible after settle")
	_expect(int(result.get("after_page_switch_button_lock", 0)) == 0, "page switch button lock did not release after settle")
	_expect(float(result.get("after_cream_ratio", 0.0)) < 0.78, "after frame still looks like a cream cover: %s" % str(result.get("after_cream_ratio", 0.0)))

	_write_result()
	if failures.is_empty():
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _select_skill(scene: Node, skill_id: String) -> void:
	scene.call("_select_skill", skill_id)
	for _i in range(SETTLE_FRAMES * 3):
		await _wait_test_frame()
		if str(scene.get("current_screen")) == "skill" and str(scene.get("selected_skill_id")) == skill_id and _valid_control(scene.get("detail_actions_scroll")) != null:
			return
	_fail("failed to select skill %s" % skill_id)


func _mouse_button_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	return event


func _press_page_switch_button(scene: Node, button: Button) -> void:
	var point := button.get_global_rect().get_center()
	scene.call("_input_routing_shell").call("_route_page_switch_button_global_input", _mouse_button_event(point, true))
	scene.call("_input_routing_shell").call("_route_page_switch_button_global_input", _mouse_button_event(point, false))


func _scroll_detail_to_bottom(scene: Node) -> void:
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null:
		_fail("missing detail_actions_scroll")
		return
	for _i in range(8):
		var max_scroll := int(scroll.call("get_max_scroll_vertical")) if scroll.has_method("get_max_scroll_vertical") else 0
		scroll.set("drag_scroll_position", float(max_scroll))
		scroll.set("scroll_vertical", max_scroll)
		await _wait_test_frame()


func _capture(name: String) -> Dictionary:
	for _i in range(3):
		await process_frame
	var stats := {"cream_ratio": 0.0, "average": ""}
	var texture := root.get_texture()
	if texture == null:
		_fail("no viewport texture for capture %s" % name)
		return stats
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("empty viewport image for capture %s" % name)
		return stats
	var capture_dir := OS.get_environment("IDLE_ELITE_PAGE_SWITCH_VISUAL_DIR")
	if not capture_dir.is_empty():
		image.save_png("%s/%s.png" % [capture_dir, name])
	stats = _image_cream_stats(image)
	result["%s_cream_ratio" % name] = stats.get("cream_ratio", 0.0)
	result["%s_average" % name] = stats.get("average", "")
	return stats


func _image_cream_stats(image: Image) -> Dictionary:
	var hits := 0
	var samples := 0
	var total := Vector3.ZERO
	var step_x := maxi(1, image.get_width() / 45)
	var step_y := maxi(1, image.get_height() / 80)
	for y in range(step_y / 2, image.get_height(), step_y):
		for x in range(step_x / 2, image.get_width(), step_x):
			var color := image.get_pixel(x, y)
			total += Vector3(color.r, color.g, color.b)
			samples += 1
			var dist := absf(color.r - PAPER.r) + absf(color.g - PAPER.g) + absf(color.b - PAPER.b)
			if dist <= 0.12:
				hits += 1
	var avg := total / float(maxi(1, samples))
	return {
		"cream_ratio": float(hits) / float(maxi(1, samples)),
		"average": "%.3f,%.3f,%.3f" % [avg.x, avg.y, avg.z],
	}


func _rect_cream_stats_from_viewport(rect: Rect2) -> Dictionary:
	var texture := root.get_texture()
	if texture == null:
		return {"cream_ratio": 0.0, "average": ""}
	var image := texture.get_image()
	if image == null or image.is_empty():
		return {"cream_ratio": 0.0, "average": ""}
	var x0 := clampi(int(floor(rect.position.x)), 0, maxi(0, image.get_width() - 1))
	var y0 := clampi(int(floor(rect.position.y)), 0, maxi(0, image.get_height() - 1))
	var x1 := clampi(int(ceil(rect.end.x)), x0 + 1, image.get_width())
	var y1 := clampi(int(ceil(rect.end.y)), y0 + 1, image.get_height())
	var hits := 0
	var samples := 0
	var total := Vector3.ZERO
	var step_x := maxi(1, (x1 - x0) / 16)
	var step_y := maxi(1, (y1 - y0) / 10)
	for y in range(y0 + step_y / 2, y1, step_y):
		for x in range(x0 + step_x / 2, x1, step_x):
			var color := image.get_pixel(x, y)
			total += Vector3(color.r, color.g, color.b)
			samples += 1
			var dist := absf(color.r - PAPER.r) + absf(color.g - PAPER.g) + absf(color.b - PAPER.b)
			if dist <= 0.12:
				hits += 1
	var avg := total / float(maxi(1, samples))
	return {
		"cream_ratio": float(hits) / float(maxi(1, samples)),
		"average": "%.3f,%.3f,%.3f" % [avg.x, avg.y, avg.z],
	}


func _buttons_under(node: Node) -> Array:
	var found := []
	if node is Button:
		found.append(node)
	for child in node.get_children():
		found.append_array(_buttons_under(child))
	return found


func _find_node_by_name(node: Node, wanted_name: String) -> Node:
	if node.name == wanted_name:
		return node
	for child in node.get_children():
		var found := _find_node_by_name(child, wanted_name)
		if found != null:
			return found
	return null


func _write_result() -> void:
	result["failures"] = failures
	var capture_dir := OS.get_environment("IDLE_ELITE_PAGE_SWITCH_VISUAL_DIR")
	if capture_dir.is_empty():
		return
	var file := FileAccess.open("%s/result.json" % capture_dir, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))


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


func _wait_for_boot_hidden(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await _wait_test_frame()
		var boot_warmup = scene.call("_boot_warmup_runtime")
		var overlay := _valid_control(boot_warmup.get("overlay") if boot_warmup != null else null)
		if (boot_warmup == null or not bool(boot_warmup.get("active"))) and (overlay == null or not overlay.visible or overlay.modulate.a <= 0.01):
			return true
	return false


func _wait_for_cover_alpha(scene: Node, target_alpha: float) -> bool:
	for _frame in range(90):
		await _wait_test_frame()
		var cover := _skill_swipe_handoff_cover(scene)
		if cover != null and cover.visible and cover.modulate.a >= target_alpha:
			return true
	return false


func _valid_control(value: Variant) -> Control:
	if value == null or not is_instance_valid(value):
		return null
	return value as Control


func _skill_swipe_handoff_cover(scene: Node) -> Control:
	var activity_surface = scene.call("_skill_swipe_activity_surface")
	if activity_surface == null:
		return null
	return _valid_control(activity_surface.get("skill_swipe_handoff_cover"))


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _fail(message: String) -> void:
	failures.append(message)
	_write_result()
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    & $runner --visible-game --path $projectRoot --script $testScript
    $runnerExitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    if ($runnerExitCode -ne 0) {
        if (Test-Path -LiteralPath $resultPath) {
            Get-Content -LiteralPath $resultPath | Write-Host
        }
        throw "Page-switch visual Godot run failed with exit code $runnerExitCode."
    }

    Assert-True (Test-Path -LiteralPath $resultPath) "Page-switch visual test did not write result.json."
    $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
    Assert-True (@($result.failures).Count -eq 0) "Page-switch visual test reported failures. result: $(Get-Content -LiteralPath $resultPath -Raw)"
    Assert-True ([double]$result.cover_rect_cream_ratio -ge 0.96) "Cover rect is not a plain cream sheet. result: $(Get-Content -LiteralPath $resultPath -Raw)"
    Assert-True ([double]$result.cover_nav_cream_ratio -lt 0.90) "Nav bar should remain visible above the cream cover. result: $(Get-Content -LiteralPath $resultPath -Raw)"
    Assert-True ([double]$result.cover_chat_cream_ratio -lt 0.90) "Chat strip should remain visible above the cream cover. result: $(Get-Content -LiteralPath $resultPath -Raw)"
    Assert-True (-not [bool]$result.after_cover_visible) "Cover stayed visible after settle. result: $(Get-Content -LiteralPath $resultPath -Raw)"

    $newProcesses = @(
        Get-GodotProcesses |
            Where-Object { -not $baselineProcessIds.ContainsKey([int]$_.ProcessId) }
    )
    if ($newProcesses.Count -gt 0) {
        $newProcesses | Select-Object ProcessId, CommandLine | Format-Table -AutoSize | Out-String | Write-Host
        throw "New Godot process(es) remained after page-switch visual test."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCaptureDir) {
        Remove-Item Env:\IDLE_ELITE_PAGE_SWITCH_VISUAL_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_PAGE_SWITCH_VISUAL_DIR = $previousCaptureDir
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
