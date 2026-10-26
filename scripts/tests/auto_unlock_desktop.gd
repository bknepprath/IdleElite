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
	game.auto_unlock_lockpads_enabled = false
	for skill in game.skills:
		game.skills[skill].xp = 0
		game.skills[skill].level = 1
	game._activity_unlock_runtime().manual_activity_unlocks.clear()
	await game._navigation_shell()._render_screen()
	await wait_layout()
	game.desktop_layout.focus_column(0)
	var runtime = game._activity_unlock_runtime()
	var action: Dictionary = game._action_data("build", "hammer-nails")
	var card: Dictionary = game.action_cards.get("build:hammer-nails", {})
	check(not card.is_empty(), "Building level-two card mounted in side column")
	await capture_responsive("auto-lock-before")
	game.auto_unlock_lockpads_enabled = true
	game.skills.build.xp = SkillState.xp_for_level(2)
	game.skills.build.level = 2
	runtime._queue_activity_unlock_readiness("build", 1, 2, {"build": ["hammer-nails"]})
	print("AUTO_LOCK_REPRO immediately_unlocked=", runtime._is_action_unlocked("build", action), " focused=", game.selected_skill_id)
	check(not runtime._is_action_unlocked("build", action), "Visible side-column lock waits for falling animation")
	await settle(0.8)
	await capture_responsive("auto-lock-falling")
	var group = card.get("lock_overlay", {}).get("group")
	check(is_instance_valid(group) and group.unlock_drop_active, "Building side-column padlock actually falls")
	check(game.selected_skill_id == "fight", "Auto-unlock does not steal focus")
	await settle(2.5)
	await capture_responsive("auto-lock-settled")
	check(runtime._is_action_unlocked("build", action), "Building unlock completes after animation")
	print("AUTO_LOCK_ANIMATION failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
