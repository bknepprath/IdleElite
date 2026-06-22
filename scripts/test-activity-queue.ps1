$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $projectRoot "run-godot-safe.ps1"
$testDir = Join-Path $projectRoot ".codex-tmp\activity-queue"
$testScript = Join-Path $testDir "activity_queue_test.gd"

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
            $text -match '^ERROR: Parameter "t" is null\.$' -or
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
$previousDisableSaveWrites = $env:IDLE_ELITE_DISABLE_SAVE_WRITES
$env:GODOT_RUN_TIMEOUT_SECONDS = "120"
$env:IDLE_ELITE_DISABLE_SAVE_WRITES = "1"

try {
    @'
extends SceneTree

const BOOT_TIMEOUT_FRAMES := 720

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("activity-queue-test-start")
	if OS.get_environment("IDLE_ELITE_DISABLE_SAVE_WRITES") != "1":
		_fail("activity queue test must run with IDLE_ELITE_DISABLE_SAVE_WRITES=1")
		return
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "14")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("could not load main scene")
		return
	var scene := packed.instantiate()
	root.add_child(scene)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	if not await _wait_for_ready(scene):
		_fail("scene did not become ready")
		return
	_prepare_state(scene)
	_assert_queue_utility_button(scene)
	await _assert_queue_utility_button_opens_queue(scene)

	var build_key := _first_queueable_action_key(scene, "build")
	var fight_key := _first_queueable_action_key(scene, "fight")
	if build_key.is_empty() or fight_key.is_empty():
		_fail("could not find queueable build/fight actions")
		return

	scene.call("set_activity_queue", [build_key, fight_key])
	_assert((scene.call("get_activity_queue") as Array) == [build_key, fight_key], "queue order should be preserved")
	_assert(int(scene.call("get_queue_index", fight_key)) == 1, "queue index should be list order")
	for raw_sort_mode in ["level", "level_desc", "name", "name_desc"]:
		scene.set("module_ui_sort_mode", str(raw_sort_mode))
		_assert((scene.call("get_activity_queue") as Array) == [build_key, fight_key], "queue order should ignore sort mode %s" % str(raw_sort_mode))
	scene.set("current_screen", "queue")
	_force_queue_page_render(scene)
	_assert_queue_page(scene)
	await _assert_queue_active_shelf_fish_controls(scene, build_key)
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	_assert(bool(scene.call("_skill_detail_needs_high_frequency_ui_update")), "queue page should keep visible stamina gauges on frame refresh even while idle")
	_assert_queue_page_clear_button(scene, build_key, fight_key)
	scene.call("set_activity_queue", [build_key, fight_key])
	scene.set("current_screen", "queue")
	_force_queue_page_render(scene)
	await _assert_queue_page_card_can_start_queue(scene, build_key)
	var mat_collection_key := _first_queueable_mat_collection_action_key(scene)
	if mat_collection_key.is_empty():
		_fail("could not find a queueable material collection action")
		return
	scene.call("set_activity_queue", [mat_collection_key])
	scene.set("current_screen", "queue")
	_force_queue_page_render(scene)
	await _assert_queue_page_mat_collection_expands(scene, mat_collection_key)
	scene.set("current_screen", "queue")
	_force_queue_page_render(scene)
	await _assert_add_to_queue_opens_skills_page(scene)
	scene.call("set_activity_queue", [build_key, fight_key])
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "build")
	var selection_render = scene.call("_render_screen", false, -1, false)
	if selection_render != null:
		await selection_render
	for _i in range(8):
		await process_frame
	scene.call("_enter_queue_selection_mode")
	for _i in range(20):
		await process_frame
	_assert_queue_selection(scene)
	scene.call("_finish_queue_selection_mode")
	await _assert_queue_selection_toggles_rendered_cards(scene, build_key)
	scene.call("set_activity_queue", [build_key, fight_key])
	_assert(bool(scene.call("remove_activity_from_queue", build_key)), "remove should succeed")
	_assert((scene.call("get_activity_queue") as Array) == [fight_key], "remove should renumber by list order")
	_assert(bool(scene.call("add_activity_to_queue", build_key)), "add should append")
	_assert((scene.call("get_activity_queue") as Array) == [fight_key, build_key], "add should append to end")

	var passive_key := _first_passive_action_key(scene, "woodcutting")
	if not passive_key.is_empty():
		_assert(not bool(scene.call("add_activity_to_queue", passive_key)), "passive action should not be queueable")

	var saved_queue := scene.call("_activity_queue_for_save") as Array
	var payload := scene.call("_save_payload", int(scene.call("_unix_now"))) as Dictionary
	_assert(payload.has("activity_queue"), "save payload should include activity_queue")
	_assert((payload.get("activity_queue", []) as Array) == saved_queue, "save payload should store queue keys in order")
	scene.call("clear_activity_queue")
	scene.call("_restore_activity_queue_from_save", {"activity_queue": saved_queue})
	_assert((scene.call("get_activity_queue") as Array) == saved_queue, "queue should restore from save data")
	scene.call("_restore_activity_queue_from_save", {})
	_assert((scene.call("get_activity_queue") as Array).is_empty(), "missing save queue should restore as empty")

	scene.call("set_activity_queue", [build_key, fight_key])
	_set_skill_stamina(scene, "build", 0.0)
	_set_skill_stamina(scene, "fight", float(scene.call("_max_stamina", "fight")))
	scene.set("fish_currency", 5.0)
	scene.call("_set_auto_eat_fish_enabled_for_skill", "build", true)
	_assert(bool(scene.call("_start_activity_queue_from_key", build_key)), "queue should start from first runnable entry")
	_assert(str(scene.get("running_skill_id")) == "fight", "queue should skip low-stamina first entry")
	_assert(str(scene.get("activity_queue_attempt_key")) == fight_key, "queue attempt key should be skipped-to entry")
	_assert(absf(float(scene.get("fish_currency")) - 5.0) < 0.001, "queue should not auto-eat fish while skipping low-stamina entries")
	_set_skill_stamina(scene, "build", float(scene.call("_max_stamina", "build")))
	_set_skill_stamina(scene, "fight", 0.0)
	scene.call("_process_activity_queue_runtime")
	_assert(bool(scene.get("activity_queue_running")), "queue should keep running after wrapping to an earlier runnable entry")
	_assert(str(scene.get("activity_queue_attempt_key")) == build_key, "queue should loop back to first entry after the last entry runs low")
	_assert(str(scene.get("running_skill_id")) == "build", "queue wrap should start the recovered first skill")
	_set_skill_stamina(scene, "build", 0.0)
	scene.call("_process_activity_queue_runtime")
	_assert(not bool(scene.get("activity_queue_running")), "queue should stop gracefully if a full loop has no runnable entries")
	_assert(str(scene.get("running_skill_id")).is_empty(), "queue exhaustion should clear running action")

	scene.call("set_activity_queue", [build_key, fight_key])
	_set_skill_stamina(scene, "build", float(scene.call("_max_stamina", "build")))
	_set_skill_stamina(scene, "fight", float(scene.call("_max_stamina", "fight")))
	_assert(bool(scene.call("_start_activity_queue_from_key", fight_key)), "queue should start from selected second entry")
	_assert(str(scene.get("activity_queue_attempt_key")) == fight_key, "selected second queue entry should be attempted first")
	_assert(str(scene.get("running_skill_id")) == "fight", "selected second queue entry should start its skill")
	scene.call("_stop_activity_queue_runtime", true)
	_assert(bool(scene.call("_start_activity_queue_from_key", build_key)), "queue should start build entry")
	var fight_target := scene.call("_activity_queue_target_for_key", fight_key) as Dictionary
	_assert(bool(scene.call("_start_action", "fight", str(fight_target.get("action_id", "")), true, false, false)), "manual action should start")
	_assert(not bool(scene.get("activity_queue_running")), "manual non-queue start should stop queue mode")

	var fishing_area_key := _first_queueable_fishing_area_key(scene)
	if not fishing_area_key.is_empty():
		await _assert_fishing_queue_overlay_uses_area_host(scene, fishing_area_key)
		await _assert_fishing_area_tap_adds_queue_entry(scene, fishing_area_key)
		scene.call("set_activity_queue", [fishing_area_key, build_key])
		_set_skill_stamina(scene, "fishing", 0.0)
		_assert(bool(scene.call("_start_activity_queue_from_key", fishing_area_key)), "fishing queue entry should start")
		_assert(str(scene.get("running_skill_id")) == "fishing", "fishing queue entry should run as fishing")
		scene.call("_process_activity_queue_runtime")
		_assert(bool(scene.get("activity_queue_running")), "fishing should not advance because of stamina")
		_assert(str(scene.get("running_skill_id")) == "fishing", "fishing should keep running and block later queue entries")

	if _failed:
		return
	print("activity-queue-test-ok")
	scene.call("_stop_activity_queue_runtime", true)
	scene.set("onboarding_tutorial_complete", false)
	scene.set("current_screen", "menu")
	scene.set("selected_skill_id", "")
	root.remove_child(scene)
	scene.queue_free()
	await process_frame
	quit(0)


