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
$captureDir = Join-Path $projectRoot ".codex-tmp\mission-ceremony"
$capturePath = Join-Path $captureDir "mission-complete-ceremony-desktop-${WindowWidth}x${WindowHeight}.png"
$scriptPath = Join-Path $captureDir "capture_mission_completion_ceremony.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."
Assert-True ($ViewportWidth -gt 0 -and $ViewportHeight -gt 0 -and $WindowWidth -gt 0 -and $WindowHeight -gt 0) "Capture dimensions must be positive."
New-Item -ItemType Directory -Path $captureDir -Force | Out-Null
Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_MISSION_CEREMONY_CAPTURE_PATH
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)

try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "180"
    $env:IDLE_ELITE_MISSION_CEREMONY_CAPTURE_PATH = $capturePath
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
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for _i in range(240):
		if bool(scene.get("startup_initialized")):
			break
		await process_frame
	if not bool(scene.get("startup_initialized")):
		_fail("main scene did not become capture-ready")
		return
	if scene.has_method("_boot_warmup_runtime"):
		scene.call("_boot_warmup_runtime").call("_dismiss_boot_splash_for_play")
	scene.set("boot_warmup_active", false)
	for property_name in ["boot_splash_overlay", "boot_warmup_overlay", "offline_summary_overlay", "page_transition_cover"]:
		var item := scene.get(property_name) as CanvasItem
		if item != null:
			item.visible = false
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 5
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(5))
	scene.skills["fight"] = fight
	scene.hub_missions = [{
		"skill_id": "fight",
		"action_id": "push-ups",
		"target": 1,
		"remaining": 1,
		"assigned_unix": int(scene.call("_unix_now"))
	}]
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fight")
	scene.call("_render_screen", false, -1, false)
	for _frame in range(8):
		await process_frame
	await scene.call("_scroll_to_activity_card", "push-ups", false, true)
	for _frame in range(8):
		await process_frame
	(scene.call("_hub_surface") as Object).call("_show_hub_mission_completion_ceremony", "fight", "push-ups")
	for _frame in range(16):
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
	var capture_path := OS.get_environment("IDLE_ELITE_MISSION_CEREMONY_CAPTURE_PATH")
	var result := image.save_png(capture_path)
	if result != OK:
		_fail("capture save failed: %s" % str(result))
		return
	print("mission-ceremony-capture path=%s result=%s size=%sx%s display=%s" % [capture_path, str(result), str(image.get_width()), str(image.get_height()), DisplayServer.get_name()])
	scene.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
"@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    $output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/mission-ceremony/capture_mission_completion_ceremony.gd" 2>&1
    $output | Write-Output
    Assert-True ($LASTEXITCODE -eq 0) "Mission ceremony capture exited with code $LASTEXITCODE."
    Assert-True (Test-Path -LiteralPath $capturePath) "Mission ceremony capture was not created."
    Write-Host "mission-ceremony-capture-file=$capturePath"
}
finally {
    if ($null -eq $previousTimeout) { Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue } else { $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout }
    if ($null -eq $previousCapturePath) { Remove-Item Env:\IDLE_ELITE_MISSION_CEREMONY_CAPTURE_PATH -ErrorAction SilentlyContinue } else { $env:IDLE_ELITE_MISSION_CEREMONY_CAPTURE_PATH = $previousCapturePath }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        throw "Headless Godot process left behind after mission ceremony capture."
    }
}
