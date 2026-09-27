extends "res://scripts/tests/first_session_input.gd"
const SkillState = preload("res://scripts/progression/skill_state.gd")

func _run() -> void:
	capture_dir = "res://.codex-tmp/audit-fixes"
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for i in range(1200):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._test_state_runtime()._god_mode_max_skills_state()
	game._test_state_runtime()._god_mode_unlock_actions_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._navigation_shell()._select_skill("fight")
	await settle(2.0)
	var info = get_nodes_in_group("skill_header_info_buttons")
	for b in info:
		if b.is_visible_in_tree():
			await click(b.get_global_rect().get_center(), true)
			await capture("combat-help")
			await click(b.get_global_rect().get_center(), true)
			break
	await game._skill_detail_surface()._scroll_to_activity_card("push-ups", false)
	await settle(1.0)
	var training: Dictionary = game.action_cards.get(game._action_key("fight", "push-ups"), {})
	print("TRAINING_FOUND ", not training.is_empty())
	if not training.is_empty():
		await click(training.button.get_global_rect().get_center(), true)
		game.stamina["fight"] = 0.0
		SkillState.host_sync_stamina_bank("fight", game)
		await settle(2.0)
		await capture("tired-training")
		check(training.pop.get_node_or_null("TiredTrainingStatus") == null, "Tired feedback must not create a permanent card label")
	for action_id in ["fight-chickens", "fight-giants", "fight-dragons"]:
		await game._skill_detail_surface()._scroll_to_activity_card(action_id, false)
		await settle(1.0)
		var card: Dictionary = game.action_cards.get(game._action_key("fight", action_id), {})
		check(not card.is_empty(), "Combat card must mount: " + action_id)
		if card.is_empty(): continue
		var point: Vector2 = card.button.get_global_rect().get_center()
		point.y = clampf(point.y, 460, 1100)
		await click(point, true)
		await settle(2.0)
		check(game.running_action_id == action_id, "Native combat start: " + action_id)
		for n in range(3):
			await settle(4.0)
			await capture(action_id + "-" + str(n))
		if action_id in ["fight-giants", "fight-dragons"]:
			await capture_edge_animation(card.get("blue_guy_chicken_stage"), action_id)
	var recovery_card: Dictionary = game.action_cards.get(game._action_key("fight", "fight-dragons"), {})
	if not recovery_card.is_empty():
		var recovery_stage: Control = recovery_card.blue_guy_chicken_stage
		recovery_stage.set("hero_hp", 0.0)
		await settle(1.0)
		await capture("knockout-recovery")
		await settle(4.0)
		await capture("knockout-restarted")
	game._navigation_shell()._select_skill("woodcutting")
	await settle(2.0)
	await game._skill_detail_surface()._scroll_to_activity_card("gather-fallen-branches", false)
	await settle(1.0)
	var wood: Dictionary = game.action_cards.get(game._action_key("woodcutting", "gather-fallen-branches"), {})
	if not wood.is_empty():
		await click(wood.button.get_global_rect().get_center(), true)
	game.material_runtime.set_amount("scrapwood", 10.0)
	await game._skill_detail_surface()._scroll_to_activity_card("firepit", false)
	await settle(1.0)
	for key in game.action_cards:
		var card: Dictionary = game.action_cards[key]
		if card.get("firepit", false):
			await click(card.toggle.get_global_rect().get_center(), true)
			await settle(2.0)
			await game._skill_detail_surface()._restore_detail_actions_scroll(maxi(0, game._skill_detail_surface().detail_actions_scroll.scroll_vertical - 260))
			await settle(0.5)
			await capture("shared-scrapwood")
			break
	var clip = game._skill_detail_surface().detail_actions_scroll.get_parent()
	var nav = clip.get_node_or_null("PageSwitchModule")
	check(nav != null, "Navigation must be outside the scroll list")
	if nav != null:
		var before: Vector2 = nav.global_position
		await game._skill_detail_surface()._scroll_to_activity_card("gather-fallen-branches", false)
		await settle(1.0)
		check(nav.global_position.distance_to(before) < 1.0, "Navigation must stay fixed while scrolling")
		await capture("fixed-navigation")
		await switch_page("fishing")
		await switch_page("fight")
		check(game.selected_skill_id == "fight", "Native fixed navigation must return to Fighting")
	print("AUDIT_FIXES failures=", failures)
	game.queue_free()
	await settle(1.0)
	print("ORPHANS_AFTER_SHUTDOWN")
	Node.print_orphan_nodes()
	check(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT) == 0, "Shutdown must release all card controls")
	quit(0 if failures.is_empty() else 1)


func switch_page(target: String) -> void:
	for button in get_nodes_in_group("page_switch_buttons"):
		if button.is_visible_in_tree() and str(button.get_meta("page_switch_owner_skill_id", "")) == game.selected_skill_id and str(button.get_meta("page_switch_target_skill_id", "")) == target:
			await click(button.get_global_rect().get_center(), true)
			await settle(2.0)
			check(game.selected_skill_id == target, "Native page switch must reach " + target)
			return
	check(false, "Missing page switch to " + target)


func capture_edge_animation(stage: Control, action_id: String) -> void:
	if not is_instance_valid(stage): return
	var enemies: Array = stage.get("chickens")
	if enemies.is_empty(): return
	# Deterministic edge poses of the existing production actor after native combat.
	stage.set_process(false)
	stage.set("hero_ko_timer", 0.0)
	var enemy: Dictionary = enemies[0].duplicate(true)
	enemies.clear()
	enemies.append(enemy)
	enemy["pos"] = Vector2(0.58, 0.78) if action_id == "fight-giants" else Vector2(0.50, 0.18)
	enemy["render_pos"] = enemy["pos"]
	enemy["hit_flash"] = 0.0
	enemy["uppercut_knock_timer"] = 0.0
	enemy["uppercut_pop"] = 0.0
	enemy["ko_retreat_alpha"] = 1.0
	for index in range(3):
		if action_id == "fight-giants":
			enemy["hp"] = 1.0 if index == 0 else 0.0
			enemy["dead_timer"] = [0.0, 0.22, 0.70][index]
		else:
			enemy["hp"] = enemy.get("max_hp", 100)
			enemy["attack_phase"] = ["windup", "strike", "recover"][index]
			enemy["dragon_attack_kind"] = "pounce"
			enemy["signature_t"] = 0.7
		stage.queue_redraw()
		await process_frame
		await capture(action_id + "-edge-" + str(index))
	stage.set_process(true)

