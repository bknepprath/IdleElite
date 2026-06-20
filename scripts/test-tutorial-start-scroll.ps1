$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\tutorial-start-scroll"
$testScript = Join-Path $testDir "tutorial_start_scroll_test.gd"
$capturePath = Join-Path $projectRoot ".codex-tmp\tutorial-intro-hidden-controls.png"

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
New-Item -ItemType Directory -Path (Split-Path -Parent $capturePath) -Force | Out-Null
Remove-Item -LiteralPath $capturePath -Force -ErrorAction SilentlyContinue

$previousTimeout = $env:GODOT_RUN_TIMEOUT_SECONDS
$previousCapture = $env:IDLE_ELITE_TUTORIAL_START_SCROLL_CAPTURE
$env:GODOT_RUN_TIMEOUT_SECONDS = "180"
$env:IDLE_ELITE_TUTORIAL_START_SCROLL_CAPTURE = $capturePath

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720
const SETTLE_FRAMES := 120
const TEST_FRAME_SECONDS := 1.0 / 120.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("tutorial-start-scroll-start")
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
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("current_screen", "menu")
	var menu_render = scene.call("_render_screen", false, -1, false)
	if menu_render != null:
		await menu_render
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()

	scene.call("_start_tutorial")
	for _i in range(8):
		await _wait_test_frame()
	scene.call("_tutorial_check_progress")
	scene.call("_select_skill", "fight")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_tutorial_check_progress")
		if _tutorial_skill_page_ready(scene):
			break

	if not _tutorial_skill_page_ready(scene):
		_fail("tutorial starter skill page was not ready: %s" % _summary(scene))
		return
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	var shadow := scene.get("detail_shelf_shadow_overlay") as CanvasItem
	var scroll_y := int(scroll.scroll_vertical)
	var drag_y := float(scroll.get("drag_scroll_position"))
	var shadow_alpha := _shelf_shadow_alpha(shadow)
	var shadow_visible := false if shadow == null else shadow.visible
	var nav_bar := scene.get("nav_bar") as Control
	var module_utility_row := scene.get("module_utility_row") as Control
	var module_sort_menu := scene.get("module_sort_menu") as Control
	var auto_fish_toggle := scene.get("detail_auto_eat_fish_button") as Control
	var shelf_background := _find_named_descendant(scene.get("detail_header_body") as Node, "SkillDetailFullBleedShelfBackground") as Control
	if scroll_y != 0 or absf(drag_y) > 0.01:
		_fail("tutorial starter skill page should start at top scroll, got scroll=%s drag=%.3f %s" % [str(scroll_y), drag_y, _summary(scene)])
		return
	if shadow_visible and shadow_alpha > 0.001:
		_fail("tutorial starter skill page shelf shadow should be hidden, got alpha=%.4f %s" % [shadow_alpha, _summary(scene)])
		return
	if nav_bar != null and nav_bar.visible:
		_fail("tutorial starter skill page bottom navigation should be hidden: %s" % _summary(scene))
		return
	if module_utility_row != null and module_utility_row.visible:
		_fail("tutorial starter skill page module utility row should be hidden: %s" % _summary(scene))
		return
	if module_sort_menu != null and module_sort_menu.visible:
		_fail("tutorial starter skill page sort menu should be hidden: %s" % _summary(scene))
		return
	if auto_fish_toggle != null and auto_fish_toggle.visible:
		_fail("tutorial starter skill page auto-fish toggle should be hidden before fish is earned: %s" % _summary(scene))
		return
	if shelf_background != null and shelf_background.visible:
		_fail("tutorial starter skill page colored shelf background should be hidden: %s" % _summary(scene))
		return
	if _activity_start_tip_before_second_module(scene):
		_fail("tutorial starter skill page should not place the activity-start tip between module 1 and 2: %s" % _summary(scene))
		return
	var first_module_gap := _tutorial_first_two_module_gap(scene)
	if first_module_gap < 0.0:
		_fail("tutorial starter skill page did not expose two modules for gap check: %s" % _summary(scene))
		return
	if first_module_gap > 120.0:
		_fail("tutorial starter skill page module 1-2 gap is too large: %.1f %s" % [first_module_gap, _summary(scene)])
		return
	await _capture_if_requested()
	print("tutorial-start-scroll-ok scroll=%s drag=%.3f shadow_visible=%s shadow_alpha=%.4f module_gap=%.1f %s" % [str(scroll_y), drag_y, str(shadow_visible), shadow_alpha, first_module_gap, _summary(scene)])
	quit(0)


func _tutorial_skill_page_ready(scene: Node) -> bool:
	if str(scene.get("current_screen")) != "skill":
		return false
	if str(scene.get("selected_skill_id")) != "fight":
		return false
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not scroll.is_inside_tree():
		return false
	var cards := scene.get("action_cards") as Dictionary
	return cards != null and cards.size() > 0


