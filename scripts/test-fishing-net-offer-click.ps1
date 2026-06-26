$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fishing-net-offer-click"
$testScript = Join-Path $testDir "fishing_net_offer_click.gd"

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

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_FRAMES := 240

func _init() -> void:
	call_deferred("_run")

func _mouse_button_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	return event

func _mouse_motion_event(point: Vector2, relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = relative
	return event

func _render_fishing_page(scene: Node) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _frame in range(30):
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)

func _fishing_offer_button(scene: Node, offer_id: String) -> Button:
	for raw_button in scene.get_tree().get_nodes_in_group("fishing_offer_buttons"):
		var candidate_button := raw_button as Button
		if candidate_button != null and str(candidate_button.get_meta("fishing_offer_id", "")) == offer_id:
			return candidate_button
	return null

func _run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	var scene := packed.instantiate()
	root.add_child(scene)
	for _frame in range(BOOT_FRAMES):
		await process_frame

	var skills := scene.get("skills") as Dictionary
	var fishing := (skills.get("fishing", {}) as Dictionary).duplicate(true)
	fishing["level"] = 3
	fishing["xp"] = 0
	skills["fishing"] = fishing
	scene.set("skills", skills)
	scene.call("_god_mode_unlock_onboarding_state")
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	scene.set("fishing_net_collected", false)
	scene.set("fishing_net_collect_pending", false)
	scene.set("fishing_rod_collected", false)
	scene.set("module_ui_sort_mode", "level")
	scene.set("module_ui_pinned_order", [])
	scene.set("module_ui_collapsed", {})

	await _render_fishing_page(scene)

	var net_offer_button := _fishing_offer_button(scene, "net")
	if net_offer_button == null or not is_instance_valid(net_offer_button):
		push_error("Fishing net offer click test could not find the rendered net offer button.")
		quit(1)
		return

	var net_offer_hit := instance_from_id(int(net_offer_button.get_meta("fishing_offer_hit_id", 0))) as Control
	if net_offer_hit == null or not is_instance_valid(net_offer_hit):
		push_error("Fishing net offer button has no fallback hit root.")
		quit(1)
		return

	var net_offer_point := net_offer_hit.get_global_rect().get_center()
	var saved_net_button_size := net_offer_button.size
	net_offer_button.size = Vector2.ZERO
	scene.set("skill_swipe_tracking", false)
	scene.set("skill_swipe_preview_prewarm_pending", false)
	if not bool(scene.call("_route_fishing_offer_button_global_input", _mouse_button_event(net_offer_point, true))):
		push_error("Fishing net offer did not accept a press through the fallback hit root. point=%s button_rect=%s hit_rect=%s" % [
			str(net_offer_point),
			str(net_offer_button.get_global_rect()),
			str(net_offer_hit.get_global_rect())
		])
		quit(1)
		return
	if not bool(net_offer_button.get_meta("fishing_offer_press_active", false)):
		push_error("Fishing net offer fallback press routed but did not arm the offer button.")
		quit(1)
		return
	if bool(scene.get("skill_swipe_tracking")):
		push_error("Fishing net offer press started skill-swipe tracking.")
		quit(1)
		return
	if bool(scene.get("skill_swipe_preview_prewarm_pending")):
		push_error("Fishing net offer press queued skill-swipe prewarm.")
		quit(1)
		return
	var net_offer_drag_point := net_offer_point + Vector2(0, 180)
	if bool(scene.call("_route_fishing_offer_button_global_input", _mouse_motion_event(net_offer_drag_point, Vector2(0, 180)))):
		push_error("Fishing net offer vertical drag was consumed by the offer route instead of passing to scroll.")
		quit(1)
		return
	if bool(scene.get("skill_swipe_tracking")):
		push_error("Fishing net offer vertical drag started skill-swipe tracking.")
		quit(1)
		return
	if bool(scene.get("skill_swipe_preview_prewarm_pending")):
		push_error("Fishing net offer vertical drag queued skill-swipe prewarm.")
		quit(1)
		return
	scene.call("_route_fishing_offer_button_global_input", _mouse_button_event(net_offer_drag_point, false))
	for _frame in range(4):
		await process_frame
	if bool(scene.get("fishing_net_collected")) or bool(scene.get("fishing_net_collect_pending")):
		push_error("Fishing net offer drag collected the net.")
		quit(1)
		return

	scene.call("_clear_fishing_offer_button_press", net_offer_button)

	scene.set("skill_swipe_tracking", false)
	scene.set("skill_swipe_preview_prewarm_pending", false)
	if not bool(scene.call("_route_fishing_offer_button_global_input", _mouse_button_event(net_offer_point, true))):
		push_error("Fishing net offer did not accept a second fallback press before horizontal swipe.")
		quit(1)
		return
	var net_offer_horizontal_drag_point := net_offer_point + Vector2(-220, 0)
	if not bool(scene.call("_route_fishing_offer_button_global_input", _mouse_motion_event(net_offer_horizontal_drag_point, Vector2(-220, 0)))):
		push_error("Fishing net offer horizontal drag was not routed into swipe handling.")
		quit(1)
		return
	if not bool(scene.get("skill_swipe_tracking")):
		push_error("Fishing net offer horizontal drag did not start skill-swipe tracking.")
		quit(1)
		return
	if bool(scene.get("skill_swipe_preview_prewarm_pending")):
		push_error("Fishing net offer horizontal drag queued idle swipe prewarm instead of active swipe feedback.")
		quit(1)
		return
	scene.call("_finish_skill_swipe", net_offer_horizontal_drag_point)
	for _frame in range(4):
		await process_frame
	if bool(scene.get("fishing_net_collected")) or bool(scene.get("fishing_net_collect_pending")):
		push_error("Fishing net offer horizontal swipe collected the net.")
		quit(1)
		return

	net_offer_button.size = saved_net_button_size

	fishing["level"] = 19
	skills["fishing"] = fishing
	scene.set("skills", skills)
	scene.set("fishing_net_collected", true)
	scene.set("fishing_rod_collected", false)
	scene.set("fish_currency", 1000.0)
	await _render_fishing_page(scene)

	var rod_offer_button := _fishing_offer_button(scene, "rod")
	if rod_offer_button == null or not is_instance_valid(rod_offer_button):
		push_error("Fishing rod offer click test could not find the rendered rod offer button.")
		quit(1)
		return
	var rod_offer_hit := instance_from_id(int(rod_offer_button.get_meta("fishing_offer_hit_id", 0))) as Control
	if rod_offer_hit == null or not is_instance_valid(rod_offer_hit):
		push_error("Fishing rod offer button has no fallback hit root.")
		quit(1)
		return
	var rod_offer_point := rod_offer_hit.get_global_rect().get_center()
	var saved_rod_button_size := rod_offer_button.size
	rod_offer_button.size = Vector2.ZERO
	if not bool(scene.call("_route_fishing_offer_button_global_input", _mouse_button_event(rod_offer_point, true))):
		push_error("Fishing rod offer did not accept a press through the fallback hit root. point=%s button_rect=%s hit_rect=%s" % [
			str(rod_offer_point),
			str(rod_offer_button.get_global_rect()),
			str(rod_offer_hit.get_global_rect())
		])
		quit(1)
		return
	if not bool(rod_offer_button.get_meta("fishing_offer_press_active", false)):
		push_error("Fishing rod offer fallback press routed but did not arm the offer button.")
		quit(1)
		return
	if not bool(scene.call("_route_fishing_offer_button_global_input", _mouse_button_event(rod_offer_point, false))):
		push_error("Fishing rod offer did not accept a release through the fallback hit root.")
		quit(1)
		return
	for _frame in range(8):
		await process_frame
	if not bool(scene.get("fishing_rod_collected")):
		push_error("Fishing rod offer fallback click did not collect the rod.")
		quit(1)
		return
	rod_offer_button.size = saved_rod_button_size

	print("fishing-net-offer-click-ok")
	quit(0)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "fishing-net-offer-click-ok") "Fishing net offer click test did not report success."
}
finally {
    $headless = @()
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        $headless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
        if ($headless.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after fishing net offer validation."
    }
}
