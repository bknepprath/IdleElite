extends "res://scripts/tests/desktop_responsive.gd"

func _run() -> void:
	create_timer(180).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "175")
	AudioServer.set_bus_mute(0, true)
	Desktop.fit_startup_window(root)
	await settle(0.15)
	var usable := DisplayServer.screen_get_usable_rect(root.current_screen)
	check(usable.encloses(Rect2i(root.get_position_with_decorations(), root.get_size_with_decorations())), "Actual initial decorated window fits monitor work area")
	print("WINDOW_FIT usable=", usable, " decorated=", Rect2i(root.get_position_with_decorations(), root.get_size_with_decorations()))
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._save_runtime().achievement_toast_seen_ids["activity-crit"] = true
	game._save_runtime().achievement_toast_seen_ids["activity-mega-crit"] = true
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	game.desktop_layout.restore_preferences({})
	game.desktop_layout.rotate_slots("fight")
	game.selected_skill_id = "fight"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	var runtime = game._activity_unlock_runtime()
	game.auto_unlock_lockpads_enabled = false
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(6) + 15
		SkillState.recalculate_level(game, skill, false)
		for action in game.actions_by_skill[skill]:
			if int(action.unlock) < 6: runtime._mark_action_manually_unlocked(skill, str(action.id))
	for action in AchievementState.mastery_actions_for_skill(game, "fight").slice(0, 5):
		game.mastery[game._action_key("fight", str(action.id))] = {"xp": MasteryState.xp_for_level(1), "level": 1}
	game.reward_bonus_cache.clear()
	check(game._navigation_shell()._shop_unlocked(), "Fixture earns five bronze medals for Shop")
	var xp := SkillState.xp_progress(game.skills, "build", 6)
	check(xp.level_current == 15, "XP counter begins at this level's threshold")
	check(SkillState.level_xp_text(game.skills, "build", 6).contains("15/"), "XP text matches current-level fraction")
	game.desktop_layout.rotate_slots("fight")
	game.selected_skill_id = "fight"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	game.desktop_layout.focus_column(2)
	var detail = game._skill_detail_surface()
	await detail._scroll_to_activity_card("patch-fence", false, true)
	await settle(0.5)
	var card: Dictionary = game.action_cards["build:patch-fence"]
	await click(card.button.get_global_rect().get_center())
	check(game.running_skill_id == "build", "Actual source activity starts")
	await check_calm_reward()
	for entry in detail.detail_lazy_plan:
		if str(entry.get("track_id", "")) == "project:build-repair-small-shack":
			detail.detail_actions_scroll.scroll_vertical = int(entry.y)
			detail._sync_detail_lazy_visible_cards(true, 30)
			break
	await settle(0.6)
	var panel: Control
	for item in get_nodes_in_group("activity_project_panels"):
		if item.skill_id == "build" and item.project.id == "build-repair-small-shack": panel = item
	check(is_instance_valid(panel), "Next project is mounted beside the source")
	if is_instance_valid(panel):
		check(panel.next_unlock, "Nearest locked project has the emphasis")
		check(panel.status_label.text == "Patch Fence", "Compact cover identifies unfinished work")
		check(panel.rail.value > 0, "Actual completion advances the visible requirement rail")
	await capture_responsive("project-contribution")
	if is_instance_valid(panel):
		await click(panel.hit_button.get_global_rect().get_center())
		await settle(0.35)
		var source_button: Button
		for button in get_nodes_in_group("feedback_help_buttons"):
			if button.get_meta("project_source", "") == "build:patch-fence" and button.is_visible_in_tree(): source_button = button
		check(is_instance_valid(source_button), "Project source button is available")
		if is_instance_valid(source_button):
			await click(source_button.get_global_rect().get_center())
			await wait_layout()
			check(game.selected_skill_id == "build", "Project source navigation selects the requested skill")
	await detail._scroll_to_activity_card("patch-fence", false, true)
	await settle(0.5)
	card = game.action_cards["build:patch-fence"]
	await physical_press(card.stat_boxes.xp.get_global_rect().get_center(), 0.7)
	await settle(0.6)
	check(card.get("bonus_expanded", false), "Actual XP chip opens its details")
	var stat_key: String = detail.expanded_activity_stat_key
	var saved_scroll: int = detail.detail_actions_scroll.scroll_vertical
	var slots: Array = game.desktop_layout.skill_slots.duplicate()
	await click(game.desktop_layout.ribbon_buttons.shop.get_global_rect().get_center())
	await settle(1)
	check(game.current_screen == "shop", "Actual Shop button leaves Skills")
	await capture_responsive("shop-visited")
	await click(game.desktop_layout.ribbon_buttons.skill.get_global_rect().get_center())
	await wait_layout()
	check(game.desktop_layout.skill_slots == slots, "Shop round trip retains the same skill columns")
	check(detail.expanded_activity_stat_key == stat_key and not stat_key.is_empty(), "Shop round trip retains expanded details")
	var build_column: Dictionary
	for column in game.desktop_layout.columns:
		if column.skill_id == "build": build_column = column
	check(not build_column.is_empty(), "Building stays visible after shop")
	if not build_column.is_empty():
		check(abs(build_column.context.detail_actions_scroll.scroll_vertical - saved_scroll) < 3, "Shop round trip retains vertical position")
	await capture_responsive("details-restored")
	game.desktop_layout.focus_column(0)
	root.size = Vector2i(1280,720)
	await wait_layout()
	check(game.desktop_layout.columns.back().skill_id == "build", "Narrowing keeps running skill in the nearest available column")
	await click(game.desktop_layout.ribbon_buttons.chat.get_global_rect().get_center())
	await wait_layout()
	check(game.desktop_layout.columns[0].skill_id == "build", "Chat preserves the running skill when only one column fits")
	await capture_responsive("narrow-running-skill")
	await click(game.desktop_layout.ribbon_buttons.chat.get_global_rect().get_center())
	await wait_layout()
	root.size = Vector2i(1920,1080)
	await wait_layout()
	check(game.desktop_layout.columns.back().skill_id == "build", "Enlarging restores the running skill's original column")
	await click(game.desktop_layout.ribbon_buttons.home.get_global_rect().get_center())
	await settle(1.5)
	var achievements = game._achievement_overlay_surface()
	check(achievements.achievement_skill_level_labels.build.text.contains("lifetime XP"), "Progress retains lifetime totals")
	await capture_responsive("lifetime-progress")
	await click(game.desktop_layout.ribbon_buttons.skill.get_global_rect().get_center())
	await wait_layout()
	root.size = Vector2i(1080,1350)
	await settle(1.5)
	game._navigation_shell()._select_skill("build")
	await settle(1.5)
	check(not game.desktop_layout.enabled(), "Portrait uses the mobile skill layout")
	for entry in detail.detail_lazy_plan:
		if str(entry.get("track_id", "")) == "project:build-repair-small-shack":
			detail.detail_actions_scroll.scroll_vertical = int(entry.y)
			detail._sync_detail_lazy_visible_cards(true, 30)
			break
	await settle(0.5)
	await capture_responsive("project-portrait")
	print("PROGRESSION_POLISH failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func check_calm_reward() -> void:
	await capture_responsive("routine-xp-before")
	var reward: Control
	for frame in range(600):
		await process_frame
		for item in get_nodes_in_group("skill_reward_float"):
			if item.get_meta("routine_xp", false): reward = item; break
		if is_instance_valid(reward): break
	check(is_instance_valid(reward), "Actual completion creates routine XP feedback")
	if not is_instance_valid(reward): return
	await settle(0.18)
	check(reward.scale.is_equal_approx(Vector2.ONE), "Routine XP stays at a steady scale")
	await capture_responsive("routine-xp-transition")
	await settle(1.28)
	check(not is_instance_valid(reward), "Routine XP finishes and is freed")
	await capture_responsive("routine-xp-settled")
