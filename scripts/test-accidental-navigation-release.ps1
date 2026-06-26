$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\accidental-navigation-release"
$testScript = Join-Path $testDir "accidental_navigation_release.gd"

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

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "300"
$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 16

var scene: Node
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("accidental-navigation-release-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	scene = packed.instantiate()
	root.add_child(scene)
	if not await _wait_for_boot_ready():
		_fail("boot did not become ready")
		quit(1)
		return
	scene.call("_close_offline_summary_overlay")
	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_max_skills_state")
	scene.call("_god_mode_unlock_actions_state")
	scene.call("_clear_running_activity_for_test_mode")
	await _stage_skill("woodcutting")

	await _assert_release_on_page_switch_does_not_change_skill()
	await _assert_release_on_bottom_nav_does_not_change_screen()
	await _assert_clean_page_switch_tap_still_changes_skill()
	await _assert_action_tap_after_page_switch_stays_on_target_skill()

	if failures.is_empty():
		print("accidental-navigation-release-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _stage_skill(skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	scene.set("_last_rendered_screen_key", "")
	scene.call("_clear_page_switch_input_state", true)
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(SETTLE_FRAMES):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	for _i in range(SETTLE_FRAMES):
		scene.call("_update_ui", 0.016, false)
		await process_frame


func _assert_release_on_page_switch_does_not_change_skill() -> void:
	await _stage_skill("woodcutting")
	var before_skill := str(scene.get("selected_skill_id"))
	var button := _first_page_switch_button(before_skill)
	if button == null:
		_fail("missing page switch button")
		return
	var press_position := _content_safe_position()
	var release_position := button.get_global_rect().get_center()
	_send_mouse_press(press_position)
	await process_frame
	_send_mouse_release(release_position)
	await _settle_after_input()
	var after_skill := str(scene.get("selected_skill_id"))
	if after_skill != before_skill:
		_fail("content press released over page switch changed skill from %s to %s" % [before_skill, after_skill])


func _assert_release_on_bottom_nav_does_not_change_screen() -> void:
	await _stage_skill("woodcutting")
	var button := scene.get("hub_tab") as Button
	if button == null or not is_instance_valid(button):
		_fail("missing bottom hub nav button")
		return
	var before_screen := str(scene.get("current_screen"))
	var before_skill := str(scene.get("selected_skill_id"))
	var press_position := _content_safe_position()
	var release_position := button.get_global_rect().get_center()
	_send_mouse_press(press_position)
	await process_frame
	_send_mouse_release(release_position)
	await _settle_after_input()
	var after_screen := str(scene.get("current_screen"))
	var after_skill := str(scene.get("selected_skill_id"))
	if after_screen != before_screen or after_skill != before_skill:
		_fail("content press released over bottom nav changed screen/skill from %s/%s to %s/%s" % [before_screen, before_skill, after_screen, after_skill])


func _assert_clean_page_switch_tap_still_changes_skill() -> void:
	await _stage_skill("woodcutting")
	var before_skill := str(scene.get("selected_skill_id"))
	var button := _first_page_switch_button(before_skill)
	if button == null:
		_fail("missing page switch button for clean tap")
		return
	var target_skill := str(button.get_meta("page_switch_target_skill_id", ""))
	var position := button.get_global_rect().get_center()
	var press := _mouse_event(position, true)
	var press_routed = scene.call("_route_page_switch_button_global_input", press)
	await process_frame
	var release := _mouse_event(position, false)
	var release_routed = scene.call("_route_page_switch_button_global_input", release)
	await _settle_after_input(96)
	var after_skill := str(scene.get("selected_skill_id"))
	if after_skill == before_skill:
		_fail("clean page switch tap did not change skill from %s target=%s press_routed=%s release_routed=%s" % [before_skill, target_skill, str(press_routed), str(release_routed)])


func _assert_action_tap_after_page_switch_stays_on_target_skill() -> void:
	await _stage_skill("fishing")
	var nav_button := _page_switch_button_for_target("woodcutting")
	if nav_button == null:
		_fail("missing fishing-to-woodcutting page switch button")
		return
	var nav_position := nav_button.get_global_rect().get_center()
	scene.call("_input", _mouse_event(nav_position, true))
	await process_frame
	scene.call("_input", _mouse_event(nav_position, false))
	for _i in range(160):
		scene.call("_update_ui", 0.016, false)
		await process_frame
		if (
			str(scene.get("current_screen")) == "skill"
			and str(scene.get("selected_skill_id")) == "woodcutting"
			and not bool(scene.call("_page_switch_scroll_cover_active"))
			and int(scene.get("page_switch_transition_button_id")) == 0
			and not bool(scene.get("screen_render_in_progress"))
		):
			break
	if str(scene.get("selected_skill_id")) != "woodcutting":
		_fail("fishing page switch did not navigate to woodcutting; selected=%s screen=%s" % [str(scene.get("selected_skill_id")), str(scene.get("current_screen"))])
		return
	var detail_scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if detail_scroll != null and is_instance_valid(detail_scroll):
		detail_scroll.scroll_vertical = 0
		detail_scroll.set("drag_scroll_position", 0.0)
	for _i in range(12):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	for _i in range(12):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var action_card := _first_visible_action_card("woodcutting")
	if action_card.is_empty():
		_fail("missing visible woodcutting action card after fishing-to-woodcutting navigation")
		return
	var source := action_card.get("pop", null) as Control
	if source == null or not is_instance_valid(source):
		source = action_card.get("root", null) as Control
	if source == null or not is_instance_valid(source) or not source.is_inside_tree():
		_fail("woodcutting action card had no visible input source")
		return
	var tap_position := source.get_global_rect().get_center()
	var accidental_nav_button := scene.call("_page_switch_button_at_position", tap_position) as Button
	if accidental_nav_button != null:
		_fail("woodcutting action tap point was still routed as page switch target=%s rect=%s tap=%s" % [
			str(accidental_nav_button.get_meta("page_switch_target_skill_id", "")),
			str(accidental_nav_button.get_global_rect()),
			str(tap_position)
		])
		return
	scene.call("_input", _mouse_event(tap_position, true))
	await process_frame
	scene.call("_input", _mouse_event(tap_position, false))
	await _settle_after_input(24)
	var expected_action_id := str(action_card.get("action_id", ""))
	if str(scene.get("selected_skill_id")) != "woodcutting":
		_fail("woodcutting action tap after page switch navigated to %s instead of staying on woodcutting" % str(scene.get("selected_skill_id")))
	if str(scene.get("running_skill_id")) != "woodcutting" or str(scene.get("running_action_id")) != expected_action_id:
		_fail("woodcutting action tap after page switch did not start expected action. expected=woodcutting:%s running=%s:%s" % [
			expected_action_id,
			str(scene.get("running_skill_id")),
			str(scene.get("running_action_id"))
		])


func _first_page_switch_button(excluded_skill_id := "") -> Button:
	var tree := scene.get_tree()
	if tree == null:
		return null
	for raw_node in tree.get_nodes_in_group("page_switch_buttons"):
		var button := raw_node as Button
		if button != null and is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled:
			var target_skill_id := str(button.get_meta("page_switch_target_skill_id", ""))
			if not excluded_skill_id.is_empty() and target_skill_id == excluded_skill_id:
				continue
			return button
	return null


func _page_switch_button_for_target(target_skill_id: String) -> Button:
	var tree := scene.get_tree()
	if tree == null:
		return null
	for raw_node in tree.get_nodes_in_group("page_switch_buttons"):
		var button := raw_node as Button
		if button != null and is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled:
			if str(button.get_meta("page_switch_target_skill_id", "")) == target_skill_id:
				return button
	return null


func _first_visible_action_card(skill_id: String) -> Dictionary:
	var action_cards := scene.get("action_cards") as Dictionary
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if str(card.get("skill_id", "")) != skill_id:
			continue
		if str(card.get("action_id", "")).is_empty():
			continue
		var source := card.get("pop", null) as Control
		if source == null or not is_instance_valid(source):
			source = card.get("root", null) as Control
		if source != null and is_instance_valid(source) and source.is_inside_tree() and source.is_visible_in_tree():
			return card
	return {}


func _content_safe_position() -> Vector2:
	var viewport_size := root.get_visible_rect().size
	return Vector2(viewport_size.x * 0.5, viewport_size.y * 0.42)


func _send_mouse_press(position: Vector2) -> void:
	var event := _mouse_event(position, true)
	scene.call("_input", event)


func _send_mouse_release(position: Vector2) -> void:
	var event := _mouse_event(position, false)
	scene.call("_input", event)


func _mouse_event(position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = position
	event.global_position = position
	return event


func _settle_after_input(frame_count := SETTLE_FRAMES) -> void:
	for _i in range(frame_count):
		scene.call("_update_ui", 0.016, false)
		await process_frame


func _wait_for_boot_ready() -> bool:
	for _i in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if scene != null and is_instance_valid(scene):
			var queue_value = scene.get("boot_detail_render_queue")
			var queue := queue_value as Array if queue_value is Array else []
			if (
				scene.get("startup_initialized") == true
				and scene.get("boot_detail_render_in_progress") != true
				and scene.get("boot_detail_scroll_locked") != true
				and scene.get("screen_render_in_progress") != true
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
            throw "Accidental navigation release regression failed with exit code $LASTEXITCODE."
        }
        Assert-True (($output -join "`n") -match 'accidental-navigation-release-ok') "Accidental navigation release regression did not report success."
    }
    finally {
        Pop-Location
    }
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }

    $leftBehind = @()
    foreach ($process in @(Get-HeadlessGodotProcesses)) {
        if (-not $baselineHeadlessProcessIds.ContainsKey([int]$process.ProcessId)) {
            $leftBehind += $process
        }
    }
    if ($leftBehind.Count -gt 0) {
        $details = ($leftBehind | ForEach-Object { "PID=$($_.ProcessId) CMD=$($_.CommandLine)" }) -join "`n"
        throw "Headless Godot process left behind by accidental navigation release test:`n$details"
    }
}
