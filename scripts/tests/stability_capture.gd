extends "res://scripts/tests/ham_feedback_capture.gd"

func _run() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/stability-captures"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
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
	game._test_state_runtime()._god_mode_max_skills_state()
	game._test_state_runtime()._god_mode_unlock_actions_state()
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game.dark_mode_enabled = true
	game._settings_surface().apply_dark_mode_visual()
	game._hub_runtime().hub_modules.mission = {"level": 1, "building": false}
	game._hub_runtime().hub_missions = [{"skill_id": "build", "action_id": "sit-on-the-toolbox", "target": 40, "remaining": 27, "assigned_unix": game._unix_now()}]
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	game.current_screen = "menu"
	await game._navigation_shell()._render_screen(false, -1, false)
	await settle(1.0)
	await click(game.skill_cards.build.button.get_global_rect().get_center())
	await settle(1.0)
	await game._skill_detail_surface()._scroll_to_activity_card("sit-on-the-toolbox", false)
	await settle(1.0)
	check(game.current_screen == "skill" and game.selected_skill_id == "build", "Build page reached through actual menu")
	await capture("dark-mode-count")
	var start := Vector2(800, 850)
	var motion := InputEventMouseMotion.new()
	motion.position = start
	motion.global_position = start
	root.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = start
	press.global_position = start
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	root.push_input(press, true)
	await settle(0.1)
	for i in range(10):
		var drag := InputEventMouseMotion.new()
		drag.position = start - Vector2((i + 1) * 24, 0)
		drag.global_position = drag.position
		drag.relative = Vector2(-24, 0)
		drag.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(drag, true)
		await process_frame
	await capture("swipe-interrupted")
	game.notification(Node.NOTIFICATION_WM_MOUSE_EXIT)
	await settle(0.5)
	check(not game._skill_swipe_activity_surface().skill_swipe_tracking, "Window exit releases the swipe")
	await capture("swipe-settled")
	if failures.is_empty():
		print("stability-capture: PASS")
	quit(0 if failures.is_empty() else 1)
