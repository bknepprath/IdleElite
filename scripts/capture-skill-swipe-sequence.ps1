# Captures real-game frames of a finger-speed page swipe at 1080x1920: before,
# during the drag, and after release. Used to judge swipe smoothness, blank
# transitions and post-swipe layout shifts. Starts from a sandboxed copy of the
# desktop save; nothing is written back.
param(
    [string]$OutputDir = "",
    [string]$StartSkill = "fight",
    [int]$Direction = -1,
    [string]$SeedSave = (Join-Path $env:APPDATA "Godot\app_userdata\Idle Elite\idle_elite_save.json")
)
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
if (-not $OutputDir) {
    $OutputDir = Join-Path $projectRoot ".codex-tmp\skill-swipe-sequence"
}
$scriptDir = Join-Path $projectRoot ".codex-tmp\skill-swipe-sequence-script"
$scriptPath = Join-Path $scriptDir "capture_skill_swipe_sequence.gd"
New-Item -ItemType Directory -Path $OutputDir, $scriptDir -Force | Out-Null
Get-ChildItem -LiteralPath $OutputDir -Filter "*.png" -ErrorAction SilentlyContinue | Remove-Item -Force

$previous = @{
    GODOT_RUN_TIMEOUT_SECONDS = $env:GODOT_RUN_TIMEOUT_SECONDS
    IDLE_ELITE_SWIPE_SEQ_DIR = $env:IDLE_ELITE_SWIPE_SEQ_DIR
    IDLE_ELITE_SWIPE_SEQ_SKILL = $env:IDLE_ELITE_SWIPE_SEQ_SKILL
    IDLE_ELITE_SWIPE_SEQ_DIRECTION = $env:IDLE_ELITE_SWIPE_SEQ_DIRECTION
    IDLE_ELITE_TEST_USER_DATA_DIR = $env:IDLE_ELITE_TEST_USER_DATA_DIR
}
try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "300"
    $env:IDLE_ELITE_SWIPE_SEQ_DIR = (Resolve-Path -LiteralPath $OutputDir).Path
    $env:IDLE_ELITE_SWIPE_SEQ_SKILL = $StartSkill
    $env:IDLE_ELITE_SWIPE_SEQ_DIRECTION = "$Direction"
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-swipe-seq-" + [guid]::NewGuid().ToString("N"))
    if ($SeedSave -and (Test-Path -LiteralPath $SeedSave)) {
        $sandboxSaveDir = Join-Path $env:IDLE_ELITE_TEST_USER_DATA_DIR "Godot\app_userdata\Idle Elite"
        New-Item -ItemType Directory -Path $sandboxSaveDir -Force | Out-Null
        Copy-Item -LiteralPath $SeedSave -Destination (Join-Path $sandboxSaveDir "idle_elite_save.json")
    }
    @'
extends SceneTree

const CAPTURE_SIZE := Vector2i(1080, 1920)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = CAPTURE_SIZE
	root.size = CAPTURE_SIZE
	DisplayServer.window_set_size(CAPTURE_SIZE)
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for _i in range(900):
		if bool(scene.get("startup_initialized")) and bool(scene.get("save_restore_complete")):
			break
		await process_frame
	var warmup = scene.call("_boot_warmup_runtime")
	for _i in range(1800):
		if not bool(warmup.get("active")):
			break
		await process_frame
	var AchievementState = load("res://scripts/achievements/state.gd")
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(scene, false), scene.call("_save_runtime").achievement_toast_seen_ids, [])
	scene.call("_achievement_toast_surface").achievement_toast_queue.clear()
	scene.set("selected_skill_id", OS.get_environment("IDLE_ELITE_SWIPE_SEQ_SKILL"))
	scene.set("current_screen", "skill")
	await scene.call("_navigation_shell").call("_render_screen")
	for _i in range(180):
		await process_frame
	var out_dir := OS.get_environment("IDLE_ELITE_SWIPE_SEQ_DIR")
	var direction := int(OS.get_environment("IDLE_ELITE_SWIPE_SEQ_DIRECTION"))
	await _capture("%s/00-rest.png" % out_dir)
	var start := Vector2(540.0 - float(direction) * 300.0, 800.0)
	var finish := start + Vector2(float(direction) * 640.0, 0.0)
	var down := InputEventScreenTouch.new()
	down.index = 0
	down.position = start
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var previous := start
	var steps := 24
	for step in range(1, steps + 1):
		var point := start.lerp(finish, float(step) / float(steps))
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = point
		drag.relative = point - previous
		drag.velocity = (point - previous) * 60.0
		root.push_input(drag, true)
		previous = point
		await process_frame
		if step in [6, 12, 18, 24]:
			await _capture("%s/%02d-drag-%s.png" % [out_dir, step / 6, step])
	var up := InputEventScreenTouch.new()
	up.index = 0
	up.position = finish
	up.pressed = false
	root.push_input(up, true)
	for index in range(12):
		for _i in range(5):
			await process_frame
		await _capture("%s/%02d-after-%s.png" % [out_dir, 10 + index, (index + 1) * 5])
	print("selected=%s" % str(scene.get("selected_skill_id")))
	scene.queue_free()
	quit(0)


func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png(path)
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/skill-swipe-sequence-script/capture_skill_swipe_sequence.gd" 2>&1 | Write-Output
    $captured = @(Get-ChildItem -LiteralPath $OutputDir -Filter "*.png")
    Assert-True ($captured.Count -ge 10) "Swipe sequence capture produced too few frames."
    Write-Output "skill-swipe-sequence-ok frames=$($captured.Count) dir=$OutputDir"
} finally {
    foreach ($name in $previous.Keys) {
        if ($null -eq $previous[$name]) {
            Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
        } else {
            Set-Item "Env:\$name" $previous[$name]
        }
    }
}