func _prepare_state(scene: Node) -> void:
	scene.set("boot_warmup_active", false)
	scene.set("boot_splash_dismissed_early", true)
	if scene.has_method("_reveal_game_under_boot_splash"):
		scene.call("_reveal_game_under_boot_splash")
	if scene.has_method("_dismiss_boot_splash_for_play"):
		scene.call("_dismiss_boot_splash_for_play")
	if scene.has_method("_close_offline_summary_overlay"):
		scene.call("_close_offline_summary_overlay")
	scene.call("_god_mode_unlock_onboarding_state")
	scene.call("_god_mode_max_skills_state")
	scene.call("_god_mode_unlock_actions_state")
	for raw_skill_id in scene.skills.keys():
		var skill_id := str(raw_skill_id)
		scene.skills[skill_id]["xp"] = scene.call("_xp_for_level", 18)
		scene.call("_recalculate_level", skill_id)
		_set_skill_stamina(scene, skill_id, float(scene.call("_max_stamina", skill_id)))
	scene.set("running_skill_id", "")
	scene.set("running_action_id", "")
	scene.set("action_progress", 0.0)
	scene.set("activity_queue", [])
	scene.set("activity_queue_running", false)
	scene.set("activity_queue_index", -1)
	scene.set("activity_queue_attempt_key", "")


