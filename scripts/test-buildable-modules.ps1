$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\buildable-modules\tests"
$testScript = Join-Path $testDir "buildable_modules_test.gd"

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

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$beforeProcesses = @(Get-HeadlessGodotProcesses | Select-Object -ExpandProperty ProcessId)
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"

try {
    @'
extends SceneTree

const SkillState := preload("res://scripts/progression/skill_state.gd")

const BuildableModules = preload("res://scripts/gameplay/buildable_modules.gd")

var test_failed := false

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("buildable-modules-start")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	scene.call("_activity_data_catalog").call("load_action_data", scene)
	scene.call("_save_runtime").call("_init_state")
	var fight := scene.skills["fight"] as Dictionary
	fight["level"] = 5
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(5))
	scene.skills["fight"] = fight
	scene.material_runtime.set_amount("scrapwood", 3.0)
	var action := scene.call("_action_data", "fight", "duel-leaning-fence-post") as Dictionary
	_expect(not action.is_empty(), "prototype buildable action should load")
	_expect(BuildableModules.is_buildable(action), "prototype action should have a build contract")
	_expect(not BuildableModules.is_built(scene.built_modules, "fight", action, Callable(scene, "_action_key")), "prototype action should begin unbuilt")
	var built := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1080.0, 1080.0) as Dictionary
	var card := built.get("card", {}) as Dictionary
	scene.call("_register_action_card", scene.call("_action_key", "fight", "duel-leaning-fence-post"), card)
	_expect((card.get("build_overlay") as Control) != null, "unbuilt card should show blueprint overlay")
	var plank_nodes = card.get("build_plank_nodes", [])
	_expect(plank_nodes is Array and plank_nodes.size() == 1, "build cover should use one full-width generated plank")
	var plank := plank_nodes[0] as TextureRect
	_expect(plank != null and plank.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "single build plank should preserve its source aspect")
	_expect((card.get("build_progress_cover") as Control) == null, "build cover should tint the full module instead of adding a progress-only cover")
	_expect((card.get("build_button_panel") as PanelContainer) != null, "build cover should place BUILD as the title-line button")
	_expect((card.get("build_module_title") as Label) == (card.get("title") as Label), "build cover should reuse the normal module title")
	_expect(str((card.get("build_module_title") as Label).text) == "Duel Fence Post", "build cover should show the normal module title above the planks")
	_expect(str((card.get("build_cta_title") as Label).text) == "BUILD", "blueprint CTA should use the build label")
	_expect(str((card.get("build_cost_heading") as Label).text) == "COST", "blueprint CTA should show a COST heading")
	var cost_rows := card.get("build_cost_rows", []) as Array
	_expect(cost_rows.size() >= 1, "blueprint CTA should show at least one cost row")
	var starting_xp := int((scene.skills["fight"] as Dictionary).get("xp", 0))
	var starting_build_xp := int((scene.skills["build"] as Dictionary).get("xp", 0))
	var start_result := bool(scene.call("_action_runtime").call("_start_action", "fight", "duel-leaning-fence-post", true, false))
	_expect(not start_result, "first tap should build instead of starting the action")
	_expect((card.get("build_overlay") as Control).has_meta("build_complete_animation_tween"), "visible build should animate the build overlay before refresh")
	_expect(BuildableModules.is_built(scene.built_modules, "fight", action, Callable(scene, "_action_key")), "first tap should persist built state")
	_expect(absf(scene.material_runtime.amount("scrapwood") - 0.0) < 0.001, "build should spend the configured Scrapwood cost once")
	_expect(int((scene.skills["fight"] as Dictionary).get("xp", 0)) == starting_xp, "build should not grant action-skill XP")
	_expect(int((scene.skills["build"] as Dictionary).get("xp", 0)) == starting_build_xp + 60, "build should grant material-based Building XP")
	_expect(str(scene.running_action_id).is_empty(), "build tap should not start the module in the same tap")
	var payload := scene.call("_save_runtime").call("_save_payload", int(scene.call("_unix_now"))) as Dictionary
	_expect(bool((payload.get("built_modules", {}) as Dictionary).get("fight:duel-leaning-fence-post", false)), "built module should be present in save payload")
	for _frame in range(24):
		await process_frame
	fight = scene.skills["fight"] as Dictionary
	fight["level"] = 6
	fight["xp"] = maxi(int(fight.get("xp", 0)), SkillState.xp_for_level(6))
	scene.skills["fight"] = fight
	scene.call("_activity_unlock_runtime").call("_finalize_manual_activity_unlock", "fight", "duel-leaning-fence-post", "buildable module test unlock")
	var built_card := scene.call("_skill_detail_surface").call("_build_detail_interactive_action_card", "fight", action, 1080.0, 1080.0) as Dictionary
	var normal_card := built_card.get("card", {}) as Dictionary
	_expect((normal_card.get("build_overlay") as Control) == null, "built card should no longer show blueprint overlay")
	scene.queue_free()
	if test_failed:
		quit(1)
		return
	print("buildable-modules-ok")
	quit(0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	test_failed = true
	push_error(message)
	print("buildable-modules-failed: %s" % message)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script "res://.codex-tmp/buildable-modules/tests/buildable_modules_test.gd" 2>&1
    $output | Write-Output
    Assert-True (($output | Out-String) -match "buildable-modules-ok") "Buildable modules test did not report success."
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    $afterProcesses = @(Get-HeadlessGodotProcesses | Where-Object { $beforeProcesses -notcontains $_.ProcessId })
    if ($afterProcesses.Count -gt 0) {
        $afterProcesses | Select-Object ProcessId, ParentProcessId, CommandLine | Format-List | Out-String | Write-Output
        throw "Headless Godot process left behind after buildable module test."
    }
}
