param(
    [switch]$Locked,
    [switch]$Inactive,
    [switch]$Header,
    [switch]$XpPopup,
    [switch]$Ignition,
    [switch]$Cooling,
    [switch]$NeedScrapwood,
    [switch]$EmptyStamina,
    [switch]$DarkMode,
    [int]$ViewportWidth = 0,
    [int]$ViewportHeight = 0,
    [int]$WindowWidth = 0,
    [int]$WindowHeight = 0
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$captureDir = Join-Path $projectRoot ".codex-tmp\woodcutting-firepit"
$desktopSuffix = if ($WindowWidth -gt 0 -and $WindowHeight -gt 0) { "-desktop-${WindowWidth}x${WindowHeight}" } else { "" }
$darkModeSuffix = if ($DarkMode) { "-dark" } else { "" }
$captureFileName = if ($NeedScrapwood) { "woodcutting-firepit-need-scrapwood$desktopSuffix$darkModeSuffix.png" } elseif ($Cooling) { "woodcutting-firepit-cooling$desktopSuffix$darkModeSuffix.png" } elseif ($Ignition) { "woodcutting-firepit-ignition$desktopSuffix$darkModeSuffix.png" } elseif ($XpPopup) { "woodcutting-firepit-xp-popup$desktopSuffix$darkModeSuffix.png" } elseif ($Header -and $EmptyStamina) { "woodcutting-firepit-header-empty-stamina$desktopSuffix$darkModeSuffix.png" } elseif ($Header) { "woodcutting-firepit-header$desktopSuffix$darkModeSuffix.png" } elseif ($Locked) { "woodcutting-firepit-card-locked$desktopSuffix$darkModeSuffix.png" } elseif ($Inactive) { "woodcutting-firepit-card-inactive$desktopSuffix$darkModeSuffix.png" } else { "woodcutting-firepit-card$desktopSuffix$darkModeSuffix.png" }
$capturePath = Join-Path $captureDir $captureFileName
$scriptPath = Join-Path $captureDir "capture_woodcutting_firepit.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $capturePath) {
    Remove-Item -LiteralPath $capturePath -Force
}
New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
$legacyVerificationPath = Join-Path $captureDir "woodcutting-firepit-card-verification.png"
if (Test-Path -LiteralPath $legacyVerificationPath) {
    Remove-Item -LiteralPath $legacyVerificationPath -Force
}

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_FIREPIT_CAPTURE_PATH
$previousCaptureLocked = $env:IDLE_ELITE_FIREPIT_CAPTURE_LOCKED
$previousCaptureInactive = $env:IDLE_ELITE_FIREPIT_CAPTURE_INACTIVE
$previousCaptureHeader = $env:IDLE_ELITE_FIREPIT_CAPTURE_HEADER
$previousCaptureXpPopup = $env:IDLE_ELITE_FIREPIT_CAPTURE_XP_POPUP
$previousCaptureIgnition = $env:IDLE_ELITE_FIREPIT_CAPTURE_IGNITION
$previousCaptureCooling = $env:IDLE_ELITE_FIREPIT_CAPTURE_COOLING
$previousCaptureNeedScrapwood = $env:IDLE_ELITE_FIREPIT_CAPTURE_NEED_SCRAPWOOD
$previousCaptureEmptyStamina = $env:IDLE_ELITE_FIREPIT_CAPTURE_EMPTY_STAMINA
$previousCaptureDarkMode = $env:IDLE_ELITE_FIREPIT_CAPTURE_DARK_MODE
$previousCaptureViewportWidth = $env:IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_WIDTH
$previousCaptureViewportHeight = $env:IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_HEIGHT
$previousCaptureWindowWidth = $env:IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_WIDTH
$previousCaptureWindowHeight = $env:IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_HEIGHT
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"
$env:IDLE_ELITE_FIREPIT_CAPTURE_PATH = $capturePath
$env:IDLE_ELITE_FIREPIT_CAPTURE_LOCKED = if ($Locked) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_INACTIVE = if ($Inactive -and -not $Locked) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_HEADER = if ($Header) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_XP_POPUP = if ($XpPopup -and -not $Locked -and -not $Inactive) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_IGNITION = if ($Ignition -and -not $Locked -and -not $Inactive) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_COOLING = if ($Cooling -and -not $Locked) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_NEED_SCRAPWOOD = if ($NeedScrapwood -and -not $Locked) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_EMPTY_STAMINA = if ($EmptyStamina) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_DARK_MODE = if ($DarkMode) { "1" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_WIDTH = if ($ViewportWidth -gt 0) { "$ViewportWidth" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_HEIGHT = if ($ViewportHeight -gt 0) { "$ViewportHeight" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_WIDTH = if ($WindowWidth -gt 0) { "$WindowWidth" } else { "0" }
$env:IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_HEIGHT = if ($WindowHeight -gt 0) { "$WindowHeight" } else { "0" }

try {
    @'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var capture_header := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_HEADER") == "1"
	var default_capture_size := Vector2i(1600, 2600) if capture_header else Vector2i(1080, 2600)
	var viewport_width := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_WIDTH").to_int()
	var viewport_height := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_HEIGHT").to_int()
	var window_width := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_WIDTH").to_int()
	var window_height := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_HEIGHT").to_int()
	var capture_size := Vector2i(viewport_width, viewport_height) if viewport_width > 0 and viewport_height > 0 else default_capture_size
	var window_size := Vector2i(window_width, window_height) if window_width > 0 and window_height > 0 else capture_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = capture_size
	root.size = window_size
	DisplayServer.window_set_size(window_size)
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		_fail("main scene did not become capture-ready")
		return
	if OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_DARK_MODE") == "1":
		scene.set("dark_mode_enabled", true)
		scene.call("_settings_surface").call("apply_dark_mode_visual")
	if scene.has_method("_test_state_runtime"):
		scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	var capture_locked := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_LOCKED") == "1"
	var capture_inactive := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_INACTIVE") == "1"
	var capture_xp_popup := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_XP_POPUP") == "1"
	var capture_ignition := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_IGNITION") == "1"
	var capture_cooling := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_COOLING") == "1"
	var capture_need_scrapwood := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_NEED_SCRAPWOOD") == "1"
	var capture_empty_stamina := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_EMPTY_STAMINA") == "1"
	if (not capture_locked) and scene.has_method("_test_state_runtime"):
		scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	var woodcutting := scene.skills["woodcutting"] as Dictionary
	woodcutting["level"] = 1 if capture_locked else maxi(2, int(woodcutting.get("level", 1)))
	if not capture_locked:
		woodcutting["xp"] = maxi(int(woodcutting.get("xp", 0)), SkillState.xp_for_level(2))
	scene.skills["woodcutting"] = woodcutting
	if capture_locked:
		scene.material_runtime.set_amount("scrapwood", 0.1)
	else:
		scene.call("_activity_unlock_runtime").call("_mark_action_manually_unlocked", "woodcutting", "woodcutting-firepit")
		scene.material_runtime.set_amount("scrapwood", 0.0 if capture_need_scrapwood else 3.8 if capture_inactive else 6.0)
		if capture_cooling:
			var cooling_now := int(scene.call("_unix_now"))
			scene.passive_modules["woodcutting-firepit"] = {
				"active": false,
				"igniting": false,
				"last_update": cooling_now,
				"started_unix": 0,
				"burned_scrapwood": 0.0,
				"cooling_bonus": 0.08,
				"cooling_started_unix": cooling_now,
				"shutdown_reason": "manual"
			}
		elif (not capture_inactive) and (not capture_ignition) and (not capture_need_scrapwood) and not bool(scene.call("_passive_modules_runtime").start_firepit(int(scene.call("_unix_now")))):
			_fail("firepit did not start for capture")
			return
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "woodcutting")
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("module_ui_collapsed", {})
	scene.set("module_ui_pinned_order", [])
	if capture_empty_stamina:
		scene.stamina["woodcutting"] = 0.0
		scene.stamina_bank["woodcutting"] = 0.0
	var render_result = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _frame in range(30):
		_hide_boot_overlay_for_capture(scene)
		_sync_detail_lazy_visible_cards(scene)
		if scene.has_method("_update_ui"):
			scene.call("_update_ui", 0.0, true)
		await process_frame
	if not capture_header:
		if not await _scroll_real_screen_to_firepit(scene):
			_fail("could not scroll real Woodcutting screen to firepit")
			return
		if capture_xp_popup:
			scene.call("_passive_modules_runtime").call("award_firepit_burn_xp", 1)
			for _xp_frame in range(44):
				_hide_boot_overlay_for_capture(scene)
				if scene.has_method("_update_ui"):
					scene.call("_update_ui", 0.0, true)
				await process_frame
		elif capture_ignition:
			scene.call("_passive_modules_runtime").begin_firepit_ignition(int(scene.call("_unix_now")))
			await create_timer(0.62).timeout
			for _ignite_frame in range(6):
				_hide_boot_overlay_for_capture(scene)
				if scene.has_method("_update_ui"):
					scene.call("_update_ui", 0.0, true)
				await process_frame
		elif capture_need_scrapwood:
			scene.call("_passive_modules_runtime").begin_firepit_ignition(int(scene.call("_unix_now")))
			for _need_frame in range(12):
				_hide_boot_overlay_for_capture(scene)
				if scene.has_method("_update_ui"):
					scene.call("_update_ui", 0.0, true)
				await process_frame
	for _frame in range(12):
		_hide_boot_overlay_for_capture(scene)
		_sync_detail_lazy_visible_cards(scene)
		if scene.has_method("_update_ui"):
			scene.call("_update_ui", 0.0, true)
		await process_frame
	_hide_boot_overlay_for_capture(scene)
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() == "headless":
		print("woodcutting-firepit-capture skipped=headless")
		scene.queue_free()
		quit(0)
		return
	var texture := root.get_texture()
	if texture == null:
		print("woodcutting-firepit-capture skipped=no-texture")
		quit(0)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("woodcutting-firepit-capture skipped=empty-image")
		quit(0)
		return
	var capture_path := OS.get_environment("IDLE_ELITE_FIREPIT_CAPTURE_PATH")
	var result_code := image.save_png(capture_path)
	print("woodcutting-firepit-capture path=%s result=%s size=%sx%s display=%s" % [
		capture_path,
		str(result_code),
		str(image.get_width()),
		str(image.get_height()),
		DisplayServer.get_name()
	])
	if result_code != OK:
		_fail("screenshot save failed")
		return
	scene.queue_free()
	quit(0)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(720):
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
			for _i in range(30):
				await process_frame
			return true
	return false


func _hide_boot_overlay_for_capture(scene: Node) -> void:
	scene.set("boot_warmup_active", false)
	scene.set("boot_splash_dismissed_early", true)
	var boot_runtime = scene.call("_boot_warmup_runtime") if scene.has_method("_boot_warmup_runtime") else null
	if boot_runtime != null:
		boot_runtime.set("active", false)
		var runtime_overlay := boot_runtime.get("overlay") as Control
		if runtime_overlay != null and is_instance_valid(runtime_overlay):
			runtime_overlay.visible = false
			runtime_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			runtime_overlay.modulate.a = 0.0
		var runtime_layer := boot_runtime.get("layer") as CanvasLayer
		if runtime_layer != null and is_instance_valid(runtime_layer):
			runtime_layer.visible = false
		var runtime_splash := boot_runtime.get("splash") as Control
		if runtime_splash != null and is_instance_valid(runtime_splash) and runtime_splash.has_method("stop"):
			runtime_splash.call("stop")
	var overlay := scene.get("boot_warmup_overlay") as Control
	if overlay != null and is_instance_valid(overlay):
		overlay.visible = false
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.modulate.a = 0.0
	var layer := scene.get("boot_warmup_layer") as CanvasLayer
	if layer != null and is_instance_valid(layer):
		layer.visible = false
	var offline_overlay := scene.get("offline_summary_overlay") as Control
	if offline_overlay != null and is_instance_valid(offline_overlay):
		offline_overlay.visible = false
		offline_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tutorial_overlay := scene.get("tutorial_overlay") as Control
	if tutorial_overlay != null and is_instance_valid(tutorial_overlay):
		tutorial_overlay.visible = false
		tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tutorial_surface = scene.call("_tutorial_overlay_surface") if scene.has_method("_tutorial_overlay_surface") else null
	if tutorial_surface != null:
		for tutorial_property in ["tutorial_arrow", "tutorial_target_ring", "tutorial_target_label", "tutorial_instruction_label"]:
			var tutorial_control := tutorial_surface.get(tutorial_property) as Control
			if tutorial_control != null and is_instance_valid(tutorial_control):
				tutorial_control.visible = false
				tutorial_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for property_name in ["chat_strip", "module_utility_row", "nav_bar"]:
		var chrome := scene.get(property_name) as Control
		if chrome != null and is_instance_valid(chrome):
			chrome.visible = false
			chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chrome.modulate.a = 0.0
	for raw_overlay in scene.get_tree().get_nodes_in_group("modal_overlay"):
		var modal := raw_overlay as Control
		if modal != null and is_instance_valid(modal):
			modal.visible = false
			modal.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _scroll_real_screen_to_firepit(scene: Node) -> bool:
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not is_instance_valid(scroll):
		return false
	if scene.has_method("_scroll_to_activity_card"):
		var native_scroll = scene.call("_scroll_to_activity_card", "woodcutting-firepit", false, true)
		if native_scroll != null:
			await native_scroll
		for _native_settle in range(24):
			_hide_boot_overlay_for_capture(scene)
			_sync_detail_lazy_visible_cards(scene)
			if scene.has_method("_update_ui"):
				scene.call("_update_ui", 0.0, true)
			await process_frame
		var native_target := _find_firepit_card_control(scene)
		if native_target != null and is_instance_valid(native_target) and _control_is_in_capture_view(scroll, native_target):
			pass
	if scene.has_method("_detail_actions_scroll_target_for_action"):
		var raw_target = scene.call("_detail_actions_scroll_target_for_action", "woodcutting-firepit", true)
		if int(raw_target) >= 0:
			_set_scroll_vertical(scroll, int(raw_target))
			for _target_settle in range(18):
				_hide_boot_overlay_for_capture(scene)
				_sync_detail_lazy_visible_cards(scene)
				if scene.has_method("_update_ui"):
					scene.call("_update_ui", 0.0, true)
				await process_frame
			var target_control := _find_firepit_card_control(scene)
			if target_control != null and is_instance_valid(target_control) and _control_is_in_capture_view(scroll, target_control):
				pass
	for attempt in range(48):
		_hide_boot_overlay_for_capture(scene)
		_sync_detail_lazy_visible_cards(scene)
		if scene.has_method("_update_ui"):
			scene.call("_update_ui", 0.0, true)
		await process_frame
		var target := _find_firepit_card_control(scene)
		if target != null and is_instance_valid(target):
			var viewport_top := scroll.get_global_rect().position.y
			var target_top := target.get_global_rect().position.y
			var desired_screen_y := viewport_top + 220.0
			var raw_target_scroll := int(round(float(scroll.scroll_vertical) + target_top - desired_screen_y))
			_set_scroll_vertical(scroll, raw_target_scroll)
			for _settle in range(18):
				_hide_boot_overlay_for_capture(scene)
				_sync_detail_lazy_visible_cards(scene)
				if scene.has_method("_update_ui"):
					scene.call("_update_ui", 0.0, true)
				await process_frame
			return _control_is_in_capture_view(scroll, target)
		var max_scroll := int(scroll.get_max_scroll_vertical())
		var next_scroll := 0
		if max_scroll > 0:
			next_scroll = int(round(float(max_scroll) * (float(attempt + 1) / 48.0)))
		else:
			next_scroll = (attempt + 1) * 320
		_set_scroll_vertical(scroll, next_scroll)
	return false


func _control_is_in_capture_view(scroll: ScrollContainer, control: Control) -> bool:
	if scroll == null or control == null or not is_instance_valid(scroll) or not is_instance_valid(control):
		return false
	var viewport := scroll.get_global_rect()
	var rect := control.get_global_rect()
	return (
		rect.position.x >= viewport.position.x - 24.0
		and rect.end.x <= viewport.end.x + 24.0
		and rect.position.y >= viewport.position.y - 32.0
		and rect.position.y < viewport.position.y + viewport.size.y - 160.0
		and rect.end.y > viewport.position.y + 80.0
	)


func _sync_detail_lazy_visible_cards(scene: Node) -> void:
	if not scene.has_method("_skill_detail_surface"):
		return
	var detail_surface = scene.call("_skill_detail_surface")
	if detail_surface != null and detail_surface.has_method("_sync_detail_lazy_visible_cards"):
		detail_surface.call("_sync_detail_lazy_visible_cards", true, -1)


func _set_scroll_vertical(scroll: ScrollContainer, target_scroll: int) -> void:
	var max_scroll := int(scroll.get_max_scroll_vertical())
	var clamped := maxi(0, target_scroll)
	if max_scroll > 0:
		clamped = mini(clamped, max_scroll)
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = clamped
	scroll.set("drag_scroll_position", float(clamped))


func _find_firepit_card_control(scene: Node) -> Control:
	var detail_surface = scene.call("_skill_detail_surface")
	if detail_surface == null:
		return null
	var entry := detail_surface.call("_detail_stack_child_for_action", "firepit") as Control
	var card := entry.find_child("FirepitCardRoot", true, false) as Control if entry != null else null
	return card if card != null else entry


func _fail(message: String) -> void:
	push_error("woodcutting-firepit-capture-failed: %s" % message)
	print("woodcutting-firepit-capture-failed: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    $output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/woodcutting-firepit/capture_woodcutting_firepit.gd" 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    if (-not (Test-Path -LiteralPath $capturePath)) {
        throw "Real Woodcutting Firepit game capture was not created. No fallback image was generated."
    } else {
        Write-Host "woodcutting-firepit-capture-file=$capturePath"
    }
    Assert-True (Test-Path -LiteralPath $capturePath) "Woodcutting Firepit real game capture was not created."
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCapturePath) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_PATH -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_PATH = $previousCapturePath
    }
    if ($null -eq $previousCaptureLocked) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_LOCKED -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_LOCKED = $previousCaptureLocked
    }
    if ($null -eq $previousCaptureInactive) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_INACTIVE -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_INACTIVE = $previousCaptureInactive
    }
    if ($null -eq $previousCaptureHeader) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_HEADER -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_HEADER = $previousCaptureHeader
    }
    if ($null -eq $previousCaptureXpPopup) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_XP_POPUP -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_XP_POPUP = $previousCaptureXpPopup
    }
    if ($null -eq $previousCaptureIgnition) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_IGNITION -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_IGNITION = $previousCaptureIgnition
    }
    if ($null -eq $previousCaptureCooling) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_COOLING -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_COOLING = $previousCaptureCooling
    }
    if ($null -eq $previousCaptureNeedScrapwood) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_NEED_SCRAPWOOD -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_NEED_SCRAPWOOD = $previousCaptureNeedScrapwood
    }
    if ($null -eq $previousCaptureEmptyStamina) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_EMPTY_STAMINA -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_EMPTY_STAMINA = $previousCaptureEmptyStamina
    }
    if ($null -eq $previousCaptureDarkMode) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_DARK_MODE -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_DARK_MODE = $previousCaptureDarkMode
    }
    if ($null -eq $previousCaptureViewportWidth) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_WIDTH -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_WIDTH = $previousCaptureViewportWidth
    }
    if ($null -eq $previousCaptureViewportHeight) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_HEIGHT -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_VIEWPORT_HEIGHT = $previousCaptureViewportHeight
    }
    if ($null -eq $previousCaptureWindowWidth) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_WIDTH -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_WIDTH = $previousCaptureWindowWidth
    }
    if ($null -eq $previousCaptureWindowHeight) {
        Remove-Item Env:\IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_HEIGHT -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_FIREPIT_CAPTURE_WINDOW_HEIGHT = $previousCaptureWindowHeight
    }
    if (Test-Path -LiteralPath $scriptPath) {
        Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
    }
    $afterHeadless = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterHeadless.Count -gt 0) {
        $afterHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "Headless Godot process left behind after Woodcutting Firepit capture."
    }
}