func _activity_start_tip_before_second_module(scene: Node) -> bool:
	var stack := _tutorial_detail_stack(scene)
	if stack == null:
		return false
	var module_count := 0
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null:
			continue
		if _control_tree_in_group(child, "activity_start_tip_notes"):
			return module_count < 2
		if bool(scene.call("_detail_stack_child_is_module_content", child)):
			module_count += 1
			if module_count >= 2:
				return false
	return false


func _tutorial_first_two_module_gap(scene: Node) -> float:
	var stack := _tutorial_detail_stack(scene)
	if stack == null:
		return -1.0
	var modules := []
	for raw_child in stack.get_children():
		var child := raw_child as Control
		if child == null:
			continue
		if bool(scene.call("_detail_stack_child_is_module_content", child)):
			modules.append(child)
			if modules.size() >= 2:
				break
	if modules.size() < 2:
		return -1.0
	var first := modules[0] as Control
	var second := modules[1] as Control
	var first_height := maxf(first.size.y, first.custom_minimum_size.y)
	return second.position.y - (first.position.y + first_height)


func _tutorial_detail_stack(scene: Node) -> VBoxContainer:
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if scroll == null or not scroll.is_inside_tree() or scroll.get_child_count() <= 0:
		return null
	return scroll.get_child(0) as VBoxContainer


func _control_tree_in_group(root_node: Node, group_name: String) -> bool:
	if root_node == null:
		return false
	if root_node.is_in_group(group_name):
		return true
	for raw_child in root_node.get_children():
		var child := raw_child as Node
		if child != null and _control_tree_in_group(child, group_name):
			return true
	return false


func _find_named_descendant(root_node: Node, node_name: String) -> Node:
	if root_node == null:
		return null
	if root_node.name == node_name:
		return root_node
	for raw_child in root_node.get_children():
		var child := raw_child as Node
		var found := _find_named_descendant(child, node_name)
		if found != null:
			return found
	return null


func _capture_if_requested() -> void:
	var capture_path := OS.get_environment("IDLE_ELITE_TUTORIAL_START_SCROLL_CAPTURE")
	if capture_path.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		print("tutorial-start-scroll-capture skipped=headless-display")
		return
	for _i in range(2):
		await _wait_test_frame()
	var texture := root.get_texture()
	if texture == null:
		print("tutorial-start-scroll-capture skipped=no-texture")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("tutorial-start-scroll-capture skipped=empty-image")
		return
	var result := image.save_png(capture_path)
	print("tutorial-start-scroll-capture path=%s result=%s size=%sx%s" % [capture_path, str(result), image.get_width(), image.get_height()])


func _summary(scene: Node) -> String:
	var scroll := scene.get("detail_actions_scroll") as ScrollContainer
	var scroll_text := "none"
	if scroll != null:
		scroll_text = "%s/%.3f max=%s" % [str(scroll.scroll_vertical), float(scroll.get("drag_scroll_position")), str(scroll.call("get_max_scroll_vertical")) if scroll.has_method("get_max_scroll_vertical") else "?"]
	var shadow := scene.get("detail_shelf_shadow_overlay") as CanvasItem
	var shadow_text := "none"
	if shadow != null:
		shadow_text = "visible=%s alpha=%.4f" % [str(shadow.visible), _shelf_shadow_alpha(shadow)]
	return "screen=%s selected=%s tutorial=%s step=%s scroll=%s shadow=%s" % [
		str(scene.get("current_screen")),
		str(scene.get("selected_skill_id")),
		str(scene.get("tutorial_active")),
		str(scene.get("tutorial_step")),
		scroll_text,
		shadow_text
	]


func _shelf_shadow_alpha(shadow: Node) -> float:
	if shadow == null:
		return 0.0
	var raw_alpha = shadow.get("shadow_alpha")
	if raw_alpha != null:
		return float(raw_alpha)
	if shadow is CanvasItem:
		return (shadow as CanvasItem).modulate.a
	return 0.0


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
	push_error("tutorial-start-scroll-fail: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "tutorial-start-scroll-ok") "Tutorial start scroll test did not report success."
    $captureOutput = ($output -join "`n") -match "tutorial-start-scroll-capture (path=|skipped=)"
    Assert-True ((Test-Path -LiteralPath $capturePath) -or $captureOutput) "Tutorial hidden-controls screenshot was not created or cleanly skipped at $capturePath."
    Assert-NoUnexpectedGodotErrors $output "tutorial start scroll test"

    $headless = @(Get-HeadlessGodotProcesses)
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after the tutorial start scroll test."
    }
} finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousCapture) {
        Remove-Item Env:\IDLE_ELITE_TUTORIAL_START_SCROLL_CAPTURE -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_TUTORIAL_START_SCROLL_CAPTURE = $previousCapture
    }
    if (Test-Path -LiteralPath $testDir) {
        Remove-Item -LiteralPath $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}
