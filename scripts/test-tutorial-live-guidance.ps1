param(
    [switch]$Capture
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\tutorial-live-guidance"
$testScript = Join-Path $testDir "tutorial_live_guidance_test.gd"
$captureDir = Join-Path $projectRoot ".codex-tmp\tutorial-live-guidance-captures"

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
        if ($text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.') {
            continue
        }
        throw "Unexpected Godot error during ${Context}: $text"
    }
}

if (-not (Test-Path -LiteralPath $runner)) {
    throw "Missing run-godot-safe.ps1."
}
if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null
if ($Capture) {
    if (Test-Path -LiteralPath $captureDir) {
        Remove-Item -LiteralPath $captureDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
}

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapture = $env:IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE
$previousCaptureDir = $env:IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE_DIR
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"
$env:IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE = if ($Capture) { "1" } else { "0" }
$env:IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE_DIR = $captureDir

try {
    @'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")
const CAPTURE_SIZE := Vector2i(1080, 1920)
const DESIGN_SIZE := Vector2i(2160, 3840)

var scene: Node
var capture_dir := ""
var capture_enabled := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("tutorial-live-guidance-start")
	var capture := OS.get_environment("IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE") == "1"
	capture_enabled = capture
	if capture:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		root.content_scale_size = DESIGN_SIZE
		root.size = CAPTURE_SIZE
		DisplayServer.window_set_size(CAPTURE_SIZE)
		capture_dir = OS.get_environment("IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE_DIR")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	scene = packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready():
		_fail("boot did not become ready")
		return

	scene.call("_save_runtime").call("reset_data")
	var reset_onboarding := scene.call("_onboarding_runtime") as Object
	reset_onboarding.lock_click_tip_seen = true
	reset_onboarding.silver_opportunity_tip_seen = true
	reset_onboarding.passive_module_tip_seen = true
	var reset_overlay := scene.call("_tutorial_overlay_surface") as Object
	reset_overlay.call("_dismiss_blocking_tip")
	reset_overlay.blocking_tip_shown_groups.clear()
	for _i in range(120):
		await process_frame
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
	if not await _wait_for_starter_card_ready():
		_fail("starter state did not become ready: %s" % _summary())
		return
	_assert_guidance("starter", "Tap Push-Ups to start training.")
	if capture:
		await _capture("starter")
	scene.call("_tutorial_overlay_surface").call("_play_tutorial_arrow_success_exit")
	for _i in range(4):
		await process_frame
	var starter_arrow := scene.call("_tutorial_overlay_surface").tutorial_arrow as Control
	if starter_arrow != null and starter_arrow.is_visible_in_tree():
		_fail("starter arrow stayed visible after Push-Ups started")
		return
	if capture:
		scene.call("_onboarding_runtime").call("_complete_tutorial_target_intro")
		await _render_skill("fight")
		await _capture("starter-after-click")

	if not await _prepare_lock_state():
		_fail("lock state did not become ready: %s" % _summary())
		return
	_assert_guidance("lock", "Tap the lock to unlock.")
	if capture:
		await _capture("first-unlock")
	if not _tap_overlay_target(true) or not _lock_outside_release_cancelled():
		_fail("lock outside release was not cancelled cleanly")
		return
	if not _tap_overlay_target():
		_fail("lock first intended tap was not routed")
		return
	for _i in range(120):
		await process_frame
	if not bool(scene._onboarding_runtime().lock_click_tip_seen):
		_fail("lock first tap did not preserve the existing lock completion flag")
		return
	var unlocked_action := scene.call("_action_data", "fight", "kick-mud-off-boot") as Dictionary
	if not bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", unlocked_action)):
		_fail("lock first tap did not unlock fight:kick-mud-off-boot")
		return

	if not await _prepare_silver_state():
		_fail("silver state did not become ready: %s" % _summary())
		return
	_assert_guidance("silver", "Tap the boost zone at the right moment.")
	if capture:
		await _capture("silver-opportunity")
	var progress_before_click := float(scene.get("action_progress"))
	if not _tap_overlay_target():
		_fail("silver first intended tap was not routed")
		return
	for _i in range(30):
		await process_frame
	if not bool(scene._onboarding_runtime().silver_opportunity_tip_seen):
		_fail("silver first tap did not preserve the existing completion flag")
		return
	var action_runtime := scene.call("_action_runtime") as Object
	if not bool(action_runtime.action_opportunity_consumed) or float(action_runtime.action_opportunity_boost_seconds) <= 0.0 or float(scene.get("action_progress")) <= progress_before_click:
		_fail("silver first tap did not apply the real opportunity result")
		return

	if not await _prepare_firepit_state():
		_fail("Firepit state did not become ready: %s" % _summary())
		return
	_assert_guidance("firepit", "Tap Firepit to start.")
	if capture:
		await _capture("firepit")
	var regression_runtime := scene.call("_passive_modules_runtime") as Object
	if not bool(regression_runtime.call("start_firepit", scene.call("_unix_now"))):
		_fail("Firepit regression setup could not start the real Firepit")
		return
	for _i in range(2):
		await process_frame
	if not _press_overlay_target():
		_fail("Firepit press did not start the captured hold")
		return
	var firepit_overlay := scene.call("_tutorial_overlay_surface") as Object
	var passive_surface := scene.call("_passive_firepit_surface") as Object
	if not bool(firepit_overlay.blocking_tip_pointer_capture_active) or not bool(passive_surface.firepit_stop_hold_active) or bool(passive_surface.firepit_stop_hold_unloading):
		_fail("Firepit press did not arm the captured hold precondition")
		return
	firepit_overlay.call("_dismiss_blocking_tip")
	await process_frame
	var dismissed_firepit_state := scene.call("_passive_modules_runtime").call("firepit_state", scene.call("_unix_now")) as Dictionary
	if bool(firepit_overlay.blocking_tip_pointer_capture_active) or bool(passive_surface.firepit_stop_hold_active) or bool(passive_surface.firepit_stop_hold_unloading) or not bool(dismissed_firepit_state.get("active", false)) or bool(dismissed_firepit_state.get("igniting", false)) or bool(scene.call("_onboarding_runtime").passive_module_tip_seen):
		_fail("Firepit programmatic dismissal did not cancel the captured hold")
		return
	regression_runtime.call("extinguish_firepit", scene.call("_unix_now"))
	var cleaned_firepit_state := scene.call("_passive_modules_runtime").call("firepit_state", scene.call("_unix_now")) as Dictionary
	if bool(cleaned_firepit_state.get("active", false)) or bool(cleaned_firepit_state.get("igniting", false)):
		_fail("Firepit regression cleanup did not stop the real Firepit")
		return
	var firepit_card := scene.action_cards.get("woodcutting:firepit", {}) as Dictionary
	var firepit_target := firepit_card.get("toggle") as Control
	if firepit_target == null or not is_instance_valid(firepit_target) or not firepit_target.is_visible_in_tree():
		_fail("Firepit target disappeared after programmatic dismissal")
		return
	firepit_overlay.blocking_tip_shown_groups.erase("passive_module_tip_notes")
	firepit_overlay.call("show_blocking_tip", "Tap Firepit to start.", "passive_module_tip_notes")
	_add_test_tip_note("passive_module_tip_notes")
	await _settle_overlay()
	if _overlay_group() != "passive_module_tip_notes" or firepit_overlay.call("_tutorial_target_control") != firepit_target:
		_fail("Firepit re-show did not rediscover the real default target")
		return
	if not _tap_overlay_target(true) or not _firepit_outside_release_cancelled():
		_fail("Firepit outside release was not cancelled cleanly")
		return
	if not _tap_overlay_target():
		_fail("Firepit first intended tap was not routed")
		return
	for _i in range(30):
		await process_frame
	if not bool(scene._onboarding_runtime().passive_module_tip_seen):
		_fail("Firepit first tap did not preserve the existing completion flag")
		return
	var firepit_state := scene.call("_passive_modules_runtime").call("firepit_state", scene.call("_unix_now")) as Dictionary
	if not bool(firepit_state.get("active", false)) and not bool(firepit_state.get("igniting", false)):
		_fail("Firepit first tap did not start the real Firepit state")
		return

	print("tutorial-live-guidance-ok %s" % _summary())
	quit(0)


func _prepare_base_state() -> void:
	scene.set_process(true)
	var onboarding := scene.call("_onboarding_runtime") as Object
	onboarding.tutorial_active = false
	onboarding.onboarding_tutorial_complete = true
	onboarding.activity_start_tip_seen = true
	onboarding.stamina_gauge_tip_seen = true
	onboarding.lock_click_tip_seen = true
	onboarding.silver_opportunity_tip_seen = true
	onboarding.silver_opportunity_tip_action_key = ""
	onboarding.passive_module_tip_seen = true
	var overlay := scene.call("_tutorial_overlay_surface") as Object
	overlay.call("_dismiss_blocking_tip")
	overlay.blocking_tip_shown_groups.clear()
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)


func _prepare_lock_state() -> bool:
	_prepare_base_state()
	var onboarding := scene.call("_onboarding_runtime") as Object
	# Keep the live tip suppressed until the real level-2 lock card is mounted.
	onboarding.lock_click_tip_seen = true
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fight")
	var skills := scene.get("skills") as Dictionary
	var fight := skills.get("fight", {}) as Dictionary
	fight["xp"] = SkillState.xp_for_level(2) + 1
	skills["fight"] = fight
	scene.set("skills", skills)
	SkillState.recalculate_level(scene, "fight", false)
	await _render_skill("fight")
	var action := scene.call("_action_data", "fight", "kick-mud-off-boot") as Dictionary
	var lock_card := scene.action_cards.get("fight:kick-mud-off-boot", {}) as Dictionary
	var target := (lock_card.get("lock_overlay", {}) as Dictionary).get("group") as Control
	if action.is_empty() or target == null or not is_instance_valid(target) or not target.is_visible_in_tree() or bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", action)):
		return false
	var padlock := scene.call("_tutorial_overlay_surface").call("_blocking_tip_padlock", target) as Control
	if padlock == null or not is_instance_valid(padlock) or not padlock.is_visible_in_tree():
		return false
	onboarding.lock_click_tip_seen = false
	var overlay := scene.call("_tutorial_overlay_surface") as Object
	overlay.blocking_tip_shown_groups.erase("lock_click_tip_notes")
	overlay.call("show_blocking_tip", "Tap the lock to unlock.", "lock_click_tip_notes")
	_add_test_tip_note("lock_click_tip_notes")
	return _overlay_group() == "lock_click_tip_notes" and scene.call("_tutorial_overlay_surface").call("_tutorial_target_control") == target


func _prepare_silver_state() -> bool:
	_prepare_base_state()
	var onboarding := scene.call("_onboarding_runtime") as Object
	onboarding.silver_opportunity_tip_seen = true
	onboarding.silver_opportunity_tip_action_key = "fight:push-ups"
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fight")
	var skills := scene.get("skills") as Dictionary
	var fight := skills.get("fight", {}) as Dictionary
	fight["xp"] = SkillState.xp_for_level(7)
	skills["fight"] = fight
	scene.set("skills", skills)
	SkillState.recalculate_level(scene, "fight", false)
	var mastery := scene.get("mastery") as Dictionary
	mastery["fight:push-ups"] = {"level": 2, "xp": 100}
	scene.set("mastery", mastery)
	await _render_skill("fight")
	var start_ok: bool = scene.call("_action_runtime").call("_start_action", "fight", "push-ups", true, false)
	if not start_ok:
		return false
	var windows := scene.call("_action_runtime").call("_action_opportunity_pattern_windows", "fight", "push-ups") as Array
	if windows.is_empty():
		return false
	var first_window := windows[0] as Vector2
	scene.set("action_progress", (first_window.x + first_window.y) * 0.5)
	scene.call("_update_ui", 0.0, true)
	var card := scene.action_cards.get("fight:push-ups", {}) as Dictionary
	var progress := card.get("progress") as Control
	if progress == null or not is_instance_valid(progress) or not progress.is_visible_in_tree():
		return false
	scene.set_process(false)
	onboarding.silver_opportunity_tip_seen = false
	var silver_overlay := scene.call("_tutorial_overlay_surface") as Object
	silver_overlay.blocking_tip_shown_groups.erase("silver_opportunity_tip_notes")
	silver_overlay.call("show_blocking_tip", "Tap the boost zone at the right moment.", "silver_opportunity_tip_notes")
	_add_test_tip_note("silver_opportunity_tip_notes")
	if silver_overlay.call("_tutorial_target_control") != progress:
		return false
	await _settle_overlay()
	var ready := _overlay_group() == "silver_opportunity_tip_notes" and not windows.is_empty() and float(progress.get("opportunity_target_alpha")) > 0.5 and float(progress.get("opportunity_alpha")) > 0.5 and float(progress.get("opportunity_unavailable_target_alpha")) < 0.5 and bool(progress.call("has_opportunity_progress", float(scene.get("action_progress"))))
	var opportunity_overlay := progress.get("opportunity_overlay") as Control
	ready = ready and opportunity_overlay != null and is_instance_valid(opportunity_overlay) and opportunity_overlay.is_visible_in_tree()
	return ready


func _prepare_firepit_state() -> bool:
	_prepare_base_state()
	var onboarding := scene.call("_onboarding_runtime") as Object
	onboarding.passive_module_tip_seen = true
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "woodcutting")
	var skills := scene.get("skills") as Dictionary
	var woodcutting := skills.get("woodcutting", {}) as Dictionary
	woodcutting["level"] = 2
	woodcutting["xp"] = SkillState.xp_for_level(2)
	skills["woodcutting"] = woodcutting
	scene.set("skills", skills)
	await _render_skill("woodcutting")
	scene.call("_test_state_runtime").call("_god_mode_max_skills_state")
	scene.call("_test_state_runtime").call("_god_mode_unlock_actions_state")
	var refresh = scene.call("_skill_detail_surface").call("_refresh_visible_skill_detail_action_list", -1, "woodcutting", true)
	if refresh != null:
		await refresh
	for _refresh_frame in range(30):
		await process_frame
	var card := scene.action_cards.get("woodcutting:firepit", {}) as Dictionary
	var target := card.get("toggle") as Control
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	scene.material_runtime.set_amount("scrapwood", 6.0)
	onboarding.passive_module_tip_seen = false
	var firepit_overlay := scene.call("_tutorial_overlay_surface") as Object
	firepit_overlay.blocking_tip_shown_groups.erase("passive_module_tip_notes")
	firepit_overlay.call("show_blocking_tip", "Tap Firepit to start.", "passive_module_tip_notes")
	_add_test_tip_note("passive_module_tip_notes")
	await _settle_overlay()
	return _overlay_group() == "passive_module_tip_notes" and firepit_overlay.call("_tutorial_target_control") == target


