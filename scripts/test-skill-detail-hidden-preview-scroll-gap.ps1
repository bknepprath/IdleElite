$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\skill-detail-hidden-preview-scroll-gap"
$testScript = Join-Path $testDir "skill_detail_hidden_preview_scroll_gap_test.gd"

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
const SETTLE_FRAMES := 80
const SKILLS_TO_SAMPLE := ["fight", "build", "woodcutting", "thieving"]
const HIDDEN_SLOT_MAX_HEIGHT := 96.0

var failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("skill-detail-hidden-preview-scroll-gap-start")
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

	scene.call("_save_runtime").call("_init_state")
	scene.call("_boot_warmup_runtime").call("validate_state")
	await _sample_case(scene, "hard_reset", false)
	if failed:
		return
	scene.call("_save_runtime").call("_init_state")
	scene.call("_boot_warmup_runtime").call("validate_state")
	await _sample_case(scene, "post_tutorial_swipe", true)
	if failed:
		return
	await _sample_swipe_load(scene)
	if failed:
		return
	await _sample_live_build_to_woodcutting_swipe(scene)
	if failed:
		return

	print("skill-detail-hidden-preview-scroll-gap-ok")
	quit(0)


func _sample_case(scene: Node, case_name: String, preview_available: bool) -> void:
	if preview_available:
		var skills := scene.get("skills") as Dictionary
		var starter_skill := str(scene.get("TUTORIAL_STARTER_SKILL_ID")) if scene.get("TUTORIAL_STARTER_SKILL_ID") != null else "fight"
		var starter_state := skills.get(starter_skill, {"xp": 0, "level": 1}) as Dictionary
		starter_state["xp"] = 16
		starter_state["level"] = 1
		skills[starter_skill] = starter_state
		scene.set("skills", skills)
		scene.set("activity_start_tip_seen", true)
		scene.set("stamina_gauge_tip_seen", true)
		scene.set("onboarding_fight_action_stats_revealed", true)
		scene.set("onboarding_swipe_navigation_unlocked", true)
		scene.set("onboarding_swipe_tip_eligible", true)
		scene.call("_boot_warmup_runtime").call("validate_state")

	for skill_id in SKILLS_TO_SAMPLE:
		var stats := await _render_and_measure(scene, skill_id)
		print("HIDDEN_PREVIEW_GAP case=%s skill=%s hidden=%s max_entry_h=%.1f max_root_h=%.1f scroll_max=%s content_count=%s" % [
			case_name,
			skill_id,
			str(stats.get("hidden_count", 0)),
			float(stats.get("max_entry_height", 0.0)),
			float(stats.get("max_root_height", 0.0)),
			str(stats.get("max_scroll", 0)),
			str(stats.get("content_count", 0))
		])
		if int(stats.get("hidden_count", 0)) <= 0:
			continue
		if float(stats.get("max_entry_height", 0.0)) > HIDDEN_SLOT_MAX_HEIGHT:
			_fail("%s/%s hidden locked preview entry still reserves %.1fpx of scroll height; %s" % [case_name, skill_id, float(stats.get("max_entry_height", 0.0)), str(stats.get("sample_detail", ""))])
			return
		if float(stats.get("max_root_height", 0.0)) > HIDDEN_SLOT_MAX_HEIGHT:
			_fail("%s/%s hidden locked preview root still reserves %.1fpx of scroll height; %s" % [case_name, skill_id, float(stats.get("max_root_height", 0.0)), str(stats.get("sample_detail", ""))])
			return
		if int(stats.get("content_count", 0)) <= 1 and int(stats.get("max_scroll", 0)) > 96:
			_fail("%s/%s fresh hidden-preview page still scrolls too far: max=%s; %s; stack=%s" % [case_name, skill_id, str(stats.get("max_scroll", 0)), str(stats.get("sample_detail", "")), str(stats.get("stack_detail", ""))])
			return


