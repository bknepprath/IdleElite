$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fishing-click-flow"
$testScript = Join-Path $testDir "fishing_click_flow.gd"

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

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_FRAMES := 240

func _capture_if_requested(label: String) -> void:
	var capture_dir := OS.get_environment("IDLE_ELITE_FISHING_CLICK_FLOW_CAPTURE_DIR")
	if capture_dir.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		print("fishing-click-flow-capture skipped=headless label=%s" % label)
		return
	var texture := root.get_texture()
	if texture == null:
		print("fishing-click-flow-capture skipped=no-texture label=%s display=%s" % [label, DisplayServer.get_name()])
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("fishing-click-flow-capture skipped=empty-image label=%s display=%s" % [label, DisplayServer.get_name()])
		return
	var safe_label := label.replace(" ", "-").replace("/", "-").replace("\\", "-")
	var path := "%s/%s-pressed.png" % [capture_dir, safe_label]
	var result := image.save_png(path)
	print("fishing-click-flow-capture path=%s result=%s size=%sx%s display=%s" % [
		path,
		str(result),
		str(image.get_width()),
		str(image.get_height()),
		DisplayServer.get_name()
	])

func _init() -> void:
	call_deferred("_run")

func _mouse_button_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	return event

func _find_page_switch_button(root_node: Node, target_skill_id: String) -> Button:
	if root_node == null:
		return null
	var button := root_node as Button
	if (
		button != null
		and button.is_inside_tree()
		and button.is_visible_in_tree()
		and str(button.get_meta("page_switch_target_skill_id", "")) == target_skill_id
	):
		return button
	for child in root_node.get_children():
		var found := _find_page_switch_button(child, target_skill_id)
		if found != null:
			return found
	return null

func _click_page_switch_button(scene: Node, target_skill_id: String, label: String) -> bool:
	scene.call("_sync_detail_actions_scroll_limit")
	var detail_scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if detail_scroll != null and is_instance_valid(detail_scroll):
		var max_scroll: int = detail_scroll.get_max_scroll_vertical()
		detail_scroll.scroll_vertical = max_scroll
		detail_scroll.set("drag_scroll_position", float(max_scroll))
	for _frame in range(8):
		await process_frame
	var page_switch_button := _find_page_switch_button(scene, target_skill_id)
	if page_switch_button == null:
		push_error("Fishing click flow could not find %s page switch button for skill: %s" % [label, target_skill_id])
		return false
	var page_switch_point := page_switch_button.get_global_rect().get_center()
	var direct_hit := scene.call("_page_switch_button_at_position", page_switch_point) as Button
	scene.call("_input", _mouse_button_event(page_switch_point, true))
	for _frame in range(3):
		await process_frame
	if not bool(page_switch_button.get_meta("page_switch_press_active", false)):
		var scroll_debug := ""
		if detail_scroll != null and is_instance_valid(detail_scroll):
			var visible_content := scene.call("_detail_authoritative_scrollable_module_bottom") as Dictionary
			scroll_debug = " scroll=%s max=%s viewport=%s" % [
				str(detail_scroll.scroll_vertical),
				str(detail_scroll.get_max_scroll_vertical()),
				str(detail_scroll.get_global_rect())
			]
			scroll_debug += " visible_bottom=%s visible_count=%s page_switch_bottom=%s effective_viewport=%s bottom_pad=%s inset=%s" % [
				str(visible_content.get("bottom", "?")),
				str(visible_content.get("count", "?")),
				str(scene.call("_detail_stack_page_switch_bottom")),
				str(scene.call("_detail_actions_scroll_viewport_height")),
				str(scene.call("_skill_detail_bottom_scroll_pad", str(scene.get("selected_skill_id")))),
				str(scene.call("_skills_content_bottom_inset_for_screen"))
			]
		push_error("Fishing %s page-switch button did not receive press. target=%s point=%s rect=%s current=%s%s" % [
			label,
			target_skill_id,
			str(page_switch_point),
			str(page_switch_button.get_global_rect()) + " direct_hit=" + str(direct_hit == page_switch_button),
			str(scene.get("selected_skill_id")),
			scroll_debug
		])
		return false
	var pop := instance_from_id(int(page_switch_button.get_meta("activity_button_pop_id", 0))) as Control
	if pop == null or not is_instance_valid(pop):
		push_error("Fishing %s page-switch button has no animated shell pop control." % label)
		return false
	var pressed_offset := scene.call("_activity_button_pop_depth_offset", pop) as Vector2
	if pressed_offset.length() <= 0.5:
		push_error("Fishing %s page-switch button did not show press animation. offset=%s target=%s" % [
			label,
			str(pressed_offset),
			str(page_switch_button.get_meta("activity_button_depth_offset", Vector2.ZERO))
		])
		return false
	await _capture_if_requested(label)
	scene.call("_input", _mouse_button_event(page_switch_point, false))
	for _frame in range(90):
		await process_frame
		if str(scene.get("current_screen")) == "skill" and str(scene.get("selected_skill_id")) == target_skill_id:
			break
	if str(scene.get("selected_skill_id")) != target_skill_id:
		push_error("Fishing %s page-switch button release did not navigate. target=%s selected=%s screen=%s cover=%s" % [
			label,
			target_skill_id,
			str(scene.get("selected_skill_id")),
			str(scene.get("current_screen")),
			str(scene.call("_page_switch_scroll_cover_active"))
		])
		return false
	return true

