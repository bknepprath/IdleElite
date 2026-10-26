extends "res://scripts/tests/ham_feedback_capture.gd"

func visible_info_button() -> Button:
	for b in get_nodes_in_group("skill_header_info_buttons"):
		if b.is_visible_in_tree() and b.get_global_rect().intersects(Rect2(0,0,1080,1920)):
			return b
	return null

func _run() -> void:
	create_timer(160).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/mission-board-review"
	DirAccess.make_dir_recursive_absolute(capture_dir)
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
	for id in ["fight", "build", "woodcutting", "fishing", "thieving"]:
		game.skills[id].xp = SkillState.xp_for_level(40)
		game.skills[id].level = 40
		for action in game.actions_by_skill[id]:
			game._activity_unlock_runtime()._mark_action_manually_unlocked(id, str(action.id))
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game._save_runtime().fishing_help_seen = true
	game.material_runtime.set_amount("berries", 100)
	game.material_runtime.set_amount("softwood", 500)
	game.material_runtime.set_amount("hardwood", 500)
	game._hub_runtime().hub_modules.woodcutting_totem = {"level":1,"building":false}
	game._hub_runtime().hub_modules.fighting_display = {"level":1,"building":false}
	game.mastery["build:sit-on-the-toolbox"] = {"xp":MasteryState.xp_for_level(3),"level":3}
	game._hub_surface().hub_tutorial_tip_seen = true
	AchievementState.mark_completed_seen_ids(AchievementState.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	game._achievement_toast_surface().achievement_toast_queue.clear()
	game._achievement_toast_surface().achievement_toast_queue_ids.clear()
	for toast in game._achievement_toast_surface().achievement_toasts:
		if is_instance_valid(toast):
			toast.queue_free()
	game._achievement_toast_surface().achievement_toasts.clear()
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.5)
	game.content_scroll.scroll_vertical = 700
	await settle(0.5)
	await click(game._navigation_shell().hub_tab.get_global_rect().get_center())
	await settle(1.0)
	check(game.current_screen == "hub", "Hub reached through navigation")
	var hub = game._hub_surface()
	var runtime = game._hub_runtime()
	for level in [0, 1, 2, 3, 4]:
		runtime.hub_modules.mission = {"level":level,"building":false}
		runtime.hub_missions.clear()
		runtime.hub_mission_cooldowns.clear()
		runtime.hub_mission_cooldown_until_unix = 0
		runtime.sync_missions()
		hub._refresh_hub_module_art("mission")
		await click((hub.hub_module_art.mission as Control).get_global_rect().get_center())
		await settle(0.8)
		check(hub.hub_detail_open, "Board opens at level %s" % level)
		check(hub.hub_detail_panel.find_children("*", "ScrollContainer", true, false).is_empty(), "No inner scrolling")
		await click(hub.hub_mission_view_buttons[0].get_global_rect().get_center())
		await settle(0.3)
		check(not hub.hub_mission_upgrade_view, "Missions tab selected")
		check(hub.hub_detail_missions_box.get_child_count() == level, "All unlocked slots shown")
		check(not hub.hub_detail_button.visible, "Purchase only on Upgrade view")
		for card in hub.hub_detail_missions_box.get_children():
			check(card.get_global_rect().end.y < hub.hub_detail_panel.global_position.y + 920, "Slot fits wood sign at level %s" % level)
		await capture("missions-lv-%s" % level)
		await click(hub.hub_mission_view_buttons[1].get_global_rect().get_center(), true)
		await settle(0.3)
		check(hub.hub_mission_upgrade_view, "Touch selects Upgrade")
		check(hub.hub_detail_button.visible, "Purchase visible with comparison")
		check(hub.hub_detail_button.disabled if level == 4 else true, "Max level cannot purchase")
		await capture("upgrade-lv-%s" % level)
		await click(Vector2(540,1550))
		await settle(0.5)
		check(not hub.hub_detail_open, "Outside tap dismisses board")
	# Cooldown state updates without leaving the selected view.
	runtime.hub_modules.mission = {"level":1,"building":false}
	runtime.hub_missions.clear()
	runtime.hub_mission_cooldowns.clear()
	runtime.hub_mission_cooldown_until_unix = game._unix_now() + 120
	hub._refresh_hub_module_art("mission")
	await click((hub.hub_module_art.mission as Control).get_global_rect().get_center())
	await settle(0.8)
	await capture("mission-cooldown")
	await click(hub.hub_mission_view_buttons[1].get_global_rect().get_center())
	await settle(1.2)
	check(hub.hub_mission_upgrade_view, "Cooldown refresh keeps Upgrade selected")
	await click(hub.hub_mission_view_buttons[0].get_global_rect().get_center())
	runtime.hub_mission_cooldowns.clear()
	runtime.hub_mission_cooldown_until_unix = 0
	runtime.sync_missions()
	hub._update_hub_detail_panel()
	await settle(0.4)
	var mission: Dictionary = runtime.hub_missions[0].duplicate()
	await click(hub.hub_detail_missions_box.get_child(0).get_global_rect().get_center())
	await settle(1.0)
	check(game.current_screen == "skill" and game.selected_skill_id == mission.skill_id, "Mission click reaches its skill")
	check(game.action_cards.has(str(mission.skill_id) + ":" + str(mission.action_id)), "Mission target activity mounted")
	print("mission-board-ui failures=", failures)
	# Let the destination's staged card construction finish before teardown.
	await settle(3.0)
	game.queue_free()
	await process_frame
	await settle(0.5)
	quit(0 if failures.is_empty() else 1)
