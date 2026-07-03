$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$testDir = Join-Path $projectRoot ".codex-tmp\skill-swipe-no-preview-flash"
$testScript = Join-Path $testDir "skill_swipe_no_preview_flash_test.gd"
New-Item -ItemType Directory -Force -Path $testDir | Out-Null

@'
extends SceneTree

const MAIN_SCENE := "res://scenes/main.tscn"

var _failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("skill-swipe-no-preview-flash-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load(MAIN_SCENE) as PackedScene
	if packed == null:
		_fail("missing main scene")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	await _wait_frames(180)
	_prepare_swipe_state(scene)
	await _wait_frames(8)
	scene.call("_begin_skill_swipe_tracking", Vector2(900, 1500), -1)
	for i in range(1, 7):
		var t := float(i) / 6.0
		scene.call("_update_skill_swipe_feedback", Vector2(900, 1500).lerp(Vector2(260, 1500), t))
		await _wait_frames(1)
		_assert_drag_frame(scene, i)
	scene.call("_finish_skill_swipe", Vector2(260, 1500))
	await _wait_until_settled(scene, 180)
	if not _failed:
		print("skill-swipe-no-preview-flash-ok")
	quit(1 if _failed else 0)

func _prepare_swipe_state(scene: Node) -> void:
	scene.set("onboarding_active", false)
	scene.set("onboarding_swipe_navigation_unlocked", true)
	scene.set("onboarding_swipe_tip_eligible", true)
	scene.set("skill_swipe_tip_seen", true)
	scene.set("selected_skill_id", "build")
	scene.set("current_screen", "skill")
	scene.call("_render_screen")

func _assert_drag_frame(scene: Node, frame_index: int) -> void:
	var page := _valid_control(scene.get("skill_swipe_page"))
	if page == null:
		_fail("missing real swipe page during drag frame %s" % frame_index)
		return
	if page.modulate.a < 0.995:
		_fail("real swipe page faded during drag frame %s alpha=%.3f" % [frame_index, page.modulate.a])
		return
	var preview := _valid_control(scene.call("_skill_swipe_activity_surface").get("preview_page"))
	if preview != null and preview.visible and preview.modulate.a > 0.01:
		_fail("lightweight preview became visible during drag frame %s alpha=%.3f" % [frame_index, preview.modulate.a])
		return

func _wait_until_settled(scene: Node, max_frames: int) -> void:
	for i in range(max_frames):
		await _wait_frames(1)
		if not bool(scene.get("skill_swipe_animating")) and not bool(scene.get("skill_swipe_tracking")) and str(scene.get("selected_skill_id")) == "woodcutting":
			return
	_fail("swipe did not settle on woodcutting")

func _valid_control(value) -> Control:
	if value == null or typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value as Control

func _wait_frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _fail(message: String) -> void:
	if _failed:
		return
	_failed = true
	push_error("skill-swipe-no-preview-flash-fail: %s" % message)
	quit(1)
'@ | Set-Content -Path $testScript -Encoding UTF8

$output = & "$projectRoot\run-godot-safe.ps1" --path "$projectRoot" --headless --script $testScript 2>&1
$output | ForEach-Object { Write-Output $_ }

if (($output -join "`n") -notmatch "skill-swipe-no-preview-flash-ok") {
    throw "Skill swipe no-preview-flash test did not report success."
}

$godotProcesses = Get-CimInstance Win32_Process -Filter "name like 'Godot%'" | Where-Object { $_.CommandLine -match [regex]::Escape($testScript) }
if ($godotProcesses) {
    throw "A headless Godot process is still running after the skill swipe no-preview-flash test."
}