func _sample_swipe_load(scene: Node) -> void:
	scene.call("_save_runtime").call("_init_state")
	scene.call("_boot_warmup_runtime").call("validate_state")
	var skills := scene.get("skills") as Dictionary
	var starter_state := skills.get("fight", {"xp": 0, "level": 1}) as Dictionary
	starter_state["xp"] = 16
	starter_state["level"] = 1
	skills["fight"] = starter_state
	scene.set("skills", skills)
	scene.set("activity_start_tip_seen", true)
	scene.set("stamina_gauge_tip_seen", true)
	scene.set("onboarding_fight_action_stats_revealed", true)
	scene.set("onboarding_swipe_navigation_unlocked", true)
	scene.set("onboarding_swipe_tip_eligible", true)
	scene.set("skill_swipe_tip_seen", true)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fight")
	scene.call("_boot_warmup_runtime").call("validate_state")
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if render_result != null:
		await render_result
	for _i in range(SETTLE_FRAMES):
		await process_frame
		scene.call("_skill_detail_surface").call("_sync_detail_actions_scroll_limit")
	var start_skill := str(scene.get("selected_skill_id"))
	scene.call("_skill_swipe_activity_surface").call("_begin_skill_swipe_tracking", Vector2(900, 1500), -1)
	scene.call("_skill_swipe_activity_surface").call("_update_skill_swipe_feedback", Vector2(240, 1500))
	scene.call("_skill_swipe_activity_surface").call("_finish_skill_swipe", Vector2(240, 1500))
	for _i in range(SETTLE_FRAMES * 2):
		await process_frame
		scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
		scene.call("_skill_detail_surface").call("_sync_detail_actions_scroll_limit")
	var stats := _current_page_stats(scene)
	print("HIDDEN_PREVIEW_SWIPE selected=%s start=%s visible_modules=%s visible_area=%.1f scroll_max=%s stack_present=%s" % [
		str(scene.get("selected_skill_id")),
		start_skill,
		str(stats.get("visible_modules", 0)),
		float(stats.get("visible_module_area", 0.0)),
		str(stats.get("max_scroll", 0)),
		str(stats.get("stack_present", false))
	])
	if str(scene.get("selected_skill_id")) == start_skill:
		_fail("swipe did not navigate away from %s" % start_skill)
		return
	if not bool(stats.get("stack_present", false)):
		_fail("swipe target page has no detail stack")
		return
	if int(stats.get("visible_modules", 0)) <= 0 or float(stats.get("visible_module_area", 0.0)) < 50000.0:
		_fail("swipe target page did not load visible modules: %s" % str(stats))
		return


func _sample_live_build_to_woodcutting_swipe(scene: Node) -> void:
	_prepare_post_tutorial_swipe_state(scene)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "build")
	scene.call("_boot_warmup_runtime").call("validate_state")
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if render_result != null:
		await render_result
	for _i in range(SETTLE_FRAMES):
		await process_frame
	var start_stats := _current_page_stats(scene)
	if int(start_stats.get("visible_modules", 0)) <= 0:
		_fail("live build->woodcutting test started with a blank build page: %s" % str(start_stats))
		return
	var activity_surface = scene.call("_skill_swipe_activity_surface")
	var target_skill := str(activity_surface.call("_skill_id_for_swipe_offset_from", "build", 1))
	if target_skill != "woodcutting":
		_fail("live swipe expected build +1 to be woodcutting, got %s" % target_skill)
		return
	if not bool(scene.call("_onboarding_runtime").call("_swipe_offset_accessible", 1)):
		_fail("live build->woodcutting target was not accessible")
		return

	scene.call("_skill_swipe_activity_surface").call("_begin_skill_swipe_tracking", Vector2(900, 1500), -1)
	for step in range(24):
		var t := float(step + 1) / 24.0
		scene.call("_skill_swipe_activity_surface").call("_update_skill_swipe_feedback", Vector2(900, 1500).lerp(Vector2(240, 1500), t))
		await process_frame
	scene.call("_skill_swipe_activity_surface").call("_finish_skill_swipe", Vector2(240, 1500))

	var first_seen_frame := -1
	var first_seen_stats := {}
	var latest_stats := {}
	for frame in range(SETTLE_FRAMES * 4):
		await process_frame
		if str(scene.get("selected_skill_id")) != "woodcutting":
			continue
		var stats := _current_page_stats(scene)
		latest_stats = stats
		var visible_modules := int(stats.get("visible_modules", 0))
		var visible_area := float(stats.get("visible_module_area", 0.0))
		var cover_alpha := _swipe_cover_alpha(scene)
		if first_seen_frame < 0 and visible_modules > 0 and visible_area >= 50000.0:
			first_seen_frame = frame
			first_seen_stats = stats.duplicate()
		if first_seen_frame >= 0 and cover_alpha <= 0.08 and (visible_modules <= 0 or visible_area < 50000.0):
			_fail("live build->woodcutting modules appeared then disappeared at frame %s first=%s latest=%s" % [str(frame), str(first_seen_stats), str(stats)])
			return
	print("HIDDEN_PREVIEW_LIVE_SWIPE selected=%s first_seen=%s first=%s latest=%s cover_alpha=%.3f" % [
		str(scene.get("selected_skill_id")),
		str(first_seen_frame),
		str(first_seen_stats),
		str(latest_stats),
		_swipe_cover_alpha(scene)
	])
	if str(scene.get("selected_skill_id")) != "woodcutting":
		_fail("live build->woodcutting did not navigate to woodcutting")
		return
	if first_seen_frame < 0:
		_fail("live build->woodcutting never showed visible modules: %s" % str(latest_stats))
		return
	if int(latest_stats.get("visible_modules", 0)) <= 0 or float(latest_stats.get("visible_module_area", 0.0)) < 50000.0:
		_fail("live build->woodcutting ended blank: first=%s latest=%s" % [str(first_seen_stats), str(latest_stats)])
		return
	if _swipe_cover_alpha(scene) > 0.08:
		_fail("live build->woodcutting left the cream cover opaque over a ready page: first=%s latest=%s cover_alpha=%.3f" % [str(first_seen_stats), str(latest_stats), _swipe_cover_alpha(scene)])
		return


