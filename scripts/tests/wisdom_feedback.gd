extends "res://scripts/tests/ham_feedback_capture.gd"

func visible_info_button() -> Button:
	for b in get_nodes_in_group("skill_header_info_buttons"):
		if b.is_visible_in_tree() and b.get_global_rect().intersects(Rect2(0,0,1080,1920)):
			return b
	return null

func _run() -> void:
	create_timer(175).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "120")
	capture_dir = "res://.codex-tmp/wisdom-review"
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
		game.skills[id].xp = SkillState.xp_for_level(99)
		game.skills[id].level = 99
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
	if OS.get_environment("IDLE_ELITE_TEST_WISDOM_REWARDS_ONLY") == "1":
		for source_case in [{"skill":"build", "action":"study-blueprint"}, {"skill":"thieving", "action":"chameleon-camouflage"}, {"skill":"woodcutting", "action":"prune-orchard-row"}]:
			await open_skill_menu()
			var skill_button: Control = game.skill_cards[source_case.skill].button
			game.content_scroll.scroll_vertical += int(skill_button.get_global_rect().get_center().y - 850)
			await settle(0.4)
			await click(skill_button.get_global_rect().get_center(), true)
			await settle(0.8)
			await game._skill_detail_surface()._scroll_to_activity_card(source_case.action, false, true)
			await settle(0.5)
			await inspect_wisdom_completion(game.action_cards[game._action_key(source_case.skill, source_case.action)], source_case.skill, source_case.action)
		await game._app_lifecycle_runtime()._repair_after_app_resume()
		await settle(0.3)
		print("wisdom-feedback failures=", failures)
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	var database: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://docs/activity-database.json"))
	check(int(database.global_rules.fishing_mirror_offer_cost) == preload("res://scripts/fishing/state.gd").FISHING_MIRROR_OFFER_COST, "Mirror cost matches authoritative database")
	var wisdom = preload("res://scripts/progression/wisdom_state.gd")
	var unlocks = game._activity_unlock_runtime()
	var action: Dictionary = game._action_data("build", "frame-a-treehouse-platform")
	var source: Dictionary = game._action_data("build", "study-blueprint")
	unlocks.manual_activity_unlocks.erase("build:frame-a-treehouse-platform")
	game.material_runtime.wisdom_by_skill["build"] = 0
	check(not unlocks._can_unlock_action("build", action), "Skills alone cannot bypass Wisdom")
	unlocks._mark_activity_requirement_manually_unlocked("build", action, 0)
	check(not game._skill_detail_surface()._action_requirement_unlocks_complete_after("build", action, 1), "Last skill padlock cannot bypass Wisdom")
	check(not unlocks._finalize_manual_activity_unlock("build", str(action.id)), "Finalization rejects unmet Wisdom")
	unlocks._clear_activity_requirement_manual_unlocks("build", str(action.id))
	game._action_runtime()._award_action_mat_rewards(source, 2.0)
	check(game.material_runtime.wisdom_by_skill["build"] == 1, "Successful source grants fixed Wisdom, independent of loot boosts")
	game._action_runtime()._award_action_mat_rewards(game._action_data("build", "hammer-nails"))
	check(game.material_runtime.wisdom_by_skill["build"] == 1, "Ordinary tasks do not award Wisdom")
	check(wisdom.total(game, "thieving") == 0 and wisdom.total(game, "woodcutting") == 0, "Building cannot award another skill's Wisdom")
	wisdom.award(game, game._action_data("thieving", "chameleon-camouflage"))
	wisdom.award(game, game._action_data("woodcutting", "prune-orchard-row"))
	check(wisdom.total(game, "thieving") == 1 and wisdom.total(game, "woodcutting") == 2 and wisdom.total(game, "build") == 1, "Each source credits only its own skill")
	game.material_runtime.wisdom_by_skill["thieving"] = 1000
	check(not unlocks._can_unlock_action("build", action), "High Thieving Wisdom cannot unlock a Building activity")
	var payload: Dictionary = game._save_runtime()._save_payload(game._unix_now())
	game.material_runtime.wisdom_by_skill["build"] = 0
	game.material_runtime.restore_wallet(payload)
	check(game.material_runtime.wisdom_by_skill["build"] == 1, "Wisdom survives save/restore")
	game.material_runtime.wisdom_by_skill["build"] = 24
	wisdom.award(game, source)
	check(unlocks._can_unlock_action("build", action), "Wisdom threshold permits eligible unlock")
	unlocks._mark_action_manually_unlocked("build", str(action.id))
	check(game.material_runtime.wisdom_by_skill["build"] == 25, "Unlock does not spend Wisdom")
	game.material_runtime.wisdom_by_skill["build"] = 0
	check(unlocks._is_action_unlocked("build", action), "Existing unlock remains available")
	var saved_unlocks: Dictionary = unlocks._manual_activity_unlocks_for_save()
	unlocks._restore_manual_activity_unlocks(saved_unlocks)
	check(unlocks._is_action_unlocked("build", action), "Grandfathered unlock survives serialization")
	for malformed in [-10, "bad", null, INF, NAN]:
		game.material_runtime.restore_wallet({"wisdom": malformed})
		check(game.material_runtime.wisdom_by_skill["build"] == 0, "Malformed Wisdom is rejected")
	var normalizers = preload("res://scripts/save_state/normalizers.gd")
	check(normalizers.payload_regresses_game_progress({"wisdom":25}, {"wisdom":24}, []), "Save guard rejects lost Wisdom")
	check(not normalizers.payload_regresses_game_progress({}, {"wisdom":1}, []), "Old save can gain Wisdom")
	check(normalizers.payload_regresses_game_progress({"wisdom":{"build":25,"thieving":10}}, {"wisdom":{"build":24,"thieving":100}}, []), "Other skill gains cannot hide lost Building Wisdom")
	check(not normalizers.payload_regresses_game_progress({"wisdom":{"build":25}}, {"wisdom":{"build":25,"thieving":1}}, []), "Skill-specific Wisdom can grow independently")
	game.material_runtime.restore_wallet({"wisdom":12})
	check(wisdom.total(game, "build") == 12 and wisdom.total(game, "thieving") == 12, "Experimental legacy balance migrates once without losing progress")
	game.material_runtime.restore_wallet({"wisdom":{"build":7,"thieving":"bad","woodcutting":-9,"fishing":NAN,"unknown":99}})
	check(wisdom.total(game, "build") == 7 and wisdom.total(game, "thieving") == 0 and wisdom.total(game, "woodcutting") == 0 and wisdom.total(game, "fishing") == 0, "Per-skill malformed values are rejected independently")
	check(not game.material_runtime.wisdom_by_skill.has("unknown"), "Unknown Wisdom skills are discarded")
	game.material_runtime.wisdom_by_skill["build"] = 0
	var offline_successes := 0
	game._action_runtime().guaranteed_success_action_completions = 999
	seed(12345)
	for i in range(100):
		var result: Dictionary = game._action_runtime()._grant_offline_action_completion("build", "study-blueprint", source, true)
		offline_successes += int(bool(result.success))
	check(offline_successes > 0 and offline_successes < 100, "Offline test exercises successes and failures")
	check(game.material_runtime.wisdom_by_skill["build"] == offline_successes, "Only successful offline attempts grant Wisdom")
	for skill_id in game.actions_by_skill:
		for gated in game.actions_by_skill[skill_id]:
			if int(gated.get("wisdom_required", 0)) <= 0:
				continue
			var key: String = game._action_key(skill_id, gated.id)
			unlocks.manual_activity_unlocks.erase(key)
			game.material_runtime.wisdom_by_skill[skill_id] = int(gated.wisdom_required) - 1
			check(not unlocks._can_unlock_action(skill_id, gated), "Gate blocks below threshold: " + key)
			game.material_runtime.wisdom_by_skill[skill_id] += 1
			check(unlocks._can_unlock_action(skill_id, gated), "Gate allows threshold: " + key)
			var prior_level: int = game.skills[skill_id].level
			game.skills[skill_id].level = 1
			check(not unlocks._can_unlock_action(skill_id, gated), "Wisdom cannot bypass skill level: " + key)
			game.skills[skill_id].level = prior_level
			check(not unlocks._action_blocks_owner_skill_progression(skill_id, gated), "Wisdom side activity does not block main progression")
	game.auto_unlock_lockpads_enabled = true
	game.material_runtime.wisdom_by_skill["build"] = 24
	wisdom.award(game, source)
	check(unlocks._is_action_unlocked("build", action), "Auto unlock responds to Wisdom threshold")
	game.auto_unlock_lockpads_enabled = false
	unlocks.manual_activity_unlocks.erase("build:frame-a-treehouse-platform")
	unlocks.pending_activity_unlock_ceremony.clear()
	for id in game.skills:
		game.skills[id].xp = SkillState.xp_for_level(40)
		game.skills[id].level = 40
	game.material_runtime.wisdom_by_skill["build"] = 12
	await open_skill_menu()
	game.content_scroll.scroll_vertical = 0
	await settle(0.5)
	for touch in [false, true]:
		await menu_drag(touch)
		check(game.current_screen == "menu", "Dragging menu must not open a skill: touch=%s" % touch)
		check(game.content_scroll.scroll_vertical > 0, "Menu drag scrolls toward Fishing")
		game.content_scroll.scroll_vertical = 0
		await settle(0.5)
	game.content_scroll.scroll_vertical = 700
	await settle(0.5)
	await click(game.skill_cards.build.button.get_global_rect().get_center())
	await settle(1.0)
	await game._skill_detail_surface()._scroll_to_activity_card("frame-a-treehouse-platform", false, true)
	await settle(1.0)
	var card: Dictionary = game.action_cards["build:frame-a-treehouse-platform"]
	check(card.has("wisdom_panel"), "Wisdom bar attached to production card")
	check(card.wisdom_panel.caption.text.begins_with("Wisdom Required (12 / 25)"), "Wisdom requirement caption groups the balance in parentheses")
	var wisdom_face: Control = card.root.get_node("WisdomActivityFace")
	check(is_equal_approx(card.wisdom_panel.get_global_rect().position.y, card.progress.get_global_rect().end.y), "Rounded Wisdom layer joins the existing progress bar directly")
	check(card.progress.bottom_radius > 0, "Existing progress bar retains rounded corners")
	check(is_equal_approx(card.wisdom_panel.size.x, card.progress.size.x), "Wisdom layer matches the activity width: %s / %s" % [card.wisdom_panel.size.x, card.progress.size.x])
	check(card.wisdom_panel.get_parent() == card.pop, "Wisdom layer shares the module face and its press motion")
	check(wisdom_face.get_global_rect().end.y > card.wisdom_panel.get_child(0).get_global_rect().end.y, "Module depth continues below Wisdom")
	check(card.wisdom_panel.caption.get_minimum_size().x <= card.wisdom_panel.caption.size.x, "Wisdom requirement text fits its bar")
	await capture("wisdom-locked")
	await click(card.wisdom_panel.get_child(0).get_global_rect().get_center())
	await settle(1.0)
	check(card.wisdom_panel.help.visible, "Wisdom bar opens explanation")
	await capture("wisdom-help")
	var source_link: Button = null
	for link in get_nodes_in_group("feedback_help_buttons"):
		if link is Button and link.text.begins_with("Study Blueprint"):
			source_link = link
	check(source_link != null, "Wisdom help has a source navigation link")
	await click(source_link.get_global_rect().get_center())
	await settle(1.0)
	check(game.selected_skill_id == "build", "Wisdom source link opens Building")
	await game._skill_detail_surface()._scroll_to_activity_card("study-blueprint", false, true)
	await settle(0.8)
	var source_card: Dictionary = game.action_cards["build:study-blueprint"]
	check(not source_card.wisdom_panel.get_child(0).visible, "Wisdom sources have no reward bar")
	check(source_card.root.custom_minimum_size.y < 400, "Wisdom source retains normal card height")
	check(is_instance_valid(source_card.wisdom_panel.reward_badge), "Wisdom reward badge is attached")
	check(source_card.wisdom_panel.reward_badge.get_parent() == source_card.art_panel, "Wisdom badge belongs to the real action art")
	check(source_card.wisdom_panel.reward_badge.position.x > 100 and source_card.wisdom_panel.reward_badge.position.y > 100, "Wisdom badge is in the bottom-right art corner")
	await capture("wisdom-source")
	await click(source_card.wisdom_panel.reward_button.get_global_rect().get_center(), true)
	await settle(0.8)
	check(source_card.wisdom_panel.help.visible, "Reward badge opens inline Wisdom help")
	check(source_card.bg.get_rect().end.y <= source_card.progress.get_rect().end.y + 1.0, "Source help keeps art above the progress strip")
	check(game.running_action_id != "study-blueprint", "Wisdom badge does not start the activity")
	await capture("wisdom-source-help")
	await click(source_card.wisdom_panel.reward_button.get_global_rect().get_center(), true)
	await settle(0.5)
	check(not source_card.wisdom_panel.help.visible, "Reward badge closes its explanation")
	game._action_runtime().guaranteed_success_action_completions = 0
	game.stamina.build = 20.0
	var before_live: int = game.material_runtime.wisdom_by_skill["build"]
	await inspect_wisdom_completion(source_card, "build", "study-blueprint")
	check(game.material_runtime.wisdom_by_skill["build"] > before_live, "Actual activity completion grants Wisdom online")
	game._action_runtime()._stop_running_action("build", "study-blueprint")
	game.material_runtime.wisdom_by_skill["build"] = 2000000000
	game._update_ui(0.0, true)
	await settle(0.1)
	check(source_card.wisdom_panel.reward_badge.get_node_or_null("WisdomRewardAmount") == null, "Wisdom badge stays icon-only at any skill balance")
	game.material_runtime.wisdom_by_skill["build"] = 12
	game._update_ui(0.0, true)
	await hold(source_card.stat_boxes.time.get_global_rect().get_center())
	await settle(0.7)
	check(source_card.bonus_expanded, "Source still opens Time Bonuses")
	check(source_card.bonus_panel.root.get_global_rect().position.y >= source_card.wisdom_panel.get_global_rect().end.y, "Time Bonuses sits below Wisdom")
	await game._skill_detail_surface()._scroll_to_activity_card("study-blueprint", false, false)
	await capture("wisdom-time-bonuses")
	game._skill_detail_surface()._clear_activity_stat_popup()
	await game._skill_detail_surface()._scroll_to_activity_card("frame-a-treehouse-platform", false, true)
	await settle(0.6)
	card = game.action_cards["build:frame-a-treehouse-platform"]
	if card.wisdom_panel.help.visible:
		await click(card.wisdom_panel.get_child(0).get_global_rect().get_center())
		await settle(0.3)
	await game._skill_detail_surface()._scroll_to_activity_card("frame-a-treehouse-platform", false, true)
	await settle(0.3)
	for i in range(unlocks._action_requirement_states("build", action).size()):
		var lock_group: Control = card.lock_overlay.group
		var lock_rig: Control = lock_group.rigs[i]
		var body_point: Vector2 = lock_rig.base_lock_position + lock_rig.lock_offset + Vector2(135, 210)
		await click(lock_rig.get_global_transform_with_canvas() * body_point)
		await settle(1.2)
		check(bool(unlocks._action_requirement_states("build", action)[i].dismissed), "Real padlock click dismisses requirement %s" % i)
		if card.wisdom_panel.help.visible:
			await click(card.wisdom_panel.get_child(0).get_global_rect().get_center())
			await settle(0.3)
		await game._skill_detail_surface()._scroll_to_activity_card("frame-a-treehouse-platform", false, true)
		await settle(0.3)
		await capture("wisdom-one-lock-removed" if i == 0 else "wisdom-both-locks-removed")
	check(not unlocks._is_action_unlocked("build", action), "Both skill locks removed still requires Wisdom")
	check(game.material_runtime.wisdom_by_skill["build"] == 12, "Removing skill locks keeps partial Wisdom balance")
	game.material_runtime.wisdom_by_skill["build"] = 25
	game._update_ui(0.0, true)
	await settle(0.4)
	check(card.wisdom_panel._ready_to_unlock(), "Wisdom offers unlock after both padlocks open")
	check(card.wisdom_panel.caption.text == "Unlock", "Full Wisdom bar uses the plain Unlock label")
	var locked_height: float = card.root.custom_minimum_size.y
	var wisdom_bar_size: Vector2 = card.wisdom_panel.meter.get_global_rect().size
	var wisdom_bar_y: float = card.wisdom_panel.position.y
	await capture("wisdom-unlock-before")
	# Real input with no post-click wait, so the transition frame is captured in motion.
	var unlock_point: Vector2 = card.wisdom_panel.get_child(0).get_global_rect().get_center()
	for down in [true, false]:
		var unlock_click := InputEventMouseButton.new()
		unlock_click.position = unlock_point
		unlock_click.global_position = unlock_point
		unlock_click.button_index = MOUSE_BUTTON_LEFT
		unlock_click.pressed = down
		Input.parse_input_event(unlock_click)
		await process_frame
	await settle(0.06)
	check(card.wisdom_panel.caption.modulate.a < 1.0, "Unlock text fades before the bar moves")
	check(is_equal_approx(card.wisdom_panel.position.y, wisdom_bar_y), "Bar holds its position while the text fades")
	await capture("wisdom-unlock-text-fading")
	await settle(0.22)
	check(bool(card.get("wisdom_unlock_active", false)), "Wisdom completion has an active transition")
	check(not unlocks._is_action_unlocked("build", action), "Activity remains locked during retraction")
	check(card.wisdom_panel.scale.is_equal_approx(Vector2.ONE), "Wisdom bar never scales during the slide")
	check(card.wisdom_panel.meter.get_global_rect().size.is_equal_approx(wisdom_bar_size), "Sliding bar retains its full width and height")
	check(card.wisdom_panel.position.y < wisdom_bar_y, "Wisdom bar slides upward behind the module")
	check(is_zero_approx(card.wisdom_panel.caption.modulate.a), "Unlock text is gone during the slide")
	check(card.root.custom_minimum_size.y < locked_height, "Module closes its extra depth during retraction")
	await capture("wisdom-unlock-retracting")
	await settle(0.8)
	check(unlocks._is_action_unlocked("build", action), "Tapping full Wisdom bar unlocks with auto-unlock disabled")
	check(game.material_runtime.wisdom_by_skill["build"] == 25, "Manual Wisdom unlock does not spend resource")
	check(not card.wisdom_panel.visible and not bool(card.get("wisdom_unlock_active", false)), "Wisdom bar is hidden after transition")
	check(is_equal_approx(card.root.custom_minimum_size.y, locked_height - 96.0), "Unlocked module no longer reserves Wisdom space")
	check(not card.lock_overlay.root.visible and not card.shade.visible, "Chain and dimming clear after retraction")
	await capture("wisdom-unlock-settled")
	game._update_ui(0.0, true)
	await settle(0.2)
	check(not bool(card.get("wisdom_unlock_active", false)) and not card.wisdom_panel.visible, "Normal refresh does not replay or restore the bar")
	# Rebuild through normal navigation: a saved unlock must mount fully retracted.
	await open_skill_menu()
	var build_button: Control = game.skill_cards.build.button
	game.content_scroll.scroll_vertical += int(build_button.get_global_rect().get_center().y - 850)
	await settle(0.3)
	await click(build_button.get_global_rect().get_center())
	await settle(0.8)
	await game._skill_detail_surface()._scroll_to_activity_card("frame-a-treehouse-platform", false, true)
	await settle(0.4)
	card = game.action_cards["build:frame-a-treehouse-platform"]
	check(not card.wisdom_panel.visible and not bool(card.get("wisdom_unlock_active", false)), "Returning to an unlocked activity does not replay the animation")
	check(absf(card.root.custom_minimum_size.y - (locked_height - 96.0)) < 0.5, "Rebuilt unlocked card has no empty Wisdom layer (before=%s, rebuilt=%s)" % [locked_height, card.root.custom_minimum_size.y])
	await capture("wisdom-unlock-returned")
	if OS.get_environment("IDLE_ELITE_TEST_WISDOM_ONLY") == "1":
		print("wisdom-feedback failures=", failures)
		await settle(2.0)
		game.queue_free()
		await process_frame
		quit(0 if failures.is_empty() else 1)
		return
	for source_case in [{"skill":"thieving", "action":"chameleon-camouflage"}, {"skill":"woodcutting", "action":"prune-orchard-row"}]:
		await open_skill_menu()
		var skill_button: Control = game.skill_cards[source_case.skill].button
		game.content_scroll.scroll_vertical += int(skill_button.get_global_rect().get_center().y - 850)
		await settle(0.6)
		await click(skill_button.get_global_rect().get_center(), true)
		await settle(1.0)
		await game._skill_detail_surface()._scroll_to_activity_card(source_case.action, false, true)
		await settle(0.8)
		var colored_card: Dictionary = game.action_cards[game._action_key(source_case.skill, source_case.action)]
		var icon: TextureRect = colored_card.wisdom_panel.reward_badge.get_child(1)
		check(icon.material.get_shader_parameter("skill_color") == ThemeStyles.skill_theme_color(source_case.skill, Color.WHITE), "Wisdom book matches its skill color: " + source_case.skill)
		check(not colored_card.wisdom_panel.get_child(0).visible, "Source has no full-width reward bar: " + source_case.skill)
		await capture("wisdom-source-" + source_case.skill)
		if source_case.skill == "woodcutting":
			await inspect_wisdom_completion(colored_card, source_case.skill, source_case.action)
	await open_skill_menu()
	game.content_scroll.scroll_vertical = 700
	await settle(0.5)
	await click(game.skill_cards.fishing.button.get_global_rect().get_center())
	await settle(1.2)
	game.fishing_runtime.boat_built = true
	game.fishing_runtime.equipped_tool_id = "boat"
	game.fishing_runtime.boat_stored_fish = 200
	await game._skill_detail_surface()._scroll_to_activity_card("rocks", false, true)
	await settle(0.5)
	var fish_card: Dictionary = {}
	for candidate in game.action_cards.values():
		if str(candidate.get("area_id", "")) == "beach" and bool(candidate.get("is_fishing_area", false)):
			var slots: Dictionary = candidate.method_slots
			fish_card = slots.values()[0]
	check(not fish_card.is_empty(), "Beach location is mounted")
	await click(fish_card.method_hit_control.get_global_rect().get_center())
	await settle(0.2)
	game.fishing_runtime.boat_stored_fish = 200
	game._update_ui(0.0, true)
	var area: Dictionary = {}
	for candidate in game.action_cards.values():
		if str(candidate.get("area_id", "")) == "beach" and bool(candidate.get("is_fishing_area", false)):
			area = candidate
	if not area.is_empty():
		var counter: Label = area.area_yield
		check(counter.text == "200/200", "Full boat counter shows capacity")
		check(counter.get_minimum_size().x <= counter.size.x, "Full boat counter fits without truncation")
		check(not (counter.get_meta("stat_title_label") as Label).visible, "Boat capacity stays on one line")
		check(area.stat_column.size.y <= 168, "Fishing stats leave the lower boat lane exposed")
	var pool: Dictionary = game.action_cards.get("fishing:practice-pool", {})
	check(not pool.is_empty(), "Practice Pool is mounted beside the boat")
	if not pool.is_empty():
		var note: Label = pool.root.find_child("FishingTrainingRewardLabel", true, false)
		check(note == null, "Practice Pool omits redundant no-fish text")
		check(pool.art_panel.get_rect().size.x > pool.art.get_rect().end.x and pool.art.get_rect().position.x > 0, "Practice rod has authored inset inside its frame")
	await capture("boat-capacity")
	for offer_id in ["net", "rod"]:
		for entry in game._skill_detail_surface().detail_lazy_plan:
			if str(entry.get("offer_id", "")) == offer_id:
				game._skill_detail_surface().detail_actions_scroll.scroll_vertical = maxi(0, int(entry.y) - 100)
				await settle(0.8)
				await capture("fishing-offer-" + offer_id)
	await game._skill_detail_surface()._scroll_to_activity_card("rocks", false, true)
	await settle(0.5)
	game._action_runtime()._stop_running_action(game.running_skill_id, game.running_action_id)
	await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center(), true)
	await settle(0.3)
	await inspect_wallet_list("fishing-wallet-locked")
	var equipped_before: String = game.fishing_runtime.equipped_tool_id
	for row in game._fishing_ui_surface().fishing_tool_wallet_popup.get_node("ToolGrid").get_children():
		if not bool(row.get_meta("tool_unlocked")):
			await click(row.get_global_rect().get_center(), true)
			check(game.fishing_runtime.equipped_tool_id == equipped_before, "Locked wallet row cannot equip a tool")
			break
	await close_tool_wallet()
	for tool in ["net", "line", "boat", "mirror"]:
		game.fishing_runtime.collect_tool_from_equipped(tool)
	await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center())
	await settle(0.4)
	await inspect_wallet_list("fishing-wallet-list")
	for chosen in ["hands", "net"]:
		var wallet: Control = game._fishing_ui_surface().fishing_tool_wallet_popup
		for row in wallet.get_node("ToolGrid").get_children():
			if str(row.get_meta("tool_id")) == chosen:
				await click(row.get_global_rect().get_center(), chosen == "net")
				break
		check(game.fishing_runtime.equipped_tool_id == chosen, "Wallet row equips tool: " + chosen)
		check(not game._fishing_ui_surface().is_fishing_tool_wallet_open(), "Selection closes the wallet")
		await settle(0.4)
		await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center(), true)
		await settle(0.3)
	await inspect_wallet_list("fishing-wallet-selected")
	for tool in ["hands", "net", "line", "boat", "mirror"]:
		await inspect_tool_help(tool)
	for tool in ["reinforced_rod", "star_rod"]:
		await close_tool_wallet()
		game.fishing_runtime.collect_tool_from_equipped(tool)
		await settle(0.5)
		await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center())
		await settle(0.4)
		await inspect_tool_help(tool)
	await close_tool_wallet()
	game.fishing_runtime.mirror_collected = false
	game.fishing_runtime.fish_currency = 1000000
	game.skills.fishing.level = 90
	game.skills.fishing.xp = SkillState.xp_for_level(90)
	await open_skill_menu()
	game.content_scroll.scroll_vertical = 700
	await settle(0.4)
	await click(game.skill_cards.fishing.button.get_global_rect().get_center())
	await settle(0.6)
	var mirror_entry: Dictionary = {}
	for entry in game._skill_detail_surface().detail_lazy_plan:
		if str(entry.get("offer_id", "")) == "mirror":
			mirror_entry = entry
	check(not mirror_entry.is_empty(), "Level 90 exposes the mirror offer")
	if not mirror_entry.is_empty():
		game._skill_detail_surface().detail_actions_scroll.scroll_vertical = maxi(0, int(mirror_entry.y) - 180)
	await settle(1.0)
	await capture("mirror-cost")
	var mirror_button: Button = null
	for offer in get_nodes_in_group("fishing_offer_buttons"):
		if str(offer.get_meta("fishing_offer_id", "")) == "mirror" and offer.is_visible_in_tree():
			mirror_button = offer
	check(mirror_button != null, "Mirror purchase offer is reachable")
	if mirror_button != null:
		await click(mirror_button.get_global_rect().get_center())
	await settle(0.6)
	check(game.fishing_runtime.mirror_collected, "Mirror can be purchased for 1,000,000 fish")
	check(is_zero_approx(game.fishing_runtime.fish_currency), "Mirror spends exactly 1,000,000 fish")
	print("wisdom-feedback failures=", failures)
	await settle(2.0)
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func open_skill_menu() -> void:
	if game.current_screen not in ["skill", "menu"]:
		await click(game.skills_tab.get_global_rect().get_center())
		await settle(1.0)
	if game.current_screen != "menu":
		await click(game._navigation_shell().skills_utility_tab.get_global_rect().get_center())
		await settle(1.0)

