extends "res://scripts/tests/ad_bonus_page_capture.gd"

func _run() -> void:
	create_timer(180).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	ProjectSettings.set_setting("application/config/itch_browser", true)
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "170")
	AudioServer.set_bus_mute(0, true)
	capture_dir = "res://outputs/verification/browser-ad-layout"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(2048,1016)
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
	game._halloween_runtime().launch_greeting_claimed = true
	game._halloween_runtime().dismiss_launch_greeting()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.desktop_layout.restore_preferences({})
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.2)

	for dimensions in [Vector2i(2048,1016),Vector2i(1366,768),Vector2i(1024,600)]:
		root.size = dimensions
		proof_size = dimensions
		await settle(1.0)
		var ad_tab: Control = game.desktop_layout.ribbon_buttons.shop if game.desktop_layout.enabled() else game._navigation_shell().shop_tab
		await click(ad_tab.get_global_rect().get_center())
		await settle(1.5)
		check(game.current_screen == "shop", "Actual ribbon opens ad page")
		if game.current_screen != "shop":
			await capture("blocked")
			quit(1)
			return
		var shop = game._shop_surface()
		var visible_rect: Rect2 = shop.presentation_scroll.get_global_rect()
		for control in [shop.presentation_hero, shop.offer_button, shop.bonus_timer, shop.bonus_bar, shop.presentation_page.get_node("AdBonusDeveloperNote")]:
			check(visible_rect.grow(1).encloses(control.get_global_rect()), "Ad control fits without scrolling: " + control.name + str(dimensions))
		print("AD_LAYOUT ", dimensions, " canvas=",game.size," page=",shop.presentation_page.size," scroll=",visible_rect)
		await capture("ads-"+str(dimensions.x)+"x"+str(dimensions.y))
		await click(shop.offer_button.get_global_rect().get_center())
		await settle(0.3)
		var privacy = game._settings_surface().privacy()
		check(privacy.visible() and privacy.overlay.name == "ItchAdNotice", "Watch ad opens itch-only notice")
		check(not game._ad_bonus_runtime().ad_loading and game._ad_bonus_runtime().web_bridge == null, "Itch never loads an ad SDK")
		check(game._ad_bonus_runtime().seconds_remaining == 0.0, "Notice grants no bonus")
		await capture("itch-notice-"+str(dimensions.x))
		var close_button: Button = privacy.overlay.find_child("CloseNotice", true, false)
		await click(close_button.get_global_rect().get_center())
		check(not privacy.visible(), "Close dismisses the notice")
		await settle(0.2)
		await click(shop.offer_button.get_global_rect().get_center())
		await click(Vector2(12,12))
		check(not privacy.visible(), "Outside click dismisses the notice")
		if dimensions.x == 2048:
			for entry in [["skill","skills"],["settings","settings"],["home","progress"],["hub","hub"]]:
				await click(game.desktop_layout.ribbon_buttons[entry[0]].get_global_rect().get_center(),true)
				await settle(1.4)
				await capture(entry[1])
	ProjectSettings.set_setting("application/config/itch_browser", false)
	print("BROWSER_AD_LAYOUT failures=",failures)
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await settle(0.3)
	quit(0 if failures.is_empty() else 1)

func click(point: Vector2, touch := false) -> void:
	await super.click(point * Vector2(root.size) / game.size, touch)