func _add_test_tip_note(group_name: String) -> void:
	var note := Control.new()
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_to_group(group_name)
	scene.add_child(note)


func _render_skill(skill_id: String) -> void:
	scene.call("_navigation_shell").last_rendered_screen_key = ""
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(60):
		scene.call("_skill_detail_surface").call("_sync_detail_lazy_visible_cards", true, -1)
		scene.call("_update_ui", 0.0, true)
		await process_frame


func _settle_overlay() -> void:
	for _i in range(20):
		await process_frame


func _tutorial_starter_ready() -> bool:
	var onboarding := scene.call("_onboarding_runtime") as Object
	var overlay := scene.call("_tutorial_overlay_surface") as Object
	var target := overlay.call("_tutorial_target_control") as Control
	return bool(onboarding.tutorial_active) and target != null and is_instance_valid(target) and target.is_visible_in_tree()


func _starter_card_ready() -> bool:
	var card := scene.action_cards.get("fight:push-ups", {}) as Dictionary
	var pop := card.get("pop") as Control
	var bg := card.get("bg") as Control
	var art := card.get("art") as TextureRect
	var art_panel := card.get("art_panel") as Control
	var title := card.get("title") as Label
	if pop == null or bg == null or art == null or art_panel == null or title == null:
		return false
	if not is_instance_valid(pop) or not is_instance_valid(bg) or not is_instance_valid(art) or not is_instance_valid(art_panel) or not is_instance_valid(title):
		return false
	if not pop.is_visible_in_tree() or not bg.is_visible_in_tree() or not art_panel.is_visible_in_tree() or not title.is_visible_in_tree():
		return false
	if pop.size.x < 1000.0 or pop.size.y < 500.0 or bg.size.x < 1000.0 or art.size.x < 200.0:
		return false
	if title.text.strip_edges().is_empty() or title.modulate.a <= 0.05 or title.self_modulate.a <= 0.05:
		return false
	if bg.get("texture") == null or art.get("texture") == null:
		return false
	return true


