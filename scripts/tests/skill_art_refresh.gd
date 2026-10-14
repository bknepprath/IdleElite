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
	await show_action("fight", "wrap-hands")
	await show_action("thieving", "count-the-coins")
	await show_action("build", "sharpen-the-pencil")
	await capture_responsive("art-rest-workbench-lane")
	await click_navigation(1)
	await settle(0.7)
	await show_action("build", "patch-fence")
	await show_action("woodcutting", "lean-on-the-axe")
	await capture_responsive("art-timber-clearing")
	var added_paths: Array = ["assets/content/build/actions/sharpen-the-pencil.png", "assets/content/build/backgrounds/timber-yard.png", "assets/content/build/backgrounds/workbench.png", "assets/content/fight/actions/wrap-hands.png", "assets/content/thieving/backgrounds/quiet-market-lane.png", "assets/content/woodcutting/backgrounds/shaded-clearing.png"]
	var texture_bytes := 0
	for path in added_paths:
		var texture: Texture2D = game.visual_texture_cache._texture_or_visual_fallback(path)
		var data := texture.get_image()
		texture_bytes += data.get_data().size()
		print("ART_TEXTURE ", path, " size=", data.get_size(), " format=", data.get_format(), " mipmaps=", data.has_mipmaps(), " bytes=", data.get_data().size())
	print("ART_TEXTURE_BYTES total=", texture_bytes)
	print("SKILL_ART_REFRESH failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func show_action(skill: String, action: String) -> void:
	for index in range(game.desktop_layout.columns.size()):
		if game.desktop_layout.columns[index].skill_id == skill: game.desktop_layout.focus_column(index); break
	await game._skill_detail_surface()._scroll_to_activity_card(action, false, true)
	await settle(0.5)
	var key := skill + ":" + action
	check(game.action_cards.has(key), "Actual activity mounted: " + key)
	if not game.action_cards.has(key): return
	var card: Dictionary = game.action_cards[key]
	var point: Vector2 = card.art_panel.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await process_frame
	var hovered: Control = root.gui_get_hovered_control()
	print("ART_HOVER ", key, " at=", point, " visible=",card.art_panel.is_visible_in_tree(), " hover=", hovered.get_path() if is_instance_valid(hovered) else "none")
	await physical_press(point, 0.12)
	await settle(0.4)
	print("ART_INPUT ",key," running=",game.running_action_id," selected=",game.selected_skill_id," tap=",game._skill_detail_surface().last_action_card_tap_key," unlocked=",game._activity_unlock_runtime()._is_action_unlocked(skill,game._action_data(skill, action))," result=",game.last_result)
	check(game.running_action_id == action, "Actual activity starts: " + key)
	var source: Dictionary = game._action_data(skill, action)
	check(card.bg.texture.resource_path.ends_with(str(source.get("bg", source.get("background", "")))), "Authored background loaded: " + key)
	if action in ["wrap-hands", "sharpen-the-pencil"]:
		check(card.art.texture.resource_path.ends_with(source.art), "Dedicated rest sprite loaded: " + key)
