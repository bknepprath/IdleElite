extends "res://scripts/tests/full_width_barriers.gd"

func _run() -> void:
	print("HALLOWEEN_START")
	create_timer(160).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "150")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.position = Vector2i.ZERO
	root.size = Vector2i(1920, 1080)
	print("HALLOWEEN_LOAD")
	game = load("res://scenes/main.tscn").instantiate()
	print("HALLOWEEN_ADD")
	root.add_child(game)
	print("HALLOWEEN_ADDED")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for frame in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	print("HALLOWEEN_BOOTED")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._save_runtime().fishing_help_seen = true
	game.auto_unlock_lockpads_enabled = false
	game.running_skill_id = ""
	game.running_action_id = ""
	game.fishing_runtime.fish_currency_ever_earned = true
	game.fishing_runtime.fish_currency = 20.0
	var locks = game._activity_unlock_runtime()
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(8)
		game.skills[skill].level = 8
		for action in game.actions_by_skill[skill]:
			if int(action.unlock) <= 8 and str(action.id) != "trick-or-treat": locks._mark_action_manually_unlocked(skill, str(action.id))
	var event: Dictionary = game._action_data("thieving", "trick-or-treat")
	var projects = game._project_runtime()
	var candy = game._halloween_runtime()
	check(not event.is_empty(), "Seasonal activity loads at Thieving 8")
	projects.work["halloween-2026-doorstep"] = {}
	locks.manual_activity_unlocks.erase("thieving:trick-or-treat")
	game.selected_skill_id = "thieving"
	game.desktop_layout.rotate_slots("thieving")
	await game._navigation_shell()._render_screen()
	await wait_layout()
	var panel = await show_project("thieving", "halloween-2026-doorstep")
	check(is_instance_valid(panel), "Construction blocker appears in real skill page")
	await capture_responsive("halloween-construction")
	projects.refresh_availability()
	for step in event.unlock_project.steps:
		check(projects.needed_resources.has(str(step.resource)), "Relevant seasonal resource visible: " + str(step.resource))
		var source: Dictionary = projects.best_source(str(step.resource))
		check(not source.is_empty(), "Requirement links to an unlocked low-level source")
		projects.record_success(str(step.source_skill), str(step.source_action), int(step.target))
	check(projects.complete(event), "Three source activities complete doorstep")
	projects.refresh_availability()
	check(not projects.needed_resources.has("halloween-webs"), "Seasonal drops stop when complete")
	locks._mark_action_manually_unlocked("thieving", "trick-or-treat")
	await game._skill_detail_surface()._refresh_visible_skill_detail_action_list(-1, "thieving")
	await wait_layout()
	game._skill_detail_surface()._scroll_to_activity_card("trick-or-treat", true, true)
	await settle(0.6)
	await capture_responsive("halloween-before-candy")
	candy.record_success("thieving", "trick-or-treat")
	await settle(0.12)
	await capture_responsive("halloween-candy-reveal")
	await settle(0.3)
	check(candy.candy == 1, "Successful trick or treat earns one candy")
	candy.candy = 200
	candy.changed.emit()
	SkillState.invalidate_max_stamina_cache()
	var cap := float(SkillState.max_stamina(game, "thieving"))
	var max_stamina := Callable(SkillState, "host_max_stamina").bind(game)
	game.stamina.thieving = cap
	var toggle: Control
	for button in get_nodes_in_group("auto_eat_candy_toggle"):
		if button.skill_id == "thieving" and button.is_visible_in_tree(): toggle = button; break
	check(is_instance_valid(toggle), "Candy toggle visible beside fish")
	if is_instance_valid(toggle):
		print("CANDY_CLICK ", toggle.get_global_rect(), " disabled=", toggle.disabled)
		await click(toggle.get_global_rect().get_center())
	print("CANDY_AFTER_CLICK ", candy.for_save(), " stamina=", game.stamina.thieving)
	var away := InputEventMouseMotion.new()
	away.position = Vector2(300, 400)
	away.global_position = away.position
	root.push_input(away, true)
	check(candy.auto_by_skill.get("thieving", false), "Actual UI click enables per-skill auto candy")
	var after := SkillState.host_stamina_value("thieving", game)
	check(after >= cap + 10 and after <= cap + 15, "Full stamina can exceed cap by one random piece")
	var left: int = candy.candy
	check(candy.eat("thieving") == 0 and candy.candy == left, "Second piece rejected while overfull")
	var payload: Dictionary = game._save_runtime()._save_payload(game._unix_now())
	check(payload.stamina.thieving == after and payload.halloween_2026.candy == left, "Save preserves excess and inventory together")
	game._save_runtime()._load_game_core(payload)
	check(SkillState.host_stamina_value("thieving", game) == after, "Loading preserves excess stamina")
	check(candy.candy == left and candy.auto_by_skill.get("thieving", false), "Loading preserves candy and toggle")
	game._action_runtime()._apply_stamina_regen_seconds_except(30, false, "")
	check(SkillState.host_stamina_value("thieving", game) == after, "Regeneration neither removes nor adds excess")
	game._update_ui(0.0, true)
	await settle(0.5)
	await capture_responsive("halloween-overfull")
	var gauge = game._reward_feedback_surface()._visible_stamina_gauge_for_skill("thieving", null)
	check(gauge != null and gauge.candy_overfilled, "Excess uses ImageGen spiral fill")
	SkillState.restore_action_stamina(game.stamina, game.stamina_bank, "thieving", 5, max_stamina)
	check(SkillState.host_stamina_value("thieving", game) == after, "Rest reward preserves candy excess")
	candy.auto_by_skill.clear()
	candy.changed.emit()
	SkillState.spend_action_stamina(game.stamina, game.stamina_bank, "thieving", after - cap, max_stamina)
	game._update_ui(0.0, true)
	await settle(0.5)
	check(not gauge.candy_overfilled, "Normal fill returns exactly at maximum")
	await capture_responsive("halloween-normal")
	candy.random.seed = 12345
	var outcomes := {}
	for i in range(100):
		game.stamina.thieving = cap
		var reward: int = candy.eat("thieving", false)
		check(reward >= 10 and reward <= 15, "Candy random roll remains within inclusive range")
		outcomes[reward] = true
	check(outcomes.size() == 6, "All six restore outcomes observed")
	candy.enabled = false
	var before: int = candy.candy
	candy.record_success("thieving", "trick-or-treat")
	check(candy.candy == before, "Ended event produces no candy")
	game.stamina.thieving = cap
	check(candy.eat("thieving", false) >= 10, "Leftover candy remains edible after event")
	candy.enabled = true
	root.size = Vector2i(1080, 1920)
	await game._navigation_shell()._render_screen()
	await wait_layout()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._skill_detail_surface()._scroll_to_activity_card("trick-or-treat", true, true)
	await settle(0.6)
	await capture_responsive("halloween-portrait")
	await settle(0.35)
	await capture_responsive("halloween-spider-moving")
	await settle(0.7)
	await capture_responsive("halloween-spider-later")
	# Exercise production reward paths, priority, and offline spending.
	candy.auto_by_skill = {"thieving": true}
	candy.candy = 4
	game.stamina.thieving = 0.0
	game.fishing_runtime.set_auto_eat_fish_enabled_for_skill(game, "thieving", true)
	var fish_before: float = game.fishing_runtime.fish_currency
	game._action_runtime()._auto_eat_fish_for_action("thieving", 1.0)
	check(candy.candy == 3 and game.fishing_runtime.fish_currency == fish_before, "Candy takes priority over fish without double spending")
	candy.auto_by_skill.clear()
	game.running_skill_id = "thieving"
	game.running_action_id = "trick-or-treat"
	game.action_progress = 0.0
	game.stamina.thieving = cap + 15.0
	game._action_runtime().guaranteed_success_action_completions = 5
	var earned_before: int = candy.candy
	game._action_runtime()._process_action(12.0)
	check(candy.candy > earned_before, "Actual activity completion awards candy")
	game.action_progress = 0.0
	game.stamina.thieving = cap + 15.0
	var offline_before: int = candy.candy
	game._action_runtime()._apply_offline_active_action(30.0)
	check(candy.candy > offline_before, "Offline successful completions award candy")
	check(SkillState.host_stamina_value("thieving", game) < cap + 15.0, "Offline actions spend excess stamina")
	game.running_skill_id = ""
	game.running_action_id = ""
	check(not preload("res://scripts/progression/mastery_state.gd").action_has_mastery(game, event), "Seasonal activity does not change permanent medal requirements")
	# Simulate the next build with the event absent. Historical keys remain safe.
	var before_retirement: Dictionary = game._save_runtime()._save_payload(game._unix_now())
	game.actions_by_skill.thieving.erase(event)
	game.actions_by_key.erase("thieving:trick-or-treat")
	projects.configure()
	game._save_runtime()._load_game_core(before_retirement)
	var after_retirement: Dictionary = game._save_runtime()._save_payload(game._unix_now())
	check(not game._save_runtime()._save_payload_regresses_progress(before_retirement, after_retirement), "Removing seasonal activity preserves save progress")
	check(game._action_data("thieving", "trick-or-treat").is_empty(), "Retired activity is absent")
	candy.restore({"candy": "invalid", "auto_by_skill": ["fight"]})
	check(candy.candy == 0 and candy.auto_by_skill.is_empty(), "Malformed seasonal save fails safely")
	print("HALLOWEEN_TEST failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
