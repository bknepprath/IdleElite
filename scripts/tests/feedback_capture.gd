extends "res://scripts/tests/first_session_input.gd"
const SkillState = preload("res://scripts/progression/skill_state.gd")

func visible_info_button() -> Button:
	for b in get_nodes_in_group("skill_header_info_buttons"):
		if b.is_visible_in_tree() and b.get_global_rect().intersects(Rect2(0,0,1080,1920)):
			return b
	return null

func _run() -> void:
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/feedback-captures"
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = Vector2i(540,960)
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
	for pair in [["fishing",2],["thieving",20],["build",10]]:
		game.skills[pair[0]].xp = SkillState.xp_for_level(pair[1])
		game.skills[pair[0]].level = pair[1]
	game._activity_unlock_runtime()._mark_action_manually_unlocked("fishing","practice-pool")
	game._activity_unlock_runtime()._mark_action_manually_unlocked("thieving","count-the-coins")
	game._test_state_runtime()._clear_activity_unlock_ceremony_test_state()
	game._hub_runtime().hub_modules.mission = {"level":1,"building":false}
	game._hub_runtime().restore_missions([{"skill_id":"thieving","action_id":"count-the-coins","target":133,"remaining":133}])
	game._save_runtime().fishing_help_seen = false
	game.current_screen = "menu"
	game._navigation_shell()._render_screen()
	await settle(1.5)
	game.content_scroll.scroll_vertical = 700
	await settle(0.6)
	var menu_button: Button = game.skill_cards.fishing.button
	await click(menu_button.get_global_rect().get_center())
	await settle(2.0)
	check(game.current_screen == "skill" and game.selected_skill_id == "fishing", "Menu click must reach Fishing")
	var info := visible_info_button()
	check(info != null, "Fishing header info must exist")
	var popover: Control = info.get_meta("info_popover") if info != null else null
	check(game._save_runtime().fishing_help_seen and popover != null and popover.visible, "First Fishing visit must automatically show help")
	await settle(0.6)
	check(popover != null and popover.visible, "Fishing help must open")
	await capture("fishing-help")
	if info != null:
		await click(info.get_global_rect().get_center())
	await game._skill_detail_surface()._scroll_to_activity_card("practice-pool", false, true)
	await settle(1.0)
	var card: Dictionary = game.action_cards.get("fishing:practice-pool", {})
	check(not card.is_empty(), "Practice Pool must be in production Fishing page")
	if not card.is_empty():
		await click((card.button as Control).get_global_rect().get_center())
		await settle(0.6)
		check(game.running_action_id == "practice-pool", "Real Practice Pool button must start activity")
		await capture("practice-pool")
	# Follow the real production page-switch controls to the recovery mission.
	game.running_skill_id = ""
	game.running_action_id = ""
	for target_skill in ["fight", "thieving"]:
		var target_button: Button = null
		for b in get_nodes_in_group("page_switch_buttons"):
			if b.is_visible_in_tree() and str(b.get_meta("page_switch_target_skill_id", "")) == target_skill:
				target_button = b
				break
		check(target_button != null, "Missing page-switch control: " + target_skill)
		if target_button != null:
			await click(target_button.get_global_rect().get_center())
			await settle(1.5)
		check(game.selected_skill_id == target_skill, "Page switch must reach " + target_skill)
	await game._skill_detail_surface()._scroll_to_activity_card("count-the-coins", false, true)
	await settle(1.0)
	var recovery_card: Dictionary = game.action_cards.get("thieving:count-the-coins", {})
	check(not recovery_card.is_empty(), "Recovery task must be mounted")
	if not recovery_card.is_empty():
		check(str(recovery_card.mission_badge_label.text) == "34", "133 repetitions must display 34 after migration")
		await capture("recovery-mission")
	print("feedback-capture failures=", failures)
	var out := FileAccess.open(capture_dir + "/result.json", FileAccess.WRITE)
	out.store_string(JSON.stringify({"failures":failures, "screen":game.current_screen, "skill":game.selected_skill_id,"running":game.running_action_id}))
	out.close()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