func _wait_for_ready(scene: Node) -> bool:
	for _i in range(BOOT_TIMEOUT_FRAMES):
		await process_frame
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


func _assert_queue_utility_button(scene: Node) -> void:
	var queue_button := scene.get("queue_utility_tab") as Button
	_assert(queue_button != null and is_instance_valid(queue_button), "queue utility button should exist")
	_assert(bool(queue_button.get_meta("module_utility_nav_button", false)), "queue utility button should use nav button styling")
	var row := scene.get("module_utility_buttons_row") as HBoxContainer
	_assert(row != null and is_instance_valid(row), "module utility button row should exist")
	_assert(row.get_child_count() == 4, "module utility row should contain four module buttons")
	_assert(row.get_child(1) == queue_button, "queue utility button should be the second module button")
	var icon := _find_named(queue_button, "ActivityButtonIcon") as TextureRect
	_assert(icon != null and is_instance_valid(icon), "queue utility button should render an icon")
	var texture := icon.texture
	_assert(texture != null, "queue utility icon texture should be loaded")
	_assert(str(texture.resource_path) == "res://assets/content/ui/navigation-controls/queue.png", "queue utility icon should use queue.png")


func _assert_queue_utility_button_opens_queue(scene: Node) -> void:
	var queue_button := scene.get("queue_utility_tab") as Button
	_assert(queue_button != null and is_instance_valid(queue_button), "queue utility button should exist before press")
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "build")
	scene.set("top_level_nav_locked_until_msec", 0)
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	queue_button.emit_signal("pressed")
	for _i in range(20):
		await process_frame
	_assert(str(scene.get("current_screen")) == "queue", "queue utility button should open the Queue page")
	var module_utility_row := scene.get("module_utility_row") as Control
	_assert(bool(scene.call("_chat_strip_visible_on_current_screen")), "queue page should reserve bottom chrome")
	_assert(module_utility_row != null and is_instance_valid(module_utility_row) and module_utility_row.visible, "queue page should keep module utility buttons visible")
	_assert(bool(queue_button.get_meta("activity_button_shell_active", false)), "queue utility button should show active state on Queue page")
	queue_button.emit_signal("pressed")
	for _i in range(20):
		await process_frame
	_assert(str(scene.get("current_screen")) == "skill", "pressing Queue again on the Queue page should return to skill view")


