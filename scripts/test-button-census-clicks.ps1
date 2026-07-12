$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\button-census-clicks"
$testScript = Join-Path $testDir "button_census_clicks.gd"

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
const CLICK_SETTLE_FRAMES := 16
const MAX_BUTTONS_PER_SCENARIO := 80

var scene: Node
var clicked_count := 0
var skipped_count := 0
var candidate_count := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("button-census-clicks-start")
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
		return
	scene.call("_achievement_overlay_surface").call("_close_offline_summary_overlay")
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.set("module_utility_collapsed", false)
	scene.set("module_ui_pinned_order", _first_module_keys(["woodcutting", "fishing", "thieving"], 4))
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	for _i in range(8):
		await process_frame

	var scenarios := _build_scenarios()
	for scenario in scenarios:
		await _exercise_scenario(scenario)

	if clicked_count <= 0:
		_record("button census did not click any buttons; discovery is not covering the live UI")
	if failures.is_empty():
		print("button-census-clicks-ok clicked=%s skipped=%s candidates=%s scenarios=%s" % [clicked_count, skipped_count, candidate_count, scenarios.size()])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _build_scenarios() -> Array[Dictionary]:
	var scenarios: Array[Dictionary] = [
		{"name": "home", "screen": "home", "skill": ""},
		{"name": "skills-menu", "screen": "menu", "skill": ""},
		{"name": "settings", "screen": "settings", "skill": ""},
		{"name": "shop", "screen": "shop", "skill": ""},
		{"name": "hub", "screen": "hub", "skill": ""},
		{"name": "leaderboard", "screen": "leaderboard", "skill": ""},
		{"name": "achievements", "screen": "achievements", "skill": ""},
		{"name": "pinned", "screen": "pinned", "skill": "woodcutting"},
		{"name": "queue", "screen": "queue", "skill": "woodcutting"},
	]
	var skill_ids: Array[String] = []
	var skills := scene.get("skills") as Dictionary
	for raw_skill_id in skills.keys():
		skill_ids.append(str(raw_skill_id))
	skill_ids.sort()
	for skill_id in skill_ids:
		scenarios.append({"name": "skill-%s" % skill_id, "screen": "skill", "skill": skill_id})
	return scenarios


func _exercise_scenario(scenario: Dictionary) -> void:
	var scenario_name := str(scenario.get("name", "unnamed"))
	if not await _stage_scenario(scenario):
		_record("%s: could not stage scenario" % scenario_name)
		return
	var before_candidates := candidate_count
	var descriptors := _visible_button_descriptors()
	print("button-census-scenario name=%s visible=%s candidates=%s" % [scenario_name, descriptors.size(), candidate_count - before_candidates])
	var limit = mini(descriptors.size(), MAX_BUTTONS_PER_SCENARIO)
	for index in range(limit):
		if not await _stage_scenario(scenario):
			_record("%s[%s]: could not restage before click" % [scenario_name, index])
			continue
		var current_descriptors := _visible_button_descriptors()
		if index >= current_descriptors.size():
			skipped_count += 1
			print("button-census-skip scenario=%s index=%s reason=disappeared-before-click" % [scenario_name, index])
			continue
		var descriptor := current_descriptors[index] as Dictionary
		var button := instance_from_id(int(descriptor.get("id", 0))) as BaseButton
		if button == null or not is_instance_valid(button) or not button.is_visible_in_tree() or button.disabled:
			_record("%s[%s]: descriptor did not resolve to a visible enabled button: %s" % [scenario_name, index, str(descriptor)])
			continue
		if _should_skip_button(button):
			skipped_count += 1
			print("button-census-skip scenario=%s index=%s button=%s" % [scenario_name, index, _button_label(button)])
			continue
		await _click_button(button, "%s[%s]" % [scenario_name, index])


func _stage_scenario(scenario: Dictionary) -> bool:
	if scene == null or not is_instance_valid(scene):
		return false
	scene.call("_achievement_overlay_surface").call("_close_offline_summary_overlay")
	scene.call("_settings_surface")._close_settings()
	scene.call("_profile_chat_overlay_surface")._close_chat_overlay()
	scene.call("_test_state_runtime")._clear_running_activity_for_test_mode()
	scene.call("_settings_surface").call("_disarm_reset_data_confirmation")
	scene.call("_fishing_ui_surface")._clear_fishing_tool_circle_menu()
	scene.set("hub_detail_open", false)
	scene.set("module_utility_collapsed", false)
	scene.set("module_ui_pinned_order", _first_module_keys(["woodcutting", "fishing", "thieving"], 4))
	scene.set("_last_rendered_screen_key", "")
	var screen := str(scenario.get("screen", "home"))
	var skill := str(scenario.get("skill", ""))
	scene.set("current_screen", screen)
	if not skill.is_empty():
		scene.set("selected_skill_id", skill)
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(12):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	if screen == "skill":
		scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
		for _i in range(6):
			scene.call("_update_ui", 0.016, false)
			await process_frame
	return true


func _visible_button_descriptors() -> Array[Dictionary]:
	var descriptors: Array[Dictionary] = []
	_collect_button_descriptors(scene, descriptors)
	descriptors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ar := a.get("rect", Rect2()) as Rect2
		var br := b.get("rect", Rect2()) as Rect2
		if absf(ar.position.y - br.position.y) > 1.0:
			return ar.position.y < br.position.y
		if absf(ar.position.x - br.position.x) > 1.0:
			return ar.position.x < br.position.x
		return str(a.get("path", "")) < str(b.get("path", ""))
	)
	return descriptors


