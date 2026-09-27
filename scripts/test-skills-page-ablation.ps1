$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$workRoot = Join-Path $projectRoot ".codex-tmp\skills-page-ablation"
$projectCopy = Join-Path $workRoot "project"
$probeScript = Join-Path $workRoot "skills_page_ablation_probe.gd"


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

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")

const SkillState := preload("res://scripts/progression/skill_state.gd")
const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 72
const FRAME_P99_BUDGET_US := 4000

var failures: Array[String] = []


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
	if not await TestHelpers.wait_for_boot_ready_truthy(self, BOOT_TIMEOUT_FRAMES, scene):
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
	if TestHelpers.truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_animating")):
		scene._skill_swipe_activity_surface()._complete_skill_swipe_navigation()
		var finalize_started := Time.get_ticks_usec()
		await process_frame
		finalize_us = Time.get_ticks_usec() - finalize_started
	for _i in range(24):
		await process_frame
	var counts := _counts(scene)
	return {
		"action": action_id,
		"drag_avg_us": TestHelpers.average(frame_times),
		"drag_p99_us": TestHelpers.percentile(frame_times, 0.99),
		"drag_max_us": _max_value(frame_times),
		"jank_frames": _count_over(frame_times, 16667),
		"sample_frames": frame_times.size(),
		"finalize_us": finalize_us,
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"cards": _action_card_count(scene),
		"real": counts.get("real", 0),
		"visible_placeholders": counts.get("visible_placeholders", 0),
		"pending_full_finalize": TestHelpers.truthy(scene.call("_skill_swipe_activity_surface").get("skill_swipe_pending_full_finalize")),
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
		if not TestHelpers.truthy(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", skill_id, action)):
			continue
		if TestHelpers.truthy(scene.call("_passive_modules_runtime").is_passive_action(action)):
			continue
		if TestHelpers.truthy(convergence_runtime.call("_is_convergence_action", action)):
			continue
		var stamina := scene.get("stamina") as Dictionary
		stamina[skill_id] = float(SkillState.host_max_stamina(skill_id, scene))
		scene.set("stamina", stamina)
		if TestHelpers.truthy(scene.call("_action_runtime").call("_start_action", skill_id, action_id, false)):
			return action_id
	return ""


func _counts(scene: Node) -> Dictionary:
	var result := {"real": 0, "visible_placeholders": 0}
	var scroll := TestHelpers.valid_control(scene.get("detail_actions_scroll"))
	if scroll == null or scroll.get_child_count() <= 0:
		return result
	var stack := TestHelpers.valid_control(scroll.get_child(0))
	if stack == null:
		return result
	var viewport_rect := scroll.get_global_rect()
	for raw_child in stack.get_children():
		var child := TestHelpers.valid_control(raw_child)
		if child == null:
			continue
		if child.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		if TestHelpers.control_intersects_viewport(child, viewport_rect):
			result["visible_placeholders"] = int(result["visible_placeholders"]) + TestHelpers.placeholder_count(child)
		if TestHelpers.has_real_content(child):
			result["real"] = int(result["real"]) + 1
	return result


func _action_card_count(scene: Node) -> int:
	var cards := scene.get("action_cards") as Dictionary
	return 0 if cards == null else cards.size()


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
