$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fighting-navigation-lifecycle"
$testScript = Join-Path $testDir "fighting_navigation_lifecycle_test.gd"

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "90"

try {
    @'
extends SceneTree

const TIMEOUT_FRAMES := 720
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var scene := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_boot(scene):
		_fail("boot did not finish")
		return
	scene.call("_achievement_overlay_surface").call("hide_offline_summary_immediate")
	scene.call("_test_state_runtime").call("_god_mode_unlock_onboarding_state")
	scene.call("_test_state_runtime").call("_god_mode_max_skills_state")
	scene.call("_test_state_runtime").call("_god_mode_unlock_actions_state")
	var shell = scene.call("_navigation_shell")
	var shared_content := scene.get("skills_content") as Control

	shell.call("_clear_top_level_nav_lock")
	shell.call("_show_skills", false)
	if not await _wait_screen(scene, shell, "menu"):
		_fail("skill menu did not open")
		return
	_expect(scene.get("skills_content") == shared_content, "skill menu replaced the shared page owner")

	var fight_button := (scene.get("skill_cards") as Dictionary).get("fight", {}).get("button") as Button
	if fight_button == null:
		_fail("Fighting navigation button was not built")
		return
	fight_button.emit_signal("pressed")
	var cover_seen := false
	for _frame in range(TIMEOUT_FRAMES):
		await process_frame
		var activity_surface = scene.call("_skill_swipe_activity_surface")
		var cover := activity_surface.get("skill_swipe_handoff_cover") as Control
		cover_seen = cover_seen or (cover != null and is_instance_valid(cover))
		if (
			str(scene.get("current_screen")) == "skill"
			and str(scene.get("selected_skill_id")) == "fight"
			and not bool(shell.get("screen_render_in_progress"))
			and cover == null
		):
			break
	_expect(cover_seen, "Fighting transition did not present its cover")
	_expect(str(scene.get("selected_skill_id")) == "fight", "Fighting navigation did not reach Fighting")
	_expect(scene.get("skills_content") == shared_content, "Fighting transition changed the shared page owner")
	_expect(_navigation_ready(shell), "navigation was not ready on Fighting")

	for target in ["home", "hub", "shop", "settings", "menu"]:
		shell.call("_clear_top_level_nav_lock")
		match target:
			"home": shell.call("_show_home")
			"hub": shell.call("_show_hub")
			"shop": shell.call("_show_shop")
			"settings": scene.call("_settings_surface").call("_show_settings")
			"menu": shell.call("_show_skills", false)
		if not await _wait_screen(scene, shell, target):
			_fail("%s page did not open" % target)
			return
		_expect(_navigation_ready(shell), "navigation disappeared on %s" % target)
		_expect(scene.get("skills_content") == shared_content, "shared page owner changed on %s" % target)

	if failures.is_empty():
		print("fighting-navigation-lifecycle-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _wait_boot(scene: Node) -> bool:
	for _frame in range(TIMEOUT_FRAMES):
		await process_frame
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.call("_boot_warmup_runtime").get("active"))
		):
			return true
	return false

func _wait_screen(scene: Node, shell, target: String) -> bool:
	for _frame in range(TIMEOUT_FRAMES):
		await process_frame
		if str(scene.get("current_screen")) == target and not bool(shell.get("screen_render_in_progress")):
			return true
	return false

func _navigation_ready(shell) -> bool:
	var bar := shell.get("nav_bar") as Control
	var row := shell.get("bottom_nav_buttons_row") as Control
	if bar == null or row == null or not bar.is_visible_in_tree() or not row.is_visible_in_tree():
		return false
	if row.get_child_count() != 5:
		return false
	for child in row.get_children():
		if child is Button and (child as Button).disabled:
			return false
	return true

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _fail(message: String) -> void:
	failures.append(message)
	for failure in failures:
		push_error(failure)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Fighting navigation lifecycle test failed with exit code $LASTEXITCODE."
    }
    Assert-NoUnexpectedGodotErrors -Output $output -Context "fighting navigation lifecycle test"
    Assert-NoHeadlessGodotProcesses -Context "fighting navigation lifecycle test"
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
