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
        if ($text -notmatch '^(ERROR|SCRIPT ERROR):') {
            continue
        }
        $knownShutdownNoise = (
            $text -match '^ERROR: \d+ RID allocations of type .+ were leaked at exit\.$' -or
            $text -match '^ERROR: \d+ resources still in use at exit \(run with --verbose for details\)\.$'
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
	if not _colors_close(circle.get("target_theme_color") as Color, honey_color):
		_fail("honey stamina gauge did not target honey color: actual=%s expected=%s" % [str(circle.get("target_theme_color")), str(honey_color)])
		return
	if _colors_close(circle.get("theme_color") as Color, honey_color):
		_fail("honey stamina gauge snapped to honey color instead of transitioning")
		return
	if not await _wait_for_circle_color(circle, honey_color):
		_fail("honey stamina gauge did not finish transitioning to honey color: actual=%s expected=%s" % [str(circle.get("theme_color")), str(honey_color)])
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

	_set_skill_stamina(scene, "build", maxf(0.0, max_stamina - 5.0))
	_set_stamina_bank(scene, "build", 0.0)
	scene.set("stamina_gauge_boost_skill_id", "build")
	scene.set("stamina_gauge_regen_multiplier", 3.0)
	scene.call("_apply_stamina_regen_seconds", 1.0, true)
	var stacked_bank := _stamina_bank(scene, "build")
	if absf(stacked_bank - 6.0) > 0.01:
		_fail("honey and manual hold regen should multiply to 6 seconds per tick, got %.4f" % stacked_bank)
		return

	print("honey-stamina-regen-ok honey_only=%.4f stacked=%.4f color=%s" % [honey_only_bank, stacked_bank, str(circle.get("theme_color"))])
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


func _set_stamina_bank(scene: Node, skill_id: String, value: float) -> void:
	var stamina_bank := scene.get("stamina_bank") as Dictionary
	stamina_bank[skill_id] = value
	scene.set("stamina_bank", stamina_bank)


func _stamina_bank(scene: Node, skill_id: String) -> float:
	var stamina_bank := scene.get("stamina_bank") as Dictionary
	return float(stamina_bank.get(skill_id, 0.0))


func _colors_close(actual: Color, expected: Color) -> bool:
	return absf(actual.r - expected.r) <= 0.004 and absf(actual.g - expected.g) <= 0.004 and absf(actual.b - expected.b) <= 0.004 and absf(actual.a - expected.a) <= 0.004


func _wait_for_circle_color(circle: Control, expected: Color) -> bool:
	for _frame in range(90):
		await _wait_test_frame()
		if _colors_close(circle.get("theme_color") as Color, expected):
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
