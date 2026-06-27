$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\honey-stamina-regen"
$testScript = Join-Path $testDir "honey_stamina_regen_test.gd"
$capturePath = Join-Path $testDir "honey-stamina-gauge.png"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-HeadlessGodotProcesses {
    $processes = @(Get-CimInstance Win32_Process -Filter "name like 'Godot%'" -ErrorAction SilentlyContinue)
    @($processes | Where-Object { $_.CommandLine -match '--headless' })
}

function Assert-NoUnexpectedGodotErrors {
    param(
        [Parameter(Mandatory = $true)][AllowNull()]$Output,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($null -eq $Output) {
        return
    }

    foreach ($line in @($Output)) {
        $text = [string]$line
        if ($text -notmatch '(ERROR|SCRIPT ERROR|powershell\.exe : ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match 'ERROR: \d+ RID allocations of type .+ were leaked at exit\.' -or
            $text -match 'ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.'
        )
        if (-not $knownShutdownNoise) {
            throw "Unexpected Godot error during ${Context}: $text"
        }
    }
}
Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_HONEY_STAMINA_CAPTURE_PATH
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"
$env:IDLE_ELITE_HONEY_STAMINA_CAPTURE_PATH = $capturePath
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 120
const TEST_FRAME_SECONDS := 1.0 / 120.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("honey-stamina-regen-start")
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

	var honey_module := scene.call("_mat_collection_module", "honey") as Control
	root.add_child(honey_module)
	var honey_info_button := _find_button_with_text(honey_module, "i")
	if honey_info_button == null:
		_fail("honey mat module should include an info button")
		return
	var honey_info_title := _find_label_with_text(honey_module, "Honey Stamina")
	if honey_info_title == null:
		_fail("honey mat module should include a Honey Stamina info popover")
		return
	honey_info_button.emit_signal("pressed")
	await _wait_test_frame()
	if not honey_info_title.is_visible_in_tree():
		_fail("honey info popover should become visible when the info button is pressed")
		return

	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_unlock_actions_state")
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "build")
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	var circle := await _wait_for_regen_circle(scene, "build")
	if circle == null:
		_fail("build stamina gauge did not become ready")
		return

	var skill_color := scene.call("_skill_theme_color", "build") as Color
	var honey_color := scene.call("_mat_color", "honey") as Color
	scene.call("_set_mat_amount", "honey", 1.0)
	scene.call("_set_regen_circle_for_skill", circle, "build", true)
	if not _colors_close(circle.get("theme_color") as Color, skill_color):
		_fail("exactly one honey should not activate stamina honey color: %s" % str(circle.get("theme_color")))
		return

	scene.call("_set_mat_amount", "honey", 2.0)
	scene.call("_set_regen_circle_for_skill", circle, "build", true)
	if not _colors_close(circle.get("target_theme_color") as Color, skill_color):
		_fail("honey stamina gauge changed the inner fill target: actual=%s expected=%s" % [str(circle.get("target_theme_color")), str(skill_color)])
		return
	if not _colors_close(circle.get("target_regen_ring_color") as Color, honey_color):
		_fail("honey stamina regen ring did not target honey color: actual=%s expected=%s" % [str(circle.get("target_regen_ring_color")), str(honey_color)])
		return
	if not _colors_close(circle.get("theme_color") as Color, skill_color):
		_fail("honey stamina changed the inner fill color: actual=%s expected=%s" % [str(circle.get("theme_color")), str(skill_color)])
		return
	if not _colors_close(circle.get("regen_ring_color") as Color, honey_color):
		_fail("honey stamina regen ring did not apply honey color: actual=%s expected=%s" % [str(circle.get("regen_ring_color")), str(honey_color)])
		return
	if not _colors_close(circle.get("theme_color") as Color, skill_color):
		_fail("honey stamina inner fill did not remain skill-colored after ring transition: actual=%s expected=%s" % [str(circle.get("theme_color")), str(skill_color)])
		return
	var capture_result := await _capture_viewport(OS.get_environment("IDLE_ELITE_HONEY_STAMINA_CAPTURE_PATH"))
	if capture_result == "skipped":
		print("honey-stamina-screenshot-skipped renderer=%s" % DisplayServer.get_name())
	elif capture_result != "ok":
		_fail("honey stamina screenshot was not captured")
		return

	var max_stamina := float(scene.call("_max_stamina", "build"))
	_set_skill_stamina(scene, "build", maxf(0.0, max_stamina - 5.0))
	_set_stamina_bank(scene, "build", 0.0)
	scene.set("stamina_gauge_boost_skill_id", "")
	scene.set("stamina_gauge_regen_multiplier", 1.0)
	scene.call("_apply_stamina_regen_seconds", 1.0, true)
	var honey_only_bank := _stamina_bank(scene, "build")
	if absf(honey_only_bank - 2.0) > 0.01:
		_fail("honey regen should add 2 seconds per 1 second tick, got %.4f" % honey_only_bank)
		return
	if absf(float(scene.call("_mat_amount", "honey")) - 1.0) > 0.01:
		_fail("starting honey regen should consume one honey, got %.4f" % float(scene.call("_mat_amount", "honey")))
		return
	if absf(float(scene.get("honey_stamina_seconds_remaining")) - 9.0) > 0.01:
		_fail("one consumed honey should leave 9 boosted seconds after a 1 second tick, got %.4f" % float(scene.get("honey_stamina_seconds_remaining")))
		return

	_set_skill_stamina(scene, "build", maxf(0.0, max_stamina - 5.0))
	_set_stamina_bank(scene, "build", 0.0)
	scene.set("stamina_gauge_boost_skill_id", "build")
	scene.set("stamina_gauge_regen_multiplier", 3.0)
	scene.call("_apply_stamina_regen_seconds", 1.0, true)
	var stacked_bank := _stamina_bank(scene, "build")
	if absf(stacked_bank - 6.0) > 0.01:
		_fail("honey and manual hold regen should multiply to 6 seconds per tick, got %.4f" % stacked_bank)
		return

	scene.call("_set_mat_amount", "honey", 2.0)
	scene.set("honey_stamina_seconds_remaining", 0.0)
	_set_skill_stamina(scene, "build", maxf(0.0, max_stamina - 25.0))
	_set_stamina_bank(scene, "build", 0.0)
	scene.set("stamina_gauge_boost_skill_id", "")
	scene.set("stamina_gauge_regen_multiplier", 1.0)
	scene.call("_apply_stamina_regen_seconds", 11.0, true)
	var expired_honey_bank := _stamina_bank(scene, "build")
	if absf(expired_honey_bank - 10.0) > 0.01:
		_fail("two honey should boost the full 11 second tick and leave bank 10, got %.4f" % expired_honey_bank)
		return
	if absf(float(scene.call("_mat_amount", "honey")) - 0.0) > 0.01:
		_fail("expired honey regen should consume all available honey, got %.4f" % float(scene.call("_mat_amount", "honey")))
		return
	if absf(float(scene.get("honey_stamina_seconds_remaining")) - 9.0) > 0.01:
		_fail("second honey should leave 9 boosted seconds after rollover, got %.4f" % float(scene.get("honey_stamina_seconds_remaining")))
		return

	scene.call("_set_mat_amount", "honey", 5.0)
	scene.set("honey_stamina_seconds_remaining", 0.0)
	_set_skill_stamina(scene, "build", max_stamina)
	if not bool(scene.call("_spend_action_stamina", "build", 2.0)):
		_fail("spending build stamina with honey should succeed")
		return
	if absf(_skill_stamina(scene, "build") - (max_stamina - 2.0)) > 0.01:
		_fail("spending two stamina should reduce build stamina by two")
		return
	if absf(float(scene.call("_mat_amount", "honey")) - 5.0) > 0.01:
		_fail("spending stamina should not consume honey until regen, got %.4f" % float(scene.call("_mat_amount", "honey")))
		return

	scene.call("_set_mat_amount", "honey", 1.0)
	scene.set("honey_stamina_seconds_remaining", 0.0)
	_set_skill_stamina(scene, "build", maxf(0.0, max_stamina - 5.0))
	_set_stamina_bank(scene, "build", 0.0)
	scene.call("_apply_stamina_regen_seconds", 1.0, true)
	if absf(float(scene.call("_mat_amount", "honey")) - 0.0) > 0.01:
		_fail("final honey should be consumed by stamina regen, got %.4f" % float(scene.call("_mat_amount", "honey")))
		return
	if absf(float(scene.get("honey_stamina_seconds_remaining")) - 9.0) > 0.01:
		_fail("final honey should leave 9 boosted seconds after a 1 second tick, got %.4f" % float(scene.get("honey_stamina_seconds_remaining")))
		return

	print("honey-stamina-regen-ok honey_only=%.4f stacked=%.4f honey_after_spend=%.4f color=%s" % [honey_only_bank, stacked_bank, float(scene.call("_mat_amount", "honey")), str(circle.get("theme_color"))])
	quit(0)


