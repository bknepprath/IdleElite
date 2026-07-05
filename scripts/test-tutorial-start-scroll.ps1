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

	scene.call("_test_state_runtime")._god_mode_unlock_onboarding_state()
	scene.call("_test_state_runtime")._god_mode_unlock_actions_state()
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("current_screen", "menu")
	var menu_render = scene.call("_navigation_shell").call("_render_screen", false, -1, false)
	if menu_render != null:
		await menu_render
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()

	scene.call("_save_runtime").call("reset_data")
	for _i in range(8):
		await _wait_test_frame()
	scene.call("_onboarding_runtime").call("_tutorial_check_progress")
	for _i in range(SETTLE_FRAMES):
		await _wait_test_frame()
		scene.call("_onboarding_runtime").call("_tutorial_check_progress")
		if _tutorial_skill_page_ready(scene):
			break

	if not _tutorial_skill_page_ready(scene):
		_fail("tutorial starter skill page was not ready: %s" % _summary(scene))
		return
	if int(scene._onboarding_runtime().tutorial_step) != 1:
		_fail("tutorial should start on the fight activity step: %s" % _summary(scene))
		return
	var scroll := scene._skill_detail_surface().detail_actions_scroll as ScrollContainer
	var shadow := scene._skill_detail_surface().detail_shelf_shadow_overlay as CanvasItem
	var scroll_y := int(scroll.scroll_vertical)
	var drag_y := float(scroll.get("drag_scroll_position"))
	var shadow_alpha := _shelf_shadow_alpha(shadow)
	var shadow_visible := false if shadow == null else shadow.visible
	var nav_bar := scene._navigation_shell().nav_bar as Control
	var module_utility_row := scene._navigation_shell().module_utility_row as Control
	var module_sort_menu := scene._navigation_shell().module_sort_menu as Control
	var auto_fish_toggle := scene.get("detail_auto_eat_fish_button") as Control
	var shelf_background := _find_named_descendant(scene._skill_detail_surface().detail_header_body as Node, "SkillDetailFullBleedShelfBackground") as Control
	var tutorial_panel := scene.get("tutorial_panel") as Control
	var tutorial_target_ring := scene.get("tutorial_target_ring") as Control
	var tutorial_target_label := scene.get("tutorial_target_label") as Control
	var tutorial_instruction_label := scene._tutorial_overlay_surface().tutorial_instruction_label as Label
	var detail_header_left_block := scene.get("detail_header_left_block") as Control
	var detail_xp_label := scene.get("detail_xp_label") as Control
	var detail_xp_bar := scene._skill_detail_surface().detail_xp_bar as Control
	var detail_regen_circle := scene._skill_detail_surface().detail_regen_circle as Control
	var tutorial_surface = scene._tutorial_overlay_surface()
	var activity_start_highlight := tutorial_surface.activity_start_highlight_border as Control
	if scroll_y != 0 or absf(drag_y) > 0.01:
		_fail("tutorial starter skill page should start at top scroll, got scroll=%s drag=%.3f %s" % [str(scroll_y), drag_y, _summary(scene)])
		return
	if shadow_visible and shadow_alpha > 0.001:
		_fail("tutorial starter skill page shelf shadow should be hidden, got alpha=%.4f %s" % [shadow_alpha, _summary(scene)])
		return
	if nav_bar == null or not nav_bar.visible:
		_fail("tutorial starter skill page bottom navigation shell should remain visible: %s" % _summary(scene))
		return
	if not _bottom_nav_locked_controls_ok(scene):
		_fail("tutorial starter skill page should show all nav buttons with skills/settings bright and other nav locked: %s" % _summary(scene))
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
	if tutorial_panel != null and tutorial_panel.visible:
		_fail("tutorial starter skill page should not show the legacy boxed tutorial panel: %s" % _summary(scene))
		return
	if tutorial_target_ring != null and _effective_canvas_alpha(tutorial_target_ring) > 0.01:
		_fail("tutorial starter skill page should not show the legacy target ring: %s" % _summary(scene))
		return
	if tutorial_target_label != null and _effective_canvas_alpha(tutorial_target_label) > 0.01:
		_fail("tutorial starter skill page should not show the legacy target label: %s" % _summary(scene))
		return
	if tutorial_instruction_label == null or not tutorial_instruction_label.is_visible_in_tree() or _effective_canvas_alpha(tutorial_instruction_label) <= 0.95:
		_fail("tutorial starter skill page should show readable instruction text: %s" % _summary(scene))
		return
	if tutorial_instruction_label.text != "Tap Push-Ups to start training.":
		_fail("tutorial starter skill page instruction text changed unexpectedly: %s %s" % [tutorial_instruction_label.text, _summary(scene)])
		return
	if detail_header_left_block != null and _effective_canvas_alpha(detail_header_left_block) > 0.01:
		_fail("tutorial starter skill page should hide the fighting icon and title: alpha=%.3f %s" % [_effective_canvas_alpha(detail_header_left_block), _summary(scene)])
		return
	if detail_xp_label != null and _effective_canvas_alpha(detail_xp_label) > 0.01:
		_fail("tutorial starter skill page should hide the fight XP label: alpha=%.3f %s" % [_effective_canvas_alpha(detail_xp_label), _summary(scene)])
		return
	if detail_xp_bar != null and _effective_canvas_alpha(detail_xp_bar) > 0.01:
		_fail("tutorial starter skill page should hide the fight XP bar: alpha=%.3f %s" % [_effective_canvas_alpha(detail_xp_bar), _summary(scene)])
		return
	if detail_regen_circle != null and _effective_canvas_alpha(detail_regen_circle) > 0.01:
		_fail("tutorial starter skill page should hide the stamina gauge: alpha=%.3f %s" % [_effective_canvas_alpha(detail_regen_circle), _summary(scene)])
		return
	if not get_nodes_in_group("stamina_cost_tip_notes").is_empty():
		_fail("tutorial starter skill page should not show the stamina tip: %s" % _summary(scene))
		return
	if get_nodes_in_group("activity_start_tip_notes").is_empty():
		_fail("tutorial starter skill page should show the brown activity-start instruction below the card: %s" % _summary(scene))
		return
	if activity_start_highlight != null and _effective_canvas_alpha(activity_start_highlight) > 0.01:
		_fail("tutorial starter skill page should not show the activity highlight immediately: alpha=%.3f %s" % [_effective_canvas_alpha(activity_start_highlight), _summary(scene)])
		return
	if _tutorial_module_count(scene) != 1:
		_fail("tutorial starter skill page should render only one activity module, got %s: %s" % [str(_tutorial_module_count(scene)), _summary(scene)])
		return
	if not _only_starter_activity_rendered(scene):
		_fail("tutorial starter skill page should render only Shove Wobbly Hay Bale, got %s: %s" % [str(_rendered_action_ids(scene)), _summary(scene)])
		return
	if not _tutorial_blocks_info_chip_expansion(scene):
		return
	if _has_page_switch_module(scene):
		_fail("tutorial starter skill page should hide page-switch controls: %s" % _summary(scene))
		return
	await _capture_if_requested()
	print("tutorial-start-scroll-ok scroll=%s drag=%.3f shadow_visible=%s shadow_alpha=%.4f modules=%s %s" % [str(scroll_y), drag_y, str(shadow_visible), shadow_alpha, str(_tutorial_module_count(scene)), _summary(scene)])
	quit(0)


