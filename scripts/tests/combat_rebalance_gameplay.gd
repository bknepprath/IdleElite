extends "res://scripts/tests/first_session_input.gd"
func _run() -> void:
	capture_dir = "res://.codex-tmp/combat-rebalance"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._test_state_runtime()._god_mode_max_skills_state()
	game._test_state_runtime()._god_mode_unlock_actions_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._navigation_shell()._select_skill("fight")
	await settle(1.0)
	for id in ["fight-giants", "fight-dragons"]:
		await game._skill_detail_surface()._scroll_to_activity_card(id, false)
		await settle(1.0)
		var card: Dictionary = game.action_cards[game._action_key("fight", id)]
		var point: Vector2 = card.button.get_global_rect().get_center()
		point.y = clampf(point.y, 470, 1100)
		await click(point, true)
		check(game.running_action_id == id, "Native fight start")
		var stage: Control = card.blue_guy_chicken_stage
		var rewards: Array = []
		stage.chicken_killed.connect(func(amount): rewards.append(amount))
		var reward_captured := false
		for sample in range(100):
			await settle(0.1)
			for label in stage.get("float_labels"):
				check(not label.visible or not (label.text.begins_with("-") or label.text.begins_with("CRIT! -")), "No damage number floats")
			if sample % 10 == 0:
				await capture(id + "-" + str(sample / 10))
			if not reward_captured and not rewards.is_empty() and int(rewards[-1]) > 0:
				await capture("reward-" + id)
				print("LIVE_REWARD ", id, " XP=", rewards[-1])
				reward_captured = true
		if id == "fight-dragons":
			stage.set_process(false)
			stage.set("hero_ko_timer", 0.0)
			stage.set("cover_open_amount", 1.0)
			var actors: Array = stage.get("chickens")
			if actors.is_empty():
				stage.call("_spawn_chicken", 0)
				actors = stage.get("chickens")
			actors[0]["pos"] = stage.call("_clamp_norm_to_arena", Vector2(0.82, 0.30))
			actors[0]["state"] = "idle"
			actors[0]["hp"] = 3000.0
			stage.queue_redraw()
			await capture("dragon-title-overlap")
	print("COMBAT_PRESENTATION failures=", failures)
	game.queue_free()
	await settle(1.0)
	quit(0 if failures.is_empty() else 1)