func _run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(BOOT_FRAMES):
		await process_frame
	var skills := scene.get("skills") as Dictionary
	var fishing := (skills.get("fishing", {}) as Dictionary).duplicate(true)
	fishing["level"] = 1
	fishing["xp"] = 0
	skills["fishing"] = fishing
	scene.set("skills", skills)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	scene.set("equipped_fishing_tool_id", "hands")
	scene.set("selected_fishing_locations", {"beach": "rocky"})
	scene.set("module_ui_sort_mode", "level")
	scene.set("module_ui_pinned_order", [])
	scene.set("module_ui_collapsed", {})
	scene.call("_mark_action_manually_unlocked", "fishing", "beach-shallows")
	scene.call("_clear_running_activity_for_test_mode")
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _frame in range(30):
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	var area_card := {}
	for raw_card in (scene.get("action_cards") as Dictionary).values():
		var card := raw_card as Dictionary
		if bool(card.get("is_fishing_area", false)) and str(card.get("area_id", "")) == "beach":
			area_card = card
			break
	if area_card.is_empty():
		push_error("Fishing click flow could not find the rendered Beach area card.")
		quit(1)
		return
	var method_card := {}
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var candidate := raw_method_card as Dictionary
		if str(candidate.get("action_id", "")) == "beach-shallows":
			method_card = candidate
			break
	var button := method_card.get("method_button", null) as Button
	if button == null or not is_instance_valid(button) or button.disabled:
		push_error("Fishing click flow could not find an enabled rendered Shallows button.")
		quit(1)
		return
	var click_point := button.get_global_rect().get_center()
	if not bool(scene.call("_position_inside_detail_actions_viewport", click_point)):
		push_error("Fishing click flow Shallows click point is outside the activity viewport: %s" % str(click_point))
		quit(1)
		return

	var nav_bar := scene.get("nav_bar") as Control
	if nav_bar == null or not is_instance_valid(nav_bar):
		push_error("Fishing click flow could not find the bottom navigation bar.")
		quit(1)
		return
	var nav_point := nav_bar.get_global_rect().get_center()
	scene.call("_clear_skill_swipe_button_suppression")
	scene.call("_input", _mouse_button_event(click_point, true))
	for _frame in range(3):
		await process_frame
	if not bool(button.get_meta("fishing_method_press_active", false)):
		push_error("Fishing method press did not arm before bottom-nav cancellation smoke.")
		quit(1)
		return
	scene.call("_input", _mouse_button_event(nav_point, false))
	for _frame in range(3):
		await process_frame
	if bool(button.get_meta("fishing_method_press_active", false)):
		push_error("Fishing method press stayed armed after release over bottom navigation.")
		quit(1)
		return
	if button.has_meta("fishing_method_press_position") or button.has_meta("fishing_method_press_dragged"):
		push_error("Fishing method press metadata was not cleared after bottom navigation input.")
		quit(1)
		return

	scene.call("_clear_skill_swipe_button_suppression")
	scene.call("_input", _mouse_button_event(click_point, true))
	for _frame in range(3):
		await process_frame
	scene.call("_input", _mouse_button_event(click_point, false))
	scene.call("_update_ui", 0.016, false)
	await process_frame
	var hands_init_seconds := float(area_card.get("active_tool_init_seconds", -1.0))
	if hands_init_seconds > 0.0:
		push_error("Bare-hands fishing startup should not play the gear drop-in initialization. init_seconds=%s" % str(hands_init_seconds))
		quit(1)
		return
	for _frame in range(29):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var active_layer := area_card.get("active_tool_layer") as Control
	var water := area_card.get("water_strip_host") as Control
	var selected_locations := scene.get("selected_fishing_locations") as Dictionary
	if str(scene.get("running_skill_id")) != "fishing" or str(scene.get("running_action_id")) != "beach-shallows":
		push_error("Fishing click flow did not start Shallows. running=%s:%s" % [str(scene.get("running_skill_id")), str(scene.get("running_action_id"))])
		quit(1)
		return
	if str(selected_locations.get("beach", "")) != "shallows":
		push_error("Fishing click flow did not update selected Beach location: %s" % str(selected_locations))
		quit(1)
		return
	if active_layer == null or not is_instance_valid(active_layer) or not active_layer.visible:
		push_error("Fishing click flow did not show the active fishing tool animation layer.")
		quit(1)
		return
	if water == null or not is_instance_valid(water) or not water.visible:
		push_error("Fishing click flow did not show the water animation strip.")
		quit(1)
		return
	var page_neighbors := scene.call("_skill_page_neighbor_ids", "fishing") as Dictionary
	var previous_skill_id := str(page_neighbors.get("previous", ""))
	var next_skill_id := str(page_neighbors.get("next", ""))
	if not await _click_page_switch_button(scene, previous_skill_id, "green Woodcutting left"):
		quit(1)
		return
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _frame in range(30):
		await process_frame
	if not await _click_page_switch_button(scene, next_skill_id, "red Fighting right"):
		quit(1)
		return
	print("fishing-click-flow-ok")
	quit(0)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "fishing-click-flow-ok") "Fishing click flow did not report success."
}
finally {
    $headless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after fishing click flow validation."
    }
}
