extends "res://scripts/tests/first_session_input.gd"

func _run() -> void:
	capture_dir = "res://.codex-tmp/audit-fixes"
	game = load("res://scenes/main.tscn").instantiate()
	game._app_lifecycle_runtime()._save_for_app_suspend()
	check(game.get_node_or_null("AudioDirector") == null and game.get_node_or_null("ActionStopHoldLayer") == null, "Early focus loss must not create children during scene setup")
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
	await game._skill_detail_surface()._scroll_to_activity_card("fight-dragons", false)
	await settle(1.0)
	var card: Dictionary = game.action_cards[game._action_key("fight", "fight-dragons")]
	var point: Vector2 = card.button.get_global_rect().get_center()
	point.y = clampf(point.y, 460, 1100)
	await click(point, true)
	await settle(3.0)
	check(game.running_action_id == "fight-dragons", "Native dragon start")
	var stage: Control = card.blue_guy_chicken_stage
	stage.set("hero_hp", 0.0)
	stage.call("setup_fighting_level", 99)
	check(float(stage.get("hero_hp")) == 0.0, "Stat refresh must not revive a defeated hero")
	await settle(1.0)
	check(float(stage.get("hero_ko_timer")) > 0.0, "Zero HP must enter knockout recovery")
	await capture("knockout-recovery")
	await settle(4.0)
	check(float(stage.get("hero_hp")) > 0.0, "Knockout must restore HP and restart automatically")
	await capture("knockout-restarted")
	game.queue_free()
	await settle(1.0)
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "Knockout test must release scene controls")
	print("KNOCKOUT_CHECK failures=", failures)
	quit(0 if failures.is_empty() else 1)