func _wait_for_starter_card_ready() -> bool:
	for _i in range(240):
		await process_frame
		if capture_enabled:
			await RenderingServer.frame_post_draw
		if _tutorial_starter_ready() and _starter_card_ready():
			for _settle in range(8):
				await process_frame
				if capture_enabled:
					await RenderingServer.frame_post_draw
			return _tutorial_starter_ready() and _starter_card_ready()
	return false


func _overlay_group() -> String:
	return str(scene.call("_tutorial_overlay_surface").blocking_tip_group)


func _tap_overlay_target(release_outside := false) -> bool:
	if not _press_overlay_target():
		return false
	var overlay := scene.call("_tutorial_overlay_surface") as Object
	var target := overlay.call("_tutorial_target_control") as Control
	var position := target.get_global_rect().get_center()
	if _overlay_group() == "lock_click_tip_notes":
		var padlock := overlay.call("_blocking_tip_padlock", target) as Control
		if padlock != null and is_instance_valid(padlock):
			position = padlock.get_global_rect().get_center()
	if _overlay_group() == "silver_opportunity_tip_notes":
		var windows := overlay.call("_blocking_tip_target_rect", target) as Rect2
		position = windows.get_center()
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	var release_position := Vector2(24.0, 24.0) if release_outside else position
	release.position = release_position
	release.global_position = release_position
	return bool(overlay.call("_route_tutorial_panel_input", release))


