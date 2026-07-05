$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\skills-page-performance"
$testScript = Join-Path $testDir "skills_page_performance_test.gd"

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
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree


const SkillState := preload("res://scripts/progression/skill_state.gd")
const SKILLS_TO_SAMPLE := ["thieving", "build", "fight", "fishing", "woodcutting"]
const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 72
const SAMPLE_FRAMES := 420
const INTERACTION_SAMPLE_FRAMES := 210
const FRAME_BUDGET_120_US := 8334
const FRAME_BUDGET_60_US := 16667
const FRAME_P99_BUDGET_US := 4000
const FRAME_MAX_BUDGET_US := 12000
const SWIPE_OVER_120_FRAME_BUDGET := 2

var failures: Array[String] = []


func _truthy(value: Variant) -> bool:
	if value == null:
		return false
	if value is bool:
		return value
	if value is int or value is float:
		return value != 0
	if value is String:
		return not value.is_empty()
	return true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("skills-page-performance-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	OS.set_environment("IDLE_ELITE_HEADLESS_SIMPLE_ACTION_BG", "1")
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
	Engine.max_fps = 0

	for skill_id in SKILLS_TO_SAMPLE:
		var sample := await _sample_skill_page(scene, skill_id)
		_print_sample(sample)
		_check_sample(sample)

	for skill_id in SKILLS_TO_SAMPLE:
		var scroll_sample := await _sample_skill_scroll(scene, skill_id)
		_print_sample(scroll_sample)
		_check_sample(scroll_sample)

	var swipe_sample := await _sample_skill_swipes(scene, "build")
	_print_sample(swipe_sample)
	_check_sample(swipe_sample)

	var rapid_swipe_sample := await _sample_rapid_skill_swipes(scene, "build")
	_print_sample(rapid_swipe_sample)
	_check_sample(rapid_swipe_sample)

	if failures.is_empty():
		print("skills-page-performance-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _sample_skill_page(scene: Node, skill_id: String) -> Dictionary:
	var action_id := await _prepare_skill_page(scene, skill_id)

	var frame_times: Array[int] = []
	var slow_frames: Array[Dictionary] = []
	for _i in range(SAMPLE_FRAMES):
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
			slow_frames.append(_slow_frame_sample(scene, _i, elapsed))

	return _build_sample(scene, "idle", skill_id, action_id, frame_times, slow_frames)


func _prepare_skill_page(scene: Node, skill_id: String) -> String:
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	scene.call("_passive_modules_runtime").sync_passive_module_unlocks(int(scene.call("_unix_now")))
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(SETTLE_FRAMES):
		await process_frame

	var action_id := _start_first_available_action(scene, skill_id)
	for _i in range(SETTLE_FRAMES):
		await process_frame
	return action_id


func _sample_skill_scroll(scene: Node, skill_id: String) -> Dictionary:
	var action_id := await _prepare_skill_page(scene, skill_id)
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	var max_scroll := 0
	if scroll != null and scroll.has_method("get_max_scroll_vertical"):
		max_scroll = int(scroll.call("get_max_scroll_vertical"))
	var frame_times: Array[int] = []
	var slow_frames: Array[Dictionary] = []
	for _i in range(INTERACTION_SAMPLE_FRAMES):
		if scroll != null and max_scroll > 0:
			var t := float(_i) / float(maxi(1, INTERACTION_SAMPLE_FRAMES - 1))
			var wave := 0.5 - cos(t * TAU) * 0.5
			var scroll_y := int(round(float(max_scroll) * wave))
			scroll.set("drag_scroll_position", float(scroll_y))
			scroll.set("scroll_vertical", scroll_y)
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
			slow_frames.append(_slow_frame_sample(scene, _i, elapsed))
	return _build_sample(scene, "scroll", skill_id, action_id, frame_times, slow_frames)


func _sample_skill_swipes(scene: Node, start_skill_id: String) -> Dictionary:
	var action_id := await _prepare_skill_page(scene, start_skill_id)
	var frame_times: Array[int] = []
	var slow_frames: Array[Dictionary] = []
	var transition_violations: Array[Dictionary] = []
	for direction in [-1, 1]:
		await _run_skill_swipe_drag(scene, direction, frame_times, slow_frames, transition_violations)
		for _i in range(SETTLE_FRAMES):
			var started := Time.get_ticks_usec()
			await process_frame
			var elapsed := Time.get_ticks_usec() - started
			frame_times.append(elapsed)
			_record_swipe_transition_violation(scene, frame_times.size() - 1, transition_violations)
			if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
				slow_frames.append(_slow_frame_sample(scene, frame_times.size() - 1, elapsed))
	for _i in range(240):
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		_record_swipe_transition_violation(scene, frame_times.size() - 1, transition_violations)
		if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
			slow_frames.append(_slow_frame_sample(scene, frame_times.size() - 1, elapsed))
	var finalize_us := 0
	if _truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_animating")):
		scene._skill_swipe_activity_surface()._complete_skill_swipe_navigation()
		var finalize_started := Time.get_ticks_usec()
		await process_frame
		finalize_us = Time.get_ticks_usec() - finalize_started
	for _i in range(24):
		await process_frame
	var sample := _build_sample(scene, "swipe", start_skill_id, action_id, frame_times, slow_frames)
	sample["preview_pages"] = _preview_page_count(scene)
	sample["preview_states"] = _preview_state_count(scene)
	sample["pending_full_finalize"] = _truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_pending_full_finalize"))
	sample["finalize_us"] = finalize_us
	sample["transition_violations"] = transition_violations
	return sample


func _sample_rapid_skill_swipes(scene: Node, start_skill_id: String) -> Dictionary:
	var action_id := await _prepare_skill_page(scene, start_skill_id)
	var frame_times: Array[int] = []
	var slow_frames: Array[Dictionary] = []
	var transition_violations: Array[Dictionary] = []
	await _run_skill_swipe_drag(scene, 1, frame_times, slow_frames, transition_violations, 8)
	await _run_skill_swipe_drag(scene, -1, frame_times, slow_frames, transition_violations, 8)
	await _run_skill_swipe_drag(scene, 1, frame_times, slow_frames, transition_violations, 8)
	for _i in range(420):
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		_record_swipe_transition_violation(scene, frame_times.size() - 1, transition_violations)
		if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
			slow_frames.append(_slow_frame_sample(scene, frame_times.size() - 1, elapsed))
	var finalize_us := 0
	if _truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_animating")):
		scene._skill_swipe_activity_surface()._complete_skill_swipe_navigation()
		var finalize_started := Time.get_ticks_usec()
		await process_frame
		finalize_us = Time.get_ticks_usec() - finalize_started
	for _i in range(36):
		await process_frame
	var sample := _build_sample(scene, "rapid_swipe", start_skill_id, action_id, frame_times, slow_frames)
	sample["preview_pages"] = _preview_page_count(scene)
	sample["preview_states"] = _preview_state_count(scene)
	sample["pending_full_finalize"] = _truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_pending_full_finalize"))
	sample["queued_offset"] = int(scene.call("_skill_swipe_activity_surface").get("skill_swipe_queued_offset"))
	sample["finalize_us"] = finalize_us
	sample["transition_violations"] = transition_violations
	return sample


func _run_skill_swipe_drag(scene: Node, direction: int, frame_times: Array[int], slow_frames: Array[Dictionary], transition_violations: Array[Dictionary], post_finish_frames := 60) -> void:
	var start := Vector2(340.0, 520.0)
	var end := start + Vector2(float(direction) * 520.0, 0.0)
	scene.call("_skill_swipe_activity_surface").call("_begin_skill_swipe_tracking", start, -1)
	for step in range(24):
		var t := float(step + 1) / 24.0
		scene.call("_skill_swipe_activity_surface").call("_update_skill_swipe_feedback", start.lerp(end, t))
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
			slow_frames.append(_slow_frame_sample(scene, frame_times.size() - 1, elapsed))
	scene.call("_skill_swipe_activity_surface").call("_finish_skill_swipe", end)
	for _i in range(post_finish_frames):
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		_record_swipe_transition_violation(scene, frame_times.size() - 1, transition_violations)
		if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
			slow_frames.append(_slow_frame_sample(scene, frame_times.size() - 1, elapsed))


func _record_swipe_transition_violation(scene: Node, frame_index: int, transition_violations: Array[Dictionary]) -> void:
	if transition_violations.size() >= 8:
		return
	var violation := _swipe_transition_violation(scene, frame_index)
	if not violation.is_empty():
		transition_violations.append(violation)


func _swipe_transition_violation(scene: Node, frame_index: int) -> Dictionary:
	var cover := _valid_control(scene.call("_skill_swipe_activity_surface").get("skill_swipe_handoff_cover"))
	var cover_alpha := 0.0
	var cover_visible := false
	var cover_cream := false
	if cover != null:
		cover_alpha = cover.modulate.a
		cover_visible = cover.visible
		cover_cream = _truthy(cover.get_meta("swipe_cream_transition_cover", false))
	var counts := _counts(scene)
	var cards := _action_card_count(scene)
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	var page_incomplete := (
		_truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_pending_full_finalize"))
		or scroll == null
		or cards <= 0
		or int(counts.get("visible_placeholders", 0)) > 0
	)
	if not page_incomplete:
		return {}
	if cover != null and cover_visible and cover_alpha >= 0.92 and cover_cream:
		return {}
	return {
		"frame": frame_index,
		"cover": cover != null,
		"visible": cover_visible,
		"alpha": cover_alpha,
		"cream": cover_cream,
		"cards": cards,
		"real": counts.get("real", 0),
		"visible_placeholders": counts.get("visible_placeholders", 0),
		"engine_visible_placeholders": _truthy(scene.call("_skill_swipe_activity_surface").call("_skill_detail_has_visible_lazy_placeholders")),
		"engine_ready": _truthy(scene.call("_skill_swipe_activity_surface").call("_skill_detail_ready_to_reveal_under_cover")),
		"pending_full": _truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_pending_full_finalize")),
		"scroll": scroll != null
	}


func _build_sample(scene: Node, mode: String, skill_id: String, action_id: String, frame_times: Array[int], slow_frames: Array[Dictionary]) -> Dictionary:
	var counts := _counts(scene)
	var sample := {
		"mode": mode,
		"skill": skill_id,
		"action": action_id,
		"avg_us": _average(frame_times),
		"p50_us": _percentile(frame_times, 0.50),
		"p95_us": _percentile(frame_times, 0.95),
		"p99_us": _percentile(frame_times, 0.99),
		"max_us": _max_value(frame_times),
		"over120_frames": _count_over(frame_times, FRAME_BUDGET_120_US),
		"jank_frames": _count_over(frame_times, FRAME_BUDGET_60_US),
		"sample_frames": frame_times.size(),
		"draw_calls": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"cards": _action_card_count(scene),
		"plan": counts.get("plan", 0),
		"mounted": counts.get("mounted", 0),
		"real": counts.get("real", 0),
		"placeholders": counts.get("placeholders", 0),
		"visible_placeholders": counts.get("visible_placeholders", 0),
		"preview_pages": _preview_page_count(scene),
		"preview_states": _preview_state_count(scene),
		"pending_full_finalize": _truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_pending_full_finalize")),
		"slow_frames": slow_frames
	}
	var geometry := _skill_detail_geometry(scene)
	for key in geometry.keys():
		sample[key] = geometry[key]
	return sample


func _start_first_available_action(scene: Node, skill_id: String) -> String:
	var convergence_runtime: Object = scene.call("_convergence_runtime") as Object
	for raw_action in scene.call("_activity_unlock_runtime").call("_visible_actions_for_skill", skill_id):
		var action := raw_action as Dictionary
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		if not _truthy(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", skill_id, action)):
			continue
		if _truthy(scene.call("_passive_modules_runtime").is_passive_action(action)):
			continue
		if _truthy(convergence_runtime.call("_is_convergence_action", action)):
			continue
		var stamina := scene.get("stamina") as Dictionary
		stamina[skill_id] = float(SkillState.max_stamina(scene, skill_id))
		scene.set("stamina", stamina)
		if _truthy(scene.call("_action_runtime").call("_start_action", skill_id, action_id, false)):
			return action_id
	return ""


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			_truthy(scene.get("startup_initialized"))
			and not _truthy(scene.get("boot_detail_render_in_progress"))
			and not _truthy(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _slow_frame_sample(scene: Node, frame_index: int, elapsed_us: int) -> Dictionary:
	var counts := _counts(scene)
	return {
		"frame": frame_index,
		"us": elapsed_us,
		"cards": _action_card_count(scene),
		"mounted": counts.get("mounted", 0),
		"plan": counts.get("plan", 0),
		"real": counts.get("real", 0),
		"visible_placeholders": counts.get("visible_placeholders", 0),
		"ui_elapsed": float(scene.get("ui_static_refresh_elapsed")),
		"background_elapsed": float(scene.get("background_maintenance_elapsed")),
		"lazy_elapsed": float(scene.call("_skill_detail_surface").get("detail_lazy_window_sync_elapsed")),
		"running": "%s:%s" % [str(scene.get("running_skill_id")), str(scene.get("running_action_id"))],
		"progress": float(scene.get("action_progress"))
	}


func _counts(scene: Node) -> Dictionary:
	var result := {"plan": 0, "mounted": 0, "real": 0, "placeholders": 0, "visible_placeholders": 0}
	var plan := scene.call("_skill_detail_surface").get("detail_lazy_plan") as Array
	if plan != null:
		result["plan"] = plan.size()
		for raw_item in plan:
			var item := raw_item as Dictionary
			if _truthy(item.get("mounted", false)):
				result["mounted"] = int(result["mounted"]) + 1
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null or scroll.get_child_count() <= 0:
		return result
	var stack := _valid_control(scroll.get_child(0))
	if stack == null:
		return result
	var viewport_rect := scroll.get_global_rect().intersection(scene.get_viewport().get_visible_rect())
	for raw_child in stack.get_children():
		var child := _valid_control(raw_child)
		if child == null:
			continue
		if child.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		result["placeholders"] = int(result["placeholders"]) + _placeholder_count(child)
		if _control_intersects_viewport(child, viewport_rect):
			result["visible_placeholders"] = int(result["visible_placeholders"]) + _placeholder_count(child)
		if _has_real_content(child):
			result["real"] = int(result["real"]) + 1
	return result


func _control_intersects_viewport(control: Control, viewport_rect: Rect2) -> bool:
	if not control.visible or control.modulate.a <= 0.01:
		return false
	var rect := control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	return rect.intersects(viewport_rect)


func _has_real_content(control: Control) -> bool:
	if _truthy(control.get_meta("detail_lazy_placeholder", false)):
		return false
	if not control.visible or control.modulate.a <= 0.01:
		return false
	if _truthy(control.get_meta("detail_stack_entry_wrapper", false)):
		for raw_child in control.get_children():
			var child := _valid_control(raw_child)
			if child != null and not _truthy(child.get_meta("detail_lazy_placeholder", false)) and child.visible and child.modulate.a > 0.01:
				return true
		return false
	return maxf(control.size.y, control.custom_minimum_size.y) > 1.0


func _placeholder_count(control: Control) -> int:
	var count := 0
	if _truthy(control.get_meta("detail_lazy_placeholder", false)):
		count += 1
	for raw_child in control.get_children():
		var child := _valid_control(raw_child)
		if child != null:
			count += _placeholder_count(child)
	return count


func _skill_detail_geometry(scene: Node) -> Dictionary:
	var result := {
		"scroll_h": 0.0,
		"content_h": 0.0,
		"scroll_ratio": 0.0,
		"scroll_parent_is_page": false,
		"scroll_parent_clips": false,
		"selected_skill": str(scene.get("selected_skill_id")),
		"regen_gauge": _valid_control(scene._skill_detail_surface().detail_regen_circle) != null,
		"fish_gauge": _valid_control(scene._skill_detail_surface().detail_fish_circle) != null,
		"header_gauge_slots": _detail_header_gauge_slot_count(scene)
	}
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	var content := _valid_control(scene.get("skills_content"))
	var page := _valid_control(scene.call("_skill_swipe_activity_surface").get("skill_swipe_page"))
	if content != null:
		result["content_h"] = content.size.y
	if scroll == null:
		return result
	result["scroll_h"] = scroll.size.y
	if content != null and content.size.y > 1.0:
		result["scroll_ratio"] = scroll.size.y / content.size.y
	var parent := _valid_control(scroll.get_parent())
	if parent != null:
		result["scroll_parent_is_page"] = parent == page
		result["scroll_parent_clips"] = parent.clip_contents
	return result


func _detail_header_gauge_slot_count(scene: Node) -> int:
	var header_body := _valid_control(scene._skill_detail_surface().detail_header_body)
	if header_body == null:
		return 0
	var row := _find_first_descendant_of_class(header_body, "HBoxContainer")
	if row == null:
		return 0
	var count := 0
	for raw_child in row.get_children():
		var child := _valid_control(raw_child)
		if child == null or not child.visible:
			continue
		if _truthy(child.size_flags_horizontal & Control.SIZE_EXPAND):
			continue
		var rect := child.get_global_rect()
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			continue
		count += 1
	return count


func _find_first_descendant_of_class(root: Control, target_class_name: String) -> Control:
	if root == null:
		return null
	for raw_child in root.get_children():
		var child := _valid_control(raw_child)
		if child == null:
			continue
		if child.get_class() == target_class_name:
			return child
		var nested := _find_first_descendant_of_class(child, target_class_name)
		if nested != null:
			return nested
	return null


func _valid_control(value: Variant) -> Control:
	if value == null:
		return null
	if not is_instance_valid(value):
		return null
	return value as Control


func _action_card_count(scene: Node) -> int:
	var cards := scene.get("action_cards") as Dictionary
	return 0 if cards == null else cards.size()


func _preview_page_count(scene: Node) -> int:
	var pages := scene.call("_skill_swipe_activity_surface").get("preview_pages") as Dictionary
	return 0 if pages == null else pages.size()


func _preview_state_count(scene: Node) -> int:
	var states := scene.call("_skill_swipe_activity_surface").get("preview_states") as Dictionary
	return 0 if states == null else states.size()


func _average(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())


func _percentile(values: Array[int], pct: float) -> int:
	if values.is_empty():
		return 0
	var sorted := values.duplicate()
	sorted.sort()
	var index := clampi(int(floor(float(sorted.size() - 1) * pct)), 0, sorted.size() - 1)
	return int(sorted[index])


func _max_value(values: Array[int]) -> int:
	var result := 0
	for value in values:
		result = maxi(result, int(value))
	return result


func _count_over(values: Array[int], threshold: int) -> int:
	var result := 0
	for value in values:
		if int(value) > threshold:
			result += 1
	return result


func _print_sample(sample: Dictionary) -> void:
	print("SKILLS_PERF mode=%s skill=%s selected=%s action=%s avg_us=%.1f p50_us=%s p95_us=%s p99_us=%s max_us=%s over120=%s/%s jank=%s/%s draw_calls=%s objects=%s nodes=%s cards=%s mounted=%s/%s real=%s visible_placeholders=%s total_placeholders=%s preview_pages=%s preview_states=%s pending_full=%s queued_offset=%s finalize_us=%s scroll_h=%.1f content_h=%.1f scroll_ratio=%.3f parent_is_page=%s parent_clips=%s regen_gauge=%s fish_gauge=%s header_gauge_slots=%s" % [
		sample.get("mode", "idle"),
		sample.get("skill", ""),
		sample.get("selected_skill", ""),
		sample.get("action", ""),
		float(sample.get("avg_us", 0.0)),
		sample.get("p50_us", 0),
		sample.get("p95_us", 0),
		sample.get("p99_us", 0),
		sample.get("max_us", 0),
		sample.get("over120_frames", 0),
		sample.get("sample_frames", 0),
		sample.get("jank_frames", 0),
		sample.get("sample_frames", 0),
		sample.get("draw_calls", 0),
		sample.get("objects", 0),
		sample.get("nodes", 0),
		sample.get("cards", 0),
		sample.get("mounted", 0),
		sample.get("plan", 0),
		sample.get("real", 0),
		sample.get("visible_placeholders", 0),
		sample.get("placeholders", 0),
		sample.get("preview_pages", 0),
		sample.get("preview_states", 0),
		sample.get("pending_full_finalize", false),
		sample.get("queued_offset", 0),
		sample.get("finalize_us", 0),
		float(sample.get("scroll_h", 0.0)),
		float(sample.get("content_h", 0.0)),
		float(sample.get("scroll_ratio", 0.0)),
		str(sample.get("scroll_parent_is_page", false)),
		str(sample.get("scroll_parent_clips", false)),
		str(sample.get("regen_gauge", false)),
		str(sample.get("fish_gauge", false)),
		sample.get("header_gauge_slots", 0)
	])
	for raw_slow_frame in sample.get("slow_frames", []) as Array:
		var slow_frame := raw_slow_frame as Dictionary
		print("SKILLS_PERF_SLOW mode=%s skill=%s frame=%s us=%s cards=%s mounted=%s/%s real=%s visible_placeholders=%s ui_elapsed=%.4f background_elapsed=%.4f lazy_elapsed=%.4f running=%s progress=%.4f" % [
			sample.get("mode", "idle"),
			sample.get("skill", ""),
			slow_frame.get("frame", 0),
			slow_frame.get("us", 0),
			slow_frame.get("cards", 0),
			slow_frame.get("mounted", 0),
			slow_frame.get("plan", 0),
			slow_frame.get("real", 0),
			slow_frame.get("visible_placeholders", 0),
			float(slow_frame.get("ui_elapsed", 0.0)),
			float(slow_frame.get("background_elapsed", 0.0)),
			float(slow_frame.get("lazy_elapsed", 0.0)),
			slow_frame.get("running", ""),
			float(slow_frame.get("progress", 0.0))
		])
	for raw_transition in sample.get("transition_violations", []) as Array:
		var transition := raw_transition as Dictionary
		print("SKILLS_TRANSITION_VIOLATION mode=%s skill=%s frame=%s cover=%s visible=%s alpha=%.3f cream=%s cards=%s real=%s visible_placeholders=%s engine_visible_placeholders=%s engine_ready=%s pending_full=%s scroll=%s" % [
			sample.get("mode", "idle"),
			sample.get("skill", ""),
			transition.get("frame", 0),
			str(transition.get("cover", false)),
			str(transition.get("visible", false)),
			float(transition.get("alpha", 0.0)),
			str(transition.get("cream", false)),
			transition.get("cards", 0),
			transition.get("real", 0),
			transition.get("visible_placeholders", 0),
			str(transition.get("engine_visible_placeholders", false)),
			str(transition.get("engine_ready", false)),
			str(transition.get("pending_full", false)),
			str(transition.get("scroll", false))
		])


func _check_sample(sample: Dictionary) -> void:
	var skill_id := str(sample.get("skill", ""))
	var mode := str(sample.get("mode", "idle"))
	var swipe_like := mode == "swipe" or mode == "rapid_swipe"
	var over120_budget := SWIPE_OVER_120_FRAME_BUDGET if swipe_like else 0
	if int(sample.get("over120_frames", 0)) > over120_budget:
		failures.append("%s/%s has frames over the 120 FPS budget." % [mode, skill_id])
	if int(sample.get("jank_frames", 0)) > 0:
		failures.append("%s/%s has frames over the 60 FPS budget." % [mode, skill_id])
	var p99_budget := FRAME_BUDGET_120_US if mode == "scroll" or swipe_like else FRAME_P99_BUDGET_US
	var max_budget := FRAME_BUDGET_60_US if mode == "scroll" or swipe_like else FRAME_MAX_BUDGET_US
	if int(sample.get("p99_us", 0)) > p99_budget:
		failures.append("%s/%s p99 frame work exceeded %sus." % [mode, skill_id, p99_budget])
	if int(sample.get("max_us", 0)) > max_budget:
		failures.append("%s/%s max frame work exceeded %sus." % [mode, skill_id, max_budget])
	if int(sample.get("cards", 0)) > 12:
		failures.append("%s/%s mounted too many action cards for a visible skills page." % [mode, skill_id])
	if int(sample.get("visible_placeholders", 0)) > 0:
		failures.append("%s/%s left visible lazy placeholders mounted." % [mode, skill_id])
	if int(sample.get("real", 0)) <= 0:
		failures.append("%s/%s did not render real skill detail modules." % [mode, skill_id])
	if int(sample.get("preview_pages", 0)) > 1:
		failures.append("%s/%s left too many swipe preview pages cached." % [mode, skill_id])
	if swipe_like and _truthy(sample.get("pending_full_finalize", false)):
		failures.append("%s/%s did not finish converting the swipe preview to the full detail page." % [mode, skill_id])
	if swipe_like and int(sample.get("cards", 0)) <= 0:
		failures.append("%s/%s did not restore interactive action cards after swipe." % [mode, skill_id])
	if swipe_like and int(sample.get("queued_offset", 0)) != 0:
		failures.append("%s/%s left queued swipe navigation pending." % [mode, skill_id])
	if swipe_like and int(sample.get("finalize_us", 0)) > FRAME_BUDGET_120_US:
		failures.append("%s/%s forced completion frame exceeded the 120 FPS budget." % [mode, skill_id])
	if swipe_like and not (sample.get("transition_violations", []) as Array).is_empty():
		failures.append("%s/%s exposed incomplete swipe content without an opaque cream cover." % [mode, skill_id])
	if swipe_like:
		var selected_skill := str(sample.get("selected_skill", skill_id))
		if selected_skill == "fishing" and not _truthy(sample.get("fish_gauge", false)):
			failures.append("%s/%s did not rebuild the fish gauge after swipe." % [mode, selected_skill])
		elif selected_skill != "fishing" and not _truthy(sample.get("regen_gauge", false)):
			failures.append("%s/%s did not rebuild the regen stamina gauge after swipe." % [mode, selected_skill])
		if int(sample.get("header_gauge_slots", 0)) != 1:
			failures.append("%s/%s has %s visible header gauge slots after swipe." % [mode, selected_skill, sample.get("header_gauge_slots", 0)])
	if swipe_like and _truthy(sample.get("scroll_parent_is_page", false)):
		failures.append("%s/%s mounted detail actions directly under the page VBox after swipe." % [mode, skill_id])
	if swipe_like and not _truthy(sample.get("scroll_parent_clips", false)):
		failures.append("%s/%s detail actions parent does not clip after swipe." % [mode, skill_id])
	if swipe_like and float(sample.get("scroll_ratio", 0.0)) < 0.68:
		failures.append("%s/%s detail actions viewport is too short after swipe: ratio %.3f." % [mode, skill_id, float(sample.get("scroll_ratio", 0.0))])


func _fail(message: String) -> void:
	push_error("skills-page-performance-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "skills-page-performance-ok") "Skills page performance test did not report success."
    Assert-NoUnexpectedGodotErrors $output "skills page performance test"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the skills page performance test."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
