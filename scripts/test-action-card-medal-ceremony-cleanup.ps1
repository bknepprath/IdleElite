$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\action-card-medal-ceremony-cleanup"
$testScript = Join-Path $testDir "action_card_medal_ceremony_cleanup.gd"

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
$env:GODOT_RUN_TIMEOUT_SECONDS = "60"

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("action-card-medal-ceremony-cleanup-start")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("main scene did not load")
		return
	var scene := packed.instantiate()
	root.add_child(scene)

	var stale_ceremony_tween := Node.new()
	var stale_outgoing_tween := Node.new()
	var stale_outgoing := Node.new()
	var stale_tap_tween := Node.new()
	var stale_tap_effect := Node.new()
	var stale_medal := TextureRect.new()
	root.add_child(stale_ceremony_tween)
	root.add_child(stale_outgoing_tween)
	root.add_child(stale_outgoing)
	root.add_child(stale_tap_tween)
	root.add_child(stale_tap_effect)
	root.add_child(stale_medal)

	var card := {
		"medal_ceremony_tween": stale_ceremony_tween,
		"medal_outgoing_tween": stale_outgoing_tween,
		"medal_outgoing": stale_outgoing,
		"medal_tap_tweens": [stale_tap_tween],
		"medal_tap_effects": [stale_tap_effect],
		"medal": stale_medal,
	}

	stale_ceremony_tween.free()
	stale_outgoing_tween.free()
	stale_outgoing.free()
	stale_tap_tween.free()
	stale_tap_effect.free()
	stale_medal.free()

	scene.call("_clear_action_card_medal_ceremony", card)
	if card.has("medal_ceremony_tween"):
		_record("medal_ceremony_tween was not erased")
	if card.has("medal_outgoing_tween"):
		_record("medal_outgoing_tween was not erased")
	if card.has("medal_outgoing"):
		_record("medal_outgoing was not erased")
	if card.has("medal_tap_tweens"):
		_record("medal_tap_tweens was not erased")
	if card.has("medal_tap_effects"):
		_record("medal_tap_effects was not erased")

	var medal := TextureRect.new()
	medal.position = Vector2(180, 220)
	medal.size = Vector2(190, 190)
	medal.visible = true
	root.add_child(medal)
	var skill_id := "fight"
	var action_id := "test-elite-heavenly-medal"
	var mastery_state := {}
	mastery_state[scene.call("_action_key", skill_id, action_id)] = {"level": 20, "xp": 0}
	scene.set("mastery", mastery_state)
	var elite_heavenly_card := {
		"medal": medal,
		"skill_id": skill_id,
		"action_id": action_id,
	}
	var medal_center := medal.get_global_rect().get_center()
	var medal_positions: Array[Vector2] = [medal_center]
	if not bool(scene.call("_event_positions_inside_activity_stat_box", elite_heavenly_card, "__medal__", medal_positions)):
		_record("Elite Heavenly medal release was not accepted as a medal hit")
	var off_medal_positions: Array[Vector2] = [Vector2(20, 20)]
	if bool(scene.call("_event_positions_inside_activity_stat_box", elite_heavenly_card, "__medal__", off_medal_positions)):
		_record("Off-medal release was incorrectly accepted as a medal hit")
	medal.queue_free()

	var scroll_script := load("res://scripts/ui/mobile_scroll_container.gd")
	var detail_scroll := scroll_script.new() as Control
	detail_scroll.position = Vector2.ZERO
	detail_scroll.size = Vector2(900, 900)
	detail_scroll.visible = true
	root.add_child(detail_scroll)
	scene.set("detail_actions_scroll", detail_scroll)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	var fishing_button := Button.new()
	fishing_button.position = Vector2(80, 80)
	fishing_button.size = Vector2(500, 500)
	fishing_button.visible = true
	root.add_child(fishing_button)
	var fishing_medal := TextureRect.new()
	fishing_medal.position = Vector2(390, 38)
	fishing_medal.size = Vector2(150, 150)
	fishing_medal.visible = true
	root.add_child(fishing_medal)
	var fishing_action_id := "test-fishing-medal"
	var fishing_mastery_state := scene.get("mastery") as Dictionary
	fishing_mastery_state[scene.call("_action_key", "fishing", fishing_action_id)] = {"level": 20, "xp": 0}
	scene.set("mastery", fishing_mastery_state)
	var fishing_method_card := {
		"is_fishing_method": true,
		"skill_id": "fishing",
		"action_id": fishing_action_id,
		"medal": fishing_medal,
		"method_button": fishing_button,
		"method_hit_control": fishing_button,
	}
	var action_cards := {}
	action_cards[scene.call("_action_key", "fishing", fishing_action_id)] = fishing_method_card
	scene.set("action_cards", action_cards)
	var fishing_medal_center := fishing_medal.get_global_rect().get_center()
	var press_event := _mouse_button_event(fishing_medal_center, true)
	if not bool(scene.call("_on_fishing_method_button_input", press_event, "fishing", fishing_action_id, "test-area", 0, fishing_button)):
		_record("Fishing medal press was not handled")
	if str(fishing_button.get_meta("fishing_method_press_kind", "")) != "__medal__":
		_record("Fishing medal press did not store medal press kind")
	var release_event := _mouse_button_event(fishing_medal_center, false)
	if not bool(scene.call("_on_fishing_method_button_input", release_event, "fishing", fishing_action_id, "test-area", 0, fishing_button)):
		_record("Fishing medal release was not handled")
	if fishing_button.has_meta("fishing_method_press_kind"):
		_record("Fishing medal press kind was not cleared after release")
	if not fishing_method_card.has("medal_tap_tweens"):
		_record("Fishing medal release did not start medal tap ceremony")
	detail_scroll.queue_free()
	fishing_button.queue_free()
	fishing_medal.queue_free()

	if failures.is_empty():
		print("action-card-medal-ceremony-cleanup-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _record(message: String) -> void:
	failures.append(message)


func _fail(message: String) -> void:
	push_error("action-card-medal-ceremony-cleanup-fail: %s" % message)
	quit(1)


func _mouse_button_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	return event
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    $joinedOutput = $output -join "`n"
    Assert-True ($joinedOutput -match "action-card-medal-ceremony-cleanup-ok") "Action card medal ceremony cleanup smoke did not report success."
    Assert-True ($joinedOutput -notmatch "Trying to cast a freed object") "Action card medal ceremony cleanup tried to cast a freed object."

    $newHeadless = @()
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $newHeadless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
        if ($newHeadless.Count -eq 0) {
            break
        }
        Start-Sleep -Milliseconds 500
    }
    if ($newHeadless.Count -gt 0) {
        $newHeadless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A new headless Godot process is still running after action card medal ceremony cleanup smoke."
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