func _prepare_post_tutorial_swipe_state(scene: Node) -> void:
	scene.call("_save_runtime").call("_init_state")
	scene.call("_boot_warmup_runtime").call("validate_state")
	var skills := scene.get("skills") as Dictionary
	var starter_state := skills.get("fight", {"xp": 0, "level": 1}) as Dictionary
	starter_state["xp"] = 16
	starter_state["level"] = 1
	skills["fight"] = starter_state
	scene.set("skills", skills)
	scene.set("activity_start_tip_seen", true)
	scene.set("stamina_gauge_tip_seen", true)
	scene.set("onboarding_fight_action_stats_revealed", true)
	scene.set("onboarding_swipe_navigation_unlocked", true)
	scene.set("onboarding_swipe_tip_eligible", true)
	scene.set("skill_swipe_tip_seen", true)
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.call("_boot_warmup_runtime").call("validate_state")


func _render_and_measure(scene: Node, skill_id: String) -> Dictionary:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.call("_passive_modules_runtime").sync_passive_module_unlocks(int(scene.call("_unix_now")))
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, 0, false)
	if render_result != null:
		await render_result
	for _i in range(SETTLE_FRAMES):
		await process_frame
		scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
		scene.call("_skill_detail_surface").call("_sync_detail_actions_scroll_limit")
	scene.call("_skill_detail_surface").call("_detail_lazy_mount_all_sync", true)
	scene.call("_skill_detail_surface").call("_sync_detail_actions_scroll_limit")
	await process_frame

	var hidden_count := 0
	var max_entry_height := 0.0
	var max_root_height := 0.0
	var sample_detail := ""
	var cards := scene.get("action_cards") as Dictionary
	for raw_key in cards.keys():
		var key := str(raw_key)
		var raw_card = cards[raw_key]
		var card := raw_card as Dictionary
		if not bool(card.get("locked_preview_hidden", false)):
			continue
		var root_control := _valid_control(card.get("root"))
		var entry_control := _valid_control(card.get("entry"))
		if root_control == null or entry_control == null:
			continue
		if not root_control.is_inside_tree() or not entry_control.is_inside_tree():
			continue
		hidden_count += 1
		if sample_detail.is_empty():
			sample_detail = "%s same=%s root_min=%.1f root_size=%.1f entry_min=%.1f entry_size=%.1f target=%s entry_target=%s" % [
				key,
				str(root_control == entry_control),
				root_control.custom_minimum_size.y,
				root_control.size.y,
				entry_control.custom_minimum_size.y,
				entry_control.size.y,
				str(card.get("locked_preview_target_height", "none")),
				str(card.get("locked_preview_entry_target_height", "none"))
			]
		max_root_height = maxf(max_root_height, _allocated_control_height(root_control))
		max_entry_height = maxf(max_entry_height, _allocated_control_height(entry_control))
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	var detail_surface = scene.call("_skill_detail_surface")
	var visible_content := detail_surface.call("_detail_authoritative_scrollable_module_bottom") as Dictionary
	var stack_detail := _stack_detail(scene)
	return {
		"hidden_count": hidden_count,
		"max_entry_height": max_entry_height,
		"max_root_height": max_root_height,
		"max_scroll": 0 if scroll == null else int(scroll.call("get_max_scroll_vertical")),
		"content_count": int(visible_content.get("count", 0)),
		"sample_detail": sample_detail,
		"stack_detail": stack_detail
	}


