extends "res://scripts/tests/first_session_input.gd"

const SkillState = preload("res://scripts/progression/skill_state.gd")

func offer_button(offer_id: String) -> Button:
	for node in get_nodes_in_group("fishing_offer_buttons"):
		if str(node.get_meta("fishing_offer_id", "")) == offer_id and node.is_visible_in_tree():
			return node as Button
	return null

func reveal_offer(offer_id: String) -> Button:
	var detail = game._skill_detail_surface()
	game._navigation_shell()._render_screen()
	await settle(0.8)
	for entry in detail.detail_lazy_plan:
		if str(entry.get("offer_id", "")) == offer_id:
			await detail._restore_detail_actions_scroll(int(entry.y))
			await settle(0.8)
			break
	var button := offer_button(offer_id)
	for attempt in range(3):
		if button == null:
			break
		var scroll: Control = detail.detail_actions_scroll
		var target: int = detail.detail_actions_scroll.scroll_vertical + int(button.get_global_rect().position.y - scroll.get_global_rect().position.y)
		await detail._restore_detail_actions_scroll(maxi(0, target))
		await settle(0.5)
		button = offer_button(offer_id)
	return offer_button(offer_id)

func _run() -> void:
	root.size = Vector2i(540, 960)
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
	game.skills.fishing.xp = SkillState.xp_for_level(5)
	SkillState.recalculate_level(game, "fishing")
	game._navigation_shell()._select_skill("fishing")
	await settle(1.0)
	var fishing = game._fishing_ui_surface()
	var circle := await reveal_area_tool("shallows")
	await click(circle.get_global_rect().get_center())
	check(fishing.fishing_tool_wallet_open, "Native area tool click must open exactly once")
	await click(circle.get_global_rect().get_center(), true)
	check(not fishing.fishing_tool_wallet_open, "Native area tool touch must close the wallet exactly once")
	await game._skill_detail_surface()._restore_detail_actions_scroll(400)
	await settle(0.6)
	var locked: Dictionary = fishing._fishing_method_card_for_action("fishing", "dock-edge")
	check(not locked.is_empty(), "Locked Pier method must be mounted")
	if not locked.is_empty():
		var lock_button: Button = locked.lock_root.get_meta("padlock_button") as Button
		check(lock_button != null, "Fishing lock must be a native button")
		if lock_button != null:
			# The bottom bars lie over the lower part of the list and take taps there,
			# so bring the padlock to the middle of the list before tapping it.
			var detail = game._skill_detail_surface()
			var list_center: Vector2 = detail.detail_actions_scroll.get_global_rect().get_center()
			await detail._restore_detail_actions_scroll(maxi(0, detail.detail_actions_scroll.scroll_vertical + int(lock_button.get_global_rect().get_center().y - list_center.y)))
			await settle(0.6)
			locked = fishing._fishing_method_card_for_action("fishing", "dock-edge")
			lock_button = locked.lock_root.get_meta("padlock_button") as Button
			check(not game._input_routing_shell()._position_inside_bottom_interactive_ui(lock_button.get_global_rect().get_center()), "Fishing lock must be clear of the bottom bars before the tap")
			game.last_result = ""
			await click(lock_button.get_global_rect().get_center(), true)
			check(game.last_result.contains("needs"), "Native lock click must explain its requirements")
	var net := await reveal_offer("net")
	check(net != null, "Net must exist in the production fishing page")
	if net == null:
		quit(1)
		return
	var point := net.get_global_rect().get_center()
	var down := InputEventScreenTouch.new()
	down.position = point
	down.pressed = true
	root.push_input(down, true)
	await process_frame
	var drag := InputEventScreenDrag.new()
	drag.position = point + Vector2(0, -220)
	drag.relative = Vector2(0, -220)
	root.push_input(drag, true)
	await process_frame
	var up := InputEventScreenTouch.new()
	up.position = drag.position
	root.push_input(up, true)
	await settle(0.5)
	check(not game.fishing_runtime.net_collected and not game.fishing_runtime.net_collect_pending, "Dragging an offer must not collect it")
	net = await reveal_offer("net")
	await click(net.get_global_rect().get_center(), true)
	await settle(4.5)
	check(game.fishing_runtime.net_collected, "Native net tap after a drag must collect the net")
	circle = await reveal_area_tool("shallows")
	await click(circle.get_global_rect().get_center())
	await settle(0.4)
	for button in fishing.fishing_tool_wallet_popup.find_children("FishingToolPopupButton*", "Button", true, false):
		if str(button.get_meta("tool_id", "")) == "net":
			await click(button.get_global_rect().get_center(), true)
			break
	check(game.fishing_runtime.tool_id_for_action("shallows") == "net", "Native area tool tap must save the net")
	# Keep the purchase targets stable while testing late-game offers.
	game.auto_unlock_lockpads_enabled = false
	game.skills.fishing.xp = SkillState.xp_for_level(99)
	SkillState.recalculate_level(game, "fishing")
	game.fishing_runtime.fish_currency = 1000000000.0
	game.skills.build.xp = SkillState.xp_for_level(99)
	SkillState.recalculate_level(game, "build")
	game.material_runtime.add_amount("softwood", 1000000000.0)
	for offer_id in ["rod", "reinforced_rod", "star_rod", "boat", "mirror"]:
		var button := await reveal_offer(offer_id)
		check(button != null, "Missing production offer: " + offer_id)
		if button == null:
			continue
		print("NATIVE_OFFER ", offer_id, " rect=", button.get_global_rect(), " scroll=", game._skill_detail_surface().detail_actions_scroll.scroll_vertical)
		await click(button.get_global_rect().get_center(), offer_id != "rod")
		await settle(0.6)
		var property: String = "boat_built" if offer_id == "boat" else str(offer_id) + "_collected"
		check(bool(game.fishing_runtime.get(property)), "Native offer click failed: " + offer_id)
	print("FISHING_NATIVE_CONTROLS failures=", failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)

func reveal_area_tool(action_id: String) -> Control:
	var fishing = game._fishing_ui_surface()
	var definition: Dictionary = fishing.render_area_module_for_action("fishing", action_id)
	var key: String = game.fishing_runtime.area_module_key("fishing", definition)
	await game._skill_detail_surface()._scroll_to_activity_card(key, false, true)
	await settle(0.8)
	var card: Dictionary = fishing._fishing_method_card_for_action("fishing", action_id)
	return card.tool_selector as Control
