extends "res://scripts/tests/desktop_responsive.gd"

func _run() -> void:
	create_timer(100).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "95")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.size = Vector2i(1920,1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	while not game.startup_initialized or game._boot_warmup_runtime().active: await process_frame
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game.desktop_layout.restore_preferences({})
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.activity_crit_seen = true
	game.activity_mega_crit_seen = true
	game._save_runtime().achievement_toast_seen_ids["activity-crit"] = true
	game._save_runtime().achievement_toast_seen_ids["activity-mega-crit"] = true
	game.desktop_layout.carousel_discovered = true
	for id in game.skills:
		game.skills[id].xp = SkillState.xp_for_level(4)
		SkillState.recalculate_level(game, id, false)
	for row in [["fight", "wrestle-stuck-gate-latch", "build"], ["build", "saw-planks", "woodcutting"], ["woodcutting", "split-firewood", "fishing"]]:
		var owner: String = row[0]
		var action_id: String = row[1]
		var support: String = row[2]
		var action: Dictionary = game._action_data(owner, action_id)
		var rewards: Dictionary = game._action_runtime()._completion_xp_reward_map(action, owner, false, false, false, false)
		check(int(rewards[owner]) == 4 and int(rewards[support]) == 2, "Early combo pays 4 primary and 2 supporting XP: " + action_id)
		check(game._activity_unlock_runtime()._action_requirements_met(owner, action), "Existing early requirements remain reachable: " + action_id)
		game._activity_unlock_runtime()._mark_action_manually_unlocked(owner, action_id)
		game.desktop_layout.rotate_slots(owner)
		game.selected_skill_id = owner
		game.desktop_layout.focused_index = 0
		await game._navigation_shell()._render_screen()
		await wait_layout()
		game._skill_detail_surface()._scroll_to_activity_card(action_id, true, true)
		await settle(0.5)
		var card: Dictionary = game.action_cards.get(owner + ":" + action_id, {})
		check(not card.is_empty(), "Combo is mounted in production page: " + action_id)
		if card.is_empty(): continue
		var before_primary := int(game.skills[owner].xp)
		var before_support := int(game.skills[support].xp)
		var button: Control = card.get("button", card.root)
		await click(button.get_global_rect().get_center())
		check(game.running_action_id == action_id, "Actual input starts combo: " + action_id)
		for frame in range(240):
			await process_frame
			if int(game.skills[support].xp) > before_support: break
		check(int(game.skills[owner].xp) >= before_primary + 4, "Live completion grants primary XP: " + action_id)
		check(int(game.skills[support].xp) >= before_support + 2, "Live completion grants supporting XP: " + action_id)
		await settle(0.18)
		await capture_responsive("early-link-" + action_id)
		game._action_runtime()._stop_running_action(owner, action_id)
		await settle(0.3)
	print("EARLY_SKILL_LINKS failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
