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
$captureDir = Join-Path $projectRoot ".codex-tmp\boss-fight"
$capturePath = Join-Path $captureDir "boss-rooster-gate-desktop-${WindowWidth}x${WindowHeight}.png"
$scriptPath = Join-Path $captureDir "capture_boss_fight_gate.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_BOSS_CAPTURE_PATH
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)

try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    $env:IDLE_ELITE_BOSS_CAPTURE_PATH = $capturePath
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
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 8
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(8))
	scene.skills["fight"] = fight
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "push-ups", "boss capture unlock")
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "kick-mud-off-boot", "boss capture unlock")
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "duel-leaning-fence-post", "boss capture unlock")
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "wrap-hands", "boss capture unlock")
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "face-the-rooster", "boss capture unlock")
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fight")
	_hide_capture_overlays(scene)
	var action := scene.call("_action_data", "fight", "face-the-rooster") as Dictionary
	if action.is_empty():
		_fail("boss action missing")
		return
	scene.call("_render_screen", false, -1, false)
	for _frame in range(8):
		await process_frame
	await scene.call("_scroll_to_activity_card", "face-the-rooster", false, true)
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll != null:
		var framed_scroll := maxi(0, scroll.scroll_vertical)
		scroll.scroll_vertical = framed_scroll
		scroll.set("drag_scroll_position", float(framed_scroll))
	for _frame in range(24):
		await process_frame
	_force_rooster_damage_flash(scene)
	for _frame in range(3):
		await process_frame
	_hide_capture_overlays(scene)
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() == "headless":
		print("boss-fight-capture skipped=headless")
		scene.queue_free()
		quit(0)
		return
	var image := root.get_texture().get_image()
	var capture_path := OS.get_environment("IDLE_ELITE_BOSS_CAPTURE_PATH")
	var result := image.save_png(capture_path)
	print("boss-fight-capture path=%s result=%s size=%sx%s display=%s" % [capture_path, str(result), str(image.get_width()), str(image.get_height()), DisplayServer.get_name()])
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
	for property_name in ["boot_splash_overlay", "boot_warmup_overlay", "offline_summary_overlay", "page_transition_cover"]:
		var item := scene.get(property_name) as CanvasItem
		if item != null:
			item.visible = false


func _force_rooster_damage_flash(root_node: Node) -> void:
	if root_node.has_method("_start_rooster_attack"):
		root_node.call("_start_rooster_attack")
		return
	for child in root_node.get_children():
		_force_rooster_damage_flash(child)


func _fail(message: String) -> void:
	push_error("boss-fight-capture-failed: %s" % message)
	print("boss-fight-capture-failed: %s" % message)
	quit(1)
"@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    $output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/boss-fight/capture_boss_fight_gate.gd" 2>&1
    $output | Write-Output
    Assert-True (Test-Path -LiteralPath $capturePath) "Boss fight real card capture was not created."
    Assert-True ((Get-Item -LiteralPath $capturePath).Length -gt 1024) "Boss fight real card capture was empty."
    Write-Host "boss-fight-capture-file=$capturePath"
}
finally {
    if ($null -eq $previousTimeout) { Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue } else { $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout }
    if ($null -eq $previousCapturePath) { Remove-Item Env:\IDLE_ELITE_BOSS_CAPTURE_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_BOSS_CAPTURE_PATH = $previousCapturePath }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        Write-Warning "Unrelated headless Godot process appeared during boss fight capture; leaving it running."
    }
}
