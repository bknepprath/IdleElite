extends "res://scripts/tests/first_session_input.gd"

const SkillState = preload("res://scripts/progression/skill_state.gd")

func _run() -> void:
	capture_dir = "res://.codex-tmp/combat-plus-five"
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
	for id in ["fight-cave-trolls", "fight-giants"]:
		var action: Dictionary = game._action_data("fight", id)
		var level := int(action.unlock) + 5
		game.skills["fight"]["xp"] = SkillState.xp_for_level(level)
		SkillState.recalculate_level(game, "fight", false)
		SkillState.invalidate_stat_caches(game)
		game._navigation_shell()._select_skill("fight")
		await settle(1.0)
		await game._skill_detail_surface()._scroll_to_activity_card(id, false)
		await settle(1.0)
		var card: Dictionary = game.action_cards[game._action_key("fight", id)]
		await click(card.button.get_global_rect().get_center(), true)
		check(game.running_action_id == id, "Native encounter start")
		var stage: Control = card.blue_guy_chicken_stage
		check(int(stage.get("fighting_level")) == level, "Actual unlock plus five level")
		var rewards: Array = []
		stage.chicken_killed.connect(func(amount): rewards.append(amount))
		await capture(id + "-start")
		for sample in range(450):
			await settle(0.1)
			if not rewards.is_empty():
				await capture(id + "-reward")
				print("PLUS_FIVE_LIVE ", id, " level=", level, " XP=", rewards[-1])
				break
		check(not rewards.is_empty(), "Kill earned within 45 seconds at plus five")
	print("PLUS_FIVE_GAMEPLAY failures=", failures)
	game.queue_free()
	await settle(1.0)
	quit(0 if failures.is_empty() else 1)