func _press_overlay_target() -> bool:
	var overlay := scene.call("_tutorial_overlay_surface") as Object
	var target := overlay.call("_tutorial_target_control") as Control
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	var position := target.get_global_rect().get_center()
	if _overlay_group() == "lock_click_tip_notes":
		var padlock := overlay.call("_blocking_tip_padlock", target) as Control
		if padlock != null and is_instance_valid(padlock):
			position = padlock.get_global_rect().get_center()
	if _overlay_group() == "silver_opportunity_tip_notes":
		var windows := overlay.call("_blocking_tip_target_rect", target) as Rect2
		position = windows.get_center()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	return bool(overlay.call("_route_tutorial_panel_input", press))


func _lock_outside_release_cancelled() -> bool:
	var overlay := scene.call("_tutorial_overlay_surface") as Object
	var action := scene.call("_action_data", "fight", "kick-mud-off-boot") as Dictionary
	var target := overlay.call("_tutorial_target_control") as Control
	var cluster_active_rig = target.get("active_rig") if target != null else null
	var rigs_variant = target.get("rigs") if target != null else null
	if typeof(rigs_variant) != TYPE_ARRAY:
		return false
	for raw_rig in rigs_variant:
		var rig := raw_rig as Object
		if rig == null or not is_instance_valid(rig) or bool(rig.get("pressing_lock")) or bool(rig.get("dragging_lock")):
			return false
	return bool(overlay.blocking_tip_active) and not bool(scene.call("_onboarding_runtime").lock_click_tip_seen) and not bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", action)) and not bool(overlay.blocking_tip_pointer_capture_active) and cluster_active_rig == null


