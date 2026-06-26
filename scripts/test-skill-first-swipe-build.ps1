$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\skill-first-swipe-build"
$testScript = Join-Path $testDir "skill_first_swipe_build_test.gd"

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

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 90
const FINALIZE_WAIT_FRAMES := 360
const TEST_FRAME_SECONDS := 1.0 / 120.0

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("skill-first-swipe-build-start")
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
	Engine.max_fps = 0

	await _prepare_skill_page_from_menu(scene, "build")
	var expected_target := str(scene.call("_skill_id_for_swipe_offset_from", "build", 1))
	_expect(expected_target == "woodcutting", "Build +1 swipe target should be woodcutting, got %s." % expected_target)
	_expect(bool(scene.call("_swipe_offset_accessible", 1)), "Build +1 swipe target should be accessible before the first swipe: %s" % _state_summary(scene))
	scene.call("_discard_skill_detail_cache_entry", scene.call("_skill_detail_cache_key", "woodcutting"))
	scene.call("_ensure_skill_swipe_preview_page_cached", 1)
	_expect(_preview_page_count(scene) > 0, "Hidden Woodcutting preview was not seeded before first swipe: %s" % _state_summary(scene))

	await _run_first_swipe_drag(scene)
	var ready_frame := -1
	var settled_frame := -1
	for frame in range(FINALIZE_WAIT_FRAMES):
		await _wait_test_frame()
		var violation := _first_swipe_transition_violation(scene, frame)
		if not violation.is_empty():
			_expect(false, "First swipe exposed incomplete target content: %s" % str(violation))
			break
		if ready_frame < 0 and _first_swipe_page_ready(scene, "woodcutting"):
			ready_frame = frame
		if _first_swipe_transition_settled(scene, "woodcutting"):
			settled_frame = frame
			break

	_expect(ready_frame >= 0, "First build->woodcutting swipe did not produce a complete page: %s" % _state_summary(scene))
	_expect(settled_frame >= 0, "First build->woodcutting swipe did not clear the transition cover after the page was ready: %s" % _state_summary(scene))
	if failures.is_empty():
		print("skill-first-swipe-build-ok ready_frame=%s settled_frame=%s %s" % [str(ready_frame), str(settled_frame), _state_summary(scene)])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _prepare_skill_page(scene: Node, skill_id: String) -> void:
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	scene.call("_sync_passive_module_unlocks", int(scene.call("_unix_now")))
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()


func _prepare_skill_page_from_menu(scene: Node, skill_id: String) -> void:
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("current_screen", "menu")
	var menu_render = scene.call("_render_screen", false, -1, false)
	if menu_render != null:
		await menu_render
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
	scene.call("_select_skill", skill_id)
	for _i in range(SETTLE_FRAMES * 2):
		await _wait_test_frame()
		if _selected_skill_ready(scene, skill_id):
			break
	_expect(_selected_skill_ready(scene, skill_id), "Skill page did not become ready after menu selection: %s" % _state_summary(scene))


func _selected_skill_ready(scene: Node, skill_id: String) -> bool:
	if str(scene.get("current_screen")) != "skill" or str(scene.get("selected_skill_id")) != skill_id:
		return false
	if bool(scene.get("screen_render_in_progress")):
		return false
	var page := _valid_control(scene.get("skill_swipe_page"))
	if page == null or not page.visible or not page.is_visible_in_tree():
		return false
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null or not scroll.visible or not scroll.is_visible_in_tree():
		return false
	var counts := _counts(scene)
	return int(counts.get("real", 0)) > 0


func _run_first_swipe_drag(scene: Node) -> void:
	var start := Vector2(900.0, 520.0)
	var end := start + Vector2(-640.0, 0.0)
	scene.call("_begin_skill_swipe_tracking", start, -1)
	for step in range(24):
		var t := float(step + 1) / 24.0
		scene.call("_update_skill_swipe_feedback", start.lerp(end, t))
		await _wait_test_frame()
	scene.call("_finish_skill_swipe", end)


func _wait_test_frame() -> void:
	await process_frame
	await create_timer(TEST_FRAME_SECONDS, true, false, true).timeout