func _wait_for_regen_circle(scene: Node, skill_id: String) -> Control:
	for _frame in range(SETTLE_FRAMES * 3):
		await _wait_test_frame()
		if str(scene.get("current_screen")) != "skill" or str(scene.get("selected_skill_id")) != skill_id:
			continue
		var circle := scene.get("detail_regen_circle") as Control
		if circle != null and circle.is_inside_tree() and circle.visible:
			return circle
	return null


func _set_skill_stamina(scene: Node, skill_id: String, value: float) -> void:
	var stamina := scene.get("stamina") as Dictionary
	stamina[skill_id] = value
	scene.set("stamina", stamina)


func _skill_stamina(scene: Node, skill_id: String) -> float:
	var stamina := scene.get("stamina") as Dictionary
	return float(stamina.get(skill_id, 0.0))


func _set_stamina_bank(scene: Node, skill_id: String, value: float) -> void:
	var stamina_bank := scene.get("stamina_bank") as Dictionary
	stamina_bank[skill_id] = value
	scene.set("stamina_bank", stamina_bank)


func _stamina_bank(scene: Node, skill_id: String) -> float:
	var stamina_bank := scene.get("stamina_bank") as Dictionary
	return float(stamina_bank.get(skill_id, 0.0))


func _find_button_with_text(root_node: Node, text: String) -> Button:
	if root_node is Button and str((root_node as Button).text) == text:
		return root_node as Button
	for child in root_node.get_children():
		var found := _find_button_with_text(child, text)
		if found != null:
			return found
	return null


