extends "res://scripts/tests/first_session_input.gd"
const AchievementState = preload("res://scripts/achievements/state.gd")
const MasteryState = preload("res://scripts/progression/mastery_state.gd")
const SkillState = preload("res://scripts/progression/skill_state.gd")

func visible_info_button() -> Button:
	for b in get_nodes_in_group("skill_header_info_buttons"):
		if b.is_visible_in_tree() and b.get_global_rect().intersects(Rect2(0,0,1080,1920)):
			return b
	return null

func _run() -> void:
	create_timer(160).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/ham-revision-captures"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080,1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized, "Real main scene must boot")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game._action_runtime().activity_start_count = 10
	for id in ["fight", "build", "woodcutting", "fishing", "thieving"]:
		game.skills[id].xp = SkillState.xp_for_level(40)
		game.skills[id].level = 40
		for action in game.actions_by_skill[id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(id, str(action.id))
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game._save_runtime().fishing_help_seen = true
	game.material_runtime.set_amount("berries", 100)
	game.material_runtime.set_amount("softwood", 500)
	game.material_runtime.set_amount("hardwood", 500)
	game._hub_runtime().hub_modules.woodcutting_totem = {"level":1,"building":false}
	game._hub_runtime().hub_modules.fighting_display = {"level":1,"building":false}
	game.mastery["build:sit-on-the-toolbox"] = {"xp":MasteryState.xp_for_level(3),"level":3}
	game._hub_surface().hub_tutorial_tip_seen = true
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	for toast in game._achievement_toast_surface().achievement_toasts:
		if is_instance_valid(toast):
			toast.queue_free()
	game._achievement_toast_surface().achievement_toasts.clear()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.5)
	game.content_scroll.scroll_vertical = 700
	await settle(0.5)
	if OS.get_environment("IDLE_ELITE_FEEDBACK_FOCUS") == "grove":
		await click((game.skill_cards.woodcutting.button as Control).get_global_rect().get_center())
		await settle(1.2)
		await game._skill_detail_surface()._scroll_to_activity_card("clear-dense-grove", false, true)
		await settle(1.0)
		var focus_card: Dictionary = game.action_cards["woodcutting:clear-dense-grove"]
		await hold((focus_card.stat_boxes.xp as Control).get_global_rect().get_center())
		await capture_information("combo-grove")
		print("focused-feedback failures=", failures)
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	await click((game.skill_cards.build.button as Control).get_global_rect().get_center())
	await settle(1.2)
	await game._skill_detail_surface()._scroll_to_activity_card("sit-on-the-toolbox", false, true)
	await settle(0.8)
	await capture("toolbox-before")
	print("capture skill=",game.selected_skill_id)
	var card: Dictionary = game.action_cards.get("build:sit-on-the-toolbox", {})
	check(not card.is_empty(), "Toolbox card exists")
	if not card.is_empty():
		var time_box: Control = card.stat_boxes.time
		print("time box=",time_box.get_global_rect())
		await hold(time_box.get_global_rect().get_center())
		await capture_information("toolbox-time")
		if OS.get_environment("IDLE_ELITE_FEEDBACK_FOCUS") == "bonuses":
			var short_height: float = card.bonus_panel.root.size.y
			game._test_state_runtime()._god_mode_max_medals_state()
			game._ad_bonus_runtime().seconds_remaining = 3600
			SkillState.invalidate_stat_caches(game)
			var detail = game._skill_detail_surface()
			var best_action: Dictionary = {}
			var most_bonuses := 0
			for action in game.actions_by_skill.build:
				if int(action.get("unlock", 1)) > 40:
					continue
				var details: Dictionary = detail._activity_stat_bonus_details("build", action, "time")
				if (details.bonuses as Array).size() > most_bonuses:
					best_action = action
					most_bonuses = (details.bonuses as Array).size()
			check(most_bonuses >= 4, "Long-list state has at least four real time bonuses")
			await detail._scroll_to_activity_card(str(best_action.id), false, true)
			await settle(0.8)
			var long_card: Dictionary = game.action_cards["build:" + str(best_action.id)]
			await hold((long_card.stat_boxes.time as Control).get_global_rect().get_center())
			await capture_information("time-bonuses-long")
			check(long_card.bonus_panel.root.size.y > short_height + 60, "More bonuses grow the information section")
			print("bonus-list rows=", most_bonuses, " short-height=", short_height, " long-height=", long_card.bonus_panel.root.size.y, " failures=", failures)
			game.queue_free()
			await process_frame
			quit(0 if failures.is_empty() else 1)
			return
		var medal: Control = card.medal
		print("medal rect=",medal.get_global_rect())
		await click(medal.get_global_rect().get_center())
		await capture_information("medals")
	await game._skill_detail_surface()._scroll_to_activity_card("repair-small-shack", false, true)
	await settle(0.6)
	card = game.action_cards["build:repair-small-shack"]
	await hold((card.stat_boxes.xp as Control).get_global_rect().get_center())
	await capture_information("combo-shack")
	await settle(0.8)
	await click(game._navigation_shell().hub_tab.get_global_rect().get_center())
	await settle(1.2)
	if game.current_screen != "hub":
		await click(game._navigation_shell().hub_tab.get_global_rect().get_center())
		await settle(1.2)
	check(game.current_screen == "hub", "Hub tab navigates")
	if game.current_screen != "hub":
		quit(1)
		return
	for level in range(5):
		for id in ["woodcutting_totem", "fighting_display"]:
			game._hub_runtime().hub_modules[id].level = level
			game._hub_surface()._refresh_hub_module_art(id)
		await settle(0.4)
		await capture("hub-tier-%s" % level)
	for id in ["woodcutting_totem", "fighting_display"]:
		game._hub_runtime().hub_modules[id].level = 1
		game._hub_surface()._refresh_hub_module_art(id)
	for module_id in ["woodcutting_totem", "fighting_display", "pond", "barn"]:
		var button: Control = game._hub_surface().hub_module_art[module_id]
		await click(button.get_global_rect().get_center())
		await settle(0.6)
		check(game._hub_runtime().hub_selected_module_id == module_id and game._hub_surface().hub_detail_open, "Hub module opens: " + module_id)
		await capture("hub-" + module_id)
		# Tap outside the panel to dismiss it.
		await click(Vector2(540, 350))
		await settle(0.3)
	await click(game.skills_tab.get_global_rect().get_center())
	await settle(0.7)
	await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center())
	await settle(1.0)
	game.content_scroll.scroll_vertical = 700
	await settle(0.5)
	await click((game.skill_cards.fishing.button as Control).get_global_rect().get_center())
	await settle(1.5)
	await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center())
	await settle(0.5)
	var info := find_visible("FishingToolInformation")
	check(info != null, "Fishing tool information control exists")
	if info != null:
		await click(info.get_global_rect().get_center())
		await capture_information("fishing-tools")
	# Reach Woodcutting through the page switch controls.
	await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center())
	await settle(0.8)
	game.content_scroll.scroll_vertical = 700
	await settle(0.4)
	await click((game.skill_cards.woodcutting.button as Control).get_global_rect().get_center())
	await settle(1.0)
	await game._skill_detail_surface()._scroll_to_activity_card("prune-orchard-row", false, true)
	await settle(0.8)
	card = game.action_cards["woodcutting:prune-orchard-row"]
	await click((card.art_panel as Control).get_global_rect().get_center())
	await settle(0.6)
	await capture("berries-before")
	info = find_visible("BerryInformationButton")
	check(info != null, "Berry help control exists")
	if info != null:
		await click(info.get_global_rect().get_center())
		await capture_information("berries")
	await game._skill_detail_surface()._scroll_to_activity_card("clear-dense-grove", false, true)
	await settle(1.0)
	card = game.action_cards["woodcutting:clear-dense-grove"]
	await hold((card.stat_boxes.xp as Control).get_global_rect().get_center())
	await capture_information("combo-grove")
	print("ham-feedback-capture failures=", failures)
	var out := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"failures":failures}))
	out.close()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func find_visible(node_name: String) -> Control:
	for node in game.find_children(node_name, "Control", true, false):
		if node.is_visible_in_tree() and node.get_global_rect().intersects(Rect2(0,0,1080,1920)):
			return node
	return null

