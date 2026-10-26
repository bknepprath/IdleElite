extends "res://scripts/tests/ham_feedback_capture.gd"

func _run() -> void:
	create_timer(300).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "280")
	capture_dir = "res://outputs/verification/ham-oct21"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.content_scale_size = Vector2i(1080,1920)
	root.size = Vector2i(1080,1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active:
			break
	check(game.startup_initialized, "Real main scene must boot")
	game._audio_director().music_muted = true
	game._audio_director().sfx_muted = true
	game._audio_director()._apply_audio_bus_volumes()
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game.auto_unlock_lockpads_enabled = false
	game._action_runtime().activity_start_count = 10
	for skill in game.skill_defs:
		game.skills[skill.id] = {"xp":SkillState.xp_for_level(99),"level":99}
		for action in game.actions_by_skill[skill.id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(skill.id, str(action.id))
			if MasteryState.action_has_mastery(game, action):
				game.mastery[str(skill.id)+":"+str(action.id)] = {"xp":MasteryState.xp_for_level(3),"level":3}
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game._save_runtime().fishing_help_seen = true
	game._hub_surface().hub_tutorial_tip_seen = true
	SkillState.invalidate_stat_caches(game)
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game,false),game._save_runtime().achievement_toast_seen_ids,[])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(2.0)
	await choose_skill("fight")
	if OS.get_environment("IDLE_ELITE_HAM_CAPTURE_FOCUS") == "diagnostic":
		var diagnostic_detail = game._skill_detail_surface()
		await diagnostic_detail._scroll_to_activity_card("ice-the-bruises",false,true)
		await settle(1.0)
		var diagnostic: Dictionary = game.action_cards["fight:ice-the-bruises"]
		print("portrait-diagnostic art=",diagnostic.art.get_global_rect()," parent=",diagnostic.art.get_parent().get_global_rect()," panel=",diagnostic.art_panel.get_global_rect()," position=",diagnostic.art.position," size=",diagnostic.art.size)
		print("stamina-diagnostic box=",diagnostic.stat_boxes.stamina.get_global_rect()," selected=",game.selected_skill_id," expanded=",diagnostic_detail.expanded_activity_stat_key)
		await capture("recovery-before")
		await hold(diagnostic.stat_boxes.stamina.get_global_rect().get_center())
		print("after-hold expanded=",diagnostic_detail.expanded_activity_stat_key," kind=",diagnostic_detail.expanded_activity_stat_kind)
		await capture_information("recovery-target")
		print("ham-oct21-capture failures=",failures)
		game.queue_free()
		await settle(0.5)
		quit(0 if failures.is_empty() else 1)
		return
	await show_tier(1)
	await capture("tier-1-compact")
	await click(find_tier_hit(1).get_global_rect().get_center())
	await settle(0.5)
	await show_tier(3)
	await capture("tier-3-compact")
	await click(find_tier_hit(3).get_global_rect().get_center())
	await settle(0.6)
	var detail = game._skill_detail_surface()
	await detail._scroll_to_activity_card("kick-mud-off-boot", false, true)
	await settle(0.8)
	var card: Dictionary = game.action_cards.get("fight:kick-mud-off-boot",{})
	check(not card.is_empty(), "Medal activity must be mounted")
	if not card.is_empty():
		await click((card.medal as Control).get_global_rect().get_center())
		await capture_information("medal-compact")
	if OS.get_environment("IDLE_ELITE_HAM_CAPTURE_FOCUS") == "panels":
		print("ham-oct21-capture failures=",failures)
		game.queue_free()
		await settle(0.5)
		quit(0 if failures.is_empty() else 1)
		return
	# All portraits are captured in their production cards, reached from skill UI.
	var portraits := {
		"fight":["catch-breath-between-rounds","shake-out-the-gloves","ice-the-bruises","slow-shadow-boxing"],
		"thieving":["count-the-coins","hide-in-plain-sight","case-the-quiet-corner","lay-low-until-morning","nap-behind-the-market-stall","crack-the-shipwrights-lockbox"],
		"build":["sit-on-the-toolbox","sweep-the-worksite","inspect-the-blueprints-again","measure-twice-again","build-weatherproof-weather"],
		"woodcutting":["lean-on-the-axe","snack-on-trail-mix","oil-the-axe-handle","stretch-the-splinters-out","rest-under-the-stump","fell-tree-that-remembers-you"]}
	for skill_id in portraits:
		await choose_skill(skill_id)
		for action_id in portraits[skill_id]:
			await detail._scroll_to_activity_card(action_id,false,true)
			await settle(0.65)
			var portrait_card: Dictionary = game.action_cards.get(str(skill_id)+":"+str(action_id),{})
			check(not portrait_card.is_empty(), "Portrait must be in production hierarchy: " + str(action_id))
			if not portrait_card.is_empty():
				var rect: Rect2 = portrait_card.root.get_global_rect()
				check(rect.position.y > 250 and rect.position.y < 1450, "Portrait card must be on screen: " + str(action_id))
				check(portrait_card.art_panel.get_global_rect().grow(-10).encloses(portrait_card.art.get_global_rect()), "Portrait draw box must stay inside its frame: " + str(action_id))
			await capture(str(action_id))
	await choose_skill("fight")
	await detail._scroll_to_activity_card("ice-the-bruises",false,true)
	await settle(0.6)
	card = game.action_cards.get("fight:ice-the-bruises",{})
	await hold((card.stat_boxes.stamina as Control).get_global_rect().get_center())
	await capture_information("recovery-target")
	game.fishing_runtime.fish_currency = 999999.0
	await choose_skill("fishing")
	await settle(0.8)
	await capture("fish-count-below-million")
	await choose_skill("fight")
	# Independent timers shown together through the actual Hub/board buttons.
	var hub = game._hub_runtime()
	hub.hub_modules.mission = {"level":4,"building":false}
	hub.hub_missions = [{"skill_id":"fight","action_id":"push-ups","target":50,"remaining":20,"rep_balance_version":1},{"skill_id":"build","action_id":"hammer-nails","target":50,"remaining":30,"rep_balance_version":1}]
	hub.hub_mission_cooldowns = [game._unix_now()+60,game._unix_now()+110]
	hub._sync_mission_cooldown_summary()
	await click(game._navigation_shell().hub_tab.get_global_rect().get_center())
	await settle(1.0)
	await click((game._hub_surface().hub_module_art.mission as Control).get_global_rect().get_center())
	await settle(0.8)
	await capture("independent-mission-timers")
	check(game._hub_surface().hub_detail_open,"Board must open through its real UI")
	print("ham-oct21-capture failures=",failures)
	game.queue_free()
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)