func _tutorial_skill_page_ready(scene: Node) -> bool:
	if str(scene.get("current_screen")) != "skill":
		return false
	if str(scene.get("selected_skill_id")) != "fight":
		return false
	var scroll := scene._skill_detail_surface().detail_actions_scroll as ScrollContainer
	if scroll == null or not scroll.is_inside_tree():
		return false
	var cards := scene.get("action_cards") as Dictionary
	return cards != null and cards.size() > 0


func _tutorial_module_count(scene: Node) -> int:
	return _rendered_action_ids(scene).size()


func _only_starter_activity_rendered(scene: Node) -> bool:
	var ids := _rendered_action_ids(scene)
	return ids.size() == 1 and ids[0] == "shove-wobbly-hay-bale"


func _tutorial_blocks_info_chip_expansion(scene: Node) -> bool:
	var cards := scene.get("action_cards") as Dictionary
	if cards == null:
		_fail("tutorial info-chip block smoke could not read action cards: %s" % _summary(scene))
		return false
	var card := cards.get("fight:shove-wobbly-hay-bale", {}) as Dictionary
	if card.is_empty():
		_fail("tutorial info-chip block smoke could not find starter card: %s" % _summary(scene))
		return false
	var stat_boxes := card.get("stat_boxes", {}) as Dictionary
	var stat_box := stat_boxes.get("xp", null) as Control
	if stat_box == null or not is_instance_valid(stat_box):
		_fail("tutorial info-chip block smoke could not find starter XP chip box: %s" % _summary(scene))
		return false
	var stat_center := stat_box.get_global_rect().get_center()
	var skill_detail_surface = scene.call("_skill_detail_surface")
	if not str(skill_detail_surface.call("_activity_stat_kind_at_position", card, stat_center)).is_empty():
		_fail("tutorial info-chip hit test should ignore hidden starter stat chips: %s" % _summary(scene))
		return false
	skill_detail_surface.call("_toggle_activity_stat_popup_for_card", card, "fight", "shove-wobbly-hay-bale", "xp")
	scene.call("_update_ui", 0.0, true)
	if str(skill_detail_surface.get("expanded_activity_stat_key")) != "" or str(skill_detail_surface.get("expanded_activity_stat_kind")) != "":
		_fail("tutorial info-chip tap expanded the starter module: key=%s kind=%s %s" % [
			str(skill_detail_surface.get("expanded_activity_stat_key")),
			str(skill_detail_surface.get("expanded_activity_stat_kind")),
			_summary(scene)
		])
		return false
	if card.get("bonus_expanded", false) == true:
		_fail("tutorial info-chip tap left the starter card bonus panel expanded: %s" % _summary(scene))
		return false
	return true


