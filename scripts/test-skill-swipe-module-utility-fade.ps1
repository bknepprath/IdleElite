$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$testDir = Join-Path $projectRoot ".codex-tmp\skill-swipe-module-utility-fade"
$testScript = Join-Path $testDir "skill_swipe_module_utility_fade_test.gd"
New-Item -ItemType Directory -Force -Path $testDir | Out-Null

@'
extends SceneTree

var failed := false

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("skill-swipe-module-utility-fade-start")
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
	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_max_skills_state")
	scene.set("selected_skill_id", "build")
	scene.set("current_screen", "skill")
	scene.call("_render_screen")
	await _wait_frames(12)

	var utility_row := _valid_control(scene.get("module_utility_row"))
	if utility_row == null:
		_fail("module_utility_row missing")
		return
	if not utility_row.visible:
		_fail("module_utility_row not visible before swipe")
		return
	if utility_row.modulate.a < 0.98:
		_fail("module_utility_row did not start opaque: alpha=%.3f" % utility_row.modulate.a)
		return
	var shelf_background := _find_named_control(scene, "SkillDetailFullBleedShelfBackground")
	if shelf_background == null:
		_fail("skill shelf background missing before swipe")
		return
	if shelf_background.modulate.a < 0.98:
		_fail("skill shelf background did not start opaque: alpha=%.3f" % shelf_background.modulate.a)
		return

	scene.call("_begin_skill_swipe_tracking", Vector2(900, 1500), -1)
	for i in range(1, 7):
		scene.call("_update_skill_swipe_feedback", Vector2(900, 1500).lerp(Vector2(260, 1500), float(i) / 6.0))
		await _wait_frames(1)

	var drag_alpha := utility_row.modulate.a
	if drag_alpha < 0.98:
		_fail("module utility row faded before swipe release: alpha=%.3f" % drag_alpha)
		return
	var shelf_drag_alpha := shelf_background.modulate.a
	if shelf_drag_alpha < 0.98:
		_fail("skill shelf background faded before swipe release: alpha=%.3f" % shelf_drag_alpha)
		return

	scene.call("_finish_skill_swipe", Vector2(260, 1500))
	var release_min_alpha := utility_row.modulate.a
	var shelf_release_min_alpha := shelf_background.modulate.a
	var settled := false
	for i in range(240):
		await _wait_frames(1)
		release_min_alpha = minf(release_min_alpha, utility_row.modulate.a)
		if shelf_background != null and is_instance_valid(shelf_background):
			shelf_release_min_alpha = minf(shelf_release_min_alpha, shelf_background.modulate.a)
		if not bool(scene.get("skill_swipe_animating")) and not bool(scene.get("skill_swipe_tracking")) and str(scene.get("selected_skill_id")) == "woodcutting":
			settled = true
			break
	if not settled:
		_fail("swipe did not settle on woodcutting")
		return
	if release_min_alpha > 0.22:
		_fail("module utility row did not fade out after swipe release: min_alpha=%.3f" % release_min_alpha)
		return
	if shelf_release_min_alpha > 0.22:
		_fail("skill shelf background did not fade out after swipe release: min_alpha=%.3f" % shelf_release_min_alpha)
		return
	var target_shelf_background := _find_named_control(scene, "SkillDetailFullBleedShelfBackground")
	for i in range(180):
		target_shelf_background = _find_named_control(scene, "SkillDetailFullBleedShelfBackground")
		var shelf_final_alpha := 0.0 if target_shelf_background == null else target_shelf_background.modulate.a
		if utility_row.modulate.a >= 0.96 and shelf_final_alpha >= 0.96:
			break
		await _wait_frames(1)
	if utility_row.modulate.a < 0.96:
		_fail("module utility row did not fade back after swipe: alpha=%.3f" % utility_row.modulate.a)
		return
	if target_shelf_background == null or target_shelf_background.modulate.a < 0.96:
		_fail("skill shelf background did not fade back after swipe: alpha=%.3f" % (0.0 if target_shelf_background == null else target_shelf_background.modulate.a))
		return

	print("skill-swipe-module-utility-fade-ok drag_alpha=%.3f release_min_alpha=%.3f final_alpha=%.3f shelf_drag_alpha=%.3f shelf_release_min_alpha=%.3f shelf_final_alpha=%.3f" % [drag_alpha, release_min_alpha, utility_row.modulate.a, shelf_drag_alpha, shelf_release_min_alpha, target_shelf_background.modulate.a])
	quit(0)

func _valid_control(value) -> Control:
	if value == null or typeof(value) != TYPE_OBJECT or not is_instance_valid(value):
		return null
	return value as Control

func _find_named_control(root_node: Node, node_name: String) -> Control:
	if root_node == null or not is_instance_valid(root_node):
		return null
	if root_node is Control and root_node.name == node_name:
		return root_node as Control
	for raw_child in root_node.get_children():
		var found := _find_named_control(raw_child as Node, node_name)
		if found != null:
			return found
	return null

func _wait_frames(count: int) -> void:
	for i in range(count):
		await process_frame

func _fail(message: String) -> void:
	if failed:
		return
	failed = true
	push_error("skill-swipe-module-utility-fade-fail: %s" % message)
	quit(1)
'@ | Set-Content -Path $testScript -Encoding UTF8

$output = & "$projectRoot\run-godot-safe.ps1" --path "$projectRoot" --headless --script $testScript 2>&1
$output | ForEach-Object { Write-Output $_ }

if (($output -join "`n") -notmatch "skill-swipe-module-utility-fade-ok") {
    throw "Skill swipe module utility fade test did not report success."
}

$godotProcesses = Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match [regex]::Escape($testScript) }
if ($godotProcesses) {
    throw "A headless Godot process is still running after the skill swipe module utility fade test."
}
