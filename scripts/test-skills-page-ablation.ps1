$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$workRoot = Join-Path $projectRoot ".codex-tmp\skills-page-ablation"
$projectCopy = Join-Path $workRoot "project"
$probeScript = Join-Path $workRoot "skills_page_ablation_probe.gd"

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
$workspaceFull = [System.IO.Path]::GetFullPath($projectRoot)
$workRootFull = [System.IO.Path]::GetFullPath($workRoot)
Assert-True ($workRootFull.StartsWith($workspaceFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) "Refusing to clean an ablation path outside the workspace."

if (Test-Path -LiteralPath $workRoot) {
    Remove-Item -LiteralPath $workRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $workRoot -Force | Out-Null

$robocopyArgs = @(
    $projectRoot,
    $projectCopy,
    "/E",
    "/NFL",
    "/NDL",
    "/NJH",
    "/NJS",
    "/NP",
    "/XD",
    ".git",
    ".codex-tmp",
    ".codex-tools",
    ".firebase",
    "android",
    "ios",
    "builds",
    "release",
    "play-store",
    "google key downloads"
)
$null = & robocopy @robocopyArgs
if ($LASTEXITCODE -ge 8) {
    throw "robocopy failed with exit code $LASTEXITCODE."
}

$mainPath = Join-Path $projectCopy "scripts\main.gd"
Assert-True (Test-Path -LiteralPath $mainPath) "Copied project is missing scripts\main.gd."
$baseMain = Get-Content -LiteralPath $mainPath -Raw

@'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 72
const FRAME_P99_BUDGET_US := 4000

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
	var variant := OS.get_environment("IDLE_ELITE_ABLATION_VARIANT")
	print("ABLATION_START variant=%s" % variant)
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
	Engine.max_fps = 0
	var sample := await _sample_swipe_finalize(scene, "build")
	print("ABLATION_RESULT variant=%s drag_avg_us=%.1f drag_p99_us=%s drag_max_us=%s finalize_us=%s jank=%s/%s cards=%s objects=%s nodes=%s real=%s visible_placeholders=%s pending_full=%s selected=%s" % [
		variant,
		float(sample.get("drag_avg_us", 0.0)),
		sample.get("drag_p99_us", 0),
		sample.get("drag_max_us", 0),
		sample.get("finalize_us", 0),
		sample.get("jank_frames", 0),
		sample.get("sample_frames", 0),
		sample.get("cards", 0),
		sample.get("objects", 0),
		sample.get("nodes", 0),
		sample.get("real", 0),
		sample.get("visible_placeholders", 0),
		sample.get("pending_full_finalize", false),
		str(scene.get("selected_skill_id"))
	])
	quit(0)


func _sample_swipe_finalize(scene: Node, start_skill_id: String) -> Dictionary:
	var action_id := await _prepare_skill_page(scene, start_skill_id)
	var frame_times: Array[int] = []
	var slow_frames: Array[Dictionary] = []
	await _run_skill_swipe_drag(scene, 1, frame_times, slow_frames)
	for _i in range(120):
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
			slow_frames.append({"frame": frame_times.size() - 1, "us": elapsed})
	var finalize_us := 0
	if _truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_animating")):
		scene._skill_swipe_activity_surface()._complete_skill_swipe_navigation()
		var finalize_started := Time.get_ticks_usec()
		await process_frame
		finalize_us = Time.get_ticks_usec() - finalize_started
	for _i in range(24):
		await process_frame
	var counts := _counts(scene)
	return {
		"action": action_id,
		"drag_avg_us": _average(frame_times),
		"drag_p99_us": _percentile(frame_times, 0.99),
		"drag_max_us": _max_value(frame_times),
		"jank_frames": _count_over(frame_times, 16667),
		"sample_frames": frame_times.size(),
		"finalize_us": finalize_us,
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"cards": _action_card_count(scene),
		"real": counts.get("real", 0),
		"visible_placeholders": counts.get("visible_placeholders", 0),
		"pending_full_finalize": _truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_pending_full_finalize")),
		"slow_frames": slow_frames
	}


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


func _run_skill_swipe_drag(scene: Node, direction: int, frame_times: Array[int], slow_frames: Array[Dictionary]) -> void:
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
			slow_frames.append({"frame": frame_times.size() - 1, "us": elapsed})
	scene.call("_skill_swipe_activity_surface").call("_finish_skill_swipe", end)
	for _i in range(60):
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		if elapsed > FRAME_P99_BUDGET_US and slow_frames.size() < 8:
			slow_frames.append({"frame": frame_times.size() - 1, "us": elapsed})


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
		stamina[skill_id] = float(scene.call("_max_stamina", skill_id))
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


func _counts(scene: Node) -> Dictionary:
	var result := {"real": 0, "visible_placeholders": 0}
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	if scroll == null or scroll.get_child_count() <= 0:
		return result
	var stack := _valid_control(scroll.get_child(0))
	if stack == null:
		return result
	var viewport_rect := scroll.get_global_rect()
	for raw_child in stack.get_children():
		var child := _valid_control(raw_child)
		if child == null:
			continue
		if child.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
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


func _valid_control(value: Variant) -> Control:
	if value == null:
		return null
	if not is_instance_valid(value):
		return null
	return value as Control


func _action_card_count(scene: Node) -> int:
	var cards := scene.get("action_cards") as Dictionary
	return 0 if cards == null else cards.size()


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


func _fail(message: String) -> void:
	push_error("ablation-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $probeScript -Encoding UTF8

$variants = @(
    "baseline",
    "strip_no_full_rebuild",
    "strip_no_post_update_ui",
    "strip_no_initial_card_mount",
    "strip_rebuild_no_render",
    "strip_rebuild_render_only",
    "strip_no_header_gauge",
    "strip_no_clear_orphans",
    "strip_no_kill_tweens",
    "strip_no_card_textures",
    "strip_no_card_static_finalize",
    "strip_no_jump_shadow"
)

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousVariant = $env:IDLE_ELITE_ABLATION_VARIANT
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    foreach ($variant in $variants) {
        $patchedMain = Patch-MainText -Text $baseMain -Variant $variant
        Set-Content -LiteralPath $mainPath -Value $patchedMain -Encoding UTF8
        $env:IDLE_ELITE_ABLATION_VARIANT = $variant
        Write-Host "Running skills page ablation: $variant"
        $output = & $runner --headless --path $projectCopy --script $probeScript 2>&1
        $output | Out-Host
        Assert-NoUnexpectedGodotErrors -Output $output -Context "skills page ablation $variant"
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        Assert-True (($output -join "`n") -match "ABLATION_RESULT variant=$([regex]::Escape($variant))") "Ablation $variant did not report a result."
        $headless = @(Get-HeadlessGodotProcesses)
        if ($headless.Count -gt 0) {
            $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
            throw "A headless Godot process is still running after ablation $variant."
        }
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousVariant) {
        Remove-Item Env:\IDLE_ELITE_ABLATION_VARIANT -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_ABLATION_VARIANT = $previousVariant
    }
}
