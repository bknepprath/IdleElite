extends "res://scripts/tests/ad_bonus_page_capture.gd"

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Ad bonus capture requires --visible-game")
		quit(1)
		return
	create_timer(160).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "150")
	capture_dir = "res://outputs/verification/itch-notice-portrait"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	ProjectSettings.set_setting("application/config/itch_browser", true)
	root.content_scale_size = Vector2i(1080,1920)
	root.size = Vector2i(1080,1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for _frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized,"Production main scene must boot")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	for skill in game.skill_defs:
		game.skills[skill.id] = {"xp":SkillState.xp_for_level(99),"level":99}
		for action in game.actions_by_skill[skill.id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(skill.id,str(action.id))
			if MasteryState.action_has_mastery(game,action):
				game.mastery[str(skill.id)+":"+str(action.id)] = {"xp":MasteryState.xp_for_level(3),"level":3}
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game,false),game._save_runtime().achievement_toast_seen_ids,[])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.2)
	var ads = game._ad_bonus_runtime()
	ads.seconds_remaining = 0.0
	await click(game._navigation_shell().shop_tab.get_global_rect().get_center(),true)
	await settle(1.0)
	check(game.current_screen == "shop","Reach the changed screen through the actual Shop navigation")
	var shop = game._shop_surface()

	await click(shop.offer_button.get_global_rect().get_center(),true)
	await settle(0.4)
	var privacy = game._settings_surface().privacy()
	check(privacy.visible(), "Itch message opens in portrait")
	await capture("notice")
	await click(Vector2(20,20),true)
	check(not privacy.visible(), "Outside touch dismisses")
	print("ITCH_PORTRAIT failures=",failures)
	game.queue_free()
	await settle(0.3)
	quit(0 if failures.is_empty() else 1)
