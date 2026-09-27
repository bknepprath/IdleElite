# Boots the real game visibly at the phone viewport, unlocks a late-game test
# state, walks every main screen and overlay, and saves one raw PNG per screen.
# Save writes are disabled and user:// is sandboxed, so no real save is touched.
param(
    [string]$OutputDir = "",
    # Copy of an existing save to start from; copied into the sandbox, never modified.
    [string]$SeedSave = (Join-Path $env:APPDATA "Godot\app_userdata\Idle Elite\idle_elite_save.json"),
    [string]$Screens = "menu,skill:fight,skill:woodcutting,skill:fishing,skill:thieving,skill:build,hub,leaderboard,settings,shop,queue,chat,profile,achievements"
)
$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
if (-not $OutputDir) {
    $OutputDir = Join-Path $projectRoot ".codex-tmp\screen-audit"
}
$scriptDir = Join-Path $projectRoot ".codex-tmp\screen-audit-script"
$scriptPath = Join-Path $scriptDir "capture_screen_audit.gd"
New-Item -ItemType Directory -Path $OutputDir, $scriptDir -Force | Out-Null

$previous = @{
    GODOT_RUN_TIMEOUT_SECONDS = $env:GODOT_RUN_TIMEOUT_SECONDS
    IDLE_ELITE_SCREEN_AUDIT_DIR = $env:IDLE_ELITE_SCREEN_AUDIT_DIR
    IDLE_ELITE_SCREEN_AUDIT_SCREENS = $env:IDLE_ELITE_SCREEN_AUDIT_SCREENS
    IDLE_ELITE_TEST_USER_DATA_DIR = $env:IDLE_ELITE_TEST_USER_DATA_DIR
    IDLE_ELITE_SCREEN_AUDIT_SEEDED = $env:IDLE_ELITE_SCREEN_AUDIT_SEEDED
}
try {
    $env:GODOT_RUN_TIMEOUT_SECONDS = "420"
    $env:IDLE_ELITE_SCREEN_AUDIT_DIR = (Resolve-Path -LiteralPath $OutputDir).Path
    $env:IDLE_ELITE_SCREEN_AUDIT_SCREENS = $Screens
    $env:IDLE_ELITE_TEST_USER_DATA_DIR = Join-Path ([IO.Path]::GetTempPath()) ("idle-elite-screen-audit-" + [guid]::NewGuid().ToString("N"))
    $env:IDLE_ELITE_SCREEN_AUDIT_SEEDED = "0"
    if ($SeedSave -and (Test-Path -LiteralPath $SeedSave)) {
        $sandboxSaveDir = Join-Path $env:IDLE_ELITE_TEST_USER_DATA_DIR "Godot\app_userdata\Idle Elite"
        New-Item -ItemType Directory -Path $sandboxSaveDir -Force | Out-Null
        Copy-Item -LiteralPath $SeedSave -Destination (Join-Path $sandboxSaveDir "idle_elite_save.json")
        $env:IDLE_ELITE_SCREEN_AUDIT_SEEDED = "1"
    }
    @'
extends SceneTree

const CAPTURE_SIZE := Vector2i(1080, 1920)
var failures: Array[String] = []


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
	if not await _wait_for_boot_ready(scene):
		_fail("main scene did not become ready")
		return
	if OS.get_environment("IDLE_ELITE_SCREEN_AUDIT_SEEDED") != "1":
		scene.call("_test_state_runtime").call("_apply_art_review_test_unlock_all_state")
	await _settle(30)
	_silence_backlog_toasts(scene)
	_hide_boot_overlays(scene)
	_seed_chat(scene)
	var out_dir := OS.get_environment("IDLE_ELITE_SCREEN_AUDIT_DIR")
	for raw_screen in OS.get_environment("IDLE_ELITE_SCREEN_AUDIT_SCREENS").split(",", false):
		var screen := str(raw_screen).strip_edges()
		await _show(scene, screen)
		_hide_boot_overlays(scene)
		await _settle(30)
		await _capture("%s/%s.png" % [out_dir, screen.replace(":", "-")])
		await _hide_overlays(scene)
	scene.queue_free()
	if failures.is_empty():
		print("screen-audit-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _show(scene: Node, screen: String) -> void:
	var nav = scene.call("_navigation_shell")
	if screen.begins_with("skill:"):
		scene.set("selected_skill_id", screen.substr(6))
		scene.set("current_screen", "skill")
	elif screen in ["chat", "profile", "achievements"]:
		scene.set("current_screen", "menu")
	else:
		scene.set("current_screen", screen)
	nav.call("_render_screen", false, -1, false)
	await _settle(20)
	match screen:
		"chat":
			scene.call("_profile_chat_overlay_surface").call("_open_chat_overlay")
		"profile":
			scene.call("_profile_chat_overlay_surface").call("open_profile_overlay")
		"achievements":
			scene.call("_achievement_overlay_surface").call("_open_achievements_overlay")


func _hide_overlays(scene: Node) -> void:
	var chat_surface = scene.call("_profile_chat_overlay_surface")
	chat_surface.call("_close_chat_overlay", false)
	chat_surface.call("_hide_profile_overlay")
	var achievements = scene.call("_achievement_overlay_surface")
	if achievements.has_method("_close_achievements_overlay"):
		achievements.call("_close_achievements_overlay")
	await _settle(10)


func _silence_backlog_toasts(scene: Node) -> void:
	# Script-edited dev saves can be max level with no toasts ever seen; mark the
	# backlog seen so captures show the screens, not a queue of old milestones.
	var AchievementState = load("res://scripts/achievements/state.gd")
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(scene, false), scene.call("_save_runtime").achievement_toast_seen_ids, [])
	var toasts = scene.call("_achievement_toast_surface")
	toasts.achievement_toast_queue.clear()
	toasts.achievement_toast_queue_ids.clear()
	for toast in toasts.achievement_toasts:
		if is_instance_valid(toast):
			toast.queue_free()
	toasts.achievement_toasts.clear()


func _hide_boot_overlays(scene: Node) -> void:
	scene.call("_boot_warmup_runtime").call("_dismiss_boot_splash_for_play")
	scene.set("boot_warmup_active", false)
	for property_name in ["boot_warmup_overlay", "offline_summary_overlay", "achievement_toast_layer", "achievement_toast_root", "page_transition_cover"]:
		var item := scene.get(property_name) as CanvasItem
		if item != null:
			item.visible = false
	var warmup = scene.call("_boot_warmup_runtime")
	for property_name in ["overlay", "layer"]:
		var node = warmup.get(property_name)
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		elif node is CanvasLayer:
			(node as CanvasLayer).visible = false


func _seed_chat(scene: Node) -> void:
	var online = scene.call("_online_runtime")
	var now := int(Time.get_unix_time_from_system())
	var messages := [
		["Rowan", "anyone else stuck on the rooster fight?"],
		["Mika", "yes!! need more stamina first"],
		["Blue Guy Fan", "fishing 60 took me forever lol"],
		["Rowan", "the new firepit is so good for offline"],
		["Tess", "how do you get the reinforced rod? I have been fishing for ages and still nothing"],
		["Mika", "gg"],
	]
	var data := {}
	for index in range(messages.size()):
		data["m%03d" % index] = {
			"sender_id": "screenaudit%02d" % index,
			"name": messages[index][0],
			"name_key": str(messages[index][0]).to_lower().replace(" ", "_"),
			"total_level": 120 + index * 7,
			"avatar_index": index,
			"text": messages[index][1],
			"created_at": (now - 600 + index * 60) * 1000,
			"created_at_unix": now - 600 + index * 60,
		}
	online.call("_chat_replace_rows", data)


func _settle(frames: int) -> void:
	for _frame in range(frames):
		await process_frame


func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		failures.append("empty capture for %s" % path)
		return
	if image.get_size() != CAPTURE_SIZE:
		failures.append("capture size %s for %s" % [image.get_size(), path])
		return
	image.save_png(path)
	print("screen-audit-capture %s" % path)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _i in range(600):
		if bool(scene.get("startup_initialized")) and bool(scene.get("save_restore_complete")):
			return true
		await process_frame
	return false


func _fail(message: String) -> void:
	push_error("screen-audit-failed: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $scriptPath -Encoding UTF8

    $startedAt = Get-Date
    # Visible runs do not relay game stdout, so success is judged by fresh PNGs.
    & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/screen-audit-script/capture_screen_audit.gd" 2>&1 | Write-Output
    $expected = @($Screens.Split(",") | ForEach-Object { Join-Path $OutputDir ($_.Trim().Replace(":", "-") + ".png") })
    $missing = @($expected | Where-Object { -not (Test-Path -LiteralPath $_) -or (Get-Item -LiteralPath $_).LastWriteTime -lt $startedAt })
    Assert-True ($missing.Count -eq 0) "Screen audit did not produce: $($missing -join ', ')"
    Write-Output "screen-audit-ok dir=$OutputDir"
} finally {
    foreach ($name in $previous.Keys) {
        if ($null -eq $previous[$name]) {
            Remove-Item "Env:\$name" -ErrorAction SilentlyContinue
        } else {
            Set-Item "Env:\$name" $previous[$name]
        }
    }
}
