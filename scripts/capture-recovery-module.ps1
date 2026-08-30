param(
    [int]$ViewportWidth = 2160,
    [int]$ViewportHeight = 3840,
    [int]$WindowWidth = 627,
    [int]$WindowHeight = 1115
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$captureDir = Join-Path $projectRoot ".codex-tmp\recovery-modules"
$capturePath = Join-Path $captureDir "recovery-wrap-hands-desktop-${WindowWidth}x${WindowHeight}.png"
$scriptPath = Join-Path $captureDir "capture_recovery_module.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
Assert-True ($ViewportWidth -gt 0 -and $ViewportHeight -gt 0 -and $WindowWidth -gt 0 -and $WindowHeight -gt 0) "Capture dimensions must be positive."
New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_RECOVERY_CAPTURE_PATH
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)

try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    $env:IDLE_ELITE_RECOVERY_CAPTURE_PATH = $capturePath
    @"
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	var capture_size := Vector2i($ViewportWidth, $ViewportHeight)
	var window_size := Vector2i($WindowWidth, $WindowHeight)
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
	if not await _wait_for_boot_ready(scene):
		_fail("main scene did not become capture-ready")
		return
	scene.call("_test_state_runtime").call("_god_mode_unlock_onboarding_state")
	scene.call("_tutorial_overlay_surface").call("_clear_onboarding_auto_run_message", true)
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 7
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(7))
	scene.skills["fight"] = fight
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "duel-leaning-fence-post", "recovery capture unlock")
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "wrap-hands", "recovery capture unlock")
	scene.built_modules["fight:duel-leaning-fence-post"] = true
	scene.stamina["fight"] = 1.0
	SkillState.host_sync_stamina_bank("fight", scene)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fight")
	await scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	for _frame in range(6):
		await process_frame
	var scroll_target := -1
	for _frame in range(120):
		scene.call("_skill_detail_surface").call("_ensure_detail_lazy_entry_mounted", "wrap-hands")
		scroll_target = int(scene.call("_skill_detail_surface").call("_detail_actions_scroll_target_for_action", "wrap-hands", true))
		if scroll_target >= 0:
			break
		await process_frame
	if scroll_target < 0:
		_fail("Wrap Hands card did not mount for capture")
		return
	scene.detail_actions_scroll.scroll_to_vertical(scroll_target, 0.0)
	for _frame in range(12):
		await process_frame
	if abs(scene.detail_actions_scroll.scroll_vertical - scroll_target) > 12:
		_fail("Wrap Hands card scroll target was not applied")
		return
	var card := scene.action_cards.get("fight:wrap-hands", {}) as Dictionary
	var progress := card.get("progress") as Control
	if progress == null:
		_fail("Wrap Hands progress rail did not mount")
		return
	progress.call("set_value", 55.0)
	for _frame in range(30):
		_hide_capture_overlays(scene)
		await process_frame
	await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	if texture == null:
		_fail("capture texture missing")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("capture image empty")
		return
	var capture_path := OS.get_environment("IDLE_ELITE_RECOVERY_CAPTURE_PATH")
	var result := image.save_png(capture_path)
	print("recovery-module-capture path=%s result=%s size=%sx%s display=%s" % [capture_path, str(result), str(image.get_width()), str(image.get_height()), DisplayServer.get_name()])
	if result != OK:
		_fail("capture save failed: %s" % str(result))
		return
	scene.queue_free()
	quit(0)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _i in range(240):
		if bool(scene.get("startup_initialized")):
			return true
		await process_frame
	return false


func _hide_capture_overlays(scene: Node) -> void:
	if scene.has_method("_boot_warmup_runtime"):
		var boot_runtime = scene.call("_boot_warmup_runtime")
		boot_runtime.call("_dismiss_boot_splash_for_play")
		boot_runtime.call("_finish_overlay_hide")
	scene.set("boot_warmup_active", false)
	for property_name in ["boot_warmup_overlay", "offline_summary_overlay", "achievements_overlay", "achievement_toast_layer", "achievement_toast_root", "page_transition_cover"]:
		var item := scene.get(property_name) as CanvasItem
		if item != null:
			item.visible = false
	var tutorial_overlay := scene.get("tutorial_overlay") as CanvasItem
	if tutorial_overlay != null:
		tutorial_overlay.visible = false
	var achievement_toasts = scene.get("achievement_toasts")
	if achievement_toasts is Array:
		for toast in achievement_toasts:
			var toast_item := toast as CanvasItem
			if toast_item != null:
				toast_item.visible = false


func _fail(message: String) -> void:
	push_error("recovery-module-capture-failed: %s" % message)
	print("recovery-module-capture-failed: %s" % message)
	quit(1)
"@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    $output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/recovery-modules/capture_recovery_module.gd" 2>&1
    $output | Write-Output
    Assert-True ($LASTEXITCODE -eq 0) "Recovery module capture exited with code $LASTEXITCODE."
    Assert-True (Test-Path -LiteralPath $capturePath) "Recovery module real game capture was not created."
    Write-Host "recovery-module-capture-file=$capturePath"
}
finally {
    if ($null -eq $previousTimeout) { Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue } else { $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout }
    if ($null -eq $previousCapturePath) { Remove-Item Env:\IDLE_ELITE_RECOVERY_CAPTURE_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_RECOVERY_CAPTURE_PATH = $previousCapturePath }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        Write-Warning "Unrelated headless Godot process appeared during recovery module capture; leaving it running."
    }
}
