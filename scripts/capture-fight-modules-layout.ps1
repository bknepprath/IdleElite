param()

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$captureDir = Join-Path $projectRoot ".codex-tmp\fight-modules"
$captureScript = Join-Path $captureDir "capture_fight_modules_layout.gd"
$screenshot = Join-Path $captureDir "fight-modules-layout-real-builder-1080x1920.png"
$pressedScreenshot = Join-Path $captureDir "fight-modules-layout-top-down-pressed-1080x1920.png"

New-Item -ItemType Directory -Path $captureDir -Force | Out-Null

@"
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const OUT_PATH := "res://.codex-tmp/fight-modules/fight-modules-layout-real-builder-1080x1920.png"
const PRESSED_OUT_PATH := "res://.codex-tmp/fight-modules/fight-modules-layout-top-down-pressed-1080x1920.png"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var capture_size := Vector2i(1080, 1920)
	var window_size := capture_size
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
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
	var cards_clip := Control.new()
	cards_clip.name = "FightModulesActualActionsClip"
	cards_clip.position = Vector2(48, 0)
	cards_clip.size = Vector2(984, 1920)
	cards_clip.clip_contents = true
	stage.add_child(cards_clip)
	var ids := [
		"push-ups",
		"chicken-sparring-pit",
		"duel-leaning-fence-post",
		"face-the-rooster"
	]
	var y := 60.0
	var push_ups_card: Control = null
	var push_ups_pop: Control = null
	var push_ups_progress: Control = null
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
		var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 984.0, 984.0) as Dictionary
		var card_root := built.get("card_root") as Control
		if card_root == null:
			push_error("%s card root did not build" % action_id)
			continue
		card_root.position = Vector2(0, y)
		card_root.size.x = 984.0
		cards_clip.add_child(card_root)
		if action_id == "push-ups":
			push_ups_card = card_root
			push_ups_pop = card_root.find_child("ActivityCardFace", true, false) as Control
			push_ups_progress = (built.get("card", {}) as Dictionary).get("progress") as Control
			if push_ups_progress != null:
				push_ups_progress.call("set_value", 100.0)
		await process_frame
		var height := maxf(card_root.custom_minimum_size.y, card_root.size.y)
		if height <= 0.0:
			height = 380.0
		y += height + 35.0
	if not _validate_push_ups_card(push_ups_card, cards_clip):
		quit(1)
		return
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
	if push_ups_progress != null:
		push_ups_progress.call("set_value", 32.0)
		await process_frame
	if not await _capture_pressed_push_ups(scene, push_ups_card, push_ups_pop):
		quit(1)
		return
	quit(0)

func _capture_pressed_push_ups(scene: Node, card_root: Control, pop: Control) -> bool:
	if card_root == null or pop == null:
		push_error("Push-Ups pressed capture is missing the card face")
		return false
	var back_face := card_root.find_child("NormalActivityCardBackFace", true, false) as Control
	var connectors := card_root.find_child("NormalActivityCardPrismConnectors", true, false) as Control
	var back_before := back_face.get_global_rect()
	var face_before := pop.get_global_rect()
	var depth_id := int(pop.get_meta("activity_card_depth_node_id", 0))
	var depth := instance_from_id(depth_id) as Control
	if depth == null:
		push_error("Push-Ups pressed capture could not resolve the depth control")
		return false
	var activity_surface = scene.call("_skill_swipe_activity_surface")
	var staged_key := "__capture_push_ups_press__"
	var staged_card := {"pop": pop, "depth": depth, "card_key": staged_key}
	var press_offset := activity_surface.call("_action_card_press_offset", staged_card) as Vector2
	if not press_offset.is_equal_approx(Vector2(0.0, 36.0)):
		push_error("Push-Ups press helper returned the wrong direction: %s" % press_offset)
		return false
	(scene.get("action_cards") as Dictionary)[staged_key] = staged_card
	activity_surface.call("_animate_action_card_3d_click", staged_key)
	await create_timer(0.12).timeout
	for _frame in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	if not back_face.get_global_rect().is_equal_approx(back_before):
		push_error("Push-Ups base moved during the press animation")
		return false
	var face_delta := pop.get_global_rect().position - face_before.position
	if not face_delta.is_equal_approx(Vector2(0.0, 36.0)):
		push_error("Push-Ups face did not press straight down: %s" % face_delta)
		return false
	if not (connectors.get("face_offset") as Vector2).is_equal_approx(Vector2(0.0, 36.0)):
		push_error("Push-Ups depth did not compress with the face")
		return false
	var pressed_image := root.get_texture().get_image()
	if pressed_image == null or pressed_image.is_empty() or pressed_image.save_png(PRESSED_OUT_PATH) != OK:
		push_error("failed to save pressed Push-Ups screenshot")
		return false
	await create_timer(0.20).timeout
	for _frame in range(2):
		await process_frame
	if not pop.get_global_rect().is_equal_approx(face_before) or not back_face.get_global_rect().is_equal_approx(back_before):
		push_error("Push-Ups release did not return the face while keeping the base stationary")
		return false
	(scene.get("action_cards") as Dictionary).erase(staged_key)
	await create_timer(0.1).timeout
	print("push-ups-press-geometry-ok face_delta=%s remaining_depth=0.0 base_stationary=true quick_tap_completed=true release_returned=true" % face_delta)
	return true