func _find_label_with_text(root_node: Node, text: String) -> Label:
	if root_node is Label and str((root_node as Label).text) == text:
		return root_node as Label
	for child in root_node.get_children():
		var found := _find_label_with_text(child, text)
		if found != null:
			return found
	return null


func _colors_close(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) <= 0.004 and absf(actual.g - expected.g) <= 0.004 and absf(actual.b - expected.b) <= 0.004 and absf(actual.a - expected.a) <= 0.004


func _wait_for_circle_color(circle: Control, expected: Color, property_name := "theme_color") -> bool:
	for _frame in range(90):
		await _wait_test_frame()
		if _colors_close(circle.get(property_name) as Color, expected):
			return true
	return false


func _capture_viewport(path: String) -> String:
	if path.is_empty():
		return "skipped"
	if DisplayServer.get_name() == "headless":
		return "skipped"
	for _frame in range(4):
		await _wait_test_frame()
	var texture := root.get_viewport().get_texture()
	if texture == null:
		return "failed"
	var image := texture.get_image()
	if image == null or image.is_empty():
		return "failed"
	return "ok" if image.save_png(path) == OK else "failed"


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await _wait_test_frame()
		if not is_instance_valid(scene):
			return false
		var queue := scene.get("boot_detail_render_queue") as Array
		if (
			bool(scene.get("startup_initialized"))
			and not bool(scene.get("boot_detail_render_in_progress"))
			and not bool(scene.get("boot_detail_scroll_locked"))
			and (queue == null or queue.is_empty())
		):
			return true
	return false


func _wait_test_frame() -> void:
	await process_frame
	await create_timer(TEST_FRAME_SECONDS, true, false, true).timeout


func _fail(message: String) -> void:
	push_error("honey-stamina-regen-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-NoUnexpectedGodotErrors $output "honey stamina regen validation"
    $successLine = @($output | Select-String -SimpleMatch "honey-stamina-regen-ok")
    if ($successLine.Count -eq 0) {
        throw "Honey stamina regen test did not report success."
    }
    $captureSkipped = @($output | Select-String -SimpleMatch "honey-stamina-screenshot-skipped")
    Assert-True ((Test-Path -LiteralPath $capturePath) -or $captureSkipped.Count -gt 0) "Honey stamina screenshot was not created or cleanly skipped at $capturePath."
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    }
    else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCapturePath) {
        Remove-Item Env:IDLE_ELITE_HONEY_STAMINA_CAPTURE_PATH -ErrorAction SilentlyContinue
    }
    else {
        $env:IDLE_ELITE_HONEY_STAMINA_CAPTURE_PATH = $previousCapturePath
    }

    $afterProcesses = @(Get-HeadlessGodotProcesses)
    $newProcesses = @($afterProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($newProcesses.Count -gt 0) {
        $details = ($newProcesses | ForEach-Object { "pid=$($_.ProcessId) $($_.CommandLine)" }) -join "`n"
        throw "A headless Godot process is still running after the honey stamina regen test:`n$details"
    }
}