func menu_drag(touch: bool) -> void:
	var start := Vector2(540, 950)
	if touch:
		var down := InputEventScreenTouch.new()
		down.position = start
		down.index = 0
		down.pressed = true
		Input.parse_input_event(down)
	else:
		var down := InputEventMouseButton.new()
		down.position = start
		down.global_position = start
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		Input.parse_input_event(down)
	await settle(0.8)
	check(game.current_screen == "menu", "Holding a menu card does not navigate")
	for i in range(1, 13):
		var point := start - Vector2(0, i * 35)
		if touch:
			var drag := InputEventScreenDrag.new()
			drag.index = 0
			drag.position = point
			drag.relative = Vector2(0, -35)
			Input.parse_input_event(drag)
		else:
			var drag := InputEventMouseMotion.new()
			drag.position = point
			drag.global_position = point
			drag.relative = Vector2(0, -35)
			drag.button_mask = MOUSE_BUTTON_MASK_LEFT
			Input.parse_input_event(drag)
		await settle(0.02)
	if touch:
		var up := InputEventScreenTouch.new()
		up.position = start - Vector2(0,420)
		up.index = 0
		up.pressed = false
		Input.parse_input_event(up)
	else:
		var up := InputEventMouseButton.new()
		up.position = start - Vector2(0,420)
		up.global_position = up.position
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		Input.parse_input_event(up)
	await settle(0.7)

