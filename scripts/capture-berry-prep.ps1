param(
    [int]$ViewportWidth = 2160,
    [int]$ViewportHeight = 3840,
    [int]$WindowWidth = 627,
    [int]$WindowHeight = 1115,
    [string]$Suffix = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$captureDir = Join-Path $projectRoot ".codex-tmp\berry-prep"
$captureName = "berry-prep-popover-desktop-${WindowWidth}x${WindowHeight}.png"
if (-not [string]::IsNullOrWhiteSpace($Suffix)) {
    $captureName = "berry-prep-popover-${Suffix}-${WindowWidth}x${WindowHeight}.png"
}
$capturePath = Join-Path $captureDir $captureName
$scriptPath = Join-Path $captureDir "capture_berry_prep.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_BERRY_PREP_CAPTURE_PATH
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)

try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    $env:IDLE_ELITE_BERRY_PREP_CAPTURE_PATH = $capturePath
    @"
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var capture_size := Vector2i($ViewportWidth, $ViewportHeight)
	var window_size := Vector2i($WindowWidth, $WindowHeight)
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
	var woodcutting := scene.skills["woodcutting"] as Dictionary
	woodcutting["level"] = 13
	woodcutting["xp"] = maxi(int(woodcutting.get("xp", 0)), SkillState.xp_for_level(13))
	scene.skills["woodcutting"] = woodcutting
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "woodcutting", "prune-orchard-row", "berry mode capture unlock")
	scene.material_runtime.set_amount("berries", 6.0)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "woodcutting")
	scene.call("_set_berry_mode_enabled", true)
	scene.call("_toggle_berry_prep_for_action", "woodcutting", "prune-orchard-row")
	scene.call("_action_runtime").call("_start_action", "woodcutting", "prune-orchard-row", true, false)
	scene.material_runtime.set_amount("berries", 6.0)
	scene.call("_render_screen", false, -1, false)
	for _frame in range(6):
		await process_frame
	await scene.call("_scroll_to_activity_card", "prune-orchard-row", false, true)
	for _frame in range(14):
		await process_frame
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll != null:
		var presentation_mode := "$Suffix" == "presentation"
		var framed_scroll := maxi(0, scroll.scroll_vertical + (140 if presentation_mode else -260))
		scroll.scroll_vertical = framed_scroll
		scroll.set("drag_scroll_position", float(framed_scroll))
	for _frame in range(6):
		await process_frame
	scene.material_runtime.set_amount("berries", 6.0)
	scene.call("_material_collection_surface").call("_sync_visible_mat_collection_for_action", "woodcutting", "prune-orchard-row", true)
	for _frame in range(2):
		await process_frame
	_hide_capture_overlays(scene)
	for _frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() == "headless":
		print("berry-prep-capture skipped=headless")
		scene.queue_free()
		quit(0)
		return
	var texture := root.get_texture()
	if texture == null:
		_fail("capture texture missing")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("capture image empty")
		return
	var capture_path := OS.get_environment("IDLE_ELITE_BERRY_PREP_CAPTURE_PATH")
	var result := image.save_png(capture_path)
	print("berry-prep-capture path=%s result=%s size=%sx%s display=%s" % [capture_path, str(result), str(image.get_width()), str(image.get_height()), DisplayServer.get_name()])
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
		scene.call("_boot_warmup_runtime").call("_dismiss_boot_splash_for_play")
	scene.set("boot_warmup_active", false)
	for property_name in ["boot_warmup_overlay", "offline_summary_overlay", "achievements_overlay", "achievement_toast_layer", "achievement_toast_root", "page_transition_cover"]:
		var item := scene.get(property_name) as CanvasItem
		if item != null:
			item.visible = false
	for toast in scene.get("achievement_toasts"):
		var toast_item := toast as CanvasItem
		if toast_item != null:
			toast_item.visible = false
	for reward_float in scene.get_tree().get_nodes_in_group(scene.SKILL_REWARD_FLOAT_GROUP):
		var reward_item := reward_float as CanvasItem
		if reward_item != null:
			reward_item.visible = false


func _fail(message: String) -> void:
	push_error("berry-prep-capture-failed: %s" % message)
	print("berry-prep-capture-failed: %s" % message)
	quit(1)
"@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    $output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/berry-prep/capture_berry_prep.gd" 2>&1
    $output | Write-Output
    Assert-True (Test-Path -LiteralPath $capturePath) "Berry Prep real game capture was not created."
    Write-Host "berry-prep-capture-file=$capturePath"
}
finally {
    if ($null -eq $previousTimeout) { Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue } else { $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout }
    if ($null -eq $previousCapturePath) { Remove-Item Env:\IDLE_ELITE_BERRY_PREP_CAPTURE_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_BERRY_PREP_CAPTURE_PATH = $previousCapturePath }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        throw "Headless Godot process left behind after Berry Prep capture."
    }
}
