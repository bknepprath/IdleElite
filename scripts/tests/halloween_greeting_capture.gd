extends "res://scripts/tests/first_session_input.gd"

func _run() -> void:
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ADJACENT_SKILL_PAGES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	AudioServer.set_bus_mute(0,true)
	create_timer(180).timeout.connect(func():
		if OS.get_environment("IDLE_ELITE_GREETING_DEMO") != "1": quit(1)
	)
	capture_dir = OS.get_environment("IDLE_ELITE_GREETING_OUTPUT")
	if capture_dir.is_empty(): capture_dir = "res://outputs/verification/halloween-greeting-oct23"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.borderless = true
	if OS.get_environment("IDLE_ELITE_GREETING_PREVIEW_ONLY") == "1":
		await boot(Vector2i(1920,1080))
		await capture_raw("desktop-preview",Vector2i(1920,1080))
		print("HALLOWEEN_GREETING_PREVIEW_READY failures=",JSON.stringify(failures))
		return
	await boot(Vector2i(1080,1920),false,false)
	check(not game.loaded_save_this_boot,"Fresh fixture is a first-time player")
	check(not game._halloween_runtime().greeting_visible(),"First-time startup never displays Halloween popup")
	check(not game._halloween_runtime().launch_greeting_claimed,"First-time startup does not claim greeting")
	await capture_raw("portrait-first-time-player",Vector2i(1080,1920))
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "0")
	check(game.save_game_now(),"Returning-player fixture is written to isolated storage")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	check(not game.loaded_save_this_boot,"Saving during first session does not turn it into a returning launch")
	await settle(.4)
	check(not game._halloween_runtime().greeting_visible(),"First-time player remains exempt after saving")
	await shutdown_game()
	await boot(Vector2i(1080,1920))
	check(game.loaded_save_this_boot,"Next launch restores the real saved game")
	var halloween = game._halloween_runtime()
	check(halloween.greeting_visible(),"Portrait startup automatically presents greeting")
	check(game._input_routing_shell()._any_modal_overlay_visible(),"Greeting blocks background input")
	await capture_raw("portrait-open",Vector2i(1080,1920))
	var old_screen: String = game.current_screen
	var old_action: String = game.running_action_id
	await click(Vector2(540,830),true)
	await settle(.5)
	check(not halloween.greeting_visible(),"Tapping the artwork dismisses the popup")
	check(game.current_screen == old_screen and game.running_action_id == old_action,"Dismissal does not click through to an activity or navigation")
	await settle(.8)
	check(not halloween.greeting_visible(),"Does not reappear within the same launch")
	await capture_raw("portrait-dismissed",Vector2i(1080,1920))
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	await game._navigation_shell()._render_screen()
	await settle(.7)
	await click((game.settings_tab as Control).get_global_rect().get_center(),true)
	await settle(.4)
	check(game.current_screen == "settings" or (is_instance_valid(game.settings_overlay) and game.settings_overlay.visible),"Normal navigation works after dismissal")
	await shutdown_game()
	await boot(Vector2i(1920,1080))
	check(game._halloween_runtime().greeting_visible(),"Fresh launch shows greeting again")
	await capture_raw("desktop-open",Vector2i(1920,1080))
	await click(Vector2(24,24),true)
	await settle(.4)
	check(not game._halloween_runtime().greeting_visible(),"Tapping outside the panel dismisses it")
	await capture_raw("desktop-dismissed",Vector2i(1920,1080))
	await shutdown_game()
	await boot(Vector2i(1080,1920),true)
	check(not game._halloween_runtime().greeting_visible(),"Expired greeting is absent from real startup")
	check(not game._halloween_runtime().launch_greeting_claimed,"Expired startup never claims or constructs the popup")
	await shutdown_game()
	print("HALLOWEEN_GREETING_UI failures=",JSON.stringify(failures))
	if OS.get_environment("IDLE_ELITE_GREETING_DEMO") == "1":
		await boot(Vector2i(1920,1080))
		await capture_raw("desktop-preview",Vector2i(1920,1080))
		print("HALLOWEEN_GREETING_PREVIEW_READY failures=",JSON.stringify(failures))
		return
	quit(0 if failures.is_empty() else 1)

func boot(dimensions: Vector2i, expired := false, expect_greeting := true) -> void:
	root.size = dimensions
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	if expired: game.set_process(false)
	for frame in range(2400):
		await process_frame
		if game.startup_initialized and not game._boot_warmup_runtime().active and not is_instance_valid(game._boot_warmup_runtime().overlay): break
	check(game.startup_initialized,"Production main scene completes startup")
	if expired:
		# Deterministic boundary setup; the actual production launch path remains intact.
		game._halloween_runtime().launch_greeting_end_date = "2026-10-01"
		game.set_process(true)
		await settle(.8)
	elif expect_greeting:
		for frame in range(600):
			await process_frame
			if game._achievement_overlay_surface().offline_summary_visible():
				check(not game._halloween_runtime().greeting_visible(),"Offline summary takes precedence over greeting")
				game._achievement_overlay_surface()._close_offline_summary_overlay()
			if game._halloween_runtime().greeting_visible(): break
		await settle(.3)
	else:
		await settle(.8)

func shutdown_game() -> void:
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	await process_frame

func capture_raw(label: String, dimensions: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var pixels := root.get_texture().get_image()
	check(pixels.get_size() == dimensions,"Raw viewport dimensions: "+label)
	pixels.save_png(capture_dir+"/"+label+".png")
