$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\stamina-gauge-offpage-smooth"
$testScript = Join-Path $testDir "stamina_gauge_offpage_smooth_test.gd"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
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
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 120
const SAMPLE_FRAMES := 54
const TEST_FRAME_SECONDS := 1.0 / 120.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("stamina-gauge-offpage-smooth-start")
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

	var max_stamina := float(scene.call("_max_stamina", "build"))
	_set_skill_stamina(scene, "build", maxf(0.0, max_stamina - 2.0))
	scene.call("_sync_stamina_bank", "build")
	scene.call("_update_ui", 0.0, true)
	await _wait_test_frame()

	scene.set("running_skill_id", "fight")
	scene.set("running_action_id", "shove-wobbly-hay-bale")
	scene.set("action_progress", 0.0)
	scene.set("ui_static_refresh_elapsed", 0.0)
	scene.set("detail_header_gauge_refresh_elapsed", 0.0)

	var changes := 0
	var last_target := float(circle.get("target_value"))
	for _frame in range(SAMPLE_FRAMES):
		await _wait_test_frame()
		var next_target := float(circle.get("target_value"))
		if absf(next_target - last_target) > 0.0001:
			changes += 1
			last_target = next_target

	if str(scene.get("selected_skill_id")) != "build" or str(scene.get("running_skill_id")) != "fight":
		_fail("test setup drifted: selected=%s running=%s" % [str(scene.get("selected_skill_id")), str(scene.get("running_skill_id"))])
		return
	if changes < 3:
		_fail("visible build regen ring updated too slowly while fight was running: changes=%s target=%.4f" % [str(changes), last_target])
		return

	print("stamina-gauge-offpage-smooth-ok changes=%s target=%.4f" % [str(changes), last_target])
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
	push_error("stamina-gauge-offpage-smooth-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-NoUnexpectedGodotErrors $output "stamina gauge off-page smooth validation"
    $successLine = @($output | Select-String -SimpleMatch "stamina-gauge-offpage-smooth-ok")
    if ($successLine.Count -eq 0) {
        throw "Stamina gauge off-page smooth test did not report success."
    }
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    }
    else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
}
