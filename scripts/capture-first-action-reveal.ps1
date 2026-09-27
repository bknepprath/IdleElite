# Captures a frame sequence from a brand-new save through the first tutorial
# activity, so reveal/pop-in behavior can be judged frame by frame at 1080x1920.
param(
    [string]$OutputDir = "",
    [int]$Frames = 16,
    [int]$FrameStep = 12
)
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
if (-not $OutputDir) {
    $OutputDir = Join-Path $projectRoot ".codex-tmp\first-action-reveal"
}
$scriptDir = Join-Path $projectRoot ".codex-tmp\first-action-reveal-script"
$scriptPath = Join-Path $scriptDir "capture_first_action_reveal.gd"
New-Item -ItemType Directory -Path $OutputDir, $scriptDir -Force | Out-Null
Get-ChildItem -LiteralPath $OutputDir -Filter "*.png" -ErrorAction SilentlyContinue | Remove-Item -Force

$previous = @{
    GODOT_RUN_TIMEOUT_SECONDS = $env:GODOT_RUN_TIMEOUT_SECONDS
    IDLE_ELITE_REVEAL_DIR = $env:IDLE_ELITE_REVEAL_DIR
    IDLE_ELITE_REVEAL_FRAMES = $env:IDLE_ELITE_REVEAL_FRAMES
    IDLE_ELITE_REVEAL_STEP = $env:IDLE_ELITE_REVEAL_STEP
    IDLE_ELITE_TEST_USER_DATA_DIR = $env:IDLE_ELITE_TEST_USER_DATA_DIR
}
try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "300"
    $env:IDLE_ELITE_REVEAL_DIR = (Resolve-Path -LiteralPath $OutputDir).Path
    $env:IDLE_ELITE_REVEAL_FRAMES = "$Frames"
    $env:IDLE_ELITE_REVEAL_STEP = "$FrameStep"
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-first-action-" + [guid]::NewGuid().ToString("N"))
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
	# Let the boot splash finish on its own so the first real screen is shown.
	var warmup = scene.call("_boot_warmup_runtime")
	for _i in range(1800):
		if not bool(warmup.get("active")):
			break
		await process_frame
	for _i in range(150):
		await process_frame
	var out_dir := OS.get_environment("IDLE_ELITE_REVEAL_DIR")
	var frames := int(OS.get_environment("IDLE_ELITE_REVEAL_FRAMES"))
	var step := int(OS.get_environment("IDLE_ELITE_REVEAL_STEP"))
	await _capture("%s/00-before.png" % out_dir)
	scene.call("_action_runtime").call("_start_action", scene.TUTORIAL_STARTER_SKILL_ID, scene.TUTORIAL_STARTER_ACTION_ID, true, false)
	for index in range(frames):
		for _i in range(step):
			await process_frame
		await _capture("%s/%02d-after.png" % [out_dir, index + 1])
	scene.queue_free()
	quit(0)


func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image != null and not image.is_empty():
		image.save_png(path)
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/first-action-reveal-script/capture_first_action_reveal.gd" 2>&1 | Write-Output
    $captured = @(Get-ChildItem -LiteralPath $OutputDir -Filter "*.png")
    Assert-True ($captured.Count -ge 2) "First-action reveal capture produced no frames."
    Write-Output "first-action-reveal-ok frames=$($captured.Count) dir=$OutputDir"
} finally {
    foreach ($name in $previous.Keys) {
        if ($null -eq $previous[$name]) {
            Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
        } else {
            Set-Item "Env:\$name" $previous[$name]
        }
    }
}
