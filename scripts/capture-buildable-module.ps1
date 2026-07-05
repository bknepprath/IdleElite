param(
    [int]$ViewportWidth = 2160,
    [int]$ViewportHeight = 3840,
    [int]$WindowWidth = 627,
    [int]$WindowHeight = 1115
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$captureDir = Join-Path $projectRoot ".codex-tmp\buildable-modules"
$capturePath = Join-Path $captureDir "buildable-duel-fence-post-blueprint-desktop-${WindowWidth}x${WindowHeight}.png"
$scriptPath = Join-Path $captureDir "capture_buildable_module.gd"

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

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_BUILDABLE_CAPTURE_PATH
$previousViewportWidth = $env:IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_WIDTH
$previousViewportHeight = $env:IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_HEIGHT
$previousWindowWidth = $env:IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_WIDTH
$previousWindowHeight = $env:IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_HEIGHT
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)

try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    $env:IDLE_ELITE_BUILDABLE_CAPTURE_PATH = $capturePath
    $env:IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_WIDTH = [string]$ViewportWidth
    $env:IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_HEIGHT = [string]$ViewportHeight
    $env:IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_WIDTH = [string]$WindowWidth
    $env:IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_HEIGHT = [string]$WindowHeight

    @'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var viewport_width := OS.get_environment("IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_WIDTH").to_int()
	var viewport_height := OS.get_environment("IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_HEIGHT").to_int()
	var window_width := OS.get_environment("IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_WIDTH").to_int()
	var window_height := OS.get_environment("IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_HEIGHT").to_int()
	var capture_size := Vector2i(viewport_width, viewport_height)
	var window_size := Vector2i(window_width, window_height)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
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
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 6
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(6))
	scene.skills["fight"] = fight
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "duel-leaning-fence-post", "buildable module capture unlock")
	scene.set("built_modules", {})
	scene.material_runtime.set_amount("scrapwood", 3.0)
	var action := scene.call("_action_data", "fight", "duel-leaning-fence-post") as Dictionary
	if action.is_empty():
		_fail("duel fence post action missing")
		return
	var stage := Control.new()
	stage.name = "BuildableModuleCaptureStage"
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.z_index = 0
	stage.z_as_relative = false
	root.add_child(stage)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#f1e8d9")
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(backdrop)
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1900.0, 1900.0) as Dictionary
	var card := built.get("card_root") as Control
	if card == null:
		_fail("duel fence post card missing")
		return
	card.position = Vector2(130.0, 1260.0)
	stage.add_child(card)
	scene.visible = false
	for _frame in range(12):
		await process_frame
	_hide_boot_overlay_for_capture(scene)
	await RenderingServer.frame_post_draw
	var texture := root.get_texture()
	if texture == null:
		_fail("capture texture missing")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("capture image empty")
		return
	var capture_path := OS.get_environment("IDLE_ELITE_BUILDABLE_CAPTURE_PATH")
	var result := image.save_png(capture_path)
	print("buildable-module-capture path=%s result=%s size=%sx%s display=%s" % [
		capture_path,
		str(result),
		str(image.get_width()),
		str(image.get_height()),
		DisplayServer.get_name()
	])
	scene.queue_free()
	quit(0)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _i in range(240):
		if bool(scene.get("startup_initialized")):
			return true
		await process_frame
	return false


func _hide_boot_overlay_for_capture(scene: Node) -> void:
	if scene.has_method("_boot_warmup_runtime"):
		scene.call("_boot_warmup_runtime").call("_dismiss_boot_splash_for_play")
	scene.set("boot_warmup_active", false)
	for property_name in ["boot_splash_overlay", "boot_warmup_overlay", "offline_summary_overlay", "achievements_overlay", "achievement_toast_layer", "achievement_toast_root", "page_transition_cover"]:
		var item := scene.get(property_name) as CanvasItem
		if item != null:
			item.visible = false
	for toast in scene.get("achievement_toasts"):
		var toast_item := toast as CanvasItem
		if toast_item != null:
			toast_item.visible = false


func _find_node_by_name(root_node: Node, target_name: String) -> Node:
	if root_node.name == target_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_node_by_name(child, target_name)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	push_error("buildable-module-capture-failed: %s" % message)
	print("buildable-module-capture-failed: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    $output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/buildable-modules/capture_buildable_module.gd" 2>&1
    $output | Write-Output
    Assert-True (Test-Path -LiteralPath $capturePath) "Buildable module real game capture was not created."
    Write-Host "buildable-module-capture-file=$capturePath"
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCapturePath) { Remove-Item Env:\IDLE_ELITE_BUILDABLE_CAPTURE_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_BUILDABLE_CAPTURE_PATH = $previousCapturePath }
    if ($null -eq $previousViewportWidth) { Remove-Item Env:\IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_WIDTH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_WIDTH = $previousViewportWidth }
    if ($null -eq $previousViewportHeight) { Remove-Item Env:\IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_HEIGHT -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_BUILDABLE_CAPTURE_VIEWPORT_HEIGHT = $previousViewportHeight }
    if ($null -eq $previousWindowWidth) { Remove-Item Env:\IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_WIDTH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_WIDTH = $previousWindowWidth }
    if ($null -eq $previousWindowHeight) { Remove-Item Env:\IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_HEIGHT -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_BUILDABLE_CAPTURE_WINDOW_HEIGHT = $previousWindowHeight }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        Write-Warning "Unrelated headless Godot process appeared during buildable module capture; leaving it running."
    }
}
