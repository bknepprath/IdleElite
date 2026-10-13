extends "res://scripts/tests/desktop_layout_input.gd"

func _run() -> void:
	create_timer(120).timeout.connect(func(): quit(1))
	var desktop := OS.get_environment("IDLE_ELITE_STROKE_DESKTOP") == "1"
	OS.set_environment("IDLE_ELITE_DESKTOP", "1" if desktop else "0")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "100")
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1920, 1080) if desktop else Vector2i(1080, 1920)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	for i in range(1600):
		await settle(0.02)
		if game.startup_initialized and not game._boot_warmup_runtime().active: break
	check(game.startup_initialized, "Production scene boots")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._update_tutorial_overlay()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game._onboarding_runtime().activity_start_tip_seen = true
	game.offline_progress_enabled = false
	for skill_id in game.skills:
		game.skills[skill_id].xp = preload("res://scripts/progression/skill_state.gd").xp_for_level(25)
		preload("res://scripts/progression/skill_state.gd").recalculate_level(game, skill_id)
	var achievements = preload("res://scripts/achievements/state.gd")
	achievements.mark_completed_seen_ids(achievements.milestones(game, false), game._save_runtime().achievement_toast_seen_ids, [])
	var toasts = game._achievement_toast_surface()
	toasts.achievement_toast_queue.clear()
	toasts.achievement_toast_queue_ids.clear()
	for toast in toasts.achievement_toasts:
		if is_instance_valid(toast): toast.queue_free()
	toasts.achievement_toasts.clear()


	var nav = game._navigation_shell()
	var detail = game._skill_detail_surface()
	var runtime = game._action_runtime()
	var material = game._material_collection_surface()
	game.selected_skill_id = "fight"
	game.current_screen = "skill"
	game.material_runtime.set_amount("berries", 1)
	game.material_runtime.toggle_berry_prep_target("fight", "push-ups", Callable(game, "_action_data"), Callable(game, "_action_key"))
	game.mastery["fight:push-ups"] = {"xp": preload("res://scripts/progression/mastery_state.gd").xp_for_level(2), "level": 2}
	await nav._render_screen()
	await settle(2)
	game.set_process(false)
	if desktop:
		game.desktop_layout.focus_column(0)
	else:
		await detail._scroll_to_activity_card("push-ups", false, true)
	await settle(0.5)
	var card: Dictionary = game.action_cards.get("fight:push-ups", {})
	print("POLISH card mounted=", not card.is_empty())
	if card.is_empty(): quit(1); return
	await click(card.button.get_global_rect().get_center(), not desktop)
	check(game.running_action_id == "push-ups", "Actual card starts activity")
	game.action_progress = 0.62
	game._update_ui(0.0, true)
	material.sync_berry_prep_badges()
	await settle(0.5)
	await shot("skills-before")
	var berry := find_berry()
	check(berry != null, "Berry visible")
	if berry != null:
		check(berry.get_parent().get_node("BerryPrepCountAnchor/BerryPrepCount").text == "1", "Remaining count begins at 1")
	game.action_progress = 1.0
	runtime._process_action(0.01)
	await settle(0.06)
	await shot("berry-pulse")
	check(game.material_runtime.amount("berries") == 0, "Completion spends final berry")
	if berry != null:
		check(berry.get_parent().get_node("BerryPrepCountAnchor/BerryPrepCount").text == "0", "Remaining count updates to zero")
	await settle(0.5)
	check(berry == null or is_zero_approx(berry.rotation), "Final berry never triggers failure shake")
	await shot("berry-settled")
	game.running_skill_id = ""
	game.running_action_id = ""
	game._reward_feedback_surface()._clear_skill_reward_floats()
	card = game.action_cards.get("fight:push-ups", {})
	var pop: Control = card.pop
	var zone: Control = detail._module_action_zone_for_card(pop, "collapse")
	check(zone != null, "Collapse hit target exists")
	if zone != null:
		await click(zone.get_global_rect().get_center(), not desktop)
		var badge: Control = detail._module_collapse_badge(pop)
		if badge != null and badge.visible:
			await press(badge.get_global_rect().get_center(), not desktop)
		else:
			await press(zone.get_global_rect().get_center(), not desktop)
		await shot("collapse-transition")
		await settle(0.6)
		await shot("collapse-settled")

	# Exercise the production expansion control, then inspect the restored body.
	var row: Control = detail._collapsed_module_row_for_key("action:fight:push-ups")
	if row == null:
		for item in get_nodes_in_group("collapsed_module_rows"):
			if item.is_visible_in_tree(): row = item; break
	if row != null:
		await press(row.get_global_rect().get_center(), not desktop)
		await shot("expand-transition")
		await settle(0.7)
		await shot("expand-settled")
	# Medal and recovery checks use the same loaded production records.
	var mastery = preload("res://scripts/progression/mastery_state.gd")
	var trial := {}
	for rep in range(270): mastery.add_xp(trial, "rest", 10, 20)
	check(mastery.level(trial, "rest") == 9, "Rest is below Heavenly at 270 reps")
	mastery.add_xp(trial, "rest", 10, 20)
	check(mastery.level(trial, "rest") == 10, "Rest reaches Heavenly at 271 reps")
	var restored: Dictionary = mastery.restored_from_save(mastery.for_save(trial, func(key): return key, 20), func(key): return key, 20)
	check(restored == trial, "Faster mastery survives save round trip")
	var saved_mastery: Dictionary = game.mastery.duplicate(true)
	game.mastery = {"fight:fight-chickens": {"xp": mastery.xp_for_level(20), "level": 20}}
	check(achievements.all_medal_counts(game).earned == 0, "Old arena medals excluded from medal total")
	check(not achievements.global_medal_tier_unlocked(game, 1), "Old arena medals grant no global medal buff")
	mastery.add_host_xp(game, "fight", "fight-chickens", 10)
	check(game.mastery["fight:fight-chickens"].xp == mastery.xp_for_level(20), "Arena cannot gain mastery through direct grant")
	game.mastery = saved_mastery
	var rest_count := 0
	var arena_count := 0
	for skill_id in game.actions_by_skill:
		for action in game.actions_by_skill[skill_id]:
			var id: String = action.id
			if action.has("recovery"):
				rest_count += 1
				check(mastery.xp_reward(action) == 10, "Rest mastery award: " + id)
				game.mastery[game._action_key(skill_id, id)] = {"xp": mastery.xp_for_level(10), "level": 10}
				check(runtime._action_opportunity_pattern_windows(skill_id, id).is_empty(), "No resting opportunity: " + id)
			if game._fighting_runtime().action_uses_diamond_combat_arena(action):
				arena_count += 1
				check(not mastery.action_has_mastery(game, action), "Arena has no mastery: " + id)
				check(not achievements.mastery_actions_for_skill(game, skill_id).has(action), "Arena excluded from totals: " + id)
	print("POLISH rest=", rest_count, " arenas=", arena_count)
	game.set_process(true)
	# The Skills utility row must disappear in the tab's input handler.
	var settings_button: Control = game.desktop_layout.ribbon_buttons.settings if desktop else game.settings_tab
	await press(settings_button.get_global_rect().get_center(), not desktop)
	if not desktop: check(not nav.module_utility_row.visible, "Utility row hides on tab input, without waiting for refresh")
	await shot("settings-first-frame")
	await settle(0.7)
	check(game.current_screen == "settings", "Settings reached through UI")
	await shot("settings-settled")
	var skills_button: Control = game.desktop_layout.ribbon_buttons.skill if desktop else game.skills_tab
	await click(skills_button.get_global_rect().get_center(), not desktop)
	await settle(0.8)
	if desktop: game.desktop_layout.focus_column(0)
	if not desktop: check(nav.module_utility_row.visible, "Utility row returns with Skills")
	game._reward_feedback_surface()._show_visible_skill_level_up_float("fight")
	await settle(0.16)
	await shot("level-up")
	await settle(1.5)
	# Reach the first mounted tier plaque through its actual scroll view.
	for entry in detail.detail_lazy_plan:
		if entry.get("kind", "") == "tier_banner":
			detail.detail_actions_scroll.scroll_vertical = int(entry.get("y", 0))
			detail._sync_detail_lazy_visible_cards(true, 30)
			break
	await settle(0.8)
	var banner := find_meta_control(game, "detail_lazy_tier_banner")
	check(banner != null, "Tier plaque mounted")
	if banner != null:
		await click(banner.get_global_rect().position + Vector2(banner.size.x * 0.5, 180), not desktop)
		await settle(0.8)
		check(not detail.expanded_tier_banner_key.is_empty(), "Tier menu opened through plaque input")
		await shot("tier-expanded")
		var info_found := false
		for info in get_nodes_in_group("skill_header_info_buttons"):
			if info.is_visible_in_tree() and has_text(info, "Tier Medal Support"):
				await click(info.get_global_rect().get_center(), not desktop)
				info_found = true
				await shot("tier-info")
				for popup in get_nodes_in_group("skill_header_info_popovers"):
					if popup.visible:
						check(Rect2(Vector2.ZERO, game.size).encloses(popup.get_global_rect()), "Tier info remains within canvas")
				await click(info.get_global_rect().get_center(), not desktop)
				break
		check(info_found, "Tier info reached through visible info button")
	# Show a real resting activity at Heavenly with no opportunity window.
	for action in game.actions_by_skill.fight:
		if action.has("recovery"):
			await detail._scroll_to_activity_card(action.id, false, true)
			await settle(0.5)
			var resting: Dictionary = game.action_cards.get("fight:" + action.id, {})
			if not resting.is_empty():
				game.stamina.fight = 0
				await click(resting.button.get_global_rect().get_center(), not desktop)
				await settle(0.3)
				check(resting.progress.opportunity_windows.is_empty(), "Resting card has no opportunity graphic")
				await shot("resting")
				game.running_skill_id = ""
				game.running_action_id = ""
			break
	var hub_button: Control = game.desktop_layout.ribbon_buttons.hub if desktop else nav.hub_tab
	await click(hub_button.get_global_rect().get_center(), not desktop)
	await settle(0.8)
	check(game.current_screen == "hub", "Hub reached through UI")
	var hub = game._hub_surface()
	if hub.hub_module_buttons.has("mission"):
		if desktop:
			await physical_press(hub.hub_module_buttons.mission.get_global_rect().get_center(), 0.08)
		else:
			await click(hub.hub_module_buttons.mission.get_global_rect().get_center(), true)
		await settle(0.6)
		check(hub.hub_detail_open, "Mission panel opened through sign")
		await shot("hub-mission")
	print("ACTIVITY_POLISH failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func find_berry() -> Sprite2D:
	for box in get_nodes_in_group("berry_prep_xp_chip_boxes"):
		var badge := instance_from_id(int(box.get_meta("berry_prep_xp_badge_id", 0))) as Sprite2D
		if badge != null and badge.is_visible_in_tree(): return badge
	return null

func press(point: Vector2, touch: bool) -> void:
	for down in [true, false]:
		if touch:
			var event := InputEventScreenTouch.new()
			event.position = point
			event.pressed = down
			root.push_input(event, true)
		else:
			var event := InputEventMouseButton.new()
			event.position = point
			event.global_position = point
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = down
			root.push_input(event, true)
		await process_frame

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	check(picture.get_size() == root.size, "Raw viewport dimensions")
	var directory := "res://.codex-tmp/activity-polish/" + ("desktop" if game.desktop_layout.enabled() else "mobile")
	DirAccess.make_dir_recursive_absolute(directory)
	picture.save_png(directory + "/" + label + ".png")

func find_meta_control(node: Node, key: String) -> Control:
	if node is Control and node.is_visible_in_tree() and node.get_meta(key, false): return node
	for child in node.get_children():
		var result := find_meta_control(child, key)
		if result != null: return result
	return null

func has_text(node: Node, value: String) -> bool:
	if node is Label and node.text == value: return true
	for child in node.get_children():
		if has_text(child, value): return true
	return false