func _force_queue_page_render(scene: Node) -> void:
	var skills_content := scene.get("skills_content") as Control
	if skills_content != null and scene.has_method("_clear"):
		scene.call("_clear", skills_content)
	if scene.has_method("_reset_page_control_refs"):
		scene.call("_reset_page_control_refs")
	if scene.has_method("_apply_skills_content_layout_for_screen"):
		scene.call("_apply_skills_content_layout_for_screen")
	scene.call("_render_activity_queue_page")


func _assert_queue_page(scene: Node) -> void:
	var queue := scene.call("get_activity_queue") as Array
	_assert(queue.size() == 2, "queue page test expected two queued entries")
	_assert(_find_named(scene, "ActivityQueuePage") != null, "queue page should render ActivityQueuePage")
	_assert(_count_named(scene, "ActivityQueueNumberOverlay") == 0, "queue page should not render selection order overlays")
	var queue_button := _find_named(scene, "ActivityQueueSetQueueButton") as Button
	_assert(queue_button != null, "queue page should render queue edit button")
	if queue_button != null:
		_assert(queue_button.text == "Adjust Queue", "populated queue should label edit button Adjust Queue")
	_assert(_find_named(scene, "ActivityQueueClearQueueButton") != null, "queue page should render Clear Queue button when populated")
	_assert(_find_named(scene, "ActivityQueueEmptyDescription") == null, "queue page should not render empty description when populated")
	var bottom_spacer := _find_named(scene, "ActivityQueueBottomSpacer") as Control
	_assert(bottom_spacer != null and is_instance_valid(bottom_spacer), "queue page should render a bottom scroll spacer")
	if bottom_spacer != null:
		var expected_pad := float(scene.call("_skills_content_bottom_inset_for_screen")) + 180.0
		_assert(bottom_spacer.custom_minimum_size.y >= expected_pad, "queue page bottom spacer should leave room above bottom chrome")


func _assert_queue_active_shelf_fish_controls(scene: Node, module_key: String) -> void:
	var target := scene.call("_activity_queue_target_for_key", module_key) as Dictionary
	var skill_id := str(target.get("skill_id", ""))
	var action_id := str(target.get("action_id", ""))
	_assert(not skill_id.is_empty() and not action_id.is_empty(), "queue active shelf fish control test should resolve a queued action")
	_set_skill_stamina(scene, skill_id, float(scene.call("_max_stamina", skill_id)))
	_assert(bool(scene.call("_start_activity_queue_from_key", module_key)), "queue active shelf fish control test should start the queued action")
	_assert(str(scene.get("running_skill_id")) == skill_id and str(scene.get("running_action_id")) == action_id, "queue active shelf fish control test should run the expected action")
	scene.set("fish_currency_ever_earned", true)
	scene.set("fish_currency", 2.0)
	scene.set("current_screen", "queue")
	_force_queue_page_render(scene)
	for _i in range(8):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	var gauge := scene.get("pinned_active_shelf_regen_circle") as Control
	_assert(gauge != null and is_instance_valid(gauge) and gauge.is_visible_in_tree(), "queue active shelf should render an interactive stamina Gage")
	var toggle := _find_named(scene, "AutoEatFishToggle") as TextureButton
	_assert(toggle != null and is_instance_valid(toggle) and toggle.is_visible_in_tree(), "queue active shelf should render the Auto Fish Eat toggle")
	if gauge == null or toggle == null:
		scene.call("_stop_activity_queue_runtime", true)
		return
	_assert(str(toggle.get_meta("auto_eat_skill_id", "")) == skill_id, "queue Auto Fish Eat toggle should target the active queue skill")
	scene.call("_set_auto_eat_fish_enabled_for_skill", skill_id, false)
	toggle.emit_signal("pressed")
	_assert(bool(scene.call("_auto_eat_fish_enabled_for_skill", skill_id)), "queue Auto Fish Eat toggle should flip the active skill setting")
	var max_stamina := float(scene.call("_max_stamina", skill_id))
	_set_skill_stamina(scene, skill_id, maxf(0.0, max_stamina - 2.0))
	var before_stamina := float(scene.call("_stamina_value", skill_id))
	var before_fish := float(scene.get("fish_currency"))
	var tap_position := gauge.get_global_rect().get_center()
	scene.call("_on_stamina_gauge_input", _mouse_button_event(tap_position, true), skill_id, gauge)
	scene.call("_on_stamina_gauge_input", _mouse_button_event(tap_position, false), skill_id, gauge)
	for _i in range(4):
		await process_frame
	_assert(absf(float(scene.call("_stamina_value", skill_id)) - (before_stamina + 1.0)) < 0.001, "queue active shelf Gage tap should eat one fish into stamina")
	_assert(absf(float(scene.get("fish_currency")) - (before_fish - 1.0)) < 0.001, "queue active shelf Gage tap should spend one fish")
	scene.call("_stop_activity_queue_runtime", true)