func _first_swipe_page_ready(scene: Node, target_skill_id: String) -> bool:
	if str(scene.get("selected_skill_id")) != target_skill_id:
		return false
	if bool(scene.get("skill_swipe_animating")) or bool(scene.get("skill_swipe_tracking")):
		return false
	if bool(scene.get("skill_swipe_pending_full_finalize")):
		return false
	var page := _valid_control(scene.get("skill_swipe_page"))
	if page == null or not page.visible or not page.is_visible_in_tree():
		return false
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null:
		return false
	if not scroll.visible or not scroll.is_visible_in_tree():
		return false
	var parent := _valid_control(scroll.get_parent())
	if parent == null or not parent.clip_contents or not parent.visible or not parent.is_visible_in_tree():
		return false
	var content := _valid_control(scene.get("skills_content"))
	if content != null and content.size.y > 1.0 and scroll.size.y / content.size.y < 0.68:
		return false
	var cards := scene.get("action_cards") as Dictionary
	if cards == null or cards.size() <= 0:
		return false
	if _valid_control(scene.get("detail_regen_circle")) == null:
		return false
	if _detail_header_gauge_slot_count(scene) != 1:
		return false
	var counts := _counts(scene)
	if int(counts.get("real", 0)) <= 0:
		return false
	if int(counts.get("visible_placeholders", 0)) > 0:
		return false
	return true


func _first_swipe_transition_settled(scene: Node, target_skill_id: String) -> bool:
	if not _first_swipe_page_ready(scene, target_skill_id):
		return false
	var cover := _valid_control(scene.get("skill_swipe_handoff_cover"))
	if cover == null:
		return true
	return (not cover.visible) or cover.modulate.a <= 0.05


func _first_swipe_transition_violation(scene: Node, frame_index: int) -> Dictionary:
	if str(scene.get("selected_skill_id")) != "woodcutting":
		return {}
	if not _first_swipe_target_incomplete(scene):
		return {}
	var cover := _valid_control(scene.get("skill_swipe_handoff_cover"))
	var cover_alpha := 0.0
	var cover_visible := false
	var cover_cream := false
	if cover != null:
		cover_alpha = cover.modulate.a
		cover_visible = cover.visible
		cover_cream = bool(cover.get_meta("swipe_cream_transition_cover", false))
	if cover != null and cover_visible and cover_cream and cover_alpha >= 0.92:
		return {}
	return {
		"frame": frame_index,
		"summary": _state_summary(scene),
		"cover": cover != null,
		"cover_visible": cover_visible,
		"cover_alpha": cover_alpha,
		"cover_cream": cover_cream
	}


func _first_swipe_target_incomplete(scene: Node) -> bool:
	if bool(scene.get("skill_swipe_pending_full_finalize")):
		return true
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null:
		return true
	var page := _valid_control(scene.get("skill_swipe_page"))
	if page == null or not page.visible or not page.is_visible_in_tree():
		return true
	if not scroll.visible or not scroll.is_visible_in_tree():
		return true
	var cards := scene.get("action_cards") as Dictionary
	if cards == null or cards.size() <= 0:
		return true
	var counts := _counts(scene)
	if int(counts.get("real", 0)) <= 0:
		return true
	if int(counts.get("visible_placeholders", 0)) > 0:
		return true
	if _valid_control(scene.get("detail_regen_circle")) == null:
		return true
	if _detail_header_gauge_slot_count(scene) != 1:
		return true
	return false