func _stack_detail(scene: Node) -> String:
	var detail_surface = scene.call("_skill_detail_surface")
	var stack := detail_surface.call("_detail_actions_stack") as Control
	if stack == null:
		return "no-stack"
	var parts: Array[String] = []
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null:
			continue
		parts.append("%s vis=%s meta=%s min=%.1f size=%.1f mod=%.2f module=%s bottom=%.1f" % [
			child.name,
			str(child.visible),
			str(child.get_meta("detail_stack_entry_wrapper", false)),
			child.custom_minimum_size.y,
			child.size.y,
			child.modulate.a,
			str(detail_surface.call("_detail_stack_child_is_module_content", child)),
			float(detail_surface.call("_detail_control_bottom_in_stack", child, stack))
		])
	return " | ".join(parts)


func _control_height(control: Control) -> float:
	if control == null or not is_instance_valid(control):
		return 0.0
	return maxf(control.custom_minimum_size.y, control.size.y)


func _allocated_control_height(control: Control) -> float:
	if control == null or not is_instance_valid(control) or not control.visible:
		return 0.0
	return _control_height(control)


func _current_page_stats(scene: Node) -> Dictionary:
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	var stack = scene.call("_skill_detail_surface").call("_detail_actions_stack")
	var visible_stats := scene.call("_skill_swipe_activity_surface").call("_skill_detail_visible_module_stats") as Dictionary
	return {
		"stack_present": stack != null and is_instance_valid(stack),
		"visible_modules": int(visible_stats.get("visible_modules", 0)),
		"visible_module_area": float(visible_stats.get("visible_module_area", 0.0)),
		"max_scroll": 0 if scroll == null else int(scroll.call("get_max_scroll_vertical")),
		"ready": bool(scene.call("_skill_swipe_activity_surface").call("_skill_detail_ready_to_reveal_under_cover")),
		"visible_placeholders": bool(scene.call("_skill_swipe_activity_surface").call("_skill_detail_has_visible_lazy_placeholders")),
		"placeholder_detail": _placeholder_summary(scene)
	}


func _placeholder_summary(scene: Node) -> String:
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	var stack = scene.call("_skill_detail_surface").call("_detail_actions_stack")
	if scroll == null or stack == null or not is_instance_valid(stack):
		return ""
	var viewport_rect := scroll.get_global_rect()
	for raw_child in stack.get_children():
		var child := _valid_control(raw_child)
		if child == null or child.name in ["DetailActionsTopSpacer", "DetailActionsBottomSpacer"]:
			continue
		if not child.visible or not child.is_visible_in_tree():
			continue
		var rect := child.get_global_rect()
		if rect.size.y <= 1.0 or not rect.intersects(viewport_rect):
			continue
		if not _control_tree_has_placeholder(child):
			continue
		return "slot=%s min=%.1f size=%.1f alpha=%.2f real=%s rect=%s children=%s" % [
			child.name,
			child.custom_minimum_size.y,
			child.size.y,
			child.modulate.a,
			str(_slot_has_real_content(child)),
			str(rect),
			str(child.get_child_count())
		]
	return ""


func _control_tree_has_placeholder(control: Control) -> bool:
	if bool(control.get_meta("detail_lazy_placeholder", false)):
		return true
	for raw_child in control.get_children():
		var child := _valid_control(raw_child)
		if child != null and _control_tree_has_placeholder(child):
			return true
	return false


func _slot_has_real_content(control: Control) -> bool:
	for raw_child in control.get_children():
		var child := _valid_control(raw_child)
		if child == null:
			continue
		if bool(child.get_meta("detail_lazy_placeholder", false)):
			continue
		if child.visible and child.modulate.a > 0.01 and maxf(child.custom_minimum_size.y, child.size.y) > 1.0:
			return true
	return false


func _swipe_cover_alpha(scene: Node) -> float:
	var cover := _valid_control(scene.get("skill_swipe_handoff_cover"))
	if cover == null or not cover.visible:
		return 0.0
	return cover.modulate.a


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


func _fail(message: String) -> void:
	failed = true
	push_error("skill-detail-hidden-preview-scroll-gap-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-NoUnexpectedGodotErrors $output "skill detail hidden preview scroll-gap validation"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after skill detail hidden preview scroll-gap validation."
    }
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    }
    else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
}