func _assert_add_to_queue_opens_skills_page(scene: Node) -> void:
	var set_button := _find_named(scene, "ActivityQueueSetQueueButton") as Button
	_assert(set_button != null and is_instance_valid(set_button), "queue page should render Set Queue button")
	_assert(set_button.get_signal_connection_list("pressed").size() > 0, "Set Queue button should be connected")
	set_button.emit_signal("pressed")
	for _i in range(20):
		await process_frame
	_assert(bool(scene.get("queue_selection_mode")), "Set Queue should enter queue selection mode")
	_assert(str(scene.get("current_screen")) == "menu", "Set Queue should open the skills page for queue selection")
	_assert(_find_named(scene, "QueueSelectionBanner") != null, "Set Queue should keep queue selection banner visible")
	_assert(_find_button_with_text(scene, "FINISH QUEUE") == null, "queue selection banner should not render a Finish Queue button")
	var queue_button := scene.get("queue_utility_tab") as Button
	_assert(queue_button != null and is_instance_valid(queue_button), "Queue utility button should exist during queue selection")
	queue_button.emit_signal("pressed")
	for _i in range(20):
		await process_frame
	_assert(not bool(scene.get("queue_selection_mode")), "pressing Queue utility should finish queue selection")
	_assert(str(scene.get("current_screen")) == "queue", "pressing Queue utility during selection should return to Queue page")


func _assert_queue_page_clear_button(scene: Node, first_key: String, second_key: String) -> void:
	scene.call("set_activity_queue", [first_key, second_key])
	scene.set("current_screen", "queue")
	_force_queue_page_render(scene)
	_assert((scene.call("get_activity_queue") as Array).size() == 2, "clear button test should still have queued items before render lookup")
	var clear_button := _find_named(scene, "ActivityQueueClearQueueButton") as Button
	_assert(clear_button != null and is_instance_valid(clear_button), "Clear Queue should appear when queue has items")
	if clear_button == null:
		return
	_assert(clear_button.get_signal_connection_list("pressed").size() > 0, "Clear Queue button should be connected")
	scene.set("activity_queue", [])
	_assert((scene.call("get_activity_queue") as Array).is_empty(), "Clear Queue should clear queued items")
	scene.set("current_screen", "queue")
	_force_queue_page_render(scene)
	var set_button := _find_named(scene, "ActivityQueueSetQueueButton") as Button
	_assert(set_button != null, "empty queue should still render Set Queue button")
	if set_button != null:
		_assert(set_button.text == "Set Queue", "empty queue should label edit button Set Queue")
	_assert(_find_named(scene, "ActivityQueueClearQueueButton") == null, "Clear Queue should be hidden when queue is empty")
	_assert(_find_named(scene, "ActivityQueueEmptyDescription") != null, "empty queue should render queue description")


func _assert_queue_page_card_can_start_queue(scene: Node, module_key: String) -> void:
	var card := _registered_card_for_module_key(scene, str(module_key))
	_assert(not card.is_empty(), "queue page should register queued module card")
	_assert(str(scene.call("_activity_queue_module_key_for_card", card)) == str(module_key), "queue page card should resolve to queued module key")
	var pop := card.get("pop", null) as Control
	_assert(pop != null and is_instance_valid(pop), "queue page card should have a visible pop control")
	var press_position := pop.get_global_rect().get_center()
	_assert(bool(scene.call("_position_inside_detail_actions_viewport", press_position)), "queue page card should be inside the action viewport")
	scene.call("_input", _mouse_button_event(press_position, true))
	var captured_press_key := str(scene.get("action_card_press_key"))
	_assert(not captured_press_key.is_empty(), "queue page card press should capture the normal action-card press key")
	scene.call("_input", _mouse_button_event(press_position, false))
	for _i in range(4):
		await process_frame
	_assert(bool(scene.get("activity_queue_running")), "pressing queue page card through normal input should enter queue runtime")
	_assert(bool(scene.call("_skill_detail_needs_high_frequency_ui_update")), "queue page should use high-frequency live card updates while an action is running")
	scene.call("_stop_activity_queue_runtime", true)