func _bottom_nav_locked_controls_ok(scene: Node) -> bool:
	return _bottom_nav_row_visible(scene) and _all_nav_buttons_visible(scene) and _settings_nav_button_enabled(scene) and _skills_nav_button_enabled(scene) and _non_settings_nav_buttons_locked(scene)


func _bottom_nav_row_visible(scene: Node) -> bool:
	var nav_bar := scene._navigation_shell().nav_bar as Control
	if nav_bar == null or not is_instance_valid(nav_bar):
		return false
	var row := scene._navigation_shell().bottom_nav_buttons_row as Control
	if row == null:
		row = _find_named_descendant(nav_bar, "BottomNavButtonsRow") as Control
	return row != null and row.is_visible_in_tree() and _effective_canvas_alpha(row) > 0.01


func _all_nav_buttons_visible(scene: Node) -> bool:
	for raw_name in ["hero_tab", "hub_tab", "skills_tab", "settings_tab", "shop_tab"]:
		var button := _nav_button(scene, raw_name) as Control
		if button == null or not button.is_visible_in_tree() or _effective_canvas_alpha(button) <= 0.01:
			return false
	return true


func _settings_nav_button_enabled(scene: Node) -> bool:
	var settings := _nav_button(scene, "settings_tab") as Button
	return settings != null and settings.is_visible_in_tree() and _effective_canvas_alpha(settings) > 0.01 and not settings.disabled and settings.mouse_filter == Control.MOUSE_FILTER_STOP


func _skills_nav_button_enabled(scene: Node) -> bool:
	var skills := _nav_button(scene, "skills_tab") as Button
	return skills != null and skills.is_visible_in_tree() and _effective_canvas_alpha(skills) > 0.01 and not skills.disabled and skills.mouse_filter == Control.MOUSE_FILTER_STOP and _color_nearly_equal(skills.modulate, Color.WHITE)