func _state_summary(scene: Node) -> String:
	var counts := _counts(scene)
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	var content := _valid_control(scene.get("skills_content"))
	var page := _valid_control(scene.get("skill_swipe_page"))
	var stack := _detail_stack(scene)
	var cards := scene.get("action_cards") as Dictionary
	var cover := _valid_control(scene.get("skill_swipe_handoff_cover"))
	var scroll_ratio := 0.0
	if scroll != null and content != null and content.size.y > 1.0:
		scroll_ratio = scroll.size.y / content.size.y
	return "selected=%s pending=%s animating=%s mode=%s tracking=%s horizontal=%s queued=%s drag=%.1f strip_index=%s accessible_next=%s cards=%s real=%s visible_placeholders=%s page_visible=%s scroll_visible=%s stack_visible=%s regen=%s header_gauges=%s scroll=%s scroll_ratio=%.3f cover=%s cover_alpha=%.3f" % [
		str(scene.get("selected_skill_id")),
		str(scene.get("skill_swipe_pending_full_finalize")),
		str(scene.get("skill_swipe_animating")),
		str(scene.get("skill_swipe_animation_mode")),
		str(scene.get("skill_swipe_tracking")),
		str(scene.get("skill_swipe_horizontal")),
		str(scene.get("skill_swipe_queued_offset")),
		float(scene.get("skill_swipe_drag_offset_x")),
		str(scene.get("skill_strip_index")),
		str(scene.call("_swipe_offset_accessible", 1)),
		str(0 if cards == null else cards.size()),
		str(counts.get("real", 0)),
		str(counts.get("visible_placeholders", 0)),
		str(page != null and page.visible and page.is_visible_in_tree()),
		str(scroll != null and scroll.visible and scroll.is_visible_in_tree()),
		str(stack != null and stack.visible and stack.is_visible_in_tree()),
		str(_valid_control(scene.get("detail_regen_circle")) != null),
		str(_detail_header_gauge_slot_count(scene)),
		str(scroll != null),
		scroll_ratio,
		str(cover != null and cover.visible),
		0.0 if cover == null else cover.modulate.a
	]


func _counts(scene: Node) -> Dictionary:
	var result := {"real": 0, "visible_placeholders": 0}
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null or not scroll.visible or not scroll.is_visible_in_tree() or scroll.get_child_count() <= 0:
		return result
	var stack := _detail_stack(scene)
	if stack == null:
		return result
	var viewport_rect := scroll.get_global_rect()
	for raw_child in stack.get_children():
		var child := _valid_control(raw_child)
		if child == null or child.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		if _control_intersects_viewport(child, viewport_rect):
			result["visible_placeholders"] = int(result["visible_placeholders"]) + _placeholder_count(child)
		if _has_real_content(child):
			result["real"] = int(result["real"]) + 1
	return result


func _preview_page_count(scene: Node) -> int:
	var pages := scene.get("skill_swipe_preview_pages") as Dictionary
	return 0 if pages == null else pages.size()


func _control_intersects_viewport(control: Control, viewport_rect: Rect2) -> bool:
	if not control.visible or not control.is_visible_in_tree() or control.modulate.a <= 0.01:
		return false
	var rect := control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		return false
	return rect.intersects(viewport_rect)


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


func _detail_stack(scene: Node) -> Control:
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null or scroll.get_child_count() <= 0:
		return null
	for raw_child in scroll.get_children():
		var child := _valid_control(raw_child)
		if child != null and child.visible and child.is_visible_in_tree():
			return child
	return _valid_control(scroll.get_child(0))


func _placeholder_count(control: Control) -> int:
	var count := 0
	if bool(control.get_meta("detail_lazy_placeholder", false)):
		count += 1
	for raw_child in control.get_children():
		var child := _valid_control(raw_child)
		if child != null:
			count += _placeholder_count(child)
	return count


func _detail_header_gauge_slot_count(scene: Node) -> int:
	var header_body := _valid_control(scene.get("detail_header_body"))
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
		if bool(child.size_flags_horizontal & Control.SIZE_EXPAND):
			continue
		var rect := child.get_global_rect()
		if rect.size.x <= 1.0 or rect.size.y <= 1.0:
			continue
		count += 1
	return count


func _find_first_descendant_of_class(root_node: Control, target_class_name: String) -> Control:
	if root_node == null:
		return null
	for raw_child in root_node.get_children():
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
	push_error("skill-first-swipe-build-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "skill-first-swipe-build-ok") "Skill first-swipe build test did not report success."
    Assert-NoUnexpectedGodotErrors $output "skill first-swipe build test"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the skill first-swipe build test."
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
