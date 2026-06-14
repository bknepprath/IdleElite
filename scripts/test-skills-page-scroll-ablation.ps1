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
        if ($text -notmatch '^(ERROR|SCRIPT ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match '^ERROR: \d+ RID allocations of type .+ were leaked at exit\.$' -or
            $text -match '^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}

function Replace-Function {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Replacement
    )

    $pattern = "(?ms)^func $([regex]::Escape($Name))\b.*?(?=^func |\z)"
    $match = [regex]::Match($Text, $pattern)
    Assert-True $match.Success "Could not find function $Name for ablation patch."
    $safeReplacement = $Replacement.TrimEnd("`r", "`n") + "`r`n`r`n"
    [regex]::Replace($Text, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $safeReplacement }, 1)
}

function Replace-TextOnce {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Needle,
        [Parameter(Mandatory = $true)][string]$Replacement
    )

    $index = $Text.IndexOf($Needle, [System.StringComparison]::Ordinal)
    Assert-True ($index -ge 0) "Could not find ablation text: $Needle"
    $Text.Substring(0, $index) + $Replacement + $Text.Substring($index + $Needle.Length)
}

function Patch-MainText {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Variant
    )

    switch ($Variant) {
        "baseline" {
            return $Text
        }
        "strip_background_texture" {
            return Replace-Function -Text $Text -Name "_action_card_background" -Replacement @'
func _action_card_background(skill_id: String, action: Dictionary) -> Control:
	var bg := ColorRect.new()
	bg.color = _skill_theme_color(skill_id).darkened(0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	return bg
'@
        }
        "strip_action_art" {
            return Replace-Function -Text $Text -Name "_action_art_image" -Replacement @'
func _action_art_image(path: String) -> Control:
	var holder := ColorRect.new()
	holder.color = Color(1.0, 1.0, 1.0, 0.0)
	holder.custom_minimum_size = ACTION_ART_SIZE
	holder.size = ACTION_ART_SIZE
	holder.position = ACTION_ART_OFFSET
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.z_index = 1
	return holder
'@
        }
        "strip_card_textures" {
            $patched = Replace-Function -Text $Text -Name "_action_card_background" -Replacement @'
func _action_card_background(skill_id: String, action: Dictionary) -> Control:
	var bg := ColorRect.new()
	bg.color = _skill_theme_color(skill_id).darkened(0.08)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 150
	return bg
'@
            return Replace-Function -Text $patched -Name "_action_art_image" -Replacement @'
func _action_art_image(path: String) -> Control:
	var holder := ColorRect.new()
	holder.color = Color(1.0, 1.0, 1.0, 0.0)
	holder.custom_minimum_size = ACTION_ART_SIZE
	holder.size = ACTION_ART_SIZE
	holder.position = ACTION_ART_OFFSET
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.z_index = 1
	return holder
'@
        }
        "strip_title_outline" {
            return Replace-TextOnce -Text $Text -Needle "const ACTION_CARD_TITLE_OUTLINE_SIZE := 34" -Replacement "const ACTION_CARD_TITLE_OUTLINE_SIZE := 0"
        }
        "strip_card_border" {
            return Replace-TextOnce -Text $Text -Needle "const ACTION_CARD_FACE_BORDER_ENABLED := true" -Replacement "const ACTION_CARD_FACE_BORDER_ENABLED := false"
        }
        "strip_stat_box_style" {
            return Replace-Function -Text $Text -Name "_action_stat_box" -Replacement @'
func _action_stat_box(label: Label, _interactive := false, _skill_id := "", _action_id := "", _stat_kind := "") -> Control:
	var box := Control.new()
	box.custom_minimum_size = Vector2(300, 222)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.set_meta("action_stat_box", true)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 18
	label.offset_right = -18
	label.offset_top = 8
	label.offset_bottom = -8
	box.add_child(label)
	if _stat_kind.is_empty():
		return box
	label.add_theme_font_size_override("font_size", 66)
	label.offset_top = 26
	label.offset_bottom = 126
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	var title_label := _action_stat_label(str(_stat_kind).to_upper())
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", COLOR_INK)
	title_label.add_theme_constant_override("outline_size", 0)
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_label.offset_left = 18
	title_label.offset_right = -18
	title_label.offset_top = 120
	title_label.offset_bottom = 198
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	box.add_child(title_label)
	label.set_meta("stat_title_label", title_label)
	return box
'@
        }
        "strip_static_finalize" {
            return Replace-Function -Text $Text -Name "_detail_lazy_finalize_action_card" -Replacement @'
func _detail_lazy_finalize_action_card(card: Dictionary, skill_id: String, action: Dictionary, action_id: String) -> void:
	card["skill_id"] = skill_id
	card["action_id"] = action_id
	card["action"] = action
	if _pending_activity_unlock_matches(action_id):
		card["unlock_ceremony_pending"] = true
'@
        }
        "strip_static_state" {
            return Replace-TextOnce -Text $Text -Needle "`t_update_action_card_static_state(card, skill_id, action, _is_action_unlocked(skill_id, action))" -Replacement "`tpass # ablation: skip action card static state"
        }
        "strip_medal" {
            return Replace-TextOnce -Text $Text -Needle "`t_set_action_card_medal(card, medal, _mastery_level(skill_id, action_id), true)" -Replacement "`tpass # ablation: skip action card medal"
        }
        "strip_mastery_bar" {
            return Replace-TextOnce -Text $Text -Needle "`t_update_action_card_mastery_bar(card, skill_id, action_id, 0.0, true)" -Replacement "`tpass # ablation: skip action card mastery bar"
        }
        "strip_lock_preview" {
            $patched = Replace-TextOnce -Text $Text -Needle "`t_prepare_locked_activity_preview_fade(card, skill_id, action)" -Replacement "`tpass # ablation: skip locked activity preview fade"
            return Replace-TextOnce -Text $patched -Needle "`t_sync_locked_activity_preview_presence(card, skill_id, action)" -Replacement "`tpass # ablation: skip locked activity preview presence"
        }
        "strip_onboarding_finalize" {
            $patched = Replace-TextOnce -Text $Text -Needle "`t_apply_onboarding_fight_action_card_stats_visibility(card, skill_id)" -Replacement "`tpass # ablation: skip onboarding stats visibility"
            return Replace-TextOnce -Text $patched -Needle "`t_schedule_activity_start_highlight_if_needed(skill_id, action_id)" -Replacement "`tpass # ablation: skip activity start highlight schedule"
        }
        "minimal_card" {
            return Replace-Function -Text $Text -Name "_build_detail_interactive_action_card" -Replacement @'
func _build_detail_interactive_action_card(skill_id: String, action: Dictionary, content_width: float, _actions_width: float) -> Dictionary:
	var action_id := str(action.get("id", ""))
	var card_root := Control.new()
	card_root.custom_minimum_size = Vector2(content_width, _activity_card_root_height())
	card_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_root.clip_contents = false
	var pop_card := ColorRect.new()
	pop_card.color = _skill_theme_color(skill_id).darkened(0.08)
	pop_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	pop_card.mouse_filter = Control.MOUSE_FILTER_PASS
	card_root.add_child(pop_card)
	var title := Label.new()
	title.text = str(action.get("name", ""))
	title.offset_left = 54
	title.offset_top = 42
	title.offset_right = 930
	title.offset_bottom = 140
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop_card.add_child(title)
	var xp_label := Label.new()
	var stamina_label := Label.new()
	var time_label := Label.new()
	var success_label := Label.new()
	var labels := [xp_label, stamina_label, time_label, success_label]
	for i in range(labels.size()):
		var label := labels[i] as Label
		label.offset_left = 54 + float(i) * 170.0
		label.offset_top = 142
		label.offset_right = label.offset_left + 150
		label.offset_bottom = 214
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pop_card.add_child(label)
	var card := {
		"root": card_root,
		"entry": null,
		"skill_id": skill_id,
		"action_id": action_id,
		"action": action,
		"pop": pop_card,
		"button": null,
		"depth": null,
		"bg": pop_card,
		"shade": null,
		"art_panel": null,
		"art": null,
		"xp": xp_label,
		"stamina": stamina_label,
		"time": time_label,
		"success": success_label,
		"stat_row": null,
		"stat_boxes": {},
		"bonus_parent": null,
		"stat_hit_buttons": {},
		"bonus_panel": {},
		"status": null,
		"medal": null,
		"mastery": null,
		"progress": null,
		"convergence_progress": null,
		"convergence_overlay": null,
		"convergence_overlay_label": null,
		"convergence_build_cta": null,
		"convergence_build_cta_title": null,
		"convergence_build_cta_meta": null,
		"fluid_strip": null,
		"border": null,
		"mission_badge_parent": pop_card,
		"mission_badge": null,
		"mission_badge_label": null,
		"lock_overlay": {},
		"medal_destination": Vector2.ZERO
	}
	return {
		"card_root": card_root,
		"card": card,
		"action_id": action_id
	}
'@
        }
        default {
            throw "Unknown scroll ablation variant: $Variant"
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
	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_max_skills_state")
	scene.call("_god_mode_unlock_actions_state")
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
	scene.call("_sync_passive_module_unlocks", int(scene.call("_unix_now")))
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
	for raw_action in scene.call("_visible_actions_for_skill", skill_id):
		var action := raw_action as Dictionary
		var action_id := str(action.get("id", ""))
		if action_id.is_empty():
			continue
		if not bool(scene.call("_is_action_unlocked", skill_id, action)):
			continue
		if bool(scene.call("_is_passive_action", action)):
			continue
		if bool(scene.call("_is_convergence_action", action)):
			continue
		var stamina := scene.get("stamina") as Dictionary
		stamina[skill_id] = float(scene.call("_max_stamina", skill_id))
		scene.set("stamina", stamina)
		if bool(scene.call("_start_action", skill_id, action_id, false)):
			return action_id
	return ""


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
			if bool(item.get("mounted", false)):
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
	if bool(control.get_meta("detail_lazy_placeholder", false)):
		return false
	if not control.visible or control.modulate.a <= 0.01:
		return false
	if bool(control.get_meta("detail_stack_entry_wrapper", false)):
		for raw_child in control.get_children():
			var child := _valid_control(raw_child)
			if child != null and not bool(child.get_meta("detail_lazy_placeholder", false)) and child.visible and child.modulate.a > 0.01:
				return true
		return false
	return maxf(control.size.y, control.custom_minimum_size.y) > 1.0


func _placeholder_count(control: Control) -> int:
	var count := 0
	if bool(control.get_meta("detail_lazy_placeholder", false)):
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
