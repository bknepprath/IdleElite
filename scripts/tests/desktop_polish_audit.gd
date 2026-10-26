extends "res://scripts/tests/desktop_responsive.gd"

func _run() -> void:
	create_timer(160).timeout.connect(func(): quit(1))
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
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	game.desktop_layout.restore_preferences({})
	game.desktop_layout.rotate_slots("fight")
	game.selected_skill_id = "fight"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(98) + int((SkillState.xp_for_level(99) - SkillState.xp_for_level(98)) * 0.9)
		SkillState.recalculate_level(game, skill, false)
	game._save_runtime().achievement_toast_seen_ids["activity-crit"] = true
	game._save_runtime().achievement_toast_seen_ids["activity-mega-crit"] = true
	for dimensions in [Vector2i(1920,1080), Vector2i(3840,2160), Vector2i(1280,720)]:
		root.size = dimensions
		await game._navigation_shell()._render_screen()
		await wait_layout()
		for column in game.desktop_layout.columns:
			check_header(column)
			var xp: Label = column.context.detail_xp_label
			var gauge: Control = column.context.detail_fish_circle if is_instance_valid(column.context.detail_fish_circle) else column.context.detail_regen_circle
			check(xp.get_parent().get_global_rect().end.x + 10 <= gauge.get_global_rect().position.x, "Late-game XP clear of gauge: " + column.skill_id + str(root.size))
		await capture_responsive("audit-level98-" + str(root.size.x))
		await click_navigation(1)
		await click_navigation(1)
		await click_navigation(1)
		for column in game.desktop_layout.columns: check_header(column)
		await capture_responsive("audit-other-skills-" + str(root.size.x))
		await click_navigation(1)
		await click_navigation(1)
		await click(game.desktop_layout.ribbon_buttons.scores.get_global_rect().get_center())
		await wait_layout()
		for column in game.desktop_layout.columns: check_header(column)
		await capture_responsive("audit-scores-" + str(root.size.x))
		await click(game.desktop_layout.ribbon_buttons.scores.get_global_rect().get_center())
		await wait_layout()
	await check_reward_drag()
	print("DESKTOP_POLISH failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func capture_desktop(label: String) -> void:
	await capture_responsive(label)

func check_reward_drag() -> void:
	root.size = Vector2i(1920,1080)
	await wait_layout()
	game.desktop_layout.rotate_slots("fight")
	await game._navigation_shell()._render_screen()
	await wait_layout()
	await click(game.action_cards["fight:push-ups"].button.get_global_rect().get_center())
	var reward: Control
	for frame in range(600):
		await process_frame
		for item in get_nodes_in_group("skill_reward_float"):
			if item.has_meta("reward_anchor_id"):
				reward = item
				break
		if is_instance_valid(reward): break
	check(is_instance_valid(reward), "Actual completion produces an anchored XP popup")
	if not is_instance_valid(reward): return
	await settle(0.12)
	var anchor: Control = instance_from_id(reward.get_meta("reward_anchor_id"))
	var initial_reward: Vector2 = reward.global_position
	var initial_anchor: Vector2 = anchor.global_position
	await drag_carousel(1, "reward-drag")
	check(is_instance_valid(reward), "XP popup survives the visible column move")
	if is_instance_valid(reward) and is_instance_valid(anchor):
		var motion_error: float = absf((reward.global_position.x - initial_reward.x) - (anchor.global_position.x - initial_anchor.x))
		print("REWARD_ANCHOR horizontal_error=", motion_error)
		check(motion_error < 5.0, "XP popup follows its own activity across columns")
	await settle(1.5)
	check(not is_instance_valid(reward), "XP popup and tween finish after movement")