func _assert_queue_page_mat_collection_expands(scene: Node, module_key: String) -> void:
	var card := _registered_card_for_module_key(scene, str(module_key))
	_assert(not card.is_empty(), "queue page should register material collection card")
	var collection := card.get("mat_collection", {}) as Dictionary
	_assert(not collection.is_empty(), "queue page material collection card should include a material drawer")
	var root := collection.get("root", null) as Control
	_assert(root != null and is_instance_valid(root), "queue page material drawer should have a live root")
	var entry := card.get("entry", null) as Control
	_assert(entry != null and is_instance_valid(entry), "queue page material collection card should have an entry root")
	var initial_height := entry.custom_minimum_size.y
	var pop := card.get("pop", null) as Control
	_assert(pop != null and is_instance_valid(pop), "queue page material collection card should have a pop control")
	var press_position := _card_body_tap_point(pop)
	scene.call("_input", _mouse_button_event(press_position, true))
	scene.call("_input", _mouse_button_event(press_position, false))
	for _i in range(32):
		scene.call("_update_ui", 0.016, false)
		await process_frame
	_assert(bool(scene.get("activity_queue_running")), "material collection queue entry should start queue runtime")
	collection = card.get("mat_collection", {}) as Dictionary
	_assert(bool(collection.get("visible", false)), "queue page material drawer should become visible while the collection action runs")
	_assert(root.modulate.a > 0.05, "queue page material drawer should fade in while running")
	_assert(entry.custom_minimum_size.y > initial_height + 100.0, "queue page material drawer should expand the module height")
	scene.call("_stop_activity_queue_runtime", true)


func _assert_queue_selection(scene: Node) -> void:
	_assert(bool(scene.get("queue_selection_mode")), "queue selection mode should be active")
	_assert(_find_named(scene, "QueueSelectionBanner") != null, "queue selection should render banner")
	_assert(_count_named(scene, "ActivityQueueNumberOverlay") >= 1, "queue selection should show order overlays for visible queued activities")


func _assert_queue_selection_toggles_rendered_cards(scene: Node, module_key: String) -> void:
	var target := scene.call("_activity_queue_target_for_key", module_key) as Dictionary
	var skill_id := str(target.get("skill_id", ""))
	_assert(not skill_id.is_empty(), "selection toggle test should resolve a skill id")
	scene.call("set_activity_queue", [module_key])
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", skill_id)
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(8):
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	scene.call("_enter_queue_selection_mode")
	var card := _registered_card_for_module_key(scene, module_key)
	_assert(not card.is_empty(), "selection toggle test should find a rendered card")
	var action_id := str(target.get("action_id", ""))
	_assert(bool(scene.call("_start_action", skill_id, action_id, false, false, false)), "selection toggle test should start active action")
	var pop := card.get("pop", null) as Control
	_assert(pop != null and is_instance_valid(pop), "selection toggle test should have a pop control")
	var press_position := pop.get_global_rect().get_center()
	_assert(bool(scene.call("_route_action_card_press", press_position, 12)), "selection mode should route press on active action")
	_assert(bool(scene.call("_route_action_card_release", _mouse_release(press_position))), "selection mode should route release on active action")
	_assert((scene.call("get_activity_queue") as Array).is_empty(), "selection mode tap should remove active queued card")
	_assert(bool(scene.call("_queue_selection_toggle_from_card", card)), "selection toggle should remove a queued card")
	_assert((scene.call("get_activity_queue") as Array) == [module_key], "selection toggle should add active unqueued card")
	_assert(bool(scene.call("_queue_selection_toggle_from_card", card)), "selection toggle should remove a queued card")
	_assert((scene.call("get_activity_queue") as Array).is_empty(), "selection toggle should remove queued card")
	_assert(bool(scene.call("_queue_selection_toggle_from_card", card)), "selection toggle should add an unqueued card")
	_assert((scene.call("get_activity_queue") as Array) == [module_key], "selection toggle should append unqueued card")
	scene.call("_finish_queue_selection_mode")