func _non_settings_nav_buttons_locked(scene: Node) -> bool:
	for raw_name in ["hero_tab", "hub_tab", "shop_tab"]:
		var button := _nav_button(scene, raw_name) as Button
		if button == null or not button.is_visible_in_tree() or _effective_canvas_alpha(button) <= 0.01:
			return false
		if button.disabled or button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
			return false
		if not _color_nearly_equal(button.modulate, Color("#3f3f3f")):
			return false
	return true


func _nav_button(scene: Node, button_name: String) -> Button:
	match button_name:
		"hero_tab", "hub_tab", "shop_tab":
			return scene._navigation_shell().get(button_name) as Button
		_:
			return scene.get(button_name) as Button


func _color_nearly_equal(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.01 and absf(a.g - b.g) < 0.01 and absf(a.b - b.b) < 0.01 and absf(a.a - b.a) < 0.01


func _rendered_action_ids(scene: Node) -> Array:
	var ids := []
	var cards := scene.get("action_cards") as Dictionary
	if cards == null:
		return ids
	for raw_key in cards.keys():
		var key := str(raw_key)
		if key.begins_with("fight:"):
			ids.append(key.substr("fight:".length()))
	ids.sort()
	return ids


func _has_page_switch_module(scene: Node) -> bool:
	var stack := _tutorial_detail_stack(scene)
	if stack == null:
		return false
	for raw_child in stack.get_children():
		var child := raw_child as Node
		if child == null:
			continue
		if _find_named_descendant(child, "PageSwitchModule") != null:
			return true
	return false


func _effective_canvas_alpha(node: Node) -> float:
	if node == null or not is_instance_valid(node):
		return 0.0
	var alpha := 1.0
	var current := node
	while current != null:
		if current is CanvasItem:
			var item := current as CanvasItem
			if not item.visible:
				return 0.0
			alpha *= item.modulate.a * item.self_modulate.a
		current = current.get_parent()
	return alpha


func _tutorial_detail_stack(scene: Node) -> VBoxContainer:
	var scroll := scene._skill_detail_surface().detail_actions_scroll as ScrollContainer
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
	var scroll := scene._skill_detail_surface().detail_actions_scroll as ScrollContainer
	var scroll_text := "none"
	if scroll != null:
		scroll_text = "%s/%.3f max=%s" % [str(scroll.scroll_vertical), float(scroll.get("drag_scroll_position")), str(scroll.call("get_max_scroll_vertical")) if scroll.has_method("get_max_scroll_vertical") else "?"]
	var shadow := scene._skill_detail_surface().detail_shelf_shadow_overlay as CanvasItem
	var shadow_text := "none"
	if shadow != null:
		shadow_text = "visible=%s alpha=%.4f" % [str(shadow.visible), _shelf_shadow_alpha(shadow)]
	return "screen=%s selected=%s tutorial=%s step=%s scroll=%s shadow=%s" % [
		str(scene.get("current_screen")),
		str(scene.get("selected_skill_id")),
		str(scene._onboarding_runtime().tutorial_active),
		str(scene._onboarding_runtime().tutorial_step),
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
			scene.get("startup_initialized") == true
			and scene.get("boot_detail_render_in_progress") != true
			and scene.get("boot_detail_scroll_locked") != true
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

    $baselineHeadlessProcessIds = @{}
    foreach ($process in @(Get-HeadlessGodotProcesses)) {
        $baselineHeadlessProcessIds[[int]$process.ProcessId] = $true
    }
    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "tutorial-start-scroll-ok") "Tutorial start scroll test did not report success."
    $captureOutput = ($output -join "`n") -match "tutorial-start-scroll-capture (path=|skipped=)"
    Assert-True ((Test-Path -LiteralPath $capturePath) -or $captureOutput) "Tutorial hidden-controls screenshot was not created or cleanly skipped at $capturePath."
    Assert-NoUnexpectedGodotErrors $output "tutorial start scroll test"

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
