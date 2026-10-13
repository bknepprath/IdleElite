extends "res://scripts/tests/detail_refresh_stability.gd"

const ThievingState = preload("res://scripts/thieving/state.gd")

func _run() -> void:
	create_timer(170).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/thieving-trophy-sequence"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game.skills.thieving.level = 99
	game.skills.thieving.xp = SkillState.xp_for_level(99)
	if OS.get_environment("IDLE_ELITE_TEST_ALL_THIEVING_ACTIVITIES") == "1":
		for action in game.actions_by_skill.thieving:
			game._activity_unlock_runtime()._mark_action_manually_unlocked("thieving", action.id)
	game._action_runtime().activity_start_count = 10
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.0)
	var button: Control = game.skill_cards.thieving.button
	game.content_scroll.scroll_vertical += int(button.get_global_rect().get_center().y - 850)
	await settle(0.4)
	await click(button.get_global_rect().get_center(), true)
	await settle(2.0)
	var detail = game._skill_detail_surface()
	var initial_stack: int = detail._detail_actions_stack().get_instance_id()
	for trophy_index in range(ThievingState.HEIST_DEFS.size()):
		var heist: Dictionary = ThievingState.HEIST_DEFS[trophy_index]
		var key := "thieving_heist:" + str(heist.id)
		if trophy_index == 0:
			await detail._scroll_to_activity_card("heist:" + str(heist.id), false, true)
			await settle(0.8)
		check(game.action_cards.has(key), "Trophy available without revisiting: " + str(heist.id))
		if not game.action_cards.has(key):
			break
		await detail._scroll_to_activity_card("heist:" + str(heist.id), false, true)
		await settle(0.8)
		await capture("trophy-%s-before" % trophy_index)
		for attempt in range(5):
			# Fixture retries exercise ordinary failure/jail cleanup as well as success.
			game.thieving_state.ensure_trophy_state(heist.id)["cooldown_until_unix"] = 0
			game._update_ui(0.0, true)
			await settle(0.2)
			seed(1234 + attempt)
			await click(game.action_cards[key].button.get_global_rect().get_center())
			if game.thieving_state.trophy_stolen(heist.id):
				break
		check(game.thieving_state.trophy_stolen(heist.id), "Trophy successfully collected: " + str(heist.id))
		var visible: Array = game.thieving_state.visible_heists_for_render()
		check(visible.size() == 1 and visible[0].id == heist.id, "Next trophy waits for current reward to finish")
		for frame in range(800):
			await settle(0.01)
			if game.thieving_state.pending_trophy_reward_float.is_empty():
				if trophy_index == 3 or game.action_cards.has("thieving_heist:" + str(ThievingState.HEIST_DEFS[trophy_index + 1].id)):
					if trophy_index < 3:
						var next_card: Dictionary = game.action_cards["thieving_heist:" + str(ThievingState.HEIST_DEFS[trophy_index + 1].id)]
						check(next_card.pop.modulate.a < 1.0, "Next trophy starts with a fade")
					await settle(0.2)
					await capture("trophy-%s-transition" % trophy_index)
					break
		await settle(1.2)
		await capture("trophy-%s-settled" % trophy_index)
		check(game.thieving_state.pending_trophy_reward_float.is_empty(), "Reward sequence finishes: " + str(heist.id))
		check(detail._detail_actions_stack().get_instance_id() == initial_stack, "Trophy progression preserves the page")
		_check_list_order(detail, "trophy " + str(heist.id))
		for entry in detail.detail_lazy_plan:
			check(entry.track_id != "heist:" + str(heist.id), "Completed trophy removed from lazy plan")
		if not failures.is_empty():
			break
	print("thieving-trophy-sequence failures=", failures)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
