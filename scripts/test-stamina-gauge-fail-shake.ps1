$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\stamina-gauge-fail-shake"
$testScript = Join-Path $testDir "stamina_gauge_fail_shake_test.gd"


Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 120
const TEST_FRAME_SECONDS := 1.0 / 120.0
const SkillState := preload("res://scripts/progression/skill_state.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("stamina-gauge-fail-shake-start")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_boot_ready(scene):
		_fail("boot did not become ready")
		return

	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	_set_fish_currency(scene, 0.0)
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("current_screen", "menu")
	var menu_render = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if menu_render != null:
		await menu_render
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()

	scene.call("_navigation_shell").call("_select_skill", "build")
	var circle := await _wait_for_regen_circle(scene, "build")
	if circle == null:
		_fail("build stamina gauge did not become ready")
		return

	var rest_position := circle.position
	var rest_rotation := circle.rotation
	_set_skill_stamina(scene, "build", maxf(0.0, float(SkillState.max_stamina(scene, "build")) - 1.0))
	circle.modulate = Color(1.0, 0.25, 0.25, 1.0)
	for i in range(6):
		scene.call("_action_runtime").call("_try_eat_fish_for_stamina", "build", circle)
		await _wait_test_frame()
		if not _is_white_rgb(circle.modulate):
			_fail("stamina gauge fail shake tinted red on click %s: modulate=%s" % [str(i), str(circle.modulate)])
			return
	if _count_need_fish_popups() <= 0:
		_fail("zero-fish stamina gauge click did not create need fish popup")
		return
	if not _has_stamina_popup_text("need fish!"):
		_fail("zero-fish stamina gauge popup did not contain exact need fish! text")
		return

	for _i in range(90):
		await _wait_test_frame()

	if not _is_white_rgb(circle.modulate):
		_fail("stamina gauge stayed tinted after fail shake: modulate=%s" % str(circle.modulate))
		return
	if circle.position.distance_to(rest_position) > 0.5:
		_fail("stamina gauge did not return to rest position: pos=%s rest=%s" % [str(circle.position), str(rest_position)])
		return
	if absf(circle.rotation - rest_rotation) > 0.002:
		_fail("stamina gauge did not return to rest rotation: rot=%.4f rest=%.4f" % [circle.rotation, rest_rotation])
		return
	if circle.has_meta("stamina_eat_fail_tween"):
		_fail("stamina gauge fail tween meta was left behind")
		return
	if absf(_fish_currency(scene)) > 0.001:
		_fail("no-food stamina gauge click changed food: %s" % str(_fish_currency(scene)))
		return

	_set_fish_currency(scene, 3.0)
	_set_skill_stamina(scene, "build", float(SkillState.max_stamina(scene, "build")))
	circle.position = rest_position
	circle.rotation = rest_rotation
	circle.modulate = Color.WHITE
	scene.call("_action_runtime").call("_try_eat_fish_for_stamina", "build", circle)
	await _wait_test_frame()
	if absf(_fish_currency(scene) - 3.0) > 0.001:
		_fail("full stamina gauge click spent fish: %s" % str(_fish_currency(scene)))
		return
	if not circle.has_meta("stamina_eat_fail_tween"):
		_fail("full stamina gauge click did not start fail shake tween")
		return
	if not _has_stamina_popup_text("full"):
		_fail("full stamina gauge click did not create a popup with exact full text")
		return
	for _i in range(90):
		await _wait_test_frame()
	if circle.has_meta("stamina_eat_fail_tween"):
		_fail("full stamina gauge fail tween meta was left behind")
		return
	if circle.position.distance_to(rest_position) > 0.5 or absf(circle.rotation - rest_rotation) > 0.002:
		_fail("full stamina gauge did not return to rest transform: pos=%s rot=%.4f" % [str(circle.position), circle.rotation])
		return

	print("stamina-gauge-fail-shake-ok modulate=%s pos=%s rot=%.4f" % [str(circle.modulate), str(circle.position), circle.rotation])
	quit(0)


func _wait_for_regen_circle(scene: Node, skill_id: String) -> Control:
	for _frame in range(SETTLE_FRAMES * 3):
		await _wait_test_frame()
		if str(scene.get("current_screen")) != "skill" or str(scene.get("selected_skill_id")) != skill_id:
			continue
		var circle := scene._skill_detail_surface().detail_regen_circle as Control
		if circle != null and circle.is_inside_tree() and circle.visible:
			return circle
	return null


func _is_white_rgb(color: Color) -> bool:
	return color.r >= 0.98 and color.g >= 0.98 and color.b >= 0.98


func _number(value: Variant, fallback := 0.0) -> float:
	match typeof(value):
		TYPE_FLOAT, TYPE_INT:
			return value
	return fallback


func _fish_currency(scene: Node) -> float:
	var fishing_runtime := scene.get("fishing_runtime") as Object
	if fishing_runtime != null:
		return _number(fishing_runtime.get("fish_currency"))
	return _number(scene.get("fish_currency"))


func _set_fish_currency(scene: Node, value: float) -> void:
	var fishing_runtime := scene.get("fishing_runtime") as Object
	if fishing_runtime != null:
		fishing_runtime.set("fish_currency", value)
	else:
		scene.set("fish_currency", value)


func _set_skill_stamina(scene: Node, skill_id: String, value: float) -> void:
	var stamina := scene.get("stamina") as Dictionary
	stamina[skill_id] = value
	scene.set("stamina", stamina)


func _count_need_fish_popups() -> int:
	return get_nodes_in_group("stamina_need_fish_float").size()


func _has_stamina_popup_text(text: String) -> bool:
	for node in get_nodes_in_group("stamina_need_fish_float"):
		if _node_tree_has_label_text(node as Node, text):
			return true
	return false


func _node_tree_has_label_text(node: Node, text: String) -> bool:
	if node == null:
		return false
	if node is Label and (node as Label).text == text:
		return true
	for raw_child in node.get_children():
		var child := raw_child as Node
		if child != null and _node_tree_has_label_text(child, text):
			return true
	return false


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await _wait_test_frame()
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			_truthy(scene.get("startup_initialized"))
			and not _truthy(scene.get("boot_detail_render_in_progress"))
			and not _truthy(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_test_frame() -> void:
	await process_frame
	await create_timer(TEST_FRAME_SECONDS, true, false, true).timeout


func _truthy(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT:
			return int(value) != 0
		TYPE_FLOAT:
			return not is_zero_approx(float(value))
		TYPE_STRING:
			return not str(value).is_empty()
		_:
			return value != null


func _fail(message: String) -> void:
	push_error("stamina-gauge-fail-shake-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "stamina-gauge-fail-shake-ok") "Stamina gauge fail-shake test did not report success."
    Assert-NoUnexpectedGodotErrors $output "stamina gauge fail-shake test"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the stamina gauge fail-shake test."
    }
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