func choose_skill(skill_id: String) -> void:
	print("choose-skill ",skill_id," from ",game.current_screen,":",game.selected_skill_id)
	if game.current_screen == "skill" and game.selected_skill_id == skill_id:
		return
	if game.current_screen != "menu":
		await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center())
		await settle(1.2)
		if game.current_screen != "menu":
			await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center())
			await settle(1.2)
	check(game.current_screen == "menu","Skills menu must be reached through UI")
	game.content_scroll.scroll_vertical = 0
	await settle(0.3)
	var button: Control = game.skill_cards[skill_id].button
	var rect := button.get_global_rect()
	if rect.end.y > 1500:
		game.content_scroll.scroll_vertical += ceili(rect.end.y - 1450)
		await settle(0.4)
	await click(button.get_global_rect().get_center(),true)
	await settle(1.0)
	check(game.current_screen == "skill" and game.selected_skill_id == skill_id, "Skill selection must work: " + skill_id)

func find_tier_hit(tier: int) -> Control:
	for button in game.find_children("*","Button",true,false):
		if button.has_meta("tier_banner_plaque_hit") and button.is_visible_in_tree():
			var plaque = button.get_parent().get_child(0)
			if int(plaque.get("tier")) == tier:
				return button
	return null

func show_tier(tier: int) -> void:
	var detail = game._skill_detail_surface()
	for entry in detail.detail_lazy_plan:
		if str(entry.get("kind","")) == "tier_banner" and int(entry.get("entry",{}).get("tier",0)) == tier:
			detail._ensure_detail_lazy_entry_mounted(str(entry.get("track_id","")))
			await settle(0.3)
			var stack: Control = entry.get("stack_host")
			detail.detail_actions_scroll.scroll_vertical += roundi(stack.get_global_rect().position.y-420)
			detail.detail_actions_scroll.set("drag_scroll_position",float(detail.detail_actions_scroll.scroll_vertical))
			await settle(0.6)
			break
	var hit := find_tier_hit(tier)
	check(hit != null,"Tier must be mounted: %s" % tier)
	if hit == null:
		return
	await click(hit.get_global_rect().get_center())
	await settle(1.0)
	hit = find_tier_hit(tier)
	check(detail.expanded_tier_banner_key == "fight:%s" % tier or not detail.expanded_tier_banner_key.is_empty(),"Tier must expand through a click")
	if hit != null:
		detail.detail_actions_scroll.scroll_vertical += roundi(hit.get_global_rect().position.y-390)
		await settle(0.5)
