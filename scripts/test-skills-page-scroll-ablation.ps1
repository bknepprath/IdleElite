$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$workRoot = Join-Path $projectRoot ".codex-tmp\skills-page-scroll-ablation"
$projectCopy = Join-Path $workRoot "project"
$probeScript = Join-Path $workRoot "skills_page_scroll_ablation_probe.gd"

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
const INTERACTION_SAMPLE_FRAMES := 210
const FRAME_120_BUDGET_US := 8334


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
	var variant := OS.get_environment("IDLE_ELITE_SCROLL_ABLATION_VARIANT")
	var skill_id := OS.get_environment("IDLE_ELITE_SCROLL_ABLATION_SKILL")
	if skill_id.is_empty():
		skill_id = "woodcutting"
	print("SCROLL_ABLATION_START variant=%s skill=%s" % [variant, skill_id])
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
	var sample := await _sample_skill_scroll(scene, skill_id)
	print("SCROLL_ABLATION_RESULT variant=%s skill=%s action=%s avg_us=%.1f p50_us=%s p95_us=%s p99_us=%s max_us=%s over120=%s/%s cards=%s mounted=%s/%s real=%s visible_placeholders=%s objects=%s nodes=%s" % [
		variant,
		skill_id,
		sample.get("action", ""),
		float(sample.get("avg_us", 0.0)),
		sample.get("p50_us", 0),
		sample.get("p95_us", 0),
		sample.get("p99_us", 0),
		sample.get("max_us", 0),
		sample.get("over120_frames", 0),
		sample.get("sample_frames", 0),
		sample.get("cards", 0),
		sample.get("mounted", 0),
		sample.get("plan", 0),
		sample.get("real", 0),
		sample.get("visible_placeholders", 0),
		sample.get("objects", 0),
		sample.get("nodes", 0)
	])
	for raw_slow_frame in sample.get("slow_frames", []) as Array:
		var slow_frame := raw_slow_frame as Dictionary
		print("SCROLL_ABLATION_SLOW variant=%s frame=%s us=%s cards=%s mounted=%s/%s real=%s visible_placeholders=%s" % [
			variant,
			slow_frame.get("frame", 0),
			slow_frame.get("us", 0),
			slow_frame.get("cards", 0),
			slow_frame.get("mounted", 0),
			slow_frame.get("plan", 0),
			slow_frame.get("real", 0),
			slow_frame.get("visible_placeholders", 0)
		])
	quit(0)


func _sample_skill_scroll(scene: Node, skill_id: String) -> Dictionary:
	var action_id := await _prepare_skill_page(scene, skill_id)
	var scroll := _valid_control(scene.get("detail_actions_scroll"))
	var max_scroll := 0
	if scroll != null and scroll.has_method("get_max_scroll_vertical"):
		max_scroll = int(scroll.call("get_max_scroll_vertical"))
	var frame_times: Array[int] = []
	var slow_frames: Array[Dictionary] = []
	for frame_index in range(INTERACTION_SAMPLE_FRAMES):
		if scroll != null and max_scroll > 0:
			var t := float(frame_index) / float(maxi(1, INTERACTION_SAMPLE_FRAMES - 1))
			var wave := 0.5 - cos(t * TAU) * 0.5
			var scroll_y := int(round(float(max_scroll) * wave))
			scroll.set("drag_scroll_position", float(scroll_y))
			scroll.set("scroll_vertical", scroll_y)
		var started := Time.get_ticks_usec()
		await process_frame
		var elapsed := Time.get_ticks_usec() - started
		frame_times.append(elapsed)
		if elapsed > FRAME_120_BUDGET_US and slow_frames.size() < 12:
			slow_frames.append(_slow_frame_sample(scene, frame_index, elapsed))
	var counts := _counts(scene)
	return {
		"action": action_id,
		"avg_us": _average(frame_times),
		"p50_us": _percentile(frame_times, 0.50),
		"p95_us": _percentile(frame_times, 0.95),
		"p99_us": _percentile(frame_times, 0.99),
		"max_us": _max_value(frame_times),
		"over120_frames": _count_over(frame_times, FRAME_120_BUDGET_US),
		"sample_frames": frame_times.size(),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"cards": _action_card_count(scene),
		"plan": counts.get("plan", 0),
		"mounted": counts.get("mounted", 0),
		"real": counts.get("real", 0),
		"visible_placeholders": counts.get("visible_placeholders", 0),
		"slow_frames": slow_frames
	}


func _prepare_skill_page(scene: Node, skill_id: String) -> String:
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	scene.call("_passive_modules_runtime").sync_passive_module_unlocks(int(scene.call("_unix_now")))
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(SETTLE_FRAMES):
		await process_frame
	var action_id := _start_first_available_action(scene, skill_id)
	for _i in range(SETTLE_FRAMES):
		await process_frame
	return action_id


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


func _slow_frame_sample(scene: Node, frame_index: int, elapsed_us: int) -> Dictionary:
	var counts := _counts(scene)
	return {
		"frame": frame_index,
		"us": elapsed_us,
		"cards": _action_card_count(scene),
		"mounted": counts.get("mounted", 0),
		"plan": counts.get("plan", 0),
		"real": counts.get("real", 0),
		"visible_placeholders": counts.get("visible_placeholders", 0)
	}


func _counts(scene: Node) -> Dictionary:
	var result := {"plan": 0, "mounted": 0, "real": 0, "visible_placeholders": 0}
	var plan := scene.get("detail_lazy_plan") as Array
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
	push_error("scroll-ablation-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $probeScript -Encoding UTF8

$variants = @(
    "baseline",
    "strip_background_texture",
    "strip_action_art",
    "strip_card_textures",
    "strip_title_outline",
    "strip_card_border",
    "strip_stat_box_style",
    "strip_static_finalize",
    "strip_static_state",
    "strip_medal",
    "strip_mastery_bar",
    "strip_lock_preview",
    "strip_onboarding_finalize",
    "minimal_card"
)

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousVariant = $env:IDLE_ELITE_SCROLL_ABLATION_VARIANT
$previousSkill = $env:IDLE_ELITE_SCROLL_ABLATION_SKILL
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    foreach ($variant in $variants) {
        $patchedMain = Patch-MainText -Text $baseMain -Variant $variant
        Set-Content -LiteralPath $mainPath -Value $patchedMain -Encoding UTF8
        $env:IDLE_ELITE_SCROLL_ABLATION_VARIANT = $variant
        Write-Host "Running skills page scroll ablation: $variant"
        $output = & $runner --headless --path $projectCopy --script $probeScript 2>&1
        $output | Out-Host
        Assert-NoUnexpectedGodotErrors -Output $output -Context "skills page scroll ablation $variant"
        if ($LASTEXITCODE -ne 0) {
            exit $LASTEXITCODE
        }
        Assert-True (($output -join "`n") -match "SCROLL_ABLATION_RESULT variant=$([regex]::Escape($variant))") "Scroll ablation $variant did not report a result."
        $headless = @(Get-HeadlessGodotProcesses)
        if ($headless.Count -gt 0) {
            $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
            throw "A headless Godot process is still running after scroll ablation $variant."
        }
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousVariant) {
        Remove-Item Env:\IDLE_ELITE_SCROLL_ABLATION_VARIANT -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_SCROLL_ABLATION_VARIANT = $previousVariant
    }
    if ($null -eq $previousSkill) {
        Remove-Item Env:\IDLE_ELITE_SCROLL_ABLATION_SKILL -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_SCROLL_ABLATION_SKILL = $previousSkill
    }
}
