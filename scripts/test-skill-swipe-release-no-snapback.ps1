$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$testDir = Join-Path $projectRoot ".codex-tmp\skill-swipe-release-no-snapback"
$testScript = Join-Path $testDir "skill_swipe_release_no_snapback_test.gd"
$testLog = Join-Path $testDir "godot.log"
New-Item -ItemType Directory -Force -Path $testDir | Out-Null

@'
extends SceneTree

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("skill-swipe-release-no-snapback-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	await _wait_frames(180)
	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_max_skills_state()
	scene.set("selected_skill_id", "build")
	scene.set("current_screen", "skill")
	scene.call("_navigation_shell").call("_render_screen")
	await _wait_frames(12)

	scene.call("_skill_swipe_activity_surface").call("_begin_skill_swipe_tracking", Vector2(900, 1500), -1)
	# A short, deliberate flick should commit even though it does not cross the
	# full distance threshold. This is the common phone gesture that previously
	# moved the page and then snapped it back on release.
	for i in range(1, 4):
		scene.call("_skill_swipe_activity_surface").call("_update_skill_swipe_feedback", Vector2(900, 1500).lerp(Vector2(720, 1500), float(i) / 3.0))
		await _wait_frames(1)
	scene.call("_skill_swipe_activity_surface").call("_finish_skill_swipe", Vector2(720, 1500))
	for frame in range(60):
		await _wait_frames(1)
		var cover := _valid_control(scene.call("_skill_swipe_activity_surface").get("skill_swipe_handoff_cover"))
		if cover == null:
			continue
		var holder_id := int(cover.get_meta("swipe_outgoing_page_holder_id", 0))
		var holder := _valid_control(instance_from_id(holder_id))
		if holder == null:
			continue
		var canvas_size := scene.call("_current_canvas_size") as Vector2
		var centered_x: float = (canvas_size.x - holder.size.x) * 0.5
		if absf(holder.position.x - centered_x) < 24.0:
			_fail("outgoing holder snapped back to center: holder_x=%.2f center_x=%.2f frame=%s" % [holder.position.x, centered_x, str(frame)])
			return
		if holder.position.x > centered_x - 120.0:
			_fail("outgoing holder did not remain left/offscreen after left swipe: holder_x=%.2f center_x=%.2f frame=%s" % [holder.position.x, centered_x, str(frame)])
			return
		print("skill-swipe-release-no-snapback-ok holder_x=%.2f center_x=%.2f frame=%s" % [holder.position.x, centered_x, str(frame)])
		quit(0)
	_fail("release handoff holder was not observed before transition settled")
	quit(0)

func _valid_control(value) -> Control:
	if value == null or typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value as Control

func _wait_frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error("skill-swipe-release-no-snapback-fail: %s" % message)
	quit(1)
'@ | Set-Content -Path $testScript -Encoding UTF8

$output = & "$projectRoot\run-godot-safe.ps1" --path "$projectRoot" --headless --log-file $testLog --script $testScript 2>&1
$output | ForEach-Object { Write-Output $_ }

if (($output -join "`n") -notmatch "skill-swipe-release-no-snapback-ok") {
    throw "Skill swipe release no-snapback test did not report success."
}

$godotProcesses = Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match [regex]::Escape($testScript) }
if ($godotProcesses) {
    throw "A headless Godot process is still running after the skill swipe release no-snapback test."
}