func _collect_button_descriptors(node: Node, descriptors: Array[Dictionary]) -> void:
	if node == null:
		return
	var button := _as_button(node)
	if button != null:
		candidate_count += 1
	if button != null and _button_is_clickable(button):
		descriptors.append({
			"id": button.get_instance_id(),
			"path": str(button.get_path()),
			"name": str(button.name),
			"text": button.text if button is Button else "",
			"rect": button.get_global_rect(),
		})
	for child in node.get_children():
		_collect_button_descriptors(child, descriptors)


func _as_button(node: Node) -> BaseButton:
	if node is Button:
		return node as Button
	if node is TextureButton:
		return node as TextureButton
	if node is LinkButton:
		return node as LinkButton
	return null


func _button_is_clickable(button: BaseButton) -> bool:
	if button == null or not is_instance_valid(button):
		return false
	if button.disabled or not button.is_inside_tree() or not button.is_visible_in_tree():
		return false
	if button.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return false
	var rect := button.get_global_rect()
	if rect.size.x < 4.0 or rect.size.y < 4.0:
		return false
	var canvas_size := Vector2(1440, 2560)
	if rect.end.x < 0.0 or rect.end.y < 0.0 or rect.position.x > canvas_size.x or rect.position.y > canvas_size.y:
		return false
	return true


func _should_skip_button(button: BaseButton) -> bool:
	var label := _button_label(button).to_lower()
	var skip_needles := [
		"hard reset",
		"reset data",
		"tap again to confirm",
		"contact the dev",
		"discord",
		"copy crash report",
		"play store",
		"rate",
		"ad",
		"rewarded",
		"delete",
		"remove",
		"prune",
	]
	for needle in skip_needles:
		if label.contains(needle):
			return true
	if bool(button.get_meta("button_census_skip", false)):
		return true
	if button.has_meta("reset_default_text") or button.has_meta("reset_confirm_until"):
		return true
	return false


func _button_label(button: BaseButton) -> String:
	var parts: Array[String] = [str(button.name)]
	if button is Button:
		parts.append(str((button as Button).text))
	for key in button.get_meta_list():
		var key_text := str(key)
		if key_text.contains("target") or key_text.contains("id") or key_text.contains("screen") or key_text.contains("reset"):
			parts.append("%s=%s" % [key_text, str(button.get_meta(key))])
	return " ".join(parts)


func _click_button(button: BaseButton, context: String) -> void:
	var before_summary := _scene_summary()
	var center := button.get_global_rect().get_center()
	var local_center := button.get_global_transform().affine_inverse() * center
	print("button-census-click context=%s button=%s point=%s before=%s" % [context, _button_label(button), str(center), before_summary])
	var local_press := _mouse_button_event(local_center, center, true)
	var local_release := _mouse_button_event(local_center, center, false)
	var global_press := _mouse_button_event(center, center, true)
	var global_release := _mouse_button_event(center, center, false)
	button.emit_signal("gui_input", local_press)
	root.push_input(global_press, false)
	for _i in range(2):
		await process_frame
	button.emit_signal("gui_input", local_release)
	root.push_input(global_release, false)
	for _i in range(CLICK_SETTLE_FRAMES):
		if scene != null and is_instance_valid(scene):
			scene.call("_update_ui", 0.016, false)
		await process_frame
	if scene == null or not is_instance_valid(scene):
		_record("%s: scene was freed after clicking %s" % [context, _button_label(button)])
		return
	if bool(scene.call("_navigation_shell").get("screen_render_in_progress")):
		for _i in range(120):
			await process_frame
			if not bool(scene.call("_navigation_shell").get("screen_render_in_progress")):
				break
	if bool(scene.call("_navigation_shell").get("screen_render_in_progress")):
		_record("%s: screen render stayed in progress after clicking %s before=%s after=%s" % [context, _button_label(button), before_summary, _scene_summary()])
		return
	clicked_count += 1


func _mouse_button_event(local_position: Vector2, global_position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = local_position
	event.global_position = global_position
	return event


func _first_module_keys(skill_ids: Array[String], max_count: int) -> Array[String]:
	var keys: Array[String] = []
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	for skill_id in skill_ids:
		for raw_action in actions_by_skill.get(skill_id, []):
			var action := raw_action as Dictionary
			if action.is_empty() or bool(scene.call("_passive_modules_runtime").is_passive_action(action)):
				continue
			var action_id := str(action.get("id", ""))
			if action_id.is_empty():
				continue
			keys.append("action:%s:%s" % [skill_id, action_id])
			if keys.size() >= max_count:
				return keys
	return keys


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


func _scene_summary() -> String:
	if scene == null or not is_instance_valid(scene):
		return "scene=invalid"
	return "screen=%s skill=%s running=%s:%s render=%s modal=%s" % [
		str(scene.get("current_screen")),
		str(scene.get("selected_skill_id")),
		str(scene.get("running_skill_id")),
		str(scene.get("running_action_id")),
		str(scene.call("_navigation_shell").get("screen_render_in_progress")),
		str(scene.call("_input_routing_shell").call("_any_modal_overlay_visible")),
	]


func _record(message: String) -> void:
	failures.append(message)


func _fail(message: String) -> void:
	push_error("button-census-clicks-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "button-census-clicks-ok") "Button census click test did not report success."
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    $headless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after button census click validation."
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
