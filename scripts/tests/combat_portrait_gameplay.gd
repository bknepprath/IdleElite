extends "res://scripts/tests/first_session_input.gd"

func _run() -> void:
	capture_dir = "res://.codex-tmp/combat-portraits"
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
	await settle(2.0)
	for action_id in ["fight-chickens", "fight-goblins", "fight-r.o.u.s.es", "fight-guys", "fight-werewolves", "fight-cave-trolls", "fight-giants", "fight-vampires", "fight-dragons"]:
		await game._skill_detail_surface()._scroll_to_activity_card(action_id, false)
		await settle(1.0)
		var card: Dictionary = game.action_cards.get(game._action_key("fight", action_id), {})
		check(not card.is_empty(), "Portrait card mounted: " + action_id)
		if not card.is_empty():
			check(card.blue_guy_chicken_stage.get("cover_clean_chicken") != null, "Portrait texture loaded: " + action_id)
		await capture(action_id)
	var card: Dictionary = game.action_cards[game._action_key("fight", "fight-dragons")]
	var point: Vector2 = card.button.get_global_rect().get_center()
	point.y = clampf(point.y, 460, 1100)
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.position = point
		event.index = 0
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle(0.04)
	await capture("dragon-opening")
	await settle(3.0)
	check(game.running_action_id == "fight-dragons", "Portrait retains native combat start")
	await capture("dragon-active")
	game.queue_free()
	await settle(1.0)
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "Portrait run releases scene")
	print("PORTRAIT_CHECK failures=", failures)
	quit(0 if failures.is_empty() else 1)
