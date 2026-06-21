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
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	scene.set("fishing_net_collected", false)
	scene.set("fishing_net_collect_pending", false)
	scene.set("module_ui_sort_mode", "level")
	scene.set("module_ui_pinned_order", [])
	scene.set("module_ui_collapsed", {})

	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _frame in range(30):
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)

	var net_offer_button: Button = null
	for raw_button in scene.get_tree().get_nodes_in_group("fishing_offer_buttons"):
		var candidate_button := raw_button as Button
		if candidate_button != null and str(candidate_button.get_meta("fishing_offer_id", "")) == "net":
			net_offer_button = candidate_button
			break
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

	scene.call("_clear_fishing_offer_button_press", net_offer_button)
	net_offer_button.size = saved_net_button_size
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
    $headless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after fishing net offer validation."
    }
}