func _firepit_outside_release_cancelled() -> bool:
	var overlay := scene.call("_tutorial_overlay_surface") as Object
	var passive_surface := scene.call("_passive_firepit_surface") as Object
	var firepit_state := scene.call("_passive_modules_runtime").call("firepit_state", scene.call("_unix_now")) as Dictionary
	return bool(overlay.blocking_tip_active) and not bool(scene.call("_onboarding_runtime").passive_module_tip_seen) and not bool(firepit_state.get("active", false)) and not bool(firepit_state.get("igniting", false)) and not bool(passive_surface.firepit_stop_hold_active) and not bool(passive_surface.firepit_stop_hold_unloading) and not bool(overlay.blocking_tip_pointer_capture_active)


func _assert_guidance(label: String, expected_text: String) -> void:
	var overlay := scene.call("_tutorial_overlay_surface") as Object
	overlay.call("_sync_tutorial_arrow")
	var target := overlay.call("_tutorial_target_control") as Control
	var arrow := overlay.tutorial_arrow as TextureRect
	var instruction := overlay.tutorial_instruction_label as Label
	if target == null or not is_instance_valid(target) or not target.is_visible_in_tree():
		_fail("%s target is not visible" % label)
		return
	if label == "firepit":
		if arrow == null or arrow.is_visible_in_tree() or instruction == null or instruction.is_visible_in_tree():
			_fail("firepit guidance should have no arrow or copy")
			return
		return
	if arrow == null or not arrow.is_visible_in_tree():
		_fail("%s arrow is not visible" % label)
		return
	if arrow.size.distance_to(Vector2(260, 420)) > 1.0:
		_fail("%s arrow is not phone-sized: %s" % [label, str(arrow.size)])
		return
	if label == "starter" and not _starter_card_ready():
		_fail("starter target card is not fully rendered")
		return
	var target_rect := overlay.call("_blocking_tip_target_rect", target) as Rect2
	var expected_tip := target_rect.position + target_rect.size * Vector2(0.50, -0.07)
	if _overlay_group() == "lock_click_tip_notes":
		var padlock := overlay.call("_blocking_tip_padlock", target) as Control
		if padlock == null or not is_instance_valid(padlock):
			var child_names := []
			for child in target.get_children():
				child_names.append("%s:%s" % [child.name, child.get_class()])
			var level := SkillState.host_skill_level(scene, "fight")
			var kick := scene.call("_action_data", "fight", "kick-mud-off-boot") as Dictionary
			var can_unlock: bool = bool(scene.call("_activity_unlock_runtime").call("_can_unlock_action", "fight", kick)) if not kick.is_empty() else false
			var is_unlocked: bool = bool(scene.call("_activity_unlock_runtime").call("_is_action_unlocked", "fight", kick)) if not kick.is_empty() else false
			_fail("lock target has no padlock class=%s children=%s names=%s active=%s level=%s can=%s unlocked=%s" % [target.get_class(), str(target.get_children().size()), str(child_names), str(target.get("active_rig")), str(level), str(can_unlock), str(is_unlocked)])
			return
		var lock_rect := padlock.get_global_rect()
		expected_tip = Vector2(lock_rect.get_center().x, lock_rect.position.y)
		target_rect = lock_rect
	var blocking_tip := label != "starter"
	var tip_offset := Vector2(0.47, 0.0) if arrow.flip_v and blocking_tip else (Vector2(0.47, 0.02) if arrow.flip_v else (Vector2(0.47, 1.0) if blocking_tip else Vector2(0.47, 0.98)))
	var actual_tip := arrow.get_global_transform() * (arrow.size * tip_offset)
	if actual_tip.distance_to(expected_tip) > 15.0:
		_fail("%s arrow misses target: actual=%s expected=%s" % [label, str(actual_tip), str(expected_tip)])
		return
	var viewport := scene.get_viewport().get_visible_rect()
	var bounds := arrow.get_global_transform() * Rect2(Vector2.ZERO, arrow.size)
	if bounds.position.x < viewport.position.x - 1.0 or bounds.position.y < viewport.position.y - 1.0 or bounds.end.x > viewport.end.x + 1.0 or bounds.end.y > viewport.end.y + 1.0:
		_fail("%s arrow spills outside viewport: %s" % [label, str(bounds)])
		return
	if bounds.intersects(target_rect):
		_fail("%s arrow obscures target: arrow=%s target=%s" % [label, str(bounds), str(target_rect)])
		return
	if label == "starter":
		if instruction == null or not instruction.is_visible_in_tree() or instruction.text != expected_text:
			_fail("%s copy is wrong or hidden: text=%s" % [label, "null" if instruction == null else instruction.text])
			return
		if instruction.get_global_rect().intersects(target_rect):
			_fail("%s copy obscures target" % label)
			return
	elif instruction != null and instruction.is_visible_in_tree():
		_fail("%s should not show tutorial copy" % label)
		return
	if label == "silver":
		var windows := target.get("opportunity_windows") as Array
		var rail_rect := target.get_global_rect()
		var first_window := windows[0] as Vector2 if not windows.is_empty() else Vector2(-1.0, -1.0)
		var expected_window_rect := Rect2(Vector2(rail_rect.position.x + rail_rect.size.x * first_window.x, rail_rect.position.y - 18.0), Vector2(rail_rect.size.x * (first_window.y - first_window.x), rail_rect.size.y + 36.0))
		if windows.is_empty() or target_rect.position.distance_to(expected_window_rect.position) > 1.0 or target_rect.size.distance_to(expected_window_rect.size) > 1.0:
			_fail("silver arrow target does not equal first opportunity window")
			return
		if float(target.get("opportunity_alpha")) <= 0.5 or float(target.get("opportunity_target_alpha")) <= 0.5 or float(target.get("opportunity_unavailable_target_alpha")) > 0.5:
			_fail("silver opportunity marker is not visible and available")
			return
		if not bool(target.call("has_opportunity_progress", float(scene.get("action_progress")))):
			_fail("silver progress is not inside the visible first opportunity window")
			return
	for raw_card in scene.action_cards.values():
		var card := raw_card as Dictionary
		var card_control := card.get("pop") as Control
		if card_control == null or not is_instance_valid(card_control) or not card_control.is_visible_in_tree():
			continue
		if instruction != null and instruction.is_visible_in_tree() and instruction.get_global_rect().intersects(card_control.get_global_rect()):
			_fail("%s copy obscures visible action card" % label)
			return


