extends "res://scripts/tests/first_session_input.gd"
func _run() -> void:
	capture_dir = "res://.codex-tmp/scrolling-arrows" + ("-early" if OS.get_environment("IDLE_ELITE_TEST_EARLY_ARROWS") == "1" else "")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	if OS.get_environment("IDLE_ELITE_TEST_EARLY_ARROWS") != "1":
		game._test_state_runtime()._god_mode_max_skills_state()
		game._test_state_runtime()._god_mode_unlock_actions_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._navigation_shell()._select_skill("fight")
	await settle(1.0)
	for screen in ["fight", "fishing", "fight"]:
		var scroll = game._skill_detail_surface().detail_actions_scroll
		for i in range(8):
			scroll.scroll_vertical = scroll.get_max_scroll_vertical()
			await settle(0.3)
		var footer: Control = scroll.find_child("PageSwitchModule", true, false)
		check(footer != null, "Arrows belong to scrolling content: " + screen)
		if footer == null: break
		check(scroll.get_parent().get_node_or_null("PageSwitchModule") == null, "No fixed footer")
		var end_y := footer.get_global_rect().position.y
		await capture(screen + "-bottom")
		var old_scroll: int = scroll.scroll_vertical
		scroll.scroll_vertical = maxi(0, old_scroll - 220)
		await settle(0.3)
		check(absf(footer.get_global_rect().position.y - end_y - float(old_scroll - scroll.scroll_vertical)) < 2, "Arrows move with scroll")
		await capture(screen + "-scrolled")
		scroll.scroll_vertical = old_scroll
		await settle(0.3)
		var target := "fishing" if screen == "fight" else "fight"
		for button in get_nodes_in_group("page_switch_buttons"):
			if button.is_visible_in_tree() and button.get_meta("page_switch_owner_skill_id", "") == screen and button.get_meta("page_switch_target_skill_id", "") == target:
				await click(button.get_global_rect().get_center(), true)
				break
		await settle(2.0)
		check(game.selected_skill_id == target, "Scrolling arrows navigate: " + target)
	print("FOOTER_CHECK failures=", failures)
	game.queue_free()
	await settle(1.0)
	quit(0 if failures.is_empty() else 1)

