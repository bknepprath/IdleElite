extends "res://scripts/tests/first_session_input.gd"
const SkillState = preload("res://scripts/progression/skill_state.gd")
func _run() -> void:
	capture_dir = "res://.codex-tmp/tired-float"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._navigation_shell()._select_skill("fight")
	await settle(1.0)
	await game._skill_detail_surface()._scroll_to_activity_card("push-ups", false)
	await settle(1.0)
	var card: Dictionary = game.action_cards[game._action_key("fight", "push-ups")]
	game.stamina["fight"] = 0.0
	SkillState.host_sync_stamina_bank("fight", game)
	await capture("before")
	await click(card.button.get_global_rect().get_center(), true)
	var popup: Control = game.get_node_or_null("ActivityWarningFloat")
	check(popup != null, "Tired activity produces floating feedback")
	if popup != null:
		var initial_y := popup.position.y
		await capture("rising")
		await settle(0.5)
		check(popup.position.y < initial_y, "Tired feedback rises")
		await capture("fading")
	await settle(1.5)
	check(game.get_node_or_null("ActivityWarningFloat") == null, "Tired feedback is removed after fading")
	check(card.pop.get_node_or_null("TiredTrainingStatus") == null, "No permanent tired label")
	await capture("finished")
	print("TIRED_FLOAT_CHECK failures=", failures)
	game.queue_free()
	await settle(1.0)
	quit(0 if failures.is_empty() else 1)