func _capture(label: String) -> void:
	if label == "starter" and not await _wait_for_starter_card_ready():
		_fail("starter capture target card is not fully rendered")
		return
	for _settle in range(8):
		await process_frame
		if capture_enabled:
			await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	if texture == null:
		_fail("%s capture has no viewport texture" % label)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("%s capture has no image" % label)
		return
	if image.get_width() != CAPTURE_SIZE.x:
		_fail("%s capture width is %s, expected %s" % [label, str(image.get_width()), str(CAPTURE_SIZE.x)])
		return
	var path := "%s/%s.png" % [capture_dir, label]
	var result := image.save_png(path)
	print("tutorial-live-guidance-capture path=%s result=%s size=%sx%s" % [path, str(result), str(image.get_width()), str(image.get_height())])
	if result != OK:
		_fail("%s capture save failed" % label)


func _wait_for_boot_ready() -> bool:
	for _i in range(720):
		await process_frame
		if bool(scene.get("startup_initialized")) and not bool(scene.get("boot_detail_render_in_progress")) and not bool(scene.get("boot_detail_scroll_locked")):
			var queue := scene.get("boot_detail_render_queue") as Array
			if queue == null or queue.is_empty():
				for _settle in range(30):
					await process_frame
				return true
	return false


func _summary() -> String:
	var onboarding := scene.call("_onboarding_runtime") as Object
	return "screen=%s selected=%s tutorial=%s lock=%s silver=%s passive=%s group=%s" % [
		str(scene.get("current_screen")), str(scene.get("selected_skill_id")), str(onboarding.tutorial_active),
		str(onboarding.lock_click_tip_seen), str(onboarding.silver_opportunity_tip_seen), str(onboarding.passive_module_tip_seen), _overlay_group()
	]


func _fail(message: String) -> void:
	push_error("tutorial-live-guidance-fail: %s" % message)
	print("tutorial-live-guidance-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $modeArg = if ($Capture) { "--visible-game" } else { "--headless" }
    $output = & $runner $modeArg --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    Assert-NoUnexpectedGodotErrors $output "tutorial live guidance test"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
	if ($Capture) {
		foreach ($name in @("starter", "starter-after-click", "first-unlock", "silver-opportunity", "firepit")) {
            $path = Join-Path $captureDir "$name.png"
            if (-not (Test-Path -LiteralPath $path)) {
                throw "Missing real-game capture: $path"
            }
            Write-Host "tutorial-live-guidance-capture-file=$path"
        }
    } else {
        Assert-True (($output -join "`n") -match "tutorial-live-guidance-ok") "Tutorial live guidance test did not report success."
    }
    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the tutorial live guidance test."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCapture) {
        Remove-Item Env:\IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE = $previousCapture
    }
    if ($null -eq $previousCaptureDir) {
        Remove-Item Env:\IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE_DIR -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TUTORIAL_LIVE_GUIDANCE_CAPTURE_DIR = $previousCaptureDir
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
