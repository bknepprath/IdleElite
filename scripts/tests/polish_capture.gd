extends "res://scripts/tests/ham_feedback_capture.gd"

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
	capture_dir = "res://.codex-tmp/polish-review"
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
	await click(game._navigation_shell().hub_tab.get_global_rect().get_center())
	await settle(1.0)
	check(game.current_screen == "hub", "Hub reached through navigation")
	for id in ["barn", "garden", "pond", "mission"]:
		game._hub_runtime().hub_modules[id] = {"level":1,"building":false}
		game._hub_surface()._refresh_hub_module_art(id)
		await click((game._hub_surface().hub_module_art[id] as Control).get_global_rect().get_center())
		await settle(0.8)
		check(game._hub_surface().hub_detail_open and game._hub_runtime().hub_selected_module_id == id, "Open correct hub detail: " + id)
		await capture("hub-" + id)
		await click(Vector2(540, 1550))
		await settle(0.5)
	await open_skill_menu()
	game.content_scroll.scroll_vertical = 700
	await settle(0.4)
	await click((game.skill_cards.fishing.button as Control).get_global_rect().get_center())
	await settle(1.0)
	game.fishing_runtime.collect_tool_from_equipped("net")
	await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center())
	await settle(0.4)
	for tool_id in ["hands", "net", "line", "boat", "mirror"]:
		await inspect_tool_help(tool_id)
	for rod in ["reinforced_rod", "star_rod"]:
		await close_tool_wallet()
		game.fishing_runtime.collect_tool_from_equipped(rod)
		await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center())
		await settle(0.4)
		check(game._fishing_ui_surface().is_fishing_tool_wallet_open(), "Fish circle opens the updated tool wallet: " + rod)
		await inspect_tool_help(rod)
	await close_tool_wallet()
	for touch in [false, true]:
		for repetition in range(3):
			for expected_open in [true, false]:
				await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center(), touch)
				check(game._fishing_ui_surface().is_fishing_tool_wallet_open() == expected_open, "Repeated wallet toggle works: touch=%s repetition=%s open=%s" % [touch, repetition, expected_open])
	await open_skill_menu()
	game.content_scroll.scroll_vertical = 700
	await settle(0.4)
	await click((game.skill_cards.build.button as Control).get_global_rect().get_center())
	await settle(1.0)
	await game._skill_detail_surface()._scroll_to_activity_card("stack-bricks", false, true)
	await settle(0.8)
	var card: Dictionary = game.action_cards["build:stack-bricks"]
	await click((card.art_panel as Control).get_global_rect().get_center())
	check(game.running_action_id == "stack-bricks", "Activity starts through real UI")
	await hold((card.stat_boxes.time as Control).get_global_rect().get_center())
	check(game.running_action_id == "stack-bricks", "Opening help keeps activity running")
	var before: String = card.time.text
	game._ad_bonus_runtime().seconds_remaining = 3600
	game._update_ui(0.0, true)
	check(card.time.text != before, "Cached card updates when ad bonus changes")
	game._ad_bonus_runtime().seconds_remaining = 0
	game._update_ui(0.0, true)
	check(card.time.text == before, "Cached card resets when bonus expires")
	await capture("activity-help")
	# Switch to a second activity after building partial progress, then return.
	var progress_before: float = game.action_progress
	game._action_runtime()._start_action("build", "hammer-nails", false, false)
	game._action_runtime()._start_action("build", "stack-bricks", false, false)
	check(is_equal_approx(game.action_progress, progress_before), "Switching activities retains partial progress")
	print("polish-ui failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func open_skill_menu() -> void:
	if game.current_screen not in ["skill", "menu"]:
		await click(game.skills_tab.get_global_rect().get_center())
		await settle(1.0)
	if game.current_screen != "menu":
		await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center())
		await settle(1.0)
	check(game.current_screen == "menu" and game.content_scroll != null, "Skill menu opens through its visible controls")

func inspect_tool_help(tool_id: String) -> void:
	var found := false
	for button in get_nodes_in_group("feedback_help_buttons"):
		if button.name == "FishingToolInformation" and str(button.get_parent().get_meta("tool_id", "")) == tool_id and button.is_visible_in_tree():
			found = true
			await click(button.get_global_rect().get_center())
			await settle(0.5)
			var wallet: Control = game._fishing_ui_surface().fishing_tool_wallet_popup
			check(wallet.get_global_rect().end.y < 1598, "Readable help stays above navigation: " + tool_id)
			var running_before: String = game.running_skill_id + ":" + game.running_action_id
			var details: Control = wallet.get_node("FishingToolDetails")
			await click(details.get_global_rect().get_center())
			check(game.running_skill_id + ":" + game.running_action_id == running_before, "Help text taps do not reach activities: " + tool_id)
			await capture("fishing-" + tool_id + "-help")
			await click(button.get_global_rect().get_center())
			check(wallet.get_node_or_null("FishingToolDetails") == null, "Same information button closes help: " + tool_id)
			var base: Rect2 = wallet.get_meta("wallet_base_rect")
			check(is_equal_approx(wallet.size.x, base.size.x), "Closing help restores the compact tool grid: " + tool_id)
			break
	check(found, "Tool help reached through its information button: " + tool_id)

func close_tool_wallet() -> void:
	await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center())
	await settle(0.4)
	check(not game._fishing_ui_surface().is_fishing_tool_wallet_open(), "Fish circle closes its tool wallet")
