$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\fishing-click-flow"
$testScript = Join-Path $testDir "fishing_click_flow.gd"

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

func _capture_if_requested(label: String) -> void:
	var capture_dir := OS.get_environment("IDLE_ELITE_FISHING_CLICK_FLOW_CAPTURE_DIR")
	if capture_dir.is_empty():
		return
	if DisplayServer.get_name() == "headless":
		print("fishing-click-flow-capture skipped=headless label=%s" % label)
		return
	var texture := root.get_texture()
	if texture == null:
		print("fishing-click-flow-capture skipped=no-texture label=%s display=%s" % [label, DisplayServer.get_name()])
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		print("fishing-click-flow-capture skipped=empty-image label=%s display=%s" % [label, DisplayServer.get_name()])
		return
	var safe_label := label.replace(" ", "-").replace("/", "-").replace("\\", "-")
	var path := "%s/%s-pressed.png" % [capture_dir, safe_label]
	var result := image.save_png(path)
	print("fishing-click-flow-capture path=%s result=%s size=%sx%s display=%s" % [
		path,
		str(result),
		str(image.get_width()),
		str(image.get_height()),
		DisplayServer.get_name()
	])

func _init() -> void:
	call_deferred("_run")

func _mouse_button_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	return event

func _screen_touch_event(point: Vector2, pressed: bool) -> InputEventScreenTouch:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.pressed = pressed
	event.position = point
	return event

func _find_page_switch_button(root_node: Node, target_skill_id: String) -> Button:
	if root_node == null:
		return null
	var button := root_node as Button
	if (
		button != null
		and button.is_inside_tree()
		and button.is_visible_in_tree()
		and str(button.get_meta("page_switch_target_skill_id", "")) == target_skill_id
	):
		return button
	for child in root_node.get_children():
		var found := _find_page_switch_button(child, target_skill_id)
		if found != null:
			return found
	return null

func _click_page_switch_button(scene: Node, target_skill_id: String, label: String) -> bool:
	scene.call("_sync_detail_actions_scroll_limit")
	var detail_scroll := scene.get("detail_actions_scroll") as ScrollContainer
	if detail_scroll != null and is_instance_valid(detail_scroll):
		var max_scroll: int = detail_scroll.get_max_scroll_vertical()
		detail_scroll.scroll_vertical = max_scroll
		detail_scroll.set("drag_scroll_position", float(max_scroll))
	for _frame in range(8):
		await process_frame
	var page_switch_button := _find_page_switch_button(scene, target_skill_id)
	if page_switch_button == null:
		push_error("Fishing click flow could not find %s page switch button for skill: %s" % [label, target_skill_id])
		return false
	var page_switch_point := page_switch_button.get_global_rect().get_center()
	var direct_hit := scene.call("_page_switch_button_at_position", page_switch_point) as Button
	scene.call("_input", _mouse_button_event(page_switch_point, true))
	for _frame in range(3):
		await process_frame
	if not bool(page_switch_button.get_meta("page_switch_press_active", false)):
		var scroll_debug := ""
		if detail_scroll != null and is_instance_valid(detail_scroll):
			var visible_content := scene.call("_detail_authoritative_scrollable_module_bottom") as Dictionary
			scroll_debug = " scroll=%s max=%s viewport=%s" % [
				str(detail_scroll.scroll_vertical),
				str(detail_scroll.get_max_scroll_vertical()),
				str(detail_scroll.get_global_rect())
			]
			scroll_debug += " visible_bottom=%s visible_count=%s page_switch_bottom=%s effective_viewport=%s bottom_pad=%s inset=%s" % [
				str(visible_content.get("bottom", "?")),
				str(visible_content.get("count", "?")),
				str(scene.call("_detail_stack_page_switch_bottom")),
				str(scene.call("_detail_actions_scroll_viewport_height")),
				str(scene.call("_skill_detail_bottom_scroll_pad", str(scene.get("selected_skill_id")))),
				str(scene.call("_skills_content_bottom_inset_for_screen"))
			]
		push_error("Fishing %s page-switch button did not receive press. target=%s point=%s rect=%s current=%s%s" % [
			label,
			target_skill_id,
			str(page_switch_point),
			str(page_switch_button.get_global_rect()) + " direct_hit=" + str(direct_hit == page_switch_button),
			str(scene.get("selected_skill_id")),
			scroll_debug
		])
		return false
	var pop := instance_from_id(int(page_switch_button.get_meta("activity_button_pop_id", 0))) as Control
	if pop == null or not is_instance_valid(pop):
		push_error("Fishing %s page-switch button has no animated shell pop control." % label)
		return false
	var pressed_offset := scene.call("_activity_button_pop_depth_offset", pop) as Vector2
	if pressed_offset.length() <= 0.5:
		push_error("Fishing %s page-switch button did not show press animation. offset=%s target=%s" % [
			label,
			str(pressed_offset),
			str(page_switch_button.get_meta("activity_button_depth_offset", Vector2.ZERO))
		])
		return false
	await _capture_if_requested(label)
	scene.call("_input", _mouse_button_event(page_switch_point, false))
	for _frame in range(90):
		await process_frame
		if str(scene.get("current_screen")) == "skill" and str(scene.get("selected_skill_id")) == target_skill_id:
			break
	if str(scene.get("selected_skill_id")) != target_skill_id:
		push_error("Fishing %s page-switch button release did not navigate. target=%s selected=%s screen=%s cover=%s" % [
			label,
			target_skill_id,
			str(scene.get("selected_skill_id")),
			str(scene.get("current_screen")),
			str(scene.call("_page_switch_scroll_cover_active")) + " global_active=" + str(scene.get("page_switch_press_active")) + " pending=" + str(scene.get("page_switch_pending_transition")) + " release_wait=" + str(scene.get("page_switch_release_when_render_idle")) + " render=" + str(scene.get("screen_render_in_progress")) + " request=" + str(scene.get("pending_screen_render_request"))
		])
		return false
	for _frame in range(90):
		await process_frame
		if not bool(scene.call("_page_switch_scroll_cover_active")) and int(scene.get("page_switch_transition_button_id")) == 0:
			break
	if bool(scene.call("_page_switch_scroll_cover_active")) or int(scene.get("page_switch_transition_button_id")) != 0:
		push_error("Fishing %s page-switch transition did not release before the next click. cover=%s lock=%s" % [
			label,
			str(scene.call("_page_switch_scroll_cover_active")),
			str(scene.get("page_switch_transition_button_id"))
		])
		return false
	return true

