param(
    [int]$ViewportWidth = 1080,
    [int]$ViewportHeight = 1920,
    [int]$WindowWidth = 1080,
    [int]$WindowHeight = 1920
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
	scene.get("activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	scene.startup_initialized = true
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 8
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(8))
	scene.skills["fight"] = fight
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "face-the-rooster", "boss capture unlock")
	var action := scene.call("_action_data", "fight", "face-the-rooster") as Dictionary
	if action.is_empty():
		_fail("boss action missing")
		return
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1080.0, 1080.0) as Dictionary
	var card := built.get("card", {}) as Dictionary
	var card_root := built.get("card_root") as Control
	if card_root == null:
		_fail("boss card missing")
		return
	scene.visible = false
	card_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_root.offset_left = 60.0
	card_root.offset_right = -60.0
	card_root.offset_top = 450.0
	card_root.offset_bottom = -450.0
	root.add_child(card_root)
	var boss_key := str(scene.call("_action_key", "fight", "face-the-rooster"))
	scene.call("_skill_detail_surface").call("_register_action_card", boss_key, card)
	if not scene.call("_action_runtime").call("_start_action_from_card_tap", "fight", "face-the-rooster", boss_key):
		_fail("boss action did not start")
		return
	for _frame in range(2):
		await process_frame
	var boot_runtime = scene.call("_boot_warmup_runtime")
	boot_runtime.call("_dismiss_boot_splash_for_play")
	var boot_layer := boot_runtime.get("layer") as CanvasLayer
	if boot_layer != null:
		boot_layer.visible = false
	for _frame in range(20):
		await process_frame
	_force_rooster_damage_flash(card_root)
	for _frame in range(3):
		await process_frame
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
