extends "res://scripts/tests/first_session_input.gd"

const SkillState = preload("res://scripts/progression/skill_state.gd")

func named(node: Node, node_name: String) -> Node:
	if node.name == node_name:
		return node
	for child in node.get_children():
		var found := named(child, node_name)
		if found != null:
			return found
	return null

func _run() -> void:
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.skills.fishing.xp = SkillState.xp_for_level(4)
	SkillState.recalculate_level(game, "fishing")
	game._activity_unlock_runtime()._finalize_manual_activity_unlock("fishing", "rocks", "test setup")
	game._navigation_shell()._select_skill("fishing")
	await settle(1.0)
	var fishing = game._fishing_ui_surface()
	var queue = game._activity_queue_runtime()
	var card: Dictionary = fishing._fishing_method_card_for_action("fishing", "rocks")
	check(not card.is_empty(), "Rocks must be available for native queue selection")
	if card.is_empty():
		quit(1)
		return
	game._skill_swipe_activity_surface()._enter_queue_selection_mode()
	await settle()
	card = fishing._fishing_method_card_for_action("fishing", "rocks")
	await click(card.method_image_hit_control.get_global_rect().get_center())
	var entries: Array = queue.get_activity_queue()
	check(entries.size() == 1, "Native Rocks tap must queue its area exactly once")
	if entries.is_empty():
		quit(1)
		return
	var fishing_key := str(entries[0])
	check(queue._activity_queue_target_for_key(fishing_key).action_id == "rocks", "Queue must retain the tapped fishing location")
	var done := named(game, "FinishQueueSelectionButton") as Button
	check(done != null, "Queue selection needs a Done button")
	await click(done.get_global_rect().get_center())
	check(game.current_screen == "queue" and not game.queue_selection_mode, "Native Done tap must finish selection")
	var fight_key := "action:fight:push-ups"
	queue.set_activity_queue([fishing_key, fight_key])
	await settle()
	card = fishing._fishing_method_card_for_action("fishing", "rocks")
	await click(card.method_image_hit_control.get_global_rect().get_center())
	check(queue.activity_queue_running and game.running_action_id == "rocks", "Native queued Rocks tap must start queue mode")
	game.stamina.fight = 0.0
	game._action_runtime()._process_action(100.0)
	queue._process_activity_queue_runtime()
	check(game.running_skill_id == "fishing", "Fishing must wait for recovery after a real attempt")
	game._action_runtime()._apply_stamina_regen_seconds(1000.0, true)
	queue._process_activity_queue_runtime()
	check(game.running_skill_id == "fight", "Recovered training must follow fishing")
	game.stamina.fight = 0.0
	queue._process_activity_queue_runtime()
	check(game.running_action_id == "rocks", "Exhausted training must return to the selected fishing location")
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.0)
	game._update_ui(0.0, true)
	check(game._navigation_shell().skill_menu_total_label.text == "Total Lv %s" % SkillState.global_level(game.skills), "Overview total must match current skill levels")
	var navigation = game._navigation_shell()
	var menu_refs: Dictionary = navigation._capture_skill_menu_swap_refs()
	var total_label: Label = navigation.skill_menu_total_label
	navigation._install_skill_menu_swap_refs({})
	navigation._install_skill_menu_swap_refs(menu_refs)
	check(navigation.skill_menu_total_label == total_label, "Cached menu must restore its own total-level label")
	game.skills.fight.level += 1
	navigation._sync_skill_menu_page(0.0, true, true)
	check(total_label.text == "Total Lv %s" % SkillState.global_level(game.skills), "Restored menu total must update after a level change")
	check(queue._activity_queue_target_for_key(fishing_key).action_id == "rocks", "Rebuilding the overview must not change queue selection")
	queue.set_activity_queue([fishing_key])
	check(queue._start_activity_queue_from_key(fishing_key), "Starting a queue on the running fishing action must succeed")
	game._action_runtime()._process_action(100.0)
	queue._process_activity_queue_runtime()
	check(queue.activity_queue_running and game.running_skill_id == "fishing", "A fishing-only queue must remain active")
	queue._stop_activity_queue_runtime(true)
	queue.set_activity_queue(["action:fishing:shallows", "action:fishing:rocks"])
	queue._start_activity_queue_from_key("action:fishing:shallows")
	game._action_runtime()._process_action(100.0)
	queue._process_activity_queue_runtime()
	check(game.running_action_id == "rocks", "Multiple fishing entries must rotate after an attempt")
	print("FISHING_QUEUE_AUDIT failures=", failures)
	queue._stop_activity_queue_runtime(true)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