func _click_module_utility_button(scene: Node, button_name: String, button: Button) -> bool:
	if button == null or not is_instance_valid(button) or not button.is_inside_tree() or not button.is_visible_in_tree():
		push_error("Fishing utility %s button was not visible." % button_name)
		return false
	var click_point := button.get_global_rect().get_center()
	scene.call("_input", _mouse_button_event(click_point, true))
	for _frame in range(2):
		await process_frame
	scene.call("_input", _mouse_button_event(click_point, false))
	for _frame in range(12):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	return true

func _restore_skill_page(scene: Node, skill_id: String) -> void:
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	scene.set("_last_rendered_screen_key", "")
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _frame in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	scene.call("_sync_module_utility_row_visibility")

func _restore_fishing_page(scene: Node) -> void:
	await _restore_skill_page(scene, "fishing")

func _check_fishing_bottom_utility_buttons(scene: Node) -> bool:
	scene.set("module_utility_collapsed", false)
	scene.call("_sync_module_utility_row_visibility")
	var settings_button := scene.get("settings_tab") as Button
	if not await _click_module_utility_button(scene, "settings", settings_button):
		return false
	if str(scene.get("current_screen")) != "settings":
		push_error("Fishing bottom nav settings button did not open settings. screen=%s" % str(scene.get("current_screen")))
		return false
	if not await _click_module_utility_button(scene, "settings red x", settings_button):
		return false
	if str(scene.get("current_screen")) != "skill" or str(scene.get("selected_skill_id")) != "fishing":
		push_error("Fishing settings red X returned to the wrong detail page. screen=%s selected=%s" % [
			str(scene.get("current_screen")),
			str(scene.get("selected_skill_id"))
		])
		return false
	await _restore_fishing_page(scene)

	await _restore_skill_page(scene, "thieving")
	settings_button = scene.get("settings_tab") as Button
	if not await _click_module_utility_button(scene, "settings from thieving", settings_button):
		return false
	if str(scene.get("current_screen")) != "settings":
		push_error("Thieving bottom nav settings button did not open settings. screen=%s" % str(scene.get("current_screen")))
		return false
	if not await _click_module_utility_button(scene, "settings red x from thieving", settings_button):
		return false
	if str(scene.get("current_screen")) != "skill" or str(scene.get("selected_skill_id")) != "thieving":
		push_error("Thieving settings red X returned to the wrong detail page. screen=%s selected=%s" % [
			str(scene.get("current_screen")),
			str(scene.get("selected_skill_id"))
		])
		return false
	await _restore_fishing_page(scene)

	var sort_button := scene.get("sort_utility_tab") as Button
	if not await _click_module_utility_button(scene, "sort", sort_button):
		return false
	var sort_menu := scene.get("module_sort_menu") as Control
	if sort_menu == null or not is_instance_valid(sort_menu) or not sort_menu.visible:
		push_error("Fishing utility sort button did not open the module sort menu.")
		return false
	scene.call("_hide_module_sort_menu", false)
	for _frame in range(4):
		await process_frame

	var skills_button := scene.get("skills_utility_tab") as Button
	if not await _click_module_utility_button(scene, "skills", skills_button):
		return false
	if str(scene.get("current_screen")) != "menu":
		push_error("Fishing utility skills button did not open the full skill page. screen=%s" % str(scene.get("current_screen")))
		return false
	await _restore_fishing_page(scene)

	var pinned_button := scene.get("pinned_utility_tab") as Button
	if not await _click_module_utility_button(scene, "pinned", pinned_button):
		return false
	for _frame in range(90):
		scene.call("_update_ui", 0.016, false)
		await process_frame
		if str(scene.get("current_screen")) == "pinned":
			break
	if str(scene.get("current_screen")) != "pinned":
		push_error("Fishing utility pinned button did not open the pinned page. screen=%s" % str(scene.get("current_screen")))
		return false
	await _restore_fishing_page(scene)
	return true

