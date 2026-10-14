extends "res://scripts/tests/first_session_input.gd"
const SkillState = preload("res://scripts/progression/skill_state.gd")
func _run() -> void:
	capture_dir = "res://.codex-tmp/six-minute-audit"
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
	for action_id in ["fight-chickens"]:
		await game._skill_detail_surface()._scroll_to_activity_card(action_id, false)
		await settle(1.0)
		var card: Dictionary = game.action_cards.get(game._action_key("fight",action_id),{})
		check(not card.is_empty(), "Combat card must mount: " + action_id)
		if card.is_empty():
			continue
		await capture(action_id+"-idle")
		var button: Control = card.get("button")
		check(button != null, "Combat start button must exist")
		if button == null:
			continue
		var point := button.get_global_rect().get_center()
		point.y = clampf(point.y, 450, 1250)
		await click(point, true)
		await settle(1.0)
		check(game.running_action_id == action_id, "Native combat start failed: " + action_id)
		var stage: Control = card.get("blue_guy_chicken_stage")
		var xp_before := int(game.skills.fight.xp)
		for sample in range(1):
			await settle(10.0)
			await capture(action_id+"-sample-"+str(sample))
			print("COMBAT ",action_id," sample=",sample," xp_delta=",int(game.skills.fight.xp)-xp_before," active=",stage.get("active")," hp=",stage.get("hero_hp")," wave=",stage.get("wave_index")," enemies=",(stage.get("chickens") as Array).size())
		check(int(game.skills.fight.xp)>xp_before,"Combat must award XP: "+action_id)
		if action_id == "fight-chickens":
			var hidden_xp := int(game.skills.fight.xp)
			var switched := false
			for nav in get_nodes_in_group("page_switch_buttons"):
				if nav.is_visible_in_tree() and str(nav.get_meta("page_switch_owner_skill_id", "")) == "fight" and str(nav.get_meta("page_switch_target_skill_id", "")) == "thieving":
					await click(nav.get_global_rect().get_center(), true)
					switched = true
					break
			check(switched, "Fixed page navigation must accept a native touch")
			await settle(15.0)
			print("COMBAT_HIDDEN xp_delta=", int(game.skills.fight.xp)-hidden_xp, " running=",game.running_action_id)
			check(int(game.skills.fight.xp)>hidden_xp,"Combat must keep progressing after leaving the skill page")
			game._navigation_shell()._select_skill("fight")
			await settle(2.0)
			await game._skill_detail_surface()._scroll_to_activity_card(action_id, false)
			await settle(1.0)
			var resumed: Dictionary = game.action_cards.get(game._action_key("fight",action_id),{})
			check(resumed.get("blue_guy_chicken_stage") == stage,"Returning must reuse the running battle")
			var active_stages := 0
			for node in game.find_children("*", "Control", true, false):
				if node.get_script() == stage.get_script() and bool(node.get("active")):
					active_stages += 1
			check(active_stages == 1,"Only one combat simulation may award rewards")
			game._navigation_shell()._select_skill("woodcutting")
			await settle(2.0)
			await game._skill_detail_surface()._scroll_to_activity_card("gather-fallen-branches", false)
			await settle(1.0)
			var wood_card: Dictionary = game.action_cards[game._action_key("woodcutting","gather-fallen-branches")]
			await click(wood_card.button.get_global_rect().get_center(),true)
			await settle(1.0)
			check(game.running_skill_id == "woodcutting","New activity must replace combat")
			var stopped_xp := int(game.skills.fight.xp)
			await settle(10.0)
			check(int(game.skills.fight.xp)==stopped_xp,"Stopped background fight must not award XP")
	print("ENDGAME failures=",failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)
