$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "lib\godot-processes.ps1")

$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\home-achievement-medal-click"
$testScript = Join-Path $testDir "home_achievement_medal_click.gd"
$capturePath = Join-Path $testDir "home-achievement-medal-popover.png"

function Assert-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $runner) "Missing run-godot-safe.ps1."

if (Test-Path -LiteralPath $testDir) {
    Remove-Item -LiteralPath $testDir -Recurse -Force
}
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapturePath = $env:IDLE_ELITE_HOME_ACHIEVEMENT_MEDAL_CLICK_PNG
$env:GODOT_RUN_TIMEOUT_SECONDS = "120"
$env:IDLE_ELITE_HOME_ACHIEVEMENT_MEDAL_CLICK_PNG = $capturePath

$baselineHeadlessProcessIds = @{}
foreach ($process in @(Get-HeadlessGodotProcesses)) {
    $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
}

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("home-achievement-medal-click-start")
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
	if not await _wait_for_boot_hidden(scene):
		_fail("boot splash did not hide before home achievement medal test")
		return
	scene.call("_close_offline_summary_overlay")
	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_max_skills_state")
	scene.call("_god_mode_unlock_actions_state")
	scene.call("_god_mode_max_medals_state")
	scene.call("_show_home")
	if not await _wait_for_home_medals(scene):
		_fail("home medals did not become visible")
		return

	var icon := _first_visible_home_medal_icon(scene)
	if icon == null:
		_fail("no visible home medal icon found")
		return
	var featured_icon := scene.get("achievement_best_medal") as TextureRect
	if (
		featured_icon == null
		or not is_instance_valid(featured_icon)
		or not featured_icon.visible
		or not featured_icon.is_visible_in_tree()
	):
		_fail("no visible featured achievement medal icon found")
		return
	var home_page := scene.get("home_page") as Control
	var skills_page := scene.get("skills_page") as Control
	if home_page == null or not home_page.is_visible_in_tree():
		_fail("home page was not visible before medal click")
		return
	if skills_page != null and skills_page.visible:
		_fail("skills page should be hidden while the home medal strip is visible")
		return

	if not await _click_icon_expect_home_popover(scene, featured_icon, home_page, "featured home medal"):
		return
	scene.call("_hide_achievement_medal_popovers")
	await process_frame
	if not await _click_icon_expect_home_popover(scene, icon, home_page, "skill row home medal"):
		return
	if not await _capture_if_possible():
		print("home-achievement-medal-click-capture skipped")

	if failures.is_empty():
		print("home-achievement-medal-click-ok")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_for_boot_ready(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
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


func _wait_for_boot_hidden(scene: Node) -> bool:
	for _frame in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
		var overlay := scene.get("boot_warmup_overlay") as Control
		if not bool(scene.get("boot_warmup_active")) and (overlay == null or not overlay.visible or overlay.modulate.a <= 0.01):
			return true
	return false


func _wait_for_home_medals(scene: Node) -> bool:
	for _frame in range(240):
		scene.call("_update_ui", 0.016, false)
		await process_frame
		if _first_visible_home_medal_icon(scene) != null and _visible_featured_home_medal_icon(scene) != null:
			return true
	return false


func _visible_featured_home_medal_icon(scene: Node) -> TextureRect:
	var featured_icon := scene.get("achievement_best_medal") as TextureRect
	if (
		featured_icon != null
		and is_instance_valid(featured_icon)
		and featured_icon.visible
		and featured_icon.is_visible_in_tree()
		and int(featured_icon.get_meta("achievement_medal_level", 0)) > 0
		and not str(featured_icon.get_meta("achievement_skill_id", "")).is_empty()
	):
		return featured_icon
	return null


func _first_visible_home_medal_icon(scene: Node) -> TextureRect:
	var icon_rows_by_skill := scene.get("achievement_medal_slot_icons") as Dictionary
	if icon_rows_by_skill == null:
		return null
	for raw_skill_id in icon_rows_by_skill.keys():
		var rows := icon_rows_by_skill.get(raw_skill_id, []) as Array
		for raw_row in rows:
			var row := raw_row as Array
			for raw_icon in row:
				var icon := raw_icon as TextureRect
				if (
					icon != null
					and is_instance_valid(icon)
					and icon.visible
					and icon.is_visible_in_tree()
					and int(icon.get_meta("achievement_medal_level", 0)) > 0
				):
					return icon
	return null


func _single_visible_medal_popover(scene: Node, record_failure := true) -> Control:
	var visible_popovers: Array[Control] = []
	for raw_popover in scene.get_tree().get_nodes_in_group("achievement_medal_popovers"):
		var popover := raw_popover as Control
		if popover != null and is_instance_valid(popover) and popover.visible and popover.is_visible_in_tree():
			visible_popovers.append(popover)
	if visible_popovers.size() != 1:
		if record_failure:
			_record("expected exactly one visible medal popover, found %s" % visible_popovers.size())
		return null
	return visible_popovers[0]


func _click_icon_expect_home_popover(scene: Node, icon: TextureRect, home_page: Control, context: String) -> bool:
	if int(icon.get_meta("achievement_medal_level", 0)) <= 0:
		_fail("%s missing achievement_medal_level metadata" % context)
		return false
	var click_point := icon.get_global_rect().get_center()
	var press_event := _mouse_button_event(click_point, true)
	scene.call("_input", press_event)
	if _single_visible_medal_popover(scene, false) == null:
		scene.call("_route_achievement_medal_press", press_event)
	await process_frame
	scene.call("_input", _mouse_button_event(click_point, false))
	for _frame in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var popover := _single_visible_medal_popover(scene)
	if popover == null:
		_fail("%s click did not create a visible popover" % context)
		return false
	if popover.get_parent() != home_page:
		_fail("%s popover parent was %s instead of home_page" % [context, str(popover.get_parent())])
		return false
	if not popover.get_global_rect().has_point(popover.get_global_rect().get_center()):
		_fail("%s popover global rect was invalid" % context)
		return false
	return true


func _mouse_button_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	return event


func _capture_if_possible() -> bool:
	var capture_path := OS.get_environment("IDLE_ELITE_HOME_ACHIEVEMENT_MEDAL_CLICK_PNG")
	if capture_path.is_empty():
		return false
	if DisplayServer.get_name() == "headless":
		return false
	await process_frame
	var texture := root.get_texture()
	if texture == null:
		return false
	var image := texture.get_image()
	if image == null or image.is_empty():
		return false
	var result := image.save_png(capture_path)
	if result == OK:
		print("home-achievement-medal-click-capture path=%s size=%sx%s" % [
			capture_path,
			image.get_width(),
			image.get_height()
		])
		return true
	print("home-achievement-medal-click-capture failed code=%s" % result)
	return false


func _record(message: String) -> void:
	failures.append(message)


func _fail(message: String) -> void:
	push_error("home-achievement-medal-click-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "home-achievement-medal-click-ok") "Home achievement medal click smoke did not report success."

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
        throw "A new headless Godot process is still running after home achievement medal click smoke."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCapturePath) {
        Remove-Item Env:\IDLE_ELITE_HOME_ACHIEVEMENT_MEDAL_CLICK_PNG -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_HOME_ACHIEVEMENT_MEDAL_CLICK_PNG = $previousCapturePath
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