func _validate_push_ups_card(card_root: Control, cards_clip: Control) -> bool:
	if card_root == null:
		push_error("Push-Ups card was not captured")
		return false
	var back_face := card_root.find_child("NormalActivityCardBackFace", true, false) as Panel
	var connectors := card_root.find_child("NormalActivityCardPrismConnectors", true, false) as Control
	if back_face == null or connectors == null:
		push_error("Push-Ups prism nodes were not rendered")
		return false
	var style := back_face.get_theme_stylebox("panel") as StyleBoxFlat
	var shadow_right := back_face.get_global_rect().end.x + style.shadow_size + maxf(0.0, style.shadow_offset.x)
	var clip_right := cards_clip.get_global_rect().end.x
	var points := connectors.call("_connector_points") as PackedVector2Array
	var front_origin := connectors.call("_connector_face_origin") as Vector2
	var front_size := connectors.call("_connector_face_size") as Vector2
	var back_origin := front_origin + (connectors.get("depth_offset") as Vector2)
	var back_size := front_size
	if shadow_right >= clip_right:
		push_error("Push-Ups shadow reaches the actions clip: %.1f >= %.1f" % [shadow_right, clip_right])
		return false
	if points.size() != 2:
		push_error("Push-Ups card did not render both prism connectors")
		return false
	if back_origin.x > front_origin.x + 0.01 or back_origin.x + back_size.x < front_origin.x + front_size.x - 0.01:
		push_error("Push-Ups front plate overhangs its base")
		return false
	var right_perspective := back_origin.x + back_size.x - front_origin.x - front_size.x
	if absf(right_perspective) > 0.01:
		push_error("Push-Ups top-view face and base widths do not match: %.1f" % right_perspective)
		return false
	print("push-ups-card-geometry-ok shadow_right=%.1f clip_right=%.1f connectors=%d top_view_depth=%.1f" % [shadow_right, clip_right, points.size(), (connectors.get("depth_offset") as Vector2).y])
	return true

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
	var achievement_toasts = scene.get("achievement_toasts")
	if achievement_toasts is Array:
		for toast in achievement_toasts:
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

function Test-CaptureCompleteness {
    param([Parameter(Mandatory = $true)][string]$Path)

    Add-Type -AssemblyName System.Drawing
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Path).Path)
        if ($bitmap.Width -ne 627 -or $bitmap.Height -ne 1115) {
            throw "Capture dimensions were $($bitmap.Width)x$($bitmap.Height), expected 627x1115."
        }
        $columns = 48
        $rows = 84
        $sampleCount = 0
        $transparentCount = 0
        $nearBlackCount = 0
        for ($row = 0; $row -lt $rows; $row++) {
            $y = [int][Math]::Round(($bitmap.Height - 1) * $row / ($rows - 1))
            for ($column = 0; $column -lt $columns; $column++) {
                $x = [int][Math]::Round(($bitmap.Width - 1) * $column / ($columns - 1))
                $pixel = $bitmap.GetPixel($x, $y)
                $sampleCount++
                if ($pixel.A -lt 255) {
                    $transparentCount++
                }
                if ($pixel.A -eq 255 -and $pixel.R -le 35 -and $pixel.G -le 35 -and $pixel.B -le 35) {
                    $nearBlackCount++
                }
            }
        }
        $nearBlackRatio = $nearBlackCount / [double]$sampleCount
        Write-Output ("Capture metrics: {0}x{1} samples={2} transparent={3} near-black={4:P2}" -f $bitmap.Width, $bitmap.Height, $sampleCount, $transparentCount, $nearBlackRatio)
        if ($transparentCount -gt 0) {
            throw "Capture contains $transparentCount sampled transparent pixels."
        }
        if ($nearBlackRatio -gt 0.15) {
            throw "Capture near-black sample ratio $nearBlackRatio exceeds 0.15."
        }
    } finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

if (Test-Path -LiteralPath $screenshot) {
	Remove-Item -LiteralPath $screenshot -Force
}
if (Test-Path -LiteralPath $pressedScreenshot) {
	Remove-Item -LiteralPath $pressedScreenshot -Force
}

$output = & $runner --visible-game --path $projectRoot --script "res://.codex-tmp/fight-modules/capture_fight_modules_layout.gd" 2>&1
$output | Write-Output
if ($LASTEXITCODE -ne 0) {
	throw "Fight modules capture exited with code $LASTEXITCODE."
}
if ($output -notmatch "push-ups-card-geometry-ok") {
	throw "Capture did not verify the Push-Ups prism geometry."
}
if ($output -notmatch "push-ups-press-geometry-ok") {
	throw "Capture did not verify the Push-Ups downward press geometry."
}
if (-not (Test-Path -LiteralPath $screenshot)) {
	throw "Fight modules layout screenshot was not created."
}
Test-CaptureCompleteness $screenshot
if (-not (Test-Path -LiteralPath $pressedScreenshot)) {
	throw "Pressed Push-Ups screenshot was not created."
}
Test-CaptureCompleteness $pressedScreenshot
$resolved = (Resolve-Path $screenshot).Path
Write-Output "Screenshot: $resolved"