func _registered_card_for_module_key(scene: Node, module_key: String) -> Dictionary:
	var normalized_key := str(scene.call("_normalized_module_ui_key", module_key))
	var target := scene.call("_activity_queue_target_for_key", normalized_key) as Dictionary
	var target_skill_id := str(target.get("skill_id", ""))
	var target_action_id := str(target.get("action_id", ""))
	var action_cards := scene.get("action_cards") as Dictionary
	for raw_card in action_cards.values():
		var card := raw_card as Dictionary
		if card.is_empty():
			continue
		var pop := card.get("pop", null) as Control
		if pop != null and is_instance_valid(pop):
			var pop_key := str(scene.call("_normalized_module_ui_key", pop.get_meta("module_ui_key", "")))
			if pop_key == normalized_key:
				return card
		var card_module_key := str(scene.call("_activity_queue_module_key_for_card", card))
		if card_module_key == normalized_key:
			return card
		if str(card.get("skill_id", "")) == target_skill_id and str(card.get("action_id", "")) == target_action_id:
			return card
	return {}


func _assert_fishing_queue_overlay_uses_area_host(scene: Node, fishing_area_key: String) -> void:
	scene.call("set_activity_queue", [fishing_area_key])
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(16):
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	scene.call("_enter_queue_selection_mode")
	for _i in range(8):
		await process_frame
	var area_card := _registered_card_for_module_key(scene, fishing_area_key)
	_assert(not area_card.is_empty(), "fishing queue overlay test should find a rendered area card")
	var area_host := area_card.get("queue_overlay_host", null) as Control
	var pop := area_card.get("pop", null) as Control
	_assert(area_host != null and is_instance_valid(area_host), "fishing area should provide a queue overlay host")
	_assert(area_host != pop, "fishing queue overlay host should not be the full module")
	_assert(_direct_child_count_named(area_host, "ActivityQueueNumberOverlay") == 1, "fishing queue overlay should be placed on the area host")
	if pop != null and is_instance_valid(pop):
		_assert(_direct_child_count_named(pop, "ActivityQueueNumberOverlay") == 0, "fishing queue overlay should not be centered on the full fishing module")
	scene.call("_finish_queue_selection_mode")


func _assert_fishing_area_tap_adds_queue_entry(scene: Node, fishing_area_key: String) -> void:
	scene.call("set_activity_queue", [])
	scene.set("current_screen", "skill")
	scene.set("selected_skill_id", "fishing")
	var render_result = scene.call("_render_screen", false, -1, false)
	if render_result != null:
		await render_result
	for _i in range(16):
		await process_frame
	scene.call("_sync_detail_lazy_visible_cards", true, -1)
	scene.call("_enter_queue_selection_mode")
	for _i in range(8):
		await process_frame
	var area_card := _registered_card_for_module_key(scene, fishing_area_key)
	_assert(not area_card.is_empty(), "fishing queue tap test should find a rendered area card")
	var host := area_card.get("queue_overlay_host", null) as Control
	if host == null or not is_instance_valid(host):
		host = area_card.get("pop", null) as Control
	_assert(host != null and is_instance_valid(host), "fishing queue tap test should have a tappable host")
	var press_position := host.get_global_rect().get_center()
	_assert(bool(scene.call("_position_inside_detail_actions_viewport", press_position)), "fishing queue tap point should be inside the action viewport")
	scene.call("_input", _mouse_button_event(press_position, true))
	scene.call("_input", _mouse_button_event(press_position, false))
	for _i in range(8):
		await process_frame
	_assert((scene.call("get_activity_queue") as Array) == [fishing_area_key], "tapping a fishing area in queue selection should add that area to the queue")
	scene.call("_finish_queue_selection_mode")


func _find_named(root_node: Node, node_name: String) -> Node:
	if root_node.is_queued_for_deletion():
		return null
	if root_node.name == node_name:
		return root_node
	for child in root_node.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _find_button_with_text(root_node: Node, button_text: String) -> Button:
	if root_node.is_queued_for_deletion():
		return null
	var button := root_node as Button
	if button != null and button.text == button_text:
		return button
	for child in root_node.get_children():
		var found := _find_button_with_text(child, button_text)
		if found != null:
			return found
	return null


