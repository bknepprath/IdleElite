extends "res://scripts/tests/desktop_activity_feedback.gd"

func _run() -> void:
	create_timer(65).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "60")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._save_runtime().fishing_help_seen = true
	game.fishing_runtime.net_collected = true
	game.fishing_runtime.equipped_tool_id = "net"
	game.skills.fishing.xp = SkillState.xp_for_level(3)
	SkillState.recalculate_level(game, "fishing", false)
	game.selected_skill_id = "fishing"
	await game._navigation_shell()._render_screen()
	await settle(3)
	var fishing = game._fishing_ui_surface()
	var method: Dictionary = fishing._fishing_method_card_for_action("fishing", "shallows")
	await click(method.method_image_hit_control.get_global_rect().get_center())
	await settle(0.85)
	check(game.running_action_id == "shallows", "Shallows starts through actual location input")
	check(game.selected_skill_id == "fishing", "Portrait Fishing is visible")
	await capture_desktop("fishing-zones-portrait")
	check_fishing_layout(fishing._fishing_area_card_for_action("fishing", "shallows"))
	print("FISHING_ZONE_SPACING failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