func inspect_wisdom_completion(card: Dictionary, skill_id: String, action_id: String) -> void:
	var feedback = game._reward_feedback_surface()
	feedback._clear_skill_reward_floats()
	game._action_runtime().guaranteed_success_action_completions = 0
	game.stamina[skill_id] = 40.0
	var before := preload("res://scripts/progression/wisdom_state.gd").total(game, skill_id)
	await capture("wisdom-reward-" + skill_id + "-before")
	await click(card.art_panel.get_global_rect().get_center(), true)
	for frame in range(1200):
		if preload("res://scripts/progression/wisdom_state.gd").total(game, skill_id) > before:
			break
		await process_frame
	# Hold the simulation after a real completion while its independent UI tweens run.
	game.set_process(false)
	var wisdom_float: Control = null
	var xp_float: Control = null
	var xp_floats: Array[Control] = []
	for node in get_nodes_in_group("skill_reward_float"):
		if node.name == "WisdomRewardFloat":
			wisdom_float = node
		else:
			if xp_float == null:
				xp_float = node
			xp_floats.append(node)
	check(wisdom_float != null and xp_float != null, "Completion shows both Wisdom and XP: " + skill_id)
	if wisdom_float == null or xp_float == null:
		game.set_process(true)
		game._action_runtime()._stop_running_action(skill_id, action_id)
		return
	check(wisdom_float.get_meta("reward_float_tween") != xp_float.get_meta("reward_float_tween"), "Wisdom has an independent tween")
	check(wisdom_float.get_child(1).text == "+%s" % int(card.action.wisdom_reward), "Popup shows the Wisdom actually earned")
	await settle(0.28)
	check(wisdom_float.get_global_rect().position.x >= xp_text_right(xp_float), "Wisdom appears to the right of the visible XP text: " + skill_id)
	check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(wisdom_float.get_global_rect()), "Wisdom popup stays inside the viewport")
	for i in range(xp_floats.size()):
		for j in range(i + 1, xp_floats.size()):
			check(not xp_floats[i].get_global_rect().intersects(xp_floats[j].get_global_rect()), "Multiple XP rewards remain readable")
	await capture("wisdom-reward-" + skill_id + "-pop")
	var first_position: Vector2 = wisdom_float.position
	await settle(0.38)
	check(is_equal_approx(wisdom_float.position.x, first_position.x) and wisdom_float.position.y < first_position.y, "Wisdom rises in its lane to the right of XP")
	check(wisdom_float.get_global_rect().position.x >= xp_text_right(xp_float), "Wisdom stays to the right of XP during the rise")
	await capture("wisdom-reward-" + skill_id + "-drift")
	await settle(1.1)
	check(not is_instance_valid(wisdom_float), "Wisdom float cleans up after fading")
	await capture("wisdom-reward-" + skill_id + "-settled")
	game.set_process(true)
	game._action_runtime()._stop_running_action(skill_id, action_id)
	feedback._play_action_feedback(game._action_key(skill_id, action_id), false, 0, 0, false, false, {}, 0.0, 2)
	check(game.get_node_or_null("WisdomRewardFloat") == null, "Failure cannot display a Wisdom reward")
	feedback._play_action_feedback(game._action_key(skill_id, action_id), true, 0, 0, false, false, {}, 0.0, 0)
	check(game.get_node_or_null("WisdomRewardFloat") == null, "No Wisdom popup when nothing was awarded")
	await settle(0.4)

