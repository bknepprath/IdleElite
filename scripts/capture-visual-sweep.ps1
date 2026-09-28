# Visual QA sweep: boots the real game visibly at 1080x1920 from a sandboxed copy of a save,
# scrolls every skill page top to bottom, opens tier menus and every overlay, optionally in dark
# mode, and saves one PNG per frame. Save writes are disabled; the source save is never modified.
param(
    [Parameter(Mandatory = $true)][string]$OutputDir,
    [string]$SeedSave = "",
    [switch]$DarkMode,
    [int]$ScrollStep = 1100
)
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$scriptDir = Join-Path $projectRoot ".codex-tmp\visual-sweep-script"
$scriptPath = Join-Path $scriptDir "capture_visual_sweep.gd"
New-Item -ItemType Directory -Force -Path $OutputDir, $scriptDir | Out-Null
Get-ChildItem -LiteralPath $OutputDir -Filter "*.png" -ErrorAction SilentlyContinue | Remove-Item -Force

$previous = @{
    GODOT_RUN_TIMEOUT_SECONDS = $env:GODOT_RUN_TIMEOUT_SECONDS
    IDLE_ELITE_SWEEP_DIR = $env:IDLE_ELITE_SWEEP_DIR
    IDLE_ELITE_SWEEP_DARK = $env:IDLE_ELITE_SWEEP_DARK
    IDLE_ELITE_SWEEP_STEP = $env:IDLE_ELITE_SWEEP_STEP
    IDLE_ELITE_SWEEP_SEEDED = $env:IDLE_ELITE_SWEEP_SEEDED
    IDLE_ELITE_TEST_USER_DATA_DIR = $env:IDLE_ELITE_TEST_USER_DATA_DIR
}
try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "900"
    $env:IDLE_ELITE_SWEEP_DIR = (Resolve-Path -LiteralPath $OutputDir).Path
    $env:IDLE_ELITE_SWEEP_DARK = if ($DarkMode) { "1" } else { "0" }
    $env:IDLE_ELITE_SWEEP_STEP = "$ScrollStep"
    $env:IDLE_ELITE_SWEEP_SEEDED = "0"
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-visual-sweep-" + [guid]::NewGuid().ToString("N"))
    if ($SeedSave) {
        $sandboxSaveDir = Join-Path $env:IDLE_ELITE_TEST_USER_DATA_DIR "Godot\app_userdata\Idle Elite"
        New-Item -ItemType Directory -Force -Path $sandboxSaveDir | Out-Null
        Copy-Item -LiteralPath $SeedSave -Destination (Join-Path $sandboxSaveDir "idle_elite_save.json")
        $env:IDLE_ELITE_SWEEP_SEEDED = "1"
    }
    @'
extends SceneTree

const CAPTURE_SIZE := Vector2i(1080, 1920)
var out_dir := ""
var shot_index := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = CAPTURE_SIZE
	root.size = CAPTURE_SIZE
	DisplayServer.window_set_size(CAPTURE_SIZE)
	out_dir = OS.get_environment("IDLE_ELITE_SWEEP_DIR")
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
	await _settle(60)
	# First real frame as a player sees it, before anything is dismissed.
	await _shot("first-frame")
	var overlays = scene.call("_achievement_overlay_surface")
	if overlays.has_method("_close_offline_summary_overlay"):
		overlays.call("_close_offline_summary_overlay")
	if OS.get_environment("IDLE_ELITE_SWEEP_DARK") == "1":
		if not bool(scene.get("dark_mode_enabled")):
			scene.call("_settings_surface").call("toggle_dark_mode_enabled")
	await _settle(30)
	var step := int(OS.get_environment("IDLE_ELITE_SWEEP_STEP"))
	for skill_id in ["fight", "thieving", "build", "woodcutting", "fishing"]:
		scene.set("selected_skill_id", skill_id)
		scene.set("current_screen", "skill")
		await scene.call("_navigation_shell").call("_render_screen")
		await _settle(90)
		var detail = scene.call("_skill_detail_surface")
		var scroll = detail.get("detail_actions_scroll")
		var y := 0
		for page in range(14):
			if scroll != null:
				scroll.scroll_vertical = y
				scroll.set("drag_scroll_position", float(y))
			await _settle(40)
			await _shot("%s-scroll-%02d" % [skill_id, page])
			if scroll == null:
				break
			var max_scroll := int(scroll.get_v_scroll_bar().max_value - scroll.size.y)
			if y >= max_scroll:
				break
			y = mini(y + step, max_scroll)
		# Open the first on-screen tier menu, if the page has one.
		var plaque := _find_meta(scene, "tier_banner_plaque_hit")
		if plaque != null and scroll != null:
			scroll.scroll_vertical = int(scroll.scroll_vertical + plaque.get_global_rect().position.y - 520.0)
			scroll.set("drag_scroll_position", float(scroll.scroll_vertical))
			await _settle(30)
			plaque = _find_meta(scene, "tier_banner_plaque_hit")
			if plaque != null:
				plaque.emit_signal("pressed")
				await _settle(40)
				await _shot("%s-tier-menu-open" % skill_id)
				plaque = _find_meta(scene, "tier_banner_plaque_hit")
				if plaque != null:
					plaque.emit_signal("pressed")
					await _settle(20)
	for screen in ["menu", "hub", "leaderboard", "settings", "shop", "queue"]:
		scene.set("current_screen", screen)
		await scene.call("_navigation_shell").call("_render_screen")
		await _settle(60)
		await _shot("screen-%s" % screen)
	scene.set("current_screen", "menu")
	await scene.call("_navigation_shell").call("_render_screen")
	await _settle(40)
	var chat = scene.call("_profile_chat_overlay_surface")
	chat.call("_open_chat_overlay")
	await _settle(40)
	await _shot("overlay-chat")
	chat.call("_close_chat_overlay", false)
	chat.call("open_profile_overlay")
	await _settle(40)
	await _shot("overlay-profile")
	chat.call("_hide_profile_overlay")
	overlays.call("_open_achievements_overlay")
	await _settle(50)
	await _shot("overlay-achievements")
	if overlays.has_method("_close_achievements_overlay"):
		overlays.call("_close_achievements_overlay")
	await _settle(20)
	print("visual-sweep-ok shots=%s" % shot_index)
	scene.queue_free()
	quit(0)


func _find_meta(node: Node, meta_key: String) -> Control:
	if node is Control and bool(node.get_meta(meta_key, false)) and (node as Control).is_visible_in_tree():
		var rect := (node as Control).get_global_rect()
		if rect.position.x >= 0.0 and rect.position.x < 540.0:
			return node as Control
	for child in node.get_children():
		var found := _find_meta(child, meta_key)
		if found != null:
			return found
	return null


func _settle(frames: int) -> void:
	for _i in range(frames):
		await process_frame


func _shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image != null and not image.is_empty():
		shot_index += 1
		image.save_png("%s/%03d-%s.png" % [out_dir, shot_index, label])
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/visual-sweep-script/capture_visual_sweep.gd" 2>&1 | Out-Null
    $count = @(Get-ChildItem -LiteralPath $OutputDir -Filter "*.png").Count
    Assert-True ($count -ge 10) "Visual sweep produced only $count frames."
    Write-Output "visual-sweep-ok frames=$count dir=$OutputDir"
} finally {
    foreach ($name in $previous.Keys) {
        if ($null -eq $previous[$name]) {
            Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
        } else {
            Set-Item "Env:\$name" $previous[$name]
        }
    }
}