func hold(point: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	Input.parse_input_event(event)
	await settle(1.5)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await settle(0.4)

func capture_information(label: String) -> void:
	await settle(0.6)
	var detail = game._skill_detail_surface()
	if label == "fishing-tools":
		var panel := find_visible("FishingToolDetails")
		check(panel != null, "Tool help expands inside wallet")
		if panel != null:
			await capture(label)
		var wallet: Control = game._fishing_ui_surface().fishing_tool_wallet_popup
		for b in get_nodes_in_group("feedback_help_buttons"):
			if b.name == "FishingToolInformation" and str(b.get_parent().get_meta("tool_id", "")) == "net":
				await click(b.get_global_rect().get_center())
				await settle(0.5)
				check(wallet.get_global_rect().end.y < 1598, "Long net help stays above navigation")
				await capture("fishing-net-help")
				break
		await click(Vector2(90, 390))
		return
	var key: String = detail.expanded_activity_stat_key
	check(not key.is_empty(), label + " expands an activity module")
	var card: Dictionary = game.action_cards.get(key, {})
	if card.is_empty():
		return
	var panel: Control = card.bonus_panel.root
	# Scroll the expanded module above the persistent utility buttons.
	if panel.get_global_rect().end.y > 1380:
		detail.detail_actions_scroll.scroll_vertical += ceili(panel.get_global_rect().end.y - 1380)
		await settle(0.6)
	check(panel.is_visible_in_tree(), label + " details are visible")
	check(panel.get_global_rect().end.y <= 1400, label + " information clears navigation")
	var card_rect := (card.root as Control).get_global_rect()
	var lazy_entry: Dictionary = detail._detail_lazy_entry_for_track_id(str(card.action_id))
	var layout_host: Control = lazy_entry.get("stack_host")
	if is_instance_valid(layout_host):
		check(layout_host.get_global_rect().end.y >= card_rect.end.y - 1, label + " reserves expanded row height after scrolling")
	check(panel.get_global_rect().position.x >= card_rect.position.x and panel.get_global_rect().end.x <= card_rect.end.x, label + " fits module width")
	check(panel.get_global_rect().end.y < (card.root as Control).get_global_rect().end.y, label + " fits inside module")
	check(panel.get_global_rect().end.y < (card.progress as Control).get_global_rect().position.y, label + " clears progress rail")
	await capture(label)
	var kind: String = detail.expanded_activity_stat_kind
	if kind == "medal":
		await click((card.medal as Control).get_global_rect().get_center())
	elif kind == "berries":
		var info := (card.entry as Control).find_child("BerryInformationButton", true, false) as Control
		check(info != null, "Berry information toggle remains in expanded row")
		if info != null:
			var point := info.get_global_rect().get_center()
			if point.y > 1360:
				detail.detail_actions_scroll.scroll_vertical += ceili(point.y - 1250)
				await settle(0.5)
			await click(info.get_global_rect().get_center())
	else:
		await hold((card.stat_boxes[kind] as Control).get_global_rect().get_center())
	check(detail.expanded_activity_stat_key.is_empty(), label + " toggles closed")

func click(point: Vector2, touch := false) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	for down in [true, false]:
		var event: InputEvent
		if touch:
			var e := InputEventScreenTouch.new()
			e.position = point
			e.index = 0
			e.pressed = down
			event = e
		else:
			var e := InputEventMouseButton.new()
			e.position = point
			e.global_position = point
			e.button_index = MOUSE_BUTTON_LEFT
			e.pressed = down
			event = e
		Input.parse_input_event(event)
		await settle(0.06)
	await settle()