func xp_text_right(xp_float: Control) -> float:
	var label := xp_float.get_child(1) as Label
	var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
	return (label.get_global_transform_with_canvas() * Vector2((label.size.x + width) * 0.5 + label.get_theme_constant("outline_size"), 0)).x

func inspect_wallet_list(capture_name: String) -> void:
	var wallet: Control = game._fishing_ui_surface().fishing_tool_wallet_popup
	var previous_bottom := -1.0
	var selected_count := 0
	for row in wallet.get_node("ToolGrid").get_children():
		check(is_zero_approx(row.position.x) and row.position.y >= previous_bottom, "Wallet rows form a vertical list")
		previous_bottom = row.position.y + row.size.y
		check(wallet.get_global_rect().encloses(row.get_global_rect()), "Wallet row stays inside its panel")
		for item in row.get_children():
			if item is Control:
				check(row.get_global_rect().encloses(item.get_global_rect()), "Tool art, text and help stay inside the row")
		if row.get_node_or_null("EquippedIndicator") != null:
			selected_count += 1
			check(str(row.get_meta("tool_id")) == game.fishing_runtime.equipped_tool_id, "Checkmark identifies the equipped tool")
	check(selected_count == 1, "Wallet has one equipped indicator")
	await capture(capture_name)

func inspect_tool_help(tool_id: String) -> void:
	await settle(0.6)
	print("Checking tool help: ", tool_id)
	var found := false
	for button in get_nodes_in_group("feedback_help_buttons"):
		if button.name == "FishingToolInformation" and str(button.get_parent().get_meta("tool_id", "")) == tool_id and button.is_visible_in_tree():
			found = true
			await click(button.get_global_rect().get_center(), true)
			await settle(0.5)
			var wallet: Control = game._fishing_ui_surface().fishing_tool_wallet_popup
			check(wallet.get_global_rect().end.y < 1598, "Readable help stays above navigation: " + tool_id)
			var running_before: String = game.running_skill_id + ":" + game.running_action_id
			var details: Control = wallet.get_node_or_null("FishingToolDetails")
			check(details != null, "Information tap opens tool details: " + tool_id)
			if details == null:
				await capture("missing-help-" + tool_id)
				return
			await click(details.get_global_rect().get_center())
			check(game.running_skill_id + ":" + game.running_action_id == running_before, "Help text taps do not reach activities: " + tool_id)
			await capture("fishing-" + tool_id + "-help")
			await click(button.get_global_rect().get_center(), true)
			check(wallet.get_node_or_null("FishingToolDetails") == null, "Same information button closes help: " + tool_id)
			var base: Rect2 = wallet.get_meta("wallet_base_rect")
			check(is_equal_approx(wallet.size.x, base.size.x), "Closing help preserves the tool list width: " + tool_id)
			break
	check(found, "Tool help reached through its information button: " + tool_id)

func close_tool_wallet() -> void:
	await settle(0.5)
	check(game._fishing_ui_surface().is_fishing_tool_wallet_open(), "Tool wallet is open before closing")
	await click(game._skill_detail_surface().detail_fish_circle.get_global_rect().get_center())
	await settle(0.4)
	check(not game._fishing_ui_surface().is_fishing_tool_wallet_open(), "Fish circle closes its tool wallet")