func _check_fishing_page_switch_buttons(scene: Node) -> bool:
	var page_neighbors := scene.call("_skill_page_neighbor_ids", "fishing") as Dictionary
	var previous_skill_id := str(page_neighbors.get("previous", ""))
	var next_skill_id := str(page_neighbors.get("next", ""))
	if previous_skill_id.is_empty() or next_skill_id.is_empty():
		push_error("Fishing page-switch neighbors were missing: %s" % str(page_neighbors))
		return false
	if not await _click_page_switch_button(scene, previous_skill_id, "left Woodcutting"):
		return false
	await _restore_fishing_page(scene)
	if not await _click_page_switch_button(scene, next_skill_id, "right Fighting"):
		return false
	await _restore_fishing_page(scene)
	return true

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
	fishing["level"] = 1
	fishing["xp"] = 0
	skills["fishing"] = fishing
	scene.set("skills", skills)
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	scene.set("equipped_fishing_tool_id", "hands")
	scene.set("selected_fishing_locations", {"beach": "rocky"})
	scene.set("module_ui_sort_mode", "level")
	scene.set("module_ui_pinned_order", [])
	scene.set("module_ui_collapsed", {})
	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_mark_action_manually_unlocked", "fishing", "beach-shallows")
	scene.call("_clear_running_activity_for_test_mode")
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _frame in range(30):
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	if not await _check_fishing_bottom_utility_buttons(scene):
		quit(1)
		return
	if not await _check_fishing_page_switch_buttons(scene):
		quit(1)
		return
	var area_card := {}
	for raw_card in (scene.get("action_cards") as Dictionary).values():
		var card := raw_card as Dictionary
		if bool(card.get("is_fishing_area", false)) and str(card.get("area_id", "")) == "beach":
			area_card = card
			break
	if area_card.is_empty():
		push_error("Fishing click flow could not find the rendered Beach area card.")
		quit(1)
		return
	for raw_card in (scene.get("action_cards") as Dictionary).values():
		var fishing_area_card := raw_card as Dictionary
		if not bool(fishing_area_card.get("is_fishing_area", false)):
			continue
		if not str(fishing_area_card.get("action_id", "")).is_empty():
			push_error("Fishing area card inherited a fake action id and can grow a duplicate generic lock: %s" % str(fishing_area_card.get("action_id", "")))
			quit(1)
			return
		if not (fishing_area_card.get("lock_overlay", {}) as Dictionary).is_empty():
			push_error("Fishing area card created a generic activity lock overlay on top of method padlocks.")
			quit(1)
			return
	var method_card := {}
	for raw_method_card in (area_card.get("method_slots", {}) as Dictionary).values():
		var candidate := raw_method_card as Dictionary
		if str(candidate.get("action_id", "")) == "beach-shallows":
			method_card = candidate
			break
	var button := method_card.get("method_button", null) as Button
	if button == null or not is_instance_valid(button) or button.disabled:
		push_error("Fishing click flow could not find an enabled rendered Shallows button.")
		quit(1)
		return
	var click_point := button.get_global_rect().get_center()
	var method_hit_control := method_card.get("method_hit_control", null) as Control
	if method_hit_control == null or not is_instance_valid(method_hit_control):
		push_error("Fishing click flow could not find the Shallows method hit control.")
		quit(1)
		return
	var image_hit_control := method_card.get("method_image_hit_control", null) as Control
	if image_hit_control == null or not is_instance_valid(image_hit_control):
		push_error("Fishing click flow could not find the Shallows image hit control.")
		quit(1)
		return
	var method_rect := method_hit_control.get_global_rect()
	var image_rect := image_hit_control.get_global_rect()
	if method_rect.size.y <= image_rect.size.y + 32.0:
		push_error("Fishing click flow Shallows method button does not cover the whole visible column. method=%s image=%s" % [
			str(method_rect),
			str(image_rect)
		])
		quit(1)
		return
	var title_click_point := Vector2(method_rect.position.x + method_rect.size.x * 0.5, method_rect.position.y + 28.0)
	var mastery_click_point := Vector2(method_rect.position.x + method_rect.size.x * 0.5, method_rect.end.y - 28.0)
	for point in [title_click_point, mastery_click_point]:
		var method_hit := scene.call("_fishing_method_button_hit", point, true) as Dictionary
		if method_hit.is_empty():
			push_error("Fishing click flow Shallows visible column point is outside the method hit route: %s method=%s image=%s" % [
				str(point),
				str(method_rect),
				str(image_rect)
			])
			quit(1)
			return
		if not (scene.call("_module_action_circle_at_direct_position", point) as Dictionary).is_empty():
			push_error("Fishing click flow Shallows visible column point is blocked by a direct module action zone: %s" % str(point))
			quit(1)
			return
	var top_image_click_point := Vector2(image_rect.position.x + image_rect.size.x * 0.5, image_rect.position.y + 18.0)
	var upper_left_image_click_point := Vector2(image_rect.position.x + 52.0, image_rect.position.y + 52.0)
	var top_image_hit := scene.call("_fishing_method_button_hit", top_image_click_point, true) as Dictionary
	if top_image_hit.is_empty():
		push_error("Fishing click flow top-image point is outside the fishing method hit route: %s" % str(top_image_click_point))
		quit(1)
		return
	var image_module_action_hit := scene.call("_module_action_circle_at_position", upper_left_image_click_point) as Dictionary
	if not image_module_action_hit.is_empty():
		push_error("Fishing click flow upper-left Shallows image point is still blocked by a module action zone: %s" % str(image_module_action_hit))
		quit(1)
		return
	for raw_zone in (area_card.get("module_action_zones", {}) as Dictionary).values():
		var zone := raw_zone as Control
		if zone != null and is_instance_valid(zone) and zone.get_global_rect().has_point(upper_left_image_click_point):
			push_error("Fishing click flow upper-left Shallows image point is physically covered by module zone %s rect=%s point=%s" % [
				str(zone.name),
				str(zone.get_global_rect()),
				str(upper_left_image_click_point)
			])
			quit(1)
			return
	if bool(scene.call("_route_module_action_zone_input", _mouse_button_event(upper_left_image_click_point, true))):
		push_error("Fishing click flow upper-left Shallows image point was consumed by the module action zone route.")
		quit(1)
		return
	var area_pop := area_card.get("pop") as Control
	if area_pop == null or not is_instance_valid(area_pop):
		push_error("Fishing click flow could not find the fishing area card host.")
		quit(1)
		return
	var area_pop_rect := area_pop.get_global_rect()
	var pin_point := area_pop_rect.position + Vector2(48.0, 48.0)
	if image_rect.has_point(pin_point) or method_rect.has_point(pin_point):
		push_error("Fishing click flow fishing area pin point overlaps Shallows button. pin=%s method=%s image=%s" % [
			str(pin_point),
			str(method_rect),
			str(image_rect)
		])
		quit(1)
		return
	var pin_corner_hit := scene.call("_fishing_area_pin_corner_hit", pin_point) as Dictionary
	if pin_corner_hit.is_empty():
		push_error("Fishing click flow fishing area pin corner was not recognized. pin=%s area=%s" % [
			str(pin_point),
			str(area_pop_rect)
		])
		quit(1)
		return
	var upper_left_corner_hit := scene.call("_fishing_area_pin_corner_hit", upper_left_image_click_point) as Dictionary
	if not upper_left_corner_hit.is_empty():
		push_error("Fishing click flow upper-left Shallows image point was mistaken for the fishing pin corner. hit=%s point=%s area=%s" % [
			str(upper_left_corner_hit),
			str(upper_left_image_click_point),
			str(area_pop_rect)
		])
		quit(1)
		return
	if bool(scene.call("_route_fishing_area_pin_corner_input", _mouse_button_event(upper_left_image_click_point, true))):
		push_error("Fishing click flow upper-left Shallows image point was consumed by the fishing pin-corner route.")
		quit(1)
		return
	if not bool(scene.call("_route_fishing_area_pin_corner_input", _mouse_button_event(pin_point, true))):
		push_error("Fishing click flow fishing area pin corner did not route through the explicit pin-corner path. pin=%s area=%s" % [
			str(pin_point),
			str(area_pop_rect)
		])
		quit(1)
		return
	if bool(scene.call("_route_fishing_location_image_priority_press", _mouse_button_event(pin_point, true))):
		push_error("Fishing click flow fishing area pin corner was consumed by the fishing priority press path.")
		quit(1)
		return
	scene.call("_route_fishing_area_pin_corner_input", _mouse_button_event(pin_point, false))
	await process_frame
	var area_module_key := str(area_pop.get_meta("module_ui_key", ""))
	if not bool(scene.call("_module_ui_is_pinned", area_module_key)):
		push_error("Fishing click flow fishing area pin corner did not pin the module. key=%s pin=%s area=%s" % [
			area_module_key,
			str(pin_point),
			str(area_pop_rect)
		])
		quit(1)
		return
	var pin_area_pop_id := area_pop.get_instance_id()
	scene.call("_unpin_module_ui_key", area_module_key, pin_area_pop_id)
	await process_frame
	scene.call("_clear_running_activity_for_test_mode")
	if not bool(scene.call("_route_fishing_location_image_priority_press", _mouse_button_event(upper_left_image_click_point, true))):
		push_error("Fishing click flow upper-left Shallows image point did not route through the fishing priority press path.")
		quit(1)
		return
	if str(scene.get("running_skill_id")) != "fishing" or str(scene.get("running_action_id")) != "beach-shallows":
		push_error("Fishing priority press did not start Shallows. running=%s:%s" % [
			str(scene.get("running_skill_id")),
			str(scene.get("running_action_id"))
		])
		quit(1)
		return
	scene.call("_clear_running_activity_for_test_mode")
	if not bool(scene.call("_position_inside_detail_actions_viewport", click_point)):
		push_error("Fishing click flow Shallows click point is outside the activity viewport: %s" % str(click_point))
		quit(1)
		return
	if not bool(scene.call("_position_inside_detail_actions_viewport", top_image_click_point)):
		push_error("Fishing click flow Shallows top-image click point is outside the activity viewport: %s" % str(top_image_click_point))
		quit(1)
		return

	scene.call("_clear_skill_swipe_button_suppression")
	scene.call("_input", _mouse_button_event(upper_left_image_click_point, true))
	for _frame in range(3):
		await process_frame
	scene.call("_input", _mouse_button_event(upper_left_image_click_point, false))
	scene.call("_update_ui", 0.016, false)
	await process_frame
	var hands_init_seconds := float(area_card.get("active_tool_init_seconds", -1.0))
	if hands_init_seconds > 0.0:
		push_error("Bare-hands fishing startup should not play the gear drop-in initialization. init_seconds=%s" % str(hands_init_seconds))
		quit(1)
		return
	for _frame in range(29):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var active_layer := area_card.get("active_tool_layer") as Control
	var water := area_card.get("water_strip_host") as Control
	var selected_locations := scene.get("selected_fishing_locations") as Dictionary
	if str(scene.get("running_skill_id")) != "fishing" or str(scene.get("running_action_id")) != "beach-shallows":
		push_error("Fishing click flow did not start Shallows. running=%s:%s" % [str(scene.get("running_skill_id")), str(scene.get("running_action_id"))])
		quit(1)
		return
	if str(selected_locations.get("beach", "")) != "shallows":
		push_error("Fishing click flow did not update selected Beach location: %s" % str(selected_locations))
		quit(1)
		return
	if active_layer == null or not is_instance_valid(active_layer) or not active_layer.visible:
		push_error("Fishing click flow did not show the active fishing tool animation layer.")
		quit(1)
		return
	if water == null or not is_instance_valid(water) or not water.visible:
		push_error("Fishing click flow did not show the water animation strip.")
		quit(1)
		return
	var area_body_pop := area_card.get("pop") as Control
	if area_body_pop == null or not is_instance_valid(area_body_pop):
		push_error("Fishing click flow could not find the Beach area body.")
		quit(1)
		return
	var area_rect := area_body_pop.get_global_rect()
	var area_hold_point := Vector2.ZERO
	var area_hold_candidates := [
		Vector2(area_rect.position.x + area_rect.size.x * 0.52, area_rect.position.y + area_rect.size.y * 0.52),
		Vector2(area_rect.position.x + area_rect.size.x * 0.38, area_rect.position.y + area_rect.size.y * 0.68),
		Vector2(area_rect.position.x + area_rect.size.x * 0.28, area_rect.position.y + area_rect.size.y * 0.74),
	]
	for candidate in area_hold_candidates:
		var area_hit := scene.call("_fishing_area_card_at_position", candidate) as Dictionary
		if not area_hit.is_empty():
			area_hold_point = candidate
			break
	if area_hold_point == Vector2.ZERO:
		push_error("Fishing click flow could not find a holdable Beach area body point. rect=%s" % str(area_rect))
		quit(1)
		return
	if not bool(scene.call("_route_fishing_area_card_press", _screen_touch_event(area_hold_point, true))):
		push_error("Fishing area hold press did not route. hold_point=%s" % str(area_hold_point))
		quit(1)
		return
	for _frame in range(126):
		scene.call("_process_action_stop_hold", 0.016)
		scene.call("_update_ui", 0.016, false)
		await process_frame
	scene.call("_input", _screen_touch_event(area_hold_point, false))
	await process_frame
	if str(scene.get("running_skill_id")) != "" or str(scene.get("running_action_id")) != "":
		push_error("Fishing area hold did not stop Shallows. running=%s:%s hold_point=%s" % [
			str(scene.get("running_skill_id")),
			str(scene.get("running_action_id")),
			str(area_hold_point)
		])
		quit(1)
		return
	if not bool(scene.call("_route_fishing_area_card_press", _screen_touch_event(area_hold_point, true))):
		push_error("Fishing area body press did not start the selected method. hold_point=%s" % str(area_hold_point))
		quit(1)
		return
	await process_frame
	if str(scene.get("running_skill_id")) != "fishing" or str(scene.get("running_action_id")) != "beach-shallows":
		push_error("Fishing area body press routed but did not start Shallows. running=%s:%s" % [
			str(scene.get("running_skill_id")),
			str(scene.get("running_action_id"))
		])
		quit(1)
		return
	scene.call("_clear_running_activity_for_test_mode")
	print("fishing-click-flow-ok")
	quit(0)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --headless --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True (($output -join "`n") -match "fishing-click-flow-ok") "Fishing click flow did not report success."
}
finally {
    $headless = @(Get-HeadlessGodotProcesses | Where-Object { -not $baselineHeadlessProcessIds.ContainsKey([int]$_.ProcessId) })
    if ($headless.Count -gt 0) {
        $headless | Format-Table ProcessId, Name, CommandLine -AutoSize | Out-String | Write-Output
        throw "A headless Godot process is still running after fishing click flow validation."
    }
}