func _count_named(root_node: Node, node_name: String) -> int:
	var count := 1 if root_node.name == node_name else 0
	for child in root_node.get_children():
		count += _count_named(child, node_name)
	return count


func _direct_child_count_named(root_node: Node, node_name: String) -> int:
	if root_node == null:
		return 0
	var count := 0
	for child in root_node.get_children():
		if child.name == node_name:
			count += 1
	return count


func _mouse_release(global_position: Vector2) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	event.position = global_position
	event.global_position = global_position
	return event


func _mouse_button_event(global_position: Vector2, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = global_position
	event.global_position = global_position
	return event


func _card_body_tap_point(pop: Control) -> Vector2:
	var rect := pop.get_global_rect()
	return rect.position + Vector2(rect.size.x * 0.58, rect.size.y * 0.72)


func _first_queueable_action_key(scene: Node, skill_id: String) -> String:
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	for raw_action in actions_by_skill.get(skill_id, []):
		var action := raw_action as Dictionary
		if action.is_empty():
			continue
		var action_id := str(action.get("id", ""))
		var key := str(scene.call("_module_ui_action_key", skill_id, action_id))
		if bool(scene.call("_activity_queue_key_is_queueable", key)):
			return key
	return ""


func _first_queueable_mat_collection_action_key(scene: Node) -> String:
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	for raw_skill_id in actions_by_skill.keys():
		var skill_id := str(raw_skill_id)
		for raw_action in actions_by_skill.get(raw_skill_id, []):
			var action := raw_action as Dictionary
			if action.is_empty() or not bool(scene.call("_action_has_mat_rewards", action)):
				continue
			var action_id := str(action.get("id", ""))
			var key := str(scene.call("_module_ui_action_key", skill_id, action_id))
			if bool(scene.call("_activity_queue_key_is_queueable", key)):
				return key
	return ""


func _first_passive_action_key(scene: Node, skill_id: String) -> String:
	var actions_by_skill := scene.get("actions_by_skill") as Dictionary
	for raw_action in actions_by_skill.get(skill_id, []):
		var action := raw_action as Dictionary
		if action.is_empty() or not bool(scene.call("_is_passive_action", action)):
			continue
		return str(scene.call("_module_ui_action_key", skill_id, str(action.get("id", ""))))
	return ""


func _first_queueable_fishing_area_key(scene: Node) -> String:
	for raw_area_def in scene.call("_fishing_render_area_modules", "fishing"):
		var area_def := raw_area_def as Dictionary
		var key := str(scene.call("_module_ui_fishing_area_key", "fishing", area_def))
		if bool(scene.call("_activity_queue_key_is_queueable", key)):
			return key
	return ""


func _set_skill_stamina(scene: Node, skill_id: String, amount: float) -> void:
	var stamina := scene.get("stamina") as Dictionary
	stamina[skill_id] = amount
	scene.set("stamina", stamina)
	if scene.has_method("_sync_stamina_bank"):
		scene.call("_sync_stamina_bank", skill_id)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	_fail(message)


func _fail(message: String) -> void:
	_failed = true
	push_error("activity queue test failed: %s" % message)
	quit(1)
'@ | Set-Content -LiteralPath $testScript -Encoding UTF8

    $output = & $runner --path $projectRoot --script $testScript 2>&1
    $output | Out-Host
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Assert-True ([bool]($output -match "activity-queue-test-ok")) "Activity queue test did not report success."
    Assert-NoUnexpectedGodotErrors $output "activity queue validation"
    $headless = @(Get-HeadlessGodotProcesses)
    Assert-True ($headless.Count -eq 0) "A headless Godot process is still running after activity queue validation."
}
finally {
    if ($null -eq $previousTimeout) {
        Remove-Item Env:\GODOT_RUN_TIMEOUT_SECONDS -ErrorAction SilentlyContinue
    } else {
        $env:GODOT_RUN_TIMEOUT_SECONDS = $previousTimeout
    }
    if ($null -eq $previousDisableSaveWrites) {
        Remove-Item Env:\IDLE_ELITE_DISABLE_SAVE_WRITES -ErrorAction SilentlyContinue
    } else {
        $env:IDLE_ELITE_DISABLE_SAVE_WRITES = $previousDisableSaveWrites
    }
}
