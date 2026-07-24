$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\battery-governor"
$testScript = Join-Path $testDir "battery_governor_test.gd"

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

try {
    @'
extends SceneTree

const PerformanceRuntime := preload("res://scripts/app/performance_runtime.gd")

class FakeHost:
	extends Node

	class FakeHubSurface:
		var hub_drag_module_id := ""
		var hub_hotspot_hold_module_id := ""

	class FakeBootWarmupRuntime:
		var active := false

	class FakeActionStopHold:
		var hold_active := false

		func active() -> bool:
			return hold_active

	class FakeProfileChatOverlaySurface:
		var keyboard_active := false

		func keyboard_lift_active() -> bool:
			return keyboard_active

	class FakeTutorialOverlaySurface:
		var activity_start_highlight_active := false
		var activity_start_highlight_pending := false

	class FakeAchievementToastSurface:
		func transient_work_active() -> bool:
			return false

	class FakeNavigationShell:
		var pin_transition_blocker: Control = null
		var screen_render_in_progress := false

		func _page_switch_pending_transition_queued() -> bool:
			return false

		func _pinned_active_shelf_has_jailed_action() -> bool:
			return false

	class FakeSkillDetailSurface:
		var detail_scroll_visual_work_this_frame := false
		var detail_lazy_mounted_this_frame := false
		var action_card_press_key := ""

		func _detail_jump_arrows_need_processing() -> bool:
			return false

	var boot_detail_render_in_progress := false
	var module_ui_animating_collapse_key := ""
	var current_screen := ""
	var boot_warmup_runtime := FakeBootWarmupRuntime.new()
	var action_stop_hold := FakeActionStopHold.new()
	var hub_surface := FakeHubSurface.new()
	var profile_chat_overlay_surface := FakeProfileChatOverlaySurface.new()
	var tutorial_overlay_surface := FakeTutorialOverlaySurface.new()
	var achievement_toast_surface := FakeAchievementToastSurface.new()
	var navigation_shell := FakeNavigationShell.new()
	var skill_detail_surface := FakeSkillDetailSurface.new()

	func _skill_swipe_loading_transition_active() -> bool:
		return false

	func _boot_warmup_runtime():
		return boot_warmup_runtime

	func _action_stop_hold():
		return action_stop_hold

	func _hub_surface():
		return hub_surface

	func _profile_chat_overlay_surface():
		return profile_chat_overlay_surface

	func _tutorial_overlay_surface():
		return tutorial_overlay_surface

	func _achievement_toast_surface():
		return achievement_toast_surface

	func _navigation_shell():
		return navigation_shell

	func _skill_detail_surface():
		return skill_detail_surface

	func _refresh_god_mode_controls() -> void:
		pass

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	OS.set_environment("IDLE_ELITE_FORCE_MOBILE_BATTERY_GOVERNOR", "1")

	var previous_fps := Engine.max_fps
	var previous_low_processor := OS.low_processor_usage_mode
	var previous_sleep_usec := OS.low_processor_usage_mode_sleep_usec
	var host := FakeHost.new()
	var runtime := PerformanceRuntime.new(host)

	runtime._configure_performance_mode()
	_expect(Engine.max_fps == 60, "Expected active mobile frame cap to be 60, got %s." % str(Engine.max_fps))
	_expect(not OS.low_processor_usage_mode, "Expected active governor state to disable low processor mode.")

	runtime.battery_governor_last_activity_msec = Time.get_ticks_msec() - 100000
	runtime._process_battery_governor()
	_expect(Engine.max_fps == 30, "Expected idle mobile frame cap to be 30, got %s." % str(Engine.max_fps))
	_expect(OS.low_processor_usage_mode, "Expected idle governor state to enable low processor mode.")
	_expect(OS.low_processor_usage_mode_sleep_usec == 8000, "Expected idle governor sleep usec to be 8000.")

	runtime._record_battery_governor_activity()
	_expect(Engine.max_fps == 60, "Expected governor activity to restore 60 FPS, got %s." % str(Engine.max_fps))
	_expect(not OS.low_processor_usage_mode, "Expected governor activity to disable low processor mode.")

	host.boot_warmup_runtime.active = true
	runtime.battery_governor_last_activity_msec = Time.get_ticks_msec() - 100000
	runtime._process_battery_governor()
	_expect(Engine.max_fps == 60, "Expected swipe work to keep active 60 FPS, got %s." % str(Engine.max_fps))
	_expect(not OS.low_processor_usage_mode, "Expected swipe work to keep low processor mode disabled.")

	host.boot_warmup_runtime.active = false
	runtime.battery_governor_last_activity_msec = Time.get_ticks_msec() - 100000
	runtime._process_battery_governor()
	_expect(Engine.max_fps == 30, "Expected governor to return to idle after swipe work ended.")

	OS.set_environment("IDLE_ELITE_FORCE_MOBILE_BATTERY_GOVERNOR", "0")
	Engine.max_fps = previous_fps
	OS.low_processor_usage_mode = previous_low_processor
	OS.low_processor_usage_mode_sleep_usec = previous_sleep_usec
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("battery-governor-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $beforeHeadless = @(Get-HeadlessGodotProcesses)
    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "battery-governor-ok") "Battery governor test did not report success."
    Assert-NoUnexpectedGodotErrors $output "battery governor test"

    $afterHeadless = @(Get-HeadlessGodotProcesses)
    $beforeIds = @($beforeHeadless | ForEach-Object { $_.ProcessId })
    $newHeadless = @($afterHeadless | Where-Object { $beforeIds -notcontains $_.ProcessId })
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the battery governor test."
    }
} finally {
    Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
