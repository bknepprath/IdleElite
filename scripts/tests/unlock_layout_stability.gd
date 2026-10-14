extends "res://scripts/tests/project_resources.gd"

func wait_layout() -> void:
	await settle(0.6)
	for frame in range(300):
		if not game.desktop_layout.rendering and not game._navigation_shell().screen_render_in_progress: break
		await process_frame
	await settle(0.2)

func _run() -> void:
	create_timer(150).timeout.connect(func(): quit(1))
	OS.set_environment("IDLE_ELITE_DESKTOP", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_ONLINE_REQUESTS", "1")
	OS.set_environment("IDLE_ELITE_DISABLE_SAVE_WRITES", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "1")
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE_SECONDS", "145")
	AudioServer.set_bus_mute(0, true)
	root.borderless = true
	root.size = Vector2i(1920, 1080)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	OS.set_environment("IDLE_ELITE_HEADLESS_BOOT_SMOKE", "0")
	while not game.startup_initialized or game._boot_warmup_runtime().active: await process_frame
	game._test_state_runtime()._god_mode_unlock_onboarding_state()
	game._tutorial_overlay_surface()._dismiss_blocking_tip()
	game.auto_unlock_lockpads_enabled = false
	game.desktop_layout.restore_preferences({})
	var tall_barrier := OS.get_environment("IDLE_ELITE_TALL_BARRIER_TEST") == "1"
	var owner := "fight" if tall_barrier else "build"
	var target_id := "tackle-water-trough" if tall_barrier else "repair-small-shack"
	var source_skill := "fight" if tall_barrier else "woodcutting"
	var source_id := "kick-mud-off-boot" if tall_barrier else "split-firewood"
	var resource_id := "grit" if tall_barrier else "plans"
	var target_level := 22 if tall_barrier else 5
	var target_key := owner + ":" + target_id
	for skill in game.skills:
		game.skills[skill].xp = SkillState.xp_for_level(target_level)
		SkillState.recalculate_level(game, skill, false)
		for action in game.actions_by_skill[skill]:
			if int(action.unlock) <= target_level: game._activity_unlock_runtime()._mark_action_manually_unlocked(skill, str(action.id))
	for dimensions in [Vector2i(1920,1080), Vector2i(1080,1920)]:
		game.stamina[source_skill] = 30.0
		root.size = dimensions
		game._project_runtime().clear()
		if tall_barrier:
			for definition in game._project_runtime().definitions.values():
				var work := {}
				for step in definition.project.steps: work[str(step.id)] = int(step.target)
				game._project_runtime().work[str(definition.project.id)] = work
			game._project_runtime().work["fight-tackle-water-trough"]["step-1"] = 46
		game.desktop_layout.rotate_slots("fight" if tall_barrier else "thieving")
		game.selected_skill_id = owner
		await game._navigation_shell()._render_screen()
		await wait_layout()
		if not game.desktop_layout.enabled():
			game._navigation_shell()._select_skill(owner)
			await settle(0.7)
		var panel = await show_project(owner, owner + "-" + target_id)
		check(is_instance_valid(panel), "Project is visible before completion")
		if not is_instance_valid(panel): continue
		# Reach the source using the actual blocker control, then return to watch completion.
		await click(panel.blockers[resource_id].get_global_rect().get_center())
		await wait_layout()
		await game._skill_detail_surface()._scroll_to_activity_card(source_id, true, true)
		await settle(0.6)
		var source: Dictionary = game.action_cards.get(source_skill + ":" + source_id, {})
		check(not source.is_empty(), "Blocker opens its production source")
		await click(source.button.get_global_rect().get_center())
		check(game.running_action_id == source_id, "Actual source click starts training")
		if not game.desktop_layout.enabled():
			game._navigation_shell()._select_skill(owner)
			await settle(0.6)
		panel = await show_project(owner, owner + "-" + target_id)
		var slot: Control = panel.get_parent()
		var slot_id := slot.get_instance_id()
		var original_y := slot.get_global_rect().position.y
		var neighbours := {}
		for child in slot.get_parent().get_children():
			if child is Control and child != slot and child.is_visible_in_tree() and child.get_global_rect().intersects(Rect2(Vector2.ZERO, game.size)):
				neighbours[child.get_instance_id()] = child.get_global_rect()
		var tag := ("unlock-tall-stability-" if tall_barrier else "unlock-stability-") + str(dimensions.x)
		await capture_responsive(tag + "-before")
		var max_jump := 0.0
		var last_y := original_y
		var lost_slot_frames := 0
		var transparent_slot_frames := 0
		var neighbour_changes := 0
		var empty_content_frames := 0
		var fade_frames := 0
		var fade_reversals := 0
		var last_cover_alpha := 1.0
		var started := Time.get_ticks_msec()
		var transition_saved := false
		var completed_at := 0
		while Time.get_ticks_msec() - started < 15000:
			await process_frame
			await RenderingServer.frame_post_draw
			for id in neighbours:
				var neighbour = instance_from_id(id)
				if not is_instance_valid(neighbour) or not neighbour.is_visible_in_tree() or neighbour.get_global_rect().position.distance_to(neighbours[id].position) > 1.0:
					neighbour_changes += 1
			if not is_instance_valid(slot) or not slot.is_inside_tree():
				lost_slot_frames += 1
			else:
				var y := slot.get_global_rect().position.y
				max_jump = maxf(max_jump, absf(y - last_y))
				last_y = y
				if slot.modulate.a < 0.99: transparent_slot_frames += 1
			var activity_mounted: bool = game.action_cards.has(target_key)
			if is_instance_valid(panel):
				var cover_alpha: float = panel.card_root.modulate.a
				if not activity_mounted and cover_alpha < 0.99: empty_content_frames += 1
				if cover_alpha > last_cover_alpha + 0.001: fade_reversals += 1
				last_cover_alpha = cover_alpha
				if cover_alpha > 0.01 and cover_alpha < 0.99:
					fade_frames += 1
					check(activity_mounted, "Activity is mounted before cover starts fading")
					# Resource refreshes during the handoff must not restart its animation.
					panel.sync()
					if not transition_saved and cover_alpha < 0.65:
						root.get_texture().get_image().save_png("res://.codex-tmp/desktop-responsive/" + tag + "-transition.png")
						transition_saved = true
			elif not activity_mounted:
				empty_content_frames += 1
			if completed_at == 0 and game._project_runtime().complete(game._action_data(owner, target_id)):
				completed_at = Time.get_ticks_msec()
			if completed_at > 0 and Time.get_ticks_msec() - completed_at > 1800: break
		game._action_runtime()._stop_running_action(source_skill,source_id)
		await capture_responsive(tag + "-settled")
		check(transition_saved, "Actual training completes blocker")
		check(empty_content_frames == 0, "Cover stays opaque until real activity is ready")
		check(fade_frames >= 2, "Cover transitions over multiple rendered frames")
		check(fade_reversals == 0, "Refreshes cannot replay the cover fade")
		check(not is_instance_valid(panel), "Outgoing cover is removed after the handoff")
		check(lost_slot_frames == 0, "Barrier replacement keeps the existing layout slot")
		check(transparent_slot_frames == 0, "Existing slot never fades out and re-enters")
		check(max_jump <= 1.0, "Completion does not move the watched slot")
		check(neighbour_changes == 0, "Existing neighbouring rows remain visible and stationary")
		check(game.action_cards.has(target_key), "Activity replaces barrier")
		print("UNLOCK_LAYOUT ", JSON.stringify({"size":str(dimensions),"slot_id":slot_id,"lost_slot_frames":lost_slot_frames,"transparent_slot_frames":transparent_slot_frames,"max_jump":max_jump,"neighbour_changes":neighbour_changes,"empty_content_frames":empty_content_frames,"fade_frames":fade_frames,"fade_reversals":fade_reversals}))
	root.size = Vector2i(1920,1080)
	await settle(1.0)
	var desktop = game.desktop_layout
	desktop.intro_guided = true
	desktop.intro_stage = 3
	desktop.intro_features.clear()
	desktop.apply_intro_ribbon()
	var button_rects := {}
	for key in desktop.ribbon_buttons: button_rects[key] = desktop.ribbon_buttons[key].get_global_rect()
	for key in desktop.INTRO_FEATURE_KEYS:
		desktop.intro_features.append(key)
		desktop.intro_feature_key = key
		desktop.intro_feature_elapsed = 0.0
		for frame in range(45):
			await process_frame
			await RenderingServer.frame_post_draw
			for button_key in button_rects:
				check(desktop.ribbon_buttons[button_key].get_global_rect() == button_rects[button_key], "Feature reveal preserves ribbon button positions")
		check(desktop.ribbon_feature_available(key), "Feature becomes available: " + key)
	print("UNLOCK_LAYOUT_STABILITY failures=", JSON.stringify(failures))
	game._app_lifecycle_runtime()._prepare_for_shutdown()
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
