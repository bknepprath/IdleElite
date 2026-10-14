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
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(9)
		SkillState.recalculate_level(game, skill, false)
		game.stamina[skill] = 5.0
		for action in game.actions_by_skill[skill]:
			if int(action.unlock) <= 9: game._activity_unlock_runtime()._mark_action_manually_unlocked(skill, str(action.id))
	for entry in game._project_runtime().definitions.values():
		if int(entry.action.unlock) <= 9:
			var row := {}
			for step in entry.project.steps: row[str(step.id)] = int(step.target)
			if entry.project.has("cost"): row.materials = 1
			game._project_runtime().work[str(entry.project.id)] = row
	game.desktop_layout.rotate_slots("fight")
	game.selected_skill_id = "fight"
	await game._navigation_shell()._render_screen()
	await wait_layout()
	game.built_modules.erase("fight:duel-fence-post")
	game.material_runtime.set_amount("scrapwood", 0)
	await game._navigation_shell()._render_screen()
	await wait_layout()
	await show_build()
	await capture_responsive("build-panel-desktop-unaffordable")
	var card: Dictionary = game.action_cards["fight:duel-fence-post"]
	await physical_press(card.build_button_panel.get_global_rect().get_center(), 0.06)
	await settle(0.4)
	check(not game.built_modules.get("fight:duel-fence-post", false), "Insufficient materials never builds")
	game.material_runtime.set_amount("scrapwood", 3)
	await game._navigation_shell()._render_screen()
	await wait_layout()
	await show_build()
	await capture_responsive("build-panel-desktop-ready")
	root.size = Vector2i(1080,1920)
	await wait_layout()
	game._navigation_shell()._select_skill("fight")
	await wait_layout()
	await show_build()
	await capture_responsive("build-panel-portrait-ready")
	root.size = Vector2i(1920,1080)
	await wait_layout()
	await show_build()
	card = game.action_cards["fight:duel-fence-post"]
	var xp: int = game.skills.build.xp
	var fight_xp: int = game.skills.fight.xp
	await build_click_with_transition(card.build_button_panel.get_global_rect().get_center())
	await settle(0.8)
	check(game.built_modules.get("fight:duel-fence-post", false), "Build click persists built state")
	check(game.material_runtime.amount("scrapwood") == 0.0, "Build spends exactly three scrapwood")
	check(game.skills.build.xp == xp + 60, "Build grants expected Building XP once")
	check(game.skills.fight.xp == fight_xp, "Build does not grant Fighting XP")
	check(game.running_action_id == "", "Build click does not start training")
	await show_build()
	await capture_responsive("build-panel-built")
	card = game.action_cards["fight:duel-fence-post"]
	check(not is_instance_valid(card.get("build_overlay")), "Finished module removes construction overlay")
	await physical_press(card.art_panel.get_global_rect().get_center(), 0.05)
	await settle(0.3)
	check(game.running_action_id == "duel-fence-post", "Built module starts via normal activity UI")
	check(game.material_runtime.amount("scrapwood") == 0.0, "Starting built module never charges again")
	print("BUILD_PANEL_REFRESH failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func show_build() -> void:
	for index in range(game.desktop_layout.columns.size()):
		if game.desktop_layout.columns[index].skill_id == "fight": game.desktop_layout.focus_column(index); break
	await game._skill_detail_surface()._scroll_to_activity_card("duel-fence-post", true, true)
	await settle(0.7)
	check(game.action_cards.has("fight:duel-fence-post"), "Production construction card mounted")

func build_click_with_transition(point: Vector2) -> void:
	for down in [true, false]:
		var state_event := InputEventMouseButton.new()
		state_event.position = Vector2(-100, -100)
		state_event.global_position = state_event.position
		state_event.button_index = MOUSE_BUTTON_LEFT
		state_event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		state_event.pressed = down
		Input.parse_input_event(state_event)
		var event := state_event.duplicate() as InputEventMouseButton
		event.position = point
		event.global_position = point
		root.push_input(event, true)
		await settle(0.04 if down else 0.1)
	await capture_responsive("build-panel-transition")
