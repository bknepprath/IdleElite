param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$captureDir = Join-Path $projectRoot ".codex-tmp\fight-modules"
$captureScript = Join-Path $captureDir "capture_fight_modules_layout.gd"
$screenshot = Join-Path $captureDir "fight-modules-layout-real-builder-desktop-627x1115.png"

New-Item -ItemType Directory -Path $captureDir -Force | Out-Null

@"
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const OUT_PATH := "res://.codex-tmp/fight-modules/fight-modules-layout-real-builder-desktop-627x1115.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var capture_size := Vector2i(2160, 3840)
	var window_size := Vector2i(627, 1115)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = capture_size
	root.size = window_size
	DisplayServer.window_set_size(window_size)
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("main scene did not load")
		quit(1)
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		push_error("main scene did not become capture-ready")
		quit(1)
		return
	_hide_capture_overlays(scene)
	_unlock_for_capture(scene)
	var stage := Control.new()
	stage.name = "FightModulesLayoutCaptureStage"
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.z_index = 5000
	stage.z_as_relative = false
	root.add_child(stage)
	var bg := ColorRect.new()
	bg.color = Color("#f4ead8")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.add_child(bg)
	var ids := [
		"wrap-hands",
		"chicken-sparring-pit",
		"duel-leaning-fence-post",
		"face-the-rooster"
	]
	var y := 120.0
	for action_id in ids:
		var action := scene.call("_action_data", "fight", action_id) as Dictionary
		if action.is_empty():
			continue
		if action_id == "chicken-sparring-pit":
			scene.set("running_skill_id", "fight")
			scene.set("running_action_id", action_id)
			scene.set("action_progress", 0.43)
		else:
			scene.set("running_skill_id", "")
			scene.set("running_action_id", "")
			scene.set("action_progress", 0.0)
		var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1900.0, 1900.0) as Dictionary
		var card_root := built.get("card_root") as Control
		if card_root == null:
			push_error("%s card root did not build" % action_id)
			continue
		card_root.position = Vector2(130, y)
		card_root.size.x = 1900.0
		stage.add_child(card_root)
		await process_frame
		var height := maxf(card_root.custom_minimum_size.y, card_root.size.y)
		if height <= 0.0:
			height = 760.0
		y += height + 70.0
	scene.visible = false
	for _frame in range(80):
		_hide_capture_overlays(scene)
		await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() == "headless":
		print("fight-modules-layout-capture skipped=headless")
		quit(0)
		return
	var texture := root.get_texture()
	if texture == null:
		push_error("capture texture missing")
		quit(1)
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		push_error("capture image empty")
		quit(1)
		return
	var err := image.save_png(OUT_PATH)
	if err != OK:
		push_error("failed to save screenshot: %s" % err)
		quit(1)
		return
	print("fight-modules-layout-screenshot=%s" % ProjectSettings.globalize_path(OUT_PATH))
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
	for property_name in ["boot_splash_overlay", "boot_warmup_overlay", "offline_summary_overlay", "achievements_overlay", "achievement_toast_layer", "achievement_toast_root", "page_transition_cover"]:
		var item := scene.get(property_name) as CanvasItem
		if item != null:
			item.visible = false
	for toast in scene.get("achievement_toasts"):
		var toast_item := toast as CanvasItem
		if toast_item != null:
			toast_item.visible = false

func _unlock_for_capture(scene: Node) -> void:
	for raw_skill_id in (scene.skills as Dictionary).keys():
		var skill := scene.skills[raw_skill_id] as Dictionary
		skill["level"] = 30
		skill["xp"] = maxi(int(skill.get("xp", 0)), SkillState.xp_for_level(30))
		scene.skills[raw_skill_id] = skill
	var fight_actions := (scene.get("actions_by_skill") as Dictionary).get("fight", []) as Array
	for action in fight_actions:
		var action_id := str((action as Dictionary).get("id", ""))
		if not action_id.is_empty():
			scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", action_id, "fight module layout capture")
	scene.stamina["fight"] = 999.0
	scene.completed_bosses["rooster"] = true
	scene.completed_bosses["chicken"] = true
	if scene.has_method("_sync_stamina_bank"):
		scene.call("_sync_stamina_bank", "fight")
"@ | Set-Content -LiteralPath $captureScript -Encoding UTF8

if (Test-Path -LiteralPath $screenshot) {
	Remove-Item -LiteralPath $screenshot -Force
}

$output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/fight-modules/capture_fight_modules_layout.gd" 2>&1
$output | Write-Output
if (-not (Test-Path -LiteralPath $screenshot)) {
	throw "Fight modules layout screenshot was not created."
}
$resolved = (Resolve-Path $screenshot).Path
Write-Output "Screenshot: $resolved"
